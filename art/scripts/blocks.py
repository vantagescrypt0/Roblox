"""Minecraft-style blocks: 16x16 pixel-art tiles in one atlas, and a 3-stud cube mesh per
block type with each face mapped to the right tile (grass: green top, grass side, dirt
bottom; logs: bark sides, rings on top/bottom; ...).

Also merged pieces for the shared worlds' scenery (see game/src/server/Util/BlockWorld.luau):
boxes several blocks big ("Merged_Stone_8x4x8": 8 blocks along x, 4 up, 8 along z) whose
every face is cut into one quad per block, each mapped to that block's tile, so a piece
looks exactly like the blocks it stands in for. They share the atlas, so they batch.

Tiles are drawn procedurally (seeded noise) and scaled up 7x with nearest-neighbour so
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
SCALE = 7
GRID = 9  # 9x9 tiles
ATLAS = TILE * SCALE * GRID  # 1008 px (Roblox's limit is 1024)

TILES = [
    "grass_top", "grass_side", "dirt", "stone",
    "log_side", "log_top", "leaves", "planks",
    "craft_top", "craft_side", "farmland", "obsidian",
    "wool_red", "wool_white", "cobblestone", "craft_front",
    "coal_ore", "iron_ore", "furnace_front", "furnace_side",
    "furnace_top", "slate", "runestone",
    # Building and scenery blocks for the Town and the worlds
    "stone_bricks", "mossy_stone_bricks", "mossy_cobble", "bricks",
    "dark_planks", "barn_planks", "plaster", "smooth_stone",
    "roof_red", "roof_slate", "thatch", "gravel",
    "sand", "path_top", "dark_stone", "hay_top",
    "hay_side", "crate", "barrel_top", "barrel_side",
    "bookshelf", "flower_grass",
    # The worlds' zones: zone trees, snow, autumn, gold, pumpkins and melons, mesa rock
    "birch_log_side", "birch_log_top", "birch_leaves",
    "spruce_log_side", "spruce_log_top", "spruce_leaves",
    "cherry_log_side", "cherry_log_top", "cherry_leaves",
    "autumn_leaves", "snow", "snowy_grass_side", "gold_ore",
    "pumpkin_top", "pumpkin_side", "melon_top", "melon_side",
    "terracotta", "red_terracotta",
    # Skybounds references: the mine's sandstone mountain, coarse woodland dirt, giant
    # mushrooms, ruins
    "sandstone_top", "sandstone_side", "coarse_dirt", "mushroom_cap", "mushroom_stem",
    "cracked_stone_bricks",
    # Resource nodes: a mined ore while it grows back
    "empty_ore",
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
    "StoneBricks": ("stone_bricks", "stone_bricks", "stone_bricks"),
    "MossyStoneBricks": ("mossy_stone_bricks", "stone_bricks", "mossy_stone_bricks"),
    "MossyCobblestone": ("mossy_cobble", "cobblestone", "mossy_cobble"),
    "Bricks": ("bricks", "bricks", "bricks"),
    "DarkPlanks": ("dark_planks", "dark_planks", "dark_planks"),
    "BarnPlanks": ("barn_planks", "barn_planks", "barn_planks"),
    "Plaster": ("plaster", "plaster", "plaster"),
    "SmoothStone": ("smooth_stone", "smooth_stone", "smooth_stone"),
    "RoofRed": ("roof_red", "roof_red", "roof_red"),
    "RoofSlate": ("roof_slate", "roof_slate", "roof_slate"),
    "Thatch": ("thatch", "thatch", "thatch"),
    "Gravel": ("gravel", "gravel", "gravel"),
    "Sand": ("sand", "sand", "sand"),
    "Path": ("path_top", "dirt", "dirt"),
    "DarkStone": ("dark_stone", "dark_stone", "dark_stone"),
    "HayBale": ("hay_top", "hay_top", "hay_side"),
    "Crate": ("crate", "crate", "crate"),
    "Barrel": ("barrel_top", "barrel_top", "barrel_side"),
    "Bookshelf": ("planks", "planks", "bookshelf"),
    "FlowerGrass": ("flower_grass", "dirt", "grass_side"),
    "BirchWood": ("birch_log_top", "birch_log_top", "birch_log_side"),
    "SpruceWood": ("spruce_log_top", "spruce_log_top", "spruce_log_side"),
    "CherryWood": ("cherry_log_top", "cherry_log_top", "cherry_log_side"),
    "BirchLeaves": ("birch_leaves", "birch_leaves", "birch_leaves"),
    "SpruceLeaves": ("spruce_leaves", "spruce_leaves", "spruce_leaves"),
    "CherryLeaves": ("cherry_leaves", "cherry_leaves", "cherry_leaves"),
    "AutumnLeaves": ("autumn_leaves", "autumn_leaves", "autumn_leaves"),
    "Snow": ("snow", "snow", "snow"),
    "SnowyGrass": ("snow", "dirt", "snowy_grass_side"),
    "GoldOre": ("gold_ore", "gold_ore", "gold_ore"),
    "Pumpkin": ("pumpkin_top", "pumpkin_top", "pumpkin_side"),
    "Melon": ("melon_top", "melon_top", "melon_side"),
    "Terracotta": ("terracotta", "terracotta", "terracotta"),
    "RedTerracotta": ("red_terracotta", "red_terracotta", "red_terracotta"),
    "Sandstone": ("sandstone_top", "sandstone_top", "sandstone_side"),
    "CoarseDirt": ("coarse_dirt", "coarse_dirt", "coarse_dirt"),
    "MushroomCap": ("mushroom_cap", "mushroom_cap", "mushroom_cap"),
    "MushroomStem": ("mushroom_stem", "mushroom_stem", "mushroom_stem"),
    "CrackedStoneBricks": ("cracked_stone_bricks", "cracked_stone_bricks", "cracked_stone_bricks"),
    "EmptyOre": ("empty_ore", "empty_ore", "empty_ore"),
}

# Merged pieces (x, y, z in blocks; each also fills z, y, x turned a quarter turn).
# Ground that's one block deep gets slabs, soil also two-deep slabs, rock big cubes too.
SLABS = [(16, 1, 16), (8, 1, 8), (8, 1, 4), (4, 1, 4), (4, 1, 2), (2, 1, 2), (4, 1, 1), (2, 1, 1)]
THICK = [(8, 2, 8), (4, 2, 4), (4, 2, 2), (2, 2, 2), (2, 2, 1)]
CUBES = [(16, 4, 16), (8, 4, 8), (4, 4, 4), (4, 4, 1), (8, 8, 8)]
MERGED = {
    "Grass": SLABS,
    "SnowyGrass": SLABS,
    "Snow": SLABS,
    "Path": SLABS,
    "Gravel": SLABS,
    "SmoothStone": SLABS,
    "DarkPlanks": SLABS,
    "Sand": SLABS + THICK,
    "Dirt": SLABS + THICK,
    "Stone": SLABS + THICK + CUBES,
    "DarkStone": SLABS + THICK + CUBES,
    "Terracotta": SLABS + THICK + CUBES,
    "RedTerracotta": SLABS + THICK + CUBES,
    "Sandstone": SLABS + THICK + CUBES,
    "CoarseDirt": SLABS + THICK,
    # The worlds' open fields (the client works out which block of a piece you click)
    "Farmland": SLABS,
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

    draw_building_tiles(tiles)
    return tiles


def shade(color, factor):
    return tuple(clamp(c * factor) for c in color)


def bricks_tile(rng, base, mortar, light, width=8, height=4, tint=0.0):
    """Offset rows of bricks (width x height px, both dividing 16 so the tile repeats),
    with a mortar line on the bottom/right of each brick and a highlight on the top/left.
    `tint` varies each brick's colour a little."""
    tile = [[None] * TILE for _ in range(TILE)]
    tints = {}
    for y in range(TILE):
        row = y // height
        offset = width // 2 if row % 2 else 0
        for x in range(TILE):
            lx, ly = (x + offset) % width, y % height
            brick = (row, (x + offset) // width % (TILE // width))
            if brick not in tints:
                tints[brick] = 1 + rng.uniform(-tint, tint)
            if ly == height - 1 or lx == width - 1:
                tile[y][x] = noisy(rng, mortar, 5)
            elif ly == 0 or lx == 0:
                tile[y][x] = noisy(rng, shade(light, tints[brick]), 5)
            else:
                tile[y][x] = noisy(rng, shade(base, tints[brick]), 7)
    return tile


def mossy(rng, tile, clumps):
    """A copy of `tile` with patches of moss, thicker near the top"""
    out = [row[:] for row in tile]
    for _ in range(clumps):
        cx, cy, r = rng.randint(0, 15), rng.randint(0, 9), rng.uniform(1.2, 3.2)
        for y in range(TILE):
            for x in range(TILE):
                d = math.hypot(x - cx, y - cy)
                if d < r and rng.random() < 1.1 - d / r:
                    out[y][x] = noisy(rng, (74, 112, 48) if rng.random() < 0.6 else (96, 136, 60), 8)
    return out


def shingles(rng, base, dark, light):
    """Roof tiles: overlapping rows of shingles, each darker at its lower edge"""
    tile = [[None] * TILE for _ in range(TILE)]
    tints = {}
    for y in range(TILE):
        row = y // 4
        offset = 2 if row % 2 else 0
        for x in range(TILE):
            lx, ly = (x + offset) % 4, y % 4
            key = (row, (x + offset) // 4 % 4)
            if key not in tints:
                tints[key] = 1 + rng.uniform(-0.07, 0.07)
            if ly == 3:
                tile[y][x] = noisy(rng, dark, 5)
            elif lx == 3:
                tile[y][x] = noisy(rng, shade(dark, 1.12), 5)
            elif ly == 0:
                tile[y][x] = noisy(rng, shade(light, tints[key]), 5)
            else:
                tile[y][x] = noisy(rng, shade(base, tints[key]), 6)
    return tile


def draw_building_tiles(tiles):
    rng = random.Random(23)

    tiles["stone_bricks"] = bricks_tile(rng, (122, 122, 124), (80, 80, 84), (146, 146, 148), tint=0.05)
    tiles["mossy_stone_bricks"] = mossy(rng, tiles["stone_bricks"], 6)
    tiles["mossy_cobble"] = mossy(rng, tiles["cobblestone"], 7)
    tiles["bricks"] = bricks_tile(rng, (152, 74, 56), (178, 170, 160), (176, 94, 72), tint=0.1)

    def planks_tile(base, seam):
        tile = [[None] * TILE for _ in range(TILE)]
        for y in range(TILE):
            for x in range(TILE):
                edge = y % 4 == 3 or (x == (2 if (y // 4) % 2 == 0 else 10) and y % 4 != 3)
                tile[y][x] = noisy(rng, seam if edge else base, 6)
        return tile

    tiles["dark_planks"] = planks_tile((96, 66, 40), (64, 44, 28))

    barn = [[None] * TILE for _ in range(TILE)]  # vertical red boards
    for y in range(TILE):
        for x in range(TILE):
            seam = x % 4 == 3 or (y == (5 if (x // 4) % 2 else 11) and x % 4 != 3)
            barn[y][x] = noisy(rng, (104, 30, 26) if seam else (152, 46, 40), 7)
    tiles["barn_planks"] = barn

    plaster = fill(rng, (230, 222, 202), 5)
    speckle(rng, plaster, (212, 202, 182), 0.14, 4)
    speckle(rng, plaster, (240, 234, 218), 0.08, 3)
    for x, y in ((3, 4), (4, 5), (4, 6), (11, 10), (12, 10), (12, 11)):  # hairline cracks
        plaster[y][x] = noisy(rng, (190, 180, 160), 4)
    tiles["plaster"] = plaster

    smooth = fill(rng, (162, 162, 164), 4)
    for i in range(TILE):
        for y, x in ((0, i), (15, i), (i, 0), (i, 15)):
            smooth[y][x] = noisy(rng, (132, 132, 136), 3)
    tiles["smooth_stone"] = smooth

    tiles["roof_red"] = shingles(rng, (176, 80, 50), (122, 50, 32), (204, 108, 72))
    tiles["roof_slate"] = shingles(rng, (84, 96, 118), (56, 64, 82), (110, 124, 146))

    thatch = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            thatch[y][x] = noisy(rng, (150, 116, 54) if y % 3 == 2 else (196, 160, 82), 10)
        x = rng.randint(0, 15)  # a few loose strands
        for dx in range(rng.randint(2, 5)):
            thatch[y][(x + dx) % TILE] = noisy(rng, (222, 190, 110), 6)
    tiles["thatch"] = thatch

    gravel = fill(rng, (128, 122, 116), 10)
    for color, chance in (((96, 92, 88), 0.2), ((156, 150, 142), 0.14), ((124, 106, 90), 0.1), ((176, 170, 162), 0.05)):
        speckle(rng, gravel, color, chance, 6)
    tiles["gravel"] = gravel

    sand = fill(rng, (220, 208, 164), 6)
    speckle(rng, sand, (200, 186, 140), 0.2, 5)
    speckle(rng, sand, (234, 224, 188), 0.1, 4)
    tiles["sand"] = sand

    path = fill(rng, (150, 120, 76), 8)
    speckle(rng, path, (124, 96, 60), 0.2, 6)
    speckle(rng, path, (174, 144, 96), 0.12, 6)
    speckle(rng, path, (130, 128, 122), 0.03, 6)  # pebbles
    tiles["path_top"] = path

    dark = fill(rng, (60, 60, 68), 5)
    for y in range(TILE):  # layered streaks
        if rng.random() < 0.45:
            x0 = rng.randint(0, 15)
            for dx in range(rng.randint(3, 8)):
                dark[y][(x0 + dx) % TILE] = noisy(rng, (46, 46, 54), 4)
    speckle(rng, dark, (80, 80, 90), 0.07, 5)
    tiles["dark_stone"] = dark

    hay_top = fill(rng, (206, 170, 70), 10)
    speckle(rng, hay_top, (168, 132, 46), 0.25, 8)
    speckle(rng, hay_top, (234, 202, 104), 0.12, 6)
    for i in range(TILE):
        for y, x in ((0, i), (15, i), (i, 0), (i, 15)):
            hay_top[y][x] = noisy(rng, (172, 136, 50), 6)
    tiles["hay_top"] = hay_top
    hay_side = [[None] * TILE for _ in range(TILE)]
    for x in range(TILE):
        column = (212, 176, 76) if x % 2 == 0 else (190, 152, 58)
        for y in range(TILE):
            band = y in (3, 4, 11, 12)
            hay_side[y][x] = noisy(rng, (118, 80, 42) if band else column, 8)
    tiles["hay_side"] = hay_side

    crate = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            if x < 2 or x > 13 or y < 2 or y > 13:
                c = (112, 80, 46)
            elif abs((15 - x) - y) <= 1:  # diagonal brace
                c = (124, 90, 54)
            elif y % 4 == 1:
                c = (148, 114, 68)
            else:
                c = (178, 142, 88)
            crate[y][x] = noisy(rng, c, 6)
    tiles["crate"] = crate

    barrel_top = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            d = math.hypot(x - 7.5, y - 7.5)
            if d > 7.6:
                c = (80, 58, 36)
            elif d > 6.4:
                c = (88, 88, 94)
            else:
                c = (128, 92, 54) if x % 4 == 1 else (156, 114, 66)
            barrel_top[y][x] = noisy(rng, c, 6)
    tiles["barrel_top"] = barrel_top
    barrel_side = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            if y in (2, 13):
                c = (112, 112, 120)
            elif y in (3, 12):
                c = (78, 78, 86)
            elif x % 4 == 3:
                c = (108, 74, 42)
            else:
                c = (150, 106, 62)
            barrel_side[y][x] = noisy(rng, c, 6)
    tiles["barrel_side"] = barrel_side

    shelf = [[None] * TILE for _ in range(TILE)]
    book_colors = [(150, 42, 38), (46, 86, 150), (48, 120, 62), (152, 120, 52), (112, 72, 140), (196, 186, 166)]
    for y in range(TILE):
        for x in range(TILE):
            board = y in (0, 7, 8, 15)
            shelf[y][x] = noisy(rng, (118, 92, 55) if board else (44, 32, 22), 5)
    for top in (1, 9):
        x = 1
        while x < 15:
            width = 1 if rng.random() < 0.6 else 2
            height = rng.randint(4, 6)
            color = rng.choice(book_colors)
            for bx in range(x, min(x + width, 15)):
                for by in range(top + 6 - height, top + 6):
                    shelf[by][bx] = noisy(rng, color, 8)
            x += width + (1 if rng.random() < 0.15 else 0)
    tiles["bookshelf"] = shelf

    flowers = [row[:] for row in tiles["grass_top"]]
    for color in ((222, 62, 52), (242, 212, 64), (242, 242, 242), (96, 124, 224), (222, 62, 52), (242, 212, 64)):
        cx, cy = rng.randint(1, 14), rng.randint(1, 14)
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            flowers[cy + dy][cx + dx] = noisy(rng, color, 8)
        flowers[cy][cx] = noisy(rng, (250, 232, 120), 6)
    tiles["flower_grass"] = flowers
    draw_zone_tiles(tiles)
    draw_reference_tiles(tiles)
    draw_node_tiles(tiles)


def draw_zone_tiles(tiles):
    """Tiles for the worlds' zones (their own random sequence, so older tiles stay put)"""
    rng = random.Random(41)

    def bark(base, dark, mark=None):
        tile = [[None] * TILE for _ in range(TILE)]
        for x in range(TILE):
            stripe = x % 4 == 1 or x % 7 == 5
            for y in range(TILE):
                tile[y][x] = noisy(rng, dark if stripe or rng.random() < 0.1 else base, 7)
        if mark:  # birch: short dark dashes across the white bark
            for _ in range(9):
                x0, y = rng.randint(0, 13), rng.randint(0, 15)
                for dx in range(rng.randint(2, 4)):
                    tile[y][(x0 + dx) % TILE] = noisy(rng, mark, 6)
        return tile

    def rings(heart, ring, edge):
        tile = [[None] * TILE for _ in range(TILE)]
        for y in range(TILE):
            for x in range(TILE):
                r = min(x, y, TILE - 1 - x, TILE - 1 - y)
                c = edge if r == 0 else ring if r in (2, 5) else heart
                tile[y][x] = noisy(rng, c, 6)
        return tile

    def leafy(base, dark, light, extra=None):
        tile = fill(rng, base, 14)
        speckle(rng, tile, dark, 0.25)
        speckle(rng, tile, light, 0.12)
        if extra:
            speckle(rng, tile, extra, 0.05)
        return tile

    tiles["birch_log_side"] = bark((222, 218, 206), (196, 192, 180), (44, 42, 40))
    tiles["birch_log_top"] = rings((214, 192, 140), (188, 164, 112), (230, 228, 220))
    tiles["birch_leaves"] = leafy((112, 160, 70), (84, 128, 50), (146, 190, 92))
    tiles["spruce_log_side"] = bark((76, 54, 32), (54, 38, 22))
    tiles["spruce_log_top"] = rings((150, 112, 66), (118, 86, 50), (62, 44, 26))
    tiles["spruce_leaves"] = leafy((46, 86, 58), (30, 62, 42), (64, 108, 76))
    tiles["cherry_log_side"] = bark((96, 56, 60), (70, 38, 44))
    tiles["cherry_log_top"] = rings((214, 156, 146), (186, 124, 118), (80, 44, 50))
    tiles["cherry_leaves"] = leafy((240, 168, 200), (214, 124, 166), (252, 206, 224), (255, 246, 250))
    tiles["autumn_leaves"] = leafy((222, 122, 42), (188, 66, 36), (238, 184, 64))

    snow = fill(rng, (242, 246, 250), 5)
    speckle(rng, snow, (218, 228, 240), 0.18, 4)
    tiles["snow"] = snow
    side = [row[:] for row in tiles["dirt"]]
    for x in range(TILE):
        depth = rng.choice((3, 4, 4, 5))
        for y in range(depth):
            side[y][x] = noisy(rng, (242, 246, 250) if y < depth - 1 else (214, 224, 236), 5)
    tiles["snowy_grass_side"] = side

    gold = [row[:] for row in tiles["stone"]]
    for _ in range(6):
        cx, cy = rng.randint(0, 13), rng.randint(0, 13)
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (2, 1), (1, 2), (2, 0), (0, 2), (2, 2)):
            if rng.random() < 0.75:
                gold[cy + dy][cx + dx] = noisy(rng, ((252, 220, 76), (222, 170, 40), (255, 242, 150))[(dx + dy) % 3], 6)
    tiles["gold_ore"] = gold

    # Pumpkins and melons: ribbed sides, a stem on top
    pumpkin = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            rib = x % 4 == 0
            pumpkin[y][x] = noisy(rng, (186, 94, 20) if rib else (228, 128, 32) if x % 4 != 2 else (240, 150, 50), 6)
    tiles["pumpkin_side"] = pumpkin
    top = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            d = max(abs(x - 7.5), abs(y - 7.5))
            top[y][x] = noisy(rng, (196, 102, 24) if int(d) % 3 == 0 else (226, 126, 32), 6)
    for y in range(6, 10):
        for x in range(6, 10):
            top[y][x] = noisy(rng, (96, 110, 40) if (x + y) % 3 else (70, 84, 30), 6)
    tiles["pumpkin_top"] = top
    melon = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            zig = (x + (y // 2) % 2) % 5 == 0
            melon[y][x] = noisy(rng, (156, 200, 84) if zig else (92, 156, 48), 8)
    tiles["melon_side"] = melon
    melon_top = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        for x in range(TILE):
            d = math.hypot(x - 7.5, y - 7.5)
            melon_top[y][x] = noisy(rng, (150, 194, 80) if int(d) % 3 == 0 else (98, 160, 52), 8)
    tiles["melon_top"] = melon_top

    terracotta = fill(rng, (164, 86, 54), 5)
    speckle(rng, terracotta, (150, 76, 46), 0.15, 4)
    tiles["terracotta"] = terracotta
    red = fill(rng, (140, 58, 44), 5)
    speckle(rng, red, (124, 50, 38), 0.15, 4)
    tiles["red_terracotta"] = red


def draw_reference_tiles(tiles):
    """Tiles from the Skybounds reference shots (their own random sequence)"""
    rng = random.Random(57)

    # Sandstone: soft tan layers with a darker line every few rows, smooth on top
    side = [[None] * TILE for _ in range(TILE)]
    for y in range(TILE):
        band = (214, 196, 148) if y < 4 else (204, 184, 134) if y < 10 else (194, 172, 122)
        for x in range(TILE):
            line = y in (3, 9, 15) or (y in (4, 10) and rng.random() < 0.3)
            side[y][x] = noisy(rng, shade(band, 0.86) if line else band, 5)
    tiles["sandstone_side"] = side
    top = fill(rng, (218, 202, 156), 5)
    speckle(rng, top, (204, 186, 138), 0.15, 4)
    for i in range(TILE):
        for y, x in ((0, i), (15, i), (i, 0), (i, 15)):
            top[y][x] = noisy(rng, (198, 178, 128), 4)
    tiles["sandstone_top"] = top

    # Coarse dirt: reddish-brown with dark clods and a few pale pebbles
    coarse = fill(rng, (138, 88, 60), 10)
    speckle(rng, coarse, (104, 64, 44), 0.25, 6)
    speckle(rng, coarse, (160, 110, 78), 0.12, 6)
    speckle(rng, coarse, (150, 140, 128), 0.04, 6)
    tiles["coarse_dirt"] = coarse

    # Giant mushroom: a red cap with white spots, and a pale stem
    cap = fill(rng, (196, 44, 40), 8)
    for _ in range(5):
        cx, cy, r = rng.randint(1, 14), rng.randint(1, 14), rng.uniform(1.2, 2.2)
        for y in range(TILE):
            for x in range(TILE):
                if math.hypot(x - cx, y - cy) < r:
                    cap[y][x] = noisy(rng, (238, 232, 222), 5)
    tiles["mushroom_cap"] = cap
    stem = fill(rng, (226, 218, 198), 5)
    for y in range(TILE):
        for x in range(TILE):
            if (x + y * 3) % 7 == 0:
                stem[y][x] = noisy(rng, (204, 194, 170), 4)
    tiles["mushroom_stem"] = stem

    # Cracked stone bricks: stone bricks with dark cracks running across
    cracked = [row[:] for row in tiles["stone_bricks"]]
    for _ in range(3):
        x, y = rng.randint(0, 15), rng.randint(0, 15)
        for _ in range(rng.randint(5, 9)):
            cracked[y][x] = noisy(rng, (58, 58, 62), 4)
            x = (x + rng.choice((-1, 0, 1, 1))) % TILE
            y = (y + rng.choice((0, 1, 1))) % TILE
    tiles["cracked_stone_bricks"] = cracked


def draw_node_tiles(tiles):
    """Tiles for resource nodes (their own random sequence)"""
    rng = random.Random(83)

    # Empty ore: a mined ore node while it grows back. Pale stone where the ore's clumps
    # still show, but hollow: just their outlines, nothing filled in
    empty = [[tuple(clamp(v + (226 - v) * 0.5) for v in pixel) for pixel in row] for row in tiles["stone"]]
    pocket = set()
    centers = []
    for _ in range(200):
        if len(centers) == 6:
            break
        cx, cy = rng.uniform(2.5, 13.5), rng.uniform(2.5, 13.5)
        rx, ry = rng.uniform(1.4, 2.1), rng.uniform(1.3, 1.9)
        if any(math.hypot(cx - ox, cy - oy) < 4.6 for ox, oy in centers):
            continue
        centers.append((cx, cy))
        for y in range(TILE):
            for x in range(TILE):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                    pocket.add((x, y))
    for x, y in sorted(pocket):
        if any((x + dx, y + dy) not in pocket for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            empty[y][x] = noisy(rng, (116, 116, 114), 5)
        elif (x, y - 1) in pocket and (x, y - 2) not in pocket:
            # A faint shadow under each pocket's top edge, so it reads as a hollow
            empty[y][x] = noisy(rng, (160, 159, 156), 4)
    tiles["empty_ore"] = empty


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


def make_merged(name, faces, size, mat):
    """A box `size` blocks (x along x, y up, z along Blender's y) with one quad per block on
    every face, each mapped to that face's tile like a single block's face"""
    sx, sy, sz = size
    top, bottom, sides = faces[0], faces[1], faces[2]
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    hx, hy, hz = sx * BLOCK / 2, sz * BLOCK / 2, sy * BLOCK / 2  # Blender x, y, z

    def quad(corners, tile):
        verts = [bm.verts.new(c) for c in corners]
        face = bm.faces.new(verts)
        u0, v0, u1, v1 = tile_rect(tile)
        # Corners go bottom-left, bottom-right, top-right, top-left as seen from outside
        for loop, (s, t) in zip(face.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
            loop[uv].uv = (u0 + (u1 - u0) * s, v0 + (v1 - v0) * t)

    b = BLOCK
    for i in range(sx):
        for j in range(sz):
            x0, y0 = -hx + i * b, -hy + j * b
            quad([(x0, y0, hz), (x0 + b, y0, hz), (x0 + b, y0 + b, hz), (x0, y0 + b, hz)], top)
            quad([(x0, y0 + b, -hz), (x0 + b, y0 + b, -hz), (x0 + b, y0, -hz), (x0, y0, -hz)], bottom)
    for k in range(sy):
        z0 = -hz + k * b
        for i in range(sx):
            x0 = -hx + i * b
            # -Y side (front) and +Y side (back), seen from outside
            quad([(x0, -hy, z0), (x0 + b, -hy, z0), (x0 + b, -hy, z0 + b), (x0, -hy, z0 + b)], sides)
            quad([(x0 + b, hy, z0), (x0, hy, z0), (x0, hy, z0 + b), (x0 + b, hy, z0 + b)], sides)
        for j in range(sz):
            y0 = -hy + j * b
            quad([(hx, y0, z0), (hx, y0 + b, z0), (hx, y0 + b, z0 + b), (hx, y0, z0 + b)], sides)
            quad([(-hx, y0 + b, z0), (-hx, y0, z0), (-hx, y0, z0 + b), (-hx, y0 + b, z0 + b)], sides)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    label = f"Merged_{name}_{sx}x{sy}x{sz}"
    mesh = bpy.data.meshes.new(label)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(label, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def main():
    common.reset_scene()
    mat = build_atlas()
    objects = [make_block(name, faces, mat) for name, faces in BLOCKS.items()]

    # Preview: blocks in a row, then back to the origin for export
    for i, obj in enumerate(objects):
        obj.location = ((i % 8) * 4.0 - 14, (i // 8) * 4.0, 0)
    common.render_preview("Blocks", target=(0, 8, 0), distance=40, height=22, angle_deg=-25)
    for obj in objects:
        obj.location = (0, 0, 0)
    merged = [
        make_merged(name, BLOCKS[name], size, mat) for name, sizes in MERGED.items() for size in sizes
    ]
    objects += merged
    print(f"blocks: {len(BLOCKS)}, merged pieces: {len(merged)}")

    common.save_blend("Blocks")
    os.makedirs(common.EXPORT_DIR, exist_ok=True)

    def export(path, chosen):
        for obj in bpy.context.scene.objects:
            obj.select_set(obj in chosen)
        bpy.ops.export_scene.fbx(
            filepath=path,
            use_selection=True,
            object_types={"MESH"},
            apply_scale_options="FBX_SCALE_ALL",
            axis_forward="-Z",
            axis_up="Y",
            mesh_smooth_type="FACE",
            path_mode="COPY",
            embed_textures=True,
        )

    export(os.path.join(common.EXPORT_DIR, "Blocks.fbx"), objects)
    print("fbx: done")
    # Block names after "--" also go in Blocks_new.fbx (with their merged pieces), so new
    # blocks can be imported without re-uploading every mesh: ... blocks.py -- Sandstone
    names = set(sys.argv[sys.argv.index("--") + 1 :]) if "--" in sys.argv else set()
    if names:
        chosen = [o for o in objects if o.name.split("_")[1] in names]
        export(os.path.join(common.EXPORT_DIR, "Blocks_new.fbx"), chosen)
        print("new:", [o.name for o in chosen])


main()
