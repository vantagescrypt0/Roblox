--!strict
-- What's sold with Robux ([[Kits]]): kits, game passes that are yours for good and pay out every week from Menu > Kits,
-- and single Loot Crates. Anything whose id is still 0 isn't on sale, and nothing in the game mentions it. Every
-- developer product's receipt comes through here (boost crystals add theirs with HandleProduct).
--
-- Crates are random, so Roblox's rules on paid random items apply. Anyone PolicyService says can't have those isn't
-- offered them, and if they already own the Crate Keeper Kit they get a fixed reward instead of a crate. Everyone else
-- sees every prize and its real odds on the window before they can buy.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Kits = require(ReplicatedStorage.Shared.Kits)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Policy = require(script.Parent.Parent.Util.Policy)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local StateService = require(script.Parent.StateService)

local ASK_COOLDOWN = 0.5
local KEEP_RECEIPTS = 100

type Test = { OnSale: boolean, Owned: boolean, Restricted: boolean }

local KitService = {}

local owners: { [Player]: { [string]: boolean } } = {} -- only ever true: a purchase on the website shows up next time
local lastAsk: { [Player]: number } = {}

-- Studio can't sell anything, so a test says what's true instead (DevService's "Kit")
local test: Test? = nil

local function onSale(kit: Kits.Kit): boolean
	return kit.PassId ~= 0 or (test ~= nil and test.OnSale)
end

local function crateOnSale(): boolean
	return Kits.CrateProductId ~= 0 or (test ~= nil and test.OnSale)
end

local function isRestricted(player: Player): boolean
	if test then
		return test.Restricted
	end
	return Policy.PaidRandomRestricted(player)
end

local function owns(player: Player, kit: Kits.Kit): boolean
	if test then
		return test.Owned
	end
	local mine = owners[player]
	if mine and mine[kit.Id] then
		return true
	end
	if kit.PassId == 0 then
		return false
	end
	local ok, has = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, kit.PassId)
	end)
	if ok and has then
		owners[player] = owners[player] or {}
		owners[player][kit.Id] = true
	end
	return ok and has
end

local function secondsLeft(data: DataService.Data, kit: Kits.Kit): number
	return math.max(0, (data.KitClaims[kit.Id] or 0) + kit.Cooldown - os.time())
end

local function sendState(player: Player)
	local blocked = isRestricted(player)
	local rows = {}
	for _, kit in Kits.List do
		table.insert(rows, {
			Id = kit.Id,
			OnSale = onSale(kit) and not (kit.Random and blocked),
			Owned = owns(player, kit),
			Left = 0,
			PassId = kit.PassId,
		})
	end
	local data = DataService.GetData(player)
	if data and player.Parent == Players then
		for _, row in rows do
			row.Left = secondsLeft(data, Kits.ById[row.Id])
		end
		Remotes.KitState:FireClient(player, {
			Kits = rows,
			Crate = { OnSale = crateOnSale() and not blocked, ProductId = Kits.CrateProductId },
		})
	end
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

local function kitFrom(id: unknown): Kits.Kit?
	return if type(id) == "string" then Kits.ById[id] else nil
end

local function onClaim(player: Player, id: unknown)
	local kit = kitFrom(id)
	if not kit or tooSoon(player) then
		return
	end
	-- Whatever can wait on Roblox comes first: from the time check on, nothing yields
	local owned = owns(player, kit)
	local blocked = kit.Random and isRestricted(player)
	local data = DataService.GetData(player)
	if not owned or not data or secondsLeft(data, kit) > 0 then
		return
	end
	local rewards: { Kits.Reward } = if blocked
		then { { Item = Kits.FixedItem, Count = Kits.FixedCount } :: Kits.Reward }
		else kit.Rewards
	for _, reward in rewards do
		if not InventoryService.HasRoom(player, reward.Item, reward.Count) then
			StateService.Notify(player, "Make room in your Bag first", "bad")
			return
		end
	end
	data.KitClaims[kit.Id] = os.time()
	for _, reward in rewards do
		InventoryService.Add(player, reward.Item, reward.Count)
	end
	DataService.MarkChanged(player)
	local first = rewards[1]
	StateService.Notify(
		player,
		if #rewards == 1 and first.Item == LootCrates.Item
			then `{kit.Name}: {first.Count} {Items[first.Item].Name}! Hold it and right-click anywhere to open it`
			elseif #rewards == 1 then `{kit.Name}: {first.Count} {Items[first.Item].Name}!`
			else `{kit.Name}: it's all in your Bag`,
		"level"
	)
	sendState(player)
