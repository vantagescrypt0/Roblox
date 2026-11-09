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
-- The scale is billions (your call, 2026-11-02): see "The billion scale" in that note.

local Blocks = require(script.Parent.Blocks)
local Decorations = require(script.Parent.Decorations)
local Gear = require(script.Parent.Gear)
local Monsters = require(script.Parent.Monsters)
local Slivers = require(script.Parent.Slivers)
local Tools = require(script.Parent.Tools)

export type Item = {
	Name: string,
	Icon: string, -- emoji fallback for the UI
	Value: number?, -- fair trade value in coins (nil = worked out from its recipe)
	SellPrice: number, -- coins per item at the market; 0 = can't sell
	BuyPrice: number?, -- coins to buy one at the market; nil = not for sale
	Block: string?, -- block type this item places (a bucket pours its liquid)
	Empties: string?, -- placing it leaves this item instead (a full bucket leaves a Bucket)
	Keep: boolean?, -- placing it doesn't use it up (the Bottomless buckets)
	Node: boolean?, -- placed as a node: its block grows back after it's mined (islands only)
	-- "Pet", "Helmet", "Chest", "Legs", "Boots" or "Shield": which slot it's worn in, from the Bag
	-- (Gear.luau). Never put on the hotbar.
	Equip: string?,
	Model: string?, -- 3D model in ReplicatedStorage.ItemModels (icons and holding)
	Tree: string?, -- a sapling: which tree it grows (IslandService)
	Crate: boolean?, -- opened from the Bag (LootCrates.luau)
}

