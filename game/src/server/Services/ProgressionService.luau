--!strict
-- Player level (1-50, seasonal) and skill levels (Skills.luau: Farming, Mining,
-- Woodcutting, Crafting, Combat). A skill level-up that unlocks recipes says which.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Skills = require(ReplicatedStorage.Shared.Skills)
local DataService = require(script.Parent.DataService)
local GearService = require(script.Parent.GearService)
local StateService = require(script.Parent.StateService)

local ProgressionService = {}

-- Names of the recipes that reaching `toLevel` in a skill made craftable (every other
-- skill they need is already high enough)
local function unlockedBy(data: DataService.Data, skillId: string, fromLevel: number, toLevel: number): { string }
	local function levelOf(id: string): number
		local skill = (data.Skills :: any)[id]
		return if skill then skill.Level else 1
	end
	local names = {}
	for _, recipe in Recipes.List do
		local need = recipe.Requires[skillId]
		if need and need > fromLevel and need <= toLevel then
			local _, ok = Skills.Check(recipe.Requires, levelOf)
			if ok then
				table.insert(names, Items[recipe.Output].Name)
			end
		end
	end
	return names
end

function ProgressionService.AddPlayerXP(player: Player, amount: number)
	local data = DataService.GetData(player)
	if not data or amount <= 0 or data.Level >= Leveling.MaxPlayerLevel then
		return
	end

	data.XP += amount
	while data.Level < Leveling.MaxPlayerLevel and data.XP >= Leveling.PlayerXPToNext(data.Level) do
		data.XP -= Leveling.PlayerXPToNext(data.Level)
		data.Level += 1
		StateService.Notify(player, `Level {data.Level}`, "levelup")
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

	local before = skill.Level
	local info = Skills.ById[skillName]
	-- A pet of this skill gives more XP
	skill.XP += math.floor(amount * (1 + GearService.XPBonus(player, skillName)) + 0.5)
	while skill.Level < Leveling.MaxSkillLevel and skill.XP >= Leveling.SkillXPToNext(skill.Level) do
		skill.XP -= Leveling.SkillXPToNext(skill.Level)
		skill.Level += 1
		StateService.Notify(player, `{if info then info.Name else skillName} level {skill.Level}!`, "level")
	end
	if skill.Level > before and data then
		local names = unlockedBy(data, skillName, before, skill.Level)
		if #names > 0 then
			StateService.Notify(player, `You can now craft: {table.concat(names, ", ")}`, "level")
		end
	end
	DataService.MarkChanged(player)
end

function ProgressionService.GetSkillLevel(player: Player, skillName: string): number
	local data = DataService.GetData(player)
	local skill = data and (data.Skills :: any)[skillName]
	return if skill then skill.Level else 1
end

return ProgressionService
