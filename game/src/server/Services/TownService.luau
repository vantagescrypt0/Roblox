--!strict
-- The Town place: the shared hub, on its own servers. Players teleport here from their
-- island's portal (TravelService) and arrive on a little spawn island to the south, laid
-- out like the Skybounds spawn:
--   Spawn        the runestone portal home on a paved islet with flower beds; ahead, a
--                wide stone bridge with walls, lantern posts and flower boxes runs north
--   The mountain a stone ridge across the south of the Town island, grassy and wooded on
--                top, with the SKYBLOX logo (rainbow and clouds) over a big stone arch;
--                the street runs through the arch into town
--   Market street  striped market stalls either side of the street past the arch
--   Market Square  a fountain in the middle of the town, ringed by four shops you walk
--                into, each with its shopkeeper behind the counter (Shops.luau, Util/Npc):
--                Market (Merchant) and Lumber Yard (Lumberjack) on the west side, Builder
--                and Miner on the east, each built in its own materials with its own
--                goods outside
--   Lanes        a lane west to a garden with a well, a lane east to a park with a pond;
--                four cottages with gardens around them
--   Portal Plaza at the north end: the runestone portals to the Farming, Woodcutting
--                and Mining worlds, and Slaying (boarded up until PvE), each with
--                banners in its colour
-- Nothing here can be broken, and anyone who falls off is put back at the spawn point.
--
-- Grid: x runs west to east, z south to north; y = 0 is the ground, things stand on y = 1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Places = require(ReplicatedStorage.Shared.Places)
local Ambience = require(script.Parent.Parent.Util.Ambience)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Build = require(script.Parent.Parent.Util.Build)
local Decor = require(script.Parent.Parent.Util.Decor)
local Logo = require(script.Parent.Parent.Util.Logo)
local Npc = require(script.Parent.Parent.Util.Npc)
local Portal = require(script.Parent.Parent.Util.Portal)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local Props = require(script.Parent.Parent.Util.Props)
local Signs = require(script.Parent.Parent.Util.Signs)
local Spawning = require(script.Parent.Parent.Util.Spawning)
local Trees = require(script.Parent.Parent.Util.Trees)
local Common = require(script.Parent.Parent.Worlds.Common)
local Context = require(script.Parent.Parent.Worlds.Context)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)
local TravelService = require(script.Parent.TravelService)

