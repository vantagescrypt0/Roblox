--!strict
-- XP curves for player level (1-50, resets each season) and skill levels.

local Leveling = {}

Leveling.MaxPlayerLevel = 50
Leveling.MaxSkillLevel = 99
-- Player level needed to enter the Warzone
Leveling.WarzoneLevel = 10

-- XP needed to go from `level` to `level + 1`
function Leveling.XPToNext(level: number): number
	return math.floor(40 * level ^ 1.35)
end

-- Chance of a double harvest from a gathering skill (Farming, Mining, Woodcutting):
-- +1% per level above 1
function Leveling.BonusChance(skillLevel: number): number
	return math.clamp((skillLevel - 1) * 0.01, 0, 0.75)
end

-- How many farm plots you can make yourself with a hoe (on top of your island's own):
-- 2, plus one more every 3 Farming levels
function Leveling.TilledPlots(farmingLevel: number): number
	return math.min(2 + farmingLevel // 3, 30)
end

return table.freeze(Leveling)
