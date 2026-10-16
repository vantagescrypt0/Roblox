"""Minecraft-style item models: 16x16 pixel-art sprites (tools, sticks, crops) extruded
into chunky voxel meshes, one pixel = one little cube, like Minecraft's held items.

All sprites live in one atlas (art/textures/items.png). Each pixel cube's UVs point at
its pixel, so a model is one mesh with one texture. In-game the same models are used
for the item held in your hand and for the 3D icons in the UI.

Output: art/export/Tools.fbx, art/blend/Tools.blend, art/renders/Tools.png
"""

import os
import sys

import bmesh
import bpy
from mathutils import Matrix

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

PIXEL = 0.2  # studs per sprite pixel (a 16 px tool is 3.2 studs long)
TILE = 16
SCALE = 8
GRID = 5
ATLAS = TILE * SCALE * GRID  # 640 px

# Sprites: '.' = empty. Handle bottom-left, head top-right, like Minecraft.
SWORD = [
    "..............oo",
    ".............olo",
    "............olmo",
    "...........olmo.",
    "..........olmo..",
    ".........olmo...",
    "........olmo....",
    ".......olmo.....",
    "..oo..olmo......",
    "..odoolmo.......",
    "...oddmo........",
    "...ohdo.........",
    "..ohoodo........",
    "ohho..oo........",
    "oho.............",
    "oo..............",
]
PICKAXE = [
    "................",
    "....oooooo......",
    "...olllmmmoo....",
    "....oooooommo...",
    "........ohomdo..",
    ".......ohho.mdo.",
    "......ohho..omdo",
    ".....ohho....omo",
    "....ohho.....omo",
    "...ohho.......o.",
    "..ohho..........",
    ".ohho...........",
    "ohho............",
    "oho.............",
    "oo..............",
    "................",
]
AXE = [
    "......oooo...oo.",
    ".....ollllooohho",
    "....ollmmmmdhho.",
    "...olmmmmmdhho..",
    "...olmmmmdhho...",
    "...olmmmdhho....",
    "....olmdhho.....",
    ".....olhho......",
    ".....ohho.......",
    "....ohho........",
    "...ohho.........",
    "..ohho..........",
    ".ohho...........",
    "ohho............",
    "oho.............",
    "oo..............",
]
SHOVEL = [
    "...........ooo..",
    "..........olmmo.",
    ".........ollmmdo",
    ".........olmmmdo",
    "..........ommdo.",
    ".........ohoo...",
    "........ohho....",
    ".......ohho.....",
    "......ohho......",
    ".....ohho.......",
    "....ohho........",
    "...ohho.........",
    "..ohho..........",
    ".ohho...........",
    "ohho............",
    "oo..............",
]
STICK = [
    "................",
    "................",
    "............oo..",
    "...........oho..",
    "..........ohho..",
    ".........ohho...",
    "........ohho....",
    ".......ohho.....",
    "......ohho......",
    ".....ohho.......",
    "....ohho........",
    "...ohho.........",
    "...oho..........",
    "...oo...........",
    "................",
    "................",
]
WHEAT = [
    "................",
    "....y...y...y...",
    "...yYy.yYy.yYy..",
    "...yYy.yYy.yYy..",
    "...yYy.yYy.yYy..",
    "....Y...Y...Y...",
    "....g...g...g...",
    ".....g..g..g....",
    "......g.g.g.....",
    ".......ggg......",
    "......wwwww.....",
    ".......ggg......",
    "......g.g.g.....",
    ".....g..g..g....",
    "....g...g...g...",
    "................",
]
SEEDS = [
    "................",
    "................",
    "................",
    "......G.........",
    "..........G.....",
    "....G...........",
    "........G...G...",
    "...G...g........",
    ".........G......",
    "......G.....G...",
    "..G.............",
    "........G.......",
    ".....G.....G....",
    "................",
    "................",
    "................",
]
CARROT = [
    "................",
    "...........gG...",
    "..........gGgG..",
    ".........gGG.Gg.",
    ".......occgG....",
    "......occCo.....",
    ".....occCco.....",
    "....occCco......",
    "...occCco.......",
    "...ocCco........",
    "..occco.........",
    "..oCco..........",
    ".occo...........",
    ".oco............",
    ".oo.............",
    "................",
]
POTATO = [
    "................",
    "................",
    "................",
    ".....oooooo.....",
    "....opppPppo....",
    "...oppPppppPo...",
    "..opppppPpppo...",
    "..oPppppppppPo..",
    "..opppPppppppo..",
    "..oppppppPpppo..",
    "...opPppppppo...",
    "....oppppPpo....",
    ".....oooooo.....",
    "................",
    "................",
    "................",
]

