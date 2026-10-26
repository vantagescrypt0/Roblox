--!strict
-- The order items are listed in on screen (Bag, trade window): blocks, materials, seeds,
-- crops, Warzone materials, then every tool.

local Tools = require(script.Parent.Tools)

local ORDER = {
	"Grass",
	"Dirt",
	"Wood",
	"BirchWood",
	"SpruceWood",
	"CherryWood",
	"Planks",
	"Stone",
	"Cobblestone",
	"RedWool",
	"WhiteWool",
	"StoneBricks",
	"Bricks",
	"SmoothStone",
	"Plaster",
	"DarkPlanks",
	"Glass",
	"RoofRed",
	"RoofSlate",
	"Sticks",
	"Furnace",
	"Coal",
	"RawIron",
	"IronIngot",
	"RawGold",
	"GoldIngot",
	"WheatSeeds",
	"CarrotSeeds",
	"PotatoSeeds",
	"PumpkinSeeds",
	"MelonSeeds",
	"GlowberrySeeds",
	"Sapling",
	"Wheat",
	"Carrot",
	"Potato",
	"Pumpkin",
	"Melon",
	"Glowberry",
	"Scrap",
	"Crystal",
}
for _, tool in Tools.List do
	table.insert(ORDER, tool.Item)
end

return table.freeze(ORDER)
