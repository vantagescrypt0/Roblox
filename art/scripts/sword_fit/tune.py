"""Keeps a hold's look and moves it as little as it takes to clear everything.
    tune.py -- spec.json out.json
spec: [{"name", "swords": [...], "against": "all"|"bare", "limit": 0.08, "base": {Hand, Along, Turn}, "tries": 4000}]
"all" is every armour set and the bare body. "bare" is the bare body and the shield (no helmet or chest piece on)."""
import json
import math
import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np

import holdlib as H

args = sys.argv[sys.argv.index("--") + 1 :]
spec = json.load(open(args[0]))
random.seed(7)

sets = H.all_obstacles()


def helmets_only():
    out = {"Bare": sets["Bare"], "Gear": {"ShieldRest": sets["Gear"]["ShieldRest"]}}
    return out


TREES = {
    "all": H.union_tree(sets, leave_out=("ShieldRaised",)),
    "bare": H.union_tree(helmets_only()),
}
SWORD_TREE = {}


def rot(axis, deg):
    a = np.asarray(axis, dtype=float)
    r = math.radians(deg)
    x, y, z = a
    c, s = math.cos(r), math.sin(r)
    return np.array(
        (
            (c + x * x * (1 - c), x * y * (1 - c) - z * s, x * z * (1 - c) + y * s),
            (y * x * (1 - c) + z * s, c + y * y * (1 - c), y * z * (1 - c) - x * s),
            (z * x * (1 - c) - y * s, z * y * (1 - c) + x * s, c + z * z * (1 - c)),
        )
    )


def rounded(pose):
    return {k: tuple(round(float(c), 2) for c in pose[k]) for k in ("Hand", "Along", "Turn")}


def clears(names, tree, pose, limit, full=False):
    worst = 1e9
    for name in names:
        v, f, grip, _ = H.sword(name)
        mount = H.pose_mount(grip, pose)
        pts = v if full else v[:: max(1, len(v) // 300)]
        placed = H.place(mount, pts)
        for p in placed:
            d = tree.find_nearest(tuple(p))[3]
            if d < worst:
                worst = d
                if worst < limit:
                    return worst
        if full:
            mine = H.tree_of(H.place(mount, v), f)
            if mine.overlap(tree):
                return 0.0
    return worst


results = {}
for item in spec:
    began = time.time()
    names = item["swords"]
    tree = TREES[item.get("against", "all")]
    limit = item.get("limit", 0.08)
    base = item["base"]
    base_hand = np.array(base["Hand"], dtype=float)
    base_along = H.unit(base["Along"])
    base_turn = np.array(base["Turn"], dtype=float)
    best = None
    best_cost = 1e9
    tries = item.get("tries", 4000)
    # Hand limit: no further than the arm can reach
    candidates = []
    for i in range(tries):
        spread = 0.02 + 1.0 * (i / tries)
        delta = np.random.default_rng(i).normal(0, 0.12 * spread, 3) if i else np.zeros(3)
        hand = base_hand + delta
        if np.linalg.norm(hand) > 0.99:
            hand = hand / np.linalg.norm(hand) * 0.99
        r = np.random.default_rng(i + 100000)
        axis = H.unit(r.normal(0, 1, 3))
        angle = r.normal(0, 14 * spread) if i else 0.0
        m = rot(axis, angle)
        pose = rounded({"Hand": hand, "Along": m @ base_along, "Turn": m @ base_turn})
        cost = np.linalg.norm(np.array(pose["Hand"]) - base_hand) / 0.1 + abs(angle) / 5
        if cost >= best_cost:
            continue
        gap = clears(names, tree, pose, limit)
        if gap < limit:
            continue
        gap = clears(names, tree, pose, limit, full=True)
        if gap < limit:
            continue
        best, best_cost = dict(pose=pose, gap=float(gap), cost=float(cost), angle=float(angle)), cost
    results[item["name"]] = best
    print(item["name"], f"{time.time()-began:.0f}s", json.dumps(best), flush=True)
json.dump(results, open(args[1], "w"), indent=1)
print("DONE", flush=True)
