# Warzone (Draft)
Inspired by the Skybounds Warzone — see [[Skybounds (Minecraft)]].

> **2026-11-02, your verdict on the prototype: "terrible and low effort".** Everything under "Prototype" below is Claude's guess and is being replaced:
> - **It's PvP, not PvE:** the monsters come out. This replaces "PvP + PvE" from 2026-10-14.
> - **You actually loot chests:** not a click that drops random loot in a bag.
> - **The exit was never agreed:** Claude invented the green pads without asking. Ask how it should work.
> - **The map:** connected floating islands like Team Vaeron's Skybounds Warzones, see [[Vaeron Warzones]].
>
> **Your rules (2026-11-02):**
> - **Competitive:** "The warzone will be competitive thats why starter players are not there."
> - **Combat tag:** shows for **20 seconds**; while tagged you can't leave.
> - **Leaving:** a button that only exists in the Warzone. Hold it for **5-10 seconds**; it makes a **noise** so people know you're teleporting out.
> - **Death:** **everything drops**. Your **body lies on the ground** and players can loot it. It **despawns with its loot after 15 minutes**.
> - **Looting:** a **traditional Minecraft chest screen**, for bodies and for all chests in the game.
> - **Chests:** shared slots; once emptied, the chest **vanishes and a new one spawns elsewhere**.
> - **First map:** **Robot / sci-fi**.
> - **Carrying:** Minecraft's **36 slots with stacks**, in the whole game. Store the rest in **real chests you place on your island**; bring only what fits.
> - **Shield:** **hold right-click to block** from the front, like Minecraft.
> - **Arrival:** you land in the **citadel, a safe zone** with no PvP. Leave it to fight.
> - **Regular chests are all the same**, spread out at random with no hotspots. **Skydrops and Legendary Skydrops** are also random but better, and land "not that far but not right next to spawn".
>
> **Your rules, second batch (2026-11-02):**
> - **Armour:** four pieces, like Minecraft (helmet, chest, legs, boots), worn from the Bag's Equipment panel. Built 2026-11-03; on the body they're still plain plates, and they do nothing in a fight yet.
> - **Quitting:** you vanish and are safe, and have **5 minutes to rejoin**. Trying to rejoin automatically teleports you back to the exact server and spot. Miss the 5 minutes and your body drops there with everything. Quit while combat tagged and it drops at once.
> - **Falling off:** you come back where you jumped from and take a little **ticking poison**.
> - **After you die:** back to Town.
> - **Health bar and hunger bar:** food is a Minecraft-style hunger bar, in the Warzone only. It drains as you run and fight, eating fills it, health only regrows while you're well fed, and at empty hunger you slowly lose health. You stock up on your island and bring food in.
> - **Shield:** one kind for now, crafted at the Anvil from planks and iron. Hold right-click to block every hit from the front; you walk slowly while blocking. Tiers can come later. It's a generated model on the left arm, raised in front of the chest while blocking. **Nothing knocks it down: you removed Claude's axe knockdown on 2026-11-04.**
>
> **2026-11-02, built:** the real map replaced the greybox (citadel, 26 islands, North/East/South/West landmarks, see [[Warzone Rebuild Plan]]). The monsters, raid bag, green pads and click-for-loot chests are gone. The safe zone, combat tag and hold-to-leave button work. The "Decided" and "Prototype" sections below are the old design, kept for reference.
>
> **2026-11-03, built:** chests. 24 are out at a time, on open ground on the islands, never in the citadel: all the same, shared slots, the traditional chest screen, and an emptied one vanishes and a new one appears elsewhere 20 seconds later. What they hold is Claude's pick, in `shared/WarzoneLoot.luau`.
>
> **Your rules, third batch (2026-11-03):**
> - **Pet:** an equipped pet drops with everything else. Coins aren't items and stay with you.
> - **Quitting in the citadel is safe:** untagged, you keep everything, with no body and no timer. The 5 minutes only apply out in the PvP zone.
> - **Going back for your body:** jump in the pit within its 15 minutes and you land on your body's server, if it has room; otherwise any server.
> - **An emptied body vanishes at once,** like a chest.
>
> **2026-11-03, built:** lootable bodies (`Services/BodyService`). Your own avatar falls over and lies there, still wearing whatever nobody's taken, with the shield flat beside it and your name above it. Right-click: the chest screen, worn gear first, growing to 5 rows if it has to. **Claude's picks, say if you want any changed:** anyone can also put things into a body; with nothing on you, you still fall, but there's nothing to open and it's gone in 6 seconds; the pet is in the slots but not shown beside the body; 20 extra seconds after the 5 minutes for someone already on their way back; if the server closes first (nobody left on it) no body drops and you keep everything, since nobody could have looted it; resetting your character counts as dying.
>
> **Your rules, fourth batch (2026-11-04):**
> - **Your own body has no marker.**
> - **A Skydrop is a regular chest with sparkles.** A **Legendary Skydrop** is still a regular chest, with purple sparkles, and a **health bar: people have to mine it to open it.** You hold mine, it cracks and "breaks", but it stays there and the health goes down. "Make it tedious so there's competition."
> - **The shield's axe knockdown is removed.**
> - **Warzone challenges** are PvP things and looting things.
> - **Server sizes:** Warzone 55, Town 40, each Grinding World 30, Island 25. Set on Roblox for the other five places; the Warzone's is set when it's published.
>
> **2026-11-04, built:** Skydrops (`Services/SkydropService`, `client/SkydropController`, numbers in `shared/Skydrops`, loot in `shared/WarzoneLoot`) and 20 Warzone challenges (`shared/Boards`). **Claude's picks, say if you want any changed:**
> - **The bar:** 300 cracks, each as long as a very tough block. With one person mining that's about 30 minutes with a Wooden Pickaxe, 10 with Iron, 5 with Ruby. Everyone's cracks bring down the same bar, and it never grows back.
> - **Only a pickaxe mines it,** so you've put your sword away while you do, and you've had to bring a pickaxe you can lose. Whoever lands the last crack gets no extra: at zero it's open to anyone in reach, and the challenge counts for them only.
> - **What they hold:** a Skydrop has 8 to 12 stacks with its rare things about ten times likelier than a chest's, a Legendary 14 to 18 stacks with about one good node in each. Ruby and Starstone only ever come as nodes.
> - **Where and when:** inner islands only, 8 seconds in the air, and at most 3 regular ones lying about, the oldest going when another falls. Only one Legendary at a time. All servers share one list of Legendary times, 4 to 8 hours apart, as a server rarely lives that long.
> - **What you see:** a line on everyone's screen when one falls (the Legendary's doesn't say where), and the regular one's marker sits on your screen, moving to the edge when it's off screen. The Legendary's bar only shows within 70 studs, so that it isn't a marker. **Tokens that call one down aren't built:** they need loot crates and Robux, which come later.

