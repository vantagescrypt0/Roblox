--!strict
-- Island expansion tiers. Islands are made of blocks; each tier has a bigger radius
-- (in blocks), more farmland and more trees. Costs fit the coin pace (tools/balance.py):
-- Meadow after a couple of hours, Grove a few hours of mid-game, Grand a long mid-game save.

export type Tier = {
	Name: string,
	Cost: number, -- coins to expand to this tier
	Radius: number, -- in blocks
	Farm: { number }, -- farmland size {width, depth} in blocks
	Plots: number,
	Trees: number,
	Rocks: number,
}

local IslandTiers: { Tier } = {
	{ Name = "Starter Island", Cost = 0, Radius = 7, Farm = { 3, 2 }, Plots = 6, Trees = 2, Rocks = 1 },
	{ Name = "Meadow Island", Cost = 3000, Radius = 9, Farm = { 3, 3 }, Plots = 9, Trees = 3, Rocks = 2 },
	{ Name = "Grove Island", Cost = 40000, Radius = 11, Farm = { 4, 3 }, Plots = 12, Trees = 4, Rocks = 2 },
	{ Name = "Grand Island", Cost = 400000, Radius = 13, Farm = { 4, 4 }, Plots = 16, Trees = 6, Rocks = 3 },
}

return table.freeze(IslandTiers)
