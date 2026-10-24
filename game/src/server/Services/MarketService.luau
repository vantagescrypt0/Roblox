--!strict
-- Trading with the Merchant in Town opens the Market window: sell crops and resources,
-- buy seeds. (Right-click / tap the Merchant, or use its Trade prompt.)
-- Every purchase and sale is checked here on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)
local TownService = require(script.Parent.TownService)

-- How close you must be to your market to trade
local MAX_TRADE_DISTANCE = 20
local MAX_BUY = 50

local MarketService = {}

local cropProducts: { [string]: boolean } = {}
for _, crop in Crops.List do
	cropProducts[crop.Product] = true
end

local function nearStall(player: Player): boolean
	local stall = TownService.GetMarketCounter()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not stall or not root or not root:IsA("BasePart") then
		return false
	end
	if (root.Position - stall.Position).Magnitude > MAX_TRADE_DISTANCE then
		StateService.Notify(player, "Walk up to the Market in Town to trade", "bad")
		return false
	end
	return true
end

local function sellItem(player: Player, itemId: string, amount: number): number
	local item = Items[itemId]
	if not item or item.SellPrice <= 0 then
		return 0
	end
	local have = InventoryService.Count(player, itemId)
	amount = math.min(amount, have)
	if amount <= 0 or not InventoryService.Remove(player, itemId, amount) then
		return 0
	end
	local earned = amount * item.SellPrice
	InventoryService.AddCoins(player, earned)
	return earned
end

local function onSell(player: Player, itemId: unknown, amount: unknown)
	if type(itemId) ~= "string" or not nearStall(player) then
		return
	end

	local earned = 0
	if itemId == "*" then
		-- Sell every crop
		for product in cropProducts do
			earned += sellItem(player, product, math.huge)
		end
	else
		local count = if amount == "all" then math.huge elseif type(amount) == "number" then math.floor(amount) else 0
		earned = sellItem(player, itemId, count)
	end

	if earned > 0 then
		StateService.Notify(player, `Sold for {earned} coins`, "coins")
		QuestService.Record(player, "Sell")
	else
		StateService.Notify(player, "Nothing to sell", "bad")
	end
end

local function onBuySeed(player: Player, seedId: unknown, amount: unknown)
	if type(seedId) ~= "string" or type(amount) ~= "number" or not nearStall(player) then
		return
	end
	amount = math.clamp(math.floor(amount), 1, MAX_BUY)
	local item = Items[seedId]
	local price = item and item.BuyPrice
	if not item or not price then
		return
	end

	-- The seed must belong to a crop the player has unlocked
	local farmingLevel = ProgressionService.GetSkillLevel(player, "Farming")
	for _, crop in Crops.List do
		if crop.Seed == seedId and farmingLevel < crop.FarmingLevel then
			StateService.Notify(player, `Needs Farming level {crop.FarmingLevel}`, "bad")
			return
		end
	end

	if InventoryService.SpendCoins(player, amount * price) then
		InventoryService.Add(player, seedId, amount)
		StateService.Notify(player, `Bought {amount} {item.Name}`, "good")
		QuestService.Record(player, "BuySeeds")
	else
		StateService.Notify(player, "Not enough coins", "bad")
	end
end

function MarketService.Start()
	local merchant = TownService.GetMerchant()
	local prompt =
		Prompts.Create(merchant.PrimaryPart :: BasePart, { Action = "Trade", Object = "Merchant", Distance = 12 })
	prompt.Triggered:Connect(function(player)
		Remotes.OpenMarket:FireClient(player)
	end)
	Remotes.Sell.OnServerEvent:Connect(onSell)
	Remotes.BuySeed.OnServerEvent:Connect(onBuySeed)
end

return MarketService
