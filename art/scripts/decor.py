"""The decorations the Builder sells, which Town and the worlds use too.

    blender --background --factory-startup --python art/scripts/decor.py

Each model is built around its own origin, in the same sizes the old part-built pieces had:
a standing thing has its origin on the floor under its middle, and a thing on a wall has it
on the wall's face, with +Y into the wall and its front at -Y (-Z in Roblox).

An object named Decor_<Name> is a model's main mesh. Decor_<Name>__<Child> goes with it:
    Glow   lit panes, made Neon in Roblox
    Tint   cloth and petals, with no texture, so the game can colour them
    Fronds a palm's leaves, which nothing bumps into

Output:
    art/export/Decor.fbx, art/blend/Decor.blend, art/renders/Decor.png
    art/export/Decor.json             each mesh's middle and size in studs, Roblox axes
    game/src/shared/DecorArt.luau     generated: the same, for the game

items3d.py imports the ICONS here, so the icon sheets show these too.
"""

import json
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
from lowpoly import Builder, export_fbx  # noqa: E402

REPO_DIR = os.path.dirname(common.ART_DIR)
DARK = "wood_darker"
IRON = "metal_dark"


# Lights ---------------------------------------------------------------------------


def lamp_post(b, g, _t):
    h = 8
    b.box((1.6, 1.6, 0.8), (0, 0, 0.4), color="stone_dark", bevel=0.06)
    b.box((0.8, 0.8, h), (0, 0, 0.8 + h / 2), color=DARK)
    z = 0.8 + h + 1.25
    b.box((2, 2, 0.3), (0, 0, z - 1.1), color=DARK)
    for x, y in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        b.box((0.3, 0.3, 2), (x * 0.85, y * 0.85, z), color=DARK)
    b.box((2.4, 2.4, 0.3), (0, 0, z + 1.1), color="wood_dark", bevel=0.04)
    b.box((1.2, 1.2, 0.4), (0, 0, z + 1.45), color=DARK, bevel=0.04)
    g.box((1.4, 1.4, 1.8), (0, 0, z), color="glow")


def lantern_at(b, g, z):
    b.box((1.2, 1.2, 0.25), (0, 0, z + 0.125), color=IRON, bevel=0.03)
    for x, y in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        b.box((0.14, 0.14, 1), (x * 0.46, y * 0.46, z + 0.75), color=IRON)
    b.box((1.3, 1.3, 0.3), (0, 0, z + 1.4), color=IRON, bevel=0.04)
    b.box((0.5, 0.5, 0.3), (0, 0, z + 1.7), color=IRON, bevel=0.03)
    g.box((0.85, 0.85, 1), (0, 0, z + 0.75), color="glow")


def lantern(b, g, _t):
    lantern_at(b, g, 0)


def lantern_chain(b, _g, _t):
    # What a hanging lantern hangs from, in the lantern's own space
    b.box((0.15, 0.15, 1.2), (0, 0, 2.45), color=IRON)


def wall_lantern(b, g, _t):
    b.box((0.7, 0.12, 0.9), (0, -0.06, 0.4), color=IRON)
    b.box((0.25, 1.4, 0.25), (0, -0.7, 0.4), color=IRON)
    b.box((0.16, 0.16, 0.7), (0, -1.3, 0.1), color=IRON)
    # lantern_at builds around x = y = 0, so it goes on after a shift out from the wall
    before_b, before_g = set(b.bm.verts), set(g.bm.verts)
    lantern_at(b, g, -1.85)
    for builder, before in ((b, before_b), (g, before_g)):
        for vert in builder.bm.verts:
            if vert not in before:
                vert.co.y -= 1.3


