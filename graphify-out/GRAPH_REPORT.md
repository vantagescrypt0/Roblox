# Graph Report - Roblox  (2026-10-26)

## Corpus Check
- 116 files · ~105,178 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 814 nodes · 1919 edges · 44 communities (34 shown, 10 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 357 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- CombatService.luau
- Theme.make
- Breaking, Placing and Crafting
- WarzoneService.luau
- WorldService.luau
- replicatedstorage_shared_items
- Mechanics to Borrow
- items3d.py
- Home
- Roblox Policies
- Props.luau
- Handoff (updated 2026-10-26, session 3)
- Skills & Levels
- Economy.luau
- Decor.luau
- Tools and Workflow
- math
- Warzone
- Main.server.luau
- Trends - Oct 2026
- TownService.luau
- HotbarService.luau
- Town & Worlds
- BlockService.luau
- Main.client.luau
- Inbox
- replicatedstorage_shared_blocks
- Build.luau
- Worlds/Mining.luau
- Core Loop
- Economy & Values
- QuestService.luau
- graph_to_vault.py
- AmbientController.luau
- InventoryService.luau
- Common.luau
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
9. `BlockWorld.key()` - 18 edges
10. `Warzone` - 18 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
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

## Communities (44 total, 10 thin omitted)

### Community 0 - "CombatService.luau"
Cohesion: 0.25
Nodes (6): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing()

### Community 1 - "Theme.make"
Cohesion: 0.09
Nodes (64): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+56 more)

### Community 2 - "Breaking, Placing and Crafting"
Cohesion: 0.08
Nodes (50): Better rewards as skills level up, nearStation(), bestSeed(), blockCrop(), FarmService.Harvest(), FarmService.ShowCrop(), FarmService.Start(), heldSeed() (+42 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.30
Nodes (11): describe(), dropBag(), dropLootHead(), endRaid(), enter(), extract(), isInRaid(), onCharacterAdded() (+3 more)

### Community 5 - "replicatedstorage_shared_items"
Cohesion: 0.13
Nodes (7): Hotbar.Selected(), BagWindow.SetState(), countLabel(), render(), offered(), setOffer(), wearBar()

### Community 6 - "Mechanics to Borrow"
Cohesion: 0.09
Nodes (24): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+16 more)

### Community 7 - "items3d.py"
Cohesion: 0.07
Nodes (30): axe(), thickness(), build_items(), downscale(), handle(), hoe(), load_blocks(), main() (+22 more)

### Community 8 - "Home"
Cohesion: 0.27
Nodes (11): Pitch (Draft), Mobile-first UI, Target Audience, 100+ challenges and an island challenge ladder, Islands Feature Checklist, Beginner quest chain (13 quests, ends at level 10), Tutorial & Quests, Game name still undecided (can't reuse Islands/Skyblock/Skybounds) (+3 more)

### Community 9 - "Roblox Policies"
Cohesion: 0.24
Nodes (7): Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added), Monetization Principles

### Community 10 - "Props.luau"
Cohesion: 0.38
Nodes (4): baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents()

### Community 11 - "Handoff (updated 2026-10-26, session 3)"
Cohesion: 0.33
Nodes (5): Handoff (updated 2026-10-26, session 3), How-to notes for the next session, In progress right now: "Grand worlds" (Skybounds-scale worlds with zone islands), Published, Still open from your notes

### Community 12 - "Skills & Levels"
Cohesion: 0.24
Nodes (12): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Player level 1-50 (XP from PvE, grinding, quests), Skills & Levels, Level 10 unlocks the Warzone, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds) (+4 more)

### Community 13 - "Economy.luau"
Cohesion: 0.08
Nodes (25): Decision: click-only farming, Decision: 5-slot Minecraft-style hotbar, aim(), aimedShop(), BlockController.Start(), burst(), interact(), place() (+17 more)

