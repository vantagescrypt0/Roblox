"""Store art for Skycore: the game icon and the thumbnails, as composed 3D artwork (not
screenshots). Each scene is built from the game's own block and item meshes (Blocks.blend,
Items.blend), so everything shown is what's in the game, then lit and rendered with Cycles.
Finishing is done here with numpy: a soft glow, then the logo and captions in the game's
chunky pixel lettering (the same letters as Util/Logo.luau).

Outputs: art/marketing/icon.png (512) and thumb<n>_<name>.png (1920x1080).

Run:
  blender --background --factory-startup --python art/scripts/store_art.py -- icon thumb2
  blender --background --factory-startup --python art/scripts/store_art.py -- all
  add "preview" for a quick half-size pass into art/renders/store_*.png
"""

import math
import os
import random
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector, noise

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
from lowpoly import Builder  # noqa: E402

OUT_DIR = os.path.join(common.ART_DIR, "marketing")
SIZE = 3.0  # studs per block
SEE_THROUGH = {"Leaves", "BirchLeaves", "SpruceLeaves", "CherryLeaves", "AutumnLeaves"}


def linear(hex_color):
    """#rrggbb to linear RGB, for materials and lights"""
    srgb = [int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb)


# Assets ---------------------------------------------------------------------------------


class Assets:
    def __init__(self):
        self.blocks, self.items = {}, {}
        path = os.path.join(common.BLEND_DIR, "Blocks.blend")
        with bpy.data.libraries.load(path, link=False) as (source, target):
            target.objects = [name for name in source.objects if name.startswith("Block_")]
        for obj in target.objects:
            self.blocks[obj.name.removeprefix("Block_")] = obj.data
        path = os.path.join(common.BLEND_DIR, "Items.blend")
        with bpy.data.libraries.load(path, link=False) as (source, target):
            target.objects = list(source.objects)
        for obj in target.objects:
            if obj.type == "MESH":
                self.items[obj.name] = obj.data


def flat(name, color, roughness=0.65):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*linear(color), 1)
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def glow(name, color, strength=3.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*linear(color), 1)
    bsdf.inputs["Roughness"].default_value = 0.2
    bsdf.inputs["Emission Color"].default_value = (*linear(color), 1)
    bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def gem(name, color, strength=0.55):
    """A crystal that still shows its facets: lit like a solid, glossy, glowing from inside"""
    mat = glow(name, color, strength)
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.12
    bsdf.inputs["Coat Weight"].default_value = 1.0
    return mat


def add_mesh(name, bm, mat, smooth=False):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = smooth
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def box(name, size, location, mat, rotation=(0, 0, 0), parent=None, bevel=0.0):
    bm = bmesh.new()
    verts = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Diagonal((*size, 1)))["verts"]
    if bevel:
        edges = list({e for v in verts for e in v.link_edges})
        bmesh.ops.bevel(bm, geom=edges, offset=bevel, segments=2, affect="EDGES", profile=0.5)
    obj = add_mesh(name, bm, mat)
    obj.location = location
    obj.rotation_euler = [math.radians(a) for a in rotation]
    if parent:
        obj.parent = parent
    return obj


class Vox:
    """A grid of the game's blocks. Only cells that can be seen become objects (each shares
    its block's mesh, so a big scene stays cheap)."""

    def __init__(self, assets):
        self.assets = assets
        self.cells = {}

    def set(self, x, y, z, block):
        self.cells[(x, y, z)] = block

    def clear(self, x, y, z):
        self.cells.pop((x, y, z), None)

    def build(self):
        collection = bpy.data.collections.new("Voxels")
        bpy.context.scene.collection.children.link(collection)
        count = 0
        for (x, y, z), block in self.cells.items():
            shown = False
            for dx, dy, dz in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)):
                other = self.cells.get((x + dx, y + dy, z + dz))
                if other is None or other in SEE_THROUGH:
                    shown = True
                    break
            if shown:
                obj = bpy.data.objects.new(block, self.assets.blocks.get(block) or self.assets.blocks["Stone"])
                obj.location = (x * SIZE, y * SIZE, z * SIZE)
                collection.objects.link(obj)
                count += 1
        print(f"voxels: {count} of {len(self.cells)}")


def item(assets, name, location, rotation=(0, 0, 0), scale=1.0):
    obj = bpy.data.objects.new(name, assets.items[name])
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = [math.radians(a) for a in rotation]
    obj.scale = (scale, scale, scale)
    return obj


# Land -----------------------------------------------------------------------------------


def n2(x, y, scale, salt):
    return noise.noise(Vector((x / scale, y / scale, salt * 3.7)))


def island(v, cx, cy, radius, top="Grass", soil="Dirt", rock="Stone", depth=None, hill=0, seed=1, ores=(), base=0):
    """A floating island like the game's: a rough outline, soil over rock, a hanging cone of
    stone. Returns each column's top height."""
    rng = random.Random(seed)
    depth = depth or int(radius * 0.9)
    tops = {}
    reach = int(radius * 1.3)
    for x in range(cx - reach, cx + reach + 1):
        for y in range(cy - reach, cy + reach + 1):
            dx, dy = x - cx, y - cy
            angle = math.atan2(dy, dx)
            edge = radius * (1 + 0.12 * math.sin(3 * angle + seed) + 0.07 * math.sin(7 * angle + seed * 2))
            d = math.hypot(dx, dy)
            if d > edge:
                continue
            t = d / edge
            height = base
            if hill:
                height += int(hill * (1 - t) ** 1.2 * (0.6 + 0.8 * (n2(x, y, 7, seed) + 0.5)))
            hang = depth * max(1 - t**1.6, 0) ** 0.85 * (0.72 + 0.6 * (n2(x, y, 5, seed + 9) + 0.5))
            bottom = base - max(1, int(hang))
            for z in range(bottom, height + 1):
                if z == height:
                    block = top
                elif z >= height - 2:
                    block = soil
                else:
                    block = rock
                    for ore, chance in ores:
                        if rng.random() < chance:
                            block = ore
                            break
                v.set(x, y, z, block)
            tops[(x, y)] = height
    return tops


def tree(v, x, y, z, height=6, log="Wood", leaf="Leaves", radius=3, seed=1):
    rng = random.Random(seed + x * 31 + y * 17)
    for dz in range(1, height + 1):
        v.set(x, y, z + dz, log)
    top = z + height
    for dx in range(-radius, radius + 1):
        for dy in range(-radius, radius + 1):
            for dz in range(-1, radius + 1):
                d = math.sqrt(dx * dx + dy * dy + (dz * 1.3) ** 2)
                if d <= radius + 0.3 and not (d > radius - 0.8 and rng.random() < 0.3):
                    if (x + dx, y + dy, top + dz) not in v.cells:
                        v.set(x + dx, y + dy, top + dz, leaf)


def shard_mesh(mat):
    """A crystal shard one stud tall and about 0.25 wide, sitting on the origin: six flat
    sides and a pointed tip"""
    bm = bmesh.new()
    rings = []
    for z, r in ((0.0, 0.8), (0.72, 1.0)):
        rings.append([bm.verts.new((math.cos(i / 6 * math.tau) * r * 0.25, math.sin(i / 6 * math.tau) * r * 0.25, z)) for i in range(6)])
    tip = bm.verts.new((0, 0, 1.0))
    for i in range(6):
        j = (i + 1) % 6
        bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
        bm.faces.new((rings[1][i], rings[1][j], tip))
    bm.faces.new(list(reversed(rings[0])))
    mesh = bpy.data.meshes.new("Shard")
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mat)
    return mesh


def crystals(mesh, location, count, height, seed=1, spread=0.55, down=False, scatter=1.0):
    """A burst of shards leaning out from `location`: a big one in the middle, smaller round it"""
    rng = random.Random(seed)
    for i in range(count):
        h = height * (1.0 if i == 0 else rng.uniform(0.35, 0.75))
        tilt = 0 if i == 0 else rng.uniform(0.18, spread)
        turn = rng.uniform(0, math.tau)
        rot = Euler((math.sin(turn) * tilt, math.cos(turn) * tilt, rng.uniform(0, 6)))
        if down:
            rot = Euler((math.pi + rot.x, rot.y, rot.z))
        obj = bpy.data.objects.new("Shard", mesh)
        bpy.context.scene.collection.objects.link(obj)
        offset = Vector((math.cos(turn), math.sin(turn), 0)) * (0 if i == 0 else rng.uniform(0.3, 1.0)) * height * 0.13 * scatter
        obj.location = Vector(location) + offset
        obj.rotation_euler = rot
        width = h * rng.uniform(0.95, 1.25)
        obj.scale = (width, width, h)


def puff(location, radius, mat, seed=1, squash=0.6, lobes=7):
    """A soft cartoon cloud: a cluster of smooth balls"""
    rng = random.Random(seed)
    bm = bmesh.new()
    for i in range(lobes):
        a = i / lobes * math.tau + rng.uniform(-0.3, 0.3)
        d = rng.uniform(0.15, 0.85) * radius
        r = rng.uniform(0.45, 0.8) * radius * (1 - d / radius * 0.45)
        at = Matrix.Translation((math.cos(a) * d * 1.5, math.sin(a) * d * 0.7, rng.uniform(0, 0.35) * radius)) @ Matrix.Diagonal((r, r, r * squash * 1.2, 1))
        bmesh.ops.create_icosphere(bm, subdivisions=3, radius=1.0, matrix=at)
    obj = add_mesh("Cloud", bm, mat, smooth=True)
    obj.location = location
    return obj


def waterfall(x, y, top, bottom, width, seed=1, mat=None, foam=None):
    """Water pouring straight down, in studs: a sheet with lighter streaks"""
    rng = random.Random(seed)
    mid = (top + bottom) / 2
    box("Fall", (width, 1.0, top - bottom), (x, y, mid), mat)
    for _ in range(int(width * 1.6)):
        sx = x + rng.uniform(-width / 2, width / 2)
        length = rng.uniform(0.25, 0.6) * (top - bottom)
        sz = rng.uniform(bottom + length / 2, top - length / 2)
        box("Streak", (rng.uniform(0.25, 0.6), 0.2, length), (sx, y - 0.55, sz), foam)


# The hero ---------------------------------------------------------------------------------


