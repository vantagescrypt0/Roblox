"""Every sword through every frame of its rest, sprint, the blend between them and its swing, the way HeldController moves
them, against what that hold has to clear. The poses come from SwordArt.luau.
    blender -b --python check.py -- [Sword,Sword]"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np

import holdlib as H

args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
holds = H.read_carries()
only = args[0].split(",") if args else None
sets = H.all_obstacles()

ARMOURED = {}
BARE = {}
for set_name, parts in sets.items():
    for part_name, (v, f) in parts.items():
        if part_name == "ShieldRaised":
            continue
        tree = H.tree_of(v, f)
        ARMOURED[f"{set_name}.{part_name}"] = tree
        if set_name in ("Bare", "Gear"):
            BARE[f"{set_name}.{part_name}"] = tree


def check(name, mount, against):
    v, f, _, _ = H.sword(name)
    placed = H.place(mount, v)
    mine = H.tree_of(placed, f)
    hits = [key for key, tree in against.items() if mine.overlap(tree)]
    pts = placed[:: max(1, len(placed) // 200)]
    gap = 9.0
    for tree in against.values():
        for p in pts:
            gap = min(gap, tree.find_nearest(tuple(p))[3])
    return hits, gap


total = 0
for family, hold in holds.items():
    names = ["RubySword"] if family == "Ruby" else H.STRAIGHT
    for name in names:
        if only and name not in only:
            continue
        _, _, grip, _ = H.sword(name)
        inverse = np.linalg.inv(grip)
        keys = [H.pose_frame(k) if k else None for k in hold["Swing"]]
        for wearing, against in (("Armoured", ARMOURED), ("Bare", BARE)):
            rest = H.pose_frame(hold[wearing]["Rest"])
            run = H.pose_frame(hold[wearing]["Run"])
            report = {}
            lowest = 9.0
            for label, mount in (("rest", rest), ("run", run), ("blend", H.lerp_frame(rest, run, 0.5))):
                hits, gap = check(name, mount @ inverse, against)
                lowest = min(lowest, gap)
                for hit in hits:
                    report.setdefault(hit, []).append(label)
            for start_label, start in (("", rest), ("r", run)):
                for key, step, mount in H.swing_frames(start, keys, steps=6):
                    hits, gap = check(name, mount @ inverse, against)
                    lowest = min(lowest, gap)
                    for hit in hits:
                        report.setdefault(hit, []).append(f"{start_label}{key}.{step}")
            total += sum(len(x) for x in report.values())
            short = {k: (x if len(x) <= 6 else x[:6] + [f"+{len(x)-6}"]) for k, x in report.items()}
            print(f"{name} {wearing}: gap {lowest:.2f} hits {short}", flush=True)
print("TOTAL HITS", total, flush=True)
