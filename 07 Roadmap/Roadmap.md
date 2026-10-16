# Roadmap (Draft)
No dates — quality over speed.

1. **Pre-production:** concept, pillars, core loop, open questions answered. (Mostly done; some questions still open.)
2. **Prototype** ← *we are here*: greybox island + greybox Warzone; prove the loop is fun.
   - [x] Toolchain set up (Rojo, Blender pipeline) — 2026-10-15
   - [x] Greybox starter island model
   - [x] Each player gets their own island plot and spawns on it; fall off → put back (playtested 2026-10-15)
   - [x] Player data saving with ProfileStore (needs a published place + Studio API access to actually save)
   - [x] Blender island imported, colored, saved as `game/assets/StarterIsland.rbxm` (synced by Rojo into `ServerStorage.Assets`) — playtested
   - [ ] Publish the place (private) + enable Studio API access so data actually saves
   - [ ] Gather → craft → farm basics
   - [ ] Greybox Warzone + loot heads
3. **Vertical slice:** one polished island tier + one Warzone map, real UI, saving.
4. **Soft launch:** small audience, measure retention, fix.
5. **Launch + ads.**
6. **Live ops:** steady update rhythm (see [[Anti-Burnout Ideas]]).
