--!strict
-- A shopkeeper's window (Shops.luau): a Sell tab for what they buy and a Buy tab for what
-- they sell (a shop with only one of those shows just that tab). The Merchant's Sell tab
-- also has "Sell all crops". The server checks every sale and purchase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Shops = require(ReplicatedStorage.Shared.Shops)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local ShopWindow = {}

local window: Window.Window
local sellPage: Frame
local buyPage: Frame
local sellAll: Theme.Button
local sellList: ScrollingFrame
local buyList: ScrollingFrame
local tabs: Frame
local tabButtons: { [string]: Theme.Button } = {}
local shop: Shops.Shop = Shops.List[1]
local currentTab = "Sell"
local state: any = nil

-- Seeds: which crop each one grows
local cropOfSeed: { [string]: Crops.Crop } = {}
for _, crop in Crops.List do
	cropOfSeed[crop.Seed] = crop
end

local function row(parent: Instance, order: number): Frame
	local frame = Theme.card(parent, UDim2.new(1, 0, 0, 68))
	frame.LayoutOrder = order
	return frame
end

-- The item's picture in a sunken box
local function iconBox(parent: Instance, itemId: string)
	local box = Theme.inset(parent, UDim2.fromOffset(50, 50), UDim2.fromOffset(9, 9))
	ItemIcon.create(box, itemId, UDim2.fromScale(0.86, 0.86))
end

local function labels(parent: Instance, title: string, subtitle: string, subtitleColor: Color3?)
	local name = Theme.title(parent, title, 21)
	name.Position = UDim2.fromOffset(70, 8)
	name.Size = UDim2.new(1, -280, 0, 26)
	local sub = Theme.text(parent, subtitle, 14, Theme.Font.Medium, subtitleColor or C.InkMuted)
	sub.Position = UDim2.fromOffset(70, 37)
	sub.Size = UDim2.new(1, -280, 0, 18)
end

local function buttonPair(
	parent: Instance,
	a: string,
	b: string,
	color: Color3,
	onA: () -> (),
	onB: () -> (),
	enabledA: boolean,
	enabledB: boolean
)
	local first = Theme.button(parent, a, color, UDim2.fromOffset(92, 42), onA)
	first.Holder.AnchorPoint = Vector2.new(1, 0.5)
	first.Holder.Position = UDim2.new(1, -110, 0.5, 0)
	first.SetEnabled(enabledA)
	local second = Theme.button(parent, b, color, UDim2.fromOffset(92, 42), onB)
	second.Holder.AnchorPoint = Vector2.new(1, 0.5)
	second.Holder.Position = UDim2.new(1, -10, 0.5, 0)
	second.SetEnabled(enabledB)
end

local function emptyNote(parent: Instance, text: string)
	local empty = Theme.title(parent, text, 20, C.InkMuted)
	empty.Size = UDim2.new(1, 0, 0, 64)
	empty.TextWrapped = true
	empty.TextXAlignment = Enum.TextXAlignment.Center
end

local function renderSell()
	Window.clear(sellList)
	sellAll.Holder.Visible = shop.SellAll
	sellList.Size = if shop.SellAll then UDim2.new(1, 0, 1, -58) else UDim2.fromScale(1, 1)
	sellList.Position = if shop.SellAll then UDim2.fromOffset(0, 58) else UDim2.new()
	if shop.SellAll then
		local total = 0
		for _, itemId in shop.Buys do
			total += (state.Items[itemId] or 0) * Items[itemId].SellPrice
		end
		sellAll.SetText(if total > 0 then `Sell all crops for {Theme.coins(total)}` else "No crops to sell yet")
		sellAll.SetEnabled(total > 0)
	end

	local shown = 0
	for index, itemId in shop.Buys do
		local count = state.Items[itemId] or 0
		local item = Items[itemId]
		if count > 0 then
			shown += 1
			local frame = row(sellList, index)
			iconBox(frame, itemId)
			labels(frame, item.Name, `{count} in your bag · {Theme.coins(item.SellPrice)} each`)
			buttonPair(frame, "Sell 1", "Sell all", C.Orange, function()
				Remotes.Sell:FireServer(shop.Id, itemId, 1)
			end, function()
				Remotes.Sell:FireServer(shop.Id, itemId, "all")
			end, true, true)
		end
	end
	if shown == 0 then
		local names = {}
		for _, itemId in shop.Buys do
			table.insert(names, Items[itemId].Name)
		end
		emptyNote(sellList, `Nothing to sell yet. The {shop.Name} buys {table.concat(names, ", ")}.`)
	end
