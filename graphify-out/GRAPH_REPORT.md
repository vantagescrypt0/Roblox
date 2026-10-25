# Graph Report - Roblox  (2026-10-24)

## Corpus Check
- 89 files · ~50,842 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 615 nodes · 1499 edges · 30 communities (24 shown, 6 thin omitted)
- Extraction: 78% EXTRACTED · 22% INFERRED · 0% AMBIGUOUS · INFERRED: 334 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Block Art Pipeline (Blender)
- Theme.make
- Breaking, Placing and Crafting
- Skybounds (Minecraft)
- Decision: block toughness + tool power (Minecraft rules)
- Knowledge Graph Tools
- Mechanics to Borrow
- items3d.py
- Home
- Warzone
- Skills & Levels
- Economy.luau
- CombatService.luau
- Tools and Workflow
- Decision Log
- Loot head: your loot drops in your avatar's head on death
- Anti-Burnout Ideas
- TownService.luau
- Merchant Behaviour
- FarmService.luau
- BlockController.luau
- Inbox
- Core Loop
- Economy & Values
- Published privately as Sky Farm Prototype

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 36 edges
2. `Builder` - 24 edges
3. `DataService.GetData()` - 23 edges
4. `Home` - 23 edges
5. `build_tier()` - 19 edges
6. `Theme.corner()` - 19 edges
7. `Theme.stroke()` - 18 edges
8. `Skills & Levels` - 18 edges
9. `onBreak()` - 17 edges
10. `DataService.MarkChanged()` - 17 edges

## Surprising Connections (you probably didn't know these)
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `Totems: passive resource generators with a range` --semantically_similar_to--> `Passive generators with a range limit`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 03 Design/Mechanics to Borrow.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (30 total, 6 thin omitted)

### Community 0 - "Block Art Pipeline (Blender)"
Cohesion: 0.07
Nodes (48): build_atlas(), clamp(), draw_tiles(), ore(), fill(), main(), make_block(), noisy() (+40 more)

### Community 1 - "Theme.make"
Cohesion: 0.06
Nodes (78): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.Selected(), Hotbar.SetState(), Hotbar.Start(), render(), slotX(), buildButtons() (+70 more)

### Community 2 - "Breaking, Placing and Crafting"
Cohesion: 0.07
Nodes (50): Decision: falling off returns you to your island, blockedByCharacter(), inReach(), isCell(), onBreak(), onPlace(), nearStation(), addNode() (+42 more)

### Community 3 - "Skybounds (Minecraft)"
Cohesion: 0.29
Nodes (7): Pitch: own a floating island, drop into a shared Warzone, bring loot home, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Skybounds Warzone (the user's favorite moment), Decision: blend Islands + Skybounds Warzone

### Community 4 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.33
Nodes (4): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules)

### Community 5 - "Knowledge Graph Tools"
Cohesion: 0.31
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 6 - "Mechanics to Borrow"
Cohesion: 0.13
Nodes (15): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+7 more)

### Community 7 - "items3d.py"
Cohesion: 0.08
Nodes (28): axe(), thickness(), build_items(), carrot(), downscale(), handle(), load_blocks(), main() (+20 more)

### Community 8 - "Home"
Cohesion: 0.31
Nodes (10): Pitch (Draft), Islands Feature Checklist, Decision Log, Game name still undecided (can't reuse Islands/Skyblock/Skybounds), Open Questions, Evidence labels: Unverified / Inference / Speculation, Home, Sync the vault with GitHub Desktop (pull before, push after) (+2 more)

### Community 9 - "Warzone"
Cohesion: 0.15
Nodes (18): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+10 more)

### Community 12 - "Skills & Levels"
Cohesion: 0.17
Nodes (13): Skybounds seasons: 2-4 months, level resets, Better rewards as skills level up, Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Player level 1-50 (XP from PvE, grinding, quests), Seasons of 2-4 months; player level resets, Skills & Levels (+5 more)

### Community 13 - "Economy.luau"
Cohesion: 0.25
Nodes (3): Economy.Total(), Economy.Value(), work()

### Community 14 - "CombatService.luau"
Cohesion: 0.16
Nodes (10): PvP only when both players are in the Warzone, addCamera(), halfExtents(), ItemIcon.create(), viewport(), CombatService.Equip(), currentTool(), makeHandle() (+2 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 17 - "Decision Log"
Cohesion: 0.18
Nodes (11): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Content Index, Merchant NPC at the Town market, Mobs: Slime (Combat 1), Brute (Combat 5), Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town (+3 more)

### Community 19 - "Loot head: your loot drops in your avatar's head on death"
Cohesion: 0.29
Nodes (6): Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers

### Community 20 - "Anti-Burnout Ideas"
Cohesion: 0.25
Nodes (7): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, Decision: buy bigger islands with coins (4 tiers)

### Community 21 - "TownService.luau"
Cohesion: 0.12
Nodes (11): MarketService.Start(), addNameTag(), addSign(), box(), makeMerchant(), TownService.GetMerchant(), Prompts.Create(), baseOf() (+3 more)

### Community 22 - "Merchant Behaviour"
Cohesion: 0.60
Nodes (3): findHead(), greet(), update()

### Community 23 - "FarmService.luau"
Cohesion: 0.05
Nodes (54): DataService.GetData(), DataService.MarkChanged(), DataService.OnChanged(), DataService.OnDataLoaded(), bestSeed(), FarmService.Start(), heldSeed(), holdingShovel() (+46 more)

### Community 24 - "BlockController.luau"
Cohesion: 0.11
Nodes (15): Decision: click-only farming, aim(), aimingAtMerchant(), BlockController.Start(), burst(), interact(), merchant(), myIsland() (+7 more)

### Community 29 - "Core Loop"
Cohesion: 0.83
Nodes (4): Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes (nothing to replant), The rules, Tools (new, full durability), Trading (planned): design notes, Value table

### Community 35 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

## Knowledge Gaps
- **14 isolated node(s):** `Skybounds (Minecraft Skyblock server, now shut down)`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 100 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Home` to `Skybounds (Minecraft)`, `Mechanics to Borrow`, `Warzone`, `Skills & Levels`, `Tools and Workflow`, `Decision Log`, `Loot head: your loot drops in your avatar's head on death`, `Anti-Burnout Ideas`, `Core Loop`?**
  _High betweenness centrality (0.371) - this node is a cross-community bridge._
- **Are the 20 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 20 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Skybounds (Minecraft Skyblock server, now shut down)`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Block Art Pipeline (Blender)` be split into smaller, more focused modules?**
  _Cohesion score 0.0730282375851996 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `Block Art Pipeline (Blender)`?**
  _High betweenness centrality (0.344) - this node is a cross-community bridge._
- **Are the 21 inferred relationships involving `DataService.GetData()` (e.g. with `onPlotClicked()` and `refreshPlot()`) actually correct?**
  _`DataService.GetData()` has 21 INFERRED edges - model-reasoned connections that need verification._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.05768132495716733 - nodes in this community are weakly interconnected._