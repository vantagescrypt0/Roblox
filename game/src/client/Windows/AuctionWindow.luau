--!strict
-- The Auction House (Auctions.luau, AuctionService), opened at the Auctioneer in Town. Three tabs:
--   Browse       everything for sale on every server: search by name, filter by kind of item and by Buy Now or
--                auction, sort, and pick one to see it on the right, where you buy it or bid on it
--   Sell         your Bag (what you wear stays on you): pick an item, how many, Buy Now or auction, a price and
--                how long; it shows what you'd get after the 5% tax
--   My Listings  what you have for sale, with Cancel until someone has bid
-- Times count down on your screen from the server's clock, and the list asks the server again every few seconds
-- while it's open.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Auctions = require(ReplicatedStorage.Shared.Auctions)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local WIDTH, HEIGHT = 1000, 650
local BODY_WIDTH = WIDTH - 48
local TOP = 52 -- the tabs
local ROW = 66
local DETAIL_WIDTH = 330
local ASK_EVERY = 8 -- seconds between fresh lists while the window is open
local SORTS = { "Ending soon", "Newest", "Lowest price", "Highest price" }
local KINDS =
	{ { Id = "All", Label = "All" }, { Id = "BuyNow", Label = "Buy Now" }, { Id = "Auction", Label = "Auctions" } }

type Listing = Auctions.Listing
type Tab = "Browse" | "Sell" | "Mine"
type State = { Listings: { Listing }, Mine: { Listing }, Now: number, Live: boolean }

local AuctionWindow = {}

local window: Window.Window
local tabButtons: { [string]: Theme.Button } = {}
local pages: { [string]: Frame } = {}
local coinsChip: Theme.IconChip
local currentTab: Tab = "Browse"

-- Browse
local searchBox: TextBox
local categoryButtons: { [string]: Theme.Button } = {}
local kindButtons: { [string]: Theme.Button } = {}
local sortButton: Theme.Button
local countLabel: TextLabel
local browseList: ScrollingFrame
local detail: Frame
local detailIcon: Frame
local detailName: TextLabel
local detailSub: TextLabel
local detailSeller: TextLabel
local detailPrice: TextLabel
local detailNote: TextLabel
local detailTime: TextLabel
local bidBox: TextBox
local actionButton: Theme.Button
local emptyDetail: TextLabel

-- Sell
local bagGrid: ScrollingFrame
local sellIcon: Frame
local sellName: TextLabel
local countBox: TextBox
local sellKindButtons: { [string]: Theme.Button } = {}
local priceBox: TextBox
local priceLabel: TextLabel
local hourButtons: { [number]: Theme.Button } = {}
local sellSummary: TextLabel
local listButton: Theme.Button
local slotsLabel: TextLabel

-- My listings
local mineList: ScrollingFrame

local state: State = { Listings = {}, Mine = {}, Now = os.time(), Live = false }
local clockOffset = 0 -- the server's os.time() minus ours
local gameState: any = nil
local category = "All"
local kindFilter = "All"
local sortIndex = 1
local selectedId: string? = nil
local sellItem: string? = nil
local sellKind: Auctions.Kind = "BuyNow"
local sellHours = Auctions.DefaultHours
local lastAsk = 0
local timeLabels: { { Label: TextLabel, Ends: number } } = {}

local function now(): number
	return os.time() + clockOffset
end

local function nameOf(itemId: string): string
	local item = Items[itemId]
	return if item then item.Name else itemId
end

local function plain(text: string): string
	return (string.gsub(string.lower(text), "%s", ""))
end

local function ask()
	lastAsk = os.clock()
	Remotes.AuctionOpen:FireServer()
end

-- The coins a listing shows: its Buy Now price, or what the next bid has to be
local function shownPrice(listing: Listing): number
	return if listing.Kind == "BuyNow" then listing.Price else Auctions.MinBid(listing)
end

local function coinText(parent: Instance, amount: number, size: number, color: Color3?): Frame
	local row = Theme.make("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, size + 6),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	Theme.list(row, Enum.FillDirection.Horizontal, 5).VerticalAlignment = Enum.VerticalAlignment.Center
	local coin = Theme.make("Frame", {
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = row,
	})
	Theme.coin(coin)
	local label = Theme.title(row, Theme.formatNumber(amount), size, color or C.Gold)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, size + 6)
	label.TextTruncate = Enum.TextTruncate.None
	label.LayoutOrder = 2
	return row
