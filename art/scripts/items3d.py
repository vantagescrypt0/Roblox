"""Low-poly 3D item models (tools incl. hoes, tool parts, crops, seed pouches, ores, loot, buckets) and their
UI icons, an icon for the Anvil (its look in the game is built in code), and a few pictures for the HUD
menu (bag, trophy, letter) at the end of the icon sheet.

Tools are modelled standing up along +Z (handle at the bottom), then tilted 45 degrees
so that, seen from the front, the handle is bottom-left and the head top-right. Every
item uses the shared palette (lowpoly.py), so in Roblox each one is a single MeshPart
with one texture. Tiers differ in material: Wooden (light wood, leather lashing), Stone
(rough chipped stone), Iron (steel, metal collar) and Crystal (cyan crystal, gold fittings).

Outputs:
  art/export/Items.fbx           one object per item, named by item id
  art/blend/Items.blend
  art/textures/item_icons.png    1024x1024 icon sheet: 8x8 cells of 128 px (upload to Roblox);
                                 past 64 icons also item_icons_2.png and on
  art/renders/Items.png          the same sheet(s) on a dark background, for previewing
  game/src/shared/ItemArt.luau   generated: where the hand holds each model, icon cell per item

Run:
  blender --background --factory-startup --python art/scripts/items3d.py
  blender --background --factory-startup --python art/scripts/items3d.py -- Hoe
    (also writes art/export/Items_new.fbx with only the items named like "Hoe")
"""

import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
from lowpoly import Builder, export_fbx  # noqa: E402

REPO_DIR = os.path.dirname(common.ART_DIR)
CELL = 128  # icon size in the sheet
RENDER = CELL * 2  # icons are rendered at 2x and scaled down for smooth edges
COLUMNS = 8
SHEET = CELL * COLUMNS  # Roblox images are at most 1024 px, so more icons go on more sheets
PER_SHEET = COLUMNS * COLUMNS
# Tilts a tool modelled along +Z so its head points to the top-right (towards +X, +Z)
TILT = Matrix.Rotation(math.radians(45), 3, "Y")
OUTLINE = (0.11, 0.09, 0.12)  # dark "sticker" outline drawn around every icon

TIERS = {
    "Wooden": {"head": "plank", "dark": "wood_dark", "accent": "wood_dark", "binding": "leather", "rough": 0.0},
    "Stone": {"head": "stone", "dark": "stone_dark", "accent": "stone_dark", "binding": "leather", "rough": 0.028},
    "Iron": {"head": "iron", "dark": "iron_dark", "accent": "metal_dark", "binding": "metal_dark", "rough": 0.0},
    "Crystal": {"head": "crystal", "dark": "crystal_dark", "accent": "gold", "binding": "gold", "rough": 0.0},
    # The deep cave's gem tiers (the palette is full, so they borrow its purples and blues)
    "Amethyst": {"head": "rune", "dark": "rune_dark", "accent": "steel", "binding": "steel", "rough": 0.0},
    "Sapphire": {"head": "blue", "dark": "crystal_dark", "accent": "gold", "binding": "steel", "rough": 0.0},
    "Ruby": {"head": "red", "dark": "red_dark", "accent": "gold", "binding": "gold_dark", "rough": 0.0},
    "Starsteel": {"head": "crystal_light", "dark": "stone_blue", "accent": "glow", "binding": "gold", "rough": 0.0},
}
KINDS = ["Pickaxe", "Axe", "Shovel", "Hoe", "Sword"]


# Shape helpers --------------------------------------------------------------------


def new_verts(b, build):
    """Runs build() and returns the vertices it added (for roughening stone)."""
    before = set(b.bm.verts)
    build()
    return [v for v in b.bm.verts if v not in before]


def slab(b, outline, thickness, color):
    """Extrudes a 2D outline (x, z points) into a solid centred on y = 0. thickness(x, z)
    is the width along Y at each point, so blades can thin out towards the edge."""
    bm = b.bm
    front = [bm.verts.new((x, -thickness(x, z) / 2, z)) for x, z in outline]
    back = [bm.verts.new((x, thickness(x, z) / 2, z)) for x, z in outline]
    faces = [bm.faces.new(front), bm.faces.new(list(reversed(back)))]
    for i in range(len(outline)):
        j = (i + 1) % len(outline)
        faces.append(bm.faces.new((front[i], front[j], back[j], back[i])))
    b._paint_faces(faces, color)
    bmesh.ops.recalc_face_normals(bm, faces=faces)
    bmesh.ops.triangulate(bm, faces=faces[:2])  # the outlines can be concave


def handle(b, length):
    """Tapered wooden handle from z = 0 to z = length, leather grip, dark end cap."""
    b.cylinder(0.135, length, location=(0, 0, length / 2), color="wood_alt", segments=8, radius2=0.115)
    b.cylinder(0.162, 0.62, location=(0, 0, 0.46), color="leather", segments=8)
    b.cylinder(0.17, 0.07, location=(0, 0, 0.8), color="leather_dark", segments=8)
    b.cylinder(0.17, 0.16, location=(0, 0, 0.08), color="wood_darker", segments=8)


def pickaxe(b, tier):
    length = 2.7
    handle(b, length)
    top = length + 0.05
    span, droop = 1.45, 0.38

    def z_at(x):
        return top + 0.14 - droop * (x / span) ** 2

    def build_head():
        for side in (1, -1):
            rings = []
            for x in (0.0, 0.28, 0.56, 0.84, 1.1, 1.3):
                t = x / span
                height, depth = 0.44 - 0.28 * t, 0.37 - 0.2 * t
                tangent = Vector((side, 0, -2 * droop * x / span**2)).normalized()
                normal = Vector((-tangent.z, 0, tangent.x))
                p = Vector((side * x, 0, z_at(x)))
                y = Vector((0, depth / 2, 0))
                n = normal * (height / 2)
                rings.append([p + n + y, p + n - y, p - n - y, p - n + y])
            tip = (side * 1.52, 0, z_at(1.52) - 0.08)
            b.loft(rings, [tier["head"]] * (len(rings) - 1), top_color=tier["head"], tip=tip, tip_color=tier["head"])

    head = new_verts(b, build_head)
    b._jitter(head, tier["rough"])
    b.cylinder(0.2, 0.52, location=(0, 0, top - 0.02), color=tier["binding"], segments=8)


