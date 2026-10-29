--!strict
-- The Farming World: four big floating islands of farms joined by plank bridges, each zone
-- with its own crop (wild crops: click a ripe one to harvest it and it grows back; each crop
-- needs its Farming level, see Crops.luau). Crops grow in huge open fields, not fenced
-- plots, like the Skybounds farms (02 Research/References/Skybounds/farming):
--   Wheat Plains (arrival, south)       a sea of wheat over the whole plain, cut by winding
--                                       dirt paths with water running along their edges,
--                                       hay bales in the wheat; a tall red silo, a striped
--                                       windmill, a red barn, a farmhouse, a farmyard, a
--                                       pond, a striped terracotta mesa, a rocky hill and a
--                                       rock arch over the path north, giant flowers
--   Veggie Gardens (west, Farming 5/10) long rows of carrots south of the path and potatoes
--                                       north of it, water between every few rows, rocky
--                                       hills round the gardens, a glasshouse at the far end
--   Pumpkin Hollow (north, Farming 15)  pumpkin patches over the rolling ground between
--                                       autumn trees, jack-o'-lanterns along the path, hay,
--                                       leaf piles, a harvest barn, falling leaves
--   Melon Oasis (east, Farming 25)      a sandy island: melon patches over the dunes, an
--                                       oasis pool ringed with palms, cacti, market stalls,
--                                       a striped terracotta mesa
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

Farming.SouthZ = -158
Farming.Seed = 33
Farming.Haze = 0.1

local PLAINS = { X = 0, Z = -88, R = 80 }
local VEGGIE = { X = -168, Z = -72, R = 64 }
local HOLLOW = { X = 0, Z = 88, R = 68 }
local OASIS = { X = 168, Z = -72, R = 64 }
local CROSS_Z = -72

local FLOWERS = {
	Color3.fromRGB(222, 62, 52),
	Color3.fromRGB(242, 212, 64),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(230, 120, 190),
	Color3.fromRGB(110, 132, 230),
}

local N, S, E, W = Vector3.zAxis, -Vector3.zAxis, Vector3.xAxis, -Vector3.xAxis

-- Hills, buildings and ponds (kept flat, and clear of crops)
local MESA = { X = 38, Z = -40, R = 21 }
local HILL = { X = -42, Z = -36, R = 16 } -- the rocky hill on the Plains
local ARCH_Z = -30 -- the rock arch over the path north
local BARN = { 30, -122 } -- door; the barn extends east
local FARMHOUSE = { 24, -150 } -- door; it extends east
local WINDMILL = { -44, -110 }
local SILO = { 58, -100 }
local WELL = { 16, -106 }
local PLAINS_POND = { -40, -142 }
local GLASSHOUSE = { -214, CROSS_Z }
local HARVEST_BARN = { 30, 116 } -- door; it extends east
local OASIS_POOL = { 184, -46 }
local OASIS_MESA = { X = 198, Z = -110, R = 14 }
local STALLS = { { 148, -52 }, { 204, -88 } }

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
	return wave((z + 148) / 136, z, 7, 0.05)
end
local function crossPathZ(x: number): number
	return CROSS_Z + wave((x + 70) / 140, x, 5, 0.06)
end
-- How far (x, z) is from the nearest Plains path, in blocks across it
local function plainsPathDistance(x: number, z: number): number
	local d = math.huge
	if z >= -148 and z <= -12 then
		d = math.min(d, math.abs(x - mainPathX(z)))
	end
	if x >= -70 and x <= 70 then
		d = math.min(d, math.abs(z - crossPathZ(x)))
	end
	return d
end

local function veggiePathZ(x: number): number
	return CROSS_Z + wave((x + 212) / 100, x, 3, 0.08)
end
local function hollowPathX(z: number): number
	return wave((z - 26) / 124, z, 6, 0.07)
end
local function oasisPathZ(x: number): number
	return CROSS_Z + wave((x - 112) / 114, x, 3, 0.08)
end

-- Ground -----------------------------------------------------------------------------------

-- How far (x, z) is from a hill's middle, roughened so its cliffs aren't round
local function roughDistance(ctx: Context.Context, x: number, z: number, hill: { X: number, Z: number }): number
	return math.sqrt((x - hill.X) ^ 2 + (z - hill.Z) ^ 2) + ctx.Noise(x, z, 5, 8) * 4
end

-- A mesa's height at (x, z): flat-topped tiers stepping down (0 off it)
local function mesaHeight(
	ctx: Context.Context,
	x: number,
	z: number,
	mesa: { X: number, Z: number, R: number },
	top: number
): number
	local d = roughDistance(ctx, x, z, mesa) / mesa.R
	if d >= 1 then
		return 0
	end
	return if d < 0.48
		then top
		elseif d < 0.67 then math.floor(top * 0.8)
		elseif d < 0.84 then math.floor(top * 0.53)
		else math.floor(top * 0.27)
end

-- The rocky hill on the Plains: grass on top, grey cliffs
local function hillHeight(ctx: Context.Context, x: number, z: number): number
	local d = roughDistance(ctx, x, z, HILL) / HILL.R
	if d >= 1 then
		return 0
	end
	return math.max(1, math.floor(14 * (1 - d ^ 1.8) + ctx.Noise(x, z, 4, 9) * 3))
end

-- The striped rock of a mesa: layers of terracotta, red terracotta and sand
local BANDS = { "Terracotta", "Terracotta", "RedTerracotta", "Terracotta", "Sand", "RedTerracotta" }

