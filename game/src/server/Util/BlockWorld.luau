--!strict
-- A grid of Minecraft-style blocks. Cells are stored as data; only blocks that touch
-- air (or see-through blocks like leaves) get a Part, so a big island stays cheap.
-- Breaking or placing a block updates that cell and its six neighbours.
--
-- Merging (drawAll with merge on, for the shared worlds and Town): scenery nobody can
-- change (protected cells: ground, cliffs, rock) is drawn as big pre-made pieces instead
-- of a Part per block. ReplicatedStorage.Blocks.Merged holds them, named
-- "<Block>_<x>x<y>x<z>" (blocks along x, up, along z; made by art/scripts/blocks.py with
-- the block's tiles on every face), so a piece looks exactly like the blocks it replaces,
-- and pieces of one shape share a mesh and batch together. A piece can be turned a
-- quarter turn, so "Stone_8x1x4" also fills 4x1x8. Changing a cell inside a piece breaks
-- the piece back into single blocks.
--
-- Grid coordinates are integers; (0, 0, 0) is the block whose center is `Origin`.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Pace = require(script.Parent.Pace)

local SIZE = Blocks.Size
local NEIGHBOURS = {
	Vector3.new(1, 0, 0),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 1, 0),
	Vector3.new(0, -1, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(0, 0, -1),
}

export type World = {
	Origin: Vector3,
	Model: Model,
	Cells: { [string]: string },
	Parts: { [string]: BasePart },
	-- Cells players may not change (crafting table, farmland, portal, ...)
	Protected: { [string]: boolean },
	-- Cells drawn as part of a merged piece
	Merged: { [string]: Piece },
	-- Empty cells that count as solid rock: the hollow inside of a world's islands, which
	-- nobody can see into, so it isn't stored block by block
	Inner: ((x: number, y: number, z: number) -> boolean)?,
}

-- A merged piece and its cells. Part is nil for a piece buried where nobody can see it.
export type Piece = { Part: BasePart?, Cells: { string } }

-- A piece's size in blocks, as placed (turned pieces swap x and z)
type Shape = { X: number, Y: number, Z: number, Template: BasePart, Turned: boolean }

local BlockWorld = {}

local templateRotations: { [string]: CFrame } = {}
local shapesByType: { [string]: { Shape } }? = nil
local QUARTER_TURN = CFrame.Angles(0, math.pi / 2, 0)

function BlockWorld.key(x: number, y: number, z: number): string
	-- + 0 turns -0 (from rounding a small negative number) into 0, so it's the same cell
	return `{x + 0},{y + 0},{z + 0}`
end

function BlockWorld.unkey(key: string): (number, number, number)
	local x, y, z = string.match(key, "^(-?%d+),(-?%d+),(-?%d+)$")
	return tonumber(x) :: number, tonumber(y) :: number, tonumber(z) :: number
end

function BlockWorld.new(origin: Vector3, name: string, parent: Instance): World
	local model = Instance.new("Model")
	model.Name = name
	-- Where block (0, 0, 0) is, so the client can find blocks inside merged pieces
	model:SetAttribute("Origin", origin)
	model.Parent = parent
	return {
		Origin = origin,
		Model = model,
		Cells = {},
		Parts = {},
		Protected = {},
		Merged = {},
	}
end

-- World position of a cell's center
function BlockWorld.position(world: World, x: number, y: number, z: number): Vector3
	return world.Origin + Vector3.new(x, y, z) * SIZE
end

-- Grid cell containing a world position
function BlockWorld.cellAt(world: World, position: Vector3): (number, number, number)
	local local_ = (position - world.Origin) / SIZE
	return math.round(local_.X), math.round(local_.Y), math.round(local_.Z)
end

function BlockWorld.get(world: World, x: number, y: number, z: number): string?
	return world.Cells[BlockWorld.key(x, y, z)]
end

local function template(blockType: string): BasePart?
	local folder = ReplicatedStorage:FindFirstChild("Blocks")
	local part = folder and folder:FindFirstChild(blockType)
	return if part and part:IsA("BasePart") then part else nil
end

-- Hides nothing behind it?
local function occludes(blockType: string?): boolean
	if not blockType then
		return false
	end
	local def = Blocks.Types[blockType]
	return def ~= nil and not def.SeeThrough
end

-- Is the cell solid as far as drawing goes (a block that hides what's behind it, or the
-- hollow inside of an island)?
local function solidAt(world: World, x: number, y: number, z: number): boolean
	local blockType = world.Cells[BlockWorld.key(x, y, z)]
	if blockType then
		return occludes(blockType)
	end
	local inner = world.Inner
	return inner ~= nil and inner(x, y, z)
end

local function exposed(world: World, x: number, y: number, z: number): boolean
	for _, offset in NEIGHBOURS do
		if not solidAt(world, x + offset.X, y + offset.Y, z + offset.Z) then
			return true
		end
	end
	return false
end

local function makePart(world: World, blockType: string, x: number, y: number, z: number): BasePart
	local source = template(blockType)
	local part: BasePart
	local rotation = templateRotations[blockType]
	if source then
		part = source:Clone()
		if not rotation then
			-- Imported meshes carry their own rotation; keep it so faces stay the right way up
			rotation = source.CFrame.Rotation
			templateRotations[blockType] = rotation
		end
	else
		-- Fallback if the block art is missing: a plain coloured cube
		local fallback = Instance.new("Part")
		fallback.Size = Vector3.one * SIZE
		fallback.Color = Color3.fromRGB(120, 160, 80)
		fallback.TopSurface = Enum.SurfaceType.Smooth
		fallback.BottomSurface = Enum.SurfaceType.Smooth
		part = fallback
		rotation = CFrame.identity
	end
	part.Name = blockType
	part.Anchored = true
	part.CFrame = CFrame.new(BlockWorld.position(world, x, y, z)) * (rotation :: CFrame)
	part:SetAttribute("X", x)
	part:SetAttribute("Y", y)
	part:SetAttribute("Z", z)
	-- Tells the client not to show cracks on blocks that can't be broken here
	if world.Protected[BlockWorld.key(x, y, z)] then
		part:SetAttribute("Locked", true)
	end
	part.Parent = world.Model
	return part
end

-- Creates or removes the Part for one cell to match its data and visibility
local function refresh(world: World, x: number, y: number, z: number)
	local key = BlockWorld.key(x, y, z)
	if world.Merged[key] then
		return -- drawn by its piece
	end
	local blockType = world.Cells[key]
	local part: BasePart? = world.Parts[key]
	local shouldShow = blockType ~= nil and exposed(world, x, y, z)
	if part and (not shouldShow or part.Name ~= blockType) then
		part:Destroy()
		world.Parts[key] = nil
		part = nil
	end
	if shouldShow and not part then
		world.Parts[key] = makePart(world, blockType :: string, x, y, z)
	end
end

-- Merged pieces ------------------------------------------------------------------

-- The pieces each block type can be merged into, biggest first
local function shapes(): { [string]: { Shape } }
	local known = shapesByType
	if known then
		return known
	end
	local result: { [string]: { Shape } } = {}
	local folder = ReplicatedStorage:FindFirstChild("Blocks")
	local merged = folder and folder:FindFirstChild("Merged")
	if merged then
		for _, mesh in merged:GetChildren() do
			local blockType, sx, sy, sz = string.match(mesh.Name, "^(%w+)_(%d+)x(%d+)x(%d+)$")
			if blockType and mesh:IsA("BasePart") then
				local x, y, z = tonumber(sx) :: number, tonumber(sy) :: number, tonumber(sz) :: number
				local list = result[blockType] or {}
				result[blockType] = list
				table.insert(list, { X = x, Y = y, Z = z, Template = mesh, Turned = false })
				if x ~= z then
					table.insert(list, { X = z, Y = y, Z = x, Template = mesh, Turned = true })
				end
			end
		end
	end
	for _, list in result do
		table.sort(list, function(a, b)
			return a.X * a.Y * a.Z > b.X * b.Y * b.Z
		end)
	end
	shapesByType = result
	return result
end

-- Can `shape` go with its lowest corner at (x, y, z)? Every cell in it must be protected
-- scenery of this type that isn't in a piece yet.
local function fits(world: World, shape: Shape, x: number, y: number, z: number, blockType: string): boolean
	for dy = 0, shape.Y - 1 do
		for dz = 0, shape.Z - 1 do
			for dx = 0, shape.X - 1 do
				local key = BlockWorld.key(x + dx, y + dy, z + dz)
				if world.Cells[key] ~= blockType or world.Merged[key] or not world.Protected[key] then
					return false
				end
			end
		end
	end
	return true
end

-- Is every cell around the box solid scenery, so nothing could ever see it?
local function buried(world: World, x: number, y: number, z: number, shape: Shape): boolean
	local function solid(cx: number, cy: number, cz: number): boolean
		local key = BlockWorld.key(cx, cy, cz)
		if world.Cells[key] then
			return world.Protected[key] == true and occludes(world.Cells[key])
		end
		local inner = world.Inner
		return inner ~= nil and inner(cx, cy, cz)
	end
	local x2, y2, z2 = x + shape.X - 1, y + shape.Y - 1, z + shape.Z - 1
	for a = x, x2 do
		for b = z, z2 do
			if not solid(a, y - 1, b) or not solid(a, y2 + 1, b) then
				return false
			end
		end
		for b = y, y2 do
			if not solid(a, b, z - 1) or not solid(a, b, z2 + 1) then
				return false
			end
		end
	end
	for a = y, y2 do
		for b = z, z2 do
			if not solid(x - 1, a, b) or not solid(x2 + 1, a, b) then
				return false
			end
		end
	end
	return true
end

local function placePiece(world: World, blockType: string, shape: Shape, x: number, y: number, z: number)
	local cells = {}
	for dy = 0, shape.Y - 1 do
		for dz = 0, shape.Z - 1 do
			for dx = 0, shape.X - 1 do
				table.insert(cells, BlockWorld.key(x + dx, y + dy, z + dz))
			end
		end
	end
	local piece: Piece = { Part = nil, Cells = cells }
	for _, key in cells do
		world.Merged[key] = piece
	end
	if buried(world, x, y, z, shape) then
		return
	end
	local source = shape.Template
	local part = source:Clone()
	local rotation = templateRotations[source.Name]
	if not rotation then
		rotation = source.CFrame.Rotation
		templateRotations[source.Name] = rotation
	end
	local center = BlockWorld.position(world, x, y, z) + Vector3.new(shape.X - 1, shape.Y - 1, shape.Z - 1) * (SIZE / 2)
	part.Name = blockType
	part.Anchored = true
	part.CFrame = CFrame.new(center) * (if shape.Turned then QUARTER_TURN else CFrame.identity) * rotation
	part:SetAttribute("Locked", true)
	-- The client works out which block of the piece you aim at (the world's Origin)
	part:SetAttribute("Merged", true)
	part.Parent = world.Model
	piece.Part = part
end

-- Draws protected scenery as big pieces where they fit: lowest cells first, biggest
-- piece first
local function mergeScenery(world: World)
	local byType = shapes()
	-- Each candidate as one number ordered by y, then z, then x (sorting plain numbers is
	-- much faster than sorting tables, and the big worlds have hundreds of thousands)
	local order: { number } = {}
	for key, blockType in world.Cells do
		if byType[blockType] and world.Protected[key] then
			local x, y, z = BlockWorld.unkey(key)
			table.insert(order, ((y + 1024) * 2048 + (z + 1024)) * 2048 + (x + 1024))
		end
	end
	table.sort(order)
	for _, n in order do
		Pace.Step()
		local x = n % 2048 - 1024
		local z = (n // 2048) % 2048 - 1024
		local y = n // 4194304 - 1024
		local key = BlockWorld.key(x, y, z)
		if not world.Merged[key] then
			local blockType = world.Cells[key] :: string
			for _, shape in byType[blockType] do
				if fits(world, shape, x, y, z, blockType) then
					placePiece(world, blockType, shape, x, y, z)
					break
				end
			end
		end
	end
end

-- Breaks a piece back into single blocks (when a cell inside it changes)
local function unmerge(world: World, piece: Piece)
	if piece.Part then
		piece.Part:Destroy()
	end
	for _, key in piece.Cells do
		world.Merged[key] = nil
	end
	for _, key in piece.Cells do
		refresh(world, BlockWorld.unkey(key))
	end
end

-- Sets a cell (nil = air) without drawing; call drawAll afterwards
function BlockWorld.setRaw(world: World, x: number, y: number, z: number, blockType: string?)
	(world.Cells :: any)[BlockWorld.key(x, y, z)] = blockType
end

-- Sets a cell and redraws it and its neighbours
function BlockWorld.set(world: World, x: number, y: number, z: number, blockType: string?)
	local key = BlockWorld.key(x, y, z)
	local piece = world.Merged[key]
	if piece then
		unmerge(world, piece)
	end
	(world.Cells :: any)[key] = blockType
	refresh(world, x, y, z)
	for _, offset in NEIGHBOURS do
		refresh(world, x + offset.X, y + offset.Y, z + offset.Z)
	end
end

-- Draws every cell. With `merge`, protected scenery is drawn as big pieces where it can be.
function BlockWorld.drawAll(world: World, merge: boolean?)
	if merge then
		mergeScenery(world)
	end
	for key in world.Cells do
		Pace.Step()
		local x, y, z = BlockWorld.unkey(key)
		refresh(world, x, y, z)
	end
end

-- How many Parts the blocks use (single blocks + pieces), for checking performance
function BlockWorld.partCount(world: World): number
	local count = 0
	for _ in world.Parts do
		count += 1
	end
	local pieces: { [Piece]: boolean } = {}
	for _, piece in world.Merged do
		if piece.Part and not pieces[piece] then
			pieces[piece] = true
			count += 1
		end
	end
	return count
end

function BlockWorld.part(world: World, x: number, y: number, z: number): BasePart?
	return world.Parts[BlockWorld.key(x, y, z)]
end

-- Is someone standing in this cell? (blocks that grow back wait until they move)
function BlockWorld.occupied(world: World, x: number, y: number, z: number): boolean
	local size = Vector3.one * (SIZE - 0.3)
	for _, part in workspace:GetPartBoundsInBox(CFrame.new(BlockWorld.position(world, x, y, z)), size) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChildOfClass("Humanoid") then
			return true
		end
	end
	return false
end

function BlockWorld.hasNeighbour(world: World, x: number, y: number, z: number): boolean
	for _, offset in NEIGHBOURS do
		if world.Cells[BlockWorld.key(x + offset.X, y + offset.Y, z + offset.Z)] then
			return true
		end
	end
	return false
end

function BlockWorld.destroy(world: World)
	world.Model:Destroy()
	table.clear(world.Parts)
	table.clear(world.Merged)
end

return BlockWorld
