"""Low-poly 3D item models (tools incl. hoes, crops, seed pouches, ores, loot) and their UI icons.

Tools are modelled standing up along +Z (handle at the bottom), then tilted 45 degrees
so that, seen from the front, the handle is bottom-left and the head top-right. Every
item uses the shared palette (lowpoly.py), so in Roblox each one is a single MeshPart
with one texture. Tiers differ in material: Wooden (light wood, leather lashing), Stone
(rough chipped stone), Iron (steel, metal collar) and Crystal (cyan crystal, gold fittings).

Outputs:
  art/export/Items.fbx           one object per item, named by item id
  art/blend/Items.blend
  art/textures/item_icons.png    1024x1024 icon sheet: 8x8 cells of 128 px (upload to Roblox)
  art/renders/Items.png          the same sheet on a dark background, for previewing
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
SHEET = CELL * COLUMNS
# Tilts a tool modelled along +Z so its head points to the top-right (towards +X, +Z)
TILT = Matrix.Rotation(math.radians(45), 3, "Y")
OUTLINE = (0.11, 0.09, 0.12)  # dark "sticker" outline drawn around every icon

TIERS = {
    "Wooden": {"head": "plank", "dark": "wood_dark", "accent": "wood_dark", "binding": "leather", "rough": 0.0},
    "Stone": {"head": "stone", "dark": "stone_dark", "accent": "stone_dark", "binding": "leather", "rough": 0.028},
    "Iron": {"head": "iron", "dark": "iron_dark", "accent": "metal_dark", "binding": "metal_dark", "rough": 0.0},
    "Crystal": {"head": "crystal", "dark": "crystal_dark", "accent": "gold", "binding": "gold", "rough": 0.0},
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


def sapling(b):
    """A young tree: a thin trunk with a side twig, leafy tufts, a clump of soil at its roots."""
    b.cylinder(0.24, 0.14, location=(0, 0, 0.07), color="soil", segments=8, radius2=0.18)
    b.cylinder(0.075, 1.05, location=(0, 0, 0.6), color="wood_alt", segments=6, radius2=0.055)
    b.cylinder(0.04, 0.45, location=(0.14, 0, 0.82), rotation=(0, 35, 0), color="wood_alt", segments=5)
    for x, y, z, radius, color in (
        (0.0, 0.0, 1.22, 0.34, "leaf"),
        (0.32, 0.04, 1.02, 0.25, "leaf_light"),
        (-0.27, -0.06, 0.98, 0.23, "leaf"),
        (0.06, 0.18, 1.46, 0.21, "leaf_light"),
    ):
        b.blob(radius, location=(x, y, z), color=color, jitter=0.12, subdivisions=1)


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


def crystal(b):
    b.cone(0.36, 0.75, location=(0, 0, 0.9), color="crystal", segments=6)
    b.cone(0.36, 0.38, location=(0, 0, 0.33), rotation=(180, 0, 0), color="crystal_dark", segments=6)
    b.cone(0.16, 0.45, location=(0.34, 0.05, 0.62), rotation=(0, 30, 0), color="crystal_light", segments=6)


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


def glowberry(b):
    for x, z in ((-0.2, 0.35), (0.2, 0.38), (0.0, 0.68)):
        b.blob(0.22, location=(x, 0, z), color="berry", jitter=0.05, subdivisions=2)
    b.box((0.36, 0.05, 0.16), location=(0.05, 0, 0.98), rotation=(0, -20, 0), color="leaf")
    b.cylinder(0.025, 0.3, location=(0, 0, 0.88), color="stalk", segments=5)


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


def render_icons(items):
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
    entries = [(name, obj, ITEMS[name][1]) for name, obj in items.items()]
    entries += [(item, blocks[block], None) for item, block in BLOCK_ICONS.items() if block in blocks]

    temp = os.path.join(common.RENDER_DIR, "_icon.png")
    sheet = np.zeros((SHEET, SHEET, 4), dtype=np.float32)
    cells = {}
    for index, (name, obj, tilted) in enumerate(entries):
        if tilted is None:
            render_icon(scene, camera, obj, -38, 28, temp)  # blocks: three faces showing
        elif tilted:
            render_icon(scene, camera, obj, -22, 14, temp)
        else:
            render_icon(scene, camera, obj, -24, 20, temp)
        icon = with_outline(read_image(temp), radius=4)
        small = downscale(icon)
        row, col = divmod(index, COLUMNS)
        sheet[row * CELL : (row + 1) * CELL, col * CELL : (col + 1) * CELL] = small
        cells[name] = index
    os.remove(temp)

    write_image(sheet, os.path.join(common.ART_DIR, "textures", "item_icons.png"), "ItemIcons")
    backdrop = np.zeros_like(sheet)
    backdrop[...] = (0.17, 0.18, 0.23, 1.0)
    write_image(over(sheet, backdrop), os.path.join(common.RENDER_DIR, "Items.png"), "ItemsPreview")
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
        "-- Icons: each item's cell in the icon sheet (art/textures/item_icons.png), row by row.",
        "",
        "return {",
        f"\tCellSize = {CELL},",
        f"\tColumns = {COLUMNS},",
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
    cells = render_icons({obj.name: obj for obj in objects})
    print("luau:", write_luau(grips, cells))
    print(f"items: {len(objects)} models, {len(cells)} icons")


main()
