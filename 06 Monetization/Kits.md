# Kits

**Your call (2026-11-02):** copy the Skybounds **Looter** kit and rebrand it as the **Crate Keeper Kit**. No shards: if you buy the kit, you own it. Probably nerf it.

**On sale on Roblox since 2026-11-10 (your call: "its the same thing as a paid egg in any other roblox game, theres odds and its for an ingame item its not gambling").** The Crate Keeper Kit is game pass **2074781079** at **1,499 Robux** and a single Loot Crate is developer product **3730224176** at **299 Robux**, both with managed pricing off, the closed crate as their icon (`art/scripts/badge_icons.ps1`) and every prize's odds in their descriptions. Their ids are in `shared/Kits.luau`. Tested in a Studio playtest: the Kits window lists both with the odds above the button, the Loot Crate says "Buy for 299 Robux" (price read from Roblox), your account sees Claim on the kit (you made the pass, so Roblox counts you as owning it) and the claim gave "Crate Keeper Kit: 1 Loot Crate!" then "Next claim in 7d 0h", and a test receipt paid one crate once though sent twice. **Live only once the seven places are published;** a real purchase by another account is still to be seen.

## What Looter was in Skybounds
An Immortal Kit: claim it every 5 days to summon a random Loot Crate and open it for goodies. It stayed on your account through season resets, like a rank.