def axe(b, tier):
    length = 2.7
    handle(b, length)
    zc = length - 0.36
    outline = [
        (0.18, 0.43),
        (-0.36, 0.41),
        (-0.84, 0.86),
        (-1.2, 0.66),
        (-1.34, 0.1),
        (-1.22, -0.52),
        (-0.8, -0.88),
        (-0.38, -0.43),
        (0.18, -0.41),
    ]
    outline = [(x, zc + z) for x, z in outline]

    def thickness(x, _z):
        return 0.045 + 0.19 * max(0.0, min(1.0, (x + 1.32) / 1.5))

    head = new_verts(b, lambda: slab(b, outline, thickness, tier["head"]))
    b._jitter(head, tier["rough"])
    b.box((0.32, 0.27, 0.54), location=(0.34, 0, zc), color=tier["dark"], bevel=0.035)
    b.cylinder(0.19, 0.34, location=(0, 0, zc + 0.6), color=tier["binding"], segments=8)


def shovel(b, tier):
    length = 2.55
    handle(b, length)
    base = length + 0.02
    outline = [(-0.43, 0), (0.43, 0), (0.52, 0.5), (0.45, 0.96), (0.25, 1.28), (0.0, 1.4), (-0.25, 1.28), (-0.45, 0.96), (-0.52, 0.5)]
    outline = [(x, base + z) for x, z in outline]
    blade = new_verts(b, lambda: slab(b, outline, lambda x, z: 0.09, tier["head"]))
    b._jitter(blade, tier["rough"] * 0.6)
    b.cylinder(0.2, 0.5, location=(0, 0, base - 0.12), color=tier["dark"], segments=8, radius2=0.25)


def hoe(b, tier):
    """A flat arm off the top of the handle with a blade hanging from its far end."""
    length = 2.7
    handle(b, length)
    top = length - 0.08
    outline = [
        (0.2, 0.16),
        (-0.5, 0.18),
        (-0.92, 0.1),
        (-1.12, -0.12),
        (-1.06, -0.66),
        (-0.82, -0.7),
        (-0.74, -0.2),
        (-0.5, -0.12),
        (0.2, -0.14),
    ]
    outline = [(x, top + z) for x, z in outline]

    def thickness(x, _z):
        # Sturdy by the handle, thin at the cutting blade
        return 0.07 + 0.12 * max(0.0, min(1.0, (x + 0.7) / 0.9))

    head = new_verts(b, lambda: slab(b, outline, thickness, tier["head"]))
    b._jitter(head, tier["rough"])
    b.box((0.3, 0.26, 0.42), location=(0.2, 0, top), color=tier["dark"], bevel=0.03)
    b.cylinder(0.19, 0.3, location=(0, 0, top - 0.42), color=tier["binding"], segments=8)


def sword(b, tier):
    b.cylinder(0.12, 0.8, location=(0, 0, 0.5), color="leather", segments=8)
    b.blob(0.2, location=(0, 0, 0.06), color=tier["accent"], jitter=0.0, subdivisions=1)
    b.box((1.25, 0.26, 0.22), location=(0, 0, 0.98), color=tier["accent"], bevel=0.04)
    rings = []
    for z, width, depth in ((1.06, 0.5, 0.13), (2.4, 0.46, 0.12), (3.3, 0.38, 0.1)):
        rings.append([(width / 2, 0, z), (0, depth / 2, z), (-width / 2, 0, z), (0, -depth / 2, z)])
    blade = new_verts(
        b,
        lambda: b.loft(rings, [tier["head"]] * 2, top_color=tier["head"], tip=(0, 0, 3.85), tip_color=tier["head"]),
    )
    b._jitter(blade, tier["rough"] * 0.5)

def sticks(b):
    b.cylinder(0.08, 2.5, location=(-0.07, 0, 1.25), rotation=(0, 6, 0), color="wood_alt", segments=6)
    b.cylinder(0.075, 2.3, location=(0.09, 0.03, 1.2), rotation=(0, -5, 0), color="wood_dark", segments=6)
    b.cylinder(0.04, 0.4, location=(-0.2, 0, 1.6), rotation=(0, -40, 0), color="wood_alt", segments=5)


def twine(b):
    """A ball of straw-gold twine wound round and round, its loose end trailing off."""
    b.blob(0.44, location=(0, 0, 0.44), color="wheat", jitter=0.02, subdivisions=2)
    for rx, rz in ((90, 0), (90, 60), (90, 120), (35, 0), (-35, 90)):
        b.cylinder(0.47, 0.05, location=(0, 0, 0.44), rotation=(rx, 0, rz), color="wheat_dark", segments=16)
    b.cylinder(0.035, 0.55, location=(0.45, -0.2, 0.1), rotation=(0, 75, 20), color="wheat_dark", segments=5)


def rope(b, main="sign", other="wood_alt"):
    """A coil of hemp rope standing up: two loops wound round, tied at the bottom, the two
    ends hanging down."""
    for radius, y, color in ((0.5, 0.08, main), (0.43, -0.08, other)):
        for v in new_verts(b, lambda radius=radius, color=color: arc(b, 0, 0.66, radius, 0, 360, 0.15, color, steps=18)):
            v.co.y += y
    b.cylinder(0.17, 0.24, location=(0, 0, 0.16), rotation=(0, 90, 0), color="wood_dark", segments=8)
    b.cylinder(0.06, 0.4, location=(-0.09, -0.04, -0.12), rotation=(0, 14, 0), color=main, segments=6)
    b.cylinder(0.06, 0.34, location=(0.09, 0.04, -0.1), rotation=(0, -18, 0), color=other, segments=6)


def iron_plate(b, rim="iron_dark", face="iron", rivet="metal_dark"):
    """A square plate of hammered metal standing on its edge: a brighter face set in a
    darker rim, a rivet in each corner."""
    b.box((1.05, 0.14, 0.95), location=(0, 0, 0.475), color=rim, bevel=0.03)
    b.box((0.84, 0.03, 0.74), location=(0, -0.07, 0.475), color=face)
    for x in (-0.41, 0.41):
        for z in (0.12, 0.83):
            b.cylinder(0.055, 0.05, location=(x, -0.08, z), rotation=(90, 0, 0), color=rivet, segments=6)


def sturdy_handle(b):
    """A tool handle bound with iron: the tapered wooden handle and grip, an iron collar at
    the top for the head, two iron bands and an iron cap at the end."""
    handle(b, 2.2)
    b.cylinder(0.175, 0.26, location=(0, 0, 2.08), color="iron_dark", segments=8)
    for z in (1.25, 1.55):
        b.cylinder(0.155, 0.07, location=(0, 0, z), color="metal_dark", segments=8)
    b.cylinder(0.185, 0.12, location=(0, 0, 0.06), color="iron_dark", segments=8)


