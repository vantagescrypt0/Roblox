"""Put the graphify knowledge graph into this Obsidian vault as `08 Knowledge Graph/`.

graphify's own Obsidian export is meant to be opened as a separate vault. This script
adapts it to live inside ours:
  - graph notes that share a name with a real note (Warzone, Roadmap, ...) are dropped,
    so their [[links]] lead to the real note instead of a stub copy
  - graph.canvas paths are made relative to the vault root
  - the per-cluster colour groups are merged into the vault's graph view settings
    (.obsidian/graph.json) and the nested .obsidian folder is removed

Run from anywhere after building or updating the graph (graphify-out/graph.json):
    python tools/graph_to_vault.py
"""

import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FOLDER = "08 Knowledge Graph"
OUT = ROOT / FOLDER
# Folders that aren't part of the vault's own notes
SKIP = {FOLDER, "graphify-out", "game", ".obsidian", ".trash", ".git"}


def real_notes():
    """Note name -> vault-relative path, for every hand-written note in the vault."""
    notes = {}
    for path in ROOT.rglob("*.md"):
        rel = path.relative_to(ROOT)
        if rel.parts[0] not in SKIP:
            notes[path.name] = rel.as_posix()
    return notes


def merge_color_groups():
    exported = OUT / ".obsidian" / "graph.json"
    if not exported.exists():
        return 0
    groups = json.loads(exported.read_text(encoding="utf-8")).get("colorGroups", [])
    settings_path = ROOT / ".obsidian" / "graph.json"
    settings = json.loads(settings_path.read_text(encoding="utf-8")) if settings_path.exists() else {}
    # Keep the user's own groups, replace the graph's cluster groups
    kept = [g for g in settings.get("colorGroups", []) if "#community/" not in g.get("query", "")]
    settings["colorGroups"] = kept + groups
    settings_path.write_text(json.dumps(settings, indent=2), encoding="utf-8")
    shutil.rmtree(OUT / ".obsidian")
    return len(groups)


def main():
    shutil.rmtree(OUT, ignore_errors=True)
    subprocess.run([sys.executable, "-m", "graphify", "export", "obsidian", "--dir", FOLDER], cwd=ROOT, check=True)

    notes = real_notes()
    removed = 0
    for name in notes:
        stub = OUT / name
        if stub.exists():
            stub.unlink()
            removed += 1

    canvas_path = OUT / "graph.canvas"
    canvas = json.loads(canvas_path.read_text(encoding="utf-8"))
    for node in canvas.get("nodes", []):
        file = node.get("file")
        if file:
            node["file"] = notes.get(Path(file).name, f"{FOLDER}/{file}")
    canvas_path.write_text(json.dumps(canvas, indent=2, ensure_ascii=False), encoding="utf-8")

    colors = merge_color_groups()
    print(f"{FOLDER}: removed {removed} duplicate notes (links now go to the real notes), "
          f"fixed canvas paths, merged {colors} cluster colours into the graph view")


if __name__ == "__main__":
    main()
