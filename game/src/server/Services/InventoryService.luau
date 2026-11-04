--!strict
-- Adding, removing and counting items. All item changes go through here.
-- data.Slots is what you carry (Inventory.luau); data.Items is the totals, which also count what
-- you wear, so everything else can just ask how many you have. New items stack, then drop into
-- the first empty slot, the hotbar first, like Minecraft.
--
-- When something won't fit, Add sends the rest to your Inbox (InboxService), so a reward is never
-- lost. Gathering checks for room first, and AddGathered drops what doesn't fit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local FULL_NOTICE_EVERY = 1.5
local WORN_ORDER = { "Helmet", "Chest", "Legs", "Boots", "Shield", "Pet" }

local InventoryService = {}

local held: { [Player]: number } = {}
local lastFullNotice: { [Player]: number } = {}
local overflowHandler: ((player: Player, itemId: string, amount: number) -> ())? = nil

-- The hotbar slot in the player's hand: placing and pouring use it first (HotbarService)
function InventoryService.SetHeld(player: Player, slot: number)
	held[player] = slot
end

-- Who takes what doesn't fit (InboxService)
function InventoryService.OnOverflow(handler: (player: Player, itemId: string, amount: number) -> ())
	overflowHandler = handler
end

function InventoryService.Count(player: Player, itemId: string): number
	local data = DataService.GetData(player)
	return if data then data.Items[itemId] or 0 else 0
end

function InventoryService.RoomFor(player: Player, itemId: string): number
	local data = DataService.GetData(player)
	return if data then Inventory.RoomFor(data.Slots, itemId) else 0
end

function InventoryService.HasRoom(player: Player, itemId: string, amount: number): boolean
	return InventoryService.RoomFor(player, itemId) >= amount
end

-- "Your Bag is full", not more than once in a while
function InventoryService.NotifyFull(player: Player)
	local now = os.clock()
	if now - (lastFullNotice[player] or 0) > FULL_NOTICE_EVERY then
		lastFullNotice[player] = now
		Remotes.Notify:FireClient(player, "Your Bag is full", "bad")
	end
end

-- Puts items in the slots and counts them. Returns how many didn't fit.
local function insert(player: Player, data: DataService.Data, itemId: string, amount: number): number
	local left = Inventory.Insert(data.Slots, itemId, amount)
	if left < amount then
		data.Items[itemId] = (data.Items[itemId] or 0) + amount - left
		DataService.MarkChanged(player)
	end
	return left
end

function InventoryService.Add(player: Player, itemId: string, amount: number)
	local data = DataService.GetData(player)
	assert(Items[itemId], `Unknown item {itemId}`)
	if not data or amount <= 0 then
		return
	end
	local left = insert(player, data, itemId, amount)
	if left > 0 and overflowHandler then
		overflowHandler(player, itemId, left)
	end
end

-- For what you gather: whatever doesn't fit is left behind
function InventoryService.AddGathered(player: Player, itemId: string, amount: number)
	local data = DataService.GetData(player)
	assert(Items[itemId], `Unknown item {itemId}`)
	if not data or amount <= 0 then
		return
	end
	if insert(player, data, itemId, amount) > 0 then
		InventoryService.NotifyFull(player)
	end
end

-- Takes items you're known to have: out of the slots, and off your body for the rest
local function take(player: Player, data: DataService.Data, itemId: string, amount: number)
	local taken = Inventory.Take(data.Slots, itemId, amount, held[player])
	if taken < amount then
		local equipped = data.Equipped :: { [string]: string }
		for slot, worn in equipped do
			if worn == itemId and taken < amount then
				equipped[slot] = ""
				taken += 1
			end
		end
	end
	data.Items[itemId] = (data.Items[itemId] or 0) - amount
end

-- Removes the items only if the player has enough. Returns whether it worked.
function InventoryService.Remove(player: Player, itemId: string, amount: number): boolean
	local data = DataService.GetData(player)
	local have = if data then data.Items[itemId] or 0 else 0
	if not data or amount <= 0 or have < amount then
		return false
	end
	take(player, data, itemId, amount)
	DataService.MarkChanged(player)
	return true
