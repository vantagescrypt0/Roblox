# Graph Report - Roblox  (2026-11-09)

## Corpus Check
- 243 files · ~338,776 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 2125 nodes · 4896 edges · 130 communities (98 shown, 32 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 857 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `15dda925`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- CombatController.luau
- Theme.make
- BlockWorld.luau
- CraftingService.luau
- numpy
- BagWindow.luau
- balance.py
- render_icons
- Common.luau
- BodyService.luau
- armour.py
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Hud.luau
- build
- decor.py
- onOpen
- os
- starter_island.py
- new_verts
- WarzoneService.luau
- replicatedstorage_shared_monsters
- math
- Town & Worlds
- script_parent_islandservice
- HeldController.luau
- Inbox
- BlockController.luau
- blocks.py
- replicatedstorage_shared_items
- HotbarService.luau
- Economy & Values
- ChestService.luau
- script_parent_dataservice
- json
- AmbientController.luau
- MobController.luau
- IslandService.luau
- os
- SpawnerService.luau
- build_tier
- Worlds/Mining.luau
- DecorModels.Place
- Tools & Stack
- Late-game proposal (2026-10-29)
- arc
- replicatedstorage_shared_remotes
- crate_rays.py
- Crafting Proposal (2026-10-31, APPROVED as written the same night)
- Boards.luau
- Roadmap
- Sfx.play
- Build.luau
- Warzone
- VisitService.luau
- gem_bench
- build
- SkydropService.luau
- TrophyModels.luau
- Kits
- Anti-Burnout Ideas
- The late-game rule (your call, 2026-11-02)
- QuestService.luau
- UI study (2026-10-29)
- Published privately as Sky Farm Prototype
- Woodcutting phase: build plan (2026-11-02)
- onFarmClick
- SkydropController.luau
- Farming phase: build plan (2026-11-02)
- crate_open.py
- .hexagon
- KitPowerController.luau
- Combat & Gear Plan (2026-11-03)
- InboxService.luau
- VitalsHud.luau
- Decision: block toughness + tool power (Minecraft rules)
- Home
- Piece
- CrateOpening.luau
- WorldService.luau
- DecorService.luau
- MobService.luau
- FarmService.luau
- SwimController.luau
- HotbarService.luau
- Leveling.luau
- items3d.py
- .leaf
- Mining phase: build plan (2026-10-31)
- chest_venomfang
- SettingsWindow.luau
- Slaying.luau
- BlockWorld.set
- replicatedstorage_shared_places
- render.py
- FlightController.luau
- replicatedstorage_shared_blocks
- Merchant NPC at the Town market
- sword_fit/README.md
- Farming.luau
- KitPowerController.luau
- Skybounds/README.md
- Slaying plan (2026-11-02, approved with your changes)
- ArmorModels.luau
- BlockWorld.position
- lerp_frame
- (2026-11-03, session 10): new shield, four armour pieces, equipment in the Bag

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 60 edges
2. `Handoff` - 57 edges
3. `Piece` - 55 edges
4. `Builder` - 34 edges
5. `Theme.corner()` - 30 edges
6. `Decision Log` - 28 edges
7. `scene_world()` - 26 edges
8. `noisy()` - 24 edges
9. `scene_icon()` - 23 edges
10. `Skills & Levels` - 23 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `(session 6) islands as build areas DONE in Studio` --references--> `moveOldFarm()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/IslandService.luau
- `TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming)` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, committed as `b66c289` (harvest wear removed later in part 4)` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (130 total, 32 thin omitted)

### Community 0 - "CombatController.luau"
Cohesion: 0.16
Nodes (15): aimedCharacter(), attack(), CombatController.Start(), cooldownOf(), faceTarget(), flash(), isFalling(), onHitEffect() (+7 more)

