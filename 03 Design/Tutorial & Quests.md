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
| # | Quest | Reward |
|---|---|---|
| 1 | Chop a tree | 10 XP |
| 2 | Mine a rock | 10 XP |
| 3 | Plant 3 seeds | 3 Wheat Seeds, 15 XP |
| 4 | Harvest 3 crops | 20 XP |
| 5 | Sell crops at the Market | 10 coins, 15 XP |
| 6 | Buy seeds at the Market | 15 XP |
| 7 | Craft a Wooden Sword | 3 Wood, 25 XP |
| 8 | Reach Farming level 3 | 25 coins, 40 XP |
| 9 | Reach level 10 to unlock the Warzone | 50 coins, 8 Stone (enough for a Stone Sword) |

Generators, island expansion, smelting and conveyors from the draft below aren't built yet; they'll slot in as quests when they are.

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