local CENTER = Vector3.new(0, 200, 0) -- top of the ground at the fountain
local SIZE = Blocks.Size
local FALL_LIMIT = 140
local SEED = 2026
-- The Town island reaches well south of the fountain, so the mountain stands inside it
-- (hills ease down near an island's rim)
local TOWN = { X = 0, Z = -12, R = 52 }
local SPAWN = { X = 0, Z = -88, R = 10 } -- the spawn islet
local HOME_PORTAL_Z = -93
local SPAWN_Z = -89
local SPAWN_PLAZA = { Z1 = -96, Z2 = -80, Half = 6 }
local PLAZA = { Z1 = -53, Z2 = -41, Half = 10 } -- in front of the mountain, where the bridge lands
local SOUTH_FACE, NORTH_FACE = -40, -27 -- the mountain's two cliffs (z)
local RIDGE_HALF = 33 -- how far the mountain runs east and west
local ARCH_HALF = 3 -- the arch through it is seven blocks wide
local PORTAL_Z = 32 -- the row of world portals
local SQUARE = 12 -- half-width of the Market Square

-- The mountain's peaks (heights in blocks): the tallest frame the logo, either side of it
local PEAKS = {
	{ X = -30, Z = -32, H = 16, R = 7 },
	{ X = -24, Z = -34, H = 34, R = 11 },
	{ X = -12, Z = -33, H = 25, R = 9 },
	{ X = 12, Z = -34, H = 26, R = 9 },
	{ X = 25, Z = -33, H = 35, R = 11 },
	{ X = 30, Z = -32, H = 15, R = 7 },
}
local WALL = 19 -- the rock behind the logo, tall enough to hide its back from town

local FLOWER_COLORS = {
	Color3.fromRGB(222, 62, 52),
	Color3.fromRGB(242, 212, 64),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(110, 132, 230),
	Color3.fromRGB(230, 120, 190),
}

-- The world portals, west to east, with their field colour and the blocks beside them
local WORLD_PORTALS: { { Kind: Places.Kind, Name: string, X: number, Color: Color3, Open: boolean } } = {
	{ Kind = "Farming", Name = "Farming World", X = -15, Color = Color3.fromRGB(250, 206, 84), Open = true },
	{ Kind = "Woodcutting", Name = "Woodcutting World", X = -5, Color = Color3.fromRGB(112, 208, 92), Open = true },
	{ Kind = "Mining", Name = "Mining World", X = 5, Color = Color3.fromRGB(255, 92, 36), Open = true },
	{ Kind = "Slaying", Name = "Slaying World", X = 15, Color = Color3.fromRGB(120, 36, 40), Open = false },
}

local TownService = {}

local world: BlockWorld.World
local ctx: Context.Context
local decor: Folder
local npcs: Folder
local rng = Random.new(SEED)
local shopkeepers: { [string]: Model } = {}

-- The shopkeeper models by shop id (see Shops.luau). Their "Head" model turns to look at
-- players (on the client).
function TownService.GetShopkeepers(): { [string]: Model }
	return shopkeepers
end

local function set(x: number, y: number, z: number, block: Build.Pattern?)
	Build.Set(world, x, y, z, block)
end

local function setFree(x: number, y: number, z: number, block: string)
	Build.SetFree(world, x, y, z, block)
end

-- The top face of a block, where things stand
local function top(x: number, y: number, z: number): Vector3
	return Build.Top(world, x, y, z)
end

-- Ground ---------------------------------------------------------------------------

-- Same answer every time for a cell
local function hash(x: number, y: number, z: number): number
	return Random.new(x * 73856093 + y * 19349663 + z * 83492791 + SEED):NextNumber()
end

-- Grass, with flowers in some of it
local function lawn(x: number, z: number): string
	return if hash(x, 0, z) < 0.07 then "FlowerGrass" else "Grass"
end

-- Where the mountain's two cliffs are at x: straight behind the arch, ragged elsewhere,
-- closing in toward its ends
local function faces(x: number): (number, number)
	local ax = math.abs(x)
	local shrink = if ax > 20 then math.floor((ax - 20) / 3) else 0
	local south = SOUTH_FACE
	if ax > ARCH_HALF + 4 then
		south += math.floor((math.noise(x / 5, 0.3, 7.7) + 0.5) * 3)
	end
	return south + shrink, NORTH_FACE - shrink
end

-- The mountain's height at (x, z), 0 off it: a wall of rock between its two cliffs, peaks
-- rising either side of the logo, stepping down a block or two at the cliff edges
local function ridgeHeight(x: number, z: number): number
	local south, north = faces(x)
	local inside = math.min(z - south, north - z)
	local ax = math.abs(x)
	if inside < 0 or ax > RIDGE_HALF then
		return 0
	end
	local h = if ax <= 16 then WALL else WALL * (1 - ((ax - 16) / (RIDGE_HALF - 14)) ^ 2)
	for _, peak in PEAKS do
		local d = math.sqrt((x - peak.X) ^ 2 + ((z - peak.Z) * 1.3) ^ 2)
		h = math.max(h, peak.H * (1 - d / peak.R))
	end
	h += math.noise(x / 6, z / 6, 3.1) * 3
	if inside == 0 then
		h *= 0.6
	elseif inside == 1 then
		h *= 0.82
	end
	if ax <= ARCH_HALF + 4 then
		h = math.max(h, 13)
	end
	return math.max(1, math.floor(h + 0.5))
end

-- The mountain's rock: stone with patches of cobble and moss
local function rock(x: number, y: number, z: number): string
	local roll = hash(x, y, z)
	return if roll < 0.1 then "MossyCobblestone" elseif roll < 0.18 then "Cobblestone" else "Stone"
end

-- Old stone bricks, some mossy or cracked (the arch, the bridge walls)
local function oldBricks(x: number, y: number, z: number): string
	local roll = hash(x, y + 50, z)
	return if roll < 0.12 then "MossyStoneBricks" elseif roll < 0.22 then "CrackedStoneBricks" else "StoneBricks"
end

-- The spawn islet: a paved square round the portal home with flower beds down its sides
local function spawnColumn(x: number, z: number): (string, number)
	local ax = math.abs(x)
	if ax <= SPAWN_PLAZA.Half and z >= SPAWN_PLAZA.Z1 and z <= SPAWN_PLAZA.Z2 then
		if ax >= 4 and ax <= 5 and z >= HOME_PORTAL_Z + 3 and z <= SPAWN_PLAZA.Z2 - 3 then
			return "Grass", 0
		end
		return if ax == SPAWN_PLAZA.Half or z == SPAWN_PLAZA.Z1 then "StoneBricks" else "SmoothStone", 0
	end
	return lawn(x, z), 0
end

-- What the Town's ground is made of at (x, z): streets, plazas and lanes are paved, the
-- rest is grass with a few flowers in it
local function groundBlock(x: number, z: number): string
	local ax, az = math.abs(x), math.abs(z)
	if ax <= PLAZA.Half and z >= PLAZA.Z1 and z <= PLAZA.Z2 then -- in front of the mountain
		return if ax == PLAZA.Half or z == PLAZA.Z1 then "StoneBricks" else "SmoothStone"
	end
	if ax <= 10 and z > NORTH_FACE and z < -SQUARE then -- the market street
		return if ax <= 3 then "Cobblestone" elseif ax == 4 or ax == 10 then "StoneBricks" else "Path"
	end
	if ax <= SQUARE and az <= SQUARE and ax + az <= 21 then -- Market Square
		local ring = math.max(ax, az)
		if ring == SQUARE or ring == 7 then
			return "StoneBricks"
		end
		return if ring <= 4 then "SmoothStone" else "Cobblestone"
	end
	if ax <= 2 and z > -27 and z < 24 then -- main street
		return "Cobblestone"
	end
	if ax == 3 and z > -27 and z < 24 then -- its kerbs
		return "StoneBricks"
	end
	if z >= 24 and ax <= 21 then -- Portal Plaza
		return if z == 24 or ax == 21 then "StoneBricks" else "Cobblestone"
	end
	if az <= 1 and ax > SQUARE and ax <= 30 then -- lanes to the garden and the park
		return "Path"
	end
	return lawn(x, z)
end

-- The Town island's columns: the mountain's rock and grass, or the flat town
local function townColumn(x: number, z: number): (string, number)
	local h = ridgeHeight(x, z)
	if h == 0 then
		return groundBlock(x, z), 0
	end
	-- Grass where it's gentle, bare rock on the steep bits
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		if math.abs(ridgeHeight(x + d[1], z + d[2]) - h) > 1 then
			return rock(x, h, z), h
		end
	end
	return "Grass", h
end

-- Street furniture ---------------------------------------------------------------------

-- A wooden lamp post with a lantern box on top
local function lampPost(x: number, z: number)
	Decor.LampPost(decor, top(x, 0, z))
end

local function tree(x: number, z: number, height: number)
	Trees.Oak(x, 0, z, height, setFree)
end

-- A raised flower bed: a stone kerb round grass full of flowers
local function flowerBed(x1: number, z1: number, x2: number, z2: number)
	for x = math.min(x1, x2), math.max(x1, x2) do
		for z = math.min(z1, z2), math.max(z1, z2) do
			if x == x1 or x == x2 or z == z1 or z == z2 then
				set(x, 1, z, "StoneBricks")
			else
				set(x, 1, z, "Grass")
				if rng:NextNumber() < 0.8 then
					Decor.Flower(decor, top(x, 1, z), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)])
				end
			end
		end
	end
end

-- The way in ---------------------------------------------------------------------------

