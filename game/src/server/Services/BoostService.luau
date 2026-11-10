--!strict
-- Boost crystals (Boosts.luau): yours for good, bought with Robux or found (Loot Crates, Legendary Skydrops). Every
-- crystal arrives as an item: hold it and right-click (tap on a phone) to redeem it (your call, 2026-11-10), and the
-- screen then shows how many you have free to place, as it does after taking them all back out. From Menu > Boosts
-- you put each free one into a tree, which unlocks that tree's next boost; once a season you can take them all back
-- out and place them again. In the Warzone you have to get a crystal out first: die carrying it and it's in your body
-- like everything else.
--
-- Other services read the boosts straight from the save (Boosts.Has). This one also puts each tree's level on the
-- player as an attribute (BoostWarzone, BoostPlayer, BoostIsland) for screens and for WarzoneService's hearts, and
-- CanFly where the Player tree's flight works (FlightController, AntiCheatService).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boosts = require(ReplicatedStorage.Shared.Boosts)
local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local KitService = require(script.Parent.KitService)
local StateService = require(script.Parent.StateService)

local ASK_COOLDOWN = 0.3

local BoostService = {}

local lastAsk: { [Player]: number } = {}
local testOnSale = false -- Studio can't sell anything: a test can say it's on sale (DevService's "Boost")

local function onSale(): boolean
	return Boosts.ProductId ~= 0 or testOnSale
end

local function placed(saved: Boosts.Save): number
	return saved.Warzone + saved.Player + saved.Island
end

-- Can they take their crystals out of the trees this season?
local function canReset(data: DataService.Data): boolean
	local saved = data.Boosts
	return saved.ResetSeason ~= data.Season and placed(saved) > 0
end

-- Puts the trees' levels where screens and other services look for them
local function apply(player: Player)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	for _, tree in Boosts.Trees do
		player:SetAttribute(`Boost{tree.Id}`, Boosts.Level(data, tree.Id))
	end
	player:SetAttribute("CanFly", Boosts.Has(data, "Player", 5) and Places.Current() ~= "Warzone")
end

-- Crystals redeemed plus the ones they're carrying: buying stops once that would max every tree
local function owned(player: Player, data: DataService.Data): number
	return data.Boosts.Crystals + InventoryService.Count(player, Boosts.Item)
end

local function sendState(player: Player)
	local data = DataService.GetData(player)
	if not data or player.Parent ~= Players then
		return
	end
	local saved = data.Boosts
	Remotes.BoostState:FireClient(player, {
		Crystals = saved.Crystals,
		Warzone = saved.Warzone,
		Player = saved.Player,
		Island = saved.Island,
		Free = Boosts.Free(data),
		CanReset = canReset(data),
		OnSale = onSale() and owned(player, data) < Boosts.Most,
		ProductId = Boosts.ProductId,
	})
end

-- Is the crystal what's in their hand (the selected hotbar slot, CombatService's Tool)?
local function holding(player: Player): boolean
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("Held") == Boosts.Item
end

local function changed(player: Player)
	DataService.MarkChanged(player)
	apply(player)
	sendState(player)
end

local function tooSoon(player: Player): boolean
	local now = os.clock()
	if now - (lastAsk[player] or 0) < ASK_COOLDOWN then
		return true
	end
	lastAsk[player] = now
	return false
end

local function onOpen(player: Player)
	if not tooSoon(player) then
		sendState(player)
	end
end

local function onAdd(player: Player, treeId: unknown)
	local tree = if type(treeId) == "string" then Boosts.ById[treeId] else nil
	local data = DataService.GetData(player)
	if not tree or not data or tooSoon(player) then
		return
	end
	local saved = data.Boosts :: any
	local level = saved[tree.Id] :: number
	if Boosts.Free(data) <= 0 or level >= Boosts.PerTree then
		return
	end
	saved[tree.Id] = level + 1
	StateService.Notify(player, `{tree.Name}: {tree.Boosts[level + 1]}!`, "level")
	changed(player)
end

local function onReset(player: Player)
	local data = DataService.GetData(player)
	if not data or tooSoon(player) or not canReset(data) then
		return
	end
	local saved = data.Boosts
	saved.Warzone, saved.Player, saved.Island = 0, 0, 0
	saved.ResetSeason = data.Season
	changed(player)
	Remotes.BoostRedeemed:FireClient(player, "reset", Boosts.Free(data))
end

local function onBuy(player: Player)
	local data = DataService.GetData(player)
	if not data or tooSoon(player) or Boosts.ProductId == 0 or owned(player, data) >= Boosts.Most then
		return
	end
	MarketplaceService:PromptProductPurchase(player, Boosts.ProductId)
end

-- Right-clicking with a crystal in your hand redeems it: it joins the crystals you can put into trees
local function onUse(player: Player)
	local data = DataService.GetData(player)
	if not data or tooSoon(player) or InventoryService.Count(player, Boosts.Item) <= 0 or not holding(player) then
		return
	end
	if player:GetAttribute("InWarzone") == true then
		StateService.Notify(player, "Get it out of the Warzone first", "bad")
		return
	end
	if data.Boosts.Crystals >= Boosts.Most then
		StateService.Notify(player, "Every boost is already yours. Keep it for new boosts later", "info")
		return
	end
	if not InventoryService.Remove(player, Boosts.Item, 1) then
		return
	end
	data.Boosts.Crystals += 1
	changed(player)
	Remotes.BoostRedeemed:FireClient(player, "redeemed", Boosts.Free(data))
end

-- One bought crystal (paid out once through KitService's receipts): it comes as the item, to hold and redeem
local function giveBought(player: Player)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	InventoryService.Add(player, Boosts.Item, 1)
	StateService.Notify(
		player,
		"Thanks! Your Boost Crystal is in your Bag. Hold it and right-click to redeem it",
		"level"
	)
	sendState(player)
end

-- For tests in Studio only (DevService)
function BoostService.SetTest(isOnSale: boolean)
	testOnSale = isOnSale
	for _, player in Players:GetPlayers() do
		sendState(player)
	end
end

function BoostService.TestReceipt(player: Player, purchaseId: string): Enum.ProductPurchaseDecision
	return KitService.TestReceipt(player, purchaseId, giveBought)
end

-- After a test changed someone's crystals by hand
function BoostService.Refresh(player: Player)
	apply(player)
	sendState(player)
end

function BoostService.Start()
	Remotes.BoostOpen.OnServerEvent:Connect(onOpen)
	Remotes.BoostAdd.OnServerEvent:Connect(onAdd)
	Remotes.BoostReset.OnServerEvent:Connect(onReset)
	Remotes.BoostBuy.OnServerEvent:Connect(onBuy)
	Remotes.BoostUse.OnServerEvent:Connect(onUse)
	KitService.HandleProduct(Boosts.ProductId, giveBought)
	DataService.OnDataLoaded(function(player)
		apply(player)
		sendState(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAsk[player] = nil
	end)
end

return BoostService
