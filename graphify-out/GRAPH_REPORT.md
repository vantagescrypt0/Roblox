# Graph Report - Roblox  (2026-11-01)

## Corpus Check
- 148 files · ~181,517 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 1172 nodes · 2721 edges · 79 communities (53 shown, 26 thin omitted)
- Extraction: 84% EXTRACTED · 16% INFERRED · 0% AMBIGUOUS · INFERRED: 448 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2ecdd4b5`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Islands (Roblox)
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- Context.luau
- Economy.luau
- balance.py
- items3d.py
- Main.server.luau
- Monetization Principles
- FarmService.luau
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Seasons of 2-4 months; player level resets
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- math
- Context.luau
- new_verts
- QuestService.luau
- FlightController.luau
- store_art.py
- Town & Worlds
- SwimController.luau
- Anti-Burnout Ideas
- Inbox
- Signs.luau
- ShopService.luau
- arc
- Decision: block toughness + tool power (Minecraft rules)
- Economy & Values
- render_icons
- Main.client.luau
- graph_to_vault.py
- AmbientController.luau
- Home
- CraftingService.luau
- Farming.luau
- Mining phase: build plan (2026-10-31)
- InboxService.luau
- WorldService.luau
- Late-game proposal (2026-10-29)
- blocks.py
- BlockWorld.position
- Crafting Proposal (2026-10-31, APPROVED as written the same night)
- TradeService.luau
- Roadmap
- HotbarService.luau
- Build.luau
- Npc.luau
- TrophyModels.luau
- script_parent_parent_util_blockworld
- gem_bench
- Skybounds (Minecraft)
- bucket
- melon
- CombatService.luau
- wood_handle
- front_slab
- TravelService.luau
- UI study (2026-10-29)
- Published privately as Sky Farm Prototype
- pickaxe
- iron_plate
- pumpkin
- starstone

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 44 edges
2. `Builder` - 26 edges
3. `scene_world()` - 26 edges
4. `Handoff` - 25 edges
5. `Theme.corner()` - 24 edges
6. `part()` - 24 edges
7. `scene_icon()` - 23 edges
8. `Theme.stroke()` - 23 edges
9. `Skills & Levels` - 23 edges
10. `Home` - 23 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming)` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, committed as `b66c289` (harvest wear removed later in part 4)` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (79 total, 26 thin omitted)

### Community 0 - "Islands (Roblox)"
Cohesion: 0.19
Nodes (12): Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns, Totems: passive resource generators with a range, Item leveling: gear grows the more you use it (+4 more)

### Community 1 - "Theme.make"
Cohesion: 0.05
Nodes (98): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.SelectedItem(), Hotbar.SetState(), Hotbar.Start(), render(), showName(), slotX() (+90 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.14
Nodes (18): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, regrow(), BlockWorld.drawAll(), BlockWorld.occupied(), BlockWorld.set(), buried(), exposed(), fits() (+10 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.30
Nodes (11): describe(), dropBag(), dropLootHead(), endRaid(), enter(), extract(), isInRaid(), onCharacterAdded() (+3 more)

### Community 4 - "Context.luau"
Cohesion: 0.22
Nodes (11): ctx.Noise(), hillHeight(), roughDistance(), chamber(), ck(), findCaves(), mountainHeights(), rough() (+3 more)

### Community 5 - "Economy.luau"
Cohesion: 0.40
Nodes (3): Economy.Total(), Economy.Value(), work()

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.08
Nodes (9): anvil(), carrot(), gem_cluster(), sapling(), scrap(), sliver(), to_roblox(), twine() (+1 more)

### Community 9 - "Monetization Principles"
Cohesion: 0.15
Nodes (18): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+10 more)

### Community 10 - "FarmService.luau"
Cohesion: 0.20
Nodes (9): blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual(), checkCell(), onPlant(), onUproot() (+1 more)

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.08
Nodes (26): (2026-10-31 night): scooping restored, committed, NOT published, Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Earlier today (session 6): UI restyle DONE in Studio, NOT committed, NOT published, Earlier today: the 4x pass — Town and the Grinding Worlds, Handoff, How-to notes, Later, LATEST (2026-10-31 ~22:45, session 7): published scooping, swimming done, crafting approved (+18 more)

### Community 12 - "Seasons of 2-4 months; player level resets"
Cohesion: 0.20
Nodes (6): Skybounds seasons: 2-4 months, level resets, Better rewards as skills level up, Player level 1-50 (XP from PvE, grinding, quests), Seasons of 2-4 months; player level resets, Level 10 unlocks the Warzone, What resets each season?

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.14
Nodes (6): countLabel(), doneCount(), stateOf(), SkillsWindow.Toggle(), offered(), setOffer()

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "math"
Cohesion: 0.07
Nodes (45): build_atlas(), main(), export_fbx(), hex_rgb(), material(), mesh_object(), render_preview(), reset_scene() (+37 more)

### Community 17 - "Context.luau"
Cohesion: 0.17
Nodes (23): Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path(), Common.Pond() (+15 more)

### Community 18 - "new_verts"
Cohesion: 0.19
Nodes (9): axe(), thickness(), handle(), hoe(), new_verts(), shovel(), slab(), sturdy_handle() (+1 more)

### Community 19 - "QuestService.luau"
Cohesion: 0.26
Nodes (8): boardCurrent(), checkReach(), complete(), completeBoard(), currentQuest(), giveReward(), QuestService.Record(), reachValue()

### Community 20 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 21 - "store_art.py"
Cohesion: 0.08
Nodes (53): add_mesh(), anvil_mesh(), Assets, blur(), box(), camera(), caption(), cave_shell() (+45 more)

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "SwimController.luau"
Cohesion: 0.33
Nodes (10): add(), anyDown(), characterParts(), columnSurface(), over(), startSwimming(), step(), stopSwimming() (+2 more)

### Community 24 - "Anti-Burnout Ideas"
Cohesion: 0.13
Nodes (13): Skill-gated vending machines and handshake trading, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log) (+5 more)

### Community 29 - "Signs.luau"
Cohesion: 0.14
Nodes (18): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+10 more)

### Community 30 - "ShopService.luau"
Cohesion: 0.13
Nodes (18): bestSeed(), open(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.Count(), InventoryService.Remove() (+10 more)

### Community 32 - "arc"
Cohesion: 0.33
Nodes (3): arc(), rope(), ui_bag()

### Community 33 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.14
Nodes (4): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules)

### Community 34 - "Economy & Values"
Cohesion: 0.25
Nodes (8): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "render_icons"
Cohesion: 0.17
Nodes (10): downscale(), load_blocks(), over(), read_image(), render_icon(), render_icons(), setup_lights(), with_outline() (+2 more)

### Community 38 - "Main.client.luau"
Cohesion: 0.06
Nodes (15): Decision: click-only farming, aim(), aimedShop(), rootPosition(), screenRay(), shopkeepers(), workArea(), fadeTo() (+7 more)

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 41 - "Home"
Cohesion: 0.19
Nodes (14): Design Pillars, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Game name still undecided (can't reuse Islands/Skyblock/Skybounds) (+6 more)

### Community 42 - "CraftingService.luau"
Cohesion: 0.22
Nodes (5): craft(), nearStation(), ProgressionService.AddPlayerXP(), unlockedBy(), Leveling.PlayerXPToNext()

### Community 45 - "Farming.luau"
Cohesion: 0.16
Nodes (7): crossPathZ(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), veggiePathZ(), wave()

### Community 46 - "Mining phase: build plan (2026-10-31)"
Cohesion: 0.29
Nodes (7): Art, Mining phase: build plan (2026-10-31), Order, Slivers and nodes, The deep cave (Worlds/Mining.luau), The ores (the deep cave, under the Gold Chamber), Tool tiers and parts (from the Crafting Proposal)

### Community 48 - "InboxService.luau"
Cohesion: 0.60
Nodes (4): clean(), deliver(), InboxService.Send(), InboxService.Start()

### Community 50 - "WorldService.luau"
Cohesion: 0.09
Nodes (6): Decision: falling off returns you to your island, makeArea(), WorldService.Start(), spawnCharacter(), Spawning.MakeSpawn(), Spawning.Start()

### Community 52 - "Late-game proposal (2026-10-29)"
Cohesion: 0.22
Nodes (9): 1. New resources (13), 2. New tool tiers (2, x 5 kinds = 10 tools), 3. Big things to buy (10M–50M), 4. The order to build it in, Farming: four new zone islands (4), Late-game proposal (2026-10-29), Mining: a deeper cave under the Gold Chamber (5), Questions (+1 more)

### Community 53 - "blocks.py"
Cohesion: 0.13
Nodes (26): bricks_tile(), clamp(), draw_building_tiles(), planks_tile(), draw_deep_ore_tiles(), clumps(), crystals(), darker() (+18 more)

### Community 55 - "BlockWorld.position"
Cohesion: 0.18
Nodes (14): build(), buildArrival(), portalFields(), Ambience.Apply(), ensure(), BlockWorld.partCount(), BlockWorld.position(), Pace.Begin() (+6 more)

### Community 56 - "Crafting Proposal (2026-10-31, APPROVED as written the same night)"
Cohesion: 0.33
Nodes (6): Crafting Proposal (2026-10-31, APPROVED as written the same night), New stations, Questions, The ladder, The rule, What it adds

### Community 58 - "Roadmap"
Cohesion: 0.16
Nodes (17): NPC visits at milestones with a starter pack, Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Warzone parked until it moves into Town, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds) (+9 more)

### Community 59 - "HotbarService.luau"
Cohesion: 0.39
Nodes (7): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 60 - "Build.luau"
Cohesion: 0.18
Nodes (11): set(), setFree(), top(), BlockWorld.get(), BlockWorld.setRaw(), Build.Fill(), Build.Set(), Build.SetFree() (+3 more)

### Community 62 - "TrophyModels.luau"
Cohesion: 0.73
Nodes (5): build(), emblem(), piece(), TrophyModels.Make(), weld()

### Community 63 - "script_parent_parent_util_blockworld"
Cohesion: 0.15
Nodes (7): liquidAt(), touches(), LiquidModels.Make(), make(), piece(), settle(), weld()

### Community 65 - "Skybounds (Minecraft)"
Cohesion: 0.15
Nodes (11): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Islands (Roblox game by Easy.gg), Full albums (sent 2026-10-28, from imgur), Skybounds reference shots, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down) (+3 more)

### Community 68 - "CombatService.luau"
Cohesion: 0.25
Nodes (6): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing()

### Community 71 - "front_slab"
Cohesion: 0.33
Nodes (3): front_slab(), ui_mail(), ui_trophy()

### Community 73 - "UI study (2026-10-29)"
Cohesion: 0.50
Nodes (4): Proposed Skycore style (combining them), Shared lessons, UI study (2026-10-29), What each does well

### Community 74 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 75 - "pickaxe"
Cohesion: 1.00
Nodes (3): pickaxe(), build_head(), z_at()

## Knowledge Gaps
- **14 isolated node(s):** `Conveyor factories (splitters, filters, sensors)`, `Hidden fossil collection quests`, `Token-summoned bosses with cooldowns`, `Skybounds (Minecraft Skyblock server, now shut down)`, `Rokit toolchain: StyLua, Selene, luau-lsp` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 316 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **26 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `BlockWorld.luau` to `Handoff (updated 2026-10-27 ~22:35, session 4)`, `blocks.py`?**
  _High betweenness centrality (0.322) - this node is a cross-community bridge._
- **Are the 27 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildCelebration()`) actually correct?**
  _`Theme.make()` has 27 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Conveyor factories (splitters, filters, sensors)`, `Hidden fossil collection quests`, `Token-summoned bosses with cooldowns` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.05009179124049305 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `BlockWorld.luau`, `store_art.py`?**
  _High betweenness centrality (0.315) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `scene_world()` (e.g. with `store_art.py` and `.build()`) actually correct?**
  _`scene_world()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Should `BlockWorld.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.14130434782608695 - nodes in this community are weakly interconnected._