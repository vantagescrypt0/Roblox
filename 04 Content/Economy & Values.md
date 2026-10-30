# Economy & Values
What everything is worth, so trading between players has a fair reference. The numbers live in code: hand-set values in `game/src/shared/Items.luau`, crafted values worked out by `game/src/shared/Economy.luau`.

## The rules
- **Value** is what an item is fairly worth between players, in coins.
  - Gathered things (wood, stone, ores, crops, seeds, Warzone loot) get a hand-set Value, based on how long they take to get.
  - Crafted things are worth **their inputs + 10%** for the work, worked out from the recipes. When a recipe changes, its value updates by itself.
  - **Worn tools** are worth value × the share of uses left. A half-used Iron Pickaxe is worth 29, not 58.
- The **shops in Town pay about half of Value** (SellPrice). Selling to a player is always the better deal, so trading is worth doing.
- **Seeds cost their Value** at the Merchant, and you pay once per plot. Crops regrow after every harvest (see below), so a seed is an investment.
- **Four shopkeepers** (since 2026-10-25, `Shops.luau`; see [[Town & Worlds]]), each buying and selling their own things: **Merchant** (crops / seeds), **Lumberjack** (wood / saplings), **Miner** (stone and ore / coal), **Builder** (sells building blocks).

## Value table
| Item | Value | Shop buys for | Shop sells for |
|---|---|---|---|
| Grass Block | 1 | – | Builder 3 |
| Dirt | 1 | – | Builder 2 |
| Cobblestone | 2 | – | Builder 4 |
| Red Wool, White Wool | 4 | – | Builder 6 |
| Stone Bricks, Smooth Stone, Plaster | 3 | – | Builder 5 |
| Bricks, Glass | 4 | – | Builder 6 |
| Dark Planks | 2 | – | Builder 4 |
| Red / Slate Roof Tiles | 3 | – | Builder 5 |
| Gravel, Sand, Dirt Path, Coarse Dirt | 2 | – | Builder 3 |
| Snow, Barn Planks, Thatch | 2 | – | Builder 4 |
| Flowery Grass, Snowy Grass, Sandstone, Terracotta, Red Terracotta, Mossy Cobblestone, Hay Bale, Mushroom Cap / Stem | 3 | – | Builder 5 |
| Ice, Mossy / Cracked Stone Bricks, Crate, Barrel | 4 | – | Builder 6 |
| Bookshelf | 6 | – | Builder 10 |
| Water Bucket (pours a water source; leaves a Bucket) | 20 | – | Builder 20 |
| Lava Bucket (pours a lava source; leaves a Bucket) | 50 | – | Builder 50 |
| Bucket (empty; scoops a source back up) | 10 | – | – |
| Bottomless Water Bucket (never empties) | 2,500,000 | – | Builder 2,500,000 |
| Bottomless Lava Bucket (never empties) | 5,000,000 | – | Builder 5,000,000 |
| Wood | 2 | Lumberjack 1 | – |
| Birch Wood (Birch Grove, Woodcutting 10) | 12 | Lumberjack 6 | – |
| Spruce Wood (Snowy Pines, Woodcutting 20) | 28 | Lumberjack 14 | – |
| Cherry Wood (Cherry Hills, Woodcutting 30) | 54 | Lumberjack 27 | – |
| Stone | 2 | Miner 1 | Builder 4 (or free from a stone generator: lava + water) |
| Planks (1 Wood → 4) | 1 | – | – |
| Sticks (2 Planks → 4) | 1 | – | – |
| Coal | 2 | Miner 1 | Miner 3 |
| Raw Iron | 8 | Miner 4 | – |
| Iron Ingot (Raw Iron + Coal) | 11 | Miner 6 | – |
| Raw Gold (deep in the Mining World; Iron pickaxe, Mining 10) | 32 | Miner 16 | – |
| Gold Ingot (Raw Gold + Coal) | 37 | Miner 20 | – |
| Furnace (8 Stone) | 18 | – | – |
| Wheat Seeds | 12 | – | Merchant 12 |
| Wheat | 2 | Merchant 1 | – |
| Carrot Seeds | 24 | – | Merchant 24 |
| Carrot | 4 | Merchant 2 | – |
| Potato Seeds | 60 | – | Merchant 60 |
| Potato | 10 | Merchant 5 | – |
| Pumpkin Seeds (Farming 15) | 120 | – | Merchant 120 |
| Pumpkin (grows in 4 min) | 20 | Merchant 10 | – |
| Melon Seeds (Farming 25) | 180 | – | Merchant 180 |
| Melon (grows in 6 min) | 30 | Merchant 15 | – |
| Glowberry Seeds (Warzone only) | 250 | – | – |
| Sapling (from leaves and felled trees) | 8 | – | Lumberjack 20 |
| Glowberry | 40 | Merchant 20 | – |
| Scrap (Warzone) | 6 | – | – |
| Crystal (Warzone) | 60 | – | – |

