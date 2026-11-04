# Warzone rebuild plan (2026-11-02)
Replaces the greybox prototype after your verdict: "terrible and low effort". Your rules are at the top of [[Warzone]], the look comes from [[Vaeron Warzones]]. Work top to bottom; tick as each is built and playtested.

## 1. The map: Robot / sci-fi (built and walked in Studio, 2026-11-02)
- [x] New sci-fi blocks (white, grey, dark and orange hull, glow, hazard stripes, rubber, crystal, red ground)
- [x] Citadel in the middle (safe zone, where you arrive) with towers, rings and four gates
- [x] 26 floating islands at different heights, each with its own hero build; North, South, East and West landmarks with their names floating over them (whole words, as in the Vaeron photos, not single letters); causeways, catwalks and stepping stones between them
- [x] Look at it against the Vaeron photos before showing you
- [x] Our own night-blue sky over a high sun (`art/scripts/warzone_sky.py`), for the Vaeron photos' bright builds on a dark sky
- **Bigger and further out (your notes, 2026-11-02):** first all islands 30% wider with the net pushed out; then the main islands (the 4 landmarks and the 9 inner ones) wider again for PvP room, with boulders, scrap and crates as cover on the new ground. Bridges kept about the same length. 158k block parts (Mining is 139k, Woodcutting 177k), so check on real devices, especially with a full server. Dropping a few islands is the easy way to cut it, and you said that's fine.

## 2. Warzone rules
- [x] No monsters
- [x] No PvP in the citadel; PvP everywhere else (written; a real hit between two players isn't tested yet)
- [x] Combat tag: 20 seconds on screen, blocks leaving (tested by setting the tag; not yet from a real hit)
- [x] Leave button, Warzone only: hold it (7 s, Claude's pick from your 5-10), with a noise others can hear. Letting go cancels it. Going back to Town needs publishing to test
- [x] Chests: all the same, random spots, shared slots; emptied = gone, a new one spawns elsewhere (`Services/LootChestService`; 24 out at a time, what's in them in `shared/WarzoneLoot.luau`: Claude's picks)
- [ ] Death: everything drops, your body lies there and anyone can loot it; gone after 15 minutes

## 3. Inventory and chests, whole game
- [x] 36 slots with stacks; old saves move what doesn't fit into an Inbox letter, which is simpler than chests by the spawn and can't land on a build (only new saves tested: Studio saves are mock)
- [x] Traditional chest screen for every chest (`Windows/ChestWindow`): bodies will use it too
- [x] Placeable storage chests on islands (`Services/ChestService`): 8 planks at the Crafting Table, 27 slots, right-click to open; breaking one gives you what's in it, and what doesn't fit goes to your Inbox
- [x] Inventory screen: armour, shield, small crafts, in its own high-quality look (Night Glass, from the Figma file `Skycore UI`)

## 4. Shield
- [x] Shield item and slot; hold right-click to block from the front

## 5. Skydrops
- [ ] Regular (every 10 minutes, marker) and Legendary (every 4-8 hours, no marker); better loot; random spots not far from spawn, but not right next to it
- [ ] Tokens later: loot crates, Robux with a daily limit, other ways

## Answered (2026-11-02)
Armour is four pieces. Quit: vanish, 5 minutes to rejoin, auto-teleported to the exact server and spot; miss it, or quit while tagged, and your body drops. Fall: back where you jumped from, with a little ticking poison. Death: back to Town. Hunger bar, Warzone only. One crafted shield. See the top of [[Warzone]].

## Map design, as built (grid in blocks, 1 block = 3 studs; our own builds, not copies)
- **Files:** `Worlds/Warzone.luau` (layout, citadel, walkways, names), `Worlds/WarzoneBuilds.luau` (the 26 heroes), `Worlds/Shapes.luau` (cones, domes, thick lines, big trees). North is -z and east is +x here, a true compass. The numbers below were the plan; the code is the truth (four tall corner towers and eight gate towers rather than 5 side towers).
- Keep it under about 100k block parts, since it's PvP.
- **Citadel at (0, 0):** rock island radius 40 under rings to radius 56: dark outer plaza at y -2 with a glow strip, white wall at radius 44-46 with an orange band and gates N/E/S/W, grass and pines inside, a central tower (cylinder radius 10 to y 30, then a 12x12 white and orange section to y 58, antenna), 5 side towers at radius 30 joined by a ring tube at y 22. Safe zone: radius 58. Arrive inside the south gate.
- **Layout:** 9 islands at radius 135-171 (island radius 23-34), 13 at radius 216-250 (21-26), landmarks at radius 298-310 (54) on the axes with their names floating over them. Heights vary from -12 to +14. About 1,090 studs from the middle to the outer edge; `StreamingTargetRadius` is 1200 here so the whole map shows from the citadel.
- **Landmarks:** N giant robot, S rocket and launch pad, E reactor and cooling towers, W crashed starship with scrap and tyres.
- **Others, one hero each:** UFO, purple crystal cliffs, radar dish, wind turbines, solar farm, comms tower, overgrown mech head, robot dog, monorail station, pipe works, drill rig, glass dome garden, hangar, escape pod crater, snow lab, beach wreck, cargo stacks, walker mech, data pylons, bunker, jungle ruin.
- **Links:** 2-wide dark catwalks with glow posts for the main routes; stepping stones with small gaps on side routes.
- **Chests and Skydrops:** collect spots per island at random with clear air above; Skydrop spots come from the inner islands.
- **Inventory plan:** `data.Slots` holds the layout, `data.Items` stays as derived counts so existing code keeps working; hotbar is slots 1-9; old saves' overflow goes into chests by the island spawn. Chest moves are checked on the server; the held stack is only on the client.
