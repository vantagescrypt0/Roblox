# Workflow

| Who | Does |
|---|---|
| Claude | Writes all code, systems design, economy, notes; builds models in Blender by script (`art/scripts/`) |
| You | Syncs code into Studio with Rojo, imports models (`art/export/*.fbx`), playtests, reports bugs/screenshots, publishes, account steps (age/ID checks, publishing fee), ad spend |

## Model pipeline
1. Claude writes/edits a script in `art/scripts/` and runs Blender in the background.
2. Out come `art/blend/<Name>.blend`, `art/export/<Name>.fbx`, and a preview in `art/renders/`.
3. You import the FBX in Studio (Import 3D, Scale Unit = Stud). See `art/README.md`.

## Code pipeline
1. Claude writes Luau in `game/src/`.
2. You run Rojo (VS Code → Rojo menu) and connect from Studio's Rojo plugin; changes sync live.
3. You playtest and report back.

## Streaming (on in every place since 2026-10-27)
A player's screen only has the parts near them, so client code can never assume a part exists:
- Look things up when needed (`FindFirstChild` each time, or poll / `ChildAdded`), and drop them when they leave (their `Parent` becomes nil). Folders and models without `ModelStreamingMode` set are there from the start; their parts come and go.
- Anything the client animates or reads as a whole (shopkeepers, `Decor.Spin` models) is `ModelStreamingMode.Atomic`, so it arrives complete. Keep its resting position in an attribute (`Neck`, `SpinBase`) instead of reading where its parts are now.
- Before the server puts a character somewhere new, call `player:RequestStreamAroundAsync(position)` (see `Spawning` and `IslandService`).
- Never send a workspace part to a client in a remote event: if it hasn't streamed in there, it arrives as nil. Send names or grid coordinates.
- Studio's Rojo live sync can't change `StreamingEnabled` (scripts can't set it); it comes from the `.project.json` files, so test from a fresh `rojo build`.

Later option: a Roblox Open Cloud API key could let Claude upload some assets directly.
