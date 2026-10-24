# Tools & Stack

## Installed on your PC (2026-10-15)
| Tool | Version | Where / how |
|---|---|---|
| Roblox Studio | — | You already had it |
| VS Code | — | You already had it; extensions added: Luau LSP, Rojo, StyLua, Selene |
| Rokit | 1.2.0 | Toolchain manager (winget). Pins tool versions in `game/rokit.toml` |
| Rojo | 7.7.1 | Syncs `game/` code into Studio. Studio plugin: `%LOCALAPPDATA%\Roblox\Plugins\Rojo.rbxm` |
| StyLua | 2.6.0 | Formatter (`game/stylua.toml`) |
| Selene | 0.32.0 | Linter (`game/selene.toml`) |
| luau-lsp | 1.70.1 | Type checker (`luau-lsp analyze`, see `game/README.md`) |
| Blender | 5.2.2 LTS | Portable install in `%LOCALAPPDATA%\Programs\blender-5.2.2-windows-x64` |
| graphify | 0.9.95 | Knowledge graph of the code + notes (pip package `graphifyy`; `graphify` command is on PATH). See below |

## Knowledge graph (graphify)
graphify maps the whole project — every Luau file and function, the Blender scripts, and these notes — into one graph, so Claude can look up how things connect instead of re-reading every file (saves usage), and you can explore it in Obsidian.
- **In Obsidian:** `08 Knowledge Graph/` holds one note per code symbol or design concept, linked to each other and to the real notes. Open `08 Knowledge Graph/graph.canvas` for the map, or the Graph view (colours = clusters such as "Farming" or "Warzone Raids"). `graphify-out/GRAPH_REPORT.md` summarises the clusters and the most connected parts.
- **In a browser:** `graphify-out/graph.html`.
- **What's skipped:** see `.graphifyignore` (art binaries, vendored ProfileStore, generated files).
- **Refresh after code changes:** `graphify update .` (code only, free), then `python tools/graph_to_vault.py` to refresh the Obsidian notes. Note changes are re-read by Claude with `/graphify . --update`.
- **Claude Code hook-up (done 2026-10-24):** the `/graphify` skill is installed, `CLAUDE.md` tells Claude to run `graphify query` before searching files, and a hook in `.claude/settings.json` reminds it. Uninstall with `graphify claude uninstall` / `graphify uninstall`.
- Known gap: the Lua parser trips on Luau type annotations, so some code files are only partly mapped.

How to use them: `game/README.md` (code) and `art/README.md` (models). The `game/` folder is hidden from Obsidian so code doesn't clutter search.

## Not yet / maybe later
- Wally (packages) — add when we adopt a library.
- Blender MCP connector — not needed for now: Claude drives Blender with Python scripts in `art/scripts/` instead.

## Libraries — check each is still maintained before adopting
- ProfileStore (player data, session locking)
- Trove or Janitor (cleanup)
- Promise (async)
- Fusion or react-lua (UI)
- TopbarPlus (topbar buttons)

## Art
- Blender — Claude writes a script per asset; outputs `.blend`, `.fbx` (import with Scale Unit = Stud) and a preview render. See [[Workflow]].
- Moon Animator (animations)
- Figma (UI mockups)

## Research / analytics
- Roblox Discover charts, RoMonitor Stats, Rolimons
- Creator Analytics (D1/D7/D30 retention after launch)
