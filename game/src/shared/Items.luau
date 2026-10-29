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
--   SellPrice  what the shops in Town pay (Shops.luau): about half of Value, so trading
--              is the better deal
--   BuyPrice   what the shops in Town charge, if one sells it. Crops regrow, so a seed is
--              a one-off cost per plot.

local Gear = require(script.Parent.Gear)
local Tools = require(script.Parent.Tools)

export type Item = {
	Name: string,
	Icon: string, -- emoji fallback for the UI
	Value: number?, -- fair trade value in coins (nil = worked out from its recipe)
	SellPrice: number, -- coins per item at the market; 0 = can't sell
	BuyPrice: number?, -- coins to buy one at the market; nil = not for sale
	Block: string?, -- block type this item places
	Node: boolean?, -- placed as a node: its block grows back after it's mined (islands only)
	Equip: string?, -- "Pet" or "Armor": worn from the Bag (Gear.luau), never put on the hotbar
	Model: string?, -- 3D model in ReplicatedStorage.ItemModels (icons and holding)
}

local Items: { [string]: Item } = {
	-- Blocks
	Grass = { Name = "Grass Block", Icon = "🟩", Value = 1, SellPrice = 0, BuyPrice = 3, Block = "Grass" },
	Dirt = { Name = "Dirt", Icon = "🟫", Value = 1, SellPrice = 0, BuyPrice = 2, Block = "Dirt" },
	Wood = { Name = "Wood", Icon = "🌲", Value = 2, SellPrice = 1, Block = "Wood" },
	-- Zone woods from the Woodcutting World (Woodcutting 10 / 20 / 30); the Lumberjack buys them
	BirchWood = { Name = "Birch Wood", Icon = "🪵", Value = 12, SellPrice = 6, Block = "BirchWood" },
	SpruceWood = { Name = "Spruce Wood", Icon = "🪵", Value = 28, SellPrice = 14, Block = "SpruceWood" },
	CherryWood = { Name = "Cherry Wood", Icon = "🌸", Value = 54, SellPrice = 27, Block = "CherryWood" },
	Planks = { Name = "Planks", Icon = "🟧", SellPrice = 0, Block = "Planks" },
	Stone = { Name = "Stone", Icon = "⛰️", Value = 2, SellPrice = 1, Block = "Stone" },
	Furnace = { Name = "Furnace", Icon = "🔥", SellPrice = 0, Block = "Furnace" },
	-- Building blocks from the Builder in Town
	Cobblestone = {
		Name = "Cobblestone",
		Icon = "🪨",
		Value = 2,
		SellPrice = 0,
		BuyPrice = 4,
		Block = "Cobblestone",
	},
	RedWool = { Name = "Red Wool", Icon = "🟥", Value = 4, SellPrice = 0, BuyPrice = 6, Block = "RedWool" },
	WhiteWool = { Name = "White Wool", Icon = "⬜", Value = 4, SellPrice = 0, BuyPrice = 6, Block = "WhiteWool" },
	StoneBricks = {
		Name = "Stone Bricks",
		Icon = "🧱",
		Value = 3,
		SellPrice = 0,
		BuyPrice = 5,
		Block = "StoneBricks",
	},
	Bricks = { Name = "Bricks", Icon = "🧱", Value = 4, SellPrice = 0, BuyPrice = 6, Block = "Bricks" },
	SmoothStone = { Name = "Smooth Stone", Icon = "⬜", Value = 3, SellPrice = 0, BuyPrice = 5, Block = "SmoothStone" },
	Plaster = { Name = "Plaster", Icon = "⬜", Value = 3, SellPrice = 0, BuyPrice = 5, Block = "Plaster" },
	DarkPlanks = { Name = "Dark Planks", Icon = "🟫", Value = 2, SellPrice = 0, BuyPrice = 4, Block = "DarkPlanks" },
	Glass = { Name = "Glass", Icon = "🪟", Value = 4, SellPrice = 0, BuyPrice = 6, Block = "Glass" },
	RoofRed = { Name = "Red Roof Tiles", Icon = "🟥", Value = 3, SellPrice = 0, BuyPrice = 5, Block = "RoofRed" },
	RoofSlate = {
		Name = "Slate Roof Tiles",
		Icon = "🟦",
		Value = 3,
		SellPrice = 0,
		BuyPrice = 5,
		Block = "RoofSlate",
	},

	-- Crafting materials
	Sticks = { Name = "Sticks", Icon = "🥢", SellPrice = 0, Model = "Sticks" },
	-- The Miner sells coal too, for smelting when you've run out
	Coal = { Name = "Coal", Icon = "⚫", Value = 2, SellPrice = 1, BuyPrice = 3, Model = "Coal" },
	RawIron = { Name = "Raw Iron", Icon = "🔸", Value = 8, SellPrice = 4, Model = "RawIron" },
	IronIngot = { Name = "Iron Ingot", Icon = "⬜", SellPrice = 6, Model = "IronIngot" },
	-- Gold, from deep in the Mining World's cave
	RawGold = { Name = "Raw Gold", Icon = "🟡", Value = 32, SellPrice = 16, Model = "RawGold" },
	GoldIngot = { Name = "Gold Ingot", Icon = "🟨", SellPrice = 20, Model = "GoldIngot" },

	-- Crops and seeds
	WheatSeeds = { Name = "Wheat Seeds", Icon = "🌱", Value = 12, SellPrice = 0, BuyPrice = 12, Model = "WheatSeeds" },
	Wheat = { Name = "Wheat", Icon = "🌾", Value = 2, SellPrice = 1, Model = "Wheat" },
	CarrotSeeds = {
		Name = "Carrot Seeds",
		Icon = "🌱",
		Value = 24,
		SellPrice = 0,
		BuyPrice = 24,
		Model = "CarrotSeeds",
	},
	Carrot = { Name = "Carrot", Icon = "🥕", Value = 4, SellPrice = 2, Model = "Carrot" },
	PotatoSeeds = {
		Name = "Potato Seeds",
		Icon = "🌱",
		Value = 60,
		SellPrice = 0,
		BuyPrice = 60,
		Model = "PotatoSeeds",
	},
	Potato = { Name = "Potato", Icon = "🥔", Value = 10, SellPrice = 5, Model = "Potato" },
	PumpkinSeeds = {
		Name = "Pumpkin Seeds",
		Icon = "🌱",
		Value = 120,
		SellPrice = 0,
		BuyPrice = 120,
		Model = "PumpkinSeeds",
	},
	Pumpkin = { Name = "Pumpkin", Icon = "🎃", Value = 20, SellPrice = 10, Model = "Pumpkin" },
	MelonSeeds = {
		Name = "Melon Seeds",
		Icon = "🌱",
		Value = 180,
		SellPrice = 0,
		BuyPrice = 180,
		Model = "MelonSeeds",
	},
	Melon = { Name = "Melon", Icon = "🍉", Value = 30, SellPrice = 15, Model = "Melon" },
	-- Warzone-only seeds (found in chests, never sold by the Merchant)
	GlowberrySeeds = { Name = "Glowberry Seeds", Icon = "✨", Value = 250, SellPrice = 0, Model = "GlowberrySeeds" },
	Glowberry = { Name = "Glowberry", Icon = "🍇", Value = 40, SellPrice = 20, Model = "Glowberry" },

	-- Drops from leaves (and the Lumberjack sells them); plant it on grass or dirt and it
	-- grows into a tree. Trees don't grow back once felled, so saplings get used up.
	Sapling = { Name = "Sapling", Icon = "🌳", Value = 8, SellPrice = 0, BuyPrice = 20, Model = "Sapling" },

	-- Nodes for your island (rewards from the beginner challenges): place one and it's ore
	-- that turns pale when mined and grows back, like the worlds' ore. Once placed, it stays.
	CoalNode = { Name = "Coal Node", Icon = "⚫", Value = 400, SellPrice = 0, Block = "CoalOre", Node = true },
	IronNode = { Name = "Iron Node", Icon = "🔸", Value = 1200, SellPrice = 0, Block = "IronOre", Node = true },

	-- Warzone materials
	Scrap = { Name = "Scrap", Icon = "⚙️", Value = 6, SellPrice = 0, Model = "Scrap" },
	Crystal = { Name = "Crystal", Icon = "💎", Value = 60, SellPrice = 0, Model = "Crystal" },
}
-- The skill challenges' rewards (Gear.luau): pets, armor sets and trophies. They're earned,
-- not bought, and the shops don't buy them; players can still trade them.
for _, pet in Gear.PetList do
	Items[pet.Item] = { Name = pet.Name, Icon = "🐾", Value = 1500 * pet.Tier, SellPrice = 0, Equip = "Pet" }
end
for _, armor in Gear.ArmorList do
	Items[armor.Item] =
		{ Name = armor.Name, Icon = "🛡️", Value = 4000 * armor.Tier, SellPrice = 0, Equip = "Armor" }
end
for _, trophy in Gear.TrophyList do
	Items[trophy.Item] =
		{ Name = trophy.Name, Icon = "🏆", Value = 40000 * trophy.Tier, SellPrice = 0, Block = trophy.Block }
end
-- Every tool from Tools.luau is an item too, e.g. "StonePickaxe" -> "Stone Pickaxe"
local KIND_ICONS = { Sword = "🗡️", Pickaxe = "⛏️", Axe = "🔨", Shovel = "🥄", Hoe = "🌱" }
for _, tool in Tools.List do
	Items[tool.Item] = {
		Name = `{Tools.TierNames[tool.Tier]} {tool.Kind}`,
		Icon = KIND_ICONS[tool.Kind] or "🛠️",
		SellPrice = 0,
		Model = tool.Item,
	}
end

return table.freeze(Items)
