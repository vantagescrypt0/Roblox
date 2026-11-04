--!strict
-- Slivers (your call, 2026-10-29: nodes are never sold). Now and then mining an ore, chopping a
-- log or harvesting a crop in a Grinding World drops a sliver of it, and enough slivers craft
-- something to grow it on your island: a node for ore, a sapling for a tree, seeds for a crop.
-- The rarer the resource, the rarer its slivers and the more it takes. Only the shared worlds
-- drop them, and only what's in the worlds has them: the late game (Ruby, Starstone, Mangrove,
-- Starwood, Strawberry, Dragonfruit, Starfruit) comes from loot crates and Warzone chests
-- instead (your call, 2026-11-02). Chances are flat (no level or armor bonus). Items.luau makes
-- the sliver items, Recipes.luau the recipes, BlockService and FarmService roll them.

export type Sliver = {
	Ore: string, -- the block or crop that drops it
	Item: string, -- the sliver's item id
	Name: string,
	Chance: number, -- per one gathered
	Node: string, -- the node, sapling or seeds it crafts
	Need: number, -- slivers to one of those
}

local List: { Sliver } = {}
local byOre: { [string]: Sliver } = {}
local byItem: { [string]: Sliver } = {}

local function add(ore: string, name: string, every: number, node: string, need: number)
	local sliver: Sliver = {
		Ore = ore,
		Item = `{name}Sliver`,
		Name = `{name} Sliver`,
		Chance = 1 / every,
		Node = node,
		Need = need,
	}
	table.insert(List, sliver)
	byOre[ore] = sliver
	byItem[sliver.Item] = sliver
end

-- One in `every` ores mined
add("CoalOre", "Coal", 150, "CoalNode", 10)
add("IronOre", "Iron", 250, "IronNode", 10)
add("GoldOre", "Gold", 400, "GoldNode", 12)
add("SilverOre", "Silver", 600, "SilverNode", 12)
add("AmethystOre", "Amethyst", 900, "AmethystNode", 15)
add("SapphireOre", "Sapphire", 1300, "SapphireNode", 15)
-- One in `every` logs chopped; Oak has none, as the Lumberjack sells its saplings
add("BirchWood", "Birch", 250, "BirchSapling", 10)
add("SpruceWood", "Spruce", 400, "SpruceSapling", 12)
add("CherryWood", "Cherry", 600, "CherrySapling", 12)
add("MapleWood", "Maple", 900, "MapleSapling", 15)
add("Redwood", "Redwood", 1300, "RedwoodSapling", 15)
-- One in `every` crops harvested; the Merchant sells the earlier crops' seeds
add("Sugarcane", "Sugarcane", 900, "SugarcaneSeeds", 15)

return table.freeze({
	List = table.freeze(List),
	ByOre = table.freeze(byOre),
	ByItem = table.freeze(byItem),
})
