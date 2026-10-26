--!strict
-- The Woodcutting World: four floating islands of forest joined by plank bridges, each
-- zone with its own tree (every log and leaf a node that grows back; chopping a zone's
-- trees needs its Woodcutting level, see BlockService):
--   Oak Woods (arrival, south)            oaks and big old oaks on rolling hills, a river
--                                         that pours off both edges of the island, and a
--                                         lumber camp by the arrival square
--   Birch Grove (west, Woodcutting 10)    slim white birches in a flower meadow round a
--                                         lily pond with a dock and benches
--   Snowy Pines (north, Woodcutting 20)   tall spruces on snowy hills, a frozen lake, a
--                                         trapper's cabin with a smoking chimney, falling snow
--   Cherry Hills (east, Woodcutting 30)   pink cherry trees on soft hills, a koi pond with a
--                                         little red bridge, stone lanterns, a pavilion and
--                                         drifting petals
-- Main paths run north from the arrival square to the Snowy Pines bridge and across the
-- Oak Woods to the Birch and Cherry bridges; each zone has a gateway at its bridge end.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Build = require(script.Parent.Parent.Util.Build)
local Decor = require(script.Parent.Parent.Util.Decor)
local Trees = require(script.Parent.Parent.Util.Trees)
local Common = require(script.Parent.Common)
local Context = require(script.Parent.Context)

local SIZE = Blocks.Size

local Woodcutting = {}

Woodcutting.SouthZ = -78
Woodcutting.Seed = 22
Woodcutting.Haze = 0.2

local OAK = { X = 0, Z = -44, R = 40 }
local BIRCH = { X = -84, Z = -36, R = 32 }
local PINES = { X = 0, Z = 44, R = 34 }
local CHERRY = { X = 84, Z = -36, R = 32 }
local CROSS_Z = -36 -- the path across the Oak Woods to the Birch and Cherry bridges
-- Ponds and buildings in the zones (kept flat)
local BIRCH_POND = { BIRCH.X - 4, BIRCH.Z + 12 }
local PINES_LAKE = { PINES.X + 10, PINES.Z + 8 }
local PINES_CABIN = { PINES.X - 14, PINES.Z + 6 } -- its door; it extends north
local CHERRY_POND = { CHERRY.X + 6, CHERRY.Z - 8 }
local PAVILION = { CHERRY.X - 6, CHERRY.Z + 10 }

local MEADOW = {
	Color3.fromRGB(222, 62, 52),
	Color3.fromRGB(242, 212, 64),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(150, 110, 220),
}
local BLOSSOM = { Color3.fromRGB(250, 186, 214), Color3.fromRGB(240, 240, 240), Color3.fromRGB(236, 120, 170) }

-- The lumber camp, by the arrival square (kept clear of trees)
local CAMP = { X1 = 9, X2 = 26, Z1 = -76, Z2 = -57 }

local function inCamp(x: number, z: number, margin: number): boolean
	return x >= CAMP.X1 - margin and x <= CAMP.X2 + margin and z >= CAMP.Z1 - margin and z <= CAMP.Z2 + margin
end

-- The Oak Woods river: its middle at each x
local function riverZ(x: number): number
	return -52 + 4 * math.sin(x * 0.1)
end

local function onPaths(x: number, z: number, margin: number): boolean
	return (math.abs(x) <= 1 + margin and z > -70 and z < 0)
		or (math.abs(z - CROSS_Z) <= 1 + margin and math.abs(x) < 40)
end

-- Ground ---------------------------------------------------------------------------

local function oakColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local river = math.abs(z - riverZ(x))
	if river <= 1.5 then
		return "Sand", -1
	elseif river <= 2.6 then
		return "Sand", 0
	end
	local h = math.round(2.2 + 4 * ctx.Noise(x, z, 22, 1) + 1.6 * ctx.Noise(x, z, 9, 2))
	h = math.clamp(h, 0, 5)
	if inCamp(x, z, 1) or river <= 4 then
		h = 0
	elseif inCamp(x, z, 3) or river <= 6 then
		h = math.min(h, 1)
	end
	return if ctx.Noise(x, z, 6, 30) > 0.4 then "FlowerGrass" else "Grass", h
