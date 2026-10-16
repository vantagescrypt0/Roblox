--!strict
-- Player level (1-50, seasonal) and skill levels (Farming, Combat, ...).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Leveling = require(ReplicatedStorage.Shared.Leveling)
local DataService = require(script.Parent.DataService)
local StateService = require(script.Parent.StateService)

local ProgressionService = {}

function ProgressionService.AddPlayerXP(player: Player, amount: number)
	local data = DataService.GetData(player)
	if not data or amount <= 0 or data.Level >= Leveling.MaxPlayerLevel then
		return
	end

	data.XP += amount
	while data.Level < Leveling.MaxPlayerLevel and data.XP >= Leveling.XPToNext(data.Level) do
		data.XP -= Leveling.XPToNext(data.Level)
		data.Level += 1
		StateService.Notify(player, `Level up! You're now level {data.Level}`, "level")
		if data.Level == Leveling.WarzoneLevel then
			StateService.Notify(player, "The Warzone is now unlocked!", "level")
		end
	end
	if data.Level >= Leveling.MaxPlayerLevel then
		data.XP = 0
	end
	DataService.MarkChanged(player)
end

function ProgressionService.AddSkillXP(player: Player, skillName: string, amount: number)
	local data = DataService.GetData(player)
	local skill = data and (data.Skills :: any)[skillName]
	if not skill or amount <= 0 or skill.Level >= Leveling.MaxSkillLevel then
		return
	end

	skill.XP += amount
	while skill.Level < Leveling.MaxSkillLevel and skill.XP >= Leveling.XPToNext(skill.Level) do
		skill.XP -= Leveling.XPToNext(skill.Level)
		skill.Level += 1
		StateService.Notify(player, `{skillName} level {skill.Level}!`, "level")
	end
	DataService.MarkChanged(player)
end

function ProgressionService.GetSkillLevel(player: Player, skillName: string): number
	local data = DataService.GetData(player)
	local skill = data and (data.Skills :: any)[skillName]
	return if skill then skill.Level else 1
end

return ProgressionService
