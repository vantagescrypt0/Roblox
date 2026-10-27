# Graph Report - Roblox  (2026-10-26)

## Corpus Check
- 117 files · ~111,339 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 844 nodes · 2003 edges · 44 communities (32 shown, 12 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 374 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Context.luau
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- WorldService.luau
- Economy.luau
- Islands (Roblox)
- items3d.py
- Home
- Warzone
- Handoff (updated 2026-10-26, session 3)
- Level gates: crops need Farming level, mobs need Combat level
- Economy.luau
- Decor.luau
- Tools and Workflow
- math
- FarmService.luau
- Warzone
- Open Questions
- HotbarService.luau
- Town & Worlds
- TravelService.luau
- Main.client.luau
- Inbox
- Signs.luau
- ShopService.luau
- Pitch: own a floating island, drop into a shared Warzone, bring loot home
- Published privately as Sky Farm Prototype
- Economy & Values
- QuestService.luau
- Leveling.luau
- graph_to_vault.py
- AmbientController.luau
- InventoryService.luau
- CraftingWindow.luau
- Decision Log

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 38 edges
2. `Builder` - 24 edges
3. `part()` - 23 edges
4. `Home` - 23 edges
5. `Skills & Levels` - 21 edges
6. `Theme.corner()` - 20 edges
7. `build_tier()` - 19 edges
8. `Theme.stroke()` - 19 edges
9. `BlockWorld.key()` - 19 edges
10. `Warzone` - 18 edges

## Surprising Connections (you probably didn't know these)
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `Idle-grow / cozy trend (Grow a Garden spike and decay)` --semantically_similar_to--> `Offline progress and timers`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Anti-Burnout Ideas.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (44 total, 12 thin omitted)

### Community 0 - "Context.luau"
Cohesion: 0.08
Nodes (38): buildArrival(), Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path() (+30 more)

### Community 1 - "Theme.make"
Cohesion: 0.09
Nodes (64): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+56 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.07
Nodes (45): inReach(), nearStation(), set(), setFree(), top(), build(), portalFields(), regrow() (+37 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.14
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 5 - "Economy.luau"
Cohesion: 0.15
Nodes (4): Economy.Total(), Economy.Value(), work(), Mining.BreakTime()

### Community 6 - "Islands (Roblox)"
Cohesion: 0.18
Nodes (13): Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns, Totems: passive resource generators with a range, Skill-gated vending machines and handshake trading (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.06
Nodes (30): axe(), thickness(), carrot(), downscale(), handle(), hoe(), load_blocks(), melon() (+22 more)

### Community 8 - "Home"
Cohesion: 0.23
Nodes (14): Anti-Burnout Ideas, Prestige with real unlocks, Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Skills & Levels (+6 more)

### Community 9 - "Warzone"
Cohesion: 0.20
Nodes (11): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+3 more)

### Community 11 - "Handoff (updated 2026-10-26, session 3)"
Cohesion: 0.33
Nodes (5): Handoff (updated 2026-10-26, session 3), How-to notes for the next session, In progress right now: "Grand worlds" (Skybounds-scale worlds with zone islands), Published, Still open from your notes

### Community 12 - "Level gates: crops need Farming level, mobs need Combat level"
Cohesion: 0.29
Nodes (5): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5)

### Community 13 - "Economy.luau"
Cohesion: 0.07
Nodes (21): Decision: click-only farming, Decision: 5-slot Minecraft-style hotbar, aim(), aimedShop(), BlockController.Start(), burst(), interact(), place() (+13 more)

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (27): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+19 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.17
Nodes (13): Blender driven by Python scripts, ProfileStore (player data with session locking), Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import (+5 more)

### Community 16 - "math"
Cohesion: 0.06
Nodes (63): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_reference_tiles(), draw_tiles(), ore() (+55 more)

### Community 17 - "FarmService.luau"
Cohesion: 0.25
Nodes (17): bestSeed(), blockCrop(), FarmService.Harvest(), FarmService.ShowCrop(), FarmService.Start(), heldSeed(), heldTool(), makePlot() (+9 more)

### Community 19 - "Warzone"
Cohesion: 0.21
Nodes (12): 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Seasonal Warzone maps and loot tables, Loot head: your loot drops in your avatar's head on death, PvP fairness options: zones by level, new-player protection, insurance slot (+4 more)

### Community 20 - "Open Questions"
Cohesion: 0.15
Nodes (13): Design Pillars, Pitch (Draft), Skybounds seasons: 2-4 months, level resets, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets (+5 more)

### Community 21 - "HotbarService.luau"
Cohesion: 0.46
Nodes (6): HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 22 - "Town & Worlds"
Cohesion: 0.29
Nodes (7): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 24 - "Main.client.luau"
Cohesion: 0.12
Nodes (12): greet(), NpcController.Start(), track(), update(), makeArea(), WorldService.Start(), addNameTag(), Npc.Build() (+4 more)

### Community 29 - "Signs.luau"
Cohesion: 0.18
Nodes (15): baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight(), inkFor(), longest(), plank() (+7 more)

### Community 30 - "ShopService.luau"
Cohesion: 0.21
Nodes (7): InventoryService.SpendCoins(), nearShop(), onBuy(), onSell(), ShopService.Start(), TownService.GetShopkeepers(), Prompts.Create()

### Community 32 - "Pitch: own a floating island, drop into a shared Warzone, bring loot home"
Cohesion: 0.25
Nodes (7): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Islands (Roblox game by Easy.gg), Skybounds Warzone (the user's favorite moment), Update cadence: weekly event + monthly content drop, Player level 1-50 (XP from PvE, grinding, quests), Level 10 unlocks the Warzone, Decision: blend Islands + Skybounds Warzone

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
Cohesion: 0.20
Nodes (9): Better rewards as skills level up, ProgressionService.AddPlayerXP(), checkCell(), onPlant(), onUproot(), Leveling.BonusChance(), Leveling.PlantedTrees(), Leveling.TilledPlots() (+1 more)

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 43 - "InventoryService.luau"
Cohesion: 0.27
Nodes (11): treeFell(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn(), InventoryService.Count(), InventoryService.Remove() (+3 more)

### Community 46 - "CraftingWindow.luau"
Cohesion: 0.08
Nodes (29): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff(), Hotbar.Selected() (+21 more)

### Community 47 - "Decision Log"
Cohesion: 0.11
Nodes (17): NPC visits at milestones with a starter pack, Economy sinks to slow inflation, Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Warzone parked until it moves into Town, Merchant NPC at the Town market, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: falling off returns you to your island, Decision: buy bigger islands with coins (4 tiers) (+9 more)

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Skybounds (Minecraft Skyblock server, now shut down)`, `Roleplay + simulator hybrids growing [Unverified]`, `Inbox` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 167 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Home` to `Islands (Roblox)`, `Warzone`, `Tools and Workflow`, `Decision Log`, `Warzone`, `Open Questions`?**
  _High betweenness centrality (0.311) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Skybounds (Minecraft Skyblock server, now shut down)` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Context.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.07857142857142857 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `math`?**
  _High betweenness centrality (0.310) - this node is a cross-community bridge._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08576576576576576 - nodes in this community are weakly interconnected._
- **Should `BlockWorld.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.07329462989840348 - nodes in this community are weakly interconnected._