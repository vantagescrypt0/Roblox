--!strict
-- Slivers (your call, 2026-10-29: ore nodes are never sold). Now and then mining an ore in
-- the Mining World drops a sliver of it, and enough slivers craft that ore's node for your
-- island (a node is ore that grows back after it's mined). The rarer the ore, the rarer
-- its slivers and the more a node takes, so nodes stay rare. Only the shared worlds drop
-- them: island nodes can't grow more nodes. Chances are flat (no level or armor bonus).
-- Items.luau makes the sliver items, Recipes.luau the node recipes, BlockService rolls them.

export type Sliver = {
	Ore: string, -- the ore block that drops it
	Item: string, -- the sliver's item id
	Name: string,
	Chance: number, -- per ore mined
	Node: string, -- the node item it crafts
	Need: number, -- slivers to a node
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
add("RubyOre", "Ruby", 1800, "RubyNode", 20)
add("StarstoneOre", "Starstone", 2500, "StarstoneNode", 20)

return table.freeze({
	List = table.freeze(List),
	ByOre = table.freeze(byOre),
	ByItem = table.freeze(byItem),
})
