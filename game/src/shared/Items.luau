--!strict
-- Every item in the game. Placeholder names and prices; tune freely.

export type Item = {
	Name: string,
	SellPrice: number, -- coins per item at the sell stand; 0 = can't sell
	BuyPrice: number?, -- coins to buy one at the stand; nil = not for sale
}

local Items: { [string]: Item } = {
	Wood = { Name = "Wood", SellPrice = 1 },
	Stone = { Name = "Stone", SellPrice = 1 },

	WheatSeeds = { Name = "Wheat Seeds", SellPrice = 0, BuyPrice = 2 },
	Wheat = { Name = "Wheat", SellPrice = 3 },

	CarrotSeeds = { Name = "Carrot Seeds", SellPrice = 0, BuyPrice = 6 },
	Carrot = { Name = "Carrot", SellPrice = 8 },

	PotatoSeeds = { Name = "Potato Seeds", SellPrice = 0, BuyPrice = 15 },
	Potato = { Name = "Potato", SellPrice = 20 },
}

return table.freeze(Items)