def face_parts(root, face, gaze, dark, white):
    """The hero's expression, on the front of the head"""
    gx, gz = gaze
    red = flat("Tongue", "#c8343c", 0.5)

    def part(name, size, x, z, mat, tilt=0, y=-0.74):
        box(name, size, (x, y, z), mat, rotation=(0, tilt, 0), parent=root)

    for sx in (-0.33, 0.33):
        side = 1 if sx > 0 else -1
        if face == "friendly":
            part("EyeW", (0.34, 0.04, 0.42), sx, 4.85, white)
            part("Eye", (0.2, 0.05, 0.3), sx + 0.03, 4.82, dark, y=-0.765)
            part("GrinEnd", (0.09, 0.04, 0.12), sx, 4.5, dark)
        elif face == "shock":
            part("EyeW", (0.46, 0.04, 0.6), sx, 4.93, white)
            part("Eye", (0.15, 0.05, 0.19), sx + gx, 4.91 + gz, dark, y=-0.765)
            part("Brow", (0.5, 0.05, 0.11), sx, 5.32, dark, tilt=14 * side)
        elif face == "huge":
            part("EyeW", (0.42, 0.04, 0.5), sx, 4.94, white)
            part("Eye", (0.23, 0.05, 0.31), sx + gx, 4.91 + gz, dark, y=-0.765)
            part("Shine", (0.08, 0.06, 0.08), sx + gx + 0.05, 5.0 + gz, white, y=-0.785)
            part("Brow", (0.46, 0.05, 0.1), sx, 5.3, dark, tilt=-10 * side)
            part("SmileEnd", (0.11, 0.04, 0.14), sx * 1.52, 4.53, dark)
        elif face == "angry":
            part("EyeW", (0.44, 0.04, 0.3), sx, 4.88, white)
            part("Eye", (0.16, 0.05, 0.22), sx + gx, 4.86 + gz, dark, y=-0.765)
            part("Brow", (0.58, 0.06, 0.17), sx, 5.08, dark, tilt=-22 * side, y=-0.77)
        elif face == "worried":
            part("EyeW", (0.42, 0.04, 0.52), sx, 4.9, white)
            part("Eye", (0.15, 0.05, 0.2), sx + gx, 4.86 + gz, dark, y=-0.765)
            part("Brow", (0.46, 0.05, 0.1), sx, 5.28, dark, tilt=18 * side)
            part("FrownEnd", (0.09, 0.04, 0.1), sx * 0.76, 4.36, dark)
    if face == "friendly":
        part("Grin", (0.62, 0.04, 0.09), 0, 4.42, dark)
    elif face == "shock":
        part("Mouth", (0.6, 0.04, 0.5), 0, 4.33, dark)
        part("Tongue", (0.4, 0.05, 0.15), 0, 4.16, red, y=-0.765)
        part("Teeth", (0.52, 0.05, 0.1), 0, 4.52, white, y=-0.765)
    elif face == "huge":
        part("Mouth", (0.92, 0.04, 0.36), 0, 4.38, dark)
        part("Teeth", (0.84, 0.05, 0.14), 0, 4.49, white, y=-0.765)
        part("Tongue", (0.5, 0.05, 0.12), 0, 4.27, red, y=-0.765)
    elif face == "angry":
        part("Mouth", (0.76, 0.04, 0.32), 0, 4.36, dark)
        part("Teeth", (0.68, 0.05, 0.22), 0, 4.36, white, y=-0.765)
        part("TeethLine", (0.68, 0.055, 0.03), 0, 4.36, dark, y=-0.78)
        for x in (-0.22, 0, 0.22):
            part("TeethGap", (0.03, 0.055, 0.22), x, 4.36, dark, y=-0.78)
    elif face == "worried":
        part("Frown", (0.46, 0.04, 0.09), 0, 4.42, dark)
        part("Sweat", (0.14, 0.06, 0.26), 0.66, 5.14, glow("Sweat", "#8fdcff", 1.2), y=-0.77)


def hero(assets, location, yaw=0, shirt="#2f6fdc", pants="#27324f", skin="#f4c38f", hair="#4b2e1e", hat=None, tool=None, swing=-115, scale=1.0, tool_scale=1.25, off_arm=-18, face="friendly", gaze=(0, 0), shoulders=None, mirror=False):
    """A blocky adventurer (facing -Y before `yaw`), one arm raised with a tool"""
    root = bpy.data.objects.new("Hero", None)
    bpy.context.scene.collection.objects.link(root)
    root.location = location
    root.rotation_euler = (0, 0, math.radians(yaw))
    root.scale = (-scale if mirror else scale, scale, scale)
    skin_m, shirt_m, pants_m = flat("Skin", skin), flat("Shirt", shirt), flat("Pants", pants)
    dark = flat("Dark", "#1c1a24", 0.3)
    white = flat("EyeWhite", "#ffffff", 0.4)
    # Legs, torso, head
    box("Leg", (0.95, 0.95, 2.0), (-0.52, 0, 1.0), pants_m, parent=root, bevel=0.06)
    box("Leg", (0.95, 0.95, 2.0), (0.52, 0, 1.0), pants_m, parent=root, bevel=0.06)
    box("Shoe", (1.0, 1.1, 0.35), (-0.52, -0.06, 0.17), dark, parent=root, bevel=0.06)
    box("Shoe", (1.0, 1.1, 0.35), (0.52, -0.06, 0.17), dark, parent=root, bevel=0.06)
    box("Torso", (2.05, 1.0, 2.0), (0, 0, 3.0), shirt_m, parent=root, bevel=0.08)
    box("Belt", (2.08, 1.04, 0.25), (0, 0, 2.15), dark, parent=root)
    box("Head", (1.5, 1.45, 1.4), (0, 0, 4.75), skin_m, parent=root, bevel=0.14)
    face_parts(root, face, gaze, dark, white)
    if shoulders:
        plate, trim = flat("Plate" + shoulders, shoulders, 0.35), flat("PlateTrim", "#f4c542", 0.3)
        for sx in (-1.52, 1.52):
            box("Shoulder", (1.3, 1.3, 0.62), (sx, 0, 4.12), plate, parent=root, bevel=0.08)
            box("ShoulderTrim", (1.34, 1.34, 0.14), (sx, 0, 3.86), trim, parent=root)
    if hat == "miner":
        box("Helmet", (1.68, 1.62, 0.62), (0, 0, 5.5), flat("Helmet", "#f6c21c", 0.35), parent=root, bevel=0.14)
        box("Brim", (1.8, 0.45, 0.14), (0, -0.9, 5.25), flat("HelmetDark", "#d99a10", 0.35), parent=root)
        box("Lamp", (0.45, 0.2, 0.42), (0, -0.92, 5.55), glow("Lamp", "#fff4b0", 9), parent=root, bevel=0.04)
    elif hat == "straw":
        straw = flat("Straw", "#e8c75c", 0.8)
        box("Brim", (2.6, 2.6, 0.13), (0, 0, 5.42), straw, parent=root, bevel=0.05)
        box("Crown", (1.5, 1.5, 0.6), (0, 0, 5.72), straw, parent=root, bevel=0.1)
        box("Band", (1.54, 1.54, 0.16), (0, 0, 5.54), flat("Band", "#c83a30"), parent=root)
    elif hat == "beanie":
        wool = flat("Wool", "#d8362c", 0.9)
        box("Beanie", (1.62, 1.56, 0.6), (0, 0, 5.5), wool, parent=root, bevel=0.14)
        box("Cuff", (1.68, 1.62, 0.22), (0, 0, 5.2), flat("WoolDark", "#a92720", 0.9), parent=root, bevel=0.04)
    else:
        box("Hair", (1.6, 1.55, 0.42), (0, 0.02, 5.42), flat("Hair", hair, 0.8), parent=root, bevel=0.1)
        box("Fringe", (1.6, 0.2, 0.24), (0, -0.72, 5.22), flat("Hair", hair, 0.8), parent=root)
    # The resting arm
    pivot = bpy.data.objects.new("ArmL", None)
    bpy.context.scene.collection.objects.link(pivot)
    pivot.parent = root
    pivot.location = (1.52, 0, 3.85)
    pivot.rotation_euler = (math.radians(off_arm), math.radians(-14), 0)
    box("Arm", (0.95, 0.95, 2.0), (0, 0, -0.9), shirt_m, parent=pivot, bevel=0.06)
    box("Hand", (0.9, 0.9, 0.5), (0, 0, -1.75), skin_m, parent=pivot, bevel=0.06)
    # The arm with the tool, raised forward
    pivot = bpy.data.objects.new("ArmR", None)
    bpy.context.scene.collection.objects.link(pivot)
    pivot.parent = root
    pivot.location = (-1.52, 0, 3.85)
    pivot.rotation_euler = (math.radians(swing), math.radians(10), 0)
    box("Arm", (0.95, 0.95, 2.0), (0, 0, -0.9), shirt_m, parent=pivot, bevel=0.06)
    box("Hand", (0.9, 0.9, 0.5), (0, 0, -1.75), skin_m, parent=pivot, bevel=0.06)
    if tool:
        held = bpy.data.objects.new(tool, assets.items[tool])
        bpy.context.scene.collection.objects.link(held)
        held.parent = pivot
        # Tools are modelled tilted 45 degrees from a handle at the origin: stand it in the hand
        held.matrix_parent_inverse = Matrix.Identity(4)
        held.matrix_basis = (
            Matrix.Translation((0, 0, -1.8))
            @ Matrix.Rotation(math.radians(90), 4, "X")
            @ Matrix.Diagonal((tool_scale, tool_scale, tool_scale, 1))
            @ Matrix.Rotation(math.radians(-45), 4, "Y")
            @ Matrix.Translation((0, 0, -0.75))
        )
    return root


# Stage -------------------------------------------------------------------------------------


def sky(top, horizon, below=None, strength=1.0):
    """A soft vertical gradient behind everything, also the fill light"""
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    tree_ = world.node_tree
    background = tree_.nodes["Background"]
    coord = tree_.nodes.new("ShaderNodeTexCoord")
    split = tree_.nodes.new("ShaderNodeSeparateXYZ")
    ramp = tree_.nodes.new("ShaderNodeValToRGB")
    tree_.links.new(coord.outputs["Generated"], split.inputs[0])
    remap = tree_.nodes.new("ShaderNodeMapRange")
    remap.inputs["From Min"].default_value = -1
    remap.inputs["From Max"].default_value = 1
    tree_.links.new(split.outputs["Z"], remap.inputs["Value"])
    tree_.links.new(remap.outputs["Result"], ramp.inputs["Fac"])
    ramp.color_ramp.elements[0].position = 0.3
    ramp.color_ramp.elements[0].color = (*linear(below or horizon), 1)
    ramp.color_ramp.elements[1].position = 0.78
    ramp.color_ramp.elements[1].color = (*linear(top), 1)
    middle = ramp.color_ramp.elements.new(0.5)
    middle.color = (*linear(horizon), 1)
    tree_.links.new(ramp.outputs["Color"], background.inputs["Color"])
    background.inputs["Strength"].default_value = strength
    bpy.context.scene.world = world


def sun(direction, color="#fff1d6", energy=4.0, angle=6):
    data = bpy.data.lights.new("Sun", "SUN")
    data.energy = energy
    data.color = linear(color)
    data.angle = math.radians(angle)
    obj = bpy.data.objects.new("Sun", data)
    bpy.context.scene.collection.objects.link(obj)
    obj.rotation_euler = Vector(direction).to_track_quat("Z", "Y").to_euler()


def lamp(location, color, power, radius=2.0):
    data = bpy.data.lights.new("Lamp", "POINT")
    data.energy = power
    data.color = linear(color)
    data.shadow_soft_size = radius
    obj = bpy.data.objects.new("Lamp", data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location


def camera(location, target, lens=35):
    data = bpy.data.cameras.new("Camera")
    data.lens = lens
    data.sensor_width = 36
    data.clip_end = 5000
    obj = bpy.data.objects.new("Camera", data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target) - Vector(location)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = obj
    return obj


def render(path, width, height, samples, transparent=False):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.compute_device_type = "OPTIX"
    prefs.get_devices()
    for device in prefs.devices:
        device.use = device.type == "OPTIX"
    scene.cycles.device = "GPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 6
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.render.film_transparent = transparent
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


# Finishing ----------------------------------------------------------------------------------


def read_image(path):
    image = bpy.data.images.load(path, check_existing=False)
    w, h = image.size
    pixels = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(pixels)
    bpy.data.images.remove(image)
    return pixels.reshape(h, w, 4)[::-1].copy()  # top row first


def write_image(array, path):
    h, w = array.shape[:2]
    image = bpy.data.images.new("Out", w, h, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(array[::-1], dtype=np.float32).ravel())
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)


