--!strict
-- Sends each player a snapshot of their data for the HUD, and pop-up messages.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IslandTiers = require(ReplicatedStorage.Shared.IslandTiers)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Quests = require(ReplicatedStorage.Shared.Quests)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local StateService = {}

local function snapshot(data: DataService.Data)
	local skills = {}
	for name, skill in data.Skills :: { [string]: { Level: number, XP: number } } do
		skills[name] = {
			Level = skill.Level,
			XP = skill.XP,
			XPToNext = Leveling.SkillXPToNext(skill.Level),
		}
	end

	local items = {}
	for id, count in data.Items do
		if count > 0 then
			items[id] = count
		end
	end

	local bag = {}
	for id, count in data.Raid.Bag do
		if count > 0 then
			bag[id] = count
		end
	end

	local quest = Quests[data.Quest.Index]

	local tier = math.clamp(data.Island.Tier, 1, #IslandTiers)

	return {
		Hotbar = table.clone(data.Hotbar),
		Wear = table.clone(data.Wear),
		Island = { Tier = tier, MaxTier = #IslandTiers },
		Quest = if quest
			then {
				Number = data.Quest.Index,
				Total = #Quests,
				Text = quest.Text,
				Progress = data.Quest.Progress,
				Target = quest.Target,
				Highlight = quest.Highlight,
			}
			else nil,
		Raid = { Active = data.Raid.Active, Bag = bag },
		Coins = data.Coins,
		Level = data.Level,
		XP = data.XP,
		XPToNext = Leveling.PlayerXPToNext(data.Level),
		MaxLevel = Leveling.MaxPlayerLevel,
		WarzoneLevel = Leveling.WarzoneLevel,
		Season = data.Season,
		Skills = skills,
		Items = items,
		Inbox = data.Inbox.Mail,
		-- Which beginner challenge you're on (past the last one when they're all done)
		QuestIndex = data.Quest.Index,
		Equipped = table.clone(data.Equipped),
		Challenges = { Counts = table.clone(data.Challenges.Counts), Reached = table.clone(data.Challenges.Reached) },
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