def anvil(b):
    """An anvil on an oak stump: a dark iron body on a waist, a pointed horn, a bright
    working face and a hammer resting on it."""
    b.cylinder(0.62, 0.7, location=(0, 0, 0.35), color="bark", segments=10)
    b.cylinder(0.56, 0.03, location=(0, 0, 0.71), color="wood", segments=10)
    b.box((1.1, 0.75, 0.2), location=(0, 0, 0.8), color="metal_dark", bevel=0.02)
    b.box((0.55, 0.4, 0.3), location=(0, 0, 1.05), color="metal_dark")
    b.box((1.15, 0.6, 0.3), location=(0, 0, 1.35), color="metal_dark", bevel=0.02)
    b.box((1.13, 0.58, 0.03), location=(0, 0, 1.505), color="metal")
    b.cone(0.22, 0.55, location=(0.85, 0, 1.38), rotation=(0, 90, 0), color="metal_dark", segments=6)
    b.cylinder(0.04, 0.7, location=(-0.15, -0.05, 1.56), rotation=(90, 0, 30), color="wood_alt", segments=6)
    b.box((0.3, 0.16, 0.16), location=(0.025, -0.353, 1.6), rotation=(0, 0, 30), color="steel")


def shield(b):
    """The shield's icon, matching its look in the game (Util/ShieldModel.luau): planks in an
    iron rim with an orange band and a boss."""
    b.box((1.3, 0.12, 1.6), location=(0, 0, 0.8), color="wood")
    for x in (-0.39, -0.13, 0.13, 0.39):
        b.box((0.03, 0.14, 1.55), location=(x, 0, 0.8), color="wood_dark")
    b.box((1.3, 0.15, 0.23), location=(0, 0, 1.08), color="carrot")
    for z in (0.0, 1.6):
        b.box((1.44, 0.18, 0.1), location=(0, 0, z), color="steel")
    for x in (-0.67, 0.67):
        b.box((0.1, 0.18, 1.7), location=(x, 0, 0.8), color="steel")
    b.blob(0.2, location=(0, -0.1, 0.8), color="metal", squash=(1.0, 0.7, 1.0), jitter=0.0)


def wheat(b):
    for i, angle in enumerate((-14, -7, 0, 7, 14)):
        a = math.radians(angle)
        b.cylinder(0.03, 1.6, location=(math.sin(a) * 0.8, 0, math.cos(a) * 0.8), rotation=(0, angle, 0), color="stalk", segments=5)
        top = Vector((math.sin(a) * 1.65, 0.0, math.cos(a) * 1.65))
        b.blob(0.11, location=top, color="wheat" if i % 2 == 0 else "wheat_dark", squash=(0.75, 0.75, 2.0), jitter=0.05, rotation=(0, angle, 0))
    b.cylinder(0.11, 0.12, location=(0, 0, 0.5), color="wood_dark", segments=8)


def seed_pouch(b, accent):
    b.blob(0.46, location=(0, 0, 0.46), color="sign", squash=(1.0, 0.9, 0.88), jitter=0.06, subdivisions=2)
    b.cylinder(0.17, 0.28, location=(0, 0, 0.9), color="sign", segments=8, radius2=0.13)
    b.cylinder(0.2, 0.09, location=(0, 0, 0.84), color=accent, segments=8)
    b.blob(0.2, location=(0, 0, 1.06), color="cream", squash=(1.0, 1.0, 0.55), jitter=0.1)
    b.box((0.26, 0.06, 0.26), location=(0, -0.42, 0.45), rotation=(0, 45, 0), color=accent)


def sapling(b, leaf="leaf", light="leaf_light"):
    """A young tree: a thin trunk with a side twig, leafy tufts, a clump of soil at its roots."""
    b.cylinder(0.24, 0.14, location=(0, 0, 0.07), color="soil", segments=8, radius2=0.18)
    b.cylinder(0.075, 1.05, location=(0, 0, 0.6), color="wood_alt", segments=6, radius2=0.055)
    b.cylinder(0.04, 0.45, location=(0.14, 0, 0.82), rotation=(0, 35, 0), color="wood_alt", segments=5)
    for x, y, z, radius, color in (
        (0.0, 0.0, 1.22, 0.34, leaf),
        (0.32, 0.04, 1.02, 0.25, light),
        (-0.27, -0.06, 0.98, 0.23, leaf),
        (0.06, 0.18, 1.46, 0.21, light),
    ):
        b.blob(radius, location=(x, y, z), color=color, jitter=0.12, subdivisions=1)


def loot_crate(b):
    """A wooden crate with iron bands and a gold lock."""
    b.box((1.1, 1.0, 0.82), location=(0, 0, 0.41), color="wood", bevel=0.03)
    b.box((1.16, 1.06, 0.14), location=(0, 0, 0.6), color="wood_dark", bevel=0.02)
    for x in (-0.34, 0.34):
        b.box((0.13, 1.06, 0.86), location=(x, 0, 0.41), color="iron_dark", bevel=0.01)
    b.box((0.24, 0.1, 0.28), location=(0, -0.53, 0.52), color="gold", bevel=0.02)


def carrot(b):
    b.cone(0.3, 1.45, location=(0, 0, 0.78), rotation=(180, 0, 0), color="carrot", segments=7)
    for angle, color in ((-25, "leaf_light"), (0, "leaf"), (22, "leaf_light")):
        b.box((0.07, 0.04, 0.62), location=(math.sin(math.radians(angle)) * 0.22, 0, 1.75), rotation=(0, angle, 0), color=color)


def potato(b):
    b.blob(0.55, location=(0, 0, 0.45), color="potato", squash=(1.2, 0.9, 0.8), jitter=0.16, subdivisions=2)


def lump(b, main, second):
    b.blob(0.5, location=(0, 0, 0.45), color=main, jitter=0.26, subdivisions=1)
    b.blob(0.3, location=(0.32, -0.12, 0.62), color=second, jitter=0.25, subdivisions=1)


def ingot(b, color="iron"):
    verts = b.box((1.25, 0.55, 0.36), location=(0, 0, 0.18), color=color)
    for v in verts:
        if v.co.z > 0.18:  # narrower top: an ingot shape
            v.co.x *= 0.8
            v.co.y *= 0.72
    b._bevel(verts, 0.025)


def crystal(b, main="crystal", dark="crystal_dark", light="crystal_light"):
    b.cone(0.36, 0.75, location=(0, 0, 0.9), color=main, segments=6)
    b.cone(0.36, 0.38, location=(0, 0, 0.33), rotation=(180, 0, 0), color=dark, segments=6)
    b.cone(0.16, 0.45, location=(0.34, 0.05, 0.62), rotation=(0, 30, 0), color=light, segments=6)


