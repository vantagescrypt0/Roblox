"""Minecraft-style blocks: 16x16 pixel-art tiles in one atlas, and a 3-stud cube mesh per
block type with each face mapped to the right tile (grass: green top, grass side, dirt
bottom; logs: bark sides, rings on top/bottom; ...).

Tiles are drawn procedurally (seeded noise) and scaled up 8x with nearest-neighbour so
they stay crisp in Roblox (which filters textures smoothly).

Output: art/textures/blocks.png, art/export/Blocks.fbx, art/blend/Blocks.blend,
        art/renders/Blocks.png
"""

import math
import os
import random
import sys

import bmesh
import bpy

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

BLOCK = 3.0  # studs
TILE = 16
SCALE = 8
GRID = 5  # 5x5 tiles
ATLAS = TILE * SCALE * GRID  # 640 px

TILES = [
    "grass_top", "grass_side", "dirt", "stone",
    "log_side", "log_top", "leaves", "planks",
    "craft_top", "craft_side", "farmland", "obsidian",
    "wool_red", "wool_white", "cobblestone", "craft_front",
    "coal_ore", "iron_ore", "furnace_front", "furnace_side",
    "furnace_top", "slate", "runestone",
]  # fmt: skip

# Which tile each face uses: (top, bottom, sides) or (top, bottom, front, other sides)
BLOCKS = {
    "Grass": ("grass_top", "dirt", "grass_side"),
    "Dirt": ("dirt", "dirt", "dirt"),
    "Stone": ("stone", "stone", "stone"),
    "Wood": ("log_top", "log_top", "log_side"),
    "Leaves": ("leaves", "leaves", "leaves"),
    "Planks": ("planks", "planks", "planks"),
    "CraftingTable": ("craft_top", "planks", "craft_front", "craft_side"),
    "Farmland": ("farmland", "dirt", "dirt"),
    "Obsidian": ("obsidian", "obsidian", "obsidian"),
    "RedWool": ("wool_red", "wool_red", "wool_red"),
    "WhiteWool": ("wool_white", "wool_white", "wool_white"),
    "Cobblestone": ("cobblestone", "cobblestone", "cobblestone"),
    "CoalOre": ("coal_ore", "coal_ore", "coal_ore"),
    "IronOre": ("iron_ore", "iron_ore", "iron_ore"),
    "Furnace": ("furnace_top", "furnace_top", "furnace_front", "furnace_side"),
    "Runestone": ("slate", "slate", "runestone"),
}


def clamp(v):
    return max(0, min(255, int(v)))


def noisy(rng, color, amount):
    d = rng.uniform(-amount, amount)
    return tuple(clamp(c + d) for c in color)


def fill(rng, color, amount):
    return [[noisy(rng, color, amount) for _ in range(TILE)] for _ in range(TILE)]


def speckle(rng, tile, color, chance, amount=6):
    for y in range(TILE):
        for x in range(TILE):
            if rng.random() < chance:
                tile[y][x] = noisy(rng, color, amount)


