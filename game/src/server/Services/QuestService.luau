--!strict
-- Tracks the Challenges board: the beginner chain (Quests.luau) and every other group's
-- chain (Boards.luau). Each group has one current challenge at a time. Other services call
-- QuestService.Record when the player does something, and it counts toward every group whose
-- current challenge asks for that; "reach" challenges are checked whenever data changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boards = require(ReplicatedStorage.Shared.Boards)
local Items = require(ReplicatedStorage.Shared.Items)
local Quests = require(ReplicatedStorage.Shared.Quests)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local StateService = require(script.Parent.StateService)

local QuestService = {}

type BoardData = { Done: { [string]: boolean }, Current: string, Progress: number }

local function currentQuest(data: DataService.Data): Quests.Quest?
	return Quests[data.Quest.Index]
end

local function giveReward(player: Player, reward: Quests.Reward)
	local parts = {}
	if reward.Coins then
		InventoryService.AddCoins(player, reward.Coins)
		table.insert(parts, `{reward.Coins} coins`)
	end
	if reward.Items then
		for itemId, count in reward.Items do
			InventoryService.Add(player, itemId, count)
			table.insert(parts, `{count} {Items[itemId].Name}`)
		end
	end
	if reward.XP then
		table.insert(parts, `{reward.XP} XP`)
	end
	if #parts > 0 then
		StateService.Notify(player, `Reward: {table.concat(parts, ", ")}`, "good")
	end
	-- XP last so a level-up message shows after the reward
	if reward.XP then
		ProgressionService.AddPlayerXP(player, reward.XP)
	end
end

local function complete(player: Player, data: DataService.Data, quest: Quests.Quest)
	data.Quest.Index += 1
	data.Quest.Progress = 0
	StateService.Notify(player, `Quest complete: {quest.Text}`, "level")
	giveReward(player, quest.Reward)
	if data.Quest.Index > #Quests then
		StateService.Notify(player, "Beginner challenges done! Pick a group to track on the Challenges board", "level")
	end
	DataService.MarkChanged(player)
end

-- The groups past Beginner that can be played now
local function playable(): { Boards.Board }
	local list = {}
	for _, board in Boards.List do
		if board.Id ~= "Beginner" and not board.Soon then
			table.insert(list, board)
		end
	end
	return list
end
local PLAYABLE = playable()

-- A group's current challenge and its saved progress. Progress starts over when the
-- current challenge isn't the one it was counted for (a challenge was added before it).
local function boardCurrent(data: DataService.Data, board: Boards.Board): (Boards.Challenge?, BoardData)
	local entry = data.Boards[board.Id]
	if not entry then
		entry = { Done = {}, Current = "", Progress = 0 }
		data.Boards[board.Id] = entry
	end
	local challenge = board.Challenges[Boards.CurrentIndex(board, entry.Done)]
	local id = if challenge then challenge.Id or "" else ""
	if entry.Current ~= id then
		entry.Current = id
		entry.Progress = 0
	end
	return challenge, entry
end

local function completeBoard(player: Player, board: Boards.Board, challenge: Boards.Challenge, entry: BoardData)
	entry.Done[challenge.Id :: string] = true
	entry.Progress = 0
	StateService.Notify(player, `{board.Name} challenge complete: {challenge.Text}`, "level")
	giveReward(player, challenge.Reward)
	DataService.MarkChanged(player)
end

-- Counts an action toward the current challenges (e.g. Record(player, "Harvest"))
function QuestService.Record(player: Player, event: string, amount: number?)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local quest = currentQuest(data)
	if quest and quest.Event == event then
		data.Quest.Progress += amount or 1
		if data.Quest.Progress >= quest.Target then
			complete(player, data, quest)
		else
			DataService.MarkChanged(player)
		end
	end
	for _, board in PLAYABLE do
		local challenge, entry = boardCurrent(data, board)
		if challenge and challenge.Event == event then
			entry.Progress += amount or 1
			if entry.Progress >= challenge.Target then
				completeBoard(player, board, challenge, entry)
			else
				DataService.MarkChanged(player)
			end
		end
	end
end

-- The value a "reach" challenge checks (nil for every other kind)
local function reachValue(data: DataService.Data, event: string): number?
	if event == "ReachLevel" then
		return data.Level
	elseif event == "ReachIsland" then
		return data.Island.Tier
	end
	local skill = string.match(event, "^Reach:(%a+)$")
	local skills = data.Skills :: any
	if skill and skills[skill] then
		return skills[skill].Level
	end
	return nil
end

-- "Reach" challenges track a value instead of counting actions
local function checkReach(player: Player, data: DataService.Data)
	local quest = currentQuest(data)
	local value = if quest then reachValue(data, quest.Event) else nil
	if quest and value and value ~= data.Quest.Progress then
		data.Quest.Progress = math.min(value, quest.Target)
		if value >= quest.Target then
			complete(player, data, quest)
		else
			DataService.MarkChanged(player)
		end
	end
	for _, board in PLAYABLE do
		-- Several in a row can already be reached (e.g. after a long break)
		for _ = 1, #board.Challenges do
			local challenge, entry = boardCurrent(data, board)
			local reached = if challenge then reachValue(data, challenge.Event) else nil
			if not challenge or not reached then
				break
			elseif reached >= challenge.Target then
				completeBoard(player, board, challenge, entry)
			else
				if reached ~= entry.Progress then
					entry.Progress = reached
					DataService.MarkChanged(player)
				end
				break
			end
		end
	end
end

-- Shows a group in the quest tracker
local function onTrack(player: Player, boardId: unknown)
	local data = DataService.GetData(player)
	local board = if type(boardId) == "string" then Boards.ById[boardId] else nil
	if not data or not board or board.Soon or data.Tracked == board.Id then
		return
	end
	data.Tracked = board.Id
	DataService.MarkChanged(player)
end

function QuestService.Start()
	DataService.OnDataLoaded(checkReach)
	DataService.OnChanged(checkReach)
	Remotes.TrackBoard.OnServerEvent:Connect(onTrack)
end

return QuestService
