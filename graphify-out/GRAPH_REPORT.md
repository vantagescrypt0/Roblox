# Graph Report - Roblox  (2026-11-03)

## Corpus Check
- 189 files · ~249,069 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 1537 nodes · 3505 edges · 101 communities (78 shown, 23 thin omitted)
- Extraction: 84% EXTRACTED · 16% INFERRED · 0% AMBIGUOUS · INFERRED: 550 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `22304ddb`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- CombatController.luau
- Theme.make
- BlockWorld.luau
- CraftingService.luau
- Signs.luau
- BagWindow.luau
- balance.py
- items3d.py
- Main.server.luau
- Warzone
- BlockService.luau
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Hud.luau
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- Builder
- Context.luau
- new_verts
- WarzoneService.luau
- FlightController.luau
- store_art.py
- Town & Worlds
- SwimController.luau
- HeldController.luau
- Inbox
- BlockController.luau
- blocks.py
- os
- HotbarService.luau
- Economy & Values
- FirstPersonController.luau
- studio_mcp.py
- AmbientController.luau
- onPlant
- IslandService.luau
- Worlds/Mining.luau
- Shapes.luau
- Mining phase: build plan (2026-10-31)
- LiquidService.luau
- Late-game proposal (2026-10-29)
- Level gates: crops need Farming level, mobs need Combat level
- Places.Current
- BlockWorld.position
- Crafting Proposal (2026-10-31, APPROVED as written the same night)
- Boards.luau
- Roadmap
- Window.luau
- Build.luau
- Warzone rebuild plan (2026-11-02)
- GearService.luau
- Main.server.luau
- gem_bench
- Farming.luau
- ChestService.luau
- Glass.text
- Kits
- build
- Slaying plan (2026-11-02, approved with your changes)
- QuestService.luau
- UI study (2026-10-29)
- Published privately as Sky Farm Prototype
- Woodcutting phase: build plan (2026-11-02)
- math
- Hotbar.luau
- Farming phase: build plan (2026-11-02)
- VitalsHud.luau
- The late-game rule (your call, 2026-11-02)
- QuestTracker.luau
- Combat & Gear Plan (2026-11-03)
- InboxService.luau
- HotbarService.luau
- sys
- Islands (Roblox)
- vitals_icons.py
- lowpoly.py
- ArmorModels.luau
- regrow
- Skybounds/README.md
- replicatedstorage_shared_remotes
- Ambience.luau
- Decision: buy bigger islands with coins (4 tiers)
- Theme.coins
- Npc.luau
- Home

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 50 edges
2. `Handoff` - 33 edges
3. `Decision Log` - 28 edges
4. `Builder` - 27 edges
5. `scene_world()` - 26 edges
6. `Theme.corner()` - 25 edges
7. `noisy()` - 24 edges
8. `part()` - 24 edges
9. `scene_icon()` - 23 edges
10. `Skills & Levels` - 23 edges

## Surprising Connections (you probably didn't know these)
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `(2026-11-03, session 10): new shield, four armour pieces, equipment in the Bag` --references--> `standStraight()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/client/Windows/BagWindow.luau
- `TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming)` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, committed as `b66c289` (harvest wear removed later in part 4)` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `NPC visits at milestones with a starter pack` --semantically_similar_to--> `Merchant NPC at the Town market`  [INFERRED] [semantically similar]
  02 Research/Islands (Roblox).md → 04 Content/Content Index.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (101 total, 23 thin omitted)

### Community 0 - "CombatController.luau"
Cohesion: 0.15
Nodes (15): aimedCharacter(), attack(), CombatController.Start(), cooldownOf(), faceTarget(), flash(), isFalling(), onHitEffect() (+7 more)

