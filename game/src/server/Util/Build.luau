--!strict
-- Building with blocks for the Town and the worlds: fills, hollow walls, stepped gable
-- roofs, doors and windows. Everything built is protected (players can't break it).
--
-- A Site is a building plot in its own frame, so one design can face any way:
--   u  runs along the front (left to right, seen from outside)
--   v  runs from the front wall (v = 0) back into the building
--   y  is height; the ground row is y = 0
-- `front` is the way the front faces (an axis: ±X or ±Z).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.BlockWorld)

local SIZE = Blocks.Size

-- A block type, or a function picking one per cell (nil leaves the cell alone)
export type Pattern = string | (x: number, y: number, z: number) -> string?

export type Site = {
	World: BlockWorld.World,
	Front: Vector3,
	-- Grid cell of a local (u, v)
	Cell: (self: Site, u: number, v: number) -> (number, number),
	-- World position of a local cell's center (fractions allowed)
	Pos: (self: Site, u: number, y: number, v: number) -> Vector3,
	-- A world direction from a local one (du along u, dv along v)
	Dir: (self: Site, du: number, dv: number) -> Vector3,
	Set: (self: Site, u: number, y: number, v: number, block: Pattern?) -> (),
	Fill: (self: Site, u1: number, y1: number, v1: number, u2: number, y2: number, v2: number, block: Pattern?) -> (),
	Walls: (self: Site, u1: number, y1: number, v1: number, u2: number, y2: number, v2: number, block: Pattern) -> (),
	Clear: (self: Site, u1: number, y1: number, v1: number, u2: number, y2: number, v2: number) -> (),
	Roof: (
		self: Site,
		u1: number,
		v1: number,
		u2: number,
		v2: number,
		y: number,
		roof: string,
		gable: Pattern?,
		ridgeAlongU: boolean
	) -> number,
}

local Build = {}

local function pick(pattern: Pattern?, x: number, y: number, z: number): string?
	if type(pattern) == "function" then
		return pattern(x, y, z)
	end
	return pattern :: string?
end

-- Sets a cell (nil = air) and protects it. Doesn't draw: call BlockWorld.drawAll after.
function Build.Set(world: BlockWorld.World, x: number, y: number, z: number, block: Pattern?)
	local chosen = pick(block, x, y, z)
	BlockWorld.setRaw(world, x, y, z, chosen)
	world.Protected[BlockWorld.key(x, y, z)] = true
end

-- Sets a cell only if it's empty (scenery never overwrites anything)
function Build.SetFree(world: BlockWorld.World, x: number, y: number, z: number, block: Pattern?)
	if not BlockWorld.get(world, x, y, z) then
		Build.Set(world, x, y, z, block)
	end
end

function Build.Fill(
	world: BlockWorld.World,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	block: Pattern?
)
	for x = math.min(x1, x2), math.max(x1, x2) do
		for y = math.min(y1, y2), math.max(y1, y2) do
			for z = math.min(z1, z2), math.max(z1, z2) do
				Build.Set(world, x, y, z, block)
			end
		end
	end
end

function Build.Site(world: BlockWorld.World, ox: number, oz: number, front: Vector3): Site
	local fx, fz = math.round(front.X), math.round(front.Z)
	local site = {} :: Site
	site.World = world
	site.Front = Vector3.new(fx, 0, fz)

	-- Facing the front from outside, u runs to the right and v runs away from you
	function site.Cell(_self, u, v)
		return ox + fz * u - fx * v, oz - fx * u - fz * v
	end
	function site.Dir(_self, du, dv)
		return Vector3.new(fz * du - fx * dv, 0, -fx * du - fz * dv)
	end
	function site.Pos(_self, u, y, v)
		local x, z = ox + fz * u - fx * v, oz - fx * u - fz * v
		return BlockWorld.position(world, x, y, z)
	end
	function site.Set(self, u, y, v, block)
		local x, z = self:Cell(u, v)
		Build.Set(world, x, y, z, block)
	end
	function site.Fill(self, u1, y1, v1, u2, y2, v2, block)
		for u = math.min(u1, u2), math.max(u1, u2) do
			for v = math.min(v1, v2), math.max(v1, v2) do
				for y = math.min(y1, y2), math.max(y1, y2) do
					self:Set(u, y, v, block)
				end
			end
		end
	end
	function site.Walls(self, u1, y1, v1, u2, y2, v2, block)
		local ua, ub = math.min(u1, u2), math.max(u1, u2)
		local va, vb = math.min(v1, v2), math.max(v1, v2)
		for u = ua, ub do
			for v = va, vb do
				if u == ua or u == ub or v == va or v == vb then
					for y = math.min(y1, y2), math.max(y1, y2) do
						self:Set(u, y, v, block)
					end
				end
			end
		end
	end
	function site.Clear(self, u1, y1, v1, u2, y2, v2)
		self:Fill(u1, y1, v1, u2, y2, v2, nil)
	end

	-- A stepped gable roof over the walls' outline [u1, u2] x [v1, v2], starting at height
	-- y and overhanging by one block. The ridge runs along u (or along v); the triangle
	-- under each sloped end is filled with `gable`. Returns the ridge's height.
	function site.Roof(self, u1, v1, u2, v2, y, roof, gable, ridgeAlongU)
		local a1, a2 = if ridgeAlongU then v1 - 1 else u1 - 1, if ridgeAlongU then v2 + 1 else u2 + 1
		local b1, b2 = if ridgeAlongU then u1 - 1 else v1 - 1, if ridgeAlongU then u2 + 1 else v2 + 1
		local function put(a: number, b: number, h: number, block: Pattern?)
			if ridgeAlongU then
				self:Set(b, h, a, block)
			else
				self:Set(a, h, b, block)
			end
		end
		local i = 0
		while a1 + i <= a2 - i do
			local h = y + i
			for b = b1, b2 do
				put(a1 + i, b, h, roof)
				put(a2 - i, b, h, roof)
			end
			-- Gable ends: fill between the slopes, just inside the overhang
			if gable then
				for a = a1 + i + 1, a2 - i - 1 do
					put(a, b1 + 1, h, gable)
					put(a, b2 - 1, h, gable)
				end
			end
			i += 1
		end
		return y + i - 1
	end

	return site
end

-- World position of the top of a cell (where things stand)
function Build.Top(world: BlockWorld.World, x: number, y: number, z: number): Vector3
	return BlockWorld.position(world, x, y, z) + Vector3.new(0, SIZE / 2, 0)
end

return Build
