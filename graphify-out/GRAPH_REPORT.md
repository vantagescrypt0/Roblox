# Graph Report - Roblox  (2026-10-26)

## Corpus Check
- 118 files · ~114,450 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 852 nodes · 2019 edges · 49 communities (40 shown, 9 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 375 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Context.luau
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- Builder
- Economy.luau
- Anti-Burnout Ideas
- items3d.py
- Home
- Warzone
- Main.server.luau
- Handoff (updated 2026-10-26 ~21:05, session 3)
- Level gates: crops need Farming level, mobs need Combat level
- common.py
- Decor.luau
- Tools and Workflow
- blocks.py
- FarmService.luau
- Warzone
- Trends - Oct 2026
- HotbarService.luau
- Town & Worlds
- lowpoly.py
- Main.client.luau
- Inbox
- Signs.luau
- ShopService.luau
- Islands (Roblox)
- Published privately as Sky Farm Prototype
- Economy & Values
- QuestService.luau
- Leveling.luau
- graph_to_vault.py
- AmbientController.luau
- hoe
- math
- InventoryService.luau
- FlightController.luau
- Seasons of 2-4 months; player level resets
- CraftingWindow.luau
- Decision: block toughness + tool power (Minecraft rules)
- Merchant NPC at the Town market

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 38 edges
2. `Builder` - 24 edges
3. `part()` - 24 edges
4. `Home` - 23 edges
5. `Skills & Levels` - 21 edges
6. `Theme.corner()` - 20 edges
7. `build_tier()` - 19 edges
8. `Theme.stroke()` - 19 edges
9. `BlockWorld.key()` - 19 edges
10. `Warzone` - 18 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md
- `Idle-grow / cozy trend (Grow a Garden spike and decay)` --semantically_similar_to--> `Offline progress and timers`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Anti-Burnout Ideas.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (49 total, 9 thin omitted)

### Community 0 - "Context.luau"
Cohesion: 0.05
Nodes (41): Decision: falling off returns you to your island, buildArrival(), notice(), onFarmClick(), Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest() (+33 more)

### Community 1 - "Theme.make"
Cohesion: 0.09
Nodes (64): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+56 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.08
Nodes (44): nearStation(), set(), setFree(), top(), build(), portalFields(), regrow(), Ambience.Apply() (+36 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.14
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 4 - "Builder"
Cohesion: 0.20
Nodes (11): build_items(), Builder, marker(), matrix(), swatch_uv(), crops(), main(), market() (+3 more)

### Community 5 - "Economy.luau"
Cohesion: 0.15
Nodes (4): Economy.Total(), Economy.Value(), work(), Mining.BreakTime()

### Community 6 - "Anti-Burnout Ideas"
Cohesion: 0.20
Nodes (9): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, PvP fairness options: zones by level, new-player protection, insurance slot, Warzone zones: outer ring Slimes, center Brutes (+1 more)

### Community 7 - "items3d.py"
Cohesion: 0.09
Nodes (18): carrot(), downscale(), load_blocks(), melon(), over(), read_image(), render_icon(), render_icons() (+10 more)

### Community 8 - "Home"
Cohesion: 0.31
Nodes (16): Core Loop, Islands Feature Checklist, Skills & Levels, Tutorial & Quests, Warzone, Content Index, Decision Log, Open Questions (+8 more)

### Community 9 - "Warzone"
Cohesion: 0.19
Nodes (11): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+3 more)

### Community 10 - "Main.server.luau"
Cohesion: 0.12
Nodes (6): inReach(), capitalized(), TravelService.Go(), checkCell(), onPlant(), onUproot()

### Community 11 - "Handoff (updated 2026-10-26 ~21:05, session 3)"
Cohesion: 0.29
Nodes (6): Handoff (updated 2026-10-26 ~21:05, session 3), How-to notes, In progress: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Later, Leftovers, State

### Community 12 - "Level gates: crops need Farming level, mobs need Combat level"
Cohesion: 0.40
Nodes (5): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5)

### Community 13 - "common.py"
Cohesion: 0.23
Nodes (12): export_fbx(), hex_rgb(), material(), mesh_object(), bridge(), dirt_body(), grass_top(), main() (+4 more)

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.21
Nodes (13): Blender driven by Python scripts, ProfileStore (player data with session locking), Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import (+5 more)