### Community 1 - "Theme.make"
Cohesion: 0.23
Nodes (31): buildGui(), Theme.badge(), Theme.bar(), Theme.button(), Theme.card(), Theme.chip(), Theme.coin(), Theme.corner() (+23 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.14
Nodes (16): IslandService.PlaceNode(), onPlayerRemoving(), BlockWorld.destroy(), BlockWorld.set(), buried(), exposed(), fits(), makePart() (+8 more)

### Community 3 - "CraftingService.luau"
Cohesion: 0.30
Nodes (11): check(), choose(), CraftingWindow.SetState(), ingredientChip(), levelOf(), render(), renderDetail(), skillChip() (+3 more)

### Community 4 - "Signs.luau"
Cohesion: 0.14
Nodes (18): cloud(), layer(), Logo.Build(), baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents(), boardHeight() (+10 more)

### Community 5 - "BagWindow.luau"
Cohesion: 0.15
Nodes (24): (2026-11-03, session 11, earlier): Night Glass on every window, shield really held, Glass.setSlot(), Glass.text(), BagWindow.SetState(), BagWindow.Start(), bonusText(), buildCrafting(), buildEquipment() (+16 more)

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.05
Nodes (27): anvil(), build_items(), carrot(), downscale(), iron_plate(), load_blocks(), loot_crate(), melon() (+19 more)

### Community 8 - "Main.server.luau"
Cohesion: 0.16
Nodes (10): nearShop(), onBuy(), onSell(), sellItem(), ShopService.Start(), TownService.GetShopkeepers(), capitalized(), TravelService.Go() (+2 more)

### Community 9 - "Warzone"
Cohesion: 0.18
Nodes (10): Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added), Seasonal Warzone maps and loot tables, PvP fairness options: zones by level, new-player protection, insurance slot (+2 more)

### Community 10 - "BlockService.luau"
Cohesion: 0.08
Nodes (6): inReach(), treeFell(), nearStation(), onOpen(), unlockedBy(), LootCrates.Roll()

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.07
Nodes (31): (2026-10-31 ~22:45, session 7): published scooping, swimming done, crafting approved, (2026-10-31 night): scooping restored, committed, NOT published, (2026-11-01 ~21:30, session 7): crafting + Mining phase tested, committed and PUBLISHED, store art live, (2026-11-02, session 8, earlier): Woodcutting phase built and playtested, (2026-11-02, session 8, last): the Warzone prototype was rejected, (2026-11-02, session 8): late-game rework, Warzone and billion-coin scale tested in Studio; NOT committed, NOT published, (2026-11-02, session 9): the real Warzone map is built, Done: Town redesign (name: **SKYBLOX**, your call 2026-10-26) (+23 more)

### Community 12 - "Hud.luau"
Cohesion: 0.16
Nodes (18): buildCelebration(), buildMenu(), buildStatus(), buildToasts(), drawMenuBars(), fadeLabel(), Hud.Celebrate(), Hud.Render() (+10 more)

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.14
Nodes (6): doneCount(), stateOf(), CrateWindow.SetState(), refresh(), offered(), setOffer()

### Community 14 - "Decor.luau"
Cohesion: 0.16
Nodes (28): Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus(), Decor.Falling(), Decor.Fence(), Decor.Flower(), Decor.FlowerBox() (+20 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.19
Nodes (13): Blender driven by Python scripts, ProfileStore (player data with session locking), Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import (+5 more)

### Community 16 - "Builder"
Cohesion: 0.19
Nodes (12): build_icon_models(), Builder, marker(), matrix(), swatch_uv(), crops(), far_crops(), main() (+4 more)

### Community 17 - "Context.luau"
Cohesion: 0.17
Nodes (23): Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path(), Common.Pond() (+15 more)

### Community 18 - "new_verts"
Cohesion: 0.09
Nodes (18): arc(), axe(), thickness(), front_slab(), handle(), hoe(), new_verts(), pickaxe() (+10 more)

### Community 19 - "WarzoneService.luau"
Cohesion: 0.11
Nodes (38): humanoidOf(), onSprint(), SprintService.Start(), SprintService.Stop(), tooHungry(), endRun(), finishLeaving(), humanoidOf() (+30 more)

### Community 20 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 21 - "store_art.py"
Cohesion: 0.07
Nodes (53): add_mesh(), anvil_mesh(), Assets, blur(), box(), camera(), caption(), cave_shell() (+45 more)

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "SwimController.luau"
Cohesion: 0.33
Nodes (10): add(), anyDown(), characterParts(), columnSurface(), over(), startSwimming(), step(), stopSwimming() (+2 more)

### Community 24 - "HeldController.luau"
Cohesion: 0.14
Nodes (12): swing(), HeldController.Holding(), HeldController.Start(), HeldController.Swing(), moveHeld(), ownHeld(), restOf(), templateFor() (+4 more)

### Community 29 - "BlockController.luau"
Cohesion: 0.33
Nodes (8): Decision: click-only farming, aim(), aimedLootChest(), aimedShop(), rootPosition(), screenRay(), shopkeepers(), workArea()

### Community 30 - "blocks.py"
Cohesion: 0.11
Nodes (34): bricks_tile(), build_atlas(), clamp(), draw_building_tiles(), planks_tile(), draw_deep_ore_tiles(), clumps(), crystals() (+26 more)

### Community 32 - "os"
Cohesion: 0.22
Nodes (18): export_fbx(), hex_rgb(), material(), mesh_object(), render_preview(), reset_scene(), save_blend(), main() (+10 more)

### Community 33 - "HotbarService.luau"
Cohesion: 0.08
Nodes (15): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), Economy.Total(), Economy.Value(), work(), Inventory.Across() (+7 more)

