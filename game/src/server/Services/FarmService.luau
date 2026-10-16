--!strict
-- Farm plots (farmland blocks) on your island. Plant seeds, wait (time keeps counting while
-- you're offline), harvest for crops, seeds and Farming XP. Better crops need a higher
-- Farming level, and a higher level gives a bigger chance of a bonus crop.
-- Bigger islands have more plots (see IslandTiers).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local Props = require(script.Parent.Parent.Util.Props)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

local SEED_RETURN_BONUS_CHANCE = 0.3
-- Crop models were made for bigger planters; shrink them to fit one block
local CROP_SCALE = 0.68
-- Growth stage thresholds
local SPROUT_UNTIL = 0.35

type Plot = {
	Key: string,
	Model: Model,
	Part: BasePart, -- the farmland block
	Base: CFrame, -- top of the farmland block
	Prompt: ProximityPrompt,
	Label: BillboardGui,
	LabelText: TextLabel,
	LabelBar: Frame,
	Stage: string?, -- which crop model is showing
	Visual: Model?,
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

-- Swaps the crop model shown in the planter when the growth stage changes
local function setVisual(plot: Plot, stage: string?, scale: number)
	if plot.Stage ~= stage then
		if plot.Visual then
			plot.Visual:Destroy()
			plot.Visual = nil
		end
		plot.Stage = stage
		if stage then
			plot.Visual = Props.Place(stage, plot.Base.Position, nil, plot.Model)
		end
	end
	local visual = plot.Visual
	local target = scale * CROP_SCALE
	if visual and math.abs(visual:GetScale() - target) > 0.01 then
		visual:ScaleTo(target)
		visual:PivotTo(plot.Base)
	end
end

local function refreshPlot(player: Player, plot: Plot)
	local data = DataService.GetData(player)
	if not data then
		return
	end

	local crop, progress = plotState(data, plot.Key)
	if not crop then
		local seed = bestSeed(player)
		setVisual(plot, nil, 1)
		plot.Prompt.Enabled = true
		plot.Prompt.ActionText = if seed then `Plant {seed.Id}` else "Need seeds"
		plot.Label.Enabled = false
		return
	end

	plot.Label.Enabled = true
	if progress >= 1 then
		setVisual(plot, `Crop_{crop.Id}`, 1)
		plot.Prompt.Enabled = true
		plot.Prompt.ActionText = `Harvest {crop.Id}`
		plot.LabelText.Text = `{Items[crop.Product].Icon} Ready!`
		plot.LabelBar.Size = UDim2.fromScale(1, 1)
		plot.LabelBar.BackgroundColor3 = Color3.fromRGB(255, 201, 60)
	else
		if progress < SPROUT_UNTIL then
			setVisual(plot, "Crop_Sprout", 1)
		else
			setVisual(plot, "Crop_Young", 0.7 + 0.3 * (progress - SPROUT_UNTIL) / (1 - SPROUT_UNTIL))
		end
		plot.Prompt.Enabled = false
		plot.LabelText.Text = `{Items[crop.Product].Icon} {formatTime(math.ceil((1 - progress) * crop.GrowTime))}`
		plot.LabelBar.Size = UDim2.fromScale(progress, 1)
		plot.LabelBar.BackgroundColor3 = Color3.fromRGB(91, 209, 107)
	end
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
			StateService.Notify(player, "You need seeds. Buy some at the Market!", "bad")
		elseif InventoryService.Remove(player, seed.Seed, 1) then
			data.Farm.Plots[plot.Key] = { Crop = seed.Id, PlantedAt = os.time() }
			DataService.MarkChanged(player)
			QuestService.Record(player, "Plant")
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
		QuestService.Record(player, "Harvest")
	end
	refreshPlot(player, plot)
end

-- Floating pill above each planter: crop icon, time left, progress bar
local function makeLabel(adornee: BasePart): (BillboardGui, TextLabel, Frame)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(110, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 45
	billboard.Enabled = false
	billboard.Adornee = adornee
	billboard.Parent = adornee

	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(28, 33, 48)
	card.BackgroundTransparency = 0.15
	card.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(12, 15, 24)
	stroke.Thickness = 2
	stroke.Parent = card

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -8, 0, 24)
	text.Position = UDim2.fromOffset(4, 2)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	text.TextSize = 18
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Text = ""
	text.Parent = card

	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(0.5, 1)
	track.Position = UDim2.new(0.5, 0, 1, -6)
	track.Size = UDim2.new(1, -16, 0, 7)
	track.BackgroundColor3 = Color3.fromRGB(55, 62, 84)
	track.Parent = card
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(0, 1)
	bar.BackgroundColor3 = Color3.fromRGB(91, 209, 107)
	bar.Parent = track
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	return billboard, text, bar
end

local function onIslandCreated(player: Player, island: IslandService.Island)
	local plots: { Plot } = {}
	for i, cell in island.FarmCells do
		local farmland = BlockWorld.part(island.World, cell.X, cell.Y, cell.Z)
		if not farmland then
			continue
		end
		local label, labelText, labelBar = makeLabel(farmland)
		local plot: Plot = {
			Key = tostring(i),
			Model = island.Model,
			Part = farmland,
			-- Top of the farmland block
			Base = CFrame.new(farmland.Position + Vector3.new(0, Blocks.Size / 2, 0)),
			Prompt = Prompts.Create(farmland, { Action = "Plant", Object = "Farmland", Hold = 0.3 }),
			Label = label,
			LabelText = labelText,
			LabelBar = labelBar,
			Stage = nil,
			Visual = nil,
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

	-- Update growth timers, crop models and prompts once a second
	task.spawn(function()
		while true do
			task.wait(1)
			for player, plots in farms do
				for _, plot in plots do
					if plot.Model.Parent then
						refreshPlot(player, plot)
					end
				end
			end
		end
	end)
end

return FarmService
