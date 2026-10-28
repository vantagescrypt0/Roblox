--!strict
-- Gives each player their own floating island made of blocks, generated for their
-- expansion tier, with their own block changes (data.Island.Blocks) on top. Spawns them
-- on it, rebuilds it bigger when they expand, and puts players back on it if they fall
-- off. Boulders and their ores are resource nodes: a mined node block grows back in the
-- same spot after a while (Blocks.NodeRespawn), so mined nodes are never saved as holes;
-- a mined ore node turns pale (Empty Ore) meanwhile. The stone underside has ore veins
-- to dig for (those are ordinary blocks).
--
-- Trees aren't nodes. Chop logs and they're gone; chop a tree's last log and the tree is
-- felled: its leaves fall away and it's gone for good (data.Island.Felled for the
-- island's own trees). BlockService gives the woodcutter saplings for it, always at least
-- one. Players plant saplings (TreeService): a sapling grows into a tree after
-- SAPLING_GROW_TIME (time counts while offline). Planted trees are saved in
-- data.Island.Trees by the cell they stand on until they're felled.
--
-- Grid: y = 0 is the top grass layer; things stand on it at y = 1.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Config = require(ReplicatedStorage.Shared.Config)
local IslandTiers = require(ReplicatedStorage.Shared.IslandTiers)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Portal = require(script.Parent.Parent.Util.Portal)
local Trees = require(script.Parent.Parent.Util.Trees)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local StateService = require(script.Parent.StateService)

local ISLAND = Config.Island
local SIZE = Blocks.Size

-- Ore veins in the island's stone underside: chance per stone block
local COAL_CHANCE, IRON_CHANCE, IRON_MIN_DEPTH = 0.07, 0.04, 4
-- Seconds a planted sapling takes to become a tree
local SAPLING_GROW_TIME = 180
-- A sapling's model is scaled to about this tall (studs)
local SAPLING_HEIGHT = 2.4
-- A felled tree's leaves drop over this many seconds
local LEAF_FALL_TIME = 1.6

