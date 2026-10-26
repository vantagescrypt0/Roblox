--!strict
-- The Mining World: a quarry camp at the foot of a mountain with a mine in it.
--   The camp     gravel yards between the arrival portals and the mountain: a miner's
--                hut, a tent by a campfire, carts of ore on rails, crates and barrels,
--                and a few rocky outcrops to mine on the way in
--   The mountain grassy slopes and mossy cliffs, with a timber-framed cave mouth
--   The mine     a main tunnel with timber supports, hanging lanterns and rails, opening
--                into a great cavern with an underground pool; side tunnels lead west and
--                east to two smaller chambers
-- Every wall of the mine is stone with coal and iron ore in it (more iron in the deep
-- chambers), two blocks thick: mine a wall and it grows back. Behind that is dark stone,
-- as far as anyone can dig. The mountain's outside, the floors and the timbers can't be
-- broken.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Build = require(script.Parent.Parent.Util.Build)
local Decor = require(script.Parent.Parent.Util.Decor)
local Signs = require(script.Parent.Parent.Util.Signs)
local Trees = require(script.Parent.Parent.Util.Trees)
local Context = require(script.Parent.Context)

local SIZE = Blocks.Size
local key = BlockWorld.key

local Mining = {}

Mining.Radius = 36
Mining.Haze = 0.6
Mining.Caves = true

-- The mountain: an oval hill centred north of the camp
local MX, MZ, RX, RZ, PEAK = 0, 14, 28, 17, 17

type Tunnel = { Points: { Vector2 }, Width: number, Height: number }
type Chamber = { Centre: Vector2, Radii: Vector3 }

local TUNNELS: { Tunnel } = {
	{ Points = { Vector2.new(0, -9), Vector2.new(0, 4), Vector2.new(-1, 10) }, Width = 2.6, Height = 4.3 },
	{
		Points = { Vector2.new(-1, 9), Vector2.new(-8, 11), Vector2.new(-14, 13), Vector2.new(-18, 17) },
		Width = 1.9,
		Height = 3.4,
	},
	{
		Points = { Vector2.new(1, 10), Vector2.new(8, 9), Vector2.new(14, 11), Vector2.new(17, 16) },
		Width = 1.9,
		Height = 3.4,
	},
}
local CHAMBERS: { Chamber } = {
	{ Centre = Vector2.new(0, 17), Radii = Vector3.new(8.5, 7.5, 6.5) }, -- the great cavern
	{ Centre = Vector2.new(-19, 18), Radii = Vector3.new(4.6, 4.6, 4.2) },
	{ Centre = Vector2.new(18, 17), Radii = Vector3.new(4.6, 4.6, 4.2) },
}
-- Main-tunnel timber frames, by z
local SUPPORTS = { -2, 2, 6 }

-- Height of the mountain at (x, z), before making room for the caves (0 = no mountain)
local function slope(x: number, z: number): number
	local e = math.sqrt(((x - MX) / RX) ^ 2 + ((z - MZ) / RZ) ^ 2)
	if e >= 1 then
		return 0
	end
	local ridge = 2.5 * math.sin(x * 0.35) * math.cos(z * 0.3) + 1.5 * math.sin((x + z) * 0.21)
	return math.max(0, math.floor(PEAK * (1 - e * e) ^ 0.75 + ridge))
end

-- Horizontal distance from p to the segment a-b
local function segmentDistance(p: Vector2, a: Vector2, b: Vector2): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

-- Is (x, y, z) inside the mine (with a little noise so the walls are rough)?
local function carved(ctx: Context.Context, x: number, y: number, z: number): boolean
	if y < 1 then
		return false
	end
	local p = Vector2.new(x, z)
	local rough = (ctx.Hash(x, y, z) - 0.5) * 0.35
	for _, tunnel in TUNNELS do
		for i = 1, #tunnel.Points - 1 do
			local d = segmentDistance(p, tunnel.Points[i], tunnel.Points[i + 1])
			if (d / tunnel.Width) ^ 2 + ((y - 1) / tunnel.Height) ^ 2 <= 1 + rough then
				return true
			end
		end
	end
	for _, chamber in CHAMBERS do
		local r = chamber.Radii
		local c = chamber.Centre
		if ((x - c.X) / r.X) ^ 2 + ((y - 1) / r.Y) ^ 2 + ((z - c.Y) / r.Z) ^ 2 <= 1 + rough then
			return true
		end
	end
	return false
end

-- Ore in a mine wall: the deep chambers have more iron
local function ore(ctx: Context.Context, x: number, y: number, z: number): string
	local deep = z > 12 or math.abs(x) > 12
	local roll = ctx.Hash(x + 400, y, z)
	if roll < (if deep then 0.12 else 0.06) then
		return "IronOre"
	elseif roll < (if deep then 0.3 else 0.22) then
		return "CoalOre"
	end
	return "Stone"