end

local function onBuy(player: Player, id: unknown)
	local kit = kitFrom(id)
	if not kit or tooSoon(player) or kit.PassId == 0 or (kit.Random and isRestricted(player)) or owns(player, kit) then
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, kit.PassId)
end

local function onBuyCrate(player: Player)
	if tooSoon(player) or Kits.CrateProductId == 0 or isRestricted(player) then
		return
	end
	MarketplaceService:PromptProductPurchase(player, Kits.CrateProductId)
end

local function forgetOldReceipts(data: DataService.Data)
	local ids = {}
	for id in data.Receipts do
		table.insert(ids, id)
	end
	if #ids > KEEP_RECEIPTS then
		table.sort(ids, function(a, b)
			return data.Receipts[a] > data.Receipts[b]
		end)
		for i = KEEP_RECEIPTS + 1, #ids do
			data.Receipts[ids[i]] = nil
		end
	end
end

-- What each developer product gives: the crate here, and anything another service adds (HandleProduct)
local products: { [number]: (player: Player) -> () } = {}

local function giveCrate(player: Player)
	InventoryService.Add(player, LootCrates.Item, 1)
	StateService.Notify(player, "Thanks! Hold your Loot Crate and right-click anywhere to open it", "level")
end

-- Pays out one purchase, once however often Roblox asks, and only says it's done when that's really saved: the
-- Robux can't be taken for something that gets lost, and asking again can't give a second one.
local function grant(player: Player?, purchaseId: string, give: (player: Player) -> ()): Enum.ProductPurchaseDecision
	local data = if player then DataService.GetData(player) else nil
	if not player or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox asks again when they're next in a server
	end
	if not data.Receipts[purchaseId] then
		data.Receipts[purchaseId] = os.time()
		forgetOldReceipts(data)
		give(player)
		DataService.MarkChanged(player)
	end
	return if DataService.SaveNow(player)
		then Enum.ProductPurchaseDecision.PurchaseGranted
		else Enum.ProductPurchaseDecision.NotProcessedYet
end

local function onReceipt(info: any): Enum.ProductPurchaseDecision
	local give = if info.ProductId == Kits.CrateProductId then giveCrate else products[info.ProductId]
	if info.ProductId == 0 or not give then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return grant(Players:GetPlayerByUserId(info.PlayerId), info.PurchaseId, give)
end

-- Another service's developer product: what one purchase gives. Roblox allows only one receipt handler in a game,
-- so every product is paid out through this one.
function KitService.HandleProduct(productId: number, give: (player: Player) -> ())
	if productId ~= 0 then
		products[productId] = give
	end
end

-- For tests in Studio only (DevService); nil goes back to asking Roblox
function KitService.SetTest(state: Test?)
	test = state
	for _, player in Players:GetPlayers() do
		sendState(player)
	end
end

-- Roblox telling us a purchase was paid for: a crate, or what `give` gives (tests in Studio only)
function KitService.TestReceipt(
	player: Player,
	purchaseId: string,
	give: ((player: Player) -> ())?
): Enum.ProductPurchaseDecision
	return grant(player, purchaseId, give or giveCrate)
end

function KitService.Start()
	Remotes.KitOpen.OnServerEvent:Connect(onOpen)
	Remotes.KitClaim.OnServerEvent:Connect(onClaim)
	Remotes.KitBuy.OnServerEvent:Connect(onBuy)
	Remotes.KitBuyCrate.OnServerEvent:Connect(onBuyCrate)
	DataService.OnDataLoaded(sendState)
	MarketplaceService.ProcessReceipt = onReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
		if not bought then
			return
		end
		for _, kit in Kits.List do
			if kit.PassId == passId then
				owners[player] = owners[player] or {}
				owners[player][kit.Id] = true
				StateService.Notify(player, `Thanks! The {kit.Name} is yours for good`, "level")
				sendState(player)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		owners[player] = nil
		lastAsk[player] = nil
	end)
end

return KitService
