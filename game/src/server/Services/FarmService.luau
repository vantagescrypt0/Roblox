--!strict
-- Farm plots (farmland blocks) on your island. Crops are perennial nodes: click farmland
-- to plant the seeds you're holding (or your best seeds) once, and from then on the crop
-- regrows by itself after every harvest (time keeps counting while you're offline). Hold
-- a hoe (an axe for pumpkins and melons) and click a ripe crop to harvest it for crops and
-- Farming XP, with a small chance of a spare seed.
-- Hold a shovel and click a crop to dig it up (you get the seed back) to plant something
-- else. Better crops need a higher Farming level, and a higher level gives a bigger chance
-- of a bonus crop.
-- There's no ready-made farm: right-click grass or dirt with a hoe to till it into
-- farmland, as much as you like (saved as a block change; the island's build border is the
-- only limit). A shovel turns an empty plot back into dirt. A better hoe adds its tier's
-- bonus to every harvest.
-- The Farming World's wild fields use the same crop models and harvest (ShowCrop, Harvest).

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
local ChallengeService = require(script.Parent.ChallengeService)
local DataService = require(script.Parent.DataService)
local GearService = require(script.Parent.GearService)
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
local TILLABLE: { [string]: boolean } = { Grass = true, Dirt = true }

-- Somewhere a crop model shows: on top of a farmland block
export type CropSpot = {
	Model: Model, -- where the crop model goes
	Base: CFrame, -- top of the farmland block
	Stage: string?, -- which crop model is showing
	Visual: Model?,
}

-- A farm plot on an island (a CropSpot, plus where it is and whose it is)
type Plot = {
	Key: string, -- the farmland's cell key
	Cell: Vector3, -- grid position of the farmland block
	Model: Model,
	Part: BasePart, -- the farmland block
	Base: CFrame,
	Stage: string?,
	Visual: Model?,
}

local FarmService = {}

local farms: { [Player]: { Plot } } = {}
local lastToolNotice: { [Player]: number } = {}
local rng = Random.new()

-- The tool of this kind in the player's hand, if any
local function heldTool(player: Player, kind: Tools.Kind): Tools.Tool?
	local held = HotbarService.GetHeldItem(player)
	local tool = held and Tools.ByItem[held]
	return if tool and tool.Kind == kind then tool else nil
end

local function useTool(player: Player, tool: Tools.Tool)
	if InventoryService.UseTool(player, tool.Item, 1) then
		StateService.Notify(player, `Your {Items[tool.Item].Name} broke!`, "bad")
	end
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
-- Ripe pumpkins and melons are their block, with a leaf beside them (no prop model)
local BLOCK_CROPS: { [string]: string } = { Crop_Pumpkin = "Pumpkin", Crop_Melon = "Melon" }

local function blockCrop(blockType: string, base: Vector3, parent: Instance): Model?
	local folder = ReplicatedStorage:FindFirstChild("Blocks")
	local template = folder and folder:FindFirstChild(blockType)
	if not template or not template:IsA("BasePart") then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = `Crop_{blockType}`
	local size = 3.2 -- scaled down with the other crops (CROP_SCALE)
	local fruit = template:Clone()
	fruit.Size = Vector3.one * size
	fruit.CFrame = CFrame.new(base + Vector3.new(0, size / 2, 0)) * template.CFrame.Rotation
	fruit.Anchored = true
	fruit.CanCollide = false
	fruit.Parent = model
	local leaf = Instance.new("Part")
	leaf.Name = "Leaf"
	leaf.Size = Vector3.new(1.6, 0.15, 1.1)
	leaf.CFrame = CFrame.new(base + Vector3.new(1.5, 0.15, 0.6)) * CFrame.Angles(0, 0.5, 0.2)
	leaf.Color = Color3.fromRGB(70, 140, 60)
	leaf.Material = Enum.Material.LeafyGrass
	leaf.Anchored = true
	leaf.CanCollide = false
	leaf.Parent = model
	model.WorldPivot = CFrame.new(base)
	model.Parent = parent
	return model
end

local function setVisual(plot: CropSpot, stage: string?, scale: number)
	if plot.Stage ~= stage then
		if plot.Visual then
			plot.Visual:Destroy()
			plot.Visual = nil
		end
		plot.Stage = stage
		if stage then
			local visual = Props.Place(stage, plot.Base.Position, nil, plot.Model)
			if not visual and BLOCK_CROPS[stage] then
				visual = blockCrop(BLOCK_CROPS[stage], plot.Base.Position, plot.Model)
			end
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

-- Shows a crop and how far along it is (0 to 1): sprout, young plant, ripe crop; nothing
-- if there's no crop. Returns "Empty", "Growing" or "Ready".
function FarmService.ShowCrop(spot: CropSpot, crop: Crops.Crop?, progress: number): string
	if not crop then
		setVisual(spot, nil, 1)
		return "Empty"
	elseif progress >= 1 then
		setVisual(spot, `Crop_{crop.Id}`, 1)
		return "Ready"
	elseif progress < SPROUT_UNTIL then
		setVisual(spot, "Crop_Sprout", 1)
	else
		setVisual(spot, "Crop_Young", 0.7 + 0.3 * (progress - SPROUT_UNTIL) / (1 - SPROUT_UNTIL))
	end
	return "Growing"
end

local function refreshPlot(player: Player, plot: Plot)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local crop, progress = plotState(data, plot.Key)
	plot.Part:SetAttribute("FarmState", FarmService.ShowCrop(plot, crop, progress))
end

-- The tool in the player's hand that harvests this crop (a hoe, or an axe for pumpkins and
-- melons). Without one, tells them what to hold (not more than once a second or so).
function FarmService.HarvestTool(player: Player, crop: Crops.Crop): Tools.Tool?
	local tool = heldTool(player, crop.Tool :: Tools.Kind)
	local now = os.clock()
	if not tool and now - (lastToolNotice[player] or 0) > 1.5 then
		lastToolNotice[player] = now
		local kind = string.lower(crop.Tool)
		local article = if string.find(kind, "^[aeiou]") then "an" else "a"
		StateService.Notify(player, `Hold {article} {kind} to harvest {crop.Id}`, "bad")
	end
	return tool