### Community 34 - "Economy & Values"
Cohesion: 0.22
Nodes (9): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The billion scale (your call, 2026-11-02), The rules, Tools (new, full durability), Trading between players (+1 more)

### Community 37 - "FirstPersonController.luau"
Cohesion: 0.31
Nodes (12): add(), addArm(), addHeld(), build(), clearRig(), copyOf(), hideReal(), keyFor() (+4 more)

### Community 39 - "studio_mcp.py"
Cohesion: 0.14
Nodes (9): main(), merge_color_groups(), real_notes(), is_published(), main(), pick_target(), Server, studio_list() (+1 more)

### Community 41 - "onPlant"
Cohesion: 0.17
Nodes (9): Better rewards as skills level up, IslandService.PlantedCount(), IslandService.TreeLog(), IslandService.TreeMinutes(), ProgressionService.AddPlayerXP(), checkCell(), onPlant(), Leveling.PlantedTrees() (+1 more)

### Community 42 - "IslandService.luau"
Cohesion: 0.13
Nodes (26): (session 6) islands as build areas DONE in Studio, Decision: falling off returns you to your island, islandArea(), announce(), build(), clampTier(), fell(), generate() (+18 more)

### Community 43 - "Worlds/Mining.luau"
Cohesion: 0.13
Nodes (11): ctx.Noise(), hillHeight(), roughDistance(), chamber(), ck(), findCaves(), mountainHeights(), rough() (+3 more)

### Community 45 - "Shapes.luau"
Cohesion: 0.15
Nodes (6): Shapes.Glow(), Shapes.Light(), beacon(), strip(), trafficCone(), v3()

### Community 46 - "Mining phase: build plan (2026-10-31)"
Cohesion: 0.29
Nodes (7): Art, Mining phase: build plan (2026-10-31), Order, Slivers and nodes, The deep cave (Worlds/Mining.luau), The ores (the deep cave, under the Gold Chamber), Tool tiers and parts (from the Crafting Proposal)

### Community 48 - "LiquidService.luau"
Cohesion: 0.24
Nodes (4): liquidAt(), touches(), LiquidModels.Make(), make()

### Community 52 - "Late-game proposal (2026-10-29)"
Cohesion: 0.22
Nodes (9): 1. New resources (13), 2. New tool tiers (2, x 5 kinds = 10 tools), 3. Big things to buy (10M–50M), 4. The order to build it in, Farming: four new zone islands (4), Late-game proposal (2026-10-29), Mining: a deeper cave under the Gold Chamber (5), Questions (+1 more)

### Community 53 - "Level gates: crops need Farming level, mobs need Combat level"
Cohesion: 0.40
Nodes (5): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5)

### Community 54 - "Places.Current"
Cohesion: 0.22
Nodes (8): fadeTo(), MusicController.Start(), newSound(), greet(), NpcController.Start(), track(), update(), Places.Current()

### Community 55 - "BlockWorld.position"
Cohesion: 0.43
Nodes (7): buildArrival(), portalFields(), BlockWorld.position(), Portal.addCells(), Portal.makeClosed(), Portal.makeField(), sheet()

