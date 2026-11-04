--!strict
-- Opening Loot Crates (LootCrates.luau). A crate is used up and its one prize goes straight into
-- your Bag; your screen is told what it was. Works in every place.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local InventoryService = require(script.Parent.InventoryService)
local StateService = require(script.Parent.StateService)

local COOLDOWN = 0.5

local CrateService = {}

local lastOpen: { [Player]: number } = {}
local rng = Random.new()

local function onOpen(player: Player)
	local now = os.clock()
	if now - (lastOpen[player] or 0) < COOLDOWN then
		return
	end
	lastOpen[player] = now
	if not InventoryService.Remove(player, LootCrates.Item, 1) then
		return
	end
	local prize = LootCrates.Roll(rng:NextNumber())
	local count = rng:NextInteger(prize.Min, prize.Max)
	InventoryService.Add(player, prize.Item, count)
	StateService.Notify(player, `Loot Crate: {count} {Items[prize.Item].Name}!`, "level")
	Remotes.CrateOpened:FireClient(player, prize.Item, count)
end

function CrateService.Start()
	Remotes.OpenCrate.OnServerEvent:Connect(onOpen)
	Players.PlayerRemoving:Connect(function(player)
		lastOpen[player] = nil
	end)
end

return CrateService
