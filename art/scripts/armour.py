"""The armour on the body, in the style of 02 Research/References/Gear/ref_armour_blocky_themes.webp: blocky coats
that fit the body's boxes, one bold colour, thick outlines, and a big theme piece on each shoulder.

Each piece is modelled for one body part, in that part's own space, for the avatar measured below; the game scales
it to whatever body wears it (Util/ArmorModels.luau). One mesh serves every tier: each tier has its own colour
sheet (art/textures/armour/tier_N.png), with the coat dark on all of them and the trim in the tier's colour. Roblox's
tint would colour the whole coat, so the colour is in the sheets. Only upload them again if they change: the meshes
don't need importing for that.

    blender -b --python art/scripts/armour.py -- Mining            writes art/export/Armour_Mining.fbx and art_data
    blender -b --python art/scripts/armour.py -- Mining preview    also renders art/renders/Armour_Mining_*.png
"""
import json
import math
import os
import struct
import sys
import zlib

import bmesh
import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
OUTLINE = 0.03

# The palette: each colour is one cell of a 256 px sheet (art/textures/armour_palette.png)
CELLS = 8
PALETTE = {
    "Dark": (44, 48, 64),
    "Dark2": (64, 70, 90),
    "Dark3": (30, 33, 44),
    "Trim": (255, 255, 255),
    "Trim2": (199, 199, 199),
    "Trim3": (140, 140, 140),
    "Black": (8, 9, 14),
    "Steel": (96, 102, 116),
}
SWATCH = {name: index for index, name in enumerate(PALETTE)}


def swatch_uv(name):
    index = SWATCH[name]
    column, row = index % CELLS, index // CELLS
    return (column + 0.5) / CELLS, 1 - (row + 0.5) / CELLS


# The same order as TIER_COLORS in game/src/shared/Gear.luau
TIERS = (
    (205, 127, 50),
    (196, 200, 208),
    (242, 193, 78),
    (80, 200, 120),
    (120, 222, 244),
    (168, 96, 230),
    (220, 40, 60),
    (255, 236, 170),
    (236, 70, 160),
    (150, 240, 220),
)
TRIMMED = ("Trim", "Trim2", "Trim3")


def write_palette(path, tier):
    size = 256
    cell = size // CELLS
    rows = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            index = y // cell * CELLS + x // cell
            names = list(PALETTE)
            color = PALETTE[names[index]] if index < len(names) else (255, 0, 255)
            if index < len(names) and names[index] in TRIMMED:
                color = tuple(round(channel * shade / 255) for channel, shade in zip(tier, color))
            row += bytes((*color, 255))
        rows.append(b"\0" + bytes(row))

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    with open(path, "wb") as out:
        out.write(b"\x89PNG\r\n\x1a\n")
        out.write(chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)))
        out.write(chunk(b"IDAT", zlib.compress(b"".join(rows), 9)))
        out.write(chunk(b"IEND", b""))


# A leaf's outline: how far along it, and how wide there, as shares
LEAF_PROFILE = ((0.0, 0.0), (0.16, 0.5), (0.4, 1.0), (0.66, 0.72), (0.84, 0.36), (1.0, 0.0))


class Piece:
    """Solid shapes in Roblox's axes: X your right, Y up, -Z ahead of you."""

    def __init__(self):
        self.shapes = []  # each: (points, [(face indices, swatch)])

    def shape(self, points, faces):
        """A closed shape. Faces are turned to look away from its middle if `outward` is left on."""
        self.shapes.append((points, faces))

    def box(self, x0, x1, y0, y1, z0, z1, swatch, cut=0.025):
        """A box with its edges cut, so it catches the light like the reference's."""
        cx, cy, cz = (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2
        hx, hy, hz = (x1 - x0) / 2, (y1 - y0) / 2, (z1 - z0) / 2
        cut = min(cut, hx * 0.45, hy * 0.45, hz * 0.45)
        points, faces = [], []
        index = {}
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    for axis in range(3):
                        p = [sx * (hx - cut), sy * (hy - cut), sz * (hz - cut)]
                        p[axis] = (sx, sy, sz)[axis] * (hx, hy, hz)[axis]
                        index[(sx, sy, sz, axis)] = len(points)
                        points.append((cx + p[0], cy + p[1], cz + p[2]))
        # The six sides
        for axis in range(3):
            for s in (-1, 1):
                ring = []
                other = [a for a in range(3) if a != axis]
                for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                    corner = [0, 0, 0]
                    corner[axis] = s
                    corner[other[0]] = a
                    corner[other[1]] = b
                    ring.append(index[(*corner, axis)])
                faces.append((ring, swatch))
        # The cut edges
        for axis in range(3):
            other = [a for a in range(3) if a != axis]
            for a in (-1, 1):
                for b in (-1, 1):
                    low = [0, 0, 0]
                    low[other[0]] = a
                    low[other[1]] = b
                    low[axis] = -1
                    high = list(low)
                    high[axis] = 1
                    ring = [index[(*low, other[0])], index[(*low, other[1])], index[(*high, other[1])], index[(*high, other[0])]]
                    faces.append((ring, swatch))
        # The cut corners
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    faces.append(([index[(sx, sy, sz, 0)], index[(sx, sy, sz, 1)], index[(sx, sy, sz, 2)]], swatch))
        self.shape(points, faces)

    def plate(self, outline, z_front, depth, swatch, side_swatch=None):
        """A flat shape on the front of something, from (x, y) points. It faces -Z, standing `depth` proud."""
        n = len(outline)
        z_back = z_front + depth
        points = [(x, y, z_front) for x, y in outline] + [(x, y, z_back) for x, y in outline]
        faces = [(list(range(n)), swatch), (list(range(n, 2 * n)), swatch)]
        for i in range(n):
            j = (i + 1) % n
            faces.append(([i, j, j + n, i + n], side_swatch or swatch))
        self.shape(points, faces)

    def back_plate(self, outline, z_front, depth, swatch, side_swatch=None):
        """The same on the back: it faces +Z."""
        n = len(outline)
        z_back = z_front - depth
        points = [(x, y, z_front) for x, y in outline] + [(x, y, z_back) for x, y in outline]
        faces = [(list(range(n)), swatch), (list(range(n, 2 * n)), swatch)]
        for i in range(n):
            j = (i + 1) % n
            faces.append(([i, j, j + n, i + n], side_swatch or swatch))
        self.shape(points, faces)

    def crystal(self, base, direction, length, radius, sides=6):
        """A faceted crystal growing from `base`: facets take turns being light and shaded."""
        base = Vector(base)
        d = Vector(direction).normalized()
        up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
        u = d.cross(up).normalized()
        v = d.cross(u).normalized()
        rings = ((0.0, 0.7), (0.62, 1.0))
        points, faces = [], []
        for t, r in rings:
            for i in range(sides):
                a = 2 * math.pi * i / sides
                p = base + d * (length * t) + (u * math.cos(a) + v * math.sin(a)) * radius * r
                points.append(tuple(p))
        tip = len(points)
        points.append(tuple(base + d * length))
        shades = ("Trim", "Trim2", "Trim3", "Trim", "Trim2", "Trim3", "Trim", "Trim2")
        for i in range(sides):
            j = (i + 1) % sides
            faces.append(([i, j, j + sides, i + sides], shades[i % len(shades)]))
            faces.append(([i + sides, j + sides, tip], shades[(i + 1) % len(shades)]))
        faces.append((list(range(sides)), "Trim3"))
        self.shape(points, faces)

    def hexagon(self, cx, cy, radius, z_front, depth, swatch, side_swatch=None, tall=1.0):
        outline = []
        for i in range(6):
            a = math.pi / 2 + i * math.pi / 3
            outline.append((cx + radius * math.cos(a), cy + radius * tall * math.sin(a)))
        self.plate(outline, z_front, depth, swatch, side_swatch)

    def prism(self, a, b, radius, swatch, side_swatch=None):
        """A square rod from a to b, for stalks."""
        a, b = Vector(a), Vector(b)
        d = (b - a).normalized()
        up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
        u = d.cross(up).normalized() * radius
        v = d.cross(u).normalized() * radius
        corners = (u + v, u - v, -u - v, -u + v)
        points = [tuple(a + c) for c in corners] + [tuple(b + c) for c in corners]
        faces = [([0, 1, 2, 3], swatch), ([4, 5, 6, 7], swatch)]
        for i in range(4):
            j = (i + 1) % 4
            faces.append(([i, j, j + 4, i + 4], side_swatch or swatch))
        self.shape(points, faces)

    def thorn(self, base, direction, length, radius):
        """A sharp four-sided spike."""
        base = Vector(base)
        d = Vector(direction).normalized()
        up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
        u = d.cross(up).normalized()
        v = d.cross(u).normalized()
        points = [tuple(base + (u * math.cos(i * math.pi / 2) + v * math.sin(i * math.pi / 2)) * radius) for i in range(4)]
        points.append(tuple(base + d * length))
        faces = [([0, 1, 2, 3], "Trim3")]
        for i in range(4):
            faces.append(([i, (i + 1) % 4, 4], ("Trim", "Trim2")[i % 2]))
        self.shape(points, faces)

    def leaf(self, base, direction, length, width, face=(0, 0, -1), thick=0.055):
        """A pointed leaf, faceted from a ridge down its middle. `face` is roughly the way its flat side looks."""
        base = Vector(base)
        d = Vector(direction).normalized()
        n = Vector(face)
        n = (n - d * n.dot(d)).normalized()
        w = n.cross(d).normalized()
        right = [base + d * (length * t) + w * (width * a) for t, a in LEAF_PROFILE]
        left = [base + d * (length * t) - w * (width * a) for t, a in reversed(LEAF_PROFILE[1:-1])]
        outline = right + left
        middle = base + d * (length * 0.42)
        points = [tuple(p) for p in outline] + [tuple(middle + n * thick), tuple(middle - n * thick)]
        top, bottom = len(outline), len(outline) + 1
        faces = []
        for i in range(len(outline)):
            j = (i + 1) % len(outline)
            faces.append(([i, j, top], "Trim" if i < len(right) - 1 else "Trim2"))
            faces.append(([i, j, bottom], "Trim3"))
        self.shape(points, faces)

    def kernel(self, centre, direction, length, radius, swatch):
        """A grain of wheat: pointed at both ends."""
        c = Vector(centre)
        d = Vector(direction).normalized()
        up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
        u = d.cross(up).normalized() * radius
        v = d.cross(u).normalized() * radius
        points = [tuple(c - d * (length / 2)), tuple(c + d * (length / 2))]
        points += [tuple(c + u), tuple(c + v), tuple(c - u), tuple(c - v)]
        faces = []
        for i in range(4):
            a, b = 2 + i, 2 + (i + 1) % 4
            faces.append(([0, a, b], "Trim3"))
            faces.append(([1, a, b], swatch))
        self.shape(points, faces)

    def wheat(self, base, direction, length):
        """A stalk of wheat: a thin stem, grains in two rows at the top, and a spike at the tip."""
        base = Vector(base)
        d = Vector(direction).normalized()
        up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
        side = d.cross(up).normalized()
        self.prism(base, base + d * (length * 0.7), 0.042, "Trim3")
        # A tight, fat ear: the grains in two rows, overlapping
        for i in range(8):
            t = 0.54 + i * 0.058
            s = 1 if i % 2 == 0 else -1
            at = base + d * (length * t) + side * (s * 0.05)
            self.kernel(at, d + side * (s * 0.26), 0.25, 0.075, "Trim" if i % 2 == 0 else "Trim2")
        self.kernel(base + d * (length * 0.99), d, 0.26, 0.062, "Trim")

    def sunflower(self, centre, facing, radius, petals=10):
        """A sunflower: pointed petals round a dark, raised disc."""
        c = Vector(centre)
        n = Vector(facing).normalized()
        up = Vector((0, 1, 0)) if abs(n.y) < 0.9 else Vector((1, 0, 0))
        a = n.cross(up).normalized()
        b = n.cross(a).normalized()
        disc = radius * 0.46
        half = math.pi * disc / petals * 1.3
        for i in range(petals):
            angle = 2 * math.pi * i / petals
            r = a * math.cos(angle) + b * math.sin(angle)
            t = r.cross(n).normalized()
            outline = [
                c + r * (disc * 0.7),
                c + r * (disc + (radius - disc) * 0.42) + t * half,
                c + r * radius + n * (radius * 0.08),
                c + r * (disc + (radius - disc) * 0.42) - t * half,
            ]
            points = [tuple(p + n * 0.025) for p in outline] + [tuple(p - n * 0.025) for p in outline]
            swatch = "Trim" if i % 2 == 0 else "Trim2"
            faces = [([0, 1, 2, 3], swatch), ([4, 5, 6, 7], swatch)]
            for k in range(4):
                m = (k + 1) % 4
                faces.append(([k, m, m + 4, k + 4], "Trim3"))
            self.shape(points, faces)
        low = [c - n * 0.02 + (a * math.cos(i * math.pi / 4) + b * math.sin(i * math.pi / 4)) * disc for i in range(8)]
        high = [c + n * 0.085 + (a * math.cos(i * math.pi / 4) + b * math.sin(i * math.pi / 4)) * (disc * 0.72) for i in range(8)]
        points = [tuple(p) for p in low] + [tuple(p) for p in high]
        faces = [(list(range(8)), "Dark3"), (list(range(8, 16)), "Dark3")]
        for i in range(8):
            j = (i + 1) % 8
            faces.append(([i, j, j + 8, i + 8], "Dark2"))
        self.shape(points, faces)

    def build(self, name, side=1):
        """A Blender object: faces turned outward, an outline behind them, and `side` -1 mirrors it for the left."""
        verts, polys, swatches = [], [], []
        for points, faces in self.shapes:
            pts = [Vector((p[0] * side, p[1], p[2])) for p in points]
            middle = sum(pts, Vector()) / len(pts)
            turned = []
            for ring, swatch in faces:
                centre = sum((pts[i] for i in ring), Vector()) / len(ring)
                a, b = pts[ring[1]] - pts[ring[0]], pts[ring[-1]] - pts[ring[0]]
                normal = a.cross(b)
                if len(ring) > 4:
                    # Newell's method, for a shape that isn't convex
                    normal = Vector()
                    for i in range(len(ring)):
                        p, q = pts[ring[i]], pts[ring[(i + 1) % len(ring)]]
                        normal += Vector(((p.y - q.y) * (p.z + q.z), (p.z - q.z) * (p.x + q.x), (p.x - q.x) * (p.y + q.y)))
                if normal.dot(centre - middle) < 0:
                    ring = list(reversed(ring))
                    normal = -normal
                turned.append((ring, swatch, normal.normalized() if normal.length > 0 else Vector((0, 1, 0))))
            # The solid faces, each with its own corners so the shading stays flat
            for ring, swatch, _ in turned:
                start = len(verts)
                verts.extend(tuple(pts[i]) for i in ring)
                polys.append(list(range(start, start + len(ring))))
                swatches.append(swatch)
            # The outline: the same shape pushed out and turned inside out, in black
            sums = {}
            for ring, _, normal in turned:
                for i in ring:
                    key = tuple(round(c, 3) for c in pts[i])
                    sums[key] = sums.get(key, Vector()) + normal
            for ring, _, _ in turned:
                start = len(verts)
                for i in reversed(ring):
                    key = tuple(round(c, 3) for c in pts[i])
                    push = sums[key].normalized() * OUTLINE
                    verts.append(tuple(pts[i] + push))
                polys.append(list(range(start, start + len(ring))))
                swatches.append("Black")

        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], polys)
        mesh.update()
        layer = mesh.uv_layers.new()
        for poly, swatch in zip(mesh.polygons, swatches):
            u, v = swatch_uv(swatch)
            for loop in poly.loop_indices:
                layer.data[loop].uv = (u, v)
            poly.use_smooth = False
        # Roblox only takes triangles, and a concave shape needs cutting up here
        work = bmesh.new()
        work.from_mesh(mesh)
        bmesh.ops.triangulate(work, faces=work.faces[:], quad_method="BEAUTY", ngon_method="BEAUTY")
        work.to_mesh(mesh)
        work.free()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        return obj


