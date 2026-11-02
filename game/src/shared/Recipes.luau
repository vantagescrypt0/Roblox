--!strict
-- Crafting recipes. Every tool past Wooden is put together from three parts, each made
-- first ([[Crafting Proposal]]), so a good tool needs all three Grinding Worlds:
--   Head     from Mining: Stone, then Iron Plates (hammered from ingots at the Anvil)
--   Handle   from Woodcutting: Sticks, then Sturdy Handles (sticks bound with iron)
--   Binding  from Farming: Twine (Wheat), then Rope (Twine)
-- The ladder:
--   Wood -> Planks -> Sticks -> wooden tools (just head + sticks, so the tutorial starts easy)
--   Stone + Sticks + Twine -> stone tools
--   Stone -> Furnace; Coal + Raw Iron -> Iron Ingots; ingots + stone -> Anvil
--   Iron Plates + a Sturdy Handle + Rope -> iron tools, at the Anvil
--   Raw Gold (deep in the Mining World) + Coal -> Gold Ingots, worth a lot in Town
--   The deep cave: Silver Ingots -> the Gem Bench; gems refined there (Amethyst + Silver,
--   Sapphire + Gold) + handles of Birch / Spruce bound with metal plates + Rope -> the
--   Amethyst and Sapphire tiers, at the Anvil
--   Slivers (Slivers.luau) -> island nodes
-- Crystal (from the Warzone) is a side tier on the iron parts for now.
-- Station says where a recipe is made: at the Crafting Table, in a Furnace, on an Anvil or
-- at the Gem Bench.
--
-- Requires: skill levels you need to make it (Skills.luau), e.g. an Iron Pickaxe needs
-- Crafting 3 and Mining 4. Everything the beginner quests ask for has no requirement.
-- CraftingXP: Crafting skill XP for making it once: 1.5x the skill XP of the raw materials
-- in it (tools/balance.py), so smelting everything you mine takes Crafting to 99 in ~30
-- hours, and every refining step on the way to a tool gives XP too.

local Slivers = require(script.Parent.Slivers)
local Tools = require(script.Parent.Tools)

export type Station = "CraftingTable" | "Furnace" | "Anvil" | "GemBench"

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
	-- Tool parts
	{
		Id = "Twine",
		Output = "Twine",
		Amount = 1,
		Inputs = { Wheat = 4 },
		Requires = {},
		CraftingXP = 150,
		Station = "CraftingTable",
	},
	{
		Id = "Rope",
		Output = "Rope",
		Amount = 1,
		Inputs = { Twine = 3 },
		Requires = {},
		CraftingXP = 450,
		Station = "CraftingTable",
	},
	{
		Id = "Anvil",
		Output = "Anvil",
		Amount = 1,
		Inputs = { IronIngot = 3, Stone = 4 },
		Requires = { Crafting = 3 },
		CraftingXP = 600,
		Station = "CraftingTable",
	},
	{
		Id = "IronPlate",
		Output = "IronPlate",
		Amount = 1,
		Inputs = { IronIngot = 2 },
		Requires = {},
		CraftingXP = 280,
		Station = "Anvil",
	},
	{
		Id = "SturdyHandle",
		Output = "SturdyHandle",
		Amount = 1,
		Inputs = { Sticks = 2, IronIngot = 1 },
		Requires = {},
		CraftingXP = 160,
		Station = "Anvil",
	},
	-- The deep cave's ores ([[Mining Phase Plan]])
	{
		Id = "SilverIngot",
		Output = "SilverIngot",
		Amount = 1,
		Inputs = { RawSilver = 1, Coal = 1 },
		Requires = {},
		CraftingXP = 210,
		Station = "Furnace",
	},
	{
		Id = "SilverPlate",
		Output = "SilverPlate",
		Amount = 1,
		Inputs = { SilverIngot = 2 },
		Requires = {},
		CraftingXP = 420,
		Station = "Anvil",
	},
	{
		Id = "GemBench",
		Output = "GemBench",
		Amount = 1,
		Inputs = { SilverIngot = 4, Planks = 4, Stone = 2 },
		Requires = { Crafting = 15 },
		CraftingXP = 1005,
		Station = "CraftingTable",
	},
	{
		Id = "RefinedAmethyst",
		Output = "RefinedAmethyst",
		Amount = 1,
		Inputs = { Amethyst = 2, SilverIngot = 1 },
		Requires = {},
		CraftingXP = 540,
		Station = "GemBench",
	},
	{
		Id = "RefinedSapphire",
		Output = "RefinedSapphire",
		Amount = 1,
		Inputs = { Sapphire = 2, GoldIngot = 1 },
		Requires = {},
		CraftingXP = 555,
		Station = "GemBench",
	},
	-- Handles from the better woods, bound with metal
	{
		Id = "BirchHandle",
		Output = "BirchHandle",
		Amount = 1,
		Inputs = { BirchWood = 1, IronPlate = 1 },
		Requires = {},
		CraftingXP = 380,
		Station = "Anvil",
	},
	{
		Id = "SpruceHandle",
		Output = "SpruceHandle",
		Amount = 1,
		Inputs = { SpruceWood = 1, SilverPlate = 1 },
		Requires = {},
		CraftingXP = 550,
		Station = "Anvil",
	},
}

