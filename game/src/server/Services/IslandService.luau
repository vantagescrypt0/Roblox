--!strict
-- Gives each player their own floating island made of blocks, generated for their
-- expansion tier, with their own block changes (data.Island.Blocks) on top. Spawns them
-- on it, rebuilds it bigger when they expand, and puts players back on it if they fall
-- off. Trees, boulders and their ores are resource nodes: a mined node block grows back
-- in the same spot after a while (Blocks.NodeRespawn), so nothing has to be replanted
-- and mined nodes are never saved as holes. The stone underside has ore veins to dig for
-- (those are ordinary blocks).
-- Players can plant saplings (TreeService): a sapling grows into a tree after
-- SAPLING_GROW_TIME (time counts while offline), and from then on it's a node tree like
-- the island's own. Planted trees are saved in data.Island.Trees by the cell they stand on.
--
-- Grid: y = 0 is the top grass layer; things stand on it at y = 1.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Config = require(ReplicatedStorage.Shared.Config)
local IslandTiers = require(ReplicatedStorage.Shared.IslandTiers)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Portal = require(script.Parent.Parent.Util.Portal)
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

type Cell = { X: number, Y: number, Z: number }
-- A resource node block: what grows there, and when it grows back if it's been mined
export type Node = { X: number, Y: number, Z: number, Block: string, RespawnAt: number? }
type PlantedTrees = { [string]: { PlantedAt: number, Height: number } }

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
	-- Planted trees that have grown: ground cell key -> the node cells that are theirs
	TreeNodes: { [string]: { string } },
	-- Planted saplings still growing: ground cell key -> their model
	Saplings: { [string]: BasePart },
}
type IslandCallback = (player: Player, island: Island) -> ()

local IslandService = {}

local islands: { [Player]: Island } = {}
local usedPlots: { [number]: boolean } = {}
local saplingRng = Random.new()
local createdCallbacks: { IslandCallback } = {}
local islandsFolder: Folder

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
	local rng = Random.new(4242)
	for i = 0, 15 do
		edgeNoise[i] = rng:NextNumber(-0.9, 0.9)
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

-- Adds an oak tree of nodes standing on the cell (x, baseY, z). Cells that are already
-- taken (or that `blocked` says are) are skipped. Returns the keys of the cells it added.
local function addTree(
	cells: { [string]: string },
	nodes: { [string]: Node },
	x: number,
	baseY: number,
	z: number,
	height: number,
	blocked: ((cellKey: string) -> boolean)?
): { string }
	local added = {}
	local function put(px: number, py: number, pz: number, block: string)
		local k = key(px, py, pz)
		if not cells[k] and not (blocked and blocked(k)) then
			addNode(cells, nodes, px, py, pz, block)
			table.insert(added, k)
		end
	end
	for y = 1, height do
		put(x, baseY + y, z, "Wood")
	end
	-- Oak shape: two wide layers, then a small cap
	for ly = height - 1, height do
		for dx = -2, 2 do
			for dz = -2, 2 do
				local corner = math.abs(dx) == 2 and math.abs(dz) == 2
				if not corner and not (dx == 0 and dz == 0) then
					put(x + dx, baseY + ly, z + dz, "Leaves")
				end
			end
		end
	end
	for dx = -1, 1 do
		for dz = -1, 1 do
			if math.abs(dx) + math.abs(dz) < 2 or ((dx + dz + height) % 2 == 0) then
				put(x + dx, baseY + height + 1, z + dz, "Leaves")
			end
		end
	end
	put(x, baseY + height + 2, z, "Leaves")
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		put(x + d[1], baseY + height + 2, z + d[2], "Leaves")
	end
	return added
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
	TreeNodes: { [string]: { string } },
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

-- `planted` are the player's planted trees (the grown ones become node trees) and
-- `changes` their saved block changes (planted trees grow around their blocks)
local function generate(tier: number, planted: PlantedTrees, changes: { [string]: string }): Generated
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

	-- Tree and boulder nodes on free spots that fit this island
	local nodes: { [string]: Node } = {}
	local trees = 0
	for i, spot in TREE_SPOTS do
		if trees >= spec.Trees then
			break
		end
		local x, z = spot[1], spot[2]
		if math.sqrt(x * x + z * z) <= radius - 1.5 then
			trees += 1
			addTree(cells, nodes, x, 0, z, 4 + (i % 2))
		end
	end
	-- Boulders: stone with a lump of coal on top and some iron showing (a reason to
	-- upgrade to a Stone Pickaxe)
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
	local treeNodes: { [string]: { string } } = {}
	local function blocked(cellKey: string): boolean
		local change = changes[cellKey]
		return protected[cellKey] == true or (change ~= nil and change ~= "Air")
	end
	for groundKey, tree in planted do
		if grown(tree) then
			local x, y, z = BlockWorld.unkey(groundKey)
			treeNodes[groundKey] = addTree(cells, nodes, x, y, z, tree.Height, blocked)
		end
	end

	return {
		Cells = cells,
		Protected = protected,
		FarmCells = farmCells,
		PortalZ = portalZ,
		Nodes = nodes,
		TreeNodes = treeNodes,
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

local function build(player: Player, data: DataService.Data, tier: number, plot: number): Island
	local center = plotCenter(plot)
	local generated = generate(tier, data.Island.Trees, data.Island.Blocks)
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
	BlockWorld.drawAll(world)

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
		TreeNodes = generated.TreeNodes,
		Saplings = {},
	}
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

