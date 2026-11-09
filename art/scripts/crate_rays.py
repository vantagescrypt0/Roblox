"""The light rays behind a Loot Crate as it bursts open (client/CrateOpening.luau): white, so the game can tint them, with
soft edges and no background. Plain Python, as this machine's has no Pillow.

    python art/scripts/crate_rays.py     writes art/textures/ui/rays.png; upload it with Studio's upload_image
"""
import math
import os
import struct
import zlib

SIZE = 512
RAYS = 14
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "textures", "ui", "rays.png")


def alpha(x, y):
    dx, dy = x - SIZE / 2 + 0.5, y - SIZE / 2 + 0.5
    radius = math.hypot(dx, dy) / (SIZE / 2)
    if radius >= 1:
        return 0
    angle = math.atan2(dy, dx)
    # Each ray is a soft wedge, and every other one is shorter and fainter
    phase = (angle / (2 * math.pi) * RAYS) % 1
    index = int((angle / (2 * math.pi) + 1) * RAYS) % 2
    wedge = max(0.0, 1 - abs(phase - 0.5) / 0.34)
    wedge = wedge * wedge * (3 - 2 * wedge)
    reach = 1.0 if index == 0 else 0.72
    fade = max(0.0, 1 - radius / reach) ** 1.15
    inner = min(1.0, radius / 0.08)
    return int(round(255 * wedge * fade * inner * (1.0 if index == 0 else 0.75)))


def chunk(tag, data):
    body = tag + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


rows = []
for y in range(SIZE):
    row = bytearray(b"\0")
    for x in range(SIZE):
        row += bytes((255, 255, 255, alpha(x, y)))
    rows.append(bytes(row))
with open(OUT, "wb") as out:
    out.write(b"\x89PNG\r\n\x1a\n")
    out.write(chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)))
    out.write(chunk(b"IDAT", zlib.compress(b"".join(rows), 9)))
    out.write(chunk(b"IEND", b""))
print("wrote", os.path.abspath(OUT))
