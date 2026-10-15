# Art (Blender)

Every model is built by a Python script in `scripts/`, so it can be rebuilt or tweaked by changing numbers.

| Folder | What |
|---|---|
| `scripts/` | Blender Python that builds each asset (`common.py` = shared helpers) |
| `blend/` | Saved `.blend` files you can open and edit in Blender |
| `export/` | `.fbx` files to import into Roblox Studio |
| `renders/` | Preview images |

## Rebuild an asset
```
"%LOCALAPPDATA%\Programs\blender-5.2.2-windows-x64\blender.exe" --background --factory-startup --python art/scripts/starter_island.py
```

## Import into Roblox Studio
1. **Home** (or **Model**) tab → **Import 3D** → pick the file in `export/`.
2. In the importer, set **Scale Unit** to **Stud** (1 Blender unit = 1 stud).
3. Insert. Each part (grass, dirt, rocks, tree) comes in as its own MeshPart inside one Model.
4. If colors don't carry over, set each MeshPart's **Color** in Properties.

## Assets
| Asset | Script | Status |
|---|---|---|
| Starter island | `scripts/starter_island.py` | Greybox (placeholder style) |
