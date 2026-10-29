--!strict
-- The Mining World: a quarry camp on the arrival island and, over a long stone bridge to
-- the north, a huge jagged mountain of sandstone with a massive mine inside it (from the
-- Skybounds mine: cracked sandstone peaks hung with vines, a big arch entrance between two
-- wooden pavilions, and inside, great halls joined by wide tunnels).
--   The quarry    gravel yards round the arrival square: miners' huts, tents by campfires,
--                 carts of ore on rails, and rocky outcrops to mine on the way in
--   The mountain  sandstone peaks with dark cracks and vines, grassy terraces with
--                 boulders and oaks at its foot, and the mine's arch with "THE MINE"
--                 hanging in it between two pavilions
--   The mine      the way in leads to the Lantern Hall (scaffolding stalls, braziers, a
--                 signpost): west to the Iron Vein, east to the Coal Seam, north to the
--                 Lava Cavern, the biggest hall (lava falls into a glowing pool, a water
--                 pool, giant crystals and mushrooms). From the cavern a tunnel winds down
--                 to the deep Gold Chamber (Mining 10) and another to the Crystal Grotto.
--                 Two long galleries close the loop: the West Gallery slopes down from the
--                 Iron Vein to the gold, and the East Gallery, with a stream and stalls
--                 along it, runs from the Coal Seam to the grotto.
-- The halls are 30-70 blocks across and up to 30 high, with pale stone floors, a dirt path
-- down the middle, glowing vines and dripstone hanging from the roof and giant crystals
-- (from the Skybounds cave shots). Each section's walls have veins of its own ore with
-- plenty of stone between; the rest of the mine is stone with the odd coal or iron. Only
-- the ore can be mined: it turns pale (Empty Ore) and grows back, so nothing in the cave
-- is ever destroyed for good. Stone, floors, the mountain's outside and the timbers can't
-- be broken. Caves stay at least four blocks inside the rock, so they never break out.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Build = require(script.Parent.Parent.Util.Build)
local Decor = require(script.Parent.Parent.Util.Decor)
local Signs = require(script.Parent.Parent.Util.Signs)
local Trees = require(script.Parent.Parent.Util.Trees)
local Common = require(script.Parent.Common)
local Context = require(script.Parent.Context)
local Pace = require(script.Parent.Parent.Util.Pace)

local SIZE = Blocks.Size
local key = BlockWorld.key

local Mining = {}

Mining.SouthZ = -172
Mining.Seed = 11
Mining.Haze = 0.6
Mining.Caves = true

local QUARRY = { X = 0, Z = -132, R = 48 }
local PEAKS = { X = 0, Z = 60, R = 128 }
local BRIDGE = { Z1 = -94, Z2 = -54 } -- the stone bridge from the quarry to the mountain's foot
local FRONT = { Z1 = -42, Z2 = -6 } -- the flat terrace in front of the arch

-- The mountain is many peaks run together: centre, radius, height
local PEAK_LIST = {
	{ 0, 76, 84, 70 },
	{ 0, 22, 32, 40 },
	{ -40, 42, 40, 54 },
	{ 40, 44, 40, 56 },
	{ -66, 60, 34, 50 },
	{ 66, 62, 34, 50 },
	{ -52, 116, 40, 58 },
	{ 54, 116, 40, 60 },
	{ 0, 136, 40, 52 },
	{ -92, 100, 26, 38 },
	{ 94, 96, 26, 40 },
	-- Spires: two framing the arch, more round the sides and back
	{ -26, 8, 14, 46 },
	{ 26, 10, 14, 48 },
	{ -82, 30, 18, 42 },
	{ 84, 34, 18, 44 },
	{ -102, 132, 18, 40 },
	{ 106, 128, 18, 42 },
	{ -32, 162, 20, 50 },
	{ 36, 164, 20, 48 },
}

-- A cave section: tunnels are runs between points (X, floor height, Z), chambers are domes
-- standing on a floor. Ore: what its walls have veins of, and Vein how much: a noise
-- threshold, so lower is rarer (-0.12 is about a quarter of the wall, -0.3 a few spots).
type Section = { Ore: string?, Vein: number?, Deep: boolean? }
type Tunnel = {
	Points: { Vector3 },
	Width: number,
	Height: number,
	Mouth: boolean?,
	Ore: string?,
	Vein: number?,
	Deep: boolean?,
}
type Chamber = {
	Name: string,
	X: number,
	Z: number,
	Floor: number,
	Radii: Vector3,
	Ore: string?,
	Vein: number?,
	Deep: boolean?,
}

local TUNNELS: { Tunnel } = {
	-- The way in, from the arch on the south face to the Lantern Hall
	{
		Points = { Vector3.new(0, 1, -14), Vector3.new(0, 1, 6), Vector3.new(0, 1, 27) },
		Width = 4,
		Height = 9,
		Mouth = true,
	},
	-- Hall to the Iron Vein (west) and the Coal Seam (east)
	{ Points = { Vector3.new(-18, 1, 44), Vector3.new(-28, 1, 48), Vector3.new(-40, 1, 52) }, Width = 5, Height = 10 },
	{ Points = { Vector3.new(18, 1, 44), Vector3.new(28, 1, 48), Vector3.new(40, 1, 52) }, Width = 5, Height = 10 },
	-- Hall north to the Lava Cavern: a wide, tall opening
	{ Points = { Vector3.new(0, 1, 56), Vector3.new(-3, 1, 63), Vector3.new(0, 1, 71) }, Width = 8, Height = 15 },
	-- Cavern down to the Gold Chamber, and over to the Crystal Grotto
	{
		Points = { Vector3.new(-26, 1, 104), Vector3.new(-32, -6, 110), Vector3.new(-37, -14, 117) },
		Width = 4.5,
		Height = 9,
		Ore = "IronOre",
		Vein = -0.32,
		Deep = true,
	},
	{ Points = { Vector3.new(26, 1, 104), Vector3.new(34, 1, 110), Vector3.new(38, 1, 117) }, Width = 4.5, Height = 9 },
	-- The West Gallery: from the Iron Vein, sloping down to the gold
	{
		Points = { Vector3.new(-58, 1, 68), Vector3.new(-60, -6, 88), Vector3.new(-54, -14, 105) },
		Width = 5,
		Height = 11,
		Ore = "IronOre",
		Vein = -0.3,
		Deep = true,
	},
	-- The East Gallery: from the Coal Seam to the Crystal Grotto, a stream along it
	{ Points = { Vector3.new(58, 1, 68), Vector3.new(61, 1, 86), Vector3.new(56, 1, 103) }, Width = 6.5, Height = 13 },
}
local CHAMBERS: { Chamber } = {
	{ Name = "Hall", X = 0, Z = 42, Floor = 1, Radii = Vector3.new(22, 18, 17) },
	{ Name = "Iron", X = -58, Z = 52, Floor = 1, Radii = Vector3.new(20, 16, 18), Ore = "IronOre", Vein = -0.15 },
	{ Name = "Coal", X = 58, Z = 52, Floor = 1, Radii = Vector3.new(20, 16, 18), Ore = "CoalOre", Vein = -0.12 },
	{ Name = "Lava", X = 0, Z = 94, Floor = 1, Radii = Vector3.new(34, 30, 26) },
	{
		Name = "Gold",
		X = -50,
		Z = 118,
		Floor = -14,
		Radii = Vector3.new(20, 16, 16),
		Ore = "GoldOre",
		Vein = -0.17,
		Deep = true,
	},
	{ Name = "Grotto", X = 52, Z = 118, Floor = 1, Radii = Vector3.new(20, 18, 16), Ore = "IronOre", Vein = -0.3 },
}

local function chamber(name: string): Chamber
	for _, c in CHAMBERS do
		if c.Name == name then
			return c
		end
	end
	error(`no chamber {name}`)
end

-- Number keys for columns and cells (much faster than strings for the big cave)
local function ck(x: number, z: number): number
	return x * 4096 + z
end
local function nk(x: number, y: number, z: number): number
	return ((x + 1024) * 2048 + (y + 1024)) * 2048 + (z + 1024)
end

-- Mountain shape ----------------------------------------------------------------------------

