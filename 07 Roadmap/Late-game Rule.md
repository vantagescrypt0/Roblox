# The late-game rule (your call, 2026-11-02)

This replaces where the [[Late-game Proposal]] put things. The Grinding Worlds hold each skill's **first 6 resources**. The rest are late game: they aren't in any world, and people only get them once they've figured out the system, by placing them on their own island.

| Skill | In the world (first 6) | Late game, island only |
|---|---|---|
| Mining | Coal, Iron, Gold, Silver, Amethyst, Sapphire | Ruby, Starstone (nodes) |
| Woodcutting | Oak, Birch, Spruce, Cherry, Maple, Redwood | Mangrove, Starwood (saplings) |
| Farming | Wheat, Carrot, Potato, Pumpkin, Melon, Sugarcane | Strawberry, Dragonfruit, Starfruit (seeds) |
| Slaying (planned) | The first 6 monsters | The last 2 (spawners) |

"First 5-6" was your wording; 6 for each is Claude's pick. Farming has one more late crop than the others because it already had an extra early one.

## How you get things
- **Late game:** only from **loot crates and Warzone chests**. Nothing late-game is sold, and none of it has slivers, since slivers only drop in the worlds.
- **World resources:** slivers. Enough of them craft a node (ore), a sapling (tree), seeds (Sugarcane) or a spawner (monsters, once Slaying is built).
- **Not in the Warzone:** resource nodes placed in the Warzone itself. You may ask for a few later; Claude doesn't add them until you do.

## What this changed
- **Removed from the worlds:** Magma Depths and Star Vault (Mining), Mangrove Marsh and Starwood Hollow (Woodcutting), Strawberry Terraces, Dragonfruit Dunes and Starfruit Orchard (Farming). The full versions are saved on the local git branch `saved/full-late-game-zones`.
- **Trees on islands:** every tree past oak grows from its own sapling, and felling one gives exactly one sapling back. So a rare tree can be replanted but never multiplies.
- **Rare crops** (Sugarcane and the late three) never give a spare seed, for the same reason.
- **Goals:** late-game challenges sit at the end of each board, so nobody gets stuck behind them.
- **Curves refit** with only world resources counted: skills `2458.1 x level^0.738`, about 22 hours to 99 for Mining and 26 for Woodcutting and Farming. Player level `3112.6 x level^1.02`, about 75 hours to 50. Modelled, not measured with real players.

## The coin targets: settled
Your call, 2026-11-02: raise what things sell for and scale it around billions, rather than speeding up nodes. See "The billion scale" in [[Economy & Values]].
