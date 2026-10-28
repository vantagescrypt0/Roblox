# Graph Report - Roblox  (2026-10-27)

## Corpus Check
- 120 files · ~121,837 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 864 nodes · 2035 edges · 47 communities (37 shown, 10 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 372 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5628666a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Context.luau
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- BlockController.luau
- ShopService.luau
- items3d.py
- Home
- Warzone
- BlockService.luau
- Merchant NPC at the Town market
- Skills & Levels
- CraftingWindow.luau
- Decor.luau
- Tools and Workflow
- blocks.py
- FarmService.luau
- Main.server.luau
- Builder
- Published privately as Sky Farm Prototype
- HotbarService.luau
- Town & Worlds
- common.py
- NpcController.luau
- Inbox
- Signs.luau
- InventoryService.luau
- Islands (Roblox)
- Economy & Values
- QuestService.luau
- Leveling.luau
- graph_to_vault.py
- AmbientController.luau
- hoe
- replicatedstorage_shared_remotes
- lowpoly.py
- Skybounds (Minecraft)
- Decision: block toughness + tool power (Minecraft rules)
- math
- FlightController.luau

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
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, NOT committed yet` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (47 total, 10 thin omitted)

### Community 0 - "Context.luau"
Cohesion: 0.07
Nodes (40): addNameTag(), Npc.Build(), Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp() (+32 more)

### Community 1 - "Theme.make"
Cohesion: 0.08
Nodes (66): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+58 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.05
Nodes (60): Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Handoff (updated 2026-10-27 ~22:35, session 4), How-to notes, Later, Leftovers, Session 4 (2026-10-27): streaming done and playtested, Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, NOT committed yet (+52 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.14
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 5 - "BlockController.luau"
Cohesion: 0.05
Nodes (25): Decision: click-only farming, Decision: 5-slot Minecraft-style hotbar, aim(), aimedShop(), BlockController.Start(), burst(), interact(), place() (+17 more)

### Community 6 - "ShopService.luau"
Cohesion: 0.25
Nodes (7): nearShop(), onBuy(), onSell(), sellItem(), ShopService.Start(), TownService.GetShopkeepers(), Prompts.Create()

### Community 7 - "items3d.py"
Cohesion: 0.08
Nodes (19): build_items(), carrot(), downscale(), load_blocks(), melon(), over(), read_image(), render_icon() (+11 more)

### Community 8 - "Home"
Cohesion: 0.21
Nodes (16): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+8 more)

### Community 9 - "Warzone"
Cohesion: 0.15
Nodes (18): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+10 more)

### Community 10 - "BlockService.luau"
Cohesion: 0.15
Nodes (4): inReach(), nearStation(), checkCell(), onUproot()

### Community 11 - "Merchant NPC at the Town market"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

### Community 12 - "Skills & Levels"
Cohesion: 0.28
Nodes (10): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5), Prototype phase (current) (+2 more)

### Community 13 - "CraftingWindow.luau"
Cohesion: 0.08
Nodes (22): Hotbar.Selected(), addCamera(), halfExtents(), ItemIcon.create(), viewport(), BagWindow.SetState(), countLabel(), render() (+14 more)

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.21
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "blocks.py"
Cohesion: 0.15
Nodes (23): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_node_tiles(), draw_reference_tiles(), draw_tiles() (+15 more)

### Community 17 - "FarmService.luau"
Cohesion: 0.39
Nodes (7): bestSeed(), blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual(), InventoryService.Count()

### Community 19 - "Builder"
Cohesion: 0.21
Nodes (9): Builder, marker(), matrix(), swatch_uv(), crops(), market(), planter(), portal() (+1 more)

### Community 20 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 21 - "HotbarService.luau"
Cohesion: 0.33
Nodes (8): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld(), onPlant()

### Community 22 - "Town & Worlds"
Cohesion: 0.29
Nodes (7): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "common.py"
Cohesion: 0.23
Nodes (12): export_fbx(), hex_rgb(), material(), mesh_object(), bridge(), dirt_body(), grass_top(), main() (+4 more)

### Community 24 - "NpcController.luau"
Cohesion: 0.28
Nodes (5): greet(), NpcController.Start(), track(), update(), Places.Current()

### Community 29 - "Signs.luau"
Cohesion: 0.13
Nodes (19): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+11 more)

### Community 30 - "InventoryService.luau"
Cohesion: 0.23
Nodes (12): treeFell(), useTool(), open(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn() (+4 more)

### Community 32 - "Islands (Roblox)"
Cohesion: 0.09
Nodes (24): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+16 more)

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "QuestService.luau"
Cohesion: 0.52
Nodes (5): checkReach(), complete(), currentQuest(), giveReward(), QuestService.Record()

### Community 38 - "Leveling.luau"
Cohesion: 0.29
Nodes (4): Better rewards as skills level up, ProgressionService.AddPlayerXP(), Leveling.PlantedTrees(), Leveling.XPToNext()

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 41 - "hoe"
Cohesion: 0.19
Nodes (11): axe(), thickness(), handle(), hoe(), new_verts(), pickaxe(), build_head(), z_at() (+3 more)

### Community 42 - "replicatedstorage_shared_remotes"
Cohesion: 0.17
Nodes (5): Decision: falling off returns you to your island, clean(), deliver(), InboxService.Send(), InboxService.Start()

### Community 44 - "lowpoly.py"
Cohesion: 0.29
Nodes (11): main(), render_preview(), reset_scene(), save_blend(), main(), main(), export_fbx(), _hex() (+3 more)

### Community 45 - "Skybounds (Minecraft)"
Cohesion: 0.14
Nodes (14): 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down), Skybounds Warzone (the user's favorite moment), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot) (+6 more)

### Community 47 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.33
Nodes (4): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules)

### Community 48 - "math"
Cohesion: 0.26
Nodes (9): build_tier(), leaves(), outline(), plot_positions(), radius_at(), ring(), rock(), tree() (+1 more)

### Community 52 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

## Knowledge Gaps
- **14 isolated node(s):** `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 176 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `BlockWorld.luau` to `blocks.py`?**
  _High betweenness centrality (0.259) - this node is a cross-community bridge._
- **Are the 23 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Context.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.07033315705975675 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `math`, `BlockWorld.luau`?**
  _High betweenness centrality (0.256) - this node is a cross-community bridge._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08475734791524266 - nodes in this community are weakly interconnected._
- **Why does `regrow()` connect `BlockWorld.luau` to `FarmService.luau`, `WorldService.luau`?**
  _High betweenness centrality (0.242) - this node is a cross-community bridge._