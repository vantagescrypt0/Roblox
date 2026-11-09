--!strict
-- Tool power system. Every tool has:
--   Kind       what it's best at: Sword (fighting), Pickaxe (stone), Axe (wood), Shovel
--              (dirt/grass), Hoe (turns grass and dirt into farmland)
--   Tier       its power: 1 = Wooden, 2 = Stone, 3 = Iron, 4 = Amethyst (and Crystal, the
--              Warzone's side tier), 5 = Sapphire, 6 = Ruby, 7 = Starsteel; some blocks need a
--              minimum tier to drop
--   TierName   the tier's own name ("Amethyst"), which item ids and names start with
--   Efficiency how much faster it breaks the blocks it's made for (hand = 1)
--   Damage     a fully charged hit's damage, against monsters and players in the Warzone
--   Cooldown   seconds a swing takes to charge fully (Combat.luau)
--   Harvest    extra chance of a double crop while you hold it to harvest (hoes only)
-- Numbers follow Minecraft's ratios (wood 2x, stone 4x, iron 6x, diamond 8x mining speed),
-- then +2x a tier past it. Damage and swing times are Minecraft's too, with its damage x5.
-- Tools never wear out from use (later, a failed enchant or gem can break one).

export type Kind = "Sword" | "Pickaxe" | "Axe" | "Shovel" | "Hoe"

export type Tool = {
	Item: string,
	Kind: Kind,
	Tier: number,
	TierName: string,
	Efficiency: number,
	Damage: number,
	Cooldown: number,
	Harvest: number,
}

-- In the order they're listed (crafting window, Bag); Crystal last, as it's Warzone-only
local TIERS = {
	{ Name = "Wooden", Tier = 1, Efficiency = 2, DamageBonus = 0, Harvest = 0.02 },
	{ Name = "Stone", Tier = 2, Efficiency = 4, DamageBonus = 1, Harvest = 0.04 },
	{ Name = "Iron", Tier = 3, Efficiency = 6, DamageBonus = 2, Harvest = 0.07 },
	{ Name = "Amethyst", Tier = 4, Efficiency = 8, DamageBonus = 3, Harvest = 0.12 },
	{ Name = "Sapphire", Tier = 5, Efficiency = 10, DamageBonus = 4, Harvest = 0.16 },
	{ Name = "Ruby", Tier = 6, Efficiency = 12, DamageBonus = 5, Harvest = 0.2 },
	{ Name = "Starsteel", Tier = 7, Efficiency = 14, DamageBonus = 6, Harvest = 0.25 },
	{ Name = "Crystal", Tier = 4, Efficiency = 8, DamageBonus = 3, Harvest = 0.12 },
}
-- The name for each power, for "a Sapphire Pickaxe or better"
local TIER_NAMES = { "Wooden", "Stone", "Iron", "Amethyst", "Sapphire", "Ruby", "Starsteel" }

-- Base damage per kind at tier 1, and how much each tier above adds
local KINDS: { [Kind]: { Damage: number, PerTier: number, Cooldown: number } } = {
	Sword = { Damage = 20, PerTier = 3.5, Cooldown = 0.625 },
	Axe = { Damage = 35, PerTier = 2.5, Cooldown = 1.0 },
	Pickaxe = { Damage = 10, PerTier = 3.5, Cooldown = 0.83 },
	Shovel = { Damage = 12, PerTier = 3.5, Cooldown = 1.0 },
	Hoe = { Damage = 5, PerTier = 0, Cooldown = 0.5 },
}

-- Order tools are listed in (crafting window, inventory)
local KIND_ORDER: { Kind } = { "Pickaxe" :: Kind, "Axe" :: Kind, "Shovel" :: Kind, "Hoe" :: Kind, "Sword" :: Kind }

local list: { Tool } = {}
local byItem: { [string]: Tool } = {}

for _, tier in TIERS do
	for _, kind: Kind in KIND_ORDER do
		local stats = KINDS[kind]
		local tool: Tool = {
			Item = `{tier.Name}{kind}`,
			Kind = kind,
			Tier = tier.Tier,
			TierName = tier.Name,
			-- Swords and hoes don't mine faster
			Efficiency = if kind == "Sword" or kind == "Hoe" then 1 else tier.Efficiency,
			Damage = math.round(stats.Damage + stats.PerTier * tier.DamageBonus),
			Cooldown = stats.Cooldown,
			Harvest = if kind == "Hoe" then tier.Harvest else 0,
		}
		table.insert(list, tool)
		byItem[tool.Item] = tool
	end
end

-- The armour kits' swords ([[Kits]]): as strong as Sapphire, so the late game's Ruby and Starsteel still beat them. They
-- aren't in List, because nothing crafts them.
local sapphire = byItem.SapphireSword
local kitSwords: { Tool } = {}
for _, kit in { "Stormcaller", "Sunforged", "Emberguard", "Frostwarden", "Venomfang" } do
	local tool: Tool = {
		Item = `{kit}Sword`,
		Kind = "Sword",
		Tier = 5,
		TierName = kit,
		Efficiency = 1,
		Damage = sapphire.Damage,
		Cooldown = sapphire.Cooldown,
		Harvest = 0,
	}
	table.insert(kitSwords, tool)
	byItem[tool.Item] = tool
end

return table.freeze({
	List = table.freeze(list),
	KitSwords = table.freeze(kitSwords),
	ByItem = table.freeze(byItem),
	TierNames = TIER_NAMES,
})
