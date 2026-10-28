# Graph Report - Roblox  (2026-10-27)

## Corpus Check
- 118 files · ~119,043 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 859 nodes · 2042 edges · 55 communities (45 shown, 10 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 379 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b4e02552`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Context.luau
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- WorldService.luau
- BlockController.luau
- Build.luau
- items3d.py
- Home
- Warzone
- BlockService.luau
- Handoff (updated 2026-10-27 ~22:15, session 4)
- Skills & Levels
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- blocks.py
- FarmService.luau
- Main.server.luau
- Builder
- build
- HotbarService.luau
- Town & Worlds
- common.py
- Main.client.luau
- Inbox
- Signs.luau
- ShopService.luau
- Islands (Roblox)
- replicatedstorage_shared_blocks
- Economy & Values
- QuestService.luau
- Leveling.luau
- graph_to_vault.py
- AmbientController.luau
- hoe
- TravelService.luau
- Warzone
- lowpoly.py
- Seasons of 2-4 months; player level resets
- CraftingWindow.luau
- Decision Log
- math
- Trends - Oct 2026
- CombatService.luau
- BlockWorld.position
- FlightController.luau
- Farming.luau
- WorldService.Start

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 38 edges
2. `Builder` - 24 edges
3. `part()` - 24 edges
4. `Home` - 23 edges
5. `Skills & Levels` - 22 edges
6. `Theme.corner()` - 20 edges
7. `build_tier()` - 19 edges
8. `Theme.stroke()` - 19 edges
9. `BlockWorld.key()` - 19 edges
10. `Warzone` - 18 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, NOT committed yet` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, NOT committed yet` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (55 total, 10 thin omitted)

### Community 0 - "Context.luau"
Cohesion: 0.17
Nodes (22): buildArrival(), Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path() (+14 more)

### Community 1 - "Theme.make"
Cohesion: 0.08
Nodes (66): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+58 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.19
Nodes (20): makePlot(), onIslandCreated(), BlockWorld.drawAll(), BlockWorld.hasNeighbour(), BlockWorld.key(), BlockWorld.part(), BlockWorld.set(), BlockWorld.unkey() (+12 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.30
Nodes (11): describe(), dropBag(), dropLootHead(), endRaid(), enter(), extract(), isInRaid(), onCharacterAdded() (+3 more)

### Community 5 - "BlockController.luau"
Cohesion: 0.08
Nodes (25): Decision: 5-slot Minecraft-style hotbar, aim(), aimedShop(), BlockController.Start(), burst(), interact(), place(), rootPosition() (+17 more)

### Community 6 - "Build.luau"
Cohesion: 0.21
Nodes (9): set(), setFree(), BlockWorld.get(), BlockWorld.setRaw(), Build.Fill(), Build.Set(), Build.SetFree(), pick() (+1 more)

### Community 7 - "items3d.py"
Cohesion: 0.08
Nodes (19): build_items(), carrot(), downscale(), load_blocks(), melon(), over(), read_image(), render_icon() (+11 more)

### Community 8 - "Home"
Cohesion: 0.24
Nodes (11): Design Pillars, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Game name still undecided (can't reuse Islands/Skyblock/Skybounds) (+3 more)

### Community 9 - "Warzone"
Cohesion: 0.18
Nodes (12): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+4 more)

### Community 10 - "BlockService.luau"
Cohesion: 0.15
Nodes (4): inReach(), checkCell(), onPlant(), onUproot()

### Community 11 - "Handoff (updated 2026-10-27 ~22:15, session 4)"
Cohesion: 0.17
Nodes (13): Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Handoff (updated 2026-10-27 ~22:15, session 4), How-to notes, Later, Leftovers, Session 4 (2026-10-27): streaming done and playtested, Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, NOT committed yet, State (+5 more)

### Community 12 - "Skills & Levels"
Cohesion: 0.26
Nodes (10): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5), Prototype phase (current) (+2 more)

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.17
Nodes (6): BagWindow.SetState(), countLabel(), render(), offered(), setOffer(), wearBar()

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "blocks.py"
Cohesion: 0.15
Nodes (23): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_node_tiles(), draw_reference_tiles(), draw_tiles() (+15 more)

### Community 17 - "FarmService.luau"
Cohesion: 0.28
Nodes (15): bestSeed(), blockCrop(), FarmService.Harvest(), FarmService.ShowCrop(), FarmService.Start(), heldSeed(), heldTool(), onFarmClick() (+7 more)

### Community 18 - "Main.server.luau"
Cohesion: 0.11
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 19 - "Builder"
Cohesion: 0.21
Nodes (9): Builder, marker(), matrix(), swatch_uv(), crops(), market(), planter(), portal() (+1 more)

### Community 20 - "build"
Cohesion: 0.33
Nodes (6): build(), Ambience.Apply(), ensure(), BlockWorld.new(), BlockWorld.partCount(), ctx.Flatten()

### Community 21 - "HotbarService.luau"
Cohesion: 0.46
Nodes (6): HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 22 - "Town & Worlds"
Cohesion: 0.29
Nodes (7): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "common.py"
Cohesion: 0.23
Nodes (12): export_fbx(), hex_rgb(), material(), mesh_object(), bridge(), dirt_body(), grass_top(), main() (+4 more)

### Community 24 - "Main.client.luau"
Cohesion: 0.07
Nodes (7): greet(), NpcController.Start(), track(), update(), addNameTag(), Npc.Build(), Places.Current()

### Community 29 - "Signs.luau"
Cohesion: 0.12
Nodes (20): portalFields(), cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents() (+12 more)

### Community 30 - "ShopService.luau"
Cohesion: 0.14
Nodes (18): treeFell(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn(), InventoryService.Count(), InventoryService.Remove() (+10 more)

### Community 32 - "Islands (Roblox)"
Cohesion: 0.11
Nodes (17): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns, Skill-gated vending machines and handshake trading (+9 more)

### Community 33 - "replicatedstorage_shared_blocks"
Cohesion: 0.16
Nodes (9): ctx.Noise(), mesaDistance(), chamber(), findCaves(), inCave(), mountainHeights(), segment(), slope() (+1 more)

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

### Community 43 - "Warzone"
Cohesion: 0.19
Nodes (14): Trading shut down after a duplication exploit [Unverified], Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Item leveling: gear grows the more you use it, Mechanics to Borrow, Loot head: your loot drops in your avatar's head on death (+6 more)

### Community 44 - "lowpoly.py"
Cohesion: 0.29
Nodes (11): main(), render_preview(), reset_scene(), save_blend(), main(), main(), export_fbx(), _hex() (+3 more)

### Community 45 - "Seasons of 2-4 months; player level resets"
Cohesion: 0.29
Nodes (6): Skybounds seasons: 2-4 months, level resets, Skybounds Warzone (the user's favorite moment), Player level 1-50 (XP from PvE, grinding, quests), Seasons of 2-4 months; player level resets, Level 10 unlocks the Warzone, What resets each season?

### Community 46 - "CraftingWindow.luau"
Cohesion: 0.18
Nodes (15): addCamera(), halfExtents(), ItemIcon.create(), viewport(), check(), choose(), CraftingWindow.SetState(), ingredientChip() (+7 more)

### Community 47 - "Decision Log"
Cohesion: 0.14
Nodes (15): NPC visits at milestones with a starter pack, Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Warzone parked until it moves into Town, Merchant NPC at the Town market, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: click-only farming, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market (+7 more)

### Community 48 - "math"
Cohesion: 0.26
Nodes (9): build_tier(), leaves(), outline(), plot_positions(), radius_at(), ring(), rock(), tree() (+1 more)

### Community 49 - "Trends - Oct 2026"
Cohesion: 0.22
Nodes (8): Totems: passive resource generators with a range, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers, Passive generators with a range limit

### Community 50 - "CombatService.luau"
Cohesion: 0.33
Nodes (6): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing()

### Community 51 - "BlockWorld.position"
Cohesion: 0.31
Nodes (8): nearStation(), top(), BlockWorld.position(), Build.Top(), Portal.addCells(), Portal.makeClosed(), Portal.makeField(), sheet()

### Community 52 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 53 - "Farming.luau"
Cohesion: 0.50
Nodes (7): crossPathZ(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), veggiePathZ(), wave()

### Community 54 - "WorldService.Start"
Cohesion: 0.38
Nodes (5): makeArea(), WorldService.Start(), spawnCharacter(), Spawning.MakeSpawn(), Spawning.Start()

## Knowledge Gaps
- **14 isolated node(s):** `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 168 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, NOT committed yet` connect `Handoff (updated 2026-10-27 ~22:15, session 4)` to `blocks.py`?**
  _High betweenness centrality (0.261) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08456140350877193 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `math`, `Handoff (updated 2026-10-27 ~22:15, session 4)`?**
  _High betweenness centrality (0.257) - this node is a cross-community bridge._
- **Should `WorldService.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.11231884057971014 - nodes in this community are weakly interconnected._
- **Why does `regrow()` connect `Handoff (updated 2026-10-27 ~22:15, session 4)` to `BlockWorld.luau`, `WorldService.luau`, `Build.luau`, `FarmService.luau`, `WorldService.Start`?**
  _High betweenness centrality (0.245) - this node is a cross-community bridge._