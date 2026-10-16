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
	if before == 0 then
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
