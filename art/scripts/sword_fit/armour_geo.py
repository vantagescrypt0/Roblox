"""Builds every armour piece with the repo's own armour.py and writes them to armour.json, in the space of the body
part each one sits on (Roblox axes: X right, Y up, -Z ahead). A pauldron is written in the chest's space."""
import json
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
path = os.path.join(REPO, "art", "scripts", "armour.py")
source = open(path, encoding="utf-8").read()
source = source[: source.rindex("main()")]
lib = {"__name__": "armour_lib", "__file__": path}
exec(compile(source, path, "exec"), lib)

SETS, SIDED, BODY = lib["SETS"], lib["SIDED"], lib["BODY"]
out = {}
for skill, pieces in SETS.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    data = {}
    for piece, build in pieces.items():
        model = build()
        sides = (("Right", 1), ("Left", -1)) if piece in SIDED else (("", 1),)
        for label, side in sides:
            name = piece + label
            obj = model.build(f"{skill}_{name}", side)
            shift = (0, 0, 0)
            if piece == "Pauldron":
                at = BODY["Pauldron"][0]
                shift = (at[0] * side, at[1], at[2])
            verts = [[round(v.co.x + shift[0], 4), round(v.co.y + shift[1], 4), round(v.co.z + shift[2], 4)] for v in obj.data.vertices]
            faces = [list(p.vertices) for p in obj.data.polygons]
            data[name] = {"v": verts, "f": faces}
    out[skill] = data
    print(skill, {k: (len(v["v"]), len(v["f"])) for k, v in data.items()}, flush=True)
with open(os.path.join(HERE, "armour.json"), "w") as f:
    json.dump(out, f)
print("DONE", flush=True)