def blur(a, radius):
    """A soft blur: three box passes along each axis"""
    r = max(1, int(radius))
    out = a
    for axis in (0, 1):
        for _ in range(3):
            total = np.cumsum(out, axis=axis)
            pad = np.take(total, [0], axis=axis) * 0
            total = np.concatenate([pad, total], axis=axis)
            n = out.shape[axis]
            hi = np.clip(np.arange(n) + r + 1, 0, n)
            lo = np.clip(np.arange(n) - r, 0, n)
            count = (hi - lo).reshape([-1 if i == axis else 1 for i in range(out.ndim)])
            out = (np.take(total, hi, axis=axis) - np.take(total, lo, axis=axis)) / count
    return out


def finish(image, bloom=0.55, threshold=0.78, vignette=0.22, saturation=1.1):
    rgb = image[..., :3].copy()
    h, w = rgb.shape[:2]
    # A soft glow round everything bright, wide and tight together
    # (only from what's really bright, so a pale sky doesn't wash everything out)
    luma = (rgb * np.array([0.3, 0.59, 0.11], dtype=np.float32)).sum(axis=2, keepdims=True)
    bright = rgb * np.clip((luma - threshold) / (1 - threshold), 0, 1)
    small = bright[::4, ::4]
    wide = blur(small, w / 80)
    tight = blur(small, w / 300)
    glow_map = np.repeat(np.repeat(wide * 0.6 + tight * 0.7, 4, axis=0), 4, axis=1)[:h, :w]
    glow_map = blur(glow_map, 3)
    rgb = 1 - (1 - rgb) * (1 - np.clip(glow_map * bloom, 0, 1))
    grey = rgb.mean(axis=2, keepdims=True)
    rgb = np.clip(grey + (rgb - grey) * saturation, 0, 1)
    if vignette:
        yy, xx = np.mgrid[0:h, 0:w]
        d = np.hypot((xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2)) / math.sqrt(2)
        rgb *= (1 - vignette * np.clip(d - 0.45, 0, 1) ** 2 * 3)[..., None]
    return np.dstack([np.clip(rgb, 0, 1), image[..., 3]])


FONT = {
    "A": ".####. ###### ##..## ##..## ###### ###### ##..## ##..## ##..## ##..##",
    "B": "#####. ###### ##..## ##..## #####. ###### ##..## ##..## ###### #####.",
    "C": ".##### ###### ##.... ##.... ##.... ##.... ##.... ##.... ###### .#####",
    "D": "#####. ###### ##..## ##..## ##..## ##..## ##..## ##..## ###### #####.",
    "E": "###### ###### ##.... ##.... #####. #####. ##.... ##.... ###### ######",
    "F": "###### ###### ##.... ##.... #####. #####. ##.... ##.... ##.... ##....",
    "G": ".##### ###### ##.... ##.... ##.### ##.### ##..## ##..## ###### .#####",
    "H": "##..## ##..## ##..## ##..## ###### ###### ##..## ##..## ##..## ##..##",
    "I": "###### ###### ..##.. ..##.. ..##.. ..##.. ..##.. ..##.. ###### ######",
    "J": "..#### ..#### ....## ....## ....## ....## ....## ##..## ###### .####.",
    "K": "##..## ##..## ##.##. ####.. ###... ###... ####.. ##.##. ##..## ##..##",
    "L": "##.... ##.... ##.... ##.... ##.... ##.... ##.... ##.... ###### ######",
    "M": "#....# ##..## ###### ###### ##..## ##..## ##..## ##..## ##..## ##..##",
    "N": "##..## ###.## ###.## ###### ###### ##.### ##.### ##..## ##..## ##..##",
    "O": ".####. ###### ##..## ##..## ##..## ##..## ##..## ##..## ###### .####.",
    "P": "#####. ###### ##..## ##..## ###### #####. ##.... ##.... ##.... ##....",
    "Q": ".####. ###### ##..## ##..## ##..## ##..## ##.### ##.### ###### .#####",
    "R": "#####. ###### ##..## ##..## #####. ####.. ##.##. ##.##. ##..## ##..##",
    "S": ".##### ###### ##.... ##.... #####. .##### ....## ....## ###### #####.",
    "T": "###### ###### ..##.. ..##.. ..##.. ..##.. ..##.. ..##.. ..##.. ..##..",
    "U": "##..## ##..## ##..## ##..## ##..## ##..## ##..## ##..## ###### .####.",
    "V": "##..## ##..## ##..## ##..## ##..## ##..## .####. .####. ..##.. ..##..",
    "W": "##..## ##..## ##..## ##..## ##..## ###### ###### ###### ##..## #....#",
    "X": "##..## ##..## .####. .####. ..##.. ..##.. .####. .####. ##..## ##..##",
    "Y": "##..## ##..## ##..## ###### .####. ..##.. ..##.. ..##.. ..##.. ..##..",
    "Z": "###### ###### ....## ...##. ..##.. .##... ##.... ##.... ###### ######",
    "&": ".###.. ##.##. ##.##. .###.. .##... ###.## ##.### ##..## ###### .###.#",
    "!": "..##.. ..##.. ..##.. ..##.. ..##.. ..##.. ...... ...... ..##.. ..##..",
    "?": ".####. ###### ##..## ....## ...##. ..##.. ..##.. ...... ..##.. ..##..",
    "0": ".####. ###### ##..## ##.### ##.### ###.## ###.## ##..## ###### .####.",
    "1": "..##.. .###.. ####.. ..##.. ..##.. ..##.. ..##.. ..##.. ###### ######",
    "2": ".####. ###### ##..## ....## ...##. ..##.. .##... ##.... ###### ######",
    "3": "#####. ###### ....## ....## .####. .####. ....## ....## ###### #####.",
    "4": "##..## ##..## ##..## ##..## ###### ###### ....## ....## ....## ....##",
    "5": "###### ###### ##.... ##.... #####. ###### ....## ....## ###### #####.",
    "6": ".##### ###### ##.... ##.... #####. ###### ##..## ##..## ###### .####.",
    "7": "###### ###### ....## ...##. ...##. ..##.. ..##.. ..##.. ..##.. ..##..",
    "8": ".####. ###### ##..## ##..## .####. .####. ##..## ##..## ###### .####.",
    "9": ".####. ###### ##..## ##..## ###### .##### ....## ....## ###### #####.",
}
FONT = {letter: rows.split(" ") for letter, rows in FONT.items()}
GLYPH_W, GLYPH_H, GAP, SPACE = 6, 10, 2, 4
OUTLINE = (26 / 255, 32 / 255, 68 / 255)


def word_width(text):
    columns = 0
    for ch in text:
        columns += SPACE + GAP if ch == " " else GLYPH_W + GAP
    return columns - GAP


def word_mask(text):
    mask = np.zeros((GLYPH_H, word_width(text)), dtype=bool)
    x = 0
    for ch in text:
        if ch == " ":
            x += SPACE + GAP
            continue
        for r, row in enumerate(FONT[ch]):
            for c, cell in enumerate(row):
                if cell == "#":
                    mask[r, x + c] = True
        x += GLYPH_W + GAP
    return mask


def rgb255(hex_color):
    return np.array([int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5)], dtype=np.float32)


def stamp(image, text, x, y, pixel, runs, outline=None, shadow=None):
    """Draws pixel letters onto the image, top left at (x, y). `runs` colours the word:
    a list of (letter count, top colour, bottom colour), so "SKY" and "CORE" can differ."""
    outline = pixel if outline is None else outline
    shadow = pixel if shadow is None else shadow
    mask = np.kron(word_mask(text), np.ones((pixel, pixel), dtype=bool))
    pad = outline + shadow + 2
    h, w = mask.shape
    grown = np.zeros((h + pad * 2, w + pad * 2), dtype=bool)
    grown[pad:pad + h, pad:pad + w] = mask
    full = grown.copy()
    # A square outline, so it stays blocky like the letters
    edge = np.zeros_like(grown)
    for dy in range(-outline, outline + 1):
        for dx in range(-outline, outline + 1):
            edge |= np.roll(np.roll(full, dy, axis=0), dx, axis=1)
    back = np.roll(edge, shadow, axis=0)
    # Each column's colour run
    fill = np.zeros((*grown.shape, 3), dtype=np.float32)
    column, run_index, in_run = 0, 0, 0
    for ch in text:
        width = (SPACE if ch == " " else GLYPH_W) + GAP
        count, top, bottom = runs[min(run_index, len(runs) - 1)]
        top_c, bottom_c = rgb255(top), rgb255(bottom)
        for r in range(GLYPH_H * pixel):
            t = r / (GLYPH_H * pixel - 1)
            # Stepped gradient in chunks of a pixel, with a bright band along the top
            t = math.floor(t * GLYPH_H) / (GLYPH_H - 1)
            fill[pad + r, pad + column * pixel : pad + (column + width) * pixel] = top_c + (bottom_c - top_c) * t
        column += width
        if ch != " ":
            in_run += 1
        if in_run >= count:
            run_index, in_run = run_index + 1, 0
    # Onto the image
    x0, y0 = x - pad, y - pad
    ih, iw = image.shape[:2]
    gy, gx = np.nonzero(back | edge)
    keep = (gy + y0 >= 0) & (gy + y0 < ih) & (gx + x0 >= 0) & (gx + x0 < iw)
    gy, gx = gy[keep], gx[keep]
    image[gy + y0, gx + x0, :3] = 0
    image[gy + y0, gx + x0, 3] = 1
    # The shadow is near black, the outline navy
    ey, ex = np.nonzero(edge)
    keep = (ey + y0 >= 0) & (ey + y0 < ih) & (ex + x0 >= 0) & (ex + x0 < iw)
    ey, ex = ey[keep], ex[keep]
    image[ey + y0, ex + x0, :3] = OUTLINE
    my, mx = np.nonzero(grown)
    keep = (my + y0 >= 0) & (my + y0 < ih) & (mx + x0 >= 0) & (mx + x0 < iw)
    my, mx = my[keep], mx[keep]
    image[my + y0, mx + x0, :3] = fill[my, mx]
    return image


SKY_TOP, SKY_BOTTOM = "#c4f2ff", "#2e92ec"
CORE_TOP, CORE_BOTTOM = "#fff070", "#f68c1c"
LOGO_RUNS = [(3, SKY_TOP, SKY_BOTTOM), (4, CORE_TOP, CORE_BOTTOM)]


def logo(image, x, y, pixel):
    return stamp(image, "SKYCORE", x, y, pixel, LOGO_RUNS)


