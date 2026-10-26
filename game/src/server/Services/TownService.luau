--!strict
-- The Town place: the shared hub, a big floating island on its own servers. Players
-- teleport here from their island's portal (TravelService) and arrive at the south end.
--   Arrival      a paved plaza by the runestone portal home, a welcome gate and a main
--                street lined with lamps running north
--   Market Square  a fountain in the middle of the town, ringed by four shops you walk
--                into, each with its shopkeeper behind the counter (Shops.luau, Util/Npc):
--                Market (Merchant) and Lumber Yard (Lumberjack) on the west side, Builder
--                and Miner on the east, each built in its own materials with its own
--                goods outside
--   Lanes        a lane west to a garden with a well, a lane east to a park with a pond;
--                four cottages with gardens around them
--   Portal Plaza at the north end, past a second gate: the runestone portals to the
--                Farming, Woodcutting and Mining worlds, and Slaying (boarded up until
--                PvE), each with banners in its colour
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
local Npc = require(script.Parent.Parent.Util.Npc)
local Portal = require(script.Parent.Parent.Util.Portal)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local Props = require(script.Parent.Parent.Util.Props)
local Signs = require(script.Parent.Parent.Util.Signs)
local Spawning = require(script.Parent.Parent.Util.Spawning)
local Trees = require(script.Parent.Parent.Util.Trees)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)
local TravelService = require(script.Parent.TravelService)

local CENTER = Vector3.new(0, 200, 0) -- top of the ground at the fountain
local RADIUS = 40
local SIZE = Blocks.Size
local FALL_LIMIT = 140
local HOME_PORTAL_Z = -34
local SPAWN_Z = -30
local PORTAL_Z = 32 -- the row of world portals
local SQUARE = 12 -- half-width of the Market Square

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
local decor: Folder
local npcs: Folder
local rng = Random.new(2026)
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

local edgeNoise: { number } = {}
for i = 0, 23 do
	edgeNoise[i] = rng:NextNumber(-1.6, 1.6)
end

local function edgeRadius(x: number, z: number): number
	local t = (math.atan2(z, x) / (2 * math.pi) + 0.5) * 24
	local i0 = math.floor(t) % 24
	local f = t - math.floor(t)
	return RADIUS + edgeNoise[i0] * (1 - f) + edgeNoise[(i0 + 1) % 24] * f
end

-- Same answer every time for a cell (for scattering flowers in the grass)
local function hash(x: number, z: number): number
	return Random.new(x * 7919 + z * 104729 + 17):NextNumber()
end

-- What the ground is made of at (x, z): streets, plazas and lanes are paved, the rest is
-- grass with a few flowers in it
local function groundBlock(x: number, z: number): string
	local ax, az = math.abs(x), math.abs(z)
	if ax <= 8 and z >= HOME_PORTAL_Z - 3 and z <= -27 then -- arrival plaza
		return if ax == 8 or z == -27 then "StoneBricks" else "SmoothStone"
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
	return if hash(x, z) < 0.07 then "FlowerGrass" else "Grass"
end

local function buildGround()
	for x = -RADIUS - 2, RADIUS + 2 do
		for z = -RADIUS - 2, RADIUS + 2 do
			local distance = math.sqrt(x * x + z * z)
			local edge = edgeRadius(x, z)
			if distance <= edge then
				set(x, 0, z, groundBlock(x, z))
				local t = distance / edge
				local depth = 2 + math.floor((1 - t) ^ 0.8 * 12) + (if (x * 7 + z * 13) % 4 == 0 then 1 else 0)
				for y = -1, -depth, -1 do
					set(x, y, z, if y >= -2 then "Dirt" else "Stone")
				end
			end
		end
	end
end

-- Street furniture ---------------------------------------------------------------------

-- A lamp post: a three-log post with a lantern on top
local function lampPost(x: number, z: number)
	for y = 1, 3 do
		set(x, y, z, "Wood")
	end
	Decor.Lantern(decor, top(x, 3, z), false, 22)
end

