"""Island props: workbench, market stall, portal, planter bed and crop growth stages.

All props are built at the origin, front facing -Y (which becomes -Z / LookVector in
Roblox), bottom at z=0. Parts that need special treatment in Roblox (glowing bits, the
sign face, the portal surface) are separate objects with the prop's name as prefix.

Output: art/export/Props.fbx, art/blend/Props.blend, art/renders/Props.png
"""

import math
import os
import sys

import bpy

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import lowpoly  # noqa: E402
from lowpoly import Builder  # noqa: E402


def workbench():
    b = Builder(seed=11)
    # Legs, stretchers and lower shelf
    for x in (-2.2, 2.2):
        for y in (-1.05, 1.05):
            b.box((0.36, 0.36, 2.76), (x, y, 1.38), color="wood_dark", bevel=0.04)
        b.box((0.24, 2.1, 0.24), (x, 0, 0.55), color="wood_dark")
    for y in (-1.05, 1.05):
        b.box((4.4, 0.24, 0.24), (0, y, 0.55), color="wood_dark")
    for i, y in enumerate((-0.7, 0, 0.7)):
        b.box((4.3, 0.64, 0.12), (0, y, 0.72), color="wood_alt" if i % 2 else "plank")
    # Logs on the shelf
    b.cylinder(0.26, 1.7, (-1.0, 0.25, 1.05), (0, 90, 0), color="bark", segments=7)
    b.cylinder(0.26, 1.7, (-1.0, -0.3, 1.05), (0, 90, 0), color="bark", segments=7)
    b.cylinder(0.24, 1.6, (-1.0, -0.02, 1.48), (0, 90, 4), color="wood_dark", segments=7)
    # Top planks
    for i, y in enumerate((-0.9, 0, 0.9)):
        b.box((5.2, 0.86, 0.26), (0, y, 2.89), color="wood" if i % 2 == 0 else "wood_alt", bevel=0.05, jitter=0.01)
    # Tool board on the back
    for x in (-2.2, 2.2):
        b.box((0.26, 0.26, 2.3), (x, 1.15, 4.15), color="wood_dark")
    b.box((4.7, 0.16, 1.7), (0, 1.22, 4.35), color="wood_alt", bevel=0.03)
    b.box((4.9, 0.22, 0.2), (0, 1.2, 5.25), color="wood_dark")
    # Hanging tools: wrench, pliers, small saw
    b.box((0.12, 0.06, 1.0), (-1.5, 1.08, 4.3), (0, 0, 0), color="steel")
    b.box((0.38, 0.06, 0.2), (-1.5, 1.08, 4.85), color="steel")
    b.box((0.1, 0.06, 0.9), (-0.55, 1.08, 4.3), (0, 12, 0), color="metal")
    b.box((0.1, 0.06, 0.9), (-0.35, 1.08, 4.3), (0, -12, 0), color="metal")
    b.box((0.18, 0.08, 0.35), (-0.45, 1.06, 3.75), color="red")
    b.box((1.2, 0.05, 0.42), (0.9, 1.09, 4.4), color="steel")
    b.box((0.36, 0.09, 0.42), (1.65, 1.08, 4.45), color="red")
    # Vise on the front-right corner
    b.box((0.8, 0.6, 0.5), (1.8, -1.0, 3.27), color="metal_dark", bevel=0.04)
    b.box((0.8, 0.14, 0.36), (1.8, -1.36, 3.32), color="steel")
    b.cylinder(0.05, 1.0, (1.8, -1.55, 3.22), (0, 90, 0), color="steel", segments=6)
    # Hammer and saw on the top
    b.cylinder(0.08, 1.4, (-0.55, 0.35, 3.1), (0, 90, 15), color="wood_darker", segments=6)
    b.box((0.28, 0.7, 0.28), (0.12, 0.53, 3.14), (0, 0, 15), color="metal_dark", bevel=0.03)
    b.box((1.6, 0.5, 0.04), (-1.5, -0.45, 3.04), (0, 0, -10), color="steel")
    b.box((0.45, 0.5, 0.1), (-2.35, -0.3, 3.07), (0, 0, -10), color="red")
    # Jar of nails
    b.cylinder(0.18, 0.36, (1.0, 0.65, 3.2), color="metal", segments=8)
    return [b.finish("Workbench")]


