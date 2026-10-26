--!strict
-- The Farming World: four floating islands of farms joined by plank bridges, each zone with
-- its own crop (fields of wild crops: click a ripe one to harvest it and it grows back;
-- each crop needs its Farming level, see Crops.luau):
--   Wheat Plains (arrival, south)       big fenced wheat fields under a terracotta mesa,
--                                       a windmill whose sails turn, a red barn, a farmhouse
--                                       with a flower garden, a farmyard and a pond
--   Veggie Gardens (west, Farming 5/10) carrot and potato fields either side of the path,
--                                       and a glasshouse full of flowers at the end of it
--   Pumpkin Hollow (north, Farming 15)  pumpkin patches among autumn trees, hay bales,
--                                       jack-o'-lanterns, scarecrows and falling leaves
--   Melon Oasis (east, Farming 25)      a sandy island: melon fields, an oasis pool ringed
--                                       with palms, cacti and a market stall
-- Every field has a fence with a gate toward the path and a tall signpost beside it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Build = require(script.Parent.Parent.Util.Build)
local Decor = require(script.Parent.Parent.Util.Decor)
local Trees = require(script.Parent.Parent.Util.Trees)
local Common = require(script.Parent.Common)
local Context = require(script.Parent.Context)

local SIZE = Blocks.Size

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

-- A field: rows of crops between X1..X2 and Z1..Z2 (every fourth row a water channel),
-- fenced, with a gate on the `Gate` side (toward the path)
type FieldInfo = { Crop: string, X1: number, X2: number, Z1: number, Z2: number, Gate: Vector3, Sign: string }

local N, S, E, W = Vector3.zAxis, -Vector3.zAxis, Vector3.xAxis, -Vector3.xAxis

local FIELDS: { FieldInfo } = {
	-- Wheat Plains
	{ Crop = "Wheat", X1 = -30, X2 = -6, Z1 = -64, Z2 = -50, Gate = E, Sign = "WHEAT" },
	{ Crop = "Wheat", X1 = -24, X2 = -6, Z1 = -32, Z2 = -20, Gate = E, Sign = "WHEAT" },
	{ Crop = "Wheat", X1 = 8, X2 = 26, Z1 = -50, Z2 = -40, Gate = W, Sign = "WHEAT" },
	-- Veggie Gardens
	{ Crop = "Carrot", X1 = -98, X2 = -86, Z1 = -50, Z2 = -42, Gate = N, Sign = "CARROTS\nFARMING 5" },
	{ Crop = "Carrot", X1 = -80, X2 = -68, Z1 = -50, Z2 = -42, Gate = N, Sign = "CARROTS\nFARMING 5" },
	{ Crop = "Potato", X1 = -98, X2 = -86, Z1 = -30, Z2 = -22, Gate = S, Sign = "POTATOES\nFARMING 10" },
	{ Crop = "Potato", X1 = -80, X2 = -68, Z1 = -30, Z2 = -22, Gate = S, Sign = "POTATOES\nFARMING 10" },
	-- Pumpkin Hollow
	{ Crop = "Pumpkin", X1 = -22, X2 = -6, Z1 = 28, Z2 = 40, Gate = E, Sign = "PUMPKINS\nFARMING 15" },
	{ Crop = "Pumpkin", X1 = 6, X2 = 22, Z1 = 28, Z2 = 40, Gate = W, Sign = "PUMPKINS\nFARMING 15" },
	{ Crop = "Pumpkin", X1 = -8, X2 = 8, Z1 = 57, Z2 = 66, Gate = S, Sign = "PUMPKINS\nFARMING 15" },
	-- Melon Oasis
	{ Crop = "Melon", X1 = 70, X2 = 84, Z1 = -52, Z2 = -42, Gate = N, Sign = "MELONS\nFARMING 25" },
	{ Crop = "Melon", X1 = 88, X2 = 102, Z1 = -52, Z2 = -42, Gate = N, Sign = "MELONS\nFARMING 25" },
}

-- Buildings and ponds (kept flat)
local MESA = { X = 14, Z = -24 }
local BARN = { 18, -66 } -- door; the barn extends east
local FARMHOUSE = { 14, -76 } -- door; it extends east
local WINDMILL = { -24, -42 }
local WELL = { 8, -57 }
local PLAINS_POND = { -18, -72 }
local GLASSHOUSE = { -100, -36 }
local OASIS_POOL = { 92, -24 }
local STALL = { 72, -26 }

local function inField(x: number, z: number, margin: number): boolean
	for _, f in FIELDS do
		if x >= f.X1 - margin and x <= f.X2 + margin and z >= f.Z1 - margin and z <= f.Z2 + margin then
			return true
		end
	end
	return false
end

