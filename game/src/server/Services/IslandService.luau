--!strict
-- Gives each player their own floating island made of blocks, generated for their
-- expansion tier, with their own block changes (data.Island.Blocks) on top. Spawns them
-- on it, rebuilds it bigger when they expand, regrows chopped trees, and puts players
-- back on it if they fall off.
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
local DataService = require(script.Parent.DataService)

local ISLAND = Config.Island
local SIZE = Blocks.Size
local TREE_REGROW_TIME = 90

type Cell = { X: number, Y: number, Z: number }
type Tree = { Trunk: { Cell }, Leaves: { Cell }, GoneSince: number? }

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
	Trees: { Tree },
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

local function addTree(cells: { [string]: string }, x: number, z: number, height: number): Tree
	local tree: Tree = { Trunk = {}, Leaves = {} }
	for y = 1, height do
		cells[key(x, y, z)] = "Wood"
		table.insert(tree.Trunk, { X = x, Y = y, Z = z })
	end
	local function leaf(lx: number, ly: number, lz: number)
		local k = key(lx, ly, lz)
		if not cells[k] then
			cells[k] = "Leaves"
			table.insert(tree.Leaves, { X = lx, Y = ly, Z = lz })
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
	return tree
end

type Generated = {
	Cells: { [string]: string },
	Protected: { [string]: boolean },
	FarmCells: { Cell },
	PortalZ: number,
	Trees: { Tree },
}

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
					cells[key(x, y, z)] = if y >= -2 then "Dirt" else "Stone"
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

	-- Obsidian portal (Nether-portal style: 4 wide, 5 tall, 2x3 opening) at the back
	local portalZ = -(radius - 2)
	for y = 1, 5 do
		for x = -2, 1 do
			local frame = x == -2 or x == 1 or y == 1 or y == 5
			if frame then
				cells[key(x, y, portalZ)] = "Obsidian"
			end
			protected[key(x, y, portalZ)] = true
		end
	end
	-- Keep the ground in front of and under the portal solid
	for x = -2, 1 do
		for z = portalZ - 1, portalZ + 1 do
			protected[key(x, 0, z)] = true
		end
	end

	-- Trees and rocks on free spots that fit this island
	local trees: { Tree } = {}
	for i, spot in TREE_SPOTS do
		if #trees >= spec.Trees then
			break
		end
		local x, z = spot[1], spot[2]
		if math.sqrt(x * x + z * z) <= radius - 1.5 then
			table.insert(trees, addTree(cells, x, z, 4 + (i % 2)))
		end
	end
	local rocks = 0
	for _, spot in ROCK_SPOTS do
		if rocks >= spec.Rocks then
			break
		end
		local x, z = spot[1], spot[2]
		if math.sqrt(x * x + z * z) <= radius - 1.5 then
			rocks += 1
			for _, c in { { 0, 1, 0 }, { 1, 1, 0 }, { 0, 1, 1 }, { 0, 2, 0 } } do
				cells[key(x + c[1], c[2], z + c[3])] = "Stone"
			end
		end
	end

	return {
		Cells = cells,
		Protected = protected,
		FarmCells = farmCells,
		PortalZ = portalZ,
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

-- Glowing purple sheet inside the obsidian frame
local function makePortalSurface(world: BlockWorld.World, portalZ: number): BasePart
	local surface = Instance.new("Part")
	surface.Name = "PortalSurface"
	surface.Size = Vector3.new(2 * SIZE, 3 * SIZE, 0.4)
	surface.CFrame = CFrame.new(BlockWorld.position(world, -0.5, 3, portalZ))
	surface.Material = Enum.Material.Neon
	surface.Color = Color3.fromRGB(140, 70, 255)
	surface.Transparency = 0.3
	surface.Anchored = true
	surface.CanCollide = false
	surface.Parent = world.Model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 100, 255)
	light.Range = 16
	light.Brightness = 2
	light.Parent = surface

	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(200, 150, 255), Color3.fromRGB(110, 60, 255))
	particles.LightEmission = 1
	particles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })
	particles.Lifetime = NumberRange.new(1, 1.8)
	particles.Rate = 20
	particles.Speed = NumberRange.new(0.5, 1.5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = surface
	return surface
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
	-- The player's own changes on top of the generated island
	for cellKey, blockType in data.Island.Blocks do
		if not generated.Protected[cellKey] then
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
		PortalSurface = makePortalSurface(world, generated.PortalZ),
		Trees = generated.Trees,
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

-- Chopped-down trees grow back after a while
local function regrowTrees()
	local now = os.clock()
	for player, island in islands do
		for _, tree in island.Trees do
			local standing = false
			for _, cell in tree.Trunk do
				if BlockWorld.get(island.World, cell.X, cell.Y, cell.Z) == "Wood" then
					standing = true
					break
				end
			end
			if standing then
				tree.GoneSince = nil
			elseif not tree.GoneSince then
				tree.GoneSince = now
			elseif now - tree.GoneSince >= TREE_REGROW_TIME then
				tree.GoneSince = nil
				local function regrow(cells: { Cell }, blockType: string)
					for _, cell in cells do
						if not BlockWorld.get(island.World, cell.X, cell.Y, cell.Z) then
							BlockWorld.set(island.World, cell.X, cell.Y, cell.Z, blockType)
							IslandService.RecordChange(player, cell.X, cell.Y, cell.Z, blockType)
						end
					end
				end
				regrow(tree.Trunk, "Wood")
				regrow(tree.Leaves, "Leaves")
			end
		end
	end
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
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	local elapsed, treeTimer = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		treeTimer += dt
		if elapsed >= 0.5 then
			elapsed = 0
			catchFallers()
		end
		if treeTimer >= 10 then
			treeTimer = 0
			regrowTrees()
		end
	end)
end

return IslandService
