--!strict
-- Farm plots (farmland blocks) on your island. Crops are perennial nodes: click farmland
-- to plant the seeds you're holding (or your best seeds) once, and from then on the crop
-- regrows by itself after every harvest (time keeps counting while you're offline). Click
-- a ripe crop to harvest it for crops and Farming XP, with a small chance of a spare seed.
-- Hold a shovel and click a crop to dig it up (you get the seed back) to plant something
-- else. Better crops need a higher Farming level, and a higher level gives a bigger chance
-- of a bonus crop. Bigger islands have more plots (see IslandTiers).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Props = require(script.Parent.Parent.Util.Props)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local DataService = require(script.Parent.DataService)
local HotbarService = require(script.Parent.HotbarService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

-- Crops regrow, so seeds are only needed to start a plot; a harvest sometimes gives a
-- spare one (to fill another plot)
local SPARE_SEED_CHANCE = 0.1
-- Crop models were made for bigger planters; shrink them to fit one block
local CROP_SCALE = 0.68
-- Growth stage thresholds
local SPROUT_UNTIL = 0.35

type Plot = {
	Key: string,
	Cell: Vector3, -- grid position of the farmland block
	Model: Model,
	Part: BasePart, -- the farmland block
	Base: CFrame, -- top of the farmland block
	Stage: string?, -- which crop model is showing
	Visual: Model?,
}

local FarmService = {}

local farms: { [Player]: { Plot } } = {}
local rng = Random.new()

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
			local visual = Props.Place(stage, plot.Base.Position, nil, plot.Model)
			-- Clicks go through the crop to the farmland underneath
			if visual then
				for _, part in visual:GetDescendants() do
					if part:IsA("BasePart") then
						part.CanQuery = false
					end
				end
			end
			plot.Visual = visual
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

	-- The crop model shows how far along it is: sprout, young plant, ripe crop
	local crop, progress = plotState(data, plot.Key)
	if not crop then
		setVisual(plot, nil, 1)
		plot.Part:SetAttribute("FarmState", "Empty")
	elseif progress >= 1 then
		setVisual(plot, `Crop_{crop.Id}`, 1)
		plot.Part:SetAttribute("FarmState", "Ready")
	else
		if progress < SPROUT_UNTIL then
			setVisual(plot, "Crop_Sprout", 1)
		else
			setVisual(plot, "Crop_Young", 0.7 + 0.3 * (progress - SPROUT_UNTIL) / (1 - SPROUT_UNTIL))
		end
		plot.Part:SetAttribute("FarmState", "Growing")
	end
end

local function holdingShovel(player: Player): boolean
	local held = HotbarService.GetHeldItem(player)
	local tool = held and Tools.ByItem[held]
	return tool ~= nil and tool.Kind == "Shovel"
end

-- The crop whose seeds the player is holding, if they can plant it
local function heldSeed(player: Player): Crops.Crop?
	local held = HotbarService.GetHeldItem(player)
	local level = ProgressionService.GetSkillLevel(player, "Farming")
	for _, crop in Crops.List do
		if crop.Seed == held and level >= crop.FarmingLevel then
			return crop
		end
	end
	return nil
end

local function onPlotClicked(player: Player, plot: Plot)
	local data = DataService.GetData(player)
	if not data then
		return
	end

	local crop, progress = plotState(data, plot.Key)
	if crop and holdingShovel(player) then
		-- Dig the plant up to plant something else; the seed comes back
		data.Farm.Plots[plot.Key] = nil
		DataService.MarkChanged(player)
		InventoryService.Add(player, crop.Seed, 1)
		StateService.Notify(player, `Dug up the {crop.Id}`, "info")
	elseif not crop then
		-- Plant the seeds in your hand, otherwise your best seeds
		local seed = heldSeed(player) or bestSeed(player)
		if not seed then
			StateService.Notify(player, "You need seeds. Buy some at the Market!", "bad")
		elseif InventoryService.Remove(player, seed.Seed, 1) then
			data.Farm.Plots[plot.Key] = { Crop = seed.Id, PlantedAt = os.time() }
			DataService.MarkChanged(player)
			QuestService.Record(player, "Plant")
		end
	elseif progress >= 1 then
		-- The plant stays and starts growing again
		data.Farm.Plots[plot.Key] = { Crop = crop.Id, PlantedAt = os.time() }

		local farmingLevel = ProgressionService.GetSkillLevel(player, "Farming")
		local amount = if rng:NextNumber() < Leveling.BonusChance(farmingLevel) then 2 else 1

		InventoryService.Add(player, crop.Product, amount)
		if rng:NextNumber() < SPARE_SEED_CHANCE then
			InventoryService.Add(player, crop.Seed, 1)
		end
		ProgressionService.AddSkillXP(player, "Farming", crop.FarmingXP)
		ProgressionService.AddPlayerXP(player, crop.PlayerXP)
		StateService.Notify(player, `+{amount} {Items[crop.Product].Name}`, "good")
		QuestService.Record(player, "Harvest")
	end
	refreshPlot(player, plot)
end

local function onIslandCreated(player: Player, island: IslandService.Island)
	local plots: { Plot } = {}
	for i, cell in island.FarmCells do
		local farmland = BlockWorld.part(island.World, cell.X, cell.Y, cell.Z)
		if not farmland then
			continue
		end
		local plot: Plot = {
			Key = tostring(i),
			Cell = Vector3.new(cell.X, cell.Y, cell.Z),
			Model = island.Model,
			Part = farmland,
			-- Top of the farmland block
			Base = CFrame.new(farmland.Position + Vector3.new(0, Blocks.Size / 2, 0)),
			Stage = nil,
			Visual = nil,
		}

		refreshPlot(player, plot)
		table.insert(plots, plot)
	end
	farms[player] = plots
end

-- Clicking farmland (no key press): plant if empty, harvest if ripe, dig up with a shovel
local lastClick: { [Player]: number } = {}
local function onFarmClick(player: Player, x: unknown, y: unknown, z: unknown)
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return
	end
	local now = os.clock()
	if now - (lastClick[player] or 0) < 0.15 then
		return
	end
	lastClick[player] = now
	local cell = Vector3.new(x, y, z)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local plots: { Plot } = farms[player] or {}
	for _, plot in plots do
		if plot.Cell == cell then
			if root and root:IsA("BasePart") and (root.Position - plot.Part.Position).Magnitude <= Blocks.Reach + 3 then
				onPlotClicked(player, plot)
			end
			return
		end
	end
end

function FarmService.Start()
	IslandService.OnIslandCreated(onIslandCreated)
	Remotes.FarmClick.OnServerEvent:Connect(onFarmClick)
	Players.PlayerRemoving:Connect(function(player)
		farms[player] = nil
		lastClick[player] = nil
	end)

	-- Update growth timers and crop models once a second
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
