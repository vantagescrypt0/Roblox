"""Player islands, one per expansion tier (bigger, more trees and farm space each tier).

Each tier is a set of objects with a _T<tier> suffix, all built around the origin:
  GrassTop     walkable top (flat at z=0)
  IslandBody   cliffs, strata, hanging roots
  Decor        flowers, grass tufts, bushes, floating pebbles (no collision in game)
  TreeTrunk_i / TreeLeaves_i   choppable trees
  Rock_i       mineable rocks
  Marker_*     layout points the game reads: Center, Spawn, Workbench, Market, Portal, Plot_i

Front of the island is -Y (Roblox -Z).
Output: art/export/Islands.fbx, art/blend/Islands.blend, art/renders/Islands_T<n>.png
"""

import math
import os
import random
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import lowpoly  # noqa: E402
from lowpoly import Builder  # noqa: E402

PLOT_SPACING = 5.2
PLOT_HALF = 2.3

TIERS = [
    {
        "radius": 22,
        "grid": (3, 2),
        "farm": (-8, -6),
        "trees": [(135, 0.7, "round"), (50, 0.72, "pine")],
        "rocks": [(160, 0.82), (300, 0.8)],
    },
    {
        "radius": 29,
        "grid": (3, 3),
        "farm": (-10, -8),
        "trees": [(135, 0.7, "round"), (50, 0.72, "pine"), (175, 0.75, "pine")],
        "rocks": [(160, 0.84), (300, 0.8), (20, 0.84)],
    },
    {
        "radius": 36,
        "grid": (4, 3),
        "farm": (-11, -9),
        "trees": [(135, 0.7, "round"), (50, 0.72, "pine"), (175, 0.75, "pine"), (285, 0.78, "round")],
        "rocks": [(160, 0.85), (310, 0.85), (20, 0.84), (240, 0.86)],
    },
    {
        "radius": 44,
        "grid": (4, 4),
        "farm": (-13, -11),
        "trees": [
            (135, 0.7, "round"),
            (50, 0.72, "pine"),
            (175, 0.75, "pine"),
            (285, 0.78, "round"),
            (15, 0.7, "round"),
            (110, 0.82, "pine"),
        ],
        "rocks": [(160, 0.86), (310, 0.85), (25, 0.84), (240, 0.87), (70, 0.86)],
    },
]

SPAWN = (3, 1)
WORKBENCH = (9, 4)
MARKET = (9, -8)


def outline(rng, radius, sides):
    radii = [radius * rng.uniform(0.94, 1.04) for _ in range(sides)]
    # Smooth neighbours so the edge wobbles gently instead of zig-zagging
    return [(radii[i - 1] + radii[i] * 2 + radii[(i + 1) % sides]) / 4 for i in range(sides)]


def ring(radii, z, scale=1.0, rng=None, wobble=0.0, z_wobble=0.0):
    sides = len(radii)
    points = []
    for i, r in enumerate(radii):
        a = 2 * math.pi * i / sides
        rr = r * scale * (1 + (rng.uniform(-wobble, wobble) if rng else 0))
        zz = z + (rng.uniform(-z_wobble, z_wobble) if rng else 0)
        points.append((rr * math.cos(a), rr * math.sin(a), zz))
    return points


def radius_at(radii, angle):
    sides = len(radii)
    i = int(round((angle % (2 * math.pi)) / (2 * math.pi) * sides)) % sides
    return radii[i]


def plot_positions(spec):
    cols, rows = spec["grid"]
    cx, cy = spec["farm"]
    positions = []
    for row in range(rows):
        for col in range(cols):
            x = cx + (col - (cols - 1) / 2) * PLOT_SPACING
            y = cy + ((rows - 1) / 2 - row) * PLOT_SPACING
            positions.append((x, y))
    return positions


def tree(b, rng, x, y, style):
    # Trunk with flared roots
    h = rng.uniform(5.2, 6.2)
    b.cylinder(0.75, h, (x, y, h / 2), color="bark", segments=7, radius2=0.45)
    for k in range(3):
        a = k * 120 + rng.uniform(-20, 20)
        r = math.radians(a)
        b.cone(0.35, 1.3, (x + 0.6 * math.cos(r), y + 0.6 * math.sin(r), 0.35), (-45 * math.sin(r), 45 * math.cos(r), 0), color="bark", segments=4)
    return h


