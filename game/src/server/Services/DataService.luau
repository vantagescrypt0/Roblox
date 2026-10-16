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
}

export type Data = typeof(TEMPLATE)
type LoadedCallback = (player: Player, data: Data) -> ()

local DataService = {}

local store = ProfileStore.New(STORE_NAME, TEMPLATE)
local profiles: { [Player]: any } = {}
local loadedCallbacks: { LoadedCallback } = {}

-- Runs the callback for every player whose data is loaded, now and in the future.
function DataService.OnDataLoaded(callback: LoadedCallback)
	table.insert(loadedCallbacks, callback)
	for player, profile in profiles do
		task.spawn(callback, player, profile.Data)
	end
end

function DataService.GetData(player: Player): Data?
	local profile = profiles[player]
	return if profile then profile.Data else nil
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

	profiles[player] = profile
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, profile.Data)
	end
end

function DataService.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profile:EndSession()
		end
	end)
end

return DataService