### Community 1 - "Theme.make"
Cohesion: 0.16
Nodes (40): buildGui(), CrateOpening.Start(), makeCard(), buildStatus(), buildToasts(), drawSliders(), show(), Glass.card() (+32 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.18
Nodes (11): buried(), exposed(), fits(), makeDecor(), makePart(), mergeScenery(), occludes(), placePiece() (+3 more)

### Community 3 - "CraftingService.luau"
Cohesion: 0.24
Nodes (13): check(), choose(), CraftingWindow.SetState(), ingredientChip(), levelOf(), render(), renderDetail(), skillChip() (+5 more)

### Community 4 - "numpy"
Cohesion: 0.10
Nodes (22): all_obstacles(), armour_piece(), armoured(), bare_body(), box(), extras(), frame(), place() (+14 more)

### Community 5 - "BagWindow.luau"
Cohesion: 0.12
Nodes (19): (2026-11-03, session 11, earlier): Night Glass on every window, shield really held, Hotbar.Selected(), Glass.setSlot(), Theme.formatNumber(), BagWindow.SetState(), BagWindow.Start(), buildCrafting(), buildPreview() (+11 more)

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "render_icons"
Cohesion: 0.15
Nodes (11): downscale(), load_blocks(), over(), read_image(), render_icons(), setup_lights(), with_outline(), write_image() (+3 more)

### Community 8 - "Common.luau"
Cohesion: 0.16
Nodes (25): Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path(), Common.Pond() (+17 more)

### Community 9 - "BodyService.luau"
Cohesion: 0.16
Nodes (13): BodyService.Copy(), BodyService.Drop(), BodyService.Lifetime(), BodyService.Start(), dress(), fallingWay(), fetchAvatar(), isAny() (+5 more)

### Community 10 - "armour.py"
Cohesion: 0.09
Nodes (36): boot_base(), boot_emberguard(), boot_farming(), boot_frostwarden(), boot_sunforged(), boot_venomfang(), boot_woodcutting(), chest_frostwarden() (+28 more)

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.04
Nodes (49): (2026-10-31 ~22:45, session 7): published scooping, swimming done, crafting approved, (2026-10-31 night): scooping restored, committed, NOT published, (2026-11-01 ~21:30, session 7): crafting + Mining phase tested, committed and PUBLISHED, store art live, (2026-11-02, session 8, earlier): Woodcutting phase built and playtested, (2026-11-02, session 8, last): the Warzone prototype was rejected, (2026-11-02, session 8): late-game rework, Warzone and billion-coin scale tested in Studio; NOT committed, NOT published, (2026-11-02, session 9): the real Warzone map is built, (2026-11-03, session 11, later): Minecraft combat, 8 generated swords, sprint, first person (+41 more)

### Community 12 - "Hud.luau"
Cohesion: 0.10
Nodes (23): buildCelebration(), buildMenu(), drawMenuBars(), fadeLabel(), Hud.Celebrate(), Hud.Render(), Hud.Toast(), renderSeason() (+15 more)

### Community 13 - "build"
Cohesion: 0.40
Nodes (6): build(), Theme.edge(), Theme.isPhone(), Theme.lighten(), Window.hideWhenCovered(), SkillsWindow.Start()

### Community 14 - "decor.py"
Cohesion: 0.06
Nodes (20): awning(), awning_stripe(), bounds(), build_models(), cactus(), cactus_icon(), jack_face(), jack_face_only() (+12 more)

### Community 15 - "onOpen"
Cohesion: 0.29
Nodes (5): (end of session 18, 2026-11-09): paused by you before the crate animation and the kit specials, loot_crate(), onOpen(), LootCrates.Roll(), pick()

### Community 16 - "os"
Cohesion: 0.21
Nodes (13): dais(), build_icon_models(), build_items(), Builder, marker(), matrix(), crops(), far_crops() (+5 more)

### Community 17 - "starter_island.py"
Cohesion: 0.38
Nodes (11): hex_rgb(), material(), mesh_object(), bridge(), dirt_body(), grass_top(), main(), ring() (+3 more)

### Community 18 - "new_verts"
Cohesion: 0.16
Nodes (12): axe(), thickness(), handle(), hoe(), new_verts(), pickaxe(), build_head(), z_at() (+4 more)

### Community 19 - "WarzoneService.luau"
Cohesion: 0.07
Nodes (50): aura(), buffOn(), chainLightning(), clearLine(), closest(), current(), freezePlayer(), frostNova() (+42 more)

### Community 20 - "replicatedstorage_shared_monsters"
Cohesion: 0.29
Nodes (6): spawnPet(), buildMonster(), PetModels.Build(), build(), SpawnerModels.Make(), weldTo()

### Community 21 - "math"
Cohesion: 0.06
Nodes (72): (2026-11-08): real-footage thumbnails, and the rival, add_mesh(), anvil_mesh(), Assets, blur(), box(), camera(), caption() (+64 more)

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "script_parent_islandservice"
Cohesion: 0.24
Nodes (4): liquidAt(), touches(), LiquidModels.Make(), make()

### Community 24 - "HeldController.luau"
Cohesion: 0.08
Nodes (35): swing(), add(), addArm(), addHeld(), build(), clearRig(), copyOf(), FirstPersonController.Start() (+27 more)

### Community 29 - "BlockController.luau"
Cohesion: 0.25
Nodes (9): Decision: click-only farming, aim(), aimedLootChest(), aimedSealed(), aimedShop(), rootPosition(), screenRay(), shopkeepers() (+1 more)

### Community 30 - "blocks.py"
Cohesion: 0.11
Nodes (32): bricks_tile(), clamp(), draw_building_tiles(), planks_tile(), draw_deep_ore_tiles(), clumps(), crystals(), darker() (+24 more)

### Community 32 - "replicatedstorage_shared_items"
Cohesion: 0.09
Nodes (13): doneCount(), renderGroups(), stateOf(), listOf(), render(), renderCarried(), shownStack(), powerRow() (+5 more)

### Community 33 - "HotbarService.luau"
Cohesion: 0.07
Nodes (15): Decision: Minecraft-style block islands (break and place, saved), Economy.Total(), Economy.Value(), work(), Inventory.Across(), Inventory.Insert(), Inventory.MaxStack(), Inventory.Move() (+7 more)

### Community 34 - "Economy & Values"
Cohesion: 0.22
Nodes (9): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The billion scale (your call, 2026-11-02), The rules, Tools (new, full durability), Trading between players (+1 more)

### Community 36 - "ChestService.luau"
Cohesion: 0.20
Nodes (11): changed(), ChestService.CloseAll(), ChestService.CloseFor(), ChestService.Open(), closeFor(), isIndex(), placeOf(), send() (+3 more)

### Community 39 - "json"
Cohesion: 0.06
Nodes (19): num(), turn(), main(), run(), matrix(), call(), read_frames(), run() (+11 more)

### Community 41 - "MobController.luau"
Cohesion: 0.60
Nodes (5): animate(), fade(), forget(), MobController.Start(), track()

### Community 42 - "IslandService.luau"
Cohesion: 0.12
Nodes (30): Decision: falling off returns you to your island, islandArea(), announce(), build(), clampTier(), fell(), generate(), growSaplings() (+22 more)

### Community 43 - "os"
Cohesion: 0.25
Nodes (11): build_atlas(), main(), export_fbx(), render_preview(), reset_scene(), save_blend(), main(), preview() (+3 more)

### Community 45 - "SpawnerService.luau"
Cohesion: 0.60
Nodes (3): besideSpawner(), check(), SpawnerService.Start()

### Community 46 - "build_tier"
Cohesion: 0.20
Nodes (9): build_tier(), leaves(), outline(), plot_positions(), radius_at(), ring(), rock(), tree() (+1 more)

### Community 47 - "Worlds/Mining.luau"
Cohesion: 0.24
Nodes (11): ctx.Noise(), hillHeight(), roughDistance(), chamber(), ck(), findCaves(), mountainHeights(), rough() (+3 more)

### Community 48 - "DecorModels.Place"
Cohesion: 0.06
Nodes (40): LATEST (2026-11-04, session 15, night): THE BUILDER SELLS DECORATIONS; START HERE, greet(), NpcController.Start(), track(), update(), buildArrival(), Decor.Flower(), Decor.Grass() (+32 more)

### Community 50 - "Tools & Stack"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 52 - "Late-game proposal (2026-10-29)"
Cohesion: 0.22
Nodes (9): 1. New resources (13), 2. New tool tiers (2, x 5 kinds = 10 tools), 3. Big things to buy (10M–50M), 4. The order to build it in, Farming: four new zone islands (4), Late-game proposal (2026-10-29), Mining: a deeper cave under the Gold Chamber (5), Questions (+1 more)

### Community 53 - "arc"
Cohesion: 0.17
Nodes (6): arc(), front_slab(), rope(), ui_bag(), ui_mail(), ui_trophy()

### Community 54 - "replicatedstorage_shared_remotes"
Cohesion: 0.09
Nodes (5): PvP only when both players are in the Warzone, lean(), moving(), SprintController.Start(), treeFell()

### Community 55 - "crate_rays.py"
Cohesion: 0.11
Nodes (10): main(), preview(), swatch_uv(), to_blender(), write_palette(), alpha(), chunk(), icon() (+2 more)

### Community 56 - "Crafting Proposal (2026-10-31, APPROVED as written the same night)"
Cohesion: 0.33
Nodes (6): Crafting Proposal (2026-10-31, APPROVED as written the same night), New stations, Questions, The ladder, The rule, What it adds

### Community 57 - "Boards.luau"
Cohesion: 0.40
Nodes (4): boardsState(), Boards.CurrentIndex(), c(), rewardCoins()

### Community 58 - "Roadmap"
Cohesion: 0.20
Nodes (16): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Skills & Levels, Tutorial & Quests, Content Index, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5) (+8 more)