type Cell = { X: number, Y: number, Z: number }
-- A resource node block: what grows there, and when it grows back if it's been mined
export type Node = { X: number, Y: number, Z: number, Block: string, RespawnAt: number? }
type PlantedTrees = { [string]: { PlantedAt: number, Height: number } }
-- A standing tree (one of the island's own, or one the player planted): its cells
type Tree = { Logs: { string }, Leaves: { string }, Planted: boolean }

export type Island = {
	World: BlockWorld.World,
	Model: Model,
	Plot: number,
	Spawn: SpawnLocation,
	-- World position of the middle of the top grass surface
	Center: Vector3,
	Tier: number,
	-- Generated cells before the player's changes (to work out what changed)
	Base: { [string]: string },
	CraftingTable: Cell,
	FarmCells: { Cell },
	PortalSurface: BasePart,
	Nodes: { [string]: Node }, -- by cell key
	-- Standing trees by the ground cell they stand on, and which tree each of their cells is
	Trees: { [string]: Tree },
	TreeCells: { [string]: string },
	-- Planted saplings still growing: ground cell key -> their model
	Saplings: { [string]: BasePart },
}
type IslandCallback = (player: Player, island: Island) -> ()

local IslandService = {}

local islands: { [Player]: Island } = {}
local usedPlots: { [number]: boolean } = {}
local rng = Random.new()
local createdCallbacks: { IslandCallback } = {}
local islandsFolder: Folder

-- Block types some item can place (so a block of that type might be player-made)
local placeable: { [string]: boolean } = {}
for _, item in Items do
	if item.Block then
		placeable[item.Block] = true
	end
end

-- Runs the callback for every island, now and whenever one is created or rebuilt.
function IslandService.OnIslandCreated(callback: IslandCallback)
	table.insert(createdCallbacks, callback)
	for player, island in islands do
		task.spawn(callback, player, island)
	end
end

function IslandService.GetIsland(player: Player): Island?
	return islands[player]
end

local function claimPlot(): number
	local plot = 1
	while usedPlots[plot] do
		plot += 1
	end
	usedPlots[plot] = true
	return plot
end

local function plotCenter(plot: number): Vector3
	local index = plot - 1
	local col = index % ISLAND.PlotsPerRow
	local row = index // ISLAND.PlotsPerRow
	local x = (col - (ISLAND.PlotsPerRow - 1) / 2) * ISLAND.Spacing
	return Vector3.new(x, ISLAND.Height, row * ISLAND.Spacing)
end

local key = BlockWorld.key

-- Generation ---------------------------------------------------------------------

local TREE_SPOTS = { { 4, 3 }, { -5, -1 }, { 6, -3 }, { 0, 7 }, { 8, 2 }, { -8, -6 } }
local ROCK_SPOTS = { { 2, -4 }, { 6, 0 }, { -8, 4 } }
local ROCK_SHAPE = {
	{ DX = 0, Y = 1, DZ = 0, Block = "Stone" },
	{ DX = 1, Y = 1, DZ = 0, Block = "IronOre" },
	{ DX = 0, Y = 1, DZ = 1, Block = "Stone" },
	{ DX = 0, Y = 2, DZ = 0, Block = "CoalOre" },
}
local CRAFTING_TABLE = { X = 3, Y = 1, Z = -2 }

-- The same noise for every tier, so bigger islands grow outward from the same shape
local edgeNoise: { number } = {}
do
	local noise = Random.new(4242)
	for i = 0, 15 do
		edgeNoise[i] = noise:NextNumber(-0.9, 0.9)
	end
end

local function edgeRadius(radius: number, x: number, z: number): number
	local t = (math.atan2(z, x) / (2 * math.pi) + 0.5) * 16
	local i0 = math.floor(t) % 16
	local f = t - math.floor(t)
	return radius + edgeNoise[i0] * (1 - f) + edgeNoise[(i0 + 1) % 16] * f
end

local function addNode(
	cells: { [string]: string },
	nodes: { [string]: Node },
	x: number,
	y: number,
	z: number,
	block: string
)
	local k = key(x, y, z)
	cells[k] = block
	nodes[k] = { X = x, Y = y, Z = z, Block = block }
end

-- Adds an oak tree standing on the cell (x, baseY, z) to `cells`. Cells that are already
-- taken (or that `blocked` says are) are skipped. Returns the tree's cells.
local function addTree(
	cells: { [string]: string },
	x: number,
	baseY: number,
	z: number,
	height: number,
	planted: boolean,
	blocked: ((cellKey: string) -> boolean)?
): Tree
	local tree: Tree = { Logs = {}, Leaves = {}, Planted = planted }
	Trees.Oak(x, baseY, z, height, function(px, py, pz, block)
		local k = key(px, py, pz)
		if not cells[k] and not (blocked and blocked(k)) then
			cells[k] = block
			table.insert(if block == "Wood" then tree.Logs else tree.Leaves, k)
		end
	end)
	return tree
end

local function grown(tree: { PlantedAt: number }): boolean
	return os.time() >= tree.PlantedAt + SAPLING_GROW_TIME
end

type Generated = {
	Cells: { [string]: string },
	Protected: { [string]: boolean },
	FarmCells: { Cell },
	PortalZ: number,
	Nodes: { [string]: Node },
	Trees: { [string]: Tree },
}

-- The block at a spot in the island's stone underside. Seeded by position, so an island
-- always generates the same veins (saves only store the player's changes).
local function undergroundBlock(x: number, y: number, z: number): string
	local roll = Random.new(x * 73856093 + y * 19349663 + z * 83492791):NextNumber()
	if -y >= IRON_MIN_DEPTH and roll < IRON_CHANCE then
		return "IronOre"
	elseif roll < IRON_CHANCE + COAL_CHANCE then
		return "CoalOre"
	end
	return "Stone"
end

-- `island` is the player's saved island data: their planted trees (the grown ones stand
-- here), the island trees they've felled, and their block changes (planted trees grow
-- around their blocks)
local function generate(tier: number, island: DataService.IslandData): Generated
	local spec = IslandTiers[tier]
	local radius = spec.Radius
	local cells: { [string]: string } = {}
	local protected: { [string]: boolean } = {}

	-- Body: grass on top, two layers of dirt, stone tapering underneath
	for x = -radius - 1, radius + 1 do
		for z = -radius - 1, radius + 1 do
			local distance = math.sqrt(x * x + z * z)
			local edge = edgeRadius(radius, x, z)
			if distance <= edge then
				local t = distance / edge
				local depth = 2 + math.floor((1 - t) ^ 0.75 * radius * 0.95) + ((x * 7 + z * 13) % 3 == 0 and 1 or 0)
				cells[key(x, 0, z)] = "Grass"
				for y = -1, -depth, -1 do
					cells[key(x, y, z)] = if y >= -2 then "Dirt" else undergroundBlock(x, y, z)
				end
			end
		end
	end

	-- Farmland patch (crops grow on top; both protected)
	local farmCells: { Cell } = {}
	local width, depthRows = spec.Farm[1], spec.Farm[2]
	for row = 0, depthRows - 1 do
		for col = 0, width - 1 do
			local x, z = -2 - width + col, 2 + row
			cells[key(x, 0, z)] = "Farmland"
			protected[key(x, 0, z)] = true
			protected[key(x, 1, z)] = true
			table.insert(farmCells, { X = x, Y = 0, Z = z })
		end
	end

	-- Crafting table
	local ct = CRAFTING_TABLE
	cells[key(ct.X, ct.Y, ct.Z)] = "CraftingTable"
	protected[key(ct.X, ct.Y, ct.Z)] = true
	-- Keep the space above it free so it can't be buried
	protected[key(ct.X, ct.Y + 1, ct.Z)] = true

	-- Runestone portal to the Town at the back (see Util/Portal)
	local portalZ = -(radius - 2)
	Portal.addCells(cells, protected, 0, portalZ)

	-- The island's own trees on free spots that fit this island (unless felled), then
	-- boulder nodes
	local trees: { [string]: Tree } = {}
	local count = 0
	for i, spot in TREE_SPOTS do
		if count >= spec.Trees then
			break
		end
		local x, z = spot[1], spot[2]
		if math.sqrt(x * x + z * z) <= radius - 1.5 then
			count += 1
			local groundKey = key(x, 0, z)
			if not island.Felled[groundKey] then
				trees[groundKey] = addTree(cells, x, 0, z, 4 + (i % 2), false)
			end
		end
	end
	-- Boulders: stone with a lump of coal on top and some iron showing (a reason to
	-- upgrade to a Stone Pickaxe)
	local nodes: { [string]: Node } = {}
	local rocks = 0
	for _, spot in ROCK_SPOTS do
		if rocks >= spec.Rocks then
			break
		end
		local x, z = spot[1], spot[2]
		if math.sqrt(x * x + z * z) <= radius - 1.5 then
			rocks += 1
			for _, part in ROCK_SHAPE do
				addNode(cells, nodes, x + part.DX, part.Y, z + part.DZ, part.Block)
			end
		end
	end

	-- Trees the player planted that have finished growing
	local changes = island.Blocks
	local function blocked(cellKey: string): boolean
		local change = changes[cellKey]
		return protected[cellKey] == true or (change ~= nil and change ~= "Air")
	end
	for groundKey, tree in island.Trees do
		if grown(tree) then
			local x, y, z = BlockWorld.unkey(groundKey)
			trees[groundKey] = addTree(cells, x, y, z, tree.Height, true, blocked)
		end
	end

	return {
		Cells = cells,
		Protected = protected,
		FarmCells = farmCells,
		PortalZ = portalZ,
		Nodes = nodes,
		Trees = trees,
	}