def draw_tiles():
    rng = random.Random(7)
    tiles = {}

    t = fill(rng, (95, 159, 53), 14)
    speckle(rng, t, (74, 128, 40), 0.18)
    speckle(rng, t, (120, 185, 70), 0.1)
    tiles["grass_top"] = t

    dirt = fill(rng, (134, 96, 67), 10)
    speckle(rng, dirt, (101, 71, 49), 0.2)
    speckle(rng, dirt, (160, 120, 86), 0.08)
    tiles["dirt"] = dirt

    side = [row[:] for row in dirt]
    for x in range(TILE):
        depth = rng.choice((2, 3, 3, 4))
        for y in range(depth):
            side[y][x] = noisy(rng, (95, 159, 53) if y < depth - 1 else (74, 128, 40), 10)
    tiles["grass_side"] = side

    stone = fill(rng, (125, 125, 125), 10)
    speckle(rng, stone, (100, 100, 100), 0.18)
    speckle(rng, stone, (145, 145, 145), 0.1)
    tiles["stone"] = stone

    bark = [[None] * TILE for _ in range(TILE)]
    for x in range(TILE):
        dark = x % 4 == 1 or (x % 7 == 5)
        for y in range(TILE):
            base = (76, 60, 36) if dark or rng.random() < 0.12 else (104, 82, 51)
            bark[y][x] = noisy(rng, base, 8)
    tiles["log_side"] = bark

    top = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            ring = min(x, y, TILE - 1 - x, TILE - 1 - y)
            if ring == 0:
                c = (104, 82, 51)
            elif ring in (2, 5):
                c = (150, 118, 70)
            else:
                c = (182, 146, 92)
            top[y][x] = noisy(rng, c, 6)
    tiles["log_top"] = top

    leaves = fill(rng, (58, 120, 38), 16)
    speckle(rng, leaves, (34, 82, 24), 0.25)
    speckle(rng, leaves, (82, 150, 54), 0.12)
    tiles["leaves"] = leaves

    planks = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            seam = y % 4 == 3 or (x == (0 if (y // 4) % 2 == 0 else 8) and y % 4 != 3)
            planks[y][x] = noisy(rng, (118, 92, 55) if seam else (162, 130, 78), 7)
    tiles["planks"] = planks

    craft = [row[:] for row in planks]
    for y in range(TILE):
        for x in range(TILE):
            if x in (0, 15) or y in (0, 15):
                craft[y][x] = noisy(rng, (104, 82, 51), 6)
            elif x in (5, 10) or y in (5, 10):
                craft[y][x] = noisy(rng, (90, 70, 42), 6)
    tiles["craft_top"] = craft

    craft_side = [row[:] for row in planks]
    for x in range(TILE):
        craft_side[0][x] = craft_side[1][x] = noisy(rng, (104, 82, 51), 6)
    for y in range(4, 12):  # a saw
        for x in range(3, 7):
            craft_side[y][x] = noisy(rng, (170, 170, 175) if x < 6 else (120, 120, 125), 6)
    for y in range(5, 13):  # a hammer handle and head
        craft_side[y][11] = noisy(rng, (90, 70, 42), 6)
    for x in range(9, 14):
        craft_side[4][x] = craft_side[5][x] = noisy(rng, (110, 110, 115), 6)
    tiles["craft_side"] = craft_side

    front = [row[:] for row in craft_side]
    for y in range(6, 14):  # shears / tongs
        front[y][7] = front[y][8] = noisy(rng, (150, 150, 155), 6)
    tiles["craft_front"] = front

    farm = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            furrow = y % 4 in (0, 1)
            farm[y][x] = noisy(rng, (62, 40, 24) if furrow else (90, 60, 38), 8)
    tiles["farmland"] = farm

    obs = fill(rng, (20, 17, 30), 6)
    speckle(rng, obs, (60, 38, 92), 0.12)
    speckle(rng, obs, (38, 28, 58), 0.2)
    tiles["obsidian"] = obs

    red = fill(rng, (168, 42, 36), 8)
    white = fill(rng, (232, 234, 234), 6)
    for tile, dark in ((red, (140, 30, 26)), (white, (205, 208, 210))):
        for y in range(TILE):
            for x in range(TILE):
                if (x + y * 2) % 5 == 0:
                    tile[y][x] = noisy(rng, dark, 5)
    tiles["wool_red"] = red
    tiles["wool_white"] = white

    cobble = fill(rng, (120, 120, 120), 12)
    for _ in range(9):  # dark outlines around rounded stones
        cx, cy, r = rng.randint(0, 15), rng.randint(0, 15), rng.randint(2, 4)
        for y in range(TILE):
            for x in range(TILE):
                d = math.hypot(x - cx, y - cy)
                if r - 0.6 < d < r + 0.4:
                    cobble[y][x] = noisy(rng, (72, 72, 72), 6)
                elif d < r - 1.5:
                    cobble[y][x] = noisy(rng, (145, 145, 145), 8)
    tiles["cobblestone"] = cobble

    # Ores: stone with clumps of coloured pixels (drawn after the older tiles so those
    # keep the same random sequence and look identical)
    def ore(colors, clumps):
        tile = [row[:] for row in stone]
        for _ in range(clumps):
            cx, cy = rng.randint(0, 13), rng.randint(0, 13)
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (2, 1), (1, 2), (2, 0), (0, 2), (2, 2)):
                if rng.random() < 0.75:
                    tile[cy + dy][cx + dx] = noisy(rng, colors[(dx + dy) % len(colors)], 6)
        return tile

    tiles["coal_ore"] = ore([(30, 30, 30), (52, 52, 52)], 7)
    tiles["iron_ore"] = ore([(222, 170, 132), (176, 128, 96), (240, 206, 174)], 6)

    # Furnace: cobblestone sides, smooth stone top, a dark grated opening on the front
    furnace_side = [row[:] for row in cobble]
    for x in range(TILE):
        furnace_side[0][x] = furnace_side[15][x] = noisy(rng, (90, 90, 90), 6)
    tiles["furnace_side"] = furnace_side
    furnace_top = fill(rng, (150, 150, 150), 6)
    for i in range(TILE):
        for edge in (furnace_top[0], furnace_top[15]):
            edge[i] = noisy(rng, (105, 105, 105), 5)
        furnace_top[i][0] = furnace_top[i][15] = noisy(rng, (105, 105, 105), 5)
    tiles["furnace_top"] = furnace_top
    front = [row[:] for row in furnace_side]
    for y in range(8, 14):
        for x in range(3, 13):
            grate = y in (8, 13) or x in (3, 12)
            front[y][x] = noisy(rng, (60, 60, 60) if grate else (22, 20, 20), 4)
    for x in range(4, 12):  # embers
        if rng.random() < 0.6:
            front[12][x] = noisy(rng, (196, 92, 30), 12)
    for x in range(3, 13):  # top ledge
        front[3][x] = front[4][x] = noisy(rng, (100, 100, 100), 6)
    tiles["furnace_front"] = front

    # Portal stone: dark slate, and the same with a carved glowing rune (our own glyph:
    # a diamond with a stroke through it and two side ticks)
    slate = fill(rng, (64, 68, 86), 7)
    speckle(rng, slate, (52, 55, 70), 0.2)
    speckle(rng, slate, (78, 83, 104), 0.1)
    for i in range(TILE):
        for edge in ((0, i), (15, i), (i, 0), (i, 15)):
            slate[edge[0]][edge[1]] = noisy(rng, (44, 46, 60), 4)
    tiles["slate"] = slate
    rune = [row[:] for row in slate]
    glyph = set()
    for i in range(5):  # diamond outline around the centre
        for x, y in ((7 - i, 3 + i), (8 + i, 3 + i), (7 - i, 12 - i), (8 + i, 12 - i)):
            glyph.add((x, y))
    for y in range(2, 14):  # vertical stroke
        glyph.add((7, y)) if y % 3 else None
    for x in (2, 13):  # side ticks
        for y in (7, 8):
            glyph.add((x, y))
    for x, y in glyph:
        for dx, dy in ((1, 0), (0, 1), (1, 1)):  # carved shadow
            if 0 <= x + dx < TILE and 0 <= y + dy < TILE and (x + dx, y + dy) not in glyph:
                rune[y + dy][x + dx] = noisy(rng, (34, 36, 48), 3)
    for x, y in glyph:
        rune[y][x] = noisy(rng, (92, 232, 210), 10)
    tiles["runestone"] = rune
    return tiles


def build_atlas():
    tiles = draw_tiles()
    image = bpy.data.images.new("Blocks", ATLAS, ATLAS, alpha=False)
    pixels = [0.0] * (ATLAS * ATLAS * 4)
    for index, name in enumerate(TILES):
        col, row = index % GRID, index // GRID
        tile = tiles[name]
        for ty in range(TILE):
            for tx in range(TILE):
                r, g, b = (c / 255 for c in tile[ty][tx])
                for sy in range(SCALE):
                    for sx in range(SCALE):
                        px = (col * TILE + tx) * SCALE + sx
                        # Tile row 0 is the top of the tile; image rows start at the bottom
                        py = ((GRID - 1 - row) * TILE + (TILE - 1 - ty)) * SCALE + sy
                        i = (py * ATLAS + px) * 4
                        pixels[i : i + 4] = [r, g, b, 1.0]
    image.pixels = pixels
    path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "textures", "blocks.png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()

    mat = bpy.data.materials.new("Blocks")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def tile_rect(name):
    index = TILES.index(name)
    col, row = index % GRID, index // GRID
    inset = 0.5 / ATLAS
    u0 = col / GRID + inset
    u1 = (col + 1) / GRID - inset
    v1 = 1 - row / GRID - inset
    v0 = 1 - (row + 1) / GRID + inset
    return u0, v0, u1, v1


def make_block(name, faces, mat):
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    bmesh.ops.create_cube(bm, size=BLOCK)
    half = BLOCK / 2
    top, bottom = faces[0], faces[1]
    front = faces[2]
    sides = faces[3] if len(faces) > 3 else faces[2]
    for face in bm.faces:
        n = face.normal
        if n.z > 0.5:
            tile = top
        elif n.z < -0.5:
            tile = bottom
        elif n.y < -0.5:
            tile = front  # -Y is the front
        else:
            tile = sides
        u0, v0, u1, v1 = tile_rect(tile)
        for loop in face.loops:
            co = loop.vert.co
            if abs(n.z) > 0.5:
                s, t = (co.x + half) / BLOCK, (co.y + half) / BLOCK
            else:
                # Horizontal axis along the face, vertical = z (so grass stays on top)
                if abs(n.x) > 0.5:
                    s = (co.y + half) / BLOCK if n.x > 0 else (half - co.y) / BLOCK
                else:
                    s = (half - co.x) / BLOCK if n.y > 0 else (co.x + half) / BLOCK
                t = (co.z + half) / BLOCK
            loop[uv].uv = (u0 + (u1 - u0) * s, v0 + (v1 - v0) * t)
    mesh = bpy.data.meshes.new("Block_" + name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Block_" + name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def main():
    common.reset_scene()
    mat = build_atlas()
    objects = [make_block(name, faces, mat) for name, faces in BLOCKS.items()]

    # Preview: blocks in a row, then back to the origin for export
    for i, obj in enumerate(objects):
        obj.location = ((i % 6) * 4.0 - 10, (i // 6) * 4.0, 0)
    common.render_preview("Blocks", target=(0, 2, 0), distance=26, height=14, angle_deg=-25)
    for obj in objects:
        obj.location = (0, 0, 0)

    common.save_blend("Blocks")
    os.makedirs(common.EXPORT_DIR, exist_ok=True)
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in objects)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(common.EXPORT_DIR, "Blocks.fbx"),
        use_selection=True,
        object_types={"MESH"},
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        path_mode="COPY",
        embed_textures=True,
    )
    print("fbx: done")


main()
