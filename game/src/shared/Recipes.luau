--!strict
-- Workbench recipes. Island resources make basic gear; Warzone materials make the best.

export type Recipe = {
	Id: string,
	Output: string, -- item id
	Amount: number,
	Inputs: { [string]: number }, -- item id -> count
	PlayerLevel: number,
}

local Recipes: { Recipe } = {
	{
		Id = "WoodenSword",
		Output = "WoodenSword",
		Amount = 1,
		Inputs = { Wood = 6 },
		PlayerLevel = 1,
	},
	{
		Id = "StoneSword",
		Output = "StoneSword",
		Amount = 1,
		Inputs = { Stone = 8, Wood = 3 },
		PlayerLevel = 3,
	},
	{
		Id = "CrystalSword",
		Output = "CrystalSword",
		Amount = 1,
		Inputs = { Crystal = 3, Scrap = 6, Wood = 2 },
		PlayerLevel = 10,
	},
}

local byId: { [string]: Recipe } = {}
for _, recipe in Recipes do
	byId[recipe.Id] = recipe
end

return table.freeze({
	List = table.freeze(Recipes),
	ById = table.freeze(byId),
})