# The set for Mining: a dark coat, with crystals bursting off the shoulders ------------------------------------


def burst(piece, origin, count_scale=1.0):
    """The shoulder's showpiece: crystals fanning up and outward, biggest in the middle."""
    x, y, z = origin
    crystals = (
        ((0.45, 1.0, 0.0), 1.15, 0.2),
        ((0.95, 0.7, 0.05), 1.0, 0.18),
        ((-0.1, 1.0, 0.25), 0.85, 0.16),
        ((0.3, 0.8, -0.65), 0.82, 0.15),
        ((0.35, 0.8, 0.7), 0.82, 0.15),
        ((1.0, 0.25, -0.35), 0.72, 0.13),
        ((1.0, 0.25, 0.4), 0.72, 0.13),
    )
    for direction, length, radius in crystals:
        piece.crystal((x, y, z), direction, length * count_scale, radius * count_scale)


def chest_mining():
    p = Piece()
    # The coat
    p.box(-0.84, 0.84, -0.66, 0.98, -0.56, 0.56, "Dark")
    # Open down the front, over a darker waistcoat
    p.plate([(-0.2, 0.96), (0.2, 0.96), (0.2, -0.64), (-0.2, -0.64)], -0.58, 0.04, "Dark3")
    for s in (-1, 1):
        # Lapels, wide at the top
        p.plate([(s * 0.2, 0.96), (s * 0.5, 0.96), (s * 0.36, 0.3), (s * 0.3, -0.64), (s * 0.2, -0.64)], -0.6, 0.05, "Trim", "Trim3")
        # Chevrons down each side
        for y in (0.22, -0.08, -0.38):
            p.plate(
                [(s * 0.46, y), (s * 0.78, y + 0.14), (s * 0.78, y + 0.02), (s * 0.46, y - 0.12)],
                -0.585,
                0.03,
                "Trim2",
                "Trim3",
            )
        # The collar, standing up each side of the neck
        p.box(s * 0.34 - 0.13, s * 0.34 + 0.13, 0.96, 1.2, -0.42, 0.42, "Trim2", 0.03)
    p.box(-0.36, 0.36, 0.96, 1.2, 0.3, 0.52, "Trim2", 0.03)
    # A gem at the throat and one on the chest
    p.hexagon(0, 0.62, 0.16, -0.61, 0.05, "Trim", "Trim3")
    p.hexagon(0, 0.12, 0.11, -0.6, 0.04, "Trim2", "Trim3")
    # The belt
    p.box(-0.87, 0.87, -0.72, -0.54, -0.59, 0.59, "Trim2", 0.02)
    p.box(-0.14, 0.14, -0.76, -0.5, -0.63, -0.56, "Trim", 0.015)
    # Tails: both sides at the front and the whole back, jagged at the bottom
    for s in (-1, 1):
        p.plate(
            [(s * 0.42, -0.7), (s * 0.84, -0.7), (s * 0.84, -1.5), (s * 0.68, -1.68), (s * 0.54, -1.46), (s * 0.42, -1.26)],
            -0.56,
            0.05,
            "Dark2",
            "Trim2",
        )
        p.plate([(s * 0.8, -0.72), (s * 0.84, -0.72), (s * 0.84, -1.5), (s * 0.8, -1.54)], -0.572, 0.02, "Trim")
    p.back_plate(
        [(-0.82, -0.7), (0.82, -0.7), (0.82, -1.56), (0.56, -1.76), (0.28, -1.54), (0, -1.78), (-0.28, -1.54), (-0.56, -1.76), (-0.82, -1.56)],
        0.56,
        0.05,
        "Dark2",
        "Trim2",
    )
    # A big gem and chevrons on the back
    p.back_plate([(0, 0.66), (0.26, 0.3), (0, -0.2), (-0.26, 0.3)], 0.59, 0.04, "Trim", "Trim3")
    for s in (-1, 1):
        p.back_plate([(s * 0.36, 0.58), (s * 0.72, 0.28), (s * 0.72, 0.1), (s * 0.36, 0.4)], 0.58, 0.03, "Trim2", "Trim3")
    return p


def sleeve_mining():
    p = Piece()
    # Over the upper arm: it moves with the arm
    p.box(-0.3, 0.5, -0.42, 0.5, -0.44, 0.34, "Dark")
    p.box(-0.32, 0.52, -0.46, -0.3, -0.46, 0.36, "Trim2", 0.02)
    return p


def pauldron_mining():
    p = Piece()
    # A wide square shoulder, with the crystals bursting from its outer top corner. It rides on the chest and not
    # the arm: on the arm, lifting a sword swings the crystals across your face.
    p.box(-0.34, 0.6, 0.44, 0.72, -0.52, 0.42, "Trim2", 0.03)
    p.box(-0.3, 0.56, 0.68, 0.8, -0.46, 0.36, "Trim", 0.02)
    burst(p, (0.16, 0.76, -0.05))
    return p


def forearm_mining():
    p = Piece()
    p.box(-0.38, 0.34, -0.34, 0.42, -0.42, 0.3, "Dark")
    # A big cuff, with a few crystals on its outside
    p.box(-0.42, 0.42, -0.62, -0.28, -0.52, 0.34, "Trim2", 0.03)
    p.box(-0.44, 0.44, -0.36, -0.28, -0.54, 0.36, "Trim", 0.015)
    p.crystal((0.38, -0.46, -0.1), (1, 0.45, 0.0), 0.5, 0.11)
    p.crystal((0.38, -0.46, -0.3), (1, 0.2, -0.5), 0.36, 0.09)
    p.crystal((0.38, -0.46, 0.12), (1, 0.2, 0.5), 0.36, 0.09)
    return p


def hips_mining():
    p = Piece()
    p.box(-0.76, 0.76, -0.42, 0.16, -0.52, 0.48, "Dark2")
    p.box(-0.78, 0.78, -0.02, 0.16, -0.54, 0.5, "Dark3", 0.02)
    return p


