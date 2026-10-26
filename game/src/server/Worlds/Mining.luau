--!strict
-- The Mining World: a quarry camp on the arrival island and, over a bridge to the north, a
-- great mountain with snow on its peak and a mine deep inside it.
--   The quarry    gravel yards round the arrival square: a miner's hut, a tent by a
--                 campfire, carts of ore on rails, and rocky outcrops to mine on the way in
--   The mountain  grassy foothills with oaks, stony slopes, a snowy peak, and a
--                 timber-framed mouth ("THE MINE") on its south face
--   The mine      a timbered tunnel leads into the great cavern, thirty blocks high: lava
--                 pours from the walls into a glowing pool, vines and roots hang from the
--                 roof, glowing mushrooms grow on the floor, and scaffolds with lanterns
--                 climb the walls. A tunnel winds down west to the deep gold chamber, and
--                 one east to the crystal grotto.
-- Every cave wall and roof is ore that grows back, two blocks thick: mostly stone, coal and
-- iron, with gold deep down (gold needs an Iron pickaxe and Mining 10). Behind it is dark
-- stone, as far as anyone can dig. Floors, the mountain's outside and the timbers can't be
-- broken. Caves stay at least four blocks inside the rock, so they never break out of the
-- mountain's side.

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
-- The mountain: an oval centred north of the island's middle
local MX, MZ, RX, RZ, PEAK = 0, 40, 42, 34, 44

-- A cave: tunnels are runs between points (X, floor height, Z), chambers are ellipsoids
-- standing on a floor. Deep caves have gold in their walls.
type Tunnel = { Points: { Vector3 }, Width: number, Height: number, Mouth: boolean? }
type Chamber = { Name: string, X: number, Z: number, Floor: number, Radii: Vector3, Deep: boolean? }

local TUNNELS: { Tunnel } = {
	-- The way in, from the mouth on the south face to the great cavern
	{
		Points = { Vector3.new(0, 1, -4), Vector3.new(0, 1, 14), Vector3.new(0, 1, 26) },
		Width = 2.6,
		Height = 4.5,
		Mouth = true,
	},
	-- Down to the deep gold chamber
	{
		Points = { Vector3.new(-16, 1, 46), Vector3.new(-22, -3, 50), Vector3.new(-27, -8, 55) },
		Width = 2,
		Height = 3.6,
	},
	-- Over to the crystal grotto
	{ Points = { Vector3.new(16, 1, 40), Vector3.new(22, 1, 36), Vector3.new(26, 1, 32) }, Width = 2, Height = 3.6 },
}
local CHAMBERS: { Chamber } = {
	{ Name = "Cavern", X = 0, Z = 42, Floor = 1, Radii = Vector3.new(19, 30, 18) },
	{ Name = "Gold", X = -30, Z = 56, Floor = -8, Radii = Vector3.new(7.5, 9, 7.5), Deep = true },
	{ Name = "Grotto", X = 30, Z = 30, Floor = 1, Radii = Vector3.new(7, 9, 7) },
}
local MOUTH_Z = 6 -- roughly where the way in meets the mountain's face

-- Mountain shape ----------------------------------------------------------------------------

-- The mountain's height at (x, z) before making room over the caves (0 = no mountain)
local function slope(ctx: Context.Context, x: number, z: number): number
	local e = math.sqrt(((x - MX) / RX) ^ 2 + ((z - MZ) / RZ) ^ 2)
	if e >= 1 then
		return 0
	end
	local ridge = 6 * ctx.Noise(x, z, 14, 20) + 3 * ctx.Noise(x, z, 6, 21)
	return math.max(0, math.floor(PEAK * (1 - e * e) ^ 0.8 + ridge * (1 - e)))
end

-- Horizontal distance from p to the segment a-b, and how far along it (0..1)
local function segment(p: Vector2, a: Vector2, b: Vector2): (number, number)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (p - (a + ab * t)).Magnitude, t
end