end

local function trackTime(label: TextLabel, ends: number)
	table.insert(timeLabels, { Label = label, Ends = ends })
	label.Text = Auctions.TimeLeft(ends - now())
end

local function selected(): Listing?
	if not selectedId then
		return nil
	end
	for _, listing in state.Listings do
		if listing.Id == selectedId then
			return listing
		end
	end
	for _, listing in state.Mine do
		if listing.Id == selectedId then
			return listing
		end
	end
	return nil
end

local function myUserId(): number
	return game:GetService("Players").LocalPlayer.UserId
end

-- Browse -----------------------------------------------------------------------------------------------------

local function filtered(): { Listing }
	local query = plain(searchBox.Text)
	local shown = {}
	for _, listing in state.Listings do
		if listing.Ends <= now() then
			continue
		end
		if category ~= "All" and Auctions.Category(listing.Item) ~= category then
			continue
		end
		if kindFilter ~= "All" and listing.Kind ~= kindFilter then
			continue
		end
		if query ~= "" and not string.find(plain(nameOf(listing.Item)), query, 1, true) then
			continue
		end
		table.insert(shown, listing)
	end
	local sort = SORTS[sortIndex]
	table.sort(shown, function(a, b)
		if sort == "Newest" then
			return a.Created > b.Created
		elseif sort == "Lowest price" then
			return shownPrice(a) / a.Count < shownPrice(b) / b.Count
		elseif sort == "Highest price" then
			return shownPrice(a) / a.Count > shownPrice(b) / b.Count
		end
		return a.Ends < b.Ends
	end)
	return shown
end

local function renderDetail()
	local listing = selected()
	Window.clear(detailIcon)
	detail.Visible = listing ~= nil
	emptyDetail.Visible = listing == nil
	if not listing then
		return
	end
	ItemIcon.create(detailIcon, listing.Item, UDim2.fromScale(0.9, 0.9))
	detailName.Text = nameOf(listing.Item)
	detailSub.Text = `x{Theme.formatNumber(listing.Count)} · {Auctions.Category(listing.Item)} · {if listing.Kind
			== "BuyNow"
		then "Buy Now"
		else "Auction"}`
	detailSeller.Text = `Sold by {listing.SellerName}`
	local mine = listing.Seller == myUserId()
	local coins = if gameState then gameState.Coins or 0 else 0
	bidBox.Visible = false
	if listing.Kind == "BuyNow" then
		detailPrice.Text = `{Theme.formatNumber(listing.Price)} coins`
		detailNote.Text = if listing.Count > 1
			then `{Theme.formatNumber(math.floor(listing.Price / listing.Count))} each`
			else "Pay this and it's yours at once"
		if mine then
			actionButton.SetText("Your listing")
			actionButton.SetEnabled(false)
		else
			actionButton.SetText(`Buy · {Theme.formatNumber(listing.Price)}`)
			actionButton.SetColor(C.Green)
			actionButton.SetEnabled(coins >= listing.Price)
		end
	else
		local least = Auctions.MinBid(listing)
		if listing.Bids > 0 then
			detailPrice.Text = `{Theme.formatNumber(listing.Bid)} coins`
			detailNote.Text =
				`{listing.Bids} {if listing.Bids == 1 then "bid" else "bids"} · top bid by {listing.BidderName}`
		else
			detailPrice.Text = `{Theme.formatNumber(listing.Price)} coins`
			detailNote.Text = "Starting bid · no bids yet"
		end
		if mine then
			actionButton.SetText("Your auction")
			actionButton.SetEnabled(false)
		elseif listing.Bids > 0 and listing.Bidder == myUserId() then
			actionButton.SetText("You're the top bidder")
			actionButton.SetEnabled(false)
		else
			bidBox.Visible = true
			local typed = tonumber(bidBox.Text)
			if not typed or typed < least then
				bidBox.Text = tostring(least)
				typed = least
			end
			actionButton.SetText(`Bid · {Theme.formatNumber(typed :: number)}`)
			actionButton.SetColor(C.Gold)
			actionButton.SetEnabled(coins >= (typed :: number))
		end
	end
	trackTime(detailTime, listing.Ends)
