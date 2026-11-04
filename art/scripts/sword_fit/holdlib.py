"""The game's sword pose maths and body, in Blender, for measuring every sword against every armour set.
Everything's in the chest's space: X right, Y up, -Z ahead, as in SwordArt.luau. See README.md."""
import json
import math
import os
import re

import numpy as np
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
MESHES = json.load(open(os.path.join(HERE, "meshes.json")))
ARMOUR = json.load(open(os.path.join(HERE, "armour.json")))

# Measured on the real avatar in a playtest (2026-11-04)
SHOULDER = np.array((0.7684, 0.5829, 0.0180))
LEFT_SHOULDER = np.array((-0.7684, 0.5829, 0.0180))
REACH = 1.5738
HEAD_AT = np.array((-0.008, 1.464, 0.041))
HIPS_AT = np.array((0.0, -0.696, 0.036))
LEFT_UPPER_AT = np.array((-0.971, 0.256, 0.089))
LEFT_LOWER_AT = np.array((-1.198, -0.255, -0.008))
THIGH_R_AT = np.array((0.34, -1.45, 0.03))
THIGH_L_AT = np.array((-0.34, -1.45, 0.03))

# Roblox's idle animation looks around, so what's on the head is measured all through these, turning at the neck.
# Measured from the real game. Yaw is turning, pitch looking up (+) or down (-).
NECK = np.array((0.0, 0.918, 0.018))
HEAD_YAWS = (-44, -22, 0, 28, 56)
HEAD_PITCHES = (-19, 0, 7)
HEAD_ROOM = 1.03

SIDE = (1, 0, 0)
DOWN = (0, -1, 0)
UP = (0, 1, 0)
SWORDS = {
    "WoodenSword": dict(Length=4.6, Grip=(0, 0.31, 0), Up=DOWN, Spine=SIDE),
    "StoneSword": dict(Length=4.6, Grip=(0, 0.333, 0), Up=DOWN, Spine=SIDE),
    "IronSword": dict(Length=5.2, Grip=(0, 0.292, 0), Up=DOWN, Spine=SIDE),
    "AmethystSword": dict(Length=6.0, Grip=(0, 0.375, 0), Up=DOWN, Spine=SIDE),
    "SapphireSword": dict(Length=6.2, Grip=(0, -0.354, 0), Up=UP, Spine=SIDE),
    "CrystalSword": dict(Length=6.4, Grip=(0, 0.333, 0), Up=DOWN, Spine=SIDE),
    "RubySword": dict(Length=6.8, Grip=(0.039, -0.36, 0), Up=(0.526, 0.85, 0), Spine=(0.85, -0.526, 0)),
    "StarsteelSword": dict(Length=7.0, Grip=(0, -0.333, 0), Up=UP, Spine=SIDE),
}
STRAIGHT = [name for name in SWORDS if name != "RubySword"]


def read_carries():
    """The poses in the game's own code, so what's measured is what's in the game."""
    path = os.path.join(HERE, "..", "..", "..", "game", "src", "shared", "SwordArt.luau")
    text = open(path, encoding="utf-8").read()
    number = r"(-?[0-9.]+)"
    triple = rf"Vector3\.new\({number}, {number}, {number}\)"
    pose = re.compile(rf"Hand = {triple},\s*Along = {triple},\s*Turn = {triple}")
    out = {}
    for family, local in (("Straight", "STRAIGHT"), ("Ruby", "CRESCENT")):
        start = text.index(f"local {local}: Carry = {{")
        end = text.index("\n}\n", start)
        poses = []
        for m in pose.finditer(text, start, end):
            n = [float(x) for x in m.groups()]
            poses.append(dict(Hand=n[0:3], Along=n[3:6], Turn=n[6:9]))
        if len(poses) != 8:
            raise ValueError(f"{local}: expected 8 poses, found {len(poses)}")
        out[family] = dict(
            Bare=dict(Rest=poses[0], Run=poses[1]),
            Armoured=dict(Rest=poses[2], Run=poses[3]),
            Swing=poses[4:] + [None],
        )
    return out


