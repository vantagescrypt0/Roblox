--!strict
-- The Woodcutting World: a forest on rolling hills.
--   A river winds across the middle with sandy banks and a wooden bridge where the path
--   crosses. By the arrival portals is a lumber camp: a log cabin, a sawmill with a
--   spinning blade, log piles and a campfire.
--   The forest: oaks and big old oaks all over the hills, every log and leaf a node that
--   grows back, with bushes, fallen logs, mushrooms, flowers and tall grass between them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Build = require(script.Parent.Parent.Util.Build)
local Decor = require(script.Parent.Parent.Util.Decor)
local Trees = require(script.Parent.Parent.Util.Trees)
local Context = require(script.Parent.Context)

local SIZE = Blocks.Size

local Woodcutting = {}

Woodcutting.Radius = 36
Woodcutting.Haze = 0.2

local FLOWERS = {
	Color3.fromRGB(222, 62, 52),
	Color3.fromRGB(242, 212, 64),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(150, 110, 220),
}

-- The camp, by the arrival square (kept clear of trees)
local CAMP = { X1 = 9, X2 = 24, Z1 = -27, Z2 = -13 }

-- Where the river runs: its middle at each x
local function riverZ(x: number): number
	return 6 + 3 * math.sin(x * 0.13)
end

local function inCamp(x: number, z: number, margin: number): boolean
	return x >= CAMP.X1 - margin and x <= CAMP.X2 + margin and z >= CAMP.Z1 - margin and z <= CAMP.Z2 + margin
end

local function onPath(x: number, z: number): boolean
	return math.abs(x) <= 1 and z > -26
end

local function hills(x: number, z: number): number
	local h = 1.4 + 1.1 * math.sin(x * 0.16 + 1.3) + 1.0 * math.cos(z * 0.13 - 0.5) + 0.6 * math.sin((x - z) * 0.09)
	return math.clamp(math.round(h), 0, 4)
end

local function column(ctx: Context.Context, x: number, z: number): (string, number)
	local river = math.abs(z - riverZ(x))
	if river <= 1.5 then
		return "Sand", -1
	elseif river <= 2.6 then
		return "Sand", 0
	end
	local h = hills(x, z)
	if ctx.NearArrival(x, z, 3) or inCamp(x, z, 1) or river <= 4 then
		h = 0
	elseif ctx.NearArrival(x, z, 6) or inCamp(x, z, 3) or river <= 6 then
		h = math.min(h, 1)
	end
	if onPath(x, z) then
		return "Path", h
	end
	return if ctx.Hash(x, 0, z) < 0.06 then "FlowerGrass" else "Grass", h
end

-- The river: water over its sandy bed, one strip per column
local function river(ctx: Context.Context)
	for x = -ctx.Radius - 2, ctx.Radius + 2 do
		local z = riverZ(x)
		local zc = math.round(z)
		if ctx.Inside(x, zc, 0) then
			Decor.Water(
				ctx.Decor,
				ctx.Top(x, -1, zc) + Vector3.new(0, SIZE * 0.8, (z - zc) * SIZE),
				Vector2.new(SIZE, 3.2 * SIZE),
				SIZE * 0.85
			)
		end
	end
	-- The bridge where the path crosses, with rails and a lantern at each end
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
	for _, z in { z0 - 4, z0 + 4 } do
		ctx.Set(2, ctx.HeightAt(2, z) + 1, z, "Wood")
		Decor.Lantern(ctx.Decor, ctx.Top(2, ctx.HeightAt(2, z) + 1, z), false, 18)
	end
end

-- A log cabin: log walls, a slate roof, a chimney, a bed and crates inside
local function cabin(ctx: Context.Context)
	local site = Build.Site(ctx.World, 16, -16, -Vector3.xAxis)
	site:Fill(-3, 0, 0, 3, 0, 6, "DarkPlanks")
	site:Walls(-3, 1, 0, 3, 3, 6, "Wood")
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
local function sawmill(ctx: Context.Context)
	local x0, z0 = 13, -24
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

