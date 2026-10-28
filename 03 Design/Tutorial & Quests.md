# Tutorial & Quests (Draft)

## Decided
- A **beginner tutorial built from quests** teaches the island loop.
- The tutorial ends at the **Warzone unlock level** (like Skybounds). See [[Skills & Levels]] and [[Warzone]].

## Design rules — [Inference]
- Teach by doing: one action per quest, short text, show an arrow to where you need to go. Players are young and on mobile ([[Target Audience]]).
- Every quest gives a reward you'll use in the next quest (tool, seeds, machine).
- NPCs show up at milestones with a starter pack (borrowed from Islands; see [[Mechanics to Borrow]]).
- Skippable for players who've played before? Decide later.

## Built in the prototype (2026-10-15)
Only uses features that exist so far. Edit it in `game/src/shared/Quests.luau`. A tracker on the right of the screen shows the current quest, and the object it's about gets a yellow outline on your island.
Updated for tools and click farming (2026-10-15). The first quests walk you down Minecraft's tool path: wood → planks → sticks → a pickaxe → stone.
| # | Quest | Reward |
|---|---|---|
| 1 | Hold click on a tree to chop 3 Wood | 150 XP |
| 2 | Click the Crafting Table and craft Planks | 2 Wood, 150 XP |
| 3 | Craft Sticks | 150 XP |
| 4 | Craft a Wooden Pickaxe | 350 XP |
| 5 | Hold your pickaxe and mine 3 Stone | 8 Grass blocks, 350 XP |
| 6 | Right-click to place 3 blocks | 150 XP |
| 7 | Click the farmland to plant 3 seeds | 3 Wheat Seeds, 250 XP |
| 8 | Hold your hoe and click ripe crops to harvest 3 | 350 XP |
| 9 | Step through the portal to visit Town | 250 XP |
| 10 | Sell crops to the Merchant in Town | 100 coins, 250 XP |
| 11 | Buy seeds from the Merchant | 250 XP |
| 12 | Craft a Stone Pickaxe | 4 Stone, 350 XP |
| 13 | Mine Iron Ore with your Stone Pickaxe | 1 Coal, 350 XP |
| 14 | Craft a Furnace (8 Stone) | 350 XP |
| 15 | Place your Furnace and smelt an Iron Ingot | 150 coins, 500 XP |
| 16 | Reach Farming level 3 | 250 coins, 700 XP |
| 17 | Reach level 10 | 1,000 coins, 3 Iron Ingots |

Rewards were scaled up with the 2026-10-27 rebalance (about 4,900 player XP in all, roughly a level and a half). Quests 12-15 (2026-10-24) teach ores and smelting. Generators and conveyors from the draft below aren't built yet; they'll slot in as quests when they are.

## Draft quest chain — [Speculation]
| # | Quest | Teaches | Reward |
|---|---|---|---|
| 1 | Chop 5 trees | Gathering | Wooden axe |
| 2 | Craft a workbench | Crafting | Seeds |
| 3 | Plant and harvest 10 wheat | Farming + Farming XP | Hoe, more seeds |
| 4 | Sell crops at the hub | Hub, coins | Coins |
| 5 | Buy your first generator | Idle income | — |
| 6 | Expand your island | Expansion | Land |
| 7 | Defeat 5 slimes | PvE + Combat XP | Sword |
| 8 | Smelt iron | Smelting | Iron tools |
| 9 | Set up a conveyor | Automation | Conveyors (NPC visit) |
| 10 | Reach player level 10 | — | **Warzone unlocked** + starter kit |

After the tutorial: daily challenges plus a longer challenge list (Skybounds had 100+). See [[Mechanics to Borrow]].

## Warzone first visit
- [Speculation] A guided first drop: a short walk-through of opening chests, loot heads, and how to extract safely.
