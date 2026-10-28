# Graph Report - Roblox  (2026-10-27)

## Corpus Check
- 118 files · ~117,360 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 855 nodes · 2030 edges · 48 communities (36 shown, 12 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 377 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8449dbe1`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Context.luau
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- WorldService.luau
- Economy.luau
- TownService.luau
- items3d.py
- Home
- Warzone
- BlockService.luau
- Handoff (updated 2026-10-26 ~21:05, session 3)
- Skills & Levels
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- math
- FarmService.luau
- Main.server.luau
- BlockController.luau
- BlockWorld.position
- HotbarService.luau
- Town & Worlds
- Hotbar.luau
- Inbox
- Signs.luau
- ShopService.luau
- Islands (Roblox)
- replicatedstorage_shared_remotes
- Economy & Values
- QuestService.luau
- TreeService.luau
- graph_to_vault.py
- AmbientController.luau
- replicatedstorage_shared_places
- TravelService.luau
- Npc.luau
- Skybounds (Minecraft)
- CraftingWindow.luau
- Decision: block toughness + tool power (Minecraft rules)
- Merchant NPC at the Town market

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
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming)` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (48 total, 12 thin omitted)

### Community 0 - "Context.luau"
Cohesion: 0.08
Nodes (37): Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path(), Common.Pond() (+29 more)

### Community 1 - "Theme.make"
Cohesion: 0.09
Nodes (65): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+57 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.18
Nodes (21): nearStation(), BlockWorld.drawAll(), BlockWorld.hasNeighbour(), BlockWorld.key(), BlockWorld.part(), BlockWorld.set(), BlockWorld.setRaw(), BlockWorld.unkey() (+13 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.15
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 4 - "WorldService.luau"
Cohesion: 0.11
Nodes (11): TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming), makeArea(), notice(), onFarmClick(), regrow(), WorldService.Start(), BlockWorld.occupied(), spawnCharacter() (+3 more)

### Community 5 - "Economy.luau"
Cohesion: 0.15
Nodes (4): Economy.Total(), Economy.Value(), work(), Mining.BreakTime()

### Community 6 - "TownService.luau"
Cohesion: 0.12
Nodes (9): set(), setFree(), top(), BlockWorld.get(), Build.Fill(), Build.Set(), Build.SetFree(), Build.Top() (+1 more)

### Community 7 - "items3d.py"
Cohesion: 0.06
Nodes (30): axe(), thickness(), carrot(), downscale(), handle(), hoe(), load_blocks(), melon() (+22 more)

### Community 8 - "Home"
Cohesion: 0.21
Nodes (16): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+8 more)

### Community 9 - "Warzone"
Cohesion: 0.15
Nodes (18): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+10 more)

### Community 10 - "BlockService.luau"
Cohesion: 0.14
Nodes (3): Mobs: Slime (Combat 1), Brute (Combat 5), inReach(), treeFell()

### Community 11 - "Handoff (updated 2026-10-26 ~21:05, session 3)"
Cohesion: 0.29
Nodes (7): Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Handoff (updated 2026-10-27 ~21:40, session 4), How-to notes, Later, Leftovers, Session 4 (2026-10-27): streaming done, Studio playtest still to do, State

### Community 12 - "Skills & Levels"
Cohesion: 0.30
Nodes (9): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Prototype phase (current), Roadmap (+1 more)

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.19
Nodes (6): BagWindow.SetState(), countLabel(), render(), offered(), setOffer(), wearBar()

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.21
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "math"
Cohesion: 0.06
Nodes (63): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_reference_tiles(), draw_tiles(), ore() (+55 more)

### Community 17 - "FarmService.luau"
Cohesion: 0.17
Nodes (22): Better rewards as skills level up, bestSeed(), blockCrop(), FarmService.Harvest(), FarmService.ShowCrop(), FarmService.Start(), heldSeed(), heldTool() (+14 more)

### Community 18 - "Main.server.luau"
Cohesion: 0.12
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 19 - "BlockController.luau"
Cohesion: 0.27
Nodes (14): Decision: click-only farming, aim(), aimedShop(), BlockController.Start(), burst(), interact(), place(), rootPosition() (+6 more)

### Community 20 - "BlockWorld.position"
Cohesion: 0.20
Nodes (13): build(), buildArrival(), portalFields(), Ambience.Apply(), ensure(), BlockWorld.new(), BlockWorld.partCount(), BlockWorld.position() (+5 more)

### Community 21 - "HotbarService.luau"
Cohesion: 0.46
Nodes (6): HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 22 - "Town & Worlds"
Cohesion: 0.29
Nodes (7): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "Hotbar.luau"
Cohesion: 0.25
Nodes (8): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.Selected(), Hotbar.SelectedItem(), Hotbar.SetState(), render(), showName(), slotX()

### Community 29 - "Signs.luau"
Cohesion: 0.13
Nodes (19): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+11 more)

### Community 30 - "ShopService.luau"
Cohesion: 0.14
Nodes (18): autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn(), InventoryService.Count(), InventoryService.Remove(), InventoryService.RemoveMany() (+10 more)

### Community 32 - "Islands (Roblox)"
Cohesion: 0.09
Nodes (24): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+16 more)

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "QuestService.luau"
Cohesion: 0.60
Nodes (4): checkReach(), complete(), currentQuest(), QuestService.Record()

### Community 38 - "TreeService.luau"
Cohesion: 0.47
Nodes (4): checkCell(), onPlant(), onUproot(), Leveling.PlantedTrees()

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 41 - "replicatedstorage_shared_places"
Cohesion: 0.47
Nodes (4): greet(), NpcController.Start(), track(), update()

### Community 45 - "Skybounds (Minecraft)"
Cohesion: 0.14
Nodes (14): 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down), Skybounds Warzone (the user's favorite moment), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot) (+6 more)

### Community 46 - "CraftingWindow.luau"
Cohesion: 0.13
Nodes (22): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff(), addCamera() (+14 more)

### Community 47 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.33
Nodes (4): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules)

### Community 48 - "Merchant NPC at the Town market"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Skybounds (Minecraft Skyblock server, now shut down)`, `Roleplay + simulator hybrids growing [Unverified]`, `Inbox` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 166 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `math`?**
  _High betweenness centrality (0.310) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Skybounds (Minecraft Skyblock server, now shut down)` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Context.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.08246753246753247 - nodes in this community are weakly interconnected._
- **Why does `Workflow` connect `Tools and Workflow` to `Home`?**
  _High betweenness centrality (0.304) - this node is a cross-community bridge._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08626434653831914 - nodes in this community are weakly interconnected._
- **Should `WorldService.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.11067193675889328 - nodes in this community are weakly interconnected._