end

-- Removes several items at once, all or nothing. Returns whether it worked.
function InventoryService.RemoveMany(player: Player, cost: { [string]: number }): boolean
	local data = DataService.GetData(player)
	if not data then
		return false
	end
	for itemId, amount in cost do
		if (data.Items[itemId] or 0) < amount then
			return false
		end
	end
	for itemId, amount in cost do
		take(player, data, itemId, amount)
	end
	DataService.MarkChanged(player)
	return true
end

-- Swaps one `from` for one `to` (a bucket filling or emptying), in the same slot, so it stays in
-- your hand. Returns whether it worked.
function InventoryService.Swap(player: Player, from: string, to: string): boolean
	local data = DataService.GetData(player)
	assert(Items[to], `Unknown item {to}`)
	if not data then
		return false
	end
	local inHand = data.Slots[held[player] or 1]
	local slot = if inHand and inHand.Item == from and inHand.Count > 0 then inHand else nil
	if not slot then
		for _, stack in data.Slots do
			if stack.Item == from and stack.Count > 0 then
				slot = stack
				break
			end
		end
	end
	if not slot then
		return false
	end
	if slot.Count == 1 then
		slot.Item = to
	elseif Inventory.Insert(data.Slots, to, 1) == 0 then
		slot.Count -= 1
	else
		return false
	end
	data.Items[from] = (data.Items[from] or 0) - 1
	data.Items[to] = (data.Items[to] or 0) + 1
	DataService.MarkChanged(player)
	return true
end

-- Gear going on: out of the slots, though it still counts as yours. Returns whether it was there.
function InventoryService.TakeOutToWear(player: Player, itemId: string): boolean
	local data = DataService.GetData(player)
	return data ~= nil and Inventory.Take(data.Slots, itemId, 1) == 1
end

-- Gear coming off: back in the slots. Returns whether it fit.
function InventoryService.PutBackFromWearing(player: Player, itemId: string): boolean
	local data = DataService.GetData(player)
	return data ~= nil and Inventory.Insert(data.Slots, itemId, 1) == 0
end

-- A copy of everything you carry and wear, worn gear first, and which items are being worn
function InventoryService.Everything(data: DataService.Data): ({ Inventory.Stack }, { string })
	local stacks: { Inventory.Stack } = {}
	local worn: { string } = {}
	local equipped = data.Equipped :: { [string]: string }
	for _, slot in WORN_ORDER do
		local itemId = equipped[slot]
		if itemId and itemId ~= "" then
			table.insert(stacks, { Item = itemId, Count = 1 })
			table.insert(worn, itemId)
		end
	end
	for _, stack in data.Slots do
		if stack.Count > 0 then
			table.insert(stacks, { Item = stack.Item, Count = stack.Count })
		end
	end
	return stacks, worn
end

-- Everything you carry and wear comes off, for your body to hold (BodyService). Coins aren't items, and
-- stay yours. Returns the same as Everything.
function InventoryService.TakeEverything(data: DataService.Data): ({ Inventory.Stack }, { string })
	local stacks, worn = InventoryService.Everything(data)
	local equipped = data.Equipped :: { [string]: string }
	for slot in equipped do
		equipped[slot] = ""
	end
	for _, stack in data.Slots do
		stack.Item = ""
		stack.Count = 0
	end
	table.clear(data.Items)
	return stacks, worn
end

function InventoryService.AddCoins(player: Player, amount: number)
	local data = DataService.GetData(player)
	if not data or amount <= 0 then
		return
	end
	data.Coins += amount
	DataService.MarkChanged(player)
end

function InventoryService.SpendCoins(player: Player, amount: number): boolean
	local data = DataService.GetData(player)
	if not data or amount <= 0 or data.Coins < amount then
		return false
	end
	data.Coins -= amount
	DataService.MarkChanged(player)
	return true
end

Players.PlayerRemoving:Connect(function(player)
	held[player] = nil
	lastFullNotice[player] = nil
end)

return InventoryService
