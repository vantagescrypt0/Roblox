# Warzone (Draft)
Inspired by the Skybounds Warzone — see [[Skybounds (Minecraft)]].

## Decided
- **Death drop (from Skybounds):** when you die, a **loot head** (your avatar's head) drops where you fell. Open it (right-click on PC) to take the loot. The loot stays in the head until someone takes it. See [[Decision Log]].

- **PvP + PvE:** in the Warzone you can fight other players, fight mobs, farm, and find chests.
- **Unlock:** you need **player level 10** to enter (like Skybounds). Player level resets each season, see [[Skills & Levels]], reached through [[Tutorial & Quests]]. This also keeps brand-new players out of PvP.
- **Level gates apply:** mobs need a Combat level and crops need a Farming level. See [[Skills & Levels]].

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