-- The bridge from the spawn islet to Town: seven blocks wide, stone bricks with low walls,
-- lantern posts on pillars along the walls with flower boxes between them, and a stone
-- arch underneath where it crosses the sky
local function bridge(z1: number, z2: number)
	local half = 3
	for z = z1, z2 do
		for x = -half, half do
			set(x, 0, z, if x == 0 then "SmoothStone" else "StoneBricks")
		end
		for _, x in { -half, half } do
			set(x, 1, z, oldBricks(x, 1, z))
		end
	end
	local pillars = {}
	for z = z1 + 1, z2 - 1, 5 do
		table.insert(pillars, z)
	end
	for i, z in pillars do
		for _, x in { -half, half } do
			set(x, 2, z, "SmoothStone")
			Decor.LampPost(decor, top(x, 2, z), 6)
			local nextZ = pillars[i + 1]
			if nextZ then
				-- Flowers along the top of the wall to the next pillar
				local inward = Vector3.new(-math.sign(x), 0, 0)
				Decor.FlowerBox(
					decor,
					top(x, 1, (z + nextZ) / 2) - inward * 0.45,
					inward,
					(nextZ - z - 1) * SIZE - 0.4,
					FLOWER_COLORS
				)
			end
		end
	end
	-- The arch underneath, thin in the middle and deep at the ends
	local gapFrom, gapTo
	for z = z1, z2 do
		if not ctx.IslandAt(0, z) then
			gapFrom = gapFrom or z
			gapTo = z
		end
	end
	if gapFrom and gapTo then
		local a, b = gapFrom - 1, gapTo + 1
		for z = a, b do
			local middle = 1 - math.abs((z - a) / math.max(b - a, 1) * 2 - 1)
			local depth = 1 + math.floor((1 - middle) ^ 2 * 5)
			for x = -half, half do
				for y = -1, -depth, -1 do
					set(x, y, z, if y == -1 then "StoneBricks" else "Cobblestone")
				end
			end
		end
	end
end

-- Is (x, y) in the arch's opening (seen end on)? Seven wide, eight high, corners cut
local function opening(x: number, y: number): boolean
	return y >= 1 and (math.abs(x) <= ARCH_HALF and y <= 7 or math.abs(x) <= ARCH_HALF - 1 and y == 8)
end

-- The arch through the mountain: a stone-brick tunnel lit by lanterns, with a stone gate
-- standing out from the cliff at each end
local function arch()
	for z = SOUTH_FACE, NORTH_FACE do
		for x = -ARCH_HALF - 1, ARCH_HALF + 1 do
			set(x, 0, z, if math.abs(x) <= 1 then "SmoothStone" else "Cobblestone")
			for y = 1, 9 do
				if opening(x, y) then
					ctx.Carve(x, y, z)
				else
					local lining = false
					for dx = -1, 1 do
						for dy = -1, 1 do
							lining = lining or opening(x + dx, y + dy)
						end
					end
					if lining then
						set(x, y, z, oldBricks(x, y, z))
					end
				end
			end
		end
	end
	for z = SOUTH_FACE + 2, NORTH_FACE - 1, 4 do
		for _, side in { -1, 1 } do
			Decor.WallLantern(
				decor,
				BlockWorld.position(world, side * (ARCH_HALF + 0.5), 4, z),
				Vector3.new(-side, 0, 0)
			)
		end
	end
	-- The gates: two pillars and a lintel with a keystone, capped with smooth stone
	for _, face in { { SOUTH_FACE - 1, -1 }, { NORTH_FACE + 1, 1 } } do
		local z, out = face[1], Vector3.new(0, 0, face[2])
		for _, x in { -ARCH_HALF - 2, ARCH_HALF + 2 } do
			for y = 1, 10 do
				set(x, y, z, if y == 1 then "SmoothStone" else oldBricks(x, y, z))
			end
			Decor.WallLantern(decor, BlockWorld.position(world, x, 6, z) + out * (SIZE / 2), out)
		end
		for x = -ARCH_HALF - 1, ARCH_HALF + 1 do
			set(x, 10, z, if x == 0 then "SmoothStone" else oldBricks(x, 10, z))
		end
		for x = -ARCH_HALF - 3, ARCH_HALF + 3 do
			set(x, 11, z, "SmoothStone")
		end
	end
end

-- Trees, vines and boulders on the mountain, and the logo over the arch
local function mountain(island: Context.Island)
	Common.Forest(ctx, island, 6, 3, function(x, z)
		local h = ridgeHeight(x, z)
		return h < 5 or math.abs(x) <= ARCH_HALF + 6 or world.Cells[BlockWorld.key(x, ctx.HeightAt(x, z), z)] ~= "Grass"
	end, function(x, h, z)
		Trees.Oak(x, h, z, rng:NextInteger(4, 6), ctx.SetFree)
	end)
	Common.CliffVines(ctx, island, 0.3, function(x, z)
		-- Only on the mountain, and not over the arch or behind the logo
		return ridgeHeight(x, z) == 0 or math.abs(x) <= 16 and z <= SOUTH_FACE + 1 or math.abs(x) <= ARCH_HALF + 2
	end)
	for _, spot in { { -15, -45 }, { 17, -46 }, { -27, -43 }, { 28, -42 }, { -36, -30 }, { 36, -29 } } do
		Common.Boulder(ctx, spot[1], spot[2], 3, { "Stone", "Cobblestone", "MossyCobblestone", "Stone" })
	end
	Logo.Build(
		decor,
		BlockWorld.position(world, 0, 11, SOUTH_FACE - 3) + Vector3.new(0, SIZE / 2 + 0.6, 0),
		-Vector3.zAxis
	)
end

-- The market street ----------------------------------------------------------------------

type StallInfo = {
	Z: number,
	Side: number, -- -1 west of the street, 1 east
	Colors: { Color3 },
	Goods: { string }, -- on the counter: crops, block pieces or "Flowers"
	Back: { string }, -- blocks at the back
}

local CREAM = Color3.fromRGB(240, 234, 222)
local STALLS: { StallInfo } = {
	{
		Z = -23,
		Side = -1,
		Colors = { Color3.fromRGB(200, 58, 52), CREAM },
		Goods = { "Crop_Wheat", "Crop_Carrot", "Crop_Potato" },
		Back = { "Pumpkin", "HayBale", "Melon" },
	},
	{
		Z = -16,
		Side = -1,
		Colors = { Color3.fromRGB(226, 110, 172), CREAM },
		Goods = { "Flowers", "Flowers", "Flowers" },
		Back = { "Leaves", "Barrel", "Leaves" },
	},
	{
		Z = -23,
		Side = 1,
		Colors = { Color3.fromRGB(64, 112, 196), CREAM },
		Goods = { "CoalOre", "IronOre", "GoldOre" },
		Back = { "Barrel", "Crate", "Barrel" },
	},
	{
		Z = -16,
		Side = 1,
		Colors = { Color3.fromRGB(70, 150, 72), CREAM },
		Goods = { "BirchWood", "CherryWood", "SpruceWood" },
		Back = { "Wood", "Crate", "Wood" },
	},
}