HANDLE = {"h": (104, 78, 46), "g": (73, 54, 30), "o": (36, 26, 16)}
TIERS = {
    "Wooden": {"m": (162, 130, 78), "l": (196, 162, 102), "d": (118, 92, 55)},
    "Stone": {"m": (125, 125, 125), "l": (165, 165, 165), "d": (88, 88, 88)},
    "Crystal": {"m": (80, 196, 238), "l": (176, 240, 255), "d": (36, 132, 186)},
}
CROPS = {
    "y": (232, 198, 92),
    "Y": (196, 160, 58),
    "g": (96, 150, 52),
    "G": (124, 186, 70),
    "w": (176, 132, 72),
    "c": (237, 124, 41),
    "C": (204, 94, 26),
    "p": (190, 142, 88),
    "P": (150, 106, 62),
    "o": (70, 48, 24),
}

# name -> (sprite, colour map)
ITEMS = {}
for tier, colors in TIERS.items():
    palette = {**HANDLE, **colors, "d": colors["d"]}
    ITEMS[f"{tier}Sword"] = (SWORD, {**palette, "d": HANDLE["g"] if tier == "Wooden" else colors["d"]})
    ITEMS[f"{tier}Pickaxe"] = (PICKAXE, palette)
    ITEMS[f"{tier}Axe"] = (AXE, palette)
    ITEMS[f"{tier}Shovel"] = (SHOVEL, palette)
ITEMS["Sticks"] = (STICK, HANDLE)
ITEMS["Wheat"] = (WHEAT, CROPS)
ITEMS["WheatSeeds"] = (SEEDS, CROPS)
ITEMS["Carrot"] = (CARROT, CROPS)
ITEMS["Potato"] = (POTATO, CROPS)


def build_atlas():
    image = bpy.data.images.new("Items", ATLAS, ATLAS, alpha=True)
    pixels = [0.0] * (ATLAS * ATLAS * 4)
    for index, (name, (sprite, colors)) in enumerate(ITEMS.items()):
        col, row = index % GRID, index // GRID
        for y, line in enumerate(sprite):
            for x, ch in enumerate(line):
                if ch == ".":
                    continue
                r, g, b = (c / 255 for c in colors[ch])
                for sy in range(SCALE):
                    for sx in range(SCALE):
                        px = (col * TILE + x) * SCALE + sx
                        py = ((GRID - 1 - row) * TILE + (TILE - 1 - y)) * SCALE + sy
                        i = (py * ATLAS + px) * 4
                        pixels[i : i + 4] = [r, g, b, 1.0]
    image.pixels = pixels
    path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "textures", "items.png")
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()

    mat = bpy.data.materials.new("Items")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def make_item(index, name, sprite, mat):
    col, row = index % GRID, index // GRID
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    for y, line in enumerate(sprite):
        for x, ch in enumerate(line):
            if ch == ".":
                continue
            # Sprite lies in the XZ plane; thickness along Y
            center = ((x - 7.5) * PIXEL, 0, (7.5 - y) * PIXEL)
            verts = bmesh.ops.create_cube(bm, size=PIXEL, matrix=Matrix.Translation(center))["verts"]
            u = (col * TILE + x + 0.5) / (TILE * GRID)
            v = 1 - (row * TILE + y + 0.5) / (TILE * GRID)
            for face in {f for vert in verts for f in vert.link_faces}:
                for loop in face.loops:
                    loop[uv].uv = (u, v)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def main():
    common.reset_scene()
    mat = build_atlas()
    objects = [make_item(i, name, sprite, mat) for i, (name, (sprite, _)) in enumerate(ITEMS.items())]

    for i, obj in enumerate(objects):
        obj.location = ((i % 6) * 3.6 - 9, 0, -(i // 6) * 3.6 + 4)
    common.render_preview("Tools", target=(0, 0, 0.5), distance=24, height=2, angle_deg=0)
    for obj in objects:
        obj.location = (0, 0, 0)

    common.save_blend("Tools")
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in objects)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(common.EXPORT_DIR, "Tools.fbx"),
        use_selection=True,
        object_types={"MESH"},
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        path_mode="COPY",
        embed_textures=True,
    )
    print("fbx: done")


main()
