--!strict
-- The Auction House (Auctions.luau): one market for every server, kept in AuctionStore.
--
--   Listing  at the Auctioneer in Town. The items leave your Bag first and your save is written, then the listing is
--            saved; if that fails they come straight back.
--   Buy Now  your coins are taken, then the listing is marked Sold in one step that only one buyer can win. Win and
--            the items are yours (anything that doesn't fit goes to your Inbox) and the seller's coins, less the 5%
--            tax, go to their Inbox. Lose (someone was quicker) and your coins come back at once.
--   Bidding  the same, but your coins are held while you're the highest bidder. Someone outbids you and they come
--            back to your Inbox. A bid in the last minute pushes the end back to a minute away.
--   The end  every server (but the Warzone's) looks for auctions and Buy Nows whose time is up and settles each once:
--            the winner gets the items in their Inbox and the seller the coins, or the seller gets the items back.
--   Cancel   your own listing, until someone bids on it: the items come back.
-- Coins only, no items for items. Trading's rules apply: player level Leveling.TradeLevel, and nobody Roblox bars
-- from trading. Loot Crates can't go to anyone Roblox bars from paid random items. Every sale is in the server log.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Auctions = require(ReplicatedStorage.Shared.Auctions)
local Items = require(ReplicatedStorage.Shared.Items)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local AuctionStore = require(script.Parent.Parent.Util.AuctionStore)
local Policy = require(script.Parent.Parent.Util.Policy)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local DataService = require(script.Parent.DataService)
local InboxService = require(script.Parent.InboxService)
local InventoryService = require(script.Parent.InventoryService)
local StateService = require(script.Parent.StateService)
local TownService = require(script.Parent.TownService)

type Listing = Auctions.Listing

local REFRESH = 10 -- seconds a read of the browse list is good for
local SWEEP_EVERY = 60 -- seconds between looks for listings whose time is up
local NEAR = 30 -- studs from an Auctioneer to use the Auction House
local MAIL_TRIES = 3
local FROM = "Auction House"

local AuctionService = {}

local store = AuctionStore.new()
local cache: { Listing } = {}
local cacheAt = -math.huge
local busy: { [Player]: boolean } = {}
local unsent: { { UserId: number, Mail: InboxService.Mail } } = {} -- letters that couldn't be sent yet
local rng = Random.new()

local function itemName(itemId: string): string
	local item = Items[itemId]
	return if item then item.Name else itemId
end

local function lot(listing: Listing): string
	return `{listing.Count} {itemName(listing.Item)}`
end

-- Sends a letter, trying a few times; one that still can't go waits for the next sweep
local function mail(userId: number, letter: InboxService.Mail)
	task.spawn(function()
		for attempt = 1, MAIL_TRIES do
			if InboxService.Send(userId, letter) then
				return
			end
			task.wait(attempt)
		end
		warn(`[Auction] couldn't send to {userId} yet: {letter.Text}`)
		table.insert(unsent, { UserId = userId, Mail = letter })
	end)
end

local function refresh(force: boolean?)
	if not force and os.clock() - cacheAt < REFRESH then
		return
	end
	local all = store.All()
	if all then
		cache = all
		cacheAt = os.clock()
	end
end

local function cached(id: string): (Listing?, number?)
	for index, listing in cache do
		if listing.Id == id then
			return listing, index
		end
	end
	return nil, nil
end

local function forget(id: string)
	local _, index = cached(id)
	if index then
		table.remove(cache, index)
	end
end

local function remember(listing: Listing)
	local _, index = cached(listing.Id)
	if index then
		cache[index] = listing
	else
		table.insert(cache, listing)
	end
end

local function forSale(listing: Listing): boolean
	return listing.State == "Active" and listing.Ends > os.time()
end

-- What the window shows: what's for sale (ending soonest first) and your own listings
local function sendState(player: Player)
	if player.Parent ~= Players then
		return
	end
	local open, mine = {}, {}
	for _, listing in cache do
		if listing.State ~= "Active" then
			continue
		end
		if listing.Seller == player.UserId then
			table.insert(mine, listing)
		end
		if listing.Ends > os.time() then
			table.insert(open, listing)
		end
	end
	table.sort(open, function(a, b)
		return a.Ends < b.Ends
	end)
	while #open > Auctions.MostShown do
		table.remove(open)
	end
	table.sort(mine, function(a, b)
		return a.Ends < b.Ends
	end)
	Remotes.AuctionState:FireClient(player, { Listings = open, Mine = mine, Now = os.time(), Live = store.Live })
end

-- Is this player standing at an Auctioneer? Tells them if not.
local function atAuctioneer(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if Places.Current() ~= "Town" or not root or not root:IsA("BasePart") then
		return false
	end
	for _, keeper in TownService.GetAuctioneers() do
		local primary = keeper.PrimaryPart
		if primary and (primary.Position - root.Position).Magnitude <= NEAR then
			return true
		end
	end
	StateService.Notify(player, "Walk up to the Auctioneer in the Auction House", "bad")
	return false
end

-- Level and Roblox's trading rules
local function mayTrade(player: Player): boolean
	local data = DataService.GetData(player)
	if not data then
		return false
	end
	if data.Level < Leveling.TradeLevel then
		StateService.Notify(player, `The Auction House opens to you at level {Leveling.TradeLevel}`, "bad")
		return false
	end
	if not Policy.TradingAllowed(player) then
		StateService.Notify(player, "The Auction House isn't available on your account", "bad")
		return false
	end
	return true
end

-- One request at a time per player (each waits on Roblox's stores)
local function begin(player: Player): boolean
	if busy[player] then
		return false
	end
	busy[player] = true
	return true
end

local function finish(player: Player)
	busy[player] = nil
	sendState(player)
end

local function wholeNumber(value: unknown, low: number, high: number): number?
	if type(value) ~= "number" or value ~= value or value % 1 ~= 0 or value < low or value > high then
		return nil
	end
	return value
end

local function newId(player: Player): string
	return string.format("%010d-%d-%04d", os.time(), player.UserId, rng:NextInteger(0, 9999))
end

local function onOpen(player: Player)
	if busy[player] then
		return
	end
	refresh()
	sendState(player)
end

local function onList(player: Player, itemId: unknown, count: unknown, kind: unknown, price: unknown, hours: unknown)
	if type(itemId) ~= "string" or not Items[itemId] or (kind ~= "BuyNow" and kind ~= "Auction") then
		return
	end
	local amount = wholeNumber(count, 1, Auctions.MaxCount)
	local asking = wholeNumber(price, Auctions.MinPrice, Auctions.MaxPrice)
	if not amount or not asking or type(hours) ~= "number" or not table.find(Auctions.Hours, hours :: number) then
		StateService.Notify(player, "Check the amount, price and time", "bad")
		return
	end
	local ok, why = Auctions.CanList(itemId)
	if not ok then
		StateService.Notify(player, why or "That can't be sold here", "bad")
		return
	end
	if not atAuctioneer(player) or not mayTrade(player) or not begin(player) then
		return
	end

	refresh(true)
	local selling = 0
	for _, listing in cache do
		if listing.Seller == player.UserId and listing.State == "Active" then
			selling += 1
		end
	end
	if selling >= Auctions.MaxListings then
		StateService.Notify(player, `You can have {Auctions.MaxListings} things for sale at once`, "bad")
		finish(player)
		return
	end
	-- What you're wearing stays on you
	local worn = 0
	local data = DataService.GetData(player)
	for _, wearing in (if data then data.Equipped else {}) :: { [string]: string } do
		if wearing == itemId then
			worn += 1
		end
	end
	if
		InventoryService.Count(player, itemId) - worn < amount or not InventoryService.Remove(player, itemId, amount)
	then
		StateService.Notify(player, `You don't have {amount} {itemName(itemId)}`, "bad")
		finish(player)
		return
	end
	-- The items are out of your save before the listing exists anywhere, so a crash can't leave them in both
	if not DataService.SaveNow(player) then
		InventoryService.Add(player, itemId, amount)
		StateService.Notify(player, "The Auction House couldn't take it right now. Try again in a moment", "bad")
		finish(player)
		return
	end

	local now = os.time()
	local listing: Listing = {
		Id = newId(player),
		Seller = player.UserId,
		SellerName = player.Name,
		Item = itemId,
		Count = amount,
		Kind = kind :: Auctions.Kind,
		Price = asking,
		Bid = 0,
		Bidder = 0,
		BidderName = "",
		Bids = 0,
		Created = now,
		Ends = now + (hours :: number) * 3600,
		State = "Active",
	}
	if not store.Create(listing) then
		InventoryService.Add(player, itemId, amount)
		StateService.Notify(player, "The Auction House couldn't take it right now. Try again in a moment", "bad")
		finish(player)
		return
	end
	store.Index(listing)
	remember(listing)
	local how = if kind == "BuyNow" then `for {Auctions.MinBid(listing)} coins` else "for auction"
	StateService.Notify(player, `Listed {lot(listing)} {how}!`, "good")
	print(`[Auction] {player.Name} ({player.UserId}) listed {lot(listing)} as {kind} at {asking}, id {listing.Id}`)
	finish(player)
end

local function onBuy(player: Player, id: unknown)
	if type(id) ~= "string" then
		return
	end
	local seen = cached(id)
	if not seen or not forSale(seen) or seen.Kind ~= "BuyNow" then
		StateService.Notify(player, "That's not for sale any more", "bad")
		sendState(player)
		return
	end
	if seen.Seller == player.UserId then
		StateService.Notify(player, "That's your own listing", "bad")
		return
	end
	if seen.Item == LootCrates.Item and Policy.PaidRandomRestricted(player) then
		StateService.Notify(player, "Loot Crates aren't available on your account", "bad")
		return
	end
	if not atAuctioneer(player) or not mayTrade(player) or not begin(player) then
		return
	end
	local price = seen.Price
	if not InventoryService.SpendCoins(player, price) then
		StateService.Notify(player, "Not enough coins", "bad")
		finish(player)
		return
	end

	local won, sold = store.Update(id, function(old)
		if not old or old.State ~= "Active" or old.Kind ~= "BuyNow" or old.Ends <= os.time() then
			return nil
		end
		if old.Price ~= price or old.Seller == player.UserId then
			return nil
		end
		local new = table.clone(old)
		new.State = "Sold"
		new.Bid = price
		new.Bidder = player.UserId
		new.BidderName = player.Name
		return new
	end)
	if not won or not sold then
		InventoryService.AddCoins(player, price)
		StateService.Notify(player, "Someone else got there first. Your coins are back", "bad")
		refresh(true)
		finish(player)
		return
	end

	InventoryService.Add(player, sold.Item, sold.Count)
	mail(sold.Seller, {
		From = FROM,
		Text = `{player.Name} bought your {lot(sold)} for {price} coins ({Auctions.TaxOn(price)} tax).`,
		Coins = Auctions.AfterTax(price),
	})
	store.Unindex(id)
	forget(id)
	StateService.Notify(player, `Bought {lot(sold)} for {price} coins!`, "good")
	print(`[Auction] {player.Name} ({player.UserId}) bought {lot(sold)} from {sold.SellerName} for {price}, id {id}`)
	task.spawn(DataService.SaveNow, player)
	finish(player)
end

local function onBid(player: Player, id: unknown, amount: unknown)
	local offer = wholeNumber(amount, Auctions.MinPrice, Auctions.MaxPrice)
	if type(id) ~= "string" or not offer then
		return
	end
	local seen = cached(id)
	if not seen or not forSale(seen) or seen.Kind ~= "Auction" then
		StateService.Notify(player, "That auction is over", "bad")
		sendState(player)
		return
	end
	if seen.Seller == player.UserId then
		StateService.Notify(player, "You can't bid on your own auction", "bad")
		return
	end
	if seen.Bidder == player.UserId and seen.Bids > 0 then
		StateService.Notify(player, "You're already the highest bidder", "info")
		return
	end
	if offer < Auctions.MinBid(seen) then
		StateService.Notify(player, `Bid at least {Auctions.MinBid(seen)} coins`, "bad")
		return
	end
	if seen.Item == LootCrates.Item and Policy.PaidRandomRestricted(player) then
		StateService.Notify(player, "Loot Crates aren't available on your account", "bad")
		return
	end
	if not atAuctioneer(player) or not mayTrade(player) or not begin(player) then
		return
	end
	if not InventoryService.SpendCoins(player, offer) then
		StateService.Notify(player, "Not enough coins", "bad")
		finish(player)
		return
	end

	local outbid: { UserId: number, Amount: number }? = nil
	local placed, after = store.Update(id, function(old)
		outbid = nil
		if not old or old.State ~= "Active" or old.Kind ~= "Auction" or old.Ends <= os.time() then
			return nil
		end
		if old.Seller == player.UserId or (old.Bids > 0 and old.Bidder == player.UserId) then
			return nil
		end
		if offer < Auctions.MinBid(old) then
			return nil
		end
		local new = table.clone(old)
		if old.Bids > 0 then
			outbid = { UserId = old.Bidder, Amount = old.Bid }
		end
		new.Bid = offer
		new.Bidder = player.UserId
		new.BidderName = player.Name
		new.Bids = old.Bids + 1
		new.Ends = math.max(old.Ends, os.time() + Auctions.SnipeGuard)
		return new
	end)
	if not placed or not after then
		InventoryService.AddCoins(player, offer)
		StateService.Notify(player, "Someone bid more first. Your coins are back: check the new price", "bad")
		refresh(true)
		finish(player)
		return
	end

	local beaten = outbid
	if beaten then
		mail(beaten.UserId, {
			From = FROM,
			Text = `You were outbid on {lot(after)}. Here are your {beaten.Amount} coins back.`,
			Coins = beaten.Amount,
		})
	end
	store.Index(after)
	remember(after)
	StateService.Notify(player, `You're the highest bidder on {lot(after)}!`, "good")
	print(`[Auction] {player.Name} ({player.UserId}) bid {offer} on {lot(after)}, id {id}`)
	task.spawn(DataService.SaveNow, player)
	finish(player)
end

local function onCancel(player: Player, id: unknown)
	if type(id) ~= "string" or not atAuctioneer(player) or not begin(player) then
		return
	end
	local taken, after = store.Update(id, function(old)
		if not old or old.Seller ~= player.UserId or old.State ~= "Active" or old.Bids > 0 then
			return nil
		end
		local new = table.clone(old)
		new.State = "Cancelled"
		return new
	end)
	if not taken or not after then
		StateService.Notify(player, "Once someone has bid it has to run to the end", "bad")
		refresh(true)
		finish(player)
		return
	end
	InventoryService.Add(player, after.Item, after.Count)
	store.Unindex(id)
	forget(id)
	StateService.Notify(player, `{lot(after)} taken off the market`, "info")
	print(`[Auction] {player.Name} ({player.UserId}) cancelled {lot(after)}, id {id}`)
	finish(player)
end

-- A listing whose time is up: only one server's settle goes through
local function settle(listing: Listing)
	local closed, after = store.Update(listing.Id, function(old)
		if not old or old.State ~= "Active" or old.Ends > os.time() then
			return nil
		end
		local new = table.clone(old)
		new.State = if old.Kind == "Auction" and old.Bids > 0 then "Sold" else "Ended"
		return new
	end)
	if not closed or not after then
		-- Already settled somewhere else (or not ended after all): the list just has an old copy
		local saved = store.Get(listing.Id)
		if saved and saved.State ~= "Active" then
			store.Unindex(listing.Id)
			forget(listing.Id)
		elseif saved then
			store.Index(saved)
			remember(saved)
		end
		return
	end
	if after.State == "Sold" then
		mail(after.Bidder, {
			From = FROM,
			Text = `You won the auction for {lot(after)} with a bid of {after.Bid} coins!`,
			Items = { [after.Item] = after.Count },
		})
		mail(after.Seller, {
			From = FROM,
			Text = `Your auction of {lot(after)} sold to {after.BidderName} for {after.Bid} coins ({Auctions.TaxOn(
				after.Bid
			)} tax).`,
			Coins = Auctions.AfterTax(after.Bid),
		})
		print(
			`[Auction] {lot(after)} from {after.SellerName} went to {after.BidderName} for {after.Bid}, id {after.Id}`
		)
	else
		mail(after.Seller, {
			From = FROM,
			Text = `Nobody bought your {lot(after)}, so here it is back.`,
			Items = { [after.Item] = after.Count },
		})
		print(`[Auction] {lot(after)} from {after.SellerName} didn't sell, id {after.Id}`)
	end
	store.Unindex(after.Id)
	forget(after.Id)
end

local function sweep()
	refresh(true)
	local now = os.time()
	for _, listing in table.clone(cache) do
		if listing.State ~= "Active" then
			store.Unindex(listing.Id)
			forget(listing.Id)
		elseif listing.Ends <= now then
			settle(listing)
		end
	end
	-- Letters that couldn't go before
	local waiting = unsent
	unsent = {}
	for _, letter in waiting do
		mail(letter.UserId, letter.Mail)
	end
end

-- For tests in Studio (DevService): ends a listing now, so the next sweep settles it
function AuctionService.EndNow(id: string): boolean
	local ended, after = store.Update(id, function(old)
		if not old or old.State ~= "Active" then
			return nil
		end
		local new = table.clone(old)
		new.Ends = os.time() - 1
		return new
	end)
	if ended and after then
		store.Index(after)
		remember(after)
	end
	return ended
end

-- For tests in Studio (DevService): every listing's time is up now, and they're all settled. Returns how many.
function AuctionService.EndAll(): number
	refresh(true)
	local ended = 0
	for _, listing in table.clone(cache) do
		if listing.State == "Active" and AuctionService.EndNow(listing.Id) then
			ended += 1
		end
	end
	sweep()
	return ended
end

function AuctionService.Start()
	Remotes.AuctionOpen.OnServerEvent:Connect(onOpen)
	Remotes.AuctionList.OnServerEvent:Connect(onList)
	Remotes.AuctionBuy.OnServerEvent:Connect(onBuy)
	Remotes.AuctionBid.OnServerEvent:Connect(onBid)
	Remotes.AuctionCancel.OnServerEvent:Connect(onCancel)
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
	-- Every server but the Warzone's settles ended listings; spread out so they don't all look at once
	task.spawn(function()
		task.wait(rng:NextNumber(5, SWEEP_EVERY))
		while true do
			local ok, problem = pcall(sweep :: any)
			if not ok then
				warn(`[Auction] sweep failed: {problem}`)
			end
			task.wait(SWEEP_EVERY + rng:NextNumber(-10, 10))
		end
	end)
	if Places.Current() == "Town" then
		for _, keeper in TownService.GetAuctioneers() do
			local primary = keeper.PrimaryPart
			if primary then
				local prompt = Prompts.Create(primary, { Action = "Auctions", Object = "Auctioneer", Distance = 12 })
				prompt.Triggered:Connect(function(player)
					Remotes.OpenShop:FireClient(player, "Auctioneer")
				end)
			end
		end
	end
end

return AuctionService
