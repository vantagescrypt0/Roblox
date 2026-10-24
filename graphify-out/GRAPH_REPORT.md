# Graph Report - Roblox  (2026-10-24)

## Corpus Check
- 87 files · ~49,369 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 595 nodes · 1490 edges · 33 communities (24 shown, 9 thin omitted)
- Extraction: 76% EXTRACTED · 24% INFERRED · 0% AMBIGUOUS · INFERRED: 365 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Block Art Pipeline (Blender)
- HUD and Hotbar
- Breaking, Placing and Crafting
- BlockController.luau
- DataService.luau
- Knowledge Graph Tools
- Islands Research
- items3d.py
- Core Loop and Pillars
- Audience, Policy and Death Drops
- DataService.MarkChanged
- FarmService.luau
- Skills, Levels and Content
- Decision: block toughness + tool power (Minecraft rules)
- CombatService.luau
- Tools and Workflow
- WarzoneService.luau
- Roadmap
- Decision Log
- Warzone
- Anti-Burnout Ideas
- TownService.luau
- Merchant Behaviour
- BlockService.luau
- Inbox
- HotbarService.luau

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 41 edges
2. `Builder` - 24 edges
3. `DataService.GetData()` - 23 edges
4. `Home` - 23 edges
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
- `Skill-gated vending machines and handshake trading` --semantically_similar_to--> `Trading with anti-scam UI (two-step confirm, trade log)`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 03 Design/Anti-Burnout Ideas.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (33 total, 9 thin omitted)

### Community 0 - "Block Art Pipeline (Blender)"
Cohesion: 0.07
Nodes (50): build_atlas(), clamp(), draw_tiles(), ore(), fill(), main(), make_block(), noisy() (+42 more)

### Community 1 - "HUD and Hotbar"
Cohesion: 0.10
Nodes (62): Hotbar.Start(), pixelText(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), Hud.Celebrate() (+54 more)

### Community 2 - "Breaking, Placing and Crafting"
Cohesion: 0.08
Nodes (45): inReach(), isCell(), onBreak(), onPlace(), nearStation(), announce(), build(), claimPlot() (+37 more)

### Community 3 - "BlockController.luau"
Cohesion: 0.09
Nodes (29): aim(), aimingAtMerchant(), BlockController.Start(), burst(), hintFor(), interact(), merchant(), myIsland() (+21 more)

### Community 4 - "DataService.luau"
Cohesion: 0.32
Nodes (4): DataService.OnChanged(), DataService.OnDataLoaded(), Leaderstats.Start(), QuestService.Start()

### Community 5 - "Knowledge Graph Tools"
Cohesion: 0.31
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 6 - "Islands Research"
Cohesion: 0.12
Nodes (17): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+9 more)

### Community 7 - "items3d.py"
Cohesion: 0.08
Nodes (26): axe(), thickness(), carrot(), downscale(), handle(), load_blocks(), new_verts(), over() (+18 more)

### Community 8 - "Core Loop and Pillars"
Cohesion: 0.26
Nodes (12): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+4 more)

### Community 9 - "Audience, Policy and Death Drops"
Cohesion: 0.20
Nodes (11): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+3 more)

### Community 10 - "DataService.MarkChanged"
Cohesion: 0.18
Nodes (20): DataService.MarkChanged(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.Count(), InventoryService.Remove(), InventoryService.RemoveMany() (+12 more)

### Community 11 - "FarmService.luau"
Cohesion: 0.22
Nodes (14): Better rewards as skills level up, bestSeed(), FarmService.Start(), formatTime(), heldSeed(), makeLabel(), onFarmClick(), onIslandCreated() (+6 more)

### Community 12 - "Skills, Levels and Content"
Cohesion: 0.15
Nodes (17): Skybounds seasons: 2-4 months, level resets, Skybounds Warzone (the user's favorite moment), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Combat (PvE) skill, Farming skill (+9 more)

### Community 13 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.15
Nodes (6): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), Mining.BreakTime(), Mining.UsesTool()

### Community 14 - "CombatService.luau"
Cohesion: 0.19
Nodes (7): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), WarzoneService.IsInRaid()

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "WarzoneService.luau"
Cohesion: 0.34
Nodes (11): DataService.GetData(), describe(), dropBag(), dropLootHead(), endRaid(), enter(), extract(), isInRaid() (+3 more)

### Community 17 - "Roadmap"
Cohesion: 0.22
Nodes (9): Warzone parked until it moves into Town, Decision: Market moved off the island into Town, Next: add the Warzone to Town, Prototype phase (current), Published privately as Sky Farm Prototype, Roadmap, Vertical slice, then soft launch, launch and live ops, Game code README (+1 more)

### Community 18 - "Decision Log"
Cohesion: 0.33
Nodes (7): Decision: click-only farming, Decision: falling off returns you to your island, Decision: 5-slot Minecraft-style hotbar, Decision Log, Sync the vault with GitHub Desktop (pull before, push after), Obsidian Setup, Vault rules: Inbox, Decision Log, Open Questions

### Community 19 - "Warzone"
Cohesion: 0.24
Nodes (11): 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Loot head: your loot drops in your avatar's head on death, PvP fairness options: zones by level, new-player protection, insurance slot, Raid bag + extraction pads (+3 more)

### Community 20 - "Anti-Burnout Ideas"
Cohesion: 0.25
Nodes (7): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, Decision: buy bigger islands with coins (4 tiers)

### Community 21 - "TownService.luau"
Cohesion: 0.12
Nodes (11): MarketService.Start(), addNameTag(), addSign(), box(), makeMerchant(), TownService.GetMerchant(), Prompts.Create(), baseOf() (+3 more)

### Community 22 - "Merchant Behaviour"
Cohesion: 0.32
Nodes (6): NPC visits at milestones with a starter pack, Merchant NPC at the Town market, Decision: villager-style Merchant runs the Market, findHead(), greet(), update()

### Community 30 - "HotbarService.luau"
Cohesion: 0.46
Nodes (6): HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Sync the vault with GitHub Desktop (pull before, push after)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 94 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Core Loop and Pillars` to `Islands Research`, `Audience, Policy and Death Drops`, `Skills, Levels and Content`, `Tools and Workflow`, `Roadmap`, `Decision Log`, `Warzone`, `Anti-Burnout Ideas`?**
  _High betweenness centrality (0.382) - this node is a cross-community bridge._
- **Are the 26 inferred relationships involving `Theme.make()` (e.g. with `BlockController.Start()` and `Hotbar.Start()`) actually correct?**
  _`Theme.make()` has 26 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Block Art Pipeline (Blender)` be split into smaller, more focused modules?**
  _Cohesion score 0.07317073170731707 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `Block Art Pipeline (Blender)`?**
  _High betweenness centrality (0.351) - this node is a cross-community bridge._
- **Are the 21 inferred relationships involving `DataService.GetData()` (e.g. with `onPlotClicked()` and `refreshPlot()`) actually correct?**
  _`DataService.GetData()` has 21 INFERRED edges - model-reasoned connections that need verification._
- **Should `HUD and Hotbar` be split into smaller, more focused modules?**
  _Cohesion score 0.09508771929824561 - nodes in this community are weakly interconnected._