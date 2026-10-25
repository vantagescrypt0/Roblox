--!strict
-- The skills you level up by doing things (see the vault note "Skills & Levels"). Each has
-- its own level (1-99), next to your player level (1-50, resets each season):
--   Farming      harvest crops                    better seeds, hoes later
--   Mining       mine stone and ore               pickaxes and shovels
--   Woodcutting  chop trees                       axes
--   Crafting     craft and smelt anything         every advanced recipe
--   Combat       defeat monsters (PvE)            swords, tougher monsters
-- Recipes say which skill levels they need (Recipes.luau). Farming, Mining and Woodcutting
-- also give a chance of a double harvest that grows with your level (Leveling.BonusChance).

export type Skill = {
	Id: string,
	Name: string,
	Icon: string, -- item (or block) whose picture stands for the skill
	Trains: string, -- how you earn its XP
	Bonus: boolean, -- gives a chance of a double harvest
}

export type Need = { Skill: Skill, Level: number }

local List: { Skill } = {
	{ Id = "Farming", Name = "Farming", Icon = "Wheat", Trains = "Harvest ripe crops", Bonus = true },
	{
		Id = "Mining",
		Name = "Mining",
		Icon = "IronPickaxe",
		Trains = "Mine boulders and ore with a pickaxe",
		Bonus = true,
	},
	{ Id = "Woodcutting", Name = "Woodcutting", Icon = "IronAxe", Trains = "Chop trees", Bonus = true },
	{
		Id = "Crafting",
		Name = "Crafting",
		Icon = "CraftingTable",
		Trains = "Craft and smelt anything",
		Bonus = false,
	},
	{ Id = "Combat", Name = "Combat", Icon = "IronSword", Trains = "Defeat monsters in the Warzone", Bonus = false },
}

local byId: { [string]: Skill } = {}
for _, skill in List do
	byId[skill.Id] = skill
end

local Skills = {
	List = table.freeze(List),
	ById = table.freeze(byId),
}

-- Every requirement in `needs` (skill id -> level), in skill order, with whether
-- `levelOf` meets it
function Skills.Check(needs: { [string]: number }, levelOf: (skillId: string) -> number): ({ Need }, boolean)
	local list: { Need } = {}
	local ok = true
	for _, skill in List do
		local level = needs[skill.Id]
		if level then
			table.insert(list, { Skill = skill, Level = level })
			if levelOf(skill.Id) < level then
				ok = false
			end
		end
	end
	return list, ok
end

-- "Crafting 3 and Mining 4" for the requirements `levelOf` doesn't meet yet
function Skills.Describe(needs: { [string]: number }, levelOf: (skillId: string) -> number): string
	local parts = {}
	for _, need in (Skills.Check(needs, levelOf)) do
		if levelOf(need.Skill.Id) < need.Level then
			table.insert(parts, `{need.Skill.Name} {need.Level}`)
		end
	end
	if #parts <= 1 then
		return parts[1] or ""
	end
	return `{table.concat(parts, ", ", 1, #parts - 1)} and {parts[#parts]}`
end

return table.freeze(Skills)