-- A market stall facing the street: posts at the corners, a counter with goods on it, more
-- stock at the back, and a striped cloth roof sloping down to a hanging edge at the front
local function stall(info: StallInfo)
	local site = Build.Site(world, info.Side * 6, info.Z, Vector3.new(-info.Side, 0, 0))
	for _, u in { -2, 2 } do
		site:Fill(u, 1, 0, u, 3, 0, "Wood")
		site:Fill(u, 1, 2, u, 4, 2, "Wood")
	end
	site:Fill(-1, 1, 0, 1, 1, 0, "Planks")
	for i, good in info.Goods do
		local at = site:Pos(i - 2, 1.5, 0)
		if good == "Flowers" then
			for _, du in { -0.25, 0.25 } do
				Decor.Flower(decor, at + site:Dir(du, 0) * SIZE, FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)])
			end
		elseif string.sub(good, 1, 5) == "Crop_" then
			local crop = Props.Place(good, at, at + site.Front, decor)
			if crop then
				crop:ScaleTo(0.45)
				crop:PivotTo(CFrame.lookAt(at, at + site.Front))
			end
		else
			Decor.Piece(
				decor,
				good,
				Vector3.one * 1.6,
				CFrame.new(at + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0.3 * i, 0)
			)
		end
	end
	for i, block in info.Back do
		site:Set(i - 2, 1, 2, block)
	end
	for i = 0, 4 do
		local color = info.Colors[i % #info.Colors + 1]
		local a = site:Pos(i - 2, 3.2, -0.8)
		local b = site:Pos(i - 2, 4.9, 2.6)
		Decor.Part(
			decor,
			"Awning",
			Vector3.new(SIZE, 0.2, (b - a).Magnitude),
			CFrame.lookAt((a + b) / 2, b),
			color,
			Enum.Material.Fabric
		)
		Decor.Part(
			decor,
			"Awning",
			Vector3.new(SIZE, 0.9, 0.15),
			CFrame.lookAt(a, a + site.Front) * CFrame.new(0, -0.45, 0),
			color,
			Enum.Material.Fabric
		)
	end
	Decor.Lantern(decor, site:Pos(0, 2.9, 1.2), true, 14)
end

-- The fountain in the middle of the square: a stone basin of water with a pillar
-- spraying from the top and four spouts at the corners
local function fountain()
	for x = -3, 3 do
		for z = -3, 3 do
			local rim = math.abs(x) == 3 or math.abs(z) == 3
			if rim and not (math.abs(x) == 3 and math.abs(z) == 3) then
				set(x, 1, z, "StoneBricks")
			elseif rim then
				set(x, 1, z, "SmoothStone")
				set(x, 2, z, "StoneBricks")
				Decor.Jet(decor, top(x, 2, z), 4)
			else
				set(x, 0, z, "SmoothStone")
			end
		end
	end
	for y = 1, 3 do
		set(0, y, 0, "StoneBricks")
	end
	set(0, 4, 0, "SmoothStone")
	Decor.Water(decor, top(0, 0, 0) + Vector3.new(0, SIZE * 0.8, 0), Vector2.new(5 * SIZE, 5 * SIZE), SIZE * 0.8)
	Decor.Jet(decor, top(0, 4, 0), 10)
	for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		Decor.Bench(decor, top(corner[1] * 6, 0, corner[2] * 6), Vector3.new(-corner[1], 0, -corner[2]).Unit)
	end
end

-- Shops ----------------------------------------------------------------------------

export type Style = {
	Wall: Build.Pattern,
	Corner: string,
	Beam: string,
	Roof: string,
	Gable: Build.Pattern,
	Floor: string,
}

local SHOP_HALF_WIDTH, SHOP_DEPTH, SHOP_HEIGHT = 5, 8, 4

-- Height of a roof (built by Site:Roof over [-hw, hw]) above the wall top at u
local function roofRise(hw: number, u: number): number
	return math.min(u + hw + 1, hw + 1 - u)
end

-- The shell of a building on `site`: a stone foundation, walls with corner posts and a
-- beam along the top, a floor, a front door (2u + 1 wide, up to doorTop) and a gable roof
-- facing the front. Returns the ridge's height.
local function building(
	site: Build.Site,
	hw: number,
	depth: number,
	height: number,
	style: Style,
	doorHalf: number,
	doorTop: number
): number
	site:Fill(-hw, 0, 0, hw, 0, depth, "StoneBricks")
	site:Fill(-hw + 1, 0, 1, hw - 1, 0, depth - 1, style.Floor)
	site:Walls(-hw, 1, 0, hw, height - 1, depth, style.Wall)
	site:Walls(-hw, height, 0, hw, height, depth, style.Beam)
	for _, u in { -hw, hw } do
		for _, v in { 0, depth } do
			site:Fill(u, 1, v, u, height, v, style.Corner)
		end
	end
	site:Clear(-doorHalf, 1, 0, doorHalf, doorTop, 0)
	return site:Roof(-hw, 0, hw, depth, height + 1, style.Roof, style.Gable, false)
end

-- Two-pane windows in the walls of a building
local function windows(site: Build.Site, hw: number, depth: number, frontU: { number })
	for _, u in frontU do
		site:Fill(u, 2, 0, u + 1, 3, 0, "Glass")
		-- A window box of flowers under it
		local sill = site:Pos(u + 0.5, 1.5, 0) + site.Front * (SIZE / 2)
		Decor.FlowerBox(decor, sill, site.Front, 2 * SIZE - 0.4, FLOWER_COLORS)
	end
	for _, u in { -hw, hw } do
		site:Fill(u, 2, 3, u, 3, depth - 3, "Glass")
	end
end

-- A brick chimney rising through the roof at (u, v), with smoke
local function chimney(site: Build.Site, hw: number, height: number, u: number, v: number)
	local topY = height + roofRise(hw, u) + 2
	site:Fill(u, height + 1, v, u, topY, v, "Bricks")
	Decor.Smoke(decor, site:Pos(u, topY + 0.6, v))
end

type ShopInfo = {
	Shop: string,
	Sign: string,
	X: number,
	Z: number,
	Front: Vector3,
	Style: Style,
	Shelf: Build.Pattern,
	Counter: string,
	Goods: { string },
	Extras: (site: Build.Site) -> (),
}

local function shop(info: ShopInfo)
	local hw, depth, height = SHOP_HALF_WIDTH, SHOP_DEPTH, SHOP_HEIGHT
	local site = Build.Site(world, info.X, info.Z, info.Front)
	building(site, hw, depth, height, info.Style, 1, 3)
	windows(site, hw, depth, { -4, 3 })
	-- A round window in the gable, and the shop's name above the door
	site:Set(0, height + 3, 0, "Glass")
	Signs.Board(
		decor,
		`{info.Shop}Sign`,
		info.Sign,
		site:Pos(0, height + 1.4, 0) + site.Front * (SIZE / 2 + 0.25),
		site.Front,
		5
	)
	for _, u in { -2.6, 2.6 } do
		Decor.WallLantern(decor, site:Pos(u, 3.4, 0) + site.Front * (SIZE / 2), site.Front)
	end

	-- Inside: a counter across the room, the shopkeeper behind it, shelves at the back
	site:Fill(-3, 1, 4, 3, 1, 4, info.Counter)
	site:Fill(-hw + 1, 1, depth - 1, hw - 1, 2, depth - 1, info.Shelf)
	site:Fill(-hw + 1, 1, depth - 2, -hw + 1, 1, depth - 2, "Barrel")
	site:Fill(hw - 1, 1, depth - 2, hw - 1, 1, depth - 2, "Crate")
	for i, good in info.Goods do
		local at = site:Pos(if i == 1 then -2 else 2, 1.5, 4)
		if string.sub(good, 1, 5) == "Crop_" then
			local crop = Props.Place(good, at, at + site.Front, decor)
			if crop then
				crop:ScaleTo(0.45)
				crop:PivotTo(CFrame.lookAt(at, at + site.Front))
			end
		else
			Decor.Piece(
				decor,
				good,
				Vector3.one * 1.3,
				CFrame.new(at + Vector3.new(0, 0.65, 0)) * CFrame.Angles(0, 0.4 * i, 0)
			)
		end
	end
	Decor.Lantern(decor, site:Pos(-3, 1.5, 4), false, 16)
	Decor.Lantern(decor, site:Pos(3, 1.5, 4), false, 16)
	Decor.Lantern(decor, site:Pos(0, height - 0.8, 2), true, 26)
	local feet = site:Pos(0, 1, 6) - Vector3.new(0, SIZE / 2, 0)
	shopkeepers[info.Shop] = Npc.Build(info.Shop, feet, site.Front, npcs)

	info.Extras(site)
end

local SHOPS: { ShopInfo } = {
	{
		Shop = "Merchant",
		Sign = "MARKET",
		X = -13,
		Z = -7,
		Front = Vector3.xAxis,
		Style = {
			Wall = "Plaster",
			Corner = "Wood",
			Beam = "DarkPlanks",
			Roof = "RoofRed",
			Gable = "Plaster",
			Floor = "Planks",
		},
		Shelf = "HayBale",
		Counter = "Planks",
		Goods = { "Crop_Wheat", "Crop_Carrot" },
		Extras = function(site)
			Decor.Awning(decor, site:Pos(0, 3.6, 0) + site.Front * (SIZE / 2), site.Front, 3 * SIZE)
			-- Crates of produce out front, and a hay bale
			for i, crop in { "Crop_Potato", "Crop_Carrot", "Crop_Wheat" } do
				local u = -5 + i
				site:Set(u - 1, 1, -1, "Crate")
				local at = site:Pos(u - 1, 1.5, -1)
				local model = Props.Place(crop, at, at + site.Front, decor)
				if model then
					model:ScaleTo(0.5)
					model:PivotTo(CFrame.new(at))
				end
			end
			site:Set(4, 1, -1, "HayBale")
			site:Set(4, 2, -1, "HayBale")
			site:Set(3, 1, -1, "HayBale")
		end,
	},
	{
		Shop = "Lumberjack",
		Sign = "LUMBER YARD",
		X = -13,
		Z = 7,
		Front = Vector3.xAxis,
		Style = {
			Wall = "Wood",
			Corner = "DarkPlanks",
			Beam = "DarkPlanks",
			Roof = "RoofSlate",
			Gable = "DarkPlanks",
			Floor = "DarkPlanks",
		},
		Shelf = "Wood",
		Counter = "DarkPlanks",
		Goods = { "Wood", "Planks" },
		Extras = function(site)
			-- A log pile along the side wall and a chopping stump with an axe in it
			site:Fill(-6, 1, 2, -6, 2, 6, "Wood")
			site:Fill(-7, 1, 3, -7, 1, 5, "Wood")
			site:Set(3, 1, -2, "Wood")
			local stump = site:Pos(3, 1.5, -2)
			Decor.Piece(
				decor,
				"Planks",
				Vector3.new(0.3, 2.2, 0.3),
				CFrame.new(stump + Vector3.new(0.2, 1.4, 0)) * CFrame.Angles(0, 0, math.rad(25))
			)
			Decor.Piece(
				decor,
				"StoneBricks",
				Vector3.new(1, 0.9, 0.2),
				CFrame.new(stump + Vector3.new(0.2, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(25))
			)
			site:Set(-3, 1, -1, "Barrel")
		end,
	},
	{
		Shop = "Builder",
		Sign = "BUILDER",
		X = 13,
		Z = -7,
		Front = -Vector3.xAxis,
		Style = {
			Wall = "Bricks",
			Corner = "StoneBricks",
			Beam = "StoneBricks",
			Roof = "RoofSlate",
			Gable = "Bricks",
			Floor = "SmoothStone",
		},
		Shelf = function(x, y, z)
			local choices = { "StoneBricks", "Bricks", "Glass", "Plaster", "Cobblestone" }
			return choices[(x + y * 3 + z * 5) % #choices + 1]
		end,
		Counter = "StoneBricks",
		Goods = { "Bricks", "Glass" },
		Extras = function(site)
			Decor.Awning(decor, site:Pos(0, 3.6, 0) + site.Front * (SIZE / 2), site.Front, 3 * SIZE, {
				Color3.fromRGB(70, 104, 170),
				Color3.fromRGB(240, 234, 222),
			})
			-- Scaffolding up the side wall
			for _, v in { 1, 4, 7 } do
				site:Fill(-7, 1, v, -7, 5, v, "Wood")
			end
			site:Fill(-7, 3, 1, -7, 3, 7, "Planks")
			-- Pallets of blocks out front
			site:Fill(-4, 1, -1, -3, 1, -1, "StoneBricks")
			site:Set(-4, 2, -1, "StoneBricks")
			site:Fill(3, 1, -1, 4, 1, -1, "Bricks")
			site:Set(4, 2, -1, "Bricks")
		end,
	},
	{
		Shop = "Miner",
		Sign = "MINER",
		X = 13,
		Z = 7,
		Front = -Vector3.xAxis,
		Style = {
			Wall = function(_x, y, _z)
				return if y <= 1 then "MossyStoneBricks" else "StoneBricks"
			end,
			Corner = "Cobblestone",
			Beam = "DarkPlanks",
			Roof = "RoofSlate",
			Gable = "DarkPlanks",
			Floor = "StoneBricks",
		},
		Shelf = function(x, y, z)
			local choices = { "CoalOre", "IronOre", "Stone", "Barrel" }
			return choices[(x * 3 + y + z * 7) % #choices + 1]
		end,
		Counter = "DarkPlanks",
		Goods = { "CoalOre", "IronOre" },
		Extras = function(site)
			-- The forge: a furnace inside under a chimney, and a cart of ore on rails out front
			site:Set(4, 1, 6, "Furnace")
			chimney(site, SHOP_HALF_WIDTH, SHOP_HEIGHT, 4, 6)
			Decor.Rails(decor, site:Pos(-4, 0.5, -1.5), site:Pos(4, 0.5, -1.5))
			Decor.Minecart(decor, site:Pos(-2, 0.5, -1.5), site:Dir(1, 0), "IronOre")
			site:Set(4, 1, -1, "Barrel")
			site:Set(4, 2, -1, "Barrel")
		end,
	},
}

-- Cottages -------------------------------------------------------------------------

-- A small house: plaster and timber walls, a thatch or tiled roof, a chimney, a bed and
-- a table inside, and a fenced garden out front with a path to the nearest street
local function cottage(x: number, z: number, front: Vector3, roof: string, pathTo: { number })
	local site = Build.Site(world, x, z, front)
	local style: Style = {
		Wall = "Plaster",
		Corner = "Wood",
		Beam = "DarkPlanks",
		Roof = roof,
		Gable = "DarkPlanks",
		Floor = "Planks",
	}
	building(site, 3, 6, 3, style, 0, 2)
	site:Fill(-2, 2, 0, -2, 2, 0, "Glass")
	site:Fill(2, 2, 0, 2, 2, 0, "Glass")
	for _, u in { -2, 2 } do
		Decor.FlowerBox(decor, site:Pos(u, 1.5, 0) + site.Front * (SIZE / 2), site.Front, SIZE - 0.4, FLOWER_COLORS)
	end
	site:Fill(-3, 2, 2, -3, 2, 4, "Glass")
	site:Fill(3, 2, 2, 3, 2, 4, "Glass")
	chimney(site, 3, 3, 2, 5)
	-- Inside: a bed, a table and a bookshelf
	site:Fill(-2, 1, 4, -2, 1, 5, "RedWool")
	site:Set(-2, 1, 5, "WhiteWool")
	site:Set(2, 1, 3, "Planks")
	site:Fill(-2, 1, 1, -1, 2, 1, "Bookshelf")
	Decor.Lantern(decor, site:Pos(2, 1.5, 3), false, 14)
	Decor.WallLantern(decor, site:Pos(1.3, 2.6, 0) + site.Front * (SIZE / 2), site.Front)
	-- Garden: a fence round the front yard with a gap at the path, flowers inside
	local function yard(u: number, v: number): Vector3
		return site:Pos(u, 0, v) + Vector3.new(0, SIZE / 2, 0)
	end
	Decor.Fence(decor, yard(-3.5, -0.5), yard(-3.5, -3.5))
	Decor.Fence(decor, yard(3.5, -0.5), yard(3.5, -3.5))
	Decor.Fence(decor, yard(-3.5, -3.5), yard(-0.5, -3.5))
	Decor.Fence(decor, yard(0.5, -3.5), yard(3.5, -3.5))
	for _, u in { -2, -1, 1, 2 } do
		for v = -3, -1 do
			if rng:NextNumber() < 0.6 then
				local cx, cz = site:Cell(u, v)
				Decor.Flower(decor, top(cx, 0, cz), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)])
			end
		end
	end
	-- Path from the door out of the yard and on to the street
	local px, pz = site:Cell(0, -1)
	for v = -1, -3, -1 do
		local cx, cz = site:Cell(0, v)
		set(cx, 0, cz, "Path")
		px, pz = cx, cz
	end
	local tx, tz = pathTo[1], pathTo[2]
	while px ~= tx or pz ~= tz do
		if px ~= tx then
			px += if tx > px then 1 else -1
		else
			pz += if tz > pz then 1 else -1
		end
		if BlockWorld.get(world, px, 0, pz) == "Grass" or BlockWorld.get(world, px, 0, pz) == "FlowerGrass" then
			set(px, 0, pz, "Path")
		end
	end
end

-- The garden and the park ------------------------------------------------------------------

-- West garden: a stone well under a little roof, flower beds and benches
local function garden()
	local wx = -31
	for dx = -1, 1 do
		for dz = -1, 1 do
			if dx ~= 0 or dz ~= 0 then
				set(wx + dx, 1, dz, "Cobblestone")
			end
			set(wx + dx, 4, dz, "DarkPlanks")
		end
	end
	for _, dx in { -1, 1 } do
		for _, dz in { -1, 1 } do
			set(wx + dx, 2, dz, "Wood")
			set(wx + dx, 3, dz, "Wood")
		end
	end
	set(wx, 0, 0, "Stone")
	Decor.Water(decor, top(wx, 0, 0) + Vector3.new(0, SIZE * 0.6, 0), Vector2.new(SIZE, SIZE), SIZE * 0.6)
	set(wx, 5, 0, "DarkPlanks")
	-- Flower beds either side of the lane
	for _, z0 in { -5, 4 } do
		for x = -28, -24 do
			for z = z0, z0 + 1 do
				set(x, 0, z, "Grass")
				Decor.Flower(decor, top(x, 0, z), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)])
			end
		end
	end
	Decor.Bench(decor, top(-27, 0, -2), Vector3.zAxis)
	Decor.Bench(decor, top(-27, 0, 2), -Vector3.zAxis)
