# Town & Worlds
Built 2026-10-25, rebuilt the same day for looks (your call: "make it an actual cave you can run up to", "a big island with actual shops", "make it look nice", all worlds; the base island stays as it is). The worlds were rebuilt again 2026-10-26 at Skybounds scale, as zone islands joined by bridges (see below). Code: `TownService.luau` (Town), `WorldService.luau` (runs a world: nodes, crops, arrival square) with one builder per world in `server/Worlds/` (`Mining`, `Woodcutting`, `Farming`), `Worlds/Context.luau` (the builders' toolkit: islands, bridges, islets, flat areas, caves), `Worlds/Common.luau` (zone signs, arrow signposts, paths, lamps, forests, boulders, giant mushrooms, cliff vines, ponds), `Shops.luau` (who buys and sells what), `Util/Npc.luau` (the shopkeepers), `Util/Build.luau` (walls, roofs, building plots), `Util/Decor.luau` (lanterns, fences, benches, flowers, water, banners, rails, carts, waterfalls, falling snow/petals/leaves, palms, cacti...), `Util/Signs.luau` (rustic, hanging and arrow signs; arrival gateways), `Util/Ambience.luau` (atmosphere, bloom, sun angle).

## Research: how the hubs we're borrowing from look
**Islands (Roblox) — the Hub** (fan wiki, robloxislands.fandom.com: Hub, Villager pages; read 2026-10-25)
- One shared island you reach through your island's portal. The first thing you see is a **central area** with a big portal back home.
- **Villagers each run one trade**, standing in front of their own themed building: Cletus (farmer: seeds, crops, farm tools), John (blocks), Jade (miner: ores and mining tools), Thomas (fisherman, by the lake and docks), Taliyah (animals, her barn), Arius (totems), Jack (mechanic), Dom (wholesaler: buys crops in bulk), Petur (baker), Fulco (florist), and more. John and Jack stand side by side on a small hill.
- **Other portals sit at the ends of paths**: one next to Ivon to Slime Island, one at the end of the path to Maple Isles. Event portals open in the central area.
- The Hub had its own **mining area with rocks that respawn** (stone, coal, iron). Rarer ores are only on later islands.
- Seasonal makeovers (Halloween, Christmas) and a countdown board for events.

**Skybounds (Minecraft)**: the server is shut down and almost nothing about its spawn survives online. From the listings: a spawn hub with warps to "10 worlds/warzones with loot and ores". Your memory is the best source here. On 2026-10-26 you found screenshots of its spawn: a stone bridge with walls and lamp posts leading to a mountain with an arch, a big logo sign with clouds and a rainbow, market stalls with striped awnings, wooden lamp posts with lantern boxes, and flowers everywhere.

**What we took:** one trade per shopkeeper, each at their own stall; the portal home where you arrive; world portals at the end of the main path; resources that respawn in shared worlds, with rare ones found elsewhere. Names, characters and layout are our own.

## New blocks (2026-10-25)
20 new textured blocks drawn by `art/scripts/blocks.py` (atlas now 7×7 tiles): Stone Bricks, Mossy Stone Bricks, Mossy Cobblestone, Bricks, Smooth Stone, Plaster, Dark Planks, Barn Planks, Red and Slate Roof Tiles, Thatch, Gravel, Sand, Dirt Path, Flowery Grass, Hay Bale, Crate, Barrel, Bookshelf, Dark Stone (the unbreakable rock behind mine walls), plus Glass and Water (plain parts added to the Blocks folder in Studio). The Builder sells the building ones (see [[Economy & Values]]).

## Zone blocks and signs (2026-10-26)
19 more tiles (atlas now 9×9 at 112 px): Birch, Spruce and Cherry logs and leaves, Autumn Leaves, Snow, Snowy Grass, Gold Ore, Pumpkin, Melon, Terracotta, Red Terracotta, plus Ice (a plain part). Later the same day: Sandstone, Coarse Dirt, Mushroom Cap and Stem, Cracked Stone Bricks, and merged Farmland pieces. Signs everywhere use a **blocky pixel font** (Press Start 2P) and sit **above head height**.

**Signs, second pass (2026-10-26, your notes: "too many labels", "big signs are too repetitive", "make some sketchy and show you where to go", "remove doubleside"):** every sign is **one-sided** now, with burnt or carved letters instead of an outline. Big plank gateways are only used for each world's arrival square. Elsewhere there are three hand-made styles (`Util/Signs.luau`):
- **Rustic**: a rough board of uneven planks with nail heads on one leaning post, marking where a zone begins (name and level). Its wood matches the zone (birch, spruce, cherry, dark, sand...).
- **Arrow signpost**: a tall post with pointed boards, one per place, each pointing the way. They stand at crossroads and beside paths, turned so you can read them from the path.
- **Hanging**: a board on two chains under a beam (the mine arch).

## The Town (hub)
Rebuilt 2026-10-26 after your Skybounds spawn screenshots. A big floating island (about 50 blocks across from the fountain to the rim) and a little spawn island south of it, all protected, with natural island edges like the worlds, clouds drifting round and below, and little rocks floating nearby. Lamp posts everywhere are **wooden posts with lantern boxes**. Soft atmosphere, the sun in the south.
- **Spawn** (its own islet): you arrive on a paved square in front of the runestone **portal home**, flower beds down both sides, and look straight up the bridge at the mountain and the logo.
- **The bridge**: seven blocks wide, stone bricks with low walls, lantern posts on pillars along both walls with flower boxes between them, a stone arch underneath over the sky.
- **The mountain**: a stone ridge across the south of the Town island, a wall of rock behind the logo with peaks up to about 35 blocks either side of it, grass and oaks on top, vines down its cliffs, boulders at its foot. A paved plaza with flower beds and benches lies in front. The street goes through a big **stone-brick arch** (seven wide, a tunnel lit by lanterns, a stone gate at each end), and over the south gate stands the **SKYBLOX logo**: chunky pixel letters, "SKY" in sky blue and "BLOX" in gold, with a dark outline and shadow, a rainbow arching over them and blocky clouds at its feet.
- **Market street** (past the arch): four market stalls with striped cloth roofs, two each side: produce (red), flowers (pink), ores (blue), wood (green). Decoration for now; the shopkeepers are in the square.
- **Market Square** (middle): cobblestone and stone-brick rings around a **fountain** (stone basin, water, a centre pillar spraying, four corner spouts), benches, lamp posts. Four **shops you walk into** face the square, each a real building with a stone foundation, timber corner posts and beams, glass windows with flower boxes, a stepped gable roof, the shop's name on the gable, lanterns by the door, and inside a counter with the shopkeeper behind it, goods on the counter, shelves, lanterns:
  | Shop (sign) | Building | Outside | Shopkeeper | Buys | Sells |
  |---|---|---|---|---|---|
  | **MARKET** (west) | plaster and timber, red tiles, striped awning | crates of crops, hay bales | **Merchant**: traveling trader (cap, mustache, green vest, red scarf, backpack with lantern) | Wheat, Carrot, Potato, Pumpkin, Melon, Glowberry ("Sell all crops") | Wheat/Carrot/Potato/Pumpkin/Melon Seeds (Farming-gated) |
  | **LUMBER YARD** (west) | log walls, slate roof | log piles, a stump with an axe in it | **Lumberjack**: plaid shirt, beanie, big beard, axe on his back | Wood, Birch/Spruce/Cherry Wood | Sapling (20) |
  | **BUILDER** (east) | bricks and stone, slate roof, blue awning | scaffolding, pallets of blocks | **Builder**: overalls, red bandana, tool belt | – | 13 building blocks (Grass 3 … Glass 6) |
  | **MINER** (east) | stone bricks with mossy footings, slate roof, forge chimney with smoke | rails with a cart of iron ore, barrels | **Miner**: hard hat with a working headlamp, grey beard, pickaxe on his back | Stone, Coal, Raw Iron, Iron Ingot, Raw Gold, Gold Ingot | Coal (10) |
  Click / tap a shopkeeper or use their **Trade** prompt (E). Their heads turn to watch you; name tags show through the door (not through walls).
- **Lanes**: west to a **garden** with a roofed stone well, flower beds and benches; east to a **park** with a sandy pond, lily pads and benches. **Four cottages** (plaster and timber, thatch or red tiles, chimneys with smoke, bed/table/bookshelf inside, fenced flower yards, paths to the street).
- **Portal Plaza** (north), past an **arrow signpost** ("THE WORLDS" one way, "HOME" the other; it replaced the old gate, which crowded the middle arches): the runestone arches with their signs, themed blocks beside each, and **one tall banner pole behind each arch** flying the portal's colour above it:
  | Portal | Field | Beside it | Status |
  |---|---|---|---|
  | Farming | gold | farmland with crops, hay | open |
  | Woodcutting | green | log-and-leaf posts | open |
  | Mining | orange | stone with coal and iron ore | open |
  | Slaying | dark red, boarded up | obsidian | "Coming soon" (until PvE) |
- Oaks round the edge, flowers and tall grass in the lawns. Player trading happens here (level 5, see [[Economy & Values]]).

## The resource worlds (rebuilt 2026-10-26, Skybounds-scale)
You showed Skybounds screenshots (huge wheat fields under a terracotta mountain, a giant cavern with lava falls and hanging vines, big oaks on stone cliffs, islands joined by bridges on the minimap) and chose: **~3x wider**, **a new resource per zone, unlocked by level**, **zones on their own islands joined by bridges**; the mine is one big cave with a mix of ores.

Each world is **its own place** with its own servers (like Town), about **230 blocks across**: an **arrival island** in the south and **three zone islands** (west, north, east) joined to it by **plank bridges** (five blocks wide, railings, log beams underneath, lantern posts), with little **floating islets** around. You arrive in a paved square at the south end with two portals, **Back to Town** and **Go home**, under a tall **gateway** with the world's name. An arrow signpost at the crossroads points to the zones, and each zone island has a rustic sign at its bridge end with the zone's name and the level its resource needs. Main paths with lamp posts link the square, the bridges and each zone's sights. Everything you can gather is a **node** that grows back in place, shared by everyone on the server; scenery can't be broken and nobody can build there.

**How the world ends:** hills ease down toward a ragged rim; the grass hangs over the rock in a thin lip; underneath hangs a cone of rock in chunky four-block terraces with spikes, deepest in the middle; roots dangle under the lip and vines hang down the cliffs. The Oak Woods river pours off both sides of its island as **waterfalls** fading into mist.

| World | Zone (island) | Resource (level) | What's there |
|---|---|---|---|
| **Woodcutting** | **Oak Woods** (arrival) | Oak → Wood (anyone) | rolling hills of oaks and big old oaks, a rocky hill in the middle, patches of coarse reddish dirt, stone paths with lamp posts, boulders, giant red mushrooms, a river with a plank bridge and two waterfalls, the lumber camp (log cabin, sawmill with a spinning blade, log piles, campfire), fallen logs, vines down the cliffs |
| | **Birch Grove** (west) | Birch → Birch Wood (Woodcutting 10) | slim white birches in a flower meadow, a lily pond with a dock and benches, fallen birch logs |
| | **Snowy Pines** (north) | Spruce → Spruce Wood (Woodcutting 20) | snowy hills, tall slim spruces, a frozen lake (ice you can walk on), a trapper's cabin of spruce logs with a smoking chimney, snowy boulders, falling snow |
| | **Cherry Hills** (east) | Cherry → Cherry Wood (Woodcutting 30) | pink cherry trees with forked trunks, a koi pond with a red-railed bridge and lily flowers, stone lanterns, an open pavilion with a red roof, drifting petals |
| **Farming** | **Wheat Plains** (arrival) | Wheat (anyone) | **one huge open wheat field** over the whole plain (your reference), cut by winding dirt paths with water running along their edges, hay bales in the wheat, a tall red **silo**, the windmill, red barn, thatched farmhouse, farmyard well and hay cart, a pond, a striped **terracotta mesa** |
| | **Veggie Gardens** (west) | Carrots (Farming 5), Potatoes (Farming 10) | long rows of carrots south of the path and potatoes north of it, water every fifth row, a glasshouse at the far end |
| | **Pumpkin Hollow** (north) | Pumpkins (Farming 15) | pumpkin patches over the rolling ground between orange autumn trees, jack-o'-lanterns along the path, hay bales, leaf piles, falling leaves |
| | **Melon Oasis** (east) | Melons (Farming 25) | a sandy island: melon patches over the dunes, an oasis pool ringed with palms, cacti, a market stall |
| **Mining** | **The Quarry** (arrival) | stone, coal, iron outcrops | gravel yards, the miner's hut, a tent and campfire, ore carts on rails; a **stone bridge** with walls and lamps leads to the mountain |
| | **The Mountain** (north) | everything below | jagged **sandstone peaks** with dark cracks and vines (your reference), grassy terraces with boulders and oaks; two wooden **pavilions** either side of the path; a big **timber arch** with "THE MINE" hanging on chains leads inside. The mine is now **a section per ore** (your note: "I actually do want sections for ores"), joined by tunnels: |

**Inside the mine:**
| Section | Where | Ore | Looks |
|---|---|---|---|
| **Lantern Hall** | just inside | stone | the hub, with lanterns hanging from the roof and an arrow signpost to the three ways on |
| **Coal Seam** | east | coal everywhere | |
| **Iron Vein** | west | iron everywhere | |
| **Lava Cavern** | north, 11 blocks high | mixed | lava falls into a glowing pool, glowing mushrooms, crystals, vines; a signpost to the next two |
| **Gold Chamber** | down a sloping tunnel, deep | gold (Mining 10) | |
| **Crystal Grotto** | north-east | a little iron | purple crystals |

- **Mine walls** are stone nobody can break, set with ore that grows back (2026-10-27: stone is never a node, so nothing in the cave is destroyed for good). A mined ore turns into a pale Empty Ore block until it fills back in (coal 20s, iron 45s, gold 90s), and an ore only breaks with a pickaxe that can collect it. Floors can't be broken. The mine is longer and lower than before (your note: "all the ore is kind of squished in, doesn't have to be as high"), and caves stay inside the rock.
- **Crops** grow wild in the open (no fences, no plots): click a ripe one to harvest it and it grows back. Ripe pumpkins and melons show as their block with a leaf. Only the two veggie rows have small crop signs.
- **Level gates:** chopping or mining a zone's resource below its level does nothing but tell you the level ("Birch Wood needs Woodcutting level 10"). Placed blocks are never gated. New items, prices and shops: see [[Economy & Values]].
- **Slaying World**: not built (waits for PvE); its zones will be themed the same way.
- **Sizes** (Studio, 2026-10-26): Woodcutting ~25.5k block parts, Farming ~19k, Mining ~27k (+2–4k decor parts each), built in 3–5 seconds on server start. Ground, rock and other unbreakable scenery are drawn as **merged pieces** (a mesh several blocks big that looks exactly like those blocks; `ReplicatedStorage.Blocks.Merged`), and islands only store their outer shell. Merged farmland is still clickable (the client works out the block from where you clicked). Worth checking on a phone.
- **Flying** (2026-10-26, your call): only you (koiopio) can fly, in every place: double-tap Space (or the jump button), Space/E up, Ctrl/Q down. The list is `Config.Flyers`.

## Not done yet
- Published: the first versions 2026-10-25; the Skybounds-scale worlds and flying 2026-10-26 afternoon; this second pass (signs, open farms, mine sections) 2026-10-26 ~21:00 (all 5 places); the Skyblox Town 2026-10-26 evening (Town place). Their names in Creator Hub are still Roblox's defaults ("koiopio's Place: 10262026_1/2/3" = Mining/Woodcutting/Farming; "…10242026_1" = Town). See [[Roadmap]].
- **Slaying World** zones (your PvE reference: dead trees, brown and terracotta ground, grey boulders, torches, mobs): with PvE.
- Node items (an Iron Node you buy, place and mine forever): later, with rare ores. See [[Decision Log]].

Related: [[Islands (Roblox)]] · [[Skybounds (Minecraft)]] · [[Economy & Values]] · [[Skills & Levels]] · [[Warzone]]
