--!strict
-- What gathering each natural block is worth: skill XP and player XP. Level: the skill
-- level you need before you can gather it at all (the worlds' zone resources). Fitted by
-- tools/balance.py so a skill takes ~25 hours to 99 (see Leveling.luau). BlockService pays
-- it out; the skill menus (Challenges.luau) show it.

export type Gather = { Skill: string, XP: number, PlayerXP: number, Level: number? }

local Gathering: { [string]: Gather } = {
	Stone = { Skill = "Mining", XP = 30, PlayerXP = 10 },
	Cobblestone = { Skill = "Mining", XP = 30, PlayerXP = 10 },
	CoalOre = { Skill = "Mining", XP = 40, PlayerXP = 13 },
	IronOre = { Skill = "Mining", XP = 55, PlayerXP = 18 },
	GoldOre = { Skill = "Mining", XP = 90, PlayerXP = 30, Level = 10 },
	Wood = { Skill = "Woodcutting", XP = 50, PlayerXP = 17 },
	BirchWood = { Skill = "Woodcutting", XP = 65, PlayerXP = 22, Level = 10 },
	SpruceWood = { Skill = "Woodcutting", XP = 85, PlayerXP = 28, Level = 20 },
	CherryWood = { Skill = "Woodcutting", XP = 105, PlayerXP = 35, Level = 30 },
}

return table.freeze(Gathering)
