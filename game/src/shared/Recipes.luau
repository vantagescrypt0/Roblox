--!strict
-- Crafting recipes, Minecraft-style:
--   Wood -> Planks -> Sticks -> wooden tools -> mine Stone -> stone tools
--   Stone -> Furnace; mine Coal + Raw Iron -> smelt Iron Ingots -> iron tools
-- Crystal (from the Warzone) makes the best tools.
-- Station says where a recipe is made: at the Crafting Table or in a Furnace.
--
-- Requires: skill levels you need to make it (Skills.luau), e.g. an Iron Pickaxe needs
-- Crafting 3 and Mining 4. Everything the beginner quests ask for has no requirement.
-- CraftingXP: Crafting skill XP for making it once.

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
		CraftingXP = 4,
		Station = "CraftingTable",
	},
	{
		Id = "Sticks",
		Output = "Sticks",
		Amount = 4,
		Inputs = { Planks = 2 },
		Requires = {},
		CraftingXP = 4,
		Station = "CraftingTable",
	},
	{
		Id = "Furnace",
		Output = "Furnace",
		Amount = 1,
		Inputs = { Stone = 8 },
		Requires = {},
		CraftingXP = 25,
		Station = "CraftingTable",
	},
	{
		Id = "IronIngot",
		Output = "IronIngot",
		Amount = 1,
		Inputs = { RawIron = 1, Coal = 1 },
		Requires = {},
		CraftingXP = 10,
		Station = "Furnace",
	},
}

-- Head material per tier and how much of it each tool kind takes (like Minecraft)
local MATERIALS = { "Planks", "Stone", "IronIngot", "Crystal" }
local COST = {
	Pickaxe = { Head = 3, Sticks = 2 },
	Axe = { Head = 3, Sticks = 2 },
	Shovel = { Head = 1, Sticks = 2 },
	Sword = { Head = 2, Sticks = 1 },
}
-- The skill each tool kind trains, and the levels each tier needs: Crafting, plus that
-- skill. Wooden and Stone tools are free so the beginner quests always work.
local KIND_SKILL = { Pickaxe = "Mining", Shovel = "Mining", Axe = "Woodcutting", Sword = "Combat" }
local TIER_NEEDS = {
	{ Crafting = 0, Skill = 0, XP = 10 }, -- Wooden
	{ Crafting = 0, Skill = 0, XP = 20 }, -- Stone
	{ Crafting = 3, Skill = 4, XP = 50 }, -- Iron
	{ Crafting = 8, Skill = 8, XP = 120 }, -- Crystal
}
-- Combat XP only comes from the Warzone, so swords need it only at the Crystal tier
-- (Crystal comes from the Warzone too)
local COMBAT_FROM_TIER = 4

for _, tool in Tools.List do
	local cost = COST[tool.Kind]
	local tier = TIER_NEEDS[tool.Tier]
	local skill = KIND_SKILL[tool.Kind]
	local requires = {}
	if tier.Crafting > 0 then
		requires.Crafting = tier.Crafting
	end
	if tier.Skill > 0 and (skill ~= "Combat" or tool.Tier >= COMBAT_FROM_TIER) then
		requires[skill] = tier.Skill
	end
	table.insert(Recipes, {
		Id = tool.Item,
		Output = tool.Item,
		Amount = 1,
		Inputs = { [MATERIALS[tool.Tier]] = cost.Head, Sticks = cost.Sticks },
		Requires = requires,
		CraftingXP = tier.XP,
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