def gem_cluster(b, main, dark, light):
    """A raw gem as it comes out of the rock: three crystals growing out of a stone base"""
    b.blob(0.36, location=(0, 0, 0.18), color="stone_dark", squash=(1.3, 1.0, 0.55), jitter=0.12)
    for x, tilt, height, color in ((-0.18, -18, 0.95, main), (0.12, 10, 1.15, light), (0.34, 34, 0.7, dark)):
        b.cylinder(0.15, height, location=(x, 0, 0.3 + height / 2 * 0.9), rotation=(0, tilt, 0), color=color, segments=6)
        top = Vector((x + math.sin(math.radians(tilt)) * height * 0.5, 0, 0.3 + math.cos(math.radians(tilt)) * height * 0.95))
        b.cone(0.15, 0.24, location=top, rotation=(0, tilt, 0), color=color, segments=6)


def cut_gem(b, main, light):
    """A refined gem, cut like a brilliant: a flat table on top, a short crown, a deep
    pointed pavilion"""
    b.cylinder(0.4, 0.06, location=(0, 0, 0.62), color=light, segments=8)
    b.cylinder(0.46, 0.16, location=(0, 0, 0.54), color=main, segments=8, radius2=0.4)
    b.cone(0.46, 0.5, location=(0, 0, 0.21), rotation=(180, 0, 0), color=main, segments=8)


def sliver(b, main, light):
    """A thin splinter of ore, with a chip broken off beside it"""
    b.cone(0.11, 0.95, location=(0, 0, 0.47), rotation=(0, 12, 0), color=main, segments=5)
    b.cone(0.11, 0.3, location=(0.035, 0, 0.05), rotation=(180, 12, 0), color=main, segments=5)
    b.cone(0.07, 0.42, location=(0.22, -0.04, 0.2), rotation=(0, -30, 0), color=light, segments=5)


def wood_handle(b, wood, band):
    """A handle of a better wood bound with metal: the wood shows its own colour, the grip
    is leather, the bands and collar are the plate's metal"""
    length = 2.2
    b.cylinder(0.135, length, location=(0, 0, length / 2), color=wood, segments=8, radius2=0.115)
    b.cylinder(0.162, 0.62, location=(0, 0, 0.46), color="leather", segments=8)
    b.cylinder(0.175, 0.26, location=(0, 0, 2.08), color=band, segments=8)
    for z in (1.25, 1.55):
        b.cylinder(0.155, 0.07, location=(0, 0, z), color=band, segments=8)
    b.cylinder(0.185, 0.12, location=(0, 0, 0.06), color=band, segments=8)


def starstone(b):
    """A lump of near-black rock with glinting star specks"""
    b.blob(0.5, location=(0, 0, 0.45), color="coal", jitter=0.24, subdivisions=1)
    for x, y, z in ((-0.22, -0.42, 0.55), (0.18, -0.4, 0.32), (0.05, -0.44, 0.75), (0.36, -0.25, 0.6)):
        b.blob(0.065, location=(x, y, z), color="glow", jitter=0.0)


def gem_bench(b):
    """A plank workbench with a stone grinding wheel at one end and gems on top"""
    b.box((1.6, 1.0, 0.16), location=(0, 0, 0.82), color="plank", bevel=0.02)
    for x in (-0.68, 0.68):
        for y in (-0.38, 0.38):
            b.box((0.16, 0.16, 0.8), location=(x, y, 0.4), color="wood_dark")
    b.cylinder(0.36, 0.14, location=(0.45, 0, 1.28), rotation=(0, 90, 0), color="stone", segments=12)
    b.cylinder(0.05, 0.36, location=(0.45, 0, 1.28), rotation=(0, 90, 0), color="metal_dark", segments=6)
    for x in (0.3, 0.6):
        b.box((0.05, 0.07, 0.42), location=(x, 0, 1.08), color="wood_dark")
    b.blob(0.11, location=(-0.45, -0.15, 0.97), color="rune", jitter=0.04)
    b.blob(0.1, location=(-0.15, 0.2, 0.96), color="blue", jitter=0.04)
    cut = new_verts(b, lambda: cut_gem(b, "rune", "flower_purple"))
    for v in cut:
        v.co = v.co * 0.35 + Vector((-0.55, 0.25, 0.9))


def scrap(b):
    b.cylinder(0.42, 0.16, location=(0, 0, 0.55), rotation=(90, 0, 0), color="metal", segments=10)
    for i in range(8):
        a = math.radians(i * 45)
        b.box((0.16, 0.14, 0.16), location=(math.cos(a) * 0.48, 0, 0.55 + math.sin(a) * 0.48), rotation=(0, -i * 45, 0), color="metal")
    b.cylinder(0.12, 0.2, location=(0, 0, 0.55), rotation=(90, 0, 0), color="metal_dark", segments=6)


def pumpkin(b):
    """Four round lobes round a squat middle, a curly stem and a leaf on top."""
    b.blob(0.5, location=(0, 0, 0.42), color="pumpkin", squash=(1.15, 1.15, 0.8), jitter=0.04, subdivisions=2)
    for i in range(4):
        a = math.radians(i * 90 + 45)
        b.blob(0.3, location=(math.cos(a) * 0.32, math.sin(a) * 0.32, 0.4), color="pumpkin_dark" if i % 2 else "pumpkin", squash=(1.0, 1.0, 1.25), jitter=0.04)
    b.cylinder(0.07, 0.3, location=(0.02, 0, 0.86), rotation=(0, 12, 0), color="wood_dark", segments=6)
    b.box((0.3, 0.05, 0.14), location=(0.16, 0, 0.84), rotation=(0, -25, 0), color="leaf")


def melon(b):
    """A striped melon lying on its side."""
    b.blob(0.52, location=(0, 0, 0.44), color="melon", squash=(1.3, 1.0, 0.9), jitter=0.03, subdivisions=2)
    for y in (-0.3, 0.0, 0.3):
        b.blob(0.1, location=(0, y, 0.86), color="melon_light", squash=(5.5, 0.6, 0.5), jitter=0.02)
    b.cylinder(0.04, 0.16, location=(0.66, 0, 0.5), rotation=(0, 90, 0), color="stalk", segments=5)


def sugarcane(b):
    """Three jointed stalks of cane, with a leaf or two at the top."""
    for x, y, height in ((-0.2, 0.05, 1.5), (0.14, -0.1, 1.75), (0.1, 0.18, 1.25)):
        b.cylinder(0.075, height, location=(x, y, height / 2), color="stalk", segments=6)
        for z in (height * 0.3, height * 0.6, height * 0.9):
            b.cylinder(0.092, 0.05, location=(x, y, z), color="grass_dark", segments=6)
        b.cone(0.08, 0.55, location=(x + 0.14, y, height + 0.1), rotation=(0, 40, 0), color="leaf_light", segments=4)
    b.cone(0.08, 0.6, location=(-0.32, 0.05, 1.5), rotation=(0, -40, 0), color="leaf", segments=4)


