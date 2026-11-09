--!strict
-- The shopkeepers in Town, each with their own stall (TownService builds them, ShopService
-- runs their trades, the client's ShopWindow shows them):
--   Buys     what they pay for, at Items.SellPrice (about half of Value)
--   Sells    what they sell, at Items.BuyPrice
--   SellAll  their window has a "Sell all" button for everything they buy (crops only, so
--            nobody sells their iron by accident)
-- Seeds need the crop's Farming level (Crops.luau) to buy.

local Decorations = require(script.Parent.Decorations)

export type Shop = {
	Id: string,
	Name: string,
	Tagline: string,
	Buys: { string },
	Sells: { string },
	SellAll: boolean,
	Greetings: { string },
}

local List: { Shop } = {
	{
		Id = "Merchant",
		Name = "Merchant",
		Tagline = "Buys crops, sells seeds",
		Buys = {
			"Wheat",
			"Carrot",
			"Potato",
			"Pumpkin",
			"Melon",
			"Sugarcane",
			"Strawberry",
			"Dragonfruit",
			"Starfruit",
			"Glowberry",
		},
		Sells = { "WheatSeeds", "CarrotSeeds", "PotatoSeeds", "PumpkinSeeds", "MelonSeeds" },
		SellAll = true,
		Greetings = {
			"Hrmm! Got crops to sell?",
			"Fresh seeds, fair prices!",
			"Bring me Wheat, Carrots and Potatoes!",
			"Welcome to Town, friend!",
			"I can't sell you Starfruit seeds. Nobody can. You'll have to earn those.",
			"Hrmm... business is good today.",
		},
	},
	{
		Id = "Lumberjack",
		Name = "Lumberjack",
		Tagline = "Buys wood, sells saplings",
		Buys = {
			"Wood",
			"BirchWood",
			"SpruceWood",
			"CherryWood",
			"MapleWood",
			"Redwood",
			"MangroveWood",
			"Starwood",
		},
		Sells = { "Sapling" },
		SellAll = false,
		Greetings = {
			"Timber! Got logs to sell?",
			"Fell a tree, plant a sapling. That's the rule.",
			"The tallest oaks grow in the Woodcutting World.",
			"Nothing smells better than fresh-cut oak.",
			"Cherry wood from the blossom hills? I'll pay well for that.",
			"Past the old zones, the trees get bigger. So do my prices.",
			"Starwood? I've only ever seen one log of it. Beautiful.",
		},
	},
	{
		Id = "Miner",
		Name = "Miner",
		Tagline = "Buys stone and ore, sells coal",
		Buys = {
			"Stone",
			"Coal",
			"RawIron",
			"IronIngot",
			"RawGold",
			"GoldIngot",
			"RawSilver",
			"SilverIngot",
			"StarsteelIngot",
			"Amethyst",
			"Sapphire",
			"Ruby",
			"Starstone",
		},
		Sells = { "Coal" },
		SellAll = false,
		Greetings = {
			"Bring me stone and ore, I pay in coin!",
			"The Mining World's full of iron, if you've a stone pickaxe.",
			"Mind the dust, friend.",
			"Smelted ingots fetch more than raw iron.",
			"There's gold deep in that cave. Bring an iron pickaxe.",
			"Under the gold there's silver, and gems deeper still.",
		},
	},
	{
		Id = "Slayer",
		Name = "Slayer",
		Tagline = "Buys monster drops",
		Buys = {
			"SlimeGel",
			"Thorn",
			"ToughHide",
			"OldBone",
			"Glowcap",
			"FrostFur",
			"EmberCore",
			"VoidShard",
		},
		Sells = {},
		SellAll = true,
		Greetings = {
			"Back from the Slaying World in one piece? Show me what you've got.",
			"Slime Gel, Thorns, Hide... I'll buy the lot.",
			"Keep your sword sharp and your head low.",
			"Frostfang's no place for the unprepared.",
			"An Ember Core? Bring me one of those and we'll talk real money.",
		},
	},
	{
		Id = "Builder",
		Name = "Builder",
		Tagline = "Sells blocks, decorations, water and lava",
		Buys = {},
		Sells = {
			"WaterBucket",
			"LavaBucket",
			"Grass",
			"Dirt",
			"Planks",
			"Stone",
			"Cobblestone",
			"StoneBricks",
			"Bricks",
			"SmoothStone",
			"Plaster",
			"DarkPlanks",
			"Glass",
			"RoofRed",
			"RoofSlate",
			"RedWool",
			"WhiteWool",
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
			"Mud",
			"DuskGrass",
			"Obsidian",
			"DarkStone",
			"Runestone",
			"BottomlessWaterBucket",
			"BottomlessLavaBucket",
		},
		SellAll = false,
		Greetings = {
			"Building something? I've got blocks!",
			"Lava meets water, and you get stone. Try it on your island!",
			"A Bottomless Bucket never runs dry. Worth every coin.",
			"A little wool makes any island cosy.",
			"Measure twice, place once.",
			"Cobblestone paths never go out of style.",
		},
	},
}

-- The Builder sells every decoration too
for _, shop in List do
	if shop.Id == "Builder" then
		for _, itemId in Decorations.Items do
			table.insert(shop.Sells, itemId)
		end
	end
end

local byId: { [string]: Shop } = {}
for _, shop in List do
	byId[shop.Id] = shop
end

return table.freeze({
	List = table.freeze(List),
	ById = table.freeze(byId),
})