### Community 56 - "Crafting Proposal (2026-10-31, APPROVED as written the same night)"
Cohesion: 0.33
Nodes (6): Crafting Proposal (2026-10-31, APPROVED as written the same night), New stations, Questions, The ladder, The rule, What it adds

### Community 57 - "Boards.luau"
Cohesion: 0.40
Nodes (4): boardsState(), Boards.CurrentIndex(), c(), rewardCoins()

### Community 58 - "Roadmap"
Cohesion: 0.16
Nodes (15): NPC visits at milestones with a starter pack, Gear references, Warzone parked until it moves into Town, Content Index, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Decision Log (+7 more)

### Community 59 - "Window.luau"
Cohesion: 0.12
Nodes (20): setBlur(), Window.clear(), Window.close(), Window.new(), Window.open(), Window.setTitle(), Window.toggle(), BagWindow.Toggle() (+12 more)

### Community 60 - "Build.luau"
Cohesion: 0.19
Nodes (10): set(), setFree(), top(), BlockWorld.setRaw(), Build.Fill(), Build.Set(), Build.SetFree(), Build.Top() (+2 more)

### Community 61 - "Warzone rebuild plan (2026-11-02)"
Cohesion: 0.13
Nodes (13): Details seen in the photos (looked at closely 2026-11-02), Five maps, one theme each, The Skybounds Warzones, built by Team Vaeron, What they all share, What this means for our Warzone, 1. The map: Robot / sci-fi (built and walked in Studio, 2026-11-02), 2. Warzone rules, 3. Inventory and chests, whole game (+5 more)

### Community 62 - "GearService.luau"
Cohesion: 0.18
Nodes (7): (2026-11-03, session 10): new shield, four armour pieces, equipment in the Bag, checkOwned(), GearService.Start(), removePet(), spawnPet(), splitOldArmor(), PetModels.Build()

### Community 63 - "Main.server.luau"
Cohesion: 0.10
Nodes (6): PvP only when both players are in the Warzone, blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual()

### Community 65 - "Farming.luau"
Cohesion: 0.36
Nodes (7): crossPathZ(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), veggiePathZ(), wave()

### Community 66 - "ChestService.luau"
Cohesion: 0.12
Nodes (16): changed(), ChestService.CloseAll(), ChestService.Open(), closeFor(), isIndex(), placeOf(), send(), findSpot() (+8 more)

### Community 67 - "Glass.text"
Cohesion: 0.18
Nodes (13): build(), edge(), Glass.button(), Glass.card(), Glass.glow(), Glass.inset(), Glass.stage(), addCamera() (+5 more)

### Community 68 - "Kits"
Cohesion: 0.33
Nodes (6): Kits, Our version (proposal), Rule to design around, Still to decide, The other Skybounds kits, for reference, What Looter was in Skybounds

### Community 69 - "build"
Cohesion: 0.20
Nodes (13): buildMap(), build(), makeArea(), WorldService.Start(), BlockWorld.drawAll(), BlockWorld.partCount(), Pace.Begin(), Pace.Finish() (+5 more)

### Community 71 - "Slaying plan (2026-11-02, approved with your changes)"
Cohesion: 0.50
Nodes (4): Slaying plan (2026-11-02, approved with your changes), The idea, What comes with it, Zones and monsters

### Community 72 - "QuestService.luau"
Cohesion: 0.26
Nodes (8): boardCurrent(), checkReach(), complete(), completeBoard(), currentQuest(), giveReward(), QuestService.Record(), reachValue()

### Community 73 - "UI study (2026-10-29)"
Cohesion: 0.50
Nodes (4): Proposed Skycore style (combining them), Shared lessons, UI study (2026-10-29), What each does well

### Community 74 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 75 - "Woodcutting phase: build plan (2026-11-02)"
Cohesion: 0.33
Nodes (6): New blocks, Order, Slivers and nodes, The trees, What isn't in this phase, Woodcutting phase: build plan (2026-11-02)

### Community 76 - "math"
Cohesion: 0.12
Nodes (15): build_tier(), leaves(), outline(), plot_positions(), radius_at(), ring(), rock(), tree() (+7 more)