def strawberry(b):
    """A plump strawberry, point down, seeds on its skin and a leafy cap."""
    b.blob(0.42, location=(0, 0, 0.42), color="red", squash=(1.0, 1.0, 1.1), jitter=0.03, subdivisions=2)
    b.cone(0.3, 0.34, location=(0, 0, 0.1), rotation=(180, 0, 0), color="red", segments=8)
    for i in range(9):
        a = math.radians(i * 40)
        z = 0.24 + (i % 3) * 0.17
        b.box((0.05, 0.05, 0.07), location=(math.cos(a) * 0.37, math.sin(a) * 0.37, z), color="flower_yellow")
    for i in range(5):
        a = math.radians(i * 72)
        b.cone(0.1, 0.34, location=(math.cos(a) * 0.15, math.sin(a) * 0.15, 0.86), rotation=(math.sin(a) * -60, math.cos(a) * 60, 0), color="leaf", segments=4)


def dragonfruit(b):
    """A hot pink oval fruit with green-tipped scales."""
    b.blob(0.42, location=(0, 0, 0.52), color="flower_pink", squash=(1.0, 1.0, 1.3), jitter=0.03, subdivisions=2)
    for ring, z, reach in ((0, 0.3, 0.38), (1, 0.55, 0.42), (0, 0.8, 0.32)):
        for i in range(6):
            a = math.radians(i * 60 + ring * 30)
            b.cone(0.09, 0.3, location=(math.cos(a) * reach, math.sin(a) * reach, z), rotation=(math.sin(a) * -55, math.cos(a) * 55, 0), color="leaf_light", segments=4)
    b.cone(0.1, 0.3, location=(0, 0, 1.05), color="leaf", segments=4)


def starfruit(b):
    """A golden five-pointed star of a fruit, standing on one point."""
    b.blob(0.22, location=(0, 0, 0.62), color="glow", squash=(1.0, 0.8, 1.0), jitter=0.0, subdivisions=2)
    for i in range(5):
        a = math.radians(i * 72)
        b.cone(0.18, 0.5, location=(math.sin(a) * 0.34, 0, 0.62 + math.cos(a) * 0.34), rotation=(0, i * 72, 0), color="flower_yellow" if i % 2 else "glow", segments=4)


def glowberry(b):
    for x, z in ((-0.2, 0.35), (0.2, 0.38), (0.0, 0.68)):
        b.blob(0.22, location=(x, 0, z), color="berry", jitter=0.05, subdivisions=2)
    b.box((0.36, 0.05, 0.16), location=(0.05, 0, 0.98), rotation=(0, -20, 0), color="leaf")
    b.cylinder(0.025, 0.3, location=(0, 0, 0.88), color="stalk", segments=5)


def bucket(b, fill=None, band="iron_dark"):
    """A tapered iron pail with two bands, a rim and a wire handle arched over the top.
    fill: None (empty: the dark inside shows), "water" or "lava". Bottomless buckets have
    gold bands."""
    b.cylinder(0.36, 0.86, location=(0, 0, 0.47), color="iron", segments=10, radius2=0.48)
    for z, r in ((0.2, 0.4), (0.68, 0.46)):
        b.cylinder(r + 0.025, 0.08, location=(0, 0, z), color=band, segments=10)
    b.cylinder(0.51, 0.06, location=(0, 0, 0.9), color=band, segments=10)
    top = {None: "metal_dark", "water": "blue", "lava": "carrot"}[fill]
    b.cylinder(0.44, 0.03, location=(0, 0, 0.92), color=top, segments=10)
    if fill == "water":
        b.cylinder(0.12, 0.03, location=(-0.16, 0.1, 0.935), color="berry", segments=6)
    elif fill == "lava":
        b.blob(0.1, location=(0.12, -0.08, 0.93), color="glow", squash=(1, 1, 0.4), jitter=0.05)
        b.blob(0.07, location=(-0.18, 0.12, 0.93), color="glow", squash=(1, 1, 0.4), jitter=0.05)
    # Lugs on the rim, and the handle arched between them
    for x in (-0.5, 0.5):
        b.box((0.08, 0.12, 0.14), location=(x, 0, 0.88), color=band)
    steps = 8
    points = [(math.cos(math.pi * i / steps) * 0.5, 0.9 + math.sin(math.pi * i / steps) * 0.42) for i in range(steps + 1)]
    for (x1, z1), (x2, z2) in zip(points, points[1:]):
        dx, dz = x2 - x1, z2 - z1
        b.box(
            (math.hypot(dx, dz) + 0.02, 0.05, 0.05),
            location=((x1 + x2) / 2, 0, (z1 + z2) / 2),
            rotation=(0, math.degrees(math.atan2(-dz, dx)), 0),
            color="metal",
        )


# Pictures for the HUD menu (not items) ----------------------------------------------


def arc(b, cx, cz, radius, start, end, thickness, color, steps=10):
    """A bent bar along a circle in the x-z plane (angles in degrees), e.g. a handle."""
    angles = [math.radians(start + (end - start) * i / steps) for i in range(steps + 1)]
    points = [(cx + math.cos(a) * radius, cz + math.sin(a) * radius) for a in angles]
    for (x1, z1), (x2, z2) in zip(points, points[1:]):
        dx, dz = x2 - x1, z2 - z1
        b.box(
            (math.hypot(dx, dz) + thickness * 0.4, thickness, thickness),
            location=((x1 + x2) / 2, 0, (z1 + z2) / 2),
            rotation=(0, math.degrees(math.atan2(-dz, dx)), 0),
            color=color,
        )


def front_slab(b, outline, thickness, y, color):
    """A flat 2D shape (x, z points) standing in front of a model, its middle at depth y."""
    verts = new_verts(b, lambda: slab(b, outline, lambda x, z: thickness, color))
    for v in verts:
        v.co.y += y