## Our version (proposal)
| | Skybounds Looter | Ours |
|---|---|---|
| Getting it | Shards: a chance to unlock, +5% per shard, otherwise one payout | One Robux purchase, yours for good |
| Claim | Every 5 days | Every **7 days** (the nerf; Claude's pick) |
| Reward | A random Loot Crate | One Loot Crate (`LootCrates.luau`, built 2026-11-02) |
| Claiming | `/kit` | A Kits window in the Menu |
| Season resets | Kept | Kept (resets are on hold anyway) |

- **Game pass, not a developer product:** a game pass is a one-time purchase that stays on the account, which is what "if they buy it they own it" means. It can't be traded (Skybounds shards could).
- **Loot Crates are built:** open one from your Bag for one random prize, with the odds shown first. They're one of the two sources of the late game ([[Late-game Rule]]); Warzone chests are the other, and they can hold crates too. The odds are Claude's picks.

## Why it costs this much (your words, 2026-11-09)
"Loot crates are very useful so they should be at 1000+": they give pets (some pets could go for 100 million+), they give expensive nodes, and a rank system and boost gems are coming soon.

**Not in the game yet:** crates hold nodes, spawners, seeds, saplings and ores (`shared/LootCrates.luau`), and since 2026-11-10 a rare [[Boost Crystals|Boost Crystal]], but **no pets**. Pets only come from skill challenges so far. Adding them means choosing which pets and their odds, and the odds table has to keep adding up to 100.

## How crates should roll (your call, 2026-11-09)
A crate gives **6 things** and has a **33% chance of giving something good** ("I kind of want a 33 change of a crate giving something good"). That replaces the 10-15% per slot you said first. Sometimes you get nothing good, sometimes something, and no good thing should be extremely rare.

Across 6 slots, 33% a crate works out to about 6.5% per slot:

| A crate gives | Chance |
|---|---|
| Nothing good | 67% |
| One good thing | 28% |
| Two or more good things | 5% |

**Built 2026-11-09, not published yet.** Simulated over 300,000 crates: 33.04% held something good and 5.24% held two or more. **Claude's picks:** good means the nine late-game prizes plus pets, and pets are every skill's tier IV and tier VII, so a tier VII is 0.19% a slot, about 1.2% a crate. Warzone chests and Skydrops now hold a quarter as many crates, because each crate is worth about 4 times as much late game, so they pay out the same as before under the [[Late-game Rule]]. Pets can be traded, and what one "goes for" is up to players.

## Armour kits (started 2026-11-09)
Kit armour protects like diamond, which is the top: armour stops there, and only tools go on into the late game. It's the same blocky, themed look as the skill sets.

**Five armour kits are built and on sale in the published game (2026-11-09; the game itself is still Private):** you asked for "four other kits" and said the special goes on the armour and the sword. Each is its own game pass, bought once, and pays out every week. You lose what you carry if you die in the Warzone, so the weekly claim is what makes it worth owning. Skybounds' kits are only the idea here: the names, themes and models are ours.

**Prices, lowered 2026-11-10 (your pick, "Card-friendly"):** every kit fits one $10 card (800 Robux) and Venomfang fits a $5 card (400). Set on Creator Hub and read back from Roblox the same day. Before that they were 800, 1,000, 1,300, 1,600 and 1,800 (your ranges, 2026-11-09: "800-1000 robux range for the weaker ones and 1000-2000 for the more op ones"). Why lower: kids mostly buy with $5 and $10 cards, so most kits couldn't be bought with one card, and ABOVE's passes are all 120 to 400. The order is still Claude's pick, from how much each one wins a fight. Managed pricing is off, so the price is the same everywhere. Change one on Creator Hub > Monetization > Passes, and the game picks it up by itself.

| Kit | Price | Pass id | Why there |
|---|---|---|---|
| **Venomfang** | 399 | 2075032826 | Poison can't finish anyone, and Antivenom only matters when poison's about |
| **Sunforged** | 499 | 2076094707 | Keeps you alive for longer but doesn't kill faster |
| **Stormcaller** | 599 | 2075536668 | The shortest cooldown, hits three people through armour, and the best supplies |
| **Emberguard** | 699 | 2075836643 | Rage is the biggest damage swing in the game, and Burning Blood adds to it |
| **Frostwarden** | 799 | 2078084502 | A 2.5 second freeze on everyone near you is free hits, and halved knockback keeps you on top of them |

You created the passes, so Roblox counts your own account as owning all five: you see Claim, not Buy, and it won't let you buy your own.

| Kit | Colour and theme | Sword special (quick right-click, holding the sword) | Wear all four | Supplies on top of the set |
|---|---|---|---|---|
| **Stormcaller** | Diamond; storm clouds and lightning | **Chain Lightning**, 30 s: 20 damage on who you aim at (40 studs), jumps to 2 more for 12 | **Static Charge:** anyone who hits you takes 5, at most every 1.5 s | 16 Crystal, 6 Sapphire, Sapphire Node |
| **Sunforged** | Gold; a sun on the chest, half suns on the shoulders | **Solar Flare**, 40 s: 15 damage and a big throw to everyone in 16 studs, heals you 25 | **Sun-Blessed:** health regrows twice as fast, and costs no hunger | 32 Gold Ingots, 8 Amethyst, Gold Node |
| **Emberguard** | Bronze; flames and a brazier on each shoulder | **Rage**, 60 s: for 10 s you hit 40% harder and run 25% faster (your Warlord example) | **Burning Blood:** you hit 25% harder at 40 health or less | 64 Coal, 32 Iron Ingots, Iron Node |
| **Frostwarden** | Silver; icicles and a snowflake | **Frost Nova**, 45 s: 10 damage, freezes everyone in 16 studs for 2.5 s, then slows them by half for 4 s | **Rooted:** hits knock you back half as far | 24 Silver Ingots, 8 Crystal, Silver Node |
| **Venomfang** | Emerald; a serpent's head on each shoulder, fangs | **Venom Coat**, 45 s: for 10 s every hit poisons for 5 s, 3 damage a second through armour | **Antivenom:** poison can't touch you, even from a fall | 12 Amethyst, 32 Scrap, Amethyst Node |

**Every armour kit also gives** the four pieces, its sword, a Shield, 16 Melons and 8 Glowberries, every week. **Nothing in an armour kit is random,** so they stay outside the paid random item rules below. Nothing in them is late-game ([[Late-game Rule]]).

**The numbers are Claude's picks** (`shared/KitPowers.luau`, `shared/Kits.luau`). Damage from a special goes through armour, because armour already takes so much off a swing; it hits monsters 3 times as hard, as they have far more health. A raised shield stops a special from the front, and it can't hurt anyone a sword couldn't. The cooldown is shared across all your kit swords. Poison never kills.

**A quick right-click fires the special; holding it raises your shield.** Right-clicking a chest, body or anything else you can use still does that first. A button beside the hotbar shows the special and its timer, and tapping it works on a touch screen.

**The swords** came from Studio's `generate_mesh`, as strong as Sapphire, so Ruby and Starsteel still beat them. The armour is modelled in Blender (`armour.py`), protects like diamond, and uses only the colour sheets up to diamond. Every sword against every set: `sword_fit/check.py` 0 hits. Measured on Stormcaller: a 40-damage hit does 35 through skill armour and 11 through this.

**The Loot Crate has an opening now (`client/CrateOpening.luau`):** a chest falls onto a floating stone with six rune stones round it, one for each thing inside. They light one by one, faster and higher each time. A rune lit gold means that slot is good, and the rays behind the chest catch it. The lid blows off and six cards fly out. Click to skip, then Open another, or Get another crate when you've none left and they're on sale. **The server has already rolled and the items are already yours:** the animation only shows that result in order, with no faked near-misses, and any gold rune is a real prize.

## Rule to design around
Pets worth 100 million+ raise the stakes on the rule below: the more a random prize is worth, the more it matters that this isn't paid gambling aimed at young players.

A kit bought with Robux that pays out random crates may count as a **paid random item**, even though the buyer pays once and the crates come later. [[Roblox Policies]] says to check `PolicyService` → `ArePaidRandomItemsRestricted` per player. [[Monetization Principles]] also says no paid gambling aimed at minors. Before it ships:
1. Re-read the current rules (linked in [[Roblox Policies]]).
2. Show the crate's odds before purchase, in the kit's description and the crate window.
3. For restricted players, don't offer it, or give them a fixed reward instead of a random one.

**Roblox's rules, re-read 2026-11-09 ([paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items), [PolicyService guidelines](https://devforum.roblox.com/t/policyservice-guidelines/773321), [UK under-18s](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183)):**
- Every possible outcome and its real numerical odds must be shown before someone pays. This covers indirect purchases too, so it covers the kit.
- A player flagged `ArePaidRandomItemsRestricted` can't use paid random items at all. A game with them that doesn't check that flag becomes unavailable to UK under-18s.
- **The Maturity & Compliance Questionnaire has to say the game has paid random items.** Add it to that list.
- If something changes the odds while it's active, the odds shown must change with it. **That will apply to boost gems if they ever improve crates.**
- `IsPaidItemTradingAllowed`: where it's false, trading should be off. Players also can't sell what they get for Robux or real money.

**As built:** every prize and its odds are on the Kits and Crates window, right above the Buy button. A player `PolicyService` restricts isn't offered crates or the kit, and one who already owns the kit gets 8 Gold Ingots a claim instead of a crate (Claude's pick). If `PolicyService` can't answer, they aren't offered that time. Trading is off for anyone Roblox says can't trade paid items, and a crate can't be traded to someone barred from paid random items. A bought crate is paid out once however often Roblox asks, and Roblox is only told it's done once the save has gone through. The questionnaire says "Paid Random Items: Yes, respects the API" (submitted 2026-11-09), and the odds are in the pass's and the product's descriptions (2026-11-10).

