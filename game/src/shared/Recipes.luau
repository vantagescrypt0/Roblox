--!strict
-- Crafting recipes, Minecraft-style:
--   Wood -> Planks -> Sticks -> wooden tools -> mine Stone -> stone tools
--   Stone -> Furnace; mine Coal + Raw Iron -> smelt Iron Ingots -> iron tools
-- Crystal (from the Warzone) makes the best tools.
-- Station says where a recipe is made: at the Crafting Table or in a Furnace.

local Tools = require(script.Parent.Tools)

export type Station = "CraftingTable" | "Furnace"

export type Recipe = {
	Id: string,
	Output: string, -- item id
	Amount: number,
	Inputs: { [string]: number }, -- item id -> count
	PlayerLevel: number,
	Station: Station,
}

local Recipes: { Recipe } = {
	{ Id = "Planks", Output = "Planks", Amount = 4, Inputs = { Wood = 1 }, PlayerLevel = 1, Station = "CraftingTable" },
	{
		Id = "Sticks",
		Output = "Sticks",
		Amount = 4,
		Inputs = { Planks = 2 },
		PlayerLevel = 1,
		Station = "CraftingTable",
	},
	{
		Id = "Furnace",
		Output = "Furnace",
		Amount = 1,
		Inputs = { Stone = 8 },
		PlayerLevel = 1,
		Station = "CraftingTable",
	},
	{
		Id = "IronIngot",
		Output = "IronIngot",
		Amount = 1,
		Inputs = { RawIron = 1, Coal = 1 },
		PlayerLevel = 1,
		Station = "Furnace",
	},
}

-- Head material per tier, the player level it needs, and how much of it each tool
-- kind takes (like Minecraft)
local MATERIALS = { "Planks", "Stone", "IronIngot", "Crystal" }
local LEVELS = { 1, 1, 5, 10 }
local COST = {
	Pickaxe = { Head = 3, Sticks = 2 },
	Axe = { Head = 3, Sticks = 2 },
	Shovel = { Head = 1, Sticks = 2 },
	Sword = { Head = 2, Sticks = 1 },
}
for _, tool in Tools.List do
	local cost = COST[tool.Kind]
	table.insert(Recipes, {
		Id = tool.Item,
		Output = tool.Item,
		Amount = 1,
		Inputs = { [MATERIALS[tool.Tier]] = cost.Head, Sticks = cost.Sticks },
		PlayerLevel = LEVELS[tool.Tier],
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