def thigh_mining():
    p = Piece()
    p.box(-0.28, 0.46, -0.6, 0.5, -0.42, 0.42, "Dark")
    # A hexagonal knee guard, and a stripe down the outside
    p.hexagon(0.09, -0.42, 0.24, -0.45, 0.06, "Trim", "Trim3", 1.1)
    p.hexagon(0.09, -0.42, 0.12, -0.5, 0.03, "Trim3", "Trim3", 1.1)
    p.box(0.42, 0.49, -0.5, 0.44, -0.16, 0.16, "Trim2", 0.015)
    return p


def boot_mining():
    p = Piece()
    # The shin, a wide top and a toe
    p.box(-0.3, 0.44, -0.66, 0.34, -0.42, 0.4, "Dark")
    p.box(-0.34, 0.48, 0.14, 0.38, -0.46, 0.44, "Trim2", 0.03)
    p.box(-0.3, 0.44, -0.72, -0.36, -0.88, 0.4, "Dark2")
    # A thick sole and a toe cap, in the armour's colour
    p.box(-0.34, 0.48, -0.78, -0.62, -0.92, 0.44, "Trim", 0.02)
    p.box(-0.3, 0.44, -0.66, -0.4, -0.94, -0.62, "Trim2", 0.03)
    # A crystal at the ankle
    p.crystal((0.42, -0.36, 0.0), (1, 0.6, 0.15), 0.36, 0.09)
    return p


def helmet_mining():
    p = Piece()
    # A square helm round the head, open at the face
    p.box(-0.62, 0.62, 0.44, 0.66, -0.62, 0.62, "Dark")
    p.box(-0.62, -0.5, -0.46, 0.46, -0.62, 0.62, "Dark")
    p.box(0.5, 0.62, -0.46, 0.46, -0.62, 0.62, "Dark")
    p.box(-0.5, 0.5, -0.46, 0.46, 0.5, 0.62, "Dark")
    # Bands round the back and sides, and a gem on the back
    p.box(-0.65, 0.65, 0.18, 0.3, -0.5, 0.65, "Trim2", 0.02)
    p.box(-0.65, 0.65, -0.5, -0.36, -0.5, 0.65, "Trim3", 0.02)
    p.back_plate([(0, 0.14), (0.14, -0.08), (0, -0.3), (-0.14, -0.08)], 0.66, 0.03, "Trim", "Trim3")
    # A brow over the face, with a gem like a lamp
    p.box(-0.66, 0.66, 0.24, 0.46, -0.68, -0.5, "Trim2", 0.03)
    p.hexagon(0, 0.35, 0.12, -0.71, 0.05, "Trim", "Trim3")
    # Cheek guards
    for s in (-1, 1):
        p.box(s * 0.56 - 0.09, s * 0.56 + 0.09, -0.5, 0.24, -0.68, -0.44, "Trim3", 0.03)
    # Crystals out of the top
    p.crystal((0.0, 0.68, 0.05), (0.0, 1, 0.1), 0.72, 0.16)
    p.crystal((0.26, 0.68, 0.05), (0.45, 1, 0.1), 0.5, 0.12)
    p.crystal((-0.26, 0.68, 0.05), (-0.45, 1, 0.1), 0.5, 0.12)
    return p


# What every set shares -------------------------------------------------------------------------------------


def coat(p):
    p.box(-0.84, 0.84, -0.66, 0.98, -0.56, 0.56, "Dark")
    # A collar, standing up each side of the neck
    for s in (-1, 1):
        p.box(s * 0.34 - 0.13, s * 0.34 + 0.13, 0.96, 1.2, -0.42, 0.42, "Trim2", 0.03)
    p.box(-0.36, 0.36, 0.96, 1.2, 0.3, 0.52, "Trim2", 0.03)


def pauldron_base(p):
    p.box(-0.34, 0.6, 0.44, 0.72, -0.52, 0.42, "Trim2", 0.03)
    p.box(-0.3, 0.56, 0.68, 0.8, -0.46, 0.36, "Trim", 0.02)


def forearm_base(p):
    p.box(-0.38, 0.34, -0.34, 0.42, -0.42, 0.3, "Dark")
    p.box(-0.42, 0.42, -0.62, -0.28, -0.52, 0.34, "Trim2", 0.03)
    p.box(-0.44, 0.44, -0.36, -0.28, -0.54, 0.36, "Trim", 0.015)


def boot_base(p):
    p.box(-0.3, 0.44, -0.66, 0.34, -0.42, 0.4, "Dark")
    p.box(-0.34, 0.48, 0.14, 0.38, -0.46, 0.44, "Trim2", 0.03)
    p.box(-0.3, 0.44, -0.72, -0.36, -0.88, 0.4, "Dark2")
    p.box(-0.34, 0.48, -0.78, -0.62, -0.92, 0.44, "Trim", 0.02)
    p.box(-0.3, 0.44, -0.66, -0.4, -0.94, -0.62, "Trim2", 0.03)


def band(a, b, half):
    """A straight strip from (x, y) to (x, y), for a plate."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy)
    px, py = -dy / length * half, dx / length * half
    return [(a[0] + px, a[1] + py), (b[0] + px, b[1] + py), (b[0] - px, b[1] - py), (a[0] - px, a[1] - py)]


def leaf_plate(x, y, angle, length, width):
    """A leaf's outline lying flat on a surface: its stem at (x, y), its tip toward `angle` (degrees)."""
    dx, dy = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    px, py = -dy, dx
    right = [(x + dx * length * t + px * width * a, y + dy * length * t + py * width * a) for t, a in LEAF_PROFILE]
    left = [(x + dx * length * t - px * width * a, y + dy * length * t - py * width * a) for t, a in reversed(LEAF_PROFILE[1:-1])]
    return right + left


def thorn_plate(x, y, angle, length, width):
    """A thorn lying flat on a surface."""
    dx, dy = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    px, py = -dy, dx
    return [(x + px * width, y + py * width), (x + dx * length, y + dy * length), (x - px * width, y - py * width)]


# The set for Woodcutting: a dark coat with a thorny vine climbing it, and leaves bursting off the shoulders ----


def chest_woodcutting():
    p = Piece()
    coat(p)
    # Toggles down the middle
    p.plate([(-0.13, 0.96), (0.13, 0.96), (0.13, -0.64), (-0.13, -0.64)], -0.58, 0.04, "Dark3")
    for y in (0.76, 0.3, -0.2):
        p.hexagon(0, y, 0.08, -0.6, 0.03, "Trim2", "Trim3", 1.3)
    # The vine, climbing from the left hip to the right shoulder
    vine = ((-0.76, -0.5), (-0.36, -0.2), (0.08, -0.36), (0.6, -0.06), (0.5, 0.3), (-0.02, 0.2), (-0.56, 0.42), (-0.38, 0.76), (0.22, 0.76), (0.64, 0.62))
    for a, b in zip(vine, vine[1:]):
        p.plate(band(a, b, 0.055), -0.63, 0.08, "Trim", "Trim3")
    for x, y, angle in ((-0.5, -0.32, 155), (0.32, -0.22, -55), (0.6, 0.1, 25), (0.2, 0.26, 95), (-0.36, 0.34, 215), (-0.46, 0.62, 165), (0.0, 0.76, 80), (0.48, 0.7, 60)):
        p.plate(leaf_plate(x, y, angle, 0.3, 0.1), -0.64, 0.05, "Trim2", "Trim3")
    for x, y, angle in ((-0.14, -0.27, 240), (0.34, -0.2, 70), (0.26, 0.24, -80), (-0.28, 0.32, 80), (-0.1, 0.76, -90), (0.42, 0.7, -80)):
        p.plate(thorn_plate(x, y, angle, 0.16, 0.05), -0.635, 0.05, "Trim", "Trim3")
    # The belt
    p.box(-0.87, 0.87, -0.72, -0.54, -0.59, 0.59, "Trim2", 0.02)
    p.box(-0.14, 0.14, -0.76, -0.5, -0.63, -0.56, "Trim", 0.015)
    # Tails ending in leaf points
    for s in (-1, 1):
        p.plate([(s * 0.42, -0.7), (s * 0.84, -0.7), (s * 0.84, -1.34), (s * 0.63, -1.7), (s * 0.42, -1.3)], -0.56, 0.05, "Dark2", "Trim2")
        p.plate(band((s * 0.63, -0.78), (s * 0.63, -1.5), 0.02), -0.572, 0.02, "Trim3")
    p.back_plate(
        [(-0.82, -0.7), (0.82, -0.7), (0.82, -1.32), (0.55, -1.72), (0.28, -1.32), (0, -1.76), (-0.28, -1.32), (-0.55, -1.72), (-0.82, -1.32)],
        0.56,
        0.05,
        "Dark2",
        "Trim2",
    )
    # A great leaf up the back, with two smaller ones
    p.back_plate(leaf_plate(0, -0.46, 90, 1.26, 0.36), 0.6, 0.04, "Trim", "Trim3")
    p.back_plate(band((0, -0.4), (0, 0.66), 0.025), 0.625, 0.03, "Dark3")
    for s in (-1, 1):
        p.back_plate(leaf_plate(s * 0.12, -0.4, 90 - s * 48, 0.74, 0.2), 0.585, 0.03, "Trim2", "Trim3")
    return p


def sleeve_woodcutting():
    p = Piece()
    p.box(-0.3, 0.5, -0.42, 0.5, -0.44, 0.34, "Dark")
    p.box(-0.32, 0.52, -0.46, -0.3, -0.46, 0.36, "Trim2", 0.02)
    p.thorn((0.48, 0.12, -0.14), (1, 0.15, -0.1), 0.26, 0.07)
    p.thorn((0.48, -0.1, 0.1), (1, 0.15, 0.1), 0.26, 0.07)
    return p


def pauldron_woodcutting():
    p = Piece()
    pauldron_base(p)
    at = (0.16, 0.76, -0.05)
    for direction, length, width, face in (
        ((0.42, 1.0, 0.0), 1.3, 0.3, (0, 0, -1)),
        ((1.0, 0.72, 0.0), 1.14, 0.28, (0, 0, -1)),
        ((0.06, 1.0, 0.42), 0.98, 0.24, (1, 0, 0)),
        ((0.3, 0.82, -0.72), 0.94, 0.24, (1, 0, 0)),
        ((0.35, 0.8, 0.78), 0.94, 0.24, (1, 0, 0)),
        ((1.0, 0.2, -0.48), 0.84, 0.21, (0, 1, 0)),
        ((1.0, 0.2, 0.48), 0.84, 0.21, (0, 1, 0)),
    ):
        p.leaf(at, direction, length, width, face)
    # Thorns off the rim
    p.thorn((0.56, 0.6, -0.42), (1, 0.05, -0.55), 0.34, 0.08)
    p.thorn((0.56, 0.6, 0.34), (1, 0.05, 0.55), 0.34, 0.08)
    p.thorn((-0.2, 0.6, -0.5), (-0.1, 0.1, -1), 0.3, 0.07)
    return p


