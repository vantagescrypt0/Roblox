"""Renders swords on the body from several sides, to look at a hold. Plain colours: this is for judging shape.
    blender -b --python render.py -- <scenes.json> <out prefix>
scenes.json: [{"name": .., "sword": .., "pose": {Hand, Along, Turn} or null, "set": "Mining"|"Bare"|.., "views": [..]}]"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
import numpy as np
from mathutils import Matrix, Vector

import holdlib as H

args = sys.argv[sys.argv.index("--") + 1 :]
scenes = json.load(open(args[0]))
prefix = args[1]

COLOURS = {
    "Sword": (0.95, 0.15, 0.1, 1),
    "Pauldron": (0.2, 0.5, 0.9, 1),
    "Helmet": (0.35, 0.6, 0.35, 1),
    "Chest": (0.35, 0.35, 0.42, 1),
    "Skin": (0.85, 0.65, 0.45, 1),
    "Other": (0.45, 0.45, 0.5, 1),
    "Hand": (1, 0.9, 0.1, 1),
}
# Views: camera direction from the body, in chest space
VIEWS = {
    "side": (1, 0.05, 0),
    "back": (0.0, 0.25, 1),
    "backright": (0.75, 0.45, 1),
    "front": (0.35, 0.15, -1),
    "top": (0.01, 1, 0.01),
    "game": (0.15, 0.55, 1),
    "photo": (0.75, 0.75, -0.6),
}


def to_blender(p):
    return (p[0], -p[2], p[1])


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "OBJECT"
    scene.display.shading.show_cavity = True
    scene.display.shading.show_shadows = False
    scene.render.resolution_x = 560
    scene.render.resolution_y = 640
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("Sky")
    world.color = (0.75, 0.8, 0.85)
    scene.world = world
    return scene


def add(name, v, f, colour):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([to_blender(p) for p in v], [], [list(x) for x in f])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    obj.color = COLOURS[colour]
    bpy.context.collection.objects.link(obj)
    return obj


def body_for(set_name):
    if set_name == "Bare":
        parts = H.bare_body()
        for name, (v, f) in parts.items():
            add(name, v, f, "Skin")
        return
    parts = H.armoured(set_name)
    for name, (v, f) in parts.items():
        colour = "Pauldron" if name.startswith("Pauldron") else "Helmet" if name == "Helmet" else "Chest" if name == "Chest" else "Other"
        add(name, v, f, colour)
    # What the armour leaves showing
    v, f = H.box(H.HEAD_AT, (1.0, 1.05, 1.0))
    add("Face", v, f, "Skin")


def camera_at(scene, direction, ortho=9.0, centre=(0, 1.3, 0)):
    data = bpy.data.cameras.new("Camera")
    data.type = "ORTHO"
    data.ortho_scale = ortho
    cam = bpy.data.objects.new("Camera", data)
    bpy.context.collection.objects.link(cam)
    d = Vector(to_blender(H.unit(direction)))
    c = Vector(to_blender(centre))
    cam.location = c + d * 20
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam


for item in scenes:
    scene = clear()
    body_for(item.get("set", "Mining"))
    if item.get("sword"):
        v, f, grip, _ = H.sword(item["sword"])
        if item.get("mount"):
            mount = np.array(item["mount"])
        else:
            mount = H.pose_mount(grip, item["pose"])
        add("Sword", H.place(mount, v), f, "Sword")
        hand = H.place(mount @ grip, np.array([[0.0, 0.0, 0.0]]))[0]
        hv, hf = H.box(hand, (0.5, 0.5, 0.5))
        add("Hand", hv, hf, "Hand")
    for view in item.get("views", ["side", "back", "front"]):
        camera_at(scene, VIEWS[view], item.get("ortho", 9.0), item.get("centre", (0, 1.3, 0)))
        scene.render.filepath = f"{prefix}{item['name']}_{view}.png"
        bpy.ops.render.render(write_still=True)
print("DONE", flush=True)
