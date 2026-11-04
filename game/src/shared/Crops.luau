--!strict
-- Crops, ordered from first to last unlocked. Each needs a minimum Farming level
-- (see "Skills & Levels" in the vault). Grow times are in seconds and keep counting
-- while the player is offline. Harvesting needs the right tool in your hand: a hoe, or an
-- axe for pumpkins, melons and dragonfruit.

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
	Rare: boolean?, -- its seeds aren't sold and it never gives a spare seed, so they stay rare
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
	-- Sugarcane Mesa, the Farming World's last zone: slivers craft its seeds (Slivers.luau)
	{
		Id = "Sugarcane",
		Seed = "SugarcaneSeeds",
		Product = "Sugarcane",
		Tool = "Hoe",
		FarmingLevel = 40,
		GrowTime = 300,
		FarmingXP = 70,
		PlayerXP = 23,
		Color = Color3.fromRGB(120, 190, 90),
		Rare = true,
	},
	-- Late game, on your own island only: seeds from loot crates and Warzone chests
	{
		Id = "Strawberry",
		Seed = "StrawberrySeeds",
		Product = "Strawberry",
		Tool = "Hoe",
		FarmingLevel = 50,
		GrowTime = 360,
		FarmingXP = 80,
		PlayerXP = 27,
		Color = Color3.fromRGB(224, 50, 64),
		Rare = true,
	},
	{
		Id = "Dragonfruit",
		Seed = "DragonfruitSeeds",
		Product = "Dragonfruit",
		Tool = "Axe",
		FarmingLevel = 65,
		GrowTime = 420,
		FarmingXP = 90,
		PlayerXP = 30,
		Color = Color3.fromRGB(236, 70, 160),
		Rare = true,
	},
	{
		Id = "Starfruit",
		Seed = "StarfruitSeeds",
		Product = "Starfruit",
		Tool = "Hoe",
		FarmingLevel = 80,
		GrowTime = 480,
		FarmingXP = 105,
		PlayerXP = 35,
		Color = Color3.fromRGB(255, 226, 110),
		Rare = true,
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
