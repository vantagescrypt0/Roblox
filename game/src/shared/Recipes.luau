--!strict
-- Crafting table recipes, Minecraft-style:
--   Wood -> Planks -> Sticks -> wooden tools -> mine Stone -> stone tools
-- Crystal (from the Warzone) makes the best tools.

local Tools = require(script.Parent.Tools)

export type Recipe = {
	Id: string,
	Output: string, -- item id
	Amount: number,
	Inputs: { [string]: number }, -- item id -> count
	PlayerLevel: number,
}

local Recipes: { Recipe } = {
	{ Id = "Planks", Output = "Planks", Amount = 4, Inputs = { Wood = 1 }, PlayerLevel = 1 },
	{ Id = "Sticks", Output = "Sticks", Amount = 4, Inputs = { Planks = 2 }, PlayerLevel = 1 },
}

-- Head material per tier, and how much of it each tool kind needs (like Minecraft)
local MATERIALS = { "Planks", "Stone", "Crystal" }
local LEVELS = { 1, 1, 10 }
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