def stone_lantern(b, g, _t):
    b.box((1.8, 1.8, 0.5), (0, 0, 0.25), color="stone_light", bevel=0.05)
    b.box((0.8, 0.8, 2), (0, 0, 1.5), color="stone")
    b.box((1.6, 1.6, 0.35), (0, 0, 2.65), color="stone_light", bevel=0.04)
    for x, y in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        b.box((0.16, 0.16, 1), (x * 0.5, y * 0.5, 3.3), color="stone_dark")
    g.box((1, 1, 1), (0, 0, 3.3), color="glow")
    b.box((2.4, 2.4, 0.4), (0, 0, 4), color="stone_light", bevel=0.06)
    b.box((0.8, 0.8, 0.5), (0, 0, 4.4), color="stone", bevel=0.05)


def jack_face(g, y):
    for x in (-0.65, 0.65):
        g.box((0.6, 0.1, 0.55), (x, y, 0.45), color="glow")
    g.box((0.3, 0.1, 0.3), (0, y, 0), color="glow")
    g.box((1.7, 0.1, 0.45), (0, y, -0.6), color="glow")


def jack_face_only(_b, g, _t):
    # Origin on the middle of a pumpkin block's face, for a jack-o'-lantern that's scenery
    jack_face(g, -0.06)


def jack_o_lantern(b, g, _t):
    b.box((2.9, 2.9, 2.9), (0, 0, 1.45), color="pumpkin", bevel=0.12)
    for x in (-1.0, 0.0, 1.0):
        b.box((0.28, 2.96, 2.96), (x, 0, 1.45), color="pumpkin_dark")
    b.box((0.6, 0.6, 0.45), (0, 0, 3.05), color="leaf_dark")
    # Its face, on the middle of the front
    before = set(g.bm.verts)
    jack_face(g, -1.5)
    for vert in g.bm.verts:
        if vert not in before:
            vert.co.z += 1.45


# Seats, fences, signs, cloth ------------------------------------------------------


def bench(b, _g, _t):
    width = 3
    for y, color in ((-0.43, "wood_dark"), (0, DARK), (0.43, "wood_dark")):
        b.box((width, 0.42, 0.35), (0, y, 1.3), color=color, bevel=0.03)
    for z, color in ((1.82, DARK), (2.32, "wood_dark")):
        b.box((width, 0.3, 0.44), (0, 0.55, z), color=color, bevel=0.03)
    for x in (-width / 2 + 0.3, width / 2 - 0.3):
        b.box((0.3, 1.1, 1.15), (x, 0, 0.58), color=IRON)
        b.box((0.3, 0.26, 1.6), (x, 0.55, 1.75), color=IRON)


def fence(b, _g, _t):
    b.box((0.6, 0.6, 2.6), (0, 0, 1.3), color="plank", bevel=0.04)
    b.box((0.72, 0.72, 0.14), (0, 0, 2.62), color="wood", bevel=0.02)


def fence_rail(b, _g, _t):
    # Two rails from the post in the middle of a block out to the edge of it, at -Y
    for z in (1, 2):
        b.box((0.3, 1.5, 0.35), (0, -0.75, z), color="plank")


def rough_planks(b, width, height, centre_z, rows=3):
    row = height / rows
    for i in range(rows):
        z = centre_z - height / 2 + row * (i + 0.5)
        color = ("wood_dark", "wood_alt", "wood")[i % 3]
        b.box((width, 0.3, row - 0.05), (0, 0, z), color=color, bevel=0.02)
    for x in (-1, 1):
        for z in (centre_z - height / 2 + 0.3, centre_z + height / 2 - 0.3):
            b.box((0.14, 0.06, 0.14), (x * (width / 2 - 0.3), -0.17, z), color="coal")


def sign_post(b, _g, _t):
    b.box((0.6, 0.6, 4.2), (0, 0.45, 2.1), color="wood_darker")
    rough_planks(b, 4.4, 2.6, 4.2)


def wall_sign(b, _g, _t):
    before = set(b.bm.verts)
    rough_planks(b, 2.9, 2, 0, rows=2)
    for vert in b.bm.verts:
        if vert not in before:
            vert.co.y -= 0.16


def sign_plank(_b, _g, t):
    # A plain plank the game sizes and colours: the boards on Town's lettered signs
    t.box((1, 1, 1), (0, 0, 0), color="wood", bevel=0.04)


