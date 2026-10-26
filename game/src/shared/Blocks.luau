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
-- mine them. On your island those are the boulders and their ore (trees aren't: a felled
-- tree is gone and you replant a sapling). In the resource worlds every rock, log and
-- leaf is a node, so they never run out. The same block placed by a player is just a
-- normal block.

export type Block = {
	Name: string,
	Drop: string?, -- item you get when you break it (nil = nothing)
	Hardness: number,
	Tool: string?,
	RequiresTool: boolean?,
	MinTier: number?,
	Breakable: boolean,
	SeeThrough: boolean?, -- blocks behind it still get drawn (leaves)
	NodeRespawn: number?, -- seconds a mined node takes to grow back
}

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
		NodeRespawn = 30,
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
	},
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
	Leaves = { Name = "Leaves", Drop = nil, Hardness = 0.2, Breakable = true, SeeThrough = true, NodeRespawn = 30 },
	RedWool = { Name = "Red Wool", Drop = "RedWool", Hardness = 0.8, Breakable = true },
	WhiteWool = { Name = "White Wool", Drop = "WhiteWool", Hardness = 0.8, Breakable = true },
	-- Special blocks the game places; players can't break them
	CraftingTable = { Name = "Crafting Table", Drop = nil, Hardness = 2.5, Breakable = false },
	Farmland = { Name = "Farmland", Drop = nil, Hardness = 0.6, Breakable = false },
	Obsidian = { Name = "Obsidian", Drop = nil, Hardness = 50, Breakable = false },
	-- Carved stone the portals are built from
	Runestone = { Name = "Runestone", Drop = nil, Hardness = 50, Breakable = false },
}

local Size = 3

return table.freeze({
	Size = Size,
	-- How far away (studs) you can break or place blocks
	Reach = 20,
	Types = table.freeze(Blocks),
})
