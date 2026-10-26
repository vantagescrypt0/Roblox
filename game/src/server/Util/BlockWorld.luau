--!strict
-- A grid of Minecraft-style blocks. Cells are stored as data; only blocks that touch
-- air (or see-through blocks like leaves) get a Part, so a big island stays cheap.
-- Breaking or placing a block updates that cell and its six neighbours.
--
-- Grid coordinates are integers; (0, 0, 0) is the block whose center is `Origin`.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)

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
}

local BlockWorld = {}

local templateRotations: { [string]: CFrame } = {}

function BlockWorld.key(x: number, y: number, z: number): string
	return `{x},{y},{z}`
end

function BlockWorld.unkey(key: string): (number, number, number)
	local x, y, z = string.match(key, "^(-?%d+),(-?%d+),(-?%d+)$")
	return tonumber(x) :: number, tonumber(y) :: number, tonumber(z) :: number
end

function BlockWorld.new(origin: Vector3, name: string, parent: Instance): World
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return {
		Origin = origin,
		Model = model,
		Cells = {},
		Parts = {},
		Protected = {},
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

local function exposed(world: World, x: number, y: number, z: number): boolean
	for _, offset in NEIGHBOURS do
		if not occludes(world.Cells[BlockWorld.key(x + offset.X, y + offset.Y, z + offset.Z)]) then
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

-- Sets a cell (nil = air) without drawing; call drawAll afterwards
function BlockWorld.setRaw(world: World, x: number, y: number, z: number, blockType: string?)
	(world.Cells :: any)[BlockWorld.key(x, y, z)] = blockType
end

-- Sets a cell and redraws it and its neighbours
function BlockWorld.set(world: World, x: number, y: number, z: number, blockType: string?)
	(world.Cells :: any)[BlockWorld.key(x, y, z)] = blockType
	refresh(world, x, y, z)
	for _, offset in NEIGHBOURS do
		refresh(world, x + offset.X, y + offset.Y, z + offset.Z)
	end
end

function BlockWorld.drawAll(world: World)
	for key in world.Cells do
		local x, y, z = BlockWorld.unkey(key)
		refresh(world, x, y, z)
	end
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
end

return BlockWorld