local function forest(ctx: Context.Context)
	local placed: { Vector2 } = {}
	local rng = ctx.Rng
	for gx = -ctx.Radius + 4, ctx.Radius - 4, 5 do
		for gz = -ctx.Radius + 4, ctx.Radius - 4, 5 do
			local x = gx + rng:NextInteger(-1, 1)
			local z = gz + rng:NextInteger(-1, 1)
			local spot = Vector2.new(x, z)
			local ok = ctx.Inside(x, z, 4)
				and not ctx.NearArrival(x, z, 4)
				and not inCamp(x, z, 3)
				and math.abs(z - riverZ(x)) > 4
				and math.abs(x) > 3
			for _, other in placed do
				if ok and (other - spot).Magnitude < 6 then
					ok = false
				end
			end
			if ok then
				table.insert(placed, spot)
				local h = ctx.HeightAt(x, z)
				if rng:NextNumber() < 0.3 then
					Trees.BigOak(x, h, z, rng:NextInteger(6, 7), ctx.Node)
				else
					Trees.Oak(x, h, z, rng:NextInteger(4, 6), ctx.Node)
				end
				if rng:NextNumber() < 0.25 then
					local mx, mz = x + rng:NextInteger(-1, 1), z + (if rng:NextNumber() < 0.5 then -1 else 1)
					Decor.Mushroom(ctx.Decor, ctx.Top(mx, ctx.HeightAt(mx, mz), mz), rng:NextNumber() < 0.5)
				end
			end
		end
	end
	-- Bushes and fallen logs between the trees
	for _ = 1, 40 do
		local x, z = rng:NextInteger(-ctx.Radius + 3, ctx.Radius - 3), rng:NextInteger(-ctx.Radius + 3, ctx.Radius - 3)
		if
			ctx.Inside(x, z, 3)
			and not ctx.NearArrival(x, z, 2)
			and not inCamp(x, z, 1)
			and not onPath(x, z)
			and math.abs(z - riverZ(x)) > 3
		then
			local h = ctx.HeightAt(x, z)
			ctx.SetFree(x, h + 1, z, "Leaves")
			if rng:NextNumber() < 0.4 then
				ctx.SetFree(x + 1, h + 1, z, "Leaves")
			end
		end
	end
	for _, spot in { { -22, -8 }, { 18, 16 }, { -14, 22 }, { 25, 0 } } do
		local x, z = spot[1], spot[2]
		local h = ctx.HeightAt(x, z)
		for dx = 0, 3 do
			ctx.SetFree(x + dx, h + 1, z, "Wood")
		end
		Decor.Mushroom(ctx.Decor, ctx.Top(x + 1, h + 1, z), false)
	end
end

-- Lantern posts along the path
local function pathLights(ctx: Context.Context)
	for z = -20, 28, 8 do
		local x = 2
		if math.abs(z - riverZ(x)) > 4 and ctx.Inside(x, z, 2) then
			local h = ctx.HeightAt(x, z)
			ctx.Set(x, h + 1, z, "Wood")
			ctx.Set(x, h + 2, z, "Wood")
			Decor.Lantern(ctx.Decor, ctx.Top(x, h + 2, z), false, 18)
		end
	end
end

-- Tall grass and flowers on open ground (after everything else)
local function scatter(ctx: Context.Context)
	local rng = ctx.Rng
	for x = -ctx.Radius, ctx.Radius do
		for z = -ctx.Radius, ctx.Radius do
			local h = ctx.HeightAt(x, z)
			local ground = h >= 0 and ctx.World.Cells[`{x},{h},{z}`]
			if (ground == "Grass" or ground == "FlowerGrass") and not ctx.World.Cells[`{x},{h + 1},{z}`] then
				local roll = rng:NextNumber()
				if roll < 0.07 then
					Decor.Grass(ctx.Decor, ctx.Top(x, h, z), rng)
				elseif roll < 0.09 then
					Decor.Flower(ctx.Decor, ctx.Top(x, h, z), FLOWERS[rng:NextInteger(1, #FLOWERS)])
				end
			end
		end
	end
end

function Woodcutting.Build(ctx: Context.Context)
	ctx.Ground(function(x, z)
		return column(ctx, x, z)
	end)
	river(ctx)
	cabin(ctx)
	sawmill(ctx)
	campfire(ctx, 21, -21)
	-- Path from the main path to the cabin door
	for x = 2, 15 do
		ctx.Set(x, 0, -16, "Path")
	end
	forest(ctx)
	pathLights(ctx)
	scatter(ctx)
end

return Woodcutting