end

local function listingRow(parent: Instance, listing: Listing, order: number, onClick: () -> ()): TextButton
	local isSelected = listing.Id == selectedId
	local row = Theme.make("TextButton", {
		Size = UDim2.new(1, -4, 0, ROW),
		BackgroundColor3 = if isSelected then C.Panel else C.Card,
		BackgroundTransparency = 0.1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		Parent = parent,
	})
	Theme.corner(row, 12)
	Theme.stroke(
		row,
		if isSelected then C.Accent else C.Edge,
		if isSelected then 1.5 else 1,
		if isSelected then 0.2 else 0.88
	)
	local well = Theme.inset(row, UDim2.fromOffset(ROW - 12, ROW - 12), UDim2.fromOffset(6, 6))
	ItemIcon.create(well, listing.Item, UDim2.fromScale(0.88, 0.88))
	local name = Theme.text(row, `{nameOf(listing.Item)}  x{Theme.formatNumber(listing.Count)}`, 17, Theme.Font.Bold)
	name.Position = UDim2.fromOffset(ROW + 4, 8)
	name.Size = UDim2.new(0.5, -ROW, 0, 22)
	local seller = Theme.text(row, `by {listing.SellerName}`, 13, Theme.Font.Medium, C.Muted)
	seller.Position = UDim2.fromOffset(ROW + 4, 34)
	seller.Size = UDim2.new(0.5, -ROW, 0, 18)

	local kind = Theme.chip(
		row,
		if listing.Kind == "BuyNow" then "Buy Now" else "Auction",
		if listing.Kind == "BuyNow" then C.Green else C.Gold
	)
	kind.AnchorPoint = Vector2.new(0, 0.5)
	kind.Position = UDim2.new(0.5, 0, 0.5, 0)
	kind.TextSize = 13
	kind.Size = UDim2.fromOffset(0, 24)

	local price = coinText(row, shownPrice(listing), 18)
	price.AnchorPoint = Vector2.new(1, 0)
	price.Position = UDim2.new(1, -12, 0, 8)
	local time = Theme.text(row, "", 13, Theme.Font.Bold, C.Muted)
	time.AnchorPoint = Vector2.new(1, 0)
	time.Position = UDim2.new(1, -12, 0, 36)
	time.Size = UDim2.fromOffset(160, 18)
	time.TextXAlignment = Enum.TextXAlignment.Right
	trackTime(time, listing.Ends)
	if listing.Kind == "Auction" and listing.Bids > 0 then
		time.Text = time.Text
		local bids =
			Theme.text(row, `{listing.Bids} {if listing.Bids == 1 then "bid" else "bids"}`, 13, Theme.Font.Bold, C.Gold)
		bids.AnchorPoint = Vector2.new(1, 0)
		bids.Position = UDim2.new(1, -110, 0, 36)
		bids.Size = UDim2.fromOffset(80, 18)
		bids.TextXAlignment = Enum.TextXAlignment.Right
	end
	row.Activated:Connect(onClick)
	return row
end

local function renderBrowse()
	for id, button in categoryButtons do
		button.SetColor(if id == category then C.Accent else C.Inset)
	end
	for id, button in kindButtons do
		button.SetColor(if id == kindFilter then C.Accent else C.Inset)
	end
	sortButton.SetText(`Sort: {SORTS[sortIndex]}`)
	Window.clear(browseList)
	local shown = filtered()
	countLabel.Text = if #state.Listings == 0 then "Nothing for sale yet" else `{#shown} of {#state.Listings} for sale`
	for order, listing in shown do
		listingRow(browseList, listing, order, function()
			selectedId = listing.Id
			bidBox.Text = ""
			renderBrowse()
		end)
	end
	if #shown == 0 then
		local none = Theme.text(
			browseList,
			if #state.Listings == 0
				then "Nobody's selling anything yet. Be the first: open the Sell tab."
				else "Nothing matches. Try another search or filter.",
			16,
			Theme.Font.Medium,
			C.Muted
		)
		none.Size = UDim2.new(1, 0, 0, 40)
		none.TextXAlignment = Enum.TextXAlignment.Center
	end
	renderDetail()
