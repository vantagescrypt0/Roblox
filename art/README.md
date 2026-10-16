# Art (Blender)

## Blocks (Minecraft-style) — what the game uses now
`scripts/blocks.py` draws 16x16 pixel-art tiles into `textures/blocks.png` (scaled up 8x so they stay crisp) and builds one 3-stud cube per block type with each face mapped to the right tile → `export/Blocks.fbx`.

Importing:
1. Import 3D `export/Blocks.fbx` (Anchored on). **Wait until every block's `MeshContent.SourceType` is `Uri`** (uploaded) before saving.
2. Move the MeshParts into a folder named `Blocks` (names without the `Block_` prefix, CollisionFidelity Box, Material SmoothPlastic), Save to File → `game/assets-replicated/Blocks.rbxm` (synced to `ReplicatedStorage.Blocks`).
3. **Rojo can't live-sync meshes.** Close the place (Don't Save), run `rojo build -o game.rbxlx`, reopen it, reconnect Rojo. Otherwise blocks show as grey checkered placeholders.

To add a block: add a tile in `draw_tiles()` + an entry in `BLOCKS`, re-run, re-import, and add it to `game/src/shared/Blocks.luau`.

## Items (tools and crops)
`scripts/tools.py` draws each item as a 16x16 pixel sprite (text grids at the top of the script; handle bottom-left, head top-right like Minecraft) into `textures/items.png`, then extrudes every pixel into a little cube (1 pixel = 0.2 studs, so a tool is 3.2 studs) → `export/Tools.fbx`, preview `renders/Tools.png`. Tools are generated per tier from one sprite + a colour palette (Wooden/Stone/Crystal). Objects are named exactly like the item ids (`StonePickaxe`, `Wheat`, ...).

```
"%LOCALAPPDATA%\Programs\blender-5.2.2-windows-x64\blender.exe" --background --factory-startup --python art/scripts/tools.py
```

Importing: Import 3D `export/Tools.fbx` (Anchored on), wait for `MeshContent.SourceType = Uri`, move the MeshParts into a folder `ItemModels` (CanCollide/CanTouch/CanQuery off, Massless, SmoothPlastic), Save to File → `game/assets-replicated/ItemModels.rbxm` (synced to `ReplicatedStorage.ItemModels`), then rebuild the place as above. The game uses them for the item in your hand (`CombatService`) and every item icon (`client/UI/ItemIcon.luau`).

To add an item: draw a sprite, add it to `ITEMS`, re-run, re-import, and give the item a `Model` in `game/src/shared/Items.luau`.

---
The low-poly props and islands below were the previous art direction; only the crop models (`Props.rbxm`) are still used.

Every model is built by a Python script in `scripts/`, so it can be rebuilt or tweaked by changing numbers.

**Style:** stylized low-poly, flat-shaded. Every model uses one shared **palette texture** (`textures/palette.png`, colors defined in `scripts/lowpoly.py`). Each face points at one color swatch, so a whole prop is a single mesh with many colors, and in Roblox a single MeshPart with one TextureID.

| Folder | What |
|---|---|
| `scripts/` | Blender Python. `lowpoly.py` = palette + mesh builder, `common.py` = scene/render helpers |
| `blend/` | Saved `.blend` files you can open and edit in Blender |
| `export/` | `.fbx` files to import into Roblox Studio (texture embedded) |
| `renders/` | Preview images |
| `textures/` | The shared palette |

## Rebuild
```
"%LOCALAPPDATA%\Programs\blender-5.2.2-windows-x64\blender.exe" --background --factory-startup --python art/scripts/props.py
"%LOCALAPPDATA%\Programs\blender-5.2.2-windows-x64\blender.exe" --background --factory-startup --python art/scripts/islands.py
```

## Assets
| File | Script | What's inside |
|---|---|---|
| `export/Props.fbx` | `props.py` | Workbench, Market (stall + sign face + lantern glow), Portal (frame + runes + surface), Planter, crops (Sprout, Young, Wheat, Carrot, Potato, Glowberry + glow) |
| `export/Islands.fbx` | `islands.py` | Island tiers 1-4 (`*_T1`…`*_T4`): GrassTop, IslandBody, Decor, TreeTrunk_N/TreeLeaves_N, Rock_N, Marker_* layout points |

Props are built at the origin, front facing -Y (becomes -Z in Roblox), bottom at z=0.
Islands carry invisible `Marker_*` cubes (Spawn, Workbench, Market, Portal, Plot_N) that the game reads to place things.

## Import into Roblox Studio
1. **Home** → **Import 3D** → pick the FBX. Tick **Anchored**; Scale Unit **Stud**. Import.
2. Paste `scripts/studio_restructure.luau` into the command bar. It splits islands into `Tier1..4`, groups props into models, and sets collisions and glow materials.
3. Select the folder → **Save / Export → Save to File** → `game/assets/Islands.rbxm` / `Props.rbxm`. Rojo syncs them into `ServerStorage.Assets`.

Imported meshes keep a built-in rotation; the game places props by their world-space bottom center (`game/src/server/Util/Props.luau`), so never rely on a prop's pivot rotation.
