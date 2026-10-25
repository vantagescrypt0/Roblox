--!strict
-- Every item in the game. Items with a Block can be placed as that block (see Blocks.luau).
-- Tools (swords, pickaxes, axes, shovels) get their stats from Tools.luau.
-- Icons: pre-rendered pictures from the icon sheet (ItemArt.luau, made by art/scripts/items3d.py);
-- without one, block items show a 3D block and items with a Model (ReplicatedStorage.ItemModels)
-- show that model, and anything else its emoji.
--
-- Prices (see Economy.luau and the vault note "Economy & Values"):
--   Value      what the item is fairly worth between players, in coins. Set here for
--              gathered things (by how long they take to get); crafted items are worth
--              their inputs plus 10% and are worked out in Economy.luau.
--   SellPrice  what the Merchant pays: about half of Value, so trading is the better deal
--   BuyPrice   seeds at the Merchant. Crops regrow, so a seed is a one-off cost per plot.

local Tools = require(script.Parent.Tools)

export type Item = {
	Name: string,
	Icon: string, -- emoji fallback for the UI
	Value: number?, -- fair trade value in coins (nil = worked out from its recipe)
	SellPrice: number, -- coins per item at the market; 0 = can't sell
	BuyPrice: number?, -- coins to buy one at the market; nil = not for sale
	Block: string?, -- block type this item places
	Model: string?, -- 3D model in ReplicatedStorage.ItemModels (icons and holding)
}

local Items: { [string]: Item } = {
	-- Blocks
	Grass = { Name = "Grass Block", Icon = "🟩", Value = 1, SellPrice = 0, Block = "Grass" },
	Dirt = { Name = "Dirt", Icon = "🟫", Value = 1, SellPrice = 0, Block = "Dirt" },
	Wood = { Name = "Wood", Icon = "🌲", Value = 2, SellPrice = 1, Block = "Wood" },
	Planks = { Name = "Planks", Icon = "🟧", SellPrice = 0, Block = "Planks" },
	Stone = { Name = "Stone", Icon = "⛰️", Value = 2, SellPrice = 1, Block = "Stone" },
	Furnace = { Name = "Furnace", Icon = "🔥", SellPrice = 0, Block = "Furnace" },

	-- Crafting materials
	Sticks = { Name = "Sticks", Icon = "🥢", SellPrice = 0, Model = "Sticks" },
	Coal = { Name = "Coal", Icon = "⚫", Value = 5, SellPrice = 2, Model = "Coal" },
	RawIron = { Name = "Raw Iron", Icon = "🔸", Value = 10, SellPrice = 5, Model = "RawIron" },
	IronIngot = { Name = "Iron Ingot", Icon = "⬜", SellPrice = 8, Model = "IronIngot" },

	-- Crops and seeds
	WheatSeeds = { Name = "Wheat Seeds", Icon = "🌱", Value = 12, SellPrice = 0, BuyPrice = 12, Model = "WheatSeeds" },
	Wheat = { Name = "Wheat", Icon = "🌾", Value = 4, SellPrice = 2, Model = "Wheat" },
	CarrotSeeds = {
		Name = "Carrot Seeds",
		Icon = "🌱",
		Value = 45,
		SellPrice = 0,
		BuyPrice = 45,
		Model = "CarrotSeeds",
	},
	Carrot = { Name = "Carrot", Icon = "🥕", Value = 10, SellPrice = 5, Model = "Carrot" },
	PotatoSeeds = {
		Name = "Potato Seeds",
		Icon = "🌱",
		Value = 120,
		SellPrice = 0,
		BuyPrice = 120,
		Model = "PotatoSeeds",
	},
	Potato = { Name = "Potato", Icon = "🥔", Value = 24, SellPrice = 12, Model = "Potato" },
	-- Warzone-only seeds (found in chests, never sold by the Merchant)
	GlowberrySeeds = { Name = "Glowberry Seeds", Icon = "✨", Value = 250, SellPrice = 0, Model = "GlowberrySeeds" },
	Glowberry = { Name = "Glowberry", Icon = "🍇", Value = 70, SellPrice = 35, Model = "Glowberry" },

	-- Warzone materials
	Scrap = { Name = "Scrap", Icon = "⚙️", Value = 6, SellPrice = 0, Model = "Scrap" },
	Crystal = { Name = "Crystal", Icon = "💎", Value = 60, SellPrice = 0, Model = "Crystal" },
}
-- Every tool from Tools.luau is an item too, e.g. "StonePickaxe" -> "Stone Pickaxe"
local KIND_ICONS = { Sword = "🗡️", Pickaxe = "⛏️", Axe = "🔨", Shovel = "🥄" }
for _, tool in Tools.List do
	Items[tool.Item] = {
		Name = `{Tools.TierNames[tool.Tier]} {tool.Kind}`,
		Icon = KIND_ICONS[tool.Kind] or "🛠️",
		SellPrice = 0,
		Model = tool.Item,
	}
end

return table.freeze(Items)
