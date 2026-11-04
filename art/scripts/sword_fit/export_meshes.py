"""Exports the sword and shield meshes' vertices and faces from Studio, in pages, to swords.json."""
import json
import os
import sys
import importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))

# studio_mcp.py runs main() on import, so take only what's above that line
source = open(os.path.join(REPO, "tools", "studio_mcp.py"), encoding="utf-8").read()
source = source[: source.rindex("main()")]
bridge = {"__name__": "bridge", "__file__": os.path.join(REPO, "tools", "studio_mcp.py")}
exec(compile(source, "studio_mcp", "exec"), bridge)
Server, pick_target = bridge["Server"], bridge["pick_target"]

LUAU = r"""
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local SwordArt = require(game.ReplicatedStorage.Shared.SwordArt)
local key, page = "@KEY@", @PAGE@
local id
if SwordArt.List[key] then
	id = SwordArt.List[key].Mesh
else
	local model = game.ReplicatedStorage:FindFirstChild("ShieldModels")
	local found = model and model:FindFirstChild(key, true)
	id = found and (found.MeshId or found.MeshContent.Uri)
end
local mesh = AssetService:CreateEditableMeshAsync(Content.fromUri(id))
local ids = {}
local parts = {}
local count = 0
local verts = {}
for _, v in mesh:GetVertices() do
	local p = mesh:GetPosition(v)
	count += 1
	ids[v] = count - 1
	table.insert(verts, string.format("%.4f,%.4f,%.4f", p.X, p.Y, p.Z))
end
local faces = {}
for _, f in mesh:GetFaces() do
	local fv = mesh:GetFaceVertices(f)
	table.insert(faces, `{ids[fv[1]]},{ids[fv[2]]},{ids[fv[3]]}`)
end
mesh:Destroy()
local text = table.concat(verts, ";") .. "|" .. table.concat(faces, ";")
local size = 90000
local pages = math.ceil(#text / size)
return `{pages}#` .. text:sub((page - 1) * size + 1, page * size)
"""


def run(server, target, code):
    res = server.call("tools/call", {"name": "execute_luau", "arguments": {"code": code, "studio_id": target, "datamodel_type": "Edit"}}, 180)
    if "error" in res:
        raise RuntimeError(res["error"])
    return "".join(c.get("text", "") for c in res["result"].get("content", []))


def main():
    names = sys.argv[1:]
    s = Server()
    s.call("initialize", {"protocolVersion": "2025-03-26", "capabilities": {}, "clientInfo": {"name": "skycore-bridge", "version": "1"}}, 30)
    s.send("notifications/initialized", notify=True)
    target = pick_target(s, None)
    path = os.path.join(HERE, "meshes.json")
    out = json.load(open(path)) if os.path.exists(path) else {}
    for name in names:
        page, pages, text = 1, 1, ""
        while page <= pages:
            raw = run(s, target, LUAU.replace("@KEY@", name).replace("@PAGE@", str(page)))
            head, _, body = raw.partition("#")
            pages = int(head)
            text += body
            page += 1
        verts, _, faces = text.partition("|")
        out[name] = {
            "v": [[float(x) for x in v.split(",")] for v in verts.split(";")],
            "f": [[int(x) for x in f.split(",")] for f in faces.split(";")],
        }
        print(name, len(out[name]["v"]), len(out[name]["f"]), "pages", pages, flush=True)
        with open(path, "w") as f:
            json.dump(out, f)
    s.close()


main()
