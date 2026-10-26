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

## The places (one Rojo project each, same code)
| Project | Place file | PlaceKind | What runs |
|---|---|---|---|
| `default.project.json` | `game.rbxlx` | Island | everyone's islands |
| `town.project.json` | `town.rbxlx` | Town | the hub: shopkeepers, trading, world portals |
| `mining.project.json` | `mining.rbxlx` | Mining | the Mining World |
| `woodcutting.project.json` | `woodcutting.rbxlx` | Woodcutting | the Woodcutting World |
| `farming.project.json` | `farming.rbxlx` | Farming | the Farming World |

Build one with e.g. `rojo build mining.project.json -o mining.rbxlx` and open it in Studio to playtest that place on its own (teleports between places only work in the published game). Place ids live in `src/shared/Places.luau`; a world with id 0 isn't published yet, and its Town portal says so. When publishing, publish **all** places together (they share the Remotes list).

## Checks
- Format: `stylua src`
- Lint: `selene src`
- Types: `rojo sourcemap -o sourcemap.json` then `luau-lsp analyze --definitions="%LOCALAPPDATA%\luau-lsp\globalTypes.d.luau" --sourcemap=sourcemap.json --ignore="src/server/Packages/**" src` (definitions from https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau)

Vendored: `src/server/Packages/ProfileStore.luau` (MadStudioRoblox/ProfileStore @ 45c9847, Apache-2.0, license in `licenses/`).

## Saving data in Studio
ProfileStore only saves when the place is published and **Game Settings → Security → Enable Studio Access to API Services** is on (it is, for "Sky Farm Prototype"). Otherwise it runs in mock mode (works, but nothing is saved) — that includes the local `game.rbxlx` built by Rojo, which isn't linked to the published game.
Studio playtests save to a separate store (`PlayerData_Studio_v1`), so testing never touches real players' saves.

## Testing shortcuts (Studio only)
While playtesting, switch Studio to the **Server** view and run in the command bar:
- `game.ServerStorage.Dev:Invoke("Level", 10)` (unlock the Warzone)
- `game.ServerStorage.Dev:Invoke("Skill", "Combat", 5)`
- `game.ServerStorage.Dev:Invoke("Give", "Wood", 20)`
- `game.ServerStorage.Dev:Invoke("Use", "IronPickaxe", 100)` (wear a tool down)
- `game.ServerStorage.Dev:Invoke("Trades")` (print your saved trades)
- `game.ServerStorage.Dev:Invoke("As", "Player2")` (later commands act on Player2)

Trading needs player level 5 on both sides: `Dev:Invoke("Level", 5)` for each player.

## Testing trading (two players)
Trading only runs in the Town place. Build it with `rojo build town.project.json -o town.rbxlx` and open that file in Studio (or `rojo serve town.project.json --port 34873` and connect the Rojo plugin to that port, if another `rojo serve` already uses 34872). Start **Test → Start Test Session → Server and Clients**, then **Test → Add Clients** in the Server window once per player. Use `Dev:Invoke("As", "Player1")` / `("As", "Player2")` from the Server command bar to give each player items.

## Island model
The server looks for a Model at `ServerStorage.Assets.StarterIsland` (with a part named `GrassTop`). It comes from `assets/StarterIsland.rbxm`, which Rojo maps into `ServerStorage.Assets`. If it's missing, the server builds a simple greybox island instead.

## Layout
| Folder | Ends up in Studio as |
|---|---|
| `src/shared` | ReplicatedStorage.Shared |
| `src/server` | ServerScriptService.Server |
| `src/client` | StarterPlayer.StarterPlayerScripts.Client |