-- Nodes for your island, from slivers (Slivers.luau): 50 Crafting XP a sliver
for _, sliver in Slivers.List do
	table.insert(Recipes, {
		Id = sliver.Node,
		Output = sliver.Node,
		Amount = 1,
		Inputs = { [sliver.Item] = sliver.Need },
		Requires = {},
		CraftingXP = 50 * sliver.Need,
		Station = "CraftingTable",
	})
end

-- Each tier's parts, where it's put together and the Crafting level it needs. Head pieces
-- per tool kind are like Minecraft (3 for a pickaxe or axe, 2 for a hoe or sword, 1 for a
-- shovel); Sticks as a handle come in the old Minecraft counts, other handles and a
-- binding are one each. Ruby and Starsteel join with Sugarcane (Cane Rope) and Redwood.
type TierParts = { Head: string, Handle: string, Binding: string?, Station: Station, Crafting: number }
local TIERS: { [string]: TierParts } = {
	Wooden = { Head = "Planks", Handle = "Sticks", Station = "CraftingTable", Crafting = 0 },
	Stone = { Head = "Stone", Handle = "Sticks", Binding = "Twine", Station = "CraftingTable", Crafting = 0 },
	Iron = { Head = "IronPlate", Handle = "SturdyHandle", Binding = "Rope", Station = "Anvil", Crafting = 3 },
	Amethyst = { Head = "RefinedAmethyst", Handle = "BirchHandle", Binding = "Rope", Station = "Anvil", Crafting = 15 },
	Sapphire = { Head = "RefinedSapphire", Handle = "SpruceHandle", Binding = "Rope", Station = "Anvil", Crafting = 25 },
	-- The Warzone's side tier
	Crystal = { Head = "Crystal", Handle = "SturdyHandle", Binding = "Rope", Station = "Anvil", Crafting = 8 },
}
local COST = {
	Pickaxe = { Head = 3, Sticks = 2 },
	Axe = { Head = 3, Sticks = 2 },
	Shovel = { Head = 1, Sticks = 2 },
	Hoe = { Head = 2, Sticks = 2 },
	Sword = { Head = 2, Sticks = 1 },
}
-- The skill each tool kind trains. Each tier also needs a level in that skill: the gem
-- tiers the level of their ore. Wooden and Stone pickaxes, axes, shovels and swords are free
-- so the beginner quests always work; hoes follow Farming's pace.
local KIND_SKILL = { Pickaxe = "Mining", Shovel = "Mining", Axe = "Woodcutting", Hoe = "Farming", Sword = "Combat" }
local SKILL_LEVELS: { [string]: { [string]: number } } = {
	Default = { Wooden = 0, Stone = 0, Iron = 4, Amethyst = 35, Sapphire = 50, Crystal = 8 },
	Hoe = { Wooden = 0, Stone = 3, Iron = 6, Amethyst = 35, Sapphire = 50, Crystal = 12 },
}
-- Crafting XP for a tool: 1.5x the raw skill XP in each of its parts
local PART_XP = {
	Planks = 19,
	Stone = 45,
	IronPlate = 280,
	RefinedAmethyst = 540,
	RefinedSapphire = 555,
	Crystal = 540,
	Sticks = 9,
	SturdyHandle = 160,
	BirchHandle = 380,
	SpruceHandle = 550,
	Twine = 150,
	Rope = 450,
}
-- Combat XP only comes from the Warzone, so only Crystal swords (from the Warzone too) need it

for _, tool in Tools.List do
	local cost = COST[tool.Kind]
	local parts = TIERS[tool.TierName]
	local skill = KIND_SKILL[tool.Kind]
	local skillLevel = (SKILL_LEVELS[tool.Kind] or SKILL_LEVELS.Default)[tool.TierName]
	local requires = {}
	if parts.Crafting > 0 then
		requires.Crafting = parts.Crafting
	end
	if skillLevel > 0 and (skill ~= "Combat" or tool.TierName == "Crystal") then
		requires[skill] = skillLevel
	end
	local inputs = {
		[parts.Head] = cost.Head,
		[parts.Handle] = if parts.Handle == "Sticks" then cost.Sticks else 1,
	}
	if parts.Binding then
		inputs[parts.Binding] = 1
	end
	local xp = 0
	for itemId, count in inputs do
		xp += PART_XP[itemId] * count
	end
	table.insert(Recipes, {
		Id = tool.Item,
		Output = tool.Item,
		Amount = 1,
		Inputs = inputs,
		Requires = requires,
		CraftingXP = xp,
		Station = parts.Station,
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
