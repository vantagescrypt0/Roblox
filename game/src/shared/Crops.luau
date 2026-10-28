--!strict
-- Crops, ordered from first to last unlocked. Each needs a minimum Farming level
-- (see "Skills & Levels" in the vault). Grow times are in seconds and keep counting
-- while the player is offline. Harvesting needs the right tool in your hand: a hoe, or an
-- axe for pumpkins and melons.

export type Crop = {
	Id: string,
	Seed: string, -- item id used to plant
	Product: string, -- item id you harvest
	Tool: string, -- the tool kind you hold to harvest it (Tools.Kind)
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
		Tool = "Hoe",
		FarmingLevel = 1,
		GrowTime = 30,
		FarmingXP = 25,
		PlayerXP = 8,
		Color = Color3.fromRGB(232, 196, 92),
	},
	{
		Id = "Carrot",
		Seed = "CarrotSeeds",
		Product = "Carrot",
		Tool = "Hoe",
		FarmingLevel = 5,
		GrowTime = 75,
		FarmingXP = 30,
		PlayerXP = 10,
		Color = Color3.fromRGB(237, 124, 41),
	},
	{
		Id = "Potato",
		Seed = "PotatoSeeds",
		Product = "Potato",
		Tool = "Hoe",
		FarmingLevel = 10,
		GrowTime = 150,
		FarmingXP = 40,
		PlayerXP = 13,
		Color = Color3.fromRGB(196, 158, 104),
	},
	-- Pumpkin Hollow and the Melon Oasis in the Farming World
	{
		Id = "Pumpkin",
		Seed = "PumpkinSeeds",
		Product = "Pumpkin",
		Tool = "Axe",
		FarmingLevel = 15,
		GrowTime = 240,
		FarmingXP = 50,
		PlayerXP = 17,
		Color = Color3.fromRGB(230, 128, 30),
	},
	{
		Id = "Melon",
		Seed = "MelonSeeds",
		Product = "Melon",
		Tool = "Axe",
		FarmingLevel = 25,
		GrowTime = 360,
		FarmingXP = 60,
		PlayerXP = 20,
		Color = Color3.fromRGB(96, 160, 52),
	},
	-- Seeds only come from Warzone chests
	{
		Id = "Glowberry",
		Seed = "GlowberrySeeds",
		Product = "Glowberry",
		Tool = "Hoe",
		FarmingLevel = 8,
		GrowTime = 240,
		FarmingXP = 45,
		PlayerXP = 15,
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
