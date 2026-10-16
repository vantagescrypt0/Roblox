--!strict
-- Tracks the beginner quest chain. Other services call QuestService.Record when the
-- player does something; "reach" quests are checked whenever data changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Quests = require(ReplicatedStorage.Shared.Quests)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local StateService = require(script.Parent.StateService)

local QuestService = {}

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
		StateService.Notify(player, "Tutorial finished! The Warzone awaits.", "level")
	end
	DataService.MarkChanged(player)
end

-- Counts an action toward the current quest (e.g. Record(player, "Harvest"))
function QuestService.Record(player: Player, event: string, amount: number?)
	local data = DataService.GetData(player)
	local quest = data and currentQuest(data)
	if not data or not quest or quest.Event ~= event then
		return
	end
	data.Quest.Progress += amount or 1
	if data.Quest.Progress >= quest.Target then
		complete(player, data, quest)
	else
		DataService.MarkChanged(player)
	end
end

-- "Reach" quests track a value instead of counting actions
local function checkReach(player: Player, data: DataService.Data)
	local quest = currentQuest(data)
	if not quest then
		return
	end
	local value
	if quest.Event == "ReachLevel" then
		value = data.Level
	elseif quest.Event == "ReachFarming" then
		value = data.Skills.Farming.Level
	else
		return
	end
	if value ~= data.Quest.Progress then
		data.Quest.Progress = math.min(value, quest.Target)
		if value >= quest.Target then
			complete(player, data, quest)
		else
			DataService.MarkChanged(player)
		end
	end
end

function QuestService.Start()
	DataService.OnDataLoaded(checkReach)
	DataService.OnChanged(checkReach)
end

return QuestService
