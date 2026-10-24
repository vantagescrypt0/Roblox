# Graph Report - Roblox  (2026-10-24)

## Corpus Check
- Corpus is ~42,793 words - fits in a single context window. You may not need a graph.

## Summary
- 544 nodes · 1388 edges · 24 communities (19 shown, 5 thin omitted)
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 345 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Block Art Pipeline (Blender)
- HUD and Hotbar
- Farming, Combat and Inventory
- Skills, Levels and Content
- Breaking, Placing and Crafting
- Prop Placement
- Merchant Behaviour
- Mouse and Touch Controls
- Player Data and Held Items
- Knowledge Graph Tools
- Decisions and Island Tiers
- Tools and Workflow
- Tutorial and Roadmap
- Trends and Anti-Burnout
- Publishing and Dev Tools
- Inbox
- Islands Research
- Pitch and Inspiration
- Core Loop and Pillars
- Audience, Policy and Death Drops

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 40 edges
2. `DataService.GetData()` - 23 edges
3. `Home` - 23 edges
4. `Builder` - 22 edges
5. `build_tier()` - 19 edges
6. `Theme.stroke()` - 19 edges
7. `Theme.corner()` - 18 edges
8. `Skills & Levels` - 18 edges
9. `DataService.MarkChanged()` - 17 edges
10. `Warzone` - 17 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `Skill-gated vending machines and handshake trading` --semantically_similar_to--> `Trading with anti-scam UI (two-step confirm, trade log)`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 03 Design/Anti-Burnout Ideas.md
- `Idle-grow / cozy trend (Grow a Garden spike and decay)` --semantically_similar_to--> `Offline progress and timers`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Anti-Burnout Ideas.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (24 total, 5 thin omitted)

### Community 0 - "Block Art Pipeline (Blender)"
Cohesion: 0.07
Nodes (51): Builder, build_atlas(), clamp(), draw_tiles(), ore(), fill(), main(), make_block() (+43 more)

### Community 1 - "HUD and Hotbar"
Cohesion: 0.15
Nodes (46): Hotbar.Start(), pixelText(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), Hud.Celebrate() (+38 more)

### Community 10 - "Farming, Combat and Inventory"
Cohesion: 0.05
Nodes (56): CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), targetsInFront(), DataService.GetData(), DataService.MarkChanged() (+48 more)

### Community 12 - "Skills, Levels and Content"
Cohesion: 0.17
Nodes (14): Leveling.FarmingBonusChance(), Leveling.XPToNext(), Skybounds seasons: 2-4 months, level resets, Better rewards as skills level up, Combat (PvE) skill, Level gates: crops need Farming level, mobs need Combat level, Player level 1-50 (XP from PvE, grinding, quests), Seasons of 2-4 months; player level resets (+6 more)

### Community 2 - "Breaking, Placing and Crafting"
Cohesion: 0.06
Nodes (51): blockedByCharacter(), inReach(), isCell(), onBreak(), onPlace(), nearStation(), announce(), build() (+43 more)

### Community 21 - "Prop Placement"
Cohesion: 0.32
Nodes (5): addSign(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents()

### Community 22 - "Merchant Behaviour"
Cohesion: 0.60
Nodes (3): findHead(), greet(), update()

### Community 3 - "Mouse and Touch Controls"
Cohesion: 0.05
Nodes (42): aim(), aimingAtMerchant(), BlockController.Start(), burst(), hintFor(), interact(), merchant(), myIsland() (+34 more)

### Community 4 - "Player Data and Held Items"
Cohesion: 0.19
Nodes (10): DataService.OnChanged(), DataService.OnDataLoaded(), HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld() (+2 more)

### Community 5 - "Knowledge Graph Tools"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 18 - "Decisions and Island Tiers"
Cohesion: 0.14
Nodes (15): NPC visits at milestones with a starter pack, Economy sinks to slow inflation, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: click-only farming, Decision: falling off returns you to your island, Decision: 5-slot Minecraft-style hotbar, Decision: buy bigger islands with coins (4 tiers) (+7 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes, Item pipeline: pixel sprites extruded into voxel tool/crop models (+4 more)

### Community 17 - "Tutorial and Roadmap"
Cohesion: 0.33
Nodes (6): 100+ challenges and an island challenge ladder, Beginner quest chain (13 quests, ends at level 10), Prototype phase (current), Vertical slice, then soft launch, launch and live ops, Tutorial & Quests, Roadmap

### Community 20 - "Trends and Anti-Burnout"
Cohesion: 0.17
Nodes (11): Skill-gated vending machines and handshake trading, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Why big hits declined: event spikes, exploits, economy trust, confusing resets, Trading with anti-scam UI (two-step confirm, trade log), Offline progress and timers, Prestige with real unlocks (+3 more)

### Community 23 - "Publishing and Dev Tools"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Saving in Studio needs a published place + Studio API access, Game code README

### Community 6 - "Islands Research"
Cohesion: 0.16
Nodes (15): Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Key-gated adventure islands, Token-summoned bosses with cooldowns, Totems: passive resource generators with a range, Fly tokens: tradeable timed power, Skybounds (Minecraft Skyblock server, now shut down) (+7 more)

### Community 7 - "Pitch and Inspiration"
Cohesion: 0.33
Nodes (5): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Islands (Roblox game by Easy.gg), Skybounds Warzone (the user's favorite moment), Update cadence: weekly event + monthly content drop, Decision: blend Islands + Skybounds Warzone

### Community 8 - "Core Loop and Pillars"
Cohesion: 0.24
Nodes (11): Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Game name still undecided (can't reuse Islands/Skyblock/Skybounds), Evidence labels: Unverified / Inference / Speculation, Design Pillars, Pitch (Draft), Core Loop (+3 more)

### Community 9 - "Audience, Policy and Death Drops"
Cohesion: 0.16
Nodes (16): Mobile-first UI, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Steal An Egg precedent (feature pulled, rule added), Skybounds: your head drops on death with your loot, Loot head: your loot drops in your avatar's head on death (+8 more)

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Sync the vault with GitHub Desktop (pull before, push after)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 79 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Core Loop and Pillars` to `Islands Research`, `Audience, Policy and Death Drops`, `Skills, Levels and Content`, `Tools and Workflow`, `Tutorial and Roadmap`, `Decisions and Island Tiers`, `Trends and Anti-Burnout`?**
  _High betweenness centrality (0.343) - this node is a cross-community bridge._
- **Are the 25 inferred relationships involving `Theme.make()` (e.g. with `BlockController.Start()` and `Hotbar.Start()`) actually correct?**
  _`Theme.make()` has 25 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Block Art Pipeline (Blender)` be split into smaller, more focused modules?**
  _Cohesion score 0.07030205827318899 - nodes in this community are weakly interconnected._
- **Why does `Workflow` connect `Tools and Workflow` to `Core Loop and Pillars`?**
  _High betweenness centrality (0.287) - this node is a cross-community bridge._
- **Are the 21 inferred relationships involving `DataService.GetData()` (e.g. with `onPlotClicked()` and `refreshPlot()`) actually correct?**
  _`DataService.GetData()` has 21 INFERRED edges - model-reasoned connections that need verification._
- **Should `Farming, Combat and Inventory` be split into smaller, more focused modules?**
  _Cohesion score 0.05239075726378403 - nodes in this community are weakly interconnected._