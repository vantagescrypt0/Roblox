--!strict
-- The Woodcutting World: six big floating islands of forest joined by plank bridges, each
-- zone with its own tree (every log and leaf a node that grows back; chopping a zone's
-- trees needs its Woodcutting level, see BlockService):
--   Oak Woods (arrival, south)            oaks and big old oaks on rolling hills, a river
--                                         that pours off both edges of the island, rocky
--                                         hills and tall stone spires, and a lumber camp
--                                         by the arrival square
--   Birch Grove (west, Woodcutting 10)    slim white birches in a flower meadow round two
--                                         lily ponds with docks and benches
--   Snowy Pines (north, Woodcutting 20)   tall spruces on snowy hills, a frozen lake,
--                                         trappers' cabins with smoking chimneys, snowy
--                                         spires, falling snow
--   Cherry Hills (east, Woodcutting 30)   pink cherry trees on soft hills, a koi pond with a
--                                         red bridge, stone lanterns, two pavilions,
--                                         drifting petals
-- The second ring, each beyond a zone of the first ([[Woodcutting Phase Plan]]):
--   Maple Ridge (north of Birch, 40)      red and orange hills, a sugar shack with sap buckets
--                                         on the trunks, a pond, stone spires, falling leaves
--   Redwood Giants (north of Cherry, 55)  trees 4-5x taller than oak, a fallen giant the trail
--                                         runs through, a ranger's cabin, and a stair round the
--                                         oldest tree up to a lookout
-- That's all the trees here: Mangrove and Starwood are late-game, grown only on your own
-- island from saplings (loot crates and Warzone chests).
-- Stone paths run north from the arrival square to the Snowy Pines bridge and across the
-- Oak Woods to the Birch and Cherry bridges; a signpost at the crossroads points the way
-- and each zone has a rough sign in its own wood where it begins. Patches of coarse dirt,
-- boulders, giant red mushrooms, fallen logs and vines on the cliffs are dotted about
-- (from the Skybounds woods, 02 Research/References/Skybounds/woodcutting).

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

local Woodcutting = {}

Woodcutting.SouthZ = -158
Woodcutting.Seed = 22
Woodcutting.Haze = 0.2

local OAK = { X = 0, Z = -88, R = 80 }
local BIRCH = { X = -168, Z = -72, R = 64 }
local PINES = { X = 0, Z = 88, R = 68 }
local CHERRY = { X = 168, Z = -72, R = 64 }
local MAPLE = { X = -184, Z = 104, R = 74 }
local REDWOOD = { X = 192, Z = 116, R = 88 }
local CROSS_Z = -72 -- the path across the Oak Woods to the Birch and Cherry bridges
local MAPLE_ROAD = -160 -- the road north through Birch Grove and up Maple Ridge
local REDWOOD_ROAD = 160 -- the road north through Cherry Hills and among the Giants
local REDWOOD_TRAIL = 116 -- the trail east from it to the lookout
-- Rocky hills in the Oak Woods: centre, radius, height
local HILLS =
	{ { X = -36, Z = -44, R = 13, H = 16 }, { X = 42, Z = -40, R = 11, H = 13 }, { X = -52, Z = -132, R = 9, H = 10 } }
-- Ponds, lakes and buildings in the zones (kept flat): centre and radius
local BIRCH_PONDS = { { X = -184, Z = -46, R = 9 }, { X = -198, Z = -102, R = 7 } }
local PINES_LAKE = { X = 22, Z = 108, R = 13 }
local PINES_CABINS = { { X = -26, Z = 92 }, { X = -34, Z = 128 } } -- doors; they extend north
local CHERRY_POND = { X = 190, Z = -98, R = 12 }
local PAVILIONS = { { 148, -42 }, { 210, -48 } }
local MAPLE_POND = { X = -216, Z = 96, R = 11 }
local MAPLE_LAKE_Z = 96 -- the path from the road to the pond
local LOOKOUT = { X = 232, Z = 115 } -- the oldest redwood, with the stair round it

local MEADOW = {
	Color3.fromRGB(222, 62, 52),
	Color3.fromRGB(242, 212, 64),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(150, 110, 220),
}
local BLOSSOM = { Color3.fromRGB(250, 186, 214), Color3.fromRGB(240, 240, 240), Color3.fromRGB(236, 120, 170) }

-- The lumber camp, by the arrival square (kept clear of trees)
local CAMP = { X1 = 14, X2 = 50, Z1 = -160, Z2 = -128 }

local function inCamp(x: number, z: number, margin: number): boolean
	return x >= CAMP.X1 - margin and x <= CAMP.X2 + margin and z >= CAMP.Z1 - margin and z <= CAMP.Z2 + margin
end

-- The Oak Woods river: its middle at each x
local function riverZ(x: number): number
	return -112 + 6 * math.sin(x * 0.05)
end

local function onPaths(x: number, z: number, margin: number): boolean
	return (math.abs(x) <= 2 + margin and z > -150 and z < -8)
		or (math.abs(z - CROSS_Z) <= 2 + margin and math.abs(x) < 80)
end

local function near(x: number, z: number, spot: { X: number, Z: number }, r: number): boolean
	return (x - spot.X) ^ 2 + (z - spot.Z) ^ 2 <= r * r
end

-- Random spots over an island, `margin` in from its rim, at least `gap` apart, where `ok`
-- says yes
local function spots(
	ctx: Context.Context,
	island: Context.Island,
	count: number,
	margin: number,
	gap: number,
	ok: (x: number, z: number) -> boolean
): { Vector2 }
	local rng = ctx.Rng
	local found: { Vector2 } = {}
	for _ = 1, count * 20 do
		if #found >= count then
			break
		end
		local x = rng:NextInteger(island.X - island.Radius, island.X + island.Radius)
		local z = rng:NextInteger(island.Z - island.Radius, island.Z + island.Radius)
		local spot = Vector2.new(x, z)
		local good = ctx.IslandAt(x, z) == island and ctx.Inside(x, z, margin) and ok(x, z)
		if good then
			for _, other in found do
				if (other - spot).Magnitude < gap then
					good = false
					break
				end
			end
		end
		if good then
			table.insert(found, spot)
		end
	end
	return found
