# Graph Report - Roblox  (2026-11-11)

## Corpus Check
- 270 files · ~385,542 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 2382 nodes · 5586 edges · 173 communities (128 shown, 45 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 950 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c861ad49`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- CombatController.luau
- Theme.make
- BlockWorld.luau
- CraftingService.luau
- numpy
- render_icons
- balance.py
- DecorService.luau
- Common.luau
- BodyService.luau
- armour.py
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Hud.luau
- store_art.py
- decor.py
- WarzoneService.luau
- os
- os
- MobService.luau
- KitPowerService.luau
- FirstPersonController.luau
- math
- Town & Worlds
- Leveling.luau
- HeldController.luau
- Inbox
- BlockController.luau
- blocks.py
- replicatedstorage_shared_items
- HotbarService.luau
- Economy & Values
- Signs.luau
- CrateService.luau
- SlayingService.luau
- json
- AmbientController.luau
- Window.luau
- IslandService.luau
- BoostService.luau
- Tools & Stack
- build_tier
- hero
- DecorModels.Place
- AuctionService.luau
- Late-game proposal (2026-10-29)
- new_verts
- BlockService.luau
- crate_rays.py
- Crafting Proposal (2026-10-31, APPROVED as written the same night)
- Main.server.luau
- Decision Log
- numpy
- render.py
- IslandWindow.luau
- ProfileWindow.luau
- Props.luau
- TownService.luau
- Islands (Roblox)
- SkydropService.luau
- ShopService.luau
- Kits
- Warzone
- Logo.luau
- QuestService.luau
- UI study (2026-10-29)
- Published privately as Sky Farm Prototype
- Woodcutting phase: build plan (2026-11-02)
- onFarmClick
- SkydropController.luau
- Farming phase: build plan (2026-11-02)
- Worlds/Mining.luau
- .hexagon
- KitPowerController.luau
- Combat & Gear Plan (2026-11-03)
- arc
- VitalsHud.luau
- InboxService.luau
- Monetization Principles
- Piece
- Build.luau
- json
- tiktok_day100.py
- badge_icons.ps1
- put
- os
- SwimController.luau
- loot_crate
- Hotbar.luau
- Skybounds/README.md
- items3d.py
- .leaf
- Mining phase: build plan (2026-10-31)
- Loot head: your loot drops in your avatar's head on death
- chest_venomfang
- Warzone rebuild plan (2026-11-02)
- script_parent_parent_util_blockworld
- CombatService.luau
- TravelService.luau
- record.py
- FlightController.luau
- build
- Farming.luau
- The late-game rule (your call, 2026-11-02)
- BetaTagController.luau
- SprintService.luau
- dragonfruit
- Auction House & Profiles
- sword_fit/README.md
- .build_world
- Glass.text
- gem_cluster
- replicatedstorage_shared_places
- pumpkin
- gem_bench
- Slaying plan (2026-11-02, approved with your changes)
- twine
- shield
- sapling
- Boost Crystals
- sliver
- starstone
- Skybounds Boost Gems (your reference, sent 2026-11-10)
- SprintController.luau
- sugarcane
- strawberry
- VisitService.luau
- SettingsWindow.luau
- Boards.luau
- lowpoly.py
- Decision: block toughness + tool power (Minecraft rules)
- store_footage.py
- Policy.luau
- HotbarService.luau
- replicatedstorage_shared_monsters
- Decision: buy bigger islands with coins (4 tiers)
- GearService.luau
- crate_open.py
- tiktok_crate.py
- replicatedstorage_shared_gear
- BlockWorld.set
- ItemIcon.luau
- StationModels.luau
- Level gates: crops need Farming level, mobs need Combat level
- tune.py
- MobController.luau
- ShieldModel.luau
- TrophyModels.luau
- warzone_sky.py
- Portal.luau
- real_check.py
- castle

## God Nodes (most connected - your core abstractions)
1. `Handoff` - 79 edges
2. `Theme.make()` - 64 edges
3. `Piece` - 55 edges
4. `Builder` - 34 edges
5. `Theme.corner()` - 31 edges
6. `Decision Log` - 31 edges
7. `scene_world()` - 26 edges
8. `noisy()` - 24 edges
9. `scene_icon()` - 23 edges
10. `Theme.text()` - 23 edges

## Surprising Connections (you probably didn't know these)
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `START HERE (2026-11-11, later): more TikToks with sound rendering; Discord still waiting on your login` --references--> `encode()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/tiktok_day100.py
- `TOMORROW: your notes (2026-10-26 night, with screenshots of the mine, Woodcutting and Farming)` --references--> `regrow()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Session 4, part 3 (2026-10-27 ~22:30): harvest tools, starter hoe and Inbox done and playtested, committed as `b66c289` (harvest wear removed later in part 4)` --references--> `onFarmClick()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/server/Services/WorldService.luau
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Seasonal progression: quests -> player level -> Warzone unlock -> season reset** — 03_design_tutorial_quests_quest_chain, 03_design_skills_levels_player_level, 03_design_skills_levels_warzone_unlock_10, 03_design_skills_levels_season_reset [EXTRACTED 1.00]
- **Warzone risk loop: drop in, loot, extract or lose it** — 03_design_core_loop_warzone_loop, 03_design_warzone_raid_bag, 03_design_warzone_loot_head, 03_design_warzone_warzone_zones, game_src_server_services_warzoneservice [EXTRACTED 1.00]
- **Tool power + block toughness system** — game_src_shared_tools, game_src_shared_mining, game_src_shared_blocks, game_src_server_services_blockservice, game_src_client_blockcontroller, 07_roadmap_decision_log_dec_toughness [INFERRED 0.95]

## Communities (173 total, 45 thin omitted)

### Community 0 - "CombatController.luau"
Cohesion: 0.18
Nodes (13): aimedCharacter(), attack(), CombatController.Start(), cooldownOf(), faceTarget(), flash(), isFalling(), onHitEffect() (+5 more)

### Community 1 - "Theme.make"
Cohesion: 0.21
Nodes (38): makeBoard(), buildGui(), ItemIcon.create(), Theme.badge(), Theme.bar(), Theme.button(), Theme.card(), Theme.chip() (+30 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.18
Nodes (12): BlockWorld.position(), buried(), exposed(), fits(), makeDecor(), makePart(), mergeScenery(), occludes() (+4 more)

### Community 3 - "CraftingService.luau"
Cohesion: 0.22
Nodes (14): check(), choose(), CraftingWindow.SetState(), CraftingWindow.Start(), ingredientChip(), levelOf(), render(), renderDetail() (+6 more)

### Community 4 - "numpy"
Cohesion: 0.09
Nodes (24): all_obstacles(), armour_piece(), armoured(), bare_body(), box(), extras(), frame(), lerp_frame() (+16 more)

### Community 5 - "render_icons"
Cohesion: 0.17
Nodes (10): downscale(), load_blocks(), over(), read_image(), render_icon(), render_icons(), setup_lights(), with_outline() (+2 more)

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "DecorService.luau"
Cohesion: 0.18
Nodes (21): attach(), checkHeld(), checkSharing(), decorAt(), DecorService.InTall(), DecorService.OpenNewSign(), drawRails(), drawWords() (+13 more)

### Community 8 - "Common.luau"
Cohesion: 0.16
Nodes (25): Common.Arrows(), Common.Boulder(), Common.CliffVines(), Common.Forest(), Common.GiantMushroom(), Common.Lamp(), Common.Path(), Common.Pond() (+17 more)

### Community 9 - "BodyService.luau"
Cohesion: 0.13
Nodes (15): BodyService.Copy(), BodyService.Drop(), BodyService.Lifetime(), BodyService.Start(), dress(), fallingWay(), fetchAvatar(), isAny() (+7 more)

### Community 10 - "armour.py"
Cohesion: 0.09
Nodes (36): boot_base(), boot_emberguard(), boot_farming(), boot_frostwarden(), boot_sunforged(), boot_venomfang(), boot_woodcutting(), chest_frostwarden() (+28 more)

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.03
Nodes (70): (2026-10-31 ~22:45, session 7): published scooping, swimming done, crafting approved, (2026-10-31 night): scooping restored, committed, NOT published, (2026-11-01 ~21:30, session 7): crafting + Mining phase tested, committed and PUBLISHED, store art live, (2026-11-02, session 8, earlier): Woodcutting phase built and playtested, (2026-11-02, session 8, last): the Warzone prototype was rejected, (2026-11-02, session 8): late-game rework, Warzone and billion-coin scale tested in Studio; NOT committed, NOT published, (2026-11-02, session 9): the real Warzone map is built, (2026-11-03, session 11, earlier): Night Glass on every window, shield really held (+62 more)

### Community 12 - "Hud.luau"
Cohesion: 0.09
Nodes (27): clear(), landedCount(), outQuart(), show(), showEnd(), spin(), step(), buildCelebration() (+19 more)

### Community 13 - "store_art.py"
Cohesion: 0.11
Nodes (25): blur(), caption(), cave_shell(), finish_icon(), logo(), main(), n2(), over() (+17 more)

### Community 14 - "decor.py"
Cohesion: 0.06
Nodes (20): awning(), awning_stripe(), bounds(), build_models(), cactus(), cactus_icon(), jack_face(), jack_face_only() (+12 more)

### Community 15 - "WarzoneService.luau"
Cohesion: 0.14
Nodes (20): finishLeaving(), fitHealth(), humanoidOf(), inSafeZone(), isSafeSpot(), maxHealthOf(), onFell(), playSound() (+12 more)

### Community 16 - "os"
Cohesion: 0.21
Nodes (13): dais(), build_icon_models(), build_items(), Builder, marker(), matrix(), crops(), far_crops() (+5 more)

### Community 17 - "os"
Cohesion: 0.24
Nodes (15): make_block(), make_merged(), quad(), tile_rect(), hex_rgb(), material(), mesh_object(), bridge() (+7 more)

### Community 18 - "MobService.luau"
Cohesion: 0.20
Nodes (16): addPlate(), build(), chase(), hurt(), loop(), MobService.Freeze(), MobService.ReachOf(), MobService.Spawn() (+8 more)

### Community 19 - "KitPowerService.luau"
Cohesion: 0.22
Nodes (19): aura(), buffOn(), chainLightning(), clearLine(), closest(), current(), freezePlayer(), frostNova() (+11 more)

### Community 20 - "FirstPersonController.luau"
Cohesion: 0.28
Nodes (13): add(), addArm(), addHeld(), build(), clearRig(), copyOf(), FirstPersonController.SetCharge(), hideReal() (+5 more)

### Community 21 - "math"
Cohesion: 0.12
Nodes (29): (2026-11-08): real-footage thumbnails, and the rival, camera(), crystals(), finish(), gem(), island(), item(), lamp() (+21 more)

### Community 22 - "Town & Worlds"
Cohesion: 0.25
Nodes (8): New blocks (2026-10-25), Not done yet, Research: how the hubs we're borrowing from look, The 4x pass (2026-10-28): the Grinding Worlds and Town, The resource worlds (rebuilt 2026-10-26, Skybounds-scale), The Town (hub), Town & Worlds, Zone blocks and signs (2026-10-26)

### Community 23 - "Leveling.luau"
Cohesion: 0.17
Nodes (8): Skybounds seasons: 2-4 months, level resets, Better rewards as skills level up, Player level 1-50 (XP from PvE, grinding, quests), Seasons of 2-4 months; player level resets, Level 10 unlocks the Warzone, What resets each season?, Leveling.PlantedTrees(), Leveling.SkillXPToNext()

### Community 24 - "HeldController.luau"
Cohesion: 0.11
Nodes (20): swing(), HeldController.Holding(), HeldController.Start(), HeldController.Swing(), moveHeld(), moveItem(), moveSword(), ownHeld() (+12 more)

### Community 29 - "BlockController.luau"
Cohesion: 0.33
Nodes (9): aim(), aimedLootChest(), aimedSealed(), aimedShop(), placeHeldCrate(), rootPosition(), screenRay(), shopkeepers() (+1 more)

### Community 30 - "blocks.py"
Cohesion: 0.13
Nodes (28): bricks_tile(), clamp(), draw_building_tiles(), planks_tile(), draw_deep_ore_tiles(), clumps(), crystals(), darker() (+20 more)

### Community 32 - "replicatedstorage_shared_items"
Cohesion: 0.07
Nodes (23): BagWindow.SetState(), buildCrafting(), buildSlots(), describe(), equippedKey(), askPrice(), BoostWindow.SetGameState(), BoostWindow.SetState() (+15 more)

### Community 33 - "HotbarService.luau"
Cohesion: 0.06
Nodes (15): Decision: Minecraft-style block islands (break and place, saved), Economy.Total(), Economy.Value(), work(), Inventory.Across(), Inventory.Insert(), Inventory.MaxStack(), Inventory.Move() (+7 more)

### Community 34 - "Economy & Values"
Cohesion: 0.20
Nodes (10): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The Auction House (2026-11-10), The billion scale (your call, 2026-11-02), The rules, Tools (new, full durability) (+2 more)

### Community 35 - "Signs.luau"
Cohesion: 0.36
Nodes (11): boardHeight(), inkFor(), longest(), plank(), roughBoard(), Signs.Arrows(), Signs.Board(), Signs.Gateway() (+3 more)

### Community 36 - "CrateService.luau"
Cohesion: 0.24
Nodes (8): copyOf(), CrateService.Start(), finish(), onDone(), onPlace(), validPosition(), LootCrates.Roll(), pick()

### Community 37 - "SlayingService.luau"
Cohesion: 0.15
Nodes (13): allowed(), checkPlayer(), notice(), onFell(), SlayingService.Setup(), spawnFor(), turnBack(), zoneAt() (+5 more)

### Community 39 - "json"
Cohesion: 0.12
Nodes (8): main(), run(), is_published(), main(), pick_target(), Server, studio_list(), wait_for_studios()

### Community 41 - "Window.luau"
Cohesion: 0.13
Nodes (16): show(), setBlur(), showHud(), tellWatchers(), Window.anyOpen(), Window.close(), Window.open(), Window.setTitle() (+8 more)

### Community 42 - "IslandService.luau"
Cohesion: 0.11
Nodes (32): (session 6) islands as build areas DONE in Studio, Decision: falling off returns you to your island, islandArea(), announce(), build(), clampTier(), fell(), generate() (+24 more)

### Community 43 - "BoostService.luau"
Cohesion: 0.15
Nodes (27): apply(), BoostService.Refresh(), BoostService.SetTest(), BoostService.Start(), BoostService.TestReceipt(), canReset(), changed(), giveBought() (+19 more)

### Community 45 - "Tools & Stack"
Cohesion: 0.21
Nodes (13): Blender driven by Python scripts, ProfileStore (player data with session locking), Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import (+5 more)

### Community 46 - "build_tier"
Cohesion: 0.31
Nodes (8): build_tier(), leaves(), outline(), plot_positions(), radius_at(), ring(), rock(), tree()

### Community 47 - "hero"
Cohesion: 0.16
Nodes (13): add_mesh(), anvil_mesh(), Assets, box(), face_parts(), part(), flat(), glow() (+5 more)

### Community 48 - "DecorModels.Place"
Cohesion: 0.15
Nodes (16): LATEST (2026-11-04, session 15, night): THE BUILDER SELLS DECORATIONS; START HERE, buildArrival(), Decor.Flower(), Decor.Grass(), Decor.LampPost(), Decor.Lantern(), Decor.Piece(), Decor.WallLantern() (+8 more)

### Community 50 - "AuctionService.luau"
Cohesion: 0.09
Nodes (14): offered(), setOffer(), atAuctioneer(), begin(), finish(), itemName(), lot(), mayTrade() (+6 more)

### Community 52 - "Late-game proposal (2026-10-29)"
Cohesion: 0.22
Nodes (9): 1. New resources (13), 2. New tool tiers (2, x 5 kinds = 10 tools), 3. Big things to buy (10M–50M), 4. The order to build it in, Farming: four new zone islands (4), Late-game proposal (2026-10-29), Mining: a deeper cave under the Gold Chamber (5), Questions (+1 more)

### Community 53 - "new_verts"
Cohesion: 0.16
Nodes (12): axe(), thickness(), handle(), hoe(), new_verts(), pickaxe(), build_head(), z_at() (+4 more)

### Community 54 - "BlockService.luau"
Cohesion: 0.06
Nodes (12): Decision: click-only farming, inReach(), treeFell(), blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual() (+4 more)

### Community 55 - "crate_rays.py"
Cohesion: 0.11
Nodes (10): main(), preview(), swatch_uv(), to_blender(), write_palette(), alpha(), chunk(), icon() (+2 more)

### Community 56 - "Crafting Proposal (2026-10-31, APPROVED as written the same night)"
Cohesion: 0.33
Nodes (6): Crafting Proposal (2026-10-31, APPROVED as written the same night), New stations, Questions, The ladder, The rule, What it adds

### Community 57 - "Main.server.luau"
Cohesion: 0.10
Nodes (5): Trading shut down after a duplication exploit [Unverified], BetaService.Start(), celebrate(), give(), onDataLoaded()

### Community 58 - "Decision Log"
Cohesion: 0.26
Nodes (9): Content Index, Decision Log, Open Questions, Prototype phase (current), Roadmap, Vertical slice, then soft launch, launch and live ops, Sync the vault with GitHub Desktop (pull before, push after), Obsidian Setup (+1 more)

### Community 59 - "numpy"
Cohesion: 0.15
Nodes (22): bed(), bell(), chime(), ding(), env(), lowpass(), lowpass_fast(), main() (+14 more)

### Community 60 - "render.py"
Cohesion: 0.43
Nodes (4): add(), body_for(), camera_at(), to_blender()

### Community 61 - "IslandWindow.luau"
Cohesion: 0.31
Nodes (8): Window.clear(), areaRow(), card(), IslandWindow.Close(), IslandWindow.SetState(), IslandWindow.Start(), render(), setSlot()

### Community 62 - "ProfileWindow.luau"
Cohesion: 0.32
Nodes (11): addChip(), build(), copyOf(), pose(), ProfileWindow.SetState(), ProfileWindow.Start(), render(), stage() (+3 more)

### Community 63 - "Props.luau"
Cohesion: 0.38
Nodes (4): baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents()

### Community 65 - "Islands (Roblox)"
Cohesion: 0.14
Nodes (14): Conveyor factories (splitters, filters, sensors), Hidden fossil collection quests, Islands (Roblox), Key-gated adventure islands, NPC visits at milestones with a starter pack, Token-summoned bosses with cooldowns, Skill-gated vending machines and handshake trading, Trading with anti-scam UI (two-step confirm, trade log) (+6 more)

### Community 66 - "SkydropService.luau"
Cohesion: 0.07
Nodes (20): changed(), ChestService.CloseAll(), ChestService.CloseFor(), ChestService.Open(), closeFor(), isIndex(), placeOf(), send() (+12 more)

### Community 67 - "ShopService.luau"
Cohesion: 0.15
Nodes (11): held(), onOpen(), snapshot(), title(), nearShop(), onBuy(), onSell(), sellItem() (+3 more)

### Community 68 - "Kits"
Cohesion: 0.22
Nodes (9): Armour kits (started 2026-11-09), How crates should roll (your call, 2026-11-09), Kits, Our version (proposal), Rule to design around, Still to decide, What Looter was in Skybounds, What the Skybounds kits came with (your list, sent 2026-11-02) (+1 more)

### Community 69 - "Warzone"
Cohesion: 0.11
Nodes (32): Design Pillars, Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Mobile-first UI, Target Audience, Islands (Roblox game by Easy.gg), 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power (+24 more)

### Community 71 - "Logo.luau"
Cohesion: 0.53
Nodes (3): cloud(), layer(), Logo.Build()

### Community 72 - "QuestService.luau"
Cohesion: 0.13
Nodes (17): AwardService.Give(), AwardService.Start(), ProgressionService.AddPlayerXP(), boardCurrent(), checkReach(), complete(), completeBoard(), currentQuest() (+9 more)

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

### Community 79 - "Worlds/Mining.luau"
Cohesion: 0.24
Nodes (11): ctx.Noise(), hillHeight(), roughDistance(), chamber(), ck(), findCaves(), mountainHeights(), rough() (+3 more)

### Community 80 - ".hexagon"
Cohesion: 0.17
Nodes (12): band(), chest_farming(), chest_mining(), chest_stormcaller(), chest_woodcutting(), coat(), helmet_mining(), helmet_woodcutting() (+4 more)

### Community 81 - "KitPowerController.luau"
Cohesion: 0.13
Nodes (10): aimed(), fire(), heldSpecial(), KitPowerController.RightClick(), secondsLeft(), keyLabel(), PromptUI.Start(), aimHighlight() (+2 more)

### Community 82 - "Combat & Gear Plan (2026-11-03)"
Cohesion: 0.17
Nodes (10): Gear references, Armour art, Armour numbers, Combat & Gear Plan (2026-11-03), Combat: real Minecraft rules, First person, Health, armour and hunger on screen, Sprinting (+2 more)

### Community 83 - "arc"
Cohesion: 0.17
Nodes (6): arc(), front_slab(), rope(), ui_bag(), ui_mail(), ui_trophy()

### Community 84 - "VitalsHud.luau"
Cohesion: 0.23
Nodes (8): Hotbar.Bar(), fill(), makeRow(), setCell(), VitalsHud.SetState(), VitalsHud.Start(), Combat.Armor(), Combat.Charge()

### Community 85 - "InboxService.luau"
Cohesion: 0.43
Nodes (5): clean(), deliver(), InboxService.Send(), InboxService.Start(), onOverflow()

### Community 86 - "Monetization Principles"
Cohesion: 0.24
Nodes (7): Younger Roblox players (Kids 5-8, Select 9-15), Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check], Paid random items need PolicyService ArePaidRandomItemsRestricted, Roblox Policies, Steal An Egg precedent (feature pulled, rule added), Monetization Principles

### Community 87 - "Piece"
Cohesion: 0.09
Nodes (22): bolt(), boot_mining(), boot_stormcaller(), burst(), cloud(), forearm_farming(), forearm_mining(), forearm_stormcaller() (+14 more)

### Community 88 - "Build.luau"
Cohesion: 0.31
Nodes (7): setFree(), top(), Build.Fill(), Build.Set(), Build.SetFree(), Build.Top(), pick()

### Community 89 - "json"
Cohesion: 0.19
Nodes (5): num(), turn(), main(), merge_color_groups(), real_notes()

### Community 90 - "tiktok_day100.py"
Cohesion: 0.12
Nodes (17): START HERE (2026-11-11, later): more TikToks with sound rendering; Discord still waiting on your login, encode(), growth(), lerp(), main(), pop_scale(), smooth(), sound_events() (+9 more)

### Community 91 - "badge_icons.ps1"
Cohesion: 0.62
Nodes (6): Add-Ring(), Add-Subject(), Cropped(), Keyed(), New-Canvas(), Save()

### Community 92 - "put"
Cohesion: 0.23
Nodes (6): put(), Trees.BigOak(), Trees.Birch(), Trees.Cherry(), Trees.Oak(), Trees.Spruce()

### Community 93 - "os"
Cohesion: 0.22
Nodes (11): build_atlas(), main(), export_fbx(), render_preview(), reset_scene(), save_blend(), main(), preview() (+3 more)

### Community 94 - "SwimController.luau"
Cohesion: 0.33
Nodes (10): add(), anyDown(), characterParts(), columnSurface(), over(), startSwimming(), step(), stopSwimming() (+2 more)

### Community 96 - "Hotbar.luau"
Cohesion: 0.23
Nodes (11): Decision: 5-slot Minecraft-style hotbar, redeemHeld(), FirstPersonController.Start(), setForced(), HeldController.OnSwing(), Hotbar.OnChanged(), Hotbar.Select(), Hotbar.Selected() (+3 more)

### Community 99 - "items3d.py"
Cohesion: 0.07
Nodes (12): anvil(), bucket(), carrot(), iron_plate(), melon(), scrap(), starfruit(), to_roblox() (+4 more)

### Community 100 - ".leaf"
Cohesion: 0.25
Nodes (5): forearm_base(), forearm_woodcutting(), pauldron_base(), pauldron_woodcutting(), sleeve_woodcutting()

### Community 103 - "Mining phase: build plan (2026-10-31)"
Cohesion: 0.29
Nodes (7): Art, Mining phase: build plan (2026-10-31), Order, Slivers and nodes, The deep cave (Worlds/Mining.luau), The ores (the deep cave, under the Gold Chamber), Tool tiers and parts (from the Crafting Proposal)

### Community 106 - "Loot head: your loot drops in your avatar's head on death"
Cohesion: 0.15
Nodes (12): Totems: passive resource generators with a range, Skybounds: your head drops on death with your loot, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers (+4 more)

### Community 107 - "chest_venomfang"
Cohesion: 0.25
Nodes (6): chest_emberguard(), chest_sunforged(), chest_venomfang(), kit_tails(), scales(), sun()

### Community 108 - "Warzone rebuild plan (2026-11-02)"
Cohesion: 0.13
Nodes (13): Details seen in the photos (looked at closely 2026-11-02), Five maps, one theme each, The Skybounds Warzones, built by Team Vaeron, What they all share, What this means for our Warzone, 1. The map: Robot / sci-fi (built and walked in Studio, 2026-11-02), 2. Warzone rules, 3. Inventory and chests, whole game (+5 more)

### Community 109 - "script_parent_parent_util_blockworld"
Cohesion: 0.10
Nodes (9): ctx.Flatten(), Shapes.Glow(), Shapes.Light(), flattenRoads(), layRoads(), beacon(), strip(), trafficCone() (+1 more)

### Community 110 - "CombatService.luau"
Cohesion: 0.16
Nodes (4): PvP only when both players are in the Warzone, besideSpawner(), check(), SpawnerService.Start()

### Community 111 - "TravelService.luau"
Cohesion: 0.22
Nodes (9): capitalized(), failed(), sendBack(), TravelService.Go(), AuctionStore.new(), inMemory(), live(), retry() (+1 more)

### Community 112 - "record.py"
Cohesion: 0.53
Nodes (4): call(), read_frames(), run(), text()

### Community 113 - "FlightController.luau"
Cohesion: 0.53
Nodes (8): anyDown(), canFly(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 114 - "build"
Cohesion: 0.22
Nodes (11): set(), build(), portalFields(), Ambience.Apply(), Ambience.Warzone(), ensure(), BlockWorld.drawAll(), BlockWorld.partCount() (+3 more)

### Community 115 - "Farming.luau"
Cohesion: 0.36
Nodes (7): crossPathZ(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), veggiePathZ(), wave()

### Community 116 - "The late-game rule (your call, 2026-11-02)"
Cohesion: 0.50
Nodes (4): How you get things, The coin targets: settled, The late-game rule (your call, 2026-11-02), What this changed

### Community 117 - "BetaTagController.luau"
Cohesion: 0.24
Nodes (9): anchor(), BetaTagController.Start(), drop(), findHead(), onIncomingMessage(), refresh(), update(), watch() (+1 more)

### Community 118 - "SprintService.luau"
Cohesion: 0.27
Nodes (8): humanoidOf(), onSprint(), SprintService.Start(), SprintService.Stop(), tooHungry(), WarzoneService.IsBlocking(), Speed.Apply(), Speed.Set()

### Community 120 - "Auction House & Profiles"
Cohesion: 0.33
Nodes (6): Auction House & Profiles, Player profiles, Tested (Studio, 2026-11-10), The Auction House, Trading anywhere, aimedPlayer()

### Community 123 - "Glass.text"
Cohesion: 0.16
Nodes (20): buildSlots(), buildStatus(), build(), edge(), Glass.button(), Glass.card(), Glass.glow(), Glass.inset() (+12 more)

### Community 125 - "replicatedstorage_shared_places"
Cohesion: 0.17
Nodes (10): fadeTo(), MusicController.Start(), newSound(), greet(), NpcController.Start(), track(), update(), addNameTag() (+2 more)

### Community 128 - "Slaying plan (2026-11-02, approved with your changes)"
Cohesion: 0.50
Nodes (4): Slaying plan (2026-11-02, approved with your changes), The idea, What comes with it, Zones and monsters

### Community 138 - "Boost Crystals"
Cohesion: 0.40
Nodes (5): Boost Crystals, Built (2026-11-10), Fairness, How it works, The boosts (your list, with the leave at 5 s)

### Community 143 - "SprintController.luau"
Cohesion: 0.83
Nodes (3): lean(), moving(), SprintController.Start()

### Community 147 - "VisitService.luau"
Cohesion: 0.24
Nodes (7): IslandService.OwnerAt(), IslandService.SendHome(), goHome(), hostOf(), rootOf(), sendState(), visitedBy()

### Community 148 - "SettingsWindow.luau"
Cohesion: 0.43
Nodes (6): applyVolumes(), save(), SettingsWindow.SetState(), SettingsWindow.Start(), SettingsWindow.Toggle(), slider()

### Community 149 - "Boards.luau"
Cohesion: 0.40
Nodes (4): boardsState(), Boards.CurrentIndex(), c(), rewardCoins()

### Community 150 - "lowpoly.py"
Cohesion: 0.24
Nodes (4): _hex(), palette_image(), palette_material(), swatch_uv()

### Community 151 - "Decision: block toughness + tool power (Minecraft rules)"
Cohesion: 0.50
Nodes (3): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: block toughness + tool power (Minecraft rules)

### Community 152 - "store_footage.py"
Cohesion: 0.33
Nodes (7): basis(), main(), sample(), stitch(), tilted(), unit(), words_world()

### Community 153 - "Policy.luau"
Cohesion: 0.83
Nodes (3): Policy.PaidRandomRestricted(), Policy.TradingAllowed(), rulesFor()

### Community 154 - "HotbarService.luau"
Cohesion: 0.33
Nodes (8): heldTool(), HotbarService.GetHeldItem(), HotbarService.Start(), isIndex(), onMoveStack(), onQuickMove(), onSelectSlot(), refreshHeld()

### Community 155 - "replicatedstorage_shared_monsters"
Cohesion: 0.29
Nodes (6): spawnPet(), buildMonster(), PetModels.Build(), build(), SpawnerModels.Make(), weldTo()

### Community 157 - "GearService.luau"
Cohesion: 0.19
Nodes (6): (2026-11-03, session 10): new shield, four armour pieces, equipment in the Bag, checkOwned(), GearService.Start(), removePet(), splitOldArmor(), refresh()

### Community 158 - "crate_open.py"
Cohesion: 0.33
Nodes (5): crate_body(), crate_lid(), main(), preview(), rune()

### Community 159 - "tiktok_crate.py"
Cohesion: 0.31
Nodes (5): crate_meshes(), ease_out(), Film, main(), sound_events()

### Community 160 - "replicatedstorage_shared_gear"
Cohesion: 0.32
Nodes (4): addEffects(), hideClothing(), meshPart(), setHidden()

### Community 161 - "BlockWorld.set"
Cohesion: 0.38
Nodes (7): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, IslandService.PlaceNode(), respawnNodes(), regrow(), BlockWorld.occupied(), BlockWorld.set(), unmerge()

### Community 162 - "ItemIcon.luau"
Cohesion: 0.71
Nodes (6): addCamera(), armorIcon(), halfExtents(), modelIcon(), picture(), viewport()

### Community 163 - "StationModels.luau"
Cohesion: 0.57
Nodes (6): anvil(), blockPiece(), gemBench(), rootPart(), settle(), weld()

### Community 164 - "Level gates: crops need Farming level, mobs need Combat level"
Cohesion: 0.40
Nodes (5): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5)

### Community 166 - "MobController.luau"
Cohesion: 0.60
Nodes (5): animate(), fade(), forget(), MobController.Start(), track()

### Community 167 - "ShieldModel.luau"
Cohesion: 0.53
Nodes (5): stopBlocking(), findPart(), seat(), ShieldModel.Apply(), ShieldModel.SetRaised()

### Community 168 - "TrophyModels.luau"
Cohesion: 0.73
Nodes (5): build(), emblem(), piece(), TrophyModels.Make(), weld()

### Community 169 - "warzone_sky.py"
Cohesion: 0.60
Nodes (3): face(), main(), save()

### Community 170 - "Portal.luau"
Cohesion: 0.60
Nodes (3): Portal.makeClosed(), Portal.makeField(), sheet()

## Knowledge Gaps
- **14 isolated node(s):** `Roleplay + simulator hybrids growing [Unverified]`, `Inbox`, `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Prototype phase (current)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 651 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **45 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `BlockWorld.set` to `Handoff (updated 2026-10-27 ~22:35, session 4)`, `blocks.py`?**
  _High betweenness centrality (0.352) - this node is a cross-community bridge._
- **Are the 46 inferred relationships involving `Theme.make()` (e.g. with `makeBoard()` and `buildGui()`) actually correct?**
  _`Theme.make()` has 46 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Roleplay + simulator hybrids growing [Unverified]`, `Inbox`, `Rokit toolchain: StyLua, Selene, luau-lsp` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `numpy` be split into smaller, more focused modules?**
  _Cohesion score 0.08502024291497975 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `BlockWorld.set`, `math`?**
  _High betweenness centrality (0.340) - this node is a cross-community bridge._
- **Should `BodyService.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Why does `respawnNodes()` connect `BlockWorld.set` to `IslandService.luau`, `DecorService.luau`?**
  _High betweenness centrality (0.192) - this node is a cross-community bridge._