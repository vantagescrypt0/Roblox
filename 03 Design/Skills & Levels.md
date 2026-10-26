# Skills & Levels (Draft)

## Built (2026-10-24)
Five skills, each with its own level (1–99), next to the player level. Code: `Skills.luau` (the list), `Recipes.luau` (what each recipe needs), `ProgressionService.luau`.

| Skill | How you train it | XP | What it unlocks |
|---|---|---|---|
| **Farming** | Harvest ripe crops | Wheat 10, Carrot 25, Potato 55, Glowberry 90 | Stone Hoe (3), Carrot seeds (5), Iron Hoe (6, + Crafting 3), Glowberry (8), Potato (10), Crystal Hoe (12, + Crafting 8); more tilled plots as you level |
| **Mining** | Mine the island's boulders and ore with a pickaxe, or anything in the Mining World | Stone 5, Coal Ore 12, Iron Ore 20 | Iron Pickaxe and Shovel (4), Crystal ones (8) |
| **Woodcutting** | Chop the island's trees, trees you planted, or the Woodcutting World's forest | Wood 6 | Iron Axe (4), Crystal Axe (8); more planted trees as you level |
| **Crafting** | Craft or smelt anything | Planks/Sticks 4, Iron Ingot 10, Furnace 25; tools 10 / 20 / 50 / 120 by tier | Every Iron tool (3) and Crystal tool (8) |
| **Combat** (the PvE level) | Defeat monsters in the Warzone | per monster | Crystal Sword (8); tougher monsters (Brute needs 5) |

- **Crafting needs skill levels.** Every Iron and Crystal tool needs a Crafting level *and* the tool's own skill: an Iron Pickaxe needs Crafting 3 and Mining 4, a Crystal Axe needs Crafting 8 and Woodcutting 8. Wooden and Stone tools, Planks, Sticks, the Furnace and Iron Ingots need nothing, so the beginner quests always work. Swords only need Combat at the Crystal tier, because Combat XP only comes from the Warzone (which is switched off for now).
- **Better rewards:** Farming, Mining and Woodcutting give a +1% chance per level of a double drop (Farming already did; now all three).
- **No XP from blocks you placed.** Only the island's own resource nodes (trees, boulders) and ore veins give Mining/Woodcutting XP and double drops, so placing and re-mining a block can't farm XP or copy items. (Before this, player XP had that hole.)
- **Level-up messages:** "Mining level 4!", and when a level-up makes recipes craftable: "You can now craft: Iron Pickaxe, Iron Shovel".
- **Skills window:** the **Skills** button (or clicking your profile card) shows your player level and every skill's level and XP. Pick a skill to see how to train it, its double-drop chance and all its unlocks (green = ready, gold = this skill is high enough but another isn't yet). Screenshot: `art/renders/ui-skills-window.jpg`.
- **Crafting window:** locked recipes have a "Locked" tag; the details show a Skills row (red until you have the level) and "Needs Woodcutting 4". Screenshot: `art/renders/ui-crafting-skills.jpg`.
- **Hoes (built 2026-10-25):** Wooden Hoe needs nothing, Stone Hoe Farming 3, Iron Hoe Crafting 3 + Farming 6, Crystal Hoe (our top tier, like a diamond hoe) Crafting 8 + Farming 12. Cost: 2 head material + 2 sticks.
  - **Tilling:** hold a hoe and right-click (or tap) grass or dirt on your island with open space above it; it becomes a real farm plot, saved with your island. Each till uses 1 durability.
  - **How many:** 2 tilled plots, plus 1 more every 3 Farming levels (Farming 3 = 3, Farming 12 = 6, max 30), on top of your island's own plots.
  - **Undo:** a shovel on an empty tilled plot turns it back into dirt (a shovel on a crop still digs the crop up first).
  - **Bonus:** holding a hoe while harvesting adds +2% / 4% / 7% / 12% (Wooden → Crystal) double-crop chance on top of your Farming bonus, and uses 1 durability.
