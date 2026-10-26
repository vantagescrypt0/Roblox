# Art (Blender)

## Blocks (Minecraft-style) — what the game uses now
`scripts/blocks.py` draws 16x16 pixel-art tiles into `textures/blocks.png` (scaled up 7x so they stay crisp) and builds one 3-stud cube per block type with each face mapped to the right tile → `export/Blocks.fbx`. The same file also holds **merged pieces** (`MERGED` in the script): boxes several blocks big, e.g. `Merged_Stone_8x4x8`, with one quad per block on every face mapped to that block's tile, so a piece looks exactly like the blocks it replaces. The shared worlds draw unbreakable scenery with them (`BlockWorld.drawAll(world, true)`), which keeps the big worlds at a fraction of the parts.

Importing:
1. Import 3D `export/Blocks.fbx` (Anchored on). **Wait until every block's `MeshContent.SourceType` is `Uri`** (uploaded) before saving.
2. Move the MeshParts into a folder named `Blocks` (names without the `Block_` prefix, Material SmoothPlastic) and the `Merged_` ones into a subfolder `Blocks/Merged` (names without the prefix, e.g. `Stone_8x4x8`), add the plain parts (below), Save to File → `game/assets-replicated/Blocks.rbxm` (synced to `ReplicatedStorage.Blocks`). The 2026-10-26 import did all of this with one command bar script (the CollisionFidelity setting can't be changed from the command bar; Default is fine for boxes).
3. **Rojo can't live-sync meshes.** Close the place (Don't Save), run `rojo build -o game.rbxlx`, reopen it, reconnect Rojo. Otherwise blocks show as grey checkered placeholders.

To add a block: add a tile in `draw_tiles()` (new tiles go in `draw_building_tiles()`, after the old ones, so the old tiles keep their random pattern) + an entry in `BLOCKS`, re-run, re-import, and add it to `game/src/shared/Blocks.luau`. The atlas is 9×9 tiles (1008 px, just under Roblox's 1024 limit); 64 are used. To merge a new block type into pieces, add it to `MERGED` with the shape lists that fit how it's used (`SLABS` for one-deep ground, `THICK` for soil, `CUBES` for rock).

**Glass, Water and Ice aren't meshes:** they're plain 3-stud Parts in the same `Blocks` folder (Glass: Glass material, light blue, 0.6 transparency; Water: SmoothPlastic, blue, 0.3 transparency, 0.15 reflectance, CanCollide off; Ice: a Glass copy with Ice material, pale blue, 0.2 transparency). When re-importing, copy them from the old folder before Save to File (the 2026-10-26 import did this from the command bar).

## Items (tools, crops, seeds, ores, loot) and their icons
`scripts/items3d.py` builds every item as a low-poly 3D model with the shared palette (`lowpoly.py`): tapered wooden handles with leather grips, curved pickaxe heads, wedge axe blades, diamond-section sword blades, seed pouches tagged by crop, crops, ore lumps, an ingot, a crystal and a scrap gear. Tiers are materials: Wooden (light wood, leather lashing), Stone (rough chipped stone), Iron (steel, metal collar), Crystal (cyan, gold fittings). Tools are modelled upright and tilted 45° so the handle is bottom-left and the head top-right.

```
"%LOCALAPPDATA%\Programs\blender-5.2.2-windows-x64\blender.exe" --background --factory-startup --python art/scripts/items3d.py
```

It writes:
- `export/Items.fbx` — one object per item, named by item id
- `textures/item_icons.png` — every item (and the block items) rendered as a 128 px icon on one 1024 px sheet, with a dark outline; preview on a dark background in `renders/Items.png`
- `game/src/shared/ItemArt.luau` — generated: where the hand holds each model and each item's icon cell

Importing:
1. Import 3D `export/Items.fbx` (Anchored on), wait for `MeshContent.SourceType = Uri`, move the MeshParts into a folder `ItemModels` (CanCollide/CanTouch/CanQuery off, Massless, SmoothPlastic), Save to File → `game/assets-replicated/ItemModels.rbxm` (synced to `ReplicatedStorage.ItemModels`), then rebuild the place as above. Used for the item in your hand (`CombatService`).
2. Upload `textures/item_icons.png` as an image (Studio → Asset Manager → Import) and put its `rbxassetid://` in `Config.ItemIconSheet`. Used for every item icon (`client/UI/ItemIcon.luau`). If the Asset Manager's Import menu won't open, run `scripts/icon_sheet_fbx.py` (see its header) and Import 3D the resulting `export/IconSheet.fbx`: the importer uploads the sheet as the plane's texture, and the MeshPart's `TextureID` is the image id (then delete the plane).

To add an item: write a build function, add it to `ITEMS` (and a `Model` in `game/src/shared/Items.luau`), and re-run with the new item's name after `--` (e.g. `... --python art/scripts/items3d.py -- Hoe`). That also writes `export/Items_new.fbx` with just those items: Import 3D only that, move its MeshParts into `ReplicatedStorage.ItemModels` (same settings as the others) and Save to File over `ItemModels.rbxm`, so existing meshes keep their uploads. Then re-upload the sheet: adding items shifts the icon cells, so the sheet, `ItemArt.luau` and `Config.ItemIconSheet` must change together.

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
