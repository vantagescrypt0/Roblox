--!strict
-- The order items are listed in on screen (Bag, trade window): blocks, materials, seeds,
-- crops, Warzone materials, then every tool.

local Tools = require(script.Parent.Tools)

local ORDER = {
	"Grass",
	"Dirt",
	"Wood",
	"Planks",
	"Stone",
	"Cobblestone",
	"RedWool",
	"WhiteWool",
	"Sticks",
	"Furnace",
	"Coal",
	"RawIron",
	"IronIngot",
	"WheatSeeds",
	"CarrotSeeds",
	"PotatoSeeds",
	"GlowberrySeeds",
	"Sapling",
	"Wheat",
	"Carrot",
	"Potato",
	"Glowberry",
	"Scrap",
	"Crystal",
}
for _, tool in Tools.List do
	table.insert(ORDER, tool.Item)
end

return table.freeze(ORDER)
