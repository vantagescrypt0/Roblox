# Graph Report - Roblox  (2026-10-28)

## Corpus Check
- 123 files · ~135,384 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 906 nodes · 2113 edges · 45 communities (37 shown, 8 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 385 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `0dcdf339`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Anti-Burnout Ideas
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- WorldService.luau
- BlockController.luau
- balance.py
- items3d.py
- Home
- Monetization Principles
- BlockService.luau
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Skills & Levels
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- math
- FarmService.luau
- Loot head: your loot drops in your avatar's head on death
- TreeService.luau
- CraftingWindow.luau
- HotbarService.luau
- Town & Worlds
- Core Loop
- Merchant NPC at the Town market
- Inbox
- Signs.luau
- ShopService.luau
- Islands (Roblox)
- BlockController.luau
- Economy & Values
- Published privately as Sky Farm Prototype
- Leveling.luau
- graph_to_vault.py
- AmbientController.luau
- Main.server.luau
- Skybounds (Minecraft)
- Decision: block toughness + tool power (Minecraft rules)
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
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming)` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, committed as `b66c289` (harvest wear removed later in part 4)` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (45 total, 8 thin omitted)

### Community 0 - "Anti-Burnout Ideas"
Cohesion: 0.20
Nodes (9): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, PvP fairness options: zones by level, new-player protection, insurance slot, Warzone zones: outer ring Slimes, center Brutes (+1 more)

### Community 1 - "Theme.make"
Cohesion: 0.09
Nodes (65): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+57 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.07
Nodes (49): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, nearStation(), set(), setFree(), top(), build(), buildArrival(), portalFields() (+41 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.15
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 4 - "WorldService.luau"
Cohesion: 0.05
Nodes (41): Decision: falling off returns you to your island, Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path() (+33 more)

### Community 5 - "BlockController.luau"
Cohesion: 0.06
Nodes (12): greet(), NpcController.Start(), track(), update(), makeArea(), WorldService.Start(), addNameTag(), Npc.Build() (+4 more)

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.06
Nodes (30): axe(), thickness(), carrot(), downscale(), handle(), hoe(), load_blocks(), melon() (+22 more)

### Community 8 - "Home"
Cohesion: 0.30
Nodes (13): Pitch (Draft), Target Audience, Islands Feature Checklist, Tutorial & Quests, Warzone, Decision Log, Game name still undecided (can't reuse Islands/Skyblock/Skybounds), Open Questions (+5 more)

### Community 9 - "Monetization Principles"
Cohesion: 0.24
Nodes (7): Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added), Monetization Principles

### Community 10 - "BlockService.luau"
Cohesion: 0.11
Nodes (4): inReach(), treeFell(), capitalized(), TravelService.Go()

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.14
Nodes (15): Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Handoff (updated 2026-10-28 ~07:25, end of session 4), How-to notes, Later, Leftovers, NOW (2026-10-28 evening): the 4x pass — Town and the Grinding Worlds, PUBLISHED (2026-10-28 ~07:17): all 5 places, from commit `0dcdf33`, Session 4 (2026-10-27): streaming done and playtested (+7 more)

### Community 12 - "Skills & Levels"
Cohesion: 0.23
Nodes (12): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Player level 1-50 (XP from PvE, grinding, quests), Skills & Levels, Level 10 unlocks the Warzone, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds) (+4 more)

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.16
Nodes (7): BagWindow.SetState(), countLabel(), render(), IslandWindow.SetState(), offered(), setOffer(), wearBar()

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "math"
Cohesion: 0.06
Nodes (64): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_node_tiles(), draw_reference_tiles(), draw_tiles() (+56 more)

### Community 17 - "FarmService.luau"
Cohesion: 0.33
Nodes (8): Decision: click-only farming, bestSeed(), blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual(), InventoryService.Count()

### Community 18 - "Loot head: your loot drops in your avatar's head on death"
Cohesion: 0.17
Nodes (11): Skybounds: your head drops on death with your loot, Skybounds seasons: 2-4 months, level resets, Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Seasons of 2-4 months; player level resets, Loot head: your loot drops in your avatar's head on death (+3 more)

### Community 19 - "TreeService.luau"
Cohesion: 0.28
Nodes (3): checkCell(), onPlant(), onUproot()

### Community 20 - "CraftingWindow.luau"
Cohesion: 0.13
Nodes (22): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff(), addCamera() (+14 more)

### Community 21 - "HotbarService.luau"
Cohesion: 0.39
Nodes (7): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "Core Loop"
Cohesion: 0.38
Nodes (7): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Skybounds Warzone (the user's favorite moment), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Decision: blend Islands + Skybounds Warzone

### Community 24 - "Merchant NPC at the Town market"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

### Community 29 - "Signs.luau"
Cohesion: 0.14
Nodes (18): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+10 more)

### Community 30 - "ShopService.luau"
Cohesion: 0.14
Nodes (18): useTool(), open(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn(), InventoryService.Remove() (+10 more)

### Community 32 - "Islands (Roblox)"
Cohesion: 0.12
Nodes (17): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+9 more)

### Community 33 - "BlockController.luau"
Cohesion: 0.11
Nodes (17): aim(), aimedShop(), BlockController.Start(), burst(), interact(), place(), rootPosition(), screenRay() (+9 more)

### Community 34 - "Economy & Values"
Cohesion: 0.25
Nodes (8): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 38 - "Leveling.luau"
Cohesion: 0.18
Nodes (9): Better rewards as skills level up, ProgressionService.AddPlayerXP(), checkReach(), complete(), currentQuest(), giveReward(), QuestService.Record(), Leveling.PlantedTrees() (+1 more)

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 42 - "Main.server.luau"
Cohesion: 0.12
Nodes (4): clean(), deliver(), InboxService.Send(), InboxService.Start()

### Community 45 - "Skybounds (Minecraft)"
Cohesion: 0.22
Nodes (8): Mobile-first UI, Full albums (sent 2026-10-28, from imgur), Skybounds reference shots, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Beginner quest chain (13 quests, ends at level 10)

### Community 47 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.33
Nodes (4): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules)

### Community 52 - "Hotbar.luau"
Cohesion: 0.25
Nodes (8): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.Selected(), Hotbar.SelectedItem(), Hotbar.SetState(), render(), showName(), slotX()

## Knowledge Gaps
- **14 isolated node(s):** `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 195 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `BlockWorld.luau` to `math`, `Handoff (updated 2026-10-27 ~22:35, session 4)`?**
  _High betweenness centrality (0.245) - this node is a cross-community bridge._
- **Are the 23 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08648648648648649 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `math` to `BlockWorld.luau`?**
  _High betweenness centrality (0.241) - this node is a cross-community bridge._
- **Should `BlockWorld.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.06721215663354763 - nodes in this community are weakly interconnected._
- **Why does `regrow()` connect `BlockWorld.luau` to `FarmService.luau`, `Handoff (updated 2026-10-27 ~22:35, session 4)`, `WorldService.luau`, `BlockController.luau`?**
  _High betweenness centrality (0.228) - this node is a cross-community bridge._