end

-- Sell -------------------------------------------------------------------------------------------------------

-- What you can sell: what you carry, less what you're wearing
local function sellable(): { [string]: number }
	local have: { [string]: number } = {}
	if not gameState or not gameState.Items then
		return have
	end
	for itemId, count in gameState.Items :: { [string]: number } do
		if count > 0 and Auctions.CanList(itemId) then
			have[itemId] = count
		end
	end
	for _, wearing in (gameState.Equipped or {}) :: { [string]: string } do
		if have[wearing] then
			have[wearing] -= 1
			if have[wearing] <= 0 then
				have[wearing] = nil
			end
		end
	end
	return have
end

local function readWhole(box: TextBox): number?
	local value = tonumber((string.gsub(box.Text, "[,%s]", "")))
	if not value or value ~= value or value % 1 ~= 0 then
		return nil
	end
	return value
end

local function renderSellForm()
	local have = sellable()
	local count = if sellItem then have[sellItem] or 0 else 0
	Window.clear(sellIcon)
	if sellItem and count > 0 then
		ItemIcon.create(sellIcon, sellItem, UDim2.fromScale(0.9, 0.9))
		sellName.Text = `{nameOf(sellItem)} · you have {Theme.formatNumber(count)}`
	else
		sellItem = nil
		sellName.Text = "Pick something from your Bag"
	end
	for id, button in sellKindButtons do
		button.SetColor(if id == sellKind then (if id == "BuyNow" then C.Green else C.Gold) else C.Inset)
	end
	for hours, button in hourButtons do
		button.SetColor(if hours == sellHours then C.Accent else C.Inset)
	end
	priceLabel.Text = if sellKind == "BuyNow" then "PRICE (COINS)" else "STARTING BID (COINS)"

	local amount = readWhole(countBox)
	local price = readWhole(priceBox)
	local selling = #state.Mine
	slotsLabel.Text = `For sale now: {selling} / {Auctions.MaxListings}`
	local problem: string? = nil
	if not sellItem then
		problem = "Pick an item"
	elseif not amount or amount < 1 or amount > count then
		problem = `How many? 1 to {count}`
	elseif not price or price < Auctions.MinPrice or price > Auctions.MaxPrice then
		problem = "Set a price"
	elseif selling >= Auctions.MaxListings then
		problem = `{Auctions.MaxListings} at a time`
	end
	if problem then
		sellSummary.Text = problem
		sellSummary.TextColor3 = C.Muted
		listButton.SetEnabled(false)
		return
	end
	local p = price :: number
	local after = Auctions.AfterTax(p)
	sellSummary.Text = if sellKind == "BuyNow"
		then `Sells for {Theme.formatNumber(p)}: you get {Theme.formatNumber(after)} after the 5% tax`
		else `Bids start at {Theme.formatNumber(p)}. You get the top bid less 5% tax`
	sellSummary.TextColor3 = C.Ink
	listButton.SetEnabled(true)
end

local function renderSell()
	Window.clear(bagGrid)
	local have = sellable()
	local ids = {}
	for itemId in have do
		table.insert(ids, itemId)
	end
	table.sort(ids, function(a, b)
		return nameOf(a) < nameOf(b)
	end)
	for order, itemId in ids do
		local isPicked = itemId == sellItem
		local cell = Theme.make("TextButton", {
			Size = UDim2.fromOffset(70, 70),
			BackgroundColor3 = if isPicked then C.Panel else C.Card,
			BackgroundTransparency = 0.1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = order,
			Parent = bagGrid,
		})
		Theme.corner(cell, 10)
		Theme.stroke(
			cell,
			if isPicked then C.Accent else C.Edge,
			if isPicked then 2 else 1,
			if isPicked then 0.1 else 0.88
		)
		ItemIcon.create(cell, itemId, UDim2.fromScale(0.82, 0.82))
		local count = Theme.text(cell, Theme.formatNumber(have[itemId]), 14, Theme.Font.Bold, C.White)
		count.AnchorPoint = Vector2.new(1, 1)
		count.Position = UDim2.new(1, -5, 1, -2)
		count.Size = UDim2.fromOffset(60, 16)
		count.TextXAlignment = Enum.TextXAlignment.Right
		count.ZIndex = 3
		cell.Activated:Connect(function()
			sellItem = itemId
			countBox.Text = tostring(have[itemId])
			renderSell()
		end)
	end
	if #ids == 0 then
		local none = Theme.text(bagGrid, "Nothing in your Bag can be sold here", 15, Theme.Font.Medium, C.Muted)
		none.Size = UDim2.fromOffset(400, 30)
	end
	renderSellForm()
