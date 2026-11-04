# Mining phase: build plan (2026-10-31)

**Update 2026-11-02:** the XP refit and the Ruby and Starsteel tools noted below are done; see [[Farming Phase Plan]]. Under the [[Late-game Rule]], Ruby and Starstone left the world: the Magma Depths and Star Vault are gone, and those two nodes come only from loot crates and Warzone chests.

Phase 1 of the approved [[Late-game Proposal]], with the approved [[Crafting Proposal]] parts that come with the new ores. Nothing here is new content beyond those two approvals; numbers come from `tools/balance.py`.

## The ores (the deep cave, under the Gold Chamber)
| Level | Block | Drop | Pickaxe | XP | Sells for | Coins/h | Zone |
|---|---|---|---|---|---|---|---|
| 20 | Silver Ore | Raw Silver → Silver Ingot (Furnace, + Coal) | Iron | 100 | 33 | ~55k | Silver Tunnels |
| 35 | Amethyst Ore | Amethyst | Iron | 110 | 61 | ~120k | Amethyst Geode |
| 50 | Sapphire Ore | Sapphire | Amethyst | 120 | 114 | ~260k | Sapphire Lake |
| 65 | Ruby Ore | Ruby | Sapphire | 130 | 213 | ~550k | Magma Depths |
| 80 | Starstone Ore | Starstone → Starsteel Ingot (Furnace: Starstone + Iron Ingot + Gold Ingot) | Ruby | 140 | 426 | ~1.2M | Star Vault |

- Hardness 3.5 / 4 / 4.5 / 5 / 5.5. All are regrowing nodes with Empty Ore, slower the rarer (Silver 120 s up to Starstone 300 s).
- XP is held a little low (rising 100 → 140 a block): the skill curve stays as it is until Woodcutting and Farming get their late resources, then all three are refit together. Until then Mining 1 → 99 is about 20 hours instead of 25.
- Each ore gets its skill challenge (pet, armor set and trophy tiers) through `Challenges.luau`, like the others.

## Slivers and nodes
- Mining any ore sometimes drops a **sliver** of it: Coal 1 in 150, Iron 1 in 250, Gold 1 in 400, Silver 1 in 600, Amethyst 1 in 900, Sapphire 1 in 1,300, Ruby 1 in 1,800, Starstone 1 in 2,500. Flat chances (no level or armor bonus), so they stay rare. (Rates, node costs, regrow times and Crafting levels on this page are Claude's picks; say if you want them changed.)
- **N slivers craft that ore's node** at the Crafting Table: Coal 10, Iron 10, Gold 12, Silver 12, Amethyst 15, Sapphire 15, Ruby 20, Starstone 20. New node items: Gold, Silver, Amethyst, Sapphire, Ruby, Starstone (Coal and Iron exist).
- Not sold by any shop. Warzone chests and Skydrops will hold nodes later.

## Tool tiers and parts (from the Crafting Proposal)
| Tier | Head | Handle | Binding | Station | Needs |
|---|---|---|---|---|---|
| Amethyst | Refined Amethyst (2 Amethyst + 1 Silver Ingot, Gem Bench) | Birch Handle (Birch Wood + Iron Plate, Anvil) | Rope | Anvil | Crafting 15, skill 35 |
| Sapphire | Refined Sapphire (2 Sapphire + 1 Gold Ingot, Gem Bench) | Spruce Handle (Spruce Wood + Silver Plate, Anvil) | Rope | Anvil | Crafting 25, skill 50 |
| Ruby | Refined Ruby (2 Ruby + Silver Ingot + Gold Ingot, Gem Bench) | Cherry Handle (Cherry Wood + Gold Plate, Anvil) | Cane Rope (Rope + 4 Sugarcane) | Anvil | Crafting 35, skill 65 |
| Starsteel | Starsteel Plate (2 Starsteel Ingots, Anvil) | Redwood Handle (Redwood + Starsteel Ingot) | Cane Rope | Anvil | Crafting 45, skill 80 |

- Speeds x8 / x10 / x12 / x14. Crystal stays a Warzone side tier at x8 (same tier number as Amethyst).
- **Ruby and Starsteel tools wait for Sugarcane (Farming phase) and Redwood (Woodcutting phase).** So in this phase Ruby Ore is minable (Sapphire pickaxe) but Starstone isn't yet: the Star Vault opens when Ruby pickaxes can be made. That fits "a top tool needs all three Grinding Worlds".
- Silver Plate / Gold Plate: 2 ingots each at the Anvil. **Gem Bench**: 4 Silver Ingots + 4 Planks + 2 Stone at the Crafting Table (Crafting 15), placed like the Anvil, its look built in code.

## The deep cave (Worlds/Mining.luau)
A shaft from the Gold Chamber down to five new halls, each a few times the size of today's chambers (the 4x pass's scale): Silver Tunnels (long low tunnels, grey-blue stone, minecart rails), Amethyst Geode (a huge hollow ball lined with purple crystal), Sapphire Lake (an underground lake with glowing blue water and islands), Magma Depths (basalt, lava rivers), Star Vault (dark stone, star-like glowing specks). Gates by level sign like today's zones. Watch the part count (117k now; streaming is on).

## Art
- `blocks.py`: 5 ore tiles + their block meshes (and Empty Ore is shared), Basalt / dark stone for the zones if needed.
- `items3d.py`: Raw Silver, Silver Ingot, Amethyst, Sapphire, Ruby, Starstone, Starsteel Ingot, 3 refined gems, Silver/Gold/Starsteel Plates, Birch/Spruce/Cherry Handles, 8 slivers, the tool tiers; Gem Bench icon (code-built look like the Anvil). That's a second icon sheet (the first is full at 63/64; the code reads several sheets now).

## Order
1. Shared data: Blocks, Gathering, Items, Tools tiers, Recipes, Challenges, Boards (Mining/Crafting), the Miner's shop, BlockService (ore events + slivers), balance numbers.
2. Art scripts run headless; Studio: import blocks + item meshes, upload sheets.
3. The deep cave, looked at in Studio as it grows.
4. Playtest every ore, sliver → node, each tool tier; part count; publish on your word.
