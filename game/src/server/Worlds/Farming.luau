--!strict
-- The Farming World: a farmstead.
--   Three fenced fields of wild crops, rows of farmland with water channels between them
--   and a scarecrow in each: Wheat (anyone), Carrots (Farming 5) and Potatoes (Farming 10).
--   A red barn full of hay, a windmill whose sails turn, a farmhouse with a flower
--   garden, a pond with a little dock, and a farmyard with a well in the middle.
-- Crops are fields (WorldService): click a ripe one to harvest it, and it grows back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Build = require(script.Parent.Parent.Util.Build)
local Decor = require(script.Parent.Parent.Util.Decor)
local Signs = require(script.Parent.Parent.Util.Signs)
local Trees = require(script.Parent.Parent.Util.Trees)
local Context = require(script.Parent.Context)

local SIZE = Blocks.Size

local Farming = {}

Farming.Radius = 34
Farming.Haze = 0.1

local FLOWERS = {
	Color3.fromRGB(222, 62, 52),
	Color3.fromRGB(242, 212, 64),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(230, 120, 190),
	Color3.fromRGB(110, 132, 230),
}

type FieldInfo = { Crop: string, X1: number, X2: number, Z1: number, Z2: number, Sign: string, Width: number }

-- Every fourth row is a water channel
local FIELDS: { FieldInfo } = {
	{ Crop = "Wheat", X1 = -24, X2 = -10, Z1 = -14, Z2 = -4, Sign = "WHEAT", Width = 2 },
	{ Crop = "Carrot", X1 = 10, X2 = 22, Z1 = -14, Z2 = -5, Sign = "CARROTS · FARMING 5", Width = 4 },
	{ Crop = "Potato", X1 = -7, X2 = 7, Z1 = 12, Z2 = 19, Sign = "POTATOES · FARMING 10", Width = 5 },
}

local function inField(x: number, z: number, margin: number): boolean
	for _, f in FIELDS do
		if x >= f.X1 - margin and x <= f.X2 + margin and z >= f.Z1 - margin and z <= f.Z2 + margin then
			return true
		end
	end
	return false
end

local function column(ctx: Context.Context, x: number, z: number): (string, number)
	local path = (math.abs(x) <= 1 and z < 10) or (z >= 1 and z <= 3 and math.abs(x) <= 26)
	if path then
		return "Path", 0
	end
	return if ctx.Hash(x, 0, z) < 0.05 and not inField(x, z, 1) then "FlowerGrass" else "Grass", 0
end

