--!strict
-- Boost crystals, like Skybounds' Boost Gems (your call, 2026-11-10; reference in 02 Research/References/Skybounds/
-- boosts). Three trees of five boosts. Each crystal you put into a tree unlocks its next boost, in order, so a tree
-- with 3 crystals has its first three. Crystals are yours for good, and once each season you can take them all back
-- out and put them in again (BoostService). Your calls: 399 Robux a crystal, also a rare find in Loot Crates and
-- Legendary Skydrops, and the list below with the Warzone's leave at 5 seconds. Where Skycore has no match for a
-- Skybounds boost (no monsters in the Warzone, no armour durability, no hoppers yet) the replacement is Claude's.
-- "50% faster" means it takes 1/1.5 of the time; "twice as fast", half.
--
-- Everything reads a save's `Boosts` (DataService), so a service that has the save can ask without BoostService.

export type TreeId = "Warzone" | "Player" | "Island"
export type Tree = { Id: TreeId, Name: string, Where: string, Boosts: { string } }

local PER_TREE = 5

local Trees: { Tree } = {
	{
		Id = "Warzone",
		Name = "Warzone Boosts",
		Where = "Only in the Warzone",
		Boosts = {
			"Leave in 5 seconds instead of 7",
			"Hunger drains half as fast",
			"Health regrows 50% faster while you're fed",
			"10% chance of an extra item in chests and Skydrops",
			"+3 hearts",
		},
	},
	{
		Id = "Player",
		Name = "Player Boosts",
		Where = "Everywhere",
		Boosts = {
			"+25% Combat XP from monsters",
			"+5% coins on everything you sell",
			"10% chance of an extra monster drop",
			"+50% damage to monsters",
			"Fly everywhere except the Warzone",
		},
	},
	{
		Id = "Island",
		Name = "Island Boosts",
		Where = "Only on your own island",
		Boosts = {
			"Ore nodes grow back 50% faster",
			"Crops and saplings grow 50% faster",
			"Ore nodes grow back twice as fast",
			"Crops and saplings grow twice as fast",
			"+25% skill XP from what you gather there",
		},
	},
}

local ById: { [string]: Tree } = {}
for _, tree in Trees do
	ById[tree.Id] = tree
end

local Boosts = {
	Item = "BoostCrystal", -- every crystal, bought or found, is this item: hold it and right-click to redeem it
	Price = 399, -- Robux, set on the product itself (Creator Hub); this is only what the notes say
	ProductId = 3730196955, -- the developer product for one crystal (made 2026-11-10); 0 = not on sale
	PerTree = PER_TREE,
	Most = PER_TREE * #Trees, -- crystals that max out every tree
	Trees = table.freeze(Trees),
	ById = table.freeze(ById),

	-- The numbers
	LeaveSeconds = 5, -- Warzone 1 (everyone else: 7)
	HungerScale = 0.5, -- Warzone 2: of every bit of hunger lost
	RegenScale = 1.5, -- Warzone 3
	ExtraLootChance = 0.1, -- Warzone 4: the first time you open a chest or Skydrop
	ExtraHealth = 30, -- Warzone 5: three hearts of 10
	MonsterXPScale = 1.25, -- Player 1
	SellScale = 1.05, -- Player 2
	ExtraDropChance = 0.1, -- Player 3
	MonsterDamageScale = 1.5, -- Player 4
	IslandXPScale = 1.25, -- Island 5
}

export type Save = { Crystals: number, Warzone: number, Player: number, Island: number, ResetSeason: number }

-- A save's crystals (an old save without any has none)
function Boosts.Of(data: any): Save
	local saved = data and data.Boosts
	return saved or { Crystals = 0, Warzone = 0, Player = 0, Island = 0, ResetSeason = 0 }
end

-- How many crystals are in this tree (0 to 5)
function Boosts.Level(data: any, tree: TreeId): number
	return (Boosts.Of(data) :: any)[tree] or 0
end

-- Whether this tree's boost number `index` (1 to 5) is unlocked
function Boosts.Has(data: any, tree: TreeId, index: number): boolean
	return Boosts.Level(data, tree) >= index
end

-- Crystals owned but not in a tree
function Boosts.Free(data: any): number
	local saved = Boosts.Of(data)
	return math.max(0, saved.Crystals - saved.Warzone - saved.Player - saved.Island)
end

-- How long a node takes to grow back, or a crop or sapling to grow, on this save's own island
function Boosts.NodeTime(data: any, seconds: number): number
	if Boosts.Has(data, "Island", 3) then
		return seconds / 2
	elseif Boosts.Has(data, "Island", 1) then
		return seconds / 1.5
	end
	return seconds
end

function Boosts.GrowTime(data: any, seconds: number): number
	if Boosts.Has(data, "Island", 4) then
		return seconds / 2
	elseif Boosts.Has(data, "Island", 2) then
		return seconds / 1.5
	end
	return seconds
end

return table.freeze(Boosts)
