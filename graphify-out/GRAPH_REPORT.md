# Graph Report - Roblox  (2026-11-08)

## Corpus Check
- 210 files · ~285,280 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 1815 nodes · 4098 edges · 126 communities (87 shown, 39 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 697 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `df4a8016`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- CombatController.luau
- Theme.make
- BlockWorld.luau
- CraftingService.luau
- holdlib.py
- BagWindow.luau
- balance.py
- items3d.py
- Context.luau
- BodyService.luau
- BlockService.luau
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Hud.luau
- replicatedstorage_shared_items
- decor.py
- Tools and Workflow
- os
- starter_island.py
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
- replicatedstorage_shared_blocks
- HotbarService.luau
- Economy & Values
- DecorService.luau
- os
- json
- AmbientController.luau
- FirstPersonController.luau
- IslandService.luau
- Worlds/Mining.luau
- Warzone
- build_tier
- Signs.luau
- Late-game proposal (2026-10-29)
- arc
- MusicController.luau
- HotbarService.luau
- Crafting Proposal (2026-10-31, APPROVED as written the same night)
- Boards.luau
- Roadmap
- Window.luau
- Build.luau
- Warzone rebuild plan (2026-11-02)
- GearService.luau
- Main.server.luau
- gem_bench
- build
- SkydropService.luau
- TrophyModels.luau
- Kits
- Anti-Burnout Ideas
- Slaying plan (2026-11-02, approved with your changes)
- QuestService.luau
- UI study (2026-10-29)
- Published privately as Sky Farm Prototype
- Woodcutting phase: build plan (2026-11-02)
- numpy
- SkydropController.luau
- Farming phase: build plan (2026-11-02)
- VitalsHud.luau
- The late-game rule (your call, 2026-11-02)
- QuestTracker.luau
- Combat & Gear Plan (2026-11-03)
- script_parent_inventoryservice
- ChestService.luau
- Decision: block toughness + tool power (Minecraft rules)
- Skills & Levels
- armour.py
- lowpoly.py
- TravelService.luau
- BlockWorld.set
- Skybounds/README.md
- sys
- Hotbar.luau
- Farming.luau
- ItemIcon.create
- graph_to_vault.py
- Skills & Levels
- gem_cluster
- SprintController.luau
- Mining phase: build plan (2026-10-31)
- render.py
- Woodcutting.luau
- SprintService.luau
- WorldService.Start
- record.py
- export_meshes.py
- anvil
- bucket
- dragonfruit
- pumpkin
- twine
- shield
- sapling
- sliver
- wood_handle
- sword_fit/README.md
- starstone
- sugarcane
- strawberry
- starfruit

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 51 edges
2. `Handoff` - 42 edges
3. `Piece` - 38 edges
4. `Builder` - 29 edges
5. `Decision Log` - 28 edges
6. `scene_world()` - 26 edges
7. `Theme.corner()` - 26 edges
8. `noisy()` - 24 edges
9. `scene_icon()` - 23 edges
10. `Warzone` - 23 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming)` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, committed as `b66c289` (harvest wear removed later in part 4)` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `100+ challenges and an island challenge ladder` --semantically_similar_to--> `Beginner quest chain (13 quests, ends at level 10)`  [INFERRED] [semantically similar]
  02 Research/Skybounds (Minecraft).md → 03 Design/Tutorial & Quests.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (126 total, 39 thin omitted)

### Community 0 - "CombatController.luau"
Cohesion: 0.16
Nodes (15): aimedCharacter(), attack(), CombatController.Start(), cooldownOf(), faceTarget(), flash(), isFalling(), onHitEffect() (+7 more)

