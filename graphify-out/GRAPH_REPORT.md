# Graph Report - Roblox  (2026-10-31)

## Corpus Check
- 144 files · ~161,075 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 1029 nodes · 2320 edges · 57 communities (40 shown, 17 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 422 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `77f6d196`
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
- Monetization Principles
- BlockService.luau
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Skills & Levels
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- math
- Context.luau
- build
- TrophyModels.luau
- FlightController.luau
- Build.luau
- Town & Worlds
- Open Questions
- Merchant NPC at the Town market
- Inbox
- Signs.luau
- QuestService.luau
- Skybounds (Minecraft)
- BlockController.luau
- Economy & Values
- Published privately as Sky Farm Prototype
- graph_to_vault.py
- AmbientController.luau
- BlockWorld.position
- FarmService.luau
- TravelService.luau
- UI study (2026-10-29)
- Hotbar.luau
- InboxService.luau
- WorldService.luau
- Late-game proposal (2026-10-29)
- LiquidModels.luau
- Trends - Oct 2026
- Crafting Proposal (2026-10-31, waiting for your OK)
- Boards.luau

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 44 edges
2. `Builder` - 25 edges
3. `Theme.corner()` - 24 edges
4. `part()` - 24 edges
5. `Theme.stroke()` - 23 edges
6. `Home` - 23 edges
7. `Theme.text()` - 22 edges
8. `Handoff` - 22 edges
9. `Skills & Levels` - 22 edges
10. `Warzone` - 20 edges

## Surprising Connections (you probably didn't know these)
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, committed as `b66c289` (harvest wear removed later in part 4)` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (57 total, 17 thin omitted)

### Community 0 - "Islands (Roblox)"
Cohesion: 0.09
Nodes (24): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+16 more)

### Community 1 - "Theme.make"
Cohesion: 0.06
Nodes (92): Hotbar.Start(), buildCelebration(), buildMenu(), buildRaidBanner(), buildStatus(), buildToasts(), drawMenuBars(), fadeLabel() (+84 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.17
Nodes (15): BlockWorld.drawAll(), BlockWorld.set(), buried(), exposed(), fits(), makePart(), mergeScenery(), occludes() (+7 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.15
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 4 - "Context.luau"
Cohesion: 0.10
Nodes (18): ctx.Noise(), crossPathZ(), hillHeight(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), roughDistance() (+10 more)

### Community 5 - "Economy.luau"
Cohesion: 0.40
Nodes (3): Economy.Total(), Economy.Value(), work()

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.05
Nodes (36): arc(), axe(), thickness(), bucket(), carrot(), downscale(), front_slab(), handle() (+28 more)

### Community 9 - "Monetization Principles"
Cohesion: 0.14
Nodes (18): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+10 more)

### Community 10 - "BlockService.luau"
Cohesion: 0.12
Nodes (3): inReach(), nearStation(), unlockedBy()

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.07
Nodes (31): Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Earlier today (session 6): UI restyle DONE in Studio, NOT committed, NOT published, Earlier today: the 4x pass — Town and the Grinding Worlds, Handoff, How-to notes, Later, Leftovers, NOW (2026-10-28 night): skill challenges + beginner challenges board (phase 1 done, NOT committed/published) (+23 more)

### Community 12 - "Skills & Levels"
Cohesion: 0.28
Nodes (10): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5), Prototype phase (current) (+2 more)

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.14
Nodes (5): countLabel(), doneCount(), stateOf(), offered(), setOffer()

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.21
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "math"
Cohesion: 0.05
Nodes (65): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_node_tiles(), draw_reference_tiles(), draw_tiles() (+57 more)

### Community 17 - "Context.luau"
Cohesion: 0.18
Nodes (22): Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path(), Common.Pond() (+14 more)

### Community 18 - "build"
Cohesion: 0.19
Nodes (9): build(), Ambience.Apply(), ensure(), BlockWorld.partCount(), Pace.Begin(), Pace.Finish(), Swim.Fill(), Swim.FillSheets() (+1 more)

### Community 19 - "TrophyModels.luau"
Cohesion: 0.73
Nodes (5): build(), emblem(), piece(), TrophyModels.Make(), weld()

### Community 20 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 21 - "Build.luau"
Cohesion: 0.21
Nodes (9): set(), setFree(), BlockWorld.get(), BlockWorld.setRaw(), Build.Fill(), Build.Set(), Build.SetFree(), pick() (+1 more)

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "Open Questions"
Cohesion: 0.21
Nodes (16): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+8 more)

### Community 24 - "Merchant NPC at the Town market"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

### Community 29 - "Signs.luau"
Cohesion: 0.14
Nodes (18): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+10 more)

### Community 30 - "QuestService.luau"
Cohesion: 0.07
Nodes (33): Better rewards as skills level up, treeFell(), bestSeed(), open(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins() (+25 more)

### Community 32 - "Skybounds (Minecraft)"
Cohesion: 0.15
Nodes (12): Full albums (sent 2026-10-28, from imgur), Skybounds reference shots, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down), Skybounds Warzone (the user's favorite moment) (+4 more)

### Community 33 - "BlockController.luau"
Cohesion: 0.05
Nodes (11): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: click-only farming, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), aim(), aimedShop(), rootPosition() (+3 more)

### Community 34 - "Economy & Values"
Cohesion: 0.25
Nodes (8): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 41 - "BlockWorld.position"
Cohesion: 0.31
Nodes (9): top(), buildArrival(), portalFields(), BlockWorld.position(), Build.Top(), Portal.addCells(), Portal.makeClosed(), Portal.makeField() (+1 more)

### Community 42 - "FarmService.luau"
Cohesion: 0.60
Nodes (5): blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual()

### Community 46 - "UI study (2026-10-29)"
Cohesion: 0.40
Nodes (4): Proposed Skycore style (combining them), Shared lessons, UI study (2026-10-29), What each does well

### Community 47 - "Hotbar.luau"
Cohesion: 0.06
Nodes (27): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.SelectedItem(), Hotbar.SetState(), render(), showName(), slotX(), fadeTo() (+19 more)

### Community 48 - "InboxService.luau"
Cohesion: 0.60
Nodes (4): clean(), deliver(), InboxService.Send(), InboxService.Start()

### Community 50 - "WorldService.luau"
Cohesion: 0.09
Nodes (3): Decision: falling off returns you to your island, liquidAt(), touches()

### Community 52 - "Late-game proposal (2026-10-29)"
Cohesion: 0.22
Nodes (9): 1. New resources (13), 2. New tool tiers (2, x 5 kinds = 10 tools), 3. Big things to buy (10M–50M), 4. The order to build it in, Farming: four new zone islands (4), Late-game proposal (2026-10-29), Mining: a deeper cave under the Gold Chamber (5), Questions (+1 more)

### Community 55 - "Trends - Oct 2026"
Cohesion: 0.50
Nodes (4): Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets

### Community 58 - "Crafting Proposal (2026-10-31, waiting for your OK)"
Cohesion: 0.29
Nodes (6): Crafting Proposal (2026-10-31, waiting for your OK), New stations, Questions, The ladder, The rule, What it adds

## Knowledge Gaps
- **14 isolated node(s):** `Conveyor factories (splitters, filters, sensors)`, `Hidden fossil collection quests`, `Token-summoned bosses with cooldowns`, `Prestige with real unlocks`, `Prototype phase (current)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 260 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `Handoff (updated 2026-10-27 ~22:35, session 4)` to `math`?**
  _High betweenness centrality (0.261) - this node is a cross-community bridge._
- **Are the 27 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildCelebration()`) actually correct?**
  _`Theme.make()` has 27 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Conveyor factories (splitters, filters, sensors)`, `Hidden fossil collection quests`, `Token-summoned bosses with cooldowns` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Islands (Roblox)` be split into smaller, more focused modules?**
  _Cohesion score 0.08735632183908046 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `math` to `Handoff (updated 2026-10-27 ~22:35, session 4)`?**
  _High betweenness centrality (0.258) - this node is a cross-community bridge._
- **Are the 12 inferred relationships involving `Theme.corner()` (e.g. with `Hotbar.Start()` and `buildRaidBanner()`) actually correct?**
  _`Theme.corner()` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.056890012642225034 - nodes in this community are weakly interconnected._