## Still to decide
- [x] **The name:** Crate Keeper Kit (your pick). You turned down Scavenger because it didn't say the kit gives a loot crate.
- [x] **The kit's price: 1,499 Robux,** bought once, a crate every week (your call, 2026-11-10; it was 2,500 from 2026-11-09: "Weekly gets a crate, that's why it's expensive because it's overpowered." It still costs about five single crates).
- [x] **A single Loot Crate: 299 Robux,** bought separately, as often as you like (your call, 2026-11-10; it was 800).
- [x] **How many armour kits, and their themes:** five (your call, 2026-11-09). Their contents and specials are Claude's picks, above.
- [x] **Each armour kit's price:** 399 to 799 Robux, above (lowered 2026-11-10 from 800 to 1,800).
- [ ] **The nerf:** a claim every 7 days is Claude's pick. Is that enough?

## What the Skybounds kits came with (your list, sent 2026-11-02)
These are for the idea of what a kit can be. Our kits use our own names, themes and models. All of them survive season resets, like ranks.

**Your direction, 2026-11-09:** every armour kit has "something special with the armour and possibly the" sword (your message said "storm"; you confirmed you meant the sword). Your example: Warlord gave you rage for 10 seconds when you right-clicked.

| Kit (7-day cooldown) | Armour | Set bonus or ability | Weapons | Also came with |
|---|---|---|---|---|
| **Medusa** | Diamond defence, Protection 1-3, Unbreaking 10, Siphon 1-5 | Immune to Poison and Wither. While shifting, look at enemies to turn them to stone for 5 s | None listed | 16 Gold Apples, 4 Enderpearls, 6 Healing Salves, a random Frost Walker piece |
| **Warlord** | Diamond defence, 2 gemstone slots a piece: Wicked Eyes, Enfeeble, Battle Trance, Evasion | Rage (a sword gemstone; you remember 10 s on right-click) | Broadsword (Sharpness 2-3, Thunderclap, Bleeding, Rage); Bow (Power 1-2, Punch 1-2, Velocity) | 16 Golden Apples, 12 each of Vitality Spells, Leaping Spells, Vanishing Orbs, Enderpearls; Immortal Stone, Egg Basket, Sky Spark or Stardust, Spawner Spinner, Transforming Skull, Compact Pouch |
| **Duelist** | Diamond defence, 2 slots a piece: Battle Trance, Evasion, Springs | In PvP, you and your enemy are locked into 1v1 single combat | Sabre (Sharpness 2-3, Blade Fury, Disarm, Rage); Bow (Power 1-2, Infinity, Velocity) | 16 Golden Apples, 8 each of Vitality Spells, Leaping Spells, Vanishing Orbs, Enderpearls; Buried Treasure, Treasure Trove, Legendary Relic, Sky Spark or Stardust, Endermite Spawner, Compact Pouch |
| **Barbarian** | Diamond defence, 2 slots | Eat Player Skulls for full health, Swiftness 3 and Strength 1 for 5 s; 3-minute cooldown | Blade (3 slots, +40% chance to decapitate on a kill); Bow (Power 1, Flame 1) | 24 Arrows, 12 Golden Apples, 18 healing potions, 8 Leaping Spells, 8 Knockback Spells, 7 ore seeds, 8 Dark Oak Saplings, Bird Nest, Ant Farm, Gemstone Shell, Gemstone Slot, Dynamite, Mahi-Mahi Spawner |
| **Drifter** | **Iron** defence; boots have 4 slots with Gears and Springs | On death the set and what you're holding are mailed to you; you deal half damage in PvP | None listed | 16 Golden Apples, 8 Vitality Spells, 8 Leaping Spells, Ancient Rune, Legendary Relic, Bird Nest, Spawner Spinner, Ant Farm, Buried Treasure, Shipwreck, Compact Pouch |

The two others:
- **Necromancer:** 3 random drops from a list of spawners and boss eggs. 5-day cooldown.
- **Builder:** a stack of decorative blocks and a tool. 5-day cooldown.