def ui_bag(b):
    """A tan backpack: rounded body, a darker flap over the top with a gold buckle, a front
    pocket and a carry handle."""
    b.box((0.9, 0.52, 1.0), location=(0, 0, 0.55), color="wood_alt", bevel=0.14)
    b.box((0.62, 0.16, 0.4), location=(0, -0.3, 0.34), color="leather", bevel=0.05)
    b.box((0.16, 0.05, 0.1), location=(0, -0.39, 0.46), color="gold")
    b.box((0.96, 0.58, 0.2), location=(0, 0, 1.03), color="leather", bevel=0.08)
    b.box((0.96, 0.08, 0.34), location=(0, -0.27, 0.88), color="leather", bevel=0.03)
    b.box((0.18, 0.06, 0.18), location=(0, -0.32, 0.77), color="gold")
    b.box((0.08, 0.07, 0.08), location=(0, -0.34, 0.77), color="leather_dark")
    arc(b, 0, 1.12, 0.2, 0, 180, 0.08, "leather_dark")


def ui_trophy(b):
    """A gold cup with two ear handles and a white star, on a gold stem and a dark plinth."""
    b.box((0.86, 0.86, 0.24), location=(0, 0, 0.12), color="wood_dark", bevel=0.03)
    b.box((0.7, 0.7, 0.07), location=(0, 0, 0.275), color="gold")
    b.cylinder(0.09, 0.26, location=(0, 0, 0.42), color="gold", segments=8)
    b.blob(0.13, location=(0, 0, 0.47), color="gold", squash=(1, 1, 0.6), jitter=0.02)
    b.cylinder(0.2, 0.62, location=(0, 0, 0.86), color="gold", segments=12, radius2=0.46)
    b.cylinder(0.48, 0.07, location=(0, 0, 1.17), color="gold", segments=12)
    b.cylinder(0.42, 0.02, location=(0, 0, 1.205), color="gold_dark", segments=12)
    arc(b, 0.42, 0.93, 0.2, -150, 100, 0.08, "gold")
    arc(b, -0.42, 0.93, 0.2, 80, 330, 0.08, "gold")
    star = []
    for i in range(10):
        a = math.radians(90 + i * 36)
        r = 0.13 if i % 2 == 0 else 0.055
        star.append((math.cos(a) * r, 0.9 + math.sin(a) * r))
    front_slab(b, star, 0.04, -0.36, "flower_white")


def ui_mail(b):
    """A white envelope standing up, its tan flap folded down and a red wax seal."""
    b.box((1.15, 0.08, 0.76), location=(0, 0, 0.38), color="flower_white", bevel=0.02)
    front_slab(b, [(-0.56, 0.75), (0.56, 0.75), (0, 0.3)], 0.03, -0.05, "sign")
    b.cylinder(0.11, 0.05, location=(0, -0.075, 0.33), rotation=(90, 0, 0), color="red", segments=10)


# name -> (build function, tilted like a tool?)
ITEMS = {}
for tier_name, tier in TIERS.items():
    for kind, build in zip(KINDS, (pickaxe, axe, shovel, hoe, sword)):
        ITEMS[f"{tier_name}{kind}"] = (lambda b, build=build, tier=tier: build(b, tier), True)
ITEMS.update(
    {
        "Sticks": (sticks, True),
        "Wheat": (wheat, False),
        "WheatSeeds": (lambda b: seed_pouch(b, "wheat_dark"), False),
        "CarrotSeeds": (lambda b: seed_pouch(b, "carrot"), False),
        "PotatoSeeds": (lambda b: seed_pouch(b, "potato"), False),
        "GlowberrySeeds": (lambda b: seed_pouch(b, "berry"), False),
        "Sapling": (sapling, False),
        "Carrot": (carrot, False),
        "Potato": (potato, False),
        "Glowberry": (glowberry, False),
        "Coal": (lambda b: lump(b, "coal", "coal_light"), False),
        "RawIron": (lambda b: lump(b, "raw_iron", "raw_iron_dark"), False),
        "IronIngot": (ingot, False),
        "Crystal": (crystal, False),
        "Scrap": (scrap, False),
        "RawGold": (lambda b: lump(b, "gold", "gold_dark"), False),
        "GoldIngot": (lambda b: ingot(b, "gold"), False),
        "PumpkinSeeds": (lambda b: seed_pouch(b, "pumpkin"), False),
        "MelonSeeds": (lambda b: seed_pouch(b, "melon"), False),
        "Pumpkin": (pumpkin, False),
        "Melon": (melon, False),
        "Bucket": (bucket, False),
        "WaterBucket": (lambda b: bucket(b, "water"), False),
        "LavaBucket": (lambda b: bucket(b, "lava"), False),
        "BottomlessWaterBucket": (lambda b: bucket(b, "water", "gold"), False),
        "BottomlessLavaBucket": (lambda b: bucket(b, "lava", "gold"), False),
        "Twine": (twine, False),
        "Rope": (rope, False),
        "IronPlate": (iron_plate, False),
        "SturdyHandle": (sturdy_handle, True),
        # The deep cave (2026-10-31)
        "RawSilver": (lambda b: lump(b, "steel", "iron_dark"), False),
        "SilverIngot": (lambda b: ingot(b, "steel"), False),
        "SilverPlate": (lambda b: iron_plate(b, "metal", "steel", "iron_dark"), False),
        "Amethyst": (lambda b: gem_cluster(b, "rune", "rune_dark", "flower_purple"), False),
        "Sapphire": (lambda b: gem_cluster(b, "blue", "crystal_dark", "berry"), False),
        "Ruby": (lambda b: gem_cluster(b, "red", "red_dark", "flower_pink"), False),
        "Starstone": (starstone, False),
        "RefinedAmethyst": (lambda b: cut_gem(b, "rune", "flower_purple"), False),
        "RefinedSapphire": (lambda b: cut_gem(b, "blue", "berry"), False),
        "BirchHandle": (lambda b: wood_handle(b, "cream", "iron_dark"), True),
        "SpruceHandle": (lambda b: wood_handle(b, "wood_darker", "steel"), True),
        "CoalSliver": (lambda b: sliver(b, "coal", "coal_light"), False),
        "IronSliver": (lambda b: sliver(b, "raw_iron", "raw_iron_dark"), False),
        "GoldSliver": (lambda b: sliver(b, "gold", "gold_dark"), False),
        "SilverSliver": (lambda b: sliver(b, "steel", "iron_dark"), False),
        "AmethystSliver": (lambda b: sliver(b, "rune", "flower_purple"), False),
        "SapphireSliver": (lambda b: sliver(b, "blue", "berry"), False),
        # The Farming World's second ring (2026-11-02)
        "Sugarcane": (sugarcane, False),
        "SugarcaneSeeds": (lambda b: seed_pouch(b, "stalk"), False),
        "Strawberry": (strawberry, False),
        "StrawberrySeeds": (lambda b: seed_pouch(b, "red"), False),
        "Dragonfruit": (dragonfruit, False),
        "DragonfruitSeeds": (lambda b: seed_pouch(b, "flower_pink"), False),
        "Starfruit": (starfruit, False),
        "StarfruitSeeds": (lambda b: seed_pouch(b, "flower_yellow"), False),
        "SugarcaneSliver": (lambda b: sliver(b, "stalk", "grass_light"), False),
        # The top two tiers' parts
        "GoldPlate": (lambda b: iron_plate(b, "gold_dark", "gold", "cream"), False),
        "RefinedRuby": (lambda b: cut_gem(b, "red", "flower_pink"), False),
        "CherryHandle": (lambda b: wood_handle(b, "red_dark", "gold"), True),
        "CaneRope": (lambda b: rope(b, "stalk", "sign"), False),
        "StarsteelIngot": (lambda b: ingot(b, "crystal_light"), False),
        "StarsteelPlate": (lambda b: iron_plate(b, "stone_blue", "crystal_light", "glow"), False),
        "RedwoodHandle": (lambda b: wood_handle(b, "dirt_light", "crystal_light"), True),
        # Tree saplings and the Loot Crate (2026-11-02)
        "BirchSapling": (lambda b: sapling(b, "leaf_light", "sprout"), False),
        "SpruceSapling": (lambda b: sapling(b, "leaf_dark", "leaf"), False),
        "CherrySapling": (lambda b: sapling(b, "flower_pink", "flower_white"), False),
        "MapleSapling": (lambda b: sapling(b, "red", "gold"), False),
        "RedwoodSapling": (lambda b: sapling(b, "leaf_dark", "red_dark"), False),
        "MangroveSapling": (lambda b: sapling(b, "leaf", "leaf_dark"), False),
        "StarwoodSapling": (lambda b: sapling(b, "crystal", "crystal_light"), False),
        "LootCrate": (loot_crate, False),
        # Slivers of wood, from chopping (2026-11-02)
        "BirchSliver": (lambda b: sliver(b, "cream", "wood_alt"), False),
        "SpruceSliver": (lambda b: sliver(b, "wood_darker", "wood_dark"), False),
        "CherrySliver": (lambda b: sliver(b, "flower_pink", "red_dark"), False),
        "MapleSliver": (lambda b: sliver(b, "red", "gold"), False),
        "RedwoodSliver": (lambda b: sliver(b, "red_dark", "wood_darker"), False),
    }
)
# Block items show their block, rendered from art/blend/Blocks.blend
BLOCK_ICONS = {
    "Grass": "Grass",
    "Dirt": "Dirt",
    "Wood": "Wood",
    "Planks": "Planks",
    "Stone": "Stone",
    "Furnace": "Furnace",
    "BirchWood": "BirchWood",
    "SpruceWood": "SpruceWood",
    "CherryWood": "CherryWood",
    "MapleWood": "MapleWood",
    "Redwood": "Redwood",
    "MangroveWood": "MangroveWood",
    "Starwood": "Starwood",
}
# Items whose look in the world is built in code (game/src/server/Util/AnvilModel.luau):
# only an icon cell, no model is exported. name -> (build, azimuth, elevation)
ICON_ONLY = {
    "Anvil": (anvil, -30, 22),
    "GemBench": (gem_bench, -30, 22),
    "Shield": (shield, -24, 12),
}
# Pictures for the HUD menu buttons. Not items: no model is exported, only an icon cell,
# after every item and block so their cells never move. name -> (build, azimuth, elevation)
UI_ICONS = {
    "IconBag": (ui_bag, -24, 18),
    "IconTrophy": (ui_trophy, -20, 14),
    "IconMail": (ui_mail, -14, 10),
}