local Items: { [string]: Item } = {
	-- Blocks
	Grass = { Name = "Grass Block", Icon = "🟩", Value = 1, SellPrice = 0, BuyPrice = 3, Block = "Grass" },
	Dirt = { Name = "Dirt", Icon = "🟫", Value = 1, SellPrice = 0, BuyPrice = 2, Block = "Dirt" },
	Wood = { Name = "Wood", Icon = "🌲", Value = 4, SellPrice = 2, Block = "Wood" },
	-- Zone woods from the Woodcutting World (Woodcutting 10 / 20 / 30); the Lumberjack buys them
	BirchWood = { Name = "Birch Wood", Icon = "🪵", Value = 20, SellPrice = 10, Block = "BirchWood" },
	SpruceWood = { Name = "Spruce Wood", Icon = "🪵", Value = 62, SellPrice = 31, Block = "SpruceWood" },
	CherryWood = { Name = "Cherry Wood", Icon = "🌸", Value = 170, SellPrice = 85, Block = "CherryWood" },
	-- The second ring of zones (Woodcutting 40 / 55 / 70 / 85; tools/balance.py prices)
	MapleWood = { Name = "Maple Wood", Icon = "🍁", Value = 534, SellPrice = 267, Block = "MapleWood" },
	Redwood = { Name = "Redwood", Icon = "🌲", Value = 2030, SellPrice = 1015, Block = "Redwood" },
	MangroveWood = { Name = "Mangrove Wood", Icon = "🪵", Value = 3000, SellPrice = 1500, Block = "MangroveWood" },
	Starwood = { Name = "Starwood", Icon = "🌟", Value = 12000, SellPrice = 6000, Block = "Starwood" },
	Planks = { Name = "Planks", Icon = "🟧", SellPrice = 0, BuyPrice = 3, Block = "Planks" },
	Stone = { Name = "Stone", Icon = "⛰️", Value = 4, SellPrice = 2, BuyPrice = 4, Block = "Stone" },
	Furnace = { Name = "Furnace", Icon = "🔥", SellPrice = 0, Block = "Furnace" },
	Chest = { Name = "Chest", Icon = "📦", SellPrice = 0, Block = "Chest" },
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
	-- More from the Builder: every block you see around Town and the worlds
	Gravel = { Name = "Gravel", Icon = "🪨", Value = 2, SellPrice = 0, BuyPrice = 3, Block = "Gravel" },
	Sand = { Name = "Sand", Icon = "🟨", Value = 2, SellPrice = 0, BuyPrice = 3, Block = "Sand" },
	Path = { Name = "Dirt Path", Icon = "🟫", Value = 2, SellPrice = 0, BuyPrice = 3, Block = "Path" },
	CoarseDirt = { Name = "Coarse Dirt", Icon = "🟫", Value = 2, SellPrice = 0, BuyPrice = 3, Block = "CoarseDirt" },
	FlowerGrass = {
		Name = "Flowery Grass",
		Icon = "🌼",
		Value = 3,
		SellPrice = 0,
		BuyPrice = 5,
		Block = "FlowerGrass",
	},
	SnowyGrass = { Name = "Snowy Grass", Icon = "⬜", Value = 3, SellPrice = 0, BuyPrice = 5, Block = "SnowyGrass" },
	Snow = { Name = "Snow", Icon = "⬜", Value = 2, SellPrice = 0, BuyPrice = 4, Block = "Snow" },
	Ice = { Name = "Ice", Icon = "🧊", Value = 4, SellPrice = 0, BuyPrice = 6, Block = "Ice" },
	Sandstone = { Name = "Sandstone", Icon = "🟨", Value = 3, SellPrice = 0, BuyPrice = 5, Block = "Sandstone" },
	Terracotta = { Name = "Terracotta", Icon = "🟧", Value = 3, SellPrice = 0, BuyPrice = 5, Block = "Terracotta" },
	RedTerracotta = {
		Name = "Red Terracotta",
		Icon = "🟥",
		Value = 3,
		SellPrice = 0,
		BuyPrice = 5,
		Block = "RedTerracotta",
	},
	MossyCobblestone = {
		Name = "Mossy Cobblestone",
		Icon = "🪨",
		Value = 3,
		SellPrice = 0,
		BuyPrice = 5,
		Block = "MossyCobblestone",
	},
	MossyStoneBricks = {
		Name = "Mossy Stone Bricks",
		Icon = "🧱",
		Value = 4,
		SellPrice = 0,
		BuyPrice = 6,
		Block = "MossyStoneBricks",
	},
	CrackedStoneBricks = {
		Name = "Cracked Stone Bricks",
		Icon = "🧱",
		Value = 4,
		SellPrice = 0,
		BuyPrice = 6,
		Block = "CrackedStoneBricks",
	},
	Obsidian = { Name = "Obsidian", Icon = "⬛", Value = 8, SellPrice = 0, BuyPrice = 12, Block = "Obsidian" },
	DarkStone = { Name = "Dark Stone", Icon = "⬛", Value = 3, SellPrice = 0, BuyPrice = 5, Block = "DarkStone" },
	Runestone = { Name = "Runestone", Icon = "🟦", Value = 8, SellPrice = 0, BuyPrice = 12, Block = "Runestone" },
	BarnPlanks = { Name = "Barn Planks", Icon = "🟥", Value = 2, SellPrice = 0, BuyPrice = 4, Block = "BarnPlanks" },
	Thatch = { Name = "Thatch", Icon = "🟨", Value = 2, SellPrice = 0, BuyPrice = 4, Block = "Thatch" },
	HayBale = { Name = "Hay Bale", Icon = "🌾", Value = 3, SellPrice = 0, BuyPrice = 5, Block = "HayBale" },
	Crate = { Name = "Crate", Icon = "📦", Value = 4, SellPrice = 0, BuyPrice = 6, Block = "Crate" },
	Barrel = { Name = "Barrel", Icon = "🛢️", Value = 4, SellPrice = 0, BuyPrice = 6, Block = "Barrel" },
	Bookshelf = { Name = "Bookshelf", Icon = "📚", Value = 6, SellPrice = 0, BuyPrice = 10, Block = "Bookshelf" },
	MushroomCap = {
		Name = "Mushroom Cap",
		Icon = "🍄",
		Value = 3,
		SellPrice = 0,
		BuyPrice = 5,
		Block = "MushroomCap",
	},
	MushroomStem = {
		Name = "Mushroom Stem",
		Icon = "⬜",
		Value = 3,
		SellPrice = 0,
		BuyPrice = 5,
		Block = "MushroomStem",
	},
	Mud = { Name = "Mud", Icon = "🟫", Value = 2, SellPrice = 0, BuyPrice = 3, Block = "Mud" },
	DuskGrass = { Name = "Dusk Grass", Icon = "🟦", Value = 3, SellPrice = 0, BuyPrice = 5, Block = "DuskGrass" },

	-- Water and lava (Liquids.luau). Pour a full bucket on your island and it leaves an empty
	-- Bucket; hold the empty Bucket and right-click a source to scoop it back up. The
	-- Bottomless buckets never run dry.
	Bucket = { Name = "Bucket", Icon = "🪣", Value = 10, SellPrice = 0, Model = "Bucket" },
	WaterBucket = {
		Name = "Water Bucket",
		Icon = "💧",
		Value = 20,
		SellPrice = 0,
		BuyPrice = 20,
		Block = "Water",
		Empties = "Bucket",
		Model = "WaterBucket",
	},
	LavaBucket = {
		Name = "Lava Bucket",
		Icon = "🔥",
		Value = 50,
		SellPrice = 0,
		BuyPrice = 50,
		Block = "Lava",
		Empties = "Bucket",
		Model = "LavaBucket",
	},
	BottomlessWaterBucket = {
		Name = "Bottomless Water Bucket",
		Icon = "💧",
		Value = 25000000,
		SellPrice = 0,
		BuyPrice = 25000000,
		Block = "Water",
		Keep = true,
		Model = "BottomlessWaterBucket",
	},
	BottomlessLavaBucket = {
		Name = "Bottomless Lava Bucket",
		Icon = "🔥",
		Value = 50000000,
		SellPrice = 0,
		BuyPrice = 50000000,
		Block = "Lava",
		Keep = true,
		Model = "BottomlessLavaBucket",
	},

	-- Crafting materials
	Sticks = { Name = "Sticks", Icon = "🥢", SellPrice = 0, Model = "Sticks" },
	-- Tool parts (Recipes.luau): bindings from Farming, handles and plates at the Anvil
	Twine = { Name = "Twine", Icon = "🧵", SellPrice = 0, Model = "Twine" },
	Rope = { Name = "Rope", Icon = "🪢", SellPrice = 0, Model = "Rope" },
	IronPlate = { Name = "Iron Plate", Icon = "⬜", SellPrice = 0, Model = "IronPlate" },
	SturdyHandle = { Name = "Sturdy Handle", Icon = "🦯", SellPrice = 0, Model = "SturdyHandle" },
	-- The station for iron tools and their parts (its look: Util/StationModels)
	Anvil = { Name = "Anvil", Icon = "⚒️", SellPrice = 0, Block = "Anvil" },
	-- Blocks hits in the Warzone (WarzoneService); its look is built in code (Util/ShieldModel)
	Shield = { Name = "Shield", Icon = "🛡️", SellPrice = 0, Equip = "Shield" },
	-- The Miner sells coal too, for smelting when you've run out
	Coal = { Name = "Coal", Icon = "⚫", Value = 4, SellPrice = 2, BuyPrice = 6, Model = "Coal" },
	RawIron = { Name = "Raw Iron", Icon = "🔸", Value = 14, SellPrice = 7, Model = "RawIron" },
	IronIngot = { Name = "Iron Ingot", Icon = "⬜", SellPrice = 11, Model = "IronIngot" },
	-- Gold, from deep in the Mining World's cave
	RawGold = { Name = "Raw Gold", Icon = "🟡", Value = 50, SellPrice = 25, Model = "RawGold" },
	GoldIngot = { Name = "Gold Ingot", Icon = "🟨", SellPrice = 32, Model = "GoldIngot" },
	-- The deep cave's ores (tools/balance.py prices; the Miner buys them)
	RawSilver = { Name = "Raw Silver", Icon = "⚪", Value = 146, SellPrice = 73, Model = "RawSilver" },
	SilverIngot = { Name = "Silver Ingot", Icon = "⬜", SellPrice = 90, Model = "SilverIngot" },
	Amethyst = { Name = "Amethyst", Icon = "🟣", Value = 404, SellPrice = 202, Model = "Amethyst" },
	Sapphire = { Name = "Sapphire", Icon = "🔷", Value = 1748, SellPrice = 874, Model = "Sapphire" },
	Ruby = { Name = "Ruby", Icon = "🔴", Value = 10000, SellPrice = 5000, Model = "Ruby" },
	Starstone = { Name = "Starstone", Icon = "⭐", Value = 40000, SellPrice = 20000, Model = "Starstone" },
	-- Tool parts for the gem tiers: refined at the Gem Bench, handles and plates at the Anvil
	SilverPlate = { Name = "Silver Plate", Icon = "⬜", SellPrice = 0, Model = "SilverPlate" },
	RefinedAmethyst = { Name = "Refined Amethyst", Icon = "💜", SellPrice = 0, Model = "RefinedAmethyst" },
	RefinedSapphire = { Name = "Refined Sapphire", Icon = "💙", SellPrice = 0, Model = "RefinedSapphire" },
	BirchHandle = { Name = "Birch Handle", Icon = "🦯", SellPrice = 0, Model = "BirchHandle" },
	SpruceHandle = { Name = "Spruce Handle", Icon = "🦯", SellPrice = 0, Model = "SpruceHandle" },
	-- The top two tiers' parts
	GoldPlate = { Name = "Gold Plate", Icon = "🟨", SellPrice = 0, Model = "GoldPlate" },
	RefinedRuby = { Name = "Refined Ruby", Icon = "❤️", SellPrice = 0, Model = "RefinedRuby" },
	CherryHandle = { Name = "Cherry Handle", Icon = "🦯", SellPrice = 0, Model = "CherryHandle" },
	CaneRope = { Name = "Cane Rope", Icon = "🪢", SellPrice = 0, Model = "CaneRope" },
	StarsteelIngot = { Name = "Starsteel Ingot", Icon = "⬜", SellPrice = 22000, Model = "StarsteelIngot" },
	StarsteelPlate = { Name = "Starsteel Plate", Icon = "⬜", SellPrice = 0, Model = "StarsteelPlate" },
	RedwoodHandle = { Name = "Redwood Handle", Icon = "🦯", SellPrice = 0, Model = "RedwoodHandle" },
	-- The station that cuts and refines gems (its look: Util/StationModels)
	GemBench = { Name = "Gem Bench", Icon = "💎", SellPrice = 0, Block = "GemBench" },

	-- Crops and seeds
	WheatSeeds = { Name = "Wheat Seeds", Icon = "🌱", Value = 12, SellPrice = 0, BuyPrice = 12, Model = "WheatSeeds" },
	Wheat = { Name = "Wheat", Icon = "🌾", Value = 2, SellPrice = 1, Model = "Wheat" },
	CarrotSeeds = {
		Name = "Carrot Seeds",
		Icon = "🌱",
		Value = 48,
		SellPrice = 0,
		BuyPrice = 48,
		Model = "CarrotSeeds",
	},
	Carrot = { Name = "Carrot", Icon = "🥕", Value = 8, SellPrice = 4, Model = "Carrot" },
	PotatoSeeds = {
		Name = "Potato Seeds",
		Icon = "🌱",
		Value = 120,
		SellPrice = 0,
		BuyPrice = 120,
		Model = "PotatoSeeds",
	},
	Potato = { Name = "Potato", Icon = "🥔", Value = 20, SellPrice = 10, Model = "Potato" },
	PumpkinSeeds = {
		Name = "Pumpkin Seeds",
		Icon = "🌱",
		Value = 264,
		SellPrice = 0,
		BuyPrice = 264,
		Model = "PumpkinSeeds",
	},
	Pumpkin = { Name = "Pumpkin", Icon = "🎃", Value = 44, SellPrice = 22, Model = "Pumpkin" },
	MelonSeeds = {
		Name = "Melon Seeds",
		Icon = "🌱",
		Value = 648,
		SellPrice = 0,
		BuyPrice = 648,
		Model = "MelonSeeds",
	},
	Melon = { Name = "Melon", Icon = "🍉", Value = 108, SellPrice = 54, Model = "Melon" },
	-- Sugarcane is the last crop in the Farming World; slivers craft its seeds (Slivers.luau)
	SugarcaneSeeds = { Name = "Sugarcane Seeds", Icon = "🌱", SellPrice = 0, Model = "SugarcaneSeeds" },
	Sugarcane = { Name = "Sugarcane", Icon = "🎋", Value = 900, SellPrice = 450, Model = "Sugarcane" },
	-- Late game, grown only on islands: seeds from loot crates and Warzone chests only
	StrawberrySeeds = {
		Name = "Strawberry Seeds",
		Icon = "🌱",
		Value = 3000000,
		SellPrice = 0,
		Model = "StrawberrySeeds",
	},
	Strawberry = { Name = "Strawberry", Icon = "🍓", Value = 8000, SellPrice = 4000, Model = "Strawberry" },
	DragonfruitSeeds = {
		Name = "Dragonfruit Seeds",
		Icon = "🌱",
		Value = 6000000,
		SellPrice = 0,
		Model = "DragonfruitSeeds",
	},
	Dragonfruit = { Name = "Dragonfruit", Icon = "🐉", Value = 16000, SellPrice = 8000, Model = "Dragonfruit" },
	StarfruitSeeds = {
		Name = "Starfruit Seeds",
		Icon = "🌱",
		Value = 15000000,
		SellPrice = 0,
		Model = "StarfruitSeeds",
	},
	Starfruit = { Name = "Starfruit", Icon = "⭐", Value = 40000, SellPrice = 20000, Model = "Starfruit" },
	-- Warzone-only seeds (found in chests, never sold by the Merchant)
	GlowberrySeeds = { Name = "Glowberry Seeds", Icon = "✨", Value = 480, SellPrice = 0, Model = "GlowberrySeeds" },
	Glowberry = { Name = "Glowberry", Icon = "🍇", Value = 80, SellPrice = 40, Model = "Glowberry" },

	-- Drops from leaves (and the Lumberjack sells them); plant it on grass or dirt and it
	-- grows into a tree. Trees don't grow back once felled, so saplings get used up.
	Sapling = {
		Name = "Sapling",
		Icon = "🌳",
		Value = 8,
		SellPrice = 0,
		BuyPrice = 20,
		Model = "Sapling",
		Tree = "Oak",
	},
	-- Zone trees: slivers craft the ones in the Woodcutting World (Slivers.luau)
	BirchSapling = { Name = "Birch Sapling", Icon = "🌳", SellPrice = 0, Model = "BirchSapling", Tree = "Birch" },
	SpruceSapling = { Name = "Spruce Sapling", Icon = "🌲", SellPrice = 0, Model = "SpruceSapling", Tree = "Spruce" },
	CherrySapling = { Name = "Cherry Sapling", Icon = "🌸", SellPrice = 0, Model = "CherrySapling", Tree = "Cherry" },
	MapleSapling = { Name = "Maple Sapling", Icon = "🍁", SellPrice = 0, Model = "MapleSapling", Tree = "Maple" },
	RedwoodSapling = {
		Name = "Redwood Sapling",
		Icon = "🌲",
		SellPrice = 0,
		Model = "RedwoodSapling",
		Tree = "Redwood",
	},
	-- Late game: from loot crates and Warzone chests only
	MangroveSapling = {
		Name = "Mangrove Sapling",
		Icon = "🌳",
		Value = 5000000,
		SellPrice = 0,
		Model = "MangroveSapling",
		Tree = "Mangrove",
	},
	StarwoodSapling = {
		Name = "Starwood Sapling",
		Icon = "🌟",
		Value = 15000000,
		SellPrice = 0,
		Model = "StarwoodSapling",
		Tree = "Starwood",
	},

	-- A random prize when opened from the Bag (LootCrates.luau)
	LootCrate = { Name = "Loot Crate", Icon = "🎁", Value = 500000, SellPrice = 0, Model = "LootCrate", Crate = true },

	-- Nodes for your island: place one and it's ore that turns pale when mined and grows back,
	-- like the worlds' ore. Once placed, it stays. Crafted from slivers (Slivers.luau), never
	-- sold; Coal and Iron Nodes are challenge rewards too. Worth their slivers (Economy.luau).
	CoalNode = { Name = "Coal Node", Icon = "⚫", SellPrice = 0, Block = "CoalOre", Node = true },
	IronNode = { Name = "Iron Node", Icon = "🔸", SellPrice = 0, Block = "IronOre", Node = true },
	GoldNode = { Name = "Gold Node", Icon = "🟡", SellPrice = 0, Block = "GoldOre", Node = true },
	SilverNode = { Name = "Silver Node", Icon = "⚪", SellPrice = 0, Block = "SilverOre", Node = true },
	AmethystNode = { Name = "Amethyst Node", Icon = "🟣", SellPrice = 0, Block = "AmethystOre", Node = true },
	SapphireNode = { Name = "Sapphire Node", Icon = "🔷", SellPrice = 0, Block = "SapphireOre", Node = true },
	-- Late game: from loot crates and Warzone chests only, so no slivers to take their worth from
	RubyNode = { Name = "Ruby Node", Icon = "🔴", Value = 5000000, SellPrice = 0, Block = "RubyOre", Node = true },
	StarstoneNode = {
		Name = "Starstone Node",
		Icon = "⭐",
		Value = 25000000,
		SellPrice = 0,
		Block = "StarstoneOre",
		Node = true,
	},
	-- What monsters drop (Monsters.luau; tools/balance.py prices). The Slayer in Town buys them
	SlimeGel = { Name = "Slime Gel", Icon = "🟢", Value = 12, SellPrice = 6 },
	Thorn = { Name = "Thorn", Icon = "🌵", Value = 74, SellPrice = 37 },
	ToughHide = { Name = "Tough Hide", Icon = "🟤", Value = 290, SellPrice = 145 },
	OldBone = { Name = "Old Bone", Icon = "🦴", Value = 996, SellPrice = 498 },
	Glowcap = { Name = "Glowcap", Icon = "🍄", Value = 3984, SellPrice = 1992 },
	FrostFur = { Name = "Frost Fur", Icon = "❄️", Value = 20624, SellPrice = 10312 },
	EmberCore = { Name = "Ember Core", Icon = "🔥", Value = 30000, SellPrice = 15000 },
	VoidShard = { Name = "Void Shard", Icon = "🔮", Value = 100000, SellPrice = 50000 },
	-- Warzone materials
	Scrap = { Name = "Scrap", Icon = "⚙️", Value = 6, SellPrice = 0, Model = "Scrap" },
	Crystal = { Name = "Crystal", Icon = "💎", Value = 60, SellPrice = 0, Model = "Crystal" },
}
-- The skill challenges' rewards (Gear.luau): pets, armor sets and trophies. They're earned or
-- found (some pets come from Loot Crates), the shops don't buy them, and players can trade them.
for _, itemId in Decorations.Items do
	local decor = Decorations.ByItem[itemId]
	Items[itemId] = {
		Name = decor.Name,
		Icon = decor.Icon,
		Value = math.ceil(decor.Price * 2 / 3),
		SellPrice = 0,
		BuyPrice = decor.Price,
		Block = decor.Block,
	}
