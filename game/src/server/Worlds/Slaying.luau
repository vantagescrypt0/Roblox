--!strict
-- The Slaying World ([[Slaying Proposal]]): six floating zones in a ring, each with its own land
-- and a giant statue of its monster you can see from the bridge, joined by stone bridges. You
-- arrive in the first; each one after it has a gate at the bridge end that turns you back until
-- your Combat level is high enough (SlayingService runs the gates and respawns).
--   Slime Meadow     (Combat 1)   green hills, lanterns, mossy boulders
--   Bramble Woods    (Combat 10)  dark forest of giant trees, overgrown stone ruins
--   Rust Canyon      (Combat 20)  a stone road between layered red cliffs
--   Bone Flats       (Combat 30)  pale sand, dead trees, giant cacti
--   Sporewood Bog    (Combat 40)  giant mushrooms over shallow pools
--   Frostfang Peaks  (Combat 55)  snow and ice, tall spires, a frozen lake
-- The monsters themselves are MobService's; this says where they stand. Nothing here can be
-- gathered or built on.
--
-- Grid: x runs west to east, z south to north; y = 0 is the ground's usual height.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Monsters = require(ReplicatedStorage.Shared.Monsters)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Decor = require(script.Parent.Parent.Util.Decor)
local MonsterModels = require(script.Parent.Parent.Util.MonsterModels)
local Signs = require(script.Parent.Parent.Util.Signs)
local Trees = require(script.Parent.Parent.Util.Trees)
local Common = require(script.Parent.Common)
local Context = require(script.Parent.Context)

local SIZE = Blocks.Size
local key = BlockWorld.key

local Slaying = {}

Slaying.SouthZ = -222
Slaying.Seed = 41
Slaying.Haze = 0.15

export type ZoneInfo = {
	Zone: Monsters.Zone,
	Island: Context.Island,
	Start: Vector3, -- where you respawn in this zone: the end of its bridge (or the arrival square)
	StartFacing: Vector3,
	MobSpots: { Vector3 },
}

-- Filled in by Build, for SlayingService
Slaying.Layout = {} :: { ZoneInfo }

-- Where each zone's island is, and the road across it from the bridge you arrive by (x1, z1) to
-- the bridge you leave by. Roads run straight along x or z, in legs.
type Road = { number } -- x1, z1, x2, z2
type Layout = { X: number, Z: number, R: number, Roads: { Road } }

local MEADOW: Layout = { X = 0, Z = -150, R = 80, Roads = { { 0, -212, 0, -130 }, { 0, -130, -72, -130 } } }
local BRAMBLE: Layout = {
	X = -190,
	Z = -130,
	R = 72,
	Roads = { { -114, -130, -205, -130 }, { -205, -130, -205, -68 } },
}
local RUST: Layout = { X = -220, Z = 60, R = 80, Roads = { { -205, -8, -205, 90 }, { -205, 90, -150, 90 } } }
local BONE: Layout =
	{ X = -20, Z = 100, R = 74, Roads = { { -84, 90, 0, 90 }, { 0, 90, 0, 110 }, { 0, 110, 46, 110 } } }
local SPORE: Layout = { X = 170, Z = 120, R = 76, Roads = { { 104, 110, 185, 110 }, { 185, 110, 185, 52 } } }
local FROST: Layout = { X = 200, Z = -70, R = 84, Roads = { { 185, 20, 185, -118 } } }

local MOBS_PER_ZONE = 30

local MEADOW_FLOWERS = {
	Color3.fromRGB(222, 62, 52),
	Color3.fromRGB(242, 212, 64),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(190, 120, 240),
}
local SPORE_GLOW = { Color3.fromRGB(120, 240, 214), Color3.fromRGB(180, 120, 255), Color3.fromRGB(120, 170, 255) }

-- Roads ----------------------------------------------------------------------------

local function flattenRoads(ctx: Context.Context, roads: { Road })
	for _, road in roads do
		ctx.Flatten(road[1] - 3, road[2] - 3, road[3] + 3, road[4] + 3)
	end
end

local function layRoads(ctx: Context.Context, roads: { Road }, block: (string | { string })?)
	for _, road in roads do
		Common.Path(ctx, road[1], road[2], road[3], road[4], 5, block or Common.StonePath)
	end
end

