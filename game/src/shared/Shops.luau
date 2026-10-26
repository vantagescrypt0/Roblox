--!strict
-- The shopkeepers in Town, each with their own stall (TownService builds them, ShopService
-- runs their trades, the client's ShopWindow shows them):
--   Buys     what they pay for, at Items.SellPrice (about half of Value)
--   Sells    what they sell, at Items.BuyPrice
--   SellAll  their window has a "Sell all" button for everything they buy (crops only, so
--            nobody sells their iron by accident)
-- Seeds need the crop's Farming level (Crops.luau) to buy.

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
		Buys = { "Wheat", "Carrot", "Potato", "Pumpkin", "Melon", "Glowberry" },
		Sells = { "WheatSeeds", "CarrotSeeds", "PotatoSeeds", "PumpkinSeeds", "MelonSeeds" },
		SellAll = true,
		Greetings = {
			"Hrmm! Got crops to sell?",
			"Fresh seeds, fair prices!",
			"Bring me Wheat, Carrots and Potatoes!",
			"Welcome to Town, friend!",
			"Hrmm... business is good today.",
		},
	},
	{
		Id = "Lumberjack",
		Name = "Lumberjack",
		Tagline = "Buys wood, sells saplings",
		Buys = { "Wood", "BirchWood", "SpruceWood", "CherryWood" },
		Sells = { "Sapling" },
		SellAll = false,
		Greetings = {
			"Timber! Got logs to sell?",
			"Fell a tree, plant a sapling. That's the rule.",
			"The tallest oaks grow in the Woodcutting World.",
			"Nothing smells better than fresh-cut oak.",
			"Cherry wood from the blossom hills? I'll pay well for that.",
		},
	},
	{
		Id = "Miner",
		Name = "Miner",
		Tagline = "Buys stone and ore, sells coal",
		Buys = { "Stone", "Coal", "RawIron", "IronIngot", "RawGold", "GoldIngot" },
		Sells = { "Coal" },
		SellAll = false,
		Greetings = {
			"Bring me stone and ore, I pay in coin!",
			"The Mining World's full of iron, if you've a stone pickaxe.",
			"Mind the dust, friend.",
			"Smelted ingots fetch more than raw iron.",
			"There's gold deep in that cave. Bring an iron pickaxe.",
		},
	},
	{
		Id = "Builder",
		Name = "Builder",
		Tagline = "Sells building blocks",
		Buys = {},
		Sells = {
			"Grass",
			"Dirt",
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
		},
		SellAll = false,
		Greetings = {
			"Building something? I've got blocks!",
			"A little wool makes any island cosy.",
			"Measure twice, place once.",
			"Cobblestone paths never go out of style.",
		},
	},
}

local byId: { [string]: Shop } = {}
for _, shop in List do
	byId[shop.Id] = shop
end

return table.freeze({
	List = table.freeze(List),
	ById = table.freeze(byId),
})
