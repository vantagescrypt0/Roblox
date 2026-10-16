--!strict
-- Adding, removing and counting items. All item changes go through here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local DataService = require(script.Parent.DataService)

local InventoryService = {}

function InventoryService.Count(player: Player, itemId: string): number
	local data = DataService.GetData(player)
	return if data then data.Items[itemId] or 0 else 0
end

function InventoryService.Add(player: Player, itemId: string, amount: number)
	local data = DataService.GetData(player)
	assert(Items[itemId], `Unknown item {itemId}`)
	if not data or amount <= 0 then
		return
	end
	data.Items[itemId] = (data.Items[itemId] or 0) + amount
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
