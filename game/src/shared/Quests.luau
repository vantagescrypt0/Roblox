--!strict
-- The beginner challenges (see "Tutorial & Quests" in the vault), shown one at a time by the
-- quest tracker and all together on the Challenges board (like the Skybounds tutorial).
-- Each teaches one thing, following Minecraft's early game: wood -> planks -> sticks ->
-- pickaxe -> stone, then out to Town and the Grinding Worlds. Some rewards are nodes for
-- your island (a Coal Node grows back after you mine it).
--
-- Event quests count actions (e.g. "Harvest" 3 times; "Craft:<recipe>" for one recipe;
-- "Harvest:<crop>", "Chop:<log>", "Mine:<ore>" for one kind). "Reach" quests check a
-- value instead: "ReachLevel" (player level) or "Reach:<skill>" (a skill level).

export type Reward = {
	XP: number?,
	Coins: number?,
	Items: { [string]: number }?,
}

export type Quest = {
	Text: string,
	Event: string,
	Target: number,
	Highlight: string?, -- name of the island object to outline
	Reward: Reward,
}

local Quests: { Quest } = {
	{
		Text = "Hold click on a tree to chop 3 Wood",
		Event = "Chop",
		Target = 3,
		Highlight = "Wood",
		Reward = { XP = 150 },
	},
	{
		Text = "Right-click the Crafting Table and craft Planks",
		Event = "Craft:Planks",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 150, Items = { Wood = 2 } },
	},
	{
		Text = "Craft Sticks",
		Event = "Craft:Sticks",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 150 },
	},
	{
		Text = "Craft a Wooden Pickaxe",
		Event = "Craft:WoodenPickaxe",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 350 },
	},
	{
		Text = "Hold your pickaxe and mine 3 Stone",
		Event = "Mine",
		Target = 3,
		Highlight = "Stone",
		Reward = { XP = 350, Items = { Grass = 8 } },
	},
	{ Text = "Right-click to place 3 blocks", Event = "Place", Target = 3, Reward = { XP = 150 } },
	{
		Text = "Right-click grass with your hoe to make farmland, then click it to plant 3 seeds",
		Event = "Plant",
		Target = 3,
		Reward = { XP = 250, Items = { WheatSeeds = 3 } },
	},
	{
		Text = "Hold your hoe and click ripe crops to harvest 3",
		Event = "Harvest",
		Target = 3,
		Highlight = "Farmland",
		Reward = { XP = 350 },
	},
	{
		Text = "Step through the portal to visit Town",
		Event = "VisitTown",
		Target = 1,
		Highlight = "PortalSurface",
		Reward = { XP = 250 },
	},
	{ Text = "Sell crops to the Merchant in Town", Event = "Sell", Target = 1, Reward = { XP = 250, Coins = 100 } },
	{ Text = "Buy seeds from the Merchant", Event = "BuySeeds", Target = 1, Reward = { XP = 250 } },
	{
		Text = "Craft a Stone Pickaxe",
		Event = "Craft:StonePickaxe",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 350, Items = { Stone = 4, CoalNode = 1 } },
	},
	{
		Text = "Mine Iron Ore with your Stone Pickaxe",
		Event = "Mine:IronOre",
		Target = 1,
		Highlight = "IronOre",
		Reward = { XP = 350, Items = { Coal = 1 } },
	},
	{
		Text = "Craft a Furnace (8 Stone)",
		Event = "Craft:Furnace",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 350 },
	},
	{
		Text = "Place your Furnace and smelt an Iron Ingot",
		Event = "Craft:IronIngot",
		Target = 1,
		Highlight = "Furnace",
		Reward = { XP = 500, Coins = 150 },
	},
	{ Text = "Reach Farming level 3", Event = "Reach:Farming", Target = 3, Reward = { XP = 700, Coins = 250 } },
	{
		Text = "Take the Mining portal in Town and mine 10 Coal Ore",
		Event = "Mine:CoalOre",
		Target = 10,
		Reward = { XP = 700, Items = { CoalNode = 1 } },
	},
	{
		Text = "Chop 20 logs in the Woodcutting World",
		Event = "Chop",
		Target = 20,
		Reward = { XP = 700, Coins = 300, Items = { Sapling = 3 } },
	},
	{
		Text = "Harvest 30 Wheat in the Farming World",
		Event = "Harvest:Wheat",
		Target = 30,
		Reward = { XP = 700, Coins = 300, Items = { CarrotSeeds = 3 } },
	},
	{
		Text = "Reach Mining level 5",
		Event = "Reach:Mining",
		Target = 5,
		Reward = { XP = 900, Items = { IronNode = 1 } },
	},
	{
		Text = "Reach level 10",
		Event = "ReachLevel",
		Target = 10,
		Reward = { Coins = 1000, Items = { IronIngot = 3 } },
	},
}

return table.freeze(Quests)
