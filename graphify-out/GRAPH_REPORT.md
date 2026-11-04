# Graph Report - Roblox  (2026-11-04)

## Corpus Check
- 201 files · ~268,680 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: (none) 4, .toml 3, .base 1)

## Summary
- 1716 nodes · 3897 edges · 122 communities (84 shown, 38 thin omitted)
- Extraction: 84% EXTRACTED · 16% INFERRED · 0% AMBIGUOUS · INFERRED: 628 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1ff67c64`
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
- items3d.py
- NpcController.luau
- BodyService.luau
- BlockService.luau
- Handoff (updated 2026-10-27 ~22:35, session 4)
- Hud.luau
- replicatedstorage_shared_items
- Decor.luau
- Tools and Workflow
- os
- store_art.py
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
- FirstPersonController.luau
- studio_mcp.py
- AmbientController.luau
- Leveling.luau
- IslandService.luau
- Worlds/Mining.luau
- Warzone
- Vox
- LiquidService.luau
- Late-game proposal (2026-10-29)
- arc
- Places.Current
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
- CraftingService.luau
- ChestService.luau
- Glass.luau
- Kits
- Props.luau
- Slaying plan (2026-11-02, approved with your changes)
- QuestService.luau
- UI study (2026-10-29)
- Published privately as Sky Farm Prototype
- Woodcutting phase: build plan (2026-11-02)
- Farming.luau
- Hotbar.luau
- Farming phase: build plan (2026-11-02)
- VitalsHud.luau
- The late-game rule (your call, 2026-11-02)
- QuestTracker.luau
- Combat & Gear Plan (2026-11-03)
- script_parent_inventoryservice
- ChestService.luau
- Trends - Oct 2026
- Islands (Roblox)
- armour.py
- replicatedstorage_shared_gear
- ArmorModels.luau
- regrow
- Skybounds/README.md
- SprintController.luau
- Level gates: crops need Farming level, mobs need Combat level
- Decision: buy bigger islands with coins (4 tiers)
- ItemIcon.create
- gem_cluster
- Warzone
- CombatService.luau
- ShieldModel.luau
- Mining phase: build plan (2026-10-31)
- SprintService.luau
- WorldService.Start
- CrateService.luau
- Ambience.luau
- anvil
- bucket
- dragonfruit
- pumpkin
- twine
- shield
- sapling
- sliver
- wood_handle
- starstone
- sugarcane
- strawberry
- starfruit
- sword_fit/README.md

## God Nodes (most connected - your core abstractions)
1. `Theme.make()` - 50 edges
2. `Piece` - 38 edges
3. `Handoff` - 35 edges
4. `Decision Log` - 28 edges
5. `Builder` - 27 edges
6. `scene_world()` - 26 edges
7. `Theme.corner()` - 25 edges
8. `noisy()` - 24 edges
9. `part()` - 24 edges
10. `scene_icon()` - 23 edges

## Surprising Connections (you probably didn't know these)
- `Steal-and-defend trend (Steal An Egg, Steal a Brainrot)` --semantically_similar_to--> `Loot head: your loot drops in your avatar's head on death`  [INFERRED] [semantically similar]
  02 Research/Trends - Oct 2026.md → 03 Design/Warzone.md
- `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` --references--> `draw_node_tiles()`  [INFERRED]
  00 Inbox/Handoff.md → art/scripts/blocks.py
- `(2026-11-03, session 11, earlier): Night Glass on every window, shield really held` --references--> `shieldArmPose()`  [INFERRED]
  00 Inbox/Handoff.md → game/src/client/Windows/BagWindow.luau
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

## Communities (122 total, 38 thin omitted)

### Community 0 - "CombatController.luau"
Cohesion: 0.15
Nodes (15): aimedCharacter(), attack(), CombatController.Start(), cooldownOf(), faceTarget(), flash(), isFalling(), onHitEffect() (+7 more)

### Community 1 - "Theme.make"
Cohesion: 0.19
Nodes (36): buildGui(), show(), Theme.badge(), Theme.bar(), Theme.button(), Theme.card(), Theme.chip(), Theme.coin() (+28 more)

### Community 2 - "BlockWorld.luau"
Cohesion: 0.12
Nodes (19): onPlayerRemoving(), build(), BlockWorld.destroy(), BlockWorld.drawAll(), BlockWorld.partCount(), buried(), exposed(), fits() (+11 more)

### Community 3 - "CraftingService.luau"
Cohesion: 0.28
Nodes (12): buildGrid(), check(), choose(), CraftingWindow.SetState(), CraftingWindow.Start(), ingredientChip(), levelOf(), render() (+4 more)

