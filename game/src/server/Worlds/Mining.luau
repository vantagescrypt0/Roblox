--!strict
-- The Mining World: a quarry camp on the arrival island and, over a stone bridge to the
-- north, a great jagged mountain of sandstone with a long mine inside it (from the
-- Skybounds mine: cracked sandstone peaks hung with vines, a big arch entrance between two
-- wooden pavilions, and inside, a section for each ore).
--   The quarry    gravel yards round the arrival square: a miner's hut, a tent by a
--                 campfire, carts of ore on rails, and rocky outcrops to mine on the way in
--   The mountain  sandstone peaks with dark cracks and vines, grassy terraces with
--                 boulders at its foot, and the mine's arch with "THE MINE" hanging in it
--   The mine      the way in leads to the Lantern Hall, where a signpost points the way:
--                 west to the Iron Vein, east to the Coal Seam, north to the Lava Cavern
--                 (lava pouring into a glowing pool, vines and glowing mushrooms). From the
--                 cavern a tunnel winds down to the deep Gold Chamber (Mining 10) and another
--                 to the Crystal Grotto.
-- Each section's walls are thick with its own ore (and grow back, two blocks deep); the
-- tunnels between are mostly stone with the odd coal or iron. Behind every wall is dark
-- stone, as far as anyone can dig. Floors, the mountain's outside and the timbers can't be
-- broken. Caves stay at least four blocks inside the rock, so they never break out.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Build = require(script.Parent.Parent.Util.Build)
local Decor = require(script.Parent.Parent.Util.Decor)
local Signs = require(script.Parent.Parent.Util.Signs)
local Trees = require(script.Parent.Parent.Util.Trees)
local Common = require(script.Parent.Common)
local Context = require(script.Parent.Context)

local SIZE = Blocks.Size
local key = BlockWorld.key

local Mining = {}

Mining.SouthZ = -84
Mining.Seed = 11
Mining.Haze = 0.6
Mining.Caves = true

local QUARRY = { X = 0, Z = -64, R = 26 }
local PEAKS = { X = 0, Z = 30, R = 58 }

-- The mountain is several peaks run together: centre, radius, height
local PEAK_LIST = {
	{ 0, 44, 34, 40 },
	{ -24, 34, 20, 30 },
	{ 24, 36, 20, 31 },
	{ -14, 64, 18, 28 },
	{ 16, 64, 18, 26 },
	{ 0, 22, 16, 22 },
}

-- A cave section: tunnels are runs between points (X, floor height, Z), chambers are domes
-- standing on a floor. Ore: what its walls are rich in, and how rich (Share).
type Section = { Ore: string?, Share: number?, Deep: boolean? }
type Tunnel = {
	Points: { Vector3 },
	Width: number,
	Height: number,
	Mouth: boolean?,
	Ore: string?,
	Share: number?,
	Deep: boolean?,
}
type Chamber = {
	Name: string,
	X: number,
	Z: number,
	Floor: number,
	Radii: Vector3,
	Ore: string?,
	Share: number?,
	Deep: boolean?,
}

local TUNNELS: { Tunnel } = {
	-- The way in, from the arch on the south face to the Lantern Hall
	{
		Points = { Vector3.new(0, 1, -2), Vector3.new(0, 1, 10), Vector3.new(0, 1, 18) },
		Width = 2.6,
		Height = 4.5,
		Mouth = true,
	},
	-- Hall to the Coal Seam (east) and the Iron Vein (west)
	{ Points = { Vector3.new(7, 1, 24), Vector3.new(14, 1, 27), Vector3.new(21, 1, 31) }, Width = 2.2, Height = 3.8 },
	{
		Points = { Vector3.new(-7, 1, 24), Vector3.new(-14, 1, 27), Vector3.new(-21, 1, 31) },
		Width = 2.2,
		Height = 3.8,
	},
	-- Hall north to the Lava Cavern
	{ Points = { Vector3.new(0, 1, 30), Vector3.new(-2, 1, 36), Vector3.new(0, 1, 41) }, Width = 2.4, Height = 4 },
	-- Cavern down to the Gold Chamber, and over to the Crystal Grotto
	{
		Points = { Vector3.new(-8, 1, 56), Vector3.new(-13, -3, 60), Vector3.new(-17, -8, 63) },
		Width = 2,
		Height = 3.6,
		Ore = "IronOre",
		Share = 0.08,
		Deep = true,
	},
	{ Points = { Vector3.new(8, 1, 56), Vector3.new(13, 1, 61), Vector3.new(17, 1, 64) }, Width = 2, Height = 3.6 },
}
local CHAMBERS: { Chamber } = {
	{ Name = "Hall", X = 0, Z = 24, Floor = 1, Radii = Vector3.new(9, 8, 7) },
	{ Name = "Coal", X = 29, Z = 33, Floor = 1, Radii = Vector3.new(9, 7, 8), Ore = "CoalOre", Share = 0.45 },
	{ Name = "Iron", X = -29, Z = 33, Floor = 1, Radii = Vector3.new(9, 7, 8), Ore = "IronOre", Share = 0.38 },
	{ Name = "Lava", X = 0, Z = 50, Floor = 1, Radii = Vector3.new(13, 11, 10) },
	{
		Name = "Gold",
		X = -21,
		Z = 66,
		Floor = -8,
		Radii = Vector3.new(8, 8, 7),
		Ore = "GoldOre",
		Share = 0.3,
		Deep = true,
	},
	{ Name = "Grotto", X = 21, Z = 67, Floor = 1, Radii = Vector3.new(7, 7, 6), Ore = "IronOre", Share = 0.12 },
}
local CAVE_BOX = { X1 = -40, X2 = 40, Z1 = -4, Z2 = 76, Y1 = -9, Y2 = 14 }

