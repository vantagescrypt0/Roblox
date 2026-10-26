# Town & Worlds
Built 2026-10-25, rebuilt the same day for looks (your call: "make it an actual cave you can run up to", "a big island with actual shops", "make it look nice", all worlds; the base island stays as it is). Code: `TownService.luau` (Town), `WorldService.luau` (shared world tools, nodes, crops, arrival) with one builder per world in `server/Worlds/` (`Mining`, `Woodcutting`, `Farming`), `Shops.luau` (who buys and sells what), `Util/Npc.luau` (the shopkeepers), `Util/Build.luau` (walls, roofs, building plots), `Util/Decor.luau` (lanterns, fences, benches, flowers, water, banners, rails, carts...), `Util/Ambience.luau` (atmosphere, bloom, sun angle).

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

## The Town (hub)
A big round floating island (radius 40 blocks), all protected, lit by lanterns everywhere, with a soft atmosphere and the sun in the south.
- **Arrival plaza** (south): smooth stone around the runestone **portal home**; a stone **"WELCOME TO TOWN" gate** with lanterns; the main street runs north between hedges, lamp posts and two planted trees.
- **Market Square** (middle): cobblestone and stone-brick rings around a **fountain** (stone basin, water, a centre pillar spraying, four corner spouts), benches, lamp posts. Four **shops you walk into** face the square, each a real building with a stone foundation, timber corner posts and beams, glass windows with flower boxes, a stepped gable roof, the shop's name on the gable, lanterns by the door, and inside a counter with the shopkeeper behind it, goods on the counter, shelves, lanterns:
  | Shop (sign) | Building | Outside | Shopkeeper | Buys | Sells |
  |---|---|---|---|---|---|
  | **MARKET** (west) | plaster and timber, red tiles, striped awning | crates of crops, hay bales | **Merchant**: travelling trader (cap, mustache, green vest, red scarf, backpack with lantern) | Wheat, Carrot, Potato, Glowberry ("Sell all crops") | Wheat/Carrot/Potato Seeds (Farming-gated) |
  | **LUMBER YARD** (west) | log walls, slate roof | log piles, a stump with an axe in it | **Lumberjack**: plaid shirt, beanie, big beard, axe on his back | Wood | Sapling (20) |
  | **BUILDER** (east) | bricks and stone, slate roof, blue awning | scaffolding, pallets of blocks | **Builder**: overalls, red bandana, tool belt | – | 13 building blocks (Grass 3 … Glass 6) |
  | **MINER** (east) | stone bricks with mossy footings, slate roof, forge chimney with smoke | rails with a cart of iron ore, barrels | **Miner**: hard hat with a working headlamp, grey beard, pickaxe on his back | Stone, Coal, Raw Iron, Iron Ingot | Coal (10) |
  Click / tap a shopkeeper or use their **Trade** prompt (E). Their heads turn to watch you; name tags show through the door (not through walls).
- **Lanes**: west to a **garden** with a roofed stone well, flower beds and benches; east to a **park** with a sandy pond, lily pads and benches. **Four cottages** (plaster and timber, thatch or red tiles, chimneys with smoke, bed/table/bookshelf inside, fenced flower yards, paths to the street).
- **Portal Plaza** (north), through a **"THE WORLDS" gate**: the runestone arches with their signs, themed blocks beside each, and a **banner in each portal's colour**:
  | Portal | Field | Beside it | Status |
  |---|---|---|---|
  | Farming | gold | farmland with crops, hay | open |
  | Woodcutting | green | log-and-leaf posts | open |
  | Mining | orange | stone with coal and iron ore | open |
  | Slaying | dark red, boarded up | obsidian | "Coming soon" (until PvE) |
- Oaks round the edge, flowers and tall grass in the lawns. Player trading happens here (level 5, see [[Economy & Values]]).

## The resource worlds
Each world is **its own place** with its own servers (like Town). You arrive in a paved square at the south end with lamp posts and two portals, **Back to Town** and **Go home**, under a welcome sign. Everything you can gather is a **node** that grows back in place, shared by everyone on that server. Scenery can't be broken and nobody can build there. Same skills, XP, tools, double drops and level gates as on your island.
- **Mining World** (radius 36): a **quarry camp** (gravel yards, a stone miner's hut, a tent by a campfire, ore carts on rails, crates and barrels, a few rocky outcrops) at the foot of a **mountain** (grassy slopes, mossy cliffs, trees on its shoulders). A timber-framed **cave mouth ("THE MINE")** opens onto the **main tunnel** (timber supports, hanging lanterns, rails and a cart) which opens into a **great cavern** (lantern posts, crates, barrels, an underground pool); **side tunnels** wind west and east to two smaller chambers. Every mine wall is stone with coal and iron ore (more iron in the deep chambers), two blocks thick, and grows back; behind it is dark stone, as far as anyone can dig. Inside it's properly dark between the lanterns. Iron needs a Stone pickaxe.
- **Woodcutting World** (radius 36): **rolling hills** of oaks and **big old oaks** (every log and leaf grows back; leaves drop saplings), a **river** with sandy banks and a **wooden bridge** with lanterns, a **lumber camp** (log cabin with a chimney, a sawmill shed with a **spinning saw blade**, log piles, a campfire with log seats), bushes, fallen logs, mushrooms, flowers and tall grass, and lamp posts along the path.
- **Farming World** (radius 34): a **farmstead**. Three **fenced fields** of wild crops in rows with **water channels** between them, a **scarecrow** in each and a signpost at each gate: Wheat (anyone), Carrots (Farming 5), Potatoes (Farming 10). A **red barn** (white trim, slate roof, loft door, hay inside and out), a **windmill** whose sails turn, a thatched **farmhouse** with a fenced flower garden, a **pond** with lily pads and a plank dock, and a **farmyard** with a roofed well, a trough and a hay cart. Click a ripe crop to harvest (crop, Farming XP, 10% spare seed, hoe bonus); it regrows on its normal timer for everyone.
- **Only today's resources.** Rarer ores, trees and crops won't be in these worlds; they'll come from somewhere else (e.g. the Warzone) later.
- **Slaying World**: not built (waits for PvE).
- Sizes: about 15,000 parts in Town and 10,000–15,000 per world (fine on PC; worth watching on phones).

## Not done yet
- The first versions were published 2026-10-25 as places in "Sky Farm Prototype" (ids in `Places.luau`); you've been through the portals live. The rebuilt Town and worlds aren't published yet. Their names in Creator Hub are still Roblox's defaults ("koiopio's Place: 10262026_1/2/3" = Mining/Woodcutting/Farming; "…10242026_1" = Town). See [[Roadmap]].
- Node items (an Iron Node you buy, place and mine forever): later, with rare ores. See [[Decision Log]].

Related: [[Islands (Roblox)]] · [[Skybounds (Minecraft)]] · [[Economy & Values]] · [[Skills & Levels]] · [[Warzone]]