end

-- My listings ------------------------------------------------------------------------------------------------

local function renderMine()
	Window.clear(mineList)
	for order, listing in state.Mine do
		local row = listingRow(mineList, listing, order, function() end)
		row.Size = UDim2.new(1, -150, 0, ROW)
		local holder = Theme.make("Frame", {
			Size = UDim2.new(1, -4, 0, ROW),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Parent = mineList,
		})
		row.Parent = holder
		local canCancel = listing.Bids == 0
		local cancel = Theme.button(
			holder,
			if canCancel then "Cancel" else "Has bids",
			C.Red,
			UDim2.fromOffset(136, ROW - 10),
			function()
				Remotes.AuctionCancel:FireServer(listing.Id)
			end
		)
		cancel.Holder.AnchorPoint = Vector2.new(1, 0.5)
		cancel.Holder.Position = UDim2.new(1, 0, 0.5, 0)
		cancel.SetEnabled(canCancel and listing.Ends > now())
	end
	if #state.Mine == 0 then
		local none = Theme.text(
			mineList,
			"You have nothing for sale. Open the Sell tab to list something.",
			16,
			Theme.Font.Medium,
			C.Muted
		)
		none.Size = UDim2.new(1, 0, 0, 40)
		none.TextXAlignment = Enum.TextXAlignment.Center
	end
end

-- Everything -------------------------------------------------------------------------------------------------