-- A scarecrow: a post with a crossbar, a straw head, an old hat and a patched shirt
local function scarecrow(ctx: Context.Context, top: Vector3)
	local base = CFrame.new(top)
	Decor.Piece(ctx.Decor, "Wood", Vector3.new(0.5, 5, 0.5), base * CFrame.new(0, 2.5, 0))
	Decor.Piece(ctx.Decor, "Wood", Vector3.new(4, 0.4, 0.4), base * CFrame.new(0, 3.6, 0))
	Decor.Part(
		ctx.Decor,
		"Shirt",
		Vector3.new(2.2, 1.8, 0.8),
		base * CFrame.new(0, 3.3, 0),
		Color3.fromRGB(70, 104, 150),
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

local function fields(ctx: Context.Context)
	for _, info in FIELDS do
		local cx, cz = math.round((info.X1 + info.X2) / 2), math.round((info.Z1 + info.Z2) / 2)
		for x = info.X1, info.X2 do
			for z = info.Z1, info.Z2 do
				if (z - info.Z1) % 4 == 3 then
					-- A water channel: a trench with water in it
					ctx.Set(x, 0, z, nil)
					ctx.Set(x, -1, z, "Dirt")
				elseif x == cx and z == cz then
					ctx.Set(x, 0, z, "Farmland")
					scarecrow(ctx, ctx.Top(x, 0, z))
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
		-- A fence all round with a gate gap in the middle of the near side
		local function corner(x: number, z: number): Vector3
			return ctx.Top(x, 0, z)
		end
		local x1, x2, z1, z2 = info.X1 - 1, info.X2 + 1, info.Z1 - 1, info.Z2 + 1
		local gate = if info.Z1 > 3 then z1 else z2
		local mid = math.round((x1 + x2) / 2)
		for _, z in { z1, z2 } do
			if z == gate then
				Decor.Fence(ctx.Decor, corner(x1, z), corner(mid - 1, z))
				Decor.Fence(ctx.Decor, corner(mid + 1, z), corner(x2, z))
			else
				Decor.Fence(ctx.Decor, corner(x1, z), corner(x2, z))
			end
		end
		Decor.Fence(ctx.Decor, corner(x1, z1), corner(x1, z2))
		Decor.Fence(ctx.Decor, corner(x2, z1), corner(x2, z2))
		-- A signpost by the gate
		local sx = mid + 2
		local sz = gate + (if gate == z1 then -1 else 1)
		ctx.Set(sx, 1, sz, "Wood")
		local facing = if gate == z1 then -Vector3.zAxis else Vector3.zAxis
		Signs.Board(
			ctx.Decor,
			`{info.Crop}Sign`,
			info.Sign,
			ctx.Top(sx, 1, sz) + Vector3.new(0, SIZE * 0.43, 0),
			facing,
			info.Width
		)
	end
end

-- The barn: red board walls with white trim, a slate roof, a big door to the farmyard
-- and hay stacked inside and out
local function barn(ctx: Context.Context)
	local site = Build.Site(ctx.World, -17, 13, Vector3.xAxis)
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
	-- Hay loft door and trim on the front gable
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

-- The windmill: a stone and plaster tower with a red cap and four turning sails
local function windmill(ctx: Context.Context)
	local x0, z0 = 19, 14
	for y = 1, 10 do
		local r = if y <= 3 then 2 elseif y <= 7 then 2 else 1
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
	cap:Roof(-1, 0, 1, 2, 11, "RoofRed", "Plaster", false)
	-- The sails turn round an axle sticking out of the front (facing south)
	-- (in front of the tower's wider lower half, so they clear it)
	local hub = ctx.Top(x0, 9, z0 - 3) - Vector3.new(0, SIZE / 2, 0)
	local towerFace = ctx.Top(x0, 9, z0 - 1).Z - SIZE / 2
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
		Decor.Piece(sails, "DarkPlanks", Vector3.new(0.5, 11, 0.4), spin * CFrame.new(0, 5.8, 0))
		local sail = Decor.Part(
			sails,
			"Sail",
			Vector3.new(2.4, 8, 0.15),
			spin * CFrame.new(1.4, 6.6, 0.1),
			Color3.fromRGB(238, 232, 218),
			Enum.Material.Fabric
		)
		sail.CanCollide = false
	end
	sails.WorldPivot = CFrame.lookAt(hub, hub - Vector3.zAxis)
	sails.Parent = ctx.Decor
	Decor.Spin(sails, 25)
end

-- The farmhouse: plaster and timber, thatched, with a fenced flower garden
local function farmhouse(ctx: Context.Context)
	local site = Build.Site(ctx.World, -14, -21, Vector3.xAxis)
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
	for v = -1, -13, -1 do
		local x, z = site:Cell(0, v)
		if ctx.World.Cells[`{x},0,{z}`] == "Grass" or ctx.World.Cells[`{x},0,{z}`] == "FlowerGrass" then
			ctx.Set(x, 0, z, "Path")
		end
	end
end

-- The pond: sandy shore, lily pads, reeds and a little plank dock
local function pond(ctx: Context.Context)
	local cx, cz, r = 16, -22, 4.4
	for x = cx - 6, cx + 6 do
		for z = cz - 6, cz + 6 do
			local d = math.sqrt((x - cx) ^ 2 + (z - cz) ^ 2)
			if d <= r - 1 then
				ctx.Set(x, 0, z, nil)
				ctx.Set(x, -1, z, "Sand")
			elseif d <= r + 0.6 then
				ctx.Set(x, 0, z, "Sand")
			end
		end
	end
	Decor.Water(
		ctx.Decor,
		ctx.Top(cx, -1, cz) + Vector3.new(0, SIZE * 0.75, 0),
		Vector2.new(7 * SIZE, 7 * SIZE),
		SIZE * 0.8
	)
	for i = 1, 5 do
		local angle = i * 1.3
		local at = ctx.Top(cx, -1, cz) + Vector3.new(math.cos(angle) * 6, SIZE * 0.78, math.sin(angle) * 6)
		Decor.Part(ctx.Decor, "LilyPad", Vector3.new(1.4, 0.1, 1.4), CFrame.new(at), Color3.fromRGB(70, 140, 60)).CastShadow =
			false
	end
	for x = cx - 6, cx - 3 do
		ctx.Set(x, 0, cz, "DarkPlanks")
	end
	Decor.Lantern(ctx.Decor, ctx.Top(cx - 6, 0, cz + 1), false, 14)
end

-- The farmyard: a well with a little roof, a water trough and a cart of hay
local function farmyard(ctx: Context.Context)
	local wx, wz = 5, 6
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
	-- Trough
	for x = -6, -4 do
		ctx.Set(x, 1, 6, "DarkPlanks")
	end
	Decor.Water(ctx.Decor, ctx.Top(-5, 1, 6) - Vector3.new(0, 0.2, 0), Vector2.new(2.6 * SIZE, 0.8 * SIZE), 0.4)
	-- A cart heaped with hay
	local at = ctx.Top(-4, 0, -1)
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
	ctx.Set(-7, 1, 4, "HayBale")
	ctx.Set(-7, 2, 4, "HayBale")
	ctx.Set(-8, 1, 4, "HayBale")
end

local function scatter(ctx: Context.Context)
	local rng = ctx.Rng
	for x = -ctx.Radius, ctx.Radius do
		for z = -ctx.Radius, ctx.Radius do
			local ground = ctx.World.Cells[`{x},0,{z}`]
			if
				(ground == "Grass" or ground == "FlowerGrass")
				and not ctx.World.Cells[`{x},1,{z}`]
				and not inField(x, z, 1)
			then
				local roll = rng:NextNumber()
				if roll < 0.05 then
					Decor.Grass(ctx.Decor, ctx.Top(x, 0, z), rng)
				elseif roll < 0.07 then
					Decor.Flower(ctx.Decor, ctx.Top(x, 0, z), FLOWERS[rng:NextInteger(1, #FLOWERS)])
				end
			end
		end
	end
end

function Farming.Build(ctx: Context.Context)
	ctx.Ground(function(x, z)
		return column(ctx, x, z)
	end)
	fields(ctx)
	barn(ctx)
	windmill(ctx)
	farmhouse(ctx)
	pond(ctx)
	farmyard(ctx)
	for _, spot in { { -28, 4 }, { -26, -20 }, { 27, 8 }, { 27, -10 }, { -12, 26 }, { 11, 26 }, { -29, -8 }, { 0, 28 } } do
		if ctx.Inside(spot[1], spot[2], 3) then
			Trees.Oak(spot[1], 0, spot[2], 4 + (spot[1] % 2), ctx.SetFree)
		end
	end
	for _, z in { -16, -8, 6 } do
		ctx.Set(2, 1, z, "Wood")
		ctx.Set(2, 2, z, "Wood")
		Decor.Lantern(ctx.Decor, ctx.Top(2, 2, z), false, 18)
	end
	scatter(ctx)
end

return Farming