end

-- 75 -> "75s", 150 -> "2.5 min", 240 -> "4 min"
local function formatTime(seconds: number): string
	if seconds < 120 then
		return `{seconds}s`
	end
	local minutes = seconds / 60
	return if minutes == math.floor(minutes) then `{minutes} min` else `{string.format("%.1f", minutes)} min`
end

local function renderBuy()
	Window.clear(buyList)
	local farmingLevel = state.Skills.Farming and state.Skills.Farming.Level or 1
	for index, itemId in shop.Sells do
		local item = Items[itemId]
		local price = item.BuyPrice
		if not price then
			continue
		end
		local crop = cropOfSeed[itemId]
		local unlocked = not crop or farmingLevel >= crop.FarmingLevel
		local subtitle
		if crop and not unlocked then
			subtitle = `Needs Farming level {crop.FarmingLevel}`
		elseif crop then
			subtitle =
				`{Theme.coins(price)} · regrows in {formatTime(crop.GrowTime)} · sells {Items[crop.Product].SellPrice}`
		else
			subtitle = `{Theme.coins(price)} each · {state.Items[itemId] or 0} in your bag`
		end
		local frame = row(buyList, index)
		iconBox(frame, if crop then crop.Product else itemId)
		labels(frame, item.Name, subtitle, if unlocked then nil else C.Red)
		-- Building blocks go by the stack
		local many = if item.Block then 10 else 5
		buttonPair(frame, "Buy 1", `Buy {many}`, C.Green, function()
			Remotes.Buy:FireServer(shop.Id, itemId, 1)
		end, function()
			Remotes.Buy:FireServer(shop.Id, itemId, many)
		end, unlocked and state.Coins >= price, unlocked and state.Coins >= price * many)
	end
end

local function render()
	if not state then
		return
	end
	local canSell, canBuy = #shop.Buys > 0, #shop.Sells > 0
	if currentTab == "Sell" and not canSell then
		currentTab = "Buy"
	elseif currentTab == "Buy" and not canBuy then
		currentTab = "Sell"
	end
	tabButtons.Sell.Holder.Visible = canSell
	tabButtons.Buy.Holder.Visible = canBuy
	sellPage.Visible = currentTab == "Sell"
	buyPage.Visible = currentTab == "Buy"
	for name, button in tabButtons do
		button.SetColor(if name == currentTab then C.Blue else C.Inset)
	end
	if currentTab == "Sell" then
		renderSell()
	else
		renderBuy()
	end
end

function ShopWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
	end
end

-- Opens the shop of a shopkeeper (a shop id from Shops.luau)
function ShopWindow.Open(shopId: string)
	local found = Shops.ById[shopId]
	if not found then
		return
	end
	if found ~= shop then
		shop = found
		currentTab = "Sell"
	end
	window.Title.Text = shop.Name
	Window.open(window)
end

function ShopWindow.Start()
	window = Window.new("ShopWindow", "Shop", Vector2.new(620, 490), C.Green)
	window.OnOpen = render

	tabs = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	Theme.list(tabs, Enum.FillDirection.Horizontal, 8)
	for order, tab in { { "Sell", "Sell" }, { "Buy", "Buy" } } do
		local button = Theme.button(tabs, tab[2], C.Inset, UDim2.fromOffset(130, 40), function()
			currentTab = tab[1]
			render()
		end)
		button.Holder.LayoutOrder = order
		button.Label.FontFace = Theme.Font.Title
		button.Label.TextSize = 21
		tabButtons[tab[1]] = button
	end

	sellPage = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	sellAll = Theme.button(sellPage, "Sell all crops", C.Orange, UDim2.new(1, -10, 0, 48), function()
		Remotes.Sell:FireServer(shop.Id, "*")
	end)
	sellAll.Label.TextSize = 19
	sellList = Window.scrollList(sellPage, UDim2.new(1, 0, 1, -58), UDim2.fromOffset(0, 58))

	buyPage = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = window.Body,
	})
	buyList = Window.scrollList(buyPage, UDim2.fromScale(1, 1))
end

return ShopWindow