### Community 77 - "Hotbar.luau"
Cohesion: 0.29
Nodes (9): Decision: 5-slot Minecraft-style hotbar, FirstPersonController.Start(), setForced(), HeldController.OnSwing(), Hotbar.Select(), Hotbar.Selected(), Hotbar.SelectedItem(), showName() (+1 more)

### Community 78 - "Farming phase: build plan (2026-11-02)"
Cohesion: 0.40
Nodes (5): Farming phase: build plan (2026-11-02), Ruby and Starsteel tools (built in the same pass), Seeds come from slivers, The crops, The skill-curve refit

### Community 79 - "VitalsHud.luau"
Cohesion: 0.25
Nodes (7): Hotbar.Bar(), fill(), makeRow(), setCell(), VitalsHud.SetState(), VitalsHud.Start(), Combat.Armor()

### Community 80 - "The late-game rule (your call, 2026-11-02)"
Cohesion: 0.50
Nodes (4): How you get things, The coin targets: settled, The late-game rule (your call, 2026-11-02), What this changed

### Community 81 - "QuestTracker.luau"
Cohesion: 0.20
Nodes (5): keyLabel(), PromptUI.Start(), show(), aimHighlight(), QuestTracker.Render()

### Community 82 - "Combat & Gear Plan (2026-11-03)"
Cohesion: 0.22
Nodes (9): Armour art, Armour numbers, Combat & Gear Plan (2026-11-03), Combat: real Minecraft rules, First person, Health, armour and hunger on screen, Sprinting, The sword system (+1 more)

### Community 83 - "InboxService.luau"
Cohesion: 0.43
Nodes (5): clean(), deliver(), InboxService.Send(), InboxService.Start(), onOverflow()

### Community 84 - "HotbarService.luau"
Cohesion: 0.33
Nodes (8): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isIndex(), onMoveStack(), onQuickMove(), onSelectSlot(), refreshHeld()

### Community 85 - "sys"
Cohesion: 0.28
Nodes (3): face(), main(), save()

### Community 86 - "Islands (Roblox)"
Cohesion: 0.09
Nodes (20): Design Pillars, Pitch: own a floating island, drop into a shared Warzone, bring loot home, Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns (+12 more)

### Community 87 - "vitals_icons.py"
Cohesion: 0.31
Nodes (3): icon(), main(), write_png()

### Community 88 - "lowpoly.py"
Cohesion: 0.47
Nodes (3): _hex(), palette_image(), palette_material()

### Community 89 - "ArmorModels.luau"
Cohesion: 0.18
Nodes (17): addEffects(), ArmorModels.Apply(), hideHeadwear(), meshPart(), setHidden(), tintFor(), anvil(), blockPiece() (+9 more)

### Community 90 - "regrow"
Cohesion: 0.60
Nodes (5): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, respawnNodes(), regrow(), BlockWorld.get(), BlockWorld.occupied()

### Community 92 - "replicatedstorage_shared_remotes"
Cohesion: 0.20
Nodes (8): Trading shut down after a duplication exploit [Unverified], lean(), moving(), SprintController.Start(), listOf(), render(), renderCarried(), shownStack()

### Community 93 - "Ambience.luau"
Cohesion: 0.83
Nodes (3): Ambience.Apply(), Ambience.Warzone(), ensure()

### Community 97 - "Home"
Cohesion: 0.12
Nodes (35): Pitch (Draft), Mobile-first UI, Target Audience, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds: your head drops on death with your loot, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets (+27 more)

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 403 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `regrow` to `Handoff (updated 2026-10-27 ~22:35, session 4)`, `blocks.py`?**
  _High betweenness centrality (0.297) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Theme.make()` (e.g. with `buildGui()` and `buildCelebration()`) actually correct?**
  _`Theme.make()` has 33 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `BlockWorld.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `regrow`, `math`?**
  _High betweenness centrality (0.293) - this node is a cross-community bridge._
- **Should `Signs.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.13846153846153847 - nodes in this community are weakly interconnected._
- **Why does `respawnNodes()` connect `regrow` to `IslandService.luau`, `BlockWorld.luau`?**
  _High betweenness centrality (0.133) - this node is a cross-community bridge._