end

-- Ground ---------------------------------------------------------------------------

-- How high a rocky hill lifts the ground at (x, z) (0 off the hills), roughened so they
-- aren't round
local function hill(ctx: Context.Context, x: number, z: number): number
	local best = 0
	for _, h in HILLS do
		local d = math.sqrt((x - h.X) ^ 2 + (z - h.Z) ^ 2) + ctx.Noise(x, z, 4, 41) * 3
		if d < h.R then
			best = math.max(best, math.floor(h.H * (1 - (d / h.R) ^ 1.6) + 0.5))
		end
	end
	return best
end

-- Forest-floor ground: grass with patches of coarse dirt and of flowers
local function floor(ctx: Context.Context, x: number, z: number, flowers: number, salt: number): string
	if ctx.Noise(x, z, 9, 40 + salt) > 0.28 then
		return "CoarseDirt"
	end
	return if ctx.Noise(x, z, 7, 30 + salt) > flowers then "FlowerGrass" else "Grass"
end

local function oakColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local river = math.abs(z - riverZ(x))
	if river <= 2.5 then
		return "Sand", -1
	elseif river <= 4 then
		return "Sand", 0
	end
	local h = math.round(2.6 + 5 * ctx.Noise(x, z, 26, 1) + 2 * ctx.Noise(x, z, 10, 2))
	h = math.clamp(h, 0, 7)
	if inCamp(x, z, 2) or river <= 7 then
		h = 0
	elseif inCamp(x, z, 5) or river <= 11 then
		h = math.min(h, 1)
	end
	local rise = hill(ctx, x, z)
	if rise > h then
		-- Bare rock where the hill is steep, grass on its top and gentle slopes
		local steep = rise
			- math.min(hill(ctx, x + 1, z), hill(ctx, x - 1, z), hill(ctx, x, z + 1), hill(ctx, x, z - 1))
		return if steep >= 2 then (if ctx.Hash(x, 42, z) < 0.6 then "Stone" else "MossyCobblestone") else "Grass", rise
	end
	return floor(ctx, x, z, 0.4, 0), h
end

local function birchColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1.2 + 3.4 * ctx.Noise(x, z, 20, 3)), 0, 4)
	return floor(ctx, x, z, 0.25, 1), h
end

local function pinesColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.round(3 + 8 * ctx.Noise(x, z, 22, 4) + 3 * ctx.Noise(x, z, 8, 5))
	h = math.clamp(h, 0, 11)
	return if h >= 6 then "Snow" else "SnowyGrass", h
end

local function cherryColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(2 + 5 * ctx.Noise(x, z, 18, 6)), 0, 6)
	return if ctx.Noise(x, z, 7, 32) > 0.32 then "FlowerGrass" else "Grass", h
end

local function mapleColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = 5 + 10 * ctx.Noise(x, z, 26, 8) + 3 * ctx.Noise(x, z, 9, 9)
	-- The hills rise away from the road
	h *= math.clamp(math.abs(x - MAPLE_ROAD) / 28, 0.3, 1)
	return floor(ctx, x, z, 0.45, 2), math.clamp(math.round(h), 0, 13)
end

local function redwoodColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1.5 + 3 * ctx.Noise(x, z, 30, 11) + ctx.Noise(x, z, 9, 12)), 0, 4)
	return floor(ctx, x, z, 0.5, 3), h
end

-- Pieces --------------------------------------------------------------------------------

-- A tall spire of rock on the ground at (x, z), tapering to its top, with moss and
-- cobbles in it and `cap` (snow, grass) on top (from the Skybounds woods)
local function spire(ctx: Context.Context, x: number, z: number, height: number, radius: number, cap: string?)
	local h0 = ctx.HeightAt(x, z)
	for y = 1, height do
		local r = radius * (1 - (y / height) ^ 2 * 0.65) + ctx.Noise(x + y * 2, z, 3, 81) * 0.9
		local reach = math.ceil(r)
		for dx = -reach, reach do
			for dz = -reach, reach do
				if dx * dx + dz * dz <= r * r then
					local roll = ctx.Hash(x + dx, y, z + dz)
					local block = if cap and y == height
						then cap
						elseif roll < 0.14 then "MossyCobblestone"
						elseif roll < 0.24 then "Cobblestone"
						else "Stone"
					ctx.SetFree(x + dx, h0 + y, z + dz, block)
				end
			end
		end
	end
end

-- A fallen log of `logs` on the ground at (x, z), along x or z, with mushrooms on it
local function fallenLog(ctx: Context.Context, x: number, z: number, logs: string, alongX: boolean)
	local h = ctx.HeightAt(x, z)
	local length = ctx.Rng:NextInteger(4, 6)
	for i = 0, length - 1 do
		local lx, lz = if alongX then x + i else x, if alongX then z else z + i
		if ctx.HeightAt(lx, lz) == h then
			ctx.SetFree(lx, h + 1, lz, logs)
		end
	end
	Decor.Mushroom(
		ctx.Decor,
		ctx.Top(x + (if alongX then 1 else 0), h + 1, z + (if alongX then 0 else 1)),
		ctx.Rng:NextNumber() < 0.5
	)
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
	-- A woodpile against the side
	site:Fill(4, 1, 1, 4, 2, 4, logs)
end

