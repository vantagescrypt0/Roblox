# Content Index
One note per item, resource, mob, island type or event. Use the templates in `99 Templates`.

**In the prototype now** (placeholder names and numbers; the real values live in code so they're easy to tune):
| What | Where in code |
|---|---|
| Items + prices | `game/src/shared/Items.luau` |
| Crops (level gates, grow times) | `game/src/shared/Crops.luau` |
| Crafting recipes | `game/src/shared/Recipes.luau` |
| Tools (power: tier, mining speed, damage, durability) | `game/src/shared/Tools.luau` |
| Blocks (toughness: hardness, right tool) | `game/src/shared/Blocks.luau` |
| Break-time rules | `game/src/shared/Mining.luau` |
| XP curve, Warzone level | `game/src/shared/Leveling.luau` |
| Mobs (Slime, Brute) | `game/src/server/Services/MobService.luau` |
| Chest loot | `game/src/server/Services/WarzoneService.luau` |

## Items
- Blocks: Grass, Dirt, Wood, Planks, Stone (Cobblestone drops Stone), Furnace (8 Stone, placeable station)
- Ores: Coal Ore (any pickaxe, drops Coal), Iron Ore (Stone pickaxe or better, drops Raw Iron)
- Materials: Sticks (2 Planks -> 4), Coal, Raw Iron, Iron Ingot (smelt 1 Raw Iron + 1 Coal in a Furnace)
- Crops: Wheat (Farming 1), Carrot (5), Potato (10), Glowberry (8, Warzone seeds only)
- Warzone materials: Scrap, Crystal
- Tools: Pickaxe, Axe, Shovel, Sword in 4 tiers. Wooden (Planks + Sticks, speed x2, 60 uses), Stone (Stone + Sticks, x4, 132 uses), Iron (Iron Ingots + Sticks, x6, 250 uses, level 5), Crystal (Crystal + Sticks, x8, 600 uses, level 10). Costs like Minecraft: pickaxe/axe 3 head + 2 sticks, shovel 1 + 2, sword 2 + 1

## NPCs
- Merchant (Town Market stall): villager-style trader in a straw hat; trade to sell crops and buy seeds

## Resources
- Trees (Wood) regrow after 90s once fully chopped
- Boulders: stone with a coal and an iron block; regrow 60s after they're fully mined, each block rolling Stone (66%), Coal Ore (22%) or Iron Ore (12%)
- Island underside: stone with ore veins (coal 7% of stone blocks, iron 4% from 4 blocks down) to dig for

## Mobs
- Slime: Combat 1, outer ring
- Brute: Combat 5, center

## Warzone maps
- Greybox arena (prototype)

## Events