def market():
    b = Builder(seed=22)
    # Floor
    b.box((8.6, 4.6, 0.3), (0, 0, 0.15), color="wood_dark", bevel=0.05)
    # Counter: body, front planks, top
    b.box((7.4, 1.0, 2.4), (0, -1.35, 1.5), color="wood_dark")
    for i in range(6):
        x = -3.05 + i * 1.22
        b.box((1.16, 0.18, 2.36), (x, -1.9, 1.5), color="wood" if i % 2 == 0 else "wood_alt", bevel=0.03)
    b.box((8.0, 1.5, 0.22), (0, -1.35, 2.82), color="plank", bevel=0.04)
    # Posts
    for x in (-3.85, 3.85):
        b.box((0.36, 0.36, 5.8), (x, -2.0, 3.2), color="wood_darker", bevel=0.03)
        b.box((0.36, 0.36, 7.2), (x, 1.95, 3.9), color="wood_darker", bevel=0.03)
    # Back wall and shelf with sacks
    b.box((7.6, 0.2, 3.2), (0, 2.0, 1.9), color="wood_alt")
    b.box((7.4, 0.8, 0.15), (0, 1.55, 2.7), color="wood_dark")
    for x in (-2.6, -1.4, 1.6, 2.8):
        b.blob(0.42, (x, 1.55, 3.15), color="cream", squash=(1, 0.9, 1.15))
    # Striped awning sloping down toward the front
    slope = math.degrees(math.atan2(7.45 - 6.05, 4.4))
    stripes = 8
    width = 8.6 / stripes
    for i in range(stripes):
        x = -4.3 + width * (i + 0.5)
        color = "red" if i % 2 == 0 else "cream"
        b.box((width, 4.9, 0.14), (x, -0.05, 6.75), (slope, 0, 0), color=color)
        # Scalloped edge
        b.cylinder(width / 2, 0.1, (x, -2.48, 5.98), (90, 0, 0), color=color, segments=10)
    # Crates on the counter with produce
    for x in (-2.5, 0, 2.5):
        b.box((1.7, 1.15, 0.6), (x, -1.35, 3.23), color="wood_alt", bevel=0.03)
        b.box((1.8, 0.1, 0.14), (x, -1.95, 3.3), color="wood_dark")
    for i in range(9):
        b.cylinder(0.08, 0.9, (-3.0 + (i % 3) * 0.45, -1.6 + (i // 3) * 0.3, 3.8), (b.rng.uniform(-8, 8), b.rng.uniform(-8, 8), 0), color="wheat_dark", segments=5)
        b.blob(0.12, (-3.0 + (i % 3) * 0.45, -1.6 + (i // 3) * 0.3, 4.3), color="wheat", squash=(1, 1, 2.4))
    for i in range(6):
        x, y = -0.5 + (i % 3) * 0.5, -1.55 + (i // 3) * 0.45
        b.cone(0.16, 0.55, (x, y, 3.65), (180 + b.rng.uniform(-30, 30), b.rng.uniform(-30, 30), 0), color="carrot")
        b.cone(0.1, 0.5, (x, y, 3.95), (b.rng.uniform(-15, 15), b.rng.uniform(-15, 15), 0), color="leaf_light", segments=4)
    for i in range(7):
        b.blob(0.22, (2.0 + (i % 4) * 0.34, -1.55 + (i // 4) * 0.4, 3.6 + (i % 2) * 0.1), color="potato", squash=(1.2, 1, 0.8))
    # Barrel and basket beside the stall
    b.cylinder(0.62, 1.3, (4.9, -1.0, 0.95), color="wood_alt", segments=10)
    for z in (0.55, 1.35):
        b.cylinder(0.65, 0.09, (4.9, -1.0, z), color="metal_dark", segments=10)
    b.cylinder(0.5, 0.5, (-4.9, -1.2, 0.55), color="wood", segments=8, radius2=0.6)
    for i in range(5):
        b.blob(0.18, (-4.9 + b.rng.uniform(-0.3, 0.3), -1.2 + b.rng.uniform(-0.3, 0.3), 0.85), color="carrot")
    # Sign frame above the awning
    b.box((3.9, 0.26, 1.15), (0, -2.32, 7.0), color="wood_darker", bevel=0.04)
    # Lantern frame
    b.cylinder(0.03, 0.6, (3.3, -2.2, 5.7), color="metal_dark", segments=4)
    b.box((0.45, 0.45, 0.08), (3.3, -2.2, 5.42), color="metal_dark")
    b.box((0.45, 0.45, 0.08), (3.3, -2.2, 4.88), color="metal_dark")
    stall = b.finish("MarketStall")

    s = Builder()
    s.box((3.5, 0.06, 0.85), (0, -2.47, 7.0), color="sign")
    sign = s.finish("MarketSignFace")

    g = Builder()
    g.box((0.34, 0.34, 0.46), (3.3, -2.2, 5.15), color="glow")
    glow = g.finish("MarketLanternGlow")
    return [stall, sign, glow]


def portal():
    b = Builder(seed=33)
    stones = ("stone", "stone_light", "stone_blue")
    # Platform
    b.cylinder(4.7, 0.45, (0, 0, 0.22), color="stone_dark", segments=8, bevel=0.06)
    b.cylinder(3.9, 0.4, (0, 0, 0.62), color="stone", segments=8, bevel=0.06)
    b.box((3.2, 1.2, 0.3), (0, -4.7, 0.15), color="stone_dark", bevel=0.04)
    # Pillars
    for x in (-3.1, 3.1):
        for i in range(4):
            b.box(
                (1.35, 1.5, 1.18),
                (x + b.rng.uniform(-0.05, 0.05), 0, 1.4 + i * 1.2),
                (0, 0, b.rng.uniform(-4, 4)),
                color=stones[(i + (1 if x > 0 else 0)) % 3],
                bevel=0.09,
                jitter=0.04,
            )
    # Arch
    center_z, radius = 5.6, 3.1
    for i in range(1, 8):
        angle = i * 22.5
        if angle == 90:
            continue
        rad = math.radians(angle)
        b.box(
            (1.25, 1.5, 1.15),
            (radius * math.cos(rad), 0, center_z + radius * math.sin(rad)),
            (0, 90 - angle, 0),
            color=stones[i % 3],
            bevel=0.09,
            jitter=0.04,
        )
    b.box((1.6, 1.75, 1.6), (0, 0, center_z + radius + 0.15), color="stone_light", bevel=0.1)
    frame = b.finish("PortalFrame")

    r = Builder(seed=34)
    # Glyphs on the pillar fronts
    for x in (-3.1, 3.1):
        for i in range(4):
            z = 1.4 + i * 1.2
            if i % 2 == 0:
                r.box((0.5, 0.06, 0.12), (x, -0.78, z), color="rune")
                r.box((0.12, 0.06, 0.5), (x, -0.78, z), color="rune")
            else:
                r.box((0.36, 0.06, 0.36), (x, -0.78, z), (0, 45, 0), color="rune")
    r.box((0.62, 0.06, 0.62), (0, -0.9, center_z + radius + 0.15), (0, 45, 0), color="rune")
    # Crystals growing at the base
    for side in (-1, 1):
        for j in range(3):
            r.cone(
                0.32 - j * 0.06,
                1.6 - j * 0.35,
                (side * (4.0 + j * 0.35), -1.2 + j * 0.5, 1.4 - j * 0.15),
                (side * (12 + j * 10), j * 8, 0),
                color="rune",
                segments=5,
            )
    runes = r.finish("PortalRunes")

    s = Builder()
    s.box((4.9, 0.12, 4.8), (0, 0, 3.2), color="portal")
    s.cylinder(2.45, 0.12, (0, 0, center_z), (90, 0, 0), color="portal", segments=16)
    surface = s.finish("PortalSurface")
    return [frame, runes, surface]


def planter():
    b = Builder(seed=44)
    for y in (-2.12, 2.12):
        b.box((4.6, 0.36, 0.72), (0, y, 0.36), color="wood_alt", bevel=0.03)
    for x in (-2.12, 2.12):
        b.box((0.36, 3.9, 0.72), (x, 0, 0.36), color="wood", bevel=0.03)
    for x in (-2.12, 2.12):
        for y in (-2.12, 2.12):
            b.box((0.52, 0.52, 0.96), (x, y, 0.48), color="wood_dark", bevel=0.05)
    b.box((3.9, 3.9, 0.56), (0, 0, 0.3), color="soil")
    # Tilled rows: low, lumpy ridges with a few clods
    for y in (-1.35, -0.45, 0.45, 1.35):
        b.box((3.8, 0.62, 0.13), (0, y, 0.62), color="soil_light", bevel=0.03, jitter=0.035)
        for k in range(4):
            b.blob(0.1, (b.rng.uniform(-1.7, 1.7), y + b.rng.uniform(-0.2, 0.2), 0.7), color="soil_light", squash=(1.3, 1, 0.6), jitter=0.3, subdivisions=0)
    return [b.finish("PlanterBed")]


ROWS = (-1.35, -0.45, 0.45, 1.35)


def crops():
    out = []

    b = Builder(seed=51)
    for y in ROWS:
        for x in (-1.2, 0, 1.2):
            b.cone(0.13, 0.4, (x - 0.08, y, 0.18), (0, -28, 0), color="sprout", segments=4)
            b.cone(0.13, 0.4, (x + 0.08, y, 0.18), (0, 28, 0), color="sprout", segments=4)
    out.append(b.finish("Crop_Sprout"))

    b = Builder(seed=52)
    for y in ROWS:
        for x in (-1.2, 0, 1.2):
            h = b.rng.uniform(0.9, 1.15)
            b.cylinder(0.06, h, (x, y, h / 2), color="stalk", segments=5)
            b.blob(0.3, (x - 0.18, y, h * 0.6), color="leaf_light", squash=(1.2, 0.45, 0.25), rotation=(0, -30, 0))
            b.blob(0.3, (x + 0.18, y, h * 0.8), color="sprout", squash=(1.2, 0.45, 0.25), rotation=(0, 30, 0))
    out.append(b.finish("Crop_Young"))

    b = Builder(seed=53)
    for y in ROWS:
        for x in (-1.35, -0.45, 0.45, 1.35):
            h = b.rng.uniform(1.8, 2.3)
            tilt = (b.rng.uniform(-7, 7), b.rng.uniform(-7, 7), 0)
            b.cylinder(0.05, h, (x, y, h / 2), tilt, color="wheat_dark", segments=4)
            b.blob(0.13, (x, y, h + 0.12), color="wheat", squash=(1, 1, 3.0))
            b.blob(0.25, (x + 0.12, y, h * 0.4), color="wheat_dark", squash=(1.1, 0.3, 0.2), rotation=(0, 35, 0))
    out.append(b.finish("Crop_Wheat"))

    b = Builder(seed=54)
    for y in ROWS:
        for x in (-1.2, 0, 1.2):
            b.cone(0.2, 0.45, (x, y, 0.1), (180, 0, 0), color="carrot", segments=6)
            for k in range(4):
                angle = k * 90 + b.rng.uniform(-20, 20)
                b.cone(
                    0.09,
                    0.85,
                    (x + 0.15 * math.cos(math.radians(angle)), y + 0.15 * math.sin(math.radians(angle)), 0.65),
                    (-30 * math.sin(math.radians(angle)), 30 * math.cos(math.radians(angle)), 0),
                    color="leaf_light" if k % 2 else "leaf",
                    segments=4,
                )
    out.append(b.finish("Crop_Carrot"))

    b = Builder(seed=55)
    for y in (-1.2, 0, 1.2):
        for x in (-1.2, 0, 1.2):
            b.blob(0.55, (x, y, 0.5), color="leaf_light", squash=(1, 1, 0.75))
            b.blob(0.38, (x + 0.25, y - 0.2, 0.85), color="leaf", squash=(1, 1, 0.8))
            for k in range(3):
                b.blob(0.09, (x + b.rng.uniform(-0.35, 0.35), y + b.rng.uniform(-0.35, 0.35), 1.05), color="potato_flower")
            b.blob(0.2, (x - 0.35, y + 0.3, 0.08), color="potato", squash=(1.2, 1, 0.7))
    out.append(b.finish("Crop_Potato"))

    b = Builder(seed=56)
    g = Builder(seed=57)
    for y in (-1.2, 0, 1.2):
        for x in (-1.2, 0, 1.2):
            b.blob(0.6, (x, y, 0.6), color="berry_bush", squash=(1, 1, 0.9))
            b.blob(0.35, (x - 0.2, y + 0.25, 1.05), color="leaf_dark")
            for k in range(6):
                angle = math.radians(k * 60 + g.rng.uniform(-15, 15))
                g.blob(0.11, (x + 0.55 * math.cos(angle), y + 0.55 * math.sin(angle), g.rng.uniform(0.5, 1.0)), color="berry", jitter=0.0)
    out.append(b.finish("Crop_Glowberry"))
    out.append(g.finish("Crop_GlowberryGlow"))
    return out


def main():
    common.reset_scene()
    lowpoly.palette_material()

    groups = [workbench(), market(), portal(), planter()] + [[c] for c in crops()]
    everything = [obj for group in groups for obj in group]

    # One close-up preview per prop (others hidden)
    framing = {
        "Workbench": (3, 13),
        "MarketStall": (4, 20),
        "PortalFrame": (5, 22),
        "PlanterBed": (1, 10),
    }
    for group in groups:
        name = group[0].name
        for obj in everything:
            obj.hide_render = obj not in group
        height, distance = framing.get(name, (1, 9))
        common.render_preview(f"Props_{name}", target=(0, 0, height), distance=distance, height=distance * 0.45, angle_deg=-30)
    for obj in everything:
        obj.hide_render = False

    print("blend:", common.save_blend("Props"))
    print("fbx:", lowpoly.export_fbx(os.path.join(common.EXPORT_DIR, "Props.fbx"), everything))


main()