-- The plain is flat for the wheat; only the mesa and the rocky hill rise out of it
local function plainsColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local mesa = mesaHeight(ctx, x, z, MESA, 30)
	if mesa > 0 then
		return "Grass", mesa
	end
	local hill = hillHeight(ctx, x, z)
	if hill > 0 then
		return "Grass", hill
	end
	return if plainsPathDistance(x, z) <= 2 then "Path" else "Grass", 0
end

local function veggieColumn(ctx: Context.Context, x: number, z: number): (string, number)
	if math.abs(z - CROSS_Z) <= 30 and x > VEGGIE.X - 56 then
		return "Grass", 0 -- the gardens either side of the path
	end
	-- Rocky hills round the gardens, like the grey cliffs in the Skybounds farms
	local h = math.clamp(math.round(3 + 9 * ctx.Noise(x, z, 14, 10) + 3 * ctx.Noise(x, z, 5, 13)), 0, 12)
	return "Grass", h
end

local function hollowColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(2 + 6 * ctx.Noise(x, z, 18, 11)), 0, 7)
	return if ctx.Noise(x, z, 7, 12) > 0.3 then "CoarseDirt" else "Grass", h
end

local function oasisColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local mesa = mesaHeight(ctx, x, z, OASIS_MESA, 20)
	if mesa > 0 then
		return "Sand", mesa
	end
	if near(x, z, OASIS_POOL, 18) then
		return "Grass", 0
	end
	local h = math.clamp(math.round(1 + 4 * ctx.Noise(x, z, 14, 12)), 0, 5)
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
	if ctx.Hash(x, 61, z) < 0.5 then
		ctx.SetFree(x + 1, h + 1, z, "HayBale")
	end
	if ctx.Hash(x, 62, z) < 0.3 then
		ctx.SetFree(x, h + 2, z, "HayBale")
	end
	if ctx.Hash(x, 64, z) < 0.3 then
		ctx.SetFree(x, h + 1, z + 1, "HayBale")
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

-- A giant flower on the ground at (x, z): a tall blocky stem with leaves, under a big
-- blocky bloom (from the giant flowers in the Skybounds farms)
local function giantFlower(ctx: Context.Context, x: number, z: number, height: number, color: Color3)
	local h = ctx.HeightAt(x, z)
	local base = ctx.Top(x, h, z)
	local stem = Color3.fromRGB(78, 140, 54)
	local lean = ctx.Hash(x, 70, z) * 6
	Decor.Part(
		ctx.Decor,
		"FlowerStem",
		Vector3.new(1, height, 1),
		CFrame.new(base + Vector3.new(0, height / 2, 0)),
		stem,
		Enum.Material.Grass
	)
	for i, side in { 1, -1 } do
		Decor.Part(
			ctx.Decor,
			"FlowerLeaf",
			Vector3.new(3, 0.5, 1.4),
			CFrame.new(base + Vector3.new(side * 1.6, height * (0.3 + i * 0.15), 0))
				* CFrame.Angles(0, lean, side * 0.4),
			stem,
			Enum.Material.Grass
		)
	end
	local head = CFrame.new(base + Vector3.new(0, height + 1, 0)) * CFrame.Angles(math.rad(25), lean, 0)
	Decor.Part(ctx.Decor, "FlowerHeart", Vector3.new(2, 2, 1.2), head, Color3.fromRGB(120, 76, 36), Enum.Material.Wood)
	for i = 0, 5 do
		local angle = i / 6 * 2 * math.pi
		Decor.Part(
			ctx.Decor,
			"Petal",
			Vector3.new(2.2, 2.2, 0.8),
			head * CFrame.new(math.cos(angle) * 2, math.sin(angle) * 2, -0.1),
			color,
			Enum.Material.SmoothPlastic
		)
	end
end

-- A spot near an island's rim in the direction `angle`, on open ground (not a field, nothing
-- standing on it), or nil
local function rimSpot(ctx: Context.Context, island: Context.Island, angle: number): (number?, number?)
	for _, reach in { 0.95, 0.9, 0.85, 0.8 } do
		local x = math.round(island.X + math.cos(angle) * island.Radius * reach)
		local z = math.round(island.Z + math.sin(angle) * island.Radius * reach)
		local h = ctx.HeightAt(x, z)
		local ground = ctx.World.Cells[key(x, h, z)]
		if
			ctx.IslandAt(x, z) == island
			and ctx.Inside(x, z, 2)
			and (ground == "Grass" or ground == "FlowerGrass" or ground == "CoarseDirt" or ground == "Sand")
			and not ctx.World.Cells[key(x, h + 1, z)]
			and not ctx.Fields[key(x, h, z)]
		then
			return x, z
		end
	end
	return nil, nil
end

-- Wheat Plains -----------------------------------------------------------------------------