### Community 59 - "Sfx.play"
Cohesion: 0.13
Nodes (22): setBlur(), showHud(), Window.clear(), Window.close(), Window.new(), Window.open(), Window.setTitle(), Window.toggle() (+14 more)

### Community 60 - "Build.luau"
Cohesion: 0.24
Nodes (9): setFree(), top(), BlockWorld.setRaw(), Build.Fill(), Build.Set(), Build.SetFree(), Build.Top(), pick() (+1 more)

### Community 61 - "Warzone"
Cohesion: 0.08
Nodes (28): Younger Roblox players (Kids 5-8, Select 9-15), Details seen in the photos (looked at closely 2026-11-02), Five maps, one theme each, The Skybounds Warzones, built by Team Vaeron, What they all share, What this means for our Warzone, Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check] (+20 more)

### Community 63 - "VisitService.luau"
Cohesion: 0.09
Nodes (11): IslandService.OwnerAt(), IslandService.SendHome(), grantCrate(), KitService.SetTest(), KitService.TestReceipt(), onReceipt(), goHome(), hostOf() (+3 more)

### Community 65 - "build"
Cohesion: 0.24
Nodes (10): set(), build(), Ambience.Apply(), Ambience.Warzone(), ensure(), BlockWorld.drawAll(), BlockWorld.partCount(), Pace.Begin() (+2 more)

