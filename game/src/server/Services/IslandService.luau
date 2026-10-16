--!strict
-- Gives each player their own floating island plot, built at their expansion tier
-- (ServerStorage.Assets.Islands.TierN), spawns them on it, rebuilds it bigger when they
-- expand, and puts them back on it if they fall off.
--
-- Island models carry invisible Marker_* parts (made in Blender) that say where the
-- spawn, workbench, market, portal and farm plots go.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local IslandTiers = require(ReplicatedStorage.Shared.IslandTiers)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local ISLAND = Config.Island

export type Island = {
	Model: Model,
	Plot: number,
	Spawn: SpawnLocation,
	-- World position of the middle of the grass surface
	Center: Vector3,
	Tier: number,
	-- Named layout points: Spawn, Workbench, Market, Portal
	Markers: { [string]: Vector3 },
	-- Farm plot positions, in order
	PlotSpots: { Vector3 },
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

-- Highest world-space Y of a part, correct for rotated parts (e.g. cylinders)
local function topOf(part: BasePart): number
	local cf, half = part.CFrame, part.Size / 2
	local halfY = math.abs(cf.RightVector.Y) * half.X
		+ math.abs(cf.UpVector.Y) * half.Y
		+ math.abs(cf.LookVector.Y) * half.Z
	return cf.Position.Y + halfY
end

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- Stand-in island used only if the Blender islands are missing
local function buildGreybox(): Model
	local model = Instance.new("Model")
	local diameter = ISLAND.Radius * 2
	local upright = CFrame.Angles(0, 0, math.rad(90))
	local grass = makePart(
		"GrassTop",
		Vector3.new(2, diameter, diameter),
		CFrame.new(0, -1, 0) * upright,
		Color3.fromRGB(109, 190, 69),
		Enum.Material.Grass
	)
	grass.Shape = Enum.PartType.Cylinder
	grass.Parent = model
	model.PrimaryPart = grass
	return model
end

local function islandTemplate(tier: number): Model?
	local assets = ServerStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Islands")
	local template = folder and folder:FindFirstChild(`Tier{tier}`)
	return if template and template:IsA("Model") then template else nil
end

-- Moves the model so its grass surface is centered on `center`
local function placeIsland(model: Model, center: Vector3)
	local grass = model:FindFirstChild("GrassTop", true)
	local pivot = model:GetPivot()
	if grass and grass:IsA("BasePart") then
		local surface = Vector3.new(grass.Position.X, topOf(grass), grass.Position.Z)
		model:PivotTo(CFrame.new(center + (pivot.Position - surface)) * pivot.Rotation)
	else
		model:PivotTo(CFrame.new(center))
	end
end

-- Reads (and removes) the Marker_* parts
local function readMarkers(model: Model): ({ [string]: Vector3 }, { Vector3 })
	local markers: { [string]: Vector3 } = {}
	local plots: { [number]: Vector3 } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local name = string.match(part.Name, "^Marker_(.+)$")
			if name then
				local index = string.match(name, "^Plot_(%d+)$")
				if index then
					plots[tonumber(index) :: number] = part.Position
				else
					markers[name] = part.Position
				end
				part:Destroy()
			end
		end
	end
	local ordered = {}
	for i = 1, #plots do
		table.insert(ordered, plots[i])
	end
	return markers, ordered
end

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

local function build(player: Player, tier: number, plot: number): Island
	local center = plotCenter(plot)
	local template = islandTemplate(tier)
	local model = if template then template:Clone() else buildGreybox()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	model.Name = `Island_{player.UserId}`
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("Tier", tier)
	placeIsland(model, center)

	local markers, plotSpots = readMarkers(model)
	if not template then
		-- Greybox fallback layout
		markers = {
			Spawn = center,
			Workbench = center + Vector3.new(9, 0, 2),
			Market = center + Vector3.new(6, 0, 10),
			Portal = center + Vector3.new(-1, 0, -14),
		}
		for i = 1, 6 do
			table.insert(plotSpots, center + Vector3.new(-11 + ((i - 1) % 3) * 5, 0, if i <= 3 then 5 else 10))
		end
	end

	local spawnPoint = makeSpawn(markers.Spawn or center, model)
	model.Parent = islandsFolder
	return {
		Model = model,
		Plot = plot,
		Spawn = spawnPoint,
		Center = center,
		Tier = tier,
		Markers = markers,
		PlotSpots = plotSpots,
	}
end

local function announce(player: Player, island: Island)
	islands[player] = island
	player.RespawnLocation = island.Spawn
	for _, callback in createdCallbacks do
		task.spawn(callback, player, island)
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
	announce(player, build(player, clampTier(data.Island.Tier), claimPlot()))

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
	local island = build(player, clampTier(data.Island.Tier), old.Plot)
	old.Model:Destroy()
	announce(player, island)

	local character = player.Character
	if character then
		character:PivotTo(island.Spawn.CFrame + Vector3.new(0, 4, 0))
	end
	Remotes.IslandRebuilt:FireClient(player, island.Tier)
end

local function onPlayerRemoving(player: Player)
	local island = islands[player]
	if island then
		islands[player] = nil
		usedPlots[island.Plot] = nil
		island.Model:Destroy()
	end
end

-- Players who fall off their island are put back on it instead of dying in the void
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

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.5 then
			elapsed = 0
			catchFallers()
		end
	end)
end

return IslandService