end

-- Ground of the camp: gravel yards and a path in the middle, grass round the edge
local function column(ctx: Context.Context, x: number, z: number): (string, number)
	if not ctx.Inside(x, z, 4) then
		return "Grass", 0
	end
	if math.abs(x) <= 1 and z < -4 then
		return "Path", 0
	end
	local roll = ctx.Hash(x, 0, z)
	return if roll < 0.12 then "Cobblestone" elseif roll < 0.25 then "Path" else "Gravel", 0
end

local function buildMountain(ctx: Context.Context)
	local solid: { [string]: boolean } = {}
	local cave: { [string]: boolean } = {}
	local heights: { [string]: number } = {}

	-- How high each column goes: the slope, raised over the caves so they keep a roof at
	-- least three blocks thick, blending into the slopes around them
	local roof: { [string]: number } = {}
	for x = MX - RX, MX + RX do
		for z = MZ - RZ, MZ + RZ do
			if slope(x, z) > 0 then
				local top = 0
				for y = 1, 14 do
					if carved(ctx, x, y, z) then
						top = y
					end
				end
				if top > 0 then
					roof[`{x},{z}`] = top + 3
				end
			end
		end
	end
	for x = MX - RX, MX + RX do
		for z = MZ - RZ, MZ + RZ do
			local h = slope(x, z)
			if h > 0 then
				for dx = -5, 5 do
					for dz = -5, 5 do
						local need = roof[`{x + dx},{z + dz}`]
						if need then
							h = math.max(h, math.floor(need - 0.7 * math.sqrt(dx * dx + dz * dz)))
						end
					end
				end
				heights[`{x},{z}`] = h
				for y = 1, h do
					local k = key(x, y, z)
					if carved(ctx, x, y, z) then
						cave[k] = true
					else
						solid[k] = true
					end
				end
				ctx.Set(x, 0, z, "Gravel")
			end
		end
	end

	-- How far each solid cell is from the mine (up to 2)
	local near: { [string]: boolean } = {}
	for k in cave do
		local x, y, z = BlockWorld.unkey(k)
		for dx = -2, 2 do
			for dy = -2, 2 do
				for dz = -2, 2 do
					near[key(x + dx, y + dy, z + dz)] = true
				end
			end
		end
	end

	local function outside(x: number, y: number, z: number): boolean
		local k = key(x, y, z)
		return y >= 1 and not solid[k] and not cave[k]
	end

	for k in solid do
		local x, y, z = BlockWorld.unkey(k)
		local exposed = outside(x + 1, y, z)
			or outside(x - 1, y, z)
			or outside(x, y + 1, z)
			or outside(x, y, z + 1)
			or outside(x, y, z - 1)
		if near[k] and not exposed then
			ctx.Node(x, y, z, ore(ctx, x, y, z))
		elseif exposed then
			local roll = ctx.Hash(x, y + 200, z)
			if outside(x, y + 1, z) then
				ctx.Set(x, y, z, if roll < 0.75 then "Grass" else "Gravel")
			else
				ctx.Set(x, y, z, if roll < 0.62 then "Stone" elseif roll < 0.85 then "MossyCobblestone" else "Gravel")
			end
		else
			ctx.Set(x, y, z, "DarkStone")
		end
	end
	return heights
end

