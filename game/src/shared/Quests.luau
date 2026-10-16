--!strict
-- The beginner quest chain (see "Tutorial & Quests" in the vault). Each quest teaches
-- one thing; the last one ends at the Warzone unlock.
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
	Event: string, -- "Chop" | "Mine" | "Plant" | "Harvest" | "Sell" | "BuySeeds" | "Craft" | "ReachLevel" | "ReachFarming"
	Target: number,
	Highlight: string?, -- name of the island object to outline
	Reward: Reward,
}

local Quests: { Quest } = {
	{ Text = "Chop a tree", Event = "Chop", Target = 1, Highlight = "TreeTrunk_1", Reward = { XP = 10 } },
	{ Text = "Mine a rock", Event = "Mine", Target = 1, Highlight = "Rock_1", Reward = { XP = 10 } },
	{
		Text = "Plant 3 seeds",
		Event = "Plant",
		Target = 3,
		Highlight = "FarmPlot1",
		Reward = { XP = 15, Items = { WheatSeeds = 3 } },
	},
	{ Text = "Harvest 3 crops", Event = "Harvest", Target = 3, Highlight = "FarmPlot1", Reward = { XP = 20 } },
	{
		Text = "Sell crops at the Market",
		Event = "Sell",
		Target = 1,
		Highlight = "Market",
		Reward = { XP = 15, Coins = 10 },
	},
	{
		Text = "Buy seeds at the Market",
		Event = "BuySeeds",
		Target = 1,
		Highlight = "Market",
		Reward = { XP = 15 },
	},
	{
		Text = "Craft a Wooden Sword",
		Event = "Craft",
		Target = 1,
		Highlight = "Workbench",
		Reward = { XP = 25, Items = { Wood = 3 } },
	},
	{ Text = "Reach Farming level 3", Event = "ReachFarming", Target = 3, Reward = { XP = 40, Coins = 25 } },
	{
		Text = "Reach level 10 to unlock the Warzone",
		Event = "ReachLevel",
		Target = 10,
		Highlight = "WarzonePortal",
		Reward = { Coins = 50, Items = { Stone = 8 } },
	},
}

return table.freeze(Quests)
