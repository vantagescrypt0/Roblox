"""Measures what the real game recorded (record.py): each frame's sword against that frame's armour and arm, wherever
the animations put them. A hand is meant to touch the handle, so the sword's parts are told apart: what's touching near
the grip is the hold itself, anything else isn't.
    real_check.py -- recorded.json"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np

import holdlib as H

args = sys.argv[sys.argv.index("--") + 1 :]
recorded = json.load(open(args[0]))
GRIP_ZONE = 0.75  # studs from the grip's middle: the wrist round the handle


def matrix(c):
    """CFrame:GetComponents(): x y z then the rotation's rows."""
    m = np.eye(4)
    m[:3, 3] = c[0:3]
    m[:3, :3] = np.array(c[3:12]).reshape(3, 3)
    return m


ARM = {"RightUpperArm": "SleeveRight", "RightLowerArm": "ForearmRight", "LeftUpperArm": "SleeveLeft", "LeftLowerArm": "ForearmLeft"}
BOX = {"RightUpperArm": (0.81, 1.18, 0.71), "RightLowerArm": (0.70, 1.13, 0.84), "LeftUpperArm": (0.81, 1.18, 0.71), "LeftLowerArm": (0.70, 1.13, 0.84)}
total = {"blade": 0, "pommel": 0, "body": 0}
summary = {}
for item in recorded:
    set_name, sword_name = item["set"], item["sword"]
    frames = item["frames"]
    if not frames:
        print(set_name, sword_name, item["kind"], "NO FRAMES", flush=True)
        continue
    v, f, grip, _ = H.sword(sword_name)
    # Each sword face's place from the grip: Y runs up the handle toward the blade
    in_grip = H.place(np.linalg.inv(grip), v)
    face_at = np.array([in_grip[list(x)].mean(0) for x in f])
    if set_name == "Bare":
        fixed = {"Chest": H.box((0, 0, 0), (1.54, 1.84, 1.01))}
    else:
        fixed = {"Chest": H.armour_piece(set_name, "Chest"), "PauldronRight": H.armour_piece(set_name, "PauldronRight"), "PauldronLeft": H.armour_piece(set_name, "PauldronLeft")}
    fixed_trees = {k: H.tree_of(*x) for k, x in fixed.items()}
    result = {}
    lowest = {}
    for index, frame in enumerate(frames):
        if frame.get("item") != sword_name:
            continue
        placed = H.place(matrix(frame["held"]), v)
        mine = H.tree_of(placed, f)
        trees = dict(fixed_trees)
        if set_name == "Bare":
            hv, hf = H.box((0, 0, 0), (1.11, 1.12, 1.12))
        else:
            hv, hf = np.array(H.ARMOUR[set_name]["Helmet"]["v"]), H.ARMOUR[set_name]["Helmet"]["f"]
        trees["Head"] = H.tree_of(H.place(matrix(frame["Head"]), np.asarray(hv)), hf)
        for body, piece in ARM.items():
            if set_name == "Bare":
                bv, bf = H.box((0, 0, 0), BOX[body])
            else:
                bv, bf = np.array(H.ARMOUR[set_name][piece]["v"]), H.ARMOUR[set_name][piece]["f"]
            trees[body] = H.tree_of(H.place(matrix(frame[body]), np.asarray(bv)), bf)
        lv, lf = H.box((0, 0, 0), (0.64, 0.84, 0.74))
        trees["LeftHand"] = H.tree_of(H.place(matrix(frame["LeftHand"]), lv), lf)
        pts = placed[:: max(1, len(placed) // 150)]
        for key, tree in trees.items():
            pairs = mine.overlap(tree)
            if pairs:
                where = face_at[[a for a, _ in pairs]]
                from_grip = np.linalg.norm(where, axis=1)
                beyond = where[from_grip > GRIP_ZONE]
                if len(beyond):
                    kind = "pommel" if beyond[:, 1].max() < 0 else "blade"
                    slot = result.setdefault(key, {"blade": 0, "pommel": 0, "far": 0.0, "first": index})
                    slot[kind] += 1
                    slot["far"] = max(slot["far"], float(np.linalg.norm(beyond, axis=1).max()))
            gap = min(tree.find_nearest(tuple(p))[3] for p in pts)
            lowest[key] = min(lowest.get(key, 9), gap)
    for key, slot in result.items():
        counts = "body" if key in ("Head", "Chest", "PauldronRight", "PauldronLeft", "LeftUpperArm", "LeftLowerArm", "LeftHand") else None
        total["body" if counts else "blade"] += slot["blade"] + (slot["pommel"] if counts else 0)
        if not counts:
            total["pommel"] += slot["pommel"]
    tight = sorted(((k, a) for k, a in lowest.items() if k in ("Head", "Chest", "PauldronRight", "PauldronLeft")), key=lambda x: x[1])[:1]
    print(set_name, sword_name, item["kind"], f"{len(frames)}f", "tightest", [(k, round(a, 2)) for k, a in tight], "HITS", {k: f"blade {x['blade']}f pommel {x['pommel']}f out to {x['far']:.1f} from f{x['first']}" for k, x in result.items()}, flush=True)
print("TOTAL frames:", total, flush=True)