def banner(b, _g, t, cloth="red"):
    h = 5
    b.box((2.6, 0.25, 0.25), (0, 0, 0), color=IRON, bevel=0.03)
    b.box((2.2, 0.17, 0.3), (0, 0, -0.5), color="gold")
    t.box((2.2, 0.15, h), (0, 0, -h / 2 - 0.1), color=cloth)
    # A pointed tail
    t.box((1.5, 0.14, 1.5), (0, 0, -h - 0.1), rotation=(0, 45, 0), color=cloth)


def stripe(builder, x, width, color):
    tilt = math.radians(28)
    builder.box(
        (width, 2.4, 0.15),
        (x, -1.2 * math.cos(tilt), -1.2 * math.sin(tilt)),
        rotation=(28, 0, 0),
        color=color,
    )
    # A little drop along the front
    builder.box((width, 0.1, 0.42), (x, -2.4 * math.cos(tilt) - 0.02, -2.4 * math.sin(tilt) - 0.2), color=color)


def awning_stripe(_b, _g, t):
    # One stripe the game colours and repeats along a wall
    stripe(t, 0, 0.9, "red")


def awning(b, _g, _t):
    for i, color in enumerate(("red", "cream", "red")):
        stripe(b, (i - 1) * 0.96, 0.96, color)


# Plants ---------------------------------------------------------------------------


def flower(b, _g, t, petals="red"):
    b.box((0.18, 0.18, 0.9), (0, 0, 0.45), color="stalk")
    b.box((0.42, 0.1, 0.16), (0.22, 0, 0.32), rotation=(0, -25, 0), color="leaf_light")
    b.box((0.36, 0.1, 0.14), (-0.2, 0, 0.5), rotation=(0, 25, 0), color="leaf_light")
    t.box((0.56, 0.24, 0.26), (0, 0, 1.06), color=petals, bevel=0.03)
    t.box((0.24, 0.56, 0.26), (0, 0, 1.06), color=petals, bevel=0.03)
    b.box((0.22, 0.22, 0.2), (0, 0, 1.2), color="flower_yellow")


def tall_grass(b, _g, _t):
    blades = (
        (-0.5, -0.2, 1.1, 8, -6, "grass"),
        (0.45, 0.25, 1.4, -6, 8, "grass_light"),
        (0.05, -0.5, 0.9, 10, 4, "grass_light"),
        (-0.15, 0.4, 1.5, -9, -5, "grass"),
        (0.55, -0.4, 1.0, 7, 10, "grass"),
    )
    for x, y, h, rx, ry, color in blades:
        b.box((0.16, 0.08, h), (x, y, h / 2), rotation=(rx, ry, 0), color=color)


def mushroom_red(b, _g, _t):
    b.cylinder(0.15, 0.6, (0, 0, 0.3), color="flower_white", segments=8)
    b.cylinder(0.45, 0.32, (0, 0, 0.72), color="red", segments=10, radius2=0.26)
    b.box((0.16, 0.16, 0.04), (0.18, 0.1, 0.89), color="flower_white")
    b.box((0.14, 0.14, 0.04), (-0.16, -0.12, 0.89), color="flower_white")
    b.box((0.1, 0.1, 0.04), (0, -0.28, 0.8), rotation=(30, 0, 0), color="flower_white")


def mushroom_brown(b, _g, _t):
    b.cylinder(0.15, 0.6, (0, 0, 0.3), color="flower_white", segments=8)
    b.cylinder(0.45, 0.3, (0, 0, 0.7), color="dirt_light", segments=10, radius2=0.22)


def flower_box(b, _g, _t):
    width = 2.6
    b.box((width, 0.9, 0.7), (0, -0.45, 0.35), color=DARK, bevel=0.03)
    colors = ("flower_pink", "flower_yellow", "flower_white", "flower_pink")
    for i, color in enumerate(colors):
        x = -width / 2 + (i + 0.5) * width / len(colors)
        b.box((0.56, 0.56, 0.35), (x, -0.45, 0.87), color="leaf", bevel=0.02)
        b.box((0.42, 0.42, 0.34), (x, -0.45, 1.2), color=color, bevel=0.03)


