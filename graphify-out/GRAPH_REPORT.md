# Graph Report - Roblox  (2026-10-25)

## Corpus Check
- 107 files · ~74,562 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 687 nodes · 1631 edges · 38 communities (27 shown, 11 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 315 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Builder
- Theme.make
- Breaking, Placing and Crafting
- WarzoneService.luau
- WorldService.luau
- CraftingWindow.luau
- Mechanics to Borrow
- items3d.py
- Home
- Warzone
- Props.luau
- Handoff (updated 2026-10-25)
- Skills & Levels
- Economy.luau
- Tools and Workflow
- replicatedstorage_shared_blocks
- Roadmap
- Warzone
- Anti-Burnout Ideas
- TownService.luau
- Town & Worlds
- BlockService.luau
- Main.client.luau
- Inbox
- Trends - Oct 2026
- TravelService.luau
- Spawning.luau
- Published privately as Sky Farm Prototype
- Economy & Values
- graph_to_vault.py

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 38 edges
2. `Builder` - 24 edges
3. `Home` - 23 edges
4. `Skills & Levels` - 22 edges
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

## Communities (38 total, 11 thin omitted)

### Community 0 - "Builder"
Cohesion: 0.07
Nodes (50): build_atlas(), clamp(), draw_tiles(), ore(), fill(), main(), make_block(), noisy() (+42 more)

### Community 1 - "Theme.make"
Cohesion: 0.09
Nodes (64): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+56 more)

### Community 2 - "Breaking, Placing and Crafting"
Cohesion: 0.05
Nodes (69): Better rewards as skills level up, inReach(), isCell(), onBreak(), onPlace(), treeFell(), nearStation(), bestSeed() (+61 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.14
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 4 - "WorldService.luau"
Cohesion: 0.18
Nodes (3): Decision: falling off returns you to your island, edgeRadius(), inside()

### Community 5 - "CraftingWindow.luau"
Cohesion: 0.07
Nodes (29): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.Selected(), Hotbar.SelectedItem(), Hotbar.SetState(), render(), showName(), slotX() (+21 more)

### Community 6 - "Mechanics to Borrow"
Cohesion: 0.13
Nodes (15): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+7 more)

### Community 7 - "items3d.py"
Cohesion: 0.07
Nodes (28): axe(), thickness(), carrot(), downscale(), handle(), hoe(), load_blocks(), new_verts() (+20 more)

### Community 8 - "Home"
Cohesion: 0.20
Nodes (17): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Skybounds Warzone (the user's favorite moment), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist (+9 more)

### Community 9 - "Warzone"
Cohesion: 0.20
Nodes (11): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+3 more)

### Community 10 - "Props.luau"
Cohesion: 0.47
Nodes (3): baseOf(), Props.Place(), Props.WorldExtents()

### Community 11 - "Handoff (updated 2026-10-25)"
Cohesion: 0.25
Nodes (8): Done this session (2026-10-25), Earlier (2026-10-24), Handoff (updated 2026-10-25), How-to notes for the next session, In progress right now (started 2026-10-25, session 2), Next up (from the Roadmap) — needs your call, Not published yet (needs your "publish"), Open questions for you

### Community 12 - "Skills & Levels"
Cohesion: 0.26
Nodes (10): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5), Prototype phase (current) (+2 more)

### Community 13 - "Economy.luau"
Cohesion: 0.08
Nodes (23): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: click-only farming, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), aim(), aimedShop(), BlockController.Start() (+15 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "replicatedstorage_shared_blocks"
Cohesion: 0.33
Nodes (4): signBoard(), Props.FaceToward(), Signs.Board(), Signs.Label()

### Community 17 - "Roadmap"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

### Community 19 - "Warzone"
Cohesion: 0.24
Nodes (11): 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Loot head: your loot drops in your avatar's head on death, PvP fairness options: zones by level, new-player protection, insurance slot, Raid bag + extraction pads (+3 more)

### Community 20 - "Anti-Burnout Ideas"
Cohesion: 0.25
Nodes (7): Skill-gated vending machines and handshake trading, Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Prestige with real unlocks, Seasonal Warzone maps and loot tables, Decision: buy bigger islands with coins (4 tiers)

### Community 21 - "TownService.luau"
Cohesion: 0.12
Nodes (6): ShopService.Start(), lamp(), part(), setFree(), TownService.GetShopkeepers(), Prompts.Create()

### Community 22 - "Town & Worlds"
Cohesion: 0.40
Nodes (5): Not done yet, Research: how the hubs we're borrowing from look, The resource worlds, The Town (hub), Town & Worlds

### Community 23 - "BlockService.luau"
Cohesion: 0.22
Nodes (3): checkCell(), onPlant(), onUproot()

### Community 24 - "Main.client.luau"
Cohesion: 0.07
Nodes (13): greet(), NpcController.Start(), track(), update(), HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot() (+5 more)

### Community 29 - "Trends - Oct 2026"
Cohesion: 0.15
Nodes (11): Skybounds seasons: 2-4 months, level resets, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers, Player level 1-50 (XP from PvE, grinding, quests) (+3 more)

### Community 33 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

## Knowledge Gaps
- **14 isolated node(s):** `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Sync the vault with GitHub Desktop (pull before, push after)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 141 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Home` to `Mechanics to Borrow`, `Warzone`, `Skills & Levels`, `Tools and Workflow`, `Warzone`, `Anti-Burnout Ideas`, `Trends - Oct 2026`?**
  _High betweenness centrality (0.332) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Builder` be split into smaller, more focused modules?**
  _Cohesion score 0.07004103967168263 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `Builder`?**
  _High betweenness centrality (0.325) - this node is a cross-community bridge._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08576576576576576 - nodes in this community are weakly interconnected._
- **Should `Breaking, Placing and Crafting` be split into smaller, more focused modules?**
  _Cohesion score 0.05443037974683544 - nodes in this community are weakly interconnected._