end

local function birchColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1 + 2.4 * ctx.Noise(x, z, 16, 3)), 0, 3)
	return if ctx.Noise(x, z, 5, 31) > 0.3 then "FlowerGrass" else "Grass", h
end

local function pinesColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.round(2.5 + 6 * ctx.Noise(x, z, 18, 4) + 2 * ctx.Noise(x, z, 7, 5))
	h = math.clamp(h, 0, 8)
	return if h >= 5 then "Snow" else "SnowyGrass", h
end

local function cherryColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1.6 + 4 * ctx.Noise(x, z, 14, 6)), 0, 5)
	return if ctx.Noise(x, z, 6, 32) > 0.36 then "FlowerGrass" else "Grass", h
end

-- Oak Woods ----------------------------------------------------------------------------

-- The river: water over its sandy bed, a plank bridge where the path crosses, and a
-- waterfall where it spills off each side of the island
local function river(ctx: Context.Context, island: Context.Island)
	local ends: { number } = {}
	for x = OAK.X - OAK.R - 10, OAK.X + OAK.R + 10 do
		local z = riverZ(x)
		local zc = math.round(z)
		if ctx.IslandAt(x, zc) == island and ctx.World.Cells[`{x},-1,{zc}`] == "Sand" then
			Decor.Water(
				ctx.Decor,
				ctx.Top(x, -1, zc) + Vector3.new(0, SIZE * 0.8, (z - zc) * SIZE),
				Vector2.new(SIZE, 3.2 * SIZE),
				SIZE * 0.85
			)
			ends[1] = math.min(ends[1] or x, x)
			ends[2] = math.max(ends[2] or x, x)
		end
	end
	for i, x in ends do
		local out = if i == 1 then -Vector3.xAxis else Vector3.xAxis
		local lip = ctx.Top(x, -1, math.round(riverZ(x))) + Vector3.new(0, SIZE * 0.8, 0) + out * (SIZE / 2)
		Decor.Waterfall(ctx.Decor, lip, out, 3 * SIZE, 90)
	end
	-- The bridge where the main path crosses, with rails and a lantern at each end
	local z0 = math.round(riverZ(0))
	for x = -1, 1 do
		for z = z0 - 3, z0 + 3 do
			ctx.Set(x, 0, z, "DarkPlanks")
		end
	end
	for _, x in { -1.6, 1.6 } do
		Decor.Fence(
			ctx.Decor,
			ctx.Top(0, 0, z0 - 3) + Vector3.new(x * SIZE, 0, 0),
			ctx.Top(0, 0, z0 + 3) + Vector3.new(x * SIZE, 0, 0),
			"DarkPlanks"
		)
	end
end

-- A log cabin: log walls, a slate roof, a chimney, a bed and crates inside
local function cabin(ctx: Context.Context, ox: number, oz: number, logs: string, front: Vector3)
	local site = Build.Site(ctx.World, ox, oz, front)
	site:Fill(-3, 0, 0, 3, 0, 6, "DarkPlanks")
	site:Walls(-3, 1, 0, 3, 3, 6, logs)
	site:Walls(-3, 4, 0, 3, 4, 6, "DarkPlanks")
	site:Clear(0, 1, 0, 0, 2, 0)
	for _, u in { -2, 2 } do
		site:Set(u, 2, 0, "Glass")
	end
	site:Fill(-3, 2, 2, -3, 2, 4, "Glass")
	site:Roof(-3, 0, 3, 6, 5, "RoofSlate", "DarkPlanks", false)
	site:Fill(2, 5, 5, 2, 9, 5, "Cobblestone")
	Decor.Smoke(ctx.Decor, site:Pos(2, 9.6, 5))
	site:Fill(-2, 1, 4, -2, 1, 5, "RedWool")
	site:Set(2, 1, 3, "Crate")
	site:Set(2, 1, 4, "Barrel")
	Decor.Lantern(ctx.Decor, site:Pos(2, 1.5, 3), false, 14)
	Decor.WallLantern(ctx.Decor, site:Pos(1.3, 2.6, 0) + site.Front * (SIZE / 2), site.Front)
