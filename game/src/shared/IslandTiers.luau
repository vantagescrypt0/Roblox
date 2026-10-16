--!strict
-- Island expansion tiers. Each tier is a bigger island model (ServerStorage.Assets.Islands.TierN)
-- with more farm plots, trees and rocks. Costs are placeholders; tune freely.

export type Tier = {
	Name: string,
	Cost: number, -- coins to expand to this tier
	Plots: number,
	Trees: number,
	Rocks: number,
}

local IslandTiers: { Tier } = {
	{ Name = "Starter Island", Cost = 0, Plots = 6, Trees = 2, Rocks = 2 },
	{ Name = "Meadow Island", Cost = 300, Plots = 9, Trees = 3, Rocks = 3 },
	{ Name = "Grove Island", Cost = 1500, Plots = 12, Trees = 4, Rocks = 4 },
	{ Name = "Grand Island", Cost = 6000, Plots = 16, Trees = 6, Rocks = 5 },
}

return table.freeze(IslandTiers)
