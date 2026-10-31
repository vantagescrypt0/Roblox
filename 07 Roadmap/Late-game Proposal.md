# Late-game proposal (2026-10-29)

**Your answers (2026-10-29):** approved, start with Mining (phase 1). **Ore nodes are not sold**; instead **slivers**: now and then mining an ore drops a sliver of it (Gold Sliver, Amethyst Sliver...), and enough slivers craft that ore's node for your island; the better the ore, the rarer its slivers (rare but not impossible, so no inflation). The same goes for Woodcutting, Farming and Slaying later. Warzone chests and Skydrops will hold nodes too, and you'll add loot crates. All 5 new ores live in the Mining World's deep cave. Silver Ore keeps its name. The node rows in section 3 are replaced by this.

**Why:** coins top out around 45k an hour today, because every resource unlocks by skill level 30 (Mining even by 10). Your targets are ~1M an hour late game, best things at 10M–50M and the richest at 100M+ ([[Decision Log]] 2026-10-27). So each skill gets a ladder of new resources at higher levels, each worth about **2× the one before**, up to ~1.2M coins an hour near the top, plus big things to save for.

Numbers are coins an hour for a player at that resource's unlock (same model as `tools/balance.py`; it refits XP so 1 → 99 still takes ~25 hours).

## 1. New resources (13)

### Mining: a deeper cave under the Gold Chamber (5)
| Level | Ore | Drops | Needs | Coins/h | Where |
|---|---|---|---|---|---|
| 20 | Silver Ore | Raw Silver → Silver Ingot | Iron pickaxe | 55k | Silver Tunnels |
| 35 | Amethyst | Amethyst shard | Iron pickaxe | 120k | Amethyst Geode (a huge hollow crystal ball) |
| 50 | Sapphire | Sapphire | Amethyst pickaxe | 260k | Sapphire Lake (underground lake, glowing water) |
| 65 | Ruby | Ruby | Sapphire pickaxe | 550k | Magma Depths (lava rivers, basalt) |
| 80 | Starstone | Starstone → Starsteel Ingot | Ruby pickaxe | 1.2M | Star Vault (the very bottom, night-sky crystals) |

### Woodcutting: four new zone islands (4)
| Level | Tree | Coins/h | Zone |
|---|---|---|---|
| 40 | Maple | 100k | Maple Ridge (red and orange autumn hills) |
| 55 | Redwood | 230k | Redwood Giants (trees 4–5x taller than oak) |
| 70 | Mangrove | 520k | Mangrove Marsh (roots over water, fog) |
| 85 | Starwood | 1.2M | Starwood Hollow (glowing blue trees, fireflies) |

### Farming: four new zone islands (4)
| Level | Crop | Harvest with | Coins/h | Zone |
|---|---|---|---|---|
| 35 | Sugarcane | Hoe | 100k | Sugarcane Mesa (your reference shot) |
| 50 | Strawberry | Hoe | 230k | Strawberry Terraces |
| 65 | Dragonfruit | Axe (cactus) | 520k | Dragonfruit Dunes |
| 80 | Starfruit | Hoe | 1.2M | Starfruit Orchard |

Each new resource automatically gets its skill challenge with a **pet tier, armor tier and trophy** (the challenge system builds them per resource), so this also adds 13 pet tiers, 13 armor tiers and 13 trophies.

## 2. New tool tiers (2, x 5 kinds = 10 tools)
Today: Wooden, Stone, Iron, Crystal (Crystal needs Warzone crystals, and the Warzone is off).
- **Amethyst tools** (Amethyst + Iron Ingots): speed x8, mines Sapphire. Replaces Crystal as the 4th tier until the Warzone opens (or Crystal stays as a Warzone-only side tier).
- **Sapphire tools**, **Ruby tools**, **Starsteel tools**: each tier mines the next ore and is faster (x10, x12, x14).
That's 4 tiers past Iron. If that's too many, Sapphire and Ruby can share one tier.

## 3. Big things to buy (10M–50M)
| Item | Price | What it does |
|---|---|---|
| Island level 5 | 2M | A bigger build border (island levels only raise limits since 2026-10-31) |
| Island level 6 | 10M | Bigger again |
| Island level 7 | 40M | Bigger again (Config.Island.Spacing has room up to a border of ~350) |
| Gold Node (for your island) | 1.5M | A gold ore that grows back, like the Coal and Iron Nodes |
| Amethyst Node | 8M | Same, Amethyst |
| Sapphire Node | 25M | Same, Sapphire |
| Bottomless Water / Lava Bucket | 2.5M / 5M | Already in |

## 4. The order to build it in
1. **Mining depths + the new tool tiers** (Mining is furthest behind; the tools are needed for everything after).
2. **Woodcutting zones**.
3. **Farming zones**.
4. **Island tiers 5–7 and the nodes for sale**.
Each phase: art (blocks, items, crops), the zone, balance refit, Studio playtest, publish.

## Questions
- OK with these names, levels and prices? Swap any you don't like.
- 4 tool tiers past Iron, or fewer?
- Selling ore nodes: they pay back over time, so a player can earn on their island instead of in the worlds. Good for a Skyblock feel; say no if you'd rather keep top ores in the worlds only.
