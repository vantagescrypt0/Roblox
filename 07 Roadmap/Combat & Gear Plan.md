# Combat & Gear Plan (2026-11-03)

References: [[02 Research/References/Gear/README]]. Inspired by GPO; our own designs.

## Your calls
- **PvP copies Minecraft 1.9+:** timed swings, not click spam.
- **First person is there for anyone who wants it,** so it feels like Minecraft, while the wielding is different and the swords look cool.
- **The Ruby Sword is the crescent,** with a texture and a glow. Late-game swords get the most detail.
- **Armour protects:** skill armour = leather. Kit armour = diamond. Claude sets the rest (below).

## Combat: real Minecraft rules
The game's health is 100 where Minecraft's is 20, so **every Minecraft damage number is x5**. One block is 3 studs.

| Rule | Minecraft | Here |
|---|---|---|
| Reach | 3 blocks | 9 studs |
| Sword swing | 0.625 s to charge | same |
| Axe swing | about 1 s to charge | same |
| Early hit | damage x (0.2 + 0.8 x charge²) | same |
| Critical | falling, charged over 90%, not sprinting: x1.5 | same |
| Sprint hit | charged over 90%: extra knockback, ends your sprint | same |
| Sweep | sword, full charge, on the ground, not sprinting: nearby enemies take 1 heart's worth | 5 damage |
| Knockback | 0.4 blocks a tick, away and up | 24 studs/s |
| After a hit | half a second where only a harder hit counts, for the difference | same |
| Shield | stops everything from the front; nothing knocks it down (you removed the axe knockdown, 2026-11-04) | already in |
| Switching items | resets the charge | same |

You have to aim: a hit goes to who's under your crosshair or mouse. The server checks the reach and that they're in front of you.

**Damage (at full charge):** sword 20 / 24 / 27 / 31 / 34 / 38 / 41 from Wooden to Starsteel. Axe 35 up to 50 (slower). Pickaxe 10 up to 31. Shovel 12 up to 33. Hoe 5. Crystal counts as Amethyst.

## Armour numbers
Minecraft's formula: damage x (1 - min(20, max(armour / 5, armour - damage / (2 + toughness / 4))) / 25), with damage in Minecraft units.

| Armour | Helmet / Chest / Legs / Boots | Total | Toughness | Against |
|---|---|---|---|---|
| **Skill armour, every tier** (your call) | 1 / 3 / 2 / 1 | 7 | 0 | leather |
| Iron | 2 / 6 / 5 / 2 | 15 | 0 | iron |
| Amethyst | 3 / 6 / 5 / 2 | 16 | 0 | |
| Sapphire | 3 / 7 / 6 / 2 | 18 | 4 | |
| **Kit armour** (your call) | 3 / 8 / 6 / 3 | 20 | 8 | diamond |

**Armour stops at diamond (your call, 2026-11-09):** "things only come in armor up to diamond... There's only late game tools etc just not armour." The Ruby and Starsteel armour that used to be on this list is gone; nothing had been made from it. Claude's picks for the rows between leather and diamond. **Iron, Amethyst and Sapphire armour don't exist as items yet:** they come with their art, and where you get them is your call.

