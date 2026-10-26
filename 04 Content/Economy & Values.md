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
| Wood | 2 | Lumberjack 1 | – |
| Stone | 2 | Miner 1 | – |
| Planks (1 Wood → 4) | 1 | – | – |
| Sticks (2 Planks → 4) | 1 | – | – |
| Coal | 5 | Miner 2 | Miner 10 |
| Raw Iron | 10 | Miner 5 | – |
| Iron Ingot (Raw Iron + Coal) | 17 | Miner 8 | – |
| Furnace (8 Stone) | 18 | – | – |
| Wheat Seeds | 12 | – | Merchant 12 |
| Wheat | 4 | Merchant 2 | – |
| Carrot Seeds | 45 | – | Merchant 45 |
| Carrot | 10 | Merchant 5 | – |
| Potato Seeds | 120 | – | Merchant 120 |
| Potato | 24 | Merchant 12 | – |
| Glowberry Seeds (Warzone only) | 250 | – | – |
| Sapling (from leaves and felled trees) | 8 | – | Lumberjack 20 |
| Glowberry | 70 | Merchant 35 | – |
| Scrap (Warzone) | 6 | – | – |
| Crystal (Warzone) | 60 | – | – |

### Tools (new, full durability)
| Tier | Pickaxe | Axe | Shovel | Hoe | Sword |
|---|---|---|---|---|---|
| Wooden | 6 | 6 | 3 | 4 | 3 |
| Stone | 9 | 9 | 4 | 7 | 6 |
| Iron | 58 | 58 | 21 | 40 | 39 |
| Crystal | 200 | 200 | 68 | 134 | 133 |

## Resource nodes
A **node** is a higher-value block because it grows back in the same spot after you harvest it. Nodes are **ores and crops** (and, later, PvE spawners). You can't build in a node's spot, and mined nodes are never saved as holes.
- **On your island:** the boulders (stone with coal and iron ore) and your crops. **Trees are not nodes**: chop a tree down and it's gone, and you replant a sapling (a felled tree always gives at least one). See [[Skills & Levels]].
- **In the resource worlds** every rock, log, leaf and wild crop grows back, so they never run out. See [[Town & Worlds]].
- Later: node items you can own, trade and place (e.g. an Iron Node), worth a lot because they never run out.

| Node | Grows back after |
|---|---|
| Stone | 15s |
| Wood (log, worlds only) | 20s |
| Leaves (worlds only) | 30s |
| Coal Ore | 30s |
| Iron Ore | 45s |

Blocks you dig out of the island underside (ore veins) and blocks you placed yourself are not nodes: once mined, they're gone.

## Crops are perennial
Plant once. After each harvest the plant stays and starts growing again, with no timer shown. There's a 10% chance per harvest of a spare seed to fill another plot. To change crops, hold a shovel and click the plant: it's dug up and you get the seed back.

| Crop | Grows in | Merchant coins / plot / min | Seed pays back after |
|---|---|---|---|
| Wheat | 30s | 4 | 6 harvests (3 min) |
| Carrot | 75s | 4 | 9 harvests (~11 min) |
| Potato | 150s | 4.8 | 10 harvests (25 min) |
| Glowberry | 240s | 8.75 | 8 harvests (32 min) |

Better crops earn about the same coins per minute as wheat but need far fewer clicks, and they give more Farming XP. The Farming level bonus (a chance of a double crop) comes on top. *Tuning idea: if Carrot feels pointless, raise its value to 12 to 14.*

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
