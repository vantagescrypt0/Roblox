--!strict
-- Adding, removing and counting items. All item changes go through here.
-- New items drop into the first empty hotbar slot, like Minecraft.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local DataService = require(script.Parent.DataService)

local HOTBAR_SIZE = 5

local InventoryService = {}

function InventoryService.Count(player: Player, itemId: string): number
	local data = DataService.GetData(player)
	return if data then data.Items[itemId] or 0 else 0
end

local function autoHotbar(data: DataService.Data, itemId: string)
	for slot = 1, HOTBAR_SIZE do
		if data.Hotbar[slot] == itemId then
			return
		end
	end
	for slot = 1, HOTBAR_SIZE do
		if data.Hotbar[slot] == "" or data.Hotbar[slot] == nil then
			data.Hotbar[slot] = itemId
			return
		end
	end
end

-- Used-up items leave the hotbar
local function clearIfEmpty(data: DataService.Data, itemId: string)
	if (data.Items[itemId] or 0) > 0 then
		return
	end
	for slot = 1, HOTBAR_SIZE do
		if data.Hotbar[slot] == itemId then
			data.Hotbar[slot] = ""
		end
	end
end

function InventoryService.Add(player: Player, itemId: string, amount: number)
	local data = DataService.GetData(player)
	assert(Items[itemId], `Unknown item {itemId}`)
	if not data or amount <= 0 then
		return
	end
	local before = data.Items[itemId] or 0
	data.Items[itemId] = before + amount
	-- New items drop into the hotbar, but not pets and armor (they're worn from the Bag)
	if before == 0 and not Items[itemId].Equip then
		autoHotbar(data, itemId)
	end
	DataService.MarkChanged(player)
end

-- Removes the items only if the player has enough. Returns whether it worked.
function InventoryService.Remove(player: Player, itemId: string, amount: number): boolean
	local data = DataService.GetData(player)
	local have = if data then data.Items[itemId] or 0 else 0
	if not data or amount <= 0 or have < amount then
		return false
	end
	data.Items[itemId] = have - amount
	clearIfEmpty(data, itemId)
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
		data.Items[itemId] -= amount
		clearIfEmpty(data, itemId)
	end
	DataService.MarkChanged(player)
	return true
end

-- Swaps one `from` for one `to` (a bucket filling or emptying). If that was the last `from`,
-- `to` takes its hotbar slot, so it stays in your hand. Returns whether it worked.
function InventoryService.Swap(player: Player, from: string, to: string): boolean
	local data = DataService.GetData(player)
	assert(Items[to], `Unknown item {to}`)
	local have = if data then data.Items[from] or 0 else 0
	if not data or have < 1 then
		return false
	end
	data.Items[from] = have - 1
	local before = data.Items[to] or 0
	data.Items[to] = before + 1
	if have == 1 then
		local onHotbar = table.find(data.Hotbar, to) ~= nil
		for slot = 1, HOTBAR_SIZE do
			if data.Hotbar[slot] == from then
				data.Hotbar[slot] = if onHotbar then "" else to
				onHotbar = true
			end
		end
		clearIfEmpty(data, from)
	end
	if before == 0 then
		autoHotbar(data, to)
	end
	DataService.MarkChanged(player)
	return true
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

return InventoryService
