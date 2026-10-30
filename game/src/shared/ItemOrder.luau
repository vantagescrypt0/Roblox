--!strict
-- The order items are listed in on screen (Bag, trade window): blocks, materials, seeds,
-- crops, Warzone materials, every tool, then the challenge rewards.

local Gear = require(script.Parent.Gear)
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
	"Gravel",
	"Sand",
	"Path",
	"CoarseDirt",
	"FlowerGrass",
	"SnowyGrass",
	"Snow",
	"Ice",
	"Sandstone",
	"Terracotta",
	"RedTerracotta",
	"MossyCobblestone",
	"MossyStoneBricks",
	"CrackedStoneBricks",
	"BarnPlanks",
	"Thatch",
	"HayBale",
	"Crate",
	"Barrel",
	"Bookshelf",
	"MushroomCap",
	"MushroomStem",
	"Bucket",
	"WaterBucket",
	"LavaBucket",
	"BottomlessWaterBucket",
	"BottomlessLavaBucket",
	"Sticks",
	"Furnace",
	"Coal",
	"RawIron",
	"IronIngot",
	"RawGold",
	"GoldIngot",
	"CoalNode",
	"IronNode",
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
-- The skill challenges' rewards last: pets, armor sets, trophies
for _, pet in Gear.PetList do
	table.insert(ORDER, pet.Item)
end
for _, armor in Gear.ArmorList do
	table.insert(ORDER, armor.Item)
end
for _, trophy in Gear.TrophyList do
	table.insert(ORDER, trophy.Item)
end

return table.freeze(ORDER)