# Where the hand holds an item, in the item's own modelling space (before tilting)
TOOL_GRIP = Vector((0, 0, 0.5))
UPRIGHT_GRIP = Vector((0, 0, 0.12))


def to_roblox(v):
    """Blender (x, y, z) -> Roblox (-x, z, y), the axis swap the FBX export makes."""
    return (-v.x, v.z, v.y)


def build_items():
    objects, grips = [], {}
    for name, (build, tilted) in ITEMS.items():
        b = Builder(seed=sum(map(ord, name)))
        build(b)
        if tilted:
            bmesh.ops.rotate(b.bm, verts=list(b.bm.verts), cent=(0, 0, 0), matrix=TILT)
        obj = b.finish(name)
        coords = [v.co for v in obj.data.vertices]
        low = Vector((min(c.x for c in coords), min(c.y for c in coords), min(c.z for c in coords)))
        high = Vector((max(c.x for c in coords), max(c.y for c in coords), max(c.z for c in coords)))
        center = (low + high) / 2
        grip = (TILT @ TOOL_GRIP) if tilted else Vector((center.x, center.y, low.z)) + UPRIGHT_GRIP
        up = (TILT @ Vector((0, 0, 1))) if tilted else Vector((0, 0, 1))
        grips[name] = (to_roblox(grip - center), to_roblox(up))
        objects.append(obj)
    return objects, grips


# Icons ----------------------------------------------------------------------------


def setup_lights(scene):
    world = bpy.data.worlds.new("IconWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.42, 0.44, 0.5, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.65
    scene.world = world
    for name, toward_light, energy in (
        ("Key", (-0.55, -0.75, 0.85), 3.2),
        ("Fill", (0.85, -0.35, 0.25), 0.9),
        ("Rim", (0.25, 0.95, 0.55), 1.6),
    ):
        data = bpy.data.lights.new(name, "SUN")
        data.energy = energy
        data.angle = math.radians(8)
        light = bpy.data.objects.new(name, data)
        light.rotation_euler = Vector(toward_light).to_track_quat("Z", "Y").to_euler()
        scene.collection.objects.link(light)


def load_blocks():
    path = os.path.join(common.BLEND_DIR, "Blocks.blend")
    wanted = [f"Block_{block}" for block in BLOCK_ICONS.values()]
    with bpy.data.libraries.load(path, link=False) as (source, target):
        target.objects = [name for name in source.objects if name in wanted]
    blocks = {}
    for obj in target.objects:
        bpy.context.scene.collection.objects.link(obj)
        obj.location = (0, 0, 0)
        blocks[obj.name.removeprefix("Block_")] = obj
    return blocks


def world_bounds(obj):
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    return corners, sum(corners, Vector()) / 8


def render_icon(scene, camera, obj, azimuth, elevation, path):
    for other in scene.objects:
        if other.type == "MESH":
            other.hide_render = other is not obj
    corners, center = world_bounds(obj)
    az, el = math.radians(azimuth), math.radians(elevation)
    direction = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)))
    camera.location = center + direction * 20
    camera.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    rot = camera.matrix_world.to_3x3()
    right, up = rot @ Vector((1, 0, 0)), rot @ Vector((0, 1, 0))
    xs = [(c - center).dot(right) for c in corners]
    ys = [(c - center).dot(up) for c in corners]
    camera.data.ortho_scale = max(max(xs) - min(xs), max(ys) - min(ys)) * 1.14
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def read_image(path):
    image = bpy.data.images.load(path, check_existing=False)
    w, h = image.size
    pixels = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(pixels)
    bpy.data.images.remove(image)
    return pixels.reshape(h, w, 4)[::-1]  # top row first


