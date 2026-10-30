# UI study (2026-10-29)

You asked for new UIs: the current parchment, wood and serif look reads as a fantasy RPG ("like RuneScape"), and you said to change it, studying popular games and combining the best of several without copying any. Claude played five on your PC (only opening menus; nothing bought, no chat) and saved screenshots in `References/UI/` (private references, not for the game).

## What each does well
| Game | Screens | What to take |
|---|---|---|
| **Grow a Garden** (top farming sim) | HUD, What's New, shop | **Big color-coded buttons**: a row of teleports at the top (SEEDS blue, GARDEN brown, SELL red) and a stack on the left (Shop green, Trade blue, Pass gold, Guide brown), each with an icon and one word, chunky and blocky to match the world. **Bold rounded font with a dark outline** everywhere. Currencies are just icon + outlined number, no box. The world **blurs** behind an open window. Red **"!" badges** on buttons that need you. |
| **Pet Simulator 99** | starter pets, HUD, inventory, achievements | The cleanest of all. **White panels with a thick dark outline**, rounded corners and a faint pattern. A **title sticker** (icon + title) breaking out of the panel's top-left corner, and a **red rounded X** on the top-right. **Selection feedback**: green check badges on chosen items, the rest dim, the OK button turns from grey to green when you can go on. **Empty slots** drawn as dashed outlines. **Achievements** as two columns of cards: picture, goal, slim progress bar "0/200", a row of reward tiles with counts. A bottom **dock of big icon buttons** with the label shown only on the selected one. |
| **Bee Swarm Simulator** | HUD, quests | The quest list is a **side panel that doesn't cover the game**; every task is a bar that **fills from red to green** with "x / y". Dense but readable for long grinds. |
| **Islands** (Roblox Skyblock) | HUD, inventory | Flat and tidy. **Square colored buttons with icon + label** down the left. Inventory: a light panel, **category tabs as small icon squares**, a **search box**, a dense grid of item icons with counts, the hotbar docked under it. Coins top-right. |
| **The Forge** (mining sim on the charts) | daily rewards, HUD | Dark and moody (not our tone), but two good ideas: **locked tiles** (dark tile, big white padlock) and **key hints** in the corner (Q Dash, Shift Sprint). A **Level + money** readout that's small and out of the way. |

## Shared lessons
- Big, simple, readable: one or two words per button, icons doing most of the talking. Everything works on a phone first.
- Strong outlines on text and panels, so they read over any background.
- Color means something: green buy/confirm/done, red close/sell/danger, gold premium/claim, blue neutral, grey not yet.
- Windows focus you (blur behind, one window at a time); trackers (quests) stay on the side.
- Feedback for everything: badges, checks, bars that fill, buttons that light up when they work.

## Proposed Skyblox style (combining them)
- **Panels:** white with a 3 px dark navy outline, 12 px corners, a faint block pattern; a **colored header band** per window (Bag blue, Shop green, Challenges gold, Inbox purple, Skills teal), with a **title sticker** breaking out of the top-left and a **red rounded X** on the top-right.
- **Font:** a bold rounded font (FredokaOne) with dark outlines; numbers big.
- **Colors:** sky blue and gold from the SKYBLOX logo, grass green; meaning colors as above.
- **Buttons:** chunky with a darker bottom lip (pressed look), icon + one word.
- **HUD:** a left dock of square icon buttons (Bag, Island, Skills, Challenges, Inbox) with red badges; currencies as icon + outlined number; a compact level badge + XP bar; the quest tracker as a side card; the world blurs behind open windows.
- **Lists and grids:** item tiles as white rounded squares with counts bottom-right; category tabs + search in the Bag; empty slots dashed; locked things dark with a padlock; challenges as achievement cards with a slim bar and reward tiles.
- Out: parchment, wood planks, serif titles.
