--!strict
-- Farm plots on your island. Plant seeds, wait (time keeps counting while you're
-- offline), harvest for crops, seeds and Farming XP. Better crops need a higher
-- Farming level, and a higher level gives a bigger chance of a bonus crop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local StateService = require(script.Parent.StateService)

-- Plot positions relative to the middle of the island's grass surface, on the open
-- side of the starter island (the tree is at about (7, -6) and rocks at (-9, -7),
-- (-12, -4) and (12, 6))
local PLOT_OFFSETS = {
	Vector3.new(-11, 0, 5),
	Vector3.new(-6, 0, 5),
	Vector3.new(-1, 0, 5),
	Vector3.new(-11, 0, 10),
	Vector3.new(-6, 0, 10),
	Vector3.new(-1, 0, 10),
}
local PLOT_SIZE = Vector3.new(4, 0.4, 4)
local GROWING_COLOR = Color3.fromRGB(96, 170, 70)
local SEED_RETURN_BONUS_CHANCE = 0.3

type Plot = {
	Key: string,
	Soil: BasePart,
	Crop: BasePart,
	Label: TextLabel,
	Prompt: ProximityPrompt,
}

local FarmService = {}

local farms: { [Player]: { Plot } } = {}
local rng = Random.new()

local function formatTime(seconds: number): string
	if seconds >= 60 then
		return string.format("%dm %02ds", seconds // 60, seconds % 60)
	end
	return `{seconds}s`
end

-- The best crop the player can plant right now (level unlocked and has seeds)
local function bestSeed(player: Player): Crops.Crop?
	local level = ProgressionService.GetSkillLevel(player, "Farming")
	for i = #Crops.List, 1, -1 do
		local crop = Crops.List[i]
		if level >= crop.FarmingLevel and InventoryService.Count(player, crop.Seed) > 0 then
			return crop
		end
	end
	return nil
end

-- What's growing in a plot and how far along it is (0 to 1)
local function plotState(data: DataService.Data, key: string): (Crops.Crop?, number)
	local planted = data.Farm.Plots[key]
	local crop = planted and Crops.ById[planted.Crop]
	if not planted or not crop then
		return nil, 0
	end
	return crop, math.clamp((os.time() - planted.PlantedAt) / crop.GrowTime, 0, 1)
end

local function refreshPlot(player: Player, plot: Plot)
	local data = DataService.GetData(player)
	if not data then
		return
	end

	local crop, progress = plotState(data, plot.Key)
	local cropPart = plot.Crop

	if not crop then
		local seed = bestSeed(player)
		cropPart.Transparency = 1
		plot.Prompt.Enabled = true
		plot.Prompt.ActionText = if seed then `Plant {seed.Id}` else "Need seeds"
		plot.Label.Text = ""
		return
	end

	local height
	if progress >= 1 then
		height = 2.2
		cropPart.Color = crop.Color
		plot.Prompt.Enabled = true
		plot.Prompt.ActionText = `Harvest {crop.Id}`
		plot.Label.Text = `{crop.Id} ready!`
	else
		height = 0.4 + 1.6 * progress
		cropPart.Color = GROWING_COLOR
		plot.Prompt.Enabled = false
		plot.Label.Text = `{crop.Id} {formatTime(math.ceil((1 - progress) * crop.GrowTime))}`
	end
	cropPart.Transparency = 0
	cropPart.Size = Vector3.new(2.4, height, 2.4)
	cropPart.CFrame = plot.Soil.CFrame * CFrame.new(0, plot.Soil.Size.Y / 2 + height / 2, 0)
end

local function onPlotTriggered(player: Player, plot: Plot)
	local data = DataService.GetData(player)
	if not data then
		return
	end

	local crop, progress = plotState(data, plot.Key)
	if not crop then
		local seed = bestSeed(player)
		if not seed then
			StateService.Notify(player, "You need seeds. Buy some at the market stand!", "bad")
		elseif InventoryService.Remove(player, seed.Seed, 1) then
			data.Farm.Plots[plot.Key] = { Crop = seed.Id, PlantedAt = os.time() }
			DataService.MarkChanged(player)
		end
	elseif progress >= 1 then
		data.Farm.Plots[plot.Key] = nil

		local farmingLevel = ProgressionService.GetSkillLevel(player, "Farming")
		local amount = if rng:NextNumber() < Leveling.FarmingBonusChance(farmingLevel) then 2 else 1
		local seeds = if rng:NextNumber() < SEED_RETURN_BONUS_CHANCE then 2 else 1

		InventoryService.Add(player, crop.Product, amount)
		InventoryService.Add(player, crop.Seed, seeds)
		ProgressionService.AddSkillXP(player, "Farming", crop.FarmingXP)
		ProgressionService.AddPlayerXP(player, crop.PlayerXP)
		StateService.Notify(player, `+{amount} {Items[crop.Product].Name}`, "good")
	end
	refreshPlot(player, plot)
end

local function makeLabel(adornee: BasePart): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 30)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 40
	billboard.Adornee = adornee
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = ""
	label.Parent = billboard
	return label
end

local function onIslandCreated(player: Player, island: IslandService.Island)
	local plots: { Plot } = {}
	for i, offset in PLOT_OFFSETS do
		local soil = Instance.new("Part")
		soil.Name = `FarmPlot{i}`
		soil.Size = PLOT_SIZE
		soil.CFrame = CFrame.new(island.Center + offset + Vector3.new(0, PLOT_SIZE.Y / 2, 0))
		soil.Color = Color3.fromRGB(92, 60, 38)
		soil.Material = Enum.Material.Ground
		soil.Anchored = true
		soil.Parent = island.Model

		local cropPart = Instance.new("Part")
		cropPart.Name = "Crop"
		cropPart.Anchored = true
		cropPart.CanCollide = false
		cropPart.CanQuery = false
		cropPart.Material = Enum.Material.SmoothPlastic
		cropPart.Transparency = 1
		cropPart.Parent = soil

		local plot: Plot = {
			Key = tostring(i),
			Soil = soil,
			Crop = cropPart,
			Label = makeLabel(soil),
			Prompt = Prompts.Create(soil, { Action = "Plant", Object = "Farm plot", Hold = 0.3 }),
		}
		Prompts.OnTriggeredBy(plot.Prompt, player, function()
			onPlotTriggered(player, plot)
		end)
		refreshPlot(player, plot)
		table.insert(plots, plot)
	end
	farms[player] = plots
end

function FarmService.Start()
	IslandService.OnIslandCreated(onIslandCreated)
	Players.PlayerRemoving:Connect(function(player)
		farms[player] = nil
	end)

	-- Update growth timers and prompts once a second
	task.spawn(function()
		while true do
			task.wait(1)
			for player, plots in farms do
				for _, plot in plots do
					refreshPlot(player, plot)
				end
			end
		end
	end)
end

return FarmService
