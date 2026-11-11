--!strict
-- Hands out the Beta Tester tags (shared/BetaTag.luau). The first time someone joins after the tags went in, any
-- server asks one shared counter for the next number: up to Config.BetaTags, it's theirs for good, saved on them and
-- shown as an attribute on their Player for everyone to see. Once they've all gone, nobody new gets one. Studio
-- playtests count on their own counter, so testing never uses up a real number, and a place that isn't published
-- (a Rojo build) has no DataStores, so it counts in a plain number.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BetaTag = require(ReplicatedStorage.Shared.BetaTag)
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local STORE_NAME = if RunService:IsStudio() then "BetaTag_Studio_v1" else "BetaTag_v1"
local COUNTER = "Given" -- how many numbers have been handed out
local CELEBRATE_AFTER = 4 -- seconds after their screen is ready, so it isn't lost under the loading in

local BetaService = {}

-- The shared counter: a DataStore, or a stand-in where there are none
type Counter = { Read: () -> number, Add: () -> number }

local function makeCounter(): Counter
	if game.GameId == 0 then
		local count = 0
		return {
			Read = function()
				return count
			end,
			Add = function()
				count += 1
				return count
			end,
		}
	end
	local store = DataStoreService:GetDataStore(STORE_NAME)
	return {
		Read = function()
			return tonumber(store:GetAsync(COUNTER)) or 0
		end,
		Add = function()
			return store:IncrementAsync(COUNTER, 1)
		end,
	}
end

local counter = makeCounter()
local allGone = false -- this server has seen the last tag go
local asking: { [Player]: boolean } = {}
local ready: { [Player]: boolean } = {}
local toCelebrate: { [Player]: number } = {}

local function celebrate(player: Player, number: number)
	task.delay(CELEBRATE_AFTER, function()
		if player.Parent == Players then
			Remotes.BetaTagGiven:FireClient(player, number, Config.BetaTags)
		end
	end)
end

local function give(player: Player, data: DataService.Data)
	if data.Beta > 0 or allGone or asking[player] then
		return
	end
	asking[player] = true
	-- Look first, so latecomers don't keep pushing the count past the last tag
	local looked, given = pcall(counter.Read)
	if looked and given >= Config.BetaTags then
		allGone = true
	end
	local ok, number = false, nil
	if looked and not allGone then
		ok, number = pcall(counter.Add)
	end
	asking[player] = nil
	if not ok or type(number) ~= "number" then
		return -- couldn't reach the counter (or they're all gone): the next time they join tries again
	end
	if number > Config.BetaTags then
		allGone = true
		return
	end
	if DataService.GetData(player) ~= data then
		warn(`[BetaService] {player.Name} left before Beta Tester #{number} was saved on them`)
		return
	end
	data.Beta = number
	player:SetAttribute(BetaTag.Attribute, number)
	DataService.MarkChanged(player)
	if ready[player] then
		celebrate(player, number)
	else
		toCelebrate[player] = number
	end
end

local function onDataLoaded(player: Player, data: DataService.Data)
	if data.Beta > 0 then
		player:SetAttribute(BetaTag.Attribute, data.Beta)
	else
		give(player, data)
	end
end

function BetaService.Start()
	DataService.OnDataLoaded(onDataLoaded)
	Remotes.Ready.OnServerEvent:Connect(function(player)
		ready[player] = true
		local number = toCelebrate[player]
		if number then
			toCelebrate[player] = nil
			celebrate(player, number)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		asking[player] = nil
		ready[player] = nil
		toCelebrate[player] = nil
	end)
end

return BetaService