end
for _, pet in Gear.PetList do
	Items[pet.Item] = { Name = pet.Name, Icon = "🐾", Value = 7500 * pet.Tier, SellPrice = 0, Equip = "Pet" }
end
for _, armor in Gear.ArmorList do
	Items[armor.Item] =
		{ Name = armor.Name, Icon = "🛡️", Value = 5000 * armor.Tier, SellPrice = 0, Equip = armor.Slot }
end
for _, trophy in Gear.TrophyList do
	Items[trophy.Item] =
		{ Name = trophy.Name, Icon = "🏆", Value = 400000 * trophy.Tier, SellPrice = 0, Block = trophy.Block }
end
-- Slivers (Slivers.luau): worth a quarter of the ore it takes to find one, so a node is
-- worth more the rarer its ore
for _, sliver in Slivers.List do
	-- What it comes from: a block's drop, or the crop itself
	local ore = Blocks.Types[sliver.Ore]
	local drop = if ore then ore.Drop else sliver.Ore
	local oreValue = drop and Items[drop] and Items[drop].Value or 2
	Items[sliver.Item] = {
		Name = sliver.Name,
		Icon = "✨",
		Value = math.round(oreValue / sliver.Chance / 4),
		SellPrice = 0,
		Model = sliver.Item,
	}