end

-- East park: a pond with a sandy shore and lily pads, benches and trees
local function park()
	local cx, cz, r = 30, 0, 4.6
	for x = cx - 6, cx + 6 do
		for z = cz - 6, cz + 6 do
			local d = math.sqrt((x - cx) ^ 2 + (z - cz) ^ 2)
			if d <= r then
				set(x, 0, z, "Sand")
				set(x, -1, z, "Sand")
				if d <= r - 1 then
					set(x, 0, z, nil)
				end
			elseif d <= r + 1 and math.abs(z) > 1 then
				set(x, 0, z, "Sand")
			end
		end
	end
	Decor.Water(
		decor,
		top(cx, -1, cz) + Vector3.new(0, SIZE * 0.75, 0),
		Vector2.new(7.2 * SIZE, 7.2 * SIZE),
		SIZE * 0.8
	)
	for _, spot in { { 28.5, -1.5 }, { 31.2, 1.3 }, { 29.4, 2 }, { 32, -1.8 } } do
		local at = top(0, -1, 0)
		local pad = Decor.Part(
			decor,
			"LilyPad",
			Vector3.new(1.4, 0.1, 1.4),
			CFrame.new(Vector3.new(spot[1] * SIZE, at.Y + SIZE * 0.78, spot[2] * SIZE)),
			Color3.fromRGB(70, 140, 60)
		)
		pad.CastShadow = false
	end
	Decor.Bench(decor, top(cx - 6, 0, cz - 4), Vector3.new(1, 0, 0.5).Unit)
	Decor.Bench(decor, top(cx - 6, 0, cz + 4), Vector3.new(1, 0, -0.5).Unit)
