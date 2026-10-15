# Obsidian Setup

## 1. Install
1. Download Obsidian (free) from https://obsidian.md and install it.
2. Install **GitHub Desktop** (https://desktop.github.com) — the easiest way to get these notes onto your PC and keep them in sync.

## 2. Get the vault onto your PC
1. In GitHub Desktop: **File → Clone repository** → pick `vantagescrypt0/Roblox`.
2. After cloning, switch to the branch `claude/roblox-simulator-brainstorm-zy7eg7` (Current Branch dropdown at the top).

## 3. Open it in Obsidian
1. Open Obsidian → **Open folder as vault** → choose the cloned `Roblox` folder.
2. Open [[Home]] — that's the dashboard.

## 4. Recommended settings
- **Settings → Files and links → Default location for new notes:** `00 Inbox`
- **Settings → Core plugins → Templates:** turn on, then set **Template folder location** to `99 Templates`.
- **Settings → Files and links → Excluded files:** later, when game code exists, add `game/` so code files don't clutter search.

## 5. Staying in sync with Claude
Claude writes notes into this repo from cloud sessions; you edit them in Obsidian.
- **Before you start editing:** GitHub Desktop → **Fetch / Pull**.
- **After you edit:** GitHub Desktop → write a short summary → **Commit** → **Push**.
- Optional: the **Git** community plugin in Obsidian can do pull/commit/push from inside Obsidian. [Unverified] Its mobile support has been reported as unreliable, so use it on desktop.

## Rules of the vault
- Dump raw ideas in `00 Inbox`, sort them later.
- Every decision goes in [[Decision Log]].
- Every unanswered question goes in [[Open Questions]].
