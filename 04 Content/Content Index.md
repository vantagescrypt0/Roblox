# Content Index
One note per item, resource, mob, island type or event. Use the templates in `99 Templates`.

**In the prototype now** (placeholder names and numbers; the real values live in code so they're easy to tune):
| What | Where in code |
|---|---|
| Items + prices | `game/src/shared/Items.luau` |
| Crops (level gates, grow times) | `game/src/shared/Crops.luau` |
| Workbench recipes | `game/src/shared/Recipes.luau` |
| Swords | `game/src/shared/Weapons.luau` |
| XP curve, Warzone level | `game/src/shared/Leveling.luau` |
| Mobs (Slime, Brute) | `game/src/server/Services/MobService.luau` |
| Chest loot | `game/src/server/Services/WarzoneService.luau` |

## Items
- Island: Wood, Stone
- Crops: Wheat (Farming 1), Carrot (5), Potato (10), Glowberry (8, Warzone seeds only)
- Warzone materials: Scrap, Crystal
- Swords: Wooden (6 Wood), Stone (8 Stone + 3 Wood, level 3), Crystal (3 Crystal + 6 Scrap + 2 Wood, level 10)

## Resources
- Tree (Wood), Rocks (Stone) on the starter island

## Mobs
- Slime: Combat 1, outer ring
- Brute: Combat 5, center

## Warzone maps
- Greybox arena (prototype)

## Events
