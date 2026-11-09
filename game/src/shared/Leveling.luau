--!strict
-- XP curves for skill levels (1-99) and player level (1-50). Both reset each season.
-- Fitted by tools/balance.py to the targets (Decision Log, 2026-10-27): a skill reaches
-- level 10 after about an hour of steady play and 99 after about 25 hours; player level
-- reaches 5 after about an hour, 10 (the Warzone) after about 4 and 50 after about 80.
-- XP per action is in BlockService (GATHER), Crops.luau, Recipes.luau and Quests.luau;
-- re-run the model after changing any of them.

local Leveling = {}

Leveling.MaxPlayerLevel = 50
Leveling.MaxSkillLevel = 99
-- Player level needed to enter the Warzone
Leveling.WarzoneLevel = 10
-- Player level needed to trade with other players: past the beginner quests and a little
-- play, so brand-new players (and throwaway accounts) can't be talked into bad trades
Leveling.TradeLevel = 5

-- Who can go into the Warzone below that level, to test it (user ids): only the game's owner
local WARZONE_TESTERS = { [545120355] = true }

function Leveling.CanEnterWarzone(player: Player, level: number): boolean
	return level >= Leveling.WarzoneLevel or WARZONE_TESTERS[player.UserId] == true
end

-- XP a skill needs to go from `level` to `level + 1`: 2,460 at first, ~72,000 at 98
-- (4.1M from 1 to 99)
function Leveling.SkillXPToNext(level: number): number
	return math.round(2458.1 * level ^ 0.738 / 5) * 5
end

-- XP the player level needs to go from `level` to `level + 1`: 3,115 at first, ~165,000
-- at 49 (4.1M from 1 to 50)
function Leveling.PlayerXPToNext(level: number): number
	return math.round(3112.6 * level ^ 1.02 / 5) * 5
end

-- Chance of a double harvest from a gathering skill (Farming, Mining, Woodcutting):
-- +1% per level above 1
function Leveling.BonusChance(skillLevel: number): number
	return math.clamp((skillLevel - 1) * 0.01, 0, 0.75)
end

-- How many planted trees (saplings and grown trees) you can have on your island at once:
-- 3, plus one more every 3 Woodcutting levels. A felled tree frees its spot.
function Leveling.PlantedTrees(woodcuttingLevel: number): number
	return math.min(3 + woodcuttingLevel // 3, 30)
end

return table.freeze(Leveling)