end

-- Building -----------------------------------------------------------------------

local function makeSpawn(position: Vector3, parent: Instance): SpawnLocation
	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "Spawn"
	spawnPoint.Size = Vector3.new(4, 1, 4)
	spawnPoint.CFrame = CFrame.new(position - Vector3.new(0, 0.5, 0))
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Transparency = 1
	spawnPoint.Duration = 0
	spawnPoint.Neutral = true
	spawnPoint.Parent = parent
	return spawnPoint
end

-- Keeps blocks out of a growing sapling's trunk (the cells above its ground cell)
local function protectTrunk(world: BlockWorld.World, x: number, y: number, z: number, height: number, on: boolean)
	for dy = 1, height do
		if on then
			world.Protected[key(x, y + dy, z)] = true
		else
			world.Protected[key(x, y + dy, z)] = nil
		end
	end
end

-- A growing sapling's model, standing on its ground cell. It carries the cell above as
-- X/Y/Z so it can be aimed at and clicked like a block.
local function makeSapling(island: Island, groundKey: string)
	local x, y, z = BlockWorld.unkey(groundKey)
	local models = ReplicatedStorage:FindFirstChild("ItemModels")
	local template = models and models:FindFirstChild("Sapling")
	local part: BasePart
	if template and template:IsA("BasePart") then
		part = template:Clone()
		part.Size *= SAPLING_HEIGHT / math.max(part.Size.Y, 0.1)
	else
		part = Instance.new("Part")
		part.Size = Vector3.new(0.6, SAPLING_HEIGHT, 0.6)
		part.Color = Color3.fromRGB(78, 154, 70)
	end
	part.Name = "Sapling"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	local top = BlockWorld.position(island.World, x, y, z) + Vector3.new(0, SIZE / 2, 0)
	part.CFrame = CFrame.new(top + Vector3.new(0, part.Size.Y / 2, 0)) * part.CFrame.Rotation
	part:SetAttribute("X", x)
	part:SetAttribute("Y", y + 1)
	part:SetAttribute("Z", z)
	part.Parent = island.Model
	island.Saplings[groundKey] = part
