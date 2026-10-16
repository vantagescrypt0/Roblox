--!strict
-- The 5-slot hotbar: which item is in each slot, which slot is selected, and showing the
-- selected item in your hand (tools, blocks and crops all show, like Minecraft).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)

local HOTBAR_SIZE = 5

local HotbarService = {}

local selected: { [Player]: number } = {}

local function isSlot(slot: unknown): boolean
	return type(slot) == "number" and slot == math.floor(slot) and slot >= 1 and slot <= HOTBAR_SIZE
end

-- The item in the player's selected hotbar slot, if they still have one
function HotbarService.GetHeldItem(player: Player): string?
	local data = DataService.GetData(player)
	local itemId = data and data.Hotbar[selected[player] or 1]
	if data and itemId and itemId ~= "" and (data.Items[itemId] or 0) > 0 then
		return itemId
	end
	return nil
end

local function refreshHeld(player: Player)
	CombatService.Equip(player, HotbarService.GetHeldItem(player))
end

local function onSetHotbar(player: Player, slot: unknown, itemId: unknown)
	local data = DataService.GetData(player)
	if not data or not isSlot(slot) or type(itemId) ~= "string" then
		return
	end
	if itemId ~= "" and (not Items[itemId] or (data.Items[itemId] or 0) <= 0) then
		return
	end
	-- An item lives in one slot at a time: moving it clears its old slot
	if itemId ~= "" then
		for other = 1, HOTBAR_SIZE do
			if data.Hotbar[other] == itemId then
				data.Hotbar[other] = ""
			end
		end
	end
	data.Hotbar[slot :: number] = itemId
	DataService.MarkChanged(player)
	refreshHeld(player)
end

local function onSelectSlot(player: Player, slot: unknown)
	if not isSlot(slot) then
		return
	end
	selected[player] = slot :: number
	refreshHeld(player)
end

function HotbarService.Start()
	Remotes.SetHotbar.OnServerEvent:Connect(onSetHotbar)
	Remotes.SelectSlot.OnServerEvent:Connect(onSelectSlot)
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
