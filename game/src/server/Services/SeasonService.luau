--!strict
-- Keeps every player on the current season (Seasons.luau). A save from an earlier season is
-- reset as it loads, before anything else sees it (so the island is built without its old
-- trophies); players online when a season ends are reset on the spot.
-- The reset: player level and every skill back to 1, the skill challenges start over, and
-- their rewards are taken away: pets, armor sets and trophies, in the Bag, on the hotbar,
-- worn, or placed on the island. Islands, the rest of the Bag and coins are kept. A letter
-- in the Inbox says what happened.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gear = require(ReplicatedStorage.Shared.Gear)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local DataService = require(script.Parent.DataService)
local InboxService = require(script.Parent.InboxService)
local IslandService = require(script.Parent.IslandService)
local StateService = require(script.Parent.StateService)

-- Seconds between checks for a season that just ended
local CHECK_INTERVAL = 1

-- The challenge rewards a reset takes away, and the blocks the trophies place
local rewardItems: { [string]: boolean } = {}
local rewardBlocks: { [string]: boolean } = {}
for _, pet in Gear.PetList do
	rewardItems[pet.Item] = true
end
for _, armor in Gear.ArmorList do
	rewardItems[armor.Item] = true
end
for _, trophy in Gear.TrophyList do
	rewardItems[trophy.Item] = true
	rewardBlocks[trophy.Block] = true
end

local SeasonService = {}

-- Players whose save was reset as it loaded, waiting for their letter
local welcome: { [Player]: boolean } = {}

-- Starts a save on `season`. Returns the island cells whose trophies it took off.
local function reset(data: DataService.Data, season: number): { string }
	data.Season = season
	data.Level = 1
	data.XP = 0
	for _, skill in data.Skills :: { [string]: { Level: number, XP: number } } do
		skill.Level = 1
		skill.XP = 0
	end
	data.Challenges.Counts = {}
	data.Challenges.Reached = {}

	for itemId in rewardItems do
		data.Items[itemId] = nil
	end
	for slot, itemId in data.Hotbar do
		if rewardItems[itemId] then
			data.Hotbar[slot] = ""
		end
	end
	data.Equipped.Pet = ""
	data.Equipped.Armor = ""

	local cleared = {}
	for cellKey, blockType in data.Island.Blocks do
		if rewardBlocks[blockType] then
			table.insert(cleared, cellKey)
		end
	end
	for _, cellKey in cleared do
		data.Island.Blocks[cellKey] = "Air"
	end
	return cleared
end

local function sendLetter(player: Player, season: number)
	InboxService.Send(player.UserId, {
		From = "Skyblox",
		Text = `Season {season} has begun! Levels, skills and challenges start fresh, and last season's pets, armor and trophies are gone. Your island, Bag and coins are still yours.`,
	})
end

-- A season ended while the player was here
local function resetNow(player: Player, data: DataService.Data, season: number)
	local cleared = reset(data, season)
	local island = IslandService.GetIsland(player)
	if island then
		for _, cellKey in cleared do
			local x, y, z = BlockWorld.unkey(cellKey)
			BlockWorld.set(island.World, x, y, z, nil)
			IslandService.RecordChange(player, x, y, z, nil)
		end
	end
	DataService.MarkChanged(player)
	StateService.Notify(player, `Season {season} has begun!`, "season")
	sendLetter(player, season)
end

local function checkOnline()
	local season = Seasons.At(os.time())
	for _, player in Players:GetPlayers() do
		local data = DataService.GetData(player)
		if data and data.Season < season then
			resetNow(player, data, season)
		end
	end
end

function SeasonService.Start()
	DataService.OnLoading(function(player, data)
		local season = Seasons.At(os.time())
		if data.Season < season then
			reset(data, season)
			welcome[player] = true
		end
	end)
	DataService.OnDataLoaded(function(player, data)
		if welcome[player] then
			welcome[player] = nil
			sendLetter(player, data.Season)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		welcome[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_INTERVAL)
			checkOnline()
		end
	end)
end

return SeasonService
