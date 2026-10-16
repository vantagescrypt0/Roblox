--!strict
-- Loads and saves each player's data with ProfileStore (session-locked, so the same
-- save can't be open on two servers at once).

local Players = game:GetService("Players")

local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)

local STORE_NAME = "PlayerData_v1"

local TEMPLATE = {
	Coins = 0,
	Level = 1,
	XP = 0,
	Season = 1,
	Island = {
		Tier = 1,
	},
	-- item id -> count
	Items = {} :: { [string]: number },
	Skills = {
		Farming = { Level = 1, XP = 0 },
		Combat = { Level = 1, XP = 0 },
	},
	Farm = {
		-- plot number (as a string) -> what's planted there
		Plots = {} :: { [string]: { Crop: string, PlantedAt: number } },
	},
	Flags = {
		StarterKit = false,
	},
	-- Beginner quest chain: which quest you're on and how far along it is
	Quest = {
		Index = 1,
		Progress = 0,
	},
	-- Warzone run in progress. The bag only becomes yours when you extract; leaving
	-- the game mid-raid loses it.
	Raid = {
		Active = false,
		Bag = {} :: { [string]: number },
	},
}

export type Data = typeof(TEMPLATE)
type PlayerCallback = (player: Player, data: Data) -> ()

local DataService = {}

local store = ProfileStore.New(STORE_NAME, TEMPLATE)
local profiles: { [Player]: any } = {}
local loadedCallbacks: { PlayerCallback } = {}
local changedCallbacks: { PlayerCallback } = {}
local pendingChanges: { [Player]: boolean } = {}

-- Runs the callback for every player whose data is loaded, now and in the future.
function DataService.OnDataLoaded(callback: PlayerCallback)
	table.insert(loadedCallbacks, callback)
	for player, profile in profiles do
		task.spawn(callback, player, profile.Data)
	end
end

-- Runs the callback (at most once per frame per player) after data changes.
function DataService.OnChanged(callback: PlayerCallback)
	table.insert(changedCallbacks, callback)
end

function DataService.GetData(player: Player): Data?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- Call after changing a player's data so the HUD and leaderboard update.
function DataService.MarkChanged(player: Player)
	if pendingChanges[player] then
		return
	end
	pendingChanges[player] = true
	task.defer(function()
		pendingChanges[player] = nil
		local data = DataService.GetData(player)
		if not data then
			return
		end
		for _, callback in changedCallbacks do
			task.spawn(callback, player, data)
		end
	end)
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		player:Kick("Your data couldn't be loaded. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data was opened on another server. Please rejoin.")
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	local data = profile.Data
	if not data.Flags.StarterKit then
		data.Flags.StarterKit = true
		data.Items.WheatSeeds = (data.Items.WheatSeeds or 0) + 6
	end
	if data.Raid.Active then
		data.Raid.Active = false
		data.Raid.Bag = {}
	end

	profiles[player] = profile
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, data)
	end
end

function DataService.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		pendingChanges[player] = nil
		local profile = profiles[player]
		if profile then
			profile:EndSession()
		end
	end)
end

return DataService