def forearm_woodcutting():
    p = Piece()
    forearm_base(p)
    p.leaf((0.36, -0.44, -0.08), (1, 0.42, -0.1), 0.56, 0.15, (0, 0, -1))
    p.thorn((0.38, -0.44, -0.34), (1, 0.15, -0.5), 0.34, 0.08)
    p.thorn((0.38, -0.44, 0.16), (1, 0.15, 0.5), 0.34, 0.08)
    return p


def thigh_woodcutting():
    p = Piece()
    p.box(-0.28, 0.46, -0.6, 0.5, -0.42, 0.42, "Dark")
    # A leaf over the knee, and a stripe down the outside
    p.plate(leaf_plate(0.09, -0.62, 90, 0.56, 0.2), -0.46, 0.05, "Trim", "Trim3")
    p.plate(band((0.09, -0.58), (0.09, -0.14), 0.018), -0.475, 0.02, "Dark3")
    p.box(0.42, 0.49, -0.5, 0.44, -0.16, 0.16, "Trim2", 0.015)
    return p


def boot_woodcutting():
    p = Piece()
    boot_base(p)
    p.leaf((0.42, -0.36, 0.0), (1, 0.62, 0.12), 0.42, 0.12, (0, 0, -1))
    p.thorn((0.42, -0.1, -0.24), (1, 0.2, -0.3), 0.24, 0.06)
    return p


def helmet_woodcutting():
    p = Piece()
    # A hood round the head, open at the face, with a peak
    p.box(-0.62, 0.62, 0.44, 0.66, -0.62, 0.62, "Dark")
    p.box(-0.62, -0.5, -0.46, 0.46, -0.62, 0.62, "Dark")
    p.box(0.5, 0.62, -0.46, 0.46, -0.62, 0.62, "Dark")
    p.box(-0.5, 0.5, -0.46, 0.46, 0.5, 0.62, "Dark")
    p.shape(
        [(-0.62, 0.64, -0.62), (0.62, 0.64, -0.62), (0.62, 0.64, 0.62), (-0.62, 0.64, 0.62), (-0.22, 1.02, -0.3), (0.22, 1.02, -0.3), (0.22, 0.88, 0.5), (-0.22, 0.88, 0.5)],
        [
            ([0, 1, 2, 3], "Dark"),
            ([4, 5, 6, 7], "Dark2"),
            ([0, 1, 5, 4], "Dark2"),
            ([1, 2, 6, 5], "Dark"),
            ([2, 3, 7, 6], "Dark"),
            ([3, 0, 4, 7], "Dark"),
        ],
    )
    p.box(-0.65, 0.65, -0.5, -0.36, -0.5, 0.65, "Trim3", 0.02)
    # A band of bark over the brow, with a leaf at its middle
    p.box(-0.66, 0.66, 0.24, 0.46, -0.68, -0.5, "Trim2", 0.03)
    p.plate(leaf_plate(0, 0.16, 90, 0.42, 0.14), -0.72, 0.05, "Trim", "Trim3")
    for s in (-1, 1):
        p.box(s * 0.56 - 0.09, s * 0.56 + 0.09, -0.5, 0.24, -0.68, -0.44, "Trim3", 0.03)
    # A crown of leaves out of the top, and thorns behind
    p.leaf((0.0, 0.98, -0.1), (0.0, 1, 0.08), 0.72, 0.2, (0, 0, -1))
    p.leaf((0.2, 0.92, -0.1), (0.62, 1, 0.08), 0.56, 0.16, (0, 0, -1))
    p.leaf((-0.2, 0.92, -0.1), (-0.62, 1, 0.08), 0.56, 0.16, (0, 0, -1))
    p.back_plate(leaf_plate(0, -0.3, 90, 0.54, 0.17), 0.66, 0.03, "Trim", "Trim3")
    return p


# The set for Farming: a laced dark coat under a wide hat, wheat sheaves on the shoulders, sunflowers ------------


def chest_farming():
    p = Piece()
    coat(p)
    # Laced up the middle
    p.plate([(-0.2, 0.96), (0.2, 0.96), (0.2, -0.64), (-0.2, -0.64)], -0.58, 0.04, "Dark3")
    rows = [0.84 - i * 0.2 for i in range(8)]
    for i in range(len(rows) - 1):
        for s in (-1, 1):
            p.plate(band((s * 0.15, rows[i]), (-s * 0.15, rows[i + 1]), 0.024), -0.605, 0.03, "Trim2", "Trim3")
    # Patches on each side, with a stitched edge, and a sunflower over the heart
    for s in (-1, 1):
        p.plate([(s * 0.3, 0.32), (s * 0.76, 0.32), (s * 0.76, -0.46), (s * 0.3, -0.46)], -0.575, 0.03, "Dark2", "Trim3")
        for y in (0.16, -0.08, -0.32):
            p.plate(band((s * 0.36, y), (s * 0.7, y), 0.02), -0.59, 0.02, "Trim3")
    p.sunflower((0.52, 0.64, -0.6), (0, 0, -1), 0.3, 9)
    # A rope belt, with a knot at the front
    p.box(-0.87, 0.87, -0.7, -0.56, -0.59, 0.59, "Dark3", 0.015)
    for i in range(14):
        x = -0.84 + i * 0.13
        p.plate([(x, -0.56), (x + 0.1, -0.56), (x + 0.03, -0.7), (x - 0.07, -0.7)], -0.61, 0.03, "Trim" if i % 2 == 0 else "Trim2", "Trim3")
    p.box(-0.13, 0.13, -0.76, -0.5, -0.65, -0.57, "Trim", 0.03)
    # Skirts, ending in a straw fringe
    for s in (-1, 1):
        p.plate([(s * 0.3, -0.7), (s * 0.84, -0.7), (s * 0.84, -1.16), (s * 0.3, -1.16)], -0.56, 0.05, "Dark2", "Trim2")
        tips = [(s * (0.3 + i * 0.09), -1.1 if i % 2 == 0 else -1.5) for i in range(7)]
        p.plate([(s * 0.3, -1.04), (s * 0.84, -1.04)] + list(reversed(tips)), -0.57, 0.03, "Trim2", "Trim3")
    p.back_plate([(-0.82, -0.7), (0.82, -0.7), (0.82, -1.16), (-0.82, -1.16)], 0.56, 0.05, "Dark2", "Trim2")
    tips = [(0.82 - i * 0.137, -1.1 if i % 2 == 0 else -1.52) for i in range(13)]
    p.back_plate([(-0.82, -1.04), (0.82, -1.04)] + tips, 0.575, 0.03, "Trim2", "Trim3")
    # A great sunflower across the back
    p.sunflower((0, 0.22, 0.6), (0, 0, 1), 0.62, 14)
    return p


def sleeve_farming():
    p = Piece()
    p.box(-0.3, 0.5, -0.42, 0.5, -0.44, 0.34, "Dark")
    p.box(-0.32, 0.52, -0.46, -0.3, -0.46, 0.36, "Trim2", 0.02)
    p.box(-0.32, 0.52, -0.16, -0.08, -0.46, 0.36, "Trim3", 0.015)
    return p


def pauldron_farming():
    p = Piece()
    pauldron_base(p)
    at = (0.14, 0.72, -0.05)
    for direction, length in (
        ((0.28, 1.0, 0.0), 1.36),
        ((0.62, 1.0, 0.1), 1.26),
        ((0.98, 0.8, -0.04), 1.14),
        ((0.14, 1.0, -0.46), 1.1),
        ((0.16, 1.0, 0.5), 1.1),
        ((0.76, 0.82, -0.56), 1.04),
        ((0.76, 0.82, 0.56), 1.04),
    ):
        p.wheat(at, direction, length)
    # Tied round the middle
    p.box(-0.06, 0.36, 0.78, 0.94, -0.26, 0.16, "Dark3", 0.02)
    # A sunflower on the outside
    p.sunflower((0.64, 0.6, -0.05), (1, 0.12, 0), 0.32, 9)
    return p


def forearm_farming():
    p = Piece()
    forearm_base(p)
    p.wheat((0.36, -0.44, -0.2), (1, 0.55, -0.32), 0.5)
    p.wheat((0.36, -0.44, 0.02), (1, 0.55, 0.32), 0.5)
    return p


def thigh_farming():
    p = Piece()
    p.box(-0.28, 0.46, -0.6, 0.5, -0.42, 0.42, "Dark")
    # A sunflower over the knee, and a stripe down the outside
    p.sunflower((0.09, -0.36, -0.46), (0, 0, -1), 0.3, 9)
    p.box(0.42, 0.49, -0.5, 0.44, -0.16, 0.16, "Trim2", 0.015)
    return p


def boot_farming():
    p = Piece()
    boot_base(p)
    p.wheat((0.42, -0.34, 0.0), (1, 0.72, 0.12), 0.46)
    return p


def helmet_farming():
    p = Piece()
    # Cloth under the hat, so your face shows and the back of your head doesn't
    p.box(-0.62, 0.62, -0.46, 0.36, 0.5, 0.62, "Dark")
    for s in (-1, 1):
        p.box(s * 0.56 - 0.06, s * 0.56 + 0.06, -0.46, 0.36, 0.0, 0.62, "Dark")
    # A wide hat: the brim, the crown and a dark band
    corners = []
    for x, z in ((1.02, 0.56), (0.56, 1.02), (-0.56, 1.02), (-1.02, 0.56), (-1.02, -0.56), (-0.56, -1.02), (0.56, -1.02), (1.02, -0.56)):
        corners.append((x, z))
    low = [(x, 0.32, z) for x, z in corners]
    high = [(x * 0.94, 0.44, z * 0.94) for x, z in corners]
    faces = [(list(range(8)), "Trim3"), (list(range(8, 16)), "Trim")]
    for i in range(8):
        j = (i + 1) % 8
        faces.append(([i, j, j + 8, i + 8], "Trim2"))
    p.shape(low + high, faces)
    p.box(-0.6, 0.6, 0.44, 0.96, -0.6, 0.6, "Trim2", 0.04)
    p.box(-0.63, 0.63, 0.44, 0.6, -0.63, 0.63, "Dark3", 0.02)
    # A sunflower on the band, with wheat tucked in behind it
    p.wheat((-0.44, 0.52, -0.6), (-0.3, 1, -0.12), 0.66)
    p.wheat((-0.3, 0.52, -0.62), (-0.08, 1, -0.2), 0.58)
    p.sunflower((0.34, 0.6, -0.66), (0, 0.05, -1), 0.26, 9)
    return p


# The first armour kit, Stormcaller: a dark coat split by lightning, and a storm bursting off each shoulder ------

# A lightning bolt in three straight chunks, as (along it, across it), so each stays a simple solid
BOLT = (
    ((0.0, -0.3), (0.0, 0.55), (0.52, 0.22), (0.52, -0.62)),
    ((0.4, -0.08), (0.4, 0.7), (0.74, 0.28), (0.74, -0.34)),
    ((0.62, -0.2), (0.62, 0.44), (1.0, -0.55)),
)