-- The mountain's height at (x, z) before making room over the caves (0 = no mountain):
-- the highest of its peaks there, made jagged with ridged noise
local function slope(ctx: Context.Context, x: number, z: number): number
	local best = 0
	for _, p in PEAK_LIST do
		local dx, dz = x - p[1], z - p[2]
		if math.abs(dx) < p[3] and math.abs(dz) < p[3] then
			local d = math.sqrt(dx * dx + dz * dz)
			if d < p[3] then
				best = math.max(best, p[4] * (1 - (d / p[3]) ^ 1.4))
			end
		end
	end
	if best <= 0 then
		return 0
	end
	-- Deep ridges and crevices, then smaller lumps on those
	local ridges = (0.5 - math.abs(ctx.Noise(x, z, 14, 20))) * 20
		+ (0.5 - math.abs(ctx.Noise(x, z, 6, 25))) * 9
		+ ctx.Noise(x, z, 4, 21) * 4
		- 7
	return math.max(0, math.floor(best + ridges * math.clamp(best / 14, 0, 1)))
end

-- Horizontal distance from p to the segment a-b, and how far along it (0..1)
local function segment(p: Vector2, a: Vector2, b: Vector2): (number, number)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (p - (a + ab * t)).Magnitude, t
end

-- How rough a cave wall is at a cell: big lumps plus a little grain
local function rough(ctx: Context.Context, x: number, y: number, z: number): number
	return ctx.Noise(x + y * 0.7, z - y * 0.5, 7, 80) * 0.35 + (ctx.Hash(x, y, z) - 0.5) * 0.12
end

-- Every cave cell, found once (by number key): its section, whether it's the way in (which
-- may reach the outside), a list, and each column's roof
type Caves = {
	Sections: { [number]: Section },
	Mouth: { [number]: boolean },
	Cells: { Vector3 },
	Roof: { [number]: number },
}

local function findCaves(ctx: Context.Context): Caves
	local caves: Caves = { Sections = {}, Mouth = {}, Cells = {}, Roof = {} }
	local function add(x: number, y: number, z: number, section: Section, mouth: boolean)
		local k = nk(x, y, z)
		if caves.Sections[k] then
			return
		end
		caves.Sections[k] = section
		if mouth then
			caves.Mouth[k] = true
		end
		table.insert(caves.Cells, Vector3.new(x, y, z))
		local col = ck(x, z)
		caves.Roof[col] = math.max(caves.Roof[col] or -100, y + 5)
	end
	for _, tunnel in TUNNELS do
		local reach = math.ceil(tunnel.Width + 2)
		for i = 1, #tunnel.Points - 1 do
			local a, b = tunnel.Points[i], tunnel.Points[i + 1]
			local a2, b2 = Vector2.new(a.X, a.Z), Vector2.new(b.X, b.Z)
			for x = math.min(a.X, b.X) - reach, math.max(a.X, b.X) + reach do
				Pace.Step()
				for z = math.min(a.Z, b.Z) - reach, math.max(a.Z, b.Z) + reach do
					local d, t = segment(Vector2.new(x, z), a2, b2)
					if d < tunnel.Width * 1.4 then
						local floor = math.round(a.Y + (b.Y - a.Y) * t)
						for y = floor, floor + math.ceil(tunnel.Height * 1.3) do
							local v = (d / tunnel.Width) ^ 2 + ((y - floor) / tunnel.Height) ^ 2
							if v <= 1 + rough(ctx, x, y, z) then
								add(x, y, z, tunnel, tunnel.Mouth == true)
							end
						end
					end
				end
			end
		end
	end
	for _, c in CHAMBERS do
		local r = c.Radii
		for x = c.X - math.ceil(r.X * 1.3), c.X + math.ceil(r.X * 1.3) do
			Pace.Step()
			for z = c.Z - math.ceil(r.Z * 1.3), c.Z + math.ceil(r.Z * 1.3) do
				local flat = ((x - c.X) / r.X) ^ 2 + ((z - c.Z) / r.Z) ^ 2
				if flat <= 1.4 then
					-- Ledges a block or two up round the edge of the floor, flat in the middle
					local lift = 0
					if flat > 0.4 then
						local n = ctx.Noise(x, z, 9, 90)
						lift = if n > 0.3 then 2 elseif n > 0.12 then 1 else 0
					end
					local floor = c.Floor + lift
					for y = floor, c.Floor + math.ceil(r.Y * 1.3) do
						local dy = (y - c.Floor) / r.Y
						local v = flat + dy * dy
						if v <= 1 + rough(ctx, x, y, z) then
							add(x, y, z, c, false)
						end
					end
				end
			end
		end
	end
	return caves
end

-- Each column's final height: the peaks, raised over the caves so they keep a thick roof
local function mountainHeights(ctx: Context.Context, caves: Caves): { [number]: number }
	local heights: { [number]: number } = {}
	for x = -136, 136 do
		Pace.Step()
		for z = -72, 196 do
			local h = slope(ctx, x, z)
			if h > 0 then
				heights[ck(x, z)] = h
			end
		end
	end
	for col, need in caves.Roof do
		Pace.Step()
		local x = (col + 2048) // 4096
		local z = col - x * 4096
		for dx = -6, 6 do
			for dz = -6, 6 do
				local k = ck(x + dx, z + dz)
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

-- What a wall is made of: veins of its section's ore, otherwise stone with the odd coal or
-- iron (and a little gold down deep)
local function ore(ctx: Context.Context, x: number, y: number, z: number, section: Section?): string
	local roll = ctx.Hash(x + 400, y, z)
	-- Ore comes in veins, not a scatter: a smooth noise decides where they run
	local vein = ctx.Noise(x * 1.3 + y * 2.1, z * 1.3 - y * 1.7, 4, 70)
	if section and section.Ore and vein < (section.Vein or -0.15) and roll < 0.9 then
		return section.Ore
	end
	if section and section.Deep and roll < 0.02 then
		return "GoldOre"
	end
	return if roll < 0.02 then "IronOre" elseif roll < 0.05 then "CoalOre" else "Stone"
end

-- A cave floor's blocks: pale stone with patches of gravel and darker stone
local function floorBlock(ctx: Context.Context, x: number, z: number): string
	local n = ctx.Noise(x, z, 6, 301)
	return if n > 0.2 then "Gravel" elseif n < -0.24 then "Stone" else "SmoothStone"
end

-- Digs the caves out of the mountain and lines them: walls of stone nobody can break,
-- set with ore that grows back (mined ore turns pale, so the walls never get holes), a
-- protected floor underfoot, then stone and dark stone behind
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

	local cave: { [number]: Section } = {}
	local cells: { Vector3 } = {}
	for _, c in caves.Cells do
		Pace.Step()
		local k = nk(c.X, c.Y, c.Z)
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
	local seen: { [number]: boolean } = {}
	local from: { [number]: Section } = {}
	-- Only cave cells next to rock start the lining
	local frontier: { Vector3 } = {}
	local DIRS = { Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis }
	for _, c in cells do
		Pace.Step()
		for _, d in DIRS do
			if not cave[nk(c.X + d.X, c.Y + d.Y, c.Z + d.Z)] then
				table.insert(frontier, c)
				break
			end
		end
	end
	for layer = 1, 4 do
		local nextLayer: { Vector3 } = {}
		for _, c in frontier do
			Pace.Step()
			local section = cave[nk(c.X, c.Y, c.Z)] or from[nk(c.X, c.Y, c.Z)]
			for _, d in DIRS do
				local n = c + d
				local nn = nk(n.X, n.Y, n.Z)
				if not cave[nn] and not seen[nn] then
					seen[nn] = true
					from[nn] = section
					table.insert(nextLayer, n)
					local k = key(n.X, n.Y, n.Z)
					if not ctx.World.Cells[k] and solidHere(n.X, n.Y, n.Z) then
						if layer == 1 and cave[nk(n.X, n.Y + 1, n.Z)] then
							ctx.Set(n.X, n.Y, n.Z, floorBlock(ctx, n.X, n.Z))
						elseif layer <= 2 and not cave[nk(n.X, n.Y + layer, n.Z)] then
							-- Only the wall's face can ever be reached, so ore goes there
							local block = if layer == 1 then ore(ctx, n.X, n.Y, n.Z, section) else "Stone"
							if block == "Stone" then
								ctx.Set(n.X, n.Y, n.Z, block)
							else
								ctx.Node(n.X, n.Y, n.Z, block)
							end
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