-- Is (x, y, z) in a cave (with a little noise so the walls are rough)? Also says whether
-- it's in the way in (which is allowed to reach the outside) and whether it's deep.
local function inCave(ctx: Context.Context, x: number, y: number, z: number): (boolean, boolean, boolean)
	local p = Vector2.new(x, z)
	local rough = (ctx.Hash(x, y, z) - 0.5) * 0.3
	for _, tunnel in TUNNELS do
		for i = 1, #tunnel.Points - 1 do
			local a, b = tunnel.Points[i], tunnel.Points[i + 1]
			local d, t = segment(p, Vector2.new(a.X, a.Z), Vector2.new(b.X, b.Z))
			local floor = math.round(a.Y + (b.Y - a.Y) * t)
			if y >= floor and (d / tunnel.Width) ^ 2 + ((y - floor) / tunnel.Height) ^ 2 <= 1 + rough then
				return true, tunnel.Mouth == true, floor < 0
			end
		end
	end
	for _, chamber in CHAMBERS do
		local r = chamber.Radii
		-- A dome: flat floor, round walls and roof
		local dy = (y - chamber.Floor) / r.Y
		if y >= chamber.Floor and ((x - chamber.X) / r.X) ^ 2 + dy * dy + ((z - chamber.Z) / r.Z) ^ 2 <= 1 + rough then
			return true, false, chamber.Deep == true
		end
	end
	return false, false, false
end

-- Each column's final height: the slope, raised over the caves so they keep a thick roof
local function mountainHeights(ctx: Context.Context): { [string]: number }
	local roof: { [string]: number } = {}
	for x = MX - RX, MX + RX do
		for z = MZ - RZ, MZ + RZ do
			local top = -100
			for y = -10, 36 do
				if inCave(ctx, x, y, z) then
					top = y
				end
			end
			if top > -100 then
				roof[`{x},{z}`] = top + 5
			end
		end
	end
	local heights: { [string]: number } = {}
	for x = MX - RX, MX + RX do
		for z = MZ - RZ, MZ + RZ do
			local h = slope(ctx, x, z)
			if h > 0 then
				for dx = -6, 6 do
					for dz = -6, 6 do
						local need = roof[`{x + dx},{z + dz}`]
						if need then
							h = math.max(h, math.floor(need - 0.6 * math.sqrt(dx * dx + dz * dz)))
						end
					end
				end
				heights[`{x},{z}`] = h
			end
		end
	end
	return heights
end

-- The mine -----------------------------------------------------------------------------------

-- What a cave wall is made of: mostly stone, with coal and iron; gold in deep places
local function ore(ctx: Context.Context, x: number, y: number, z: number, deep: boolean): string
	local roll = ctx.Hash(x + 400, y, z)
	if deep then
		return if roll < 0.12
			then "GoldOre"
			elseif roll < 0.27 then "IronOre"
			elseif roll < 0.42 then "CoalOre"
			else "Stone"
	end
	if y < 4 and roll < 0.02 then
		return "GoldOre"
	end
	return if roll < 0.11 then "IronOre" elseif roll < 0.29 then "CoalOre" else "Stone"
end

-- Digs the caves out of the mountain and lines them: two blocks of ore that grows back
-- (a protected floor underfoot), then two of dark stone
local function digMine(ctx: Context.Context)
	local function height(x: number, z: number): number
		return ctx.HeightAt(x, z)
	end
	-- Is (x, y, z) well inside the rock, at least four blocks from the mountain's outside?
	local function sealed(x: number, y: number, z: number): boolean
		if not ctx.Inside(x, z, 6) then
			return false
		end
		for _, d in { { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 }, { 3, 3 }, { -3, 3 }, { 3, -3 }, { -3, -3 } } do
			local h = height(x + d[1], z + d[2])
			if h < y + 2 and y >= -1 then
				return false
			end
		end
		return height(x, z) >= y + 4
	end

	local cave: { [string]: boolean } = {}
	local deepCells: { [string]: boolean } = {}
	local cells: { Vector3 } = {}
	for x = MX - RX, MX + RX do
		for z = MZ - RZ - 12, MZ + RZ do
			for y = -10, 36 do
				local inside, mouth, deep = inCave(ctx, x, y, z)
				if inside and (mouth or sealed(x, y, z)) then
					local k = key(x, y, z)
					cave[k] = true
					if deep then
						deepCells[k] = true
					end
					table.insert(cells, Vector3.new(x, y, z))
				end
			end
		end
	end
	for _, c in cells do
		ctx.Carve(c.X, c.Y, c.Z)
	end

	-- The lining, one layer at a time outward from the caves
	local function solidHere(x: number, y: number, z: number): boolean
		return ctx.IslandAt(x, z) ~= nil and y <= height(x, z)
	end
	local seen: { [string]: boolean } = {}
	local frontier = cells
	for layer = 1, 4 do
		local nextLayer: { Vector3 } = {}
		for _, c in frontier do
			for _, d in { Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis } do
				local n = c + d
				local k = key(n.X, n.Y, n.Z)
				if not cave[k] and not seen[k] then
					seen[k] = true
					table.insert(nextLayer, n)
					local existing = ctx.World.Cells[k]
					local floor = cave[key(n.X, n.Y + 1, n.Z)] and layer == 1
					if not existing and solidHere(n.X, n.Y, n.Z) then
						if floor then
							local roll = ctx.Hash(n.X, n.Y + 300, n.Z)
							ctx.Set(
								n.X,
								n.Y,
								n.Z,
								if roll < 0.55 then "Stone" elseif roll < 0.8 then "Gravel" else "Cobblestone"
							)
						elseif layer <= 2 and not cave[key(n.X, n.Y + layer, n.Z)] then
							local deep = deepCells[key(c.X, c.Y, c.Z)] == true or n.Y < -2
							ctx.Node(n.X, n.Y, n.Z, ore(ctx, n.X, n.Y, n.Z, deep))
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