def caption(image, lines, x, y, pixel, align="left", gap=None):
    """Big words stacked. lines: (text, top colour, bottom colour, optional size multiple)"""
    gap = pixel * 3 if gap is None else gap
    h, w = image.shape[:2]
    at = y
    for line in lines:
        text, top, bottom = line[:3]
        p = int(pixel * (line[3] if len(line) > 3 else 1))
        width = word_width(text) * p
        left = x if align == "left" else (w - x - width if align == "right" else x - width // 2)
        stamp(image, text, left, at, p, [(len(text), top, bottom)])
        at += GLYPH_H * p + gap
    return image


def sunburst(width, height, center, inner, outer, ray, rays=18, spin=0.0):
    """A cartoon sunburst backdrop: soft radial glow with alternating rays"""
    yy, xx = np.mgrid[0:height, 0:width]
    dx, dy = xx - center[0], yy - center[1]
    d = np.hypot(dx, dy) / math.hypot(width, height)
    angle = np.arctan2(dy, dx) + spin
    stripes = (np.sin(angle * rays) > 0).astype(np.float32)[..., None]
    base = rgb255(inner) + (rgb255(outer) - rgb255(inner)) * np.clip(d * 2.0, 0, 1)[..., None]
    streak = rgb255(ray)
    fade = np.clip(1.1 - d * 2.0, 0, 1)[..., None]
    out = base + (streak - base) * stripes * fade * 0.28
    return np.dstack([out, np.ones((height, width), dtype=np.float32)])


def over(fg, bg):
    alpha = fg[..., 3:4]
    return np.dstack([fg[..., :3] * alpha + bg[..., :3] * (1 - alpha), np.ones(fg.shape[:2], dtype=np.float32)])


# Scenes ---------------------------------------------------------------------------------


class Stage:
    """What every scene shares"""

    def __init__(self):
        common.reset_scene()
        self.assets = Assets()
        self.v = Vox(self.assets)
        self.white = flat("CloudWhite", "#ffffff", 0.9)
        mat = self.white
        mat.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (*linear("#dceeff"), 1)
        mat.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.35
        self.water = glow("Water", "#2f9df2", 0.7)
        self.foam = glow("Foam", "#c9f0ff", 1.2)


def scene_icon(size, samples, tmp):
    """The island with its glowing core: a crystal bursting up through it and hanging below,
    a waterfall, trees, the logo across the bottom"""
    s = Stage()
    v = s.v
    tops = island(v, 0, 0, 15, depth=19, seed=3, hill=2, ores=(("GoldOre", 0.03), ("AmethystOre", 0.03), ("IronOre", 0.03), ("SapphireOre", 0.02)))
    tree(v, -9, -2, tops[(-9, -2)], 6, seed=2)
    tree(v, 9, 3, tops[(9, 3)], 5, "CherryWood", "CherryLeaves", seed=4)
    tree(v, -5, 8, tops[(-5, 8)], 5, seed=5)
    # A hole round the core, ringed with stone
    for x in range(-3, 4):
        for y in range(-3, 4):
            d = math.hypot(x, y)
            if d < 3.4:
                top = tops[(x, y)]
                v.set(x, y, top, "Runestone" if d > 2.2 else "DarkStone")
    v.build()
    core = shard_mesh(gem("CoreCrystal", "#27d3ff", 0.6))
    pale = shard_mesh(gem("CorePale", "#a8f4ff", 1.1))
    deep = shard_mesh(gem("CoreDeep", "#2a7bff", 0.7))
    crystals(core, (0, 0, tops[(0, 0)] * SIZE + 1), 11, 44, seed=4, spread=0.42, scatter=1.3)
    crystals(pale, (1, -2, tops[(0, 0)] * SIZE + 1), 4, 22, seed=7, spread=0.5)
    crystals(deep, (0, 0, -40), 7, 22, seed=9, down=True, spread=0.4)
    lamp((0, -6, 26), "#7fe8ff", 22000, 8)
    lamp((0, -14, -46), "#4aa8ff", 9000, 6)
    # A stream from the core out over the front right edge, and down
    edge_x = max(x for (x, y) in tops if y == -6)
    length = edge_x * SIZE - 4
    box("Stream", (length, 6, 0.6), (4 + length / 2, -6 * SIZE, 1.9), s.water)
    waterfall(edge_x * SIZE + 1, -6 * SIZE, 1.9, -86, 7, seed=2, mat=s.water, foam=s.foam)
    hero(s.assets, (-17, -30, tops[(-6, -10)] * SIZE + 1.6), yaw=24, tool="SapphirePickaxe", swing=-125, scale=2.6, shirt="#e8452c", pants="#2b3a67", tool_scale=1.5)
    # Islets and clouds
    v2 = Vox(s.assets)
    island(v2, -32, 12, 4, depth=5, seed=7, base=-9)
    island(v2, 31, 14, 3, depth=4, seed=9, base=-2)
    v2.build()
    for loc, r, seed in (((-70, 30, -62), 22, 1), ((70, 40, -56), 26, 2), ((-48, 60, 55), 18, 3), ((60, 70, 58), 16, 4)):
        puff(loc, r, s.white, seed=seed)
    sky("#0a46c8", "#2f9bff", below="#6fd2ff", strength=1.0)
    sun((-0.5, -0.7, 0.8), energy=3.8)
    camera((0, -178, 30), (0, 0, -5), lens=52)
    render(tmp, size, size, samples)
    image = finish(read_image(tmp), bloom=0.6, threshold=0.7, vignette=0.2, saturation=1.15)
    return image


def finish_icon(image, final):
    # Render at double size: scale down, then the logo crisp on top
    h = image.shape[0]
    if h > final:
        step = h // final
        image = image.reshape(final, step, final, step, 4).mean(axis=(1, 3))
    pixel = final // 64
    width = word_width("SKYCORE") * pixel
    logo(image, (final - width) // 2, final - GLYPH_H * pixel - pixel * 4, pixel)
    return image


def scene_island(w, h, samples, tmp):
    """Build your own sky island: a home, a farm, trees, a waterfall, floating among clouds"""
    s = Stage()
    v, a = s.v, s.assets
    tops = island(v, 0, 0, 30, depth=26, seed=6, hill=3, ores=(("IronOre", 0.02), ("CoalOre", 0.03), ("GoldOre", 0.01)))

    def top(x, y):
        return tops.get((x, y), 0)

    # The cottage
    fx, fy, fz = -12, 6, top(-12, 6)
    for x in range(fx - 5, fx + 6):
        for y in range(fy - 4, fy + 5):
            v.set(x, y, fz, "Planks")
            for dz in range(1, 5):
                edge = x in (fx - 5, fx + 5) or y in (fy - 4, fy + 4)
                if edge:
                    corner = x in (fx - 5, fx + 5) and y in (fy - 4, fy + 4)
                    v.set(x, y, fz + dz, "Wood" if corner else "Plaster")
    for i in range(0, 5):
        for x in range(fx - 6 + i, fx + 7 - i):
            for y in range(fy - 5, fy + 6):
                v.set(x, y, fz + 5 + i, "RoofRed")
    for x in (fx - 2, fx + 2):
        v.clear(x, fy - 4, fz + 3)
    v.clear(fx, fy - 4, fz + 1)
    v.clear(fx, fy - 4, fz + 2)
    v.set(fx + 4, fy - 4, fz + 2, "Plaster")
    # Beside it, the crafting table and furnace
    v.set(fx + 8, fy - 3, top(fx + 8, fy - 3) + 1, "CraftingTable")
    v.set(fx + 10, fy - 3, top(fx + 10, fy - 3) + 1, "Furnace")
    # The farm in front
    for x in range(6, 20):
        for y in range(-14, -4):
            if (x, y) in tops:
                tops[(x, y)] = top(x, y)
                v.set(x, y, top(x, y), "Farmland")
    # The stream's channel: dug down into flat ground
    for x in range(-20, -15):
        for y in range(-40, -5):
            if (x, y) in tops:
                for z in range(tops[(x, y)], 0, -1):
                    v.clear(x, y, z)
                tops[(x, y)] = 0
                if -19 <= x <= -17:
                    v.clear(x, y, 0)
                    tops[(x, y)] = -1
    # Trees
    for x, y, h_, log, leaf, r in (
        (-25, -2, 6, "Wood", "Leaves", 3),
        (20, 12, 7, "Wood", "Leaves", 4),
        (-4, 20, 6, "BirchWood", "BirchLeaves", 3),
        (10, 18, 6, "CherryWood", "CherryLeaves", 4),
        (-20, 14, 5, "SpruceWood", "SpruceLeaves", 3),
    ):
        if (x, y) in tops:
            tree(v, x, y, top(x, y), h_, log, leaf, r, seed=x + y)
    v.build()
    # Wheat in rows
    for x in range(6, 20):
        for y in range(-14, -4, 2):
            if (x, y) in tops:
                item(a, "Wheat", ((x - 0.25) * SIZE, y * SIZE, top(x, y) * SIZE + 1.5), scale=1.5)
                item(a, "Wheat", ((x + 0.25) * SIZE, y * SIZE, top(x, y) * SIZE + 1.5), rotation=(0, 0, 60), scale=1.4)
    # Windows and a door, lit
    window = glow("Window", "#ffd88a", 2.2)
    for x in (fx - 2, fx + 2):
        box("Window", (2.8, 0.4, 2.8), (x * SIZE, (fy - 4) * SIZE + 1.2, (fz + 3) * SIZE), window)
    door = flat("Door", "#6a3f22")
    box("Door", (2.8, 0.6, 5.8), (fx * SIZE, (fy - 4) * SIZE + 1.2, (fz + 1.5) * SIZE), door)
    # A stream in its channel, over the front edge and down
    edge_y = min(y for (x, y) in tops if x == -18)
    stream_top = 0.15 * SIZE
    length = (-6 - edge_y) * SIZE
    box("Stream", (9, length, 0.8), (-18 * SIZE, (edge_y * SIZE + -6 * SIZE) / 2, stream_top), s.water)
    waterfall(-18 * SIZE, edge_y * SIZE - 1.5, stream_top, -64 * SIZE, 9, seed=4, mat=s.water, foam=s.foam)
    # The hero on the path, big enough to read
    hx, hy = 2, -18
    hero(a, (hx * SIZE, hy * SIZE, top(hx, hy) * SIZE + 1.5), yaw=-14, tool="SapphirePickaxe", swing=-125, scale=3.2, shirt="#e8452c", pants="#2b3a67", tool_scale=1.4)
    # Other islands far off
    far = Vox(a)
    island(far, -75, 120, 14, depth=14, seed=12, base=10, hill=2)
    island(far, 80, 140, 18, depth=18, seed=13, base=-6, hill=3)
    island(far, 95, 30, 6, depth=8, seed=14, base=-16)
    far.build()
    for loc, r, seed in (
        ((-210, 120, -90), 46, 1),
        ((230, 80, -100), 50, 2),
        ((-120, -60, -135), 40, 3),
        ((110, -80, -140), 44, 4),
        ((-240, 300, 110), 40, 5),
        ((60, 420, 150), 60, 6),
        ((260, 300, 60), 36, 7),
    ):
        puff(loc, r, s.white, seed=seed)
    sky("#0a4ad0", "#39a6ff", below="#8fdcff", strength=1.0)
    sun((-0.55, -0.6, 0.75), energy=4.2)
    camera((-30, -262, 62), (12, 0, -14), lens=33)
    render(tmp, w, h, samples)
    image = finish(read_image(tmp), bloom=0.35, saturation=1.14)
    return image


def cave_shell(v, seed, width=40, depth=30, height=26, wall="DarkStone", floor=("DarkStone", "Stone", "Gravel"), ores=()):
    """The inside of a cave as seen from its open front: floor, curved back wall and roof"""
    rng = random.Random(seed)
    for x in range(-width, width + 1):
        for y in range(-14, depth + 4):
            # Rough floor
            f = int((n2(x, y, 9, seed) + 0.4) * 2.2)
            v.set(x, y, f, floor[rng.randrange(len(floor))] if n2(x, y, 4, seed + 1) > -0.1 else floor[0])
            v.set(x, y, f - 1, "Stone")
    for x in range(-width, width + 1):
        for z in range(0, height + 8):
            wobble = 5 * n2(x, z, 11, seed + 2) + 2 * n2(x, z, 4, seed + 3)
            # The wall curves in over the top and round the sides
            curve = (abs(x) / width) ** 2.4 * depth * 0.95 + (z / (height + 8)) ** 2.6 * depth * 0.8
            y = int(depth - curve + wobble)
            for t in range(0, 3):
                block = wall
                if t == 0:
                    for ore, chance, scale, salt in ores:
                        if n2(x + z * 0.6, z - x * 0.4, scale, salt) > 0.42 - chance:
                            block = ore
                            break
                v.set(x, y + t, z, block)


def scene_mine(w, h, samples, tmp):
    """Mine the depths: the hero swinging a Sapphire Pickaxe in a cavern of crystal and lava"""
    s = Stage()
    v, a = s.v, s.assets
    cave_shell(
        v,
        3,
        ores=(("AmethystOre", 0.14, 7, 21), ("SapphireOre", 0.13, 7, 34), ("RubyOre", 0.13, 7, 47), ("GoldOre", 0.1, 5, 58), ("SilverOre", 0.08, 5, 69)),
    )
    # The ore face the hero is breaking
    rough = random.Random(5)
    for x in range(-7, 9):
        for z in range(1, 13):
            d = math.hypot(x - 1, (z - 5) * 0.8)
            if d < 7.5 + rough.uniform(-1.6, 0.6):
                depth = 3 + int(d * 0.35 + rough.uniform(0, 1.4))
                v.set(x, depth, z, "AmethystOre" if (x + z) % 4 else "StarstoneOre")
                v.set(x, depth + 1, z, "DarkStone")
    v.build()
    purple = shard_mesh(gem("Amethyst", "#a13cff", 1.0))
    pink = shard_mesh(gem("Pink", "#ff4fc4", 0.9))
    blue = shard_mesh(gem("Sapphire", "#2878ff", 1.1))
    red = shard_mesh(gem("Ruby", "#ff1f3c", 1.0))
    gold = shard_mesh(gem("Star", "#ffd86a", 1.3))
    # Crystal clusters round the hall
    crystals(purple, (-60, 34, 1), 11, 42, seed=2)
    crystals(pink, (-48, 16, 0), 7, 20, seed=3)
    crystals(blue, (62, 36, 1), 11, 46, seed=4)
    crystals(red, (46, 14, 1), 7, 22, seed=5)
    crystals(purple, (-24, 56, 2), 7, 26, seed=6)
    crystals(gold, (26, 58, 2), 7, 24, seed=7)
    crystals(blue, (-72, 8, 1), 6, 22, seed=8)
    crystals(purple, (74, 8, 1), 6, 24, seed=9)
    for loc, mesh_, height in (((-32, 40, 66), pink, 24), ((36, 44, 66), blue, 24), ((0, 62, 72), purple, 28), ((-58, 34, 62), red, 18), ((60, 34, 60), gold, 18)):
        crystals(mesh_, loc, 7, height, seed=int(height), down=True)
    lamp((-55, 24, 14), "#b45cff", 16000, 6)
    lamp((55, 24, 14), "#3f8bff", 16000, 6)
    lamp((40, 8, 8), "#ff3048", 6000, 4)
    lamp((-40, 8, 6), "#ff6fd0", 5000, 4)
    lamp((0, -4, 22), "#fff0d0", 8000, 8)
    # Lava falling at the back
    lava = glow("Lava", "#ff5a0a", 1.6)
    hot = glow("LavaHot", "#ffb020", 2.4)
    box("LavaFall", (7, 2, 70), (-18, 62, 34), lava)
    box("LavaHot", (2.6, 2, 70), (-18.8, 61, 34), hot)
    box("LavaFall", (5, 2, 70), (20, 60, 34), lava)
    box("LavaHot", (1.8, 2, 70), (20.6, 59, 34), hot)
    box("LavaPool", (22, 8, 0.6), (-18, 58, 2), hot)
    box("LavaPool", (18, 8, 0.6), (20, 56, 2), hot)
    lamp((-18, 52, 10), "#ff7a1c", 7000, 4)
    lamp((20, 50, 10), "#ff7a1c", 6000, 4)
    # The hero, chips flying off the face
    hero(a, (3, -14, 2.2), yaw=-22, shirt="#2f6fdc", pants="#27324f", hat="miner", tool="SapphirePickaxe", swing=-132, scale=2.2, tool_scale=1.6)
    rng = random.Random(4)
    for i in range(22):
        chip = glow("Chip", ("#c78bff", "#ffe28a", "#8fc2ff")[i % 3], 3)
        r = rng.uniform(0.35, 0.8)
        box("Chip", (r, r, r), (rng.uniform(-22, 22), rng.uniform(-6, 6), rng.uniform(6, 26)), chip, rotation=(rng.uniform(0, 90), rng.uniform(0, 90), 0))
    # Gems in the foreground
    item(a, "Sapphire", (20, -40, 2.4), rotation=(0, 0, -20), scale=3.4)
    item(a, "Ruby", (29, -32, 2.4), rotation=(0, 0, 25), scale=3.4)
    sky("#0a0a1c", "#14102a", below="#100c20", strength=0.8)
    sun((0.2, -0.9, 0.5), color="#a8c4ff", energy=0.5)
    camera((0, -66, 15), (0, 12, 17), lens=26)
    render(tmp, w, h, samples)
    return finish(read_image(tmp), bloom=0.8, threshold=0.68, vignette=0.32, saturation=1.15)


def anvil_mesh(a_mat, face_mat, wood_mat):
    root = bpy.data.objects.new("Anvil", None)
    bpy.context.scene.collection.objects.link(root)
    box("Stump", (13, 13, 8), (0, 0, 4), wood_mat, parent=root, bevel=0.5)
    box("Foot", (12, 8, 2.2), (0, 0, 9.1), a_mat, parent=root, bevel=0.3)
    box("Waist", (5.8, 4.4, 3.4), (0, 0, 11.8), a_mat, parent=root, bevel=0.2)
    box("Body", (13, 6.6, 3.4), (0, 0, 15), a_mat, parent=root, bevel=0.3)
    box("Face", (12.8, 6.3, 0.34), (0, 0, 16.8), face_mat, parent=root)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=8, radius1=2.4, radius2=0.25, depth=7, matrix=Matrix.Rotation(math.radians(90), 4, "Y"))
    horn = add_mesh("Horn", bm, a_mat)
    horn.parent = root
    horn.location = (9.8, 0, 15.3)
    return root


def scene_forge(w, h, samples, tmp):
    """Forge legendary tools: the Anvil glowing under a fan of every tier of tool"""
    s = Stage()
    a = s.assets
    iron = flat("Iron", "#6c7180", 0.42)
    iron.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.35
    face = flat("IronFace", "#d4d8e4", 0.28)
    face.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.4
    root = anvil_mesh(iron, face, flat("Stump", "#7c5230", 0.8))
    root.location = (0, 0, -23)
    # The hot metal on the anvil
    hot = glow("Hot", "#ff8a24", 8)
    box("Hot", (5, 2.2, 0.8), (-1.5, 0, -5.6), hot, bevel=0.2)
    lamp((-1, -7, -1), "#ffa24c", 4000, 4)
    # The fan of pickaxes and swords, every tier
    tools = [
        ("WoodenPickaxe", -68),
        ("StonePickaxe", -46),
        ("IronPickaxe", -23),
        ("AmethystPickaxe", 0),
        ("SapphirePickaxe", 23),
        ("AmethystSword", 46),
        ("SapphireSword", 68),
    ]
    for name, angle in tools:
        pivot = Matrix.Translation((0, 6, -8)) @ Matrix.Rotation(math.radians(angle), 4, "Y")
        obj = bpy.data.objects.new(name, a.items[name])
        bpy.context.scene.collection.objects.link(obj)
        obj.matrix_world = (
            pivot
            @ Matrix.Translation((0, 0, 19))
            @ Matrix.Diagonal((6.2, 6.2, 6.2, 1))
            @ Matrix.Rotation(math.radians(-45), 4, "Y")
            @ Matrix.Translation((0, 0, -1.6))
        )
    # Parts and gems round the foot
    for name, x, z, scale, spin in (
        ("RefinedSapphire", -21, -15, 6, 20),
        ("RefinedAmethyst", 21, -15, 6, -20),
        ("IronPlate", -35, -17, 5.5, 25),
        ("Rope", 36, -16, 5.5, -25),
    ):
        item(a, name, (x, -12, z), rotation=(0, 0, spin), scale=scale)
    # Sparks
    rng = random.Random(9)
    for i in range(70):
        spark = glow("Spark" + str(i % 3), ("#ffc44a", "#ff8a2a", "#ffe08a")[i % 3], 2.2)
        angle = rng.uniform(0, math.tau)
        d = rng.uniform(4, 42)
        r = rng.uniform(0.14, 0.34)
        box("Spark", (r, r, r), (math.cos(angle) * d, -7 + rng.uniform(-3, 3), -6 + abs(math.sin(angle)) * d * 0.75), spark)
    # Lit from the front, warm from below
    sun((-0.25, -0.8, 0.55), color="#fff2e0", energy=4.0)
    lamp((-34, -30, 10), "#9fd0ff", 16000, 12)
    lamp((34, -30, 10), "#ffcf9a", 16000, 12)
    camera((0, -118, 2), (0, 0, 0), lens=40)
    sky("#000000", "#000000", strength=0.25)
    render(tmp, w, h, samples, transparent=True)
    art = read_image(tmp)
    back = sunburst(w, h, (w * 0.5, h * 0.56), "#7a3cff", "#120a38", "#ffb45c", rays=14)
    composed = over(art, back)
    return finish(composed, bloom=0.7, threshold=0.75, vignette=0.3)


def wheat_rows(s, tops, x1, x2, y1, y2, step=1):
    for x in range(x1, x2):
        for y in range(y1, y2, step):
            if (x, y) in tops:
                z = tops[(x, y)] * SIZE + 1.5
                item(s.assets, "Wheat", (x * SIZE - 0.7, y * SIZE, z), scale=1.9)
                item(s.assets, "Wheat", (x * SIZE + 0.7, y * SIZE + 0.5, z), rotation=(0, 0, 70), scale=1.7)


def scene_farm(w, h, samples, tmp):
    """Grow your own farm: the hero in a golden field, pumpkins and melons, a windmill"""
    s = Stage()
    v, a = s.v, s.assets
    tops = island(v, 0, 20, 46, depth=16, seed=8, hill=0)
    # Fields: wheat in the middle, pumpkins left, melons right
    for x in range(-40, 41):
        for y in range(-14, 60):
            if (x, y) in tops:
                if abs(x) % 11 == 0:
                    v.set(x, y, 0, "Path")
                elif -24 < x < 24:
                    v.set(x, y, 0, "Farmland")
    # Pumpkins and melons on either side, in front
    rng = random.Random(3)
    for x in range(-40, -24):
        for y in range(-14, 30):
            if (x, y) in tops and x % 3 == 0 and y % 3 == 0:
                v.set(x, y, 1, "Pumpkin")
    for x in range(25, 41):
        for y in range(-14, 30):
            if (x, y) in tops and x % 3 == 0 and y % 3 == 0:
                v.set(x, y, 1, "Melon")
    # Close to the camera: a patch of pumpkins and one of melons
    front = set()
    for x in (4, 6, 8):
        for y in (-10, -8, -6):
            if (x, y) in tops:
                v.set(x, y, 1, "Melon" if (x + y) % 4 == 2 else "Pumpkin")
    for x in range(3, 10):
        for y in range(-11, -4):
            front.add((x, y))
    # Hay and crates by the path
    for x, y, z, block in ((-10, -8, 1, "HayBale"), (-11, -8, 1, "HayBale"), (-10, -8, 2, "HayBale"), (10, -7, 1, "Crate")):
        v.set(x, y, z, block)
    # The windmill on the far hill, and a barn
    wx, wy = -22, 46
    for z in range(1, 15):
        r = 4 if z < 9 else 3
        for x in range(-r, r + 1):
            for y in range(-r, r + 1):
                if abs(x) == r or abs(y) == r:
                    v.set(wx + x, wy + y, z, "Plaster" if z % 4 else "DarkPlanks")
    for i in range(4):
        for x in range(-4 + i, 5 - i):
            for y in range(-4 + i, 5 - i):
                v.set(wx + x, wy + y, 15 + i, "RoofRed")
    bx, by = 24, 48
    for x in range(-7, 8):
        for y in range(-5, 6):
            for z in range(1, 7):
                if abs(x) == 7 or abs(y) == 5:
                    v.set(bx + x, by + y, z, "BarnPlanks")
    for i in range(5):
        for x in range(-8, 9):
            for y in range(-6 + i, 7 - i):
                v.set(bx + x, by + y, 7 + i, "RoofRed")
    for x, y, h_, log, leaf in ((-40, 44, 7, "Wood", "Leaves"), (42, 30, 7, "Wood", "Leaves"), (6, 62, 8, "Wood", "Leaves")):
        if (x, y) in tops:
            tree(v, x, y, 0, h_, log, leaf, 4, seed=x)
    v.build()
    # The sails
    sail = flat("Sail", "#f4ead2", 0.8)
    wood = flat("SailWood", "#6a4426", 0.8)
    hub = Vector((wx * SIZE, (wy - 5) * SIZE, 12 * SIZE))
    for i in range(4):
        angle = i * 90 + 25
        rad = math.radians(angle)
        along = Vector((math.cos(rad), 0, math.sin(rad)))
        box("Spar", (1.0, 0.5, 34), hub + along * 17, wood, rotation=(0, 90 - angle, 0))
        box("Sail", (7, 0.25, 26), hub + along * 20 + Vector((math.sin(rad), 0, -math.cos(rad))) * 4, sail, rotation=(0, 90 - angle, 0))
    wheat_rows(s, {k: 0 for k in tops if -24 < k[0] < 24 and abs(k[0]) % 11 and -2 < k[1] < 42}, -23, 24, -1, 42)
    wheat_rows(s, {k: 0 for k in tops if -24 < k[0] < 24 and abs(k[0]) % 11 and k[1] <= -2 and k not in front}, -23, 24, -14, -2, 2)
    hero(a, (2, -29, 1.5), yaw=-22, shirt="#e6443a", pants="#3a5ca8", hat="straw", tool="IronHoe", swing=-122, scale=2.1, tool_scale=1.5)
    for loc, r, seed in (((-220, 300, 120), 60, 1), ((60, 460, 170), 80, 2), ((270, 340, 100), 60, 3), ((-90, 420, 70), 44, 4), ((180, 300, 30), 40, 5)):
        puff(loc, r, s.white, seed=seed)
    sky("#0a4ad0", "#46aeff", below="#a6e6ff", strength=1.0)
    sun((-0.6, -0.55, 0.6), color="#ffe9b8", energy=4.5)
    camera((3, -62, 14), (1, 20, 15), lens=27)
    render(tmp, w, h, samples)
    return finish(read_image(tmp), bloom=0.4, saturation=1.14)


def scene_forest(w, h, samples, tmp):
    """Chop giant forests: towering trees of every kind, the hero with an axe, petals falling"""
    s = Stage()
    v, a = s.v, s.assets
    tops = island(v, 0, 34, 60, depth=12, seed=11, hill=3)
    rng = random.Random(6)
    kinds = (
        ("Wood", "Leaves"),
        ("BirchWood", "BirchLeaves"),
        ("CherryWood", "CherryLeaves"),
        ("SpruceWood", "SpruceLeaves"),
        ("CherryWood", "CherryLeaves"),
        ("Wood", "AutumnLeaves"),
    )
    spots = []
    for _ in range(600):
        x, y = rng.randint(-55, 55), rng.randint(0, 80)
        if (x, y) not in tops or any(math.hypot(x - p[0], y - p[1]) < 11 for p in spots):
            continue
        if abs(x) < 8 and y < 12:
            continue
        spots.append((x, y))
        log, leaf = kinds[len(spots) % len(kinds)]
        height = rng.randint(10, 17)
        tree(v, x, y, tops[(x, y)], height, log, leaf, rng.randint(4, 6), seed=x * y)
    # A giant in front on the left: a thick trunk the hero is chopping
    gx, gy = -6, -4
    for dz in range(0, 24):
        for x in range(gx - 1, gx + 2):
            for y in range(gy - 1, gy + 2):
                v.set(x, y, dz + 1, "Wood")
    for dx in range(-9, 10):
        for dy in range(-9, 10):
            for dz in range(-2, 8):
                d = math.sqrt(dx * dx + dy * dy + (dz * 1.4) ** 2)
                if d < 9 and rng.random() > (0.3 if d > 7.5 else 0):
                    v.set(gx + dx, gy + dy, 26 + dz, "CherryLeaves")
    # The cut: a notch out of the trunk, facing the hero
    for x in range(gx - 1, gx + 2):
        v.clear(x, gy - 1, 3)
    # Logs stacked by the path
    for x, z in ((10, 1), (11, 1), (12, 1), (10.5, 2), (11.5, 2)):
        v.set(int(x), -12, z, "Wood")
    v.build()
    hero(a, (4, -30, 3 * SIZE + 1.6), yaw=-48, shirt="#3a8f3e", pants="#4d3a2a", hat="beanie", tool="IronAxe", swing=-128, scale=2.1, tool_scale=1.7)
    # Blossom falling
    petal = flat("Petal", "#ffb6d8", 0.7)
    for _ in range(170):
        r = rng.uniform(0.5, 1.2)
        box("Petal", (r, r * 0.2, r), (rng.uniform(-90, 90), rng.uniform(-30, 80), rng.uniform(4, 90)), petal, rotation=(rng.uniform(0, 90), rng.uniform(0, 90), rng.uniform(0, 90)))
    item(a, "Sapling", (32, -46, 8), rotation=(0, 0, 10), scale=5)
    item(a, "BirchHandle", (-30, -46, 18), rotation=(0, 0, 0), scale=3)
    sky("#0a4ad0", "#46aeff", below="#a6e6ff", strength=1.0)
    sun((-0.45, -0.7, 0.6), color="#fff0cc", energy=4.2)
    camera((6, -72, 20), (0, 20, 30), lens=26)
    render(tmp, w, h, samples)
    return finish(read_image(tmp), bloom=0.4, saturation=1.12)


def scene_world(w, h, samples, tmp):
    """The whole sky: the mine's mountain, the farm and forest islands, bridges between them"""
    s = Stage()
    v = s.v
    # The mountain in the middle: many sharp peaks run together, sandstone below and bare
    # rock above with dark cracks, grass round its foot
    peaks = ((0, 8, 34, 58), (-20, -2, 20, 34), (21, 0, 19, 37), (-13, 19, 20, 42), (15, 20, 18, 40), (-33, 12, 12, 22), (34, 12, 12, 24), (-7, -16, 11, 22), (9, -15, 10, 20))
    tops = island(v, 0, 0, 40, depth=30, seed=2, ores=(("AmethystOre", 0.03), ("GoldOre", 0.02)))
    for (x, y), base in list(tops.items()):
        height = 0
        for px, py, r, ph in peaks:
            d = math.hypot(x - px, y - py)
            if d < r:
                jag = 1 + 0.5 * n2(x, y, 3.2, 5) + 0.35 * n2(x, y, 7, 6)
                height = max(height, int(ph * (1 - d / r) ** 1.15 * jag))
        if height <= 1:
            continue
        crack = abs(n2(x, y, 9, 7)) < 0.035
        for z in range(1, height + 1):
            if crack and z > 6:
                block = "DarkStone"
            elif z > 32:
                block = "SmoothStone" if z > 44 else "Stone"
            else:
                block = "Sandstone"
            v.set(x, y, z, block)
    # Oaks round the foot, in front
    for x, y in ((-30, -24), (-20, -30), (26, -27), (33, -18), (-37, -8), (38, -4)):
        if (x, y) in tops and tops[(x, y)] >= 0 and (x, y, 2) not in v.cells:
            tree(v, x, y, tops[(x, y)], 5, seed=x * y)
    # The mine's great timber arch, dark and lantern-lit inside
    for x in range(-7, 8):
        for z in range(1, 14):
            for y in range(-34, 0):
                if math.hypot(x, z * 0.8) < 7.2:
                    v.clear(x, y, z)
    for x in range(-8, 9):
        for z in range(1, 15):
            r = math.hypot(x, z * 0.8)
            if 7.2 <= r < 9.2:
                for y in range(-22, -18):
                    v.set(x, y, z, "DarkPlanks" if int(r * 2) % 2 else "Wood")
    for x in range(-7, 8):
        for z in range(1, 13):
            if math.hypot(x, z * 0.8) < 7.2:
                v.set(x, -6, z, "Obsidian")
    # The farm island on the left
    farm = island(v, -82, -10, 26, depth=20, seed=7, hill=0)
    for x in range(-100, -66):
        for y in range(-26, 8):
            if (x, y) in farm and x % 7:
                v.set(x, y, 0, "Farmland")
            elif (x, y) in farm:
                v.set(x, y, 0, "Path")
    # The windmill
    for z in range(1, 12):
        for x in range(-3, 4):
            for y in range(-3, 4):
                if abs(x) == 3 or abs(y) == 3:
                    v.set(-90 + x, 14 + y, z, "Plaster")
    for i in range(3):
        for x in range(-3 + i, 4 - i):
            for y in range(-3 + i, 4 - i):
                v.set(-90 + x, 14 + y, 12 + i, "RoofRed")
    # The forest island on the right
    wood = island(v, 86, -6, 26, depth=20, seed=9, hill=2)
    rng = random.Random(2)
    spots = []
    for _ in range(300):
        x, y = rng.randint(62, 110), rng.randint(-30, 20)
        if (x, y) in wood and not any(math.hypot(x - p[0], y - p[1]) < 7 for p in spots):
            spots.append((x, y))
            log, leaf = (("Wood", "Leaves"), ("CherryWood", "CherryLeaves"), ("BirchWood", "BirchLeaves"))[len(spots) % 3]
            tree(v, x, y, wood[(x, y)], rng.randint(6, 10), log, leaf, 3, seed=x + y)
    # Stone bridges
    for x in range(-58, -38):
        for y in (-13, -12, -11):
            v.set(x, y, 0, "StoneBricks")
    for x in range(38, 62):
        for y in (-11, -10, -9):
            v.set(x, y, 0, "StoneBricks")
    v.build()
    wheat = {k: 0 for k in farm if k[0] % 7 and k[1] % 2 == 0 and -30 < k[1] < 8}
    for x, y in list(wheat)[:600]:
        item(s.assets, "Wheat", (x * SIZE, y * SIZE, 1.5), scale=1.5)
    sail = flat("Sail", "#f4ead2", 0.8)
    wood_m = flat("SailWood", "#6a4426", 0.8)
    hub = Vector((-90 * SIZE, 10.5 * SIZE, 9 * SIZE))
    for i in range(4):
        rad = math.radians(i * 90 + 25)
        along = Vector((math.cos(rad), 0, math.sin(rad)))
        box("Spar", (1.0, 0.5, 26), hub + along * 13, wood_m, rotation=(0, 65 - i * 90, 0))
        box("Sail", (6, 0.25, 20), hub + along * 15 + Vector((math.sin(rad), 0, -math.cos(rad))) * 3.2, sail, rotation=(0, 65 - i * 90, 0))
    # The glow of the mine, and the peak's crystal
    core = shard_mesh(gem("Peak", "#27d3ff", 0.8))
    crystals(core, (0, 8 * SIZE, 58 * SIZE - 12), 9, 56, seed=4, spread=0.42)
    # Inside the arch: warm lantern light against the dark
    lantern = glow("Lantern", "#ffc25c", 2.6)
    for x, z in ((-13, 4), (13, 4), (0, 9), (-7, 14), (7, 14)):
        box("Lantern", (2.4, 2.4, 3.2), (x, -24 * SIZE, z * 2.5), lantern, bevel=0.2)
    lamp((0, -24 * SIZE, 18), "#ffb35c", 9000, 5)
    # The stream off the mountain's side, over the edge
    waterfall(-96, -68, 3, -80, 8, seed=5, mat=s.water, foam=s.foam)
    # Small islets, clouds
    far = Vox(s.assets)
    for x, y, z, r, seed in ((-38, -60, 26, 5, 3), (42, -64, 22, 4, 5), (0, 90, 12, 16, 8), (-130, 76, 20, 12, 6), (140, 88, 16, 14, 7)):
        island(far, x, y, r, depth=r + 2, seed=seed, base=z)
    far.build()
    for loc, r, seed in (
        ((-300, -60, -120), 66, 1),
        ((320, -70, -130), 70, 2),
        ((0, -130, -165), 70, 3),
        ((-430, 300, 110), 70, 4),
        ((420, 320, 150), 80, 5),
        ((120, 500, 230), 90, 6),
        ((-150, -90, -60), 30, 7),
        ((190, -100, -80), 32, 8),
    ):
        puff(loc, r, s.white, seed=seed)
    sky("#0a4ad0", "#39a6ff", below="#8fdcff", strength=1.0)
    sun((-0.45, -0.75, 0.6), energy=4.4)
    camera((0, -600, 40), (0, 0, 66), lens=34)
    render(tmp, w, h, samples)
    return finish(read_image(tmp), bloom=0.42)


# Layouts: the words on each picture -------------------------------------------------------

WHITE = ("#ffffff", "#c8e4ff")
GOLD = ("#fff070", "#f68c1c")
CYAN = ("#c4f2ff", "#2e92ec")
PURPLE = ("#f0d4ff", "#a24cf0")
GREEN = ("#e6ff9a", "#58c034")
PINK = ("#ffe0ee", "#f070b0")


def words_island(image, unit):
    logo(image, unit * 2, unit * 2, unit)
    caption(image, [("BUILD YOUR", *WHITE, 1.0), ("SKY ISLAND", *GOLD, 1.5)], unit * 2, image.shape[0] - unit * 33, unit)


def words_mine(image, unit):
    logo(image, unit * 2, unit * 2, unit)
    caption(image, [("MINE THE", *WHITE, 1.0), ("DEPTHS", *PURPLE, 1.7)], unit * 2, image.shape[0] - unit * 36, unit)


def words_forge(image, unit):
    logo(image, unit * 2, unit * 2, unit)
    caption(image, [("FORGE LEGENDARY TOOLS", *GOLD, 1.0)], image.shape[1] // 2, image.shape[0] - unit * 14, unit, align="center")


def words_farm(image, unit):
    logo(image, unit * 2, unit * 2, unit)
    caption(image, [("GROW YOUR", *WHITE, 1.0), ("FARM", *GREEN, 1.8)], unit * 2, image.shape[0] - unit * 38, unit)


def words_forest(image, unit):
    logo(image, unit * 2, unit * 2, unit)
    caption(image, [("CHOP GIANT", *WHITE, 1.0), ("FORESTS", *PINK, 1.6)], unit * 2, image.shape[0] - unit * 35, unit)


def words_world(image, unit):
    logo(image, unit * 2, unit * 2, int(unit * 1.5))
    caption(image, [("MINE & FARM & CHOP & BUILD", *WHITE, 0.9)], image.shape[1] // 2, image.shape[0] - unit * 13, unit, align="center")


def motes(seed, count, center, spread, height, colors, size=(0.2, 0.5), strength=3.0):
    """Little lit cubes hanging or rising in the air"""
    rng = random.Random(seed)
    for i in range(count):
        color = colors[i % len(colors)]
        r = rng.uniform(*size)
        at = (center[0] + rng.uniform(-spread, spread), center[1] + rng.uniform(-spread, spread), center[2] + rng.uniform(0, height))
        box("Mote", (r, r, r), at, glow("Mote" + color, color, strength), rotation=(rng.uniform(0, 90), rng.uniform(0, 90), 0))


def castle(v, cx, cy, z):
    """A proper keep: curtain walls, four round-the-corner towers and a tall middle tower"""
    half_x, half_y = 13, 9
    for x in range(cx - half_x, cx + half_x + 1):
        for y in range(cy - half_y, cy + half_y + 1):
            edge = abs(x - cx) == half_x or abs(y - cy) == half_y
            v.set(x, y, z, "SmoothStone")
            if edge:
                for dz in range(1, 8):
                    v.set(x, y, z + dz, "StoneBricks")
                if (x + y) % 2 == 0:
                    v.set(x, y, z + 8, "StoneBricks")

    def tower(tx, ty, r, height, roof):
        for x in range(tx - r, tx + r + 1):
            for y in range(ty - r, ty + r + 1):
                for dz in range(1, height + 1):
                    v.set(x, y, z + dz, "StoneBricks" if (dz % 5 or max(abs(x - tx), abs(y - ty)) < r) else "SmoothStone")
        for i in range(r + 3):
            spread = r + 1 - i
            for x in range(tx - spread, tx + spread + 1):
                for y in range(ty - spread, ty + spread + 1):
                    v.set(x, y, z + height + 1 + i, roof)

    for sx in (-1, 1):
        for sy in (-1, 1):
            tower(cx + sx * half_x, cy + sy * half_y, 3, 13, "RoofSlate")
    tower(cx, cy, 6, 21, "RoofRed")


def split_frame(left, right, w, h, unit):
    """Two renders side by side, with a slanted white bar where they meet"""
    lw = left.shape[1]
    yy, xx = np.mgrid[0:h, 0:w]
    edge = w / 2 + (yy - h / 2) * -0.09
    out = np.zeros((h, w, 4), dtype=np.float32)
    out[:, :lw] = left
    behind = np.zeros_like(out)
    behind[:, w - lw:] = right
    out = np.where((xx >= edge)[..., None], behind, out)
    band = np.abs(xx - edge)
    out[band < unit * 3.0] = (*OUTLINE, 1)
    out[band < unit * 1.9] = (1, 1, 1, 1)
    return out


def scene_day100(w, h, samples, tmp):
    """Day 1 against day 100: the same player, a dirt speck next to a castle in the sky"""
    lw = int(w * 0.58)
    # Day 1
    s = Stage()
    v, a = s.v, s.assets
    tops = island(v, -13, 0, 4, depth=5, seed=21, base=7)
    tree(v, -13, 0, tops[(-13, 0)], height=2, leaf="Leaves", radius=1, seed=3)
    v.build()
    grey = flat("CloudGrey", "#8a93a8", 0.95)
    for loc, r, seed in (((-90, 90, -40), 46, 11), ((60, 70, 70), 34, 12), ((-20, 120, -70), 60, 13), ((120, 150, -20), 50, 14)):
        puff(loc, r, grey, seed=seed)
    hero(a, (3, -116, -12), yaw=-8, shirt="#7d6a55", pants="#4d463f", face="worried", gaze=(-0.08, -0.03), tool="WoodenPickaxe", swing=-160, scale=7.5, tool_scale=1.5)
    lamp((12, -96, 36), "#a9c4ff", 7000, 8)
    sky("#39425e", "#7b859c", below="#454c60", strength=0.95)
    sun((-0.5, -0.6, 0.7), color="#c6d1ea", energy=1.8)
    camera((0, -150, 20), (0, 0, 20), lens=38)
    render(tmp, lw, h, samples)
    left = finish(read_image(tmp), bloom=0.2, vignette=0.32, saturation=0.72)
    # Day 100
    s = Stage()
    v, a = s.v, s.assets
    tops = island(v, 26, 0, 34, depth=30, seed=6, hill=2, ores=(("GoldOre", 0.06), ("IronOre", 0.03), ("RubyOre", 0.02)))
    castle(v, 28, 8, max(tops.get((28, 8), 0), 2))
    for x, y, h_, log, leaf, r in (
        (3, -14, 7, "CherryWood", "CherryLeaves", 4),
        (52, -18, 8, "Wood", "Leaves", 4),
        (10, 20, 7, "BirchWood", "BirchLeaves", 3),
        (46, 26, 7, "CherryWood", "CherryLeaves", 4),
    ):
        if (x, y) in tops:
            tree(v, x, y, tops[(x, y)], h_, log, leaf, r, seed=x + y)
    v.build()
    edge_y = min(y for (x, y) in tops if x == 18)
    waterfall(18 * SIZE, edge_y * SIZE - 1.5, 2, -200, 12, seed=4, mat=s.water, foam=s.foam)
    window = glow("Window", "#ffd88a", 3.0)
    for i in range(-2, 3):
        box("Window", (3, 0.5, 5), ((28 + i * 4) * SIZE, -1 * SIZE - 3.1, 13 * SIZE), window)
    motes(5, 90, (0, -160, -30), 110, 150, ["#ffe08a", "#fff3c4", "#7fe6ff"], size=(0.25, 0.7), strength=4.0)
    for loc, r, seed in (((260, 70, -120), 60, 1), ((-40, 80, -130), 54, 2), ((190, 140, 170), 44, 3), ((-90, 160, 130), 40, 4)):
        puff(loc, r, s.white, seed=seed)
    hero(a, (-3, -196, -2), yaw=8, shirt="#23c4dc", pants="#20305c", face="huge", gaze=(0.05, 0.02), tool="StarsteelSword", swing=-158, scale=7.5, tool_scale=2.1, shoulders="#1a8fb0", mirror=True, hair="#3a2415")
    lamp((-14, -176, 44), "#ffd27a", 9000, 8)
    sky("#0a4ad0", "#39a6ff", below="#8fdcff", strength=1.05)
    sun((-0.45, -0.7, 0.72), energy=4.4)
    camera((0, -230, 30), (0, 0, 30), lens=38)
    render(tmp, lw, h, samples)
    right = finish(read_image(tmp), bloom=0.5, vignette=0.12, saturation=1.28)
    return split_frame(left, right, w, h, w // 240)


def scene_chest(w, h, samples, tmp):
    """The Warzone's Legendary Skydrop with two players about to fight for it and everyone else running in"""
    s = Stage()
    v, a = s.v, s.assets
    tops = island(v, 0, 12, 28, top="DuskGrass", soil="Dirt", rock="DarkStone", depth=22, seed=31, hill=1)
    for side in (-1, 1):
        for i in range(0, 34):
            for k in (-1, 0, 1):
                v.set(side * (26 + i), 30 + k, 0, "DarkPlanks")
    v.build()
    far = Vox(a)
    island(far, -86, 62, 16, top="DuskGrass", soil="Dirt", rock="DarkStone", depth=16, seed=32, base=1)
    island(far, 86, 58, 17, top="DuskGrass", soil="Dirt", rock="DarkStone", depth=16, seed=33, base=-1)
    island(far, 0, 150, 26, top="DuskGrass", soil="Dirt", rock="DarkStone", depth=20, seed=34, base=14, hill=4)
    far.build()
    ground = tops.get((0, 0), 0) * SIZE + 1.5
    mesh = a.blocks.get("LootChest") or a.blocks.get("Chest")
    if mesh:
        chest = bpy.data.objects.new("Legendary", mesh)
        bpy.context.scene.collection.objects.link(chest)
        chest.location = (0, -6, ground + 7.8)
        chest.scale = (5.2, 5.2, 5.2)
    else:
        print("no chest mesh")
        box("Legendary", (15, 12, 12), (0, -6, ground + 6), flat("ChestWood", "#8a5a2c"), bevel=0.4)
    # Its health bar, part mined away
    box("BarBack", (30, 0.6, 3.2), (0, -8, ground + 23), flat("BarBack", "#14102a", 0.5), bevel=0.2)
    box("BarFill", (19, 0.8, 2.1), (-4.9, -8.4, ground + 23), glow("BarFill", "#c060ff", 5))
    lamp((0, -28, ground + 12), "#b65cff", 42000, 10)
    motes(7, 170, (0, -10, ground), 19, 34, ["#d08cff", "#b65cff", "#ffd27a", "#ffffff"], size=(0.18, 0.5), strength=5.0)
    # The two fighting over it, swords crossing above the chest
    hero(a, (-23, -60, ground - 5), yaw=38, shirt="#d8362c", pants="#3a1a20", face="angry", gaze=(0.07, 0), tool="RubySword", swing=-142, scale=7.2, tool_scale=2.2, shoulders="#7a1f1f", mirror=True)
    hero(a, (23, -60, ground - 5), yaw=-38, shirt="#2f6fdc", pants="#1a2a55", face="angry", gaze=(-0.07, 0), tool="SapphireSword", swing=-142, scale=7.2, tool_scale=2.2, shoulders="#1c3f8f", hair="#d7a94a")
    lamp((-40, -40, 44), "#ff8a6a", 9000, 8)
    lamp((40, -40, 44), "#7ab8ff", 9000, 8)
    # Everyone else, running in over the island and the bridges
    rng = random.Random(44)
    shirts = ["#e8452c", "#2f6fdc", "#2fbf71", "#f4b92c", "#a65cff", "#e4e7ef", "#f27fb3"]
    for i in range(46):
        x, y = rng.uniform(-110, 110), rng.uniform(16, 110)
        cell = (round(x / SIZE), round(y / SIZE))
        z = (tops.get(cell, 0) if cell in tops else 0) * SIZE + 1.5
        toward = math.degrees(math.atan2(-x, y))
        hero(a, (x, y, z), yaw=toward, shirt=shirts[i % len(shirts)], tool="IronSword" if i % 2 else None, swing=-90, scale=rng.uniform(1.0, 1.25))
    motes(9, 240, (0, 700, -100), 1100, 760, ["#ffffff", "#c9d8ff"], size=(1.2, 3.4), strength=4.0)
    plum = glow("Plum", "#3a2a78", 0.5)
    for loc, r, seed in (((-280, 260, -60), 80, 1), ((300, 280, -50), 90, 2), ((-60, 420, -120), 120, 3)):
        puff(loc, r, plum, seed=seed)
    sky("#050a24", "#1c2a6a", below="#0a1030", strength=0.9)
    sun((-0.2, -0.6, 0.75), color="#c7d4ff", energy=1.8)
    camera((0, -114, 32), (0, 0, 20), lens=30)
    render(tmp, w, h, samples)
    return finish(read_image(tmp), bloom=0.75, threshold=0.7, vignette=0.32, saturation=1.25)


def scene_pit(w, h, samples, tmp):
    """The void pit in Town's square: a player at the edge, looking back, and others already falling"""
    s = Stage()
    v, a = s.v, s.assets
    for x in range(-26, 27):
        for y in range(-26, 27):
            ring = max(abs(x), abs(y))
            if ring <= 4:
                continue
            if ring == 5:
                roll = (x * 7 + y * 13) % 9
                brick = "MossyStoneBricks" if roll == 0 else ("CrackedStoneBricks" if roll <= 2 else "StoneBricks")
                if not (abs(x) == 5 and abs(y) == 5):
                    v.set(x, y, 1, brick)
                for z in range(0, -9, -1):
                    v.set(x, y, z, brick)
            else:
                v.set(x, y, 0, "StoneBricks" if ring <= 6 or ring == 15 else ("SmoothStone" if ring <= 9 else "Cobblestone"))
    v.build()
    across = 9 * SIZE
    surface = -2 * SIZE
    box("Void", (across + 1, across + 1, 0.4), (0, 0, surface), glow("Void", "#0b0620", 0.8))
    motes(3, 190, (0, 0, surface + 0.5), across / 2 - 1, 13, ["#efe6ff", "#a766ff", "#96f0d7"], size=(0.14, 0.42), strength=7.0)
    flame = shard_mesh(glow("Flame", "#a45cff", 5.0))
    rng = random.Random(8)
    for i in range(18):
        crystals(flame, (rng.uniform(-11, 11), rng.uniform(-11, 11), surface), 3, rng.uniform(9, 26), seed=i, spread=0.25, scatter=1.6)
    motes(4, 260, (0, 0, surface), across / 2 + 1, 80, ["#d08cff", "#a766ff", "#f0c8ff", "#ffffff"], size=(0.18, 0.55), strength=5.0)
    lamp((0, 0, 8), "#9a50ff", 52000, 14)
    # Others already falling in, arms up
    for x, y, z, yaw, shirt in ((-6, 4, 6, 40, "#e8452c"), (5, -3, 1, -30, "#2fbf71"), (2, 7, 13, 170, "#f4b92c"), (-3, -5, -2, 90, "#2f6fdc")):
        hero(a, (x, y, z), yaw=yaw, shirt=shirt, swing=-172, off_arm=-172, scale=1.05)
    # The dark town behind
    wall = Vox(a)
    for x in range(-60, 61):
        tall = 8 + int(5 * (1 + math.sin(x * 0.7)) + 3 * (1 + math.sin(x * 0.23)))
        for z in range(1, tall):
            wall.set(x, 34, z, "Bricks" if x % 24 < 12 else "StoneBricks")
    wall.build()
    # The one who hasn't jumped yet, looking back at you
    hero(a, (-15, -40, 1.5), yaw=30, shirt="#f4b92c", pants="#27324f", face="shock", gaze=(0.11, -0.03), scale=5.2, off_arm=-26, swing=-30)
    lamp((-24, -62, 34), "#ffe2b8", 5200, 9)
    lamp((-6, -30, 24), "#9a50ff", 6000, 7)
    sky("#120a30", "#3a1a6a", below="#100826", strength=0.75)
    sun((-0.3, -0.7, 0.7), color="#b9a8ff", energy=1.1)
    camera((-3, -66, 31), (4, 0, 2), lens=31)
    render(tmp, w, h, samples)
    return finish(read_image(tmp), bloom=0.8, threshold=0.68, vignette=0.34, saturation=1.25)


def words_day100(image, unit):
    caption(image, [("DAY 1", "#ffffff", "#c9d3e6", 2.6)], unit * 3, unit * 3, unit)
    caption(image, [("DAY 100", CORE_TOP, CORE_BOTTOM, 2.6)], unit * 3, unit * 3, unit, align="right")


def words_chest(image, unit):
    caption(image, [("55 PLAYERS", "#ffffff", "#c9d8ff", 1.7), ("1 CHEST", CORE_TOP, CORE_BOTTOM, 2.7)], image.shape[1] // 2, unit * 3, unit, align="center", gap=unit * 3)


def words_pit(image, unit):
    caption(image, [("JUMP IN?", "#f0d4ff", "#b65cff", 2.5)], unit * 3, unit * 3, unit, align="right")


THUMBS = {
    "thumb1": ("thumb1_world", scene_world, words_world),
    "thumb2": ("thumb2_island", scene_island, words_island),
    "thumb3": ("thumb3_mine", scene_mine, words_mine),
    "thumb4": ("thumb4_forge", scene_forge, words_forge),
    "thumb5": ("thumb5_farm", scene_farm, words_farm),
    "thumb6": ("thumb6_forest", scene_forest, words_forest),
    # The click-tested set: one clear idea, a big reacting face, two or three words at the top
    "thumb7": ("thumb7_day100", scene_day100, words_day100),
    "thumb8": ("thumb8_chest", scene_chest, words_chest),
    "thumb9": ("thumb9_pit", scene_pit, words_pit),
}


def main():
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else ["all"]
    preview = "preview" in args
    wanted = [a for a in args if a != "preview"]
    if "all" in wanted:
        wanted = ["icon", *THUMBS]
    temp = os.path.join(common.RENDER_DIR, "_store.png")
    for name in wanted:
        if name == "icon":
            final = 512
            size = 512 if preview else 1024
            image = scene_icon(size, 24 if preview else 96, temp)
            image = finish_icon(image, final)
            out = os.path.join(common.RENDER_DIR, "store_icon.png") if preview else os.path.join(OUT_DIR, "icon.png")
        else:
            file_name, scene, words = THUMBS[name]
            w, h = (960, 540) if preview else (1920, 1080)
            image = scene(w, h, 24 if preview else 128, temp)
            words(image, w // 240)
            out = os.path.join(common.RENDER_DIR, f"store_{name}.png") if preview else os.path.join(OUT_DIR, file_name + ".png")
        write_image(image, out)
        print("wrote", out)
    if os.path.exists(temp):
        os.remove(temp)


if __name__ == "__main__":
    main()
