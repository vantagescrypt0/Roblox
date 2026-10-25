# Economy & Values
What everything is worth, so trading between players (coming later) has a fair reference. The numbers live in code: hand-set values in `game/src/shared/Items.luau`, crafted values worked out by `game/src/shared/Economy.luau`.

## The rules
- **Value** is what an item is fairly worth between players, in coins.
  - Gathered things (wood, stone, ores, crops, seeds, Warzone loot) get a hand-set Value, based on how long they take to get.
  - Crafted things are worth **their inputs + 10%** for the work, worked out from the recipes. When a recipe changes, its value updates by itself.
  - **Worn tools** are worth value × the share of uses left. A half-used Iron Pickaxe is worth 29, not 58.
- The **Merchant pays about half of Value** (SellPrice). Selling to a player is always the better deal, so trading is worth doing.
- **Seeds cost their Value** at the Merchant, and you pay once per plot. Crops regrow after every harvest (see below), so a seed is an investment.

## Value table
| Item | Value | Merchant buys | Merchant sells |
|---|---|---|---|
| Grass, Dirt | 1 | – | – |
| Wood | 2 | 1 | – |
| Stone | 2 | 1 | – |
| Planks (1 Wood → 4) | 1 | – | – |
| Sticks (2 Planks → 4) | 1 | – | – |
| Coal | 5 | 2 | – |
| Raw Iron | 10 | 5 | – |
| Iron Ingot (Raw Iron + Coal) | 17 | 8 | – |
| Furnace (8 Stone) | 18 | – | – |
| Wheat Seeds | 12 | – | 12 |
| Wheat | 4 | 2 | – |
| Carrot Seeds | 45 | – | 45 |
| Carrot | 10 | 5 | – |
| Potato Seeds | 120 | – | 120 |
| Potato | 24 | 12 | – |
| Glowberry Seeds (Warzone only) | 250 | – | – |
| Glowberry | 70 | 35 | – |
| Scrap (Warzone) | 6 | – | – |
| Crystal (Warzone) | 60 | – | – |

### Tools (new, full durability)
| Tier | Pickaxe | Axe | Shovel | Sword |
|---|---|---|---|---|
| Wooden | 6 | 6 | 3 | 3 |
| Stone | 9 | 9 | 4 | 6 |
| Iron | 58 | 58 | 21 | 39 |
| Crystal | 200 | 200 | 68 | 133 |

## Resource nodes (nothing to replant)
Every tree, leaf, boulder and ore block that comes with the island is a **node**. Mine it and it grows back in the same spot after a set time. You can't build in a node's spot, and mined nodes are never saved as holes.

| Node | Grows back after |
|---|---|
| Stone | 15s |
| Wood (log) | 20s |
| Leaves | 30s |
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

## Trading (planned): design notes
- **Where:** in Town, where players from different islands meet. Both players are on the same server, so the swap can happen in one step.
- **Two-step confirm:** both players put items in and press Accept. Then a 3-second countdown starts, and any change resets both Accepts. This stops last-second swaps.
- **Server does the swap atomically:** check that both sides still own everything, then remove and add in one go. Never trust what the client says is in the trade. ProfileStore's session lock already stops the same save being open on two servers (the usual source of duplicated items).
- **Lopsided trade warning:** show each side's total value (`Economy.Total`). If one side is worth less than half the other, show a warning before Accept. Younger players are the audience, so this matters.
- **Worn tools** show their worn value in the trade window.
- **Log every trade** (who, what, when) so scams and duplication bugs can be looked into.
- Open question: should coins be tradable, or only items? Allowing coins is simpler for players but makes coin-selling scams easier.

Related: [[Content Index]], [[Monetization Principles]], [[Core Loop]]
