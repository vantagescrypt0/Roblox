# Graph Report - Roblox  (2026-10-28)

## Corpus Check
- 127 files · ~138,864 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 920 nodes · 2133 edges · 50 communities (39 shown, 11 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 388 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1842e8db`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Anti-Burnout Ideas
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- Farming.luau
- BlockController.luau
- balance.py
- items3d.py
- Home
- Monetization Principles
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Skills & Levels
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- math
- FarmService.luau
- Loot head: your loot drops in your avatar's head on death
- Context.luau
- FlightController.luau
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
- ShopService.luau
- graph_to_vault.py
- AmbientController.luau
- WorldService.luau
- BlockService.luau
- Build.luau
- build
- Skybounds (Minecraft)
- CombatService.luau
- BlockWorld.position
- InboxService.luau

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
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (50 total, 11 thin omitted)

### Community 0 - "Anti-Burnout Ideas"
Cohesion: 0.20
Nodes (9): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, PvP fairness options: zones by level, new-player protection, insurance slot, Warzone zones: outer ring Slimes, center Brutes (+1 more)

### Community 1 - "Theme.make"
Cohesion: 0.06
Nodes (84): Hotbar.Selected(), Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel() (+76 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.16
Nodes (23): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, regrow(), BlockWorld.drawAll(), BlockWorld.get(), BlockWorld.hasNeighbour(), BlockWorld.key(), BlockWorld.occupied(), BlockWorld.part() (+15 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.18
Nodes (13): capitalized(), TravelService.Go(), describe(), dropBag(), dropLootHead(), endRaid(), enter(), extract() (+5 more)

### Community 4 - "Farming.luau"
Cohesion: 0.11
Nodes (18): ctx.Noise(), crossPathZ(), hillHeight(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), roughDistance() (+10 more)

### Community 5 - "BlockController.luau"
Cohesion: 0.05
Nodes (14): greet(), NpcController.Start(), track(), update(), makeArea(), WorldService.Start(), addNameTag(), Npc.Build() (+6 more)

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.06
Nodes (33): axe(), thickness(), build_items(), carrot(), downscale(), handle(), hoe(), load_blocks() (+25 more)

### Community 8 - "Home"
Cohesion: 0.30
Nodes (13): Pitch (Draft), Target Audience, Islands Feature Checklist, Tutorial & Quests, Warzone, Decision Log, Game name still undecided (can't reuse Islands/Skyblock/Skybounds), Open Questions (+5 more)

### Community 9 - "Monetization Principles"
Cohesion: 0.24
Nodes (7): Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added), Monetization Principles

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.13
Nodes (16): Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Earlier today: the 4x pass — Town and the Grinding Worlds, Handoff (updated 2026-10-28 ~07:25, end of session 4), How-to notes, Later, Leftovers, NOW (2026-10-28 night): skill challenges + beginner challenges board (phase 1 done, NOT committed/published), PUBLISHED (2026-10-28 ~07:17): all 5 places, from commit `0dcdf33` (+8 more)

### Community 12 - "Skills & Levels"
Cohesion: 0.28
Nodes (10): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5), Prototype phase (current) (+2 more)

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.12
Nodes (3): offered(), setOffer(), wearBar()

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.21
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "math"
Cohesion: 0.06
Nodes (61): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_node_tiles(), draw_reference_tiles(), draw_tiles() (+53 more)

### Community 17 - "FarmService.luau"
Cohesion: 0.39
Nodes (7): bestSeed(), blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual(), InventoryService.Count()

### Community 18 - "Loot head: your loot drops in your avatar's head on death"
Cohesion: 0.18
Nodes (10): Skybounds: your head drops on death with your loot, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers, Loot head: your loot drops in your avatar's head on death (+2 more)

### Community 19 - "Context.luau"
Cohesion: 0.17
Nodes (22): Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path(), Common.Pond() (+14 more)

### Community 20 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 21 - "HotbarService.luau"
Cohesion: 0.39
Nodes (7): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "Core Loop"
Cohesion: 0.19
Nodes (10): Design Pillars, Pitch: own a floating island, drop into a shared Warzone, bring loot home, Islands (Roblox game by Easy.gg), Skybounds Warzone (the user's favorite moment), Update cadence: weekly event + monthly content drop, Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop (+2 more)

### Community 24 - "Merchant NPC at the Town market"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

### Community 29 - "Signs.luau"
Cohesion: 0.14
Nodes (18): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+10 more)

### Community 30 - "ShopService.luau"
Cohesion: 0.23
Nodes (12): treeFell(), useTool(), open(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn() (+4 more)

### Community 32 - "Islands (Roblox)"
Cohesion: 0.19
Nodes (12): Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns, Totems: passive resource generators with a range, Item leveling: gear grows the more you use it (+4 more)

### Community 33 - "BlockController.luau"
Cohesion: 0.07
Nodes (29): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: click-only farming, Decision: 5-slot Minecraft-style hotbar, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), aim(), aimedShop() (+21 more)

### Community 34 - "Economy & Values"
Cohesion: 0.25
Nodes (8): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 38 - "ShopService.luau"
Cohesion: 0.18
Nodes (12): checkReach(), complete(), currentQuest(), giveReward(), QuestService.Record(), nearShop(), onBuy(), onSell() (+4 more)

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 42 - "BlockService.luau"
Cohesion: 0.12
Nodes (5): inReach(), checkCell(), onPlant(), onUproot(), Leveling.PlantedTrees()

### Community 43 - "Build.luau"
Cohesion: 0.19
Nodes (10): set(), setFree(), top(), BlockWorld.setRaw(), Build.Fill(), Build.Set(), Build.SetFree(), Build.Top() (+2 more)

### Community 44 - "build"
Cohesion: 0.24
Nodes (8): build(), Ambience.Apply(), ensure(), BlockWorld.new(), BlockWorld.partCount(), Pace.Begin(), Pace.Finish(), ctx.Flatten()

### Community 45 - "Skybounds (Minecraft)"
Cohesion: 0.10
Nodes (16): Mobile-first UI, Full albums (sent 2026-10-28, from imgur), Skybounds reference shots, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down) (+8 more)

### Community 46 - "CombatService.luau"
Cohesion: 0.33
Nodes (6): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing()

### Community 47 - "BlockWorld.position"
Cohesion: 0.36
Nodes (8): nearStation(), buildArrival(), portalFields(), BlockWorld.position(), Portal.addCells(), Portal.makeClosed(), Portal.makeField(), sheet()

### Community 48 - "InboxService.luau"
Cohesion: 0.60
Nodes (4): clean(), deliver(), InboxService.Send(), InboxService.Start()

## Knowledge Gaps
- **14 isolated node(s):** `Prestige with real unlocks`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 203 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `BlockWorld.luau` to `math`, `Handoff (updated 2026-10-27 ~22:35, session 4)`?**
  _High betweenness centrality (0.243) - this node is a cross-community bridge._
- **Are the 23 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prestige with real unlocks`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.0594059405940594 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `math` to `BlockWorld.luau`?**
  _High betweenness centrality (0.239) - this node is a cross-community bridge._
- **Should `Farming.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.10795454545454546 - nodes in this community are weakly interconnected._
- **Why does `regrow()` connect `BlockWorld.luau` to `WorldService.luau`, `Handoff (updated 2026-10-27 ~22:35, session 4)`, `BlockController.luau`, `FarmService.luau`?**
  _High betweenness centrality (0.227) - this node is a cross-community bridge._