"""The game page's thumbnails: real captures from the game, with the store captions on them.

Studio's capture is far wider than 16:9, so each frame is stitched from three captures taken
from the same point at different tilts (nothing shifts between them, so they join exactly).

    blender --background --factory-startup --python art/scripts/store_footage.py -- <shots dir> [names...]

Each shot is <name>_0.png, _1.png, _2.png and <name>.json in the shots dir.
Output: art/footage/<name>.png (no words) and art/marketing/page_<name>.png (1920x1080).
"""

import json
import math
import os
import sys

import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402
import store_art as art  # noqa: E402

W, H = 1920, 1080
FOCAL = 1400  # pixels: about 69 degrees across the frame
FEATHER = 40
# Lifted a little: Roblox can cover the bottom of a thumbnail with the player count
LIFT = 48


def words_world(image, unit_):
    # The real logo is already huge in this shot, so only the words go on it
    art.caption(image, [("MINE & FARM & CHOP & BUILD", *art.WHITE, 0.9)], image.shape[1] // 2, image.shape[0] - unit_ * 13, unit_, align="center")


CAPTIONS = {
    "world": words_world,
    "island": art.words_island,
    "mine": art.words_mine,
    "forge": art.words_forge,
    "farm": art.words_farm,
    "forest": art.words_forest,
}


def unit(v):
    return v / np.linalg.norm(v)


def basis(look):
    right = unit(np.cross(look, (0.0, 1.0, 0.0)))
    return right, np.cross(right, look)


def tilted(cam, target, degrees):
    d = np.array(target, dtype=np.float64) - cam
    flat = math.hypot(d[0], d[2])
    angle = math.atan2(d[1], flat) + math.radians(degrees)
    return np.array((d[0] / flat * math.cos(angle), math.sin(angle), d[2] / flat * math.cos(angle)))


def sample(image, u, v):
    """Bilinear lookup; u and v are arrays of pixel positions already inside the image"""
    x0, y0 = np.floor(u).astype(int), np.floor(v).astype(int)
    x1, y1 = np.minimum(x0 + 1, image.shape[1] - 1), np.minimum(y0 + 1, image.shape[0] - 1)
    fx, fy = (u - x0)[..., None], (v - y0)[..., None]
    top = image[y0, x0] * (1 - fx) + image[y0, x1] * fx
    bottom = image[y1, x0] * (1 - fx) + image[y1, x1] * fx
    return top * (1 - fy) + bottom * fy


def stitch(shots, name):
    info = json.load(open(os.path.join(shots, f"{name}.json")))
    cam = np.array(info["cam"], dtype=np.float64)
    look = unit(np.array(info["target"], dtype=np.float64) - cam)
    right, up = basis(look)
    yy, xx = np.mgrid[0:H, 0:W]
    rays = look[None, None] + right[None, None] * ((xx - W / 2)[..., None] / FOCAL) + up[None, None] * ((H / 2 - yy)[..., None] / FOCAL)
    total = np.zeros((H, W, 3), dtype=np.float64)
    weight = np.zeros((H, W), dtype=np.float64)
    for i, pitch in enumerate(info["pitches"]):
        tile = art.read_image(os.path.join(shots, f"{name}_{i}.png"))[..., :3]
        th, tw = tile.shape[:2]
        focal = (th / 2) / math.tan(math.radians(info["lens"]) / 2)
        forward = tilted(cam, info["target"], pitch)
        r, u = basis(forward)
        depth = rays @ forward
        u_px = tw / 2 + focal * (rays @ r) / depth
        v_px = th / 2 - focal * (rays @ u) / depth
        inside = (depth > 0) & (u_px >= 0) & (u_px <= tw - 1) & (v_px >= 0) & (v_px <= th - 1)
        edge = np.minimum.reduce((v_px, th - 1 - v_px, u_px, tw - 1 - u_px))
        w = np.clip(edge / FEATHER, 0.001, 1) * inside
        total[inside] += sample(tile, u_px[inside], v_px[inside]) * w[inside][..., None]
        weight += w
    missing = int((weight == 0).sum())
    if missing:
        print(f"{name}: {missing} pixels not covered")
    rgb = total / np.maximum(weight, 1e-6)[..., None]
    return np.dstack([np.clip(rgb, 0, 1), np.ones((H, W))]).astype(np.float32)


def main():
    args = sys.argv[sys.argv.index("--") + 1 :]
    shots, names = args[0], args[1:] or list(CAPTIONS)
    footage = os.path.join(common.ART_DIR, "footage")
    os.makedirs(footage, exist_ok=True)
    for name in names:
        image = stitch(shots, name)
        art.write_image(image, os.path.join(footage, f"{name}.png"))
        # Only a light touch: it has to stay what the game really looks like
        final = art.finish(image, bloom=0.14, threshold=0.86, vignette=0.08, saturation=1.06)
        CAPTIONS[name](final[: H - LIFT], W // 240)
        out = os.path.join(art.OUT_DIR, f"page_{name}.png")
        art.write_image(final, out)
        print("wrote", out)


main()