local function chamber(name: string): Chamber
	for _, c in CHAMBERS do
		if c.Name == name then
			return c
		end
	end
	error(`no chamber {name}`)
end

-- Mountain shape ----------------------------------------------------------------------------

-- The mountain's height at (x, z) before making room over the caves (0 = no mountain):
-- the highest of its peaks there, made jagged with ridged noise
local function slope(ctx: Context.Context, x: number, z: number): number
	local best = 0
	for _, p in PEAK_LIST do
		local d = math.sqrt((x - p[1]) ^ 2 + (z - p[2]) ^ 2)
		if d < p[3] then
			best = math.max(best, p[4] * (1 - (d / p[3]) ^ 1.4))
		end
	end
	if best <= 0 then
		return 0
	end
	local ridges = (0.5 - math.abs(ctx.Noise(x, z, 9, 20))) * 9 + ctx.Noise(x, z, 4, 21) * 3
	return math.max(0, math.floor(best + ridges * math.clamp(best / 12, 0, 1)))
end

-- Horizontal distance from p to the segment a-b, and how far along it (0..1)
local function segment(p: Vector2, a: Vector2, b: Vector2): (number, number)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (p - (a + ab * t)).Magnitude, t
end

-- Which cave section (x, y, z) is in, if any (with a little noise so the walls are rough),
-- and whether it's the way in (which may reach the outside)
local function inCave(ctx: Context.Context, x: number, y: number, z: number): (Section?, boolean)
	local p = Vector2.new(x, z)
	for _, tunnel in TUNNELS do
		for i = 1, #tunnel.Points - 1 do
			local a, b = tunnel.Points[i], tunnel.Points[i + 1]
			local d, t = segment(p, Vector2.new(a.X, a.Z), Vector2.new(b.X, b.Z))
			if d < tunnel.Width + 1 then
				local floor = math.round(a.Y + (b.Y - a.Y) * t)
				local v = (d / tunnel.Width) ^ 2 + ((y - floor) / tunnel.Height) ^ 2
				if y >= floor and v <= 1.2 and v <= 1 + (ctx.Hash(x, y, z) - 0.5) * 0.3 then
					return tunnel, tunnel.Mouth == true
				end
			end
		end
	end
	for _, c in CHAMBERS do
		local r = c.Radii
		local dy = (y - c.Floor) / r.Y
		if y >= c.Floor and math.abs(x - c.X) <= r.X + 1 and math.abs(z - c.Z) <= r.Z + 1 then
			local v = ((x - c.X) / r.X) ^ 2 + dy * dy + ((z - c.Z) / r.Z) ^ 2
			if v <= 1 + (ctx.Hash(x, y, z) - 0.5) * 0.3 then
				return c, false
			end
		end
	end
	return nil, false
end

-- Every cave cell, found once: { key -> section } and a list, plus each column's roof
type Caves = {
	Sections: { [string]: Section },
	Mouth: { [string]: boolean },
	Cells: { Vector3 },
	Roof: { [string]: number },
}

local function findCaves(ctx: Context.Context): Caves
	local caves: Caves = { Sections = {}, Mouth = {}, Cells = {}, Roof = {} }
	for x = CAVE_BOX.X1, CAVE_BOX.X2 do
		for z = CAVE_BOX.Z1, CAVE_BOX.Z2 do
			for y = CAVE_BOX.Y1, CAVE_BOX.Y2 do
				local section, mouth = inCave(ctx, x, y, z)
				if section then
					local k = key(x, y, z)
					caves.Sections[k] = section
					if mouth then
						caves.Mouth[k] = true
					end
					table.insert(caves.Cells, Vector3.new(x, y, z))
					local col = `{x},{z}`
					caves.Roof[col] = math.max(caves.Roof[col] or -100, y + 5)
				end
			end
		end
	end
	return caves