-- Timber frames, lanterns, rails and the cave mouth
local function furnishMine(ctx: Context.Context)
	local decor = ctx.Decor
	for _, z in SUPPORTS do
		for _, x in { -2, 2 } do
			for y = 1, 3 do
				ctx.Set(x, y, z, "Wood")
			end
		end
		for x = -2, 2 do
			ctx.Set(x, 4, z, "DarkPlanks")
		end
		Decor.Lantern(decor, ctx.Top(0, 4, z) - Vector3.new(0, SIZE + 2.7, 0), true, 24)
	end
	-- The cave mouth: the first frame where the tunnel meets the cliff, and a sign over it
	local mouth = -4
	for z = -9, 4 do
		if BlockWorld.get(ctx.World, 3, 1, z) then
			mouth = z
			break
		end
	end
	for _, x in { -3, 3 } do
		for y = 1, 4 do
			ctx.Set(x, y, mouth, "Wood")
		end
	end
	for x = -3, 3 do
		ctx.Set(x, 5, mouth, "DarkPlanks")
	end
	for x = -2, 2 do
		for y = 1, 4 do
			ctx.Set(x, y, mouth, nil)
		end
	end
	Signs.Board(
		decor,
		"MineSign",
		"THE MINE",
		BlockWorld.position(ctx.World, 0, 6, mouth) - Vector3.new(0, 0, SIZE / 2 + 0.25),
		-Vector3.zAxis,
		4
	)
	for _, x in { -3, 3 } do
		Decor.WallLantern(
			decor,
			BlockWorld.position(ctx.World, x, 3.5, mouth) - Vector3.new(0, 0, SIZE / 2),
			-Vector3.zAxis
		)
	end
	Decor.Rails(decor, ctx.Top(0, 0, -16), ctx.Top(0, 0, 12))
	Decor.Minecart(decor, ctx.Top(0, 0, -12), Vector3.zAxis, "CoalOre")
	Decor.Minecart(decor, ctx.Top(0, 0, 9), Vector3.zAxis, "IronOre")

	-- Lanterns along the side tunnels and round the chambers
	for t = 2, 3 do
		local points = TUNNELS[t].Points
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local mid = (a + b) / 2
			Decor.Lantern(decor, ctx.Top(math.round(mid.X), 0, math.round(mid.Y)) + Vector3.new(0, 0, 1.2), false, 20)
		end
	end
	for _, chamber in CHAMBERS do
		local c = chamber.Centre
		Decor.Lantern(decor, ctx.Top(math.round(c.X), 0, math.round(c.Y)), false, 30)
	end
	-- The great cavern: lantern posts, crates and barrels, and a pool
	for _, spot in { { -5, 15 }, { 5, 15 }, { -4, 20 }, { 4, 20 } } do
		for y = 1, 2 do
			ctx.Set(spot[1], y, spot[2], "Wood")
		end
		Decor.Lantern(decor, ctx.Top(spot[1], 2, spot[2]), false, 26)
	end
	for _, spot in
		{
			{ X = -6, Z = 18, Block = "Crate" },
			{ X = -6, Z = 19, Block = "Barrel" },
			{ X = -5, Z = 19, Block = "Crate" },
			{ X = 6, Z = 18, Block = "Barrel" },
		}
	do
		ctx.Set(spot.X, 1, spot.Z, spot.Block)
	end
	for x = -2, 2 do
		for z = 20, 22 do
			ctx.Set(x, 0, z, nil)
			ctx.Set(x, -1, z, "Gravel")
		end
	end
	Decor.Water(decor, ctx.Top(0, -1, 21) + Vector3.new(0, SIZE * 0.75, 0), Vector2.new(5 * SIZE, 3 * SIZE), SIZE * 0.8)
end

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
local function camp(ctx: Context.Context, x: number, z: number)
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

function Mining.Build(ctx: Context.Context)
	ctx.Ground(function(x, z)
		return column(ctx, x, z)
	end)
	local heights = buildMountain(ctx)
	furnishMine(ctx)

	-- The camp
	hut(ctx, -14, -15)
	camp(ctx, 12, -15)
	Decor.Rails(ctx.Decor, ctx.Top(6, 0, -24), ctx.Top(6, 0, -10))
	Decor.Minecart(ctx.Decor, ctx.Top(6, 0, -19), Vector3.zAxis, "IronOre")
	for _, spot in
		{
			{ X = -5, Z = -12, Block = "Crate" },
			{ X = -6, Z = -12, Block = "Crate" },
			{ X = -5, Z = -11, Block = "Barrel" },
			{ X = 5, Z = -6, Block = "Barrel" },
			{ X = 9, Z = -8, Block = "Crate" },
		}
	do
		ctx.Set(spot.X, 1, spot.Z, spot.Block)
	end
	for _, spot in { { -8, -20 }, { 11, -22 }, { -20, -6 }, { 20, -6 }, { -11, -26 }, { 16, -26 } } do
		local x, z = spot[1], spot[2]
		if not ctx.NearArrival(x, z, 1) then
			local size = ctx.Rng:NextNumber(1.2, 2)
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
	end
	for _, spot in { { -12, -8 }, { 13, -9 }, { -4, -20 }, { 4, -14 } } do
		Decor.Lantern(ctx.Decor, ctx.Top(spot[1], 0, spot[2]), false, 16)
	end

	-- A few trees on the mountain's grassy shoulders
	for _, spot in { { -18, 10 }, { 17, 7 }, { -9, 24 }, { 10, 25 }, { -22, 16 }, { 21, 18 } } do
		local h = heights[`{spot[1]},{spot[2]}`]
		if h and BlockWorld.get(ctx.World, spot[1], h, spot[2]) == "Grass" then
			Trees.Oak(spot[1], h, spot[2], 4, ctx.SetFree)
		end
	end
end

return Mining
