--!strict
-- Crops, ordered from first to last unlocked. Each needs a minimum Farming level
-- (see "Skills & Levels" in the vault). Grow times are in seconds and keep counting
-- while the player is offline.

export type Crop = {
	Id: string,
	Seed: string, -- item id used to plant
	Product: string, -- item id you harvest
	FarmingLevel: number,
	GrowTime: number,
	FarmingXP: number,
	PlayerXP: number,
	Color: Color3, -- ripe crop color
}

local Crops: { Crop } = {
	{
		Id = "Wheat",
		Seed = "WheatSeeds",
		Product = "Wheat",
		FarmingLevel = 1,
		GrowTime = 30,
		FarmingXP = 10,
		PlayerXP = 5,
		Color = Color3.fromRGB(232, 196, 92),
	},
	{
		Id = "Carrot",
		Seed = "CarrotSeeds",
		Product = "Carrot",
		FarmingLevel = 5,
		GrowTime = 75,
		FarmingXP = 25,
		PlayerXP = 12,
		Color = Color3.fromRGB(237, 124, 41),
	},
	{
		Id = "Potato",
		Seed = "PotatoSeeds",
		Product = "Potato",
		FarmingLevel = 10,
		GrowTime = 150,
		FarmingXP = 55,
		PlayerXP = 25,
		Color = Color3.fromRGB(196, 158, 104),
	},
	-- Seeds only come from Warzone chests
	{
		Id = "Glowberry",
		Seed = "GlowberrySeeds",
		Product = "Glowberry",
		FarmingLevel = 8,
		GrowTime = 240,
		FarmingXP = 90,
		PlayerXP = 45,
		Color = Color3.fromRGB(120, 230, 255),
	},
}

local byId: { [string]: Crop } = {}
for _, crop in Crops do
	byId[crop.Id] = crop
end

return table.freeze({
	List = table.freeze(Crops),
	ById = table.freeze(byId),
})