def lily_pad(b, _g, _t):
    b.cylinder(0.72, 0.1, (0, 0, 0.05), color="leaf_light", segments=10)
    b.cylinder(0.5, 0.11, (0, 0, 0.055), color="leaf", segments=10)


def lily_bloom(_b, _g, t):
    # The flower some lily pads have, in the world's own colour
    t.box((0.42, 0.2, 0.3), (0.2, 0.1, 0.25), color="flower_pink", bevel=0.03)
    t.box((0.2, 0.42, 0.3), (0.2, 0.1, 0.25), color="flower_pink", bevel=0.03)


def cactus(b, arms):
    height = 6
    b.box((1.4, 1.4, height), (0, 0, height / 2), color="melon", bevel=0.08)
    for x in (-0.4, 0.4):
        b.box((0.12, 1.46, height - 0.3), (x, 0, height / 2), color="leaf")
    for y in (-0.4, 0.4):
        b.box((1.46, 0.12, height - 0.3), (0, y, height / 2), color="leaf")
    for i in range(1, arms + 1):
        side = 1 if i == 1 else -1
        z = height * (0.35 + 0.15 * i)
        b.box((1.4, 0.9, 0.9), (side * 1.1, 0, z), color="melon", bevel=0.05)
        b.box((0.9, 0.9, 1.8), (side * 1.6, 0, z + 1.2), color="melon", bevel=0.06)


def palm(b, _g, t_fronds):
    height, segments = 12, 5
    step = height / segments
    x, z, lean = 0.0, 0.0, 0.0
    for i in range(segments):
        lean += 4 + i
        rad = math.radians(lean)
        mid_y, mid_z = -step / 2 * math.sin(rad), step / 2 * math.cos(rad)
        width = 1.3 - i * 0.06
        b.box(
            (width, width, step),
            (0, x + mid_y, z + mid_z),
            rotation=(lean, 0, 0),
            color="bark" if i % 2 else "wood_dark",
        )
        x += 2 * mid_y
        z += 2 * mid_z
    crown = Vector((0, x, z))
    for i in range(3):
        angle = i * 2.1
        b.blob(
            0.36,
            (crown.x + math.cos(angle) * 0.6, crown.y + math.sin(angle) * 0.6, crown.z - 0.5),
            color="soil",
            jitter=0.05,
        )
    for i in range(7):
        angle = i * math.tau / 7
        # Each frond is three pieces, drooping more toward its tip
        out, down = 0.0, 0.0
        for piece, (length, width, droop) in enumerate(((2.2, 1.4, 12), (2.2, 1.1, 30), (2.0, 0.7, 52))):
            rad = math.radians(droop)
            mid_out = out + length / 2 * math.cos(rad)
            mid_down = down - length / 2 * math.sin(rad)
            t_fronds.box(
                (width, length, 0.15),
                (crown.x + math.sin(angle) * mid_out, crown.y - math.cos(angle) * mid_out, crown.z + mid_down),
                rotation=(droop, 0, math.degrees(angle)),
                color="leaf_light" if piece % 2 else "leaf",
            )
            out += length * math.cos(rad)
            down -= length * math.sin(rad)


# Mine and farm --------------------------------------------------------------------


def minecart(b, _g, _t):
    body = "metal"
    b.box((2, 3, 0.3), (0, 0, 0.9), color=IRON)
    for side in (-1, 1):
        b.box((0.25, 3, 1.4), (side, 0, 1.6), color=body, bevel=0.03)
        b.box((2, 0.25, 1.4), (0, side * 1.5, 1.6), color=body, bevel=0.03)
        b.box((2.3, 0.12, 0.2), (0, side * 1.56, 2.2), color=IRON)
        for y in (-1, 1):
            b.cylinder(0.4, 0.3, (side * 0.9, y, 0.45), rotation=(0, 90, 0), color=IRON, segments=10)
            b.cylinder(0.14, 0.34, (side * 0.9, y, 0.45), rotation=(0, 90, 0), color="metal", segments=6)
    for side in (-1, 1):
        b.box((0.25, 3.1, 0.2), (side, 0, 2.34), color=IRON)


