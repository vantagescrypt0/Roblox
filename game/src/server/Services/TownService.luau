--!strict
-- The Town place: the shared hub, a floating block island on its own servers. Players
-- teleport here from their island's portal (TravelService) and arrive by the runestone
-- portal home at the south end. Laid out like a village hub:
--   the plaza   a cobblestone square around a well, with four market stalls, two on each
--               side, each run by a shopkeeper (Shops.luau, Util/Npc.luau):
--               Merchant and Lumberjack on the west, Builder and Miner on the east
--   the portals a row of runestone arches at the north end, one per world: Farming,
--               Woodcutting and Mining (WorldService), and Slaying, boarded up until PvE
-- Lamp posts line the paths and a few oaks stand around the edge. Nothing here can be
-- broken, and anyone who falls off is put back at the spawn point.
--
-- Grid: x runs west to east, z south to north; y = 0 is the ground, things stand on y = 1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Places = require(ReplicatedStorage.Shared.Places)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
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

local TOWN_CENTER = Vector3.new(0, 200, 0) -- top of the ground at the well
local RADIUS = 26
local SIZE = Blocks.Size
local FALL_LIMIT = 120
local HOME_PORTAL_Z = -21
local SPAWN_Z = -17
local PORTAL_Z = 18 -- the row of world portals

-- The plaza (with its corners cut off), the main path south to north, and the walk in
-- front of the world portals
local function isPaved(x: number, z: number): boolean
	local plaza = math.abs(x) <= 8 and math.abs(z) <= 8 and math.abs(x) + math.abs(z) <= 13
	local path = math.abs(x) <= 1 and z >= HOME_PORTAL_Z - 1 and z <= 16
	local walk = math.abs(x) <= 18 and z >= 14 and z <= 16
	return plaza or path or walk
end

-- The stalls: the counter's middle cell and the way the shopkeeper faces (into the plaza)
local STALLS = {
	{ Shop = "Merchant", X = -9, Z = -4, Facing = Vector3.xAxis },
	{ Shop = "Lumberjack", X = -9, Z = 5, Facing = Vector3.xAxis },
	{ Shop = "Builder", X = 9, Z = -4, Facing = -Vector3.xAxis },
	{ Shop = "Miner", X = 9, Z = 5, Facing = -Vector3.xAxis },
}

-- What each stall shows on its counter: little blocks (block types) or crop models
local COUNTER_GOODS: { [string]: { string } } = {
	Merchant = { "Crop_Wheat", "Crop_Carrot" },
	Lumberjack = { "Wood", "Planks" },
	Builder = { "Cobblestone", "RedWool" },
	Miner = { "CoalOre", "IronOre" },
}

-- The world portals, west to east, with their field colour and the blocks beside them
local WORLD_PORTALS: { { Kind: Places.Kind, Name: string, X: number, Color: Color3, Open: boolean } } = {
	{ Kind = "Farming", Name = "Farming World", X = -15, Color = Color3.fromRGB(250, 206, 84), Open = true },
	{ Kind = "Woodcutting", Name = "Woodcutting World", X = -5, Color = Color3.fromRGB(112, 208, 92), Open = true },
	{ Kind = "Mining", Name = "Mining World", X = 5, Color = Color3.fromRGB(255, 92, 36), Open = true },
	{ Kind = "Slaying", Name = "Slaying World", X = 15, Color = Color3.fromRGB(120, 36, 40), Open = false },
}

local LAMPS = {
	{ -2, -14 },
	{ 2, -14 },
	{ -2, -10 },
	{ 2, -10 },
	{ -10, 17 },
	{ 0, 17 },
	{ 10, 17 },
	{ -7, 11 },
	{ 7, 11 },
}
local TREES = { { -19, -6, 5 }, { 19, -6, 4 }, { -21, 6, 4 }, { 21, 6, 5 }, { -12, -16, 4 }, { 12, -16, 5 } }

local TownService = {}

local world: BlockWorld.World
local shopkeepers: { [string]: Model } = {}

-- The shopkeeper models by shop id (see Shops.luau). Their "Head" model turns to look at
-- players (on the client).
function TownService.GetShopkeepers(): { [string]: Model }
	return shopkeepers
end

local function set(x: number, y: number, z: number, blockType: string)
	BlockWorld.setRaw(world, x, y, z, blockType)
	world.Protected[BlockWorld.key(x, y, z)] = true
end

-- Sets a cell only if it's still empty (decorations never overwrite the town)
local function setFree(x: number, y: number, z: number, blockType: string)
	if not BlockWorld.get(world, x, y, z) then
		set(x, y, z, blockType)
	end
end

local function signBoard(name: string, text: string, position: Vector3, front: Vector3, width: number)
	Signs.Board(world.Model, name, text, position, front, width)
