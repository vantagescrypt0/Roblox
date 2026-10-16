--!strict
-- The beginner quest chain (see "Tutorial & Quests" in the vault). Each quest teaches
-- one thing.
--
-- Event quests count actions (e.g. "Harvest" 3 times). "Reach" quests check a value
-- (player level or a skill level) instead.

export type Reward = {
	XP: number?,
	Coins: number?,
	Items: { [string]: number }?,
}

export type Quest = {
	Text: string,
	Event: string, -- "Chop" | "Mine" | "Place" | "Plant" | "Harvest" | "VisitTown" | "Sell" | "BuySeeds" | "Craft" | "ReachLevel" | "ReachFarming"
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
		Text = "Right-click to place 3 blocks",
		Event = "Place",
		Target = 3,
		Reward = { XP = 10, Items = { Grass = 8 } },
	},
	{
		Text = "Plant 3 seeds on the farmland",
		Event = "Plant",
		Target = 3,
		Highlight = "Farmland",
		Reward = { XP = 15, Items = { WheatSeeds = 3 } },
	},
	{ Text = "Harvest 3 crops", Event = "Harvest", Target = 3, Highlight = "Farmland", Reward = { XP = 20 } },
	{
		Text = "Step through the portal to visit Town",
		Event = "VisitTown",
		Target = 1,
		Highlight = "PortalSurface",
		Reward = { XP = 15 },
	},
	{ Text = "Sell crops at the Market in Town", Event = "Sell", Target = 1, Reward = { XP = 15, Coins = 10 } },
	{ Text = "Buy seeds at the Market", Event = "BuySeeds", Target = 1, Reward = { XP = 15 } },
	{
		Text = "Craft Planks at your Crafting Table",
		Event = "Craft",
		Target = 1,
		Highlight = "CraftingTable",
		Reward = { XP = 25, Items = { Wood = 3 } },
	},
	{ Text = "Reach Farming level 3", Event = "ReachFarming", Target = 3, Reward = { XP = 40, Coins = 25 } },
	{ Text = "Reach level 10", Event = "ReachLevel", Target = 10, Reward = { Coins = 50, Items = { Stone = 8 } } },
}

return table.freeze(Quests)
