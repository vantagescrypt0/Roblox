--!strict
-- Gives each player their own floating island plot, spawns them on it, and puts them
-- back on it if they fall off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local ISLAND = Config.Island

export type Island = {
	Model: Model,
	Plot: number,
	Spawn: SpawnLocation,
	-- World position of the middle of the grass surface
	Center: Vector3,
}
type IslandCallback = (player: Player, island: Island) -> ()

local IslandService = {}

local islands: { [Player]: Island } = {}
local usedPlots: { [number]: boolean } = {}
local createdCallbacks: { IslandCallback } = {}
local islandsFolder: Folder

-- Runs the callback for every island, now and when new ones are created.
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

-- Stand-in island used until the Blender model is imported into ServerStorage.Assets
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

	local dirt = makePart(
		"DirtBody",
		Vector3.new(10, diameter * 0.8, diameter * 0.8),
		CFrame.new(0, -7, 0) * upright,
		Color3.fromRGB(138, 90, 52),
		Enum.Material.Ground
	)
	dirt.Shape = Enum.PartType.Cylinder
	dirt.Parent = model

	model.PrimaryPart = grass
	return model
end

local function newIslandModel(): Model
	local assets = ServerStorage:FindFirstChild("Assets")
	local template = assets and assets:FindFirstChild(ISLAND.TemplateName)
	if template and template:IsA("Model") then
		local model = template:Clone()
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end
		return model
	end
	return buildGreybox()
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

local function makeSpawn(center: Vector3, parent: Instance): SpawnLocation
	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "Spawn"
	spawnPoint.Size = Vector3.new(4, 1, 4)
	spawnPoint.CFrame = CFrame.new(center - Vector3.new(0, 0.5, 0))
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Transparency = 1
	spawnPoint.Duration = 0
	spawnPoint.Neutral = true
	spawnPoint.Parent = parent
	return spawnPoint
end

local function spawnCharacter(player: Player)
	if player.Parent == Players then
		player:LoadCharacterAsync()
	end
end

local function onDataLoaded(player: Player, _data: DataService.Data)
	if islands[player] then
		return
	end

	local plot = claimPlot()
	local center = plotCenter(plot)

	local model = newIslandModel()
	model.Name = `Island_{player.UserId}`
	model:SetAttribute("OwnerUserId", player.UserId)
	placeIsland(model, center)
	local spawnPoint = makeSpawn(center, model)
	model.Parent = islandsFolder

	local island: Island = { Model = model, Plot = plot, Spawn = spawnPoint, Center = center }
	islands[player] = island
	player.RespawnLocation = spawnPoint
	for _, callback in createdCallbacks do
		task.spawn(callback, player, island)
	end

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