-- The mouth: a timber frame where the way in meets the mountain, the sign high over it
local function mouth(ctx: Context.Context)
	local z = MOUTH_Z
	for tz = -4, 30 do
		if ctx.HeightAt(4, tz) >= 7 then
			z = tz
			break
		end
	end
	for _, x in { -3, 3 } do
		for y = 1, 5 do
			ctx.Set(x, y, z, "Wood")
		end
	end
	for x = -3, 3 do
		ctx.Set(x, 6, z, "DarkPlanks")
	end
	for x = -2, 2 do
		for y = 1, 5 do
			ctx.Carve(x, y, z)
		end
	end
	Signs.Board(
		ctx.Decor,
		"MineSign",
		"THE MINE",
		BlockWorld.position(ctx.World, 0, 7, z) - Vector3.new(0, 0, SIZE / 2 + 0.25),
		-Vector3.zAxis,
		5
	)
	for _, x in { -3, 3 } do
		Decor.WallLantern(
			ctx.Decor,
			BlockWorld.position(ctx.World, x, 3.5, z) - Vector3.new(0, 0, SIZE / 2),
			-Vector3.zAxis
		)
	end
	-- Timber frames along the way in
	for tz = z + 4, 22, 5 do
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
	Decor.Rails(ctx.Decor, ctx.Top(0, 0, z - 14), ctx.Top(0, 0, 30))
	Decor.Minecart(ctx.Decor, ctx.Top(0, 0, z - 6), Vector3.zAxis, "CoalOre")
	Decor.Minecart(ctx.Decor, ctx.Top(0, 0, 28), Vector3.zAxis, "IronOre")
end