def unit(v):
    v = np.asarray(v, dtype=float)
    return v / np.linalg.norm(v)


def frame(right, up, at):
    m = np.eye(4)
    m[:3, 0], m[:3, 1], m[:3, 2], m[:3, 3] = right, up, np.cross(right, up), at
    return m


def sword_points(name):
    """The mesh at its size in the game, in the part's own space, and the grip's frame there."""
    art = SWORDS[name]
    mesh = MESHES[name]
    v = np.array(mesh["v"], dtype=float)
    mesh_size = v.max(0) - v.min(0)
    scale = art["Length"] / mesh_size[1]
    size = mesh_size * scale
    v = v * scale
    up = unit(art["Up"])
    spine = np.asarray(art["Spine"], dtype=float)
    spine = unit(spine - up * up.dot(spine))
    grip = frame(spine, up, np.asarray(art["Grip"]) * size)
    return v, mesh["f"], grip, size


CACHE = {}


def sword(name):
    if name not in CACHE:
        CACHE[name] = sword_points(name)
    return CACHE[name]


def pose_mount(grip, pose, shoulder=SHOULDER, reach=REACH):
    hand, along, turn = (np.asarray(pose[k], dtype=float) for k in ("Hand", "Along", "Turn"))
    a = unit(along)
    out = -unit(turn - a * a.dot(turn))
    return frame(out, a, shoulder + hand * reach) @ np.linalg.inv(grip)


def pose_frame(pose, shoulder=SHOULDER, reach=REACH):
    """Where the grip is for a pose: blended in this space, a swing moves the hand in a line and turns about it."""
    hand, along, turn = (np.asarray(pose[k], dtype=float) for k in ("Hand", "Along", "Turn"))
    a = unit(along)
    out = -unit(turn - a * a.dot(turn))
    return frame(out, a, shoulder + hand * reach)


def place(m, v):
    return v @ m[:3, :3].T + m[:3, 3]


