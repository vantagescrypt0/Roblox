--!strict
-- Crafting recipes, Minecraft-style:
--   Wood -> Planks -> Sticks -> wooden tools -> mine Stone -> stone tools
--   Stone -> Furnace; mine Coal + Raw Iron -> smelt Iron Ingots -> iron tools
--   Raw Gold (deep in the Mining World) + Coal -> Gold Ingots, worth a lot in Town
-- Crystal (from the Warzone) makes the best tools.
-- Station says where a recipe is made: at the Crafting Table or in a Furnace.
--
-- Requires: skill levels you need to make it (Skills.luau), e.g. an Iron Pickaxe needs
-- Crafting 3 and Mining 4. Everything the beginner quests ask for has no requirement.
-- CraftingXP: Crafting skill XP for making it once: 1.5x the skill XP its raw materials gave
-- (tools/balance.py), so smelting everything you mine takes Crafting to 99 in ~30 hours.

local Tools = require(script.Parent.Tools)

export type Station = "CraftingTable" | "Furnace"

export type Recipe = {
	Id: string,
	Output: string, -- item id
	Amount: number,
	Inputs: { [string]: number }, -- item id -> count
	Requires: { [string]: number }, -- skill id -> level
	CraftingXP: number,
	Station: Station,
}

local Recipes: { Recipe } = {
	{
		Id = "Planks",
		Output = "Planks",
		Amount = 4,
		Inputs = { Wood = 1 },
		Requires = {},
		CraftingXP = 75,
		Station = "CraftingTable",
	},
	{
		Id = "Sticks",
		Output = "Sticks",
		Amount = 4,
		Inputs = { Planks = 2 },
		Requires = {},
		CraftingXP = 40,
		Station = "CraftingTable",
	},
	{
		Id = "Furnace",
		Output = "Furnace",
		Amount = 1,
		Inputs = { Stone = 8 },
		Requires = {},
		CraftingXP = 360,
		Station = "CraftingTable",
	},
	{
		Id = "IronIngot",
		Output = "IronIngot",
		Amount = 1,
		Inputs = { RawIron = 1, Coal = 1 },
		Requires = {},
		CraftingXP = 140,
		Station = "Furnace",
	},
	{
		Id = "GoldIngot",
		Output = "GoldIngot",
		Amount = 1,
		Inputs = { RawGold = 1, Coal = 1 },
		Requires = {},
		CraftingXP = 195,
		Station = "Furnace",
	},
}

-- Head material per tier and how much of it each tool kind takes (like Minecraft)
local MATERIALS = { "Planks", "Stone", "IronIngot", "Crystal" }
local COST = {
	Pickaxe = { Head = 3, Sticks = 2 },
	Axe = { Head = 3, Sticks = 2 },
	Shovel = { Head = 1, Sticks = 2 },
	Hoe = { Head = 2, Sticks = 2 },
	Sword = { Head = 2, Sticks = 1 },
}
-- The skill each tool kind trains. Each tier needs a Crafting level plus a level in that
-- skill (per tier: Wooden, Stone, Iron, Crystal). Wooden and Stone pickaxes, axes, shovels
-- and swords are free so the beginner quests always work; hoes follow Farming's pace.
local KIND_SKILL = { Pickaxe = "Mining", Shovel = "Mining", Axe = "Woodcutting", Hoe = "Farming", Sword = "Combat" }
local CRAFTING_LEVELS = { 0, 0, 3, 8 }
local SKILL_LEVELS: { [string]: { number } } = {
	Default = { 0, 0, 4, 8 },
	Hoe = { 0, 3, 6, 12 },
}
-- Crafting XP for a tool: each head piece by its material, plus each stick
local MATERIAL_XP = { Planks = 19, Stone = 45, IronIngot = 140, Crystal = 540 }
local STICK_XP = 9
-- Combat XP only comes from the Warzone, so swords need it only at the Crystal tier
-- (Crystal comes from the Warzone too)
local COMBAT_FROM_TIER = 4

for _, tool in Tools.List do
	local cost = COST[tool.Kind]
	local skill = KIND_SKILL[tool.Kind]
	local skillLevel = (SKILL_LEVELS[tool.Kind] or SKILL_LEVELS.Default)[tool.Tier]
	local requires = {}
	if CRAFTING_LEVELS[tool.Tier] > 0 then
		requires.Crafting = CRAFTING_LEVELS[tool.Tier]
	end
	if skillLevel > 0 and (skill ~= "Combat" or tool.Tier >= COMBAT_FROM_TIER) then
		requires[skill] = skillLevel
	end
	table.insert(Recipes, {
		Id = tool.Item,
		Output = tool.Item,
		Amount = 1,
		Inputs = { [MATERIALS[tool.Tier]] = cost.Head, Sticks = cost.Sticks },
		Requires = requires,
		CraftingXP = MATERIAL_XP[MATERIALS[tool.Tier]] * cost.Head + STICK_XP * cost.Sticks,
		Station = "CraftingTable",
	})
end

local byId: { [string]: Recipe } = {}
for _, recipe in Recipes do
	byId[recipe.Id] = recipe
end

return table.freeze({
	List = table.freeze(Recipes),
	ById = table.freeze(byId),
})
