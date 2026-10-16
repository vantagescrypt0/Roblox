"""Shared helpers for asset scripts. Run scripts with Blender in background mode:

    blender --background --factory-startup --python art/scripts/<asset>.py

Units: 1 Blender unit = 1 Roblox stud. Import FBX into Studio with Scale Unit = Stud.
"""

import math
import os

import bpy

ART_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLEND_DIR = os.path.join(ART_DIR, "blend")
EXPORT_DIR = os.path.join(ART_DIR, "export")
RENDER_DIR = os.path.join(ART_DIR, "renders")


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    return scene


def material(name, rgb, roughness=0.8):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    mat.diffuse_color = (*rgb, 1.0)
    return mat


def mesh_object(name, bm, mat=None):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    if mat:
        obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = False
    return obj


def hex_rgb(value):
    value = value.lstrip("#")
    srgb = [int(value[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    # Blender colors are linear
    return tuple(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb)


def save_blend(name):
    os.makedirs(BLEND_DIR, exist_ok=True)
    path = os.path.join(BLEND_DIR, f"{name}.blend")
    bpy.ops.wm.save_as_mainfile(filepath=path)
    return path


def export_fbx(name):
    os.makedirs(EXPORT_DIR, exist_ok=True)
    path = os.path.join(EXPORT_DIR, f"{name}.fbx")
    bpy.ops.export_scene.fbx(
        filepath=path,
        object_types={"MESH"},
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        use_mesh_modifiers=True,
    )
    return path


def render_preview(name, target=(0, 0, 0), distance=70, height=35, angle_deg=35):
    scene = bpy.context.scene

    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (*hex_rgb("#8EC9F0"), 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    scene.world = world

    sun_data = bpy.data.lights.new("Sun", "SUN")
    sun_data.energy = 3.5
    sun = bpy.data.objects.new("Sun", sun_data)
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(40))
    scene.collection.objects.link(sun)

    cam_data = bpy.data.cameras.new("Camera")
    cam_data.lens = 40
    cam = bpy.data.objects.new("Camera", cam_data)
    a = math.radians(angle_deg)
    cam.location = (target[0] + distance * math.sin(a), target[1] - distance * math.cos(a), target[2] + height)
    scene.collection.objects.link(cam)
    aim = bpy.data.objects.new("CameraTarget", None)
    aim.location = target
    scene.collection.objects.link(aim)
    track = cam.constraints.new("TRACK_TO")
    track.target = aim
    scene.camera = cam

    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT", "BLENDER_WORKBENCH"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    # Show the real palette colors (Roblox doesn't tone-map textures like Blender's default)
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.film_transparent = False

    os.makedirs(RENDER_DIR, exist_ok=True)
    scene.render.filepath = os.path.join(RENDER_DIR, f"{name}.png")
    bpy.ops.render.render(write_still=True)

    # Keep preview-only objects out of the saved .blend and FBX
    for obj in (sun, cam, aim):
        bpy.data.objects.remove(obj, do_unlink=True)
    return scene.render.filepath