end

-- The portals ----------------------------------------------------------------------

-- Blocks and banners beside a world portal that show what's through it
local function portalDecor(info: { Kind: Places.Kind, X: number, Color: Color3 })
	local cx = info.X
	for _, side in { -1, 1 } do
		local x = cx + side * 3
		if info.Kind == "Farming" then
			set(x, 0, PORTAL_Z, "Farmland")
			set(x, 1, PORTAL_Z - 1, "HayBale")
			local crop = Props.Place(if side < 0 then "Crop_Wheat" else "Crop_Carrot", top(x, 0, PORTAL_Z), nil, decor)
			if crop then
				crop:ScaleTo(0.68)
				crop:PivotTo(CFrame.new(top(x, 0, PORTAL_Z)))
			end
		elseif info.Kind == "Woodcutting" then
			set(x, 1, PORTAL_Z, "Wood")
			set(x, 2, PORTAL_Z, "Wood")
			set(x, 3, PORTAL_Z, "Leaves")
		elseif info.Kind == "Mining" then
			set(x, 1, PORTAL_Z, "Stone")
			set(x, 2, PORTAL_Z, if side < 0 then "CoalOre" else "IronOre")
		else
			set(x, 1, PORTAL_Z, "Obsidian")
			set(x, 2, PORTAL_Z, "Obsidian")
		end
	end
	-- One tall banner pole behind the arch, its banner flying above it
	for y = 1, 10 do
		set(cx, y, PORTAL_Z + 1, "DarkPlanks")
	end
	Decor.Banner(decor, top(cx, 10, PORTAL_Z + 1) - Vector3.new(0, 0.6, SIZE / 2 + 0.3), -Vector3.zAxis, info.Color, 6)