end

-- The sawmill: an open shed over a saw table, with a log on it and a spinning blade
local function sawmill(ctx: Context.Context, x0: number, z0: number)
	for _, dx in { -2, 2 } do
		for _, dz in { -1, 2 } do
			for y = 1, 3 do
				ctx.Set(x0 + dx, y, z0 + dz, "Wood")
			end
		end
	end
	for dx = -3, 3 do
		for dz = -2, 3 do
			ctx.Set(x0 + dx, 4, z0 + dz, "DarkPlanks")
		end
	end
	for dx = -1, 1 do
		ctx.Set(x0 + dx, 1, z0, "Planks")
	end
	ctx.Set(x0 - 1, 2, z0, "Wood")
	local blade = Instance.new("Model")
	blade.Name = "SawBlade"
	local centre = ctx.Top(x0, 1, z0) + Vector3.new(0.6, 0.9, 0)
	-- A cylinder's round faces are on its X axis: turn that onto Z, the axis it spins round
	local disc = Decor.Part(
		blade,
		"Blade",
		Vector3.new(0.15, 2.4, 2.4),
		CFrame.new(centre) * CFrame.Angles(0, math.rad(90), 0),
		Color3.fromRGB(176, 180, 188),
		Enum.Material.Metal
	)
	disc.Shape = Enum.PartType.Cylinder
	blade.WorldPivot = CFrame.new(centre)
	blade.Parent = ctx.Decor
	Decor.Spin(blade, 240)
	-- Log piles beside it
	for dz = -1, 2 do
		for y = 1, 2 do
			ctx.Set(x0 + 5, y, z0 + dz, "Wood")
		end
		ctx.Set(x0 + 6, 1, z0 + dz, "Wood")
	end
end

-- A campfire ringed with log seats
local function campfire(ctx: Context.Context, x: number, z: number)
	local fire = ctx.Top(x, 0, z)
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
	glow.Range = 20
	glow.Brightness = 1.5
	glow.Parent = flame
	for _, d in { { -2, 0 }, { 2, 0 }, { 0, -2 } } do
		ctx.Set(x + d[1], 1, z + d[2], "Wood")
	end
end

local function oakWoods(ctx: Context.Context, island: Context.Island)
	river(ctx, island)
	cabin(ctx, 16, -61, "Wood", -Vector3.xAxis)
	sawmill(ctx, 13, -69)
	campfire(ctx, 22, -66)
	Common.Path(ctx, 2, -61, 15, -61, 1)
	Common.Forest(ctx, island, 6, 4, function(x, z)
		return ctx.NearArrival(x, z, 4)
			or inCamp(x, z, 3)
			or math.abs(z - riverZ(x)) <= 4
			or onPaths(x, z, 2)
			or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		if ctx.Rng:NextNumber() < 0.3 then
			Trees.BigOak(x, h, z, ctx.Rng:NextInteger(6, 7), ctx.Node)
		else
			Trees.Oak(x, h, z, ctx.Rng:NextInteger(4, 6), ctx.Node)
		end
		if ctx.Rng:NextNumber() < 0.2 then
			local mx, mz = x + ctx.Rng:NextInteger(-1, 1), z + (if ctx.Rng:NextNumber() < 0.5 then -1 else 1)
			Decor.Mushroom(ctx.Decor, ctx.Top(mx, ctx.HeightAt(mx, mz), mz), ctx.Rng:NextNumber() < 0.5)
		end
	end)
	-- Fallen logs between the trees
	for _, spot in { { -22, -30 }, { 18, -20 }, { -14, -14 }, { 28, -44 } } do
		local x, z = spot[1], spot[2]
		if ctx.Inside(x, z, 3) then
			local h = ctx.HeightAt(x, z)
			for dx = 0, 3 do
				ctx.SetFree(x + dx, h + 1, z, "Wood")
			end
			Decor.Mushroom(ctx.Decor, ctx.Top(x + 1, h + 1, z), false)
		end
	end
	for z = -62, -10, 8 do
		if math.abs(z - riverZ(2)) > 4 then
			Common.Lamp(ctx, 2, z)
		end
	end
	for _, x in { -28, -14, 14, 28 } do
		Common.Lamp(ctx, x, CROSS_Z + 2)
	end
	Common.Scatter(ctx, island, 0.07, 0.02, MEADOW)
