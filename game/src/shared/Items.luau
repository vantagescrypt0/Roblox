--!strict
-- Every item in the game. Placeholder names and prices; tune freely.
-- Items with a Block can be placed as that block (see Blocks.luau).

export type Item = {
	Name: string,
	Icon: string, -- emoji shown in the UI (blocks show a 3D block instead)
	SellPrice: number, -- coins per item at the market; 0 = can't sell
	BuyPrice: number?, -- coins to buy one at the market; nil = not for sale
	Block: string?, -- block type this item places
}

local Items: { [string]: Item } = {
	-- Blocks
	Grass = { Name = "Grass Block", Icon = "🟩", SellPrice = 0, Block = "Grass" },
	Dirt = { Name = "Dirt", Icon = "🟫", SellPrice = 0, Block = "Dirt" },
	Wood = { Name = "Wood", Icon = "🌲", SellPrice = 1, Block = "Wood" },
	Planks = { Name = "Planks", Icon = "🟧", SellPrice = 0, Block = "Planks" },
	Stone = { Name = "Stone", Icon = "⛰️", SellPrice = 1, Block = "Stone" },

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

	-- Weapons (crafted at the crafting table)
	WoodenSword = { Name = "Wooden Sword", Icon = "🗡️", SellPrice = 0 },
	StoneSword = { Name = "Stone Sword", Icon = "🗡️", SellPrice = 0 },
	CrystalSword = { Name = "Crystal Sword", Icon = "🗡️", SellPrice = 0 },
}

return table.freeze(Items)