end

-- What harvesting a ripe crop with `tool` gives: the crop (sometimes two, more often with a
-- higher Farming level or a better hoe), now and then a spare seed, and Farming and player
-- XP. Harvesting doesn't wear the tool (a busy farmer harvests thousands an hour; tilling
-- does wear a hoe).
function FarmService.Harvest(player: Player, crop: Crops.Crop, tool: Tools.Tool)
	local farmingLevel = ProgressionService.GetSkillLevel(player, "Farming")
	local chance = Leveling.BonusChance(farmingLevel) + tool.Harvest + GearService.DropBonus(player, "Farming")
	local amount = if rng:NextNumber() < chance then 2 else 1

	InventoryService.Add(player, crop.Product, amount)
	if rng:NextNumber() < SPARE_SEED_CHANCE then
		InventoryService.Add(player, crop.Seed, 1)
	end
	ProgressionService.AddSkillXP(player, "Farming", crop.FarmingXP)
	ProgressionService.AddPlayerXP(player, crop.PlayerXP)
	StateService.Notify(player, `+{amount} {Items[crop.Product].Name}`, "good")
	QuestService.Record(player, "Harvest")
	QuestService.Record(player, `Harvest:{crop.Id}`)
	ChallengeService.Count(player, crop.Id)
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

local function makePlot(island: IslandService.Island, key: string, x: number, y: number, z: number): Plot?
	local farmland = BlockWorld.part(island.World, x, y, z)
	if not farmland then
		return nil
	end
	return {
		Key = key,
		Cell = Vector3.new(x, y, z),
		Model = island.Model,
		Part = farmland,
		-- Top of the farmland block
		Base = CFrame.new(farmland.Position + Vector3.new(0, Blocks.Size / 2, 0)),
		Stage = nil,
		Visual = nil,
	}
end