end

local function portals()
	Portal.addCells(world.Cells, world.Protected, 0, HOME_PORTAL_Z)
	local home = Portal.makeField(world, 0, HOME_PORTAL_Z)
	TravelService.AddPortal(home, "Island", "Go home", function()
		return true
	end)
	Signs.Board(
		decor,
		"HomeSign",
		"HOME",
		BlockWorld.position(world, 0, 6, HOME_PORTAL_Z) + Vector3.zAxis * (SIZE / 2 + 0.25),
		Vector3.zAxis,
		2
	)

	local south = -Vector3.zAxis
	for _, info in WORLD_PORTALS do
		Portal.addCells(world.Cells, world.Protected, info.X, PORTAL_Z)
		portalDecor(info)
		Signs.Board(
			decor,
			`{info.Kind}Sign`,
			string.upper(info.Kind),
			BlockWorld.position(world, info.X, 6, PORTAL_Z) + south * (SIZE / 2 + 0.25),
			south,
			3
		)
	end
end

-- Portal fields are parts: made after the blocks are drawn
local function portalFields()
	for _, info in WORLD_PORTALS do
		if info.Open then
			local field = Portal.makeField(world, info.X, PORTAL_Z, info.Color)
			TravelService.AddPortal(field, info.Kind, "Travel", function()
				return true
			end, info.Name)
		else
			local field = Portal.makeClosed(world, info.X, PORTAL_Z, info.Color)
			local prompt = Prompts.Create(field, { Action = "Coming soon", Object = info.Name, Distance = 12 })
			prompt.Triggered:Connect(function(player)
				StateService.Notify(player, `{info.Name} opens when monsters arrive. Coming soon!`, "info")
			end)
		end
	end
end

-- Clouds drifting round the islands, some below them, and little rocks floating nearby
local function sky()
	for _, cloud in
		{
			{ -70, 6, -60, 70 },
			{ 75, 12, -40, 80 },
			{ -95, -10, 25, 90 },
			{ 80, -20, 50, 70 },
			{ -35, 22, 85, 60 },
			{ 45, -32, -100, 80 },
			{ -55, -26, -120, 70 },
			{ 105, 18, 10, 60 },
			{ 20, 26, -130, 60 },
		}
	do
		Logo.SkyCloud(decor, CENTER + Vector3.new(cloud[1], cloud[2], cloud[3]) * SIZE, cloud[4], rng)
	end
	for _, spot in { { -30, 3, -82, 3 }, { 28, -4, -76, 3 }, { -62, 6, 6, 4 }, { 64, -3, -22, 3 }, { 44, 9, 50, 3 } } do
		ctx.Islet(spot[1], spot[2], spot[3], spot[4])
	end
