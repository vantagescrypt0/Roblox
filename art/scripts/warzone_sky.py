"""The Warzone's night-blue sky: six 1024 px cube faces, a smooth gradient by height with stars
above the horizon. It only changes with height, so the faces meet with no seam whichever way
Roblox turns them.

Output: art/textures/sky/warzone_{bk,dn,ft,lf,rt,up}.png
"""

import os

import bpy
import numpy as np

SIZE = 1024
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "textures", "sky")

# Colour by elevation: (sine of the angle above the horizon, r, g, b)
STOPS = np.array(
    [
        (-1.0, 8, 10, 30),
        (-0.35, 14, 20, 52),
        (-0.06, 34, 50, 96),
        (0.0, 66, 88, 138),
        (0.05, 50, 72, 124),
        (0.2, 26, 40, 86),
        (0.5, 14, 22, 56),
        (1.0, 7, 10, 30),
    ],
    dtype=np.float64,
)

# Direction of each face's pixels: (right, up, forward) in world axes
FACES = {
    "ft": ((1, 0, 0), (0, 1, 0), (0, 0, -1)),
    "bk": ((-1, 0, 0), (0, 1, 0), (0, 0, 1)),
    "lf": ((0, 0, -1), (0, 1, 0), (-1, 0, 0)),
    "rt": ((0, 0, 1), (0, 1, 0), (1, 0, 0)),
    "up": ((1, 0, 0), (0, 0, 1), (0, 1, 0)),
    "dn": ((1, 0, 0), (0, 0, -1), (0, -1, 0)),
}


def face(name, seed):
    right, up, forward = (np.array(v, dtype=np.float64) for v in FACES[name])
    axis = (np.arange(SIZE) + 0.5) / SIZE * 2 - 1
    u, v = np.meshgrid(axis, -axis)
    dirs = u[..., None] * right + v[..., None] * up + forward
    dirs /= np.linalg.norm(dirs, axis=-1, keepdims=True)
    elevation = dirs[..., 1]

    rgb = np.stack([np.interp(elevation, STOPS[:, 0], STOPS[:, i]) for i in (1, 2, 3)], axis=-1)

    # Stars: more of them high up, none near the horizon or below it
    rng = np.random.default_rng(seed)
    fade = np.clip((elevation - 0.06) / 0.3, 0, 1)
    count = 2600
    xs, ys = rng.integers(1, SIZE - 1, count), rng.integers(1, SIZE - 1, count)
    bright = rng.uniform(0.18, 1, count) ** 2.4
    tint = rng.uniform(0.82, 1, (count, 3))
    for x, y, b, t in zip(xs, ys, bright, tint):
        a = b * fade[y, x]
        if a > 0.02:
            rgb[y, x] = rgb[y, x] * (1 - a) + 255 * t * a
            if b > 0.6:  # The bright ones get a soft edge
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    rgb[y + dy, x + dx] = rgb[y + dy, x + dx] * (1 - a * 0.35) + 255 * t * a * 0.35

    # A little dither so the gradient doesn't band
    rgb += rng.uniform(-0.8, 0.8, rgb.shape)
    return np.clip(rgb, 0, 255) / 255


def save(name, pixels):
    image = bpy.data.images.new(f"warzone_{name}", SIZE, SIZE, alpha=True)
    rgba = np.ones((SIZE, SIZE, 4), dtype=np.float32)
    rgba[..., :3] = pixels[::-1]  # Blender's rows run bottom to top
    image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(rgba.ravel())
    image.filepath_raw = os.path.join(OUT, f"warzone_{name}.png")
    image.file_format = "PNG"
    image.save()
    print("wrote", image.filepath_raw)


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, name in enumerate(FACES):
        save(name, face(name, 1000 + i))


main()