def rails(b, _g, _t):
    # A straight piece as long as a block, running along Y
    for y in (-0.75, 0.75):
        b.box((2.6, 0.5, 0.2), (0, y, 0.1), color=DARK)
    for x in (-0.8, 0.8):
        b.box((0.2, 3, 0.25), (x, 0, 0.32), color="metal")


# What's exported: model -> how to build it. Each builds into b (main), g (glow), t (tint).
def with_colour(build, color):
    return lambda b, g, t: build(b, g, t, color)


MODELS = {
    "LampPost": lamp_post,
    "Lantern": lantern,
    "LanternChain": lantern_chain,
    "WallLantern": wall_lantern,
    "StoneLantern": stone_lantern,
    "JackOLantern": jack_o_lantern,
    "JackFace": jack_face_only,
    "Bench": bench,
    "Fence": fence,
    "FenceRail": fence_rail,
    "SignPost": sign_post,
    "WallSign": wall_sign,
    "SignPlank": sign_plank,
    "Banner": banner,
    "Awning": awning,
    "AwningStripe": awning_stripe,
    "Flower": flower,
    "TallGrass": tall_grass,
    "MushroomRed": mushroom_red,
    "MushroomBrown": mushroom_brown,
    "FlowerBox": flower_box,
    "LilyPad": lily_pad,
    "LilyBloom": lily_bloom,
    "Cactus0": lambda b, _g, _t: cactus(b, 0),
    "Cactus1": lambda b, _g, _t: cactus(b, 1),
    "Cactus2": lambda b, _g, _t: cactus(b, 2),
    "PalmTree": palm,
    "Minecart": minecart,
    "Rails": rails,
}

# Models with no main mesh: their one kind of mesh is the model
ONLY_TINT = {"SignPlank", "AwningStripe", "LilyBloom"}
ONLY_GLOW = {"JackFace"}
# Which child the third builder makes, where it isn't Tint
CHILD_NAME = {"PalmTree": "Fronds"}


def icon(build, *args, azimuth=-30, elevation=20):
    return (lambda b: build(b, b, b, *args), azimuth, elevation)


def cactus_icon(b):
    cactus(b, 2)


# Item id -> (build, azimuth, elevation), for the icon sheets (items3d.py)
ICONS = {
    "LampPost": icon(lamp_post, azimuth=-24, elevation=12),
    "Lantern": icon(lantern),
    "WallLantern": icon(wall_lantern),
    "StoneLantern": icon(stone_lantern),
    "JackOLantern": icon(jack_o_lantern, azimuth=-24),
    "Bench": icon(bench),
    "Fence": icon(fence),
    "Sign": icon(sign_post, azimuth=-20, elevation=10),
    "BannerRed": icon(banner, "red", azimuth=-18, elevation=8),
    "BannerBlue": icon(banner, "blue", azimuth=-18, elevation=8),
    "BannerGreen": icon(banner, "leaf_light", azimuth=-18, elevation=8),
    "BannerYellow": icon(banner, "flower_yellow", azimuth=-18, elevation=8),
    "Awning": icon(awning, azimuth=-40, elevation=25),
    "FlowerRed": icon(flower, "red"),
    "FlowerYellow": icon(flower, "flower_yellow"),
    "FlowerBlue": icon(flower, "blue"),
    "FlowerWhite": icon(flower, "flower_white"),
    "FlowerPink": icon(flower, "flower_pink"),
    "TallGrass": icon(tall_grass),
    "MushroomRed": icon(mushroom_red),
    "MushroomBrown": icon(mushroom_brown),
    "FlowerBox": icon(flower_box),
    "LilyPad": icon(lily_pad, elevation=35),
    "Cactus": (cactus_icon, -24, 12),
    "PalmTree": icon(palm, azimuth=-24, elevation=12),
    "Minecart": icon(minecart, azimuth=-40, elevation=25),
    "Rails": icon(rails, azimuth=-40, elevation=30),
}


