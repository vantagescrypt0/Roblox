--!strict
-- Every item in the game. Placeholder names and prices; tune freely.

export type Item = {
	Name: string,
	SellPrice: number, -- coins per item at the sell stand; 0 = can't sell
	BuyPrice: number?, -- coins to buy one at the stand; nil = not for sale
}

local Items: { [string]: Item } = {
	-- Island resources
	Wood = { Name = "Wood", SellPrice = 1 },
	Stone = { Name = "Stone", SellPrice = 1 },

	-- Crops and seeds
	WheatSeeds = { Name = "Wheat Seeds", SellPrice = 0, BuyPrice = 2 },
	Wheat = { Name = "Wheat", SellPrice = 3 },
	CarrotSeeds = { Name = "Carrot Seeds", SellPrice = 0, BuyPrice = 6 },
	Carrot = { Name = "Carrot", SellPrice = 8 },
	PotatoSeeds = { Name = "Potato Seeds", SellPrice = 0, BuyPrice = 15 },
	Potato = { Name = "Potato", SellPrice = 20 },
	-- Warzone-only seeds (found in chests, never sold)
	GlowberrySeeds = { Name = "Glowberry Seeds", SellPrice = 0 },
	Glowberry = { Name = "Glowberry", SellPrice = 60 },

	-- Warzone materials
	Scrap = { Name = "Scrap", SellPrice = 0 },
	Crystal = { Name = "Crystal", SellPrice = 0 },

	-- Weapons (crafted at the workbench)
	WoodenSword = { Name = "Wooden Sword", SellPrice = 0 },
	StoneSword = { Name = "Stone Sword", SellPrice = 0 },
	CrystalSword = { Name = "Crystal Sword", SellPrice = 0 },
}

return table.freeze(Items)
