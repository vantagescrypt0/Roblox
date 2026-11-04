# Kits

**Your call (2026-11-02):** copy the Skybounds **Looter** kit and rebrand it as the **Crate Keeper Kit**. No shards: if you buy the kit, you own it. Probably nerf it. Not built yet; it comes after the content on the [[Roadmap]].

## What Looter was in Skybounds
An Immortal Kit: claim it every 5 days to summon a random Loot Crate and open it for goodies. It stayed on your account through season resets, like a rank.

## Our version (proposal)
| | Skybounds Looter | Ours |
|---|---|---|
| Getting it | Shards: a chance to unlock, +5% per shard, otherwise one payout | One Robux purchase, yours for good |
| Claim | Every 5 days | Every **7 days** (the nerf; Claude's pick) |
| Reward | A random Loot Crate | One Loot Crate (`LootCrates.luau`, built 2026-11-02) |
| Claiming | `/kit` | A Kits window in the Menu |
| Season resets | Kept | Kept (resets are on hold anyway) |

- **Game pass, not a developer product:** a game pass is a one-time purchase that stays on the account, which is what "if they buy it they own it" means. It can't be traded (Skybounds shards could).
- **Loot Crates are built:** open one from your Bag for one random prize, with the odds shown first. They're one of the two sources of the late game ([[Late-game Rule]]); Warzone chests are the other, and they can hold crates too. The odds are Claude's picks.

## Rule to design around
A kit bought with Robux that pays out random crates may count as a **paid random item**, even though the buyer pays once and the crates come later. [[Roblox Policies]] says to check `PolicyService` → `ArePaidRandomItemsRestricted` per player. [[Monetization Principles]] also says no paid gambling aimed at minors. Before it ships:
1. Re-read the current rules (linked in [[Roblox Policies]]).
2. Show the crate's odds before purchase, in the kit's description and the crate window.
3. For restricted players, don't offer it, or give them a fixed reward instead of a random one.

## Still to decide
- [x] **The name:** Crate Keeper Kit (your pick). You turned down Scavenger because it didn't say the kit gives a loot crate.
- [ ] **The price** in Robux.
- [ ] **The nerf:** a claim every 7 days is Claude's pick. Is that enough?

## The other Skybounds kits, for reference
You shared these for the idea of what a kit can be; only Looter is being copied.
- **Combat sets (Medusa, Warlord, Duelist, Barbarian, Drifter):** a full armor set with a set bonus, weapons, consumables and extras. 7-day cooldown.
- **Necromancer:** 3 random drops from a list of spawners and boss eggs. 5-day cooldown.
- **Builder:** a stack of decorative blocks and a tool. 5-day cooldown.
