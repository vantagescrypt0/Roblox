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

-- Bonus yield from your Farming level: +1% per level above 1 (chance for an extra item)
function Leveling.FarmingBonusChance(farmingLevel: number): number
	return math.clamp((farmingLevel - 1) * 0.01, 0, 0.75)
end

return table.freeze(Leveling)
