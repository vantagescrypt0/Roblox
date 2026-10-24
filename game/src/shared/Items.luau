--!strict
-- Every item in the game. Placeholder names and prices; tune freely.
-- Items with a Block can be placed as that block (see Blocks.luau).
-- Tools (swords, pickaxes, axes, shovels) get their stats from Tools.luau.
-- Icons: pre-rendered pictures from the icon sheet (ItemArt.luau, made by art/scripts/items3d.py);
-- without one, block items show a 3D block and items with a Model (ReplicatedStorage.ItemModels)
-- show that model, and anything else its emoji.

local Tools = require(script.Parent.Tools)

export type Item = {
	Name: string,
	Icon: string, -- emoji fallback for the UI
	SellPrice: number, -- coins per item at the market; 0 = can't sell
	BuyPrice: number?, -- coins to buy one at the market; nil = not for sale
	Block: string?, -- block type this item places
	Model: string?, -- 3D model in ReplicatedStorage.ItemModels (icons and holding)
}

local Items: { [string]: Item } = {
	-- Blocks
	Grass = { Name = "Grass Block", Icon = "🟩", SellPrice = 0, Block = "Grass" },
	Dirt = { Name = "Dirt", Icon = "🟫", SellPrice = 0, Block = "Dirt" },
	Wood = { Name = "Wood", Icon = "🌲", SellPrice = 1, Block = "Wood" },
	Planks = { Name = "Planks", Icon = "🟧", SellPrice = 0, Block = "Planks" },
	Stone = { Name = "Stone", Icon = "⛰️", SellPrice = 1, Block = "Stone" },
	Furnace = { Name = "Furnace", Icon = "🔥", SellPrice = 0, Block = "Furnace" },

	-- Crafting materials
	Sticks = { Name = "Sticks", Icon = "🥢", SellPrice = 0, Model = "Sticks" },
	Coal = { Name = "Coal", Icon = "⚫", SellPrice = 2, Model = "Coal" },
	RawIron = { Name = "Raw Iron", Icon = "🔸", SellPrice = 3, Model = "RawIron" },
	IronIngot = { Name = "Iron Ingot", Icon = "⬜", SellPrice = 8, Model = "IronIngot" },

	-- Crops and seeds
	WheatSeeds = { Name = "Wheat Seeds", Icon = "🌱", SellPrice = 0, BuyPrice = 2, Model = "WheatSeeds" },
	Wheat = { Name = "Wheat", Icon = "🌾", SellPrice = 3, Model = "Wheat" },
	CarrotSeeds = { Name = "Carrot Seeds", Icon = "🌱", SellPrice = 0, BuyPrice = 6, Model = "CarrotSeeds" },
	Carrot = { Name = "Carrot", Icon = "🥕", SellPrice = 8, Model = "Carrot" },
	PotatoSeeds = { Name = "Potato Seeds", Icon = "🌱", SellPrice = 0, BuyPrice = 15, Model = "PotatoSeeds" },
	Potato = { Name = "Potato", Icon = "🥔", SellPrice = 20, Model = "Potato" },
	-- Warzone-only seeds (found in chests, never sold)
	GlowberrySeeds = { Name = "Glowberry Seeds", Icon = "✨", SellPrice = 0, Model = "GlowberrySeeds" },
	Glowberry = { Name = "Glowberry", Icon = "🍇", SellPrice = 60, Model = "Glowberry" },

	-- Warzone materials
	Scrap = { Name = "Scrap", Icon = "⚙️", SellPrice = 0, Model = "Scrap" },
	Crystal = { Name = "Crystal", Icon = "💎", SellPrice = 0, Model = "Crystal" },
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
