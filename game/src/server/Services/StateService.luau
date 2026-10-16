--!strict
-- Sends each player a snapshot of their data for the HUD, and pop-up messages.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local StateService = {}

local function snapshot(data: DataService.Data)
	local skills = {}
	for name, skill in data.Skills :: { [string]: { Level: number, XP: number } } do
		skills[name] = {
			Level = skill.Level,
			XP = skill.XP,
			XPToNext = Leveling.XPToNext(skill.Level),
		}
	end

	local items = {}
	for id, count in data.Items do
		if count > 0 then
			items[id] = count
		end
	end

	return {
		Coins = data.Coins,
		Level = data.Level,
		XP = data.XP,
		XPToNext = Leveling.XPToNext(data.Level),
		MaxLevel = Leveling.MaxPlayerLevel,
		WarzoneLevel = Leveling.WarzoneLevel,
		Season = data.Season,
		Skills = skills,
		Items = items,
	}
end

local function send(player: Player, data: DataService.Data)
	Remotes.State:FireClient(player, snapshot(data))
end

-- kind: "info" | "good" | "bad" | "level"
function StateService.Notify(player: Player, text: string, kind: string?)
	Remotes.Notify:FireClient(player, text, kind or "info")
end

function StateService.Start()
	DataService.OnDataLoaded(send)
	DataService.OnChanged(send)

	Remotes.Ready.OnServerEvent:Connect(function(player)
		local data = DataService.GetData(player)
		if data then
			send(player, data)
		end
	end)
end

return StateService
