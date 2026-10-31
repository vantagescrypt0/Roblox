--!strict
-- Sends each player a snapshot of their data for the HUD, and pop-up messages.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boards = require(ReplicatedStorage.Shared.Boards)
local IslandTiers = require(ReplicatedStorage.Shared.IslandTiers)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local StateService = {}

-- Every Challenges board group: the current challenge's number (one past the end when
-- they're all done), progress on it, and which are done (one true/false per challenge)
local function boardsState(data: DataService.Data)
	local result = {}
	for _, board in Boards.List do
		local index, progress = 1, 0
		local done = {}
		if board.Id == "Beginner" then
			index, progress = data.Quest.Index, data.Quest.Progress
			for i = 1, #board.Challenges do
				done[i] = i < index
			end
		else
			local entry = data.Boards[board.Id]
			local finished = if entry then entry.Done else {}
			index = Boards.CurrentIndex(board, finished)
			local challenge = board.Challenges[index]
			if entry and challenge and entry.Current == challenge.Id then
				progress = entry.Progress
			end
			for i, each in board.Challenges do
				done[i] = each.Id ~= nil and finished[each.Id] == true
			end
		end
		result[board.Id] = { Index = index, Progress = progress, Done = done }
	end
	return result
end

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

	-- The quest tracker shows the tracked group's current challenge
	local boards = boardsState(data)
	local tracked = Boards.ById[data.Tracked] or Boards.ById.Beginner
	local trackedState = boards[tracked.Id]
	local quest = tracked.Challenges[trackedState.Index]

	local tier = math.clamp(data.Island.Tier, 1, #IslandTiers)

	return {
		Hotbar = table.clone(data.Hotbar),
		Wear = table.clone(data.Wear),
		Island = { Tier = tier, MaxTier = #IslandTiers },
		Quest = if quest
			then {
				Board = if tracked.Id == "Beginner" then "Quest" else tracked.Name,
				Number = trackedState.Index,
				Total = #tracked.Challenges,
				Text = quest.Text,
				Progress = trackedState.Progress,
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
		Boards = boards,
		Tracked = tracked.Id,
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