end

-- Each column's final height: the peaks, raised over the caves so they keep a thick roof
local function mountainHeights(ctx: Context.Context, caves: Caves): { [string]: number }
	local heights: { [string]: number } = {}
	for x = -60, 60 do
		for z = -8, 86 do
			local h = slope(ctx, x, z)
			if h > 0 then
				heights[`{x},{z}`] = h
			end
		end
	end
	for col, need in caves.Roof do
		local cx, cz = string.match(col, "^(-?%d+),(-?%d+)$")
		local x, z = tonumber(cx) :: number, tonumber(cz) :: number
		for dx = -6, 6 do
			for dz = -6, 6 do
				local k = `{x + dx},{z + dz}`
				local h = heights[k]
				if h then
					heights[k] = math.max(h, math.floor(need - 0.6 * math.sqrt(dx * dx + dz * dz)))
				end
			end
		end
	end
	return heights
end

-- The mine -------------------------------------------------------------------------------------

-- What a wall is made of: rich in its section's ore, otherwise stone with the odd coal or
-- iron (and a little gold down deep)
local function ore(ctx: Context.Context, x: number, y: number, z: number, section: Section?): string
	local roll = ctx.Hash(x + 400, y, z)
	-- Ore comes in clumps, not a scatter: a smooth noise decides where the clumps are
	local clump = ctx.Noise(x * 1.7 + y * 3.1, z * 1.7 - y * 2.3, 3, 70) + 0.5
	if section and section.Ore then
		local share = section.Share or 0.3
		if clump < share * 1.5 and roll < 0.85 then
			return section.Ore
		end
	end
	if section and section.Deep and roll < 0.04 then
		return "GoldOre"
	end
	return if roll < 0.05 then "IronOre" elseif roll < 0.13 then "CoalOre" else "Stone"
end

-- Digs the caves out of the mountain and lines them: two blocks of ore that grows back
-- (a protected floor underfoot), then two of dark stone
local function digMine(ctx: Context.Context, caves: Caves)
	-- Is (x, y, z) well inside the rock, at least four blocks from the mountain's outside?
	local function sealed(x: number, y: number, z: number): boolean
		if not ctx.Inside(x, z, 6) then
			return false
		end
		for _, d in { { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 }, { 3, 3 }, { -3, 3 }, { 3, -3 }, { -3, -3 } } do
			if ctx.HeightAt(x + d[1], z + d[2]) < y + 2 and y >= -1 then
				return false
			end
		end
		return ctx.HeightAt(x, z) >= y + 4
	end

	local cave: { [string]: Section } = {}
	local cells: { Vector3 } = {}
	for _, c in caves.Cells do
		local k = key(c.X, c.Y, c.Z)
		if caves.Mouth[k] or sealed(c.X, c.Y, c.Z) then
			cave[k] = caves.Sections[k]
			table.insert(cells, c)
		end
	end
	for _, c in cells do
		ctx.Carve(c.X, c.Y, c.Z)
	end

	-- The lining, one layer at a time outward from the caves
	local function solidHere(x: number, y: number, z: number): boolean
		return ctx.IslandAt(x, z) ~= nil and y <= ctx.HeightAt(x, z)
	end
	local seen: { [string]: boolean } = {}
	local from: { [string]: Section } = {}
	local frontier = cells
	for layer = 1, 4 do
		local nextLayer: { Vector3 } = {}
		for _, c in frontier do
			local ck = key(c.X, c.Y, c.Z)
			local section = cave[ck] or from[ck]
			for _, d in { Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis } do
				local n = c + d
				local k = key(n.X, n.Y, n.Z)
				if not cave[k] and not seen[k] then
					seen[k] = true
					from[k] = section
					table.insert(nextLayer, n)
					local floor = cave[key(n.X, n.Y + 1, n.Z)] ~= nil and layer == 1
					if not ctx.World.Cells[k] and solidHere(n.X, n.Y, n.Z) then
						if floor then
							local roll = ctx.Hash(n.X, n.Y + 300, n.Z)
							ctx.Set(
								n.X,
								n.Y,
								n.Z,
								if roll < 0.55 then "Stone" elseif roll < 0.8 then "Gravel" else "Cobblestone"
							)
						elseif layer <= 2 and not cave[key(n.X, n.Y + layer, n.Z)] then
							ctx.Node(n.X, n.Y, n.Z, ore(ctx, n.X, n.Y, n.Z, section))
						else
							ctx.Set(n.X, n.Y, n.Z, "DarkStone")
						end
					end
				end
			end
		end
		frontier = nextLayer
	end