### Community 4 - "numpy"
Cohesion: 0.09
Nodes (26): over(), all_obstacles(), armour_piece(), armoured(), bare_body(), box(), extras(), frame() (+18 more)

### Community 5 - "BagWindow.luau"
Cohesion: 0.15
Nodes (21): Hotbar.Selected(), Glass.setSlot(), Theme.formatNumber(), BagWindow.SetState(), BagWindow.Start(), bonusText(), buildCrafting(), buildPreview() (+13 more)

### Community 6 - "balance.py"
Cohesion: 0.19
Nodes (13): actions_per_hour(), best(), bonus(), curve(), main(), player_hours(), player_timeline(), skill_hours() (+5 more)

### Community 7 - "items3d.py"
Cohesion: 0.10
Nodes (16): carrot(), downscale(), load_blocks(), over(), read_image(), render_icon(), render_icons(), scrap() (+8 more)

### Community 8 - "NpcController.luau"
Cohesion: 0.24
Nodes (6): greet(), NpcController.Start(), track(), update(), addNameTag(), Npc.Build()

### Community 9 - "BodyService.luau"
Cohesion: 0.14
Nodes (12): BodyService.Copy(), BodyService.Drop(), BodyService.Lifetime(), fallingWay(), fetchAvatar(), isAny(), prepare(), shapeOf() (+4 more)

### Community 10 - "BlockService.luau"
Cohesion: 0.10
Nodes (8): Decision: click-only farming, inReach(), treeFell(), blockCrop(), FarmService.ShowCrop(), plotState(), refreshPlot(), setVisual()

### Community 11 - "Handoff (updated 2026-10-27 ~22:35, session 4)"
Cohesion: 0.06
Nodes (34): (2026-10-31 ~22:45, session 7): published scooping, swimming done, crafting approved, (2026-10-31 night): scooping restored, committed, NOT published, (2026-11-01 ~21:30, session 7): crafting + Mining phase tested, committed and PUBLISHED, store art live, (2026-11-02, session 8, earlier): Woodcutting phase built and playtested, (2026-11-02, session 8, last): the Warzone prototype was rejected, (2026-11-02, session 8): late-game rework, Warzone and billion-coin scale tested in Studio; NOT committed, NOT published, (2026-11-02, session 9): the real Warzone map is built, (2026-11-03, session 11, earlier): Night Glass on every window, shield really held (+26 more)

### Community 12 - "Hud.luau"
Cohesion: 0.16
Nodes (18): buildCelebration(), buildMenu(), buildStatus(), buildToasts(), drawMenuBars(), fadeLabel(), Hud.Celebrate(), Hud.Render() (+10 more)

### Community 13 - "replicatedstorage_shared_items"
Cohesion: 0.10
Nodes (10): doneCount(), stateOf(), listOf(), render(), renderCarried(), shownStack(), CrateWindow.SetState(), refresh() (+2 more)

### Community 14 - "Decor.luau"
Cohesion: 0.05
Nodes (74): buildArrival(), portalFields(), BlockWorld.position(), BlockWorld.setRaw(), Decor.Awning(), Decor.Banner(), Decor.Bench(), Decor.Cactus() (+66 more)

### Community 15 - "Tools and Workflow"
Cohesion: 0.21
Nodes (12): Blender driven by Python scripts, Rojo (syncs game/ code into Studio), Rokit toolchain: StyLua, Selene, luau-lsp, Tools & Stack, Code pipeline: Luau in game/src -> Rojo live sync -> playtest, Claude builds code, models and notes; the user playtests and publishes, Model pipeline: script -> .blend/.fbx/render -> Studio import, Workflow (+4 more)

### Community 16 - "os"
Cohesion: 0.07
Nodes (47): build_atlas(), main(), export_fbx(), hex_rgb(), material(), mesh_object(), render_preview(), reset_scene() (+39 more)

### Community 17 - "store_art.py"
Cohesion: 0.15
Nodes (19): blur(), caption(), cave_shell(), finish_icon(), logo(), main(), n2(), rgb255() (+11 more)

### Community 18 - "new_verts"
Cohesion: 0.16
Nodes (12): axe(), thickness(), handle(), hoe(), new_verts(), pickaxe(), build_head(), z_at() (+4 more)

### Community 19 - "WarzoneService.luau"
Cohesion: 0.18
Nodes (16): finishLeaving(), inSafeZone(), isSafeSpot(), onFell(), playSound(), poison(), rootOf(), setHunger() (+8 more)

