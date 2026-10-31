# Graph Report - Roblox  (2026-10-31)

## Corpus Check
- 141 files · ~159,629 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 1022 nodes · 2326 edges · 52 communities (36 shown, 16 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 422 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8ea73be5`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Islands (Roblox)
- Theme.make
- BlockWorld.luau
- WarzoneService.luau
- Context.luau
- Decision: block toughness + tool power (Minecraft rules)
- balance.py
- items3d.py
- Main.server.luau
- Monetization Principles
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Skills & Levels
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- math
- CraftingWindow.luau
- CombatService.luau
- TrophyModels.luau
- FlightController.luau
- Town & Worlds
- Open Questions
- Decision Log
- Inbox
- Signs.luau
- QuestService.luau
- Skybounds (Minecraft)
- BlockController.luau
- Economy & Values
- Published privately as Sky Farm Prototype
- graph_to_vault.py
- AmbientController.luau
- FarmService.luau
- Npc.luau
- InboxService.luau
- BlockService.luau
- Late-game proposal (2026-10-29)
- Loot head: your loot drops in your avatar's head on death
- Crafting Proposal (2026-10-31, waiting for your OK)
- Boards.luau

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 45 edges
2. `Builder` - 25 edges
3. `Theme.corner()` - 24 edges
4. `part()` - 24 edges
5. `Theme.stroke()` - 23 edges
6. `Home` - 23 edges
7. `Theme.text()` - 22 edges
8. `Skills & Levels` - 22 edges
9. `Handoff (updated 2026-10-29 ~21:50, session 5)` - 20 edges
10. `Warzone` - 20 edges

## Surprising Connections (you probably didn't know these)
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming)` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, committed as `b66c289` (harvest wear removed later in part 4)` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Fly tokens: tradeable timed power` --semantically_similar_to--> `Item leveling: gear grows the more you use it`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Mechanics to Borrow.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (52 total, 16 thin omitted)

### Community 0 - "Islands (Roblox)"
Cohesion: 0.09
Nodes (24): Design Pillars, Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+16 more)

### Community 1 - "Theme.make"
Cohesion: 0.06
Nodes (85): Hotbar.Start(), buildCelebration(), buildMenu(), buildRaidBanner(), buildStatus(), buildToasts(), drawMenuBars(), fadeLabel() (+77 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.05
Nodes (50): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, inReach(), nearStation(), set(), setFree(), top(), build(), buildArrival() (+42 more)

### Community 3 - "WarzoneService.luau"
Cohesion: 0.24
Nodes (13): PvP only when both players are in the Warzone, swing(), describe(), dropBag(), dropLootHead(), endRaid(), enter(), extract() (+5 more)

### Community 4 - "Context.luau"
Cohesion: 0.07
Nodes (18): ctx.Noise(), crossPathZ(), hillHeight(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), roughDistance() (+10 more)

### Community 5 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.10
Nodes (8): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), Economy.Total(), Economy.Value(), work(), Mining.BreakTime()

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.05
Nodes (36): arc(), axe(), thickness(), bucket(), carrot(), downscale(), front_slab(), handle() (+28 more)

### Community 9 - "Monetization Principles"
Cohesion: 0.19
Nodes (16): Mobile-first UI, Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added) (+8 more)

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.10
Nodes (21): Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26), Earlier today (session 6): UI restyle DONE in Studio, NOT committed, NOT published, Earlier today: the 4x pass — Town and the Grinding Worlds, Handoff (updated 2026-10-29 ~21:50, session 5), How-to notes, Later, Leftovers, NOW (2026-10-28 night): skill challenges + beginner challenges board (phase 1 done, NOT committed/published) (+13 more)

### Community 12 - "Skills & Levels"
Cohesion: 0.26
Nodes (10): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5), Prototype phase (current) (+2 more)

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.12
Nodes (4): doneCount(), stateOf(), offered(), setOffer()

### Community 14 - "Decor.luau"
Cohesion: 0.08
Nodes (50): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+42 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "math"
Cohesion: 0.05
Nodes (65): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_node_tiles(), draw_reference_tiles(), draw_tiles() (+57 more)

### Community 17 - "CraftingWindow.luau"
Cohesion: 0.22
Nodes (9): check(), choose(), CraftingWindow.SetState(), ingredientChip(), render(), renderDetail(), unlockedBy(), Skills.Check() (+1 more)

### Community 18 - "CombatService.luau"
Cohesion: 0.36
Nodes (4): CombatService.Equip(), currentTool(), makeHandle(), makeTool()

