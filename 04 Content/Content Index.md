# Content Index
One note per item, resource, mob, island type or event. Use the templates in `99 Templates`.

**In the prototype now** (placeholder names and numbers; the real values live in code so they're easy to tune):
| What | Where in code |
|---|---|
| Items + prices (hand-set values) | `game/src/shared/Items.luau` |
| Trade values (crafted items, worn tools) | `game/src/shared/Economy.luau`, see [[Economy & Values]] |
| Node regrow times | `game/src/shared/Blocks.luau` (NodeRespawn) |
| Crops (level gates, grow times) | `game/src/shared/Crops.luau` |
| Crafting recipes | `game/src/shared/Recipes.luau` |
| Tools (power: tier, mining speed, damage, durability) | `game/src/shared/Tools.luau` |
| Blocks (toughness: hardness, right tool) | `game/src/shared/Blocks.luau` |
| Break-time rules | `game/src/shared/Mining.luau` |
| XP curve, Warzone level, trade level | `game/src/shared/Leveling.luau` |
| Shopkeepers (who buys and sells what) | `game/src/shared/Shops.luau`, looks in `game/src/server/Util/Npc.luau` |
| Town layout, world layouts | `TownService.luau`, `WorldService.luau`, see [[Town & Worlds]] |
| Mobs (Slime, Brute) | `game/src/server/Services/MobService.luau` |
| Chest loot | `game/src/server/Services/WarzoneService.luau` |

## Items
- Blocks: Grass, Dirt, Wood, Planks, Stone, Furnace (8 Stone, placeable station); Cobblestone, Red Wool, White Wool (from the Builder)
- Ores: Coal Ore (any pickaxe, drops Coal), Iron Ore (Stone pickaxe or better, drops Raw Iron)
- Materials: Sticks (2 Planks -> 4), Coal, Raw Iron, Iron Ingot (smelt 1 Raw Iron + 1 Coal in a Furnace)
- Crops: Wheat (Farming 1), Carrot (5), Potato (10), Glowberry (8, Warzone seeds only). Perennial: plant once, they regrow after every harvest (10% spare-seed chance); dig up with a shovel to get the seed back
- Warzone materials: Scrap, Crystal
- Tools: Pickaxe, Axe, Shovel, Hoe, Sword in 4 tiers (hoes till farmland; see [[Skills & Levels]]). Wooden (Planks + Sticks, speed x2, 60 uses), Stone (Stone + Sticks, x4, 132 uses), Iron (Iron Ingots + Sticks, x6, 250 uses, Crafting 3 + the tool's skill 4), Crystal (Crystal + Sticks, x8, 600 uses, Crafting 8 + the tool's skill 8). See [[Skills & Levels]]. Costs like Minecraft: pickaxe/axe 3 head + 2 sticks, shovel 1 + 2, sword 2 + 1

## NPCs (Town shopkeepers, see [[Town & Worlds]])
- Merchant: an original travelling trader (newsboy cap, bushy mustache, green vest, red scarf, big backpack with a bedroll and lantern); buys crops, sells seeds. Replaced the earlier villager-style design (too close to Minecraft)
- Lumberjack: red plaid shirt, suspenders, green beanie, big beard, axe on his back; buys wood, sells saplings
- Miner: yellow hard hat with a headlamp, grey beard, overalls, pickaxe on his back; buys stone and ore, sells coal
- Builder: white shirt, blue overalls, red bandana, tool belt with a hammer; sells building blocks

## Resources
**Nodes** grow back in the same spot, and you can't build there: ores and crops (and later PvE spawners). See [[Economy & Values]].
- Island trees: chop-once (a felled tree drops its leaves and gives at least 1 sapling)
- Boulders: 2 Stone (15s), Coal Ore on top (30s), Iron Ore at the side (45s)
- Island underside: stone with ore veins (coal 7% of stone blocks, iron 4% from 4 blocks down) to dig for. These are not nodes; once mined they're gone
- Resource worlds: Mining (outcrops + cliff of stone/coal/iron), Woodcutting (~40 oaks), Farming (wheat, carrot and potato fields); everything there grows back

## Mobs
- Slime: Combat 1, outer ring
- Brute: Combat 5, center

## Warzone maps
- Greybox arena (prototype)

## Events
