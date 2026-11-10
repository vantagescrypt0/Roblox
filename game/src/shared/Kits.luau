--!strict
-- What's sold with Robux ([[Kits]]). KitService runs it, and each price is set on Roblox, on the
-- pass or product itself. An id of 0 means it hasn't been made on Roblox yet, and nothing in the
-- game mentions it.
--   Crate Keeper Kit   1,499 Robux once, then a Loot Crate every week (your call, 2026-11-10; was 2,500)
--   A single crate     299 Robux, as often as you like (your call, 2026-11-10; was 800)
--                      Both on sale since 2026-11-10: "the same thing as a paid egg in any other roblox game, theres
--                      odds and its for an ingame item". Their odds are in their descriptions on Roblox and in the game.
--   Armour kits        bought once, then every week a full set, its sword, a shield and supplies. Nothing in them is
--                      random, so Roblox's paid random item rules don't apply. Armour stops at diamond, and none of it
--                      is late-game (Late-game Rule): what's in each is Claude's pick. Their specials are in KitPowers.
--                      Priced by how strong they are, each within one $10 card (your call, 2026-11-10): Venomfang 399,
--                      Sunforged 499, Stormcaller 599, Emberguard 699, Frostwarden 799

export type Reward = { Item: string, Count: number }
export type Kit = {
	Id: string,
	Name: string,
	Text: string, -- what the window says it is
	PassId: number, -- the game pass on Roblox; 0 = not on sale yet
	Cooldown: number, -- seconds between claims
	Rewards: { Reward },
	Random: boolean, -- pays out something random, so Roblox's paid random item rules apply
}

local WEEK = 7 * 24 * 60 * 60

local function armourKit(id: string, passId: number, extras: { Reward }): Kit
	local rewards: { Reward } = {
		{ Item = `{id}Helmet`, Count = 1 },
		{ Item = `{id}Chestplate`, Count = 1 },
		{ Item = `{id}Leggings`, Count = 1 },
		{ Item = `{id}Boots`, Count = 1 },
		{ Item = `{id}Sword`, Count = 1 },
		{ Item = "Shield", Count = 1 },
		{ Item = "Melon", Count = 16 },
		{ Item = "Glowberry", Count = 8 },
	}
	for _, extra in extras do
		table.insert(rewards, extra)
	end
	return {
		Id = id,
		Name = `{id} Kit`,
		Text = "Buy it once and it's yours for good. Every week: a full set of armour as strong as diamond, its sword, a shield and supplies.",
		PassId = passId,
		Cooldown = WEEK,
		Rewards = rewards,
		Random = false,
	}
end

local List: { Kit } = {
	{
		Id = "CrateKeeper",
		Name = "Crate Keeper Kit",
		Text = "Buy it once and it's yours for good: one Loot Crate every week.",
		PassId = 2074781079,
		Cooldown = WEEK,
		Rewards = { { Item = "LootCrate", Count = 1 } },
		Random = true,
	},
	armourKit("Stormcaller", 2075536668, {
		{ Item = "Crystal", Count = 16 },
		{ Item = "Sapphire", Count = 6 },
		{ Item = "SapphireNode", Count = 1 },
	}),
	armourKit("Sunforged", 2076094707, {
		{ Item = "GoldIngot", Count = 32 },
		{ Item = "Amethyst", Count = 8 },
		{ Item = "GoldNode", Count = 1 },
	}),
	armourKit("Emberguard", 2075836643, {
		{ Item = "Coal", Count = 64 },
		{ Item = "IronIngot", Count = 32 },
		{ Item = "IronNode", Count = 1 },
	}),
	armourKit("Frostwarden", 2078084502, {
		{ Item = "SilverIngot", Count = 24 },
		{ Item = "Crystal", Count = 8 },
		{ Item = "SilverNode", Count = 1 },
	}),
	armourKit("Venomfang", 2075032826, {
		{ Item = "Amethyst", Count = 12 },
		{ Item = "Scrap", Count = 32 },
		{ Item = "AmethystNode", Count = 1 },
	}),
}

local ById: { [string]: Kit } = {}
for _, kit in List do
	ById[kit.Id] = kit
end

return table.freeze({
	CrateProductId = 3730224176, -- the developer product for one Loot Crate; 0 = not on sale yet
	List = table.freeze(List),
	ById = table.freeze(ById),
	-- What someone gets instead of a random crate if Roblox doesn't allow them paid random items
	FixedItem = "GoldIngot",
	FixedCount = 8,
})
