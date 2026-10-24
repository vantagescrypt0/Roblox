--!strict
-- The beginner quest chain (see "Tutorial & Quests" in the vault). Each quest teaches
-- one thing, following Minecraft's early game: wood -> planks -> sticks -> pickaxe -> stone.
--
-- Event quests count actions (e.g. "Harvest" 3 times; "Craft:<recipe>" for one recipe).
-- "Reach" quests check a value (player level or a skill level) instead.

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
		Reward = { XP = 10 },
	},
	{
		Text = "Right-click the Crafting Table and craft Planks",
		Event = "Craft:Planks",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 10, Items = { Wood = 2 } },
	},
	{
		Text = "Craft Sticks",
		Event = "Craft:Sticks",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 10 },
	},
	{
		Text = "Craft a Wooden Pickaxe",
		Event = "Craft:WoodenPickaxe",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 20 },
	},
	{
		Text = "Hold your pickaxe and mine 3 Stone",
		Event = "Mine",
		Target = 3,
		Highlight = "Stone",
		Reward = { XP = 20, Items = { Grass = 8 } },
	},
	{ Text = "Right-click to place 3 blocks", Event = "Place", Target = 3, Reward = { XP = 10 } },
	{
		Text = "Click the farmland to plant 3 seeds",
		Event = "Plant",
		Target = 3,
		Highlight = "Farmland",
		Reward = { XP = 15, Items = { WheatSeeds = 3 } },
	},
	{
		Text = "Click ripe crops to harvest 3",
		Event = "Harvest",
		Target = 3,
		Highlight = "Farmland",
		Reward = { XP = 20 },
	},
	{
		Text = "Step through the portal to visit Town",
		Event = "VisitTown",
		Target = 1,
		Highlight = "PortalSurface",
		Reward = { XP = 15 },
	},
	{ Text = "Sell crops to the Merchant in Town", Event = "Sell", Target = 1, Reward = { XP = 15, Coins = 10 } },
	{ Text = "Buy seeds from the Merchant", Event = "BuySeeds", Target = 1, Reward = { XP = 15 } },
	{
		Text = "Craft a Stone Pickaxe",
		Event = "Craft:StonePickaxe",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 20, Items = { Stone = 4 } },
	},
	{
		Text = "Mine Iron Ore with your Stone Pickaxe",
		Event = "Mine:IronOre",
		Target = 1,
		Highlight = "IronOre",
		Reward = { XP = 20, Items = { Coal = 1 } },
	},
	{
		Text = "Craft a Furnace (8 Stone)",
		Event = "Craft:Furnace",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 20 },
	},
	{
		Text = "Place your Furnace and smelt an Iron Ingot",
		Event = "Craft:IronIngot",
		Target = 1,
		Highlight = "Furnace",
		Reward = { XP = 30, Coins = 15 },
	},
	{ Text = "Reach Farming level 3", Event = "ReachFarming", Target = 3, Reward = { XP = 40, Coins = 25 } },
	{ Text = "Reach level 10", Event = "ReachLevel", Target = 10, Reward = { Coins = 50, Items = { IronIngot = 3 } } },
}

return table.freeze(Quests)