end

local function build()
	world = BlockWorld.new(CENTER - Vector3.new(0, SIZE / 2, 0), "Town", workspace)
	npcs = Instance.new("Folder")
	npcs.Name = "Npcs"
	npcs.Parent = world.Model
	decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = world.Model
	ctx = Context.new(world, decor, SEED, HOME_PORTAL_Z)

	-- Ground that must stay ground, even near an island's rim
	ctx.Flatten(-SPAWN_PLAZA.Half - 1, SPAWN_PLAZA.Z1, SPAWN_PLAZA.Half + 1, SPAWN_PLAZA.Z2, true)
	ctx.Flatten(-PLAZA.Half, PLAZA.Z1, PLAZA.Half, PLAZA.Z2 - 3, true)
	ctx.Flatten(-22, PORTAL_Z - 9, 22, PORTAL_Z + 3, true)
	ctx.Flatten(-32, 12, -23, 20, true)
	ctx.Flatten(23, 12, 32, 20, true)
	ctx.Flatten(23, -7, 37, 7, true)
	local spawnIsland = ctx.Island({
		Name = "Spawn",
		X = SPAWN.X,
		Z = SPAWN.Z,
		Radius = SPAWN.R,
		Column = spawnColumn,
	})
	local town = ctx.Island({
		Name = "Town",
		X = TOWN.X,
		Z = TOWN.Z,
		Radius = TOWN.R,
		Column = townColumn,
		Fill = function(x, y, z, depth)
			if ridgeHeight(x, z) == 0 then
				return nil
			end
			if depth == 1 and world.Cells[BlockWorld.key(x, y + 1, z)] == "Grass" then
				return "Dirt"
			end
			return rock(x, y, z)
		end,
	})

	-- The way in: spawn, the bridge, the plaza and the arch through the mountain
	portals()
	for _, x in { -5, -4, 4, 5 } do
		for z = HOME_PORTAL_Z + 3, SPAWN_PLAZA.Z2 - 3 do
			if rng:NextNumber() < 0.75 then
				Decor.Flower(decor, top(x, 0, z), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)])
			end
		end
	end
	for _, spot in { { -4, HOME_PORTAL_Z }, { 4, HOME_PORTAL_Z }, { -4, SPAWN_PLAZA.Z2 }, { 4, SPAWN_PLAZA.Z2 } } do
		lampPost(spot[1], spot[2])
	end
	bridge(SPAWN_PLAZA.Z2 + 1, PLAZA.Z1 - 1)
	flowerBed(-PLAZA.Half + 1, -51, -6, -44)
	flowerBed(6, -51, PLAZA.Half - 1, -44)
	for _, spot in { { -7, -42 }, { 7, -42 }, { -5, PLAZA.Z1 + 1 }, { 5, PLAZA.Z1 + 1 } } do
		lampPost(spot[1], spot[2])
	end
	Decor.Bench(decor, top(-4, 0, -47), Vector3.xAxis)
	Decor.Bench(decor, top(4, 0, -47), -Vector3.xAxis)
	arch()
	mountain(town)

	-- The town
	for _, info in STALLS do
		stall(info)
	end
	fountain()
	for _, info in SHOPS do
		shop(info)
	end
	cottage(-20, -20, Vector3.xAxis, "Thatch", { -5, -20 })
	cottage(20, -20, -Vector3.xAxis, "RoofRed", { 5, -20 })
	cottage(-25, 16, Vector3.xAxis, "RoofRed", { -22, 1 })
	cottage(25, 16, -Vector3.xAxis, "Thatch", { 22, 1 })
	garden()
	park()

	-- A signpost at the square's north edge points the way
	Signs.Arrows(decor, top(5, 0, 17), -Vector3.xAxis, {
		{ Text = "THE WORLDS", Toward = Vector3.zAxis },
		{ Text = "HOME", Toward = -Vector3.zAxis },
	})
	for _, z in { -25, -19, 13 } do
		lampPost(-4, z)
		lampPost(4, z)
	end
	for _, corner in { { -10, -10 }, { 10, -10 }, { -10, 10 }, { 10, 10 } } do
		lampPost(corner[1], corner[2])
	end
	for _, spot in { { -10, 28 }, { 0, 29 }, { 10, 28 }, { -20, 28 }, { 20, 28 } } do
		lampPost(spot[1], spot[2])
	end
	-- Trees round the edge of town and on the lawns either side of the plaza
	for _, spot in
		{
			{ -12, -24, 5 },
			{ 12, -24, 4 },
			{ -14, 20, 4 },
			{ 14, 20, 5 },
			{ -35, -14, 5 },
			{ 35, -14, 4 },
			{ -35, 9, 4 },
			{ 35, 9, 5 },
			{ -27, 27, 4 },
			{ 27, 27, 5 },
			{ -35, -7, 4 },
			{ 35, -6, 4 },
			{ -17, -50, 5 },
			{ 18, -51, 4 },
			{ -26, -48, 4 },
			{ 26, -47, 5 },
		}
	do
		tree(spot[1], spot[2], spot[3])
	end
	sky()

	Common.Scatter(ctx, spawnIsland, 0.05, 0.08, FLOWER_COLORS)
	Common.Scatter(ctx, town, 0.05, 0.03, FLOWER_COLORS)
	BlockWorld.drawAll(world, true)
	portalFields()
end

function TownService.Start()
	Ambience.Apply(0)
	build()
	-- Players arrive in front of the home portal, facing up the main street
	local spawnPoint = Spawning.MakeSpawn(CENTER + Vector3.new(0, 0, SPAWN_Z * SIZE), Vector3.zAxis, world.Model)
	Spawning.Start(spawnPoint, CENTER.Y - FALL_LIMIT, function(player)
		QuestService.Record(player, "VisitTown")
	end)
end

return TownService
