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
| Blender | 5.2.2 LTS | Portable install in `%LOCALAPPDATA%\Programs\blender-5.2.2-windows-x64` |

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
