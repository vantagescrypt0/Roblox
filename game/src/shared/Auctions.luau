--!strict
-- The Auction House (your calls, 2026-11-10): one market shared by every server, in a grand hall at the head of
-- Town's Market Square. Sellers list items for coins at the Auctioneer, either at a fixed Buy Now price or as an
-- auction that goes to the highest bid when its time runs out. What comes back to anyone (a sale's coins, coins from
-- being outbid, an auction won, items nobody bought) arrives in their Inbox, even while they're offline. A 5% tax
-- comes off every sale, so coins leave the game. The numbers are here; AuctionService runs it and AuctionWindow
-- shows it.

local Foods = require(script.Parent.Foods)
local Gear = require(script.Parent.Gear)
local Items = require(script.Parent.Items)
local Tools = require(script.Parent.Tools)

export type Kind = "BuyNow" | "Auction"
-- Active while it's for sale; then Sold (bought, or an auction that had bids), Ended (an auction or Buy Now
-- nobody took) or Cancelled (taken back by its seller before anyone bid)
export type State = "Active" | "Sold" | "Ended" | "Cancelled"
export type Listing = {
	Id: string,
	Seller: number,
	SellerName: string,
	Item: string,
	Count: number,
	Kind: Kind,
	Price: number, -- the Buy Now price, or an auction's starting bid
	Bid: number, -- an auction's highest bid so far (0 = none)
	Bidder: number, -- who made it (or who bought a Buy Now)
	BidderName: string,
	Bids: number,
	Created: number, -- os.time()
	Ends: number, -- os.time()
	State: State,
}

local Auctions = {
	Tax = 0.05, -- of every sale
	MaxListings = 10, -- for sale at once, per player
	MinPrice = 1,
	MaxPrice = 1000000000,
	MaxCount = 9999, -- of one item in one listing
	Hours = { 1, 6, 12, 24, 48 }, -- how long a listing can run
	DefaultHours = 24,
	SnipeGuard = 60, -- seconds: a bid with less than this left pushes the end back to this far away
	BidStep = 0.05, -- each bid beats the last by at least this much (and by at least 1 coin)
	Categories = { "All", "Blocks", "Resources", "Tools", "Armour", "Pets", "Food", "Other" },
	-- Shown to the browser: at most this many listings, the ones ending soonest first
	MostShown = 500,
}

-- The lowest bid an auction will take next
function Auctions.MinBid(listing: Listing): number
	if listing.Bids <= 0 then
		return listing.Price
	end
	return listing.Bid + math.max(1, math.ceil(listing.Bid * Auctions.BidStep))
end

-- The tax on a sale, and what the seller gets
function Auctions.TaxOn(price: number): number
	return math.floor(price * Auctions.Tax)
end

function Auctions.AfterTax(price: number): number
	return price - Auctions.TaxOn(price)
end

-- What the Browse tab's filter puts an item under
function Auctions.Category(itemId: string): string
	local item = Items[itemId]
	if not item then
		return "Other"
	elseif Tools.ByItem[itemId] then
		return "Tools"
	elseif Gear.Armors[itemId] or item.Equip == "Shield" then
		return "Armour"
	elseif Gear.Pets[itemId] then
		return "Pets"
	elseif Foods[itemId] then
		return "Food"
	elseif item.Crate then
		return "Other"
	elseif item.Block then
		return "Blocks"
	end
	return "Resources"
end

-- Whether an item can go up for sale, and why not
function Auctions.CanList(itemId: string): (boolean, string?)
	local item = Items[itemId]
	if not item then
		return false, "That isn't an item"
	elseif item.NoTrade then
		return false, `{item.Name}s can't be sold to other players`
	end
	return true, nil
end

-- "2h 05m", "4m 10s", "Ended"
function Auctions.TimeLeft(seconds: number): string
	if seconds <= 0 then
		return "Ended"
	end
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	if hours >= 24 then
		return `{hours // 24}d {hours % 24}h`
	elseif hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	end
	return string.format("%dm %02ds", minutes, seconds % 60)
end

return table.freeze(Auctions)