def leaves(b, rng, x, y, h, style):
    if style == "pine":
        for k, (radius, z) in enumerate(((3.2, h - 1.2), (2.6, h + 0.6), (1.9, h + 2.2), (1.2, h + 3.6))):
            b.cone(radius, 2.6, (x, y, z), (rng.uniform(-3, 3), rng.uniform(-3, 3), rng.uniform(0, 60)), color="leaf_dark" if k % 2 else "leaf", segments=7)
    else:
        colors = ("leaf", "leaf_light", "leaf_dark", "leaf")
        for k in range(4):
            a = math.radians(k * 90 + rng.uniform(-30, 30))
            off = 1.3 if k else 0
            b.blob(
                rng.uniform(2.0, 2.6),
                (x + off * math.cos(a), y + off * math.sin(a), h + rng.uniform(0.6, 2.2)),
                color=colors[k],
                squash=(1, 1, 0.85),
                jitter=0.15,
            )


def rock(b, rng, x, y):
    b.blob(1.5, (x, y, 0.6), color="stone", squash=(1.2, 1, 0.75), jitter=0.25, subdivisions=1)
    b.blob(0.9, (x + 1.1, y + 0.4, 0.35), color="stone_light", squash=(1, 1.1, 0.8), jitter=0.3, subdivisions=0)
    b.blob(0.6, (x - 0.9, y - 0.8, 0.25), color="stone_dark", jitter=0.3, subdivisions=0)


