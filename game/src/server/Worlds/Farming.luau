--!strict
-- The Farming World: four floating islands of farms joined by plank bridges, each zone with
-- its own crop (wild crops: click a ripe one to harvest it and it grows back; each crop
-- needs its Farming level, see Crops.luau). Crops grow in big open fields, not fenced
-- plots, like the Skybounds farms:
--   Wheat Plains (arrival, south)       wheat over the whole plain, cut by winding dirt
--                                       paths with water running along their edges, hay
--                                       bales in the wheat, a tall red silo, a windmill, a
--                                       red barn, a farmhouse, a farmyard, a pond and a
--                                       striped terracotta mesa
--   Veggie Gardens (west, Farming 5/10) rows of carrots south of the path and potatoes
--                                       north of it, water between every few rows, a
--                                       glasshouse at the far end
--   Pumpkin Hollow (north, Farming 15)  pumpkin patches over the rolling ground between
--                                       autumn trees, jack-o'-lanterns along the path, hay
--                                       bales, leaf piles, falling leaves
--   Melon Oasis (east, Farming 25)      a sandy island: melon patches over the dunes, an
--                                       oasis pool ringed with palms, cacti, a market stall
-- A signpost at the crossroads points the way; each zone has a rough sign where it begins.

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

local Farming = {}

Farming.SouthZ = -78
Farming.Seed = 33
Farming.Haze = 0.1

local PLAINS = { X = 0, Z = -44, R = 40 }
local VEGGIE = { X = -84, Z = -36, R = 32 }
local HOLLOW = { X = 0, Z = 44, R = 34 }
local OASIS = { X = 84, Z = -36, R = 32 }
local CROSS_Z = -36

local FLOWERS = {
	Color3.fromRGB(222, 62, 52),
	Color3.fromRGB(242, 212, 64),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(230, 120, 190),
	Color3.fromRGB(110, 132, 230),
}

local N, S, E, W = Vector3.zAxis, -Vector3.zAxis, Vector3.xAxis, -Vector3.xAxis

-- Buildings and ponds (kept flat, and clear of crops)
local MESA = { X = 14, Z = -24 }
local BARN = { 18, -66 } -- door; the barn extends east
local FARMHOUSE = { 14, -76 } -- door; it extends east
local WINDMILL = { -24, -42 }
local SILO = { 30, -52 }
local WELL = { 8, -57 }
local PLAINS_POND = { -18, -72 }
local GLASSHOUSE = { -100, -36 }
local OASIS_POOL = { 92, -24 }
local STALL = { 72, -26 }

local function near(x: number, z: number, spot: { number }, r: number): boolean
	return (x - spot[1]) ^ 2 + (z - spot[2]) ^ 2 <= r * r
end

-- Paths ----------------------------------------------------------------------------------

-- A gentle wave for a winding path, fading to straight near its ends (`t` 0..1 along it)
local function wave(t: number, at: number, amplitude: number, frequency: number): number
	local fade = math.clamp(math.min(t, 1 - t) * 6, 0, 1)
	return math.round(amplitude * fade * math.sin(at * frequency))
end

-- The Wheat Plains' paths: north from the square to the bridge, and across to the side
-- bridges. Their middle lines:
local function mainPathX(z: number): number
	return wave((z + 70) / 64, z, 3, 0.11)
end
local function crossPathZ(x: number): number
	return CROSS_Z + wave((x + 34) / 68, x, 2.5, 0.13)
end
-- How far (x, z) is from the nearest Plains path, in blocks across it
local function plainsPathDistance(x: number, z: number): number
	local d = math.huge
	if z >= -70 and z <= -6 then
		d = math.min(d, math.abs(x - mainPathX(z)))
	end
	if x >= -34 and x <= 34 then
		d = math.min(d, math.abs(z - crossPathZ(x)))
	end
	return d
end

local function veggiePathZ(x: number): number
	return CROSS_Z + wave((x + 104) / 42, x, 1.5, 0.15)
end
local function hollowPathX(z: number): number
	return wave((z - 20) / 42, z, 2.5, 0.15)
end
local function oasisPathZ(x: number): number
	return CROSS_Z + wave((x - 62) / 40, x, 1.5, 0.17)
end

-- Ground -----------------------------------------------------------------------------------

-- How far (x, z) is from the mesa's middle, roughened so its cliffs aren't round
local function mesaDistance(ctx: Context.Context, x: number, z: number): number
	return math.sqrt((x - MESA.X) ^ 2 + (z - MESA.Z) ^ 2) + ctx.Noise(x, z, 4, 8) * 3
end

-- The mesa's striped rock: layers of terracotta, red terracotta and sand
local BANDS = { "Terracotta", "Terracotta", "RedTerracotta", "Terracotta", "Sand", "RedTerracotta" }

