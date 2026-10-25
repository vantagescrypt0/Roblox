# Roadmap (Draft)
No dates — quality over speed.

1. **Pre-production:** concept, pillars, core loop, open questions answered. (Mostly done; some questions still open.)
2. **Prototype** ← *we are here*: greybox island + greybox Warzone; prove the loop is fun.
   - [x] Toolchain set up (Rojo, Blender pipeline) — 2026-10-15
   - [x] Greybox starter island model
   - [x] Each player gets their own island plot and spawns on it; fall off → put back (playtested 2026-10-15)
   - [x] Player data saving with ProfileStore (needs a published place + Studio API access to actually save)
   - [x] Blender island imported, colored, saved as `game/assets/StarterIsland.rbxm` (synced by Rojo into `ServerStorage.Assets`) — playtested
   - [x] Published privately as **"Sky Farm Prototype"** (placeholder name) — 2026-10-15. Universe 10771160256, place 70908743282881. Last update published 2026-10-24 (ores, furnace, iron tools)
   - [x] Studio access to API services enabled (2026-10-15): Studio playtests of the published place can save; since 2026-10-24 they use their own separate save, never real players' data
   - [x] Gather → craft → farm basics: chop/mine, 6 farm plots with offline growth, market stand, workbench + swords, XP/levels, HUD (playtested 2026-10-15)
   - [x] Greybox Warzone + loot heads: portal (level 10), chests, Slimes/Brutes, PvP, raid bag, extraction, loot heads (playtested 2026-10-15)
   - [x] Beginner quests ([[Tutorial & Quests]]) with tracker + highlight
   - [x] Art + UI overhaul (2026-10-15): stylized low-poly props (workbench, market stall, portal arch, planter beds, crop growth models), 4 island tiers, new HUD/windows/prompts
   - [x] Island expansion: buy bigger islands with coins (4 tiers) — playtested
   - [x] Minecraft pivot (2026-10-15): block islands, break/place blocks, 5-slot hotbar + inventory, crafting table & farmland blocks, Town with the Market, portal travel — playtested
   - [x] Tools + toughness (2026-10-15): pickaxe/axe/shovel/sword in Wooden/Stone/Crystal, block hardness, mining speed, durability, pixel-art tool models, crafting table with item photos, click-to-farm, Merchant NPC — playtested
   - [x] Ores + smelting (2026-10-24): coal/iron ore (regrowing boulders + underside veins), Furnace, Iron tool tier, 4 new quests — playtested
   - [x] Art pass (2026-10-24): low-poly 3D tools/crops/ores with pre-rendered icon sheet, original Merchant, runestone portals
   - [x] Town as a separate place with teleports (published 2026-10-24) — [ ] test the teleports live
   - [x] Resource nodes + perennial crops, no timers/hints, trade values for every item (2026-10-24) — playtested
   - [ ] UI style refresh (less generic / "AI-looking"): chosen style "Workshop" (wood frames, parchment panels, storybook serif titles)
   - [ ] Player trading in Town (design notes in [[Economy & Values]])
   - [ ] Saplings, a hoe to make farmland
   - [ ] Add the Warzone to Town (when you're ready)
   - [ ] Warzone arena art (still greybox)
   - [ ] Playtest with real people: is the loop fun?
3. **Vertical slice:** one polished island tier + one Warzone map, real UI, saving.
4. **Soft launch:** small audience, measure retention, fix.
5. **Launch + ads.**
6. **Live ops:** steady update rhythm (see [[Anti-Burnout Ideas]]).