def bolt(piece, base, direction, length, width, face=(0, 0, -1), thick=0.05, swatch="Trim", side="Trim3"):
    """A flat lightning bolt growing from `base`. `face` is roughly the way its flat side looks."""
    base = Vector(base)
    d = Vector(direction).normalized()
    n = Vector(face)
    n = (n - d * n.dot(d)).normalized()
    w = n.cross(d).normalized()
    for chunk in BOLT:
        outline = [base + d * (length * t) + w * (width * a) for t, a in chunk]
        count = len(outline)
        points = [tuple(p + n * thick) for p in outline] + [tuple(p - n * thick) for p in outline]
        faces = [(list(range(count)), swatch), (list(range(count, 2 * count)), swatch)]
        for i in range(count):
            j = (i + 1) % count
            faces.append(([i, j, j + count, i + count], side))
        piece.shape(points, faces)


def cloud(piece, x, y, z, s=1.0):
    """A blocky storm cloud: stacked boxes, shaded underneath and lit on top."""
    piece.box(x - 0.48 * s, x + 0.48 * s, y - 0.12 * s, y + 0.14 * s, z - 0.44 * s, z + 0.44 * s, "Trim3", 0.03)
    piece.box(x - 0.32 * s, x + 0.36 * s, y + 0.1 * s, y + 0.36 * s, z - 0.32 * s, z + 0.32 * s, "Trim2", 0.03)
    piece.box(x - 0.14 * s, x + 0.2 * s, y + 0.32 * s, y + 0.5 * s, z - 0.17 * s, z + 0.17 * s, "Trim", 0.03)


def chest_stormcaller():
    p = Piece()
    p.box(-0.84, 0.84, -0.66, 0.98, -0.56, 0.56, "Dark")
    # A high collar, open at the throat
    for s in (-1, 1):
        p.box(s * 0.4 - 0.14, s * 0.4 + 0.14, 0.96, 1.22, -0.44, 0.44, "Trim2", 0.03)
    p.box(-0.42, 0.42, 0.96, 1.22, 0.3, 0.54, "Trim2", 0.03)
    # A dark yoke across the top, and one great bolt down the front
    p.plate([(-0.82, 0.96), (0.82, 0.96), (0.82, 0.62), (0.34, 0.46), (-0.34, 0.46), (-0.82, 0.62)], -0.58, 0.04, "Dark2", "Trim3")
    bolt(p, (0.03, 0.88, -0.64), (0, -1, 0), 1.56, 0.42, thick=0.04)
    for s in (-1, 1):
        # Chevrons down each side, like the storm's rain
        for y in (0.2, -0.1, -0.4):
            p.plate([(s * 0.5, y), (s * 0.8, y + 0.13), (s * 0.8, y + 0.01), (s * 0.5, y - 0.12)], -0.585, 0.03, "Trim2", "Trim3")
    # The belt
    p.box(-0.87, 0.87, -0.72, -0.54, -0.59, 0.59, "Trim2", 0.02)
    p.hexagon(0, -0.63, 0.13, -0.63, 0.05, "Trim", "Trim3")
    # Jagged tails at the front and the back
    for s in (-1, 1):
        p.plate([(s * 0.42, -0.7), (s * 0.84, -0.7), (s * 0.84, -1.42), (s * 0.7, -1.26), (s * 0.62, -1.66), (s * 0.5, -1.3), (s * 0.42, -1.4)], -0.56, 0.05, "Dark2", "Trim2")
    p.back_plate(
        [(-0.82, -0.7), (0.82, -0.7), (0.82, -1.44), (0.62, -1.28), (0.48, -1.74), (0.26, -1.34), (0, -1.8), (-0.26, -1.34), (-0.48, -1.74), (-0.62, -1.28), (-0.82, -1.44)],
        0.56,
        0.05,
        "Dark2",
        "Trim2",
    )
    # A great bolt down the back too
    bolt(p, (0.03, 0.84, 0.64), (0, -1, 0), 1.46, 0.46, face=(0, 0, 1), thick=0.04)
    return p


def sleeve_stormcaller():
    p = Piece()
    p.box(-0.3, 0.5, -0.42, 0.5, -0.44, 0.34, "Dark")
    p.box(-0.32, 0.52, -0.46, -0.3, -0.46, 0.36, "Trim2", 0.02)
    return p


def pauldron_stormcaller():
    p = Piece()
    # A wide shoulder under a storm cloud, with bolts bursting up and outward. It rides on the chest, like every set.
    p.box(-0.34, 0.6, 0.44, 0.72, -0.52, 0.42, "Trim2", 0.03)
    p.box(-0.3, 0.56, 0.68, 0.8, -0.46, 0.36, "Dark2", 0.02)
    cloud(p, 0.3, 0.92, -0.05, 1.1)  # Kept out past the helmet
    # No taller than the Mining set's crystals, so a raised sword clears them (art/scripts/sword_fit/check.py)
    bolt(p, (0.34, 1.2, -0.05), (0.55, 1.0, 0.0), 0.74, 0.4, face=(0, 0, -1), thick=0.07)
    bolt(p, (0.72, 1.0, -0.05), (1.0, 0.4, 0.0), 0.86, 0.36, face=(0, 0, -1), thick=0.07)
    return p


def forearm_stormcaller():
    p = Piece()
    p.box(-0.38, 0.34, -0.34, 0.42, -0.42, 0.3, "Dark")
    p.box(-0.42, 0.42, -0.62, -0.28, -0.52, 0.34, "Trim2", 0.03)
    p.box(-0.44, 0.44, -0.36, -0.28, -0.54, 0.36, "Trim", 0.015)
    bolt(p, (0.4, -0.5, -0.1), (1, 0.55, 0.0), 0.62, 0.22, face=(0, 0, -1))
    return p


def thigh_stormcaller():
    p = Piece()
    p.box(-0.28, 0.46, -0.6, 0.5, -0.42, 0.42, "Dark")
    # A bolt strikes down to the knee guard, with a stripe down the outside
    p.hexagon(0.09, -0.42, 0.24, -0.45, 0.06, "Trim2", "Trim3", 1.1)
    bolt(p, (0.1, 0.34, -0.47), (0, -1, 0), 0.74, 0.2, thick=0.03)
    p.box(0.42, 0.49, -0.5, 0.44, -0.16, 0.16, "Trim2", 0.015)
    return p


def boot_stormcaller():
    p = Piece()
    p.box(-0.3, 0.44, -0.66, 0.34, -0.42, 0.4, "Dark")
    p.box(-0.34, 0.48, 0.14, 0.38, -0.46, 0.44, "Trim2", 0.03)
    p.box(-0.3, 0.44, -0.72, -0.36, -0.88, 0.4, "Dark2")
    p.box(-0.34, 0.48, -0.78, -0.62, -0.92, 0.44, "Trim", 0.02)
    p.box(-0.3, 0.44, -0.66, -0.4, -0.94, -0.62, "Trim2", 0.03)
    # A bolt off the ankle, like a wing
    bolt(p, (0.42, -0.3, 0.05), (1, 0.75, 0.15), 0.56, 0.2, face=(0, 0, -1))
    return p


def helmet_stormcaller():
    p = Piece()
    # The same square helm as the others, open at the face
    p.box(-0.62, 0.62, 0.44, 0.66, -0.62, 0.62, "Dark")
    p.box(-0.62, -0.5, -0.46, 0.46, -0.62, 0.62, "Dark")
    p.box(0.5, 0.62, -0.46, 0.46, -0.62, 0.62, "Dark")
    p.box(-0.5, 0.5, -0.46, 0.46, 0.5, 0.62, "Dark")
    p.box(-0.65, 0.65, 0.18, 0.3, -0.5, 0.65, "Trim2", 0.02)
    p.box(-0.65, 0.65, -0.5, -0.36, -0.5, 0.65, "Trim3", 0.02)
    p.box(-0.66, 0.66, 0.24, 0.46, -0.68, -0.5, "Trim2", 0.03)
    p.hexagon(0, 0.35, 0.12, -0.71, 0.05, "Trim", "Trim3")
    for s in (-1, 1):
        p.box(s * 0.56 - 0.09, s * 0.56 + 0.09, -0.5, 0.24, -0.68, -0.44, "Trim3", 0.03)
    # A crown of bolts: one straight up, and one out to each side like horns
    bolt(p, (0.02, 0.66, 0.02), (0, 1, 0.05), 0.8, 0.36, thick=0.06)
    bolt(p, (0.3, 0.66, 0.0), (0.42, 1, 0.0), 0.56, 0.2)
    bolt(p, (-0.3, 0.66, 0.0), (-0.42, 1, 0.0), 0.56, 0.2, face=(0, 0, 1))
    return p


# The other armour kits. Same blocky coat and square helm as Stormcaller, each with its own theme. They stay within
# Stormcaller's height so a raised sword clears them (art/scripts/sword_fit/check.py).


def frame_of(direction, face):
    d = Vector(direction).normalized()
    n = Vector(face)
    n = (n - d * n.dot(d)).normalized()
    return d, n, n.cross(d).normalized()


def cut_out(piece, base, direction, length, width, chunks, face=(0, 0, -1), thick=0.05, swatch="Trim", side="Trim3"):
    """A flat shape made of convex chunks of (along, across) shares, so every face turns the right way."""
    base = Vector(base)
    d, n, w = frame_of(direction, face)
    for chunk in chunks:
        outline = [base + d * (length * t) + w * (width * a) for t, a in chunk]
        count = len(outline)
        points = [tuple(p + n * thick) for p in outline] + [tuple(p - n * thick) for p in outline]
        faces = [(list(range(count)), swatch), (list(range(count, 2 * count)), swatch)]
        for i in range(count):
            j = (i + 1) % count
            faces.append(([i, j, j + count, i + count], side))
        piece.shape(points, faces)


RAY = (((0.0, -0.5), (0.0, 0.5), (0.24, 0.62), (1.0, 0.0), (0.24, -0.62)),)
# A flame leans one way as it rises and flicks back the other way at the tip, with one lick off its side
FLAME = (
    ((0.0, -0.6), (0.0, 0.6), (0.3, 0.72), (0.42, -0.42), (0.2, -0.68)),
    ((0.36, -0.44), (0.3, 0.72), (0.62, 0.52), (0.72, -0.06)),
    ((0.6, 0.52), (0.7, -0.06), (1.0, -0.42), (0.82, 0.24)),
    ((0.12, -0.64), (0.4, -0.42), (0.64, -0.9)),
)


def ray(piece, base, direction, length, width, face=(0, 0, -1), thick=0.05, swatch="Trim"):
    cut_out(piece, base, direction, length, width, RAY, face, thick, swatch)


def flame(piece, base, direction, length, width, face=(0, 0, -1), thick=0.05, swatch="Trim"):
    """Two flames, one inside the other: the darker outer one and a bright heart standing a little proud of it."""
    cut_out(piece, base, direction, length, width, FLAME, face, thick, "Trim3" if swatch == "Trim2" else "Trim2", "Trim3")
    d = Vector(direction).normalized()
    heart = Vector(base) + d * (length * 0.04)
    cut_out(piece, tuple(heart), direction, length * 0.66, width * 0.56, FLAME[:3], face, thick + 0.022, swatch, "Trim2")


