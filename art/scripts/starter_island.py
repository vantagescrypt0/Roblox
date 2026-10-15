"""Greybox starter floating island: grass top, dirt underside, rocks, one tree.

About 40 studs across. Prototype art only; style is not decided yet.
"""

import math
import os
import random
import sys

import bmesh
import bpy

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

NAME = "StarterIsland"
RADIUS = 20
SIDES = 14
SEED = 7


def ring_radii(rng, base, jitter):
    return [base * (1 + rng.uniform(-jitter, jitter)) for _ in range(SIDES)]


def ring(bm, radii, z, z_jitter=0.0, rng=None, offset=(0, 0)):
    verts = []
    for i, r in enumerate(radii):
        a = 2 * math.pi * i / SIDES
        dz = rng.uniform(-z_jitter, z_jitter) if rng and z_jitter else 0
        verts.append(bm.verts.new((offset[0] + r * math.cos(a), offset[1] + r * math.sin(a), z + dz)))
    return verts


def bridge(bm, lower, upper):
    n = len(lower)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lower[i], lower[j], upper[j], upper[i]))


def grass_top(rng, outline):
    bm = bmesh.new()
    top = ring(bm, [r * 0.97 for r in outline], 0.0)
    lip = ring(bm, outline, -0.6)
    bottom = ring(bm, [r * 0.98 for r in outline], -2.0)
    bm.faces.new(top)
    bridge(bm, lip, top)
    bridge(bm, bottom, lip)
    bm.faces.new(list(reversed(bottom)))
    bm.normal_update()
    return common.mesh_object("GrassTop", bm, common.material("Grass", common.hex_rgb("#6DBE45")))


def dirt_body(rng, outline):
    bm = bmesh.new()
    layers = [(-1.8, 1.0), (-5, 0.9), (-9, 0.68), (-13, 0.44), (-17, 0.22)]
    rings = []
    for i, (z, scale) in enumerate(layers):
        jitter = 0.0 if i == 0 else 0.12
        radii = [r * scale * (1 + rng.uniform(-jitter, jitter)) for r in outline]
        rings.append(ring(bm, radii, z, z_jitter=0.0 if i == 0 else 0.8, rng=rng))
    for lower, upper in zip(rings[1:], rings[:-1]):
        bridge(bm, lower, upper)
    tip = bm.verts.new((rng.uniform(-1, 1), rng.uniform(-1, 1), -22))
    last = rings[-1]
    for i in range(SIDES):
        bm.faces.new((last[(i + 1) % SIDES], last[i], tip))
    bm.faces.new(rings[0])
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return common.mesh_object("DirtBody", bm, common.material("Dirt", common.hex_rgb("#8A5A34")))


def rock(rng, name, location, size):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=size)
    for v in bm.verts:
        v.co.x *= rng.uniform(0.8, 1.25)
        v.co.y *= rng.uniform(0.8, 1.25)
        v.co.z *= rng.uniform(0.55, 0.8)
    obj = common.mesh_object(name, bm, common.material("Stone", common.hex_rgb("#8C8C8C")))
    obj.location = location
    obj.rotation_euler.z = rng.uniform(0, math.tau)
    return obj


def tree(rng, location):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.9, radius2=0.7, depth=7)
    bmesh.ops.translate(bm, vec=(0, 0, 3.5), verts=bm.verts)
    trunk = common.mesh_object("TreeTrunk", bm, common.material("Wood", common.hex_rgb("#6B4423")))
    trunk.location = location

    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=4.2)
    for v in bm.verts:
        v.co.z *= 0.85
        v.co *= rng.uniform(0.92, 1.08)
    leaves = common.mesh_object("TreeLeaves", bm, common.material("Leaves", common.hex_rgb("#3F8F3A")))
    leaves.location = (location[0], location[1], location[2] + 8.5)
    return trunk, leaves


def main():
    common.reset_scene()
    rng = random.Random(SEED)
    outline = ring_radii(rng, RADIUS, 0.08)

    grass_top(rng, outline)
    dirt_body(rng, outline)
    rock(rng, "RockA", (9, -6, 0.2), 2.2)
    rock(rng, "RockB", (11.5, -3, 0.1), 1.3)
    rock(rng, "RockC", (-12, 7, 0.1), 1.6)
    tree(rng, (-7, -5, 0))

    print("render:", common.render_preview(NAME, target=(0, 0, -4)))
    print("blend:", common.save_blend(NAME))
    print("fbx:", common.export_fbx(NAME))


main()