-- The plain is flat for the wheat; only the mesa rises out of it
local function plainsColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local d = mesaDistance(ctx, x, z)
	if d < 10.5 then
		local h = if d < 5 then 15 elseif d < 7 then 12 elseif d < 8.8 then 8 else 4
		return "Grass", h
	end
	return if plainsPathDistance(x, z) <= 1 then "Path" else "Grass", 0
end

local function veggieColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(0.8 + 2 * ctx.Noise(x, z, 16, 10)), 0, 2)
	if math.abs(z - CROSS_Z) <= 15 and x > VEGGIE.X - 26 then
		h = 0 -- the gardens either side of the path
	end
	return "Grass", h
end

local function hollowColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1.5 + 4 * ctx.Noise(x, z, 15, 11)), 0, 5)
	return if ctx.Noise(x, z, 6, 12) > 0.3 then "CoarseDirt" else "Grass", h
end

local function oasisColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1 + 3 * ctx.Noise(x, z, 12, 12)), 0, 4)
	if near(x, z, OASIS_POOL, 10) then
		return "Grass", 0
	end
	return "Sand", h
end

-- Fields ------------------------------------------------------------------------------------

local SOWABLE: { [string]: boolean } = { Grass = true, FlowerGrass = true, CoarseDirt = true, Sand = true }

-- Sows a wild crop on the ground at (x, z) if it's open ground with nothing on it
local function sow(ctx: Context.Context, x: number, z: number, crop: string): boolean
	local h = ctx.HeightAt(x, z)
	if not SOWABLE[ctx.World.Cells[key(x, h, z)] or ""] or ctx.World.Cells[key(x, h + 1, z)] then
		return false
	end
	ctx.Field(x, h, z, crop)
	return true
end

-- A water channel in the ground at (x, z) (flat ground at y = 0)
local function channel(ctx: Context.Context, x: number, z: number)
	if ctx.World.Cells[key(x, 1, z)] or ctx.World.Cells[key(x, 0, z)] == "Farmland" then
		return
	end
	ctx.Set(x, 0, z, nil)
	ctx.Set(x, -1, z, "Dirt")
	Decor.Water(ctx.Decor, ctx.Top(x, -1, z) + Vector3.new(0, SIZE * 0.75, 0), Vector2.new(SIZE, SIZE), SIZE * 0.8)
end

-- A hay bale or two standing in a field
local function hay(ctx: Context.Context, x: number, z: number)
	local h = ctx.HeightAt(x, z)
	ctx.SetFree(x, h + 1, z, "HayBale")
	if ctx.Hash(x, 61, z) < 0.4 then
		ctx.SetFree(x + 1, h + 1, z, "HayBale")
	end
	if ctx.Hash(x, 62, z) < 0.2 then
		ctx.SetFree(x, h + 2, z, "HayBale")
	end
end

-- A scarecrow: a post with a crossbar, a straw head, an old hat and a patched shirt
local function scarecrow(ctx: Context.Context, x: number, z: number, shirt: Color3?)
	local h = ctx.HeightAt(x, z)
	ctx.Set(x, h, z, "Farmland")
	ctx.Set(x, h + 1, z, nil)
	local base = CFrame.new(ctx.Top(x, h, z))
	Decor.Piece(ctx.Decor, "Wood", Vector3.new(0.5, 5, 0.5), base * CFrame.new(0, 2.5, 0))
	Decor.Piece(ctx.Decor, "Wood", Vector3.new(4, 0.4, 0.4), base * CFrame.new(0, 3.6, 0))
	Decor.Part(
		ctx.Decor,
		"Shirt",
		Vector3.new(2.2, 1.8, 0.8),
		base * CFrame.new(0, 3.3, 0),
		shirt or Color3.fromRGB(70, 104, 150),
		Enum.Material.Fabric
	)
	Decor.Piece(ctx.Decor, "HayBale", Vector3.new(1.2, 1.2, 1.2), base * CFrame.new(0, 4.9, 0))
	Decor.Part(
		ctx.Decor,
		"HatBrim",
		Vector3.new(2, 0.15, 2),
		base * CFrame.new(0, 5.55, 0),
		Color3.fromRGB(120, 88, 50),
		Enum.Material.Fabric
	)
	Decor.Part(
		ctx.Decor,
		"HatTop",
		Vector3.new(1.1, 0.7, 1.1),
		base * CFrame.new(0, 5.95, 0),
		Color3.fromRGB(120, 88, 50),
		Enum.Material.Fabric
	)
end

-- Wheat Plains -----------------------------------------------------------------------------