end

-- Birch Grove ----------------------------------------------------------------------------

local function birchGrove(ctx: Context.Context, island: Context.Island)
	local px, pz = BIRCH_POND[1], BIRCH_POND[2]
	local water = Common.Pond(ctx, px, pz, 5.5, "Sand")
	for i = 1, 7 do
		local angle = i * 0.9
		Decor.LilyPad(
			ctx.Decor,
			Vector3.new(water.Position.X, water.Position.Y + water.Size.Y / 2, water.Position.Z)
				+ Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8),
			if i % 3 == 0 then Color3.fromRGB(250, 200, 220) else nil
		)
	end
	-- A little dock out into the pond, and benches on the shore
	for x = px + 2, px + 6 do
		ctx.Set(x, 0, pz, "DarkPlanks")
	end
	Decor.Lantern(ctx.Decor, ctx.Top(px + 6, 0, pz + 1), false, 14)
	Decor.Bench(ctx.Decor, ctx.Top(px, ctx.HeightAt(px, pz - 8), pz - 8), Vector3.zAxis)
	Decor.Bench(ctx.Decor, ctx.Top(px - 8, ctx.HeightAt(px - 8, pz), pz), Vector3.xAxis)
	-- The path in from the gate to the pond
	Common.Path(ctx, BIRCH.X + 22, CROSS_Z, BIRCH.X + 2, CROSS_Z, 3)
	Common.Path(ctx, BIRCH.X + 2, CROSS_Z, BIRCH.X + 2, pz - 7, 3)
	Common.Lamp(ctx, BIRCH.X + 12, CROSS_Z + 2)
	Common.Lamp(ctx, BIRCH.X, CROSS_Z - 2)
	Common.Forest(ctx, island, 5, 3, function(x, z)
		return math.sqrt((x - px) ^ 2 + (z - pz) ^ 2) < 10
			or (math.abs(z - CROSS_Z) <= 3 and x > BIRCH.X)
			or (math.abs(x - BIRCH.X - 2) <= 3 and z > CROSS_Z and z < pz)
			or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		Trees.Birch(x, h, z, ctx.Rng:NextInteger(5, 7), ctx.Node)
	end)
	for _, spot in { { BIRCH.X - 14, BIRCH.Z - 12 }, { BIRCH.X + 10, BIRCH.Z + 14 } } do
		local x, z = spot[1], spot[2]
		if ctx.Inside(x, z, 3) then
			local h = ctx.HeightAt(x, z)
			for dz = 0, 3 do
				ctx.SetFree(x, h + 1, z + dz, "BirchWood")
			end
			Decor.Mushroom(ctx.Decor, ctx.Top(x, h + 1, z + 1), true)
		end
	end
	Common.Scatter(ctx, island, 0.06, 0.07, MEADOW)
end

-- Snowy Pines ----------------------------------------------------------------------------