-- Remembers a block change in the player's save (only differences from the generated island)
function IslandService.RecordChange(player: Player, x: number, y: number, z: number, blockType: string?)
	local island = islands[player]
	local data = DataService.GetData(player)
	if not island or not data then
		return
	end
	local cellKey = key(x, y, z)
	if island.Base[cellKey] == blockType then
		data.Island.Blocks[cellKey] = nil
	else
		data.Island.Blocks[cellKey] = blockType or "Air"
	end
end

local function spawnCharacter(player: Player)
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

-- Marks a node as mined: it grows back after its block's NodeRespawn time
function IslandService.DepleteNode(player: Player, x: number, y: number, z: number)
	local node = IslandService.GetNode(player, x, y, z)
	if node then
		local respawn = Blocks.Types[node.Block].NodeRespawn or 30
		node.RespawnAt = os.clock() + respawn
	end
end

-- Is someone standing in this cell? (nodes wait until they move)
local function cellOccupied(world: BlockWorld.World, x: number, y: number, z: number): boolean
	local size = Vector3.one * (SIZE - 0.3)
	for _, part in workspace:GetPartBoundsInBox(CFrame.new(BlockWorld.position(world, x, y, z)), size) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChildOfClass("Humanoid") then
			return true
		end
	end
	return false
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
	local height = 4 + saplingRng:NextInteger(0, 1)
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

-- Digs up a tree the player planted (still a sapling, or grown) that the cell at
-- (x, y, z) belongs to. Returns whether there was one.
function IslandService.Uproot(player: Player, x: number, y: number, z: number): boolean
	local island = islands[player]
	local data = DataService.GetData(player)
	if not island or not data then
		return false
	end
	local groundKey: string? = nil
	if island.Saplings[key(x, y - 1, z)] then
		groundKey = key(x, y - 1, z)
	else
		local cellKey = key(x, y, z)
		for treeKey, cells in island.TreeNodes do
			if table.find(cells, cellKey) then
				groundKey = treeKey
				break
			end
		end
	end
	local tree = groundKey and data.Island.Trees[groundKey]
	if not groundKey or not tree then
		return false
	end
	data.Island.Trees[groundKey] = nil
	local sapling = island.Saplings[groundKey]
	if sapling then
		sapling:Destroy()
		island.Saplings[groundKey] = nil
		local gx, gy, gz = BlockWorld.unkey(groundKey)
		protectTrunk(island.World, gx, gy, gz, tree.Height, false)
	end
	local cells: { string } = island.TreeNodes[groundKey] or {}
	for _, cellKey in cells do
		island.Nodes[cellKey] = nil
		island.Base[cellKey] = nil
		data.Island.Blocks[cellKey] = nil
		local cx, cy, cz = BlockWorld.unkey(cellKey)
		BlockWorld.set(island.World, cx, cy, cz, nil)
	end
	island.TreeNodes[groundKey] = nil
	DataService.MarkChanged(player)
	return true
end

-- A sapling whose time is up becomes a tree of nodes (waiting if someone stands in it)
local function growTree(island: Island, data: DataService.Data, groundKey: string, tree: { Height: number })
	local world = island.World
	local x, y, z = BlockWorld.unkey(groundKey)
	for dy = 1, tree.Height do
		if cellOccupied(world, x, y + dy, z) then
			return
		end
	end
	local sapling = island.Saplings[groundKey]
	island.Saplings[groundKey] = nil
	if sapling then
		sapling:Destroy()
	end
	protectTrunk(world, x, y, z, tree.Height, false)
	local cells: { [string]: string } = {}
	local nodes: { [string]: Node } = {}
	local added = addTree(cells, nodes, x, y, z, tree.Height, function(cellKey)
		return world.Cells[cellKey] ~= nil or world.Protected[cellKey] == true or island.Nodes[cellKey] ~= nil
	end)
	for _, cellKey in added do
		local node = nodes[cellKey]
		island.Nodes[cellKey] = node
		island.Base[cellKey] = node.Block
		data.Island.Blocks[cellKey] = nil
		BlockWorld.set(world, node.X, node.Y, node.Z, node.Block)
	end
	island.TreeNodes[groundKey] = added
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
				local world = island.World
				if BlockWorld.get(world, node.X, node.Y, node.Z) then
					node.RespawnAt = nil -- something's already there
				elseif not cellOccupied(world, node.X, node.Y, node.Z) then
					node.RespawnAt = nil
					BlockWorld.set(world, node.X, node.Y, node.Z, node.Block)
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