end

local function part(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = world.Model
	return p
end

-- A small copy of a block (block art from ReplicatedStorage.Blocks), sitting on `top`
local function miniBlock(blockType: string, top: Vector3, size: number)
	local folder = ReplicatedStorage:FindFirstChild("Blocks")
	local template = folder and folder:FindFirstChild(blockType)
	if not template or not template:IsA("BasePart") then
		return
	end
	local block = template:Clone()
	block.Size *= size / math.max(block.Size.X, block.Size.Y, block.Size.Z)
	block.CFrame = CFrame.new(top + Vector3.new(0, size / 2, 0)) * template.CFrame.Rotation
	block.Anchored = true
	block.CanCollide = false
	block.Parent = world.Model
end

-- A lamp post: two logs with a lantern on top
local function lamp(x: number, z: number)
	set(x, 1, z, "Wood")
	set(x, 2, z, "Wood")
	local top = BlockWorld.position(world, x, 2, z) + Vector3.new(0, SIZE / 2, 0)
	local iron = Color3.fromRGB(46, 40, 38)
	part("LampBase", Vector3.new(1.6, 0.3, 1.6), CFrame.new(top + Vector3.new(0, 0.15, 0)), iron, Enum.Material.Metal)
	local glass = part(
		"Lantern",
		Vector3.new(1.1, 1.3, 1.1),
		CFrame.new(top + Vector3.new(0, 0.95, 0)),
		Color3.fromRGB(255, 214, 128),
		Enum.Material.Neon
	)
	part("LampCap", Vector3.new(1.7, 0.35, 1.7), CFrame.new(top + Vector3.new(0, 1.75, 0)), iron, Enum.Material.Metal)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 150)
	light.Brightness = 1.1
	light.Range = 18
	light.Shadows = false
	light.Parent = glass
end

-- A market stall around its counter cell (ox, oz), open toward `facing`, with its
-- shopkeeper behind the counter
local function stall(shopId: string, ox: number, oz: number, facing: Vector3)
	local fx, fz = math.round(facing.X), math.round(facing.Z)
	-- u runs along the counter, v from the counter (0) to the back wall (2)
	local function cell(u: number, v: number): (number, number)
		return ox - fz * u - fx * v, oz + fx * u - fz * v
	end
	for u = -2, 2 do
		local cx, cz = cell(u, 0)
		set(cx, 1, cz, "Planks") -- counter
		local bx, bz = cell(u, 2)
		set(bx, 1, bz, "Planks") -- back wall
		set(bx, 2, bz, "Planks")
	end
	for _, u in { -3, 3 } do
		for _, v in { 0, 2 } do
			local px, pz = cell(u, v)
			for y = 1, 3 do
				set(px, y, pz, "Wood")
			end
		end
	end
	for u = -3, 3 do
		for v = 0, 2 do
			local rx, rz = cell(u, v)
			set(rx, 4, rz, if u % 2 == 0 then "RedWool" else "WhiteWool")
		end
	end

	-- The shop's name on a board over the front of the roof
	local sx, sz = cell(0, 0)
	local front = Vector3.new(fx, 0, fz)
	local signAt = BlockWorld.position(world, sx, 5, sz) + front * (SIZE / 2 + 0.25)
	signBoard(`{shopId}Sign`, string.upper(shopId), signAt, front, 3)

	-- A few goods on the counter, either side of the shopkeeper
	local goods: { string } = COUNTER_GOODS[shopId] or {}
	for i, good in ipairs(goods) do
		local gx, gz = cell(if i == 1 then -1 else 1, 0)
		local top = BlockWorld.position(world, gx, 1, gz) + Vector3.new(0, SIZE / 2, 0)
		if string.sub(good, 1, 5) == "Crop_" then
			local crop = Props.Place(good, top, top + front, world.Model)
			if crop then
				crop:ScaleTo(0.45)
				crop:PivotTo(CFrame.lookAt(top, top + front))
			end
		else
			miniBlock(good, top, 1.3)
		end
	end

	local nx, nz = cell(0, 1)
	local feet = BlockWorld.position(world, nx, 1, nz) - Vector3.new(0, SIZE / 2, 0)
	local npcs = world.Model:FindFirstChild("Npcs") :: Folder
	shopkeepers[shopId] = Npc.Build(shopId, feet, front, npcs)
end