def box(at, size):
    at, size = np.asarray(at, dtype=float), np.asarray(size, dtype=float) / 2
    v = [at + size * (x, y, z) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return np.array(v), [list(x) for x in f]


def armour_piece(skill, name, at=(0, 0, 0)):
    data = ARMOUR[skill][name]
    return np.array(data["v"], dtype=float) + np.asarray(at, dtype=float), data["f"]


def rotation_y(deg):
    r = math.radians(deg)
    m = np.eye(4)
    m[0, 0], m[0, 2], m[2, 0], m[2, 2] = math.cos(r), math.sin(r), -math.sin(r), math.cos(r)
    return m


def translate(p):
    m = np.eye(4)
    m[:3, 3] = p
    return m


def shield_rest():
    """ShieldModel.luau: from the left shoulder, hanging."""
    grip = translate((0.05, -0.05, 0.75))
    at = LEFT_SHOULDER + np.array((-0.1, -0.74, -0.34)) * REACH
    return translate(at) @ rotation_y(62) @ np.linalg.inv(grip)


def shield_raised():
    return translate((-0.35, 0.15, -1.75)) @ rotation_y(6)


def shield_mesh(which):
    data = MESHES["Shield"]
    v = np.array(data["v"], dtype=float)
    scale = 3.7 / (v.max(0) - v.min(0))[1]
    return place(which, v * scale), data["f"]


def swept_head(v, f):
    """What's on the head, in the head's space, everywhere the head goes as it looks around."""
    verts, faces, base = [], [], 0
    from_neck = HEAD_AT - NECK
    for yaw in HEAD_YAWS:
        for pitch in HEAD_PITCHES:
            a, b = math.radians(yaw), math.radians(pitch)
            turn = np.array(((math.cos(a), 0, math.sin(a)), (0, 1, 0), (-math.sin(a), 0, math.cos(a))))
            tip = np.array(((1, 0, 0), (0, math.cos(b), -math.sin(b)), (0, math.sin(b), math.cos(b))))
            r = turn @ tip
            verts.append((np.asarray(v) * HEAD_ROOM) @ r.T + NECK + r @ from_neck)
            faces.extend([[i + base for i in x] for x in f])
            base += len(v)
    return np.vstack(verts), faces


def bare_body():
    """The body with no armour: boxes the size of the real parts."""
    return {
        "Head": swept_head(*box((0, 0, 0), np.array((1.11, 1.12, 1.12)))),
        "Chest": box((0, 0, 0), (1.54, 1.84, 1.01)),
        "Hips": box(HIPS_AT, (1.42, 0.59, 0.97)),
        "LeftUpper": box(LEFT_UPPER_AT, (0.81, 1.18, 0.71)),
        "LeftLower": box(LEFT_LOWER_AT, (0.70, 1.13, 0.84)),
    }


def armoured(skill):
    """A whole set, as far as a sword can reach it. The right arm moves with the hand, so it's checked apart."""
    return {
        "Helmet": swept_head(*armour_piece(skill, "Helmet")),
        "Chest": armour_piece(skill, "Chest"),
        "PauldronRight": armour_piece(skill, "PauldronRight"),
        "PauldronLeft": armour_piece(skill, "PauldronLeft"),
        "Hips": armour_piece(skill, "Hips", HIPS_AT),
        "SleeveLeft": armour_piece(skill, "SleeveLeft", LEFT_UPPER_AT),
        "ForearmLeft": armour_piece(skill, "ForearmLeft", LEFT_LOWER_AT),
        "ThighRight": armour_piece(skill, "ThighRight", THIGH_R_AT),
        "ThighLeft": armour_piece(skill, "ThighLeft", THIGH_L_AT),
    }


def tree_of(v, f):
    return BVHTree.FromPolygons([tuple(p) for p in v], [tuple(x) for x in f], all_triangles=False)


def extras():
    return {"ShieldRest": shield_mesh(shield_rest()), "ShieldRaised": shield_mesh(shield_raised())}


def all_obstacles():
    """Every obstacle by set, then by name."""
    sets = {"Bare": bare_body()}
    for skill in ARMOUR:
        sets[skill] = armoured(skill)
    sets["Gear"] = extras()
    return sets


def union_tree(sets, include=None, leave_out=()):
    verts, faces, base = [], [], 0
    for set_name, parts in sets.items():
        if include and set_name not in include:
            continue
        for part_name, (v, f) in parts.items():
            if part_name in leave_out:
                continue
            verts.append(v)
            faces.extend([[i + base for i in x] for x in f])
            base += len(v)
    return tree_of(np.vstack(verts), faces)


def nearest(tree, points):
    best = 1e9
    where = None
    for p in points:
        hit = tree.find_nearest(tuple(p))
        if hit[0] is not None and hit[3] < best:
            best, where = hit[3], p
    return best, where


def lerp_frame(a, b, t):
    """CFrame:Lerp: straight line for the place, shortest turn for the rotation."""
    from mathutils import Matrix

    qa = Matrix(a[:3, :3].tolist()).to_quaternion()
    qb = Matrix(b[:3, :3].tolist()).to_quaternion()
    q = qa.slerp(qb, t)
    m = np.eye(4)
    m[:3, :3] = np.array(q.to_matrix())
    m[:3, 3] = a[:3, 3] * (1 - t) + b[:3, 3] * t
    return m


def swing_frames(rest_mount, key_mounts, steps=8):
    """The mounts a swing passes through, the way HeldController's swungMount eases them. Last key is home."""
    frames = []
    from_m = rest_mount
    for index, mount in enumerate(key_mounts):
        to = rest_mount if index == len(key_mounts) - 1 else mount
        for step in range(1, steps + 1):
            t = step / steps
            frames.append((index + 1, step, lerp_frame(from_m, to, 1 - (1 - t) * (1 - t))))
        from_m = to
    return frames