def icicle(piece, base, direction, length, radius, sides=5):
    """An icicle: widest at its root, narrowing to a point, with facets that catch the light."""
    base = Vector(base)
    d = Vector(direction).normalized()
    up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
    u = d.cross(up).normalized()
    v = d.cross(u).normalized()
    points, faces = [], []
    for t, r in ((0.0, 1.0), (0.42, 0.66)):
        for i in range(sides):
            a = 2 * math.pi * i / sides
            points.append(tuple(base + d * (length * t) + (u * math.cos(a) + v * math.sin(a)) * (radius * r)))
    tip = len(points)
    points.append(tuple(base + d * length))
    shades = ("Trim", "Trim2", "Trim3", "Trim", "Trim2")
    for i in range(sides):
        j = (i + 1) % sides
        faces.append(([i, j, j + sides, i + sides], shades[i]))
        faces.append(([i + sides, j + sides, tip], shades[(i + 1) % sides]))
    faces.append((list(range(sides)), "Trim3"))
    piece.shape(points, faces)


def fang(piece, base, direction, bend, length, radius, sides=5):
    """A curved fang, in convex bands so its faces turn the right way, with a dark line at each band."""
    base = Vector(base)
    d = Vector(direction).normalized()
    b = Vector(bend)
    b = (b - d * b.dot(d)).normalized()
    u = b
    v = d.cross(b).normalized()
    stations = (0.0, 0.34, 0.68, 1.0)

    def centre(t):
        return base + d * (length * t) + b * (length * 0.34 * t * t)

    def size(t):
        return radius * (1 - t) ** 0.75

    shades = ("Trim", "Trim2", "Trim")
    for band in range(len(stations) - 1):
        t0, t1 = stations[band], stations[band + 1]
        low = [centre(t0) + (u * math.cos(2 * math.pi * i / sides) + v * math.sin(2 * math.pi * i / sides)) * size(t0) for i in range(sides)]
        if band == len(stations) - 2:
            points = [tuple(p) for p in low] + [tuple(centre(1.0))]
            faces = [(list(range(sides)), "Trim3")]
            for i in range(sides):
                faces.append(([i, (i + 1) % sides, sides], shades[i % 3]))
        else:
            high = [centre(t1) + (u * math.cos(2 * math.pi * i / sides) + v * math.sin(2 * math.pi * i / sides)) * size(t1) for i in range(sides)]
            points = [tuple(p) for p in low] + [tuple(p) for p in high]
            faces = [(list(range(sides)), "Trim3"), (list(range(sides, 2 * sides)), "Trim3")]
            for i in range(sides):
                j = (i + 1) % sides
                faces.append(([i, j, j + sides, i + sides], shades[i % 3]))
        piece.shape(points, faces)


def kit_chest():
    p = Piece()
    p.box(-0.84, 0.84, -0.66, 0.98, -0.56, 0.56, "Dark")
    for s in (-1, 1):
        p.box(s * 0.4 - 0.14, s * 0.4 + 0.14, 0.96, 1.22, -0.44, 0.44, "Trim2", 0.03)
    p.box(-0.42, 0.42, 0.96, 1.22, 0.3, 0.54, "Trim2", 0.03)
    p.plate([(-0.82, 0.96), (0.82, 0.96), (0.82, 0.62), (0.34, 0.46), (-0.34, 0.46), (-0.82, 0.62)], -0.58, 0.04, "Dark2", "Trim3")
    p.box(-0.87, 0.87, -0.72, -0.54, -0.59, 0.59, "Trim2", 0.02)
    p.hexagon(0, -0.63, 0.13, -0.63, 0.05, "Trim", "Trim3")
    return p


def kit_tails(p, swatch="Dark2", side="Trim2"):
    for s in (-1, 1):
        p.plate([(s * 0.42, -0.7), (s * 0.84, -0.7), (s * 0.84, -1.42), (s * 0.62, -1.62), (s * 0.42, -1.4)], -0.56, 0.05, swatch, side)
    p.back_plate([(-0.82, -0.7), (0.82, -0.7), (0.82, -1.44), (0.42, -1.72), (0, -1.8), (-0.42, -1.72), (-0.82, -1.44)], 0.56, 0.05, swatch, side)


def kit_sleeve():
    p = Piece()
    p.box(-0.3, 0.5, -0.42, 0.5, -0.44, 0.34, "Dark")
    p.box(-0.32, 0.52, -0.46, -0.3, -0.46, 0.36, "Trim2", 0.02)
    return p


def kit_shoulder(p):
    p.box(-0.34, 0.6, 0.44, 0.72, -0.52, 0.42, "Trim2", 0.03)
    p.box(-0.3, 0.56, 0.68, 0.8, -0.46, 0.36, "Dark2", 0.02)


def kit_forearm():
    p = Piece()
    p.box(-0.38, 0.34, -0.34, 0.42, -0.42, 0.3, "Dark")
    p.box(-0.42, 0.42, -0.62, -0.28, -0.52, 0.34, "Trim2", 0.03)
    p.box(-0.44, 0.44, -0.36, -0.28, -0.54, 0.36, "Trim", 0.015)
    return p


def kit_thigh():
    p = Piece()
    p.box(-0.28, 0.46, -0.6, 0.5, -0.42, 0.42, "Dark")
    p.box(0.42, 0.49, -0.5, 0.44, -0.16, 0.16, "Trim2", 0.015)
    return p


def kit_boot():
    p = Piece()
    p.box(-0.3, 0.44, -0.66, 0.34, -0.42, 0.4, "Dark")
    p.box(-0.34, 0.48, 0.14, 0.38, -0.46, 0.44, "Trim2", 0.03)
    p.box(-0.3, 0.44, -0.72, -0.36, -0.88, 0.4, "Dark2")
    p.box(-0.34, 0.48, -0.78, -0.62, -0.92, 0.44, "Trim", 0.02)
    p.box(-0.3, 0.44, -0.66, -0.4, -0.94, -0.62, "Trim2", 0.03)
    return p


def kit_helmet():
    p = Piece()
    p.box(-0.62, 0.62, 0.44, 0.66, -0.62, 0.62, "Dark")
    p.box(-0.62, -0.5, -0.46, 0.46, -0.62, 0.62, "Dark")
    p.box(0.5, 0.62, -0.46, 0.46, -0.62, 0.62, "Dark")
    p.box(-0.5, 0.5, -0.46, 0.46, 0.5, 0.62, "Dark")
    p.box(-0.65, 0.65, 0.18, 0.3, -0.5, 0.65, "Trim2", 0.02)
    p.box(-0.65, 0.65, -0.5, -0.36, -0.5, 0.65, "Trim3", 0.02)
    p.box(-0.66, 0.66, 0.24, 0.46, -0.68, -0.5, "Trim2", 0.03)
    p.hexagon(0, 0.35, 0.12, -0.71, 0.05, "Trim", "Trim3")
    for s in (-1, 1):
        p.box(s * 0.56 - 0.09, s * 0.56 + 0.09, -0.5, 0.24, -0.68, -0.44, "Trim3", 0.03)
    return p


# Sunforged: a gold sun on the chest and a half sun blazing on each shoulder ------------------------------------


def sun(piece, cx, cy, radius, z, rays=8, ray_length=0.34, face=(0, 0, -1), turn=0.0):
    """A disc with rays all round it, lying flat on the front (or, with face +Z, the back)."""
    depth = 0.05
    for i in range(rays):
        a = turn + 2 * math.pi * i / rays
        out = Vector((math.cos(a), math.sin(a), 0))
        at = Vector((cx, cy, z)) + out * (radius * 0.86)
        ray(piece, tuple(at), tuple(out), ray_length, radius * 0.62, face=face, thick=0.028, swatch="Trim" if i % 2 == 0 else "Trim2")
    if face[2] < 0:
        piece.hexagon(cx, cy, radius, z - 0.03, 0.07, "Trim", "Trim3")
        piece.hexagon(cx, cy, radius * 0.56, z - 0.06, depth, "Trim2", "Trim3")
    else:
        outline = [(cx + radius * math.cos(math.pi / 2 + i * math.pi / 3), cy + radius * math.sin(math.pi / 2 + i * math.pi / 3)) for i in range(6)]
        piece.back_plate(outline, z + 0.03, 0.07, "Trim", "Trim3")


def chest_sunforged():
    p = kit_chest()
    sun(p, 0, 0.1, 0.36, -0.6, turn=math.pi / 8)
    for s in (-1, 1):
        p.plate([(s * 0.56, 0.42), (s * 0.8, 0.42), (s * 0.8, 0.3), (s * 0.56, 0.3)], -0.585, 0.03, "Trim2", "Trim3")
    kit_tails(p)
    sun(p, 0, 0.1, 0.42, 0.6, face=(0, 0, 1), turn=math.pi / 8)
    return p


def pauldron_sunforged():
    p = Piece()
    kit_shoulder(p)
    # A half sun rising off the shoulder, its rays fanning up and outward
    for i, (direction, length) in enumerate((((-0.1, 1.0), 0.62), ((0.4, 1.0), 0.74), ((0.8, 0.75), 0.82), ((1.0, 0.3), 0.76), ((1.0, -0.14), 0.56))):
        ray(p, (0.3 + direction[0] * 0.26, 0.84 + direction[1] * 0.26, -0.05), (direction[0], direction[1], 0), length, 0.32, thick=0.06, swatch="Trim" if i % 2 == 0 else "Trim2")
    p.hexagon(0.3, 0.86, 0.34, -0.15, 0.2, "Trim", "Trim3")
    p.hexagon(0.3, 0.86, 0.19, -0.2, 0.05, "Trim2", "Trim3")
    return p


def forearm_sunforged():
    p = kit_forearm()
    ray(p, (0.4, -0.5, -0.1), (1, 0.55, 0.0), 0.62, 0.24)
    return p


def thigh_sunforged():
    p = kit_thigh()
    p.hexagon(0.09, -0.42, 0.24, -0.45, 0.06, "Trim2", "Trim3", 1.1)
    p.hexagon(0.09, -0.42, 0.12, -0.5, 0.04, "Trim", "Trim3")
    ray(p, (0.09, -0.16, -0.47), (0, 1, 0), 0.44, 0.2, thick=0.03)
    return p


def boot_sunforged():
    p = kit_boot()
    ray(p, (0.42, -0.3, 0.05), (1, 0.75, 0.15), 0.56, 0.24)
    return p


def helmet_sunforged():
    p = kit_helmet()
    for i, (x, direction, length) in enumerate(((0.0, (0, 1, 0.05), 0.8), (0.26, (0.42, 1, 0), 0.62), (-0.26, (-0.42, 1, 0), 0.62), (0.5, (0.9, 0.8, 0), 0.44), (-0.5, (-0.9, 0.8, 0), 0.44))):
        ray(p, (x, 0.66, 0.0), direction, length, 0.3 if i == 0 else 0.22, thick=0.06, swatch="Trim" if i % 2 == 0 else "Trim2")
    return p


