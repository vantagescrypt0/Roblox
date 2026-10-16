# Roadmap (Draft)
No dates — quality over speed.

1. **Pre-production:** concept, pillars, core loop, open questions answered. (Mostly done; some questions still open.)
2. **Prototype** ← *we are here*: greybox island + greybox Warzone; prove the loop is fun.
   - [x] Toolchain set up (Rojo, Blender pipeline) — 2026-10-15
   - [x] Greybox starter island model
   - [x] Each player gets their own island plot and spawns on it; fall off → put back (playtested 2026-10-15)
   - [x] Player data saving with ProfileStore (needs a published place + Studio API access to actually save)
   - [x] Blender island imported, colored, saved as `game/assets/StarterIsland.rbxm` (synced by Rojo into `ServerStorage.Assets`) — playtested
   - [x] Published privately as **"Sky Farm Prototype"** (placeholder name) — 2026-10-15. Universe 10771160256, place 70908743282881
   - [ ] Enable Studio access to API services (Game Settings → Security) so data saves in Studio playtests too
   - [x] Gather → craft → farm basics: chop/mine, 6 farm plots with offline growth, market stand, workbench + swords, XP/levels, HUD (playtested 2026-10-15)
   - [x] Greybox Warzone + loot heads: portal (level 10), chests, Slimes/Brutes, PvP, raid bag, extraction, loot heads (playtested 2026-10-15)
   - [x] Beginner quests ([[Tutorial & Quests]]) with tracker + highlight
   - [x] Art + UI overhaul (2026-10-15): stylized low-poly props (workbench, market stall, portal arch, planter beds, crop growth models), 4 island tiers, new HUD/windows/prompts
   - [x] Island expansion: buy bigger islands with coins (4 tiers) — playtested
   - [x] Minecraft pivot (2026-10-15): block islands, break/place blocks, 5-slot hotbar + inventory, crafting table & farmland blocks, Town with the Market, portal travel — playtested
   - [x] Tools + toughness (2026-10-15): pickaxe/axe/shovel/sword in Wooden/Stone/Crystal, block hardness, mining speed, durability, pixel-art tool models, crafting table with item photos, click-to-farm, Merchant NPC — playtested
   - [ ] More blocks (ores?), saplings, a hoe to make farmland
   - [ ] Add the Warzone to Town (when you're ready)
   - [ ] Warzone arena art (still greybox)
   - [ ] Playtest with real people: is the loop fun?
3. **Vertical slice:** one polished island tier + one Warzone map, real UI, saving.
4. **Soft launch:** small audience, measure retention, fix.
5. **Launch + ads.**
6. **Live ops:** steady update rhythm (see [[Anti-Burnout Ideas]]).
