# Woodcutting phase: build plan (2026-11-02)

**Changed the same day by the [[Late-game Rule]]:** Maple and Redwood stay in the world. Mangrove and Starwood are island-only, from saplings out of loot crates and Warzone chests, and their zones are gone. Wood slivers now craft saplings, not log nodes. The table below is the original plan.

Phase 2 of the approved [[Late-game Proposal]]: four new trees on four new zone islands, in a second ring beyond the first. Sizes, hardness, regrow times, sliver rates and layouts are Claude's picks; say if you want any changed. XP and prices come from `tools/balance.py`.

## The trees
| Level | Tree | Hardness | Regrows | Coins/h | Zone | Reached from |
|---|---|---|---|---|---|---|
| 40 | Maple | 3.5 | 40 s | ~100k | Maple Ridge: red and orange hills, a sugar shack, falling leaves | Birch Grove, north |
| 55 | Redwood | 4 | 45 s | ~230k | Redwood Giants: trees 4-5x taller than oak, a spiral stair up the tallest | Cherry Hills, north |
| 70 | Mangrove | 4.5 | 50 s | ~520k | Mangrove Marsh: roots over shallow water, boardwalks, fog | Snowy Pines, north |
| 85 | Starwood | 5 | 60 s | ~1.2M | Starwood Hollow: glowing blue trees in a dusky bowl, fireflies | Mangrove Marsh, north |

Each tree gets its skill challenge (pet, armor and trophy tiers V to VIII) through `Challenges.luau`, and the Lumberjack buys all four.

## Slivers and nodes
The approved rule says slivers work for Woodcutting the same way as for ore, so chopping logs in the Woodcutting World sometimes drops a sliver of that wood, and enough of them craft a node. A wood node is a single log on your island that grows back after you chop it.

| Wood | Oak | Birch | Spruce | Cherry | Maple | Redwood | Mangrove | Starwood |
|---|---|---|---|---|---|---|---|---|
| One sliver per logs | 150 | 250 | 400 | 600 | 900 | 1,300 | 1,800 | 2,500 |
| Slivers to a node | 10 | 10 | 12 | 12 | 15 | 15 | 20 | 20 |

## New blocks
Logs and leaves for each tree, plus two ground blocks with merged pieces so the islands stay light: **Mud** (Mangrove Marsh) and **Dusk Grass** (Starwood Hollow). That's 15 new tiles, so the block atlas grows from 9x9 at 112 px a tile to 10x10 at 96 px. Existing blocks keep their own uploaded copy of the old atlas.

## What isn't in this phase
Cherry and Redwood Handles come with the Ruby and Starsteel tools, after Farming. The XP refit waits until Farming's crops are in too.

## Order
1. Shared data, zones and art scripts.
2. Studio: import the blocks and item meshes, upload the icon sheets.
3. Walk each zone, check every level gate, chop each log, sliver to node, part count and build time. Publish on your word.