end

-- The highest open cell above the floor at (x, z) inside a cave (its ceiling is above it)
local function ceiling(ctx: Context.Context, x: number, floorY: number, z: number): number
	local y = floorY + 1
	while y < floorY + 30 and not ctx.World.Cells[key(x, y + 1, z)] do
		y += 1
	end
	return y
end

-- A lantern hanging from the cave roof over (x, z)
local function hangingLantern(ctx: Context.Context, x: number, floorY: number, z: number, range: number?)
	local top = ceiling(ctx, x, floorY, z)
	Decor.Lantern(ctx.Decor, ctx.Top(x, top, z) - Vector3.new(0, 2.7, 0), true, range or 24)
end

-- The arch: a timber frame where the way in meets the mountain, "THE MINE" hanging in it
local function arch(ctx: Context.Context): number
	local z = 6
	for tz = -4, 30 do
		if ctx.HeightAt(4, tz) >= 8 then
			z = tz
			break
		end
	end
	-- A wide, tall opening, lined with sandstone where it cuts into the rock, then the
	-- timbered tunnel
	local opening: { [string]: boolean } = {}
	for x = -4, 4 do
		for y = 1, 8 do
			for dz = -1, 1 do
				ctx.Carve(x, y, z + dz)
				opening[key(x, y, z + dz)] = true
			end
		end
	end
	for x = -5, 5 do
		for y = 1, 9 do
			for dz = -1, 1 do
				local k = key(x, y, z + dz)
				if not opening[k] and not ctx.World.Cells[k] and y <= ctx.HeightAt(x, z + dz) then
					ctx.Set(x, y, z + dz, "Sandstone")
				end
			end
		end
	end
	for _, x in { -5, 5 } do
		for y = 1, 8 do
			ctx.Set(x, y, z, "Wood")
		end
	end
	for x = -5, 5 do
		ctx.Set(x, 9, z, "DarkPlanks")
	end
	Signs.Hanging(
		ctx.Decor,
		BlockWorld.position(ctx.World, 0, 9, z) - Vector3.new(0, SIZE / 2, SIZE / 2 + 0.4),
		-Vector3.zAxis,
		"THE MINE",
		Signs.Woods.Dark,
		2.2
	)
	for _, x in { -5, 5 } do
		Decor.WallLantern(
			ctx.Decor,
			BlockWorld.position(ctx.World, x, 5, z) - Vector3.new(0, 0, SIZE / 2),
			-Vector3.zAxis
		)
	end
	-- Timber frames along the way in, each with a lantern
	for tz = z + 5, 16, 5 do
		for _, x in { -2, 2 } do
			for y = 1, 3 do
				ctx.Set(x, y, tz, "Wood")
			end
		end
		for x = -2, 2 do
			ctx.Set(x, 4, tz, "DarkPlanks")
		end
		Decor.Lantern(ctx.Decor, ctx.Top(0, 4, tz) - Vector3.new(0, SIZE + 2.7, 0), true, 24)
	end
	Decor.Rails(ctx.Decor, ctx.Top(0, 0, z - 10), ctx.Top(0, 0, 24))
	Decor.Minecart(ctx.Decor, ctx.Top(0, 0, z - 5), Vector3.zAxis, "CoalOre")
	return z
end

-- An open wooden pavilion beside the path: four posts and a slate roof
local function pavilion(ctx: Context.Context, x0: number, z0: number, front: Vector3)
	for _, dx in { -2, 2 } do
		for _, dz in { -2, 2 } do
			for y = 1, 3 do
				ctx.Set(x0 + dx, ctx.HeightAt(x0, z0) + y, z0 + dz, "Wood")
			end
		end
	end
	local site = Build.Site(ctx.World, x0, z0 - 2, front)
	site:Roof(-3, -1, 3, 5, ctx.HeightAt(x0, z0) + 4, "RoofSlate", "DarkPlanks", false)
	Decor.Lantern(ctx.Decor, ctx.Top(x0, ctx.HeightAt(x0, z0) + 3.4, z0), true, 18)
end

-- Lava pouring from the cavern roof into a glowing pool on the floor
local function lavaFall(ctx: Context.Context, x: number, z: number)
	local glow = Color3.fromRGB(255, 120, 30)
	local bottom = ctx.Top(x, 0, z)
	local height = (ceiling(ctx, x, 0, z) + 0.5) * SIZE
	local fall = Decor.Part(
		ctx.Decor,
		"LavaFall",
		Vector3.new(2.2, height, 2.2),
		CFrame.new(bottom + Vector3.new(0, height / 2, 0)),
		glow,
		Enum.Material.Neon
	)
	fall.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 40
	light.Brightness = 2
	light.Parent = fall