local function snowyPines(ctx: Context.Context, island: Context.Island)
	-- The frozen lake: ice over dark water
	local lx, lz = PINES_LAKE[1], PINES_LAKE[2]
	local water = Common.Pond(ctx, lx, lz, 6.5, "Snow", "Gravel")
	water.Transparency = 0.5
	local ice = Decor.Part(
		ctx.Decor,
		"Ice",
		Vector3.new(water.Size.X, 0.4, water.Size.Z),
		water.CFrame + Vector3.new(0, water.Size.Y / 2 + 0.2, 0),
		Color3.fromRGB(196, 226, 246),
		Enum.Material.Ice
	)
	ice.Transparency = 0.25
	-- The trapper's cabin, built of spruce, west of the path, its door facing south
	cabin(ctx, PINES_CABIN[1], PINES_CABIN[2], "SpruceWood", -Vector3.zAxis)
	Common.Path(ctx, PINES.X, PINES.Z - 30, PINES.X, PINES.Z + 2, 3)
	Common.Path(ctx, PINES.X, PINES.Z + 2, PINES_CABIN[1], PINES.Z + 2, 3)
	Common.Path(ctx, PINES_CABIN[1], PINES.Z + 2, PINES_CABIN[1], PINES_CABIN[2] - 1, 1)
	for _, spot in { { PINES.X + 2, PINES.Z - 22 }, { PINES.X + 2, PINES.Z - 8 }, { PINES.X - 8, PINES.Z + 4 } } do
		Common.Lamp(ctx, spot[1], spot[2])
	end
	-- Snowy boulders
	for _, spot in { { PINES.X - 20, PINES.Z - 10 }, { PINES.X + 22, PINES.Z - 6 }, { PINES.X + 4, PINES.Z + 24 } } do
		local x, z = spot[1], spot[2]
		if ctx.Inside(x, z, 3) then
			local h = ctx.HeightAt(x, z)
			for dx = 0, 1 do
				for dz = 0, 1 do
					ctx.SetFree(x + dx, h + 1, z + dz, "Stone")
				end
			end
			ctx.SetFree(x, h + 2, z, "Snow")
			ctx.SetFree(x + 1, h + 2, z, "Stone")
		end
	end
	Common.Forest(ctx, island, 7, 3, function(x, z)
		return math.sqrt((x - lx) ^ 2 + (z - lz) ^ 2) < 10
			or (math.abs(x - PINES.X) <= 4 and z < PINES.Z + 4)
			or (math.abs(z - PINES.Z - 2) <= 3 and x < PINES.X and x > PINES_CABIN[1] - 4)
			or (math.abs(x - PINES_CABIN[1]) <= 7 and z > PINES.Z and z < PINES_CABIN[2] + 10)
			or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		Trees.Spruce(x, h, z, ctx.Rng:NextInteger(8, 11), ctx.Node)
	end)
	Common.Scatter(ctx, island, 0.03, 0, {})
	Decor.Falling(ctx.Decor, ctx.Top(PINES.X, 22, PINES.Z), Vector2.new(PINES.R * 2 * SIZE, PINES.R * 2 * SIZE), "Snow")
end

-- Cherry Hills -------------------------------------------------------------------------------

-- An open pavilion: four posts, a red tiled roof, benches inside
local function pavilion(ctx: Context.Context, x0: number, z0: number)
	for dx = -2, 2 do
		for dz = -2, 2 do
			ctx.Set(x0 + dx, 0, z0 + dz, "SmoothStone")
		end
	end
	for _, dx in { -2, 2 } do
		for _, dz in { -2, 2 } do
			for y = 1, 3 do
				ctx.Set(x0 + dx, y, z0 + dz, "CherryWood")
			end
		end
	end
	local site = Build.Site(ctx.World, x0, z0 - 2, -Vector3.zAxis)
	site:Roof(-3, -1, 3, 5, 4, "RoofRed", "CherryWood", false)
	Decor.Bench(ctx.Decor, ctx.Top(x0, 0, z0 - 1), Vector3.zAxis, 3)
	Decor.Bench(ctx.Decor, ctx.Top(x0, 0, z0 + 1), -Vector3.zAxis, 3)
	Decor.Lantern(ctx.Decor, ctx.Top(x0, 3.4, z0), true, 18)