### Community 66 - "SkydropService.luau"
Cohesion: 0.10
Nodes (9): LootChestService.FindSpot(), LootChestService.Refill(), LootChestService.Start(), spawnOne(), findLanding(), innerIslands(), Inventory.EmptyOf(), WarzoneLoot.Roll() (+1 more)

### Community 67 - "TrophyModels.luau"
Cohesion: 0.33
Nodes (11): anvil(), blockPiece(), gemBench(), rootPart(), settle(), weld(), build(), emblem() (+3 more)

### Community 68 - "Kits"
Cohesion: 0.22
Nodes (9): Armour kits (started 2026-11-09), How crates should roll (your call, 2026-11-09), Kits, Our version (proposal), Rule to design around, Still to decide, What Looter was in Skybounds, What the Skybounds kits came with (your list, sent 2026-11-02) (+1 more)

### Community 69 - "Anti-Burnout Ideas"
Cohesion: 0.20
Nodes (8): Skill-gated vending machines and handshake trading, Idle-grow / cozy trend (Grow a Garden spike and decay), Anti-Burnout Ideas, Trading with anti-scam UI (two-step confirm, trade log), Economy sinks to slow inflation, Offline progress and timers, Prestige with real unlocks, Decision: buy bigger islands with coins (4 tiers)

### Community 71 - "The late-game rule (your call, 2026-11-02)"
Cohesion: 0.50
Nodes (4): How you get things, The coin targets: settled, The late-game rule (your call, 2026-11-02), What this changed

### Community 72 - "QuestService.luau"
Cohesion: 0.09
Nodes (24): AwardService.Give(), AwardService.Start(), ProgressionService.AddPlayerXP(), boardCurrent(), checkReach(), complete(), completeBoard(), currentQuest() (+16 more)

### Community 73 - "UI study (2026-10-29)"
Cohesion: 0.50
Nodes (4): Proposed Skycore style (combining them), Shared lessons, UI study (2026-10-29), What each does well

### Community 74 - "Published privately as Sky Farm Prototype"
Cohesion: 0.50
Nodes (4): Published privately as Sky Farm Prototype, Studio dev shortcuts (Dev:Invoke Level/Skill/Give), Game code README, Saving in Studio needs a published place + Studio API access

