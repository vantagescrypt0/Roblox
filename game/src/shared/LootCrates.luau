--!strict
-- Loot Crates: open one from your Bag and get 6 things at once. They're the main way to get the
-- late-game things that aren't in the Grinding Worlds (Ruby and Starstone nodes, Mangrove and
-- Starwood saplings, Strawberry, Dragonfruit and Starfruit seeds, Cinderkin and Voidling
-- spawners), along with Warzone chests, and they can hold pets.
--
-- Each of the 6 slots is rolled on its own. Your call (2026-11-09): a crate has a 33% chance of
-- holding something good, so sometimes there's nothing good in it, and no good thing is extremely
-- rare. Which prizes count as good, and their shares, are Claude's picks. A Boost Crystal is one of
-- them (your call, 2026-11-10: "rare in crates"), as rare as a tier VII pet: about 1 crate in 90.
--
-- Roblox's rules say every outcome and its real odds must be shown before anyone pays, so Chance
-- is worked out here from the same numbers the rolls use, and the windows only show it ([[Kits]]).

export type Prize = {
	Item: string,
	Min: number,
	Max: number,
	Weight: number, -- its share of its own list
	Good: boolean,
	Chance: number, -- percent, for any one slot
}

local SLOTS = 6
local GOOD_CRATE = 0.33 -- the chance a whole crate holds at least one good thing
local GOOD_SLOT = 1 - (1 - GOOD_CRATE) ^ (1 / SLOTS)

local function list(rows: { { any } }, good: boolean): { Prize }
	local total = 0
	for _, row in rows do
		total += row[4]
	end
	local share = if good then GOOD_SLOT else 1 - GOOD_SLOT
	local prizes: { Prize } = {}
	for _, row in rows do
		table.insert(prizes, {
			Item = row[1],
			Min = row[2],
			Max = row[3],
			Weight = row[4],
			Good = good,
			Chance = row[4] / total * share * 100,
		})
	end
	return prizes
end

local Good = list({
	{ "StrawberrySeeds", 1, 1, 11 },
	{ "MangroveSapling", 1, 1, 9 },
	{ "RubyNode", 1, 1, 9 },
	{ "DragonfruitSeeds", 1, 1, 7 },
	{ "StarfruitSeeds", 1, 1, 5 },
	{ "StarwoodSapling", 1, 1, 5 },
	{ "StarstoneNode", 1, 1, 5 },
	{ "CinderkinSpawner", 1, 1, 5 },
	{ "VoidlingSpawner", 1, 1, 4 },
	{ "MiningPet4", 1, 1, 7 },
	{ "WoodcuttingPet4", 1, 1, 7 },
	{ "FarmingPet4", 1, 1, 7 },
	{ "CombatPet4", 1, 1, 7 },
	{ "MiningPet7", 1, 1, 3 },
	{ "WoodcuttingPet7", 1, 1, 3 },
	{ "FarmingPet7", 1, 1, 3 },
	{ "CombatPet7", 1, 1, 3 },
	{ "BoostCrystal", 1, 1, 3 },
}, true)

local Common = list({
	{ "Coal", 16, 32, 23.2 },
	{ "IronIngot", 6, 12, 20 },
	{ "GoldIngot", 4, 8, 15 },
	{ "SilverIngot", 3, 6, 10 },
	{ "Amethyst", 3, 5, 8 },
	{ "Sapphire", 2, 4, 6 },
	{ "SugarcaneSeeds", 1, 1, 3 },
	{ "MapleSapling", 1, 1, 3 },
	{ "RedwoodSapling", 1, 1, 2 },
}, false)

local everything: { Prize } = {}
for _, prize in Good do
	table.insert(everything, prize)
end
for _, prize in Common do
	table.insert(everything, prize)
end

local LootCrates = {
	Item = "LootCrate",
	Slots = SLOTS,
	GoodCratePercent = math.round(GOOD_CRATE * 100),
	Prizes = table.freeze(everything),
}

local function pick(prizes: { Prize }, roll: number): Prize
	local total = 0
	for _, prize in prizes do
		total += prize.Weight
	end
	local left = roll * total
	for _, prize in prizes do
		left -= prize.Weight
		if left < 0 then
			return prize
		end
	end
	return prizes[1]
end

-- One slot, given two random numbers from 0 up to 1: is it good, and which prize
function LootCrates.Roll(goodRoll: number, pickRoll: number): Prize
	return pick(if goodRoll < GOOD_SLOT then Good else Common, pickRoll)
end

return table.freeze(LootCrates)