local function render()
	if not window or not window.IsOpen then
		return
	end
	timeLabels = {}
	for id, button in tabButtons do
		button.SetColor(if id == currentTab then C.Accent else C.Inset)
	end
	tabButtons.Mine.SetText(if #state.Mine > 0 then `My Listings ({#state.Mine})` else "My Listings")
	for id, page in pages do
		page.Visible = id == currentTab
	end
	coinsChip.Label.Text = Theme.formatNumber(if gameState then gameState.Coins or 0 else 0)
	if currentTab == "Browse" then
		renderBrowse()
	elseif currentTab == "Sell" then
		renderSell()
	else
		renderMine()
	end
end

function AuctionWindow.Open()
	ask()
	if not window.IsOpen then
		searchBox.Text = ""
		Window.open(window)
	end
end

function AuctionWindow.SetState(newState: any)
	gameState = newState
	if window and window.IsOpen and currentTab == "Sell" then
		renderSell()
	elseif window and window.IsOpen then
		coinsChip.Label.Text = Theme.formatNumber(newState.Coins or 0)
		if currentTab == "Browse" then
			renderDetail()
		end
	end
end

local function textBox(parent: Instance, placeholder: string, size: UDim2, position: UDim2?): TextBox
	local box = Theme.make("TextBox", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = C.SlotBottom,
		BackgroundTransparency = 0.1,
		Text = "",
		PlaceholderText = placeholder,
		TextColor3 = C.Ink,
		PlaceholderColor3 = C.Muted,
		TextSize = 17,
		FontFace = Theme.Font.Bold,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
	Theme.corner(box, 10)
	Theme.padding(box, 12, 12, 0, 0)
	Theme.stroke(box, C.Edge, 1, 0.85)
	return box
end

local function heading(parent: Instance, text: string, y: number): TextLabel
	local label = Theme.text(parent, text, 13, Theme.Font.Bold, C.Muted)
	label.Position = UDim2.fromOffset(0, y)
	label.Size = UDim2.new(1, 0, 0, 16)
	return label
end

local function buildBrowse(page: Frame)
	searchBox = textBox(page, "Search", UDim2.fromOffset(220, 38))
	local cats = Theme.make("Frame", {
		Position = UDim2.fromOffset(232, 0),
		Size = UDim2.new(1, -232, 0, 38),
		BackgroundTransparency = 1,
		Parent = page,
	})
	Theme.list(cats, Enum.FillDirection.Horizontal, 6)
	local catWidth = math.floor((BODY_WIDTH - 232 - 6 * (#Auctions.Categories - 1)) / #Auctions.Categories)
	for order, name in Auctions.Categories do
		local button = Theme.button(cats, name, C.Inset, UDim2.fromOffset(catWidth, 38), function()
			category = name
			browseList.CanvasPosition = Vector2.zero
			renderBrowse()
		end)
		button.Holder.LayoutOrder = order
		button.Label.TextSize = 15
		categoryButtons[name] = button
	end

	local second = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Parent = page,
	})
	Theme.list(second, Enum.FillDirection.Horizontal, 6)
	for order, kind in KINDS do
		local button = Theme.button(second, kind.Label, C.Inset, UDim2.fromOffset(104, 36), function()
			kindFilter = kind.Id
			renderBrowse()
		end)
		button.Holder.LayoutOrder = order
		button.Label.TextSize = 15
		kindButtons[kind.Id] = button
	end
	sortButton = Theme.button(second, "Sort", C.Inset, UDim2.fromOffset(230, 36), function()
		sortIndex = sortIndex % #SORTS + 1
		renderBrowse()
	end)
	sortButton.Holder.LayoutOrder = 10
	sortButton.Label.TextSize = 15
	countLabel = Theme.text(page, "", 15, Theme.Font.Bold, C.Muted)
	countLabel.AnchorPoint = Vector2.new(1, 0)
	countLabel.Position = UDim2.new(1, 0, 0, 54)
	countLabel.Size = UDim2.fromOffset(260, 20)
	countLabel.TextXAlignment = Enum.TextXAlignment.Right

	local listTop = 92
	browseList = Window.scrollList(page, UDim2.new(1, -(DETAIL_WIDTH + 12), 1, -listTop), UDim2.fromOffset(0, listTop))

	-- The picked listing, on the right
	local card = Theme.card(page, UDim2.new(0, DETAIL_WIDTH, 1, -listTop), UDim2.new(1, -DETAIL_WIDTH, 0, listTop))
	emptyDetail = Theme.text(card, "Pick something to see it here", 16, Theme.Font.Medium, C.Muted)
	emptyDetail.AnchorPoint = Vector2.new(0.5, 0.5)
	emptyDetail.Position = UDim2.fromScale(0.5, 0.5)
	emptyDetail.TextXAlignment = Enum.TextXAlignment.Center
	detail = Theme.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = card })
	Theme.padding(detail, 16, 16, 14, 14)
	local stage = Theme.inset(detail, UDim2.fromOffset(110, 110))
	stage.AnchorPoint = Vector2.new(0.5, 0)
	stage.Position = UDim2.fromScale(0.5, 0)
	detailIcon = Theme.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = stage })
	detailName = Theme.title(detail, "", 22, C.Ink)
	detailName.Position = UDim2.fromOffset(0, 118)
	detailName.Size = UDim2.new(1, 0, 0, 26)
	detailName.TextXAlignment = Enum.TextXAlignment.Center
	detailSub = Theme.text(detail, "", 14, Theme.Font.Medium, C.Muted)
	detailSub.Position = UDim2.fromOffset(0, 146)
	detailSub.TextXAlignment = Enum.TextXAlignment.Center
	detailSeller = Theme.text(detail, "", 14, Theme.Font.Medium, C.Muted)
	detailSeller.Position = UDim2.fromOffset(0, 166)
	detailSeller.TextXAlignment = Enum.TextXAlignment.Center
	detailPrice = Theme.title(detail, "", 30, C.Gold)
	detailPrice.Position = UDim2.fromOffset(0, 196)
	detailPrice.Size = UDim2.new(1, 0, 0, 34)
	detailPrice.TextXAlignment = Enum.TextXAlignment.Center
	detailNote = Theme.text(detail, "", 14, Theme.Font.Medium, C.Ink)
	detailNote.Position = UDim2.fromOffset(0, 232)
	detailNote.TextXAlignment = Enum.TextXAlignment.Center
	detailTime = Theme.text(detail, "", 15, Theme.Font.Bold, C.Accent)
	detailTime.Position = UDim2.fromOffset(0, 254)
	detailTime.TextXAlignment = Enum.TextXAlignment.Center
	bidBox = textBox(detail, "Your bid", UDim2.new(1, 0, 0, 40))
	bidBox.AnchorPoint = Vector2.new(0, 1)
	bidBox.Position = UDim2.new(0, 0, 1, -62)
	bidBox.TextXAlignment = Enum.TextXAlignment.Center
	bidBox:GetPropertyChangedSignal("Text"):Connect(function()
		local listing = selected()
		local typed = readWhole(bidBox)
		if listing and listing.Kind == "Auction" and typed then
			local coins = if gameState then gameState.Coins or 0 else 0
			actionButton.SetText(`Bid · {Theme.formatNumber(typed)}`)
			actionButton.SetEnabled(typed >= Auctions.MinBid(listing) and coins >= typed)
		end
	end)
	actionButton = Theme.button(detail, "Buy", C.Green, UDim2.new(1, 0, 0, 52), function()
		local listing = selected()
		if not listing then
			return
		end
		if listing.Kind == "BuyNow" then
			Remotes.AuctionBuy:FireServer(listing.Id)
		else
			local amount = readWhole(bidBox)
			if amount then
				Remotes.AuctionBid:FireServer(listing.Id, amount)
			end
		end
		actionButton.SetEnabled(false)
	end)
	actionButton.Holder.AnchorPoint = Vector2.new(0, 1)
	actionButton.Holder.Position = UDim2.fromScale(0, 1)
	actionButton.Label.TextSize = 20

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if window.IsOpen and currentTab == "Browse" then
			browseList.CanvasPosition = Vector2.zero
			renderBrowse()
		end
	end)