### Community 1 - "Theme.make"
Cohesion: 0.19
Nodes (37): buildGui(), show(), build(), Theme.badge(), Theme.bar(), Theme.button(), Theme.card(), Theme.chip() (+29 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.16
Nodes (15): inReach(), onPlayerRemoving(), BlockWorld.destroy(), BlockWorld.position(), buried(), exposed(), fits(), makeDecor() (+7 more)

### Community 3 - "CraftingService.luau"
Cohesion: 0.24
Nodes (14): buildGrid(), check(), choose(), CraftingWindow.SetState(), CraftingWindow.Start(), ingredientChip(), levelOf(), render() (+6 more)

### Community 4 - "holdlib.py"
Cohesion: 0.10
Nodes (18): all_obstacles(), armour_piece(), armoured(), bare_body(), box(), extras(), lerp_frame(), place() (+10 more)

### Community 5 - "BagWindow.luau"
Cohesion: 0.14
Nodes (24): (2026-11-03, session 11, earlier): Night Glass on every window, shield really held, Glass.setSlot(), Glass.text(), BagWindow.SetState(), BagWindow.Start(), bonusText(), buildCrafting(), buildEquipment() (+16 more)

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.10
Nodes (16): carrot(), downscale(), load_blocks(), over(), read_image(), render_icon(), render_icons(), scrap() (+8 more)

### Community 8 - "Context.luau"
Cohesion: 0.18
Nodes (22): Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path(), Common.Pond() (+14 more)

### Community 9 - "BodyService.luau"
Cohesion: 0.09
Nodes (15): BodyService.Copy(), BodyService.Drop(), BodyService.Lifetime(), dress(), fallingWay(), fetchAvatar(), isAny(), prepare() (+7 more)

### Community 10 - "BlockService.luau"
Cohesion: 0.08
Nodes (10): treeFell(), onOpen(), blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual(), unlockedBy() (+2 more)

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.05
Nodes (39): (2026-10-31 ~22:45, session 7): published scooping, swimming done, crafting approved, (2026-10-31 night): scooping restored, committed, NOT published, (2026-11-01 ~21:30, session 7): crafting + Mining phase tested, committed and PUBLISHED, store art live, (2026-11-02, session 8, earlier): Woodcutting phase built and playtested, (2026-11-02, session 8, last): the Warzone prototype was rejected, (2026-11-02, session 8): late-game rework, Warzone and billion-coin scale tested in Studio; NOT committed, NOT published, (2026-11-02, session 9): the real Warzone map is built, (2026-11-03, session 11, later): Minecraft combat, 8 generated swords, sprint, first person (+31 more)

### Community 12 - "Hud.luau"
Cohesion: 0.15
Nodes (19): buildCelebration(), buildMenu(), buildStatus(), buildToasts(), drawMenuBars(), fadeLabel(), Hud.Celebrate(), Hud.Render() (+11 more)

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.10
Nodes (12): doneCount(), stateOf(), listOf(), render(), renderCarried(), shownStack(), CrateWindow.SetState(), refresh() (+4 more)

### Community 14 - "decor.py"
Cohesion: 0.06
Nodes (20): awning(), awning_stripe(), bounds(), build_models(), cactus(), cactus_icon(), jack_face(), jack_face_only() (+12 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.15
Nodes (14): Trading shut down after a duplication exploit [Unverified], Blender driven by Python scripts, ProfileStore (player data with session locking), Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes (+6 more)

### Community 16 - "os"
Cohesion: 0.23
Nodes (12): build_icon_models(), build_items(), Builder, marker(), matrix(), crops(), far_crops(), main() (+4 more)

### Community 17 - "starter_island.py"
Cohesion: 0.24
Nodes (15): make_block(), make_merged(), quad(), tile_rect(), hex_rgb(), material(), mesh_object(), bridge() (+7 more)

### Community 18 - "new_verts"
Cohesion: 0.16
Nodes (12): axe(), thickness(), handle(), hoe(), new_verts(), pickaxe(), build_head(), z_at() (+4 more)

### Community 19 - "WarzoneService.luau"
Cohesion: 0.11
Nodes (25): dropNow(), finishLeaving(), groundFor(), humanoidOf(), inSafeZone(), isSafeSpot(), onFell(), playSound() (+17 more)

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
Cohesion: 0.09
Nodes (22): swing(), HeldController.Holding(), HeldController.Start(), HeldController.Swing(), moveHeld(), moveItem(), moveSword(), ownHeld() (+14 more)

### Community 29 - "BlockController.luau"
Cohesion: 0.28
Nodes (9): Decision: click-only farming, aim(), aimedLootChest(), aimedSealed(), aimedShop(), rootPosition(), screenRay(), shopkeepers() (+1 more)

### Community 30 - "blocks.py"
Cohesion: 0.13
Nodes (28): bricks_tile(), clamp(), draw_building_tiles(), planks_tile(), draw_deep_ore_tiles(), clumps(), crystals(), darker() (+20 more)

### Community 32 - "replicatedstorage_shared_blocks"
Cohesion: 0.15
Nodes (6): Shapes.Glow(), Shapes.Light(), beacon(), strip(), trafficCone(), v3()

### Community 33 - "HotbarService.luau"
Cohesion: 0.07
Nodes (17): Decision: Minecraft-style block islands (break and place, saved), Combat.Armor(), Economy.Total(), Economy.Value(), work(), Inventory.Across(), Inventory.Insert(), Inventory.MaxStack() (+9 more)

### Community 34 - "Economy & Values"
Cohesion: 0.22
Nodes (9): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The billion scale (your call, 2026-11-02), The rules, Tools (new, full durability), Trading between players (+1 more)

### Community 36 - "DecorService.luau"
Cohesion: 0.20
Nodes (18): attach(), checkHeld(), decorAt(), DecorService.InTall(), drawRails(), drawWords(), fenceJoins(), filtered() (+10 more)

### Community 37 - "os"
Cohesion: 0.25
Nodes (11): build_atlas(), main(), export_fbx(), render_preview(), reset_scene(), save_blend(), main(), preview() (+3 more)

### Community 39 - "json"
Cohesion: 0.22
Nodes (6): is_published(), main(), pick_target(), Server, studio_list(), wait_for_studios()

### Community 41 - "FirstPersonController.luau"
Cohesion: 0.35
Nodes (12): add(), addArm(), addHeld(), build(), clearRig(), copyOf(), hideReal(), keyFor() (+4 more)

### Community 42 - "IslandService.luau"
Cohesion: 0.10
Nodes (33): (session 6) islands as build areas DONE in Studio, Decision: falling off returns you to your island, islandArea(), announce(), build(), clampTier(), fell(), generate() (+25 more)

### Community 43 - "Worlds/Mining.luau"
Cohesion: 0.22
Nodes (11): ctx.Noise(), hillHeight(), roughDistance(), chamber(), ck(), findCaves(), mountainHeights(), rough() (+3 more)

### Community 45 - "Warzone"
Cohesion: 0.11
Nodes (21): Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Details seen in the photos (looked at closely 2026-11-02), Five maps, one theme each, The Skybounds Warzones, built by Team Vaeron, What they all share, What this means for our Warzone, Roblox Kids & Select age bands and content ratings (+13 more)

### Community 46 - "build_tier"
Cohesion: 0.31
Nodes (8): build_tier(), leaves(), outline(), plot_positions(), radius_at(), ring(), rock(), tree()

### Community 48 - "Signs.luau"
Cohesion: 0.06
Nodes (40): LATEST (2026-11-04, session 15, night): THE BUILDER SELLS DECORATIONS; START HERE, greet(), NpcController.Start(), track(), update(), buildArrival(), Decor.Flower(), Decor.Grass() (+32 more)

### Community 52 - "Late-game proposal (2026-10-29)"
Cohesion: 0.22
Nodes (9): 1. New resources (13), 2. New tool tiers (2, x 5 kinds = 10 tools), 3. Big things to buy (10M–50M), 4. The order to build it in, Farming: four new zone islands (4), Late-game proposal (2026-10-29), Mining: a deeper cave under the Gold Chamber (5), Questions (+1 more)

### Community 53 - "arc"
Cohesion: 0.17
Nodes (6): arc(), front_slab(), rope(), ui_bag(), ui_mail(), ui_trophy()

### Community 54 - "MusicController.luau"
Cohesion: 0.83
Nodes (3): fadeTo(), MusicController.Start(), newSound()

### Community 55 - "HotbarService.luau"
Cohesion: 0.33
Nodes (8): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isIndex(), onMoveStack(), onQuickMove(), onSelectSlot(), refreshHeld()

### Community 56 - "Crafting Proposal (2026-10-31, APPROVED as written the same night)"
Cohesion: 0.33
Nodes (6): Crafting Proposal (2026-10-31, APPROVED as written the same night), New stations, Questions, The ladder, The rule, What it adds

### Community 57 - "Boards.luau"
Cohesion: 0.40
Nodes (4): boardsState(), Boards.CurrentIndex(), c(), rewardCoins()

### Community 58 - "Roadmap"
Cohesion: 0.19
Nodes (12): NPC visits at milestones with a starter pack, Gear references, Warzone parked until it moves into Town, Content Index, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Decision Log (+4 more)

### Community 59 - "Window.luau"
Cohesion: 0.10
Nodes (23): edge(), Glass.button(), Glass.card(), Glass.glow(), Glass.inset(), Glass.stage(), setBlur(), Window.clear() (+15 more)

### Community 60 - "Build.luau"
Cohesion: 0.18
Nodes (11): set(), setFree(), top(), Build.Fill(), Build.Set(), Build.SetFree(), Build.Top(), pick() (+3 more)

### Community 61 - "Warzone rebuild plan (2026-11-02)"
Cohesion: 0.25
Nodes (8): 1. The map: Robot / sci-fi (built and walked in Studio, 2026-11-02), 2. Warzone rules, 3. Inventory and chests, whole game, 4. Shield, 5. Skydrops, Answered (2026-11-02), Map design, as built (grid in blocks, 1 block = 3 studs; our own builds, not copies), Warzone rebuild plan (2026-11-02)

### Community 62 - "GearService.luau"
Cohesion: 0.19
Nodes (8): (2026-11-03, session 10): new shield, four armour pieces, equipment in the Bag, checkOwned(), GearService.Start(), removePet(), spawnPet(), splitOldArmor(), refresh(), PetModels.Build()

### Community 65 - "build"
Cohesion: 0.22
Nodes (11): build(), portalFields(), Ambience.Apply(), Ambience.Warzone(), ensure(), BlockWorld.drawAll(), BlockWorld.partCount(), Pace.Begin() (+3 more)

### Community 66 - "SkydropService.luau"
Cohesion: 0.10
Nodes (9): LootChestService.FindSpot(), LootChestService.Refill(), LootChestService.Start(), spawnOne(), findLanding(), innerIslands(), Inventory.EmptyOf(), WarzoneLoot.Roll() (+1 more)

### Community 67 - "TrophyModels.luau"
Cohesion: 0.33
Nodes (11): anvil(), blockPiece(), gemBench(), rootPart(), settle(), weld(), build(), emblem() (+3 more)

### Community 68 - "Kits"
Cohesion: 0.33
Nodes (6): Kits, Our version (proposal), Rule to design around, Still to decide, The other Skybounds kits, for reference, What Looter was in Skybounds

### Community 69 - "Anti-Burnout Ideas"
Cohesion: 0.17
Nodes (10): Totems: passive resource generators with a range, Skill-gated vending machines and handshake trading, Idle-grow / cozy trend (Grow a Garden spike and decay), Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Offline progress and timers, Prestige with real unlocks (+2 more)

### Community 71 - "Slaying plan (2026-11-02, approved with your changes)"
Cohesion: 0.50
Nodes (4): Slaying plan (2026-11-02, approved with your changes), The idea, What comes with it, Zones and monsters

### Community 72 - "QuestService.luau"
Cohesion: 0.13
Nodes (15): boardCurrent(), checkReach(), complete(), completeBoard(), currentQuest(), giveReward(), QuestService.Record(), reachValue() (+7 more)

### Community 73 - "UI study (2026-10-29)"
Cohesion: 0.50
Nodes (4): Proposed Skycore style (combining them), Shared lessons, UI study (2026-10-29), What each does well

### Community 74 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 75 - "Woodcutting phase: build plan (2026-11-02)"
Cohesion: 0.33
Nodes (6): New blocks, Order, Slivers and nodes, The trees, What isn't in this phase, Woodcutting phase: build plan (2026-11-02)

### Community 76 - "numpy"
Cohesion: 0.18
Nodes (10): frame(), pose_frame(), pose_mount(), sword(), sword_points(), unit(), matrix(), face() (+2 more)

### Community 77 - "SkydropController.luau"
Cohesion: 0.31
Nodes (5): addMarker(), placeMarker(), SkydropController.Start(), update(), watchChest()

### Community 78 - "Farming phase: build plan (2026-11-02)"
Cohesion: 0.40
Nodes (5): Farming phase: build plan (2026-11-02), Ruby and Starsteel tools (built in the same pass), Seeds come from slivers, The crops, The skill-curve refit

### Community 79 - "VitalsHud.luau"
Cohesion: 0.33
Nodes (6): Hotbar.Bar(), fill(), makeRow(), setCell(), VitalsHud.SetState(), VitalsHud.Start()

### Community 80 - "The late-game rule (your call, 2026-11-02)"
Cohesion: 0.50
Nodes (4): How you get things, The coin targets: settled, The late-game rule (your call, 2026-11-02), What this changed

### Community 81 - "QuestTracker.luau"
Cohesion: 0.18
Nodes (4): keyLabel(), PromptUI.Start(), aimHighlight(), QuestTracker.Render()

### Community 82 - "Combat & Gear Plan (2026-11-03)"
Cohesion: 0.22
Nodes (9): Armour art, Armour numbers, Combat & Gear Plan (2026-11-03), Combat: real Minecraft rules, First person, Health, armour and hunger on screen, Sprinting, The sword system (+1 more)

### Community 83 - "script_parent_inventoryservice"
Cohesion: 0.36
Nodes (6): BodyService.Start(), clean(), deliver(), InboxService.Send(), InboxService.Start(), onOverflow()

### Community 84 - "ChestService.luau"
Cohesion: 0.22
Nodes (10): changed(), ChestService.CloseAll(), ChestService.CloseFor(), ChestService.Open(), closeFor(), isIndex(), placeOf(), send() (+2 more)

### Community 85 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.25
Nodes (7): Mobile-first UI, 100+ challenges and an island challenge ladder, Beginner quest chain (13 quests, ends at level 10), Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tutorial & Quests, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: block toughness + tool power (Minecraft rules)

### Community 86 - "Skills & Levels"
Cohesion: 0.10
Nodes (30): Design Pillars, Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands (+22 more)

### Community 87 - "armour.py"
Cohesion: 0.06
Nodes (39): band(), boot_base(), boot_farming(), boot_mining(), boot_woodcutting(), burst(), chest_farming(), chest_mining() (+31 more)

### Community 88 - "lowpoly.py"
Cohesion: 0.20
Nodes (4): _hex(), palette_image(), palette_material(), swatch_uv()

### Community 89 - "TravelService.luau"
Cohesion: 0.15
Nodes (9): liquidAt(), touches(), capitalized(), failed(), sendBack(), TravelService.Go(), LiquidModels.Make(), make() (+1 more)

### Community 90 - "BlockWorld.set"
Cohesion: 0.38
Nodes (7): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, IslandService.PlaceNode(), respawnNodes(), regrow(), BlockWorld.occupied(), BlockWorld.set(), unmerge()

### Community 93 - "Hotbar.luau"
Cohesion: 0.29
Nodes (9): Decision: 5-slot Minecraft-style hotbar, FirstPersonController.Start(), setForced(), HeldController.OnSwing(), Hotbar.Select(), Hotbar.Selected(), Hotbar.SelectedItem(), showName() (+1 more)

### Community 94 - "Farming.luau"
Cohesion: 0.36
Nodes (7): crossPathZ(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), veggiePathZ(), wave()

### Community 95 - "ItemIcon.create"
Cohesion: 0.46
Nodes (5): addCamera(), halfExtents(), ItemIcon.create(), modelIcon(), viewport()

### Community 96 - "graph_to_vault.py"
Cohesion: 0.36
Nodes (3): main(), merge_color_groups(), real_notes()

### Community 97 - "Skills & Levels"
Cohesion: 0.11
Nodes (19): Skybounds seasons: 2-4 months, level resets, Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Better rewards as skills level up, Combat (PvE) skill, Farming skill (+11 more)

### Community 99 - "gem_cluster"
Cohesion: 0.14
Nodes (4): gem_cluster(), iron_plate(), loot_crate(), melon()

### Community 100 - "SprintController.luau"
Cohesion: 0.83
Nodes (3): lean(), moving(), SprintController.Start()

### Community 103 - "Mining phase: build plan (2026-10-31)"
Cohesion: 0.29
Nodes (7): Art, Mining phase: build plan (2026-10-31), Order, Slivers and nodes, The deep cave (Worlds/Mining.luau), The ores (the deep cave, under the Gold Chamber), Tool tiers and parts (from the Crafting Proposal)

### Community 106 - "render.py"
Cohesion: 0.36
Nodes (4): add(), body_for(), camera_at(), to_blender()

### Community 108 - "SprintService.luau"
Cohesion: 0.67
Nodes (6): humanoidOf(), onSprint(), SprintService.Start(), SprintService.Stop(), tooHungry(), WarzoneService.IsBlocking()

### Community 109 - "WorldService.Start"
Cohesion: 0.38
Nodes (5): makeArea(), WorldService.Start(), spawnCharacter(), Spawning.MakeSpawn(), Spawning.Start()

### Community 110 - "record.py"
Cohesion: 0.53
Nodes (4): call(), read_frames(), run(), text()

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox`, `Steal An Egg precedent (feature pulled, rule added)`, `Prototype phase (current)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 511 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **39 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `BlockWorld.set` to `Handoff (updated 2026-10-27 ~22:35, session 4)`, `blocks.py`?**
  _High betweenness centrality (0.375) - this node is a cross-community bridge._
- **Are the 34 inferred relationships involving `Theme.make()` (e.g. with `buildGui()` and `buildCelebration()`) actually correct?**
  _`Theme.make()` has 34 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `holdlib.py` be split into smaller, more focused modules?**
  _Cohesion score 0.1032258064516129 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `BlockWorld.set`, `store_art.py`?**
  _High betweenness centrality (0.370) - this node is a cross-community bridge._
- **Should `BagWindow.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.13793103448275862 - nodes in this community are weakly interconnected._
- **Why does `respawnNodes()` connect `BlockWorld.set` to `IslandService.luau`, `DecorService.luau`?**
  _High betweenness centrality (0.170) - this node is a cross-community bridge._