### Community 75 - "Woodcutting phase: build plan (2026-11-02)"
Cohesion: 0.33
Nodes (6): New blocks, Order, Slivers and nodes, The trees, What isn't in this phase, Woodcutting phase: build plan (2026-11-02)

### Community 76 - "onFarmClick"
Cohesion: 0.50
Nodes (4): Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, committed as `b66c289` (harvest wear removed later in part 4), TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming), notice(), onFarmClick()

### Community 77 - "SkydropController.luau"
Cohesion: 0.31
Nodes (5): addMarker(), placeMarker(), SkydropController.Start(), update(), watchChest()

### Community 78 - "Farming phase: build plan (2026-11-02)"
Cohesion: 0.40
Nodes (5): Farming phase: build plan (2026-11-02), Ruby and Starsteel tools (built in the same pass), Seeds come from slivers, The crops, The skill-curve refit

### Community 79 - "crate_open.py"
Cohesion: 0.33
Nodes (5): crate_body(), crate_lid(), main(), preview(), rune()

### Community 80 - ".hexagon"
Cohesion: 0.17
Nodes (12): band(), chest_farming(), chest_mining(), chest_stormcaller(), chest_woodcutting(), coat(), helmet_mining(), helmet_woodcutting() (+4 more)

### Community 81 - "KitPowerController.luau"
Cohesion: 0.15
Nodes (9): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.SelectedItem(), showName(), slotCenter(), keyLabel(), PromptUI.Start(), aimHighlight() (+1 more)

### Community 82 - "Combat & Gear Plan (2026-11-03)"
Cohesion: 0.17
Nodes (10): Gear references, Armour art, Armour numbers, Combat & Gear Plan (2026-11-03), Combat: real Minecraft rules, First person, Health, armour and hunger on screen, Sprinting (+2 more)

### Community 83 - "InboxService.luau"
Cohesion: 0.43
Nodes (5): clean(), deliver(), InboxService.Send(), InboxService.Start(), onOverflow()

### Community 84 - "VitalsHud.luau"
Cohesion: 0.19
Nodes (8): Hotbar.Bar(), fill(), makeRow(), setCell(), VitalsHud.SetState(), VitalsHud.Start(), Combat.Armor(), Combat.Charge()

### Community 85 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.50
Nodes (3): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: block toughness + tool power (Minecraft rules)

### Community 86 - "Home"
Cohesion: 0.10
Nodes (29): Design Pillars, Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Target Audience, Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox) (+21 more)

### Community 87 - "Piece"
Cohesion: 0.09
Nodes (22): bolt(), boot_mining(), boot_stormcaller(), burst(), cloud(), forearm_farming(), forearm_mining(), forearm_stormcaller() (+14 more)

### Community 89 - "CrateOpening.luau"
Cohesion: 0.19
Nodes (12): clamp01(), clearScene(), CrateOpening.Play(), cue(), glowLabel(), headingText(), outBack(), render() (+4 more)

### Community 90 - "WorldService.luau"
Cohesion: 0.19
Nodes (13): allowed(), checkPlayer(), notice(), onFell(), SlayingService.Setup(), spawnFor(), turnBack(), zoneAt() (+5 more)

### Community 91 - "DecorService.luau"
Cohesion: 0.15
Nodes (24): attach(), checkHeld(), checkSharing(), decorAt(), DecorService.InTall(), DecorService.OpenNewSign(), drawRails(), drawWords() (+16 more)

### Community 92 - "MobService.luau"
Cohesion: 0.21
Nodes (14): addPlate(), build(), chase(), loop(), MobService.Freeze(), MobService.ReachOf(), MobService.Spawn(), MobService.Start() (+6 more)

### Community 93 - "FarmService.luau"
Cohesion: 0.20
Nodes (9): addCamera(), halfExtents(), modelIcon(), viewport(), blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot() (+1 more)

### Community 94 - "SwimController.luau"
Cohesion: 0.33
Nodes (10): add(), anyDown(), characterParts(), columnSurface(), over(), startSwimming(), step(), stopSwimming() (+2 more)

### Community 95 - "HotbarService.luau"
Cohesion: 0.33
Nodes (8): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isIndex(), onMoveStack(), onQuickMove(), onSelectSlot(), refreshHeld()

### Community 97 - "Leveling.luau"
Cohesion: 0.11
Nodes (14): Mobile-first UI, 100+ challenges and an island challenge ladder, Skybounds seasons: 2-4 months, level resets, Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Better rewards as skills level up (+6 more)

