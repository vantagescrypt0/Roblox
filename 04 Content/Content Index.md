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
| Chest loot | `game/src/shared/WarzoneLoot.luau` |
| Storage chests | `game/src/server/Services/ChestService.luau` |
| Armour look | `game/src/shared/ArmorArt.luau`, `game/src/server/Util/ArmorModels.luau` |

## Items
- Blocks: Grass, Dirt, Wood, Planks, Stone, Furnace (8 Stone, placeable station); Cobblestone, Red Wool, White Wool (from the Builder)
- Builder blocks (2026-10-29): every block seen round Town and the worlds is for sale too: Gravel, Sand, Dirt Path, Coarse Dirt, Flowery Grass, Snowy Grass, Snow, Ice, Sandstone, Terracotta, Red Terracotta, Mossy Cobblestone, Mossy / Cracked Stone Bricks, Barn Planks, Thatch, Hay Bale, Crate, Barrel, Bookshelf, Mushroom Cap, Mushroom Stem (they drop themselves when broken)
- Water and lava (2026-10-29, `Liquids.luau`, `LiquidService`): Water Bucket, Lava Bucket, Bucket (empty), Bottomless Water Bucket, Bottomless Lava Bucket. Sources flow like Minecraft (water 7 blocks, lava 3 and slower); where they'd touch, stone forms (a stone generator); lava burns
- Ores: Coal Ore (any pickaxe, drops Coal), Iron Ore (Stone pickaxe or better, drops Raw Iron)
- Materials: Sticks (2 Planks -> 4), Coal, Raw Iron, Iron Ingot (smelt 1 Raw Iron + 1 Coal in a Furnace)
- Tool parts (2026-10-31): Twine (4 Wheat), Rope (3 Twine), Iron Plate (2 Iron Ingots, Anvil), Sturdy Handle (2 Sticks + 1 Iron Ingot, Anvil); the **Anvil** station (3 Iron Ingots + 4 Stone, an iron anvil on an oak stump) and the **Gem Bench** (4 Silver Ingots + 4 Planks + 2 Stone, Crafting 15: a workbench with a grinding wheel), both built in code (`Util/StationModels.luau`)
- The deep cave (2026-10-31, [[Mining Phase Plan]]): Silver Ore → Raw Silver → Silver Ingot (+ Silver Plate), Amethyst, Sapphire, Ruby, Starstone; Refined Amethyst (2 Amethyst + Silver Ingot) and Refined Sapphire (2 Sapphire + Gold Ingot) at the Gem Bench; Birch Handle (Birch Wood + Iron Plate) and Spruce Handle (Spruce Wood + Silver Plate) at the Anvil; **Amethyst** and **Sapphire** tools (speed x8, x10)
- Slivers (`Slivers.luau`): a rare drop from what's in the Grinding Worlds (1 in 150 for coal up to 1 in 1,300 for sapphire and redwood). 10-15 craft a node (Coal, Iron, Gold, Silver, Amethyst, Sapphire), a sapling (Birch, Spruce, Cherry, Maple, Redwood) or Sugarcane Seeds. Nodes are never sold.
- Late game ([[Late-game Rule]]): Ruby and Starstone Nodes, Mangrove and Starwood Saplings, Strawberry, Dragonfruit and Starfruit Seeds, only from Loot Crates and Warzone chests.
- Loot Crate (`LootCrates.luau`): open it from your Bag for one random prize, with the odds shown first. From Warzone chests; the Crate Keeper Kit will give them too ([[Kits]]).
- Crops: Wheat (Farming 1), Carrot (5), Potato (10), Pumpkin (15), Melon (25), Glowberry (8, Warzone seeds only), Sugarcane (40, seeds from slivers). Late game, on your island only: Strawberry (50), Dragonfruit (65, axe), Starfruit (80)
- Zone woods (Woodcutting World): Birch (Woodcutting 10), Spruce (20), Cherry (30), Maple (40), Redwood (55). Late game, on your island only ([[Late-game Rule]]): Mangrove (70), Starwood (85); Gold (Mining World, Mining 10 + Iron pickaxe) smelts into Gold Ingots. Perennial: plant once, they regrow after every harvest (10% spare-seed chance); dig up with a shovel to get the seed back
- Warzone materials: Scrap, Crystal
- Tools: Pickaxe, Axe, Shovel, Hoe, Sword in 7 tiers plus the Warzone's Crystal side tier (hoes till farmland; see [[Skills & Levels]]). Amethyst x8, Sapphire x10, Ruby x12 and Starsteel x14 are in [[Mining Phase Plan]] and [[Farming Phase Plan]]. Wooden (Planks + Sticks, speed x2), Stone (Stone + Sticks + Twine, x4), Iron (Iron Plates + Sturdy Handle + Rope at the Anvil, x6, Crafting 3 + the tool's skill 4), Crystal (Crystal + Sturdy Handle + Rope at the Anvil, x8, Crafting 8 + the tool's skill 8). Tools never wear out. See [[Skills & Levels]]. Head pieces like Minecraft: pickaxe/axe 3, hoe/sword 2, shovel 1

## NPCs (Town shopkeepers, see [[Town & Worlds]])
- Merchant: an original travelling trader (newsboy cap, bushy mustache, green vest, red scarf, big backpack with a bedroll and lantern); buys crops, sells seeds. Replaced the earlier villager-style design (too close to Minecraft)
- Lumberjack: red plaid shirt, suspenders, green beanie, big beard, axe on his back; buys wood, sells saplings
- Miner: yellow hard hat with a headlamp, grey beard, overalls, pickaxe on his back; buys stone and ore, sells coal
- Builder: white shirt, blue overalls, red bandana, tool belt with a hammer; sells every block, water and lava buckets and the Bottomless buckets

## Resources
**Nodes** grow back in the same spot, and you can't build there: ores and crops (and later PvE spawners). See [[Economy & Values]].
- Island trees: chop-once (a felled tree drops its leaves and gives at least 1 sapling)
- Boulders: 2 Stone (15s), Coal Ore on top (30s), Iron Ore at the side (45s)
- Island underside: stone with ore veins (coal 7% of stone blocks, iron 4% from 4 blocks down) to dig for. These are not nodes; once mined they're gone
- Resource worlds: Mining (outcrops and cave walls of unbreakable stone, set with coal, iron and gold; below the Gold Chamber the deep cave: Silver Tunnels, Amethyst Geode, Sapphire Lake), Woodcutting (~40 oaks), Farming (wheat, carrot and potato fields); every ore, tree and crop there grows back (a mined ore shows as a pale Empty Ore block meanwhile)

## Mobs
- Slime: Combat 1, outer ring
- Brute: Combat 5, center

## Warzone maps
- Greybox arena (prototype)

## Events
