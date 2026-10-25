--!strict
-- Market window: Sell tab (crops and resources for coins) and Seeds tab (buy seeds).
-- The server checks every sale and purchase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local SELL_ORDER = { "Wheat", "Carrot", "Potato", "Glowberry", "Wood", "Stone", "Coal", "RawIron", "IronIngot" }

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

local function renderSell()
	Window.clear(sellList)
	local cropTotal = 0
	for _, crop in Crops.List do
		cropTotal += (state.Items[crop.Product] or 0) * Items[crop.Product].SellPrice
	end
	sellAll.SetText(if cropTotal > 0 then `Sell all crops for {Theme.coins(cropTotal)}` else "No crops to sell yet")
	sellAll.SetEnabled(cropTotal > 0)

	local shown = 0
	for index, itemId in SELL_ORDER do
		local count = state.Items[itemId] or 0
		local item = Items[itemId]
		if count > 0 then
			shown += 1
			local frame = row(sellList, index)
			iconBox(frame, itemId)
			labels(frame, item.Name, `{count} in your bag · {Theme.coins(item.SellPrice)} each`)
			buttonPair(frame, "Sell 1", "Sell all", C.Ochre, function()
				Remotes.Sell:FireServer(itemId, 1)
			end, function()
				Remotes.Sell:FireServer(itemId, "all")
			end, true, true)
		end
	end
	if shown == 0 then
		local empty =
			Theme.title(sellList, "Nothing to sell yet. Harvest crops or gather wood and stone!", 20, C.InkMuted)
		empty.Size = UDim2.new(1, 0, 0, 64)
		empty.TextWrapped = true
		empty.TextXAlignment = Enum.TextXAlignment.Center
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
		iconBox(frame, crop.Product)
		labels(
			frame,
			seed.Name,
			if unlocked
				then `{Theme.coins(price)} · regrows in {formatTime(crop.GrowTime)} · sells {Items[crop.Product].SellPrice}`
				else `Needs Farming level {crop.FarmingLevel}`,
			if unlocked then nil else C.Red
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
		button.SetColor(if name == currentTab then C.WoodLight else C.Tan)
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
	window = Window.new("MarketWindow", "Market", Vector2.new(620, 490))
	window.OnOpen = render

	-- Tabs
	local tabs = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	Theme.list(tabs, Enum.FillDirection.Horizontal, 8)
	for order, tab in { { "Sell", "Sell" }, { "Seeds", "Seeds" } } do
		local button = Theme.button(tabs, tab[2], C.Tan, UDim2.fromOffset(130, 40), function()
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
	sellAll = Theme.button(sellPage, "Sell all crops", C.Ochre, UDim2.new(1, -10, 0, 48), function()
		Remotes.Sell:FireServer("*")
	end)
	sellAll.Label.TextSize = 19
	sellList = Window.scrollList(sellPage, UDim2.new(1, 0, 1, -58), UDim2.fromOffset(0, 58))

	seedsPage = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = window.Body,
	})
	seedList = Window.scrollList(seedsPage, UDim2.fromScale(1, 1))
end

return MarketWindow