### Community 99 - "items3d.py"
Cohesion: 0.04
Nodes (24): anvil(), bucket(), carrot(), dragonfruit(), gem_cluster(), iron_plate(), melon(), pumpkin() (+16 more)

### Community 100 - ".leaf"
Cohesion: 0.25
Nodes (5): forearm_base(), forearm_woodcutting(), pauldron_base(), pauldron_woodcutting(), sleeve_woodcutting()

### Community 103 - "Mining phase: build plan (2026-10-31)"
Cohesion: 0.29
Nodes (7): Art, Mining phase: build plan (2026-10-31), Order, Slivers and nodes, The deep cave (Worlds/Mining.luau), The ores (the deep cave, under the Gold Chamber), Tool tiers and parts (from the Crafting Proposal)

### Community 107 - "chest_venomfang"
Cohesion: 0.25
Nodes (6): chest_emberguard(), chest_sunforged(), chest_venomfang(), kit_tails(), scales(), sun()

### Community 108 - "SettingsWindow.luau"
Cohesion: 0.53
Nodes (5): applyVolumes(), save(), SettingsWindow.SetState(), SettingsWindow.Start(), slider()

### Community 109 - "Slaying.luau"
Cohesion: 0.14
Nodes (3): ctx.Flatten(), flattenRoads(), layRoads()

### Community 110 - "BlockWorld.set"
Cohesion: 0.15
Nodes (11): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, checkOwned(), GearService.Start(), removePet(), IslandService.PlaceNode(), respawnNodes(), regrow(), BlockWorld.occupied() (+3 more)

### Community 111 - "replicatedstorage_shared_places"
Cohesion: 0.16
Nodes (10): fadeTo(), MusicController.Start(), newSound(), offered(), setOffer(), capitalized(), failed(), sendBack() (+2 more)

### Community 112 - "render.py"
Cohesion: 0.21
Nodes (7): _hex(), palette_image(), palette_material(), add(), body_for(), camera_at(), to_blender()

### Community 113 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 116 - "replicatedstorage_shared_blocks"
Cohesion: 0.19
Nodes (6): Shapes.Glow(), Shapes.Light(), beacon(), strip(), trafficCone(), v3()

### Community 120 - "Merchant NPC at the Town market"
Cohesion: 0.33
Nodes (6): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Next: add the Warzone to Town

### Community 124 - "Farming.luau"
Cohesion: 0.36
Nodes (7): crossPathZ(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), veggiePathZ(), wave()

### Community 125 - "KitPowerController.luau"
Cohesion: 0.36
Nodes (5): aimed(), fire(), heldSpecial(), KitPowerController.RightClick(), secondsLeft()

### Community 137 - "Slaying plan (2026-11-02, approved with your changes)"
Cohesion: 0.50
Nodes (4): Slaying plan (2026-11-02, approved with your changes), The idea, What comes with it, Zones and monsters

### Community 140 - "ArmorModels.luau"
Cohesion: 0.24
Nodes (5): addEffects(), ArmorModels.Apply(), hideClothing(), meshPart(), setHidden()

### Community 142 - "BlockWorld.position"
Cohesion: 0.39
Nodes (6): inReach(), portalFields(), BlockWorld.position(), Portal.makeClosed(), Portal.makeField(), sheet()

## Knowledge Gaps
- **14 isolated node(s):** `Inbox`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)`, `Vertical slice, then soft launch, launch and live ops` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 589 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **32 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `BlockWorld.set` to `Handoff (updated 2026-10-27 ~22:35, session 4)`, `blocks.py`?**
  _High betweenness centrality (0.282) - this node is a cross-community bridge._
- **Are the 42 inferred relationships involving `Theme.make()` (e.g. with `buildGui()` and `CrateOpening.Start()`) actually correct?**
  _`Theme.make()` has 42 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Inbox`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `numpy` be split into smaller, more focused modules?**
  _Cohesion score 0.09747899159663866 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `math`, `BlockWorld.set`?**
  _High betweenness centrality (0.274) - this node is a cross-community bridge._
- **Should `BagWindow.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._
- **Why does `respawnNodes()` connect `BlockWorld.set` to `IslandService.luau`, `DecorService.luau`?**
  _High betweenness centrality (0.137) - this node is a cross-community bridge._