### Community 20 - "FlightController.luau"
Cohesion: 0.57
Nodes (7): anyDown(), characterParts(), facing(), FlightController.Start(), jumpPressed(), land(), takeOff()

### Community 21 - "store_art.py"
Cohesion: 0.14
Nodes (28): add_mesh(), anvil_mesh(), box(), camera(), crystals(), finish(), flat(), hero() (+20 more)

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
Cohesion: 0.38
Nodes (7): aim(), aimedLootChest(), aimedShop(), rootPosition(), screenRay(), shopkeepers(), workArea()

### Community 30 - "blocks.py"
Cohesion: 0.11
Nodes (32): bricks_tile(), clamp(), draw_building_tiles(), planks_tile(), draw_deep_ore_tiles(), clumps(), crystals(), darker() (+24 more)

### Community 32 - "replicatedstorage_shared_blocks"
Cohesion: 0.15
Nodes (6): Shapes.Glow(), Shapes.Light(), beacon(), strip(), trafficCone(), v3()

### Community 33 - "HotbarService.luau"
Cohesion: 0.07
Nodes (16): Tool path quests: wood -> planks -> sticks -> pickaxe -> stone, Tools: pickaxe, axe, shovel, sword in Wooden / Stone / Crystal, Decision: Minecraft-style block islands (break and place, saved), Decision: block toughness + tool power (Minecraft rules), Combat.Armor(), Economy.Total(), Economy.Value(), work() (+8 more)

### Community 34 - "Economy & Values"
Cohesion: 0.22
Nodes (9): Coin pace (rebalance 2026-10-27), Crops are perennial, Economy & Values, Resource nodes, The billion scale (your call, 2026-11-02), The rules, Tools (new, full durability), Trading between players (+1 more)

### Community 37 - "FirstPersonController.luau"
Cohesion: 0.26
Nodes (15): add(), addArm(), addHeld(), build(), clearRig(), copyOf(), FirstPersonController.Start(), hideReal() (+7 more)

### Community 39 - "studio_mcp.py"
Cohesion: 0.06
Nodes (20): main(), run(), matrix(), call(), read_frames(), run(), text(), add() (+12 more)

### Community 41 - "Leveling.luau"
Cohesion: 0.17
Nodes (9): Better rewards as skills level up, IslandService.PlantedCount(), IslandService.TreeLog(), IslandService.TreeMinutes(), ProgressionService.AddPlayerXP(), checkCell(), onPlant(), Leveling.PlantedTrees() (+1 more)

### Community 42 - "IslandService.luau"
Cohesion: 0.13
Nodes (26): (session 6) islands as build areas DONE in Studio, Decision: falling off returns you to your island, islandArea(), announce(), build(), clampTier(), fell(), generate() (+18 more)

### Community 43 - "Worlds/Mining.luau"
Cohesion: 0.14
Nodes (11): ctx.Noise(), hillHeight(), roughDistance(), chamber(), ck(), findCaves(), mountainHeights(), rough() (+3 more)

### Community 45 - "Warzone"
Cohesion: 0.11
Nodes (20): Younger Roblox players (Kids 5-8, Select 9-15), Details seen in the photos (looked at closely 2026-11-02), Five maps, one theme each, The Skybounds Warzones, built by Team Vaeron, What they all share, What this means for our Warzone, Roblox Kids & Select age bands and content ratings, Maturity rating of combat [open check] (+12 more)

### Community 46 - "Vox"
Cohesion: 0.17
Nodes (5): Assets, gem(), glow(), linear(), Vox

### Community 48 - "LiquidService.luau"
Cohesion: 0.24
Nodes (4): liquidAt(), touches(), LiquidModels.Make(), make()

### Community 52 - "Late-game proposal (2026-10-29)"
Cohesion: 0.22
Nodes (9): 1. New resources (13), 2. New tool tiers (2, x 5 kinds = 10 tools), 3. Big things to buy (10M–50M), 4. The order to build it in, Farming: four new zone islands (4), Late-game proposal (2026-10-29), Mining: a deeper cave under the Gold Chamber (5), Questions (+1 more)

### Community 53 - "arc"
Cohesion: 0.17
Nodes (6): arc(), front_slab(), rope(), ui_bag(), ui_mail(), ui_trophy()

### Community 54 - "Places.Current"
Cohesion: 0.26
Nodes (8): fadeTo(), MusicController.Start(), newSound(), capitalized(), failed(), sendBack(), TravelService.Go(), Places.Current()

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
Cohesion: 0.16
Nodes (15): NPC visits at milestones with a starter pack, Gear references, Warzone parked until it moves into Town, Content Index, Merchant NPC at the Town market, Decision: Market moved off the island into Town, Decision: villager-style Merchant runs the Market, Decision Log (+7 more)