## The sword system
- Each sword has its own generated mesh. `shared/SwordArt.luau` lists them by asset id; the server loads them when it starts.
- **The hold in third person (your calls, 2026-11-03 and 2026-11-04):** over the shoulder, and no sword may touch your body or armour. Each sword has two holds, and moves between them when a helmet or chest armour goes on or off, because the shoulder pieces stand as high as your head with no way past them low down. Poses are in `shared/SwordArt.luau`, in arm lengths from the shoulder.
  - **The Ruby, bare shoulders:** as in your photo `yours_ruby_hold_LOVED.webp`: the guard on your shoulder, the pommel out in front, the blade going back and curving up and over with your head inside it. Turned about 25 degrees from your photo so its face shows from behind: straight on, from your usual camera, it's a thin line.
  - **The Ruby, in armour (Claude's call, which you left to Claude on 2026-11-04, as the photo's hold can't clear the shoulder pieces):** carried like a scythe: your hand comes up in front of the shoulder and the blade arcs over it and over your head, with the tip behind you on your left.
  - **Straight swords, bare shoulders:** they rise past your head leaning back, on edge so the guard stays off your head, nearly as before. **In armour:** your hand comes up in front of the shoulder piece and the blade leans back over it.
- **The swing in third person:** coded poses: up, down in front of you, across your body, back up and home, in 0.5 seconds. The steps blend about your hand, so it moves in a line and every sword moves alike. (Blending about the middle of the sword is what sent hands and pommels into chests.)
- **The check (`art/scripts/sword_fit`):** every sword against every armour set and bare shoulders, resting, sprinting, between the two, and every step of a swing starting from either. The old poses put every sword through the right shoulder piece of all three sets, even at rest; the new ones have no overlaps, with the head swept through everywhere Roblox's idle animation turns it (it looks round by up to 56 degrees). `record.py` and `real_check.py` then confirmed it in the real game: about 2,700 recorded frames, 5 swords, 3 sets and bare, none touching armour, head, chest or left arm. **What still touches is your own holding arm:** the pommel brushes the forearm next to the hand on most straight swords, the Ruby's in its swings only, and on bare shoulders some guards rest on the forearm, which is how a guard on your shoulder sits. Run `check.py` after changing a pose or adding a sword or armour.
- **Tools, crops and blocks** use Minecraft's hold: the arm hangs 18 degrees forward, swings half as far as a free arm as you walk, and lifts from the shoulder to chop down in 0.3 seconds. That was Claude's reading, and you only ruled on swords: say if tools should change too.
- **The swords (remade 2026-11-03 from `ref_sword_lineup_elements.webp`):** one family of slim longswords, each with one theme. Wooden 4.6 with a living vine, Stone 4.6 with blue runes, Iron 5.2 with a gold guard, Amethyst 6 with a purple ribbon, Sapphire 6.2 with water inside the blade, Crystal 6.4 with ice shards and a frosted guard, Ruby 6.8 the crescent (your pick), Starsteel 7 with stars, a sunset blade and a gold ribbon. The older tries are in the references' README.
- **The glow:** the texture, a soft neon shell, a light and embers along the blade. Stronger on later tiers: Wooden to Iron have none.

## First person
`V` switches, or scroll all the way in. Your call: first person is where wielding copies Minecraft. Minecraft's own numbers (`yours_minecraft_first_person.png`): what you hold sits low on the right with its tip leaning toward you, your shield low on the left with its back to you, both mostly off screen. No arm shows unless your hand is empty. After a swing the item dips and rises again as it charges. Crescents are smaller here and turned so their bulk is away from the camera. Crosshair and charge bar stay.

## Sprinting
Double-tap `W` or hold `Ctrl`, like Minecraft. Walking stays 16; sprinting is 21. It works everywhere; in the Warzone it needs some hunger left and burns more. A sword leans back further on your shoulder while you run.

## Health, armour and hunger on screen
Your call, 2026-11-03: Minecraft's rows, not bars. Ten hearts on the left over the hotbar, armour above them while you wear any, ten drumsticks on the right in the Warzone, half icons counting, blinking when hit, shaking near death, green when poisoned. The layout and behaviour copy Minecraft; **the pictures are our own** (`art/scripts/vitals_icons.py`), because Mojang's own art can't go in a published game. There never was a shield bar in the game: the second bar was hunger, so that's what was replaced.

## Armour art
**Your call, 2026-11-03: all armour gets the look in `ref_armour_blocky_themes.webp`:** blocky coats that fit the body, a dark coat with one bold colour, thick outlines, a big theme piece on each shoulder. Generated meshes can't fit a block body (a box-shaped set came out like crates), so these are modelled in Blender: `art/scripts/armour.py`.

- **All three sets are built:** Mining with crystals bursting from the shoulders; Woodcutting with leaves and thorny vines, a vine climbing the coat and a great leaf on the back; Farming with wheat sheaves, a wide hat, sunflowers and a straw fringe. The themes for the last two are Claude's.
- **Tiers:** one mesh, and a colour sheet per tier: bronze, silver, gold, emerald, diamond, amethyst, ruby, starlight and two more. From tier 3 they sparkle, from 5 they give a little light, from 7 embers rise from the shoulders and boots.
- **The pauldrons ride on the chest,** not the arm, so lifting a sword can't swing them across your face. The sleeves move with the arm.
- **What's hidden:** whatever the armour covers, so a body can't poke through: the body parts, hats and hair under a helmet, layered clothes and shoes. Your hands and face still show. R6 legs are one piece, so no body part is hidden there.