-- Is the cell open cave air (not a block, and not the island's solid inside)?
local function open(ctx: Context.Context, x: number, y: number, z: number): boolean
	if ctx.World.Cells[key(x, y, z)] then
		return false
	end
	local inner = ctx.World.Inner
	return not (inner and inner(x, y, z))
end

-- The floor block under (x, z) inside a cave, near height `near` (nil if there isn't one)
local function floorAt(ctx: Context.Context, x: number, z: number, near: number): number?
	for y = near + 3, near - 8, -1 do
		if ctx.World.Cells[key(x, y, z)] and open(ctx, x, y + 1, z) and open(ctx, x, y + 2, z) then
			return y
		end
	end
	return nil
end

-- The highest open cell above the floor at (x, z) inside a cave (its ceiling is above it)
local function ceiling(ctx: Context.Context, x: number, floorY: number, z: number): number
	local y = floorY + 1
	while y < floorY + 45 and open(ctx, x, y + 1, z) do
		y += 1
	end
	return y
end

-- A lantern hanging from the cave roof over (x, z)
local function hangingLantern(ctx: Context.Context, x: number, floorY: number, z: number, range: number?)
	local top = ceiling(ctx, x, floorY, z)
	Decor.Lantern(ctx.Decor, ctx.Top(x, top, z) - Vector3.new(0, 2.7, 0), true, range or 24)
end

-- The point `t` (0..1) of the way along a tunnel's points
local function along(points: { Vector3 }, t: number): Vector3
	local total = 0
	for i = 1, #points - 1 do
		total += (points[i + 1] - points[i]).Magnitude
	end
	local want = total * t
	for i = 1, #points - 1 do
		local length = (points[i + 1] - points[i]).Magnitude
		if want <= length then
			return points[i]:Lerp(points[i + 1], want / math.max(length, 1e-6))
		end
		want -= length
	end
	return points[#points]
end

-- A light with no shadows (cheap, for the many glowing things in the cave)
local function glow(holder: BasePart, color: Color3, range: number, brightness: number?)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness or 1
	light.Shadows = false
	light.Parent = holder
end

-- Cave decor ------------------------------------------------------------------------------------

local VINE = Color3.fromRGB(70, 128, 52)
local BERRY = Color3.fromRGB(255, 196, 86)
local DRIP = Color3.fromRGB(138, 96, 66)
local CRYSTAL = {
	Pink = Color3.fromRGB(255, 136, 196),
	Purple = Color3.fromRGB(186, 88, 240),
	Red = Color3.fromRGB(232, 48, 62),
	Cyan = Color3.fromRGB(96, 218, 238),
}

-- Floor cells of the dirt path (decor keeps off it)
local pathCells: { [string]: boolean } = {}

-- Random spots on a chamber's floor, `edge` (0..1) of the way out from its middle, away
-- from the path and each other
local function chamberSpots(ctx: Context.Context, c: Chamber, count: number, edge: number, gap: number): { Vector3 }
	local rng = ctx.Rng
	local spots: { Vector3 } = {}
	for _ = 1, count * 8 do
		if #spots >= count then
			break
		end
		local angle = rng:NextNumber(0, 2 * math.pi)
		local reach = edge * rng:NextNumber(0.55, 1)
		local x = math.round(c.X + math.cos(angle) * c.Radii.X * reach)
		local z = math.round(c.Z + math.sin(angle) * c.Radii.Z * reach)
		local y = floorAt(ctx, x, z, c.Floor - 1)
		if y and not pathCells[key(x, y, z)] then
			local ok = true
			for _, other in spots do
				if (Vector2.new(other.X, other.Z) - Vector2.new(x, z)).Magnitude < gap then
					ok = false
					break
				end
			end
			if ok then
				table.insert(spots, Vector3.new(x, y, z))
			end
		end
	end
	return spots
end

-- The dirt path along the floor from `a` to `b` (points at floor height), `half` blocks
-- either side of the middle, wandering a little
local function floorPath(ctx: Context.Context, a: Vector3, b: Vector3, half: number)
	local flat = Vector2.new(b.X - a.X, b.Z - a.Z)
	local steps = math.max(1, math.ceil(flat.Magnitude * 1.5))
	local side = if flat.Magnitude > 0 then Vector2.new(-flat.Y, flat.X).Unit else Vector2.xAxis
	for i = 0, steps do
		local t = i / steps
		local wander = ctx.Noise(a.X + flat.X * t, a.Z + flat.Y * t, 9, 95) * 3 * math.min(t, 1 - t) * 4
		local cx = a.X + flat.X * t + side.X * wander
		local cz = a.Z + flat.Y * t + side.Y * wander
		local near = math.round(a.Y + (b.Y - a.Y) * t) - 1
		local reach = math.ceil(half)
		for dx = -reach, reach do
			for dz = -reach, reach do
				if dx * dx + dz * dz <= half * half + 0.5 then
					local x, z = math.round(cx) + dx, math.round(cz) + dz
					local y = floorAt(ctx, x, z, near)
					if y then
						local k = key(x, y, z)
						local block = ctx.World.Cells[k]
						if not pathCells[k] and block ~= "DarkStone" and not ctx.Nodes[k] then
							pathCells[k] = true
							ctx.Set(x, y, z, if ctx.Hash(x, 97, z) < 0.12 then "Path" else "CoarseDirt")
						end
					end
				end
			end
		end
	end
end

-- A strand of glowing vine hanging from the roof over (x, z): a green stem dotted with
-- glowing berries
local function glowVine(ctx: Context.Context, x: number, floorY: number, z: number)
	local rng = ctx.Rng
	local top = ceiling(ctx, x, floorY, z)
	local room = top - floorY - 3
	if room < 3 then
		return
	end
	local length = SIZE * rng:NextNumber(2, math.min(room, 12))
	local under = ctx.Top(x, top, z) + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
	-- The stem glows faintly, or it would be a black line against the dark rock
	local stem = Decor.Part(
		ctx.Decor,
		"GlowVine",
		Vector3.new(0.25, length, 0.25),
		CFrame.new(under - Vector3.new(0, length / 2, 0)),
		Color3.fromRGB(52, 96, 40),
		Enum.Material.Neon
	)
	stem.CanCollide = false
	stem.CastShadow = false
	local berries = math.clamp(math.floor(length / 2.2), 2, 8)
	for i = 1, berries do
		local side = if i % 2 == 0 then 0.35 else -0.35
		local berry = Decor.Part(
			ctx.Decor,
			"GlowBerry",
			Vector3.new(0.45, 0.45, 0.45),
			CFrame.new(under - Vector3.new(side, length * i / (berries + 0.5), side * 0.6)),
			BERRY,
			Enum.Material.Neon
		)
		berry.CanCollide = false
		berry.CastShadow = false
		if i == berries and rng:NextNumber() < 0.3 then
			glow(berry, BERRY, 14, 0.8)
		end
	end
end

-- A spike of dripstone: hanging from the roof over (x, z), or (`up`) rising from the floor
local function dripstone(ctx: Context.Context, x: number, floorY: number, z: number, up: boolean)
	local rng = ctx.Rng
	local top = ceiling(ctx, x, floorY, z)
	if not up and top < floorY + 5 then
		return
	end
	local base = if up then ctx.Top(x, floorY, z) else ctx.Top(x, top, z)
	local dir = if up then 1 else -1
	local width = rng:NextNumber(1.6, 3)
	local y = 0
	for i = 1, 4 do
		local w = width * (1 - (i - 1) * 0.22)
		local h = rng:NextNumber(1.2, 2.4)
		local piece = Decor.Part(
			ctx.Decor,
			"Dripstone",
			Vector3.new(w, h, w),
			CFrame.new(base + Vector3.new(0, dir * (y + h / 2), 0)) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0),
			DRIP:Lerp(Color3.fromRGB(110, 76, 54), rng:NextNumber()),
			Enum.Material.Slate
		)
		piece.CastShadow = false
		y += h
	end
end

-- A giant crystal cluster: blocky arms of glowing crystal reaching out from `base` (on the
-- floor, `up`, or hanging from the roof)
local function crystal(ctx: Context.Context, base: Vector3, up: boolean, color: Color3, size: number)
	local rng = ctx.Rng
	local dir = if up then 1 else -1
	local arms = rng:NextInteger(3, 5)
	local first: BasePart? = nil
	for a = 1, arms do
		local angle = a / arms * 2 * math.pi + rng:NextNumber(-0.4, 0.4)
		local lean = rng:NextNumber(0.25, 0.8)
		local step = Vector3.new(math.cos(angle) * lean, dir, math.sin(angle) * lean).Unit
		local at = base
		local cubes = math.max(2, math.round(size * rng:NextNumber(0.6, 1)))
		for i = 1, cubes do
			local s = SIZE * rng:NextNumber(0.7, 1.15) * (1 - i / (cubes + 2) * 0.5)
			at += step * s * 0.75
			local cube = Decor.Part(
				ctx.Decor,
				"Crystal",
				Vector3.new(s, s, s),
				CFrame.new(at)
					* CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 1.5), rng:NextNumber(-0.3, 0.3)),
				color:Lerp(Color3.new(1, 1, 1), rng:NextNumber(0, 0.25)),
				Enum.Material.Neon
			)
			cube.Transparency = 0.15
			cube.CanCollide = false
			cube.CastShadow = false
			first = first or cube
		end
	end
	if first then
		glow(first, color, 34, 1.6)
	end
