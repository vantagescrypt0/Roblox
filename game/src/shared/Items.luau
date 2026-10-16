--!strict
-- Every item in the game. Placeholder names and prices; tune freely.

export type Item = {
	Name: string,
	Icon: string, -- emoji shown in the UI
	SellPrice: number, -- coins per item at the market; 0 = can't sell
	BuyPrice: number?, -- coins to buy one at the market; nil = not for sale
}

local Items: { [string]: Item } = {
	-- Island resources
	Wood = { Name = "Wood", Icon = "🌲", SellPrice = 1 },
	Stone = { Name = "Stone", Icon = "⛰️", SellPrice = 1 },

	-- Crops and seeds
	WheatSeeds = { Name = "Wheat Seeds", Icon = "🌱", SellPrice = 0, BuyPrice = 2 },
	Wheat = { Name = "Wheat", Icon = "🌾", SellPrice = 3 },
	CarrotSeeds = { Name = "Carrot Seeds", Icon = "🌱", SellPrice = 0, BuyPrice = 6 },
	Carrot = { Name = "Carrot", Icon = "🥕", SellPrice = 8 },
	PotatoSeeds = { Name = "Potato Seeds", Icon = "🌱", SellPrice = 0, BuyPrice = 15 },
	Potato = { Name = "Potato", Icon = "🥔", SellPrice = 20 },
	-- Warzone-only seeds (found in chests, never sold)
	GlowberrySeeds = { Name = "Glowberry Seeds", Icon = "✨", SellPrice = 0 },
	Glowberry = { Name = "Glowberry", Icon = "🍇", SellPrice = 60 },

	-- Warzone materials
	Scrap = { Name = "Scrap", Icon = "⚙️", SellPrice = 0 },
	Crystal = { Name = "Crystal", Icon = "💎", SellPrice = 0 },

	-- Weapons (crafted at the workbench)
	WoodenSword = { Name = "Wooden Sword", Icon = "🗡️", SellPrice = 0 },
	StoneSword = { Name = "Stone Sword", Icon = "🗡️", SellPrice = 0 },
	CrystalSword = { Name = "Crystal Sword", Icon = "🗡️", SellPrice = 0 },
}

return table.freeze(Items)