-- A barn: red board walls with white trim, a slate roof, a big door, hay inside and out
local function barn(
	ctx: Context.Context,
	ox: number,
	oz: number,
	front: Vector3,
	hw: number,
	depth: number,
	height: number
)
	local site = Build.Site(ctx.World, ox, oz, front)
	site:Fill(-hw, 0, 0, hw, 0, depth, "Cobblestone")
	site:Walls(-hw, 1, 0, hw, height - 1, depth, "BarnPlanks")
	site:Walls(-hw, height, 0, hw, height, depth, "WhiteWool")
	for _, u in { -hw, hw } do
		for _, v in { 0, depth } do
			site:Fill(u, 1, v, u, height, v, "WhiteWool")
		end
	end
	site:Clear(-2, 1, 0, 2, height - 2, 0)
	for v = 3, depth - 3, 4 do
		site:Fill(-hw, 3, v, -hw, 4, v + 1, "Glass")
		site:Fill(hw, 3, v, hw, 4, v + 1, "Glass")
	end
	site:Roof(-hw, 0, hw, depth, height + 1, "RoofSlate", "BarnPlanks", false)
	-- Hay loft door on the front gable
	site:Fill(-1, height + 2, 0, 1, height + 4, 0, "DarkPlanks")
	for u = -hw + 1, hw - 1 do
		for v = 1, depth - 1 do
			if math.abs(u) >= 4 and (u + v) % 3 ~= 0 then
				site:Set(u, 1, v, "HayBale")
				if (u + v) % 2 == 0 then
					site:Set(u, 2, v, "HayBale")
				end
			end
		end
	end
	for _, spot in { { -4, -1 }, { -5, -1 }, { -5, -2 }, { 4, -2 }, { 5, -1 } } do
		site:Set(spot[1], 1, spot[2], "HayBale")
	end
	site:Set(-5, 2, -1, "HayBale")
	Decor.Lantern(ctx.Decor, site:Pos(0, height - 0.6, depth / 2), true, 30)
	for _, u in { -3.4, 3.4 } do
		Decor.WallLantern(ctx.Decor, site:Pos(u, height - 2.4, 0) + site.Front * (SIZE / 2), site.Front)
	end
end

-- A tall round silo: red boards with white bands, under a grey dome
local function silo(ctx: Context.Context, x0: number, z0: number)
	local height, r = 32, 4.5
	for dx = -5, 5 do
		for dz = -5, 5 do
			local d = math.sqrt(dx * dx + dz * dz)
			if d <= r then
				ctx.Set(x0 + dx, 0, z0 + dz, "SmoothStone")
				if d > r - 1.2 then
					for y = 1, height do
						ctx.Set(x0 + dx, y, z0 + dz, if y % 6 == 0 then "WhiteWool" else "BarnPlanks")
					end
				end
			end
			-- The dome: rings stepping in
			for i, ring in { r, r - 1, r - 2, r - 3 } do
				if d <= ring and d > ring - 1.3 or (i == 4 and d <= ring) then
					ctx.Set(x0 + dx, height + i, z0 + dz, "SmoothStone")
				end
			end
		end
	end
	ctx.Set(x0, height + 5, z0, "SmoothStone")
	-- A ladder up the side
	for y = 1, height do
		Decor.Piece(
			ctx.Decor,
			"DarkPlanks",
			Vector3.new(2, 0.3, 0.3),
			CFrame.new(ctx.Top(x0, y - 1, z0) + Vector3.new(0, 0, -(r + 0.6) * SIZE))
		)
	end
end

-- The windmill: a tall tower striped red and white with a red cap, and four big sails
-- turning to the south (from the Skybounds windmill)
local function windmill(ctx: Context.Context, x0: number, z0: number)
	local top = 24
	for y = 1, top do
		local r = if y <= 16 then 3 else 2
		for dx = -r, r do
			for dz = -r, r do
				if math.abs(dx) == r or math.abs(dz) == r then
					local along = if math.abs(dz) == r then dx else dz
					local block = if y <= 3 then "StoneBricks" elseif along % 2 == 0 then "WhiteWool" else "RedWool"
					ctx.Set(x0 + dx, y, z0 + dz, block)
				end
			end
		end
		if y == 16 then
			-- A balcony round the narrowing
			for dx = -4, 4 do
				for dz = -4, 4 do
					if math.max(math.abs(dx), math.abs(dz)) == 4 or math.max(math.abs(dx), math.abs(dz)) == 3 then
						ctx.SetFree(x0 + dx, y, z0 + dz, "DarkPlanks")
					end
				end
			end
		end
	end
	for dx = -4, 4 do
		for dz = -4, 4 do
			ctx.Set(x0 + dx, 0, z0 + dz, "Cobblestone")
		end
	end
	ctx.Set(x0, 1, z0 - 3, nil)
	ctx.Set(x0, 2, z0 - 3, nil)
	for _, y in { 7, 12, 19 } do
		ctx.Set(x0 - (if y > 16 then 2 else 3), y, z0, "Glass")
		ctx.Set(x0 + (if y > 16 then 2 else 3), y, z0, "Glass")
	end
	local cap = Build.Site(ctx.World, x0, z0 - 2, -Vector3.zAxis)
	cap:Roof(-2, 0, 2, 4, top + 1, "RoofRed", "WhiteWool", false)
	-- The sails turn round an axle sticking out of the front
	local hub = ctx.Top(x0, top - 2, z0 - 6) - Vector3.new(0, SIZE / 2, 0)
	local towerFace = ctx.Top(x0, top - 2, z0 - 2).Z - SIZE / 2
	Decor.Piece(
		ctx.Decor,
		"DarkPlanks",
		Vector3.new(1, 1, towerFace - hub.Z),
		CFrame.new(hub.X, hub.Y, (hub.Z + towerFace) / 2)
	)
	local sails = Instance.new("Model")
	sails.Name = "WindmillSails"
	Decor.Piece(sails, "DarkPlanks", Vector3.new(2.2, 2.2, 2.2), CFrame.new(hub))
	for i = 0, 3 do
		local spin = CFrame.new(hub) * CFrame.Angles(0, 0, i * math.pi / 2)
		Decor.Piece(sails, "DarkPlanks", Vector3.new(0.9, 32, 0.7), spin * CFrame.new(0, 16, 0))
		local sail = Decor.Part(
			sails,
			"Sail",
			Vector3.new(6, 24, 0.2),
			spin * CFrame.new(3.4, 18, 0.15),
			Color3.fromRGB(238, 232, 218),
			Enum.Material.Fabric
		)
		sail.CanCollide = false
		for j = 1, 3 do
			Decor.Piece(sails, "Planks", Vector3.new(6.4, 0.4, 0.3), spin * CFrame.new(3.4, 8 + j * 6, 0.3))
		end
	end
	sails.WorldPivot = CFrame.lookAt(hub, hub - Vector3.zAxis)
	sails.Parent = ctx.Decor
	Decor.Spin(sails, 18)