-- Turns an empty plot back into dirt
local function untill(player: Player, plot: Plot)
	local island = IslandService.GetIsland(player)
	local data = DataService.GetData(player)
	if not island or not data then
		return
	end
	local x, y, z = plot.Cell.X, plot.Cell.Y, plot.Cell.Z
	setVisual(plot, nil, 1)
	data.Farm.Plots[plot.Key] = nil
	BlockWorld.set(island.World, x, y, z, "Dirt")
	IslandService.RecordChange(player, x, y, z, "Dirt")
	island.World.Protected[BlockWorld.key(x, y + 1, z)] = nil
	local plots = farms[player]
	local index = plots and table.find(plots, plot)
	if plots and index then
		table.remove(plots, index)
	end
	DataService.MarkChanged(player)
	StateService.Notify(player, "Turned the farmland back into dirt", "info")
end

local function onPlotClicked(player: Player, plot: Plot)
	local data = DataService.GetData(player)
	if not data then
		return
	end

	local crop, progress = plotState(data, plot.Key)
	local shovel = heldTool(player, "Shovel")
	if crop and shovel then
		-- Dig the plant up to plant something else; the seed comes back
		data.Farm.Plots[plot.Key] = nil
		DataService.MarkChanged(player)
		InventoryService.Add(player, crop.Seed, 1)
		StateService.Notify(player, `Dug up the {crop.Id}`, "info")
	elseif not crop and shovel then
		untill(player, plot)
		return
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
		local tool = FarmService.HarvestTool(player, crop)
		if not tool then
			return
		end
		-- The plant stays and starts growing again
		data.Farm.Plots[plot.Key] = { Crop = crop.Id, PlantedAt = os.time() }
		FarmService.Harvest(player, crop, tool)
	end
	refreshPlot(player, plot)
end

local function onIslandCreated(player: Player, island: IslandService.Island)
	local plots: { Plot } = {}
	-- Farmland the player tilled (saved as a block change); nothing can be built on top
	for cellKey, blockType in island.World.Cells do
		if blockType == "Farmland" then
			local x, y, z = BlockWorld.unkey(cellKey)
			island.World.Protected[BlockWorld.key(x, y + 1, z)] = true
			local plot = makePlot(island, cellKey, x, y, z)
			if plot then
				refreshPlot(player, plot)
				table.insert(plots, plot)
			end
		end
	end
	farms[player] = plots
end

-- Right-clicking grass or dirt with a hoe: it becomes a new farm plot
local lastTill: { [Player]: number } = {}
local function onTill(player: Player, x: unknown, y: unknown, z: unknown)
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return
	end
	if x ~= math.floor(x) or y ~= math.floor(y) or z ~= math.floor(z) then
		return
	end
	local now = os.clock()
	if now - (lastTill[player] or 0) < 0.25 then
		return
	end
	lastTill[player] = now
	local island = IslandService.GetIsland(player)
	local data = DataService.GetData(player)
	local hoe = heldTool(player, "Hoe")
	if not island or not data or not hoe then
		return
	end

	local world = island.World
	local cellKey = BlockWorld.key(x, y, z)
	local above = BlockWorld.key(x, y + 1, z)
	if
		not TILLABLE[world.Cells[cellKey] or ""]
		or world.Protected[cellKey]
		or IslandService.GetNode(player, x, y, z)
	then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	if (root.Position - BlockWorld.position(world, x, y, z)).Magnitude > Blocks.Reach + 3 then
		return
	end
	-- Crops need open sky (a mined tree or boulder counts as taken: it grows back)
	if world.Cells[above] or world.Protected[above] or IslandService.GetNode(player, x, y + 1, z) then
		StateService.Notify(player, "Clear the space on top first", "bad")
		return
	end

	local plots: { Plot } = farms[player] or {}
	BlockWorld.set(world, x, y, z, "Farmland")
	IslandService.RecordChange(player, x, y, z, "Farmland")
	world.Protected[above] = true
	data.Farm.Plots[cellKey] = nil
	local plot = makePlot(island, cellKey, x, y, z)
	if plot then
		refreshPlot(player, plot)
		table.insert(plots, plot)
		farms[player] = plots
	end
	useTool(player, hoe)
	DataService.MarkChanged(player)
	QuestService.Record(player, "Till")
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
	Remotes.Till.OnServerEvent:Connect(onTill)
	Players.PlayerRemoving:Connect(function(player)
		farms[player] = nil
		lastClick[player] = nil
		lastTill[player] = nil
		lastToolNotice[player] = nil
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
