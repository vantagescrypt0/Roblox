--!strict
-- Swords, weakest to strongest. You always hold the best one you own.

export type Weapon = {
	Item: string,
	Damage: number,
	Range: number, -- studs in front of you
	Cooldown: number, -- seconds between swings
	Color: Color3,
	Material: Enum.Material,
}

local Weapons: { Weapon } = {
	{
		Item = "WoodenSword",
		Damage = 12,
		Range = 6,
		Cooldown = 0.6,
		Color = Color3.fromRGB(150, 105, 60),
		Material = Enum.Material.Wood,
	},
	{
		Item = "StoneSword",
		Damage = 20,
		Range = 6,
		Cooldown = 0.6,
		Color = Color3.fromRGB(140, 140, 140),
		Material = Enum.Material.Slate,
	},
	{
		Item = "CrystalSword",
		Damage = 32,
		Range = 7,
		Cooldown = 0.5,
		Color = Color3.fromRGB(120, 220, 255),
		Material = Enum.Material.Glass,
	},
}

local byItem: { [string]: Weapon } = {}
for _, weapon in Weapons do
	byItem[weapon.Item] = weapon
end

return table.freeze({
	List = table.freeze(Weapons),
	ByItem = table.freeze(byItem),
})