end

-- The farmhouse: plaster and timber, thatched, with a fenced flower garden in front
local function farmhouse(ctx: Context.Context, ox: number, oz: number, front: Vector3)
	local site = Build.Site(ctx.World, ox, oz, front)
	local hw, depth = 4, 8
	site:Fill(-hw, 0, 0, hw, 0, depth, "StoneBricks")
	site:Fill(-hw + 1, 0, 1, hw - 1, 0, depth - 1, "Planks")
	site:Walls(-hw, 1, 0, hw, 3, depth, "Plaster")
	site:Walls(-hw, 4, 0, hw, 4, depth, "DarkPlanks")
	for _, u in { -hw, hw } do
		for _, v in { 0, depth } do
			site:Fill(u, 1, v, u, 4, v, "Wood")
		end
	end
	site:Clear(0, 1, 0, 0, 2, 0)
	for _, u in { -2, 2 } do
		site:Fill(u, 2, 0, u, 3, 0, "Glass")
	end
	site:Fill(-hw, 2, 3, -hw, 3, 5, "Glass")
	site:Fill(hw, 2, 3, hw, 3, 5, "Glass")
	site:Roof(-hw, 0, hw, depth, 5, "Thatch", "Plaster", false)
	site:Fill(3, 5, 7, 3, 11, 7, "Bricks")
	Decor.Smoke(ctx.Decor, site:Pos(3, 11.6, 7))
	site:Fill(-3, 1, 6, -3, 1, 7, "RedWool")
	site:Set(3, 1, 4, "Planks")
	site:Fill(-3, 1, 1, -2, 2, 1, "Bookshelf")
	Decor.Lantern(ctx.Decor, site:Pos(3, 1.5, 4), false, 16)
	Decor.WallLantern(ctx.Decor, site:Pos(1.3, 2.6, 0) + site.Front * (SIZE / 2), site.Front)
	for v = -1, -4, -1 do
		for u = -hw, hw do
			if u ~= 0 then
				Decor.Flower(ctx.Decor, site:Pos(u, 0.5, v), FLOWERS[ctx.Rng:NextInteger(1, #FLOWERS)])
			end
		end
	end
	local function yard(u: number, v: number): Vector3
		return site:Pos(u, 0.5, v)
	end
	Decor.Fence(ctx.Decor, yard(-hw - 0.5, -0.5), yard(-hw - 0.5, -4.5))
	Decor.Fence(ctx.Decor, yard(hw + 0.5, -0.5), yard(hw + 0.5, -4.5))
	Decor.Fence(ctx.Decor, yard(-hw - 0.5, -4.5), yard(-0.5, -4.5))
	Decor.Fence(ctx.Decor, yard(0.5, -4.5), yard(hw + 0.5, -4.5))
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

-- A rock arch over the path at (x0, z0): two pillars of stone and terracotta with a span
-- across, grass and a little tree on top (from the Skybounds farms)
local function rockArch(ctx: Context.Context, x0: number, z0: number)
	for dx = -8, 8 do
		for dz = -2, 2 do
			local ax = math.abs(dx)
			local h = if ax >= 5 then 13 - math.max(0, ax - 6) else 13
			for y = 1, h do
				local inOpening = ax <= 4 and y <= 8 + (if ax <= 2 then 1 else 0)
				if not inOpening and ctx.Noise(x0 + dx, y * 3 + dz, 3, 77) > -0.42 then
					local block = if y == h
						then "Grass"
						elseif y % 5 == 0 then "Terracotta"
						elseif ctx.Hash(x0 + dx, y, z0 + dz) < 0.2 then "MossyCobblestone"
						else "Stone"
					ctx.SetFree(x0 + dx, y, z0 + dz, block)
				end
			end
		end
	end
	Trees.Oak(x0 + 2, 13, z0, 4, ctx.SetFree)
	Decor.WallLantern(ctx.Decor, ctx.Top(x0 - 5, 4, z0 - 2) - Vector3.new(0, SIZE / 2, SIZE / 2), S)
	Decor.WallLantern(ctx.Decor, ctx.Top(x0 + 5, 4, z0 - 2) - Vector3.new(0, SIZE / 2, SIZE / 2), S)
end

-- Is (x, z) on the Plains somewhere crops don't grow (buildings, the pond, the hills, the
-- square, bridge ends)?
local function plainsBusy(ctx: Context.Context, x: number, z: number): boolean
	return ctx.NearArrival(x, z, 3)
		or near(x, z, WINDMILL, 7)
		or near(x, z, SILO, 7)
		or near(x, z, WELL, 7)
		or near(x, z, PLAINS_POND, 10)
		or mesaHeight(ctx, x, z, MESA, 30) > 0
		or roughDistance(ctx, x, z, MESA) < MESA.R + 3
		or roughDistance(ctx, x, z, HILL) < HILL.R + 3
		or (math.abs(z - ARCH_Z) <= 4 and math.abs(x - mainPathX(ARCH_Z)) <= 10)
		or (x > BARN[1] - 5 and x < BARN[1] + 17 and z > BARN[2] - 12 and z < BARN[2] + 12)
		or (x > FARMHOUSE[1] - 7 and x < FARMHOUSE[1] + 11 and z > FARMHOUSE[2] - 8 and z < FARMHOUSE[2] + 8)
		or (math.abs(x) >= 64 and math.abs(z - CROSS_Z) <= 5)
		or (math.abs(x) <= 6 and z >= -22)
end

local function wheatPlains(ctx: Context.Context, island: Context.Island)
	windmill(ctx, WINDMILL[1], WINDMILL[2])
	barn(ctx, BARN[1], BARN[2], W, 8, 14, 8)
	silo(ctx, SILO[1], SILO[2])
	farmhouse(ctx, FARMHOUSE[1], FARMHOUSE[2], W)
	farmyard(ctx, WELL[1], WELL[2])
	rockArch(ctx, mainPathX(ARCH_Z), ARCH_Z)
	local water = Common.Pond(ctx, PLAINS_POND[1], PLAINS_POND[2], 7, "Sand")
	for i = 1, 8 do
		local angle = i * 0.8
		Decor.LilyPad(
			ctx.Decor,
			water.Position + Vector3.new(math.cos(angle) * 10, water.Size.Y / 2, math.sin(angle) * 10),
			if i % 3 == 0 then FLOWERS[4] else nil
		)
	end
	Decor.Bench(ctx.Decor, ctx.Top(PLAINS_POND[1] + 9, 0, PLAINS_POND[2]), W)
	Common.Path(ctx, mainPathX(FARMHOUSE[2]) + 3, FARMHOUSE[2], FARMHOUSE[1] - 1, FARMHOUSE[2], 1)
	Common.Path(ctx, mainPathX(BARN[2]) + 3, BARN[2], BARN[1] - 1, BARN[2], 3)
	-- Wheat over the whole plain, water along both edges of the paths, hay in the wheat
	local r = math.ceil(PLAINS.R * 1.3)
	for x = PLAINS.X - r, PLAINS.X + r do
		for z = PLAINS.Z - r, PLAINS.Z + r do
			if ctx.IslandAt(x, z) == island and ctx.Inside(x, z, 3) and not plainsBusy(ctx, x, z) then
				local d = plainsPathDistance(x, z)
				if d == 3 then
					channel(ctx, x, z)
				elseif d > 3 then
					if ctx.Hash(x, 60, z) < 0.008 then
						hay(ctx, x, z)
					else
						sow(ctx, x, z, "Wheat")
					end
				end
			end
		end
	end
	for _, spot in
		{
			{ -24, -126 },
			{ 28, -84 },
			{ -22, -52 },
			{ 44, -150 },
			{ -60, -72 },
			{ 20, -24 },
			{ -56, -100 },
			{ 48, -72 },
		}
	do
		if ctx.World.Cells[key(spot[1], 0, spot[2])] == "Farmland" then
			scarecrow(ctx, spot[1], spot[2])
		end
	end
	-- Oaks and autumn trees round the rim, oaks on the rocky hill and the mesa
	Common.Forest(ctx, island, 9, 2, function(x, z)
		local onHill = hillHeight(ctx, x, z) > 6 or mesaHeight(ctx, x, z, MESA, 30) >= 24
		return not onHill and (ctx.Inside(x, z, 6) or plainsBusy(ctx, x, z) or ctx.Flat(x, z, 2))
	end, function(x, h, z)
		Trees.Oak(x, h, z, 4 + (x % 3), ctx.SetFree, "Wood", if (x + z) % 3 == 0 then "AutumnLeaves" else nil)
	end)
	-- Giant flowers round the edges
	local colors = { Color3.fromRGB(250, 214, 60), Color3.fromRGB(246, 236, 120), Color3.fromRGB(240, 150, 40) }
	for i = 1, 14 do
		local x, z = rimSpot(ctx, island, i / 14 * 2 * math.pi + 0.2)
		if x and z and not plainsBusy(ctx, x, z) then
			giantFlower(ctx, x, z, 10 + (i % 4) * 2, colors[i % #colors + 1])
		end
	end
	Common.CliffVines(ctx, island, 0.3)
	Common.Scatter(ctx, island, 0.05, 0.02, FLOWERS)
end

-- Veggie Gardens ----------------------------------------------------------------------------

-- A glasshouse: glass walls and roof on a stone footing, planters of flowers inside
local function glasshouse(ctx: Context.Context, x0: number, z0: number)
	local site = Build.Site(ctx.World, x0, z0, E)
	local hw, depth = 6, 12
	site:Fill(-hw, 0, 0, hw, 0, depth, "SmoothStone")
	site:Walls(-hw, 1, 0, hw, 1, depth, "StoneBricks")
	site:Walls(-hw, 2, 0, hw, 4, depth, "Glass")
	for _, u in { -hw, hw } do
		for v = 0, depth, 4 do
			site:Fill(u, 1, v, u, 4, v, "DarkPlanks")
		end
	end
	site:Roof(-hw, 0, hw, depth, 5, "Glass", "Glass", false)
	site:Clear(-1, 1, 0, 1, 3, 0)
	for _, u in { -4, -3, 3, 4 } do
		for v = 2, depth - 2 do
			site:Set(u, 1, v, "DarkPlanks")
			Decor.Flower(ctx.Decor, site:Pos(u, 1.5, v), FLOWERS[(u + v) % #FLOWERS + 1])
		end
	end
	Decor.Lantern(ctx.Decor, site:Pos(0, 4.4, 4), true, 22)
	Decor.Lantern(ctx.Decor, site:Pos(0, 4.4, 9), true, 22)
end

local function veggieGardens(ctx: Context.Context, island: Context.Island)
	for x = VEGGIE.X + 60, GLASSHOUSE[1] + 1, -1 do
		Common.Path(ctx, x, veggiePathZ(x), x, veggiePathZ(x), 5)
	end
	glasshouse(ctx, GLASSHOUSE[1], GLASSHOUSE[2])
	Common.ZoneSign(ctx, VEGGIE.X + 40, CROSS_Z - 5, E, "CARROTS", "FARMING 5", Signs.Woods.Oak)
	Common.ZoneSign(ctx, VEGGIE.X + 40, CROSS_Z + 5, E, "POTATOES", "FARMING 10", Signs.Woods.Oak)
	-- Long rows: carrots south of the path, potatoes north, water every fifth row
	for x = VEGGIE.X - 44, VEGGIE.X + 50 do
		local pathZ = veggiePathZ(x)
		for z = pathZ - 28, pathZ + 28 do
			local off = math.abs(z - pathZ)
			if
				off >= 4
				and ctx.IslandAt(x, z) == island
				and ctx.Inside(x, z, 3)
				and ctx.HeightAt(x, z) == 0
				and not near(x, z, GLASSHOUSE, 10)
			then
				if off % 5 == 0 then
					channel(ctx, x, z)
				else
					sow(ctx, x, z, if z < pathZ then "Carrot" else "Potato")
				end
			end
		end
	end
	for _, spot in
		{
			{ VEGGIE.X - 10, CROSS_Z - 11 },
			{ VEGGIE.X + 20, CROSS_Z - 18 },
			{ VEGGIE.X - 6, CROSS_Z + 12 },
			{ VEGGIE.X + 26, CROSS_Z + 19 },
		}
	do
		if ctx.World.Cells[key(spot[1], 0, spot[2])] == "Farmland" then
			scarecrow(ctx, spot[1], spot[2], Color3.fromRGB(150, 110, 50))
		end
	end
	for _, spot in { { VEGGIE.X - 20, CROSS_Z - 3 }, { VEGGIE.X + 14, CROSS_Z + 3 }, { VEGGIE.X + 44, CROSS_Z - 3 } } do
		ctx.SetFree(spot[1], 1, spot[2], "Crate")
		ctx.SetFree(spot[1] + 1, 1, spot[2], "Barrel")
		ctx.SetFree(spot[1], 2, spot[2], "Crate")
	end
	for x = VEGGIE.X + 56, VEGGIE.X - 40, -16 do
		Common.Lamp(ctx, x, veggiePathZ(x) + 3)
	end
	-- Oaks and spruces on the rocky hills round the gardens
	Common.Forest(ctx, island, 8, 3, function(x, z)
		return ctx.World.Cells[key(x, ctx.HeightAt(x, z), z)] == "Farmland"
			or math.abs(z - CROSS_Z) <= 31 and x > VEGGIE.X - 58
			or near(x, z, GLASSHOUSE, 12)
			or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		if ctx.Hash(x, 71, z) < 0.35 then
			Trees.Spruce(x, h, z, ctx.Rng:NextInteger(7, 9), ctx.SetFree)
		else
			Trees.Oak(x, h, z, 4 + (z % 2), ctx.SetFree)
		end
	end)
	Common.CliffVines(ctx, island, 0.25)
	Common.Scatter(ctx, island, 0.05, 0.04, FLOWERS)
end

-- Pumpkin Hollow ----------------------------------------------------------------------------

-- A pumpkin with a carved face glowing toward `out`, on the ground at (x, z)
local function jackOLantern(ctx: Context.Context, x: number, z: number, out: Vector3)
	local h = ctx.HeightAt(x, z) + 1
	ctx.SetFree(x, h, z, "Pumpkin")
	Decor.JackOLantern(ctx.Decor, ctx.Top(x, h, z) - Vector3.new(0, SIZE / 2, 0) + out * (SIZE / 2), out)
end

-- A market stall: a counter of crates under a striped awning on four posts
local function stall(ctx: Context.Context, x0: number, z0: number, crop: string, colors: { Color3 })
	local h = ctx.HeightAt(x0, z0)
	for _, dx in { -2, 2 } do
		for _, dz in { 0, 3 } do
			for y = 1, 3 do
				ctx.Set(x0 + dx, h + y, z0 + dz, "DarkPlanks")
			end
		end
	end
	for dx = -1, 1 do
		ctx.Set(x0 + dx, h + 1, z0, "Crate")
	end
	ctx.Set(x0 - 1, h + 2, z0, crop)
	ctx.Set(x0 + 1, h + 2, z0, crop)
	ctx.Set(x0, h + 1, z0 + 2, "Barrel")
	Decor.Awning(ctx.Decor, ctx.Top(x0, h + 3, z0 + 3) + Vector3.new(0, 0.3, 0), S, 5 * SIZE, colors)
	Decor.Lantern(ctx.Decor, ctx.Top(x0 + 2, h + 3, z0), false, 16)
end

local function pumpkinHollow(ctx: Context.Context, island: Context.Island)
	for z = HOLLOW.Z - 62, HOLLOW.Z + 60 do
		Common.Path(ctx, hollowPathX(z) - 2, z, hollowPathX(z) + 2, z, 1)
	end
	for z = HOLLOW.Z - 54, HOLLOW.Z + 54, 10 do
		jackOLantern(ctx, hollowPathX(z) - 3, z, E)
		jackOLantern(ctx, hollowPathX(z + 5) + 3, z + 5, W)
	end
	barn(ctx, HARVEST_BARN[1], HARVEST_BARN[2], W, 6, 10, 6)
	stall(ctx, -10, HOLLOW.Z - 30, "Pumpkin", { Color3.fromRGB(230, 120, 40), Color3.fromRGB(240, 234, 222) })
	-- Pumpkin patches over the rolling ground between the trees
	local r = math.ceil(HOLLOW.R * 1.3)
	for x = HOLLOW.X - r, HOLLOW.X + r do
		for z = HOLLOW.Z - r, HOLLOW.Z + r do
			if
				ctx.IslandAt(x, z) == island
				and ctx.Inside(x, z, 4)
				and math.abs(x - hollowPathX(z)) >= 4
				and not ctx.Flat(x, z, 2)
				and not (x > HARVEST_BARN[1] - 6 and x < HARVEST_BARN[1] + 14 and math.abs(z - HARVEST_BARN[2]) < 10)
				and not near(x, z, { -10, HOLLOW.Z - 28 }, 6)
				and ctx.Noise(x, z, 11, 50) > 0.08
			then
				if ctx.Hash(x, 63, z) < 0.012 then
					hay(ctx, x, z)
				else
					sow(ctx, x, z, "Pumpkin")
				end
			end
		end
	end
	for _, spot in { { -28, 66 }, { 30, 92 }, { -20, 130 }, { 22, 54 } } do
		if ctx.World.Cells[key(spot[1], ctx.HeightAt(spot[1], spot[2]), spot[2])] == "Farmland" then
			scarecrow(ctx, spot[1], spot[2], Color3.fromRGB(150, 60, 40))
		end
	end
	-- Autumn trees between the patches, with leaf piles under them
	Common.Forest(ctx, island, 7, 3, function(x, z)
		return ctx.World.Cells[key(x, ctx.HeightAt(x, z), z)] == "Farmland"
			or math.abs(x - hollowPathX(z)) <= 4
			or ctx.Flat(x, z, 3)
			or (x > HARVEST_BARN[1] - 7 and x < HARVEST_BARN[1] + 15 and math.abs(z - HARVEST_BARN[2]) < 11)
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
	for z = HOLLOW.Z - 50, HOLLOW.Z + 50, 20 do
		Common.Lamp(ctx, hollowPathX(z) + 3, z + 2)
	end
	local colors = { Color3.fromRGB(240, 150, 40), Color3.fromRGB(250, 214, 60) }
	for i = 1, 8 do
		local x, z = rimSpot(ctx, island, i / 8 * 2 * math.pi + 0.5)
		if x and z then
			giantFlower(ctx, x, z, 9 + (i % 3) * 2, colors[i % #colors + 1])
		end
	end
	Common.CliffVines(ctx, island, 0.3)
	Common.Scatter(ctx, island, 0.04, 0, {})
	Decor.Falling(
		ctx.Decor,
		ctx.Top(HOLLOW.X, 18, HOLLOW.Z),
		Vector2.new(HOLLOW.R * 2 * SIZE, HOLLOW.R * 2 * SIZE),
		"Leaves"
	)
end

-- Melon Oasis -------------------------------------------------------------------------------

local function melonOasis(ctx: Context.Context, island: Context.Island)
	for x = OASIS.X - 56, OASIS.X + 58 do
		Common.Path(ctx, x, oasisPathZ(x), x, oasisPathZ(x), 5, "Gravel")
	end
	Common.Path(ctx, OASIS_POOL[1], CROSS_Z + 3, OASIS_POOL[1], OASIS_POOL[2] - 14, 3, "Gravel")
	local water = Common.Pond(ctx, OASIS_POOL[1], OASIS_POOL[2], 12, "Sand")
	for i = 1, 8 do
		Decor.LilyPad(
			ctx.Decor,
			water.Position + Vector3.new(math.cos(i * 0.8) * 18, water.Size.Y / 2, math.sin(i * 0.8) * 18)
		)
	end
	-- Palms round the pool
	for i = 0, 11 do
		local angle = i / 12 * math.pi * 2 + 0.3
		local x = math.round(OASIS_POOL[1] + math.cos(angle) * 15.5)
		local z = math.round(OASIS_POOL[2] + math.sin(angle) * 15.5)
		if ctx.Inside(x, z, 2) and math.abs(x - OASIS_POOL[1]) > 2 then
			Decor.PalmTree(ctx.Decor, ctx.Top(x, ctx.HeightAt(x, z), z), 12 + (i % 3) * 3, angle + math.pi / 2)
		end
	end
	for _, spot in STALLS do
		stall(ctx, spot[1], spot[2], "Melon", { Color3.fromRGB(64, 150, 70), Color3.fromRGB(240, 234, 222) })
	end
	-- Melon patches over the dunes
	local r = math.ceil(OASIS.R * 1.3)
	for x = OASIS.X - r, OASIS.X + r do
		for z = OASIS.Z - r, OASIS.Z + r do
			if
				ctx.IslandAt(x, z) == island
				and ctx.Inside(x, z, 4)
				and math.abs(z - oasisPathZ(x)) >= 4
				and not near(x, z, OASIS_POOL, 19)
				and mesaHeight(ctx, x, z, OASIS_MESA, 20) == 0
				and roughDistance(ctx, x, z, OASIS_MESA) > OASIS_MESA.R + 2
				and not near(x, z, STALLS[1], 6)
				and not near(x, z, STALLS[2], 6)
				and not (math.abs(x - OASIS_POOL[1]) <= 2 and z > CROSS_Z and z < OASIS_POOL[2])
				and not ctx.Flat(x, z, 2)
				and ctx.Noise(x, z, 10, 51) > 0.06
			then
				sow(ctx, x, z, "Melon")
			end
		end
	end
	-- Cacti over the rest of the sand
	for i = 1, 120 do
		local x = OASIS.X + ctx.Rng:NextInteger(-OASIS.R, OASIS.R)
		local z = OASIS.Z + ctx.Rng:NextInteger(-OASIS.R, OASIS.R)
		local h = ctx.HeightAt(x, z)
		if
			ctx.Inside(x, z, 3)
			and ctx.World.Cells[key(x, h, z)] == "Sand"
			and not ctx.World.Cells[key(x, h + 1, z)]
			and not near(x, z, OASIS_POOL, 19)
			and math.abs(z - oasisPathZ(x)) > 4
		then
			Decor.Cactus(ctx.Decor, ctx.Top(x, h, z), 3 + (i % 4) * 1.4, i % 3)
		end
	end
	for x = OASIS.X - 50, OASIS.X + 50, 16 do
		Common.Lamp(ctx, x, oasisPathZ(x) + 3)
	end
	-- Twisted trees on the mesa
	for i = 1, 4 do
		local angle = i / 4 * 2 * math.pi
		local x = math.round(OASIS_MESA.X + math.cos(angle) * 4)
		local z = math.round(OASIS_MESA.Z + math.sin(angle) * 4)
		Trees.Oak(x, ctx.HeightAt(x, z), z, 5, ctx.SetFree, "SpruceWood", "Leaves")
	end
	Common.Scatter(ctx, island, 0.05, 0.03, FLOWERS)
end

-- The world ----------------------------------------------------------------------------------

function Farming.Build(ctx: Context.Context)
	-- Bridge ends, buildings and the gardens stay flat
	ctx.Flatten(-118, CROSS_Z - 3, -60, CROSS_Z + 3)
	ctx.Flatten(60, CROSS_Z - 3, 118, CROSS_Z + 3)
	ctx.Flatten(-3, -26, 3, 34)
	ctx.Flatten(VEGGIE.X - 56, CROSS_Z - 30, VEGGIE.X + 66, CROSS_Z + 30)
	ctx.Flatten(OASIS.X - 64, CROSS_Z - 4, OASIS.X + 60, CROSS_Z + 4)
	for _, spot in STALLS do
		ctx.Flatten(spot[1] - 4, spot[2] - 3, spot[1] + 4, spot[2] + 5)
	end
	ctx.Flatten(OASIS_POOL[1] - 18, OASIS_POOL[2] - 18, OASIS_POOL[1] + 18, OASIS_POOL[2] + 18)
	ctx.Flatten(-14, HOLLOW.Z - 34, -6, HOLLOW.Z - 26)
	ctx.Flatten(HARVEST_BARN[1] - 3, HARVEST_BARN[2] - 9, HARVEST_BARN[1] + 13, HARVEST_BARN[2] + 9)

	local plains = ctx.Island({
		Name = "Wheat Plains",
		X = PLAINS.X,
		Z = PLAINS.Z,
		Radius = PLAINS.R,
		Column = function(x, z)
			return plainsColumn(ctx, x, z)
		end,
		Fill = function(x, y, z, depth)
			if mesaHeight(ctx, x, z, MESA, 30) > 0 then
				return BANDS[y % #BANDS + 1]
			elseif hillHeight(ctx, x, z) > 0 then
				return if depth == 1 then "Dirt" else "Stone"
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
		Fill = function(_x, y, _z, depth)
			if y > 0 then
				return if depth == 1 then "Dirt" else "Stone"
			end
			return nil
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
		Fill = function(x, y, z, _depth)
			if mesaHeight(ctx, x, z, OASIS_MESA, 20) > 0 then
				return BANDS[y % #BANDS + 1]
			end
			return nil
		end,
	})
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
		}
	do
		-- The ones off the Melon Oasis are sandy
		ctx.Islet(spot[1], spot[2], spot[3], spot[4], if spot[1] > 240 then "Sand" else nil)
		if spot[4] >= 4 then
			Trees.Oak(spot[1], spot[2], spot[3], 5, ctx.SetFree, "Wood", "AutumnLeaves")
		end
	end

	ctx.Bridge(-118, CROSS_Z, -62, CROSS_Z)
	ctx.Bridge(62, CROSS_Z, 118, CROSS_Z)
	ctx.Bridge(0, -24, 0, 32)
	Common.Arrows(ctx, 8, CROSS_Z - 8, S, {
		{ Text = "VEGGIE GARDENS", Toward = W },
		{ Text = "PUMPKIN HOLLOW", Toward = N },
		{ Text = "MELON OASIS", Toward = E },
	})
	Common.ZoneSign(ctx, VEGGIE.X + 58, CROSS_Z - 5, E, "VEGGIE GARDENS", "FARMING 5 + 10", Signs.Woods.Oak)
	Common.ZoneSign(ctx, OASIS.X - 58, CROSS_Z - 5, W, "MELON OASIS", "FARMING 25", Signs.Woods.Sand)
	Common.ZoneSign(ctx, HOLLOW.X + 5, HOLLOW.Z - 60, S, "PUMPKIN HOLLOW", "FARMING 15", Signs.Woods.Spruce)
	for z = -146, -26, 14 do
		Common.Lamp(ctx, mainPathX(z) + (if z % 28 == 0 then 4 else -4), z)
	end
	for x = -60, 60, 20 do
		Common.Lamp(ctx, x, crossPathZ(x) - 4)
	end

	wheatPlains(ctx, plains)
	veggieGardens(ctx, veggie)
	pumpkinHollow(ctx, hollow)
	melonOasis(ctx, oasis)
	Common.CliffVines(ctx, oasis, 0.2)
end

return Farming
