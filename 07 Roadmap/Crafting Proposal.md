# Crafting Proposal (2026-10-31, waiting for your OK)

Your ask: crafting shouldn't be Minecraft-easy ("a sword isn't a stick and two diamonds ... maybe it needs refined diamonds"). Today every tool is head material + sticks (`game/src/shared/Recipes.luau`).

## The rule
Every tool past Wooden is built from **three parts**, each refined from raw resources first:

- **Head** from Mining: refined metal or gems (plates, refined gems)
- **Handle** from Woodcutting: sticks, then handles from better woods
- **Binding** from Farming: twine and rope made from crops

So a top tool needs all three Grinding Worlds (or trading with players who grind them), and every part is its own step.

## New stations
- **Anvil** (3 Iron Ingots + 4 Stone, placed on your island): hammers ingots into plates, and puts together Iron and better tools.
- **Gem Bench** (comes with the new ores): cuts and refines gems.
- The Crafting Table and Furnace stay.

## The ladder
| Tier | Head (x3 for a pickaxe or axe, x2 for a sword or hoe, x1 for a shovel) | Handle | Binding | Made at |
|---|---|---|---|---|
| Wooden | Planks | Sticks | — | Table (unchanged, so the tutorial starts the same) |
| Stone | Stone | Sticks | **Twine** (4 Wheat) | Table |
| Iron | **Iron Plate** (2 Iron Ingots, Anvil) | **Sturdy Handle** (2 Sticks + 1 Iron Ingot) | **Rope** (3 Twine) | Anvil |
| Amethyst | **Refined Amethyst** (2 Amethyst + 1 Silver Ingot, Gem Bench) | **Birch Handle** (Birch log + Iron Plate) | Rope | Anvil |
| Sapphire | **Refined Sapphire** (2 Sapphire + 1 Gold Ingot) | **Spruce Handle** (Spruce log + Silver Plate) | Rope | Anvil |
| Ruby | **Refined Ruby** (2 Ruby + 1 Silver Ingot + 1 Gold Ingot) | **Cherry Handle** (Cherry log + Gold Plate) | **Cane Rope** (Rope + 4 Sugarcane) | Anvil |
| Starsteel | **Starsteel Plate** (2 Starsteel Ingots; ingot = Starstone + Iron Ingot + Gold Ingot, Furnace) | **Redwood Handle** (Redwood log + Starsteel Ingot) | Cane Rope | Anvil |

Crystal (from the Warzone) stays a side tier for when the Warzone opens: Refined Crystal = Crystal + Gold Ingot.

**Example: a Sapphire Sword** = 2 Refined Sapphire (4 Sapphire + 2 Gold Ingots) + a Spruce Handle (Spruce log + a Silver Plate, which is 2 Silver Ingots) + Rope (3 Twine = 12 Wheat). That's about a dozen raw resources from all three worlds, and five crafting steps.

## What it adds
- **Now (with the Iron tier):** Twine, Rope, Iron Plate, Sturdy Handle, Anvil (5 new items, 3D models and icons like the rest).
- **With each new ore in the Mining phase:** its refined gem, its handle, the Gem Bench, Silver/Gold Plates, Cane Rope.
- Crafting XP per part, so Crafting levels up from refining too (refit in `tools/balance.py`).
- Beginner chain: a new step "Craft Twine from Wheat" before "Craft a Stone Pickaxe" (it comes right after the harvesting step).
- Crafting challenges: "Hammer 25 Iron Plates", "Refine 50 gems" and so on.

## Questions
1. OK with three parts per tool (head, handle, binding)?
2. Keep Wooden tools simple for the tutorial?
3. Anything you'd want harder still (e.g. tools needing a Crafting level *and* a station upgrade)?
