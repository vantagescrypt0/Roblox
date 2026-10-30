--!strict
-- Block types (Minecraft-style). Each one has a cube mesh in ReplicatedStorage.Blocks
-- with the same name (made in art/scripts/blocks.py). Blocks are 3 studs.
--
-- Toughness system:
--   Hardness     how tough it is (Minecraft values). Break time = Hardness x 1.5 / tool speed.
--   Tool         the tool kind that breaks it fast (Pickaxe, Axe, Shovel) - see Tools.luau
--   RequiresTool if true you need that tool (and MinTier) or it breaks very slowly and drops nothing
--
-- Resource nodes: blocks that grow back in the same spot NodeRespawn seconds after you
-- mine them (the rarer, the slower). On your island those are the boulders and their ore
-- (trees aren't: a felled tree is gone and you replant a sapling). In the resource worlds
-- every ore, log and leaf is a node, so they never run out; the mine's stone is scenery
-- nobody can break. A mined ore never leaves a hole: it turns into a pale Empty Ore block
-- until it fills back in. The same block placed by a player is just a normal block.
-- Water and lava are blocks too (Liquids.luau): nobody can break them, and they're drawn
-- see-through and lower than a full block.

local Gear = require(script.Parent.Gear)
local Liquids = require(script.Parent.Liquids)

export type Block = {
	Name: string,
	Drop: string?, -- item you get when you break it (nil = nothing)
	Hardness: number,
	Tool: string?,
	RequiresTool: boolean?,
	MinTier: number?,
	Breakable: boolean,
	SeeThrough: boolean?, -- blocks behind it still get drawn (glass, water, ice)
	NodeRespawn: number?, -- seconds a mined node takes to grow back
	Ore: boolean?, -- a mined node of it leaves an Empty Ore block while it grows back
	Liquid: string?, -- "Water" or "Lava" (Liquids.luau)
	Height: number?, -- drawn this tall (a share of a block), standing on the cell's floor
}

-- A stone-like building block: needs a pickaxe, like stone
local function stone(name: string, drop: string?): Block
	return {
		Name = name,
		Drop = drop,
		Hardness = 1.5,
		Tool = "Pickaxe",
		RequiresTool = true,
		MinTier = 1,
		Breakable = true,
	}
end

-- Leaves: break in a moment, drop nothing (oak leaves sometimes give a sapling, see
-- BlockService). Their texture is solid, so leaves hidden inside a canopy aren't drawn.
local function leaves(name: string): Block
	return { Name = name, Drop = nil, Hardness = 0.2, Breakable = true, NodeRespawn = 30 }
end

local Blocks: { [string]: Block } = {
	Grass = { Name = "Grass Block", Drop = "Grass", Hardness = 0.6, Tool = "Shovel", Breakable = true },
	Dirt = { Name = "Dirt", Drop = "Dirt", Hardness = 0.5, Tool = "Shovel", Breakable = true },
	Stone = {
		Name = "Stone",
		Drop = "Stone",
		Hardness = 1.5,
		Tool = "Pickaxe",
		RequiresTool = true,
		MinTier = 1,
		Breakable = true,
		NodeRespawn = 15,
	},
	Cobblestone = {
		Name = "Cobblestone",
		Drop = "Cobblestone",
		Hardness = 2,
		Tool = "Pickaxe",
		RequiresTool = true,
		MinTier = 1,
		Breakable = true,
	},
	-- Ores: coal needs any pickaxe, iron needs a Stone pickaxe or better
	CoalOre = {
		Name = "Coal Ore",
		Drop = "Coal",
		Hardness = 3,
		Tool = "Pickaxe",
		RequiresTool = true,
		MinTier = 1,
		Breakable = true,
		NodeRespawn = 20,
		Ore = true,
	},
	IronOre = {
		Name = "Iron Ore",
		Drop = "RawIron",
		Hardness = 3,
		Tool = "Pickaxe",
		RequiresTool = true,
		MinTier = 2,
		Breakable = true,
		NodeRespawn = 45,
		Ore = true,
	},
	-- A mined ore node while it grows back: pale stone with empty pockets where the ore
	-- was. Nobody can break it; it fills back in with its ore (WorldService, IslandService)
	EmptyOre = { Name = "Empty Ore", Drop = nil, Hardness = 50, Breakable = false },
	Furnace = {
		Name = "Furnace",
		Drop = "Furnace",
		Hardness = 3.5,
		Tool = "Pickaxe",
		RequiresTool = true,
		MinTier = 1,
		Breakable = true,
	},
	Wood = { Name = "Wood", Drop = "Wood", Hardness = 2, Tool = "Axe", Breakable = true, NodeRespawn = 20 },
	Planks = { Name = "Planks", Drop = "Planks", Hardness = 2, Tool = "Axe", Breakable = true },
	Leaves = leaves("Leaves"),
	-- The Woodcutting World's zone trees; each needs a Woodcutting level to chop (BlockService)
	BirchWood = {
		Name = "Birch Wood",
		Drop = "BirchWood",
		Hardness = 2,
		Tool = "Axe",
		Breakable = true,
		NodeRespawn = 25,
	},
	SpruceWood = {
		Name = "Spruce Wood",
		Drop = "SpruceWood",
		Hardness = 2.5,
		Tool = "Axe",
		Breakable = true,
		NodeRespawn = 30,
	},
	CherryWood = {
		Name = "Cherry Wood",
		Drop = "CherryWood",
		Hardness = 3,
		Tool = "Axe",
		Breakable = true,
		NodeRespawn = 35,
	},
	BirchLeaves = leaves("Birch Leaves"),
	SpruceLeaves = leaves("Spruce Leaves"),
	CherryLeaves = leaves("Cherry Blossom"),
	-- Gold: deep in the Mining World's cave, needs an Iron pickaxe (and Mining 10)
	GoldOre = {
		Name = "Gold Ore",
		Drop = "RawGold",
		Hardness = 3,
		Tool = "Pickaxe",
		RequiresTool = true,
		MinTier = 3,
		Breakable = true,
		NodeRespawn = 90,
		Ore = true,
	},
	RedWool = { Name = "Red Wool", Drop = "RedWool", Hardness = 0.8, Breakable = true },
	WhiteWool = { Name = "White Wool", Drop = "WhiteWool", Hardness = 0.8, Breakable = true },
	-- Special blocks the game places; players can't break them
	CraftingTable = { Name = "Crafting Table", Drop = nil, Hardness = 2.5, Breakable = false },
	Farmland = { Name = "Farmland", Drop = nil, Hardness = 0.6, Breakable = false },
	Obsidian = { Name = "Obsidian", Drop = nil, Hardness = 50, Breakable = false },
	-- Carved stone the portals are built from
	Runestone = { Name = "Runestone", Drop = nil, Hardness = 50, Breakable = false },

	-- Building blocks (the Builder sells the ones with a Drop)
	StoneBricks = stone("Stone Bricks", "StoneBricks"),
	MossyStoneBricks = stone("Mossy Stone Bricks", "MossyStoneBricks"),
	MossyCobblestone = stone("Mossy Cobblestone", "MossyCobblestone"),
	SmoothStone = stone("Smooth Stone", "SmoothStone"),
	Bricks = stone("Bricks", "Bricks"),
	Plaster = { Name = "Plaster", Drop = "Plaster", Hardness = 1, Tool = "Pickaxe", Breakable = true },
	DarkPlanks = { Name = "Dark Planks", Drop = "DarkPlanks", Hardness = 2, Tool = "Axe", Breakable = true },
	BarnPlanks = { Name = "Barn Planks", Drop = "BarnPlanks", Hardness = 2, Tool = "Axe", Breakable = true },
	RoofRed = { Name = "Red Roof Tiles", Drop = "RoofRed", Hardness = 1.5, Tool = "Pickaxe", Breakable = true },
	RoofSlate = { Name = "Slate Roof Tiles", Drop = "RoofSlate", Hardness = 1.5, Tool = "Pickaxe", Breakable = true },
	Thatch = { Name = "Thatch", Drop = "Thatch", Hardness = 0.5, Breakable = true },
	Glass = { Name = "Glass", Drop = "Glass", Hardness = 0.3, Breakable = true, SeeThrough = true },
	-- Scenery for the Town and the worlds
	Gravel = { Name = "Gravel", Drop = "Gravel", Hardness = 0.6, Tool = "Shovel", Breakable = true },
	Sand = { Name = "Sand", Drop = "Sand", Hardness = 0.5, Tool = "Shovel", Breakable = true },
	Path = { Name = "Dirt Path", Drop = "Path", Hardness = 0.6, Tool = "Shovel", Breakable = true },
	FlowerGrass = { Name = "Flowery Grass", Drop = "FlowerGrass", Hardness = 0.6, Tool = "Shovel", Breakable = true },
	HayBale = { Name = "Hay Bale", Drop = "HayBale", Hardness = 0.5, Breakable = true },
	Crate = { Name = "Crate", Drop = "Crate", Hardness = 2, Tool = "Axe", Breakable = true },
	Barrel = { Name = "Barrel", Drop = "Barrel", Hardness = 2, Tool = "Axe", Breakable = true },
	Bookshelf = { Name = "Bookshelf", Drop = "Bookshelf", Hardness = 1.5, Tool = "Axe", Breakable = true },
	-- The deep rock behind a cave's walls: as far as anyone can dig
	DarkStone = { Name = "Dark Stone", Drop = nil, Hardness = 50, Breakable = false },
	-- Zone scenery: snowy pines, autumn trees, pumpkin and melon patches, mesa cliffs
	Snow = { Name = "Snow", Drop = "Snow", Hardness = 0.5, Tool = "Shovel", Breakable = true },
	SnowyGrass = { Name = "Snowy Grass", Drop = "SnowyGrass", Hardness = 0.6, Tool = "Shovel", Breakable = true },
	Ice = { Name = "Ice", Drop = "Ice", Hardness = 0.5, Breakable = true, SeeThrough = true },
	AutumnLeaves = leaves("Autumn Leaves"),
	Pumpkin = { Name = "Pumpkin", Drop = nil, Hardness = 1, Tool = "Axe", Breakable = true },
	Melon = { Name = "Melon", Drop = nil, Hardness = 1, Tool = "Axe", Breakable = true },
	Terracotta = stone("Terracotta", "Terracotta"),
	RedTerracotta = stone("Red Terracotta", "RedTerracotta"),
	-- From the Skybounds references: the mine's sandstone mountain, woodland dirt, giant
	-- mushrooms, old ruins
	Sandstone = stone("Sandstone", "Sandstone"),
	CoarseDirt = { Name = "Coarse Dirt", Drop = "CoarseDirt", Hardness = 0.5, Tool = "Shovel", Breakable = true },
	MushroomCap = { Name = "Mushroom Cap", Drop = "MushroomCap", Hardness = 0.2, Tool = "Axe", Breakable = true },
	MushroomStem = { Name = "Mushroom Stem", Drop = "MushroomStem", Hardness = 0.2, Tool = "Axe", Breakable = true },
	CrackedStoneBricks = stone("Cracked Stone Bricks", "CrackedStoneBricks"),
}

-- Water and lava: sources, flowing levels and falling blocks (Liquids.luau). Their look is
-- built in code (Util/LiquidModels).
for blockType, cell in Liquids.ByBlock do
	Blocks[blockType] = {
		Name = cell.Kind.Name,
		Drop = nil,
		Hardness = 100,
		Breakable = false,
		SeeThrough = true,
		Liquid = cell.Kind.Id,
		Height = Liquids.Height(cell),
	}
end

-- Trophies (Gear.luau): a golden cup on a plinth, put on your island to show off. Their
-- look is built in code (Util/TrophyModels), so they're see-through to the blocks round them.
for _, trophy in Gear.TrophyList do
	Blocks[trophy.Block] = { Name = trophy.Name, Drop = trophy.Item, Hardness = 1, Breakable = true, SeeThrough = true }
end

local Size = 3

return table.freeze({
	Size = Size,
	-- How far away (studs) you can break or place blocks
	Reach = 20,
	Types = table.freeze(Blocks),
})