# Emberguard: flames climbing the coat and burning off the shoulders --------------------------------------------


def chest_emberguard():
    p = kit_chest()
    flame(p, (0, -0.56, -0.62), (0, 1, 0), 1.3, 0.56, thick=0.04)
    for s in (-1, 1):
        flame(p, (s * 0.6, -0.56, -0.6), (s * 0.12, 1, 0), 0.62, 0.22, thick=0.03, swatch="Trim2")
    kit_tails(p)
    flame(p, (0, -0.56, 0.62), (0, 1, 0), 1.3, 0.6, face=(0, 0, 1), thick=0.04)
    return p


def pauldron_emberguard():
    p = Piece()
    kit_shoulder(p)
    # A brazier on the shoulder, burning up and outward
    p.box(-0.04, 0.62, 0.78, 0.98, -0.34, 0.26, "Trim3", 0.03)
    p.box(-0.08, 0.66, 0.94, 1.04, -0.38, 0.3, "Trim2", 0.02)
    flame(p, (0.3, 1.0, -0.05), (0.14, 1.0, 0.0), 0.8, 0.42, thick=0.07)
    flame(p, (0.56, 0.98, -0.05), (1.0, 0.5, 0.0), 0.74, 0.32, thick=0.07, swatch="Trim2")
    flame(p, (0.06, 1.0, -0.02), (-0.34, 1.0, 0.0), 0.5, 0.24, thick=0.05, swatch="Trim2")
    return p


def forearm_emberguard():
    p = kit_forearm()
    flame(p, (0.4, -0.5, -0.1), (1, 0.55, 0.0), 0.66, 0.26)
    return p


def thigh_emberguard():
    p = kit_thigh()
    p.hexagon(0.09, -0.42, 0.24, -0.45, 0.06, "Trim2", "Trim3", 1.1)
    flame(p, (0.09, -0.34, -0.5), (0, 1, 0), 0.74, 0.3, thick=0.03)
    return p


def boot_emberguard():
    p = kit_boot()
    flame(p, (0.42, -0.3, 0.05), (1, 0.75, 0.15), 0.6, 0.26)
    return p


def helmet_emberguard():
    p = kit_helmet()
    flame(p, (0.0, 0.66, 0.02), (0, 1, 0.05), 0.82, 0.44, thick=0.06)
    flame(p, (0.34, 0.66, 0.0), (0.46, 1, 0.0), 0.54, 0.24, thick=0.05, swatch="Trim2")
    flame(p, (-0.34, 0.66, 0.0), (-0.46, 1, 0.0), 0.54, 0.24, face=(0, 0, 1), thick=0.05, swatch="Trim2")
    return p


# Frostwarden: silver plate hung with icicles and crowned with ice ---------------------------------------------


def snowflake(piece, cx, cy, z, radius):
    """A six-armed snowflake lying flat on the front."""
    for i in range(6):
        a = i * math.pi / 3 + math.pi / 6
        out = Vector((math.cos(a), math.sin(a), 0))
        at = Vector((cx, cy, z))
        piece.prism(tuple(at), tuple(at + out * radius), radius * 0.12, "Trim", "Trim2")
        tip = at + out * (radius * 0.6)
        for turn in (-1, 1):
            b = a + turn * math.pi / 3.4
            piece.prism(tuple(tip), tuple(tip + Vector((math.cos(b), math.sin(b), 0)) * (radius * 0.34)), radius * 0.09, "Trim", "Trim2")
    piece.hexagon(cx, cy, radius * 0.3, z - 0.05, 0.08, "Trim", "Trim3")


def chest_frostwarden():
    p = kit_chest()
    snowflake(p, 0, 0.08, -0.6, 0.5)
    # Icicles hanging from the yoke and the belt
    for x, length in ((-0.62, 0.34), (-0.42, 0.22), (0.42, 0.22), (0.62, 0.34)):
        icicle(p, (x, 0.54, -0.62), (0, -1, -0.04), length, 0.07, sides=4)
    for x, length in ((-0.7, 0.42), (-0.42, 0.54), (-0.14, 0.34), (0.14, 0.34), (0.42, 0.54), (0.7, 0.42)):
        icicle(p, (x, -0.72, -0.57), (0, -1, -0.02), length, 0.085)
        icicle(p, (x, -0.72, 0.57), (0, -1, 0.02), length + 0.12, 0.085)
    # A great icicle crown across the back, with a shard running down the spine
    for x, length in ((-0.58, 0.46), (-0.3, 0.7), (0.0, 0.94), (0.3, 0.7), (0.58, 0.46)):
        icicle(p, (x, 0.72, 0.62), (0, -1, 0.02), length, 0.11)
    return p


def pauldron_frostwarden():
    p = Piece()
    kit_shoulder(p)
    # A cluster of ice bursting up and out, and icicles hanging off the edge
    for direction, length, radius in (((0.32, 1.0, -0.04), 1.04, 0.2), ((0.92, 0.62, 0.0), 1.06, 0.18), ((-0.14, 1.0, 0.22), 0.72, 0.14), ((0.34, 0.82, -0.56), 0.74, 0.13), ((0.4, 0.82, 0.6), 0.74, 0.13), ((1.0, 0.16, -0.3), 0.72, 0.12), ((1.0, 0.16, 0.34), 0.7, 0.12)):
        icicle(p, (0.3, 0.84, -0.05), direction, length, radius)
    for z in (-0.4, -0.12, 0.16):
        icicle(p, (0.62, 0.46, z), (0.06, -1, 0), 0.4, 0.07, sides=4)
    return p


def forearm_frostwarden():
    p = kit_forearm()
    for y, length in ((-0.5, 0.56), (-0.26, 0.42)):
        icicle(p, (0.38, y, -0.1), (1, 0.45, 0.0), length, 0.1)
    return p


def thigh_frostwarden():
    p = kit_thigh()
    p.hexagon(0.09, -0.42, 0.24, -0.45, 0.06, "Trim2", "Trim3", 1.1)
    p.hexagon(0.09, -0.42, 0.12, -0.5, 0.04, "Trim", "Trim3")
    icicle(p, (0.09, -0.62, -0.47), (0, -1, -0.05), 0.3, 0.075, sides=4)
    icicle(p, (0.44, 0.1, 0.0), (1, -0.5, 0.0), 0.34, 0.07, sides=4)
    return p


def boot_frostwarden():
    p = kit_boot()
    icicle(p, (0.42, -0.26, 0.05), (1, 0.75, 0.15), 0.56, 0.1)
    icicle(p, (0.42, -0.04, 0.05), (1, 0.3, 0.15), 0.36, 0.07, sides=4)
    return p


def helmet_frostwarden():
    p = kit_helmet()
    for x, z, direction, length, radius in ((0.0, 0.0, (0, 1, 0.05), 0.82, 0.16), (0.3, 0.0, (0.34, 1, 0), 0.62, 0.11), (-0.3, 0.0, (-0.34, 1, 0), 0.62, 0.11), (0.54, 0.0, (0.86, 0.8, 0), 0.42, 0.09), (-0.54, 0.0, (-0.86, 0.8, 0), 0.42, 0.09), (0.0, -0.4, (0, 1, -0.2), 0.42, 0.09)):
        icicle(p, (x, 0.64, z), direction, length, radius)
    return p


# Venomfang: a serpent's head on each shoulder, its hood round the helm, and fangs everywhere --------------------


def scales(piece, side, ys, z=-0.585):
    """Chevrons down one side of the coat, like a snake's belly."""
    for y in ys:
        piece.plate([(side * 0.5, y), (side * 0.8, y + 0.13), (side * 0.8, y + 0.01), (side * 0.5, y - 0.12)], z, 0.03, "Trim2", "Trim3")


def chest_venomfang():
    p = kit_chest()
    # A serpent's open mouth across the top of the chest, with two great fangs down the front
    p.plate([(-0.58, 0.46), (0.58, 0.46), (0.3, 0.12), (-0.3, 0.12)], -0.6, 0.04, "Trim3", "Trim2")
    for s in (-1, 1):
        fang(p, (s * 0.25, 0.44, -0.66), (s * -0.08, -1, 0), (s * -1, 0, 0), 1.0, 0.16)
        scales(p, s, (0.1, -0.2, -0.5))
    kit_tails(p, "Dark2", "Trim2")
    # Down the back, a snake's spine
    for i, y in enumerate((0.72, 0.36, 0.0, -0.36)):
        fang(p, (0, y, 0.58), (0, 0.4, 1), (0, 1, 0), 0.34 - i * 0.03, 0.09)
    return p


def pauldron_venomfang():
    p = Piece()
    kit_shoulder(p)
    # A blocky serpent's head sitting on the shoulder, its hood flaring behind and two fangs out in front
    p.box(0.0, 0.66, 0.82, 1.08, -0.3, 0.2, "Trim2", 0.03)
    p.box(0.02, 0.64, 1.06, 1.2, -0.28, 0.14, "Trim", 0.03)
    p.box(0.08, 0.2, 1.08, 1.24, -0.3, -0.16, "Black", 0.02)
    p.box(0.46, 0.58, 1.08, 1.24, -0.3, -0.16, "Black", 0.02)
    for x in (0.14, 0.52):
        fang(p, (x, 0.84, -0.26), (0, -0.9, -0.5), (0, 0, 1), 0.34, 0.07)
    # The hood, flared up and out behind the head
    cut_out(p, (0.33, 0.98, 0.14), (0.0, 1.0, 0.1), 0.64, 0.56, RAY, thick=0.05, swatch="Trim3", side="Trim2")
    cut_out(p, (0.62, 0.94, 0.14), (0.9, 0.5, 0.05), 0.72, 0.4, RAY, thick=0.05, swatch="Trim2", side="Trim3")
    return p


def forearm_venomfang():
    p = kit_forearm()
    fang(p, (0.4, -0.5, -0.1), (1, 0.3, 0.0), (0, 1, 0), 0.6, 0.11)
    return p


def thigh_venomfang():
    p = kit_thigh()
    p.hexagon(0.09, -0.42, 0.24, -0.45, 0.06, "Trim2", "Trim3", 1.1)
    fang(p, (0.09, -0.42, -0.5), (0, 0.2, -1), (0, -1, 0), 0.4, 0.09)
    for y in (0.3, 0.06):
        p.plate([(-0.14, y), (0.1, y + 0.1), (0.34, y), (0.34, y - 0.08), (0.1, y + 0.02), (-0.14, y - 0.08)], -0.44, 0.03, "Trim2", "Trim3")
    return p


def boot_venomfang():
    p = kit_boot()
    fang(p, (0.42, -0.3, 0.05), (1, 0.6, 0.15), (0, 1, 0), 0.54, 0.1)
    return p


