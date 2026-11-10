--!strict
-- What the Warzone's chests hold. Your rules: all regular chests are the same, Skydrops are better, and the late
-- game's nodes, saplings and seeds come from here and from Loot Crates (Late-game Rule). The tables themselves are
-- Claude's picks, in one place so they're easy to change. Each stack is one roll; Weight is how often, against the
-- others. Gems you can only get from a node on your island (Ruby, Starstone) are never in here, only their nodes.

export type Loot = { Item: string, Min: number, Max: number, Weight: number }
export type Kind = "Chest" | "Skydrop" | "Legendary"
type LootTable = { MinStacks: number, MaxStacks: number, Stacks: { Loot }, Total: number }

local function make(minStacks: number, maxStacks: number, stacks: { Loot }): LootTable
	local total = 0
	for _, entry in stacks do
		total += entry.Weight
	end
	return { MinStacks = minStacks, MaxStacks = maxStacks, Stacks = table.freeze(stacks), Total = total }
end

local Tables: { [Kind]: LootTable } = {
	Chest = make(4, 7, {
		-- Food: hunger only counts here, so a chest can keep you going
		{ Item = "Carrot", Min = 3, Max = 8, Weight = 14 },
		{ Item = "Potato", Min = 3, Max = 8, Weight = 12 },
		{ Item = "Pumpkin", Min = 1, Max = 4, Weight = 6 },
		{ Item = "Melon", Min = 1, Max = 4, Weight = 6 },
		-- Materials
		{ Item = "Scrap", Min = 3, Max = 10, Weight = 16 },
		{ Item = "IronIngot", Min = 2, Max = 6, Weight = 12 },
		{ Item = "GoldIngot", Min = 1, Max = 4, Weight = 8 },
		{ Item = "SilverIngot", Min = 1, Max = 3, Weight = 6 },
		{ Item = "Crystal", Min = 1, Max = 3, Weight = 6 },
		{ Item = "Amethyst", Min = 1, Max = 2, Weight = 4 },
		{ Item = "Sapphire", Min = 1, Max = 1, Weight = 3 },
		{ Item = "GlowberrySeeds", Min = 1, Max = 2, Weight = 4 },
		-- Rare
		-- A quarter of what it was before crates held 6 things, so chests pay out as much late game as before
		{ Item = "LootCrate", Min = 1, Max = 1, Weight = 0.75 },
		{ Item = "StrawberrySeeds", Min = 1, Max = 1, Weight = 1.2 },
		{ Item = "MangroveSapling", Min = 1, Max = 1, Weight = 1 },
		{ Item = "RubyNode", Min = 1, Max = 1, Weight = 0.8 },
		{ Item = "DragonfruitSeeds", Min = 1, Max = 1, Weight = 0.5 },
		{ Item = "StarfruitSeeds", Min = 1, Max = 1, Weight = 0.2 },
		{ Item = "StarwoodSapling", Min = 1, Max = 1, Weight = 0.15 },
		{ Item = "StarstoneNode", Min = 1, Max = 1, Weight = 0.15 },
		{ Item = "CinderkinSpawner", Min = 1, Max = 1, Weight = 0.2 },
		{ Item = "VoidlingSpawner", Min = 1, Max = 1, Weight = 0.1 },
	}),
	-- Fuller than a chest, with bigger stacks, and the rare things about ten times likelier
	Skydrop = make(8, 12, {
		{ Item = "Pumpkin", Min = 3, Max = 8, Weight = 8 },
		{ Item = "Melon", Min = 3, Max = 8, Weight = 8 },
		{ Item = "GoldIngot", Min = 3, Max = 8, Weight = 12 },
		{ Item = "SilverIngot", Min = 3, Max = 6, Weight = 10 },
		{ Item = "Crystal", Min = 2, Max = 5, Weight = 10 },
		{ Item = "Amethyst", Min = 2, Max = 4, Weight = 8 },
		{ Item = "Sapphire", Min = 1, Max = 3, Weight = 6 },
		{ Item = "GlowberrySeeds", Min = 2, Max = 4, Weight = 6 },
		{ Item = "LootCrate", Min = 1, Max = 1, Weight = 1.25 },
		{ Item = "StrawberrySeeds", Min = 1, Max = 2, Weight = 3 },
		{ Item = "MangroveSapling", Min = 1, Max = 1, Weight = 2.5 },
		{ Item = "GoldNode", Min = 1, Max = 1, Weight = 2.5 },
		{ Item = "SilverNode", Min = 1, Max = 1, Weight = 2 },
		{ Item = "AmethystNode", Min = 1, Max = 1, Weight = 1.5 },
		{ Item = "SapphireNode", Min = 1, Max = 1, Weight = 1 },
		{ Item = "RubyNode", Min = 1, Max = 1, Weight = 1.5 },
		{ Item = "DragonfruitSeeds", Min = 1, Max = 1, Weight = 1 },
		{ Item = "StarfruitSeeds", Min = 1, Max = 1, Weight = 0.5 },
		{ Item = "StarwoodSapling", Min = 1, Max = 1, Weight = 0.4 },
		{ Item = "StarstoneNode", Min = 1, Max = 1, Weight = 0.4 },
		{ Item = "CinderkinSpawner", Min = 1, Max = 1, Weight = 0.7 },
		{ Item = "VoidlingSpawner", Min = 1, Max = 1, Weight = 0.35 },
	}),
	-- Worth the wait and the fight: no food or scrap, and the late game's best things are far likelier. Nodes last
	-- for ever on your island, so even here you'd expect about one good one in each. A Boost Crystal is in about one
	-- Legendary in five (your call, 2026-11-10: "legendary skydrops"; how often is Claude's pick).
	Legendary = make(14, 18, {
		{ Item = "GoldIngot", Min = 8, Max = 16, Weight = 10 },
		{ Item = "Crystal", Min = 4, Max = 8, Weight = 10 },
		{ Item = "Amethyst", Min = 4, Max = 8, Weight = 10 },
		{ Item = "Sapphire", Min = 3, Max = 6, Weight = 10 },
		{ Item = "LootCrate", Min = 1, Max = 3, Weight = 10 },
		{ Item = "AmethystNode", Min = 1, Max = 1, Weight = 2.5 },
		{ Item = "SapphireNode", Min = 1, Max = 1, Weight = 2.5 },
		{ Item = "RubyNode", Min = 1, Max = 1, Weight = 2.5 },
		{ Item = "StarstoneNode", Min = 1, Max = 1, Weight = 1.5 },
		{ Item = "StrawberrySeeds", Min = 1, Max = 3, Weight = 5 },
		{ Item = "DragonfruitSeeds", Min = 1, Max = 2, Weight = 5 },
		{ Item = "StarfruitSeeds", Min = 1, Max = 2, Weight = 4 },
		{ Item = "MangroveSapling", Min = 1, Max = 2, Weight = 4 },
		{ Item = "StarwoodSapling", Min = 1, Max = 2, Weight = 3 },
		{ Item = "CinderkinSpawner", Min = 1, Max = 1, Weight = 2.5 },
		{ Item = "VoidlingSpawner", Min = 1, Max = 1, Weight = 1.5 },
		{ Item = "BoostCrystal", Min = 1, Max = 1, Weight = 1.2 },
	}),
}

local WarzoneLoot = {
	Tables = table.freeze(Tables),
}

-- How many stacks this kind of chest holds, between
function WarzoneLoot.Stacks(kind: Kind): (number, number)
	local chosen = Tables[kind]
	return chosen.MinStacks, chosen.MaxStacks
end

-- Picks a stack, given a random number from 0 up to 1
function WarzoneLoot.Roll(kind: Kind, roll: number): Loot
	local chosen = Tables[kind]
	local left = roll * chosen.Total
	for _, entry in chosen.Stacks do
		left -= entry.Weight
		if left < 0 then
			return entry
		end
	end
	return chosen.Stacks[1]
end

return table.freeze(WarzoneLoot)