### Community 59 - "Window.luau"
Cohesion: 0.15
Nodes (14): setBlur(), Window.clear(), Window.close(), Window.open(), Window.setTitle(), Window.toggle(), BagWindow.Toggle(), CraftingWindow.Open() (+6 more)

### Community 60 - "Build.luau"
Cohesion: 0.24
Nodes (8): set(), setFree(), top(), Build.Fill(), Build.Set(), Build.SetFree(), Build.Top(), pick()

### Community 61 - "Warzone rebuild plan (2026-11-02)"
Cohesion: 0.25
Nodes (8): 1. The map: Robot / sci-fi (built and walked in Studio, 2026-11-02), 2. Warzone rules, 3. Inventory and chests, whole game, 4. Shield, 5. Skydrops, Answered (2026-11-02), Map design, as built (grid in blocks, 1 block = 3 studs; our own builds, not copies), Warzone rebuild plan (2026-11-02)

### Community 62 - "GearService.luau"
Cohesion: 0.19
Nodes (8): (2026-11-03, session 10): new shield, four armour pieces, equipment in the Bag, checkOwned(), GearService.Start(), removePet(), spawnPet(), splitOldArmor(), refresh(), PetModels.Build()

### Community 65 - "CraftingService.luau"
Cohesion: 0.24
Nodes (3): craft(), nearStation(), unlockedBy()

### Community 66 - "ChestService.luau"
Cohesion: 0.19
Nodes (8): ChestService.CloseAll(), findSpot(), goneAfter(), LootChestService.Start(), refill(), spawnOne(), Inventory.EmptyOf(), WarzoneLoot.Roll()

### Community 67 - "Glass.luau"
Cohesion: 0.23
Nodes (12): build(), edge(), Glass.button(), Glass.card(), Glass.glow(), Glass.inset(), Glass.stage(), Glass.text() (+4 more)

### Community 68 - "Kits"
Cohesion: 0.33
Nodes (6): Kits, Our version (proposal), Rule to design around, Still to decide, The other Skybounds kits, for reference, What Looter was in Skybounds

### Community 69 - "Props.luau"
Cohesion: 0.38
Nodes (4): baseOf(), Props.FaceToward(), Props.Place(), Props.WorldExtents()

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

### Community 76 - "Farming.luau"
Cohesion: 0.36
Nodes (7): crossPathZ(), hollowPathX(), mainPathX(), oasisPathZ(), plainsPathDistance(), veggiePathZ(), wave()

### Community 77 - "Hotbar.luau"
Cohesion: 0.53
Nodes (5): Decision: 5-slot Minecraft-style hotbar, Hotbar.Select(), Hotbar.SelectedItem(), showName(), slotCenter()

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
Cohesion: 0.19
Nodes (4): keyLabel(), PromptUI.Start(), aimHighlight(), QuestTracker.Render()

### Community 82 - "Combat & Gear Plan (2026-11-03)"
Cohesion: 0.22
Nodes (9): Armour art, Armour numbers, Combat & Gear Plan (2026-11-03), Combat: real Minecraft rules, First person, Health, armour and hunger on screen, Sprinting, The sword system (+1 more)

### Community 83 - "script_parent_inventoryservice"
Cohesion: 0.36
Nodes (6): BodyService.Start(), clean(), deliver(), InboxService.Send(), InboxService.Start(), onOverflow()

### Community 84 - "ChestService.luau"
Cohesion: 0.25
Nodes (8): changed(), ChestService.CloseFor(), ChestService.Open(), closeFor(), isIndex(), placeOf(), send(), onOpen()

### Community 85 - "Trends - Oct 2026"
Cohesion: 0.22
Nodes (8): Totems: passive resource generators with a range, Idle-grow / cozy trend (Grow a Garden spike and decay), Roleplay + simulator hybrids growing [Unverified], Steal-and-defend trend (Steal An Egg, Steal a Brainrot), Trends - Oct 2026, Why big hits declined: event spikes, exploits, economy trust, confusing resets, Offline progress and timers, Passive generators with a range limit

### Community 86 - "Islands (Roblox)"
Cohesion: 0.14
Nodes (12): Conveyor factories (splitters, filters, sensors), Trading shut down after a duplication exploit [Unverified], Hidden fossil collection quests, Islands (Roblox game by Easy.gg), Islands (Roblox), Key-gated adventure islands, Token-summoned bosses with cooldowns, Skill-gated vending machines and handshake trading (+4 more)