- **Saplings and trees (built 2026-10-25, reworked the same day):** trees are **not nodes**, they don't grow back. Natural leaves drop a Sapling 8% of the time, and the Lumberjack in Town sells them (20 coins). Hold one and right-click (or tap) grass or dirt with room above it to plant it; after 3 minutes (counting while you're offline) it grows into an oak.
  - **Felling:** chop a tree's last log and it falls: its leaves drop away over a second or two and you get saplings for them (8% per falling leaf, **always at least 1**), so you can always replant. This goes for the island's own trees too; a felled island tree is gone for good, even after expanding (saved in `Island.Felled`), and its spot is free to plant on.
  - Chopping your island's trees (and planted ones) gives Woodcutting XP and double drops; a log you put back by hand doesn't.
  - **How many:** up to 3 planted trees at once (saplings and grown ones), plus 1 more every 3 Woodcutting levels (max 30). Felling one frees its spot.
  - **Undo:** click a growing sapling to dig it up and get it back.
  - Endless wood: the **Woodcutting World** (through its portal in Town), where every tree grows back. See [[Town & Worlds]].

## Decided
- Separate skill levels: **Farming**, **Mining**, **Woodcutting**, **Crafting** and **Combat (PvE)** (see above).
- **Level gates:** each crop needs a minimum Farming level to plant/harvest; each mob needs a minimum Combat level to fight or loot.
- **Better rewards as you level:** the higher your skill, the better the payoff.
- **Player level (copied from Skybounds):**
  - Levels **1–50**.
  - **Level 10 unlocks the Warzone.** The beginner quests get you there. See [[Tutorial & Quests]].
  - **Level 5 unlocks trading** with other players (built 2026-10-25). See [[Economy & Values]].
  - **XP comes from** PvE, grinding (farming, mining, etc.) and quests.
  - **Seasons:** each lasts 2–4 months, and player level **resets to 1** at the start of each season.
See [[Decision Log]].

## Seasons — to decide
- **What resets?** Player level for sure. What about skill levels, island, items, coins? [Inference] If islands and items reset too, players lose what they built (Pillar #1 "Your island, your story"). A safer version: only player level and the season ladder reset; your island and items stay.
- **Warzone re-locks each season?** If level resets to 1, veterans must hit level 10 again. [Inference] That's fine if it takes them about an hour (catch-up XP boost for returning players?), but frustrating if it takes days.
- **Rewards for the season:** exclusive cosmetics/titles for reaching level 50 or placing high on the leaderboard, kept forever.
- [Inference] "Confusing resets" is one reported reason big Roblox sims declined ([[Trends - Oct 2026]]). Show the season end date clearly in-game, and say exactly what resets and what stays.

## Player level vs skill levels — to decide
- Skill levels (Farming, Combat) control what you can farm/fight; player level controls access (Warzone) and season rewards. Do skill levels also reset each season?
- Do later Warzone zones need higher player levels (e.g., 10 / 25 / 40)? (This would also help PvP fairness.)

## How it could work — [Speculation]
| Level | Farming unlocks | Combat (PvE) unlocks |
|---|---|---|
| 1 | Wheat, carrots | Slimes |
| 10 | Potatoes, berries | Wolves |
| 25 | Pumpkins, melons | Skeletons |
| 50 | Rare crops (Warzone seeds) | Elite / mini-bosses |
| 75+ | Mythic crops | Bosses |
(Placeholder names. The real list goes in [[Content Index]].)

**"Better rewards" per level — pick which:**
- More yield per harvest (e.g., +1% per level).
- Chance for a double or golden harvest.
- Faster grow time / faster mob kills.
- Higher rare-drop chance from mobs.
- Perks at milestone levels (every 10 levels) that change how you play, not just bigger numbers (see [[Anti-Burnout Ideas]]).

[Inference] Bonuses should also apply to low-tier crops/mobs, so old content stays worth something instead of dead.

## Open questions
- Any more skills later (Fishing?)
- XP sources: is it only doing the activity, or also quests and challenges?
- Does PvP (killing players) give Combat XP? [Inference] If it does, high-level players could farm new players for XP.
- Are Warzone mobs and crops level-gated the same way as on the island?
- Level cap? Prestige later?

## Related
- [[Warzone]] · [[Core Loop]] · [[Mechanics to Borrow]] · [[Islands Feature Checklist]]