-- The sawmill: an open shed over a saw table, with a log on it and a spinning blade
local function sawmill(ctx: Context.Context, x0: number, z0: number)
	for _, dx in { -3, 3 } do
		for _, dz in { -2, 3 } do
			for y = 1, 4 do
				ctx.Set(x0 + dx, y, z0 + dz, "Wood")
			end
		end
	end
	for dx = -4, 4 do
		for dz = -3, 4 do
			ctx.Set(x0 + dx, 5, z0 + dz, "DarkPlanks")
		end
	end
	for dx = -2, 2 do
		ctx.Set(x0 + dx, 1, z0, "Planks")
	end
	ctx.Set(x0 - 2, 2, z0, "Wood")
	ctx.Set(x0 - 1, 2, z0, "Wood")
	local blade = Instance.new("Model")
	blade.Name = "SawBlade"
	local centre = ctx.Top(x0, 1, z0) + Vector3.new(0.6, 1.2, 0)
	-- A cylinder's round faces are on its X axis: turn that onto Z, the axis it spins round
	local disc = Decor.Part(
		blade,
		"Blade",
		Vector3.new(0.15, 3.2, 3.2),
		CFrame.new(centre) * CFrame.Angles(0, math.rad(90), 0),
		Color3.fromRGB(176, 180, 188),
		Enum.Material.Metal
	)
	disc.Shape = Enum.PartType.Cylinder
	blade.WorldPivot = CFrame.new(centre)
	blade.Parent = ctx.Decor
	Decor.Spin(blade, 240)
	Decor.Lantern(ctx.Decor, ctx.Top(x0, 5, z0) - Vector3.new(0, SIZE + 2.7, 0), true, 22)
	-- Log piles beside it
	for dz = -2, 3 do
		for y = 1, 3 do
			ctx.Set(x0 + 6, y, z0 + dz, "Wood")
		end
		for y = 1, 2 do
			ctx.Set(x0 + 7, y, z0 + dz, "Wood")
		end
		ctx.Set(x0 + 8, 1, z0 + dz, "Wood")
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
	for _, d in { { -2, 0 }, { 2, 0 }, { 0, -2 }, { 0, 2 } } do
		ctx.Set(x + d[1], 1, z + d[2], "Wood")
	end
end

