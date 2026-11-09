"""The Loot Crate's opening scene (client/CrateOpening.luau): the crate in two halves so its lid can blow off, the
floating stone dais it lands on, and the rune stone that stands round it, one for each thing inside. Everything's on
the shared palette, like the items, so each is one MeshPart with one texture. The runes are tinted in the game.

    blender -b --factory-startup --python art/scripts/crate_open.py              writes art/export/CrateOpen.fbx
    blender -b --factory-startup --python art/scripts/crate_open.py -- preview   renders art/renders/CrateOpen.png
"""

import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import common  # noqa: E402
from lowpoly import Builder, export_fbx  # noqa: E402


def crate_body():
    b = Builder(seed=3)
    # A wooden chest of planks, darker at the corners, bound in iron and studded
    b.box((2.4, 2.0, 1.3), location=(0, 0, 0.65), color="wood", bevel=0.04)
    for z in (0.24, 0.65, 1.06):
        b.box((2.44, 2.04, 0.05), location=(0, 0, z), color="wood_darker")
    for x in (-1.14, 1.14):
        for y in (-0.94, 0.94):
            b.box((0.2, 0.2, 1.36), location=(x, y, 0.66), color="wood_dark", bevel=0.02)
    for x in (-0.72, 0.72):
        b.box((0.3, 2.1, 1.36), location=(x, 0, 0.66), color="iron_dark", bevel=0.02)
        for y in (-1.06, 1.06):
            for z in (0.3, 0.66, 1.02):
                b.box((0.12, 0.05, 0.12), location=(x, y, z), color="iron")
    b.box((2.5, 2.1, 0.12), location=(0, 0, 0.06), color="iron_dark", bevel=0.02)
    # The hasp's lower half
    b.box((0.5, 0.1, 0.42), location=(0, -1.05, 1.08), color="gold_dark", bevel=0.02)
    b.box((0.26, 0.12, 0.2), location=(0, -1.09, 1.04), color="gold", bevel=0.02)
    # Inside it's dark, with a warm glow where the treasure is
    b.box((2.1, 1.7, 0.04), location=(0, 0, 1.31), color="wood_darker")
    b.box((1.7, 1.3, 0.05), location=(0, 0, 1.33), color="glow")
    return b.finish("Crate_Body")


def crate_lid():
    """Its origin is the middle of its bottom edge, so the game can throw it about its own centre."""
    b = Builder(seed=4)
    b.box((2.5, 2.1, 0.2), location=(0, 0, 0.1), color="wood_dark", bevel=0.02)
    # An arched lid in five staves
    for i, (y, z, tilt) in enumerate(((-0.84, 0.3, 40), (-0.44, 0.52, 18), (0.0, 0.6, 0), (0.44, 0.52, -18), (0.84, 0.3, -40))):
        b.box((2.42, 0.48, 0.2), location=(0, y, z), rotation=(tilt, 0, 0), color="plank" if i % 2 == 0 else "wood", bevel=0.02)
    for x in (-0.72, 0.72):
        for y, z, tilt in ((-0.86, 0.32, 40), (-0.45, 0.56, 18), (0.0, 0.64, 0), (0.45, 0.56, -18), (0.86, 0.32, -40)):
            b.box((0.3, 0.5, 0.2), location=(x, y, z), rotation=(tilt, 0, 0), color="iron_dark", bevel=0.01)
    # The lock, in gold, with a keyhole
    b.box((0.6, 0.12, 0.52), location=(0, -1.06, 0.14), color="gold", bevel=0.03)
    b.box((0.36, 0.14, 0.26), location=(0, -1.09, 0.14), color="gold_dark", bevel=0.02)
    b.box((0.08, 0.16, 0.14), location=(0, -1.1, 0.14), color="coal")
    return b.finish("Crate_Lid")


