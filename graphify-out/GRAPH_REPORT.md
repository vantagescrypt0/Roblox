# Graph Report - Roblox  (2026-10-27)

## Corpus Check
- 121 files · ~125,021 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 887 nodes · 2074 edges · 53 communities (41 shown, 12 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 372 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b66c289a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Worlds/Mining.luau
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- BlockController.luau
- balance.py
- items3d.py
- Home
- Monetization Principles
- BlockService.luau
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Roadmap
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- blocks.py
- FarmService.luau
- Loot head: your loot drops in your avatar's head on death
- Builder
- CraftingWindow.luau
- HotbarService.luau
- Town & Worlds
- common.py
- WorldService.Start
- Inbox
- Signs.luau
- ShopService.luau
- Islands (Roblox)
- Economy.luau
- Economy & Values
- QuestService.luau
- Leveling.luau
- graph_to_vault.py
- AmbientController.luau
- hoe
- Main.server.luau
- Trends - Oct 2026
- lowpoly.py
- Skybounds (Minecraft)
- Farming.luau
- Decision Log
- math
- InboxService.luau
- replicatedstorage_shared_blocks
- Hotbar.luau

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 39 edges
2. `Builder` - 24 edges
3. `part()` - 24 edges
4. `Home` - 23 edges
5. `Skills & Levels` - 22 edges
6. `Theme.corner()` - 21 edges
7. `Theme.stroke()` - 20 edges
8. `build_tier()` - 19 edges
9. `Warzone` - 18 edges
10. `Theme.text()` - 17 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, NOT committed yet` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (53 total, 12 thin omitted)

### Community 0 - "Worlds/Mining.luau"
Cohesion: 0.16
Nodes (9): ctx.Noise(), mesaDistance(), chamber(), findCaves(), inCave(), mountainHeights(), segment(), slope() (+1 more)

### Community 1 - "Theme.make"
Cohesion: 0.08
Nodes (66): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+58 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.08
Nodes (43): nearStation(), set(), setFree(), top(), build(), portalFields(), Ambience.Apply(), ensure() (+35 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.14
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 5 - "BlockController.luau"
Cohesion: 0.08
Nodes (18): aim(), aimedShop(), BlockController.Start(), burst(), interact(), place(), rootPosition(), screenRay() (+10 more)

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.10
Nodes (15): build_items(), downscale(), load_blocks(), melon(), over(), read_image(), render_icon(), render_icons() (+7 more)

### Community 8 - "Home"
Cohesion: 0.20
Nodes (21): Design Pillars, Pitch (Draft), Target Audience, Anti-Burnout Ideas, Prestige with real unlocks, Seasonal Warzone maps and loot tables, Core Loop, Island loop: gather, craft, expand, automate, earn offline (+13 more)

### Community 9 - "Monetization Principles"
Cohesion: 0.24
Nodes (7): Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added), Monetization Principles

### Community 10 - "BlockService.luau"
Cohesion: 0.09
Nodes (11): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5), inReach(), treeFell(), capitalized() (+3 more)

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.16
Nodes (14): Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Handoff (updated 2026-10-27 ~22:35, session 4), How-to notes, Later, Leftovers, Session 4 (2026-10-27): streaming done and playtested, Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, NOT committed yet (+6 more)

### Community 12 - "Roadmap"
Cohesion: 0.24
Nodes (8): Content Index, Prototype phase (current), Published privately as Sky Farm Prototype, Roadmap, Vertical slice, then soft launch, launch and live ops, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.21
Nodes (3): offered(), setOffer(), wearBar()

### Community 14 - "Decor.luau"
Cohesion: 0.08
Nodes (50): buildArrival(), Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower() (+42 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.21
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "blocks.py"
Cohesion: 0.19
Nodes (19): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_node_tiles(), draw_reference_tiles(), draw_tiles() (+11 more)

### Community 17 - "FarmService.luau"
Cohesion: 0.48
Nodes (6): Decision: click-only farming, blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual()

### Community 18 - "Loot head: your loot drops in your avatar's head on death"
Cohesion: 0.22
Nodes (6): Trading shut down after a duplication exploit [Unverified], Skybounds: your head drops on death with your loot, Loot head: your loot drops in your avatar's head on death, Raid bag + extraction pads, ProfileStore (player data with session locking), Loot head rules: how much, who opens first, despawn

### Community 19 - "Builder"
Cohesion: 0.21
Nodes (10): Builder, marker(), matrix(), swatch_uv(), crops(), main(), market(), planter() (+2 more)

### Community 20 - "CraftingWindow.luau"
Cohesion: 0.26
Nodes (11): check(), choose(), CraftingWindow.SetState(), ingredientChip(), levelOf(), render(), renderDetail(), skillChip() (+3 more)

### Community 21 - "HotbarService.luau"
Cohesion: 0.39
Nodes (7): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 22 - "Town & Worlds"
Cohesion: 0.29
Nodes (7): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "common.py"
Cohesion: 0.24
Nodes (15): make_block(), make_merged(), quad(), tile_rect(), hex_rgb(), material(), mesh_object(), bridge() (+7 more)

### Community 24 - "WorldService.Start"
Cohesion: 0.24
Nodes (6): makeArea(), WorldService.Start(), spawnCharacter(), Spawning.MakeSpawn(), Spawning.Start(), Places.Current()

### Community 29 - "Signs.luau"
Cohesion: 0.13
Nodes (19): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+11 more)

### Community 30 - "ShopService.luau"
Cohesion: 0.12
Nodes (21): bestSeed(), useTool(), open(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn() (+13 more)

### Community 32 - "Islands (Roblox)"
Cohesion: 0.15
Nodes (12): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns, Skill-gated vending machines and handshake trading (+4 more)

### Community 33 - "Economy.luau"
Cohesion: 0.15
Nodes (4): Economy.Total(), Economy.Value(), work(), Mining.BreakTime()

### Community 34 - "Economy & Values"
Cohesion: 0.25
Nodes (8): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "QuestService.luau"
Cohesion: 0.52
Nodes (5): checkReach(), complete(), currentQuest(), giveReward(), QuestService.Record()

### Community 38 - "Leveling.luau"
Cohesion: 0.25
Nodes (4): Better rewards as skills level up, ProgressionService.AddPlayerXP(), Leveling.PlantedTrees(), Leveling.PlayerXPToNext()

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 41 - "hoe"
Cohesion: 0.19
Nodes (11): axe(), thickness(), handle(), hoe(), new_verts(), pickaxe(), build_head(), z_at() (+3 more)

### Community 43 - "Trends - Oct 2026"
Cohesion: 0.22
Nodes (8): Totems: passive resource generators with a range, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers, Passive generators with a range limit

### Community 44 - "lowpoly.py"
Cohesion: 0.24
Nodes (11): main(), export_fbx(), render_preview(), reset_scene(), save_blend(), main(), main(), export_fbx() (+3 more)

### Community 45 - "Skybounds (Minecraft)"
Cohesion: 0.16
Nodes (13): Mobile-first UI, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down), Skybounds Warzone (the user's favorite moment), Item leveling: gear grows the more you use it (+5 more)

### Community 46 - "Farming.luau"
Cohesion: 0.50
Nodes (7): crossPathZ(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), veggiePathZ(), wave()

### Community 47 - "Decision Log"
Cohesion: 0.12
Nodes (16): NPC visits at milestones with a starter pack, Economy sinks to slow inflation, Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Warzone parked until it moves into Town, Merchant NPC at the Town market, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: buy bigger islands with coins (4 tiers), Decision: Market moved off the island into Town (+8 more)

### Community 48 - "math"
Cohesion: 0.18
Nodes (13): build_tier(), leaves(), outline(), plot_positions(), radius_at(), ring(), rock(), tree() (+5 more)

### Community 49 - "InboxService.luau"
Cohesion: 0.60
Nodes (4): clean(), deliver(), InboxService.Send(), InboxService.Start()

### Community 52 - "Hotbar.luau"
Cohesion: 0.12
Nodes (21): Decision: 5-slot Minecraft-style hotbar, anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff() (+13 more)

## Knowledge Gaps
- **14 isolated node(s):** `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 185 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `Handoff (updated 2026-10-27 ~22:35, session 4)` to `blocks.py`?**
  _High betweenness centrality (0.247) - this node is a cross-community bridge._
- **Are the 23 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08475734791524266 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `math`, `Handoff (updated 2026-10-27 ~22:35, session 4)`?**
  _High betweenness centrality (0.244) - this node is a cross-community bridge._
- **Should `BlockWorld.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.07607843137254902 - nodes in this community are weakly interconnected._
- **Why does `regrow()` connect `Handoff (updated 2026-10-27 ~22:35, session 4)` to `WorldService.Start`, `FarmService.luau`, `BlockWorld.luau`, `WorldService.luau`?**
  _High betweenness centrality (0.231) - this node is a cross-community bridge._