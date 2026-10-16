--!strict
-- A market stand on your island: sell crops for coins, buy seeds.
-- (Later this moves to the shared hub; see Tutorial & Quests in the vault.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

local STAND_OFFSET = Vector3.new(6, 0, 10)
local SEED_PACK_SIZE = 5

local MarketService = {}

local function sellCrops(player: Player)
	local data = DataService.GetData(player)
	if not data then
		return
	end

	local earned = 0
	for _, crop in Crops.List do
		local count = InventoryService.Count(player, crop.Product)
		if count > 0 and InventoryService.Remove(player, crop.Product, count) then
			earned += count * Items[crop.Product].SellPrice
		end
	end

	if earned > 0 then
		InventoryService.AddCoins(player, earned)
		StateService.Notify(player, `Sold crops for {earned} coins`, "good")
		QuestService.Record(player, "Sell")
	else
		StateService.Notify(player, "No crops to sell yet", "bad")
	end
end

local function buySeeds(player: Player)
	local farmingLevel = ProgressionService.GetSkillLevel(player, "Farming")
	local data = DataService.GetData(player)
	if not data then
		return
	end

	-- Best seed the player has unlocked that the stand sells (Warzone seeds aren't sold)
	local crop: Crops.Crop? = nil
	for _, candidate in Crops.List do
		if farmingLevel >= candidate.FarmingLevel and Items[candidate.Seed].BuyPrice then
			crop = candidate
		end
	end
	if not crop then
		return
	end

	local price = Items[crop.Seed].BuyPrice or 0
	local amount = if price > 0 then math.min(SEED_PACK_SIZE, data.Coins // price) else 0
	if amount <= 0 then
		StateService.Notify(player, `Not enough coins ({price} per {Items[crop.Seed].Name})`, "bad")
		return
	end

	if InventoryService.SpendCoins(player, amount * price) then
		InventoryService.Add(player, crop.Seed, amount)
		StateService.Notify(player, `Bought {amount} {Items[crop.Seed].Name}`, "good")
		QuestService.Record(player, "BuySeeds")
	end
end

local function buildStand(island: IslandService.Island): BasePart
	local base = island.Center + STAND_OFFSET

	local counter = Instance.new("Part")
	counter.Name = "MarketStand"
	counter.Size = Vector3.new(6, 3, 2)
	counter.CFrame = CFrame.new(base + Vector3.new(0, 1.5, 0))
	counter.Color = Color3.fromRGB(160, 110, 60)
	counter.Material = Enum.Material.WoodPlanks
	counter.Anchored = true
	counter.Parent = island.Model

	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(7, 0.4, 3.5)
	roof.CFrame = CFrame.new(base + Vector3.new(0, 6, 0))
	roof.Color = Color3.fromRGB(200, 60, 60)
	roof.Material = Enum.Material.Fabric
	roof.Anchored = true
	roof.Parent = counter

	for _, x in { -3, 3 } do
		local post = Instance.new("Part")
		post.Name = "Post"
		post.Size = Vector3.new(0.4, 3, 0.4)
		post.CFrame = CFrame.new(base + Vector3.new(x, 4.5, 0))
		post.Color = Color3.fromRGB(120, 80, 45)
		post.Material = Enum.Material.Wood
		post.Anchored = true
		post.Parent = counter
	end

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(120, 34)
	sign.StudsOffset = Vector3.new(0, 6, 0)
	sign.MaxDistance = 80
	sign.Parent = counter
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "MARKET"
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.2
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.Parent = sign

	return counter
end

local function onIslandCreated(player: Player, island: IslandService.Island)
	local counter = buildStand(island)

	local sell = Prompts.Create(counter, { Action = "Sell crops", Object = "Market" })
	Prompts.OnTriggeredBy(sell, player, function()
		sellCrops(player)
	end)

	local buy = Prompts.Create(counter, { Action = "Buy seeds", Object = "Market", Key = Enum.KeyCode.F })
	buy.GamepadKeyCode = Enum.KeyCode.ButtonY
	Prompts.OnTriggeredBy(buy, player, function()
		buySeeds(player)
	end)
end

function MarketService.Start()
	IslandService.OnIslandCreated(onIslandCreated)
end

return MarketService