end

local function lavaPool(ctx: Context.Context, cx: number, cz: number, r: number)
	for x = cx - r, cx + r do
		for z = cz - r, cz + r do
			if (x - cx) ^ 2 + (z - cz) ^ 2 <= r * r and ctx.World.Cells[key(x, 0, z)] then
				ctx.Set(x, 0, z, "DarkStone")
			end
		end
	end
	local diameter = (2 * r + 1) * SIZE * 0.85
	local pool = Decor.Part(
		ctx.Decor,
		"Lava",
		Vector3.new(0.6, diameter, diameter),
		CFrame.new(ctx.Top(cx, 0, cz) + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(255, 100, 20),
		Enum.Material.Neon
	)
	pool.Shape = Enum.PartType.Cylinder
	local fire = Instance.new("Fire")
	fire.Size = 6
	fire.Heat = 4
	fire.Color = Color3.fromRGB(255, 140, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 60, 20)
	fire.Parent = pool
end

-- Vines and roots hanging from the roof, glowing mushrooms on the floor
local function caveLife(ctx: Context.Context, c: Chamber)
	local rng = ctx.Rng
	local vine, root, crimson = Color3.fromRGB(70, 128, 52), Color3.fromRGB(104, 76, 48), Color3.fromRGB(176, 40, 66)
	for _ = 1, math.floor(c.Radii.X * c.Radii.Z / 6) do
		local x = c.X + rng:NextInteger(-math.floor(c.Radii.X), math.floor(c.Radii.X))
		local z = c.Z + rng:NextInteger(-math.floor(c.Radii.Z), math.floor(c.Radii.Z))
		if not ctx.World.Cells[key(x, c.Floor, z)] and ctx.World.Cells[key(x, c.Floor - 1, z)] then
			local top = ceiling(ctx, x, c.Floor - 1, z)
			if top > c.Floor + 2 then
				local length = SIZE * rng:NextNumber(1.5, math.min(5, top - c.Floor - 1.5))
				local under = ctx.Top(x, top, z)
				local roll = rng:NextNumber()
				local strand = Decor.Part(
					ctx.Decor,
					if roll < 0.55 then "Vine" elseif roll < 0.8 then "Root" else "CrimsonVine",
					Vector3.new(if roll < 0.55 then 1 else 0.45, length, if roll < 0.55 then 0.2 else 0.45),
					CFrame.new(under - Vector3.new(0, length / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
					if roll < 0.55 then vine elseif roll < 0.8 then root else crimson,
					if roll < 0.55 then Enum.Material.LeafyGrass else Enum.Material.Wood
				)
				strand.CanCollide = false
				strand.CastShadow = false
				if roll >= 0.8 then
					Decor.Part(
						ctx.Decor,
						"Bud",
						Vector3.new(1, 1, 1),
						CFrame.new(under - Vector3.new(0, length, 0)),
						Color3.fromRGB(255, 90, 120),
						Enum.Material.Neon
					).CanCollide =
						false
				end
			end
		end
	end
	for _ = 1, math.floor(c.Radii.X * c.Radii.Z / 14) do
		local x = c.X + rng:NextInteger(-math.floor(c.Radii.X) + 2, math.floor(c.Radii.X) - 2)
		local z = c.Z + rng:NextInteger(-math.floor(c.Radii.Z) + 2, math.floor(c.Radii.Z) - 2)
		local y = c.Floor - 1
		if ctx.World.Cells[key(x, y, z)] and not ctx.World.Cells[key(x, y + 1, z)] then
			local top = ctx.Top(x, y, z)
			local stem = Decor.Part(
				ctx.Decor,
				"GlowStem",
				Vector3.new(0.4, 1.4, 0.4),
				CFrame.new(top + Vector3.new(0, 0.7, 0)),
				Color3.fromRGB(220, 220, 200)
			)
			stem.CanCollide = false
			local cap = Decor.Part(
				ctx.Decor,
				"GlowCap",
				Vector3.new(1.4, 0.5, 1.4),
				CFrame.new(top + Vector3.new(0, 1.5, 0)),
				if rng:NextNumber() < 0.5 then Color3.fromRGB(90, 220, 230) else Color3.fromRGB(170, 110, 240),
				Enum.Material.Neon
			)
			cap.CanCollide = false
		end
	end
end

-- Purple crystals glowing round the grotto's walls
local function crystals(ctx: Context.Context, c: Chamber)
	local rng = ctx.Rng
	for i = 1, 16 do
		local angle = i / 16 * math.pi * 2
		local x = math.round(c.X + math.cos(angle) * (c.Radii.X - 1.5))
		local z = math.round(c.Z + math.sin(angle) * (c.Radii.Z - 1.5))
		local base = ctx.Top(x, c.Floor - 1, z)
		for j = 1, 3 do
			local h = rng:NextNumber(1.5, 3.5)
			local shard = Decor.Part(
				ctx.Decor,
				"Crystal",
				Vector3.new(0.7, h, 0.7),
				CFrame.new(base + Vector3.new(rng:NextNumber(-1, 1), h / 2, rng:NextNumber(-1, 1)))
					* CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), rng:NextNumber(-0.4, 0.4)),
				Color3.fromRGB(180, 120, 255),
				Enum.Material.Neon
			)
			shard.CanCollide = false
			if j == 1 and i % 3 == 0 then
				local glow = Instance.new("PointLight")
				glow.Color = Color3.fromRGB(190, 140, 255)
				glow.Range = 18
				glow.Parent = shard
			end
		end
	end
end

-- Lanterns on posts round a chamber's floor
local function chamberLights(ctx: Context.Context, c: Chamber, count: number)
	for i = 0, count - 1 do
		local angle = i / count * math.pi * 2 + 0.4
		local x = math.round(c.X + math.cos(angle) * c.Radii.X * 0.55)
		local z = math.round(c.Z + math.sin(angle) * c.Radii.Z * 0.55)
		if not ctx.World.Cells[key(x, c.Floor, z)] then
			ctx.SetFree(x, c.Floor, z, "Wood")
			ctx.SetFree(x, c.Floor + 1, z, "Wood")
			Decor.Lantern(ctx.Decor, ctx.Top(x, c.Floor + 1, z), false, 28)
		end
	end
end

local function furnishMine(ctx: Context.Context)
	local hall, coal, iron, lava, gold, grotto =
		chamber("Hall"), chamber("Coal"), chamber("Iron"), chamber("Lava"), chamber("Gold"), chamber("Grotto")

	-- The Lantern Hall: lanterns, crates, a cart, and the signpost that points the way
	chamberLights(ctx, hall, 4)
	for _, spot in
		{
			{ X = -5, Z = 20, Block = "Crate" },
			{ X = -6, Z = 20, Block = "Barrel" },
			{ X = 5, Z = 21, Block = "Crate" },
		}
	do
		ctx.SetFree(spot.X, 1, spot.Z, spot.Block)
	end
	Decor.Minecart(ctx.Decor, ctx.Top(3, 0, 24), Vector3.xAxis, "IronOre")
	Common.Arrows(ctx, 3, 19, -Vector3.zAxis, {
		{ Text = "IRON VEIN", Toward = -Vector3.xAxis },
		{ Text = "LAVA CAVERN", Toward = Vector3.zAxis },
		{ Text = "COAL SEAM", Toward = Vector3.xAxis },
	}, Signs.Woods.Dark, 0)

	-- The ore sections: lanterns, carts of their ore, a scaffold against the wall
	chamberLights(ctx, coal, 3)
	chamberLights(ctx, iron, 3)
	Decor.Minecart(ctx.Decor, ctx.Top(coal.X - 3, 0, coal.Z), Vector3.zAxis, "CoalOre")
	Decor.Minecart(ctx.Decor, ctx.Top(iron.X + 3, 0, iron.Z), Vector3.zAxis, "IronOre")

	-- The Lava Cavern: lava from the roof into a pool, life on the floor and roof
	lavaPool(ctx, lava.X - 7, lava.Z + 4, 3)
	lavaFall(ctx, lava.X - 8, lava.Z + 5)
	lavaFall(ctx, lava.X - 5, lava.Z + 7)
	chamberLights(ctx, lava, 5)
	caveLife(ctx, lava)
	Common.Arrows(ctx, lava.X + 3, lava.Z + 5, -Vector3.zAxis, {
		{ Text = "GOLD - MINING 10", Toward = Vector3.new(-1, 0, 1) },
		{ Text = "CRYSTAL GROTTO", Toward = Vector3.new(1, 0, 1) },
	}, Signs.Woods.Dark, 0)

	-- The deep Gold Chamber and the Crystal Grotto
	chamberLights(ctx, gold, 4)
	caveLife(ctx, gold)
	crystals(ctx, grotto)
	caveLife(ctx, grotto)

	-- Lanterns hanging along every tunnel but the way in
	for t = 2, #TUNNELS do
		local points = TUNNELS[t].Points
		for i = 1, #points - 1 do
			local mid = (points[i] + points[i + 1]) / 2
			hangingLantern(ctx, math.round(mid.X), math.round(mid.Y) - 1, math.round(mid.Z), 22)
		end
	end
end

-- The quarry ----------------------------------------------------------------------------------

-- A small stone hut with a slate roof, a door to the east and crates inside
local function hut(ctx: Context.Context, x: number, z: number)
	local site = Build.Site(ctx.World, x, z, Vector3.xAxis)
	site:Fill(-2, 0, 0, 2, 0, 4, "Cobblestone")
	site:Walls(-2, 1, 0, 2, 3, 4, "StoneBricks")
	for _, u in { -2, 2 } do
		for _, v in { 0, 4 } do
			site:Fill(u, 1, v, u, 3, v, "Wood")
		end
	end
	site:Clear(0, 1, 0, 0, 2, 0)
	site:Set(-1, 2, 0, "Glass")
	site:Set(1, 2, 0, "Glass")
	site:Roof(-2, 0, 2, 4, 4, "RoofSlate", "DarkPlanks", false)
	site:Set(-1, 1, 3, "Crate")
	site:Set(1, 1, 3, "Barrel")
	Decor.WallLantern(ctx.Decor, site:Pos(1, 2.6, 0) + site.Front * (SIZE / 2), site.Front)
end

-- A canvas tent with a campfire in front
local function tent(ctx: Context.Context, x: number, z: number)
	local site = Build.Site(ctx.World, x, z, -Vector3.zAxis)
	site:Roof(-1, 0, 1, 3, 1, "WhiteWool", "RedWool", false)
	site:Clear(0, 1, 0, 0, 1, 0)
	local fire = ctx.Top(x, 0, z - 3)
	for i = 0, 2 do
		Decor.Piece(
			ctx.Decor,
			"Wood",
			Vector3.new(0.5, 0.5, 2),
			CFrame.new(fire + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, i * math.pi / 3, 0)
		)
	end
	local flame = Decor.Part(
		ctx.Decor,
		"Fire",
		Vector3.new(0.6, 0.6, 0.6),
		CFrame.new(fire + Vector3.new(0, 0.8, 0)),
		Color3.fromRGB(255, 150, 50),
		Enum.Material.Neon
	)
	flame.CanCollide = false
	local flames = Instance.new("Fire")
	flames.Size = 3
	flames.Heat = 6
	flames.Parent = flame
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 160, 80)
	glow.Range = 18
	glow.Brightness = 1.5
	glow.Parent = flame
	for _, dx in { -2, 2 } do
		ctx.Set(x + dx, 1, z - 3, "Wood")
	end
