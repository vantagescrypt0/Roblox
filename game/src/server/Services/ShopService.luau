--!strict
-- The shopkeepers in Town (Shops.luau). Click or tap one, or use their Trade prompt, to
-- open their shop window: sell them what they buy, buy what they sell. Every sale and
-- purchase is checked here on the server: you must be standing near that shopkeeper, the
-- item must be on their list, and seeds need the crop's Farming level.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Shops = require(ReplicatedStorage.Shared.Shops)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)
local TownService = require(script.Parent.TownService)

-- How close (studs) you must be to a shopkeeper to trade with them
local MAX_TRADE_DISTANCE = 22
local MAX_BUY = 50

local ShopService = {}

-- Which items each shop buys and sells, for quick checks
local buys: { [string]: { [string]: boolean } } = {}
local sells: { [string]: { [string]: boolean } } = {}
for _, shop in Shops.List do
	buys[shop.Id], sells[shop.Id] = {}, {}
	for _, itemId in shop.Buys do
		buys[shop.Id][itemId] = true
	end
	for _, itemId in shop.Sells do
		sells[shop.Id][itemId] = true
	end
end

-- Seeds need their crop's Farming level
local seedLevel: { [string]: number } = {}
for _, crop in Crops.List do
	seedLevel[crop.Seed] = crop.FarmingLevel
end

local function nearShop(player: Player, shopId: string): boolean
	local keeper = TownService.GetShopkeepers()[shopId]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not keeper or not keeper.PrimaryPart or not root or not root:IsA("BasePart") then
		return false
	end
	if (root.Position - keeper.PrimaryPart.Position).Magnitude > MAX_TRADE_DISTANCE then
		StateService.Notify(player, `Walk up to the {Shops.ById[shopId].Name} to trade`, "bad")
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

local function onSell(player: Player, shopId: unknown, itemId: unknown, amount: unknown)
	if type(shopId) ~= "string" or type(itemId) ~= "string" or not buys[shopId] then
		return
	end
	local shop = Shops.ById[shopId]
	if (itemId == "*" and not shop.SellAll) or (itemId ~= "*" and not buys[shopId][itemId]) then
		return
	end
	if not nearShop(player, shopId) then
		return
	end

	local earned = 0
	if itemId == "*" then
		for _, product in shop.Buys do
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

local function onBuy(player: Player, shopId: unknown, itemId: unknown, amount: unknown)
	if type(shopId) ~= "string" or type(itemId) ~= "string" or type(amount) ~= "number" then
		return
	end
	if amount ~= amount or not sells[shopId] or not sells[shopId][itemId] then
		return
	end
	local item = Items[itemId]
	local price = item and item.BuyPrice
	if not item or not price or not nearShop(player, shopId) then
		return
	end
	amount = math.clamp(math.floor(amount), 1, MAX_BUY)

	local needs = seedLevel[itemId]
	if needs and ProgressionService.GetSkillLevel(player, "Farming") < needs then
		StateService.Notify(player, `Needs Farming level {needs}`, "bad")
		return
	end

	if InventoryService.SpendCoins(player, amount * price) then
		InventoryService.Add(player, itemId, amount)
		StateService.Notify(player, `Bought {amount} {item.Name}`, "good")
		if needs then
			QuestService.Record(player, "BuySeeds")
		end
	else
		StateService.Notify(player, "Not enough coins", "bad")
	end
end

function ShopService.Start()
	for shopId, keeper in TownService.GetShopkeepers() do
		local shop = Shops.ById[shopId]
		local prompt =
			Prompts.Create(keeper.PrimaryPart :: BasePart, { Action = "Trade", Object = shop.Name, Distance = 12 })
		prompt.Triggered:Connect(function(player)
			Remotes.OpenShop:FireClient(player, shopId)
		end)
	end
	Remotes.Sell.OnServerEvent:Connect(onSell)
	Remotes.Buy.OnServerEvent:Connect(onBuy)
end

return ShopService
