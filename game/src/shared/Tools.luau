--!strict
-- Tool power system. Every tool has:
--   Kind       what it's best at: Sword (fighting), Pickaxe (stone), Axe (wood), Shovel
--              (dirt/grass), Hoe (turns grass and dirt into farmland)
--   Tier       1 = Wooden, 2 = Stone, 3 = Iron, 4 = Crystal; some blocks need a minimum tier to drop
--   Efficiency how much faster it breaks the blocks it's made for (hand = 1)
--   Damage     hit damage against monsters (and players in the Warzone)
--   Durability uses before it breaks (a block broken, a hit landed, a block tilled)
--   Cooldown   seconds between swings
--   Range      reach of a swing, in studs
--   Harvest    extra chance of a double crop while you hold it to harvest (hoes only)
-- Numbers follow Minecraft's ratios (wood 2x, stone 4x, iron 6x, top tier 8x mining speed).

export type Kind = "Sword" | "Pickaxe" | "Axe" | "Shovel" | "Hoe"

export type Tool = {
	Item: string,
	Kind: Kind,
	Tier: number,
	Efficiency: number,
	Damage: number,
	Durability: number,
	Cooldown: number,
	Range: number,
	Harvest: number,
}

local TIERS = {
	{ Name = "Wooden", Efficiency = 2, Durability = 60, DamageBonus = 0, Harvest = 0.02 },
	{ Name = "Stone", Efficiency = 4, Durability = 132, DamageBonus = 1, Harvest = 0.04 },
	{ Name = "Iron", Efficiency = 6, Durability = 250, DamageBonus = 2, Harvest = 0.07 },
	{ Name = "Crystal", Efficiency = 8, Durability = 600, DamageBonus = 3, Harvest = 0.12 },
}

-- Base damage per kind at tier 1, and how much each tier above adds
local KINDS: { [Kind]: { Damage: number, PerTier: number, Cooldown: number, Range: number } } = {
	Sword = { Damage = 12, PerTier = 9, Cooldown = 0.6, Range = 6 },
	Axe = { Damage = 10, PerTier = 7, Cooldown = 1.0, Range = 5.5 },
	Pickaxe = { Damage = 5, PerTier = 3, Cooldown = 0.8, Range = 5 },
	Shovel = { Damage = 4, PerTier = 2, Cooldown = 0.8, Range = 5 },
	Hoe = { Damage = 3, PerTier = 1, Cooldown = 0.8, Range = 5 },
}

-- Order tools are listed in (crafting window, inventory)
local KIND_ORDER: { Kind } = { "Pickaxe" :: Kind, "Axe" :: Kind, "Shovel" :: Kind, "Hoe" :: Kind, "Sword" :: Kind }

local list: { Tool } = {}
local byItem: { [string]: Tool } = {}

for tierIndex, tier in TIERS do
	for _, kind: Kind in KIND_ORDER do
		local stats = KINDS[kind]
		local tool: Tool = {
			Item = `{tier.Name}{kind}`,
			Kind = kind,
			Tier = tierIndex,
			-- Swords and hoes don't mine faster
			Efficiency = if kind == "Sword" or kind == "Hoe" then 1 else tier.Efficiency,
			Damage = stats.Damage + stats.PerTier * tier.DamageBonus,
			Durability = tier.Durability,
			Cooldown = stats.Cooldown,
			Range = stats.Range,
			Harvest = if kind == "Hoe" then tier.Harvest else 0,
		}
		table.insert(list, tool)
		byItem[tool.Item] = tool
	end
end

return table.freeze({
	List = table.freeze(list),
	ByItem = table.freeze(byItem),
	TierNames = { "Wooden", "Stone", "Iron", "Crystal" },
})
