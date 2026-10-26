# Graph Report - Roblox  (2026-10-26)

## Corpus Check
- 117 files · ~105,906 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 823 nodes · 1937 edges · 45 communities (35 shown, 10 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 357 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Context.luau
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- WorldService.luau
- replicatedstorage_shared_items
- Mechanics to Borrow
- items3d.py
- Home
- Warzone
- Handoff (updated 2026-10-26, session 3)
- Skills & Levels
- Economy.luau
- Decor.luau
- Tools and Workflow
- math
- FarmService.luau
- Mechanics to Borrow
- Trends - Oct 2026
- HotbarService.luau
- Town & Worlds
- BlockService.luau
- Main.client.luau
- Inbox
- replicatedstorage_shared_blocks
- Build.luau
- Worlds/Mining.luau
- FlightController.luau
- Economy & Values
- QuestService.luau
- Leveling.luau
- graph_to_vault.py
- AmbientController.luau
- build
- InventoryService.luau
- CraftingWindow.luau
- Merchant NPC at the Town market

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
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md
- `Key-gated adventure islands` --semantically_similar_to--> `Warzone-only keys/materials unlock island tiers`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 03 Design/Mechanics to Borrow.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (45 total, 10 thin omitted)

### Community 0 - "Context.luau"
Cohesion: 0.16
Nodes (18): cellCentre(), Common.Forest(), Common.Lamp(), Common.Path(), Common.Pond(), Common.Scatter(), Common.Signpost(), Common.ZoneGate() (+10 more)

### Community 1 - "Theme.make"
Cohesion: 0.11
Nodes (55): Hotbar.Start(), buildButtons(), buildCelebration(), buildProfile(), buildRaidBanner(), buildToasts(), fadeLabel(), Hud.Celebrate() (+47 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.18
Nodes (21): nearStation(), regrow(), BlockWorld.drawAll(), BlockWorld.hasNeighbour(), BlockWorld.key(), BlockWorld.occupied(), BlockWorld.part(), BlockWorld.set() (+13 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.14
Nodes (17): PvP only when both players are in the Warzone, CombatService.Equip(), currentTool(), makeHandle(), makeTool(), swing(), describe(), dropBag() (+9 more)

### Community 4 - "WorldService.luau"
Cohesion: 0.11
Nodes (3): Decision: falling off returns you to your island, notice(), onFarmClick()

### Community 5 - "replicatedstorage_shared_items"
Cohesion: 0.14
Nodes (7): BagWindow.SetState(), countLabel(), render(), IslandWindow.SetState(), offered(), setOffer(), wearBar()

### Community 6 - "Mechanics to Borrow"
Cohesion: 0.12
Nodes (14): Design Pillars, Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Token-summoned bosses with cooldowns, Skill-gated vending machines and handshake trading, Anti-Burnout Ideas (+6 more)

### Community 7 - "items3d.py"
Cohesion: 0.06
Nodes (30): axe(), thickness(), carrot(), downscale(), handle(), hoe(), load_blocks(), melon() (+22 more)

### Community 8 - "Home"
Cohesion: 0.21
Nodes (16): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+8 more)

### Community 9 - "Warzone"
Cohesion: 0.15
Nodes (18): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+10 more)

### Community 11 - "Handoff (updated 2026-10-26, session 3)"
Cohesion: 0.33
Nodes (5): Handoff (updated 2026-10-26, session 3), How-to notes for the next session, In progress right now: "Grand worlds" (Skybounds-scale worlds with zone islands), Published, Still open from your notes

### Community 12 - "Skills & Levels"
Cohesion: 0.28
Nodes (10): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5), Prototype phase (current) (+2 more)

### Community 13 - "Economy.luau"
Cohesion: 0.06
Nodes (30): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: click-only farming, Decision: 5-slot Minecraft-style hotbar, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), aim(), aimedShop() (+22 more)

### Community 14 - "Decor.luau"
Cohesion: 0.11
Nodes (31): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+23 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.17
Nodes (14): Trading shut down after a duplication exploit [Unverified], Blender driven by Python scripts, ProfileStore (player data with session locking), Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes (+6 more)

### Community 16 - "math"
Cohesion: 0.06
Nodes (62): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_tiles(), ore(), draw_zone_tiles() (+54 more)

