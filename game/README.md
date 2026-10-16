# Game code (Rojo project)

Luau code for the game. Rojo syncs it into Roblox Studio.

## One-time setup (already done on the main PC)
- Rokit installs the tools pinned in `rokit.toml` (Rojo, StyLua, Selene): run `rokit install` in this folder.
- The Rojo Studio plugin lives in `%LOCALAPPDATA%\Roblox\Plugins\Rojo.rbxm`.
- VS Code extensions: Luau LSP, Rojo, StyLua, Selene.

## Every session
1. Open this `game` folder in VS Code.
2. Start syncing: Command Palette → **Rojo: Open menu** → start `default.project.json` (or run `rojo serve` in a terminal here).
3. In Roblox Studio, open the place → **Plugins** tab → **Rojo** → **Connect**.
4. Code changes in VS Code now show up in Studio live.

To build a place file from scratch: `rojo build -o game.rbxlx`

## Checks
- Format: `stylua src`
- Lint: `selene src`
- Types: `rojo sourcemap -o sourcemap.json` then `luau-lsp analyze --definitions=<globalTypes.d.luau> --sourcemap=sourcemap.json --ignore="src/server/Packages/**" src`

Vendored: `src/server/Packages/ProfileStore.luau` (MadStudioRoblox/ProfileStore @ 45c9847, Apache-2.0, license in `licenses/`).

## Saving data in Studio
ProfileStore only saves when the place is published and **Game Settings → Security → Enable Studio Access to API Services** is on. Otherwise it runs in mock mode (works, but nothing is saved).

## Island model
The server looks for a Model at `ServerStorage.Assets.StarterIsland` (with a part named `GrassTop`). If it's missing, it builds a simple greybox island instead.

## Layout
| Folder | Ends up in Studio as |
|---|---|
| `src/shared` | ReplicatedStorage.Shared |
| `src/server` | ServerScriptService.Server |
| `src/client` | StarterPlayer.StarterPlayerScripts.Client |
