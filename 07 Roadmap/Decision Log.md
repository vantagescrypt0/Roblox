# Decision Log

| Date | Decision | Why |
|---|---|---|
| 2026-10-14 | Solo project; Claude does the building, you test and publish | Your call |
| 2026-10-14 | Target younger players, fair-value monetization only | Core Roblox audience; Roblox policy direction |
| 2026-10-14 | No fixed timeline — quality first | Your call |
| 2026-10-15 | Direction: blend Islands (Roblox) + Skybounds Warzone (Minecraft) | You loved both; Warzone was your favorite moment |
| 2026-10-15 | Notes live in this repo as an Obsidian vault | Shared between you and Claude |
| 2026-10-14 | Warzone death: your avatar's head drops as a loot container; open it to take the loot, which stays inside until taken | How Skybounds worked; keeps risk and reward |
| 2026-10-14 | Warzone has PvP + PvE + farming + chests | Your call |
| 2026-10-14 | Skill levels (Farming, Combat): crops and mobs are level-gated; higher level = better rewards | Long-term progression |
| 2026-10-14 | Player level (like Skybounds); the Warzone unlocks at a set player level | Your call; also protects brand-new players from PvP |
| 2026-10-14 | Beginner tutorial built from quests, ending at the Warzone unlock | Teach the loop to young players |
| 2026-10-15 | Player level 1–50; level 10 unlocks the Warzone; XP from PvE, grinding and quests | Same as Skybounds |
| 2026-10-15 | Seasons of 2–4 months; player level resets each season | Same as Skybounds; fresh start every season |
| 2026-10-15 | Repo layout: `game/` = Rojo code, `art/` = Blender scripts + exports; models built by Python script | Reproducible models Claude can tweak; no extra Blender plugin needed |
| 2026-10-15 | Player data uses ProfileStore (vendored, pinned commit) | Session locking stops the same save being open on two servers, which is a common cause of item duplication |
| 2026-10-15 | Island expansion: spend coins to grow your island through 4 tiers (Starter → Meadow 300 → Grove 1,500 → Grand 6,000 coins; 6/9/12/16 farm plots). Prices are placeholders | Your call ("expand your island with spending money") |
| 2026-10-15 | ~~Art direction: stylized low-poly~~ → replaced the same day by the Minecraft-style block look (below). The cartoon UI (HUD, windows) stays | — |
| 2026-10-15 | **Minecraft-style blocks.** Islands are made of 3-stud blocks with 16x16 pixel-art textures; players break (hold click) and place (right-click) blocks; changes are saved. Blocks so far: Grass, Dirt, Stone, Wood (logs), Leaves, Planks, Cobblestone, Wool, plus special Crafting Table, Farmland, Obsidian | Your call ("make the island made of blocks… heavy inspo from Minecraft") |
| 2026-10-15 | **5-slot Minecraft-style hotbar** (keys 1-5 / tap), new items drop into the first empty slot; Minecraft-style inventory to rearrange it | Your call |
| 2026-10-15 | **Market moved off the island into Town.** The island portal now goes to Town (a shared block plaza); Town has the Market and a portal home. The Warzone will be added to Town later (its code is switched off until then) | Your call |
| 2026-10-15 | Workbench → Crafting Table block; planters → Farmland blocks; chopped trees regrow after ~90s | Fits the block style; keeps wood renewable |
| 2026-10-15 | Islands float at Y=200 on a grid of plots, one per player; falling off returns you to your island instead of killing you | Kid-friendly; the void isn't a punishment on your safe island |
| 2026-10-15 | **Toughness + tool power (Minecraft rules).** Every block has a Hardness and a best tool (Pickaxe/Axe/Shovel). Hold to break: Hardness x 1.5 / tool speed with the right tool, x 1.5 by hand; stone needs a pickaxe or it breaks slowly (x 5) and drops nothing. Tools have Tier (Wooden/Stone/Crystal), mining speed (x2/x4/x8), Damage, Durability (60/132/500 uses), Cooldown and Range. Tools wear down and break | Your call ("make a toughness system for blocks and a power system for tools") |
| 2026-10-15 | Tools are crafted from Planks/Stone/Crystal + Sticks with Minecraft's costs; pixel-art 3D models for every tool and crop (made in Blender), held in your hand and shown as 3D "photos" in the hotbar, inventory and crafting table | Your call |
| 2026-10-15 | **Farming is click-only**: click farmland to plant the seeds in your hand (or your best seeds), click a ripe crop to harvest. No key press | Your call |
| 2026-10-15 | A **Merchant NPC** (blocky villager with a straw hat) runs the Market stall: watches you, greets you, and opens the Market when you click or tap it | Your call |