def to_roblox(v):
    """Blender (x, y, z) -> Roblox (-x, z, y), the axis swap the FBX export makes."""
    return (-v[0], v[2], v[1])


def bounds(obj):
    coords = [v.co for v in obj.data.vertices]
    low = Vector((min(c.x for c in coords), min(c.y for c in coords), min(c.z for c in coords)))
    high = Vector((max(c.x for c in coords), max(c.y for c in coords), max(c.z for c in coords)))
    size = high - low
    return to_roblox((low + high) / 2), (size.x, size.z, size.y)


def build_models():
    """Every mesh, and where each sits: name -> {Center, Size} in Roblox axes around the origin."""
    objects, info = [], {}
    for name, build in MODELS.items():
        seed = sum(map(ord, name))
        b, g, t = Builder(seed=seed), Builder(seed=seed + 1), Builder(seed=seed + 2)
        build(b, g, t)
        child_name = CHILD_NAME.get(name, "Tint")
        pieces = [(b, f"Decor_{name}"), (g, f"Decor_{name}__Glow"), (t, f"Decor_{name}__{child_name}")]
        if name in ONLY_TINT:
            pieces = [(t, f"Decor_{name}")]
        elif name in ONLY_GLOW:
            pieces = [(g, f"Decor_{name}")]
        for builder, object_name in pieces:
            if not builder.bm.verts:
                builder.bm.free()
                continue
            obj = builder.finish(object_name)
            objects.append(obj)
            center, size = bounds(obj)
            info[object_name.removeprefix("Decor_")] = {"Center": center, "Size": size}
    return objects, info


def vec(v):
    return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"


def write_luau(info):
    lines = [
        "--!strict",
        "-- GENERATED by art/scripts/decor.py - don't edit by hand; change the script and re-run it.",
        "-- Each decoration mesh's middle and size in studs, around its model's origin (on the floor",
        "-- under it, or on the wall behind it). Name__Child goes with the model Name.",
        "",
        "return table.freeze({",
    ]
    for name in sorted(info):
        lines.append(f'\t["{name}"] = {{ Center = {vec(info[name]["Center"])}, Size = {vec(info[name]["Size"])} }},')
    lines.append("})")
    path = os.path.join(REPO_DIR, "game", "src", "shared", "DecorArt.luau")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    return path


def preview(objects):
    """Lays every model out in rows so they can be looked at together."""
    spacing, per_row = 9, 8
    placed = {}
    columns = {}
    for obj in objects:
        model = obj.name.removeprefix("Decor_").split("__")[0]
        columns.setdefault(model, len(columns))
        index = columns[model]
        at = Vector((index % per_row * spacing, -(index // per_row) * spacing * 1.6, 0))
        placed[obj] = obj.location.copy()
        obj.location = at
    count = len(columns)
    rows = (count - 1) // per_row
    target = ((per_row - 1) * spacing / 2, -rows * spacing * 0.8, 3)
    path = common.render_preview("Decor", target=target, distance=70, height=62, angle_deg=-12)
    for obj, location in placed.items():
        obj.location = location
    return path


def main():
    common.reset_scene()
    objects, info = build_models()
    common.save_blend("Decor")
    print("fbx:", export_fbx(os.path.join(common.EXPORT_DIR, "Decor.fbx"), objects))
    with open(os.path.join(common.EXPORT_DIR, "Decor.json"), "w", encoding="utf-8") as f:
        json.dump(info, f, indent=1)
    print("luau:", write_luau(info))
    print("preview:", preview(objects))
    print(f"decor: {len(MODELS)} models, {len(objects)} meshes")


if __name__ == "__main__":
    main()