end

-- A giant glowing mushroom on the cave floor: a pale stem under a wide purple cap
local function glowMushroom(ctx: Context.Context, at: Vector3, height: number, color: Color3)
	local rng = ctx.Rng
	local stem = Decor.Part(
		ctx.Decor,
		"MushroomStem",
		Vector3.new(1.6, height, 1.6),
		CFrame.new(at + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, rng:NextNumber(-0.08, 0.08)),
		Color3.fromRGB(226, 220, 204),
		Enum.Material.SmoothPlastic
	)
	stem.CastShadow = false
	local capTop = at + Vector3.new(0, height, 0)
	local width = height * rng:NextNumber(0.9, 1.3)
	for i, w in { 1, 0.75, 0.45 } do
		local cap = Decor.Part(
			ctx.Decor,
			"MushroomCap",
			Vector3.new(width * w, 1.3, width * w),
			CFrame.new(capTop + Vector3.new(0, (i - 1) * 1.1, 0)) * CFrame.Angles(0, i * 0.4, 0),
			color:Lerp(Color3.new(0, 0, 0), (i - 1) * 0.08),
			Enum.Material.Neon
		)
		cap.Transparency = 0.05
		if i == 1 then
			glow(cap, color, 26, 1.2)
		end
	end
end

-- A red mushroom of blocks on the cave floor (y is the floor block)
local function blockMushroom(ctx: Context.Context, x: number, y: number, z: number, height: number, capRadius: number)
	for dy = 1, height do
		ctx.SetFree(x, y + dy, z, "MushroomStem")
	end
	local top = y + height + 1
	for dx = -capRadius, capRadius do
		for dz = -capRadius, capRadius do
			local d = math.sqrt(dx * dx + dz * dz)
			if d <= capRadius + 0.3 then
				ctx.SetFree(x + dx, top, z + dz, "MushroomCap")
				if d > capRadius - 0.8 then
					ctx.SetFree(x + dx, top - 1, z + dz, "MushroomCap")
				end
			end
			if d <= capRadius - 1.2 then
				ctx.SetFree(x + dx, top + 1, z + dz, "MushroomCap")
			end
		end
	end
end

-- A brazier: a dark stone pillar with a fire burning on top
local function brazier(ctx: Context.Context, x: number, y: number, z: number)
	ctx.SetFree(x, y + 1, z, "DarkStone")
	local at = ctx.Top(x, y + 1, z)
	local flame = Decor.Part(
		ctx.Decor,
		"Fire",
		Vector3.new(0.9, 0.9, 0.9),
		CFrame.new(at + Vector3.new(0, 0.5, 0)),
		Color3.fromRGB(255, 160, 60),
		Enum.Material.Neon
	)
	flame.CanCollide = false
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 7
	fire.Parent = flame
	glow(flame, Color3.fromRGB(255, 170, 90), 24, 1.4)
end

-- A miners' stall of scaffolding: four posts, a plank counter with crates and barrels on
-- it, a beam overhead and lanterns on the front posts. `front` faces the path.
local function stall(ctx: Context.Context, x0: number, y: number, z0: number, front: Vector3)
	local site = Build.Site(ctx.World, x0, z0, front)
	for _, u in { -2, 2 } do
		for _, v in { 0, 2 } do
			local cx, cz = site:Cell(u, v)
			for dy = 1, 3 do
				ctx.SetFree(cx, y + dy, cz, "Wood")
			end
		end
	end
	for u = -2, 2 do
		for _, v in { 0, 2 } do
			local cx, cz = site:Cell(u, v)
			ctx.SetFree(cx, y + 4, cz, "DarkPlanks")
		end
	end
	for u = -1, 1 do
		local cx, cz = site:Cell(u, 0)
		ctx.SetFree(cx, y + 1, cz, "Planks")
		local bx, bz = site:Cell(u, 2)
		ctx.SetFree(bx, y + 1, bz, if u == 0 then "Barrel" else "Crate")
	end
	local gx, gz = site:Cell(-1, 0)
	ctx.SetFree(gx, y + 2, gz, if ctx.Hash(x0, y, z0) < 0.5 then "Crate" else "IronOre")
	for _, u in { -2, 2 } do
		local cx, cz = site:Cell(u, 0)
		Decor.Lantern(ctx.Decor, ctx.Top(cx, y + 4, cz), false, 18)
	end
end

-- A small heap of pale boulders on the floor
local function boulders(ctx: Context.Context, x: number, y: number, z: number)
	for i = 0, ctx.Rng:NextInteger(2, 5) do
		local dx, dz = ctx.Rng:NextInteger(-1, 1), ctx.Rng:NextInteger(-1, 1)
		local h = if i == 0 then 2 else 1
		for dy = 1, h do
			ctx.SetFree(
				x + dx,
				y + dy,
				z + dz,
				if ctx.Hash(x + dx, y + dy, z + dz) < 0.7 then "SmoothStone" else "Stone"
			)
		end
	end
end

-- Lava pouring from the cavern roof into a glowing pool on the floor
local function lavaFall(ctx: Context.Context, x: number, floorY: number, z: number)
	local color = Color3.fromRGB(255, 120, 30)
	local bottom = ctx.Top(x, floorY, z)
	local height = (ceiling(ctx, x, floorY, z) - floorY + 0.5) * SIZE
	local fall = Decor.Part(
		ctx.Decor,
		"LavaFall",
		Vector3.new(3.6, height, 3.6),
		CFrame.new(bottom + Vector3.new(0, height / 2, 0)),
		color,
		Enum.Material.Neon
	)
	fall.CanCollide = false
	glow(fall, color, 50, 2)
end