-- Lava pouring from the cavern roof into a glowing pool on the floor
local function lavaFall(ctx: Context.Context, x: number, z: number)
	local glow = Color3.fromRGB(255, 120, 30)
	local bottom = ctx.Top(x, 0, z)
	local top = 1
	while top < 40 and not ctx.World.Cells[key(x, top, z)] do
		top += 1
	end
	local height = (top - 0.5) * SIZE
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
	local pool = Decor.Part(
		ctx.Decor,
		"Lava",
		Vector3.new((2 * r + 1) * SIZE * 0.85, 0.6, (2 * r + 1) * SIZE * 0.85),
		CFrame.new(ctx.Top(cx, 0, cz) + Vector3.new(0, 0.3, 0)),
		Color3.fromRGB(255, 100, 20),
		Enum.Material.Neon
	)
	pool.Shape = Enum.PartType.Cylinder
	pool.CFrame = CFrame.new(ctx.Top(cx, 0, cz) + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	pool.Size = Vector3.new(0.6, (2 * r + 1) * SIZE * 0.85, (2 * r + 1) * SIZE * 0.85)
	local fire = Instance.new("Fire")
	fire.Size = 6
	fire.Heat = 4
	fire.Color = Color3.fromRGB(255, 140, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 60, 20)
	fire.Parent = pool
end

-- Vines and roots hanging from the roof, glowing mushrooms on the floor
local function cavernLife(ctx: Context.Context, chamber: Chamber)
	local rng = ctx.Rng
	local vine, root = Color3.fromRGB(70, 128, 52), Color3.fromRGB(104, 76, 48)
	local crimson = Color3.fromRGB(176, 40, 66)
	for _ = 1, math.floor(chamber.Radii.X * chamber.Radii.Z / 6) do
		local x = chamber.X + rng:NextInteger(-math.floor(chamber.Radii.X), math.floor(chamber.Radii.X))
		local z = chamber.Z + rng:NextInteger(-math.floor(chamber.Radii.Z), math.floor(chamber.Radii.Z))
		-- Up from the floor to the roof
		local roofY
		for y = chamber.Floor, chamber.Floor + 40 do
			if ctx.World.Cells[key(x, y, z)] then
				roofY = y
				break
			end
		end
		if roofY and roofY > chamber.Floor + 2 then
			local length = SIZE * rng:NextNumber(2, math.min(9, roofY - chamber.Floor - 2))
			local under = ctx.Top(x, roofY, z) - Vector3.new(0, SIZE, 0)
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
				-- A glowing bud at the tip
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
	for _ = 1, math.floor(chamber.Radii.X * chamber.Radii.Z / 14) do
		local x = chamber.X + rng:NextInteger(-math.floor(chamber.Radii.X) + 2, math.floor(chamber.Radii.X) - 2)
		local z = chamber.Z + rng:NextInteger(-math.floor(chamber.Radii.Z) + 2, math.floor(chamber.Radii.Z) - 2)
		local y = chamber.Floor - 1
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

-- Purple crystals glowing on the grotto's walls
local function crystals(ctx: Context.Context, chamber: Chamber)
	local rng = ctx.Rng
	for i = 1, 16 do
		local angle = i / 16 * math.pi * 2
		local x = math.round(chamber.X + math.cos(angle) * (chamber.Radii.X - 1.5))
		local z = math.round(chamber.Z + math.sin(angle) * (chamber.Radii.Z - 1.5))
		local base = ctx.Top(x, chamber.Floor - 1, z)
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

-- A scaffold tower against a wall: log posts, plank platforms, a lantern on top
local function scaffold(ctx: Context.Context, x: number, z: number, height: number)
	for _, dx in { 0, 2 } do
		for _, dz in { 0, 2 } do
			for y = 1, height do
				ctx.SetFree(x + dx, y, z + dz, "Wood")
			end
		end
	end
	for y = 4, height, 4 do
		for dx = 0, 2 do
			for dz = 0, 2 do
				ctx.SetFree(x + dx, y, z + dz, "DarkPlanks")
			end
		end
	end
	Decor.Lantern(ctx.Decor, ctx.Top(x + 1, height, z + 1), false, 28)
end

local function furnishMine(ctx: Context.Context)
	local cavern, gold, grotto = CHAMBERS[1], CHAMBERS[2], CHAMBERS[3]
	-- The great cavern: lava from the west wall into a pool, lantern posts, scaffolds,
	-- crates and barrels, a miner's hut on the floor
	lavaPool(ctx, cavern.X - 10, cavern.Z + 10, 3)
	lavaFall(ctx, cavern.X - 11, cavern.Z + 11)
	lavaFall(ctx, cavern.X - 8, cavern.Z + 13)
	for _, spot in { { -6, 32 }, { 6, 32 }, { -6, 46 }, { 8, 50 }, { 0, 56 }, { 12, 40 } } do
		for y = 1, 2 do
			ctx.SetFree(spot[1], y, spot[2], "Wood")
		end
		Decor.Lantern(ctx.Decor, ctx.Top(spot[1], 2, spot[2]), false, 30)
	end
	scaffold(ctx, 12, 50, 12)
	scaffold(ctx, -14, 32, 9)
	local site = Build.Site(ctx.World, 6, 44, -Vector3.xAxis)
	site:Walls(-2, 1, 0, 2, 3, 4, "Planks")
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
	for _, spot in
		{
			{ X = -4, Z = 30, Block = "Crate" },
			{ X = -5, Z = 30, Block = "Barrel" },
			{ X = 4, Z = 31, Block = "Crate" },
			{ X = 5, Z = 31, Block = "Crate" },
			{ X = 5, Z = 32, Block = "Barrel" },
		}
	do
		ctx.SetFree(spot.X, 1, spot.Z, spot.Block)
	end
	cavernLife(ctx, cavern)
	-- The gold chamber: lanterns round it, and a sign at the tunnel's top
	cavernLife(ctx, gold)
	for i = 0, 3 do
		local angle = i * math.pi / 2 + 0.4
		local x = math.round(gold.X + math.cos(angle) * 4)
		local z = math.round(gold.Z + math.sin(angle) * 4)
		Decor.Lantern(ctx.Decor, ctx.Top(x, gold.Floor - 1, z), false, 24)
	end
	Common.Signpost(ctx, -14, 45, Vector3.xAxis, "GOLD\nMINING 10", 4, 0)
	-- The crystal grotto
	crystals(ctx, grotto)
	cavernLife(ctx, grotto)
	Decor.Lantern(ctx.Decor, ctx.Top(grotto.X, 0, grotto.Z), false, 24)
	-- Lanterns along the side tunnels
	for t = 2, 3 do
		local points = TUNNELS[t].Points
		for i = 1, #points - 1 do
			local mid = (points[i] + points[i + 1]) / 2
			local x, z = math.round(mid.X), math.round(mid.Z)
			Decor.Lantern(ctx.Decor, ctx.Top(x, math.round(mid.Y) - 1, z), false, 22)
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

-- Ground ----------------------------------------------------------------------------------------

local function quarryColumn(ctx: Context.Context, x: number, z: number): (string, number)
	if not ctx.Inside(x, z, 4) and ctx.IslandAt(x, z) then
		return "Grass", 0
	end
	local roll = ctx.Hash(x, 0, z)
	return if roll < 0.12 then "Cobblestone" elseif roll < 0.25 then "Path" else "Gravel", 0
end

function Mining.Build(ctx: Context.Context)
	ctx.Flatten(-2, -74, 2, -16)
	ctx.Flatten(-3, -20, 3, 2)
	local heights = mountainHeights(ctx)

	-- What's on top of the mountain: grass on gentle slopes, bare rock on steep ones, snow
	-- up high
	local function peakColumn(x: number, z: number): (string, number)
		local h = heights[`{x},{z}`]
		if not h then
			local foot = math.clamp(math.round(1 + 2 * ctx.Noise(x, z, 12, 22)), 0, 2)
			return if ctx.Hash(x, 5, z) < 0.15 then "Gravel" else "Grass", foot
		end
		local steep = 0
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			steep = math.max(steep, h - (heights[`{x + d[1]},{z + d[2]}`] or 0))
		end
		if h >= 34 then
			return "Snow", h
		elseif steep >= 3 then
			local roll = ctx.Hash(x, 6, z)
			return if roll < 0.6 then "Stone" elseif roll < 0.85 then "MossyCobblestone" else "Gravel", h
		end
		return "Grass", h
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
			-- Rock right under the mountain's skin, with a little soil under the grass
			if heights[`{x},{z}`] then
				return if depth == 1 and ctx.World.Cells[key(x, y + depth, z)] == "Grass" then "Dirt" else "Stone"
			end
			return nil
		end,
	})
	for _, spot in { { -36, 4, -70, 3 }, { 40, -4, -60, 3 }, { -72, 10, 20, 4 }, { 72, 6, 40, 4 }, { -50, -8, 86, 3 } } do
		ctx.Islet(spot[1], spot[2], spot[3], spot[4], "Stone")
	end

	digMine(ctx)
	mouth(ctx)
	furnishMine(ctx)
	quarry(ctx)

	ctx.Bridge(0, -46, 0, -20)
	Common.Path(ctx, 0, -72, 0, -46, 3)
	Common.Path(ctx, 0, -20, 0, MOUTH_Z - 1, 3)
	Common.ZoneGate(ctx, 0, -18, -Vector3.zAxis, "THE MOUNTAIN")
	for _, z in { -14, -6 } do
		Common.Lamp(ctx, 2, z)
	end

	-- Oaks and boulders on the foothills
	Common.Forest(ctx, peaks, 7, 4, function(x, z)
		return heights[`{x},{z}`] ~= nil or math.abs(x) <= 4 or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		Trees.Oak(x, h, z, ctx.Rng:NextInteger(4, 5), ctx.SetFree)
	end)
	Common.Scatter(ctx, peaks, 0.05, 0.01, { Color3.fromRGB(242, 212, 64), Color3.fromRGB(240, 240, 240) })
end

return Mining
