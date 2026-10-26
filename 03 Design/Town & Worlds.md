# Town & Worlds
Built 2026-10-25, rebuilt the same day for looks (your call: "make it an actual cave you can run up to", "a big island with actual shops", "make it look nice", all worlds; the base island stays as it is). The worlds were rebuilt again 2026-10-26 at Skybounds scale, as zone islands joined by bridges (see below). Code: `TownService.luau` (Town), `WorldService.luau` (runs a world: nodes, crops, arrival square) with one builder per world in `server/Worlds/` (`Mining`, `Woodcutting`, `Farming`), `Worlds/Context.luau` (the builders' toolkit: islands, bridges, islets, flat areas, caves), `Worlds/Common.luau` (zone gateways, signposts, paths, lamps, forests, ponds), `Shops.luau` (who buys and sells what), `Util/Npc.luau` (the shopkeepers), `Util/Build.luau` (walls, roofs, building plots), `Util/Decor.luau` (lanterns, fences, benches, flowers, water, banners, rails, carts, waterfalls, falling snow/petals/leaves, palms, cacti...), `Util/Signs.luau` (plank signs, gateways, signposts), `Util/Ambience.luau` (atmosphere, bloom, sun angle).

## Research: how the hubs we're borrowing from look
**Islands (Roblox) — the Hub** (fan wiki, robloxislands.fandom.com: Hub, Villager pages; read 2026-10-25)
- One shared island you reach through your island's portal. The first thing you see is a **central area** with a big portal back home.
- **Villagers each run one trade**, standing in front of their own themed building: Cletus (farmer: seeds, crops, farm tools), John (blocks), Jade (miner: ores and mining tools), Thomas (fisherman, by the lake and docks), Taliyah (animals, her barn), Arius (totems), Jack (mechanic), Dom (wholesaler: buys crops in bulk), Petur (baker), Fulco (florist), and more. John and Jack stand side by side on a small hill.
- **Other portals sit at the ends of paths**: one next to Ivon to Slime Island, one at the end of the path to Maple Isles. Event portals open in the central area.
- The Hub had its own **mining area with rocks that respawn** (stone, coal, iron). Rarer ores are only on later islands.
- Seasonal makeovers (Halloween, Christmas) and a countdown board for events.

**Skybounds (Minecraft)**: the server is shut down and almost nothing about its spawn survives online. From the listings: a spawn hub with warps to "10 worlds/warzones with loot and ores". Your memory is the best source here; tell me anything you remember about its spawn.

**What we took:** one trade per shopkeeper, each at their own stall; the portal home where you arrive; world portals at the end of the main path; resources that respawn in shared worlds, with rare ones found elsewhere. Names, characters and layout are our own.

## New blocks (2026-10-25)
20 new textured blocks drawn by `art/scripts/blocks.py` (atlas now 7×7 tiles): Stone Bricks, Mossy Stone Bricks, Mossy Cobblestone, Bricks, Smooth Stone, Plaster, Dark Planks, Barn Planks, Red and Slate Roof Tiles, Thatch, Gravel, Sand, Dirt Path, Flowery Grass, Hay Bale, Crate, Barrel, Bookshelf, Dark Stone (the unbreakable rock behind mine walls), plus Glass and Water (plain parts added to the Blocks folder in Studio). The Builder sells the building ones (see [[Economy & Values]]).

## Zone blocks and signs (2026-10-26)
19 more tiles (atlas now 9×9 at 112 px): Birch, Spruce and Cherry logs and leaves, Autumn Leaves, Snow, Snowy Grass, Gold Ore, Pumpkin, Melon, Terracotta, Red Terracotta, plus Ice (a plain part). Signs everywhere use a **blocky pixel font** (Press Start 2P) and sit **above head height**: gateways have five-block posts with the sign under the beam (readable from both sides), signposts are four blocks tall.

## The Town (hub)
A big round floating island (radius 40 blocks), all protected, lit by lanterns everywhere, with a soft atmosphere and the sun in the south. Its two gates have taller pillars now, so their signs sit well above everyone's heads.
- **Arrival plaza** (south): smooth stone around the runestone **portal home**; a stone **"WELCOME TO TOWN" gate** with lanterns; the main street runs north between hedges, lamp posts and two planted trees.
- **Market Square** (middle): cobblestone and stone-brick rings around a **fountain** (stone basin, water, a centre pillar spraying, four corner spouts), benches, lamp posts. Four **shops you walk into** face the square, each a real building with a stone foundation, timber corner posts and beams, glass windows with flower boxes, a stepped gable roof, the shop's name on the gable, lanterns by the door, and inside a counter with the shopkeeper behind it, goods on the counter, shelves, lanterns:
  | Shop (sign) | Building | Outside | Shopkeeper | Buys | Sells |
  |---|---|---|---|---|---|
  | **MARKET** (west) | plaster and timber, red tiles, striped awning | crates of crops, hay bales | **Merchant**: travelling trader (cap, mustache, green vest, red scarf, backpack with lantern) | Wheat, Carrot, Potato, Pumpkin, Melon, Glowberry ("Sell all crops") | Wheat/Carrot/Potato/Pumpkin/Melon Seeds (Farming-gated) |
  | **LUMBER YARD** (west) | log walls, slate roof | log piles, a stump with an axe in it | **Lumberjack**: plaid shirt, beanie, big beard, axe on his back | Wood, Birch/Spruce/Cherry Wood | Sapling (20) |
  | **BUILDER** (east) | bricks and stone, slate roof, blue awning | scaffolding, pallets of blocks | **Builder**: overalls, red bandana, tool belt | – | 13 building blocks (Grass 3 … Glass 6) |
  | **MINER** (east) | stone bricks with mossy footings, slate roof, forge chimney with smoke | rails with a cart of iron ore, barrels | **Miner**: hard hat with a working headlamp, grey beard, pickaxe on his back | Stone, Coal, Raw Iron, Iron Ingot, Raw Gold, Gold Ingot | Coal (10) |
  Click / tap a shopkeeper or use their **Trade** prompt (E). Their heads turn to watch you; name tags show through the door (not through walls).
- **Lanes**: west to a **garden** with a roofed stone well, flower beds and benches; east to a **park** with a sandy pond, lily pads and benches. **Four cottages** (plaster and timber, thatch or red tiles, chimneys with smoke, bed/table/bookshelf inside, fenced flower yards, paths to the street).
- **Portal Plaza** (north), through a tall **"THE WORLDS" gate** set well back from the portals (moved 2026-10-26: it used to crowd the middle arches): the runestone arches with their signs, themed blocks beside each, and **one tall banner pole behind each arch** flying the portal's colour above it:
  | Portal | Field | Beside it | Status |
  |---|---|---|---|
  | Farming | gold | farmland with crops, hay | open |
  | Woodcutting | green | log-and-leaf posts | open |
  | Mining | orange | stone with coal and iron ore | open |
  | Slaying | dark red, boarded up | obsidian | "Coming soon" (until PvE) |
- Oaks round the edge, flowers and tall grass in the lawns. Player trading happens here (level 5, see [[Economy & Values]]).

## The resource worlds (rebuilt 2026-10-26, Skybounds-scale)
You showed Skybounds screenshots (huge wheat fields under a terracotta mountain, a giant cavern with lava falls and hanging vines, big oaks on stone cliffs, islands joined by bridges on the minimap) and chose: **~3x wider**, **a new resource per zone, unlocked by level**, **zones on their own islands joined by bridges**; the mine is one big cave with a mix of ores.

Each world is **its own place** with its own servers (like Town), about **230 blocks across**: an **arrival island** in the south and **three zone islands** (west, north, east) joined to it by **plank bridges** (five blocks wide, railings, log beams underneath, lantern posts), with little **floating islets** around. You arrive in a paved square at the south end with two portals, **Back to Town** and **Go home**, under a tall **gateway** with the world's name. Each zone island has a gateway at its bridge end with the zone's name and the level its resource needs. Main paths with lamp posts link the square, the bridges and each zone's sights. Everything you can gather is a **node** that grows back in place, shared by everyone on the server; scenery can't be broken and nobody can build there.

**How the world ends:** hills ease down toward a ragged rim; the grass hangs over the rock in a thin lip; underneath hangs a cone of rock in chunky four-block terraces with spikes, deepest in the middle; roots dangle under the lip and vines hang down the cliffs. The Oak Woods river pours off both sides of its island as **waterfalls** fading into mist.

| World | Zone (island) | Resource (level) | What's there |
|---|---|---|---|
| **Woodcutting** | **Oak Woods** (arrival) | Oak → Wood (anyone) | rolling hills of oaks and big old oaks, a river with a plank bridge and two waterfalls, the lumber camp (log cabin, sawmill with a spinning blade, log piles, campfire), fallen logs, mushrooms |
| | **Birch Grove** (west) | Birch → Birch Wood (Woodcutting 10) | slim white birches in a flower meadow, a lily pond with a dock and benches, fallen birch logs |
| | **Snowy Pines** (north) | Spruce → Spruce Wood (Woodcutting 20) | snowy hills, tall slim spruces, a frozen lake (ice you can walk on), a trapper's cabin of spruce logs with a smoking chimney, snowy boulders, falling snow |
| | **Cherry Hills** (east) | Cherry → Cherry Wood (Woodcutting 30) | pink cherry trees with forked trunks, a koi pond with a red-railed bridge and lily flowers, stone lanterns, an open pavilion with a red roof, drifting petals |
| **Farming** | **Wheat Plains** (arrival) | Wheat (anyone) | three big fenced wheat fields, a striped **terracotta mesa** fifteen blocks high, the windmill (taller, bigger sails), red barn, thatched farmhouse with a flower garden, farmyard well and hay cart, a lily pond |
| | **Veggie Gardens** (west) | Carrots (Farming 5), Potatoes (Farming 10) | two carrot and two potato fields either side of the path, a glasshouse full of flowers, crates and barrels of produce |
| | **Pumpkin Hollow** (north) | Pumpkins (Farming 15) | three pumpkin patches among orange autumn trees, jack-o'-lanterns glowing along the path, hay bales, leaf piles, falling leaves |
| | **Melon Oasis** (east) | Melons (Farming 25) | a sandy island over striped terracotta rock, two melon fields, an oasis pool ringed with palms, cacti on the dunes, a market stall with a green awning |
| **Mining** | **The Quarry** (arrival) | stone, coal, iron outcrops | gravel yards, the miner's hut, a tent and campfire, ore carts on rails |
| | **The Mountain** (north) | everything below | a snow-capped mountain 44 blocks high with grassy foothills and oaks; a timbered mouth ("THE MINE") leads into the **great cavern**, thirty blocks high: lava pours from the roof into a glowing pool, vines, roots and glowing crimson buds hang from the roof, glowing mushrooms grow on the floor, scaffolds with lanterns, a miner's hut, crates and barrels. A tunnel winds **down west to the deep gold chamber** (sign: "GOLD · MINING 10") and one **east to the crystal grotto** (purple crystals). |

- **Mine walls** are two blocks of ore that grows back: mostly stone, coal and iron, a little gold low down, and plenty of gold in the deep chamber; behind is dark stone. Floors can't be broken. Caves stay at least four blocks inside the rock, so they never break out of the mountain's side (the old mine did, near the ground).
- **Fields** are fenced with a gate toward the path, every fourth row a water channel, a scarecrow in the middle, and a **signpost four blocks tall, two blocks off the fence** beside the gate. Ripe pumpkins and melons show as their block with a leaf.
- **Level gates:** chopping or mining a zone's resource below its level does nothing but tell you the level ("Birch Wood needs Woodcutting level 10"). Placed blocks are never gated. New items, prices and shops: see [[Economy & Values]].
- **Slaying World**: not built (waits for PvE); its zones will be themed the same way.
- **Sizes** (Studio, 2026-10-26): Woodcutting ~25k block parts, Farming ~20k, Mining ~30k (+2–4k decor parts each), built in 3–6 seconds on server start. Ground, rock and other unbreakable scenery are drawn as **merged pieces** (a mesh several blocks big that looks exactly like those blocks; `ReplicatedStorage.Blocks.Merged`), and islands only store their outer shell. Worth checking on a phone.

## Not done yet
- The first versions were published 2026-10-25 as places in "Sky Farm Prototype" (ids in `Places.luau`); you've been through the portals live. The rebuilt Town and worlds were published the same evening (all 5 places together). The Skybounds-scale worlds (2026-10-26) are playtested in Studio but **not published yet**.
- Flying (your note): not built; where, which key and how fast still to decide. Their names in Creator Hub are still Roblox's defaults ("koiopio's Place: 10262026_1/2/3" = Mining/Woodcutting/Farming; "…10242026_1" = Town). See [[Roadmap]].
- Node items (an Iron Node you buy, place and mine forever): later, with rare ores. See [[Decision Log]].

Related: [[Islands (Roblox)]] · [[Skybounds (Minecraft)]] · [[Economy & Values]] · [[Skills & Levels]] · [[Warzone]]