-- The barn: red board walls with white trim, a slate roof, a big door, hay inside and out
local function barn(ctx: Context.Context, ox: number, oz: number, front: Vector3)
	local site = Build.Site(ctx.World, ox, oz, front)
	local hw, depth, height = 5, 8, 5
	site:Fill(-hw, 0, 0, hw, 0, depth, "Cobblestone")
	site:Walls(-hw, 1, 0, hw, height - 1, depth, "BarnPlanks")
	site:Walls(-hw, height, 0, hw, height, depth, "WhiteWool")
	for _, u in { -hw, hw } do
		for _, v in { 0, depth } do
			site:Fill(u, 1, v, u, height, v, "WhiteWool")
		end
	end
	site:Clear(-1, 1, 0, 1, 4, 0)
	site:Fill(-hw, 3, 3, -hw, 3, 5, "Glass")
	site:Fill(hw, 3, 3, hw, 3, 5, "Glass")
	site:Roof(-hw, 0, hw, depth, height + 1, "RoofSlate", "BarnPlanks", false)
	-- Hay loft door on the front gable
	site:Fill(-1, height + 2, 0, 1, height + 3, 0, "DarkPlanks")
	for u = -hw + 1, hw - 1 do
		for v = 1, depth - 1 do
			if math.abs(u) >= 3 and (u + v) % 3 ~= 0 then
				site:Set(u, 1, v, "HayBale")
				if (u + v) % 2 == 0 then
					site:Set(u, 2, v, "HayBale")
				end
			end
		end
	end
	for _, spot in { { -3, -1 }, { -4, -1 }, { -4, -2 }, { 3, -2 } } do
		site:Set(spot[1], 1, spot[2], "HayBale")
	end
	site:Set(-4, 2, -1, "HayBale")
	Decor.Lantern(ctx.Decor, site:Pos(0, height - 0.6, 3), true, 26)
	for _, u in { -2.4, 2.4 } do
		Decor.WallLantern(ctx.Decor, site:Pos(u, 3.6, 0) + site.Front * (SIZE / 2), site.Front)
	end
end

-- A tall round silo: red boards with white bands, under a grey dome
local function silo(ctx: Context.Context, x0: number, z0: number)
	local height = 16
	for dx = -2, 2 do
		for dz = -2, 2 do
			local d = math.sqrt(dx * dx + dz * dz)
			if d <= 2.5 then
				ctx.Set(x0 + dx, 0, z0 + dz, "SmoothStone")
				if d > 1.5 then
					for y = 1, height do
						ctx.Set(x0 + dx, y, z0 + dz, if y % 4 == 0 then "WhiteWool" else "BarnPlanks")
					end
				end
				ctx.Set(x0 + dx, height + 1, z0 + dz, "SmoothStone")
			end
			if d <= 1.5 then
				ctx.Set(x0 + dx, height + 2, z0 + dz, "SmoothStone")
			end
		end
	end
	ctx.Set(x0, height + 3, z0, "SmoothStone")
end

-- The windmill: a stone and plaster tower with a red cap and four sails turning to the south
local function windmill(ctx: Context.Context, x0: number, z0: number)
	for y = 1, 12 do
		local r = if y <= 8 then 2 else 1
		for dx = -r, r do
			for dz = -r, r do
				if math.abs(dx) == r or math.abs(dz) == r then
					ctx.Set(x0 + dx, y, z0 + dz, if y <= 2 then "StoneBricks" else "Plaster")
				end
			end
		end
	end
	for dx = -2, 2 do
		for dz = -2, 2 do
			ctx.Set(x0 + dx, 0, z0 + dz, "Cobblestone")
		end
	end
	ctx.Set(x0, 1, z0 - 2, nil)
	ctx.Set(x0, 2, z0 - 2, nil)
	ctx.Set(x0 - 2, 5, z0, "Glass")
	ctx.Set(x0 + 2, 5, z0, "Glass")
	local cap = Build.Site(ctx.World, x0, z0 - 1, -Vector3.zAxis)
	cap:Roof(-1, 0, 1, 2, 13, "RoofRed", "Plaster", false)
	-- The sails turn round an axle sticking out of the front, clear of the wider lower tower
	local hub = ctx.Top(x0, 11, z0 - 3) - Vector3.new(0, SIZE / 2, 0)
	local towerFace = ctx.Top(x0, 11, z0 - 1).Z - SIZE / 2
	Decor.Piece(
		ctx.Decor,
		"DarkPlanks",
		Vector3.new(0.7, 0.7, towerFace - hub.Z),
		CFrame.new(hub.X, hub.Y, (hub.Z + towerFace) / 2)
	)
	local sails = Instance.new("Model")
	sails.Name = "WindmillSails"
	Decor.Piece(sails, "DarkPlanks", Vector3.new(1.2, 1.2, 1.2), CFrame.new(hub))
	for i = 0, 3 do
		local spin = CFrame.new(hub) * CFrame.Angles(0, 0, i * math.pi / 2)
		Decor.Piece(sails, "DarkPlanks", Vector3.new(0.5, 15, 0.4), spin * CFrame.new(0, 7.8, 0))
		local sail = Decor.Part(
			sails,
			"Sail",
			Vector3.new(3, 11, 0.15),
			spin * CFrame.new(1.7, 8.8, 0.1),
			Color3.fromRGB(238, 232, 218),
			Enum.Material.Fabric
		)
		sail.CanCollide = false
	end
	sails.WorldPivot = CFrame.lookAt(hub, hub - Vector3.zAxis)
	sails.Parent = ctx.Decor
	Decor.Spin(sails, 25)
