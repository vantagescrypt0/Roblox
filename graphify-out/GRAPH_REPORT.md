# Graph Report - Roblox  (2026-10-24)

## Corpus Check
- 89 files · ~50,706 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 609 nodes · 1510 edges · 36 communities (29 shown, 7 thin omitted)
- Extraction: 76% EXTRACTED · 24% INFERRED · 0% AMBIGUOUS · INFERRED: 367 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Block Art Pipeline (Blender)
- HUD and Hotbar
- Breaking, Placing and Crafting
- CraftingWindow.luau
- DataService.luau
- Knowledge Graph Tools
- Islands (Roblox)
- items3d.py
- Core Loop and Pillars
- Audience, Policy and Death Drops
- DataService.GetData
- FarmService.luau
- Skybounds (Minecraft)
- Economy.luau
- CombatService.luau
- Tools and Workflow
- WarzoneService.luau
- Decision Log
- MarketService.luau
- Loot head: your loot drops in your avatar's head on death
- Anti-Burnout Ideas
- TownService.luau
- Merchant Behaviour
- BlockService.luau
- BlockController.luau
- Inbox
- Pitch: own a floating island, drop into a shared Warzone, bring loot home
- HotbarService.luau
- Props.luau
- Economy & Values
- Published privately as Sky Farm Prototype

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 40 edges
2. `Builder` - 24 edges
3. `DataService.GetData()` - 23 edges
4. `Home` - 23 edges
5. `build_tier()` - 19 edges
6. `Theme.stroke()` - 19 edges
7. `Theme.corner()` - 18 edges
8. `Skills & Levels` - 18 edges
9. `onBreak()` - 17 edges
10. `DataService.MarkChanged()` - 17 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md
- `Skill-gated vending machines and handshake trading` --semantically_similar_to--> `Trading with anti-scam UI (two-step confirm, trade log)`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 03 Design/Anti-Burnout Ideas.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (36 total, 7 thin omitted)

### Community 0 - "Block Art Pipeline (Blender)"
Cohesion: 0.07
Nodes (51): build_atlas(), clamp(), draw_tiles(), ore(), fill(), main(), make_block(), noisy() (+43 more)

### Community 1 - "HUD and Hotbar"
Cohesion: 0.16
Nodes (44): buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), Hud.Celebrate(), Hud.Render(), Hud.Start() (+36 more)

### Community 2 - "Breaking, Placing and Crafting"
Cohesion: 0.06
Nodes (54): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: falling off returns you to your island, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), blockedByCharacter(), inReach(), isCell() (+46 more)

### Community 3 - "CraftingWindow.luau"
Cohesion: 0.06
Nodes (34): Hotbar.Select(), Hotbar.Selected(), Hotbar.SelectedItem(), Hotbar.SetState(), Hotbar.Start(), pixelText(), render(), showName() (+26 more)

### Community 4 - "DataService.luau"
Cohesion: 0.32
Nodes (4): DataService.OnChanged(), DataService.OnDataLoaded(), Leaderstats.Start(), QuestService.Start()

### Community 5 - "Knowledge Graph Tools"
Cohesion: 0.31
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 6 - "Islands (Roblox)"
Cohesion: 0.22
Nodes (8): Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns, Warzone-only keys/materials unlock island tiers, ProfileStore (player data with session locking)

### Community 7 - "items3d.py"
Cohesion: 0.08
Nodes (25): axe(), thickness(), build_items(), downscale(), handle(), load_blocks(), main(), new_verts() (+17 more)

### Community 8 - "Core Loop and Pillars"
Cohesion: 0.36
Nodes (13): Design Pillars, Pitch (Draft), Target Audience, Core Loop, Islands Feature Checklist, Mechanics to Borrow, Skills & Levels, Tutorial & Quests (+5 more)

### Community 9 - "Audience, Policy and Death Drops"
Cohesion: 0.24
Nodes (7): Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added), Monetization Principles