### Community 16 - "blocks.py"
Cohesion: 0.16
Nodes (21): bricks_tile(), clamp(), draw_building_tiles(), planks_tile(), draw_reference_tiles(), draw_tiles(), ore(), draw_zone_tiles() (+13 more)

### Community 17 - "FarmService.luau"
Cohesion: 0.25
Nodes (17): bestSeed(), blockCrop(), FarmService.Harvest(), FarmService.ShowCrop(), FarmService.Start(), heldSeed(), heldTool(), makePlot() (+9 more)

### Community 19 - "Warzone"
Cohesion: 0.18
Nodes (12): Trading shut down after a duplication exploit [Unverified], Key-gated adventure islands, Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Item leveling: gear grows the more you use it, Mechanics to Borrow (+4 more)

### Community 20 - "Trends - Oct 2026"
Cohesion: 0.22
Nodes (8): Totems: passive resource generators with a range, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers, Passive generators with a range limit

### Community 21 - "HotbarService.luau"
Cohesion: 0.46
Nodes (6): HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 22 - "Town & Worlds"
Cohesion: 0.29
Nodes (7): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "lowpoly.py"
Cohesion: 0.23
Nodes (11): build_atlas(), main(), render_preview(), reset_scene(), save_blend(), main(), main(), export_fbx() (+3 more)

### Community 24 - "Main.client.luau"
Cohesion: 0.06
Nodes (12): greet(), NpcController.Start(), track(), update(), makeArea(), WorldService.Start(), addNameTag(), Npc.Build() (+4 more)

### Community 29 - "Signs.luau"
Cohesion: 0.13
Nodes (19): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+11 more)

### Community 30 - "ShopService.luau"
Cohesion: 0.21
Nodes (7): InventoryService.SpendCoins(), nearShop(), onBuy(), onSell(), ShopService.Start(), TownService.GetShopkeepers(), Prompts.Create()

### Community 32 - "Islands (Roblox)"
Cohesion: 0.13
Nodes (15): Design Pillars, Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Token-summoned bosses with cooldowns (+7 more)

### Community 33 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "QuestService.luau"
Cohesion: 0.52
Nodes (5): checkReach(), complete(), currentQuest(), giveReward(), QuestService.Record()

### Community 38 - "Leveling.luau"
Cohesion: 0.29
Nodes (6): Better rewards as skills level up, ProgressionService.AddPlayerXP(), Leveling.BonusChance(), Leveling.PlantedTrees(), Leveling.TilledPlots(), Leveling.XPToNext()

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 41 - "hoe"
Cohesion: 0.19
Nodes (11): axe(), thickness(), handle(), hoe(), new_verts(), pickaxe(), build_head(), z_at() (+3 more)

### Community 42 - "math"
Cohesion: 0.26
Nodes (9): build_tier(), leaves(), outline(), plot_positions(), radius_at(), ring(), rock(), tree() (+1 more)

### Community 43 - "InventoryService.luau"
Cohesion: 0.27
Nodes (11): treeFell(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn(), InventoryService.Count(), InventoryService.Remove() (+3 more)

### Community 44 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 45 - "Seasons of 2-4 months; player level resets"
Cohesion: 0.33
Nodes (5): Skybounds seasons: 2-4 months, level resets, Player level 1-50 (XP from PvE, grinding, quests), Seasons of 2-4 months; player level resets, Level 10 unlocks the Warzone, What resets each season?

### Community 46 - "CraftingWindow.luau"
Cohesion: 0.05
Nodes (43): Decision: click-only farming, Decision: 5-slot Minecraft-style hotbar, aim(), aimedShop(), BlockController.Start(), burst(), interact(), place() (+35 more)

### Community 47 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.33
Nodes (4): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules)

### Community 48 - "Merchant NPC at the Town market"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Skybounds (Minecraft Skyblock server, now shut down)`, `Roleplay + simulator hybrids growing [Unverified]`, `Inbox` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 167 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Home` to `Islands (Roblox)`, `Anti-Burnout Ideas`, `Warzone`, `Tools and Workflow`, `Warzone`, `Trends - Oct 2026`?**
  _High betweenness centrality (0.309) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Skybounds (Minecraft Skyblock server, now shut down)` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Context.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.05443037974683544 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `blocks.py`?**
  _High betweenness centrality (0.307) - this node is a cross-community bridge._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08576576576576576 - nodes in this community are weakly interconnected._
- **Should `BlockWorld.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.07541478129713423 - nodes in this community are weakly interconnected._