-- Blocks from a road, however it runs
local function roadDistance(x: number, z: number, roads: { Road }): number
	local best = math.huge
	for _, road in roads do
		local cx = math.clamp(x, math.min(road[1], road[3]), math.max(road[1], road[3]))
		local cz = math.clamp(z, math.min(road[2], road[4]), math.max(road[2], road[4]))
		best = math.min(best, math.sqrt((x - cx) ^ 2 + (z - cz) ^ 2))
	end
	return best
end

local function lamps(ctx: Context.Context, roads: { Road }, every: number)
	for _, road in roads do
		local alongX = road[2] == road[4]
		local from = if alongX then math.min(road[1], road[3]) else math.min(road[2], road[4])
		local to = if alongX then math.max(road[1], road[3]) else math.max(road[2], road[4])
		local side = 1
		for s = from + 6, to - 4, every do
			local x, z
			if alongX then
				x, z = s, road[2] + 4 * side
			else
				x, z = road[1] + 4 * side, s
			end
			if ctx.Inside(x, z, 2) and not ctx.World.Cells[key(x, ctx.HeightAt(x, z) + 1, z)] then
				Common.Lamp(ctx, x, z)
			end
			side = -side
		end
	end
end

-- Random spots on an island, `margin` in from the rim, at least `gap` apart, where `ok` says yes
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
	for _ = 1, count * 30 do
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

-- Pieces ------------------------------------------------------------------------------

-- A giant statue of a monster on a stone plinth, `height` studs tall, looking along `facing`
local function statue(ctx: Context.Context, x: number, z: number, monsterId: string, height: number, facing: Vector3)
	local h = ctx.HeightAt(x, z)
	local r = 5
	for dx = -r, r do
		for dz = -r, r do
			local edge = math.abs(dx) == r or math.abs(dz) == r
			ctx.Set(x + dx, h + 1, z + dz, if edge then "MossyStoneBricks" else "StoneBricks")
			if not edge then
				ctx.Set(x + dx, h + 2, z + dz, "SmoothStone")
			end
		end
	end
	local at = ctx.Top(x, h + 2, z)
	MonsterModels.Statue(ctx.Decor, Monsters.ById[monsterId], at, height, facing)
	Decor.Lantern(ctx.Decor, ctx.Top(x + r, h + 1, z + r), false, 24)
	Decor.Lantern(ctx.Decor, ctx.Top(x - r, h + 1, z - r), false, 24)
	Decor.Lantern(ctx.Decor, ctx.Top(x + r, h + 1, z - r), false, 24)
	Decor.Lantern(ctx.Decor, ctx.Top(x - r, h + 1, z + r), false, 24)
end

-- Where a zone begins, at the end of its bridge: an arch with its name, facing `front` (toward
-- the people arriving), a glowing sheet across the road and a sign with the Combat level
local function gate(ctx: Context.Context, x: number, z: number, front: Vector3, zone: Monsters.Zone, color: Color3)
	Signs.Gateway(ctx.Decor, ctx.Set, function(cx, cy, cz)
		return BlockWorld.position(ctx.World, cx, cy, cz)
	end, x, z, front, string.upper(zone.Name), 7)
	local side = Vector3.new(-front.Z, 0, front.X)
	local ground = ctx.Top(x, ctx.HeightAt(x, z), z)
	local barrier = Instance.new("Part")
	barrier.Name = "ZoneGate"
	barrier.Size = Vector3.new(8 * SIZE, 5 * SIZE, 0.4)
	barrier.CFrame =
		CFrame.lookAt(ground + Vector3.new(0, 2.5 * SIZE, 0), ground + Vector3.new(0, 2.5 * SIZE, 0) + front)
	barrier.Color = color
	barrier.Material = Enum.Material.ForceField
	barrier.Transparency = 0.35
	barrier.Anchored = true
	barrier.CanCollide = false
	barrier.CanQuery = false
	barrier.CanTouch = false
	barrier.CastShadow = false
	barrier.Parent = ctx.Decor
	Common.ZoneSign(
		ctx,
		x + math.round(side.X * 6),
		z + math.round(side.Z * 6),
		front,
		zone.Name:upper(),
		`COMBAT {zone.Level}`,
		Signs.Woods.Dark
	)
end