end

-- The farmhouse: plaster and timber, thatched, with a fenced flower garden in front
local function farmhouse(ctx: Context.Context, ox: number, oz: number, front: Vector3)
	local site = Build.Site(ctx.World, ox, oz, front)
	site:Fill(-3, 0, 0, 3, 0, 6, "StoneBricks")
	site:Fill(-2, 0, 1, 2, 0, 5, "Planks")
	site:Walls(-3, 1, 0, 3, 2, 6, "Plaster")
	site:Walls(-3, 3, 0, 3, 3, 6, "DarkPlanks")
	for _, u in { -3, 3 } do
		for _, v in { 0, 6 } do
			site:Fill(u, 1, v, u, 3, v, "Wood")
		end
	end
	site:Clear(0, 1, 0, 0, 2, 0)
	site:Set(-2, 2, 0, "Glass")
	site:Set(2, 2, 0, "Glass")
	site:Fill(-3, 2, 2, -3, 2, 4, "Glass")
	site:Fill(3, 2, 2, 3, 2, 4, "Glass")
	site:Roof(-3, 0, 3, 6, 4, "Thatch", "Plaster", false)
	site:Fill(2, 4, 5, 2, 8, 5, "Bricks")
	Decor.Smoke(ctx.Decor, site:Pos(2, 8.6, 5))
	site:Fill(-2, 1, 4, -2, 1, 5, "RedWool")
	site:Set(2, 1, 3, "Planks")
	Decor.Lantern(ctx.Decor, site:Pos(2, 1.5, 3), false, 14)
	Decor.WallLantern(ctx.Decor, site:Pos(1.3, 2.6, 0) + site.Front * (SIZE / 2), site.Front)
	for v = -1, -3, -1 do
		for u = -3, 3 do
			if u ~= 0 then
				Decor.Flower(ctx.Decor, site:Pos(u, 0.5, v), FLOWERS[ctx.Rng:NextInteger(1, #FLOWERS)])
			end
		end
	end
	local function yard(u: number, v: number): Vector3
		return site:Pos(u, 0.5, v)
	end
	Decor.Fence(ctx.Decor, yard(-3.5, -0.5), yard(-3.5, -3.5))
	Decor.Fence(ctx.Decor, yard(3.5, -0.5), yard(3.5, -3.5))
	Decor.Fence(ctx.Decor, yard(-3.5, -3.5), yard(-0.5, -3.5))
	Decor.Fence(ctx.Decor, yard(0.5, -3.5), yard(3.5, -3.5))
end

-- The farmyard: a well with a little roof, a water trough and a cart heaped with hay
local function farmyard(ctx: Context.Context, wx: number, wz: number)
	for dx = -1, 1 do
		for dz = -1, 1 do
			if dx ~= 0 or dz ~= 0 then
				ctx.Set(wx + dx, 1, wz + dz, "Cobblestone")
			end
			ctx.Set(wx + dx, 4, wz + dz, "RoofRed")
		end
	end
	for _, dx in { -1, 1 } do
		for _, dz in { -1, 1 } do
			ctx.Set(wx + dx, 2, wz + dz, "Wood")
			ctx.Set(wx + dx, 3, wz + dz, "Wood")
		end
	end
	ctx.Set(wx, 0, wz, "Stone")
	Decor.Water(ctx.Decor, ctx.Top(wx, 0, wz) + Vector3.new(0, SIZE * 0.6, 0), Vector2.new(SIZE, SIZE), SIZE * 0.6)
	for x = wx + 3, wx + 5 do
		ctx.Set(x, 1, wz - 3, "DarkPlanks")
	end
	Decor.Water(
		ctx.Decor,
		ctx.Top(wx + 4, 1, wz - 3) - Vector3.new(0, 0.2, 0),
		Vector2.new(2.6 * SIZE, 0.8 * SIZE),
		0.4
	)
	local at = ctx.Top(wx + 3, 0, wz + 3)
	Decor.Piece(ctx.Decor, "Planks", Vector3.new(3, 0.4, 5), CFrame.new(at + Vector3.new(0, 1.4, 0)))
	for _, side in { -1, 1 } do
		for _, z in { -1.6, 1.6 } do
			Decor.Part(
				ctx.Decor,
				"Wheel",
				Vector3.new(0.3, 2, 2),
				CFrame.new(at + Vector3.new(side * 1.6, 1, z)),
				Color3.fromRGB(96, 66, 40)
			)
		end
	end
	Decor.Piece(ctx.Decor, "HayBale", Vector3.new(2.6, 1.4, 4.4), CFrame.new(at + Vector3.new(0, 2.3, 0)))
end

-- Is (x, z) on the Plains somewhere crops don't grow (buildings, the pond, the mesa, the
-- square, bridge ends)?
local function plainsBusy(ctx: Context.Context, x: number, z: number): boolean
	return ctx.NearArrival(x, z, 3)
		or near(x, z, WINDMILL, 5)
		or near(x, z, SILO, 4)
		or near(x, z, WELL, 6)
		or near(x, z, PLAINS_POND, 7)
		or mesaDistance(ctx, x, z) < 12
		or (x > BARN[1] - 4 and x < BARN[1] + 10 and z > BARN[2] - 8 and z < BARN[2] + 8)
		or (x > FARMHOUSE[1] - 6 and x < FARMHOUSE[1] + 9 and z > FARMHOUSE[2] - 6 and z < FARMHOUSE[2] + 6)
		or (math.abs(x) >= 28 and math.abs(z - CROSS_Z) <= 4)
		or (math.abs(x) <= 5 and z >= -16)
end

local function wheatPlains(ctx: Context.Context, island: Context.Island)
	windmill(ctx, WINDMILL[1], WINDMILL[2])
	barn(ctx, BARN[1], BARN[2], W)
	silo(ctx, SILO[1], SILO[2])
	farmhouse(ctx, FARMHOUSE[1], FARMHOUSE[2], W)
	farmyard(ctx, WELL[1], WELL[2])
	local water = Common.Pond(ctx, PLAINS_POND[1], PLAINS_POND[2], 4.4, "Sand")
	for i = 1, 5 do
		local angle = i * 1.3
		Decor.LilyPad(
			ctx.Decor,
			water.Position + Vector3.new(math.cos(angle) * 5, water.Size.Y / 2, math.sin(angle) * 5),
			if i == 2 then FLOWERS[4] else nil
		)
	end
	Common.Path(ctx, mainPathX(FARMHOUSE[2]) + 2, FARMHOUSE[2], FARMHOUSE[1] - 1, FARMHOUSE[2], 1)
	Common.Path(ctx, mainPathX(BARN[2]) + 2, BARN[2], BARN[1] - 1, BARN[2], 3)
	-- Wheat over the whole plain, water along both edges of the paths, hay in the wheat
	local r = math.ceil(PLAINS.R * 1.2)
	for x = PLAINS.X - r, PLAINS.X + r do
		for z = PLAINS.Z - r, PLAINS.Z + r do
			if ctx.IslandAt(x, z) == island and ctx.Inside(x, z, 3) and not plainsBusy(ctx, x, z) then
				local d = plainsPathDistance(x, z)
				if d == 2 then
					channel(ctx, x, z)
				elseif d > 2 then
					if ctx.Hash(x, 60, z) < 0.012 then
						hay(ctx, x, z)
					else
						sow(ctx, x, z, "Wheat")
					end
				end
			end
		end
	end
	for _, spot in { { -14, -58 }, { 14, -44 }, { -12, -26 }, { 22, -44 } } do
		if ctx.World.Cells[key(spot[1], 0, spot[2])] == "Farmland" then
			scarecrow(ctx, spot[1], spot[2])
		end
	end
	-- Oaks and autumn trees round the rim
	Common.Forest(ctx, island, 8, 2, function(x, z)
		return ctx.Inside(x, z, 5) or plainsBusy(ctx, x, z) or ctx.Flat(x, z, 2)
	end, function(x, h, z)
		Trees.Oak(x, h, z, 4 + (x % 2), ctx.SetFree, "Wood", if (x + z) % 3 == 0 then "AutumnLeaves" else nil)
	end)
	Common.Scatter(ctx, island, 0.05, 0.02, FLOWERS)
end

-- Veggie Gardens ----------------------------------------------------------------------------

-- A glasshouse: glass walls and roof on a stone footing, planters of flowers inside
local function glasshouse(ctx: Context.Context, x0: number, z0: number)
	local site = Build.Site(ctx.World, x0, z0, E)
	site:Fill(-4, 0, 0, 4, 0, 8, "SmoothStone")
	site:Walls(-4, 1, 0, 4, 1, 8, "StoneBricks")
	site:Walls(-4, 2, 0, 4, 3, 8, "Glass")
	for _, u in { -4, 4 } do
		for _, v in { 0, 4, 8 } do
			site:Fill(u, 1, v, u, 3, v, "DarkPlanks")
		end
	end
	site:Fill(-4, 4, 0, 4, 4, 8, "Glass")
	site:Clear(0, 1, 0, 0, 2, 0)
	for _, u in { -2, 2 } do
		for v = 2, 6 do
			site:Set(u, 1, v, "DarkPlanks")
			Decor.Flower(ctx.Decor, site:Pos(u, 1.5, v), FLOWERS[(u + v) % #FLOWERS + 1])
		end
	end
	Decor.Lantern(ctx.Decor, site:Pos(0, 3.4, 4), true, 20)
end

local function veggieGardens(ctx: Context.Context, island: Context.Island)
	for x = VEGGIE.X + 22, GLASSHOUSE[1] + 1, -1 do
		Common.Path(ctx, x, veggiePathZ(x), x, veggiePathZ(x), 3)
	end
	glasshouse(ctx, GLASSHOUSE[1], GLASSHOUSE[2])
	Common.ZoneSign(ctx, VEGGIE.X + 14, CROSS_Z - 4, E, "CARROTS", "FARMING 5", Signs.Woods.Oak)
	Common.ZoneSign(ctx, VEGGIE.X + 14, CROSS_Z + 4, E, "POTATOES", "FARMING 10", Signs.Woods.Oak)
	-- Long rows: carrots south of the path, potatoes north, water every fifth row
	for x = VEGGIE.X - 22, VEGGIE.X + 13 do
		local pathZ = veggiePathZ(x)
		for z = pathZ - 13, pathZ + 13 do
			local off = math.abs(z - pathZ)
			if off >= 3 and ctx.IslandAt(x, z) == island and ctx.Inside(x, z, 3) and not near(x, z, GLASSHOUSE, 7) then
				if off % 5 == 0 then
					channel(ctx, x, z)
				else
					sow(ctx, x, z, if z < pathZ then "Carrot" else "Potato")
				end
			end
		end
	end
	for _, spot in { { VEGGIE.X - 6, CROSS_Z - 7 }, { VEGGIE.X - 2, CROSS_Z + 8 } } do
		if ctx.World.Cells[key(spot[1], 0, spot[2])] == "Farmland" then
			scarecrow(ctx, spot[1], spot[2], Color3.fromRGB(150, 110, 50))
		end
	end
	for _, spot in { { -91, CROSS_Z - 2 }, { -77, CROSS_Z + 2 } } do
		ctx.SetFree(spot[1], 1, spot[2], "Crate")
		ctx.SetFree(spot[1] + 1, 1, spot[2], "Barrel")
	end
	Common.Forest(ctx, island, 8, 3, function(x, z)
		return ctx.World.Cells[key(x, ctx.HeightAt(x, z), z)] == "Farmland"
			or math.abs(z - CROSS_Z) <= 15 and x > VEGGIE.X - 26
			or near(x, z, GLASSHOUSE, 9)
			or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		Trees.Oak(x, h, z, 4 + (z % 2), ctx.SetFree)
	end)
	Common.Scatter(ctx, island, 0.05, 0.04, FLOWERS)
end

-- Pumpkin Hollow ----------------------------------------------------------------------------

-- A pumpkin with a carved face glowing toward `out`, on the ground at (x, z)
local function jackOLantern(ctx: Context.Context, x: number, z: number, out: Vector3)
	local h = ctx.HeightAt(x, z) + 1
	ctx.SetFree(x, h, z, "Pumpkin")
	Decor.JackOLantern(ctx.Decor, ctx.Top(x, h, z) - Vector3.new(0, SIZE / 2, 0) + out * (SIZE / 2), out)
end

local function pumpkinHollow(ctx: Context.Context, island: Context.Island)
	for z = HOLLOW.Z - 24, HOLLOW.Z + 18 do
		Common.Path(ctx, hollowPathX(z), z, hollowPathX(z), z, 3)
	end
	for z = HOLLOW.Z - 18, HOLLOW.Z + 14, 8 do
		jackOLantern(ctx, hollowPathX(z) - 2, z, E)
		jackOLantern(ctx, hollowPathX(z + 4) + 2, z + 4, W)
	end
	-- Pumpkin patches over the rolling ground between the trees
	local r = math.ceil(HOLLOW.R * 1.2)
	for x = HOLLOW.X - r, HOLLOW.X + r do
		for z = HOLLOW.Z - r, HOLLOW.Z + r do
			if
				ctx.IslandAt(x, z) == island
				and ctx.Inside(x, z, 4)
				and math.abs(x - hollowPathX(z)) >= 3
				and not ctx.Flat(x, z, 2)
				and ctx.Noise(x, z, 9, 50) > 0.12
			then
				if ctx.Hash(x, 63, z) < 0.015 then
					hay(ctx, x, z)
				else
					sow(ctx, x, z, "Pumpkin")
				end
			end
		end
	end
	for _, spot in { { -14, 34 }, { 15, 50 } } do
		if ctx.World.Cells[key(spot[1], ctx.HeightAt(spot[1], spot[2]), spot[2])] == "Farmland" then
			scarecrow(ctx, spot[1], spot[2], Color3.fromRGB(150, 60, 40))
		end
	end
	-- Autumn trees between the patches, with leaf piles under them
	Common.Forest(ctx, island, 6, 3, function(x, z)
		return ctx.World.Cells[key(x, ctx.HeightAt(x, z), z)] == "Farmland"
			or math.abs(x - hollowPathX(z)) <= 3
			or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		local roll = ctx.Rng:NextNumber()
		if roll < 0.3 then
			Trees.BigOak(x, h, z, 6, ctx.SetFree, "Wood", "AutumnLeaves")
		else
			Trees.Oak(
				x,
				h,
				z,
				ctx.Rng:NextInteger(4, 5),
				ctx.SetFree,
				"Wood",
				if roll < 0.85 then "AutumnLeaves" else "Leaves"
			)
		end
		for _ = 1, 2 do
			local lx, lz = x + ctx.Rng:NextInteger(-2, 2), z + ctx.Rng:NextInteger(-2, 2)
			if ctx.Inside(lx, lz, 2) and ctx.World.Cells[key(lx, ctx.HeightAt(lx, lz), lz)] ~= "Farmland" then
				ctx.SetFree(lx, ctx.HeightAt(lx, lz) + 1, lz, "AutumnLeaves")
			end
		end
	end)
	Common.CliffVines(ctx, island, 0.3)
	Common.Scatter(ctx, island, 0.04, 0, {})
	Decor.Falling(
		ctx.Decor,
		ctx.Top(HOLLOW.X, 16, HOLLOW.Z),
		Vector2.new(HOLLOW.R * 2 * SIZE, HOLLOW.R * 2 * SIZE),
		"Leaves"
	)
end

-- Melon Oasis -------------------------------------------------------------------------------

-- A market stall: a counter of crates under a striped awning on four posts
local function stall(ctx: Context.Context, x0: number, z0: number)
	for _, dx in { -2, 2 } do
		for _, dz in { 0, 3 } do
			for y = 1, 3 do
				ctx.Set(x0 + dx, y, z0 + dz, "DarkPlanks")
			end
		end
	end
	for dx = -1, 1 do
		ctx.Set(x0 + dx, 1, z0, "Crate")
	end
	ctx.Set(x0 - 1, 2, z0, "Melon")
	ctx.Set(x0 + 1, 2, z0, "Melon")
	Decor.Awning(
		ctx.Decor,
		ctx.Top(x0, 3, z0 + 3) + Vector3.new(0, 0.3, 0),
		S,
		5 * SIZE,
		{ Color3.fromRGB(64, 150, 70), Color3.fromRGB(240, 234, 222) }
	)
	Decor.Lantern(ctx.Decor, ctx.Top(x0 + 2, 3, z0), false, 16)
end

local function melonOasis(ctx: Context.Context, island: Context.Island)
	for x = OASIS.X - 22, OASIS.X + 18 do
		Common.Path(ctx, x, oasisPathZ(x), x, oasisPathZ(x), 3, "Gravel")
	end
	Common.Path(ctx, OASIS_POOL[1], CROSS_Z + 2, OASIS_POOL[1], OASIS_POOL[2] - 8, 3, "Gravel")
	local water = Common.Pond(ctx, OASIS_POOL[1], OASIS_POOL[2], 6, "Sand")
	for i = 1, 4 do
		Decor.LilyPad(
			ctx.Decor,
			water.Position + Vector3.new(math.cos(i * 1.6) * 8, water.Size.Y / 2, math.sin(i * 1.6) * 8)
		)
	end
	-- Palms round the pool
	for i = 0, 6 do
		local angle = i / 7 * math.pi * 2 + 0.3
		local x = math.round(OASIS_POOL[1] + math.cos(angle) * 8.5)
		local z = math.round(OASIS_POOL[2] + math.sin(angle) * 8.5)
		if ctx.Inside(x, z, 2) and math.abs(x - OASIS_POOL[1]) > 2 then
			Decor.PalmTree(ctx.Decor, ctx.Top(x, ctx.HeightAt(x, z), z), 10 + (i % 3) * 2, angle + math.pi / 2)
		end
	end
	stall(ctx, STALL[1], STALL[2])
	-- Melon patches over the dunes
	local r = math.ceil(OASIS.R * 1.2)
	for x = OASIS.X - r, OASIS.X + r do
		for z = OASIS.Z - r, OASIS.Z + r do
			if
				ctx.IslandAt(x, z) == island
				and ctx.Inside(x, z, 4)
				and math.abs(z - oasisPathZ(x)) >= 3
				and not near(x, z, OASIS_POOL, 11)
				and not near(x, z, STALL, 5)
				and not (math.abs(x - OASIS_POOL[1]) <= 2 and z > CROSS_Z and z < OASIS_POOL[2])
				and not ctx.Flat(x, z, 2)
				and ctx.Noise(x, z, 8, 51) > 0.1
			then
				sow(ctx, x, z, "Melon")
			end
		end
	end
	-- Cacti over the rest of the sand
	for i = 1, 40 do
		local x = OASIS.X + ctx.Rng:NextInteger(-OASIS.R, OASIS.R)
		local z = OASIS.Z + ctx.Rng:NextInteger(-OASIS.R, OASIS.R)
		local h = ctx.HeightAt(x, z)
		if
			ctx.Inside(x, z, 3)
			and ctx.World.Cells[key(x, h, z)] == "Sand"
			and not ctx.World.Cells[key(x, h + 1, z)]
			and not near(x, z, OASIS_POOL, 11)
			and math.abs(z - oasisPathZ(x)) > 3
		then
			Decor.Cactus(ctx.Decor, ctx.Top(x, h, z), 3 + (i % 4) * 1.2, i % 3)
		end
	end
	for _, x in { 70, 86, 100 } do
		Common.Lamp(ctx, x, oasisPathZ(x) + 2)
	end
	Common.Scatter(ctx, island, 0.06, 0.03, FLOWERS)
end

-- The world ----------------------------------------------------------------------------------

function Farming.Build(ctx: Context.Context)
	-- Bridge ends, buildings and the gardens stay flat
	ctx.Flatten(-66, CROSS_Z - 2, -30, CROSS_Z + 2)
	ctx.Flatten(30, CROSS_Z - 2, 66, CROSS_Z + 2)
	ctx.Flatten(-2, -14, 2, 26)
	ctx.Flatten(VEGGIE.X - 26, CROSS_Z - 15, VEGGIE.X + 30, CROSS_Z + 15)
	ctx.Flatten(OASIS.X - 30, CROSS_Z - 3, OASIS.X + 20, CROSS_Z + 3)
	ctx.Flatten(STALL[1] - 4, STALL[2] - 3, STALL[1] + 4, STALL[2] + 5)
	ctx.Flatten(OASIS_POOL[1] - 8, OASIS_POOL[2] - 8, OASIS_POOL[1] + 8, OASIS_POOL[2] + 8)
	ctx.Flatten(PLAINS_POND[1] - 8, PLAINS_POND[2] - 8, PLAINS_POND[1] + 8, PLAINS_POND[2] + 8)

	local plains = ctx.Island({
		Name = "Wheat Plains",
		X = PLAINS.X,
		Z = PLAINS.Z,
		Radius = PLAINS.R,
		Column = function(x, z)
			return plainsColumn(ctx, x, z)
		end,
		Fill = function(x, y, z, _depth)
			if mesaDistance(ctx, x, z) < 10.5 then
				return BANDS[y % #BANDS + 1]
			end
			return nil
		end,
	})
	local veggie = ctx.Island({
		Name = "Veggie Gardens",
		X = VEGGIE.X,
		Z = VEGGIE.Z,
		Radius = VEGGIE.R,
		Column = function(x, z)
			return veggieColumn(ctx, x, z)
		end,
	})
	local hollow = ctx.Island({
		Name = "Pumpkin Hollow",
		X = HOLLOW.X,
		Z = HOLLOW.Z,
		Radius = HOLLOW.R,
		Column = function(x, z)
			return hollowColumn(ctx, x, z)
		end,
	})
	local oasis = ctx.Island({
		Name = "Melon Oasis",
		X = OASIS.X,
		Z = OASIS.Z,
		Radius = OASIS.R,
		Column = function(x, z)
			return oasisColumn(ctx, x, z)
		end,
		Soil = "Sand",
		Rock = function(_x, y, _z)
			return if y % 4 == 0 then "RedTerracotta" else "Terracotta"
		end,
	})
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
		-- The one off the Melon Oasis is sandy
		ctx.Islet(spot[1], spot[2], spot[3], spot[4], if spot[1] > 100 then "Sand" else nil)
		if spot[4] >= 4 then
			Trees.Oak(spot[1], spot[2], spot[3], 4, ctx.SetFree, "Wood", "AutumnLeaves")
		end
	end

	ctx.Bridge(-62, CROSS_Z, -32, CROSS_Z)
	ctx.Bridge(32, CROSS_Z, 62, CROSS_Z)
	ctx.Bridge(0, -12, 0, 20)
	Common.Arrows(ctx, 5, CROSS_Z - 5, S, {
		{ Text = "VEGGIE GARDENS", Toward = W },
		{ Text = "PUMPKIN HOLLOW", Toward = N },
		{ Text = "MELON OASIS", Toward = E },
	})
	Common.ZoneSign(ctx, VEGGIE.X + 20, CROSS_Z - 4, E, "VEGGIE GARDENS", "FARMING 5 + 10", Signs.Woods.Oak)
	Common.ZoneSign(ctx, OASIS.X - 20, CROSS_Z - 4, W, "MELON OASIS", "FARMING 25", Signs.Woods.Sand)
	Common.ZoneSign(ctx, HOLLOW.X + 4, HOLLOW.Z - 22, S, "PUMPKIN HOLLOW", "FARMING 15", Signs.Woods.Spruce)
	for _, spot in { { -4, -64 }, { 4, -64 }, { -4, CROSS_Z - 4 }, { 4, -16 } } do
		Common.Lamp(ctx, spot[1] + mainPathX(spot[2]), spot[2])
	end

	wheatPlains(ctx, plains)
	veggieGardens(ctx, veggie)
	pumpkinHollow(ctx, hollow)
	melonOasis(ctx, oasis)
	for _, island in { plains, veggie, oasis } do
		Common.CliffVines(ctx, island, 0.25)
	end
end

return Farming
