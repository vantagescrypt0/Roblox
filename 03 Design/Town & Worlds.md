# Town & Worlds
Built 2026-10-25. Code: `TownService.luau` (Town), `WorldService.luau` (the worlds), `Shops.luau` (who buys and sells what), `Util/Npc.luau` (the shopkeepers).

## Research: how the hubs we're borrowing from look
**Islands (Roblox) — the Hub** (fan wiki, robloxislands.fandom.com: Hub, Villager pages; read 2026-10-25)
- One shared island you reach through your island's portal. The first thing you see is a **central area** with a big portal back home.
- **Villagers each run one trade**, standing in front of their own themed building: Cletus (farmer: seeds, crops, farm tools), John (blocks), Jade (miner: ores and mining tools), Thomas (fisherman, by the lake and docks), Taliyah (animals, her barn), Arius (totems), Jack (mechanic), Dom (wholesaler: buys crops in bulk), Petur (baker), Fulco (florist), and more. John and Jack stand side by side on a small hill.
- **Other portals sit at the ends of paths**: one next to Ivon to Slime Island, one at the end of the path to Maple Isles. Event portals open in the central area.
- The Hub had its own **mining area with rocks that respawn** (stone, coal, iron). Rarer ores are only on later islands.
- Seasonal makeovers (Halloween, Christmas) and a countdown board for events.

**Skybounds (Minecraft)**: the server is shut down and almost nothing about its spawn survives online. From the listings: a spawn hub with warps to "10 worlds/warzones with loot and ores". Your memory is the best source here; tell me anything you remember about its spawn.

**What we took:** one trade per shopkeeper, each at their own stall; the portal home where you arrive; world portals at the end of the main path; resources that respawn in shared worlds, with rare ones found elsewhere. Names, characters and layout are our own.

## The Town (hub)
A round floating island (radius 26 blocks), all protected.
- **Arrive** at the south end, in front of the runestone **portal home** (sign "HOME"), on a cobblestone path lined with hedges and lamp posts.
- **The plaza**: a cobblestone square around a **well** (cobblestone ring, water, plank roof on four posts). Four market stalls with red-and-white wool awnings face into it, two on each side:
  | Shopkeeper | Look | Buys | Sells |
  |---|---|---|---|
  | **Merchant** (west) | travelling trader: cap, mustache, green vest, red scarf, backpack with lantern | Wheat, Carrot, Potato, Glowberry ("Sell all crops" button) | Wheat/Carrot/Potato Seeds (Farming-level gated) |
  | **Lumberjack** (west) | red plaid shirt, suspenders, green beanie, big beard, axe on his back | Wood | Sapling (20) |
  | **Builder** (east) | white shirt, blue overalls, red bandana, tool belt with hammer and pouch | – | Grass (3), Dirt (2), Cobblestone (4), Red Wool (6), White Wool (6) |
  | **Miner** (east) | yellow hard hat with a working headlamp, grey beard, overalls, pickaxe on his back | Stone, Coal, Raw Iron, Iron Ingot | Coal (10) |
  Each has goods on the counter, a name board on the roof, a name tag, their own greetings, and a head that turns to watch you. Click / tap them or use their **Trade** prompt (E).
- **The portal row** at the north end: four runestone arches, each with a sign and blocks beside it showing what's inside:
  | Portal | Field | Beside it | Status |
  |---|---|---|---|
  | Farming | gold | farmland with wheat and carrots | open |
  | Woodcutting | green | log-and-leaf posts | open |
  | Mining | orange | stone with coal and iron ore | open |
  | Slaying | dark red, boarded up | obsidian | "Coming soon" (until PvE) |
- A few oaks around the edge. Player trading happens here (level 5, see [[Economy & Values]]).

## The resource worlds
Each world is **its own place** with its own servers (like Town). You arrive at the south end next to two portals, **Back to Town** and **Go home**, under a welcome sign. Everything you can gather is a **node** that grows back in place, shared by everyone on that server. The ground can't be broken and nobody can build there. Same skills, XP, tools, double drops and level gates as on your island.
- **Mining World** (radius 28): a cobblestone quarry floor ringed with grass, ~24 rocky outcrops of stone with coal and iron ore (more iron higher up), and a cliff face along the north edge. Iron needs a Stone pickaxe.
- **Woodcutting World** (radius 28): a forest of ~40 oaks on a loose grid. Logs regrow in 20s, leaves in 30s; leaves drop saplings (8%).
- **Farming World** (radius 24): three fields of wild, already-growing crops off a cobblestone path: Wheat (80 plots, anyone), Carrots (66, Farming 5), Potatoes (56, Farming 10), each with a signpost, plus oaks around the edge. Click a ripe crop to harvest (crop, Farming XP, 10% spare seed, hoe bonus); it regrows on its normal timer for everyone.
- **Only today's resources.** Rarer ores, trees and crops won't be in these worlds; they'll come from somewhere else (e.g. the Warzone) later.
- **Slaying World**: not built (waits for PvE).

## Not done yet
- Published 2026-10-25 as places in "Sky Farm Prototype" (ids in `Places.luau`). Their names in Creator Hub are still Roblox's defaults ("koiopio's Place: 10262026_1/2/3" = Mining/Woodcutting/Farming; "…10242026_1" = Town). Teleports still need a live test. See [[Roadmap]].
- Node items (an Iron Node you buy, place and mine forever): later, with rare ores. See [[Decision Log]].

Related: [[Islands (Roblox)]] · [[Skybounds (Minecraft)]] · [[Economy & Values]] · [[Skills & Levels]] · [[Warzone]]
