--!strict
-- What Warzone chests hold. Your rules: all chests are the same, and the late game's nodes, saplings
-- and seeds come from here and from Loot Crates (Late-game Rule). The rest of this table is Claude's
-- pick, in one place so it's easy to change: food to keep you fighting, materials for crafting, a rare
-- Loot Crate and rarer late-game things. Each stack is one roll; Weight is how often, against the others.

export type Loot = { Item: string, Min: number, Max: number, Weight: number }

local Table: { Loot } = {
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
	{ Item = "LootCrate", Min = 1, Max = 1, Weight = 3 },
	{ Item = "StrawberrySeeds", Min = 1, Max = 1, Weight = 1.2 },
	{ Item = "MangroveSapling", Min = 1, Max = 1, Weight = 1 },
	{ Item = "RubyNode", Min = 1, Max = 1, Weight = 0.8 },
	{ Item = "DragonfruitSeeds", Min = 1, Max = 1, Weight = 0.5 },
	{ Item = "StarfruitSeeds", Min = 1, Max = 1, Weight = 0.2 },
	{ Item = "StarwoodSapling", Min = 1, Max = 1, Weight = 0.15 },
	{ Item = "StarstoneNode", Min = 1, Max = 1, Weight = 0.15 },
}

local total = 0
for _, entry in Table do
	total += entry.Weight
end

local WarzoneLoot = {
	MinStacks = 4,
	MaxStacks = 7,
	Table = table.freeze(Table),
}

-- Picks a stack, given a random number from 0 up to 1
function WarzoneLoot.Roll(roll: number): Loot
	local left = roll * total
	for _, entry in Table do
		left -= entry.Weight
		if left < 0 then
			return entry
		end
	end
	return Table[1]
end

return table.freeze(WarzoneLoot)