## Decided
- **Death drop (from Skybounds):** when you die, a **loot head** (your avatar's head) drops where you fell. Open it (right-click on PC) to take the loot. The loot stays in the head until someone takes it. See [[Decision Log]].

- **PvP + PvE:** in the Warzone you can fight other players, fight mobs, farm, and find chests.
- **Unlock:** you need **player level 10** to enter (like Skybounds). Player level resets each season, see [[Skills & Levels]], reached through [[Tutorial & Quests]]. This also keeps brand-new players out of PvP.
- **Level gates apply:** mobs need a Combat level and crops need a Farming level. See [[Skills & Levels]].

> **2026-11-04: the entrance moved.** The void pit is now in the middle of Town's Market Square, where the fountain was, with a stone frame like an End portal and effects rising out of it. See [[Town & Worlds]].
>
> **2026-11-02: the entrance is open.** The Warzone is its own place now. You jump into the black void pit in Town's Portal Plaza (player level 10, or it puts you back at the rim). Extract or die and you go back to Town. The arena is still the greybox prototype. Chests can hold Loot Crates and the late game's nodes, saplings and seeds ([[Late-game Rule]]); resource nodes placed in the Warzone itself wait until you ask for them.
>
> **2026-10-15:** The island portal now goes to **Town**. The Warzone will be reached from Town once you're ready to add it; its code is built but switched off (`WarzoneService`, `MobService` aren't started in `Main.server.luau`).

