# Graph Report - Roblox  (2026-10-25)

## Corpus Check
- 115 files · ~88,791 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 754 nodes · 1763 edges · 42 communities (29 shown, 13 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 321 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Builder
- Theme.make
- Breaking, Placing and Crafting
- WarzoneService.luau
- WorldService.luau
- TradeWindow.luau
- Mechanics to Borrow
- items3d.py
- Home
- Warzone
- Props.luau
- Handoff (updated 2026-10-25, session 2)
- Skills & Levels
- Economy.luau
- Decor.luau
- Tools and Workflow
- CraftingWindow.luau
- Roadmap
- Skybounds (Minecraft)
- Anti-Burnout Ideas
- ShopService.luau
- Town & Worlds
- replicatedstorage_shared_items
- Main.client.luau
- Inbox
- Trends - Oct 2026
- TravelService.luau
- Spawning.luau
- Published privately as Sky Farm Prototype
- Economy & Values
- QuestService.luau
- ItemIcon.create
- graph_to_vault.py
- AmbientController.luau
- Ambience.luau

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 38 edges
2. `Builder` - 24 edges
3. `Home` - 23 edges
4. `Skills & Levels` - 21 edges
5. `Theme.corner()` - 20 edges
6. `build_tier()` - 19 edges
7. `Theme.stroke()` - 19 edges
8. `Warzone` - 18 edges
9. `Theme.text()` - 17 edges
10. `Decision Log` - 17 edges

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

## Communities (42 total, 13 thin omitted)

### Community 0 - "Builder"
Cohesion: 0.06
Nodes (56): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_tiles(), ore(), fill() (+48 more)

### Community 1 - "Theme.make"
Cohesion: 0.09
Nodes (64): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+56 more)

### Community 2 - "Breaking, Placing and Crafting"
Cohesion: 0.05
Nodes (62): Better rewards as skills level up, Decision: Minecraft-style block islands (break and place, saved), inReach(), isCell(), onBreak(), onPlace(), treeFell(), nearStation() (+54 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.16
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 4 - "WorldService.luau"
Cohesion: 0.05
Nodes (20): Decision: falling off returns you to your island, set(), setFree(), top(), ctx.Field(), ctx.Hash(), ctx.Inside(), ctx.Node() (+12 more)

### Community 5 - "TradeWindow.luau"
Cohesion: 0.18
Nodes (6): BagWindow.SetState(), countLabel(), render(), offered(), setOffer(), wearBar()

### Community 6 - "Mechanics to Borrow"
Cohesion: 0.13
Nodes (15): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+7 more)

### Community 7 - "items3d.py"
Cohesion: 0.07
Nodes (28): axe(), thickness(), carrot(), downscale(), handle(), hoe(), load_blocks(), new_verts() (+20 more)

### Community 8 - "Home"
Cohesion: 0.21
Nodes (16): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+8 more)

### Community 9 - "Warzone"
Cohesion: 0.15
Nodes (18): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+10 more)

### Community 10 - "Props.luau"
Cohesion: 0.24
Nodes (6): baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), Signs.Board(), Signs.Label()

### Community 11 - "Handoff (updated 2026-10-25, session 2)"
Cohesion: 0.25
Nodes (7): Done this session (2026-10-25, session 2), Handoff (updated 2026-10-25, session 2), How-to notes for the next session, In progress right now, Next up — needs your call, Open questions for you, Published 2026-10-25

### Community 12 - "Skills & Levels"
Cohesion: 0.30
Nodes (9): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Prototype phase (current), Roadmap (+1 more)

### Community 13 - "Economy.luau"
Cohesion: 0.07
Nodes (30): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: click-only farming, Decision: 5-slot Minecraft-style hotbar, Decision: block toughness + tool power (Minecraft rules), aim(), aimedShop(), BlockController.Start() (+22 more)

### Community 14 - "Decor.luau"
Cohesion: 0.22
Nodes (18): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox(), Decor.Grass(), Decor.Jet() (+10 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "CraftingWindow.luau"
Cohesion: 0.26
Nodes (11): check(), choose(), CraftingWindow.SetState(), ingredientChip(), levelOf(), render(), renderDetail(), skillChip() (+3 more)

### Community 17 - "Roadmap"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

### Community 19 - "Skybounds (Minecraft)"
Cohesion: 0.20
Nodes (10): 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down), Skybounds Warzone (the user's favorite moment), Player level 1-50 (XP from PvE, grinding, quests), Seasons of 2-4 months; player level resets (+2 more)

### Community 20 - "Anti-Burnout Ideas"
Cohesion: 0.25
Nodes (7): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, Decision: buy bigger islands with coins (4 tiers)

### Community 21 - "ShopService.luau"
Cohesion: 0.27
Nodes (6): nearShop(), onBuy(), onSell(), ShopService.Start(), TownService.GetShopkeepers(), Prompts.Create()

### Community 22 - "Town & Worlds"
Cohesion: 0.33
Nodes (6): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The resource worlds, The Town (hub), Town & Worlds

### Community 24 - "Main.client.luau"
Cohesion: 0.07
Nodes (13): greet(), NpcController.Start(), track(), update(), HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot() (+5 more)

### Community 29 - "Trends - Oct 2026"
Cohesion: 0.29
Nodes (6): Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers

### Community 33 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "QuestService.luau"
Cohesion: 0.52
Nodes (5): checkReach(), complete(), currentQuest(), giveReward(), QuestService.Record()

### Community 38 - "ItemIcon.create"
Cohesion: 0.53
Nodes (4): addCamera(), halfExtents(), ItemIcon.create(), viewport()

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

## Knowledge Gaps
- **14 isolated node(s):** `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Skybounds (Minecraft Skyblock server, now shut down)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 157 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Home` to `Mechanics to Borrow`, `Warzone`, `Skills & Levels`, `Tools and Workflow`, `Skybounds (Minecraft)`, `Anti-Burnout Ideas`, `Trends - Oct 2026`?**
  _High betweenness centrality (0.316) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Builder` be split into smaller, more focused modules?**
  _Cohesion score 0.06315789473684211 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `Builder`?**
  _High betweenness centrality (0.314) - this node is a cross-community bridge._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08576576576576576 - nodes in this community are weakly interconnected._
- **Should `Breaking, Placing and Crafting` be split into smaller, more focused modules?**
  _Cohesion score 0.05348101265822785 - nodes in this community are weakly interconnected._