### Community 17 - "FarmService.luau"
Cohesion: 0.25
Nodes (17): bestSeed(), blockCrop(), FarmService.Harvest(), FarmService.ShowCrop(), FarmService.Start(), heldSeed(), heldTool(), makePlot() (+9 more)

### Community 19 - "Mechanics to Borrow"
Cohesion: 0.15
Nodes (14): Key-gated adventure islands, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down), Skybounds Warzone (the user's favorite moment), Item leveling: gear grows the more you use it (+6 more)

### Community 20 - "Trends - Oct 2026"
Cohesion: 0.22
Nodes (8): Totems: passive resource generators with a range, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers, Passive generators with a range limit

### Community 21 - "HotbarService.luau"
Cohesion: 0.46
Nodes (6): HotbarService.GetHeldItem(), HotbarService.Start(), isSlot(), onSelectSlot(), onSetHotbar(), refreshHeld()

### Community 22 - "Town & Worlds"
Cohesion: 0.29
Nodes (7): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "BlockService.luau"
Cohesion: 0.10
Nodes (10): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access, inReach(), capitalized(), TravelService.Go(), checkCell() (+2 more)

### Community 24 - "Main.client.luau"
Cohesion: 0.06
Nodes (12): greet(), NpcController.Start(), track(), update(), makeArea(), WorldService.Start(), addNameTag(), Npc.Build() (+4 more)

### Community 29 - "replicatedstorage_shared_blocks"
Cohesion: 0.21
Nodes (12): buildArrival(), portalFields(), BlockWorld.position(), Portal.addCells(), Portal.makeClosed(), Portal.makeField(), sheet(), boardHeight() (+4 more)

### Community 30 - "Build.luau"
Cohesion: 0.18
Nodes (11): set(), setFree(), top(), BlockWorld.get(), BlockWorld.setRaw(), Build.Fill(), Build.Set(), Build.SetFree() (+3 more)

### Community 32 - "Worlds/Mining.luau"
Cohesion: 0.18
Nodes (6): ctx.Noise(), mesaDistance(), inCave(), mountainHeights(), segment(), slope()

### Community 33 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 34 - "Economy & Values"
Cohesion: 0.29
Nodes (7): Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "QuestService.luau"
Cohesion: 0.52
Nodes (5): checkReach(), complete(), currentQuest(), giveReward(), QuestService.Record()

### Community 38 - "Leveling.luau"
Cohesion: 0.29
Nodes (6): Better rewards as skills level up, ProgressionService.AddPlayerXP(), Leveling.BonusChance(), Leveling.PlantedTrees(), Leveling.TilledPlots(), Leveling.XPToNext()

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 41 - "build"
Cohesion: 0.33
Nodes (6): build(), Ambience.Apply(), ensure(), BlockWorld.new(), BlockWorld.partCount(), ctx.Flatten()

### Community 43 - "InventoryService.luau"
Cohesion: 0.13
Nodes (18): treeFell(), autoHotbar(), clearIfEmpty(), InventoryService.Add(), InventoryService.AddCoins(), InventoryService.AddWorn(), InventoryService.Count(), InventoryService.Remove() (+10 more)

### Community 46 - "CraftingWindow.luau"
Cohesion: 0.12
Nodes (23): addCamera(), halfExtents(), ItemIcon.create(), viewport(), Window.clear(), Window.close(), Window.open(), Window.toggle() (+15 more)

### Community 47 - "Merchant NPC at the Town market"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

## Knowledge Gaps
- **14 isolated node(s):** `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Skybounds (Minecraft Skyblock server, now shut down)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 166 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Home` connect `Home` to `Mechanics to Borrow`, `Warzone`, `Skills & Levels`, `Tools and Workflow`, `Mechanics to Borrow`, `Trends - Oct 2026`?**
  _High betweenness centrality (0.312) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildButtons()`) actually correct?**
  _`Theme.make()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.10957501280081926 - nodes in this community are weakly interconnected._
- **Why does `Block pipeline: 16x16 pixel tiles -> atlas -> 3-stud cubes` connect `Tools and Workflow` to `math`?**
  _High betweenness centrality (0.311) - this node is a cross-community bridge._
- **Should `WarzoneService.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.14333333333333334 - nodes in this community are weakly interconnected._
- **Should `WorldService.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.10869565217391304 - nodes in this community are weakly interconnected._