def dais():
    """A round slab of carved stone with a broken chunk of island underneath, so it floats like everything up here."""
    b = Builder(seed=5)
    b.cylinder(4.5, 0.5, location=(0, 0, -0.25), color="stone_light", segments=24, radius2=4.3)
    b.cylinder(4.56, 0.12, location=(0, 0, -0.42), color="stone_dark", segments=24)
    b.cylinder(2.5, 0.08, location=(0, 0, 0.02), color="stone_blue", segments=24)
    b.cylinder(2.2, 0.1, location=(0, 0, 0.03), color="stone_dark", segments=24)
    # The six sockets the runes hang over, with a groove from each to the middle
    for i in range(6):
        a = math.radians(i * 60)
        x, y = math.cos(a), math.sin(a)
        b.cylinder(0.56, 0.1, location=(x * 3.5, y * 3.5, 0.03), color="stone_dark", segments=6)
        b.cylinder(0.36, 0.1, location=(x * 3.5, y * 3.5, 0.06), color="metal_dark", segments=6)
        b.box((1.14, 0.2, 0.06), location=(x * 2.6, y * 2.6, 0.03), rotation=(0, 0, math.degrees(a)), color="stone_dark")
    # The rock it's cut from, tapering away below
    b.cylinder(4.2, 1.1, location=(0, 0, -1.0), color="dirt", segments=12, radius2=3.1, bevel=0.0)
    b.cylinder(3.0, 1.3, location=(0, 0, -2.2), color="stone_dark", segments=9, radius2=1.6)
    b.cylinder(1.5, 1.4, location=(0.2, 0.1, -3.5), color="stone", segments=7, radius2=0.2)
    for i in range(7):
        a = math.radians(i * 51)
        b.cone(0.42, 1.1, location=(math.cos(a) * 3.1, math.sin(a) * 3.1, -1.8), rotation=(180, 0, 0), color="stone_dark", segments=5)
    return b.finish("Crate_Dais")


def rune():
    """A carved rune stone: tall, faceted, its marks cut in the one colour the game can tint."""
    b = Builder(seed=6)
    b.cylinder(0.34, 0.26, location=(0, 0, 0.13), color="flower_white", segments=6, radius2=0.42)
    b.cylinder(0.42, 0.9, location=(0, 0, 0.71), color="flower_white", segments=6, radius2=0.36)
    b.cone(0.36, 0.36, location=(0, 0, 1.34), color="flower_white", segments=6)
    return b.finish("Crate_Rune")


def preview(objects):
    scene = bpy.context.scene
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in engines else "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 960
    scene.render.resolution_y = 720
    scene.world = bpy.data.worlds.new("Sky")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.12, 0.13, 0.22, 1)
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3
    sun_obj = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(55), 0, math.radians(30))
    by_name = {o.name: o for o in objects}
    by_name["Crate_Lid"].location = (0, 0, 2.4)
    by_name["Crate_Lid"].rotation_euler = (math.radians(-18), 0, math.radians(8))
    base = by_name["Crate_Rune"]
    for i in range(6):
        a = math.radians(i * 60)
        copy = base if i == 0 else base.copy()
        if i > 0:
            scene.collection.objects.link(copy)
        copy.location = (math.cos(a) * 3.5, math.sin(a) * 3.5, 0.35)
    data = bpy.data.cameras.new("Camera")
    data.lens = 42
    camera = bpy.data.objects.new("Camera", data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.location = (1.6, -12.5, 6.2)
    camera.rotation_euler = (math.radians(66), 0, math.radians(7))
    scene.render.filepath = os.path.join(common.RENDER_DIR, "CrateOpen.png")
    bpy.ops.render.render(write_still=True)


def main():
    common.reset_scene()
    objects = [crate_body(), crate_lid(), dais(), rune()]
    if "preview" in sys.argv:
        preview(objects)
        print("PREVIEWED", flush=True)
    else:
        print("EXPORTED", export_fbx(os.path.join(common.EXPORT_DIR, "CrateOpen.fbx"), objects), flush=True)
    for obj in objects:
        print(obj.name, len(obj.data.polygons), [round(v, 3) for v in obj.dimensions], flush=True)


main()