def over(fg, bg):
    """Straight-alpha 'fg over bg'."""
    fa, ba = fg[..., 3:4], bg[..., 3:4]
    out_a = fa + ba * (1 - fa)
    rgb = np.where(out_a > 0, (fg[..., :3] * fa + bg[..., :3] * ba * (1 - fa)) / np.maximum(out_a, 1e-6), 0)
    return np.concatenate([rgb, out_a], axis=-1)


def with_outline(icon, radius):
    """Adds a dark outline around the icon's shape (a 'sticker' edge)."""
    alpha = icon[..., 3]
    grown = np.zeros_like(alpha)
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if dx * dx + dy * dy <= radius * radius:
                grown = np.maximum(grown, np.roll(np.roll(alpha, dy, axis=0), dx, axis=1))
    outline = np.zeros_like(icon)
    outline[..., :3] = OUTLINE
    outline[..., 3] = np.clip(grown * 1.2, 0, 1)
    return over(icon, outline)


def downscale(icon):
    """Halves the size, averaging colours weighted by alpha so edges don't darken."""
    pre = icon.copy()
    pre[..., :3] *= pre[..., 3:4]
    pre = pre.reshape(CELL, 2, CELL, 2, 4).mean(axis=(1, 3))
    alpha = pre[..., 3:4]
    pre[..., :3] = np.where(alpha > 0, pre[..., :3] / np.maximum(alpha, 1e-6), 0)
    return pre


def write_image(array, path, name):
    h, w = array.shape[:2]
    image = bpy.data.images.new(name, w, h, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(array[::-1]).ravel())
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)


def build_icon_models(icons):
    objects = {}
    for name, (build, _, _) in icons.items():
        b = Builder(seed=sum(map(ord, name)))
        build(b)
        objects[name] = b.finish(name)
    return objects


def render_icons(items, icon_only, ui_icons):
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.view_settings.view_transform = "Standard"
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = RENDER
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    setup_lights(scene)
    camera_data = bpy.data.cameras.new("IconCamera")
    camera_data.type = "ORTHO"
    camera = bpy.data.objects.new("IconCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera

    blocks = load_blocks()
    # (name, object, (azimuth, elevation)); blocks show three faces
    entries = [(name, obj, (-22, 14) if ITEMS[name][1] else (-24, 20)) for name, obj in items.items()]
    entries += [(item, blocks[block], (-38, 28)) for item, block in BLOCK_ICONS.items() if block in blocks]
    entries += [(name, obj, ICON_ONLY[name][1:]) for name, obj in icon_only.items()]
    entries += [(name, obj, UI_ICONS[name][1:]) for name, obj in ui_icons.items()]

    temp = os.path.join(common.RENDER_DIR, "_icon.png")
    sheets = [np.zeros((SHEET, SHEET, 4), dtype=np.float32) for _ in range(-(-len(entries) // PER_SHEET))]
    cells = {}
    for index, (name, obj, (azimuth, elevation)) in enumerate(entries):
        render_icon(scene, camera, obj, azimuth, elevation, temp)
        icon = with_outline(read_image(temp), radius=4)
        small = downscale(icon)
        page, here = divmod(index, PER_SHEET)
        row, col = divmod(here, COLUMNS)
        sheets[page][row * CELL : (row + 1) * CELL, col * CELL : (col + 1) * CELL] = small
        cells[name] = index
    os.remove(temp)

    for page, sheet in enumerate(sheets):
        suffix = "" if page == 0 else f"_{page + 1}"
        write_image(sheet, os.path.join(common.ART_DIR, "textures", f"item_icons{suffix}.png"), f"ItemIcons{suffix}")
        backdrop = np.zeros_like(sheet)
        backdrop[...] = (0.17, 0.18, 0.23, 1.0)
        write_image(over(sheet, backdrop), os.path.join(common.RENDER_DIR, f"Items{suffix}.png"), f"ItemsPreview{suffix}")
    print(f"icon sheets: {len(sheets)} (upload each, in order, into Config.ItemIconSheets)")
    return cells


# Generated Luau -------------------------------------------------------------------


def vec(v):
    return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"


def write_luau(grips, cells):
    lines = [
        "--!strict",
        "-- GENERATED by art/scripts/items3d.py - don't edit by hand; change the script and re-run it.",
        "-- Models: where the hand holds each item model (Grip, studs from the model's centre) and",
        "--   which way its business end points (Up), in the model's imported orientation.",
        "-- Icons: each item's cell in the icon sheets (art/textures/item_icons.png, then",
        "--   item_icons_2.png...), row by row, numbered on from one sheet to the next.",
        "",
        "return {",
        f"\tCellSize = {CELL},",
        f"\tColumns = {COLUMNS},",
        f"\tPerSheet = {PER_SHEET},",
        "\tModels = {",
    ]
    for name, (grip, up) in grips.items():
        lines.append(f"\t\t{name} = {{ Grip = {vec(grip)}, Up = {vec(up)} }},")
    lines += ["\t},", "\tIcons = {"]
    for name, index in cells.items():
        lines.append(f"\t\t{name} = {index},")
    lines += ["\t},", "}", ""]
    path = os.path.join(REPO_DIR, "game", "src", "shared", "ItemArt.luau")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    return path


def main():
    common.reset_scene()
    objects, grips = build_items()
    common.save_blend("Items")
    export_fbx(os.path.join(common.EXPORT_DIR, "Items.fbx"), objects)
    # Words after "--" also export just the items whose names contain one of them, so new
    # items can be imported without re-uploading every mesh: ... items3d.py -- Hoe
    words = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    if words:
        subset = [obj for obj in objects if any(word in obj.name for word in words)]
        print("subset:", export_fbx(os.path.join(common.EXPORT_DIR, "Items_new.fbx"), subset), [o.name for o in subset])
    cells = render_icons({obj.name: obj for obj in objects}, build_icon_models(ICON_ONLY), build_icon_models(UI_ICONS))
    print("luau:", write_luau(grips, cells))
    print(f"items: {len(objects)} models, {len(cells)} icons")


main()
