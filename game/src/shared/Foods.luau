--!strict
-- What you can eat in the Warzone, and how much of the hunger bar (out of 100) each fills. Hold
-- it in your hand and click. You grow it on your island and bring it in: hunger only counts in
-- the Warzone (your call, 2026-11-02). The numbers are Claude's picks.

local Foods: { [string]: number } = {
	Wheat = 6,
	Carrot = 12,
	Potato = 18,
	Glowberry = 20,
	Pumpkin = 24,
	Melon = 30,
	Strawberry = 40,
	Dragonfruit = 55,
	Starfruit = 75,
}

return table.freeze(Foods)