-- A dead tree: a bare trunk with a few crooked branches
local function deadTree(ctx: Context.Context, x: number, z: number, height: number, log: string)
	local h = ctx.HeightAt(x, z)
	for y = 1, height do
		ctx.SetFree(x, h + y, z, log)
	end
	local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	for i = 1, ctx.Rng:NextInteger(3, 5) do
		local d = dirs[ctx.Rng:NextInteger(1, 4)]
		local y = h + ctx.Rng:NextInteger(math.max(2, height - 4), height)
		local length = ctx.Rng:NextInteger(2, 4)
		for n = 1, length do
			ctx.SetFree(x + d[1] * n, y + (if n > 2 and i % 2 == 0 then 1 else 0), z + d[2] * n, log)
		end
	end
end

-- A tall spire of rock on the ground at (x, z), tapering to `cap`
local function spire(
	ctx: Context.Context,
	x: number,
	z: number,
	height: number,
	radius: number,
	blocks: { string },
	cap: string
)
	local h0 = ctx.HeightAt(x, z)
	for y = 1, height do
		local r = radius * (1 - (y / height) ^ 2 * 0.65) + ctx.Noise(x + y * 2, z, 3, 81) * 0.9
		local reach = math.ceil(r)
		for dx = -reach, reach do
			for dz = -reach, reach do
				if dx * dx + dz * dz <= r * r then
					local block = if y == height
						then cap
						else blocks[math.floor(ctx.Hash(x + dx, y, z + dz) * #blocks) + 1]
					ctx.SetFree(x + dx, h0 + y, z + dz, block)
				end
			end
		end
	end
end

-- A broken stone wall: `length` blocks along x or z, its top stepping up and down
local function brokenWall(ctx: Context.Context, x: number, z: number, length: number, alongX: boolean, height: number)
	local mix = { "MossyStoneBricks", "CrackedStoneBricks", "StoneBricks", "MossyCobblestone" }
	for s = 0, length - 1 do
		local wx, wz = if alongX then x + s else x, if alongX then z else z + s
		local top = math.max(1, math.round(height * (0.4 + ctx.Hash(wx, 5, wz) * 0.9)))
		for y = 1, top do
			ctx.SetFree(wx, ctx.HeightAt(wx, wz) + y, wz, mix[math.floor(ctx.Hash(wx, y, wz) * #mix) + 1])
		end
	end
end

-- Overgrown ruins: a broken square of walls round an open floor, with an archway in one side
local function ruin(ctx: Context.Context, x: number, z: number, half: number)
	for dx = -half, half do
		for dz = -half, half do
			ctx.Set(
				x + dx,
				ctx.HeightAt(x + dx, z + dz),
				z + dz,
				if ctx.Hash(x + dx, 3, z + dz) < 0.4 then "MossyCobblestone" else "Cobblestone"
			)
		end
	end
	brokenWall(ctx, x - half, z - half, half * 2 + 1, true, 5)
	brokenWall(ctx, x - half, z + half, half * 2 + 1, true, 4)
	brokenWall(ctx, x - half, z - half + 1, half * 2 - 1, false, 5)
	-- The side with the archway
	for y = 1, 6 do
		ctx.SetFree(x + half, ctx.HeightAt(x + half, z - 2) + y, z - 2, "StoneBricks")
		ctx.SetFree(x + half, ctx.HeightAt(x + half, z + 2) + y, z + 2, "StoneBricks")
	end
	for dz = -2, 2 do
		ctx.SetFree(x + half, ctx.HeightAt(x + half, z + dz) + 7, z + dz, "CrackedStoneBricks")
	end
	Decor.Lantern(ctx.Decor, ctx.Top(x, ctx.HeightAt(x, z), z), false, 18)
end

-- Giant props made by generate_mesh, on the ground at (x, z)
local function prop(ctx: Context.Context, name: string, x: number, z: number, height: number, turn: number?)
	MonsterModels.Prop(
		ctx.Decor,
		name,
		ctx.Top(x, ctx.HeightAt(x, z), z),
		height,
		turn or ctx.Rng:NextNumber(0, 2 * math.pi)
	)
end

-- Records where this zone's monsters stand
local function mobSpots(
	ctx: Context.Context,
	island: Context.Island,
	ok: (x: number, z: number) -> boolean
): { Vector3 }
	local out: { Vector3 } = {}
	for _, spot in spots(ctx, island, MOBS_PER_ZONE, 9, 8, ok) do
		table.insert(out, ctx.Top(spot.X, ctx.HeightAt(spot.X, spot.Y), spot.Y))
	end
	return out
end

-- The zones ------------------------------------------------------------------------------

local function zoneByMonster(id: string): Monsters.Zone
	for _, zone in Monsters.Zones do
		if zone.Monster == id then
			return zone
		end
	end
	error(id)
end

-- Slime Meadow ----------------------------------------------------------------------------

local function meadowColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(2 + 6 * ctx.Noise(x, z, 28, 1) + 2 * ctx.Noise(x, z, 9, 2)), 0, 8)
	return if ctx.Noise(x, z, 7, 30) > 0.3 then "FlowerGrass" else "Grass", h
end

local function dressMeadow(ctx: Context.Context, island: Context.Island): { Vector3 }
	layRoads(ctx, MEADOW.Roads)
	lamps(ctx, MEADOW.Roads, 12)
	statue(ctx, 24, -168, "Slime", 44, -Vector3.zAxis)
	local function clear(x: number, z: number): boolean
		return roadDistance(x, z, MEADOW.Roads) > 5 and not ctx.NearArrival(x, z, 6) and not ctx.Flat(x, z, 3)
	end
	-- Mossy boulders and a few oaks, as in the first Skybounds slayer shot
	for _, spot in spots(ctx, island, 22, 4, 12, clear) do
		Common.Boulder(
			ctx,
			spot.X,
			spot.Y,
			ctx.Rng:NextInteger(3, 5),
			{ "MossyCobblestone", "Stone", "MossyCobblestone", "Cobblestone" }
		)
	end
	Common.Forest(ctx, island, 20, 5, function(x, z)
		return not clear(x, z)
	end, function(x, h, z)
		Trees.BigOak(x, h, z, ctx.Rng:NextInteger(6, 8), ctx.SetFree)
	end)
	Common.Scatter(ctx, island, 0.09, 0.05, MEADOW_FLOWERS)
	Common.CliffVines(ctx, island, 0.3)
	return mobSpots(ctx, island, function(x, z)
		return clear(x, z) and z > -205
	end)
end

-- Bramble Woods ---------------------------------------------------------------------------

local BRAMBLE_RUINS = { { -160, -176, 6 }, { -232, -116, 7 }, { -176, -92, 5 } }

local function brambleColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1.5 + 4.5 * ctx.Noise(x, z, 22, 3) + 2 * ctx.Noise(x, z, 9, 4)), 0, 7)
	local patch = ctx.Noise(x, z, 8, 33)
	-- A dark forest floor: leaf litter over mud, as in the first Skybounds slayer shot
	return if patch > 0.2 then "CoarseDirt" elseif patch < -0.1 then "Mud" else "Grass", h
end

local function dressBramble(ctx: Context.Context, island: Context.Island): { Vector3 }
	layRoads(ctx, BRAMBLE.Roads)
	lamps(ctx, BRAMBLE.Roads, 14)
	statue(ctx, -170, -158, "Thornling", 46, Vector3.xAxis)
	for _, r in BRAMBLE_RUINS do
		ruin(ctx, r[1], r[2], r[3])
	end
	local function clear(x: number, z: number): boolean
		for _, r in BRAMBLE_RUINS do
			if math.abs(x - r[1]) <= r[3] + 3 and math.abs(z - r[2]) <= r[3] + 3 then
				return false
			end
		end
		return roadDistance(x, z, BRAMBLE.Roads) > 5 and not ctx.Flat(x, z, 3)
	end
	-- The big dark trees: redwoods with spruces between them
	Common.Forest(ctx, island, 13, 5, function(x, z)
		return not clear(x, z)
	end, function(x, h, z)
		if ctx.Rng:NextNumber() < 0.45 then
			Trees.Redwood(
				x,
				h,
				z,
				ctx.Rng:NextInteger(26, 36),
				ctx.SetFree,
				if ctx.Rng:NextNumber() < 0.3 then 3 else 2
			)
		else
			Trees.Spruce(x, h, z, ctx.Rng:NextInteger(10, 14), ctx.SetFree)
		end
	end)
	for i, spot in spots(ctx, island, 8, 5, 14, clear) do
		brokenWall(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(5, 9), i % 2 == 0, 4)
	end
	for _, spot in spots(ctx, island, 10, 4, 14, clear) do
		Common.Boulder(
			ctx,
			spot.X,
			spot.Y,
			ctx.Rng:NextInteger(3, 4),
			{ "MossyCobblestone", "MossyStoneBricks", "Stone" }
		)
	end
	Common.Scatter(ctx, island, 0.05, 0.01, { Color3.fromRGB(150, 110, 220) })
	Common.CliffVines(ctx, island, 0.4)
	return mobSpots(ctx, island, clear)
end

-- Rust Canyon -----------------------------------------------------------------------------

local function canyonDepth(x: number, z: number): number
	return roadDistance(x, z, RUST.Roads)
end

local function rustColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local d = canyonDepth(x, z)
	local rise = d - 18 + ctx.Noise(x, z, 12, 6) * 8
	if rise <= 0 then
		return if ctx.Noise(x, z, 9, 34) > 0.15 then "Sand" else "CoarseDirt", 0
	end
	return "RedTerracotta", math.clamp(math.round(rise * 1.6 + ctx.Noise(x, z, 18, 7) * 5), 1, 22)
end

local function rustFill(ctx: Context.Context, x: number, y: number, z: number, _depth: number): string?
	if canyonDepth(x, z) <= 18 then
		return nil
	end
	-- Bands of colour that run along the cliffs, with their edges a little uneven
	local band = (y + math.floor(ctx.Noise(x, z, 14, 8) * 3)) % 7
	if band < 3 then
		return "RedTerracotta"
	elseif band < 5 then
		return "Terracotta"
	end
	return "Sandstone"
end

local function dressRust(ctx: Context.Context, island: Context.Island): { Vector3 }
	layRoads(ctx, RUST.Roads, { "StoneBricks", "Cobblestone", "StoneBricks", "Gravel" })
	lamps(ctx, RUST.Roads, 12)
	statue(ctx, -187, 40, "BoarBrute", 50, -Vector3.zAxis)
	-- A natural arch over the road, of the same bands as the cliffs
	for dx = -8, 8 do
		local top = 12 + math.floor(math.abs(dx) ^ 1.6 * 0.25)
		for y = top, top + 3 do
			if math.abs(dx) >= 3 or y >= 10 then
				ctx.Set(-205 + dx, y, 56, if y % 3 == 0 then "Terracotta" else "RedTerracotta")
			end
		end
	end
	for _, dx in { -8, 8 } do
		for y = 1, 12 do
			ctx.Set(-205 + dx, y, 56, if y % 3 == 0 then "Terracotta" else "RedTerracotta")
		end
	end
	local function clear(x: number, z: number): boolean
		return canyonDepth(x, z) > 5 and canyonDepth(x, z) <= 16 and not ctx.Flat(x, z, 2)
	end
	for _, spot in spots(ctx, island, 16, 4, 12, clear) do
		Common.Boulder(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(3, 5), { "Sandstone", "Terracotta", "Sandstone" })
	end
	-- Scrubby spruces up on the rims
	Common.Forest(ctx, island, 18, 4, function(x, z)
		return canyonDepth(x, z) < 26
	end, function(x, h, z)
		Trees.Spruce(x, h, z, ctx.Rng:NextInteger(7, 11), ctx.SetFree)
	end)
	Common.CliffVines(ctx, island, 0.12)
	return mobSpots(ctx, island, clear)
end

-- Bone Flats ------------------------------------------------------------------------------

local function boneColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(0.6 + 3 * ctx.Noise(x, z, 24, 10)), 0, 3)
	local patch = ctx.Noise(x, z, 10, 35)
	return if patch > 0.32 then "Sandstone" elseif patch < -0.34 then "Gravel" else "Sand", h
end

local function dressBone(ctx: Context.Context, island: Context.Island): { Vector3 }
	layRoads(ctx, BONE.Roads, { "Gravel", "Sandstone", "Gravel", "Path" })
	lamps(ctx, BONE.Roads, 14)
	statue(ctx, -44, 122, "Rattlebones", 48, -Vector3.xAxis)
	local function clear(x: number, z: number): boolean
		return roadDistance(x, z, BONE.Roads) > 5 and not ctx.Flat(x, z, 2)
	end
	-- Sandstone boulders and dunes of low rock
	for _, spot in spots(ctx, island, 14, 4, 12, clear) do
		Common.Boulder(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(3, 5), { "Sandstone", "Sand", "Sandstone" })
	end
	for _, spot in spots(ctx, island, 12, 5, 18, clear) do
		deadTree(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(9, 16), "DarkPlanks")
	end
	for _, spot in spots(ctx, island, 7, 8, 22, clear) do
		prop(ctx, "GiantCactus", spot.X, spot.Y, ctx.Rng:NextNumber(28, 40))
	end
	return mobSpots(ctx, island, clear)
end

-- Sporewood Bog ---------------------------------------------------------------------------

local SPORE_POOLS = { { 130, 148, 9 }, { 212, 148, 10 }, { 150, 76, 8 }, { 222, 86, 9 } }

local function sporeColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local h = math.clamp(math.round(1 + 3 * ctx.Noise(x, z, 18, 12)), 0, 4)
	local patch = ctx.Noise(x, z, 9, 36)
	-- Mostly mud, with a few small patches of the dusky glowing grass
	return if patch > 0.42 then "DuskGrass" elseif patch > -0.1 then "Mud" else "CoarseDirt", h
end

local function dressSpore(ctx: Context.Context, island: Context.Island): { Vector3 }
	layRoads(ctx, SPORE.Roads, { "Path", "Gravel", "Path", "Cobblestone" })
	lamps(ctx, SPORE.Roads, 13)
	statue(ctx, 155, 80, "Sporeling", 46, -Vector3.xAxis)
	for _, pool in SPORE_POOLS do
		local water = Common.Pond(ctx, pool[1], pool[2], pool[3], "Mud", "Mud")
		for i = 1, pool[3] do
			local angle = i * 0.8
			Decor.LilyPad(
				ctx.Decor,
				Vector3.new(water.Position.X, water.Position.Y + water.Size.Y / 2, water.Position.Z)
					+ Vector3.new(math.cos(angle) * pool[3] * 1.8, 0, math.sin(angle) * pool[3] * 1.8),
				SPORE_GLOW[i % #SPORE_GLOW + 1]
			)
		end
	end
	local function clear(x: number, z: number): boolean
		for _, pool in SPORE_POOLS do
			if (x - pool[1]) ^ 2 + (z - pool[2]) ^ 2 <= (pool[3] + 4) ^ 2 then
				return false
			end
		end
		return roadDistance(x, z, SPORE.Roads) > 5 and not ctx.Flat(x, z, 2)
	end
	for _, spot in spots(ctx, island, 12, 6, 16, clear) do
		Common.GiantMushroom(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(8, 14), ctx.Rng:NextInteger(4, 6))
	end
	for _, spot in spots(ctx, island, 9, 7, 18, clear) do
		prop(ctx, "GlowMushroom", spot.X, spot.Y, ctx.Rng:NextNumber(14, 22))
	end
	Common.Forest(ctx, island, 20, 5, function(x, z)
		return not clear(x, z)
	end, function(x, h, z)
		Trees.Spruce(x, h, z, ctx.Rng:NextInteger(8, 12), ctx.SetFree)
	end)
	Common.Scatter(ctx, island, 0.05, 0.03, SPORE_GLOW)
	Common.CliffVines(ctx, island, 0.35)
	return mobSpots(ctx, island, clear)
end

-- Frostfang Peaks -------------------------------------------------------------------------

local FROST_LAKE = { X = 232, Z = -100, R = 13 }

local function frostColumn(ctx: Context.Context, x: number, z: number): (string, number)
	local d = roadDistance(x, z, FROST.Roads)
	local h = 2 + 11 * ctx.Noise(x, z, 24, 14) + 4 * ctx.Noise(x, z, 8, 15)
	h *= math.clamp((d - 6) / 20, 0.15, 1)
	h = math.clamp(math.round(h), 0, 14)
	return if h >= 7 or ctx.Noise(x, z, 8, 37) > 0.1 then "Snow" else "SnowyGrass", h
end

local function dressFrost(ctx: Context.Context, island: Context.Island): { Vector3 }
	layRoads(ctx, FROST.Roads, { "SnowyGrass", "Gravel", "Path", "Gravel" })
	lamps(ctx, FROST.Roads, 14)
	statue(ctx, 185, -132, "FrostYeti", 62, Vector3.zAxis)
	-- The frozen lake
	local water = Common.Pond(ctx, FROST_LAKE.X, FROST_LAKE.Z, FROST_LAKE.R, "Snow", "Gravel")
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
	local function clear(x: number, z: number): boolean
		if (x - FROST_LAKE.X) ^ 2 + (z - FROST_LAKE.Z) ^ 2 <= (FROST_LAKE.R + 4) ^ 2 then
			return false
		end
		return roadDistance(x, z, FROST.Roads) > 5 and not ctx.Flat(x, z, 2)
	end
	for _, spot in spots(ctx, island, 10, 6, 22, clear) do
		spire(
			ctx,
			spot.X,
			spot.Y,
			ctx.Rng:NextInteger(18, 34),
			ctx.Rng:NextNumber(2.5, 4),
			{ "Stone", "Stone", "Snow", "Ice" },
			"Snow"
		)
	end
	for _, spot in spots(ctx, island, 12, 6, 16, clear) do
		prop(ctx, "IceCrystal", spot.X, spot.Y, ctx.Rng:NextNumber(10, 18))
	end
	Common.Forest(ctx, island, 12, 4, function(x, z)
		return not clear(x, z)
	end, function(x, h, z)
		Trees.Spruce(x, h, z, ctx.Rng:NextInteger(9, 14), ctx.SetFree)
	end)
	for _, spot in spots(ctx, island, 12, 4, 14, clear) do
		Common.Boulder(ctx, spot.X, spot.Y, ctx.Rng:NextInteger(2, 4), { "Stone", "Stone", "Snow", "Cobblestone" })
	end
	Common.Scatter(ctx, island, 0.03, 0, {})
	Decor.Falling(ctx.Decor, ctx.Top(FROST.X, 26, FROST.Z), Vector2.new(FROST.R * 2 * SIZE, FROST.R * 2 * SIZE), "Snow")
	return mobSpots(ctx, island, clear)
end

-- The world -------------------------------------------------------------------------------

function Slaying.Build(ctx: Context.Context)
	for _, layout in { MEADOW, BRAMBLE, RUST, BONE, SPORE, FROST } do
		flattenRoads(ctx, layout.Roads)
	end
	for _, r in BRAMBLE_RUINS do
		ctx.Flatten(r[1] - r[3] - 2, r[2] - r[3] - 2, r[1] + r[3] + 2, r[2] + r[3] + 2)
	end
	for _, spot in { { 24, -168 }, { -170, -158 }, { -187, 40 }, { -44, 122 }, { 155, 80 }, { 185, -132 } } do
		ctx.Flatten(spot[1] - 7, spot[2] - 7, spot[1] + 7, spot[2] + 7)
	end
	for _, pool in SPORE_POOLS do
		ctx.Flatten(pool[1] - pool[3] - 4, pool[2] - pool[3] - 4, pool[1] + pool[3] + 4, pool[2] + pool[3] + 4)
	end
	-- The ends of the bridges, wide enough for the gates and their arches
	ctx.Flatten(-150, -137, -112, -123)
	ctx.Flatten(-212, -30, -198, 6)
	ctx.Flatten(-104, 83, -70, 97)
	ctx.Flatten(84, 103, 124, 117)
	ctx.Flatten(178, -6, 192, 30)
	ctx.Flatten(
		FROST_LAKE.X - FROST_LAKE.R - 4,
		FROST_LAKE.Z - FROST_LAKE.R - 4,
		FROST_LAKE.X + FROST_LAKE.R + 4,
		FROST_LAKE.Z + FROST_LAKE.R + 4
	)

	local meadow = ctx.Island({
		Name = "Slime Meadow",
		X = MEADOW.X,
		Z = MEADOW.Z,
		Radius = MEADOW.R,
		Column = function(x, z)
			return meadowColumn(ctx, x, z)
		end,
	})
	local bramble = ctx.Island({
		Name = "Bramble Woods",
		X = BRAMBLE.X,
		Z = BRAMBLE.Z,
		Radius = BRAMBLE.R,
		Column = function(x, z)
			return brambleColumn(ctx, x, z)
		end,
		Step = 8,
	})
	local rust = ctx.Island({
		Name = "Rust Canyon",
		X = RUST.X,
		Z = RUST.Z,
		Radius = RUST.R,
		Column = function(x, z)
			return rustColumn(ctx, x, z)
		end,
		Fill = function(x, y, z, depth)
			return rustFill(ctx, x, y, z, depth)
		end,
		Step = 8,
		Depth = 50,
	})
	local bone = ctx.Island({
		Name = "Bone Flats",
		X = BONE.X,
		Z = BONE.Z,
		Radius = BONE.R,
		Column = function(x, z)
			return boneColumn(ctx, x, z)
		end,
		Soil = "Sand",
		Rock = function()
			return "Sandstone"
		end,
		Step = 8,
	})
	local spore = ctx.Island({
		Name = "Sporewood Bog",
		X = SPORE.X,
		Z = SPORE.Z,
		Radius = SPORE.R,
		Column = function(x, z)
			return sporeColumn(ctx, x, z)
		end,
		Soil = "Mud",
		Step = 8,
	})
	local frost = ctx.Island({
		Name = "Frostfang Peaks",
		X = FROST.X,
		Z = FROST.Z,
		Radius = FROST.R,
		Column = function(x, z)
			return frostColumn(ctx, x, z)
		end,
		Soil = "Snow",
		Depth = 56,
		Step = 8,
	})

	-- Little rocks round the ring
	for _, spot in
		{
			{ -96, 8, -214, 4 },
			{ 104, 10, -178, 5 },
			{ -118, 14, -24, 5 },
			{ -300, 6, -60, 4 },
			{ 64, 12, -8, 5 },
			{ 58, 6, 196, 4 },
			{ -300, 10, 150, 4 },
			{ 270, 8, 40, 4 },
			{ 300, 4, -150, 4 },
		}
	do
		ctx.Islet(spot[1], spot[2], spot[3], spot[4])
	end

	-- The bridges between the zones, stone, with the monsters' lands either side
	ctx.Bridge(-130, -130, -72, -130, "StoneBricks")
	ctx.Bridge(-205, -68, -205, -8, "StoneBricks")
	ctx.Bridge(-150, 90, -84, 90, "StoneBricks")
	ctx.Bridge(46, 110, 104, 110, "StoneBricks")
	ctx.Bridge(185, 52, 185, 8, "StoneBricks")

	Common.Arrows(ctx, 5, -130, -Vector3.zAxis, {
		{ Text = "BRAMBLE WOODS", Toward = -Vector3.xAxis },
	}, Signs.Woods.Dark)

	-- The gates, each right where the bridge meets its island, facing back along the bridge
	local function gateAt(
		island: Context.Island,
		x: number,
		z: number,
		stepX: number,
		stepZ: number,
		monster: string,
		color: Color3
	)
		while ctx.IslandAt(x, z) ~= island do
			x += stepX
			z += stepZ
		end
		gate(ctx, x + stepX * 2, z + stepZ * 2, Vector3.new(-stepX, 0, -stepZ), zoneByMonster(monster), color)
	end
	gateAt(bramble, -100, -130, -1, 0, "Thornling", Color3.fromRGB(106, 200, 88))
	gateAt(rust, -205, -34, 0, 1, "BoarBrute", Color3.fromRGB(226, 120, 62))
	gateAt(bone, -104, 90, 1, 0, "Rattlebones", Color3.fromRGB(232, 222, 188))
	gateAt(spore, 84, 110, 1, 0, "Sporeling", Color3.fromRGB(160, 110, 240))
	gateAt(frost, 185, 26, 0, -1, "FrostYeti", Color3.fromRGB(140, 210, 250))

	local function zoneInfo(
		monster: string,
		island: Context.Island,
		x: number,
		z: number,
		front: Vector3,
		spotsOf: { Vector3 }
	)
		table.insert(Slaying.Layout, {
			Zone = zoneByMonster(monster),
			Island = island,
			Start = ctx.Top(x, 0, z),
			StartFacing = front,
			MobSpots = spotsOf,
		})
	end
	zoneInfo("Slime", meadow, 0, Slaying.SouthZ + 4, Vector3.zAxis, dressMeadow(ctx, meadow))
	zoneInfo("Thornling", bramble, -137, -130, -Vector3.xAxis, dressBramble(ctx, bramble))
	zoneInfo("BoarBrute", rust, -205, 0, Vector3.zAxis, dressRust(ctx, rust))
	zoneInfo("Rattlebones", bone, -76, 90, Vector3.xAxis, dressBone(ctx, bone))
	zoneInfo("Sporeling", spore, 112, 110, Vector3.xAxis, dressSpore(ctx, spore))
	zoneInfo("FrostYeti", frost, 185, 0, -Vector3.zAxis, dressFrost(ctx, frost))
end

return Slaying