end

-- Rocky outcrops of stone and ore to mine on the way in
local function outcrop(ctx: Context.Context, x: number, z: number)
	local size = ctx.Rng:NextNumber(1.4, 2.2)
	for dx = -2, 2 do
		for dz = -2, 2 do
			local d = math.sqrt(dx * dx + dz * dz)
			if d <= size then
				for y = 1, math.max(1, math.round(3 * (1 - (d / size) ^ 2 * 0.7))) do
					local roll = ctx.Hash(x + dx, y, z + dz)
					ctx.Node(
						x + dx,
						y,
						z + dz,
						if roll < 0.08 then "IronOre" elseif roll < 0.25 then "CoalOre" else "Stone"
					)
				end
			end
		end
	end
end

local function quarry(ctx: Context.Context)
	hut(ctx, -14, -62)
	tent(ctx, 12, -58)
	Decor.Rails(ctx.Decor, ctx.Top(6, 0, -72), ctx.Top(6, 0, -52))
	Decor.Minecart(ctx.Decor, ctx.Top(6, 0, -66), Vector3.zAxis, "IronOre")
	for _, spot in
		{
			{ X = -5, Z = -58, Block = "Crate" },
			{ X = -6, Z = -58, Block = "Crate" },
			{ X = -5, Z = -57, Block = "Barrel" },
			{ X = 4, Z = -50, Block = "Barrel" },
			{ X = 9, Z = -54, Block = "Crate" },
		}
	do
		ctx.Set(spot.X, 1, spot.Z, spot.Block)
	end
	for _, spot in { { -9, -68 }, { 13, -70 }, { -18, -52 }, { 16, -52 }, { -12, -46 }, { 12, -48 } } do
		if not ctx.NearArrival(spot[1], spot[2], 2) then
			outcrop(ctx, spot[1], spot[2])
		end
	end
	for _, spot in { { -10, -56 }, { 11, -62 }, { -4, -70 }, { 4, -48 } } do
		Decor.Lantern(ctx.Decor, ctx.Top(spot[1], 0, spot[2]), false, 16)
	end
