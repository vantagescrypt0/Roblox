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
   - [x] UI style refresh (2026-10-24): "Workshop" style (wood frames, parchment panels, storybook serif titles) on every screen. Playtested in Studio; not published yet
   - [x] Player trading in Town (2026-10-24): invite, two-step accept with countdown, value warning, trade log — see [[Economy & Values]]. Playtested in Studio with two players; not published yet
   - [x] Skills (2026-10-24): Mining, Woodcutting and Crafting join Farming and Combat; Skills window; Iron/Crystal tools need Crafting + their skill level; double drops for gathering skills. Playtested in Studio; not published yet — see [[Skills & Levels]]
   - [x] Hoes (2026-10-25): 4 tiers gated by Farming (+ Crafting), till grass/dirt into saved farm plots (more as Farming levels up), shovel undoes, hoe adds a double-crop bonus — playtested in Studio; not published yet. See [[Skills & Levels]]
   - [x] Saplings (2026-10-25): leaves drop saplings; plant on grass/dirt, grows into a tree in 3 min; more trees as Woodcutting levels up — playtested in Studio; not published yet
   - [x] Nodes rethink (2026-10-25): trees are chop-once (felled trees drop their leaves and give ≥1 sapling); only ores and crops grow back — playtested in Studio; not published yet
   - [x] Trading needs level 5; items only (2026-10-25) — not published yet
   - [x] Town hub (2026-10-25): Merchant, Lumberjack, Miner and Builder stalls around a plaza with a well; portal row to the worlds — playtested in Studio; not published yet. See [[Town & Worlds]]
   - [x] Mining, Woodcutting and Farming worlds as their own places (2026-10-25) — each playtested in Studio
   - [x] Published everything (2026-10-25): Island + Town updated, 3 new places (Mining 97612918094932, Woodcutting 75392192647539, Farming 134413726720555) — portals tested live by you
   - [x] Look pass (2026-10-25): 20 new blocks + glass/water; Town rebuilt with walk-in shops, fountain square, cottages, garden, park; Mining mountain with a walk-in mine; Woodcutting hills, river, lumber camp; Farming barn, windmill, farmhouse, fenced fields — playtested in Studio; published 2026-10-25 (all 5 places). See [[Town & Worlds]]
   - [x] Grand worlds (2026-10-26): each world is ~3x wider, an arrival island + 3 zone islands joined by bridges, each zone with its own resource and level gate (Birch/Spruce/Cherry wood, gold, pumpkins, melons); natural island edges, waterfalls, floating islets; merged scenery keeps worlds at ~20-30k parts; pixel-font signs up high; Town's "THE WORLDS" gate fixed - published 2026-10-26 (all 5 places). See [[Town & Worlds]]
   - [x] Flying for you only, in every place: double-tap Space (2026-10-26) - published
   - [x] Worlds, second pass (2026-10-26, your notes + 8 Skybounds shots): one-sided hand-made signs (rustic, arrow signposts, hanging) instead of big plank boards; Farming as open fields with winding paths and water lines, hay, a silo; Mining as jagged sandstone peaks, a timber arch, pavilions, a stone bridge, and a section per ore inside (Lantern Hall, Coal Seam, Iron Vein, Lava Cavern, Gold Chamber, Crystal Grotto); Woodcutting with coarse dirt, a rocky hill, boulders, giant mushrooms, vines, stone paths; "Traveling" spelling - playtested in Studio; published 2026-10-26 ~21:00 (all 5 places)
   - [x] Town redesign after your Skybounds spawn shots (2026-10-26): spawn islet, stone bridge with lantern posts and flower boxes, a mountain with the SKYBLOX logo over a stone arch, striped market stalls, lantern-box lamp posts, flowers; ~19k parts - playtested in Studio; published (Town). See [[Town & Worlds]]
   - [ ] **Next up (your notes, 2026-10-26 night):** everything grander (mine 4x+, more zones, crops, ores, trees, NPCs; ask before new content); StreamingEnabled; ores as regrowing nodes everywhere (rarer = slower) that turn into a pale empty node when mined; no breaking nodes without the right tool in public areas; a hoe to harvest crops, an axe for pumpkins and melons; a starter hoe for every player; an **Inbox** for items from traders, starter kits and more; harder leveling for skills and player levels; quests ready to grow; a big coin economy (the richest players hold 100M+ to buy the best things). See the Decision Log
   - [ ] Phone performance check of the bigger worlds (part counts printed as "[World] ..." on server start)
   - [ ] Slaying World (PvE spawners) — its Town portal is boarded up until then
   - [ ] Rare ores, trees and crops found outside the worlds (e.g. the Warzone); node items you can own and place
   - [ ] Add the Warzone to Town (when you're ready)
   - [ ] Warzone arena art (still greybox)
   - [ ] Playtest with real people: is the loop fun?
   - Future ideas (your list, 2026-10-26; not started): **Enchants**, **Pets**, **Warzone** and the ideas that come with it, **Auction House**, **Coinflip** (check Roblox's gambling rules and our [[Monetization Principles]] first: if coins can be bought with Robux, a coinflip counts as paid gambling, which is off-limits for our young audience). At the very end: **Gamepasses and other Robux income** (see [[Monetization Principles]])
3. **Vertical slice:** one polished island tier + one Warzone map, real UI, saving.
4. **Soft launch:** small audience, measure retention, fix.
5. **Launch + ads.**
6. **Live ops:** steady update rhythm (see [[Anti-Burnout Ideas]]).
