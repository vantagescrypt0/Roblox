"""Stylized low-poly building blocks shared by all asset scripts.

Every model uses ONE shared palette texture (art/textures/palette.png). Each face's UVs
point at a single color swatch, so a whole prop can be one mesh with many colors. In
Roblox that becomes one MeshPart with one TextureID.

Build a mesh with Builder: add boxes, cylinders, cones and blobs, each with a palette
color name, then call .finish(name).
"""

import math
import os
import random

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

ART_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEXTURE_DIR = os.path.join(ART_DIR, "textures")

# Palette colors (sRGB hex). Names are what scripts use. Max 64 entries (8x8 grid).
PALETTE = {
    # Grass and plants
    "grass": "#6DBE45",
    "grass_light": "#86D05A",
    "grass_dark": "#4F9A36",
    "leaf": "#3F8F3A",
    "leaf_light": "#58A847",
    "leaf_dark": "#2E6E2C",
    "sprout": "#7CC46A",
    "stalk": "#5FAE4E",
    # Earth and stone
    "dirt": "#8A5A34",
    "dirt_dark": "#6E4527",
    "dirt_light": "#A06B3F",
    "soil": "#4E3220",
    "soil_light": "#65432A",
    "stone": "#8C8C8C",
    "stone_light": "#A3A3A8",
    "stone_dark": "#6E6F75",
    "stone_blue": "#7F8794",
    "root": "#5C3B22",
    # Wood
    "wood": "#C8935A",
    "wood_alt": "#B9834E",
    "wood_dark": "#7A4E2D",
    "wood_darker": "#5E3B21",
    "bark": "#6B4423",
    "plank": "#D9A86C",
    # Metal
    "metal": "#7D8590",
    "metal_dark": "#4A4F57",
    "steel": "#C9CED6",
    "gold": "#E8B740",
    # Cloth and paint
    "red": "#D9493F",
    "red_dark": "#A8322B",
    "cream": "#F3E3C3",
    "sign": "#E9D3A5",
    "blue": "#3F7FD9",
    # Crops
    "wheat": "#E8C45C",
    "wheat_dark": "#C9A23E",
    "carrot": "#ED7C29",
    "potato": "#B98A55",
    "potato_flower": "#E9E4F5",
    "berry": "#7AE8FF",
    "berry_bush": "#2F7F6F",
    # Flowers
    "flower_pink": "#F28AB8",
    "flower_yellow": "#F7D64A",
    "flower_white": "#F7F4EA",
    "flower_purple": "#A77BF0",
    # Magic
    "rune": "#B57CFF",
    "rune_dark": "#7A4BD6",
    "portal": "#8A5CF6",
    "glow": "#FFD27A",
    # Tools and materials (items3d.py); appended so older swatches keep their place
    "leather": "#7B4A2C",
    "leather_dark": "#5A341F",
    "iron": "#D3D9E0",
    "iron_dark": "#9AA4B0",
    "crystal": "#4FD3F2",
    "crystal_light": "#B5F2FF",
    "crystal_dark": "#2390B8",
    "coal": "#2E2E33",
    "coal_light": "#4B4B53",
    "raw_iron": "#C99068",
    "raw_iron_dark": "#9C6748",
    # The worlds' zone crops and gold (the palette is now full: 64 swatches)
    "pumpkin": "#E07F22",
    "pumpkin_dark": "#B35E16",
    "melon": "#5E9F35",
    "melon_light": "#A2CF60",
    "gold_dark": "#B98A24",
}

GRID = 8
SWATCH_PX = 8
SIZE_PX = GRID * SWATCH_PX
_NAMES = list(PALETTE.keys())
assert len(_NAMES) <= GRID * GRID


def _hex(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) / 255 for i in (0, 2, 4))


def swatch_uv(color):
    index = _NAMES.index(color)
    col, row = index % GRID, index // GRID
    # Center of the swatch; v counts from the bottom in Blender
    return ((col + 0.5) / GRID, 1 - (row + 0.5) / GRID)


def palette_image():
    image = bpy.data.images.get("Palette")
    if image:
        return image
    image = bpy.data.images.new("Palette", SIZE_PX, SIZE_PX, alpha=False)
    pixels = [0.0] * (SIZE_PX * SIZE_PX * 4)
    for index, name in enumerate(_NAMES):
        r, g, b = _hex(PALETTE[name])
        col, row = index % GRID, index // GRID
        for y in range(SWATCH_PX):
            for x in range(SWATCH_PX):
                px = col * SWATCH_PX + x
                py = (GRID - 1 - row) * SWATCH_PX + y  # image rows start at the bottom
                i = (py * SIZE_PX + px) * 4
                pixels[i : i + 4] = [r, g, b, 1.0]
    image.pixels = pixels
    os.makedirs(TEXTURE_DIR, exist_ok=True)
    image.filepath_raw = os.path.join(TEXTURE_DIR, "palette.png")
    image.file_format = "PNG"
    image.save()
    return image


def palette_material():
    mat = bpy.data.materials.get("Palette")
    if mat:
        return mat
    mat = bpy.data.materials.new("Palette")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.85
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = palette_image()
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def matrix(location=(0, 0, 0), rotation=(0, 0, 0), scale=(1, 1, 1)):
    return (
        Matrix.Translation(Vector(location))
        @ Euler([math.radians(a) for a in rotation]).to_matrix().to_4x4()
        @ Matrix.Diagonal((*scale, 1))
    )