def build_tier(tier, spec):
    suffix = f"_T{tier}"
    radius = spec["radius"]
    rng = random.Random(100 + tier)
    sides = max(20, int(radius * 0.9))
    edge = outline(rng, radius, sides)
    depth = 0.55 + 0.45 * radius / 22
    objects = []

    # Walkable grass top with a thick lip
    g = Builder(seed=tier)
    g.loft(
        [ring(edge, 0.0), ring(edge, -0.6, 1.01), ring(edge, -1.4, 0.98)],
        ["grass_dark", "grass_dark"],
        top_color="grass",
        bottom_color="dirt",
    )
    objects.append(g.finish("GrassTop" + suffix))

    # Cliffs: dirt and stone layers tapering to a point
    body = Builder(seed=tier + 10)
    layers = [(-1.3, 0.985, 0.0, 0.0), (-4.0, 0.95, 0.05, 0.4), (-8.0, 0.84, 0.08, 0.8), (-13.0, 0.66, 0.1, 1.0), (-18.0, 0.46, 0.12, 1.2), (-23.0, 0.27, 0.14, 1.2)]
    rings = [ring(edge, z * depth, s, rng, w, zw) for z, s, w, zw in layers]
    body.loft(
        rings,
        ["dirt", "dirt_dark", "dirt", "stone_dark", "stone"],
        tip=(rng.uniform(-1, 1), rng.uniform(-1, 1), -30 * depth),
        tip_color="stone_dark",
    )
    # Hanging roots and stones poking out of the cliffs
    for k in range(int(radius * 0.8)):
        a = rng.uniform(0, 2 * math.pi)
        r = radius_at(edge, a) * rng.uniform(0.96, 1.0)
        body.cone(rng.uniform(0.12, 0.28), rng.uniform(1.2, 3.2), (r * math.cos(a), r * math.sin(a), -2.2 * depth), (180 + rng.uniform(-12, 12), rng.uniform(-12, 12), 0), color="root", segments=4)
    for k in range(int(radius * 0.4)):
        a = rng.uniform(0, 2 * math.pi)
        z = rng.uniform(-12, -4) * depth
        scale = 0.95 - (abs(z) / (23 * depth)) * 0.6
        r = radius_at(edge, a) * scale
        body.blob(rng.uniform(0.8, 1.6), (r * math.cos(a), r * math.sin(a), z), color=rng.choice(("stone", "stone_dark", "stone_blue")), jitter=0.3, subdivisions=0)
    objects.append(body.finish("IslandBody" + suffix))

    # Reserved areas: nothing decorative may sit here
    reserved = [(SPAWN, 3.5), (WORKBENCH, 4.5), (MARKET, 6.5), ((0, radius - 6), 6.5)]
    plots = plot_positions(spec)
    cols, rows = spec["grid"]
    fx, fy = spec["farm"]
    farm_half = (cols * PLOT_SPACING / 2 + 1.5, rows * PLOT_SPACING / 2 + 1.5)

    def free(x, y, margin=0.0):
        if abs(x - fx) < farm_half[0] + margin and abs(y - fy) < farm_half[1] + margin:
            return False
        for (cx, cy), r in reserved:
            if math.hypot(x - cx, y - cy) < r + margin:
                return False
        return math.hypot(x, y) < radius * 0.86

    # Trees and rocks (each its own object so the game can make them harvestable)
    for i, (angle, dist, style) in enumerate(spec["trees"], start=1):
        a = math.radians(angle)
        x, y = radius * dist * math.cos(a), radius * dist * math.sin(a)
        t = Builder(seed=tier * 100 + i)
        h = tree(t, rng, x, y, style)
        objects.append(t.finish(f"TreeTrunk_{i}{suffix}"))
        lv = Builder(seed=tier * 200 + i)
        leaves(lv, rng, x, y, h, style)
        objects.append(lv.finish(f"TreeLeaves_{i}{suffix}"))
        reserved.append(((x, y), 3.2))
    for i, (angle, dist) in enumerate(spec["rocks"], start=1):
        a = math.radians(angle)
        x, y = radius * dist * math.cos(a), radius * dist * math.sin(a)
        r = Builder(seed=tier * 300 + i)
        rock(r, rng, x, y)
        objects.append(r.finish(f"Rock_{i}{suffix}"))
        reserved.append(((x, y), 2.8))

    # Decor: grass patches, tufts, flowers, bushes, floating pebbles
    d = Builder(seed=tier + 20)
    attempts = int(radius * radius * 0.32)
    for _ in range(attempts):
        x, y = rng.uniform(-radius, radius), rng.uniform(-radius, radius)
        if not free(x, y):
            continue
        roll = rng.random()
        if roll < 0.18:
            d.blob(rng.uniform(1.0, 2.0), (x, y, 0.02), color=rng.choice(("grass_light", "grass_dark")), squash=(1.4, 1, 0.03), jitter=0.2, subdivisions=0, rotation=(0, 0, rng.uniform(0, 180)))
        elif roll < 0.6:
            for k in range(3):
                d.cone(0.12, rng.uniform(0.5, 0.9), (x + rng.uniform(-0.25, 0.25), y + rng.uniform(-0.25, 0.25), 0.3), (rng.uniform(-20, 20), rng.uniform(-20, 20), 0), color=rng.choice(("grass_dark", "grass_light")), segments=3)
        elif roll < 0.9:
            color = rng.choice(("flower_pink", "flower_yellow", "flower_white", "flower_purple"))
            for k in range(rng.randint(2, 4)):
                fx2, fy2 = x + rng.uniform(-0.6, 0.6), y + rng.uniform(-0.6, 0.6)
                d.cylinder(0.04, 0.5, (fx2, fy2, 0.25), color="stalk", segments=4)
                d.blob(0.16, (fx2, fy2, 0.55), color=color, squash=(1, 1, 0.6), subdivisions=0)
        elif free(x, y, 1.0):
            d.blob(rng.uniform(0.7, 1.1), (x, y, 0.5), color=rng.choice(("leaf", "leaf_light")), squash=(1.2, 1, 0.8))
    for k in range(3 + tier):
        a = rng.uniform(0, 2 * math.pi)
        r = radius * rng.uniform(0.8, 1.3)
        d.blob(rng.uniform(0.8, 1.8), (r * math.cos(a), r * math.sin(a), rng.uniform(-14, -6) * depth), color=rng.choice(("stone", "dirt", "stone_dark")), jitter=0.3, subdivisions=0)
    objects.append(d.finish("Decor" + suffix))

    # Layout markers
    objects.append(lowpoly.marker("Marker_Center" + suffix, (0, 0, 0)))
    objects.append(lowpoly.marker("Marker_Spawn" + suffix, (*SPAWN, 0)))
    objects.append(lowpoly.marker("Marker_Workbench" + suffix, (*WORKBENCH, 0)))
    objects.append(lowpoly.marker("Marker_Market" + suffix, (*MARKET, 0)))
    objects.append(lowpoly.marker("Marker_Portal" + suffix, (0, radius - 6, 0)))
    for i, (x, y) in enumerate(plots, start=1):
        objects.append(lowpoly.marker(f"Marker_Plot_{i}{suffix}", (x, y, 0)))
    return objects


def main():
    common.reset_scene()
    lowpoly.palette_material()

    tiers = [build_tier(i + 1, spec) for i, spec in enumerate(TIERS)]
    everything = [obj for objs in tiers for obj in objs]

    for i, objs in enumerate(tiers):
        for obj in everything:
            obj.hide_render = obj not in objs or obj.name.startswith("Marker_")
        radius = TIERS[i]["radius"]
        common.render_preview(f"Islands_T{i + 1}", target=(0, 0, -radius * 0.25), distance=radius * 3.0, height=radius * 1.6, angle_deg=-30)
    for obj in everything:
        obj.hide_render = False

    print("blend:", common.save_blend("Islands"))
    print("fbx:", lowpoly.export_fbx(os.path.join(common.EXPORT_DIR, "Islands.fbx"), everything))


main()