end

local function registerTree(island: Island, groundKey: string, tree: Tree)
	island.Trees[groundKey] = tree
	for _, cells in { tree.Logs, tree.Leaves } do
		for _, cellKey in cells do
			island.TreeCells[cellKey] = groundKey
		end
	end
end

-- Is this block still part of the island as it was made: a node, or a generated block
-- the player never touched (only trees count among blocks an item could place, so
-- placing and re-mining a block can't farm XP or copy items)?
local function isNatural(island: Island, data: DataService.Data, cellKey: string, blockType: string): boolean
	if island.Nodes[cellKey] then
		return true
	end
	if island.Base[cellKey] ~= blockType or data.Island.Blocks[cellKey] ~= nil then
		return false
	end
	return island.TreeCells[cellKey] ~= nil or not placeable[blockType]
end

-- Does the tree still have a log standing (one it grew, not one the player put back)?
local function standing(island: Island, data: DataService.Data, tree: Tree): boolean
	for _, cellKey in tree.Logs do
		if island.World.Cells[cellKey] == "Wood" and isNatural(island, data, cellKey, "Wood") then
			return true
		end
	end
	return false
end

-- The tree standing on `groundKey` is gone: it's no longer part of the island, its
-- leaves fall away (over LEAF_FALL_TIME, or at once if `instant`) and its spot is free
-- again. Returns how many leaves fell.
local function fell(island: Island, data: DataService.Data, groundKey: string, instant: boolean): number
	local tree = island.Trees[groundKey]
	if not tree then
		return 0
	end
	island.Trees[groundKey] = nil
	if tree.Planted then
		data.Island.Trees[groundKey] = nil
	else
		data.Island.Felled[groundKey] = true
	end

	local world = island.World
	local fallen = 0
	for _, cells in { tree.Logs, tree.Leaves } do
		for _, cellKey in cells do
			local leaf = world.Cells[cellKey] == "Leaves" and isNatural(island, data, cellKey, "Leaves")
			island.TreeCells[cellKey] = nil
			island.Base[cellKey] = nil
			-- A hole where the tree was is just air now; anything built there stays
			if data.Island.Blocks[cellKey] == "Air" then
				data.Island.Blocks[cellKey] = nil
			end
			if leaf then
				fallen += 1
				local x, y, z = BlockWorld.unkey(cellKey)
				if instant then
					BlockWorld.setRaw(world, x, y, z, nil)
				else
					task.delay(rng:NextNumber(0.1, LEAF_FALL_TIME), function()
						-- (unless the island was rebuilt meanwhile)
						if
							island.Model.Parent
							and world.Cells[cellKey] == "Leaves"
							and not island.TreeCells[cellKey]
						then
							BlockWorld.set(world, x, y, z, nil)
						end
					end)
				end
			end
		end
	end
	return fallen
end

local function build(player: Player, data: DataService.Data, tier: number, plot: number): Island
	local center = plotCenter(plot)
	local generated = generate(tier, data.Island)
	local world = BlockWorld.new(center - Vector3.new(0, SIZE / 2, 0), `Island_{player.UserId}`, islandsFolder)
	world.Model:SetAttribute("OwnerUserId", player.UserId)
	world.Model:SetAttribute("Tier", tier)
	world.Protected = generated.Protected

	local base = table.clone(generated.Cells)
	world.Cells = generated.Cells
	-- The player's own changes on top of the generated island. Nodes always come back,
	-- so any old change saved on a node's cell is dropped.
	for cellKey, blockType in data.Island.Blocks do
		if generated.Nodes[cellKey] then
			data.Island.Blocks[cellKey] = nil
		elseif not generated.Protected[cellKey] then
			(world.Cells :: any)[cellKey] = if blockType == "Air" then nil else blockType
		end
	end

	local spawnPoint = makeSpawn(center, world.Model)
	local island: Island = {
		World = world,
		Model = world.Model,
		Plot = plot,
		Spawn = spawnPoint,
		Center = center,
		Tier = tier,
		Base = base,
		CraftingTable = CRAFTING_TABLE,
		FarmCells = generated.FarmCells,
		PortalSurface = Portal.makeField(world, 0, generated.PortalZ),
		Nodes = generated.Nodes,
		Trees = {},
		TreeCells = {},
		Saplings = {},
	}
	for groundKey, tree in generated.Trees do
		registerTree(island, groundKey, tree)
	end
	-- A tree whose logs were all chopped (say the server stopped before it fell) falls now
	for groundKey, tree in generated.Trees do
		if not standing(island, data, tree) then
			fell(island, data, groundKey, true)
		end
	end
	BlockWorld.drawAll(world)

	for groundKey, tree in data.Island.Trees do
		if not grown(tree) then
			local x, y, z = BlockWorld.unkey(groundKey)
			protectTrunk(world, x, y, z, tree.Height, true)
			makeSapling(island, groundKey)
		end
	end
	return island
end

local function announce(player: Player, island: Island)
	islands[player] = island
	player.RespawnLocation = island.Spawn
	for _, callback in createdCallbacks do
		task.spawn(callback, player, island)
	end
end

-- Remembers a block change in the player's save. Every change to a generated block is
-- kept (even putting the same block back), so a block once broken is never "natural" again.
function IslandService.RecordChange(player: Player, x: number, y: number, z: number, blockType: string?)
	local island = islands[player]
	local data = DataService.GetData(player)
	if not island or not data then
		return
	end
	local cellKey = key(x, y, z)
	if blockType == nil and island.Base[cellKey] == nil then
		data.Island.Blocks[cellKey] = nil -- broke something the player built on open air
	else
		data.Island.Blocks[cellKey] = blockType or "Air"
	end
end

local function spawnCharacter(player: Player)
	local island = islands[player]
	if island then
		-- With streaming on, load the island on their screen first
		pcall(function()
			player:RequestStreamAroundAsync(island.Spawn.Position)
		end)
	end
	if player.Parent == Players then
		player:LoadCharacterAsync()
	end
end

local function clampTier(tier: number): number
	return math.clamp(tier, 1, #IslandTiers)
end

local function onDataLoaded(player: Player, data: DataService.Data)
	if islands[player] then
		return
	end
	announce(player, build(player, data, clampTier(data.Island.Tier), claimPlot()))

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			task.wait(Players.RespawnTime)
			if player.Character == character then
				spawnCharacter(player)
			end
		end)
	end)

	spawnCharacter(player)
