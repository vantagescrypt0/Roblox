--!strict
-- The market stall on your island opens the Market window: sell crops and resources,
-- buy seeds. Also handles buying island expansions (from the Island window).
-- Every purchase and sale is checked here on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local IslandTiers = require(ReplicatedStorage.Shared.IslandTiers)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local Props = require(script.Parent.Parent.Util.Props)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

-- How close you must be to your market to trade
local MAX_TRADE_DISTANCE = 20
local MAX_BUY = 50

local MarketService = {}

local stalls: { [Player]: BasePart } = {}
local cropProducts: { [string]: boolean } = {}
for _, crop in Crops.List do
	cropProducts[crop.Product] = true
end

local function nearStall(player: Player): boolean
	local stall = stalls[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not stall or not root or not root:IsA("BasePart") then
		return false
	end
	if (root.Position - stall.Position).Magnitude > MAX_TRADE_DISTANCE then
		StateService.Notify(player, "Walk back to your Market to trade", "bad")
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

local function onExpand(player: Player)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local nextTier = IslandTiers[data.Island.Tier + 1]
	if not nextTier then
		StateService.Notify(player, "Your island is already the biggest it can be!", "bad")
		return
	end
	if not InventoryService.SpendCoins(player, nextTier.Cost) then
		StateService.Notify(player, `You need {nextTier.Cost} coins to expand`, "bad")
		return
	end
	data.Island.Tier += 1
	DataService.MarkChanged(player)
	IslandService.Rebuild(player)
	StateService.Notify(player, `Your island grew into a {nextTier.Name}!`, "level")
end

local function addSign(face: BasePart, front: Vector3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Props.FaceToward(face, front)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0.3
	gui.Parent = face
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(122, 78, 45)
	text.Text = "MARKET"
	text.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.12, 0)
	padding.PaddingBottom = UDim.new(0.12, 0)
	padding.Parent = text
end

local function buildStall(island: IslandService.Island): BasePart
	local position = island.Markers.Market or (island.Center + Vector3.new(6, 0, 10))
	local model = Props.Place("Market", position, island.Markers.Spawn, island.Model)
	if model then
		model.Name = "Market"
		local face = Props.Part(model, "MarketSignFace")
		if face then
			addSign(face, model:GetPivot().LookVector)
		end
		local lantern = Props.Part(model, "MarketLanternGlow")
		if lantern then
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 200, 120)
			light.Range = 14
			light.Brightness = 1.4
			light.Parent = lantern
		end
		return Props.Part(model, "MarketStall") :: BasePart
	end
	-- Fallback if the art is missing
	local counter = Instance.new("Part")
	counter.Name = "Market"
	counter.Size = Vector3.new(6, 3, 2)
	counter.CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0))
	counter.Color = Color3.fromRGB(160, 110, 60)
	counter.Material = Enum.Material.WoodPlanks
	counter.Anchored = true
	counter.Parent = island.Model
	return counter
end

local function onIslandCreated(player: Player, island: IslandService.Island)
	local stall = buildStall(island)
	stalls[player] = stall
	local prompt = Prompts.Create(stall, { Action = "Open Market", Object = "Market", Distance = 12 })
	Prompts.OnTriggeredBy(prompt, player, function()
		Remotes.OpenMarket:FireClient(player)
	end)
	stall.Destroying:Connect(function()
		if stalls[player] == stall then
			stalls[player] = nil
		end
	end)
end

function MarketService.Start()
	IslandService.OnIslandCreated(onIslandCreated)
	Remotes.Sell.OnServerEvent:Connect(onSell)
	Remotes.BuySeed.OnServerEvent:Connect(onBuySeed)
	Remotes.Expand.OnServerEvent:Connect(onExpand)
end

return MarketService