-- A pond with lily pads, a little dock out into it and benches on the shore
local function lilyPond(ctx: Context.Context, pond: { X: number, Z: number, R: number }, flowers: { Color3 })
	local water = Common.Pond(ctx, pond.X, pond.Z, pond.R, "Sand")
	for i = 1, math.floor(pond.R * 1.2) do
		local angle = i * 0.9
		Decor.LilyPad(
			ctx.Decor,
			Vector3.new(water.Position.X, water.Position.Y + water.Size.Y / 2, water.Position.Z)
				+ Vector3.new(math.cos(angle) * pond.R * 1.6, 0, math.sin(angle) * pond.R * 1.6),
			if i % 3 == 0 then flowers[i % #flowers + 1] else nil
		)
	end
	for x = pond.X + 2, pond.X + math.floor(pond.R) + 1 do
		ctx.Set(x, 0, pond.Z, "DarkPlanks")
	end
	Decor.Lantern(ctx.Decor, ctx.Top(pond.X + math.floor(pond.R) + 1, 0, pond.Z + 1), false, 14)
	local r = math.floor(pond.R) + 3
	Decor.Bench(ctx.Decor, ctx.Top(pond.X, ctx.HeightAt(pond.X, pond.Z - r), pond.Z - r), Vector3.zAxis)
	Decor.Bench(ctx.Decor, ctx.Top(pond.X - r, ctx.HeightAt(pond.X - r, pond.Z), pond.Z), Vector3.xAxis)
end

-- Oak Woods ----------------------------------------------------------------------------

-- The river: water over its sandy bed, a plank bridge where the path crosses, and a
-- waterfall where it spills off each side of the island
local function river(ctx: Context.Context, island: Context.Island)
	local ends: { number } = {}
	for x = OAK.X - OAK.R - 30, OAK.X + OAK.R + 30 do
		local z = riverZ(x)
		local zc = math.round(z)
		if ctx.IslandAt(x, zc) == island and ctx.World.Cells[key(x, -1, zc)] == "Sand" then
			Decor.Water(
				ctx.Decor,
				ctx.Top(x, -1, zc) + Vector3.new(0, SIZE * 0.8, (z - zc) * SIZE),
				Vector2.new(SIZE, 5.2 * SIZE),
				SIZE * 0.85
			)
			ends[1] = math.min(ends[1] or x, x)
			ends[2] = math.max(ends[2] or x, x)
		end
	end
	for i, x in ends do
		local out = if i == 1 then -Vector3.xAxis else Vector3.xAxis
		local lip = ctx.Top(x, -1, math.round(riverZ(x))) + Vector3.new(0, SIZE * 0.8, 0) + out * (SIZE / 2)
		Decor.Waterfall(ctx.Decor, lip, out, 5 * SIZE, 120)
	end
	-- The bridge where the main path crosses, with rails and a lantern at each end
	local z0 = math.round(riverZ(0))
	for x = -2, 2 do
		for z = z0 - 5, z0 + 5 do
			ctx.Set(x, 0, z, "DarkPlanks")
		end
	end
	for _, x in { -2.6, 2.6 } do
		Decor.Fence(
			ctx.Decor,
			ctx.Top(0, 0, z0 - 5) + Vector3.new(x * SIZE, 0, 0),
			ctx.Top(0, 0, z0 + 5) + Vector3.new(x * SIZE, 0, 0),
			"DarkPlanks"
		)
	end
end

local function oakWoods(ctx: Context.Context, island: Context.Island)
	river(ctx, island)
	cabin(ctx, 22, -144, "Wood", -Vector3.xAxis)
	cabin(ctx, 40, -154, "Wood", -Vector3.zAxis)
	sawmill(ctx, 36, -136)
	campfire(ctx, 28, -150)
	Common.Path(ctx, 3, -144, 21, -144, 3)
	for _, spot in { { 18, -156 }, { 46, -130 }, { 20, -130 } } do
		for dx = 0, 2 do
			ctx.SetFree(spot[1] + dx, 1, spot[2], "Wood")
		end
		ctx.SetFree(spot[1] + 1, 2, spot[2], "Wood")
	end
	-- Stone spires among the trees
	local function clear(x: number, z: number): boolean
		return not ctx.NearArrival(x, z, 6)
			and not inCamp(x, z, 4)
			and math.abs(z - riverZ(x)) > 7
			and not onPaths(x, z, 4)
			and not ctx.Flat(x, z, 3)
			and hill(ctx, x, z) == 0
	end
	for _, spot in spots(ctx, island, 7, 6, 22, clear) do
		spire(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(12, 20), ctx.Rng:NextNumber(2, 3.2), "Grass")
	end
	Common.Forest(ctx, island, 7, 4, function(x, z)
		return ctx.NearArrival(x, z, 4)
			or inCamp(x, z, 3)
			or math.abs(z - riverZ(x)) <= 6
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
	for i, spot in spots(ctx, island, 12, 4, 10, clear) do
		fallenLog(ctx, spot.X, spot.Y, "Wood", i % 2 == 0)
	end
	for z = -146, -14, 12 do
		if math.abs(z - riverZ(3)) > 6 then
			Common.Lamp(ctx, if z % 24 == 0 then 4 else -4, z)
		end
	end
	for x = -64, 64, 16 do
		if x ~= 0 then
			Common.Lamp(ctx, x, CROSS_Z + 4)
		end
	end
	Common.Scatter(ctx, island, 0.07, 0.02, MEADOW)
end

-- Birch Grove ----------------------------------------------------------------------------

local function birchGrove(ctx: Context.Context, island: Context.Island)
	for _, pond in BIRCH_PONDS do
		lilyPond(ctx, pond, { Color3.fromRGB(250, 200, 220), Color3.fromRGB(240, 240, 240) })
	end
	-- The paths in from the bridge to the ponds
	local a, b = BIRCH_PONDS[1], BIRCH_PONDS[2]
	Common.Path(ctx, BIRCH.X + 58, CROSS_Z, a.X + 4, CROSS_Z, 3)
	Common.Path(ctx, a.X + 4, CROSS_Z, a.X + 4, a.Z - math.floor(a.R) - 2, 3)
	Common.Path(ctx, b.X + 4, CROSS_Z, b.X + 4, b.Z + math.floor(b.R) + 2, 3)
	Common.Path(ctx, a.X + 4, CROSS_Z, b.X + 4, CROSS_Z, 3)
	for x = BIRCH.X + 50, BIRCH.X - 30, -16 do
		Common.Lamp(ctx, x, CROSS_Z + 3)
	end
	local function open(x: number, z: number): boolean
		for _, pond in BIRCH_PONDS do
			if near(x, z, pond, pond.R + 5) then
				return false
			end
		end
		return not (math.abs(z - CROSS_Z) <= 3 and x > b.X)
			and not (math.abs(x - a.X - 4) <= 3 and z > CROSS_Z and z < a.Z)
			and not (math.abs(x - b.X - 4) <= 3 and z < CROSS_Z and z > b.Z)
			and not ctx.Flat(x, z, 3)
	end
	Common.Forest(ctx, island, 6, 3, function(x, z)
		return not open(x, z)
	end, function(x, h, z)
		Trees.Birch(x, h, z, ctx.Rng:NextInteger(5, 8), ctx.Node)
	end)
	for i, spot in spots(ctx, island, 7, 4, 12, open) do
		fallenLog(ctx, spot.X, spot.Y, "BirchWood", i % 2 == 0)
	end
	for _, spot in spots(ctx, island, 5, 5, 16, open) do
		Common.Boulder(ctx, spot.X, spot.Y, 3, { "Sandstone", "Stone", "Sandstone" })
	end
	Common.Scatter(ctx, island, 0.06, 0.09, MEADOW)
end

-- Snowy Pines ----------------------------------------------------------------------------

local function snowyPines(ctx: Context.Context, island: Context.Island)
	-- The frozen lake: ice over dark water
	local water = Common.Pond(ctx, PINES_LAKE.X, PINES_LAKE.Z, PINES_LAKE.R, "Snow", "Gravel")
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
	-- The trappers' cabins, built of spruce, west of the path
	for _, c in PINES_CABINS do
		cabin(ctx, c.X, c.Z, "SpruceWood", -Vector3.zAxis)
		Common.Path(ctx, c.X, c.Z - 1, -2, c.Z - 1, 1)
		campfire(ctx, c.X + 6, c.Z - 4)
	end
	for z = PINES.Z - 62, PINES.Z + 54 do
		Common.Path(ctx, -2, z, 2, z, 1)
	end
	for z = PINES.Z - 50, PINES.Z + 50, 14 do
		Common.Lamp(ctx, 4, z)
	end
	local function open(x: number, z: number): boolean
		return not near(x, z, PINES_LAKE, PINES_LAKE.R + 6)
			and math.abs(x) > 6
			and not (x < 0 and x > PINES_CABINS[1].X - 8 and math.abs(z - PINES_CABINS[1].Z - 3) <= 9)
			and not (x < 0 and x > PINES_CABINS[2].X - 8 and math.abs(z - PINES_CABINS[2].Z - 3) <= 9)
			and not ctx.Flat(x, z, 3)
	end
	-- Snowy spires and boulders
	for _, spot in spots(ctx, island, 4, 6, 24, open) do
		spire(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(12, 18), ctx.Rng:NextNumber(2, 3), "Snow")
	end
	for _, spot in spots(ctx, island, 10, 4, 12, open) do
		Common.Boulder(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(2, 4), { "Stone", "Stone", "Snow", "Cobblestone" })
	end
	Common.Forest(ctx, island, 8, 3, function(x, z)
		return not open(x, z)
	end, function(x, h, z)
		Trees.Spruce(x, h, z, ctx.Rng:NextInteger(8, 12), ctx.Node)
	end)
	Common.Scatter(ctx, island, 0.03, 0, {})
	Decor.Falling(ctx.Decor, ctx.Top(PINES.X, 26, PINES.Z), Vector2.new(PINES.R * 2 * SIZE, PINES.R * 2 * SIZE), "Snow")
end

-- Cherry Hills -------------------------------------------------------------------------------

-- An open pavilion: four posts, a red tiled roof, benches inside
local function pavilion(ctx: Context.Context, x0: number, z0: number)
	for dx = -3, 3 do
		for dz = -3, 3 do
			ctx.Set(x0 + dx, 0, z0 + dz, "SmoothStone")
		end
	end
	for _, dx in { -3, 3 } do
		for _, dz in { -3, 3 } do
			for y = 1, 4 do
				ctx.Set(x0 + dx, y, z0 + dz, "CherryWood")
			end
		end
	end
	local site = Build.Site(ctx.World, x0, z0 - 3, -Vector3.zAxis)
	site:Roof(-4, -1, 4, 7, 5, "RoofRed", "CherryWood", false)
	Decor.Bench(ctx.Decor, ctx.Top(x0, 0, z0 - 1), Vector3.zAxis, 3)
	Decor.Bench(ctx.Decor, ctx.Top(x0, 0, z0 + 1), -Vector3.zAxis, 3)
	Decor.Lantern(ctx.Decor, ctx.Top(x0, 4.4, z0), true, 20)
end

local function cherryHills(ctx: Context.Context, island: Context.Island)
	-- The koi pond, with a red-railed bridge over it
	local px, pz = CHERRY_POND.X, CHERRY_POND.Z
	local water = Common.Pond(ctx, px, pz, CHERRY_POND.R, "Gravel")
	local surface = water.Position + Vector3.new(0, water.Size.Y / 2, 0)
	for i = 1, 9 do
		Decor.LilyPad(
			ctx.Decor,
			surface + Vector3.new(math.cos(i * 1.2) * 20, 0, math.sin(i * 1.2) * 20),
			BLOSSOM[i % 3 + 1]
		)
	end
	for i = 1, 12 do
		local fish = Decor.Part(
			ctx.Decor,
			"Koi",
			Vector3.new(0.5, 0.25, 1.2),
			CFrame.new(surface + Vector3.new(math.cos(i * 2.3) * 14, -0.6, math.sin(i * 2.3) * 14))
				* CFrame.Angles(0, i * 1.1, 0),
			if i % 2 == 0 then Color3.fromRGB(246, 120, 40) else Color3.fromRGB(245, 240, 236)
		)
		fish.CanCollide = false
	end
	local reach = math.floor(CHERRY_POND.R) + 1
	for z = pz - reach, pz + reach do
		for x = px - 1, px + 1 do
			ctx.Set(x, 0, z, "DarkPlanks")
		end
	end
	for _, dx in { -1.6, 1.6 } do
		Decor.Fence(
			ctx.Decor,
			ctx.Top(px, 0, pz - reach + 1) + Vector3.new(dx * SIZE, 0, 0),
			ctx.Top(px, 0, pz + reach - 1) + Vector3.new(dx * SIZE, 0, 0),
			"RedWool"
		)
	end
	for _, p in PAVILIONS do
		pavilion(ctx, p[1], p[2])
	end
	-- Paths from the bridge: along the island, to the pavilions and over the pond's bridge
	Common.Path(ctx, CHERRY.X - 58, CROSS_Z, CHERRY.X + 50, CROSS_Z, 3)
	for _, p in PAVILIONS do
		Common.Path(ctx, p[1], CROSS_Z, p[1], p[2] - 4, 3)
	end
	Common.Path(ctx, px, CROSS_Z, px, pz + reach + 1, 3)
	for x = CHERRY.X - 50, CHERRY.X + 44, 12 do
		local z = CROSS_Z + (if x % 24 == 0 then 3 else -3)
		if ctx.Inside(x, z, 2) then
			Decor.StoneLantern(ctx.Decor, ctx.Top(x, ctx.HeightAt(x, z), z))
		end
	end
	local function open(x: number, z: number): boolean
		if near(x, z, CHERRY_POND, CHERRY_POND.R + 5) or math.abs(z - CROSS_Z) <= 4 then
			return false
		end
		for _, p in PAVILIONS do
			if
				math.abs(x - p[1]) <= 6
				and ((z - CROSS_Z) * (p[2] - CROSS_Z) > 0 and math.abs(z - CROSS_Z) <= math.abs(p[2] - CROSS_Z) + 6)
			then
				return false
			end
		end
		return not (math.abs(x - px) <= 3 and z > pz and z < CROSS_Z) and not ctx.Flat(x, z, 3)
	end
	Common.Forest(ctx, island, 8, 4, function(x, z)
		return not open(x, z)
	end, function(x, h, z)
		Trees.Cherry(x, h, z, ctx.Rng:NextInteger(4, 5), ctx.Node)
	end)
	for _, spot in spots(ctx, island, 4, 5, 18, open) do
		Common.Boulder(ctx, spot.X, spot.Y, 3, { "Stone", "MossyCobblestone", "Stone" })
	end
	Common.Scatter(ctx, island, 0.05, 0.06, BLOSSOM)
	Decor.Falling(
		ctx.Decor,
		ctx.Top(CHERRY.X, 16, CHERRY.Z),
		Vector2.new(CHERRY.R * 2 * SIZE, CHERRY.R * 2 * SIZE),
		"Petals"
	)
end

-- Maple Ridge --------------------------------------------------------------------------------

local function mapleRidge(ctx: Context.Context, island: Context.Island)
	lilyPond(ctx, MAPLE_POND, { Color3.fromRGB(240, 150, 60), Color3.fromRGB(226, 70, 50) })
	Common.Path(ctx, MAPLE_ROAD, 44, MAPLE_ROAD, 160, 5, Common.StonePath)
	Common.Path(ctx, MAPLE_ROAD - 3, MAPLE_LAKE_Z, MAPLE_POND.X + 14, MAPLE_LAKE_Z, 3)
	-- The sugar shack, its door on the road, with a campfire and sap barrels beside it
	cabin(ctx, MAPLE_ROAD - 6, 76, "MapleWood", Vector3.xAxis)
	Common.Path(ctx, MAPLE_ROAD - 5, 76, MAPLE_ROAD - 3, 76, 1)
	campfire(ctx, MAPLE_ROAD - 10, 86)
	for _, spot in { { -6, 70 }, { -7, 70 }, { -6, 69 } } do
		ctx.Set(MAPLE_ROAD + spot[1], 1, spot[2], "Barrel")
	end
	for z = 50, 156, 14 do
		Common.Lamp(ctx, MAPLE_ROAD + (if z % 28 == 8 then 4 else -4), z)
	end
	local function open(x: number, z: number): boolean
		return not ctx.Flat(x, z, 3) and not near(x, z, MAPLE_POND, MAPLE_POND.R + 5)
	end
	for _, spot in spots(ctx, island, 5, 6, 26, open) do
		spire(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(12, 20), ctx.Rng:NextNumber(2, 3.2), "Grass")
	end
	Common.Forest(ctx, island, 13, 4, function(x, z)
		return not open(x, z)
	end, function(x, h, z)
		Trees.Maple(x, h, z, ctx.Rng:NextInteger(5, 7), ctx.Node)
		-- Now and then a sap bucket hung on the trunk
		if ctx.Rng:NextNumber() < 0.15 then
			local bucket = Decor.Part(
				ctx.Decor,
				"SapBucket",
				Vector3.new(0.8, 0.9, 0.8),
				CFrame.new(ctx.Top(x, h + 1, z) + Vector3.new(0, -SIZE / 3, -SIZE / 2 - 0.4)),
				Color3.fromRGB(150, 156, 164),
				Enum.Material.Metal
			)
			bucket.CanCollide = false
		end
	end)
	for i, spot in spots(ctx, island, 8, 4, 12, open) do
		fallenLog(ctx, spot.X, spot.Y, "MapleWood", i % 2 == 0)
	end
	for _, spot in spots(ctx, island, 8, 5, 14, open) do
		Common.Boulder(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(3, 4), { "Stone", "MossyCobblestone", "Cobblestone" })
	end
	-- Fallen leaves stand in for the meadow flowers
	Common.Scatter(ctx, island, 0.04, 0.05, {
		Color3.fromRGB(226, 70, 50),
		Color3.fromRGB(240, 140, 50),
		Color3.fromRGB(244, 196, 70),
	})
	Decor.Falling(
		ctx.Decor,
		ctx.Top(MAPLE.X, 26, MAPLE.Z),
		Vector2.new(MAPLE.R * 2 * SIZE, MAPLE.R * 2 * SIZE),
		"Leaves"
	)
end

-- Redwood Giants ------------------------------------------------------------------------------

-- The oldest tree: a stair of planks winds round the trunk up to a railed lookout below the
-- boughs. It's scenery, so nobody can chop the stair out from under anyone.
local function lookout(ctx: Context.Context, x: number, z: number)
	local h = ctx.HeightAt(x, z)
	local ring: { { number } } = {}
	for i = -1, 2 do
		table.insert(ring, { x + i, z - 1 })
	end
	for i = -1, 2 do
		table.insert(ring, { x + 3, z + i })
	end
	for i = 3, 0, -1 do
		table.insert(ring, { x + i, z + 3 })
	end
	for i = 3, 0, -1 do
		table.insert(ring, { x - 1, z + i })
	end
	local steps = 28
	for i = 0, steps - 1 do
		local cell = ring[i % #ring + 1]
		ctx.Set(cell[1], h + 1 + i, cell[2], "DarkPlanks")
	end
	-- The deck goes all round, one block out from the top of the stair
	local deck = h + steps
	for dx = -4, 6 do
		for dz = -4, 6 do
			local inside = dx >= -1 and dx <= 3 and dz >= -1 and dz <= 3
			if not inside then
				ctx.Set(x + dx, deck, z + dz, "DarkPlanks")
			end
		end
	end
	local corners = { { -4, -4 }, { 6, -4 }, { 6, 6 }, { -4, 6 } }
	for i, corner in corners do
		local nextCorner = corners[i % #corners + 1]
		Decor.Fence(
			ctx.Decor,
			ctx.Top(x + corner[1], deck, z + corner[2]),
			ctx.Top(x + nextCorner[1], deck, z + nextCorner[2]),
			"DarkPlanks"
		)
		Decor.Lantern(ctx.Decor, ctx.Top(x + corner[1], deck, z + corner[2]), false, 20)
	end
	Trees.Redwood(x, h, z, 46, ctx.SetFree, 3)
end

-- A fallen giant lying along the trail, hollow, so the trail runs through it
local function fallenGiant(ctx: Context.Context, x1: number, x2: number, z: number)
	for x = x1, x2 do
		-- Moss along the top (a log's top face shows its rings, which looks wrong lying down)
		for dz = -3, 3 do
			ctx.Set(x, 5, z + dz, "Grass")
		end
		for y = 1, 4 do
			ctx.Set(x, y, z - 3, "Redwood")
			ctx.Set(x, y, z + 3, "Redwood")
		end
	end
	for x = x1 + 2, x2 - 2, 3 do
		Decor.Mushroom(ctx.Decor, ctx.Top(x, 5, z + ctx.Rng:NextInteger(-2, 2)), ctx.Rng:NextNumber() < 0.5)
	end
	Decor.Lantern(ctx.Decor, ctx.Top(math.floor((x1 + x2) / 2), 5, z) - Vector3.new(0, SIZE + 2.7, 0), true, 22)
end

local function redwoodGiants(ctx: Context.Context, island: Context.Island)
	Common.Path(ctx, REDWOOD_ROAD, 44, REDWOOD_ROAD, 190, 5, Common.StonePath)
	Common.Path(ctx, REDWOOD_ROAD, REDWOOD_TRAIL, LOOKOUT.X - 2, REDWOOD_TRAIL, 5, Common.StonePath)
	fallenGiant(ctx, 196, 208, REDWOOD_TRAIL)
	lookout(ctx, LOOKOUT.X, LOOKOUT.Z)
	-- The ranger's cabin, its door on the road, with a campfire beside it
	cabin(ctx, REDWOOD_ROAD + 6, 76, "Redwood", -Vector3.xAxis)
	Common.Path(ctx, REDWOOD_ROAD + 3, 76, REDWOOD_ROAD + 5, 76, 1)
	campfire(ctx, REDWOOD_ROAD + 10, 64)
	for z = 50, 186, 14 do
		Common.Lamp(ctx, REDWOOD_ROAD + (if z % 28 == 8 then 4 else -4), z)
	end
	for x = REDWOOD_ROAD + 12, 190, 14 do
		Common.Lamp(ctx, x, REDWOOD_TRAIL + 4)
	end
	local function open(x: number, z: number): boolean
		return not ctx.Flat(x, z, 4)
	end
	Common.Forest(ctx, island, 22, 6, function(x, z)
		return not open(x, z)
	end, function(x, h, z)
		if ctx.Rng:NextNumber() < 0.12 then
			Trees.Redwood(x, h, z, ctx.Rng:NextInteger(38, 46), ctx.Node, 3)
		else
			Trees.Redwood(x, h, z, ctx.Rng:NextInteger(28, 36), ctx.Node, 2)
		end
	end)
	for i, spot in spots(ctx, island, 10, 4, 14, open) do
		fallenLog(ctx, spot.X, spot.Y, "Redwood", i % 2 == 0)
	end
	for _, spot in spots(ctx, island, 12, 5, 16, open) do
		Common.Boulder(
			ctx,
			spot.X,
			spot.Y,
			ctx.Rng:NextInteger(3, 5),
			{ "Stone", "MossyCobblestone", "MossyCobblestone", "Cobblestone" }
		)
	end
	for _, spot in spots(ctx, island, 5, 6, 24, open) do
		Common.GiantMushroom(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(5, 7), ctx.Rng:NextInteger(2, 3))
	end
	Common.Scatter(ctx, island, 0.12, 0.01, MEADOW)
end

-- The world -----------------------------------------------------------------------------

function Woodcutting.Build(ctx: Context.Context)
	-- Main paths, the camp, the bridge ends, ponds and buildings stay flat (the main path
	-- isn't flattened where it crosses the river, or the river would be dammed there)
	ctx.Flatten(-3, -150, 3, -122)
	ctx.Flatten(-3, -102, 3, -10)
	ctx.Flatten(-72, CROSS_Z - 3, 72, CROSS_Z + 3)
	ctx.Flatten(-118, CROSS_Z - 3, -60, CROSS_Z + 3)
	ctx.Flatten(60, CROSS_Z - 3, 118, CROSS_Z + 3)
	ctx.Flatten(-3, -26, 3, 34)
	ctx.Flatten(CAMP.X1, CAMP.Z1, CAMP.X2, CAMP.Z2)
	ctx.Flatten(-3, 20, 3, PINES.Z + 56)
	-- The second ring: roads up to its bridges and on through each zone
	ctx.Flatten(MAPLE_ROAD - 3, CROSS_Z, MAPLE_ROAD + 3, 4)
	ctx.Flatten(MAPLE_ROAD - 3, 30, MAPLE_ROAD + 3, 160)
	ctx.Flatten(MAPLE_POND.X + 10, MAPLE_LAKE_Z - 2, MAPLE_ROAD - 3, MAPLE_LAKE_Z + 2)
	ctx.Flatten(
		MAPLE_POND.X - MAPLE_POND.R - 4,
		MAPLE_POND.Z - MAPLE_POND.R - 4,
		MAPLE_POND.X + MAPLE_POND.R + 4,
		MAPLE_POND.Z + MAPLE_POND.R + 4
	)
	ctx.Flatten(MAPLE_ROAD - 15, 66, MAPLE_ROAD - 3, 92)
	ctx.Flatten(REDWOOD_ROAD - 3, CROSS_Z, REDWOOD_ROAD + 3, 4)
	ctx.Flatten(REDWOOD_ROAD - 3, 30, REDWOOD_ROAD + 3, 192)
	ctx.Flatten(REDWOOD_ROAD, REDWOOD_TRAIL - 3, LOOKOUT.X, REDWOOD_TRAIL + 3)
	ctx.Flatten(LOOKOUT.X - 6, LOOKOUT.Z - 6, LOOKOUT.X + 8, LOOKOUT.Z + 8)
	ctx.Flatten(REDWOOD_ROAD + 3, 58, REDWOOD_ROAD + 16, 84)
	ctx.Flatten(BIRCH.X - 40, CROSS_Z - 3, BIRCH.X + 58, CROSS_Z + 3)
	ctx.Flatten(CHERRY.X - 58, CROSS_Z - 3, CHERRY.X + 52, CROSS_Z + 3)
	for _, pond in BIRCH_PONDS do
		ctx.Flatten(pond.X - pond.R - 4, pond.Z - pond.R - 4, pond.X + pond.R + 4, pond.Z + pond.R + 4)
	end
	ctx.Flatten(
		PINES_LAKE.X - PINES_LAKE.R - 4,
		PINES_LAKE.Z - PINES_LAKE.R - 4,
		PINES_LAKE.X + PINES_LAKE.R + 4,
		PINES_LAKE.Z + PINES_LAKE.R + 4
	)
	for _, c in PINES_CABINS do
		ctx.Flatten(c.X - 5, c.Z - 6, c.X + 8, c.Z + 7)
		ctx.Flatten(c.X, c.Z - 2, 0, c.Z)
	end
	ctx.Flatten(
		CHERRY_POND.X - CHERRY_POND.R - 4,
		CHERRY_POND.Z - CHERRY_POND.R - 4,
		CHERRY_POND.X + CHERRY_POND.R + 4,
		CHERRY_POND.Z + CHERRY_POND.R + 4
	)
	for _, p in PAVILIONS do
		ctx.Flatten(p[1] - 5, p[2] - 5, p[1] + 5, p[2] + 5)
		ctx.Flatten(p[1] - 2, math.min(p[2], CROSS_Z), p[1] + 2, math.max(p[2], CROSS_Z))
	end

	local oak = ctx.Island({
		Name = "Oak Woods",
		X = OAK.X,
		Z = OAK.Z,
		Radius = OAK.R,
		Column = function(x, z)
			return oakColumn(ctx, x, z)
		end,
		-- The hills are rock under their skin of grass
		Fill = function(x, y, z, depth)
			if hill(ctx, x, z) > 0 then
				return if depth == 1 and ctx.World.Cells[key(x, y + depth, z)] == "Grass" then "Dirt" else "Stone"
			end
			return nil
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
		Depth = 46,
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
	local maple = ctx.Island({
		Name = "Maple Ridge",
		X = MAPLE.X,
		Z = MAPLE.Z,
		Radius = MAPLE.R,
		Column = function(x, z)
			return mapleColumn(ctx, x, z)
		end,
		Step = 8,
	})
	local redwood = ctx.Island({
		Name = "Redwood Giants",
		X = REDWOOD.X,
		Z = REDWOOD.Z,
		Radius = REDWOOD.R,
		Column = function(x, z)
			return redwoodColumn(ctx, x, z)
		end,
		Depth = 44,
		Step = 8,
	})
	-- Little rocks floating round the islands
	for _, spot in
		{
			{ -80, 8, -180, 4 },
			{ 92, -6, -172, 4 },
			{ -96, 14, 32, 5 },
			{ 100, 10, 40, 5 },
			{ -262, -2, -16, 4 },
			{ 262, 6, -124, 4 },
			{ 68, 18, 170, 4 },
			{ -76, -8, 156, 4 },
			{ -258, 12, -140, 3 },
			{ 258, 2, -10, 3 },
			{ -96, 10, 190, 4 },
			{ -270, 8, 60, 4 },
			{ 294, 4, 60, 4 },
		}
	do
		ctx.Islet(spot[1], spot[2], spot[3], spot[4])
		if spot[4] >= 4 then
			Trees.Oak(spot[1], spot[2], spot[3], 5, ctx.SetFree)
		end
	end

	Common.Path(ctx, 0, -148, 0, -12, 5, Common.StonePath)
	Common.Path(ctx, -70, CROSS_Z, 70, CROSS_Z, 5, Common.StonePath)
	ctx.Bridge(-118, CROSS_Z, -62, CROSS_Z)
	ctx.Bridge(62, CROSS_Z, 118, CROSS_Z)
	ctx.Bridge(0, -24, 0, 32)
	-- At the crossroads a signpost points the way; each zone has a rough sign where it begins
	Common.Arrows(ctx, 5, CROSS_Z - 5, -Vector3.zAxis, {
		{ Text = "BIRCH GROVE", Toward = -Vector3.xAxis },
		{ Text = "SNOWY PINES", Toward = Vector3.zAxis },
		{ Text = "CHERRY HILLS", Toward = Vector3.xAxis },
	})
	Common.ZoneSign(ctx, BIRCH.X + 56, CROSS_Z - 5, Vector3.xAxis, "BIRCH GROVE", "WOODCUTTING 10", Signs.Woods.Birch)
	Common.ZoneSign(
		ctx,
		CHERRY.X - 56,
		CROSS_Z - 5,
		-Vector3.xAxis,
		"CHERRY HILLS",
		"WOODCUTTING 30",
		Signs.Woods.Cherry
	)
	Common.ZoneSign(ctx, PINES.X + 5, PINES.Z - 60, -Vector3.zAxis, "SNOWY PINES", "WOODCUTTING 20", Signs.Woods.Spruce)

	-- The roads and bridges out to the second ring, laid before the zones are dressed so no
	-- flower or tree ends up on them
	Common.Path(ctx, MAPLE_ROAD, CROSS_Z, MAPLE_ROAD, -22, 3)
	Common.Path(ctx, REDWOOD_ROAD, CROSS_Z, REDWOOD_ROAD, -22, 3)
	ctx.Bridge(MAPLE_ROAD, -22, MAPLE_ROAD, 52)
	ctx.Bridge(REDWOOD_ROAD, -22, REDWOOD_ROAD, 52)
	Common.Arrows(
		ctx,
		MAPLE_ROAD + 4,
		CROSS_Z + 5,
		Vector3.xAxis,
		{ { Text = "MAPLE RIDGE", Toward = Vector3.zAxis } },
		Signs.Woods.Maple
	)
	Common.Arrows(
		ctx,
		REDWOOD_ROAD - 4,
		CROSS_Z + 5,
		-Vector3.xAxis,
		{ { Text = "REDWOOD GIANTS", Toward = Vector3.zAxis } },
		Signs.Woods.Redwood
	)
	Common.ZoneSign(ctx, MAPLE_ROAD + 5, 56, -Vector3.zAxis, "MAPLE RIDGE", "WOODCUTTING 40", Signs.Woods.Maple)
	Common.ZoneSign(ctx, REDWOOD_ROAD + 5, 56, -Vector3.zAxis, "REDWOOD GIANTS", "WOODCUTTING 55", Signs.Woods.Redwood)

	oakWoods(ctx, oak)
	birchGrove(ctx, birch)
	snowyPines(ctx, pines)
	cherryHills(ctx, cherry)

	-- Rocks and giant mushrooms, as in the Skybounds woods
	local function free(x: number, z: number): boolean
		return not onPaths(x, z, 3)
			and not ctx.NearArrival(x, z, 6)
			and not inCamp(x, z, 3)
			and not ctx.Flat(x, z, 3)
			and not ctx.World.Cells[key(x, ctx.HeightAt(x, z) + 1, z)]
	end
	for _, spot in spots(ctx, oak, 10, 5, 14, free) do
		Common.Boulder(
			ctx,
			spot.X,
			spot.Y,
			ctx.Rng:NextInteger(3, 5),
			{ "Stone", "MossyCobblestone", "Stone", "Cobblestone" }
		)
	end
	for _, island in { oak, oak, birch, cherry } do
		for _, spot in spots(ctx, island, 3, 6, 20, free) do
			Common.GiantMushroom(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(5, 7), ctx.Rng:NextInteger(2, 3))
		end
	end
	for _, island in { oak, birch, pines, cherry } do
		Common.CliffVines(ctx, island, 0.35)
	end

	mapleRidge(ctx, maple)
	redwoodGiants(ctx, redwood)
	for _, island in { maple, redwood } do
		Common.CliffVines(ctx, island, 0.25)
	end
end

return Woodcutting
