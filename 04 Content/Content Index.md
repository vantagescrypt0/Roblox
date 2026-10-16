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
- Blocks: Grass, Dirt, Wood, Planks, Stone (Cobblestone drops Stone)
- Materials: Sticks (2 Planks -> 4)
- Crops: Wheat (Farming 1), Carrot (5), Potato (10), Glowberry (8, Warzone seeds only)
- Warzone materials: Scrap, Crystal
- Tools: Pickaxe, Axe, Shovel, Sword in 3 tiers. Wooden (Planks + Sticks, speed x2, 60 uses), Stone (Stone + Sticks, x4, 132 uses), Crystal (Crystal + Sticks, x8, 500 uses, level 10). Costs like Minecraft: pickaxe/axe 3 head + 2 sticks, shovel 1 + 2, sword 2 + 1

## NPCs
- Merchant (Town Market stall): villager-style trader in a straw hat; trade to sell crops and buy seeds

## Resources
- Tree (Wood), Rocks (Stone) on the starter island

## Mobs
- Slime: Combat 1, outer ring
- Brute: Combat 5, center

## Warzone maps
- Greybox arena (prototype)

## Events
