--!strict
-- The hotbar is the inventory's first 9 slots: this keeps track of which one is selected and
-- shows its item in your hand (tools, blocks and crops all show, like Minecraft). It also
-- moves stacks around the inventory for the Bag.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local HotbarService = {}

local selected: { [Player]: number } = {}

local function isIndex(index: unknown, last: number): boolean
	return type(index) == "number" and index == math.floor(index) and index >= 1 and index <= last
end

-- The item in the player's selected hotbar slot, if they still have one
function HotbarService.GetHeldItem(player: Player): string?
	local data = DataService.GetData(player)
	local stack = data and data.Slots[selected[player] or 1]
	if stack and stack.Count > 0 then
		return stack.Item
	end
	return nil
end

local function refreshHeld(player: Player)
	CombatService.Equip(player, HotbarService.GetHeldItem(player))
end

local function onSelectSlot(player: Player, slot: unknown)
	if not isIndex(slot, Inventory.Hotbar) then
		return
	end
	selected[player] = slot :: number
	InventoryService.SetHeld(player, slot :: number)
	refreshHeld(player)
end

local function onMoveStack(player: Player, from: unknown, to: unknown, amount: unknown)
	local data = DataService.GetData(player)
	if not data or not isIndex(from, Inventory.Size) or not isIndex(to, Inventory.Size) then
		return
	end
	if not isIndex(amount, 1e9) then
		return
	end
	if Inventory.Move(data.Slots, from :: number, to :: number, amount :: number) then
		DataService.MarkChanged(player)
	end
end

local function onQuickMove(player: Player, from: unknown)
	local data = DataService.GetData(player)
	if data and isIndex(from, Inventory.Size) and Inventory.QuickMove(data.Slots, from :: number) then
		DataService.MarkChanged(player)
	end
end

function HotbarService.Start()
	Remotes.SelectSlot.OnServerEvent:Connect(onSelectSlot)
	Remotes.MoveStack.OnServerEvent:Connect(onMoveStack)
	Remotes.QuickMove.OnServerEvent:Connect(onQuickMove)
	-- Re-hold the item after respawning, and drop it if it was used up
	DataService.OnChanged(function(player)
		refreshHeld(player)
	end)
	local function track(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(refreshHeld, player)
		end)
	end
	for _, player in Players:GetPlayers() do
		track(player)
	end
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(player)
		selected[player] = nil
	end)
end

return HotbarService
