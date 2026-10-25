--!strict
-- Gives each player their own floating island made of blocks, generated for their
-- expansion tier, with their own block changes (data.Island.Blocks) on top. Spawns them
-- on it, rebuilds it bigger when they expand, and puts players back on it if they fall
-- off. Trees, boulders and their ores are resource nodes: a mined node block grows back
-- in the same spot after a while (Blocks.NodeRespawn), so nothing has to be replanted
-- and mined nodes are never saved as holes. The stone underside has ore veins to dig for
-- (those are ordinary blocks).
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

type Cell = { X: number, Y: number, Z: number }
-- A resource node block: what grows there, and when it grows back if it's been mined
export type Node = { X: number, Y: number, Z: number, Block: string, RespawnAt: number? }

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
}
type IslandCallback = (player: Player, island: Island) -> ()

local IslandService = {}

local islands: { [Player]: Island } = {}
local usedPlots: { [number]: boolean } = {}
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

local function addTree(cells: { [string]: string }, nodes: { [string]: Node }, x: number, z: number, height: number)
	for y = 1, height do
		addNode(cells, nodes, x, y, z, "Wood")
	end
	local function leaf(lx: number, ly: number, lz: number)
		if not cells[key(lx, ly, lz)] then
			addNode(cells, nodes, lx, ly, lz, "Leaves")
		end
	end
	-- Oak shape: two wide layers, then a small cap
	for ly = height - 1, height do
		for dx = -2, 2 do
			for dz = -2, 2 do
				local corner = math.abs(dx) == 2 and math.abs(dz) == 2
				if not corner and not (dx == 0 and dz == 0) then
					leaf(x + dx, ly, z + dz)
				end
			end
		end
	end
	for dx = -1, 1 do
		for dz = -1, 1 do
			if math.abs(dx) + math.abs(dz) < 2 or ((dx + dz + height) % 2 == 0) then
				leaf(x + dx, height + 1, z + dz)
			end
		end
	end
	leaf(x, height + 2, z)
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		leaf(x + d[1], height + 2, z + d[2])
	end
end

type Generated = {
	Cells: { [string]: string },
	Protected: { [string]: boolean },
	FarmCells: { Cell },
	PortalZ: number,
	Nodes: { [string]: Node },
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

local function generate(tier: number): Generated
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
			addTree(cells, nodes, x, z, 4 + (i % 2))
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

	return {
		Cells = cells,
		Protected = protected,
		FarmCells = farmCells,
		PortalZ = portalZ,
		Nodes = nodes,
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

local function build(player: Player, data: DataService.Data, tier: number, plot: number): Island
	local center = plotCenter(plot)
	local generated = generate(tier)
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
	return {
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
	}
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
		end
	end)
end

return IslandService