### Community 87 - "armour.py"
Cohesion: 0.06
Nodes (39): band(), boot_base(), boot_farming(), boot_mining(), boot_woodcutting(), burst(), chest_farming(), chest_mining() (+31 more)

### Community 88 - "replicatedstorage_shared_gear"
Cohesion: 0.31
Nodes (6): dress(), addEffects(), ArmorModels.Apply(), hideClothing(), meshPart(), setHidden()

### Community 89 - "ArmorModels.luau"
Cohesion: 0.33
Nodes (11): anvil(), blockPiece(), gemBench(), rootPart(), settle(), weld(), build(), emblem() (+3 more)

### Community 90 - "regrow"
Cohesion: 0.36
Nodes (8): Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`, IslandService.PlaceNode(), respawnNodes(), regrow(), BlockWorld.get(), BlockWorld.occupied(), BlockWorld.set(), unmerge()

### Community 92 - "SprintController.luau"
Cohesion: 0.83
Nodes (3): lean(), moving(), SprintController.Start()

### Community 93 - "Level gates: crops need Farming level, mobs need Combat level"
Cohesion: 0.40
Nodes (5): Combat (PvE) skill, Farming skill, Level gates: crops need Farming level, mobs need Combat level, Crops: Wheat (1), Carrot (5), Potato (10), Glowberry (Warzone seeds), Mobs: Slime (Combat 1), Brute (Combat 5)

### Community 95 - "ItemIcon.create"
Cohesion: 0.57
Nodes (5): addCamera(), halfExtents(), ItemIcon.create(), modelIcon(), viewport()

### Community 96 - "gem_cluster"
Cohesion: 0.14
Nodes (4): gem_cluster(), iron_plate(), loot_crate(), melon()

### Community 97 - "Warzone"
Cohesion: 0.11
Nodes (32): Design Pillars, Pitch: own a floating island, drop into a shared Warzone, bring loot home, Pitch (Draft), Mobile-first UI, Target Audience, 100+ challenges and an island challenge ladder, Fly tokens: tradeable timed power, Skybounds (Minecraft) (+24 more)

### Community 100 - "ShieldModel.luau"
Cohesion: 0.39
Nodes (7): humanoidOf(), startBlocking(), stopBlocking(), findPart(), seat(), ShieldModel.Apply(), ShieldModel.SetRaised()

### Community 103 - "Mining phase: build plan (2026-10-31)"
Cohesion: 0.29
Nodes (7): Art, Mining phase: build plan (2026-10-31), Order, Slivers and nodes, The deep cave (Worlds/Mining.luau), The ores (the deep cave, under the Gold Chamber), Tool tiers and parts (from the Crafting Proposal)

### Community 104 - "SprintService.luau"
Cohesion: 0.67
Nodes (6): humanoidOf(), onSprint(), SprintService.Start(), SprintService.Stop(), tooHungry(), WarzoneService.IsBlocking()

### Community 105 - "WorldService.Start"
Cohesion: 0.38
Nodes (5): makeArea(), WorldService.Start(), spawnCharacter(), Spawning.MakeSpawn(), Spawning.Start()

### Community 107 - "Ambience.luau"
Cohesion: 0.83
Nodes (3): Ambience.Apply(), Ambience.Warzone(), ensure()

## Knowledge Gaps
- **14 isolated node(s):** `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox`, `Steal An Egg precedent (feature pulled, rule added)`, `Prototype phase (current)` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 469 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **38 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Session 4, part 2 (2026-10-27 ~22:10): nodes done and playtested, committed later as `5628666`` connect `regrow` to `Handoff (updated 2026-10-27 ~22:35, session 4)`, `blocks.py`?**
  _High betweenness centrality (0.357) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Theme.make()` (e.g. with `buildGui()` and `buildCelebration()`) actually correct?**
  _`Theme.make()` has 33 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Rokit toolchain: StyLua, Selene, luau-lsp`, `Claude builds code, models and notes; the user playtests and publishes`, `Inbox` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `BlockWorld.luau` be split into smaller, more focused modules?**
  _Cohesion score 0.11692307692307692 - nodes in this community are weakly interconnected._
- **Why does `draw_node_tiles()` connect `blocks.py` to `regrow`, `store_art.py`?**
  _High betweenness centrality (0.351) - this node is a cross-community bridge._
- **Should `numpy` be split into smaller, more focused modules?**
  _Cohesion score 0.08585858585858586 - nodes in this community are weakly interconnected._
- **Why does `respawnNodes()` connect `regrow` to `IslandService.luau`?**
  _High betweenness centrality (0.160) - this node is a cross-community bridge._