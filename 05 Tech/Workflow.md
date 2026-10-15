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

Later option: a Roblox Open Cloud API key could let Claude upload some assets directly.