### Community 19 - "TrophyModels.luau"
Cohesion: 0.73
Nodes (5): build(), emblem(), piece(), TrophyModels.Make(), weld()

### Community 20 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "Open Questions"
Cohesion: 0.27
Nodes (10): Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Core Loop, Island loop: gather, craft, expand, automate, earn offline, Island (safe) <-> Warzone (risky) loop, Warzone loop: gear up, drop in, loot, survive, extract, Islands Feature Checklist, Decision: blend Islands + Skybounds Warzone (+2 more)

### Community 24 - "Decision Log"
Cohesion: 0.13
Nodes (15): NPC visits at milestones with a starter pack, Proposed Skyblox style (combining them), Shared lessons, UI study (2026-10-29), What each does well, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: falling off returns you to your island (+7 more)

### Community 29 - "Signs.luau"
Cohesion: 0.14
Nodes (18): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+10 more)

### Community 30 - "QuestService.luau"
Cohesion: 0.05
Nodes (49): Better rewards as skills level up, greet(), NpcController.Start(), track(), update(), treeFell(), bestSeed(), heldTool() (+41 more)

### Community 32 - "Skybounds (Minecraft)"
Cohesion: 0.15
Nodes (12): Full albums (sent 2026-10-28, from imgur), Skybounds reference shots, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down), Skybounds Warzone (the user's favorite moment) (+4 more)

### Community 33 - "BlockController.luau"
Cohesion: 0.07
Nodes (21): Decision: click-only farming, Decision: 5-slot Minecraft-style hotbar, aim(), aimedShop(), BlockController.Start(), burst(), interact(), place() (+13 more)

### Community 34 - "Economy & Values"
Cohesion: 0.25
Nodes (8): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The rules, Tools (new, full durability), Trading between players, Value table

### Community 37 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 39 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 42 - "FarmService.luau"
Cohesion: 0.60
Nodes (5): blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual()

### Community 47 - "Npc.luau"
Cohesion: 0.20
Nodes (5): addNameTag(), Npc.Build(), slung(), PetModels.Build(), add()

### Community 48 - "InboxService.luau"
Cohesion: 0.60
Nodes (4): clean(), deliver(), InboxService.Send(), InboxService.Start()

### Community 50 - "BlockService.luau"
Cohesion: 0.11
Nodes (4): liquidAt(), touches(), LiquidModels.Make(), make()

### Community 52 - "Late-game proposal (2026-10-29)"
Cohesion: 0.22
Nodes (9): 1. New resources (13), 2. New tool tiers (2, x 5 kinds = 10 tools), 3. Big things to buy (10M–50M), 4. The order to build it in, Farming: four new zone islands (4), Late-game proposal (2026-10-29), Mining: a deeper cave under the Gold Chamber (5), Questions (+1 more)

### Community 55 - "Loot head: your loot drops in your avatar's head on death"
Cohesion: 0.25
Nodes (8): Skybounds: your head drops on death with your loot, Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Loot head: your loot drops in your avatar's head on death, Raid bag + extraction pads, Loot head rules: how much, who opens first, despawn

### Community 58 - "Crafting Proposal (2026-10-31, waiting for your OK)"
Cohesion: 0.29
Nodes (6): Crafting Proposal (2026-10-31, waiting for your OK), New stations, Questions, The ladder, The rule, What it adds

## Knowledge Gaps
- **14 isolated node(s):** `Conveyor factories (splitters, filters, sensors)`, `Hidden fossil collection quests`, `Token-summoned bosses with cooldowns`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 252 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `BlockWorld.luau` to `math`, `Handoff (updated 2026-10-27 ~22:35, session 4)`?**
  _High betweenness centrality (0.273) - this node is a cross-community bridge._
- **Are the 28 inferred relationships involving `Theme.make()` (e.g. with `Hotbar.Start()` and `buildCelebration()`) actually correct?**
  _`Theme.make()` has 28 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Conveyor factories (splitters, filters, sensors)`, `Hidden fossil collection quests`, `Token-summoned bosses with cooldowns` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Islands (Roblox)` be split into smaller, more focused modules?**
  _Cohesion score 0.08735632183908046 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `math` to `BlockWorld.luau`?**
  _High betweenness centrality (0.269) - this node is a cross-community bridge._
- **Are the 12 inferred relationships involving `Theme.corner()` (e.g. with `Hotbar.Start()` and `buildRaidBanner()`) actually correct?**
  _`Theme.corner()` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Should `Theme.make` be split into smaller, more focused modules?**
  _Cohesion score 0.06231799650553291 - nodes in this community are weakly interconnected._