class Builder:
    """Accumulates colored low-poly pieces into one mesh."""

    def __init__(self, seed=1):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.rng = random.Random(seed)

    def _paint(self, verts, color):
        u, v = swatch_uv(color)
        faces = {f for vert in verts for f in vert.link_faces}
        for face in faces:
            for loop in face.loops:
                loop[self.uv].uv = (u, v)
        return faces

    def _bevel(self, verts, amount):
        if amount <= 0:
            return
        edges = list({e for v in verts for e in v.link_edges})
        bmesh.ops.bevel(
            self.bm,
            geom=edges,
            offset=amount,
            offset_type="OFFSET",
            segments=1,
            profile=0.5,
            affect="EDGES",
            clamp_overlap=True,
        )

    def _jitter(self, verts, amount):
        if amount <= 0:
            return
        for v in verts:
            v.co += Vector(
                (
                    self.rng.uniform(-amount, amount),
                    self.rng.uniform(-amount, amount),
                    self.rng.uniform(-amount, amount),
                )
            )

    def box(self, size, location=(0, 0, 0), rotation=(0, 0, 0), color="wood", bevel=0.0, jitter=0.0):
        verts = bmesh.ops.create_cube(self.bm, size=1.0, matrix=matrix(location, rotation, size))["verts"]
        self._jitter(verts, jitter)
        self._paint(verts, color)
        self._bevel(verts, bevel)
        return verts

    def cylinder(self, radius, depth, location=(0, 0, 0), rotation=(0, 0, 0), color="wood", segments=8, radius2=None, bevel=0.0):
        verts = bmesh.ops.create_cone(
            self.bm,
            cap_ends=True,
            cap_tris=False,
            segments=segments,
            radius1=radius,
            radius2=radius if radius2 is None else radius2,
            depth=depth,
            matrix=matrix(location, rotation),
        )["verts"]
        self._paint(verts, color)
        self._bevel(verts, bevel)
        return verts

    def cone(self, radius, depth, location=(0, 0, 0), rotation=(0, 0, 0), color="leaf", segments=6):
        verts = bmesh.ops.create_cone(
            self.bm,
            cap_ends=True,
            cap_tris=True,
            segments=segments,
            radius1=radius,
            radius2=0.0,
            depth=depth,
            matrix=matrix(location, rotation),
        )["verts"]
        self._paint(verts, color)
        return verts

    def blob(self, radius, location=(0, 0, 0), color="leaf", squash=(1, 1, 1), jitter=0.12, subdivisions=1, rotation=(0, 0, 0)):
        verts = bmesh.ops.create_icosphere(
            self.bm, subdivisions=subdivisions, radius=radius, matrix=matrix(location, rotation, squash)
        )["verts"]
        self._jitter(verts, radius * jitter)
        self._paint(verts, color)
        return verts

    def _paint_faces(self, faces, color):
        u, v = swatch_uv(color)
        for face in faces:
            for loop in face.loops:
                loop[self.uv].uv = (u, v)

    def loft(self, rings, band_colors, top_color=None, bottom_color=None, tip=None, tip_color=None):
        """Stacks rings of points (top to bottom, same count each) into a solid.
        band_colors[i] colors the band between ring i and ring i+1."""
        vrings = [[self.bm.verts.new(p) for p in ring] for ring in rings]
        n = len(rings[0])
        new_faces = []
        if top_color:
            face = self.bm.faces.new(vrings[0])
            self._paint_faces([face], top_color)
            new_faces.append(face)
        for i in range(len(vrings) - 1):
            upper, lower = vrings[i], vrings[i + 1]
            band = []
            for j in range(n):
                k = (j + 1) % n
                band.append(self.bm.faces.new((lower[j], lower[k], upper[k], upper[j])))
            self._paint_faces(band, band_colors[i])
            new_faces += band
        last = vrings[-1]
        if tip is not None:
            tip_vert = self.bm.verts.new(tip)
            cone = [self.bm.faces.new((last[(j + 1) % n], last[j], tip_vert)) for j in range(n)]
            self._paint_faces(cone, tip_color or band_colors[-1])
            new_faces += cone
        elif bottom_color:
            face = self.bm.faces.new(list(reversed(last)))
            self._paint_faces([face], bottom_color)
            new_faces.append(face)
        bmesh.ops.recalc_face_normals(self.bm, faces=new_faces)

    def finish(self, name, collection=None):
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=0.0001)
        mesh = bpy.data.meshes.new(name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for poly in mesh.polygons:
            poly.use_smooth = False
        obj = bpy.data.objects.new(name, mesh)
        (collection or bpy.context.scene.collection).objects.link(obj)
        obj.data.materials.append(palette_material())
        return obj


def marker(name, location, collection=None):
    """Tiny cube used as a layout point; the game reads its position and hides it."""
    b = Builder()
    b.box((0.2, 0.2, 0.2), location, color="red")
    return b.finish(name, collection)


def export_fbx(path, objects=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if objects is not None:
        for obj in bpy.context.scene.objects:
            obj.select_set(obj in objects)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=objects is not None,
        object_types={"MESH"},
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        path_mode="COPY",
        embed_textures=True,
    )
    return path