-- The town well in the middle of the plaza: a cobblestone ring around water, under a
-- little plank roof on four posts
local function well()
	for dx = -1, 1 do
		for dz = -1, 1 do
			if dx ~= 0 or dz ~= 0 then
				set(dx, 1, dz, "Cobblestone")
			end
			set(dx, 4, dz, "Planks")
		end
	end
	for _, dx in { -1, 1 } do
		for _, dz in { -1, 1 } do
			set(dx, 2, dz, "Wood")
			set(dx, 3, dz, "Wood")
		end
	end
	local water = part(
		"Water",
		Vector3.new(SIZE, SIZE * 0.8, SIZE),
		CFrame.new(BlockWorld.position(world, 0, 1, 0) - Vector3.new(0, SIZE * 0.1, 0)),
		Color3.fromRGB(64, 142, 206),
		Enum.Material.Glass
	)
	water.Transparency = 0.2
	water.CanCollide = false
end

-- Blocks beside a world portal that show what's through it
local function portalDecor(kind: Places.Kind, cx: number)
	for _, side in { -1, 1 } do
		local x = cx + side * 3
		if kind == "Farming" then
			set(x, 0, PORTAL_Z, "Farmland")
			local top = BlockWorld.position(world, x, 0, PORTAL_Z) + Vector3.new(0, SIZE / 2, 0)
			local crop = Props.Place(if side < 0 then "Crop_Wheat" else "Crop_Carrot", top, nil, world.Model)
			if crop then
				crop:ScaleTo(0.68)
				crop:PivotTo(CFrame.new(top))
			end
		elseif kind == "Woodcutting" then
			set(x, 1, PORTAL_Z, "Wood")
			set(x, 2, PORTAL_Z, "Wood")
			set(x, 3, PORTAL_Z, "Leaves")
		elseif kind == "Mining" then
			set(x, 1, PORTAL_Z, "Stone")
			set(x, 2, PORTAL_Z, if side < 0 then "CoalOre" else "IronOre")
		else
			set(x, 1, PORTAL_Z, "Obsidian")
			set(x, 2, PORTAL_Z, "Obsidian")
		end
	end
end

local function build()
	world = BlockWorld.new(TOWN_CENTER - Vector3.new(0, SIZE / 2, 0), "Town", workspace)
	local npcs = Instance.new("Folder")
	npcs.Name = "Npcs"
	npcs.Parent = world.Model

	-- Ground: a round floating island, paved where people walk
	for x = -RADIUS, RADIUS do
		for z = -RADIUS, RADIUS do
			local distance = math.sqrt(x * x + z * z)
			if distance <= RADIUS + 0.4 then
				set(x, 0, z, if isPaved(x, z) then "Cobblestone" else "Grass")
				local depth = 2 + math.floor((1 - distance / RADIUS) ^ 0.8 * 10)
				for y = -1, -depth, -1 do
					set(x, y, z, if y >= -2 then "Dirt" else "Stone")
				end
			end
		end
	end

	-- Portals first, so nothing else is built in their way
	Portal.addCells(world.Cells, world.Protected, 0, HOME_PORTAL_Z)
	for _, info in WORLD_PORTALS do
		Portal.addCells(world.Cells, world.Protected, info.X, PORTAL_Z)
		portalDecor(info.Kind, info.X)
	end

	well()
	for _, info in STALLS do
		stall(info.Shop, info.X, info.Z, info.Facing)
	end
	for _, spot in LAMPS do
		lamp(spot[1], spot[2])
	end
	-- Hedges along the path from the arrival portal
	for z = HOME_PORTAL_Z + 3, -11 do
		if z ~= -14 and z ~= -10 then
			setFree(-3, 1, z, "Leaves")
			setFree(3, 1, z, "Leaves")
		end
	end
	for _, spot in TREES do
		Trees.Oak(spot[1], 0, spot[2], spot[3], setFree)
	end

	BlockWorld.drawAll(world)

	-- Portal fields: home, and one to each world (the Slaying one is boarded up)
	local home = Portal.makeField(world, 0, HOME_PORTAL_Z)
	TravelService.AddPortal(home, "Island", "Go home", function()
		return true
	end)
	local south = -Vector3.zAxis
	signBoard(
		"HomeSign",
		"HOME",
		BlockWorld.position(world, 0, 6, HOME_PORTAL_Z) + Vector3.zAxis * (SIZE / 2 + 0.25),
		Vector3.zAxis,
		2
	)
	for _, info in WORLD_PORTALS do
		local signAt = BlockWorld.position(world, info.X, 6, PORTAL_Z) + south * (SIZE / 2 + 0.25)
		signBoard(`{info.Kind}Sign`, string.upper(info.Kind), signAt, south, 3)
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

function TownService.Start()
	build()
	-- Players arrive in front of the home portal, facing the plaza
	local spawnPoint = Spawning.MakeSpawn(TOWN_CENTER + Vector3.new(0, 0, SPAWN_Z * SIZE), Vector3.zAxis, world.Model)
	Spawning.Start(spawnPoint, TOWN_CENTER.Y - FALL_LIMIT, function(player)
		QuestService.Record(player, "VisitTown")
	end)
end

return TownService