### Community 10 - "DataService.GetData"
Cohesion: 0.33
Nodes (14): DataService.GetData(), DataService.MarkChanged(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.Remove(), InventoryService.RemoveMany() (+6 more)

### Community 11 - "FarmService.luau"
Cohesion: 0.19
Nodes (15): Better rewards as skills level up, bestSeed(), FarmService.Start(), heldSeed(), holdingShovel(), onFarmClick(), onIslandCreated(), onPlotClicked() (+7 more)

### Community 12 - "Skybounds (Minecraft)"
Cohesion: 0.15
Nodes (14): Mobile-first UI, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down), Skybounds Warzone (the user's favorite moment) (+6 more)

### Community 13 - "Economy.luau"
Cohesion: 0.25
Nodes (3): Economy.Total(), Economy.Value(), work()

### Community 14 - "CombatService.luau"
Cohesion: 0.29
Nodes (6): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing()

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "WarzoneService.luau"
Cohesion: 0.33
Nodes (9): describe(), dropBag(), dropLootHead(), enter(), isInRaid(), onCharacterAdded(), part(), WarzoneService.AddToBag() (+1 more)

### Community 17 - "Decision Log"
Cohesion: 0.13
Nodes (18): NPC visits at milestones with a starter pack, Combat (PvE) skill, Level gates: crops need Farming level, mobs need Combat level, Warzone parked until it moves into Town, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Merchant NPC at the Town market, Mobs: Slime (Combat 1), Brute (Combat 5) (+10 more)

### Community 18 - "MarketService.luau"
Cohesion: 0.22
Nodes (9): InventoryService.Count(), nearStall(), onBuySeed(), onSell(), sellItem(), checkReach(), complete(), currentQuest() (+1 more)

### Community 19 - "Loot head: your loot drops in your avatar's head on death"
Cohesion: 0.17
Nodes (11): Totems: passive resource generators with a range, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers, Passive generators with a range limit (+3 more)

### Community 20 - "Anti-Burnout Ideas"
Cohesion: 0.20
Nodes (9): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, PvP fairness options: zones by level, new-player protection, insurance slot, Warzone zones: outer ring Slimes, center Brutes (+1 more)

### Community 21 - "TownService.luau"
Cohesion: 0.20
Nodes (6): MarketService.Start(), addNameTag(), box(), makeMerchant(), TownService.GetMerchant(), Prompts.Create()

### Community 22 - "Merchant Behaviour"
Cohesion: 0.60
Nodes (3): findHead(), greet(), update()

### Community 24 - "BlockController.luau"
Cohesion: 0.12
Nodes (13): Decision: click-only farming, aim(), aimingAtMerchant(), BlockController.Start(), burst(), interact(), merchant(), myIsland() (+5 more)

### Community 29 - "Pitch: own a floating island, drop into a shared Warzone, bring loot home"
Cohesion: 0.22
Nodes (7): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Islands (Roblox game by Easy.gg), Update cadence: weekly event + monthly content drop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Decision: blend Islands + Skybounds Warzone

### Community 30 - "HotbarService.luau"
Cohesion: 0.39
Nodes (7): Decision: 5-slot Minecraft-style hotbar, HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 33 - "Props.luau"
Cohesion: 0.32
Nodes (5): addSign(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents()

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes (nothing to replant), The rules, Tools (new, full durability), Trading (planned): design notes, Value table

### Community 35 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

## Knowledge Gaps
- **14 isolated node(s):** `Roleplay + simulator hybrids growing [Unverified]`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 100 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Core Loop and Pillars` to `Islands (Roblox)`, `Audience, Policy and Death Drops`, `Skybounds (Minecraft)`, `Tools and Workflow`, `Decision Log`, `Loot head: your loot drops in your avatar's head on death`, `Anti-Burnout Ideas`?**
  _High betweenness centrality (0.374) - this node is a cross-community bridge._
- **Are the 25 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `pixelText()`) actually correct?**
  _`Theme.make()` has 25 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Roleplay + simulator hybrids growing [Unverified]`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Block Art Pipeline (Blender)` be split into smaller, more focused modules?**
  _Cohesion score 0.07199529826623567 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `Block Art Pipeline (Blender)`?**
  _High betweenness centrality (0.346) - this node is a cross-community bridge._
- **Are the 21 inferred relationships involving `DataService.GetData()` (e.g. with `onPlotClicked()` and `refreshPlot()`) actually correct?**
  _`DataService.GetData()` has 21 INFERRED edges - model-reasoned connections that need verification._
- **Should `Breaking, Placing and Crafting` be split into smaller, more focused modules?**
  _Cohesion score 0.05839727195225917 - nodes in this community are weakly interconnected._