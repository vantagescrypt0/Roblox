# Farming phase: build plan (2026-11-02)

**Changed the same day by the [[Late-game Rule]] and the billion coin scale ([[Economy & Values]]):** Sugarcane stays in the world, now at Farming 40. Strawberry, Dragonfruit and Starfruit are island-only, from seeds out of loot crates and Warzone chests, and their zones are gone. The curves below were refit again; the rule page has the current numbers. The tables below are the original plan.

Phase 3 of the approved [[Late-game Proposal]]: four new crops on four new zone islands, in the same second-ring layout as [[Woodcutting Phase Plan]]. Layouts, grow times and sliver rates are Claude's picks; say if you want any changed. XP and prices come from `tools/balance.py`.

## The crops
| Level | Crop | Harvest with | Grows in | XP | Sells for | Coins/h | Zone | Reached from |
|---|---|---|---|---|---|---|---|---|
| 35 | Sugarcane | Hoe | 5 min | 70 | 31 | ~100k | Sugarcane Mesa: water channels on sand, striped mesas, twisted trees, a sugar mill | Veggie Gardens, north |
| 50 | Strawberry | Hoe | 6 min | 80 | 64 | ~230k | Strawberry Terraces: a hill in stone-walled steps, a farmhouse, giant flowers | Melon Oasis, north |
| 65 | Dragonfruit | Axe | 7 min | 90 | 132 | ~520k | Dragonfruit Dunes: big dunes, cacti, sandstone ruins, a small oasis, hot hazy air | Pumpkin Hollow, north |
| 80 | Starfruit | Hoe | 8 min | 105 | 286 | ~1.2M | Starfruit Orchard: rows under glowing blue trees round a glowing pool, always night | Dragonfruit Dunes, north |

The Merchant buys all four. Each gets its skill challenge (pet, armor and trophy tiers VI to IX) through `Challenges.luau`.

## Seeds come from slivers
The approved rule says slivers work for Farming too. A crop plot is Farming's node: you plant it once and it keeps giving. So:

- These four crops' seeds **aren't sold**. Harvesting them in the Farming World sometimes drops a sliver, and enough slivers craft one seed at the Crafting Table.
- They **never give a spare seed**. The older crops' 10% spare seed chance would make a rare seed multiply and undo the rarity.

| Crop | Sugarcane | Strawberry | Dragonfruit | Starfruit |
|---|---|---|---|---|
| One sliver per harvests | 900 | 1,300 | 1,800 | 2,500 |
| Slivers to a seed | 15 | 15 | 20 | 20 |

## Ruby and Starsteel tools (built in the same pass)
Now that Sugarcane and Redwood exist, the top two tiers from the [[Crafting Proposal]] are in:

| Tier | Head | Handle | Binding | Speed | Needs |
|---|---|---|---|---|---|
| Ruby | Refined Ruby (2 Ruby + Silver Ingot + Gold Ingot, Gem Bench) | Cherry Handle (Cherry Wood + Gold Plate, Anvil) | Cane Rope (Rope + 4 Sugarcane) | x12 | Crafting 35, skill 65 |
| Starsteel | Starsteel Plate (2 Starsteel Ingots, Anvil; ingot = Starstone + Iron Ingot + Gold Ingot, Furnace) | Redwood Handle (Redwood + Starsteel Ingot, Anvil) | Cane Rope | x14 | Crafting 45, skill 80 |

A Ruby pickaxe opens the Star Vault's Starstone, so the Mining ladder is now complete.

## The skill-curve refit
All three skills now have their late resources, so the curves were refit with `tools/balance.py`:

- Skills: `2269.3 x level^0.786`. Mining reaches 99 in about 23 hours, Woodcutting 27, Farming 24.5 (target ~25). Mining's XP moved from the held-low numbers to the model's (Silver 110 up to Starstone 155).
- Player level: `2669.3 x level^1.10`. 5 at ~1.1 h, 10 at ~4 h, 50 at ~75 h (target ~80).
- These are modelled numbers. The model assumes Iron axes and hoes through the whole climb, since better ones need the deep cave's gems, so someone with top tools will go a bit faster. Real players' pace is still unmeasured.
