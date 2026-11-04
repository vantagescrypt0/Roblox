"""Draws the pixel icons over the hotbar: hearts, hunger and armour, each full, half and empty, as one
sheet (art/textures/ui/vitals.png). Minecraft's layout and behaviour, your call (2026-11-03), but these
are our own drawings: Mojang's own art can't go in a published game. The row order is in
game/src/client/VitalsHud.luau. No libraries needed:
    python art/scripts/vitals_icons.py
"""
import os
import struct
import zlib

CELL = 11  # pixels each way
SCALE = 4  # the sheet is drawn this much bigger, so it stays crisp however Roblox samples it
TRANSPARENT = (0, 0, 0, 0)

HEART = [
    "...........",
    ".kkk...kkk.",
    "kHHmk.kmmmk",
    "kHmmmkmmmmk",
    "kmmmmmmmmsk",
    "kmmmmmmmmsk",
    ".kmmmmmmsk.",
    "..kmmmmsk..",
    "...kmmsk...",
    "....ksk....",
    ".....k.....",
]
FOOD = [
    "......kkkk.",
    ".....kHHmmk",
    "....kHmmmmk",
    "...kHmmmmmk",
    "...kmmmmmsk",
    "...kmmmmsk.",
    "..kBksskk..",
    ".kBBkkk....",
    "kWWBk......",
    "kWWk.......",
    ".kk........",
]
ARMOUR = [
    ".kkk...kkk.",
    "kHHHkkkHmmk",
    "kHmmmmmmmsk",
    ".kkmmmmmkk.",
    "..kHmmmsk..",
    "..kHmmmsk..",
    "..kHmmmsk..",
    "..kHmmmsk..",
    "..kHmmmsk..",
    "..kkkkkkk..",
    "...........",
]

OUTLINE = (22, 12, 20, 255)
WELL = (40, 34, 48, 190)  # inside an empty icon
FLASH = (245, 245, 250, 255)

RED = {"H": (255, 150, 150, 255), "m": (226, 42, 58, 255), "s": (150, 20, 38, 255)}
GREEN = {"H": (196, 240, 120, 255), "m": (106, 178, 52, 255), "s": (62, 116, 30, 255)}
MEAT = {
    "H": (238, 170, 100, 255),
    "m": (196, 116, 58, 255),
    "s": (138, 72, 34, 255),
    "B": (226, 216, 192, 255),
    "W": (255, 250, 236, 255),
}
STEEL = {"H": (238, 244, 252, 255), "m": (186, 198, 214, 255), "s": (122, 134, 154, 255)}


def icon(shape, colours, fill="full", side="left", outline=OUTLINE):
    """One icon as rows of colours. `fill` is full, half (the `side` half filled) or empty."""
    rows = []
    for row in shape:
        pixels = []
        for x, ch in enumerate(row):
            if ch == ".":
                pixels.append(TRANSPARENT)
            elif ch == "k":
                pixels.append(outline)
            else:
                filled = fill == "full" or (
                    fill == "half" and (x <= CELL // 2 if side == "left" else x >= CELL // 2)
                )
                pixels.append(colours[ch] if filled else WELL)
        rows.append(pixels)
    return rows


# In the order VitalsHud reads them
CELLS = [
    icon(HEART, RED),
    icon(HEART, RED, "half"),
    icon(HEART, RED, "empty"),
    icon(HEART, RED, "empty", outline=FLASH),
    icon(HEART, GREEN),
    icon(HEART, GREEN, "half"),
    icon(FOOD, MEAT),
    icon(FOOD, MEAT, "half", "right"),
    icon(FOOD, MEAT, "empty"),
    icon(ARMOUR, STEEL),
    icon(ARMOUR, STEEL, "half"),
    icon(ARMOUR, STEEL, "empty"),
]


def write_png(path, width, height, rows):
    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    raw = b"".join(b"\0" + bytes(value for pixel in row for value in pixel) for row in rows)
    with open(path, "wb") as out:
        out.write(b"\x89PNG\r\n\x1a\n")
        out.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
        out.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        out.write(chunk(b"IEND", b""))


def main():
    size = CELL * SCALE
    rows = []
    for y in range(size):
        row = []
        for cell in CELLS:
            source = cell[y // SCALE]
            for x in range(size):
                row.append(source[x // SCALE])
        rows.append(row)
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "textures", "ui", "vitals.png")
    write_png(path, size * len(CELLS), size, rows)
    print(os.path.abspath(path), size * len(CELLS), size)


main()
