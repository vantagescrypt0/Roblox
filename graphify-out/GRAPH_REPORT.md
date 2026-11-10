# Graph Report - Roblox  (2026-11-10)

## Corpus Check
- 260 files · ~371,139 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 2254 nodes · 5240 edges · 147 communities (109 shown, 38 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 923 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a328c924`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- CombatController.luau
- Theme.make
- BlockWorld.luau
- CraftingService.luau
- numpy
- numpy
- balance.py
- DecorService.luau
- Common.luau
- BodyService.luau
- armour.py
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Hud.luau
- WarzoneService.luau
- decor.py
- SlayingService.luau
- os
- os
- BlockWorld.set
- WarzoneService.luau
- FirstPersonController.luau
- math
- Town & Worlds
- snapshot
- HeldController.luau
- Inbox
- BlockController.luau
- blocks.py
- replicatedstorage_shared_items
- Inventory.luau
- Economy & Values
- script_parent_stateservice
- MobService.luau
- json
- AmbientController.luau
- Theme.corner
- IslandService.luau
- BoostService.luau
- Tools & Stack
- build_tier
- Worlds/Mining.luau
- DecorModels.Place
- Main.server.luau
- Late-game proposal (2026-10-29)
- new_verts
- replicatedstorage_shared_remotes
- crate_rays.py
- Crafting Proposal (2026-10-31, APPROVED as written the same night)
- Boards.luau
- Decision Log
- Window.luau
- Build.luau
- Loot head: your loot drops in your avatar's head on death
- build
- CombatService.luau
- replicatedstorage_shared_blocks
- Signs.luau
- SkydropService.luau
- VisitService.luau
- Kits
- Islands (Roblox)
- BlockWorld.position
- QuestService.luau
- UI study (2026-10-29)
- Published privately as Sky Farm Prototype
- Woodcutting phase: build plan (2026-11-02)
- onFarmClick
- SkydropController.luau
- Farming phase: build plan (2026-11-02)
- Blocks.luau
- .hexagon
- KitPowerController.luau
- Combat & Gear Plan (2026-11-03)
- arc
- VitalsHud.luau
- Decision: block toughness + tool power (Minecraft rules)
- Skills & Levels
- Piece
- KitPowerController.luau
- onBuy
- onOpen
- Boosts.Has
- TrophyModels.luau
- ShopService.Start
- SwimController.luau
- HotbarService.luau
- Hotbar.luau
- Farming.luau
- items3d.py
- .leaf
- Mining phase: build plan (2026-10-31)
- Skybounds (Minecraft)
- chest_venomfang
- Warzone rebuild plan (2026-11-02)
- Slaying.luau
- SettingsWindow.luau
- CrateOpening.luau
- sys
- FlightController.luau
- script_parent_tools
- BoostWindow.luau
- The late-game rule (your call, 2026-11-02)
- Economy.luau
- IslandWindow.luau
- Props.luau
- Auction House & Profiles
- sword_fit/README.md
- MobController.luau
- build
- Logo.luau
- Npc.luau
- gem_bench
- Slaying plan (2026-11-02, approved with your changes)
- lerp_frame
- Skydrops.luau
- goHome
- Boost Crystals
- BoostService.TestReceipt
- monster_art.py
- Skybounds Boost Gems (your reference, sent 2026-11-10)
- SprintController.luau
- Decision: buy bigger islands with coins (4 tiers)
- (2026-11-03, session 10): new shield, four armour pieces, equipment in the Bag

## God Nodes (most connected - your core abstractions)
1. `Handoff` - 68 edges
2. `Theme.make()` - 63 edges
3. `Piece` - 55 edges
4. `Builder` - 34 edges
5. `Theme.corner()` - 31 edges
6. `Decision Log` - 30 edges
7. `scene_world()` - 26 edges
8. `Theme.text()` - 25 edges
9. `noisy()` - 24 edges
10. `scene_icon()` - 23 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
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

## Communities (147 total, 38 thin omitted)

### Community 0 - "CombatController.luau"
Cohesion: 0.15
Nodes (15): aimedCharacter(), attack(), CombatController.Start(), cooldownOf(), faceTarget(), flash(), isFalling(), onHitEffect() (+7 more)

### Community 1 - "Theme.make"
Cohesion: 0.18
Nodes (36): buildGui(), CrateOpening.Start(), makeCard(), ItemIcon.create(), Theme.badge(), Theme.bar(), Theme.button(), Theme.card() (+28 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.13
Nodes (17): build(), Ambience.Apply(), Ambience.Warzone(), ensure(), BlockWorld.drawAll(), BlockWorld.partCount(), buried(), exposed() (+9 more)

### Community 3 - "CraftingService.luau"
Cohesion: 0.22
Nodes (15): buildGrid(), check(), choose(), CraftingWindow.SetState(), CraftingWindow.Start(), ingredientChip(), levelOf(), render() (+7 more)

### Community 4 - "numpy"
Cohesion: 0.11
Nodes (16): all_obstacles(), armour_piece(), armoured(), bare_body(), box(), extras(), place(), read_carries() (+8 more)

### Community 5 - "numpy"
Cohesion: 0.13
Nodes (17): downscale(), load_blocks(), over(), read_image(), render_icons(), setup_lights(), with_outline(), write_image() (+9 more)

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "DecorService.luau"
Cohesion: 0.18
Nodes (21): attach(), checkHeld(), checkSharing(), decorAt(), DecorService.InTall(), DecorService.OpenNewSign(), drawRails(), drawWords() (+13 more)

### Community 8 - "Common.luau"
Cohesion: 0.14
Nodes (28): buildArrival(), BlockWorld.setRaw(), Decor.Lantern(), Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom() (+20 more)

### Community 9 - "BodyService.luau"
Cohesion: 0.10
Nodes (12): BodyService.Copy(), BodyService.Drop(), BodyService.Lifetime(), fallingWay(), fetchAvatar(), isAny(), prepare(), shapeOf() (+4 more)

### Community 10 - "armour.py"
Cohesion: 0.09
Nodes (36): boot_base(), boot_emberguard(), boot_farming(), boot_frostwarden(), boot_sunforged(), boot_venomfang(), boot_woodcutting(), chest_frostwarden() (+28 more)

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.03
Nodes (60): (2026-10-31 ~22:45, session 7): published scooping, swimming done, crafting approved, (2026-10-31 night): scooping restored, committed, NOT published, (2026-11-01 ~21:30, session 7): crafting + Mining phase tested, committed and PUBLISHED, store art live, (2026-11-02, session 8, earlier): Woodcutting phase built and playtested, (2026-11-02, session 8, last): the Warzone prototype was rejected, (2026-11-02, session 8): late-game rework, Warzone and billion-coin scale tested in Studio; NOT committed, NOT published, (2026-11-02, session 9): the real Warzone map is built, (2026-11-03, session 11, earlier): Night Glass on every window, shield really held (+52 more)

### Community 12 - "Hud.luau"
Cohesion: 0.15
Nodes (16): buildToasts(), drawSliders(), fadeLabel(), Hud.Celebrate(), Hud.CrystalsAvailable(), Hud.Render(), Hud.SetFreeCrystals(), Hud.Toast() (+8 more)

### Community 13 - "WarzoneService.luau"
Cohesion: 0.14
Nodes (20): finishLeaving(), fitHealth(), humanoidOf(), inSafeZone(), isSafeSpot(), maxHealthOf(), onFell(), playSound() (+12 more)

### Community 14 - "decor.py"
Cohesion: 0.06
Nodes (23): awning(), awning_stripe(), bounds(), build_models(), cactus(), cactus_icon(), jack_face(), jack_face_only() (+15 more)

### Community 15 - "SlayingService.luau"
Cohesion: 0.07
Nodes (29): fadeTo(), MusicController.Start(), newSound(), greet(), NpcController.Start(), track(), update(), allowed() (+21 more)

### Community 16 - "os"
Cohesion: 0.17
Nodes (16): crate_body(), crate_lid(), dais(), main(), preview(), rune(), Builder, marker() (+8 more)

### Community 17 - "os"
Cohesion: 0.22
Nodes (17): build_atlas(), main(), export_fbx(), hex_rgb(), material(), mesh_object(), render_preview(), reset_scene() (+9 more)

### Community 18 - "BlockWorld.set"
Cohesion: 0.25
Nodes (11): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, checkOwned(), GearService.Start(), removePet(), IslandService.PlaceNode(), respawnNodes(), regrow(), BlockWorld.occupied() (+3 more)

### Community 19 - "WarzoneService.luau"
Cohesion: 0.12
Nodes (28): aura(), buffOn(), chainLightning(), clearLine(), closest(), current(), freezePlayer(), frostNova() (+20 more)

### Community 20 - "FirstPersonController.luau"
Cohesion: 0.35
Nodes (12): add(), addArm(), addHeld(), build(), clearRig(), copyOf(), hideReal(), keyFor() (+4 more)

### Community 21 - "math"
Cohesion: 0.06
Nodes (72): (2026-11-08): real-footage thumbnails, and the rival, add_mesh(), anvil_mesh(), Assets, blur(), box(), camera(), caption() (+64 more)

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "snapshot"
Cohesion: 0.18
Nodes (9): Better rewards as skills level up, held(), onOpen(), snapshot(), title(), ProgressionService.AddPlayerXP(), Leveling.PlantedTrees(), Leveling.PlayerXPToNext() (+1 more)

### Community 24 - "HeldController.luau"
Cohesion: 0.09
Nodes (25): swing(), HeldController.Holding(), HeldController.Start(), HeldController.Swing(), moveHeld(), moveItem(), moveSword(), ownHeld() (+17 more)

### Community 29 - "BlockController.luau"
Cohesion: 0.23
Nodes (10): Decision: click-only farming, aim(), aimedLootChest(), aimedSealed(), aimedShop(), redeemHeld(), rootPosition(), screenRay() (+2 more)

### Community 30 - "blocks.py"
Cohesion: 0.11
Nodes (32): bricks_tile(), clamp(), draw_building_tiles(), planks_tile(), draw_deep_ore_tiles(), clumps(), crystals(), darker() (+24 more)

### Community 32 - "replicatedstorage_shared_items"
Cohesion: 0.06
Nodes (15): BagWindow.SetState(), buildCrafting(), buildSlots(), equippedKey(), doneCount(), stateOf(), howClicked(), listOf() (+7 more)

### Community 33 - "Inventory.luau"
Cohesion: 0.30
Nodes (7): Inventory.Across(), Inventory.Insert(), Inventory.MaxStack(), Inventory.Move(), Inventory.QuickMove(), Inventory.RoomFor(), isGear()

### Community 34 - "Economy & Values"
Cohesion: 0.20
Nodes (10): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The Auction House (2026-11-10), The billion scale (your call, 2026-11-02), The rules, Tools (new, full durability) (+2 more)

### Community 36 - "script_parent_stateservice"
Cohesion: 0.12
Nodes (8): BodyService.Start(), clean(), deliver(), InboxService.Send(), InboxService.Start(), onOverflow(), grant(), onReceipt()

### Community 37 - "MobService.luau"
Cohesion: 0.21
Nodes (15): addPlate(), build(), chase(), hurt(), loop(), MobService.ReachOf(), MobService.Spawn(), MobService.Start() (+7 more)

### Community 39 - "json"
Cohesion: 0.09
Nodes (12): main(), run(), rot(), main(), merge_color_groups(), real_notes(), is_published(), main() (+4 more)

### Community 41 - "Theme.corner"
Cohesion: 0.18
Nodes (22): buildCelebration(), buildMenu(), buildStatus(), drawMenuBars(), squareButton(), show(), edge(), Glass.button() (+14 more)

### Community 42 - "IslandService.luau"
Cohesion: 0.11
Nodes (31): (session 6) islands as build areas DONE in Studio, Decision: falling off returns you to your island, islandArea(), treeFell(), announce(), build(), clampTier(), fell() (+23 more)

### Community 43 - "BoostService.luau"
Cohesion: 0.24
Nodes (17): BoostService.Refresh(), BoostService.SetTest(), canReset(), changed(), giveBought(), holding(), onAdd(), onBuy() (+9 more)

### Community 45 - "Tools & Stack"
Cohesion: 0.23
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 46 - "build_tier"
Cohesion: 0.15
Nodes (13): build_tier(), leaves(), main(), outline(), plot_positions(), radius_at(), ring(), rock() (+5 more)

### Community 47 - "Worlds/Mining.luau"
Cohesion: 0.22
Nodes (11): ctx.Noise(), hillHeight(), roughDistance(), chamber(), ck(), findCaves(), mountainHeights(), rough() (+3 more)

### Community 48 - "DecorModels.Place"
Cohesion: 0.17
Nodes (14): LATEST (2026-11-04, session 15, night): THE BUILDER SELLS DECORATIONS; START HERE, Decor.Flower(), Decor.Grass(), Decor.LampPost(), Decor.Piece(), Decor.WallLantern(), part(), DecorModels.Get() (+6 more)

### Community 52 - "Late-game proposal (2026-10-29)"
Cohesion: 0.22
Nodes (9): 1. New resources (13), 2. New tool tiers (2, x 5 kinds = 10 tools), 3. Big things to buy (10M–50M), 4. The order to build it in, Farming: four new zone islands (4), Late-game proposal (2026-10-29), Mining: a deeper cave under the Gold Chamber (5), Questions (+1 more)

### Community 53 - "new_verts"
Cohesion: 0.16
Nodes (12): axe(), thickness(), handle(), hoe(), new_verts(), pickaxe(), build_head(), z_at() (+4 more)

### Community 54 - "replicatedstorage_shared_remotes"
Cohesion: 0.09
Nodes (5): blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual()

### Community 55 - "crate_rays.py"
Cohesion: 0.11
Nodes (10): main(), preview(), swatch_uv(), to_blender(), write_palette(), alpha(), chunk(), icon() (+2 more)

### Community 56 - "Crafting Proposal (2026-10-31, APPROVED as written the same night)"
Cohesion: 0.33
Nodes (6): Crafting Proposal (2026-10-31, APPROVED as written the same night), New stations, Questions, The ladder, The rule, What it adds

### Community 57 - "Boards.luau"
Cohesion: 0.40
Nodes (4): boardsState(), Boards.CurrentIndex(), c(), rewardCoins()

### Community 58 - "Decision Log"
Cohesion: 0.19
Nodes (15): NPC visits at milestones with a starter pack, Warzone parked until it moves into Town, Content Index, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Decision Log, Open Questions (+7 more)

### Community 59 - "Window.luau"
Cohesion: 0.12
Nodes (18): setBlur(), showHud(), Window.close(), Window.open(), Window.setTitle(), Window.toggle(), BagWindow.Toggle(), BoostWindow.Open() (+10 more)

### Community 60 - "Build.luau"
Cohesion: 0.27
Nodes (8): set(), setFree(), top(), Build.Fill(), Build.Set(), Build.SetFree(), Build.Top(), pick()

### Community 61 - "Loot head: your loot drops in your avatar's head on death"
Cohesion: 0.25
Nodes (7): Trading shut down after a duplication exploit [Unverified], Maturity rating of combat [open check], Skybounds: your head drops on death with your loot, Loot head: your loot drops in your avatar's head on death, Raid bag + extraction pads, ProfileStore (player data with session locking), Loot head rules: how much, who opens first, despawn

### Community 62 - "build"
Cohesion: 0.29
Nodes (12): Theme.chip(), addChip(), build(), copyOf(), pose(), ProfileWindow.SetState(), ProfileWindow.Start(), render() (+4 more)

### Community 64 - "replicatedstorage_shared_blocks"
Cohesion: 0.08
Nodes (7): liquidAt(), touches(), besideSpawner(), check(), SpawnerService.Start(), LiquidModels.Make(), make()

### Community 65 - "Signs.luau"
Cohesion: 0.36
Nodes (11): boardHeight(), inkFor(), longest(), plank(), roughBoard(), Signs.Arrows(), Signs.Board(), Signs.Gateway() (+3 more)

### Community 66 - "SkydropService.luau"
Cohesion: 0.07
Nodes (20): changed(), ChestService.CloseAll(), ChestService.CloseFor(), ChestService.Open(), closeFor(), isIndex(), placeOf(), send() (+12 more)

### Community 67 - "VisitService.luau"
Cohesion: 0.24
Nodes (4): IslandService.OwnerAt(), hostOf(), rootOf(), visitedBy()

### Community 68 - "Kits"
Cohesion: 0.22
Nodes (9): Armour kits (started 2026-11-09), How crates should roll (your call, 2026-11-09), Kits, Our version (proposal), Rule to design around, Still to decide, What Looter was in Skybounds, What the Skybounds kits came with (your list, sent 2026-11-02) (+1 more)

### Community 69 - "Islands (Roblox)"
Cohesion: 0.10
Nodes (19): Design Pillars, Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands (+11 more)

### Community 71 - "BlockWorld.position"
Cohesion: 0.24
Nodes (10): inReach(), portalFields(), BlockWorld.position(), makeDecor(), makePart(), template(), Portal.addCells(), Portal.makeClosed() (+2 more)

### Community 72 - "QuestService.luau"
Cohesion: 0.20
Nodes (16): boardCurrent(), checkReach(), complete(), completeBoard(), currentQuest(), giveReward(), QuestService.Record(), reachValue() (+8 more)

### Community 73 - "UI study (2026-10-29)"
Cohesion: 0.40
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

### Community 79 - "Blocks.luau"
Cohesion: 0.18
Nodes (3): Decision: Minecraft-style block islands (break and place, saved), Combat.Armor(), Combat.Charge()

### Community 80 - ".hexagon"
Cohesion: 0.17
Nodes (12): band(), chest_farming(), chest_mining(), chest_stormcaller(), chest_woodcutting(), coat(), helmet_mining(), helmet_woodcutting() (+4 more)

### Community 81 - "KitPowerController.luau"
Cohesion: 0.19
Nodes (4): keyLabel(), PromptUI.Start(), aimHighlight(), QuestTracker.Render()

### Community 82 - "Combat & Gear Plan (2026-11-03)"
Cohesion: 0.17
Nodes (10): Gear references, Armour art, Armour numbers, Combat & Gear Plan (2026-11-03), Combat: real Minecraft rules, First person, Health, armour and hunger on screen, Sprinting (+2 more)

### Community 83 - "arc"
Cohesion: 0.17
Nodes (6): arc(), front_slab(), rope(), ui_bag(), ui_mail(), ui_trophy()

### Community 84 - "VitalsHud.luau"
Cohesion: 0.48
Nodes (6): Hotbar.Bar(), fill(), makeRow(), setCell(), VitalsHud.SetState(), VitalsHud.Start()

### Community 85 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.50
Nodes (3): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: block toughness + tool power (Minecraft rules)

### Community 86 - "Skills & Levels"
Cohesion: 0.13
Nodes (28): Target Audience, Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added), Anti-Burnout Ideas, Prestige with real unlocks (+20 more)

### Community 87 - "Piece"
Cohesion: 0.09
Nodes (22): bolt(), boot_mining(), boot_stormcaller(), burst(), cloud(), forearm_farming(), forearm_mining(), forearm_stormcaller() (+14 more)

### Community 88 - "KitPowerController.luau"
Cohesion: 0.31
Nodes (5): aimed(), fire(), heldSpecial(), KitPowerController.RightClick(), secondsLeft()

### Community 89 - "onBuy"
Cohesion: 0.23
Nodes (11): atAuctioneer(), begin(), finish(), mayTrade(), onBuy(), onOpen(), sendState(), TownService.GetAuctioneers() (+3 more)

### Community 90 - "onOpen"
Cohesion: 0.18
Nodes (8): (end of session 18, 2026-11-09): paused by you before the crate animation and the kit specials, loot_crate(), AwardService.Give(), AwardService.Start(), onOpen(), arrive(), LootCrates.Roll(), pick()

### Community 91 - "Boosts.Has"
Cohesion: 0.31
Nodes (9): apply(), BoostService.Start(), KitService.HandleProduct(), MobService.Damage(), Boosts.GrowTime(), Boosts.Has(), Boosts.Level(), Boosts.NodeTime() (+1 more)

### Community 92 - "TrophyModels.luau"
Cohesion: 0.09
Nodes (29): addCamera(), armorIcon(), halfExtents(), modelIcon(), picture(), viewport(), dress(), spawnPet() (+21 more)

### Community 93 - "ShopService.Start"
Cohesion: 0.40
Nodes (3): ShopService.Start(), TownService.GetShopkeepers(), Prompts.Create()

### Community 94 - "SwimController.luau"
Cohesion: 0.33
Nodes (10): add(), anyDown(), characterParts(), columnSurface(), over(), startSwimming(), step(), stopSwimming() (+2 more)

### Community 95 - "HotbarService.luau"
Cohesion: 0.33
Nodes (8): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isIndex(), onMoveStack(), onQuickMove(), onSelectSlot(), refreshHeld()

### Community 96 - "Hotbar.luau"
Cohesion: 0.29
Nodes (9): Decision: 5-slot Minecraft-style hotbar, FirstPersonController.Start(), setForced(), HeldController.OnSwing(), Hotbar.Select(), Hotbar.Selected(), Hotbar.SelectedItem(), showName() (+1 more)

### Community 97 - "Farming.luau"
Cohesion: 0.36
Nodes (7): crossPathZ(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), veggiePathZ(), wave()

### Community 99 - "items3d.py"
Cohesion: 0.04
Nodes (27): anvil(), bucket(), build_icon_models(), build_items(), carrot(), dragonfruit(), gem_cluster(), iron_plate() (+19 more)

### Community 100 - ".leaf"
Cohesion: 0.25
Nodes (5): forearm_base(), forearm_woodcutting(), pauldron_base(), pauldron_woodcutting(), sleeve_woodcutting()

### Community 103 - "Mining phase: build plan (2026-10-31)"
Cohesion: 0.29
Nodes (7): Art, Mining phase: build plan (2026-10-31), Order, Slivers and nodes, The deep cave (Worlds/Mining.luau), The ores (the deep cave, under the Gold Chamber), Tool tiers and parts (from the Crafting Proposal)

### Community 106 - "Skybounds (Minecraft)"
Cohesion: 0.10
Nodes (19): Mobile-first UI, Full albums (sent 2026-10-28, from imgur), Skybounds reference shots, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft), Skybounds seasons: 2-4 months, level resets, Skybounds (Minecraft Skyblock server, now shut down) (+11 more)

### Community 107 - "chest_venomfang"
Cohesion: 0.25
Nodes (6): chest_emberguard(), chest_sunforged(), chest_venomfang(), kit_tails(), scales(), sun()

### Community 108 - "Warzone rebuild plan (2026-11-02)"
Cohesion: 0.13
Nodes (13): Details seen in the photos (looked at closely 2026-11-02), Five maps, one theme each, The Skybounds Warzones, built by Team Vaeron, What they all share, What this means for our Warzone, 1. The map: Robot / sci-fi (built and walked in Studio, 2026-11-02), 2. Warzone rules, 3. Inventory and chests, whole game (+5 more)

### Community 109 - "Slaying.luau"
Cohesion: 0.09
Nodes (9): ctx.Flatten(), Shapes.Glow(), Shapes.Light(), flattenRoads(), layRoads(), beacon(), strip(), trafficCone() (+1 more)

### Community 110 - "SettingsWindow.luau"
Cohesion: 0.53
Nodes (5): applyVolumes(), save(), SettingsWindow.SetState(), SettingsWindow.Start(), slider()

### Community 111 - "CrateOpening.luau"
Cohesion: 0.18
Nodes (12): clamp01(), clearScene(), CrateOpening.Play(), cue(), glowLabel(), headingText(), outBack(), render() (+4 more)

### Community 112 - "sys"
Cohesion: 0.11
Nodes (9): matrix(), call(), read_frames(), run(), text(), add(), body_for(), camera_at() (+1 more)

### Community 113 - "FlightController.luau"
Cohesion: 0.53
Nodes (8): anyDown(), canFly(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 115 - "BoostWindow.luau"
Cohesion: 0.67
Nodes (5): askPrice(), BoostWindow.SetGameState(), BoostWindow.SetState(), plural(), refresh()

### Community 116 - "The late-game rule (your call, 2026-11-02)"
Cohesion: 0.50
Nodes (4): How you get things, The coin targets: settled, The late-game rule (your call, 2026-11-02), What this changed

### Community 117 - "Economy.luau"
Cohesion: 0.29
Nodes (3): Economy.Total(), Economy.Value(), work()

### Community 118 - "IslandWindow.luau"
Cohesion: 0.43
Nodes (6): Window.clear(), areaRow(), card(), IslandWindow.SetState(), render(), setSlot()

### Community 119 - "Props.luau"
Cohesion: 0.38
Nodes (4): baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents()

### Community 120 - "Auction House & Profiles"
Cohesion: 0.33
Nodes (6): Auction House & Profiles, Player profiles, Tested (Studio, 2026-11-10), The Auction House, Trading anywhere, aimedPlayer()

### Community 122 - "MobController.luau"
Cohesion: 0.60
Nodes (5): animate(), fade(), forget(), MobController.Start(), track()

### Community 123 - "build"
Cohesion: 0.40
Nodes (6): build(), Theme.edge(), Theme.isPhone(), Theme.lighten(), Window.hideWhenCovered(), SkillsWindow.Start()

### Community 124 - "Logo.luau"
Cohesion: 0.53
Nodes (3): cloud(), layer(), Logo.Build()

### Community 125 - "Npc.luau"
Cohesion: 0.60
Nodes (3): addNameTag(), Npc.Build(), Npc.NameTag()

### Community 128 - "Slaying plan (2026-11-02, approved with your changes)"
Cohesion: 0.50
Nodes (4): Slaying plan (2026-11-02, approved with your changes), The idea, What comes with it, Zones and monsters

### Community 137 - "goHome"
Cohesion: 0.67
Nodes (3): IslandService.SendHome(), goHome(), sendState()

### Community 138 - "Boost Crystals"
Cohesion: 0.40
Nodes (5): Boost Crystals, Built (2026-11-10), Fairness, How it works, The boosts (your list, with the leave at 5 s)

### Community 143 - "SprintController.luau"
Cohesion: 0.83
Nodes (3): lean(), moving(), SprintController.Start()

## Knowledge Gaps
- **14 isolated node(s):** `Roleplay + simulator hybrids growing [Unverified]`, `Inbox`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 624 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **38 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `BlockWorld.set` to `Handoff (updated 2026-10-27 ~22:35, session 4)`, `blocks.py`?**
  _High betweenness centrality (0.286) - this node is a cross-community bridge._
- **Are the 45 inferred relationships involving `Theme.make()` (e.g. with `buildGui()` and `CrateOpening.Start()`) actually correct?**
  _`Theme.make()` has 45 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Roleplay + simulator hybrids growing [Unverified]`, `Inbox`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `BlockWorld.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.12666666666666668 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `BlockWorld.set`, `math`?**
  _High betweenness centrality (0.274) - this node is a cross-community bridge._
- **Should `numpy` be split into smaller, more focused modules?**
  _Cohesion score 0.10574712643678161 - nodes in this community are weakly interconnected._
- **Why does `respawnNodes()` connect `BlockWorld.set` to `IslandService.luau`, `DecorService.luau`?**
  _High betweenness centrality (0.149) - this node is a cross-community bridge._