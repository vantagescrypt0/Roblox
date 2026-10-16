--!strict
-- Market window: SELL tab (crops and resources for coins) and SEEDS tab (buy seeds).
-- The server checks every sale and purchase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local SELL_ORDER = { "Wheat", "Carrot", "Potato", "Glowberry", "Wood", "Stone" }

local MarketWindow = {}

local window: Window.Window
local sellPage: Frame
local seedsPage: Frame
local sellAll: Theme.Button
local sellList: ScrollingFrame
local seedList: ScrollingFrame
local tabButtons: { [string]: Theme.Button } = {}
local currentTab = "Sell"
local state: any = nil

local function row(parent: Instance, order: number): Frame
	local frame = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 70),
		LayoutOrder = order,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = parent,
	})
	Theme.gradient(frame, Theme.lighten(C.Row, 0.08), C.Row)
	Theme.corner(frame, 12)
	Theme.stroke(frame, C.Stroke, 2)
	return frame
end

local function iconBox(parent: Instance, icon: string)
	local box = Theme.make("TextLabel", {
		Size = UDim2.fromOffset(52, 52),
		Position = UDim2.fromOffset(9, 9),
		BackgroundColor3 = C.Inset,
		Text = icon,
		TextSize = 32,
		Parent = parent,
	})
	Theme.corner(box, 10)
end

local function labels(parent: Instance, title: string, subtitle: string)
	local name = Theme.title(parent, title, 20)
	name.Position = UDim2.fromOffset(72, 10)
	name.Size = UDim2.new(1, -280, 0, 24)
	local sub = Theme.text(parent, subtitle, 14, Theme.Font.Medium, C.Muted)
	sub.Position = UDim2.fromOffset(72, 38)
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
	local first = Theme.button(parent, a, color, UDim2.fromOffset(92, 44), onA)
	first.Holder.AnchorPoint = Vector2.new(1, 0.5)
	first.Holder.Position = UDim2.new(1, -110, 0.5, 0)
	first.SetEnabled(enabledA)
	local second = Theme.button(parent, b, color, UDim2.fromOffset(92, 44), onB)
	second.Holder.AnchorPoint = Vector2.new(1, 0.5)
	second.Holder.Position = UDim2.new(1, -10, 0.5, 0)
	second.SetEnabled(enabledB)
end

local function renderSell()
	Window.clear(sellList)
	local cropTotal = 0
	for _, crop in Crops.List do
		cropTotal += (state.Items[crop.Product] or 0) * Items[crop.Product].SellPrice
	end
	sellAll.SetText(
		if cropTotal > 0 then `Sell all crops  +💰 {Theme.formatNumber(cropTotal)}` else "No crops to sell yet"
	)
	sellAll.SetEnabled(cropTotal > 0)

	local shown = 0
	for index, itemId in SELL_ORDER do
		local count = state.Items[itemId] or 0
		local item = Items[itemId]
		if count > 0 then
			shown += 1
			local frame = row(sellList, index)
			iconBox(frame, item.Icon)
			labels(frame, `{item.Name}  x{count}`, `💰 {item.SellPrice} each`)
			buttonPair(frame, "Sell 1", "Sell all", C.Gold, function()
				Remotes.Sell:FireServer(itemId, 1)
			end, function()
				Remotes.Sell:FireServer(itemId, "all")
			end, true, true)
		end
	end
	if shown == 0 then
		local empty = Theme.title(sellList, "Nothing to sell. Harvest crops or gather wood and stone!", 18, C.Muted)
		empty.Size = UDim2.new(1, 0, 0, 60)
		empty.TextWrapped = true
		empty.TextXAlignment = Enum.TextXAlignment.Center
	end
end

local function renderSeeds()
	Window.clear(seedList)
	local farmingLevel = state.Skills.Farming and state.Skills.Farming.Level or 1
	for index, crop in Crops.List do
		local seed = Items[crop.Seed]
		local price = seed.BuyPrice
		if not price then
			continue
		end
		local unlocked = farmingLevel >= crop.FarmingLevel
		local frame = row(seedList, index)
		iconBox(frame, Items[crop.Product].Icon)
		local growTime = if crop.GrowTime >= 60 then `{crop.GrowTime // 60}m` else `{crop.GrowTime}s`
		labels(
			frame,
			seed.Name,
			if unlocked
				then `💰 {price} each · grows in {growTime} · sells 💰 {Items[crop.Product].SellPrice}`
				else `🔒 Needs Farming level {crop.FarmingLevel}`
		)
		buttonPair(frame, "Buy 1", "Buy 5", C.Green, function()
			Remotes.BuySeed:FireServer(crop.Seed, 1)
		end, function()
			Remotes.BuySeed:FireServer(crop.Seed, 5)
		end, unlocked and state.Coins >= price, unlocked and state.Coins >= price * 5)
	end
end

local function render()
	if not state then
		return
	end
	sellPage.Visible = currentTab == "Sell"
	seedsPage.Visible = currentTab == "Seeds"
	for name, button in tabButtons do
		button.SetColor(if name == currentTab then C.Blue else C.Grey)
	end
	if currentTab == "Sell" then
		renderSell()
	else
		renderSeeds()
	end
end

function MarketWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
	end
end

function MarketWindow.Open()
	Window.open(window)
end

function MarketWindow.Start()
	window = Window.new("MarketWindow", "Market", "🏪", Vector2.new(600, 480))
	window.OnOpen = render

	-- Tabs
	local tabs = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	Theme.list(tabs, Enum.FillDirection.Horizontal, 10)
	for order, tab in { { "Sell", "💰 SELL" }, { "Seeds", "🌱 SEEDS" } } do
		local button = Theme.button(tabs, tab[2], C.Grey, UDim2.fromOffset(150, 44), function()
			currentTab = tab[1]
			render()
		end)
		button.Holder.LayoutOrder = order
		tabButtons[tab[1]] = button
	end

	sellPage = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 1, -56),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	sellAll = Theme.button(sellPage, "Sell all crops", C.Gold, UDim2.new(1, -10, 0, 52), function()
		Remotes.Sell:FireServer("*")
	end)
	sellAll.Label.TextSize = 22
	sellList = Window.scrollList(sellPage, UDim2.new(1, 0, 1, -62), UDim2.fromOffset(0, 62))

	seedsPage = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 1, -56),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = window.Body,
	})
	seedList = Window.scrollList(seedsPage, UDim2.fromScale(1, 1))
end

return MarketWindow