## Prototype (built + playtested 2026-10-15)
Greybox arena, one shared map. These are **prototype defaults Claude picked**; change any of them. See [[Open Questions]].
- **Getting in:** purple portal on your island → level 10 required → you appear at the arena edge.
- **Raid bag:** everything you loot in the Warzone goes into a raid bag shown at the top of the screen. It only becomes yours when you **extract** (hold E for 3s on a green pad; there are 4 pads at the corners). Your island gear (swords) is never at risk.
- **Death:** your whole raid bag drops as a **loot head** (a head with a face and "<name>'s loot"). **Anyone** in the Warzone can open it (hold E, works with tap on mobile); the first opener takes everything. It disappears after **2 minutes**. You respawn on your island.
- **Leaving the game mid-raid** drops your bag as a loot head too, so logging out can't save it.
- **Zones:** outer ring = Slimes (Combat 1) + common chests; red center = Brutes (Combat 5) + rare chests (more Crystal and Glowberry Seeds). The center really is dangerous: Brutes killed the test avatar while it was opening a chest.
- **PvP:** sword hits only damage other players when both are in the Warzone.
- **Loot:** Scrap and Crystal (for the Crystal Sword), Glowberry Seeds (a crop you can only get here, sells for the most). Chests refill after 60s; mobs respawn after 20s.

## Warzone activities
| Activity | Notes |
|---|---|
| Fight players | Kill → their loot head drops |
| Fight mobs (PvE) | Gated by Combat level |
| Farm | Gated by Farming level; Warzone-only crops/seeds? |
| Find chests | Spawn points, respawn timer, rarity tiers — TBD |

## Skydrops (your idea, 2026-10-29; built 2026-11-04 apart from tokens, see the top of this note)
- On top of the regular chests that spawn round the Warzone, **Skydrops** fall from the sky: chests with better loot (ore nodes among it, see [[Late-game Proposal]]).
- **Regular Skydrops** fall every 10 minutes and everyone gets a **marker** showing where. **Legendary Skydrops** fall at a random time every 4–8 hours, with **no marker**: you have to find it.
- A **Skydrop token** calls one down. **Your call 2026-11-02:** tokens come from loot crates, from Robux **with a limit on how many you can buy a day**, and from other ways still to come up with. A Skydrop is up for grabs, so anyone can take it: calling one is a flex and a chance if you're strategic, not a guaranteed prize.
- [Inference] Before Robux tokens ship: Roblox treats paid random items as loot boxes (show the odds; some countries restrict them). Check the rules then, with our [[Monetization Principles]].

## PvP fairness — [Inference], to discuss
High-level players can kill new players and take their loot. That's part of the fun, but it can drive young players away. Options:
- **Zones by level:** an outer ring that's safer and low-tier, and a center that's dangerous and high-tier.
- **New-player protection** for your first few runs.
- **Insurance:** keep one item slot that doesn't drop.

## Death drop: details to settle
- Does the head hold **everything** you carried, or only some of it?
- **Who can open it:** anyone, the killer first for a few seconds, or squadmates first?
- **Despawn:** how long does the head last before it disappears? (Prevents clutter and lag.)
- **Mobile:** tap or hold to open, because phones have no right-click. See [[Target Audience]].
- **Rating:** [Unverified] A detached avatar head might count as violent imagery for the Kids/Select age bands. A stylized version (a sack or crate with your avatar's face on it) could be a fallback. Check against [[Roblox Policies]].

## Open design questions
1. **Best loot:** materials, blueprints, gear, cosmetics, pets?
2. **Access:** always open, or timed events (e.g., opens every 30 minutes)?
3. **PvP fairness:** zones by level, new-player protection, insurance slot?

## Constraints
- [Unverified] Combat may raise the maturity rating — check against [[Roblox Policies]].
- Tone (stylized vs realistic) affects rating and audience.
- Must stay opt-in: your island is always safe.
