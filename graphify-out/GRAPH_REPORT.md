# Graph Report - Roblox  (2026-10-24)

## Corpus Check
- Corpus is ~42,793 words - fits in a single context window. You may not need a graph.

## Summary
- 514 nodes · 1313 edges · 29 communities (24 shown, 5 thin omitted)
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 329 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Block Art Pipeline (Blender)
- HUD and Toasts
- Block Breaking and Toughness
- Hotbar and Item Icons
- Combat and Held Tools
- Mouse and Touch Controls
- Islands Research and Pillars
- Island Plots and Spawning
- Pitch and Core Loop
- Audience, Policy and Tutorial
- Town and Merchant Build
- Inventory and Coins
- Skills, Levels and Content
- Market, Mobs and Quests
- Warzone Raids
- Tools and Workflow
- Farming
- Skybounds and Loot Heads
- Roadmap and Merchant Plans
- Seasons and Trends
- Economy and Anti-Burnout
- Prop Placement
- Merchant Behaviour
- Publishing and Dev Tools
- Inbox

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 40 edges
2. `Home (vault dashboard)` - 23 edges
3. `Builder` - 22 edges
4. `DataService.GetData()` - 21 edges
5. `build_tier()` - 19 edges
6. `Theme.stroke()` - 19 edges
7. `Theme.corner()` - 18 edges
8. `Skills & Levels` - 18 edges
9. `DataService.MarkChanged()` - 17 edges
10. `Warzone` - 17 edges

## Surprising Connections (you probably didn't know these)
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md
- `Totems: passive resource generators with a range` --semantically_similar_to--> `Passive generators with a range limit`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 03 Design/Mechanics to Borrow.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]

## Communities (29 total, 5 thin omitted)

### Community 0 - "Block Art Pipeline (Blender)"
Cohesion: 0.07
Nodes (50): build_atlas(), clamp(), draw_tiles(), fill(), main(), make_block(), noisy(), speckle() (+42 more)

### Community 1 - "HUD and Toasts"
Cohesion: 0.11
Nodes (55): Hotbar.Start(), pixelText(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), Hud.Celebrate() (+47 more)

### Community 2 - "Block Breaking and Toughness"
Cohesion: 0.09
Nodes (26): Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), blockedByCharacter(), inReach(), isCell(), onBreak(), onPlace() (+18 more)

### Community 3 - "Hotbar and Item Icons"
Cohesion: 0.10
Nodes (20): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.Selected(), Hotbar.SetState(), render(), showName(), addCamera(), halfExtents() (+12 more)

### Community 4 - "Combat and Held Tools"
Cohesion: 0.12
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), targetsInFront(), DataService.OnChanged() (+9 more)

### Community 5 - "Mouse and Touch Controls"
Cohesion: 0.13
Nodes (14): aim(), aimingAtMerchant(), BlockController.Start(), burst(), hintFor(), interact(), merchant(), myIsland() (+6 more)

### Community 6 - "Islands Research and Pillars"
Cohesion: 0.12
Nodes (17): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+9 more)

### Community 7 - "Island Plots and Spawning"
Cohesion: 0.11
Nodes (3): Player level 1-50 (XP from PvE, grinding, quests), Decision: falling off returns you to your island, IslandService.OnIslandCreated()

### Community 8 - "Pitch and Core Loop"
Cohesion: 0.19
Nodes (17): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+9 more)

### Community 9 - "Audience, Policy and Tutorial"
Cohesion: 0.17
Nodes (12): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+4 more)

### Community 10 - "Town and Merchant Build"
Cohesion: 0.18
Nodes (5): addNameTag(), box(), makeMerchant(), TownService.Enter(), travel()

### Community 11 - "Inventory and Coins"
Cohesion: 0.33
Nodes (14): DataService.GetData(), DataService.MarkChanged(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.Count(), InventoryService.Remove() (+6 more)

### Community 12 - "Skills, Levels and Content"
Cohesion: 0.21
Nodes (12): Skybounds Warzone (the user's favorite moment), Better rewards as skills level up, Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Level 10 unlocks the Warzone, Content Index (+4 more)

### Community 13 - "Market, Mobs and Quests"
Cohesion: 0.25
Nodes (7): nearStall(), onBuySeed(), onSell(), checkReach(), complete(), currentQuest(), QuestService.Record()

### Community 14 - "Warzone Raids"
Cohesion: 0.30
Nodes (11): describe(), dropBag(), dropLootHead(), endRaid(), enter(), extract(), isInRaid(), onCharacterAdded() (+3 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "Farming"
Cohesion: 0.33
Nodes (11): bestSeed(), FarmService.Start(), formatTime(), heldSeed(), makeLabel(), onFarmClick(), onIslandCreated(), onPlotClicked() (+3 more)

### Community 17 - "Skybounds and Loot Heads"
Cohesion: 0.24
Nodes (11): 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Loot head: your loot drops in your avatar's head on death, PvP fairness options: zones by level, new-player protection, insurance slot, Raid bag + extraction pads (+3 more)

### Community 18 - "Roadmap and Merchant Plans"
Cohesion: 0.22
Nodes (9): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town, Prototype phase (current), Roadmap (+1 more)

### Community 19 - "Seasons and Trends"
Cohesion: 0.25
Nodes (7): Skybounds seasons: 2-4 months, level resets, Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Seasons of 2-4 months; player level resets, What resets each season?

### Community 20 - "Economy and Anti-Burnout"
Cohesion: 0.25
Nodes (7): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, Decision: buy bigger islands with coins (4 tiers)

### Community 21 - "Prop Placement"
Cohesion: 0.32
Nodes (5): addSign(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents()

### Community 22 - "Merchant Behaviour"
Cohesion: 0.60
Nodes (3): findHead(), greet(), update()

### Community 23 - "Publishing and Dev Tools"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

## Knowledge Gaps
- **14 isolated node(s):** `Evidence labels: Unverified / Inference / Speculation`, `Inbox`, `Conveyor factories (splitters, filters, sensors)`, `Token-summoned bosses with cooldowns`, `Hidden fossil collection quests` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 80 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Pitch and Core Loop` to `Islands Research and Pillars`, `Audience, Policy and Tutorial`, `Skills, Levels and Content`, `Tools and Workflow`, `Skybounds and Loot Heads`, `Roadmap and Merchant Plans`, `Seasons and Trends`, `Economy and Anti-Burnout`?**
  _High betweenness centrality (0.336) - this node is a cross-community bridge._
- **Are the 25 inferred relationships involving `Theme.make()` (e.g. with `BlockController.Start()` and `Hotbar.Start()`) actually correct?**
  _`Theme.make()` has 25 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Evidence labels: Unverified / Inference / Speculation`, `Inbox`, `Conveyor factories (splitters, filters, sensors)` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Block Art Pipeline (Blender)` be split into smaller, more focused modules?**
  _Cohesion score 0.07140902872777018 - nodes in this community are weakly interconnected._
- **Why does `Workflow` connect `Tools and Workflow` to `Pitch and Core Loop`?**
  _High betweenness centrality (0.274) - this node is a cross-community bridge._
- **Are the 19 inferred relationships involving `DataService.GetData()` (e.g. with `onPlotClicked()` and `refreshPlot()`) actually correct?**
  _`DataService.GetData()` has 19 INFERRED edges - model-reasoned connections that need verification._
- **Should `HUD and Toasts` be split into smaller, more focused modules?**
  _Cohesion score 0.11394230769230769 - nodes in this community are weakly interconnected._