end

-- Rebuilds the player's island at their current tier (after expanding)
function IslandService.Rebuild(player: Player)
	local old = islands[player]
	local data = DataService.GetData(player)
	if not old or not data then
		return
	end
	local island = build(player, data, clampTier(data.Island.Tier), old.Plot)
	BlockWorld.destroy(old.World)
	announce(player, island)

	local character = player.Character
	if character then
		character:PivotTo(island.Spawn.CFrame + Vector3.new(0, 4, 0))
	end
	Remotes.IslandRebuilt:FireClient(player, island.Tier)
end

function IslandService.SendHome(player: Player)
	local island = islands[player]
	local character = player.Character
	if island and character then
		character:PivotTo(island.Spawn.CFrame + Vector3.new(0, 4, 0))
	end
end

local function onPlayerRemoving(player: Player)
	local island = islands[player]
	if island then
		islands[player] = nil
		usedPlots[island.Plot] = nil
		BlockWorld.destroy(island.World)
	end
end

-- The resource node at a cell of the player's island, if there is one
function IslandService.GetNode(player: Player, x: number, y: number, z: number): Node?
	local island = islands[player]
	return if island then island.Nodes[key(x, y, z)] else nil
end

-- Is the block at this cell still the island's own (gives skill XP and double drops)?
-- Call before breaking it.
function IslandService.IsNatural(player: Player, x: number, y: number, z: number, blockType: string): boolean
	local island = islands[player]
	local data = DataService.GetData(player)
	return island ~= nil and data ~= nil and isNatural(island, data, key(x, y, z), blockType)
