--!strict
-- What WorldService hands each world's builder (Worlds/Mining, Woodcutting, Farming): the
-- block world and the tools to fill it. Everything a builder sets is protected scenery
-- except nodes and fields, the resources players gather (they grow back).
--
-- A world is a group of floating islands, Skybounds-style: the arrival island at the
-- south and zone islands around it, joined by plank bridges, with little rocks floating
-- around them. Islands get natural edges: hills ease down toward a ragged rim, the grass
-- hangs over the rock in a lip, roots and vines dangle from it, and underneath hangs a
-- rough cone of rock with spikes, deepest in the middle.
--
-- Grid: x runs west to east, z south to north; y = 0 is the ground's usual height.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Decor = require(script.Parent.Parent.Util.Decor)

local SIZE = Blocks.Size
local ROOT = Color3.fromRGB(104, 76, 48)
local VINE = Color3.fromRGB(70, 128, 52)
local LIP = 0.94 -- beyond this share of the radius the ground is a thin grassy lip
local key = BlockWorld.key

export type IslandSpec = {
	Name: string,
	X: number, -- the centre
	Z: number,
	Radius: number,
	-- The top block and the ground's height for each column (flat areas are made flat
	-- for you, and hills ease down toward the rim)
	Column: (x: number, z: number) -> (string, number),
	Soil: string?, -- the three blocks under the top one (default Dirt)
	Rock: ((x: number, y: number, z: number) -> string)?, -- below that (default Stone)
	-- Or decide every block under the top yourself (`depth` = blocks below the top, 1 = just
	-- under it); return nil for the usual soil and rock
	Fill: ((x: number, y: number, z: number, depth: number) -> string?)?,
	Depth: number?, -- how far the rock hangs below the middle (default 60% of the radius)
}

export type Island = {
	Name: string,
	X: number,
	Z: number,
	Radius: number,
	-- Distance from the centre to the rim in the direction of (x, z)
	Edge: (x: number, z: number) -> number,
}

export type NodeSpot = { X: number, Y: number, Z: number, Block: string }
export type FieldSpot = { X: number, Y: number, Z: number, Crop: string }

export type Context = {
	World: BlockWorld.World,
	Decor: Folder, -- scenery parts (outside the block world, so they never block aiming)
	Rng: Random, -- seeded per world: the same world every time
	SouthZ: number, -- z of the arrival portals, at x = 0 on the arrival island's south end
	Islands: { Island },
	-- What the builder made for players to gather (WorldService runs them)
	Nodes: { [string]: NodeSpot },
	Fields: { [string]: FieldSpot },

	-- Keeps a rectangle flat (height 0) on any island built after this, with a one-block
	-- step around it. With `land`, it's always ground, even past the island's rim (the
	-- arrival square). Call before Island.
	Flatten: (x1: number, z1: number, x2: number, z2: number, land: boolean?) -> (),
	-- Is (x, z) within `margin` of a flat rectangle?
	Flat: (x: number, z: number, margin: number) -> boolean,
	Island: (spec: IslandSpec) -> Island,
	-- A plank bridge from (x1, z1) to (x2, z2), straight along x or z, its deck at y = 0
	Bridge: (x1: number, z1: number, x2: number, z2: number, plank: string?) -> (),
	-- A little floating rock with `top` on it, its top at height y
	Islet: (x: number, y: number, z: number, radius: number, top: string?) -> (),
	-- Digs a cell out of an island (caves, tunnels); use it instead of Set(nil) below the
	-- ground, where the island's inside isn't stored block by block
	Carve: (x: number, y: number, z: number) -> (),

	-- Is (x, z) on an island, at least `margin` blocks in from its rim?
	Inside: (x: number, z: number, margin: number) -> boolean,
	IslandAt: (x: number, z: number) -> Island?,
	-- Is (x, z) within `margin` of the arrival square (kept flat and clear)?
	NearArrival: (x: number, z: number, margin: number) -> boolean,
	-- The ground's height at (x, z), as built (0 off the islands)
	HeightAt: (x: number, z: number) -> number,

	Set: (x: number, y: number, z: number, block: string?) -> (),
	SetFree: (x: number, y: number, z: number, block: string) -> (),
	-- A resource block that grows back after it's mined (skipped if the cell is taken)
	Node: (x: number, y: number, z: number, block: string) -> (),
	-- A wild crop growing on a farmland block at (x, y, z)
	Field: (x: number, y: number, z: number, crop: string) -> (),
	-- Top face of a block, where things stand
	Top: (x: number, y: number, z: number) -> Vector3,
	-- Same number every time for a cell, 0..1
	Hash: (x: number, y: number, z: number) -> number,
	-- Smooth noise about -0.5..0.5 that changes over roughly `scale` blocks
	Noise: (x: number, z: number, scale: number, salt: number) -> number,
}