### Tools (new, full durability)
| Tier | Pickaxe | Axe | Shovel | Hoe | Sword |
|---|---|---|---|---|---|
| Wooden | 6 | 6 | 3 | 4 | 3 |
| Stone | 9 | 9 | 4 | 7 | 6 |
| Iron | 39 | 39 | 14 | 26 | 25 |
| Crystal | 200 | 200 | 68 | 134 | 133 |

## Resource nodes
A **node** is a higher-value block because it grows back in the same spot after you harvest it. Nodes are **ores and crops** (and, later, PvE spawners). You can't build in a node's spot, and mined nodes are never saved as holes. **A mined ore never leaves a hole:** it turns into a pale **Empty Ore** block (stone with hollow pockets) that can't be mined, and fills back in with its ore. The rarer the ore, the slower it comes back.
- **On your island:** the boulders (stone with coal and iron ore) and your crops. **Trees are not nodes**: chop a tree down and it's gone, and you replant a sapling (a felled tree always gives at least one). See [[Skills & Levels]].
- **In the resource worlds** every ore, log, leaf and wild crop grows back, so they never run out. The Mining World's stone (cave walls, outcrops) is scenery nobody can break; only its ores can be mined, and only with a pickaxe good enough to collect them (no breaking a node for nothing). See [[Town & Worlds]].
- Later: node items you can own, trade and place (e.g. an Iron Node), worth a lot because they never run out.

| Node | Grows back after |
|---|---|
| Stone (island boulders) | 15s |
| Wood (log, worlds only) | 20s |
| Leaves (worlds only) | 30s |
| Coal Ore | 20s |
| Iron Ore | 45s |
| Birch / Spruce / Cherry Wood (worlds) | 25s / 30s / 35s |
| Gold Ore (Mining World) | 90s |

Blocks you dig out of the island underside (ore veins) and blocks you placed yourself are not nodes: once mined, they're gone.

## Crops are perennial
Plant once. After each harvest the plant stays and starts growing again, with no timer shown. There's a 10% chance per harvest of a spare seed to fill another plot. To change crops, hold a shovel and click the plant: it's dug up and you get the seed back.

| Crop | Grows in | Merchant coins / plot / min | Seed pays back after |
|---|---|---|---|
| Wheat | 30s | 2 | 12 harvests (6 min) |
| Carrot | 75s | 1.6 | 12 harvests (15 min) |
| Potato | 150s | 2 | 12 harvests (30 min) |
| Pumpkin | 240s | 2.5 | 12 harvests (48 min) |
| Melon | 360s | 2.5 | 12 harvests (72 min) |
| Glowberry | 240s | 5 | 12 harvests (50 min) |

