# Sword fit

Your rule (2026-11-04): "make sure none of the swords overlap, especially with armour." These scripts measure that on
the real meshes, so a pose change can be checked without playing through every combination. Run them whenever a pose
changes in `game/src/shared/SwordArt.luau`, or a sword or armour set is added.

| Script | What it does |
|---|---|
| `check.py` | Every sword against every armour set and bare shoulders: resting, sprinting, the blend between them, and every step of a swing starting from either. Reads the poses from `SwordArt.luau`. Run this first. |
| `record.py` | In a running Studio playtest, plays real swings and sprints and records every frame: the sword, both arms, the head and the shield, wherever the animations put them. Needs the items given first (the slots it picks are at its `SLOTS`). Needs the PC unlocked, as it counts rendered frames. |
| `real_check.py` | Measures what `record.py` recorded, including your arms, which `check.py` can't move. |
| `tune.py` | Takes a pose you like the look of and moves it as little as it takes to clear everything. |
| `render.py` | Plain-colour pictures of a hold from any side, for judging its shape. |
| `holdlib.py` | The shared maths. Holds the avatar's measurements and each sword's numbers: **add a new sword's numbers to `SWORDS` here.** |

**Setting up** (only needed once, or after a mesh changes). With a place open in Studio in Edit mode:

```bash
python art/scripts/sword_fit/export_meshes.py WoodenSword StoneSword IronSword AmethystSword SapphireSword CrystalSword RubySword StarsteelSword Shield
```

```bash
blender -b --python art/scripts/sword_fit/armour_geo.py
```

They write `meshes.json` and `armour.json` here. They're left out of git, as they can be made again.

**Checking:**

```bash
blender -b --python art/scripts/sword_fit/check.py
```

`TOTAL HITS 0` is what you want. `gap` is the closest any part of that sword gets to anything, in studs. Add `-- RubySword,IronSword` to check only those.

**What it doesn't cover:** avatars other than the one measured (the numbers at the top of `holdlib.py`), hats and hair (a helmet hides those, but bare heads can wear anything), and other players' bodies.
