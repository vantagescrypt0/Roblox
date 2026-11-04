--!strict
-- Island levels. Every island starts as the same small floating island; players build
-- outward from it, block by block, as far as their build border. Upgrading the island
-- only moves the border out (the island itself doesn't change), so it's a bigger limit,
-- not a new island. The build area is Border * 2 + 1 blocks across. Costs fit the coin
-- pace (tools/balance.py): level 2 after a couple of hours, level 3 a few hours of
-- mid-game, level 4 a long mid-game save, and levels 5-7 are the big things to save for on the
-- way to a billion.
-- Islands sit Config.Island.Spacing apart, which has room for borders up to ~350.

export type Tier = {
	Name: string,
	Cost: number, -- coins to upgrade to this level
	Border: number, -- you can build this many blocks out from the island's middle, each way
}

local IslandTiers: { Tier } = {
	{ Name = "Island level 1", Cost = 0, Border = 64 },
	{ Name = "Island level 2", Cost = 3000, Border = 96 },
	{ Name = "Island level 3", Cost = 40000, Border = 144 },
	{ Name = "Island level 4", Cost = 1000000, Border = 192 },
	{ Name = "Island level 5", Cost = 10000000, Border = 240 },
	{ Name = "Island level 6", Cost = 100000000, Border = 288 },
	{ Name = "Island level 7", Cost = 500000000, Border = 336 },
}

return table.freeze(IslandTiers)