local function near(x: number, z: number, spot: { number }, r: number): boolean
	return (x - spot[1]) ^ 2 + (z - spot[2]) ^ 2 <= r * r
end

-- Ground ------------------------------------------------------------------------------

-- How far (x, z) is from the mesa's middle, roughened so its cliffs aren't round
local function mesaDistance(ctx: Context.Context, x: number, z: number): number
	return math.sqrt((x - MESA.X) ^ 2 + (z - MESA.Z) ^ 2) + ctx.Noise(x, z, 4, 8) * 3
end

-- The mesa's striped rock: layers of terracotta, red terracotta and sand
local BANDS = { "Terracotta", "Terracotta", "RedTerracotta", "Terracotta", "Sand", "RedTerracotta" }

local function plainsColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local d = mesaDistance(ctx, x, z)
	if d < 10.5 then
		local h = if d < 5 then 15 elseif d < 7 then 12 elseif d < 8.8 then 8 else 4
		return "Grass", h
	end
	local h = math.clamp(math.round(0.6 + 2 * ctx.Noise(x, z, 20, 9)), 0, 2)
	if inField(x, z, 2) then
		h = 0
	end
	return if ctx.Noise(x, z, 6, 33) > 0.4 and not inField(x, z, 1) then "FlowerGrass" else "Grass", h
end

local function veggieColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(0.8 + 2 * ctx.Noise(x, z, 16, 10)), 0, 2)
	if inField(x, z, 2) then
		h = 0
	end
	return "Grass", h
end

local function hollowColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1.5 + 4 * ctx.Noise(x, z, 15, 11)), 0, 5)
	if inField(x, z, 2) then
		h = 0
	end
	return if ctx.Hash(x, 4, z) < 0.1 then "Path" else "Grass", h
end

local function oasisColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1 + 3 * ctx.Noise(x, z, 12, 12)), 0, 4)
	if inField(x, z, 2) then
		h = 0
	end
	if near(x, z, OASIS_POOL, 10) then
		return "Grass", 0
	end
	return "Sand", h
end

-- Fields ---------------------------------------------------------------------------------

-- A scarecrow: a post with a crossbar, a straw head, an old hat and a patched shirt
local function scarecrow(ctx: Context.Context, top: Vector3, shirt: Color3?)
	local base = CFrame.new(top)
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

local function field(ctx: Context.Context, info: FieldInfo)
	local cx, cz = math.round((info.X1 + info.X2) / 2), math.round((info.Z1 + info.Z2) / 2)
	if (cz - info.Z1) % 4 == 3 then
		cz += 1
	end
	for x = info.X1, info.X2 do
		for z = info.Z1, info.Z2 do
			if (z - info.Z1) % 4 == 3 then
				-- A water channel: a trench with water in it
				ctx.Set(x, 0, z, nil)
				ctx.Set(x, -1, z, "Dirt")
			elseif x == cx and z == cz then
				ctx.Set(x, 0, z, "Farmland")
				scarecrow(ctx, ctx.Top(x, 0, z), if info.Crop == "Pumpkin" then Color3.fromRGB(150, 60, 40) else nil)
			else
				ctx.Field(x, 0, z, info.Crop)
			end
		end
	end
	for z = info.Z1, info.Z2 do
		if (z - info.Z1) % 4 == 3 then
			Decor.Water(
				ctx.Decor,
				ctx.Top(info.X1, -1, z) + Vector3.new((info.X2 - info.X1) / 2 * SIZE, SIZE * 0.75, 0),
				Vector2.new((info.X2 - info.X1 + 1) * SIZE, SIZE),
				SIZE * 0.8
			)
		end
	end
	-- A fence all round, with a gate in the middle of the side toward the path
	local x1, x2, z1, z2 = info.X1 - 1, info.X2 + 1, info.Z1 - 1, info.Z2 + 1
	local function at(x: number, z: number): Vector3
		return ctx.Top(x, 0, z)
	end
	local sides = {
		{ Dir = S, A = { x1, z1 }, B = { x2, z1 } },
		{ Dir = N, A = { x1, z2 }, B = { x2, z2 } },
		{ Dir = W, A = { x1, z1 }, B = { x1, z2 } },
		{ Dir = E, A = { x2, z1 }, B = { x2, z2 } },
	}
	for _, side in sides do
		local a, b = side.A, side.B
		if side.Dir == info.Gate then
			local alongX = a[2] == b[2]
			local mid = if alongX then math.round((a[1] + b[1]) / 2) else math.round((a[2] + b[2]) / 2)
			if alongX then
				Decor.Fence(ctx.Decor, at(a[1], a[2]), at(mid - 1, a[2]))
				Decor.Fence(ctx.Decor, at(mid + 1, a[2]), at(b[1], a[2]))
				Common.Signpost(ctx, mid + 3, a[2] + math.round(side.Dir.Z) * 2, side.Dir, info.Sign, 4)
			else
				Decor.Fence(ctx.Decor, at(a[1], a[2]), at(a[1], mid - 1))
				Decor.Fence(ctx.Decor, at(a[1], mid + 1), at(a[1], b[2]))
				Common.Signpost(ctx, a[1] + math.round(side.Dir.X) * 2, mid + 3, side.Dir, info.Sign, 4)
			end
		else
			Decor.Fence(ctx.Decor, at(a[1], a[2]), at(b[1], b[2]))
		end
	end
