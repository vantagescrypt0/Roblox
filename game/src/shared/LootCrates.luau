--!strict
-- Loot Crates: open one from your Bag for one random prize. They're the main way to get the
-- late-game things that aren't in the Grinding Worlds (Ruby and Starstone nodes, Mangrove and
-- Starwood saplings, Strawberry, Dragonfruit and Starfruit seeds), along with Warzone chests.
-- The crate window shows these odds before you open one. The odds are Claude's picks, and
-- Weight adds up to 100, so each is a percentage ([[Kits]]).

export type Prize = { Item: string, Min: number, Max: number, Weight: number }

local Prizes: { Prize } = {
	{ Item = "Coal", Min = 16, Max = 32, Weight = 24 },
	{ Item = "IronIngot", Min = 6, Max = 12, Weight = 20 },
	{ Item = "GoldIngot", Min = 4, Max = 8, Weight = 15 },
	{ Item = "SilverIngot", Min = 3, Max = 6, Weight = 10 },
	{ Item = "Amethyst", Min = 3, Max = 5, Weight = 8 },
	{ Item = "Sapphire", Min = 2, Max = 4, Weight = 6 },
	{ Item = "SugarcaneSeeds", Min = 1, Max = 1, Weight = 3 },
	{ Item = "MapleSapling", Min = 1, Max = 1, Weight = 3 },
	{ Item = "RedwoodSapling", Min = 1, Max = 1, Weight = 2 },
	-- Late game
	{ Item = "StrawberrySeeds", Min = 1, Max = 1, Weight = 3 },
	{ Item = "MangroveSapling", Min = 1, Max = 1, Weight = 2 },
	{ Item = "RubyNode", Min = 1, Max = 1, Weight = 2 },
	{ Item = "DragonfruitSeeds", Min = 1, Max = 1, Weight = 1 },
	{ Item = "StarfruitSeeds", Min = 1, Max = 1, Weight = 0.4 },
	{ Item = "StarwoodSapling", Min = 1, Max = 1, Weight = 0.3 },
	{ Item = "StarstoneNode", Min = 1, Max = 1, Weight = 0.3 },
}

local total = 0
for _, prize in Prizes do
	total += prize.Weight
end

local LootCrates = {
	Item = "LootCrate",
	Prizes = table.freeze(Prizes),
}

-- Picks a prize, given a random number from 0 up to 1
function LootCrates.Roll(roll: number): Prize
	local left = roll * total
	for _, prize in Prizes do
		left -= prize.Weight
		if left < 0 then
			return prize
		end
	end
	return Prizes[1]
end

return table.freeze(LootCrates)