end
-- Monster spawners for your island (Monsters.luau): place one and its monster keeps appearing
-- beside it to fight. Crafted from slivers, except the late game's two, which only come from
-- loot crates and Warzone chests and are priced like the late game's nodes.
local LATE_SPAWNER_VALUE: { [string]: number } = { CinderkinSpawner = 8000000, VoidlingSpawner = 30000000 }
for _, monster in Monsters.List do
	Items[monster.Spawner] = {
		Name = `{monster.Name} Spawner`,
		Icon = "🥚",
		Value = LATE_SPAWNER_VALUE[monster.Spawner],
		SellPrice = 0,
		Block = monster.Spawner,
		Node = true,
	}
end
-- Every tool from Tools.luau is an item too, e.g. "StonePickaxe" -> "Stone Pickaxe"
local KIND_ICONS = { Sword = "🗡️", Pickaxe = "⛏️", Axe = "🔨", Shovel = "🥄", Hoe = "🌱" }
for _, tool in Tools.List do
	Items[tool.Item] = {
		Name = `{tool.TierName} {tool.Kind}`,
		Icon = KIND_ICONS[tool.Kind] or "🛠️",
		SellPrice = 0,
		Model = tool.Item,
	}
end
-- The armour kits' swords: a kit's, so no shop buys them. Their look is in SwordArt.luau.
for _, tool in Tools.KitSwords do
	Items[tool.Item] = {
		Name = `{tool.TierName} Sword`,
		Icon = KIND_ICONS.Sword,
		Value = 5000 * tool.Tier,
		SellPrice = 0,
	}
end

return table.freeze(Items)