end

-- What's left in a cell when its block is mined (nil = air): a mined ore node turns into
-- a pale Empty Ore block until it grows back
function IslandService.Remains(player: Player, x: number, y: number, z: number): string?
	local island = islands[player]
	local node = island and island.Nodes[key(x, y, z)]
	return if node and Blocks.Types[node.Block].Ore then "EmptyOre" else nil
end

-- After a block on the island was broken: a node starts growing back, anything else is
-- saved as changed. Chopping a tree's last log fells it; then this returns how many of
-- its leaves fell (for the woodcutter's saplings).
function IslandService.Broken(player: Player, x: number, y: number, z: number): number?
	local island = islands[player]
	local data = DataService.GetData(player)
	if not island or not data then
		return nil
	end
	local cellKey = key(x, y, z)
	local node = island.Nodes[cellKey]
	if node then
		node.RespawnAt = os.clock() + (Blocks.Types[node.Block].NodeRespawn or 30)
		return nil
	end
	IslandService.RecordChange(player, x, y, z, nil)
	local groundKey = island.TreeCells[cellKey]
	local tree = groundKey and island.Trees[groundKey]
	if groundKey and tree and table.find(tree.Logs, cellKey) and not standing(island, data, tree) then
		local fallen = fell(island, data, groundKey, false)
		DataService.MarkChanged(player)
		return fallen
	end
	return nil
end

-- Planted trees ------------------------------------------------------------------

function IslandService.PlantedCount(player: Player): number
	local data = DataService.GetData(player)
	if not data then
		return 0
	end
	local count = 0
	for _ in data.Island.Trees do
		count += 1
	end
	return count
end

-- Plants a sapling on the grass or dirt block at (x, y, z) if there's room above it for
-- a tree. Returns whether it worked, and a reason to show the player if not.
function IslandService.PlantSapling(player: Player, x: number, y: number, z: number): (boolean, string?)
	local island = islands[player]
	local data = DataService.GetData(player)
	if not island or not data then
		return false, nil
	end
	local world = island.World
	local groundKey = key(x, y, z)
	local ground = world.Cells[groundKey]
	if (ground ~= "Grass" and ground ~= "Dirt") or world.Protected[groundKey] or island.Nodes[groundKey] then
		return false, "Saplings grow on grass or dirt"
	end
	if data.Island.Trees[groundKey] or island.Trees[groundKey] then
		return false, "Something's already growing here"
	end
	local height = 4 + rng:NextInteger(0, 1)
	for dy = 1, height + 2 do
		local k = key(x, y + dy, z)
		if world.Cells[k] or world.Protected[k] or island.Nodes[k] then
			return false, "There's no room for a tree to grow here"
		end
	end
	data.Island.Trees[groundKey] = { PlantedAt = os.time(), Height = height }
	protectTrunk(world, x, y, z, height, true)
	makeSapling(island, groundKey)
	DataService.MarkChanged(player)
	return true, nil
end

-- Digs up the growing sapling at the cell above (x, y - 1, z). Returns whether there was one.
function IslandService.Uproot(player: Player, x: number, y: number, z: number): boolean
	local island = islands[player]
	local data = DataService.GetData(player)
	local groundKey = key(x, y - 1, z)
	local sapling = island and island.Saplings[groundKey]
	local tree = data and data.Island.Trees[groundKey]
	if not island or not data or not sapling or not tree then
		return false
	end
	data.Island.Trees[groundKey] = nil
	sapling:Destroy()
	island.Saplings[groundKey] = nil
	protectTrunk(island.World, x, y - 1, z, tree.Height, false)
	DataService.MarkChanged(player)
	return true
end

-- A sapling whose time is up becomes a tree (waiting if someone stands in it)
local function growTree(island: Island, data: DataService.Data, groundKey: string, planted: { Height: number })
	local world = island.World
	local x, y, z = BlockWorld.unkey(groundKey)
	for dy = 1, planted.Height do
		if BlockWorld.occupied(world, x, y + dy, z) then
			return
		end
	end
	local sapling = island.Saplings[groundKey]
	island.Saplings[groundKey] = nil
	if sapling then
		sapling:Destroy()
	end
	protectTrunk(world, x, y, z, planted.Height, false)
	local cells: { [string]: string } = {}
	local tree = addTree(cells, x, y, z, planted.Height, true, function(cellKey)
		return world.Cells[cellKey] ~= nil or world.Protected[cellKey] == true or island.Nodes[cellKey] ~= nil
	end)
	for cellKey, block in cells do
		island.Base[cellKey] = block
		data.Island.Blocks[cellKey] = nil
		local cx, cy, cz = BlockWorld.unkey(cellKey)
		BlockWorld.set(world, cx, cy, cz, block)
	end
	registerTree(island, groundKey, tree)
end

local function growSaplings()
	for player, island in islands do
		local data = DataService.GetData(player)
		if not data then
			continue
		end
		for groundKey in island.Saplings do
			local tree = data.Island.Trees[groundKey]
			if tree and grown(tree) then
				growTree(island, data, groundKey, tree)
			end
		end
	end
end

-- Mined nodes grow back once their time is up
local function respawnNodes()
	local now = os.clock()
	for _, island in islands do
		for _, node in island.Nodes do
			local due = node.RespawnAt
			if due and now >= due then
				-- An empty ore fills back in; an empty spot grows back once nobody stands in it
				local world = island.World
				local cell = BlockWorld.get(world, node.X, node.Y, node.Z)
				if cell == "EmptyOre" or (cell == nil and not BlockWorld.occupied(world, node.X, node.Y, node.Z)) then
					node.RespawnAt = nil
					BlockWorld.set(world, node.X, node.Y, node.Z, node.Block)
				elseif cell ~= nil then
					node.RespawnAt = nil -- something's already there
				end
			end
		end
	end
end

-- Buying the next island size (from the Island window)
local function onExpand(player: Player)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local nextTier = IslandTiers[data.Island.Tier + 1]
	if not nextTier then
		StateService.Notify(player, "Your island is already the biggest it can be!", "bad")
		return
	end
	if not InventoryService.SpendCoins(player, nextTier.Cost) then
		StateService.Notify(player, `You need {nextTier.Cost} coins to expand`, "bad")
		return
	end
	data.Island.Tier += 1
	DataService.MarkChanged(player)
	IslandService.Rebuild(player)
	StateService.Notify(player, `Your island grew into a {nextTier.Name}!`, "level")
end

-- Players who fall off are put back on their island instead of dying in the void
local function catchFallers()
	for player, island in islands do
		local character = player.Character
		if not character then
			continue
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and root.Position.Y < ISLAND.Height - ISLAND.FallLimit then
			root.AssemblyLinearVelocity = Vector3.zero
			character:PivotTo(island.Spawn.CFrame + Vector3.new(0, 4, 0))
		end
	end
end

function IslandService.Start()
	Players.CharacterAutoLoads = false

	islandsFolder = Instance.new("Folder")
	islandsFolder.Name = "Islands"
	islandsFolder.Parent = workspace

	DataService.OnDataLoaded(onDataLoaded)
	Remotes.Expand.OnServerEvent:Connect(onExpand)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	local elapsed, nodeTimer = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		nodeTimer += dt
		if elapsed >= 0.5 then
			elapsed = 0
			catchFallers()
		end
		if nodeTimer >= 1 then
			nodeTimer = 0
			respawnNodes()
			growSaplings()
		end
	end)
end

return IslandService