end

local function cherryHills(ctx: Context.Context, island: Context.Island)
	-- The koi pond, with a little red-railed bridge over it
	local px, pz = CHERRY_POND[1], CHERRY_POND[2]
	local water = Common.Pond(ctx, px, pz, 6, "Gravel")
	local surface = water.Position + Vector3.new(0, water.Size.Y / 2, 0)
	for i = 1, 5 do
		Decor.LilyPad(
			ctx.Decor,
			surface + Vector3.new(math.cos(i * 1.2) * 9, 0, math.sin(i * 1.2) * 9),
			BLOSSOM[i % 3 + 1]
		)
	end
	for i = 1, 6 do
		local fish = Decor.Part(
			ctx.Decor,
			"Koi",
			Vector3.new(0.5, 0.25, 1.2),
			CFrame.new(surface + Vector3.new(math.cos(i * 2.3) * 6, -0.6, math.sin(i * 2.3) * 6))
				* CFrame.Angles(0, i * 1.1, 0),
			if i % 2 == 0 then Color3.fromRGB(246, 120, 40) else Color3.fromRGB(245, 240, 236)
		)
		fish.CanCollide = false
	end
	for z = pz - 6, pz + 6 do
		ctx.Set(px, 0, z, "DarkPlanks")
	end
	for _, dx in { -0.4, 0.4 } do
		Decor.Fence(
			ctx.Decor,
			ctx.Top(px, 0, pz - 5) + Vector3.new(dx * SIZE, 0, 0),
			ctx.Top(px, 0, pz + 5) + Vector3.new(dx * SIZE, 0, 0),
			"RedWool"
		)
	end
	pavilion(ctx, PAVILION[1], PAVILION[2])
	-- Paths from the gate: to the pavilion and over the pond's bridge
	Common.Path(ctx, CHERRY.X - 22, CROSS_Z, CHERRY.X - 6, CROSS_Z, 3)
	Common.Path(ctx, CHERRY.X - 6, CROSS_Z, CHERRY.X - 6, CHERRY.Z + 7, 3)
	Common.Path(ctx, CHERRY.X - 6, CROSS_Z, px - 2, CROSS_Z, 1)
	for _, spot in
		{
			{ CHERRY.X - 16, CROSS_Z + 2 },
			{ CHERRY.X - 8, CROSS_Z - 2 },
			{ CHERRY.X - 4, CHERRY.Z + 2 },
			{ px + 2, pz + 8 },
			{ px - 2, pz - 8 },
		}
	do
		local x, z = spot[1], spot[2]
		if ctx.Inside(x, z, 2) then
			Decor.StoneLantern(ctx.Decor, ctx.Top(x, ctx.HeightAt(x, z), z))
		end
	end
	Common.Forest(ctx, island, 7, 4, function(x, z)
		return math.sqrt((x - px) ^ 2 + (z - pz) ^ 2) < 11
			or (math.abs(z - CROSS_Z) <= 4 and x < CHERRY.X)
			or (math.abs(x - CHERRY.X + 6) <= 6 and z > CROSS_Z - 2 and z < CHERRY.Z + 16)
			or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		Trees.Cherry(x, h, z, ctx.Rng:NextInteger(4, 5), ctx.Node)
	end)
	Common.Scatter(ctx, island, 0.05, 0.05, BLOSSOM)
	Decor.Falling(
		ctx.Decor,
		ctx.Top(CHERRY.X, 14, CHERRY.Z),
		Vector2.new(CHERRY.R * 2 * SIZE, CHERRY.R * 2 * SIZE),
		"Petals"
	)
