# Graph Report - Roblox  (2026-10-25)

## Corpus Check
- 95 files · ~61,297 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 654 nodes · 1618 edges · 35 communities (27 shown, 8 thin omitted)
- Extraction: 77% EXTRACTED · 23% INFERRED · 0% AMBIGUOUS · INFERRED: 370 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Builder
- Theme.make
- Breaking, Placing and Crafting
- Hotbar.luau
- FarmService.luau
- replicatedstorage_shared_items
- Mechanics to Borrow
- items3d.py
- Home
- Warzone
- CraftingWindow.luau
- Window.luau
- Skills & Levels
- Economy.luau
- CombatService.luau
- Tools and Workflow
- DataService.luau
- Roadmap
- ProgressionService.luau
- Design Pillars
- Anti-Burnout Ideas
- TownService.luau
- Merchant Behaviour
- replicatedstorage_shared_items
- BlockController.luau
- Inbox
- Economy & Values
- TradeService.luau
- Warzone
- graph_to_vault.py

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 38 edges
2. `DataService.GetData()` - 26 edges
3. `Builder` - 24 edges
4. `Home` - 23 edges
5. `Theme.corner()` - 20 edges
6. `DataService.MarkChanged()` - 20 edges
7. `Skills & Levels` - 20 edges
8. `build_tier()` - 19 edges
9. `Theme.stroke()` - 19 edges
10. `onBreak()` - 19 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md
- `In progress right now` --references--> `untill()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/FarmService.luau

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (35 total, 8 thin omitted)

### Community 0 - "Builder"
Cohesion: 0.07
Nodes (50): build_atlas(), clamp(), draw_tiles(), ore(), fill(), main(), make_block(), noisy() (+42 more)

### Community 1 - "Theme.make"
Cohesion: 0.11
Nodes (55): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+47 more)

### Community 2 - "Breaking, Placing and Crafting"
Cohesion: 0.07
Nodes (46): Decision: falling off returns you to your island, Decision: Minecraft-style block islands (break and place, saved), blockedByCharacter(), inReach(), isCell(), isNatural(), onPlace(), addNode() (+38 more)

### Community 3 - "Hotbar.luau"
Cohesion: 0.15
Nodes (14): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.Selected(), Hotbar.SetState(), render(), showName(), slotX(), addCamera() (+6 more)

### Community 4 - "FarmService.luau"
Cohesion: 0.07
Nodes (68): Handoff (updated 2026-10-25), In progress right now, Next up (from the Roadmap), Not published yet (needs your "publish"), Open questions for you, Where things are, Better rewards as skills level up, onBreak() (+60 more)

### Community 5 - "replicatedstorage_shared_items"
Cohesion: 0.22
Nodes (4): IslandWindow.SetState(), offered(), setOffer(), wearBar()

### Community 6 - "Mechanics to Borrow"
Cohesion: 0.12
Nodes (17): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+9 more)

### Community 7 - "items3d.py"
Cohesion: 0.08
Nodes (26): axe(), thickness(), carrot(), downscale(), handle(), load_blocks(), new_verts(), over() (+18 more)

### Community 8 - "Home"
Cohesion: 0.21
Nodes (16): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+8 more)

### Community 9 - "Warzone"
Cohesion: 0.20
Nodes (11): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+3 more)

### Community 10 - "CraftingWindow.luau"
Cohesion: 0.29
Nodes (10): check(), choose(), CraftingWindow.SetState(), ingredientChip(), levelOf(), render(), renderDetail(), skillChip() (+2 more)

### Community 11 - "Window.luau"
Cohesion: 0.27
Nodes (8): Window.clear(), Window.close(), Window.open(), Window.toggle(), BagWindow.Toggle(), CraftingWindow.Open(), IslandWindow.Close(), IslandWindow.Toggle()

### Community 12 - "Skills & Levels"
Cohesion: 0.24
Nodes (10): Skybounds Warzone (the user's favorite moment), Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Player level 1-50 (XP from PvE, grinding, quests), Skills & Levels, Level 10 unlocks the Warzone, Content Index (+2 more)

### Community 13 - "Economy.luau"
Cohesion: 0.12
Nodes (8): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: block toughness + tool power (Minecraft rules), Economy.Total(), Economy.Value(), work(), Mining.BreakTime(), Mining.UsesTool()

### Community 14 - "CombatService.luau"
Cohesion: 0.29
Nodes (6): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing()

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "DataService.luau"
Cohesion: 0.20
Nodes (5): DataService.OnChanged(), DataService.OnDataLoaded(), Leaderstats.Start(), QuestService.Start(), TradeService.Start()

### Community 17 - "Roadmap"
Cohesion: 0.22
Nodes (9): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town, Prototype phase (current), Roadmap (+1 more)

### Community 19 - "Design Pillars"
Cohesion: 0.25
Nodes (7): Skybounds seasons: 2-4 months, level resets, Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Seasons of 2-4 months; player level resets, What resets each season?

### Community 20 - "Anti-Burnout Ideas"
Cohesion: 0.25
Nodes (7): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, Decision: buy bigger islands with coins (4 tiers)

### Community 21 - "TownService.luau"
Cohesion: 0.12
Nodes (11): MarketService.Start(), addNameTag(), addSign(), box(), makeMerchant(), TownService.GetMerchant(), Prompts.Create(), baseOf() (+3 more)

### Community 22 - "Merchant Behaviour"
Cohesion: 0.60
Nodes (3): findHead(), greet(), update()

### Community 24 - "BlockController.luau"
Cohesion: 0.11
Nodes (14): Decision: click-only farming, aim(), aimingAtMerchant(), BlockController.Start(), burst(), interact(), merchant(), myIsland() (+6 more)

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes (nothing to replant), The rules, Tools (new, full durability), Trading between players, Value table

### Community 35 - "TradeService.luau"
Cohesion: 0.18
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 37 - "Warzone"
Cohesion: 0.24
Nodes (11): 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Loot head: your loot drops in your avatar's head on death, PvP fairness options: zones by level, new-player protection, insurance slot, Raid bag + extraction pads (+3 more)

### Community 39 - "graph_to_vault.py"
Cohesion: 0.31
Nodes (3): main(), merge_color_groups(), real_notes()

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Sync the vault with GitHub Desktop (pull before, push after)`, `Roleplay + simulator hybrids growing [Unverified]`, `Prestige with real unlocks` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 113 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Home` to `Warzone`, `Mechanics to Borrow`, `Warzone`, `Skills & Levels`, `Tools and Workflow`, `Roadmap`, `Design Pillars`, `Anti-Burnout Ideas`?**
  _High betweenness centrality (0.348) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Sync the vault with GitHub Desktop (pull before, push after)` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Builder` be split into smaller, more focused modules?**
  _Cohesion score 0.07467630231857875 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `Builder`?**
  _High betweenness centrality (0.329) - this node is a cross-community bridge._
- **Are the 24 inferred relationships involving `DataService.GetData()` (e.g. with `onPlotClicked()` and `onTill()`) actually correct?**
  _`DataService.GetData()` has 24 INFERRED edges - model-reasoned connections that need verification._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.10957501280081926 - nodes in this community are weakly interconnected._