end

-- Wheat Plains ---------------------------------------------------------------------------

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

local function wheatPlains(ctx: Context.Context, island: Context.Island)
	windmill(ctx, WINDMILL[1], WINDMILL[2])
	barn(ctx, BARN[1], BARN[2], W)
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
	Common.Path(ctx, 2, FARMHOUSE[2], FARMHOUSE[1] - 1, FARMHOUSE[2], 1)
	Common.Path(ctx, 2, BARN[2], BARN[1] - 1, BARN[2], 3)
	for _, z in { -62, -54, -46, -28, -20, -12 } do
		Common.Lamp(ctx, 2, z)
	end
	-- A few oaks round the edge of the plains
	Common.Forest(ctx, island, 9, 3, function(x, z)
		return inField(x, z, 3)
			or mesaDistance(ctx, x, z) < 13
			or near(x, z, WINDMILL, 7)
			or (x > BARN[1] - 4 and x < BARN[1] + 10 and z > BARN[2] - 8 and z < BARN[2] + 8)
			or (x > FARMHOUSE[1] - 6 and x < FARMHOUSE[1] + 9 and z > FARMHOUSE[2] - 6 and z < FARMHOUSE[2] + 6)
			or near(x, z, WELL, 6)
			or near(x, z, PLAINS_POND, 8)
			or ctx.Flat(x, z, 3)
			or ctx.NearArrival(x, z, 4)
	end, function(x, h, z)
		Trees.Oak(x, h, z, 4 + (x % 2), ctx.SetFree)
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
	Common.Path(ctx, VEGGIE.X + 22, CROSS_Z, GLASSHOUSE[1] + 1, CROSS_Z, 3)
	glasshouse(ctx, GLASSHOUSE[1], GLASSHOUSE[2])
	for _, x in { -96, -84, -72 } do
		Common.Lamp(ctx, x, CROSS_Z + 2)
	end
	-- Crates of produce and barrels along the path
	for _, spot in { { -91, CROSS_Z - 2 }, { -77, CROSS_Z + 2 } } do
		ctx.SetFree(spot[1], 1, spot[2], "Crate")
		ctx.SetFree(spot[1] + 1, 1, spot[2], "Barrel")
	end
	Common.Forest(ctx, island, 8, 3, function(x, z)
		return inField(x, z, 3) or math.abs(z - CROSS_Z) <= 4 or near(x, z, GLASSHOUSE, 9) or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		Trees.Oak(x, h, z, 4 + (z % 2), ctx.SetFree)
	end)
	Common.Scatter(ctx, island, 0.05, 0.04, FLOWERS)
end

-- Pumpkin Hollow -----------------------------------------------------------------------------

-- A pumpkin with a carved face glowing toward `out`, on the ground at (x, z)
local function jackOLantern(ctx: Context.Context, x: number, z: number, out: Vector3)
	local h = ctx.HeightAt(x, z) + 1
	ctx.SetFree(x, h, z, "Pumpkin")
	Decor.JackOLantern(ctx.Decor, ctx.Top(x, h, z) - Vector3.new(0, SIZE / 2, 0) + out * (SIZE / 2), out)
end

local function pumpkinHollow(ctx: Context.Context, island: Context.Island)
	Common.Path(ctx, 0, HOLLOW.Z - 23, 0, 55, 3)
	for z = HOLLOW.Z - 18, 50, 8 do
		jackOLantern(ctx, -2, z, E)
		jackOLantern(ctx, 2, z + 4, W)
	end
	-- Hay bales and a harvest cart by the paths
	for _, spot in { { -4, 44 }, { -5, 44 }, { -4, 45 }, { 4, 52 }, { 5, 52 } } do
		ctx.SetFree(spot[1], 1, spot[2], "HayBale")
	end
	ctx.SetFree(-4, 2, 44, "HayBale")
	-- Leaf piles under the trees
	Common.Forest(ctx, island, 6, 3, function(x, z)
		return inField(x, z, 3) or math.abs(x) <= 4 or ctx.Flat(x, z, 3)
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
			if ctx.Inside(lx, lz, 2) and not inField(lx, lz, 1) then
				ctx.SetFree(lx, ctx.HeightAt(lx, lz) + 1, lz, "AutumnLeaves")
			end
		end
	end)
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
	Common.Path(ctx, OASIS.X - 22, CROSS_Z, OASIS.X + 18, CROSS_Z, 3, "Gravel")
	Common.Path(ctx, OASIS_POOL[1], CROSS_Z, OASIS_POOL[1], OASIS_POOL[2] - 8, 3, "Gravel")
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
	-- Cacti over the dunes
	for i = 1, 40 do
		local x = OASIS.X + ctx.Rng:NextInteger(-OASIS.R, OASIS.R)
		local z = OASIS.Z + ctx.Rng:NextInteger(-OASIS.R, OASIS.R)
		if
			ctx.Inside(x, z, 3)
			and not inField(x, z, 3)
			and not near(x, z, OASIS_POOL, 11)
			and math.abs(z - CROSS_Z) > 3
			and not near(x, z, STALL, 5)
		then
			Decor.Cactus(ctx.Decor, ctx.Top(x, ctx.HeightAt(x, z), z), 3 + (i % 4) * 1.2, i % 3)
		end
	end
	for _, x in { 70, 86, 100 } do
		Common.Lamp(ctx, x, CROSS_Z + 2)
	end
	Common.Scatter(ctx, island, 0.06, 0.03, FLOWERS)
end

-- The world ----------------------------------------------------------------------------------

function Farming.Build(ctx: Context.Context)
	-- Main paths, bridge ends, fields and buildings stay flat
	ctx.Flatten(-2, -70, 2, -6)
	ctx.Flatten(-34, CROSS_Z - 2, 34, CROSS_Z + 2)
	ctx.Flatten(-66, CROSS_Z - 2, -30, CROSS_Z + 2)
	ctx.Flatten(30, CROSS_Z - 2, 66, CROSS_Z + 2)
	ctx.Flatten(-2, -14, 2, 56)
	ctx.Flatten(VEGGIE.X - 26, CROSS_Z - 2, VEGGIE.X + 30, CROSS_Z + 2)
	ctx.Flatten(OASIS.X - 30, CROSS_Z - 2, OASIS.X + 20, CROSS_Z + 2)
	for _, f in FIELDS do
		ctx.Flatten(f.X1 - 1, f.Z1 - 1, f.X2 + 1, f.Z2 + 1)
	end
	ctx.Flatten(BARN[1] - 3, BARN[2] - 6, BARN[1] + 9, BARN[2] + 6)
	ctx.Flatten(FARMHOUSE[1] - 5, FARMHOUSE[2] - 4, FARMHOUSE[1] + 7, FARMHOUSE[2] + 4)
	ctx.Flatten(WINDMILL[1] - 3, WINDMILL[2] - 4, WINDMILL[1] + 3, WINDMILL[2] + 3)
	ctx.Flatten(WELL[1] - 2, WELL[2] - 4, WELL[1] + 6, WELL[2] + 6)
	ctx.Flatten(GLASSHOUSE[1] - 5, GLASSHOUSE[2] - 5, GLASSHOUSE[1] + 9, GLASSHOUSE[2] + 5)
	ctx.Flatten(STALL[1] - 4, STALL[2] - 3, STALL[1] + 4, STALL[2] + 5)
	for _, spot in { PLAINS_POND, OASIS_POOL } do
		ctx.Flatten(spot[1] - 8, spot[2] - 8, spot[1] + 8, spot[2] + 8)
	end

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
			Trees.Oak(spot[1], spot[2], spot[3], 4, ctx.SetFree)
		end
	end

	Common.Path(ctx, 0, -68, 0, -10, 3)
	Common.Path(ctx, -32, CROSS_Z, 32, CROSS_Z, 3)
	ctx.Bridge(-62, CROSS_Z, -32, CROSS_Z)
	ctx.Bridge(32, CROSS_Z, 62, CROSS_Z)
	ctx.Bridge(0, -12, 0, 20)
	Common.ZoneGate(ctx, VEGGIE.X + 21, CROSS_Z, E, "VEGGIE GARDENS", "FARMING 5 + 10")
	Common.ZoneGate(ctx, OASIS.X - 21, CROSS_Z, W, "MELON OASIS", "FARMING 25")
	Common.ZoneGate(ctx, HOLLOW.X, HOLLOW.Z - 23, S, "PUMPKIN HOLLOW", "FARMING 15")

	for _, info in FIELDS do
		field(ctx, info)
	end
	wheatPlains(ctx, plains)
	veggieGardens(ctx, veggie)
	pumpkinHollow(ctx, hollow)
	melonOasis(ctx, oasis)
end

return Farming
