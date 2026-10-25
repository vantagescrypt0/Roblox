# Graph Report - Roblox  (2026-10-24)

## Corpus Check
- 92 files · ~56,306 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 631 nodes · 1541 edges · 35 communities (29 shown, 6 thin omitted)
- Extraction: 78% EXTRACTED · 22% INFERRED · 0% AMBIGUOUS · INFERRED: 343 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Block Art Pipeline (Blender)
- Theme.make
- Breaking, Placing and Crafting
- CraftingWindow.luau
- DataService.GetData
- WarzoneService.luau
- Mechanics to Borrow
- items3d.py
- Home
- Warzone
- FarmService.luau
- MarketService.luau
- Skills & Levels
- Economy.luau
- CombatService.luau
- Tools and Workflow
- DataService.luau
- Decision Log
- HotbarService.luau
- Design Pillars
- Anti-Burnout Ideas
- Props.luau
- Merchant Behaviour
- replicatedstorage_shared_items
- BlockController.luau
- Inbox
- ItemIcon.create
- QuestService.luau
- Economy & Values
- Published privately as Sky Farm Prototype

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 38 edges
2. `Builder` - 24 edges
3. `DataService.GetData()` - 24 edges
4. `Home` - 23 edges
5. `Theme.corner()` - 20 edges
6. `build_tier()` - 19 edges
7. `Theme.stroke()` - 19 edges
8. `DataService.MarkChanged()` - 18 edges
9. `Skills & Levels` - 18 edges
10. `Theme.text()` - 17 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Idle-grow / cozy trend (Grow a Garden spike and decay)` --semantically_similar_to--> `Offline progress and timers`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Anti-Burnout Ideas.md
- `Skill-gated vending machines and handshake trading` --semantically_similar_to--> `Trading with anti-scam UI (two-step confirm, trade log)`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 03 Design/Anti-Burnout Ideas.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (35 total, 6 thin omitted)

### Community 0 - "Block Art Pipeline (Blender)"
Cohesion: 0.06
Nodes (53): build_atlas(), clamp(), draw_tiles(), ore(), fill(), main(), make_block(), noisy() (+45 more)

### Community 1 - "Theme.make"
Cohesion: 0.11
Nodes (55): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+47 more)

### Community 2 - "Breaking, Placing and Crafting"
Cohesion: 0.06
Nodes (54): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: falling off returns you to your island, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), blockedByCharacter(), inReach(), isCell() (+46 more)

### Community 3 - "CraftingWindow.luau"
Cohesion: 0.06
Nodes (21): Window.clear(), Window.close(), Window.open(), Window.toggle(), BagWindow.SetState(), BagWindow.Toggle(), countLabel(), render() (+13 more)

### Community 4 - "DataService.GetData"
Cohesion: 0.33
Nodes (15): DataService.GetData(), DataService.MarkChanged(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn(), InventoryService.Count() (+7 more)

### Community 5 - "WarzoneService.luau"
Cohesion: 0.30
Nodes (11): describe(), dropBag(), dropLootHead(), endRaid(), enter(), extract(), isInRaid(), onCharacterAdded() (+3 more)

### Community 6 - "Mechanics to Borrow"
Cohesion: 0.16
Nodes (15): Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns, Totems: passive resource generators with a range, Fly tokens: tradeable timed power (+7 more)

### Community 7 - "items3d.py"
Cohesion: 0.08
Nodes (26): axe(), thickness(), carrot(), downscale(), handle(), load_blocks(), new_verts(), over() (+18 more)

### Community 8 - "Home"
Cohesion: 0.23
Nodes (14): Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision Log, Game name still undecided (can't reuse Islands/Skyblock/Skybounds) (+6 more)

### Community 9 - "Warzone"
Cohesion: 0.14
Nodes (19): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+11 more)

### Community 10 - "FarmService.luau"
Cohesion: 0.36
Nodes (10): bestSeed(), FarmService.Start(), heldSeed(), holdingShovel(), onFarmClick(), onIslandCreated(), onPlotClicked(), plotState() (+2 more)

### Community 11 - "MarketService.luau"
Cohesion: 0.22
Nodes (6): MarketService.Start(), nearStall(), onBuySeed(), onSell(), TownService.GetMerchant(), Prompts.Create()

### Community 12 - "Skills & Levels"
Cohesion: 0.21
Nodes (12): Better rewards as skills level up, Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Player level 1-50 (XP from PvE, grinding, quests), Skills & Levels, Level 10 unlocks the Warzone, Content Index (+4 more)

### Community 13 - "Economy.luau"
Cohesion: 0.22
Nodes (3): Economy.Total(), Economy.Value(), work()

### Community 14 - "CombatService.luau"
Cohesion: 0.22
Nodes (6): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing()

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "DataService.luau"
Cohesion: 0.28
Nodes (5): DataService.OnChanged(), DataService.OnDataLoaded(), Leaderstats.Start(), QuestService.Start(), TradeService.Start()

### Community 17 - "Decision Log"
Cohesion: 0.22
Nodes (9): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town, Prototype phase (current), Roadmap (+1 more)

### Community 18 - "HotbarService.luau"
Cohesion: 0.46
Nodes (6): HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 19 - "Design Pillars"
Cohesion: 0.15
Nodes (10): Design Pillars, Skybounds seasons: 2-4 months, level resets, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers (+2 more)

### Community 20 - "Anti-Burnout Ideas"
Cohesion: 0.14
Nodes (12): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Islands (Roblox game by Easy.gg), Skill-gated vending machines and handshake trading, Skybounds Warzone (the user's favorite moment), Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks (+4 more)

### Community 21 - "Props.luau"
Cohesion: 0.32
Nodes (5): addSign(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents()

### Community 22 - "Merchant Behaviour"
Cohesion: 0.60
Nodes (3): findHead(), greet(), update()

### Community 23 - "replicatedstorage_shared_items"
Cohesion: 0.11
Nodes (5): IslandService.OnIslandCreated(), addNameTag(), box(), makeMerchant(), TravelService.Go()

### Community 24 - "BlockController.luau"
Cohesion: 0.14
Nodes (21): Decision: click-only farming, Decision: 5-slot Minecraft-style hotbar, aim(), aimingAtMerchant(), BlockController.Start(), burst(), interact(), merchant() (+13 more)

### Community 29 - "ItemIcon.create"
Cohesion: 0.43
Nodes (4): addCamera(), halfExtents(), ItemIcon.create(), viewport()

### Community 30 - "QuestService.luau"
Cohesion: 0.80
Nodes (4): checkReach(), complete(), currentQuest(), QuestService.Record()

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes (nothing to replant), The rules, Tools (new, full durability), Trading between players, Value table

### Community 35 - "Published privately as Sky Farm Prototype"
Cohesion: 0.33
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Roleplay + simulator hybrids growing [Unverified]` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 106 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Home` to `Mechanics to Borrow`, `Warzone`, `Skills & Levels`, `Tools and Workflow`, `Decision Log`, `Design Pillars`, `Anti-Burnout Ideas`?**
  _High betweenness centrality (0.358) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Block Art Pipeline (Blender)` be split into smaller, more focused modules?**
  _Cohesion score 0.06287985039738195 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `Block Art Pipeline (Blender)`?**
  _High betweenness centrality (0.337) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `DataService.GetData()` (e.g. with `onPlotClicked()` and `refreshPlot()`) actually correct?**
  _`DataService.GetData()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.10957501280081926 - nodes in this community are weakly interconnected._