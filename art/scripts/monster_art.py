"""Writes game/src/shared/MonsterArt.luau from art/generated/monster_assets.json: the Slaying
World's generated meshes (monsters, drops, the spawner cage, props), made through Studio's MCP
by generate_mesh with the prompts in art/generated/monster_prompts.json. Run after generating.

    python art/scripts/monster_art.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
assets = json.load(open(os.path.join(ROOT, "art", "generated", "monster_assets.json"), encoding="utf-8"))
HEADER = '''--!strict
-- The Slaying World's generated meshes: the monsters, what they drop, the spawner cage and the big
-- props, plus the Boost Crystal and the Auction House's Auctioneer, as generate_mesh made them (art/generated/). Written by
-- art/scripts/monster_art.py; don't edit by hand. Util/MonsterModels makes them at server start.

export type Art = { Mesh: string, Texture: string, Size: Vector3, Turn: CFrame }

local MonsterArt: { [string]: Art } = {
'''
FOOTER = '''}

return MonsterArt
'''


def num(x):
    return f"{x:.4f}".rstrip("0").rstrip(".")


def turn(r):
    identity = abs(r[0] - 1) < 1e-4 and abs(r[4] - 1) < 1e-4 and abs(r[8] - 1) < 1e-4
    if identity:
        return "CFrame.identity"
    return "CFrame.new(0, 0, 0, " + ", ".join(num(v) for v in r) + ")"


lines = []
for name in sorted(assets):
    a = assets[name]
    size = ", ".join(num(v) for v in a["size"])
    lines.append(
        f'\t{name} = {{ Mesh = "{a["mesh"]}", Texture = "{a["tex"]}", Size = Vector3.new({size}), Turn = {turn(a["rot"])} }},\n'
    )
out = os.path.join(ROOT, "game", "src", "shared", "MonsterArt.luau")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    f.write(HEADER + "".join(lines) + FOOTER)
print("wrote", out, len(assets), "models")