end

-- Ground ------------------------------------------------------------------------------------------

local function quarryColumn(ctx: Context.Context, x: number, z: number): (string, number)
	if not ctx.Inside(x, z, 4) and ctx.IslandAt(x, z) then
		return "Grass", 0
	end
	local roll = ctx.Hash(x, 0, z)
	return if roll < 0.12 then "Cobblestone" elseif roll < 0.25 then "Path" else "Gravel", 0
end

function Mining.Build(ctx: Context.Context)
	ctx.Flatten(-2, -74, 2, -16)
	ctx.Flatten(-15, -20, 15, 2)
	local caves = findCaves(ctx)
	local heights = mountainHeights(ctx, caves)

	-- The mountain's skin: sandstone, with dark cracks running across its upper slopes and
	-- grassy terraces low down
	local function peakColumn(x: number, z: number): (string, number)
		local h = heights[`{x},{z}`]
		if not h then
			local foot = math.clamp(math.round(1 + 2 * ctx.Noise(x, z, 12, 22)), 0, 2)
			return if ctx.Hash(x, 5, z) < 0.15 then "Gravel" else "Grass", foot
		end
		if h >= 10 and math.abs(ctx.Noise(x, z, 11, 71)) < 0.025 then
			return "DarkStone", h
		end
		local steep = 0
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			steep = math.max(steep, h - (heights[`{x + d[1]},{z + d[2]}`] or 0))
		end
		if h <= 5 and steep <= 1 then
			return "Grass", h
		end
		return if ctx.Hash(x, 6, z) < 0.96 then "Sandstone" else "Stone", h
	end

	ctx.Island({
		Name = "Quarry",
		X = QUARRY.X,
		Z = QUARRY.Z,
		Radius = QUARRY.R,
		Column = function(x, z)
			return quarryColumn(ctx, x, z)
		end,
	})
	local peaks = ctx.Island({
		Name = "Mountain",
		X = PEAKS.X,
		Z = PEAKS.Z,
		Radius = PEAKS.R,
		Column = peakColumn,
		Depth = 40,
		Fill = function(x, y, z, depth)
			-- Sandstone right under the mountain's skin, a little soil under the grass
			if heights[`{x},{z}`] then
				return if depth == 1 and ctx.World.Cells[key(x, y + depth, z)] == "Grass" then "Dirt" else "Sandstone"
			end
			return nil
		end,
	})
	for _, spot in { { -36, 4, -70, 3 }, { 40, -4, -60, 3 }, { -72, 10, 20, 4 }, { 72, 6, 40, 4 }, { -50, -8, 86, 3 } } do
		ctx.Islet(spot[1], spot[2], spot[3], spot[4], "Stone")
	end

	digMine(ctx, caves)
	local mouthZ = arch(ctx)
	furnishMine(ctx)
	quarry(ctx)

	-- A stone bridge over to the mountain, a dirt path up to the arch between two pavilions
	ctx.Bridge(0, -46, 0, -20, "StoneBricks")
	Common.Path(ctx, 0, -72, 0, -46, 3, Common.StonePath)
	Common.Path(ctx, 0, -20, 0, mouthZ - 1, 3)
	pavilion(ctx, -11, mouthZ - 9, -Vector3.zAxis)
	pavilion(ctx, 11, mouthZ - 9, -Vector3.zAxis)
	ctx.SetFree(-8, ctx.HeightAt(-8, mouthZ - 7) + 1, mouthZ - 7, "Crate")
	ctx.SetFree(-7, ctx.HeightAt(-7, mouthZ - 7) + 1, mouthZ - 7, "Barrel")
	Decor.Minecart(ctx.Decor, ctx.Top(8, ctx.HeightAt(8, mouthZ - 7), mouthZ - 7), Vector3.zAxis, "IronOre")
	Common.Arrows(ctx, 4, -50, -Vector3.xAxis, { { Text = "THE MINE", Toward = Vector3.zAxis } })

	-- Grassy terraces at the mountain's foot: boulders, oaks, vines down the cliffs
	for _, spot in { { -16, -8 }, { 14, -6 }, { -26, 6 }, { 26, 4 }, { -6, -14 }, { 8, -14 } } do
		if ctx.Inside(spot[1], spot[2], 4) then
			Common.Boulder(ctx, spot[1], spot[2], 3, { "Sandstone", "Stone", "Sandstone", "MossyCobblestone" })
		end
	end
	Common.Forest(ctx, peaks, 7, 4, function(x, z)
		return heights[`{x},{z}`] ~= nil or math.abs(x) <= 15 and z < mouthZ or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		Trees.Oak(x, h, z, ctx.Rng:NextInteger(4, 5), ctx.SetFree)
	end)
	Common.CliffVines(ctx, peaks, 0.3, function(x, z)
		-- Keep the arch and its sign clear
		return math.abs(x) <= 7 and math.abs(z - mouthZ) <= 3
	end)
	Common.Scatter(ctx, peaks, 0.05, 0.01, { Color3.fromRGB(242, 212, 64), Color3.fromRGB(240, 240, 240) })
end

return Mining
