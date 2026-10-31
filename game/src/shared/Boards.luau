--!strict
-- The Challenges board's groups. Each group is its own chain of numbered challenges (done
-- one at a time, in order, like the Skybounds tutorial screen): Beginner (Quests.luau, the
-- tutorial the quest tracker starts on), the three Grinding Worlds, Crafting and your
-- Island, plus Slaying and the Warzone, which open with the Warzone.
--
-- Events are the same as in Quests.luau ("Mine:CoalOre", "Chop", "Craft:IronPickaxe"...),
-- plus "MineOre" (any ore), "CraftTool:<tier>" (any tool of a tier), "PlaceNode",
-- "PlantSapling", "PlaceTrophy", "Kill", "Extract" and "OpenChest". Reach challenges check a
-- value: "ReachLevel", "Reach:<skill>" and "ReachIsland" (the island's tier).
--
-- Progress is saved by challenge Id, so a challenge can be added anywhere in a list later
-- (players past it get it as their next one). Never change an Id.
-- Rewards: coins and player XP grow along each chain, roughly with the coin pace in
-- [[Economy & Values]] (~2k an hour early, ~50k mid, ~1M late); some give island nodes.

local Quests = require(script.Parent.Quests)

export type Challenge = {
	Id: string?, -- the beginner chain goes by number instead
	Text: string,
	Event: string,
	Target: number,
	Highlight: string?,
	Reward: Quests.Reward,
}

export type Board = {
	Id: string,
	Name: string,
	Icon: string, -- item (or block, or menu picture) shown on its square
	Color: string, -- a Theme.Color name
	Soon: string?, -- set while it can't be played yet: why
	Challenges: { Challenge },
}

-- One challenge: Id, text, event, target, coins, player XP and any items
local function c(
	id: string,
	text: string,
	event: string,
	target: number,
	coins: number,
	xp: number,
	items: { [string]: number }?
): Challenge
	return { Id = id, Text = text, Event = event, Target = target, Reward = { Coins = coins, XP = xp, Items = items } }
end

local List: { Board } = {
	{
		Id = "Beginner",
		Name = "Beginner",
		Icon = "WoodenPickaxe",
		Color = "Gold",
		Challenges = Quests :: any,
	},
	{
		Id = "Mining",
		Name = "Mining",
		Icon = "IronPickaxe",
		Color = "Blue",
		Challenges = {
			c("Mining:Coal25", "Mine 25 Coal Ore", "Mine:CoalOre", 25, 300, 500),
			c("Mining:Lv5", "Reach Mining level 5", "Reach:Mining", 5, 500, 750),
			c("Mining:Iron50", "Mine 50 Iron Ore", "Mine:IronOre", 50, 800, 1000, { Coal = 10 }),
			c("Mining:IronPickaxe", "Craft an Iron Pickaxe", "Craft:IronPickaxe", 1, 1000, 1250),
			c("Mining:Lv10", "Reach Mining level 10", "Reach:Mining", 10, 1500, 1500, { CoalNode = 1 }),
			c("Mining:Gold25", "Mine 25 Gold Ore deep in the Mining World", "Mine:GoldOre", 25, 2000, 2000),
			c("Mining:Coal500", "Mine 500 Coal Ore", "Mine:CoalOre", 500, 3000, 2500),
			c("Mining:Lv15", "Reach Mining level 15", "Reach:Mining", 15, 4000, 3000, { IronNode = 1 }),
			c("Mining:Iron500", "Mine 500 Iron Ore", "Mine:IronOre", 500, 5000, 3500),
			c("Mining:Gold250", "Mine 250 Gold Ore", "Mine:GoldOre", 250, 8000, 4500),
			c("Mining:Lv25", "Reach Mining level 25", "Reach:Mining", 25, 12000, 5500, { IronNode = 1 }),
			c("Mining:Ore2500", "Mine 2,500 ore of any kind", "MineOre", 2500, 15000, 7000),
			c("Mining:Lv40", "Reach Mining level 40", "Reach:Mining", 40, 25000, 9000),
			c("Mining:Gold2500", "Mine 2,500 Gold Ore", "Mine:GoldOre", 2500, 40000, 11000),
			c("Mining:Lv60", "Reach Mining level 60", "Reach:Mining", 60, 60000, 13000),
			c("Mining:Ore10000", "Mine 10,000 ore of any kind", "MineOre", 10000, 100000, 16000),
			c("Mining:Lv80", "Reach Mining level 80", "Reach:Mining", 80, 150000, 20000),
			c("Mining:Lv99", "Reach Mining level 99", "Reach:Mining", 99, 300000, 25000),
		},
	},
	{
		Id = "Woodcutting",
		Name = "Woodcutting",
		Icon = "IronAxe",
		Color = "Green",
		Challenges = {
			c("Woodcutting:Oak50", "Chop 50 Oak logs", "Chop:Wood", 50, 300, 500),
			c("Woodcutting:Plant5", "Plant 5 Saplings on your island", "PlantSapling", 5, 400, 600),
			c("Woodcutting:Lv5", "Reach Woodcutting level 5", "Reach:Woodcutting", 5, 500, 750),
			c("Woodcutting:IronAxe", "Craft an Iron Axe", "Craft:IronAxe", 1, 1000, 1250),
			c("Woodcutting:Lv10", "Reach Woodcutting level 10", "Reach:Woodcutting", 10, 1500, 1500),
			c("Woodcutting:Birch100", "Chop 100 Birch logs", "Chop:BirchWood", 100, 2000, 2000, { Sapling = 5 }),
			c("Woodcutting:Logs500", "Chop 500 logs", "Chop", 500, 3000, 2500),
			c("Woodcutting:Lv20", "Reach Woodcutting level 20", "Reach:Woodcutting", 20, 4000, 3000),
			c("Woodcutting:Spruce250", "Chop 250 Spruce logs", "Chop:SpruceWood", 250, 5000, 3500),
			c("Woodcutting:Lv30", "Reach Woodcutting level 30", "Reach:Woodcutting", 30, 8000, 4500),
			c("Woodcutting:Cherry250", "Chop 250 Cherry logs", "Chop:CherryWood", 250, 12000, 5500),
			c("Woodcutting:Logs2500", "Chop 2,500 logs", "Chop", 2500, 15000, 7000),
			c("Woodcutting:Lv40", "Reach Woodcutting level 40", "Reach:Woodcutting", 40, 25000, 9000),
			c("Woodcutting:Cherry2500", "Chop 2,500 Cherry logs", "Chop:CherryWood", 2500, 40000, 11000),
			c("Woodcutting:Lv60", "Reach Woodcutting level 60", "Reach:Woodcutting", 60, 60000, 13000),
			c("Woodcutting:Logs10000", "Chop 10,000 logs", "Chop", 10000, 100000, 16000),
			c("Woodcutting:Lv80", "Reach Woodcutting level 80", "Reach:Woodcutting", 80, 150000, 20000),
			c("Woodcutting:Lv99", "Reach Woodcutting level 99", "Reach:Woodcutting", 99, 300000, 25000),
		},
	},
	{
		Id = "Farming",
		Name = "Farming",
		Icon = "Wheat",
		Color = "Orange",
		Challenges = {
			c("Farming:Wheat50", "Harvest 50 Wheat", "Harvest:Wheat", 50, 300, 500),
			c("Farming:Till25", "Make 25 farmland with your hoe", "Till", 25, 300, 500),
			c("Farming:Plant25", "Plant 25 seeds", "Plant", 25, 400, 600, { CarrotSeeds = 5 }),
			c("Farming:Lv5", "Reach Farming level 5", "Reach:Farming", 5, 500, 750),
			c("Farming:Carrot100", "Harvest 100 Carrots", "Harvest:Carrot", 100, 1000, 1250, { PotatoSeeds = 5 }),
			c("Farming:IronHoe", "Craft an Iron Hoe", "Craft:IronHoe", 1, 1500, 1500),
			c("Farming:Lv10", "Reach Farming level 10", "Reach:Farming", 10, 2000, 2000),
			c("Farming:Potato200", "Harvest 200 Potatoes", "Harvest:Potato", 200, 3000, 2500),
			c("Farming:Lv15", "Reach Farming level 15", "Reach:Farming", 15, 4000, 3000, { PumpkinSeeds = 5 }),
			c("Farming:Pumpkin250", "Harvest 250 Pumpkins (with an axe)", "Harvest:Pumpkin", 250, 5000, 3500),
			c("Farming:Crops1000", "Harvest 1,000 crops", "Harvest", 1000, 8000, 4500),
			c("Farming:Lv25", "Reach Farming level 25", "Reach:Farming", 25, 12000, 5500, { MelonSeeds = 5 }),
			c("Farming:Melon500", "Harvest 500 Melons", "Harvest:Melon", 500, 15000, 7000),
			c("Farming:Lv40", "Reach Farming level 40", "Reach:Farming", 40, 25000, 9000),
			c("Farming:Crops5000", "Harvest 5,000 crops", "Harvest", 5000, 40000, 11000),
			c("Farming:Lv60", "Reach Farming level 60", "Reach:Farming", 60, 60000, 13000),
			c("Farming:Crops25000", "Harvest 25,000 crops", "Harvest", 25000, 100000, 16000),
			c("Farming:Lv80", "Reach Farming level 80", "Reach:Farming", 80, 150000, 20000),
			c("Farming:Lv99", "Reach Farming level 99", "Reach:Farming", 99, 300000, 25000),
		},
	},
	{
		Id = "Crafting",
		Name = "Crafting",
		Icon = "CraftingTable",
		Color = "Purple",
		Challenges = {
			c("Crafting:Planks10", "Craft Planks 10 times", "Craft:Planks", 10, 300, 500),
			c("Crafting:Stone3", "Craft 3 Stone tools", "CraftTool:Stone", 3, 400, 600),
			c("Crafting:Lv5", "Reach Crafting level 5", "Reach:Crafting", 5, 500, 750),
			c("Crafting:Iron25", "Smelt 25 Iron Ingots", "Craft:IronIngot", 25, 1000, 1250, { Coal = 10 }),
			c("Crafting:IronTools3", "Craft 3 Iron tools", "CraftTool:Iron", 3, 1500, 1500),
			c("Crafting:Lv10", "Reach Crafting level 10", "Reach:Crafting", 10, 2000, 2000),
			c("Crafting:Gold25", "Smelt 25 Gold Ingots", "Craft:GoldIngot", 25, 3000, 2500),
			c("Crafting:IronSet", "Craft a full set of 5 Iron tools", "CraftTool:Iron", 5, 4000, 3000),
			c("Crafting:Iron250", "Smelt 250 Iron Ingots", "Craft:IronIngot", 250, 5000, 3500),
			c("Crafting:Lv20", "Reach Crafting level 20", "Reach:Crafting", 20, 8000, 4500),
			c("Crafting:Craft1000", "Craft or smelt 1,000 times", "Craft", 1000, 12000, 5500),
			c("Crafting:Lv30", "Reach Crafting level 30", "Reach:Crafting", 30, 15000, 7000),
			c("Crafting:Gold1000", "Smelt 1,000 Gold Ingots", "Craft:GoldIngot", 1000, 25000, 9000),
			c("Crafting:Lv50", "Reach Crafting level 50", "Reach:Crafting", 50, 40000, 11000),
			c("Crafting:Craft5000", "Craft or smelt 5,000 times", "Craft", 5000, 60000, 13000),
			c("Crafting:Lv75", "Reach Crafting level 75", "Reach:Crafting", 75, 150000, 20000),
			c("Crafting:Lv99", "Reach Crafting level 99", "Reach:Crafting", 99, 300000, 25000),
		},
	},
	{
		Id = "Island",
		Name = "Island",
		Icon = "Grass",
		Color = "Teal",
		Challenges = {
			c("Island:Place50", "Place 50 blocks on your island", "Place", 50, 300, 500),
			c("Island:Meadow", "Upgrade your island to level 2", "ReachIsland", 2, 500, 1000),
			c("Island:Node", "Place a node on your island", "PlaceNode", 1, 500, 750),
			c("Island:Saplings10", "Plant 10 Saplings", "PlantSapling", 10, 800, 1000),
			c("Island:Place500", "Place 500 blocks", "Place", 500, 1500, 1500, { StoneBricks = 32 }),
			c("Island:Trophy", "Earn a trophy and place it on your island", "PlaceTrophy", 1, 3000, 2500),
			c("Island:Grove", "Upgrade your island to level 3", "ReachIsland", 3, 5000, 4000, { CoalNode = 1 }),
			c("Island:Place2500", "Place 2,500 blocks", "Place", 2500, 8000, 5000),
			c("Island:Grand", "Upgrade your island to level 4", "ReachIsland", 4, 25000, 9000, { IronNode = 1 }),
			c("Island:Trophies5", "Place 5 trophies", "PlaceTrophy", 5, 40000, 11000),
			c("Island:Place10000", "Place 10,000 blocks", "Place", 10000, 60000, 13000),
		},
	},
	{
		Id = "Slaying",
		Name = "Slaying",
		Icon = "IronSword",
		Color = "Red",
		Soon = "Opens with the Warzone",
		Challenges = {
			c("Slaying:Kill10", "Defeat 10 monsters", "Kill", 10, 500, 750),
			c("Slaying:Lv5", "Reach Combat level 5", "Reach:Combat", 5, 1000, 1250),
			c("Slaying:Kill100", "Defeat 100 monsters", "Kill", 100, 3000, 2500),
			c("Slaying:Lv15", "Reach Combat level 15", "Reach:Combat", 15, 6000, 4000),
			c("Slaying:Kill1000", "Defeat 1,000 monsters", "Kill", 1000, 15000, 7000),
			c("Slaying:Lv30", "Reach Combat level 30", "Reach:Combat", 30, 25000, 9000),
			c("Slaying:Kill5000", "Defeat 5,000 monsters", "Kill", 5000, 60000, 13000),
			c("Slaying:Lv60", "Reach Combat level 60", "Reach:Combat", 60, 100000, 16000),
			c("Slaying:Lv99", "Reach Combat level 99", "Reach:Combat", 99, 300000, 25000),
		},
	},
	{
		Id = "Warzone",
		Name = "Warzone",
		Icon = "Crystal",
		Color = "Navy",
		Soon = "Opens with the Warzone",
		Challenges = {
			c("Warzone:Extract1", "Make it out of the Warzone alive", "Extract", 1, 1000, 1000),
			c("Warzone:Chests10", "Open 10 Warzone chests", "OpenChest", 10, 3000, 2500),
			c("Warzone:Extract10", "Make it out 10 times", "Extract", 10, 8000, 5000),
			c("Warzone:Chests100", "Open 100 Warzone chests", "OpenChest", 100, 25000, 9000),
			c("Warzone:Extract50", "Make it out 50 times", "Extract", 50, 60000, 13000),
			c("Warzone:Extract250", "Make it out 250 times", "Extract", 250, 200000, 20000),
		},
	},
}

local byId: { [string]: Board } = {}
for _, board in List do
	byId[board.Id] = board
end

local Boards = {
	List = table.freeze(List),
	ById = table.freeze(byId),
}

-- The board's current challenge number: the first one not done (one past the end once
-- they're all done). `done` holds the Ids of finished challenges.
function Boards.CurrentIndex(board: Board, done: { [string]: boolean }): number
	for index, challenge in board.Challenges do
		if not (challenge.Id and done[challenge.Id]) then
			return index
		end
	end
	return #board.Challenges + 1
end

return table.freeze(Boards)
