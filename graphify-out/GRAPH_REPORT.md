# Graph Report - Roblox  (2026-10-28)

## Corpus Check
- 132 files · ~142,864 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 945 nodes · 2181 edges · 48 communities (33 shown, 15 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 397 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d3c74827`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Islands (Roblox)
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- Farming.luau
- Npc.luau
- balance.py
- items3d.py
- Decision: block toughness + tool power (Minecraft rules)
- Monetization Principles
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Skills & Levels
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- math
- ShopService.luau
- WorldService.Start
- TrophyModels.luau
- ItemIcon.create
- HotbarService.luau
- Town & Worlds
- Open Questions
- Decision Log
- Inbox
- Signs.luau
- InventoryService.luau
- Warzone
- BlockController.luau
- Economy & Values
- Published privately as Sky Farm Prototype
- ShopService.Start
- graph_to_vault.py
- AmbientController.luau
- FarmService.luau
- Trends - Oct 2026
- InboxService.luau

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 40 edges
2. `Builder` - 24 edges
3. `part()` - 24 edges
4. `Home` - 23 edges
5. `Theme.corner()` - 22 edges
6. `Skills & Levels` - 22 edges
7. `Theme.stroke()` - 21 edges
8. `build_tier()` - 19 edges
9. `Theme.text()` - 18 edges
10. `Warzone` - 18 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming)` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (48 total, 15 thin omitted)

### Community 0 - "Islands (Roblox)"
Cohesion: 0.10
Nodes (18): Design Pillars, Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Token-summoned bosses with cooldowns, Totems: passive resource generators with a range, Skill-gated vending machines and handshake trading (+10 more)

### Community 1 - "Theme.make"
Cohesion: 0.08
Nodes (69): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+61 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.07
Nodes (47): inReach(), nearStation(), set(), setFree(), top(), build(), regrow(), Ambience.Apply() (+39 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.14
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 4 - "Farming.luau"
Cohesion: 0.07
Nodes (41): buildArrival(), Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path() (+33 more)

### Community 5 - "Npc.luau"
Cohesion: 0.20
Nodes (5): addNameTag(), Npc.Build(), slung(), PetModels.Build(), add()

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.07
Nodes (29): axe(), thickness(), build_items(), downscale(), handle(), hoe(), load_blocks(), main() (+21 more)

### Community 8 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.11
Nodes (8): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), Economy.Total(), Economy.Value(), work(), Mining.BreakTime()

### Community 9 - "Monetization Principles"
Cohesion: 0.19
Nodes (13): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+5 more)

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.12
Nodes (17): Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Earlier today: the 4x pass — Town and the Grinding Worlds, Handoff (updated 2026-10-28 ~07:25, end of session 4), How-to notes, Later, Leftovers, NOW (2026-10-28 night): skill challenges + beginner challenges board (phase 1 done, NOT committed/published), PUBLISHED (2026-10-28 ~07:17): all 5 places, from commit `0dcdf33` (+9 more)

### Community 12 - "Skills & Levels"
Cohesion: 0.20
Nodes (12): Full albums (sent 2026-10-28, from imgur), Skybounds reference shots, Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds) (+4 more)

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.17
Nodes (13): Blender driven by Python scripts, ProfileStore (player data with session locking), Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import (+5 more)

### Community 16 - "math"
Cohesion: 0.05
Nodes (65): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_node_tiles(), draw_reference_tiles(), draw_tiles() (+57 more)

### Community 18 - "WorldService.Start"
Cohesion: 0.38
Nodes (5): makeArea(), WorldService.Start(), spawnCharacter(), Spawning.MakeSpawn(), Spawning.Start()

### Community 19 - "TrophyModels.luau"
Cohesion: 0.73
Nodes (5): build(), emblem(), piece(), TrophyModels.Make(), weld()

### Community 20 - "ItemIcon.create"
Cohesion: 0.12
Nodes (22): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff(), addCamera() (+14 more)

### Community 21 - "HotbarService.luau"
Cohesion: 0.18
Nodes (12): greet(), NpcController.Start(), track(), update(), heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isSlot() (+4 more)

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "Open Questions"
Cohesion: 0.27
Nodes (10): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+2 more)

### Community 24 - "Decision Log"
Cohesion: 0.18
Nodes (13): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: click-only farming, Decision: falling off returns you to your island, Decision: 5-slot Minecraft-style hotbar, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market (+5 more)

### Community 29 - "Signs.luau"
Cohesion: 0.13
Nodes (19): portalFields(), cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents() (+11 more)

### Community 30 - "InventoryService.luau"
Cohesion: 0.08
Nodes (30): Better rewards as skills level up, treeFell(), bestSeed(), useTool(), open(), autoHotbar(), clearIfEmpty(), InventoryService.Add() (+22 more)

### Community 32 - "Warzone"
Cohesion: 0.16
Nodes (16): Trading shut down after a duplication exploit [Unverified], Key-gated adventure islands, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Item leveling: gear grows the more you use it (+8 more)

### Community 33 - "BlockController.luau"
Cohesion: 0.07
Nodes (19): aim(), aimedShop(), BlockController.Start(), burst(), interact(), place(), rootPosition(), screenRay() (+11 more)

### Community 34 - "Economy & Values"
Cohesion: 0.25
Nodes (8): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 38 - "ShopService.Start"
Cohesion: 0.40
Nodes (3): ShopService.Start(), TownService.GetShopkeepers(), Prompts.Create()

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 42 - "FarmService.luau"
Cohesion: 0.16
Nodes (5): blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual()

### Community 45 - "Trends - Oct 2026"
Cohesion: 0.18
Nodes (10): Skybounds seasons: 2-4 months, level resets, Skybounds Warzone (the user's favorite moment), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Player level 1-50 (XP from PvE, grinding, quests), Seasons of 2-4 months; player level resets (+2 more)

### Community 48 - "InboxService.luau"
Cohesion: 0.60
Nodes (4): clean(), deliver(), InboxService.Send(), InboxService.Start()

## Knowledge Gaps
- **14 isolated node(s):** `Prestige with real unlocks`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 216 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `Handoff (updated 2026-10-27 ~22:35, session 4)` to `math`, `BlockWorld.luau`?**
  _High betweenness centrality (0.239) - this node is a cross-community bridge._
- **Are the 24 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 24 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prestige with real unlocks`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Islands (Roblox)` be split into smaller, more focused modules?**
  _Cohesion score 0.10276679841897234 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `math` to `Handoff (updated 2026-10-27 ~22:35, session 4)`?**
  _High betweenness centrality (0.235) - this node is a cross-community bridge._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08024691358024691 - nodes in this community are weakly interconnected._
- **Why does `regrow()` connect `BlockWorld.luau` to `WorldService.Start`, `WorldService.luau`, `FarmService.luau`, `Handoff (updated 2026-10-27 ~22:35, session 4)`?**
  _High betweenness centrality (0.224) - this node is a cross-community bridge._