def helmet_venomfang():
    p = kit_helmet()
    # A cobra's hood flaring round the helm, and fangs down each side of your face
    cut_out(p, (0.0, 0.66, 0.2), (0, 1, 0.1), 0.7, 0.62, RAY, thick=0.05, swatch="Trim3", side="Trim2")
    for s in (-1, 1):
        cut_out(p, (s * 0.3, 0.66, 0.1), (s * 0.44, 1, 0.05), 0.46, 0.26, RAY, thick=0.05, swatch="Trim2", side="Trim3")
        fang(p, (s * 0.44, -0.3, -0.7), (0, -1, -0.12), (s * -1, 0, 0), 0.5, 0.075)
    fang(p, (0.0, 0.74, -0.46), (0, 0.9, -0.5), (0, 1, 0), 0.34, 0.07)
    return p


SETS = {
    "Sunforged": {
        "Helmet": helmet_sunforged,
        "Chest": chest_sunforged,
        "Sleeve": kit_sleeve,
        "Pauldron": pauldron_sunforged,
        "Forearm": forearm_sunforged,
        "Hips": lambda: hips_mining(),
        "Thigh": thigh_sunforged,
        "Boot": boot_sunforged,
    },
    "Emberguard": {
        "Helmet": helmet_emberguard,
        "Chest": chest_emberguard,
        "Sleeve": kit_sleeve,
        "Pauldron": pauldron_emberguard,
        "Forearm": forearm_emberguard,
        "Hips": lambda: hips_mining(),
        "Thigh": thigh_emberguard,
        "Boot": boot_emberguard,
    },
    "Frostwarden": {
        "Helmet": helmet_frostwarden,
        "Chest": chest_frostwarden,
        "Sleeve": kit_sleeve,
        "Pauldron": pauldron_frostwarden,
        "Forearm": forearm_frostwarden,
        "Hips": lambda: hips_mining(),
        "Thigh": thigh_frostwarden,
        "Boot": boot_frostwarden,
    },
    "Venomfang": {
        "Helmet": helmet_venomfang,
        "Chest": chest_venomfang,
        "Sleeve": kit_sleeve,
        "Pauldron": pauldron_venomfang,
        "Forearm": forearm_venomfang,
        "Hips": lambda: hips_mining(),
        "Thigh": thigh_venomfang,
        "Boot": boot_venomfang,
    },
    "Mining": {
        "Helmet": helmet_mining,
        "Chest": chest_mining,
        "Sleeve": sleeve_mining,
        "Pauldron": pauldron_mining,
        "Forearm": forearm_mining,
        "Hips": hips_mining,
        "Thigh": thigh_mining,
        "Boot": boot_mining,
    },
    "Woodcutting": {
        "Helmet": helmet_woodcutting,
        "Chest": chest_woodcutting,
        "Sleeve": sleeve_woodcutting,
        "Pauldron": pauldron_woodcutting,
        "Forearm": forearm_woodcutting,
        "Hips": hips_mining,
        "Thigh": thigh_woodcutting,
        "Boot": boot_woodcutting,
    },
    "Farming": {
        "Helmet": helmet_farming,
        "Chest": chest_farming,
        "Sleeve": sleeve_farming,
        "Pauldron": pauldron_farming,
        "Forearm": forearm_farming,
        "Hips": hips_mining,
        "Thigh": thigh_farming,
        "Boot": boot_farming,
    },
    "Stormcaller": {
        "Helmet": helmet_stormcaller,
        "Chest": chest_stormcaller,
        "Sleeve": sleeve_stormcaller,
        "Pauldron": pauldron_stormcaller,
        "Forearm": forearm_stormcaller,
        "Hips": hips_mining,
        "Thigh": thigh_stormcaller,
        "Boot": boot_stormcaller,
    },
}
# Which colour sheet the previews use; armour kits wear diamond, the top of armour
PREVIEW_TIER = {"Stormcaller": 5, "Sunforged": 3, "Emberguard": 1, "Frostwarden": 2, "Venomfang": 4}
# Pieces with a left and a right, as avatars' limbs mirror each other
SIDED = ("Sleeve", "Pauldron", "Forearm", "Thigh", "Boot")

# Where each body part is on the avatar these were modelled on, in the chest's space, and its size. The game scales
# a piece by how the wearer's part compares with this one.
BODY = {
    "Head": ((0.0, 1.47, 0.01), (1.11, 1.12, 1.12)),
    "Chest": ((0.0, 0.0, 0.0), (1.54, 1.84, 1.01)),
    "Sleeve": ((0.97, 0.25, 0.09), (0.81, 1.18, 0.71)),
    "Pauldron": ((0.97, 0.25, 0.09), (0.81, 1.18, 0.71)),
    "Forearm": ((1.18, -0.27, 0.02), (0.70, 1.13, 0.84)),
    "Hips": ((0.0, -0.70, 0.04), (1.42, 0.59, 0.97)),
    "Thigh": ((0.34, -1.45, 0.03), (0.66, 1.78, 0.77)),
    "Boot": ((0.36, -2.26, 0.03), (0.61, 1.27, 0.77)),
}
PART_OF = {"Helmet": "Head"}


def to_blender():
    return Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def preview(skill, objects, out_base, tint, icon=False):
    """Renders the set on boxes for the head and hands, the way the game hides the rest of the body. `icon` makes one
    square picture of the top half with no background, for its game pass."""
    scene = bpy.context.scene
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in engines else "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 512 if icon else 640
    scene.render.resolution_y = 512 if icon else 860
    scene.world = bpy.data.worlds.new("Sky")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.45, 0.47, 0.5, 1)
    scene.render.film_transparent = icon  # art/scripts/pass_icons.ps1 puts it on a background
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 2.5
    sun_obj = bpy.data.objects.new("Sun", sun)
    bpy.context.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(50), 0, math.radians(25))

    path = os.path.join(ROOT, "textures", "armour", f"tier_{tint}.png")
    image = bpy.data.images.load(path)
    material = bpy.data.materials.new("Armour")
    material.use_nodes = True
    material.use_backface_culling = True
    nodes = material.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.8
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.interpolation = "Closest"
    material.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    skin = bpy.data.materials.new("Skin")
    skin.use_nodes = True
    skin.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.7, 0.45, 0.28, 1)

    to_b = to_blender()
    for name, obj in objects.items():
        base, _, left = name.partition("Left")
        piece = name[:-5] if name.endswith("Right") else name[:-4] if name.endswith("Left") else name
        part = PART_OF.get(piece, piece)
        at = Vector(BODY[part][0])
        if name.endswith("Left"):
            at.x = -at.x
        obj.data.materials.append(material)
        obj.matrix_world = to_b @ Matrix.Translation(at)

    def box(at, size):
        bpy.ops.mesh.primitive_cube_add(size=1)
        cube = bpy.context.active_object
        cube.data.materials.append(skin)
        cube.matrix_world = to_b @ Matrix.Translation(at) @ Matrix.Diagonal((*size, 1))

    box((0, 1.47, 0.01), (1.0, 1.05, 1.0))
    box((1.28, -1.0, -0.2), (0.62, 0.7, 0.7))
    box((-1.28, -1.0, -0.2), (0.62, 0.7, 0.7))

    data = bpy.data.cameras.new("Camera")
    data.type = "ORTHO"
    data.ortho_scale = 5.4 if icon else 7.6
    camera = bpy.data.objects.new("Camera", data)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera
    for label, angle in (("icon", 25),) if icon else (("front", 25), ("back", 205)):
        a = math.radians(angle)
        at = Vector((0, 0, 0.45 if icon else -0.3))
        pos = at + Vector((math.sin(a) * 14, math.cos(a) * 14, 2.5))
        camera.location = pos
        camera.rotation_euler = (at - pos).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = f"{out_base}_{label}.png"
        bpy.ops.render.render(write_still=True)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["Mining"]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(os.path.join(ROOT, "textures", "armour"), exist_ok=True)
    for number, tier in enumerate(TIERS, 1):
        write_palette(os.path.join(ROOT, "textures", "armour", f"tier_{number}.png"), tier)
    # Several sets at once, "A,B,C", go into one Armour_Kits.fbx, so they take a single Import 3D
    names = args[0].split(",")
    if len(names) > 1:
        chosen = {}
        for skill in names:
            for piece, build in SETS[skill].items():
                model = build()
                if piece in SIDED:
                    chosen[f"{skill}_{piece}Right"] = model.build(f"{skill}_{piece}Right", 1)
                    chosen[f"{skill}_{piece}Left"] = model.build(f"{skill}_{piece}Left", -1)
                else:
                    chosen[f"{skill}_{piece}"] = model.build(f"{skill}_{piece}", 1)
        bpy.ops.object.select_all(action="DESELECT")
        for obj in chosen.values():
            obj.select_set(True)
        bpy.ops.export_scene.fbx(
            filepath=os.path.join(ROOT, "export", "Armour_Kits.fbx"),
            use_selection=True,
            apply_unit_scale=True,
            global_scale=1.0,
            axis_forward="-Z",
            axis_up="Y",
            bake_space_transform=False,
            mesh_smooth_type="FACE",
        )
        print("EXPORTED", len(chosen), flush=True)
        return
    skill = names[0]
    objects = {}
    for piece, build in SETS[skill].items():
        model = build()
        if piece in SIDED:
            objects[piece + "Right"] = model.build(f"{skill}_{piece}Right", 1)
            objects[piece + "Left"] = model.build(f"{skill}_{piece}Left", -1)
        else:
            objects[piece] = model.build(f"{skill}_{piece}", 1)

    # What the game needs to know: the middle and size of each mesh in its body part's space
    info = {}
    for name, obj in objects.items():
        points = [v.co for v in obj.data.vertices]
        low = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
        high = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
        centre = (low + high) / 2
        # A pauldron rides on the chest, so its place is in the chest's space
        if name.startswith("Pauldron"):
            at = Vector(BODY["Pauldron"][0])
            at.x = at.x if name.endswith("Right") else -at.x
            centre = centre + at
        info[name] = {
            "Centre": [round(c, 4) for c in centre],
            "Size": [round(c, 4) for c in high - low],
            "Tris": len(obj.data.polygons),
        }
    with open(os.path.join(ROOT, "export", f"Armour_{skill}.json"), "w") as out:
        json.dump(info, out, indent=1)

    if "icon" in args:
        os.makedirs(os.path.join(ROOT, "marketing"), exist_ok=True)
        preview(skill, objects, os.path.join(ROOT, "marketing", f"Pass_{skill}"), PREVIEW_TIER.get(skill, 7), icon=True)
        print("ICON", flush=True)
    elif "preview" in args:
        preview(skill, objects, os.path.join(ROOT, "renders", f"Armour_{skill}"), PREVIEW_TIER.get(skill, 7))
        print("PREVIEWED", flush=True)
    else:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects.values():
            obj.select_set(True)
        bpy.ops.export_scene.fbx(
            filepath=os.path.join(ROOT, "export", f"Armour_{skill}.fbx"),
            use_selection=True,
            apply_unit_scale=True,
            global_scale=1.0,
            axis_forward="-Z",
            axis_up="Y",
            bake_space_transform=False,
            mesh_smooth_type="FACE",
        )
        print("EXPORTED", flush=True)
    print({name: value["Tris"] for name, value in info.items()}, flush=True)


main()