end

local function buildSell(page: Frame)
	local left = Theme.card(page, UDim2.new(1, -(DETAIL_WIDTH + 52), 1, 0))
	Theme.padding(left, 12, 12, 10, 10)
	heading(left, "YOUR BAG", 0)
	bagGrid = Theme.make("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 1, -22),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 7,
		ScrollBarImageColor3 = C.NavyLight,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = left,
	})
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(70, 70),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = bagGrid,
	})
	Theme.padding(bagGrid, 2, 10, 2, 2)

	local form = Theme.card(page, UDim2.new(0, DETAIL_WIDTH + 40, 1, 0), UDim2.new(1, -(DETAIL_WIDTH + 40), 0, 0))
	Theme.padding(form, 16, 16, 12, 12)
	local well = Theme.inset(form, UDim2.fromOffset(64, 64))
	sellIcon = Theme.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = well })
	sellName = Theme.text(form, "", 17, Theme.Font.Bold)
	sellName.Position = UDim2.fromOffset(76, 20)
	sellName.Size = UDim2.new(1, -76, 0, 22)

	heading(form, "HOW MANY", 78)
	countBox = textBox(form, "1", UDim2.new(1, -96, 0, 38), UDim2.fromOffset(0, 96))
	local most = Theme.button(form, "All", C.Inset, UDim2.fromOffset(86, 38), function()
		if sellItem then
			countBox.Text = tostring(sellable()[sellItem] or 0)
		end
	end)
	most.Holder.Position = UDim2.new(1, -86, 0, 96)

	heading(form, "HOW TO SELL", 142)
	local kinds = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 160),
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		Parent = form,
	})
	Theme.list(kinds, Enum.FillDirection.Horizontal, 8)
	for order, kind in { { Id = "BuyNow", Label = "Buy Now" }, { Id = "Auction", Label = "Auction" } } do
		local button = Theme.button(kinds, kind.Label, C.Inset, UDim2.new(0.5, -4, 1, 0), function()
			sellKind = kind.Id :: Auctions.Kind
			renderSellForm()
		end)
		button.Holder.LayoutOrder = order
		sellKindButtons[kind.Id] = button
	end

	priceLabel = heading(form, "PRICE (COINS)", 206)
	priceBox = textBox(form, "0", UDim2.new(1, 0, 0, 38), UDim2.fromOffset(0, 224))

	heading(form, "HOW LONG", 270)
	local hours = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 288),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Parent = form,
	})
	Theme.list(hours, Enum.FillDirection.Horizontal, 6)
	local hourWidth = math.floor((DETAIL_WIDTH + 40 - 32 - 6 * (#Auctions.Hours - 1)) / #Auctions.Hours)
	for order, h in Auctions.Hours do
		local button = Theme.button(hours, `{h}h`, C.Inset, UDim2.fromOffset(hourWidth, 36), function()
			sellHours = h
			renderSellForm()
		end)
		button.Holder.LayoutOrder = order
		button.Label.TextSize = 15
		hourButtons[h] = button
	end

	sellSummary = Theme.text(form, "", 15, Theme.Font.Bold, C.Ink)
	sellSummary.Position = UDim2.fromOffset(0, 336)
	sellSummary.Size = UDim2.new(1, 0, 0, 40)
	sellSummary.TextWrapped = true
	sellSummary.TextTruncate = Enum.TextTruncate.None
	slotsLabel = Theme.text(form, "", 13, Theme.Font.Medium, C.Muted)
	slotsLabel.AnchorPoint = Vector2.new(0, 1)
	slotsLabel.Position = UDim2.new(0, 0, 1, -62)
	listButton = Theme.button(form, "List it", C.Green, UDim2.new(1, 0, 0, 52), function()
		local amount = readWhole(countBox)
		local price = readWhole(priceBox)
		if sellItem and amount and price then
			Remotes.AuctionList:FireServer(sellItem, amount, sellKind, price, sellHours)
			listButton.SetEnabled(false)
			sellSummary.Text = "Listing..."
		end
	end)
	listButton.Holder.AnchorPoint = Vector2.new(0, 1)
	listButton.Holder.Position = UDim2.fromScale(0, 1)
	listButton.Label.TextSize = 20

	for _, box in { countBox, priceBox } do
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if window.IsOpen and currentTab == "Sell" then
				renderSellForm()
			end
		end)
	end
end

function AuctionWindow.Start()
	window = Window.new("AuctionWindow", "Auction House", Vector2.new(WIDTH, HEIGHT))
	window.OnOpen = render

	local tabs = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	Theme.list(tabs, Enum.FillDirection.Horizontal, 8)
	for order, tab in { { "Browse", "Browse" }, { "Sell", "Sell" }, { "Mine", "My Listings" } } do
		local button = Theme.button(
			tabs,
			tab[2],
			C.Inset,
			UDim2.fromOffset(if tab[1] == "Mine" then 190 else 140, 42),
			function()
				currentTab = tab[1] :: Tab
				render()
			end
		)
		button.Holder.LayoutOrder = order
		button.Label.FontFace = Theme.Font.Title
		button.Label.TextSize = 20
		tabButtons[tab[1]] = button
	end
	coinsChip = Theme.iconChip(window.Body, "0", 36)
	coinsChip.Frame.AnchorPoint = Vector2.new(1, 0)
	coinsChip.Frame.Position = UDim2.new(1, 0, 0, 3)
	Theme.coin(coinsChip.Icon)
	coinsChip.Label.TextColor3 = C.Gold

	for _, id in { "Browse", "Sell", "Mine" } do
		local page = Theme.make("Frame", {
			Position = UDim2.fromOffset(0, TOP),
			Size = UDim2.new(1, 0, 1, -TOP),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = window.Body,
		})
		pages[id] = page
	end
	buildBrowse(pages.Browse)
	buildSell(pages.Sell)
	mineList = Window.scrollList(pages.Mine, UDim2.fromScale(1, 1))

	Remotes.AuctionState.OnClientEvent:Connect(function(newState: State)
		state = newState
		clockOffset = newState.Now - os.time()
		if selectedId and not selected() then
			selectedId = nil
		end
		render()
	end)

	-- Count down every time on screen, and ask for a fresh list now and then
	local tick = 0
	RunService.Heartbeat:Connect(function(dt)
		if not window.IsOpen then
			return
		end
		tick += dt
		if tick < 1 then
			return
		end
		tick = 0
		local t = now()
		for _, entry in timeLabels do
			if entry.Label.Parent then
				entry.Label.Text = Auctions.TimeLeft(entry.Ends - t)
			end
		end
		if os.clock() - lastAsk > ASK_EVERY then
			ask()
		end
	end)
end

return AuctionWindow
