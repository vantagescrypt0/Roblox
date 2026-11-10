# Auction House & Profiles

**Your calls (2026-11-10):** "i want to add an auction house and a trade system. Whenever you left click on a player anywhere but the warzone their profile shows up and add some cool features and add a trade button. Make it look cool maybe what armour their wearing their pet, their level their coins just make it cool. and the auction house is a place in the town make it pretty prominent." Then your answers: trade **anywhere, any distance**; the auction **Buy Now and bids, one market for all servers**; the hall at the **head of Market Square**.

## Player profiles
- **Left-click (tap on phones) another player anywhere but the Warzone** and their profile opens. Clicks through walls don't count: the first thing under the pointer has to be them (or their pet).
- **On the left:** their character as they look right now, armour, shield, held item and pet all on, turning slowly on a lit stage (drag to spin it). Their pet stands at their side. Under it: display name, @username and a **title from their best skill**: Novice (1+), Apprentice (10+), Adept (25+), Expert (50+), Master (75+), Grandmaster (99) Farmer / Miner / Lumberjack / Crafter / Slayer.
- **On the right:** Level with a bar to the next, Coins, Skill total; **Wearing**: Helmet, Chest, Legs, Boots, Shield, Pet and what's in their hand; **Skills**: all five with level and a bar; chips for Season, Island tier, Boosts (Warzone · Player · Island), kits owned and trades made.
- **Buttons:** **Trade** (needs both players at level 5; says why when it can't), **Add Friend** (Roblox's own friend request; shows "Friends ✓" when you already are), **Visit Island** on island servers.
- Nothing private shows: no Inbox, no trade details, no anti-cheat record.
- Code: `server/Services/ProfileService.luau` (the snapshot), `client/Windows/ProfileWindow.luau`, the click in `client/BlockController.luau` (`aimedPlayer`).

## Trading anywhere
Trading now runs on every server but the Warzone's, with anyone on your server however far away. Everything else is as before ([[Economy & Values]]): level 5, items only, both accept, a 3-second countdown, the swap all at once, every trade logged. The Town's T prompt over nearby players stays.

## The Auction House
**Where:** a grand hall across the head of Market Square, facing the arch over the void pit. The main street to the portals runs straight through a great arch in its middle, so everyone passes under it. Two wings, each with its own door ("AUCTIONEER" over it), a red carpet to a long counter with an **Auctioneer** behind it, display pedestals with ore on them, bookshelves and hanging lanterns. Smooth stone and sandstone with a red band under the cornice, a flat roof with a parapet and corner turrets, red and gold banners down the pillars. Over the arch: a tower with **AUCTION HOUSE** in big letters facing the square, a round window, and a blue dome with a gold banner on top. AUCTION HOUSE again over the arch on the portals' side. The two cottages that stood by the main street there are gone; the "THE WORLDS / HOME" signpost moved to where the street comes out of the arch.

**The Auctioneer** is a generated model (Studio's `generate_mesh`: top hat, monocle, curly mustache, red waistcoat, gavel raised), not built from parts. Ids in `shared/MonsterArt.luau`, prompt in `art/generated/monster_prompts.json`. Click him or use his prompt (E) to open the Auction House.

**How it works** (numbers in `shared/Auctions.luau`, Claude's picks where you didn't say):
- **One market for every server.** What anyone lists shows on every Town server.
- **Sell:** pick something from your Bag (what you're wearing stays on you), how many, **Buy Now** (a fixed price) or **Auction** (a starting bid), and how long: 1, 6, 12, 24 or 48 hours. The window shows what you'd get after the tax. Up to **10 listings** at once. The items leave your Bag at once.
- **Browse:** search by name; filter All / Blocks / Resources / Tools / Armour / Pets / Food / Other and All / Buy Now / Auctions; sort by ending soon, newest, or price per item. Pick one to see it on the right, with Buy or a bid box.
- **Buy Now:** pay and it's yours at once (anything that doesn't fit goes to your Inbox).
- **Bidding:** each bid beats the last by at least 5% (and 1 coin). Your coins are held while you're the top bidder; outbid, they come back to your Inbox. A bid in the last minute pushes the end back to a minute away, so nobody can snipe it in the last second. You can't bid on your own auction or outbid yourself.
- **When time's up:** the winner gets the items in their Inbox and the seller the coins; with no bids (or a Buy Now nobody bought) the seller gets the items back in their Inbox. All of this reaches players who are offline.
- **5% tax** on every sale (the seller gets 95%). Coins leave the game.
- **Cancel** your own listing until someone has bid on it; the items come straight back.
- **Rules:** level 5 like trading, nobody Roblox bars from trading, untradeable items (Boost Crystals) can't be listed, and a Loot Crate can't go to anyone Roblox bars from paid random items. Every sale, bid and cancel is in the server log.

**How it's kept safe:** each listing is saved in a DataStore and changed only in one step (UpdateAsync), so two servers can never sell the same thing twice or take the same bid. A MemoryStore list is what every server reads to show what's for sale and to find listings whose time is up; every server but the Warzone's checks about once a minute and settles each ended listing exactly once. Before a listing exists anywhere, the items are out of your save and the save is written, so a crash can't leave them in both. Payouts go through the Inbox, which reaches players on any server or offline.

Code: `shared/Auctions.luau`, `server/Util/AuctionStore.luau`, `server/Services/AuctionService.luau`, `client/Windows/AuctionWindow.luau`, the hall in `server/Services/TownService.luau` (`auctionHouse`).

## Tested (Studio, 2026-11-10)
Two players in a Server and Clients session of Town: list Buy Now and auction, a bid that's too low refused, buy, bid, "already the top bidder", cancel, the ending of both auctions (winner's items and seller's coins by Inbox, unsold items back), the tax (500 → 475, 150 → 143), the Buy Now picked and bought and a listing made from the Sell tab by real clicks. Profile by a real left-click, with Stormcaller armour, shield and pet; Trade pressed on the profile 156 studs away and both trade windows open. Island server with two players: profile with Frostwarden armour and a pet in frame, Visit Island shown, no server errors.

**Not tested:** the live stores (a Rojo build in Studio isn't published, so the Auction House used its plain-table stand-in there; the live DataStore and MemoryStore path has only been checked by reading the code), two servers at once, phones, Add Friend's prompt.