On your island (crops grow while you're away), better crops earn about the same coins per plot per minute but need far fewer clicks. In the Farming World, where you harvest nonstop, a better crop pays far more an hour (see Coin pace). The Farming level bonus (a chance of a double crop) comes on top.

## Coin pace (rebalance 2026-10-27)
Your targets: about **2k coins an hour early**, **50k mid game**, **1M late game**; the best things cost **10M–50M** and the richest players hold **100M+**. Prices are fitted by `tools/balance.py` (run `python tools/balance.py`): each resource earns a set amount an hour at the level it unlocks, for steady play in the worlds.

| Stage | Skill level | Best resource today | Coins an hour |
|---|---|---|---|
| Early | 1–5 | Wheat, Coal, Oak, then Raw Iron and Carrots | ~1k–6k |
| Getting going | 10 | Raw Gold, Potatoes, Birch | ~10k–25k |
| Mid | 20–30 | Spruce, Pumpkins; then Cherry and Melons | ~25k–45k |
| Mid, maxed | 50–99 | the same, with bigger double-drop chances | ~35k–63k |
| Late | — | **nothing yet** | target ~1M |

**The late game is missing content:** today's best resources unlock at Mining 10, Farming 25 and Woodcutting 30, so from there to 99 nothing new pays more, and nothing costs 10M–50M yet. Closing the gap needs new top-tier ores, crops and trees at higher levels (each tier worth about 2–3x the one before) and new big purchases. That's a content decision for you (see the Roadmap).

Island expansion: Meadow **3,000**, Grove **40,000**, Grand **400,000** coins (were 300 / 1,500 / 6,000).

## Trading between players
Built 2026-10-24 (code: `TradeService.luau` on the server, `TradeWindow.luau` on the client). Screenshot: `art/renders/ui-trade-window.png`.

**How it plays**
1. In Town, walk up to another player. A **Trade** prompt shows over them (press **T**, or tap it). They get a "wants to trade" card with Trade / No thanks for 20 seconds. If you both ask each other, the trade just opens.
2. The trade window shows **You give** and **They give**, each with its total value, and your bag. Click an item in your bag to put one in (click it under You give to take one back), or pick it and use -1 / +1 / +10 / All / None.
3. Both press **Accept**. A 3-second countdown runs ("Trading in 3... press to stop"), then everything swaps at once.
4. Closing the window (X, Cancel trade, clicking outside, or opening another window) ends the trade for both.

**Safety rules**
- **The server owns the trade.** The client only asks to change an offer; the server checks every count against what you actually have.
- **Any change un-accepts both sides** and stops the countdown. An Accept also only counts for the version of the trade that player was looking at, so nothing can be swapped in at the last second.
- **The swap is atomic:** check both sides still own everything, remove from both, add to both, with no waiting in between. ProfileStore's session lock stops the same save being open on two servers (the usual source of duplicated items).
- If your items change mid-trade (e.g. you sell some), your offer shrinks to what you still have and both sides must accept again.
- **Lopsided warning:** if you'd get back less than half of what you give, you see "Careful! You give items worth X coins and get Y back" and the button becomes "Accept anyway". Gifts are allowed, just warned.
- **Every trade is logged** in both players' saved data (`Trades`, the last 30: who, when, what each side gave) and printed to the server log.
- Limits: up to 12 different items per side; you can ask again 3s later, or 20s after a "no thanks".

**Worn tools:** only one tool of each kind can be part-used (the one you're using up). When you trade some of a tool, you give fresh ones first and keep the worn one; it only goes along if you trade them all, and it's shown at its worn value with a wear bar. If the other player already has a worn one of that kind, the two are combined: the wear adds up and, when it passes a whole tool, they get one fewer tool. The total uses are always exactly kept (tested: 50 + 150 + 250 uses in → 2 tools with 450 uses).

**Coins:** not tradable for now, items only (your call 2026-10-25: "hold off on coins"). Coins would be simpler for players but make coin-selling scams easier.

**Level 5 to trade** (2026-10-25, `Leveling.TradeLevel`): both players need player level 5. Below it, the Trade prompt over other players reads "Trade at level 5", and asking says "Trading unlocks at level 5. You're level N, keep going!" (or that the other player needs level 5). Level 5 takes the beginner quests plus a little play, so brand-new and throwaway accounts can't be used for scams.

Related: [[Content Index]], [[Monetization Principles]], [[Core Loop]]