### Community 14 - "Decor.luau"
Cohesion: 0.08
Nodes (48): BlockWorld.setRaw(), Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower() (+40 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "math"
Cohesion: 0.06
Nodes (62): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_tiles(), ore(), draw_zone_tiles() (+54 more)

### Community 17 - "Warzone"
Cohesion: 0.27
Nodes (10): Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds (Minecraft Skyblock server, now shut down), Loot head: your loot drops in your avatar's head on death, PvP fairness options: zones by level, new-player protection, insurance slot, Raid bag + extraction pads, Warzone (+2 more)

### Community 18 - "Main.server.luau"
Cohesion: 0.12
Nodes (5): Decision: falling off returns you to your island, Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 19 - "Trends - Oct 2026"
Cohesion: 0.25
Nodes (7): Skybounds seasons: 2-4 months, level resets, Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Seasons of 2-4 months; player level resets, What resets each season?

### Community 21 - "HotbarService.luau"
Cohesion: 0.46
Nodes (6): HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 22 - "Town & Worlds"
Cohesion: 0.29
Nodes (7): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "BlockService.luau"
Cohesion: 0.12
Nodes (6): capitalized(), TravelService.Go(), checkCell(), onPlant(), onUproot(), Leveling.PlantedTrees()

### Community 24 - "Main.client.luau"
Cohesion: 0.06
Nodes (12): greet(), NpcController.Start(), track(), update(), makeArea(), WorldService.Start(), addNameTag(), Npc.Build() (+4 more)

### Community 29 - "replicatedstorage_shared_blocks"
Cohesion: 0.27
Nodes (8): inReach(), buildArrival(), portalFields(), BlockWorld.position(), Portal.addCells(), Portal.makeClosed(), Portal.makeField(), sheet()

### Community 30 - "Build.luau"
Cohesion: 0.36
Nodes (6): set(), setFree(), Build.Fill(), Build.Set(), Build.SetFree(), pick()

### Community 32 - "Worlds/Mining.luau"
Cohesion: 0.16
Nodes (6): ctx.Noise(), mesaDistance(), inCave(), mountainHeights(), segment(), slope()

### Community 33 - "Core Loop"
Cohesion: 0.38
Nodes (7): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Skybounds Warzone (the user's favorite moment), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Decision: blend Islands + Skybounds Warzone

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "QuestService.luau"
Cohesion: 0.52
Nodes (5): checkReach(), complete(), currentQuest(), giveReward(), QuestService.Record()

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 43 - "InventoryService.luau"
Cohesion: 0.14
Nodes (18): treeFell(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn(), InventoryService.Count(), InventoryService.Remove() (+10 more)

### Community 44 - "Common.luau"
Cohesion: 0.52
Nodes (4): boardHeight(), Signs.Board(), Signs.Gateway(), Signs.Label()

### Community 46 - "CraftingWindow.luau"
Cohesion: 0.18
Nodes (15): addCamera(), halfExtents(), ItemIcon.create(), viewport(), check(), choose(), CraftingWindow.SetState(), ingredientChip() (+7 more)

### Community 47 - "Decision Log"
Cohesion: 0.15
Nodes (14): NPC visits at milestones with a starter pack, Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Warzone parked until it moves into Town, Merchant NPC at the Town market, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Decision: Minecraft-style block islands (break and place, saved) (+6 more)

## Knowledge Gaps
- **14 isolated node(s):** `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Skybounds (Minecraft Skyblock server, now shut down)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 165 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `math`?**
  _High betweenness centrality (0.314) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.08576576576576576 - nodes in this community are weakly interconnected._
- **Why does `Home` connect `Home` to `Core Loop`, `Mechanics to Borrow`, `Roblox Policies`, `Skills & Levels`, `Tools and Workflow`, `Decision Log`, `Warzone`, `Trends - Oct 2026`?**
  _High betweenness centrality (0.314) - this node is a cross-community bridge._
- **Should `Breaking, Placing and Crafting` be split into smaller, more focused modules?**
  _Cohesion score 0.07662337662337662 - nodes in this community are weakly interconnected._
- **Should `replicatedstorage_shared_items` be split into smaller, more focused modules?**
  _Cohesion score 0.1339031339031339 - nodes in this community are weakly interconnected._