local Context = {}

function Context.new(world: BlockWorld.World, decor: Folder, seed: number, southZ: number): Context
	local heights: { [string]: number } = {}
	local owner: { [string]: Island } = {}
	local flats: { { number } } = {}
	local lands: { { number } } = {}
	-- Each island column's hollow inside: cells strictly between the two heights
	local hollow: { [string]: { number } } = {}
	local carved: { [string]: boolean } = {}
	local ctx = {} :: Context
	ctx.World = world
	ctx.Decor = decor
	ctx.Rng = Random.new(seed)
	ctx.SouthZ = southZ
	ctx.Islands = {}
	ctx.Nodes = {}
	ctx.Fields = {}

	local function column(x: number, z: number): string
		return `{x},{z}`
	end

	-- Blocks ----------------------------------------------------------------------

	function ctx.Set(x, y, z, block)
		local k = key(x, y, z)
		BlockWorld.setRaw(world, x, y, z, block)
		world.Protected[k] = true
		ctx.Nodes[k] = nil
	end
	function ctx.SetFree(x, y, z, block)
		if not world.Cells[key(x, y, z)] then
			ctx.Set(x, y, z, block)
		end
	end
	function ctx.Node(x, y, z, block)
		local k = key(x, y, z)
		if world.Cells[k] then
			return
		end
		BlockWorld.setRaw(world, x, y, z, block)
		world.Protected[k] = nil
		ctx.Nodes[k] = { X = x, Y = y, Z = z, Block = block }
	end
	function ctx.Field(x, y, z, crop)
		ctx.Set(x, y, z, "Farmland")
		-- Crops need the space above free
		world.Protected[key(x, y + 1, z)] = true
		ctx.Fields[key(x, y, z)] = { X = x, Y = y, Z = z, Crop = crop }
	end
	function ctx.Top(x, y, z)
		return BlockWorld.position(world, x, y, z) + Vector3.new(0, SIZE / 2, 0)
	end
	function ctx.Hash(x, y, z)
		return Random.new(x * 73856093 + y * 19349663 + z * 83492791 + seed):NextNumber()
	end
	function ctx.Noise(x, z, scale, salt)
		return math.noise(x / scale, z / scale, seed * 0.01 + salt * 0.37)
	end

	-- Where things are ---------------------------------------------------------------

	function ctx.IslandAt(x, z)
		return owner[column(x, z)]
	end
	function ctx.Inside(x, z, margin)
		local island = owner[column(x, z)]
		if not island then
			return false
		end
		local dx, dz = x - island.X, z - island.Z
		return math.sqrt(dx * dx + dz * dz) <= island.Edge(x, z) - margin
	end
	function ctx.NearArrival(x, z, margin)
		return z < southZ + 9 + margin and z > southZ - 3 - margin and math.abs(x) < 9 + margin
	end
	function ctx.HeightAt(x, z)
		return heights[column(x, z)] or 0
	end
	function ctx.Flatten(x1, z1, x2, z2, land)
		local r = { math.min(x1, x2), math.min(z1, z2), math.max(x1, x2), math.max(z1, z2) }
		table.insert(flats, r)
		if land then
			table.insert(lands, r)
		end
	end
	-- Is (x, z) within `margin` of a rectangle that must be ground?
	local function mustBeLand(x: number, z: number, margin: number): boolean
		for _, r in lands do
			if x >= r[1] - margin and x <= r[3] + margin and z >= r[2] - margin and z <= r[4] + margin then
				return true
			end
		end
		return false
	end
	function ctx.Flat(x, z, margin)
		for _, r in flats do
			if x >= r[1] - margin and x <= r[3] + margin and z >= r[2] - margin and z <= r[4] + margin then
				return true
			end
		end
		return false
	end

	-- Islands -------------------------------------------------------------------------

	-- Roots under the lip and vines down the cliff, every few blocks round the rim
	local function rimDecor(island: Island, bottoms: { [string]: number }, salt: number)
		local count = math.floor(2 * math.pi * island.Radius / 2.5)
		for i = 0, count - 1 do
			local angle = (i + ctx.Hash(i, salt, 3) * 0.6) / count * 2 * math.pi
			local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local reach = island.Edge(island.X + dir.X * island.Radius, island.Z + dir.Z * island.Radius)
			-- The outermost ground in this direction
			for d = math.floor(reach), math.floor(reach) - 3, -1 do
				local x, z = math.round(island.X + dir.X * d), math.round(island.Z + dir.Z * d)
				if owner[column(x, z)] == island then
					local roll = ctx.Hash(x, salt + 3, z)
					local length = SIZE * (1 + ctx.Hash(x, salt + 4, z) * 3)
					local tilt = CFrame.Angles((roll - 0.5) * 0.5, roll * 6, (ctx.Hash(z, salt, x) - 0.5) * 0.5)
					if roll < 0.55 then
						-- A root hanging from the underside of the lip
						local under = BlockWorld.position(world, x, bottoms[column(x, z)], z)
							- Vector3.new(0, SIZE / 2, 0)
						local root = Decor.Part(
							decor,
							"Root",
							Vector3.new(0.4, length, 0.4),
							CFrame.new(under) * tilt * CFrame.new(0, -length / 2, 0),
							ROOT,
							Enum.Material.Wood
						)
						root.CanCollide = false
						root.CastShadow = false
					else
						-- A vine down the outside of the cliff from the grass
						local top = ctx.Top(x, heights[column(x, z)], z) + dir * (SIZE / 2 + 0.1)
						local vine = Decor.Part(
							decor,
							"Vine",
							Vector3.new(1.1, length, 0.15),
							CFrame.lookAt(top, top + dir) * CFrame.new(0, -length / 2, 0),
							VINE,
							Enum.Material.LeafyGrass
						)
						vine.CanCollide = false
						vine.CastShadow = false
					end
					break
				end
			end
		end
	end

	function ctx.Island(spec)
		local islandRng = Random.new(seed + spec.X * 31 + spec.Z * 17)
		local waves = {}
		for k = 2, 9 do
			table.insert(
				waves,
				{ K = k, Phase = islandRng:NextNumber(0, 2 * math.pi), Amp = islandRng:NextNumber(0.4, 1) / k }
			)
		end
		local function edge(x: number, z: number): number
			local angle = math.atan2(z - spec.Z, x - spec.X)
			local r = 0
			for _, wave in waves do
				r += wave.Amp * math.sin(wave.K * angle + wave.Phase)
			end
			return spec.Radius * (1 + 0.15 * r)
		end
		local island: Island = { Name = spec.Name, X = spec.X, Z = spec.Z, Radius = spec.Radius, Edge = edge }
		table.insert(ctx.Islands, island)

		local salt = #ctx.Islands * 10
		local soil = spec.Soil or "Dirt"
		local rock = spec.Rock
		local depthMax = spec.Depth or math.floor(spec.Radius * 0.6)
		local reach = math.ceil(spec.Radius * 1.4)
		local bottoms: { [string]: number } = {}
		local tops: { [string]: string } = {}
		local ground: { { number } } = {}

		-- First the shape: which columns are ground, how high and how deep
		for x = spec.X - reach, spec.X + reach do
			for z = spec.Z - reach, spec.Z + reach do
				local dx, dz = x - spec.X, z - spec.Z
				local d = math.sqrt(dx * dx + dz * dz)
				local e = edge(x, z)
				local col = column(x, z)
				-- A ragged rim: notches out of the outermost ring. Areas that must be ground
				-- (the arrival square) always are.
				local notch = d > e - 1.2 and ctx.Hash(x, salt, z) < 0.4
				local flat = mustBeLand(x, z, 1) and d <= e * 1.3
				if (d <= e and not notch or flat) and not owner[col] then
					local t = math.min(d / e, 1)
					local block, height = spec.Column(x, z)
					if ctx.Flat(x, z, 0) then
						height = 0
					elseif ctx.Flat(x, z, 2) then
						height = math.min(height, 1)
					end
					-- Hills ease down toward the rim
					if height > 0 and t > 0.7 then
						height = math.floor(height * math.clamp((1 - t) / 0.3, 0, 1) + 0.5)
					end
					-- How far down it goes: a thin lip at the rim, then a rough cone of rock,
					-- with a spike here and there
					local bottom
					if t > LIP and not flat then
						bottom = height - 1
					else
						local hang = depthMax * (1 - t ^ 1.6) ^ 0.85
						hang *= 0.7 + 0.6 * (ctx.Noise(x, z, 9, salt) + 0.5)
						-- Chunky spikes, two blocks across
						local sx, sz = math.floor(x / 2), math.floor(z / 2)
						if ctx.Hash(sx, salt + 1, sz) < 0.1 * (1 - t) then
							hang += if ctx.Hash(sx, salt + 2, sz) < 0.5 then 4 else 8
						end
						-- In steps of four blocks deep (fewer, bigger rock pieces)
						local depth = math.max(2, math.floor(hang))
						if depth > 4 then
							depth = 4 * math.round(depth / 4)
						end
						bottom = math.min(height - 2, -depth)
					end
					heights[col] = height
					bottoms[col] = bottom
					tops[col] = block
					owner[col] = island
					table.insert(ground, { x, z })
				end
			end
		end

		-- Then the blocks. Only the shell is stored: the top and three blocks of soil, two
		-- of rock underneath, and wherever a lower or shallower neighbour leaves a side
		-- open. The rest is the island's hollow inside, solid as far as anyone can tell
		-- (world.Inner).
		local INF = math.huge
		for _, spot in ground do
			local x, z = spot[1], spot[2]
			local col = column(x, z)
			local top, bottom = heights[col], bottoms[col]
			local lowestTop, deepestBottom = INF, -INF
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local n = column(x + d[1], z + d[2])
				if owner[n] then
					lowestTop = math.min(lowestTop, heights[n])
					deepestBottom = math.max(deepestBottom, bottoms[n])
				else
					lowestTop, deepestBottom = -INF, INF
				end
			end
			local lo = math.max(bottom + 1, deepestBottom)
			local hi = math.min(top - 3, lowestTop)
			if hi - lo > 1 then
				hollow[col] = { lo, hi }
			end
			ctx.Set(x, top, z, tops[col])
			for y = top - 1, bottom, -1 do
				if y <= lo or y >= hi then
					local block = if spec.Fill then spec.Fill(x, y, z, top - y) else nil
					if not block then
						block = if y >= top - 3 then soil elseif rock then rock(x, y, z) else "Stone"
					end
					ctx.Set(x, y, z, block)
				end
			end
		end
		rimDecor(island, bottoms, salt)
		return island
	end

	-- Digs out a cell inside an island (caves, tunnels): it becomes real air, even in the
	-- island's hollow inside
	function ctx.Carve(x, y, z)
		carved[key(x, y, z)] = true
		ctx.Set(x, y, z, nil)
	end
	world.Inner = function(x, y, z)
		local range = hollow[column(x, z)]
		return range ~= nil and y > range[1] and y < range[2] and not carved[key(x, y, z)]
	end

	function ctx.Islet(x, y, z, radius, top)
		local reach = math.ceil(radius) + 1
		for dx = -reach, reach do
			for dz = -reach, reach do
				local d = math.sqrt(dx * dx + dz * dz)
				local e = radius + ctx.Noise(x + dx, z + dz, 3, 99) * 1.5
				if d <= e then
					local t = d / e
					ctx.Set(x + dx, y, z + dz, top or "Grass")
					local depth = 1 + math.floor((1 - t) ^ 0.8 * radius * 1.3)
					for dy = 1, depth do
						ctx.Set(x + dx, y - dy, z + dz, if dy <= 1 then "Dirt" else "Stone")
					end
				end
			end
		end
	end

	-- Bridges ---------------------------------------------------------------------------

	function ctx.Bridge(x1, z1, x2, z2, plank)
		local deck = plank or "DarkPlanks"
		local alongX = z1 == z2
		local from = if alongX then math.min(x1, x2) else math.min(z1, z2)
		local to = if alongX then math.max(x1, x2) else math.max(z1, z2)
		local side = if alongX then Vector3.zAxis else Vector3.xAxis
		local function cell(s: number, w: number): (number, number)
			if alongX then
				return s, z1 + w
			end
			return x1 + w, s
		end
		-- Where it crosses open air
		local gapFrom, gapTo
		for s = from, to do
			local x, z = cell(s, 0)
			if not owner[column(x, z)] then
				gapFrom = gapFrom or s
				gapTo = s
			end
		end
		-- The deck, five blocks wide, with headroom cleared over it
		for s = from, to do
			for w = -2, 2 do
				local x, z = cell(s, w)
				ctx.Set(x, 0, z, deck)
				heights[column(x, z)] = 0
				for y = 1, 6 do
					if world.Cells[key(x, y, z)] then
						ctx.Set(x, y, z, nil)
					end
				end
			end
		end
		if not gapFrom then
			return
		end
		-- Over the gap: log beams under both edges and across every few blocks, railings,
		-- and lantern posts at both ends and along the way
		local a, b = gapFrom - 1, gapTo + 1
		for s = a, b do
			for _, w in { -2, 2 } do
				local x, z = cell(s, w)
				ctx.Set(x, -1, z, "Wood")
			end
			if (s - a) % 5 == 0 then
				for w = -1, 1 do
					local x, z = cell(s, w)
					ctx.Set(x, -1, z, "Wood")
				end
			end
		end
		for _, w in { -2, 2 } do
			local ax, az = cell(a, w)
			local bx, bz = cell(b, w)
			local out = side * (w / 2) * (SIZE * 0.35)
			Decor.Fence(decor, ctx.Top(ax, 0, az) + out, ctx.Top(bx, 0, bz) + out, deck)
		end
		local posts = math.max(1, math.round((b - a) / 8))
		for i = 0, posts do
			local s = a + math.round((b - a) * i / posts)
			for _, w in { -2, 2 } do
				local x, z = cell(s, w)
				ctx.Set(x, 1, z, "Wood")
				ctx.Set(x, 2, z, "Wood")
				Decor.Lantern(decor, ctx.Top(x, 2, z), false, 18)
			end
		end
	end

	return ctx
end

return Context