-- A gate over a street: two tall stone pillars with lanterns and a beam carrying a sign,
-- well above everyone's heads
local function gate(z: number, halfWidth: number, text: string, front: Vector3)
	for _, x in { -halfWidth, halfWidth } do
		for y = 1, 6 do
			set(x, y, z, "StoneBricks")
		end
		set(x, 7, z, "SmoothStone")
		Decor.Lantern(decor, top(x, 7, z), false, 18)
	end
	for x = -halfWidth + 1, halfWidth - 1 do
		set(x, 6, z, "DarkPlanks")
	end
	Signs.Board(
		decor,
		"GateSign",
		text,
		BlockWorld.position(world, 0, 5.1, z) + front * (SIZE / 2 + 0.25),
		front,
		math.min(halfWidth * 2 - 2, 8)
	)
end

local function tree(x: number, z: number, height: number)
	Trees.Oak(x, 0, z, height, setFree)
end

-- A planter box with a small tree in it
local function plantedTree(x: number, z: number)
	for dx = -1, 1 do
		for dz = -1, 1 do
			if dx ~= 0 or dz ~= 0 then
				set(x + dx, 1, z + dz, "StoneBricks")
			end
		end
	end
	set(x, 1, z, "Grass")
	Trees.Oak(x, 1, z, 3, setFree)
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
	Decor.Banner(
		decor,
		top(cx, 10, PORTAL_Z + 1) - Vector3.new(0, 0.6, SIZE / 2 + 0.3),
		-Vector3.zAxis,
		info.Color,
		6
	)
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

-- Grass, flowers and hedges in the open lawns (after everything else is built)
local function scatter()
	for x = -RADIUS, RADIUS do
		for z = -RADIUS, RADIUS do
			local ground = BlockWorld.get(world, x, 0, z)
			if (ground == "Grass" or ground == "FlowerGrass") and not BlockWorld.get(world, x, 1, z) then
				local roll = rng:NextNumber()
				if roll < 0.05 then
					Decor.Grass(decor, top(x, 0, z), rng)
				elseif roll < 0.075 then
					Decor.Flower(decor, top(x, 0, z), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)])
				end
			end
		end
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

	buildGround()
	portals()
	fountain()
	for _, info in SHOPS do
		shop(info)
	end
	cottage(-20, -21, Vector3.xAxis, "Thatch", { -4, -21 })
	cottage(20, -21, -Vector3.xAxis, "RoofRed", { 4, -21 })
	cottage(-25, 16, Vector3.xAxis, "RoofRed", { -22, 1 })
	cottage(25, 16, -Vector3.xAxis, "Thatch", { 22, 1 })
	garden()
	park()

	gate(-26, 4, "WELCOME TO TOWN", -Vector3.zAxis)
	-- Back from the portal row, so the plaza opens out beyond it
	gate(17, 6, "THE WORLDS", -Vector3.zAxis)
	for _, z in { -22, -16, 13 } do
		lampPost(-4, z)
		lampPost(4, z)
	end
	for _, corner in { { -10, -10 }, { 10, -10 }, { -10, 10 }, { 10, 10 } } do
		lampPost(corner[1], corner[2])
	end
	for _, spot in { { -6, -30 }, { 6, -30 }, { -10, 28 }, { 0, 29 }, { 10, 28 }, { -20, 28 }, { 20, 28 } } do
		lampPost(spot[1], spot[2])
	end
	for _, spot in { { -6, -16 }, { 6, -16 } } do
		plantedTree(spot[1], spot[2])
	end
	-- Hedges along the arrival street
	for z = -25, -18 do
		for _, x in { -5, 5 } do
			setFree(x, 1, z, "Leaves")
		end
	end
	-- Trees around the edge of town
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
			{ -12, -32, 4 },
			{ 12, -32, 5 },
			{ -27, 27, 4 },
			{ 27, 27, 5 },
			{ -35, -7, 4 },
			{ 35, -6, 4 },
			{ -24, -30, 5 },
			{ 24, -30, 4 },
		}
	do
		tree(spot[1], spot[2], spot[3])
	end

	BlockWorld.drawAll(world)
	portalFields()
	scatter()
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