local function lavaPool(ctx: Context.Context, cx: number, floorY: number, cz: number, r: number)
	for x = cx - r, cx + r do
		for z = cz - r, cz + r do
			if (x - cx) ^ 2 + (z - cz) ^ 2 <= r * r and ctx.World.Cells[key(x, floorY, z)] then
				ctx.Set(x, floorY, z, "DarkStone")
			end
		end
	end
	local diameter = (2 * r + 1) * SIZE * 0.85
	local pool = Decor.Part(
		ctx.Decor,
		"Lava",
		Vector3.new(0.6, diameter, diameter),
		CFrame.new(ctx.Top(cx, floorY, cz) + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(255, 100, 20),
		Enum.Material.Neon
	)
	pool.Shape = Enum.PartType.Cylinder
	local fire = Instance.new("Fire")
	fire.Size = 8
	fire.Heat = 4
	fire.Color = Color3.fromRGB(255, 140, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 60, 20)
	fire.Parent = pool
end

-- A pool of water sunk one block into the floor
local function waterPool(ctx: Context.Context, cx: number, floorY: number, cz: number, r: number)
	for x = cx - r, cx + r do
		for z = cz - r, cz + r do
			if (x - cx) ^ 2 + (z - cz) ^ 2 <= r * r and ctx.World.Cells[key(x, floorY, z)] then
				ctx.Set(x, floorY, z, nil)
				ctx.Set(x, floorY - 1, z, "Gravel")
				Decor.Water(
					ctx.Decor,
					ctx.Top(x, floorY - 1, z) + Vector3.new(0, SIZE * 0.75, 0),
					Vector2.new(SIZE, SIZE),
					SIZE * 0.8
				)
			end
		end
	end
end

-- Vines and roots hanging from the roof of a chamber
local function caveLife(ctx: Context.Context, c: Chamber)
	local rng = ctx.Rng
	local root, crimson = Color3.fromRGB(104, 76, 48), Color3.fromRGB(176, 40, 66)
	for _ = 1, math.floor(c.Radii.X * c.Radii.Z / 14) do
		local x = c.X + rng:NextInteger(-math.floor(c.Radii.X), math.floor(c.Radii.X))
		local z = c.Z + rng:NextInteger(-math.floor(c.Radii.Z), math.floor(c.Radii.Z))
		local floorY = floorAt(ctx, x, z, c.Floor - 1)
		if floorY then
			local top = ceiling(ctx, x, floorY, z)
			if top > floorY + 4 then
				local length = SIZE * rng:NextNumber(1.5, math.min(7, top - floorY - 2.5))
				local under = ctx.Top(x, top, z)
				local roll = rng:NextNumber()
				local strand = Decor.Part(
					ctx.Decor,
					if roll < 0.55 then "Vine" elseif roll < 0.8 then "Root" else "CrimsonVine",
					Vector3.new(if roll < 0.55 then 1.2 else 0.45, length, if roll < 0.55 then 0.2 else 0.45),
					CFrame.new(under - Vector3.new(0, length / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
					if roll < 0.55 then VINE elseif roll < 0.8 then root else crimson,
					if roll < 0.55 then Enum.Material.LeafyGrass else Enum.Material.Wood
				)
				strand.CanCollide = false
				strand.CastShadow = false
			end
		end
	end
	-- Glowing vines and dripstone
	for _ = 1, math.floor(c.Radii.X * c.Radii.Z / 22) do
		local x = c.X + rng:NextInteger(-math.floor(c.Radii.X * 0.85), math.floor(c.Radii.X * 0.85))
		local z = c.Z + rng:NextInteger(-math.floor(c.Radii.Z * 0.85), math.floor(c.Radii.Z * 0.85))
		local floorY = floorAt(ctx, x, z, c.Floor - 1)
		if floorY then
			if rng:NextNumber() < 0.6 then
				glowVine(ctx, x, floorY, z)
			else
				dripstone(ctx, x, floorY, z, false)
			end
		end
	end
	for _, spot in chamberSpots(ctx, c, math.floor(c.Radii.X * c.Radii.Z / 60), 0.95, 4) do
		dripstone(ctx, spot.X, spot.Y, spot.Z, true)
	end
end

-- Lanterns on posts round a chamber's floor
local function chamberLights(ctx: Context.Context, c: Chamber, count: number)
	for i = 0, count - 1 do
		local angle = i / count * math.pi * 2 + 0.4
		local x = math.round(c.X + math.cos(angle) * c.Radii.X * 0.6)
		local z = math.round(c.Z + math.sin(angle) * c.Radii.Z * 0.6)
		local y = floorAt(ctx, x, z, c.Floor - 1)
		if y and not pathCells[key(x, y, z)] then
			ctx.SetFree(x, y + 1, z, "Wood")
			ctx.SetFree(x, y + 2, z, "Wood")
			Decor.Lantern(ctx.Decor, ctx.Top(x, y + 2, z), false, 30)
		end
	end
end

-- The point at floor height in a chamber's middle
local function middle(c: Chamber): Vector3
	return Vector3.new(c.X, c.Floor, c.Z)
end

-- A zone sign standing on the cave floor at (x, z), near height `near`
local function caveSign(
	ctx: Context.Context,
	x: number,
	z: number,
	near: number,
	front: Vector3,
	name: string,
	need: string?
)
	local y = floorAt(ctx, x, z, near)
	if y then
		Common.ZoneSign(ctx, x, z, front, name, need, Signs.Woods.Dark, y)
	end
end

-- The roof over (x, z) in a chamber, for crystals hanging from it
local function roofAt(ctx: Context.Context, c: Chamber, x: number, z: number): Vector3
	local floorY = floorAt(ctx, x, z, c.Floor - 1) or (c.Floor - 1)
	return ctx.Top(x, ceiling(ctx, x, floorY, z), z)
end

local function furnishMine(ctx: Context.Context)
	local hall, coal, iron, lava, gold, grotto =
		chamber("Hall"), chamber("Coal"), chamber("Iron"), chamber("Lava"), chamber("Gold"), chamber("Grotto")
	local rng = ctx.Rng

	-- The dirt path: in from the arch, through the hall to every section and round the loop
	floorPath(ctx, Vector3.new(0, 1, -6), middle(hall), 1.6)
	for t = 2, #TUNNELS do
		local points = TUNNELS[t].Points
		for i = 1, #points - 1 do
			floorPath(ctx, points[i], points[i + 1], 1.2)
		end
	end
	floorPath(ctx, middle(hall), TUNNELS[2].Points[1], 1.2)
	floorPath(ctx, middle(hall), TUNNELS[3].Points[1], 1.2)
	floorPath(ctx, middle(hall), TUNNELS[4].Points[1], 1.6)
	floorPath(ctx, TUNNELS[4].Points[3], middle(lava), 1.6)
	floorPath(ctx, middle(lava), TUNNELS[5].Points[1], 1.2)
	floorPath(ctx, middle(lava), TUNNELS[6].Points[1], 1.2)
	floorPath(ctx, TUNNELS[2].Points[3], middle(iron), 1.2)
	floorPath(ctx, TUNNELS[3].Points[3], middle(coal), 1.2)
	floorPath(ctx, middle(iron), TUNNELS[7].Points[1], 1.2)
	floorPath(ctx, middle(coal), TUNNELS[8].Points[1], 1.2)
	floorPath(ctx, TUNNELS[5].Points[3], middle(gold), 1.2)
	floorPath(ctx, TUNNELS[6].Points[3], middle(grotto), 1.2)

	-- Every chamber: life on the roof, dripstone, pale boulders, braziers
	for _, c in CHAMBERS do
		caveLife(ctx, c)
		for _, spot in chamberSpots(ctx, c, math.floor(c.Radii.X * c.Radii.Z / 70), 0.9, 6) do
			boulders(ctx, spot.X, spot.Y, spot.Z)
		end
	end

	-- The Lantern Hall: stalls of scaffolding, braziers, a cart, and the signpost
	chamberLights(ctx, hall, 6)
	for i, spot in chamberSpots(ctx, hall, 4, 0.75, 10) do
		local toward = Vector3.new(hall.X - spot.X, 0, hall.Z - spot.Z)
		local front = if math.abs(toward.X) > math.abs(toward.Z)
			then Vector3.new(math.sign(toward.X), 0, 0)
			else Vector3.new(0, 0, if toward.Z < 0 then -1 else 1)
		if i <= 3 then
			stall(ctx, spot.X, spot.Y, spot.Z, front)
		else
			brazier(ctx, spot.X, spot.Y, spot.Z)
		end
	end
	for _, spot in chamberSpots(ctx, hall, 4, 0.5, 8) do
		brazier(ctx, spot.X, spot.Y, spot.Z)
	end
	Decor.Minecart(ctx.Decor, ctx.Top(6, 0, 40), Vector3.xAxis, "IronOre")
	Common.Arrows(ctx, 4, 32, -Vector3.zAxis, {
		{ Text = "IRON VEIN", Toward = -Vector3.xAxis },
		{ Text = "LAVA CAVERN", Toward = Vector3.zAxis },
		{ Text = "COAL SEAM", Toward = Vector3.xAxis },
	}, Signs.Woods.Dark, 0)
	crystal(ctx, roofAt(ctx, hall, -12, 48), false, CRYSTAL.Pink, 4)
	crystal(ctx, roofAt(ctx, hall, 10, 50), false, CRYSTAL.Red, 3)

	-- The ore sections: lanterns, carts of their ore, stalls, braziers
	for _, c in { coal, iron } do
		chamberLights(ctx, c, 5)
		local spots = chamberSpots(ctx, c, 3, 0.6, 10)
		for i, spot in spots do
			if i == 1 then
				stall(ctx, spot.X, spot.Y, spot.Z, if c.X > 0 then -Vector3.xAxis else Vector3.xAxis)
			else
				brazier(ctx, spot.X, spot.Y, spot.Z)
			end
		end
		Decor.Minecart(ctx.Decor, ctx.Top(c.X, c.Floor - 1, c.Z - 6), Vector3.zAxis, c.Ore)
	end
	caveSign(ctx, -36, 46, 0, Vector3.xAxis, "IRON VEIN", "STONE PICKAXE")
	caveSign(ctx, 36, 46, 0, -Vector3.xAxis, "COAL SEAM")

	-- The Lava Cavern: lava from the roof into a big pool, a water pool on the far side,
	-- giant crystals and mushrooms, life on the floor and roof
	local lavaFloor = floorAt(ctx, lava.X - 14, lava.Z + 6, 0) or 0
	lavaPool(ctx, lava.X - 14, lavaFloor, lava.Z + 6, 6)
	lavaFall(ctx, lava.X - 16, lavaFloor, lava.Z + 7)
	lavaFall(ctx, lava.X - 11, lavaFloor, lava.Z + 10)
	lavaFall(ctx, lava.X - 13, lavaFloor, lava.Z + 3)
	local waterFloor = floorAt(ctx, lava.X + 16, lava.Z - 4, 0)
	if waterFloor then
		waterPool(ctx, lava.X + 16, waterFloor, lava.Z - 4, 4)
	end
	chamberLights(ctx, lava, 8)
	for i, spot in chamberSpots(ctx, lava, 6, 0.85, 12) do
		local colors = { CRYSTAL.Purple, CRYSTAL.Pink, CRYSTAL.Cyan, CRYSTAL.Red }
		crystal(ctx, ctx.Top(spot.X, spot.Y, spot.Z), true, colors[(i - 1) % #colors + 1], rng:NextInteger(3, 5))
	end
	for i = 1, 5 do
		local angle = i / 5 * 2 * math.pi + 0.5
		local x = math.round(lava.X + math.cos(angle) * lava.Radii.X * 0.55)
		local z = math.round(lava.Z + math.sin(angle) * lava.Radii.Z * 0.55)
		local colors = { CRYSTAL.Pink, CRYSTAL.Purple, CRYSTAL.Red }
		crystal(ctx, roofAt(ctx, lava, x, z), false, colors[(i - 1) % #colors + 1], 5)
	end
	for i, spot in chamberSpots(ctx, lava, 6, 0.9, 10) do
		if i <= 4 then
			glowMushroom(ctx, ctx.Top(spot.X, spot.Y, spot.Z), rng:NextNumber(7, 12), CRYSTAL.Purple)
		else
			blockMushroom(ctx, spot.X, spot.Y, spot.Z, rng:NextInteger(4, 6), 3)
		end
	end
	for _, spot in chamberSpots(ctx, lava, 5, 0.7, 10) do
		brazier(ctx, spot.X, spot.Y, spot.Z)
	end
	Common.Arrows(ctx, lava.X + 4, lava.Z - 12, -Vector3.zAxis, {
		{ Text = "GOLD - MINING 10", Toward = Vector3.new(-1, 0, 1) },
		{ Text = "CRYSTAL GROTTO", Toward = Vector3.new(1, 0, 1) },
	}, Signs.Woods.Dark, 0)

	-- The deep Gold Chamber: a little lava, braziers, mushrooms
	chamberLights(ctx, gold, 5)
	local goldFloor = floorAt(ctx, gold.X - 6, gold.Z + 4, gold.Floor - 1)
	if goldFloor then
		lavaPool(ctx, gold.X - 6, goldFloor, gold.Z + 4, 3)
		lavaFall(ctx, gold.X - 6, goldFloor, gold.Z + 5)
	end
	for i, spot in chamberSpots(ctx, gold, 5, 0.8, 9) do
		if i <= 2 then
			glowMushroom(ctx, ctx.Top(spot.X, spot.Y, spot.Z), rng:NextNumber(6, 9), CRYSTAL.Purple)
		else
			brazier(ctx, spot.X, spot.Y, spot.Z)
		end
	end
	crystal(ctx, roofAt(ctx, gold, gold.X + 6, gold.Z), false, CRYSTAL.Red, 4)
	caveSign(ctx, -22, 100, 0, Vector3.new(1, 0, -1).Unit, "GOLD CHAMBER", "MINING 10")

	-- The Crystal Grotto: crystals everywhere, a pool
	for i, spot in chamberSpots(ctx, grotto, 10, 0.95, 6) do
		local colors = { CRYSTAL.Purple, CRYSTAL.Cyan, CRYSTAL.Pink }
		crystal(ctx, ctx.Top(spot.X, spot.Y, spot.Z), true, colors[(i - 1) % #colors + 1], rng:NextInteger(3, 6))
	end
	for i = 1, 6 do
		local angle = i / 6 * 2 * math.pi
		local x = math.round(grotto.X + math.cos(angle) * grotto.Radii.X * 0.5)
		local z = math.round(grotto.Z + math.sin(angle) * grotto.Radii.Z * 0.5)
		local colors = { CRYSTAL.Pink, CRYSTAL.Cyan, CRYSTAL.Purple }
		crystal(ctx, roofAt(ctx, grotto, x, z), false, colors[i % 3 + 1], 4)
	end
	local grottoFloor = floorAt(ctx, grotto.X + 6, grotto.Z + 4, 0)
	if grottoFloor then
		waterPool(ctx, grotto.X + 6, grottoFloor, grotto.Z + 4, 3)
	end
	chamberLights(ctx, grotto, 4)
	caveSign(ctx, 22, 100, 0, Vector3.new(-1, 0, -1).Unit, "CRYSTAL GROTTO")

	-- The East Gallery: a stream down one side, stalls along the other, rails
	local east = TUNNELS[8].Points
	for i = 1, #east - 1 do
		local a, b = east[i], east[i + 1]
		local steps = math.ceil((b - a).Magnitude)
		for s = 0, steps do
			local p = a:Lerp(b, s / steps)
			local x, z = math.round(p.X + 3.5), math.round(p.Z)
			local y = floorAt(ctx, x, z, 0)
			if y and not pathCells[key(x, y, z)] then
				ctx.Set(x, y, z, nil)
				ctx.Set(x, y - 1, z, "Gravel")
				Decor.Water(
					ctx.Decor,
					ctx.Top(x, y - 1, z) + Vector3.new(0, SIZE * 0.75, 0),
					Vector2.new(SIZE, SIZE),
					SIZE * 0.8
				)
			end
		end
	end
	for _, at in { 0.2, 0.5, 0.8 } do
		local p = along(east, at)
		local x, z = math.round(p.X - 4), math.round(p.Z)
		local y = floorAt(ctx, x, z, 0)
		if y then
			stall(ctx, x, y, z, Vector3.xAxis)
		end
	end
	-- Galleries and tunnels: lanterns hanging along them, braziers by the path, vines
	for t = 2, #TUNNELS do
		local points = TUNNELS[t].Points
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local steps = math.max(1, math.floor((b - a).Magnitude / 7))
			for s = 0, steps do
				local p = a:Lerp(b, s / math.max(steps, 1))
				local x, z = math.round(p.X), math.round(p.Z)
				local y = floorAt(ctx, x, z, math.round(p.Y) - 1)
				if y then
					if s % 2 == 0 then
						hangingLantern(ctx, x, y, z, 30)
					else
						local vy = floorAt(ctx, x + 2, z, y)
						if vy then
							glowVine(ctx, x + 2, vy, z)
						end
						local dy = floorAt(ctx, x - 2, z, y)
						if dy then
							dripstone(ctx, x - 2, dy, z, false)
						end
					end
				end
			end
		end
	end
	local west = TUNNELS[7].Points
	for _, at in { 0.3, 0.7 } do
		local p = along(west, at)
		local x, z = math.round(p.X + 3), math.round(p.Z)
		local y = floorAt(ctx, x, z, math.round(p.Y) - 1)
		if y then
			glowMushroom(ctx, ctx.Top(x, y, z), 6, CRYSTAL.Purple)
		end
	end
end

-- The way in -----------------------------------------------------------------------------------

-- The arch: a timber frame where the way in meets the mountain, "THE MINE" hanging in it
local function arch(ctx: Context.Context): number
	local z = 0
	for tz = FRONT.Z2, 60 do
		if ctx.HeightAt(7, tz) >= 15 then
			z = tz
			break
		end
	end
	-- A wide, tall opening, lined with sandstone where it cuts into the rock, then the
	-- timbered tunnel
	local opening: { [string]: boolean } = {}
	for x = -6, 6 do
		for y = 1, 13 do
			for dz = -1, 1 do
				ctx.Carve(x, y, z + dz)
				opening[key(x, y, z + dz)] = true
			end
		end
	end
	for x = -7, 7 do
		for y = 1, 14 do
			for dz = -1, 1 do
				local k = key(x, y, z + dz)
				if not opening[k] and not ctx.World.Cells[k] and y <= ctx.HeightAt(x, z + dz) then
					ctx.Set(x, y, z + dz, "Sandstone")
				end
			end
		end
	end
	for _, x in { -7, 7 } do
		for y = 1, 13 do
			ctx.Set(x, y, z, "Wood")
		end
	end
	for x = -8, 8 do
		ctx.Set(x, 14, z, "DarkPlanks")
	end
	for x = -6, 6 do
		ctx.Set(x, 15, z, "Wood")
	end
	Signs.Hanging(
		ctx.Decor,
		BlockWorld.position(ctx.World, 0, 14, z) - Vector3.new(0, SIZE / 2, SIZE / 2 + 0.4),
		-Vector3.zAxis,
		"THE MINE",
		Signs.Woods.Dark,
		3.2
	)
	for _, x in { -7, 7 } do
		Decor.WallLantern(
			ctx.Decor,
			BlockWorld.position(ctx.World, x, 8, z) - Vector3.new(0, 0, SIZE / 2),
			-Vector3.zAxis
		)
	end
	-- Timber frames along the way in, each with a lantern
	for tz = z + 6, 22, 6 do
		for _, x in { -3, 3 } do
			for y = 1, 6 do
				ctx.Set(x, y, tz, "Wood")
			end
		end
		for x = -3, 3 do
			ctx.Set(x, 7, tz, "DarkPlanks")
		end
		Decor.Lantern(ctx.Decor, ctx.Top(0, 7, tz) - Vector3.new(0, SIZE + 2.7, 0), true, 26)
	end
	Decor.Rails(ctx.Decor, ctx.Top(2, 0, z - 14), ctx.Top(2, 0, 30))
	Decor.Minecart(ctx.Decor, ctx.Top(2, 0, z - 8), Vector3.zAxis, "CoalOre")
	Decor.Minecart(ctx.Decor, ctx.Top(2, 0, z + 10), Vector3.zAxis, "IronOre")
	return z
end

-- An open wooden pavilion beside the path: a plank deck, four tall posts, beams and a
-- slate roof, with crates under it
local function pavilion(ctx: Context.Context, x0: number, z0: number, front: Vector3)
	local h0 = ctx.HeightAt(x0, z0)
	for dx = -3, 3 do
		for dz = -3, 3 do
			ctx.Set(x0 + dx, h0, z0 + dz, "DarkPlanks")
		end
	end
	for _, dx in { -3, 3 } do
		for _, dz in { -3, 3 } do
			for y = 1, 5 do
				ctx.Set(x0 + dx, h0 + y, z0 + dz, "Wood")
			end
		end
	end
	for d = -3, 3 do
		ctx.Set(x0 + d, h0 + 6, z0 - 3, "DarkPlanks")
		ctx.Set(x0 + d, h0 + 6, z0 + 3, "DarkPlanks")
		ctx.Set(x0 - 3, h0 + 6, z0 + d, "DarkPlanks")
		ctx.Set(x0 + 3, h0 + 6, z0 + d, "DarkPlanks")
	end
	local site = Build.Site(ctx.World, x0, z0 - 3, front)
	site:Roof(-4, -1, 4, 7, h0 + 7, "RoofSlate", "DarkPlanks", false)
	Decor.Lantern(ctx.Decor, ctx.Top(x0, h0 + 4.4, z0), true, 22)
	ctx.SetFree(x0 - 2, h0 + 1, z0 + 2, "Crate")
	ctx.SetFree(x0 - 1, h0 + 1, z0 + 2, "Barrel")
	ctx.SetFree(x0 + 2, h0 + 1, z0 + 2, "Crate")
	ctx.SetFree(x0 + 2, h0 + 2, z0 + 2, "Crate")
	Decor.Bench(ctx.Decor, ctx.Top(x0, h0, z0 - 1), -Vector3.zAxis, 3)
end

-- The quarry ----------------------------------------------------------------------------------

-- A small stone hut with a slate roof, its door facing `front`, crates inside
local function hut(ctx: Context.Context, x: number, z: number, front: Vector3)
	local site = Build.Site(ctx.World, x, z, front)
	site:Fill(-3, 0, 0, 3, 0, 6, "Cobblestone")
	site:Walls(-3, 1, 0, 3, 4, 6, "StoneBricks")
	for _, u in { -3, 3 } do
		for _, v in { 0, 6 } do
			site:Fill(u, 1, v, u, 4, v, "Wood")
		end
	end
	site:Clear(0, 1, 0, 0, 2, 0)
	site:Set(-2, 2, 0, "Glass")
	site:Set(2, 2, 0, "Glass")
	site:Fill(-3, 2, 2, -3, 3, 4, "Glass")
	site:Fill(3, 2, 2, 3, 3, 4, "Glass")
	site:Roof(-3, 0, 3, 6, 5, "RoofSlate", "DarkPlanks", false)
	site:Set(-2, 1, 5, "Crate")
	site:Set(-1, 1, 5, "Barrel")
	site:Set(2, 1, 5, "Barrel")
	site:Set(2, 1, 3, "Crate")
	Decor.Lantern(ctx.Decor, site:Pos(0, 3.4, 3), true, 18)
	Decor.WallLantern(ctx.Decor, site:Pos(1.3, 2.6, 0) + site.Front * (SIZE / 2), site.Front)
	site:Set(-4, 1, -1, "Crate")
	site:Set(-4, 2, -1, "Crate")
	site:Set(-5, 1, -1, "Barrel")
end

-- A canvas tent with a campfire in front (to the south)
local function tent(ctx: Context.Context, x: number, z: number)
	local site = Build.Site(ctx.World, x, z, -Vector3.zAxis)
	site:Roof(-2, 0, 2, 4, 1, "WhiteWool", "RedWool", false)
	site:Clear(0, 1, 0, 0, 2, 0)
	local fire = ctx.Top(x, 0, z - 4)
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
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 160, 80)
	light.Range = 18
	light.Brightness = 1.5
	light.Parent = flame
	for _, dx in { -2, 2 } do
		ctx.Set(x + dx, 1, z - 4, "Wood")
	end
end

-- A rocky outcrop: stone nobody can break, with coal and iron to mine
local function outcrop(ctx: Context.Context, x: number, z: number)
	local size = ctx.Rng:NextNumber(2, 3.6)
	local reach = math.ceil(size)
	for dx = -reach, reach do
		for dz = -reach, reach do
			local d = math.sqrt(dx * dx + dz * dz)
			if d <= size then
				for y = 1, math.max(1, math.round(4.5 * (1 - (d / size) ^ 2 * 0.7))) do
					local roll = ctx.Hash(x + dx, y, z + dz)
					local block = if roll < 0.08 then "IronOre" elseif roll < 0.24 then "CoalOre" else "Stone"
					if block == "Stone" then
						ctx.SetFree(x + dx, y, z + dz, block)
					else
						ctx.Node(x + dx, y, z + dz, block)
					end
				end
			end
		end
	end
end

local HUTS = { { X = -18, Z = -146, Front = Vector3.xAxis }, { X = 18, Z = -116, Front = -Vector3.xAxis } }
local TENTS = { { 18, -150 }, { -18, -110 } }

local function quarry(ctx: Context.Context)
	for _, h in HUTS do
		hut(ctx, h.X, h.Z, h.Front)
	end
	for _, t in TENTS do
		tent(ctx, t[1], t[2])
	end
	Decor.Rails(ctx.Decor, ctx.Top(9, 0, -162), ctx.Top(9, 0, -128))
	Decor.Minecart(ctx.Decor, ctx.Top(9, 0, -150), Vector3.zAxis, "IronOre")
	Decor.Minecart(ctx.Decor, ctx.Top(9, 0, -136), Vector3.zAxis, "CoalOre")
	Decor.Rails(ctx.Decor, ctx.Top(-9, 0, -132), ctx.Top(-9, 0, -96))
	Decor.Minecart(ctx.Decor, ctx.Top(-9, 0, -120), Vector3.zAxis, "CoalOre")
	for _, spot in { { -6, -136 }, { -7, -136 }, { -6, -135 }, { 6, -104 }, { 7, -104 }, { 12, -140 } } do
		ctx.SetFree(spot[1], 1, spot[2], if (spot[1] + spot[2]) % 2 == 0 then "Crate" else "Barrel")
	end
	-- Rocky outcrops round the yards, clear of the path and the buildings
	local placed: { Vector2 } = {}
	local rng = ctx.Rng
	for _ = 1, 200 do
		if #placed >= 18 then
			break
		end
		local x = rng:NextInteger(QUARRY.X - QUARRY.R + 6, QUARRY.X + QUARRY.R - 6)
		local z = rng:NextInteger(QUARRY.Z - QUARRY.R + 10, QUARRY.Z + QUARRY.R - 6)
		local spot = Vector2.new(x, z)
		local ok = math.abs(x) > 8 and ctx.Inside(x, z, 6) and not ctx.NearArrival(x, z, 5)
		for _, b in HUTS do
			ok = ok and (Vector2.new(b.X, b.Z) - spot).Magnitude > 11
		end
		for _, b in TENTS do
			ok = ok and (Vector2.new(b[1], b[2]) - spot).Magnitude > 10
		end
		for _, other in placed do
			ok = ok and (other - spot).Magnitude > 9
		end
		if ok then
			table.insert(placed, spot)
			outcrop(ctx, x, z)
		end
	end
	for z = -160, -92, 12 do
		Common.Lamp(ctx, -4, z)
		Common.Lamp(ctx, 4, z + 6)
	end
end

-- Ground ------------------------------------------------------------------------------------------

-- The quarry's yards: gravel with patches of path and bare stone, grass round the rim
local function quarryColumn(ctx: Context.Context, x: number, z: number): (string, number)
	if not ctx.Inside(x, z, 5) and ctx.IslandAt(x, z) then
		return "Grass", 0
	end
	local n = ctx.Noise(x, z, 8, 23)
	return if n > 0.22 then "Path" elseif n < -0.24 then "Stone" else "Gravel", 0
end

function Mining.Build(ctx: Context.Context)
	ctx.Flatten(-3, -170, 3, -84)
	ctx.Flatten(-3, BRIDGE.Z2 - 8, 3, FRONT.Z2)
	ctx.Flatten(-20, FRONT.Z1, 20, FRONT.Z2)
	local caves = findCaves(ctx)
	local heights = mountainHeights(ctx, caves)

	-- The mountain's skin: sandstone, with dark cracks running across its upper slopes and
	-- grassy terraces low down
	local function peakColumn(x: number, z: number): (string, number)
		local h = heights[ck(x, z)]
		if not h then
			-- The foot: terraces of grass stepping up toward the mountain
			local foot = math.clamp(math.floor((ctx.Noise(x, z, 16, 22) + 0.5) * 5), 0, 4)
			return if ctx.Noise(x, z, 5, 24) > 0.3 then "Gravel" else "Grass", foot
		end
		if h >= 12 and math.abs(ctx.Noise(x, z, 14, 71)) < 0.022 then
			return "DarkStone", h
		end
		local steep = 0
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			steep = math.max(steep, h - (heights[ck(x + d[1], z + d[2])] or 0))
		end
		if h <= 6 and steep <= 1 then
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
		Depth = 26,
	})
	local peaks = ctx.Island({
		Name = "Mountain",
		X = PEAKS.X,
		Z = PEAKS.Z,
		Radius = PEAKS.R,
		Column = peakColumn,
		Depth = 64,
		Fill = function(x, y, z, depth)
			-- Sandstone right under the mountain's skin, a little soil under the grass
			if heights[ck(x, z)] then
				return if depth == 1 and ctx.World.Cells[key(x, y + depth, z)] == "Grass" then "Dirt" else "Sandstone"
			end
			return nil
		end,
	})
	for _, spot in
		{
			{ -64, 6, -150, 4 },
			{ 66, -6, -120, 4 },
			{ -150, 12, 30, 5 },
			{ 152, 8, 70, 5 },
			{ -100, -10, 200, 4 },
			{ 110, 14, -40, 4 },
			{ -120, -4, -60, 3 },
			{ 40, 18, 210, 4 },
		}
	do
		ctx.Islet(spot[1], spot[2], spot[3], spot[4], "Stone")
	end

	digMine(ctx, caves)
	local mouthZ = arch(ctx)
	furnishMine(ctx)
	quarry(ctx)

	-- A long stone bridge over to the mountain, a dirt path up to the arch between two
	-- pavilions
	ctx.Bridge(0, BRIDGE.Z1, 0, BRIDGE.Z2, "StoneBricks")
	Common.Path(ctx, 0, -164, 0, BRIDGE.Z1, 5, Common.StonePath)
	Common.Path(ctx, 0, BRIDGE.Z2, 0, mouthZ - 1, 5)
	pavilion(ctx, -15, FRONT.Z2 - 12, -Vector3.zAxis)
	pavilion(ctx, 15, FRONT.Z2 - 12, -Vector3.zAxis)
	Decor.Minecart(ctx.Decor, ctx.Top(9, ctx.HeightAt(9, mouthZ - 6), mouthZ - 6), Vector3.zAxis, "IronOre")
	Common.Arrows(ctx, 5, BRIDGE.Z2 + 3, -Vector3.xAxis, { { Text = "THE MINE", Toward = Vector3.zAxis } })
	for z = BRIDGE.Z2 + 6, mouthZ - 4, 8 do
		Common.Lamp(ctx, -4, z)
		Common.Lamp(ctx, 4, z)
	end

	-- Grassy terraces at the mountain's foot: boulders, oaks, vines down the cliffs
	local rng = ctx.Rng
	local rocks: { Vector2 } = {}
	for _ = 1, 300 do
		if #rocks >= 26 then
			break
		end
		local x = rng:NextInteger(-110, 110)
		local z = rng:NextInteger(-64, 180)
		local spot = Vector2.new(x, z)
		local ok = ctx.IslandAt(x, z) == peaks
			and ctx.Inside(x, z, 6)
			and heights[ck(x, z)] == nil
			and math.abs(x) > 9
			and not ctx.Flat(x, z, 3)
		for _, other in rocks do
			ok = ok and (other - spot).Magnitude > 12
		end
		if ok then
			table.insert(rocks, spot)
			Common.Boulder(
				ctx,
				x,
				z,
				rng:NextInteger(3, 5),
				{ "Sandstone", "Stone", "Sandstone", "MossyCobblestone", "SmoothStone" }
			)
		end
	end
	-- Oaks on the terraces in front and round the sides (nobody sees behind the mountain)
	Common.Forest(ctx, peaks, 10, 4, function(x, z)
		return heights[ck(x, z)] ~= nil or math.abs(x) <= 8 or z > 40 or ctx.Flat(x, z, 3)
	end, function(x, h, z)
		if rng:NextNumber() < 0.25 then
			Trees.BigOak(x, h, z, 6, ctx.SetFree)
		else
			Trees.Oak(x, h, z, rng:NextInteger(4, 6), ctx.SetFree)
		end
	end)
	-- Vines hang down the cliffs in clumps, not everywhere
	Common.CliffVines(ctx, peaks, 0.16, function(x, z)
		-- Keep the arch and its sign clear
		return math.abs(x) <= 9 and math.abs(z - mouthZ) <= 4 or ctx.Noise(x, z, 10, 72) < 0.05
	end)
	Common.Scatter(ctx, peaks, 0.04, 0.01, { Color3.fromRGB(242, 212, 64), Color3.fromRGB(240, 240, 240) })
end

return Mining
