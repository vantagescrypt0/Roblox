# Boost Crystals

**Your call (2026-11-10):** when Claude suggested cheap first-buy passes (island flight, quick travel, a supporter tag), you said "for these ideas this is where boost crystals come into play" and sent Skybounds' Boost Gems store. Reference and notes: `02 Research/References/Skybounds/boosts/`. Our names, art and numbers are our own.

## How it works
- **Three trees of five boosts.** Each crystal you put into a tree unlocks its next boost, in order. 15 crystals max out all three.
- **Yours for good,** through season resets like the kits. **Once a season** you can take them all back out of the trees and place them again (Menu > Boosts, press twice).
- **Getting them (your call):** **399 Robux** each (developer product `3730196955`, managed pricing off), or found as a **rare prize**:
  - **Loot Crates:** a "good" prize, as rare as a tier VII pet: about 0.19% a slot, **about 1 crate in 89**. It shows in the crate odds like every other prize.
  - **Legendary Skydrops:** weight 1.2 in the Legendary table, **about 1 Legendary in 5** (Claude's pick).
- **A found crystal is an item** until you shift-click it in the Bag (or press "Add the crystal from your Bag" in Menu > Boosts). It can't be traded, and it can't be added inside the Warzone: get it out alive, or it's in your body with everything else. With all 15 placed, a found one stays in the Bag for boosts added later. A bought one goes straight onto your account.
- **Buy** is hidden once you have 15.

## The boosts (your list, with the leave at 5 s)
Where Skycore has no match for a Skybounds boost, the replacement is Claude's: our Warzone has no monsters, nothing wears out, and there are no hoppers yet.

| # | Warzone (only in the Warzone) | Player (everywhere) | Island (only your own island) |
|---|---|---|---|
| 1 | Leave in 5 seconds instead of 7 | +25% Combat XP from monsters | Ore nodes grow back 50% faster |
| 2 | Hunger drains half as fast | +5% coins on everything you sell | Crops and saplings grow 50% faster |
| 3 | Health regrows 50% faster while you're fed | 10% chance of an extra monster drop | Ore nodes grow back twice as fast |
| 4 | 10% chance of an extra item in chests and Skydrops (the first time you open each) | +50% damage to monsters (never players) | Crops and saplings grow twice as fast |
| 5 | +3 hearts (130 health, a second row of hearts) | Fly everywhere except the Warzone | +25% skill XP from what you gather there |

"50% faster" takes 1/1.5 of the time; "twice as fast", half. Selling rounds down to whole coins. All the numbers are in `shared/Boosts.luau`.

## Fairness
The Warzone tree adds real PvP strength (+3 hearts, faster health), as Skybounds' did; you picked that list over a gentler one. Kits already sell diamond armour. A crystal never changes crate odds; if anything ever does, the odds shown must change with it (Roblox's rule).

## Built (2026-11-10)
`shared/Boosts.luau`, `server/Services/BoostService.luau`, `client/Windows/BoostWindow.luau`; hooks in WarzoneService, LootChestService, MobService, ShopService, IslandService, FarmService, BlockService, AntiCheatService (boost flyers may fly fast and stay up, but not through blocks), FlightController, VitalsHud. Purchases are paid through KitService's receipt handler (`HandleProduct`), once per purchase and only after the save. The crystal's look is a generated mesh (`art/generated/`), and the product icon is `art/marketing/Product_BoostCrystal.png` (`art/scripts/boost_icon.ps1`).