end

-- The world -----------------------------------------------------------------------------

function Woodcutting.Build(ctx: Context.Context)
	-- Main paths, the camp and the bridge ends stay flat
	ctx.Flatten(-2, -70, 2, -6)
	ctx.Flatten(-34, CROSS_Z - 2, 34, CROSS_Z + 2)
	ctx.Flatten(-66, CROSS_Z - 2, -30, CROSS_Z + 2)
	ctx.Flatten(30, CROSS_Z - 2, 66, CROSS_Z + 2)
	ctx.Flatten(-2, -14, 2, 24)
	ctx.Flatten(CAMP.X1, CAMP.Z1, CAMP.X2, CAMP.Z2)
	ctx.Flatten(-2, 8, 2, PINES.Z + 4)
	ctx.Flatten(PINES_CABIN[1] - 4, PINES.Z, 2, PINES_CABIN[2] + 7)
	for _, spot in { BIRCH_POND, PINES_LAKE, CHERRY_POND, PAVILION } do
		ctx.Flatten(spot[1] - 9, spot[2] - 9, spot[1] + 9, spot[2] + 9)
	end

	local oak = ctx.Island({
		Name = "Oak Woods",
		X = OAK.X,
		Z = OAK.Z,
		Radius = OAK.R,
		Column = function(x, z)
			return oakColumn(ctx, x, z)
		end,
	})
	local birch = ctx.Island({
		Name = "Birch Grove",
		X = BIRCH.X,
		Z = BIRCH.Z,
		Radius = BIRCH.R,
		Column = function(x, z)
			return birchColumn(ctx, x, z)
		end,
	})
	local pines = ctx.Island({
		Name = "Snowy Pines",
		X = PINES.X,
		Z = PINES.Z,
		Radius = PINES.R,
		Column = function(x, z)
			return pinesColumn(ctx, x, z)
		end,
		Depth = 26,
	})
	local cherry = ctx.Island({
		Name = "Cherry Hills",
		X = CHERRY.X,
		Z = CHERRY.Z,
		Radius = CHERRY.R,
		Column = function(x, z)
			return cherryColumn(ctx, x, z)
		end,
	})
	-- Little rocks floating round the islands
	for _, spot in
		{
			{ -40, 6, -86, 3 },
			{ 46, -4, -84, 3 },
			{ -48, 10, 16, 4 },
			{ 50, 8, 20, 4 },
			{ -120, -2, -8, 3 },
			{ 120, 4, -62, 3 },
			{ 34, 14, 82, 3 },
			{ -38, -6, 76, 3 },
		}
	do
		ctx.Islet(spot[1], spot[2], spot[3], spot[4])
		if spot[4] >= 4 then
			Trees.Oak(spot[1], spot[2], spot[3], 4, ctx.SetFree)
		end
	end

	Common.Path(ctx, 0, -68, 0, -10, 3)
	Common.Path(ctx, -32, CROSS_Z, 32, CROSS_Z, 3)
	ctx.Bridge(-62, CROSS_Z, -32, CROSS_Z)
	ctx.Bridge(32, CROSS_Z, 62, CROSS_Z)
	ctx.Bridge(0, -12, 0, 20)
	Common.ZoneGate(ctx, BIRCH.X + 21, CROSS_Z, Vector3.xAxis, "BIRCH GROVE", "WOODCUTTING 10")
	Common.ZoneGate(ctx, CHERRY.X - 21, CROSS_Z, -Vector3.xAxis, "CHERRY HILLS", "WOODCUTTING 30")
	Common.ZoneGate(ctx, PINES.X, PINES.Z - 23, -Vector3.zAxis, "SNOWY PINES", "WOODCUTTING 20")

	oakWoods(ctx, oak)
	birchGrove(ctx, birch)
	snowyPines(ctx, pines)
	cherryHills(ctx, cherry)
end

return Woodcutting
