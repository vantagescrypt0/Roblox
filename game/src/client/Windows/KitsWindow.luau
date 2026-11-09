--!strict
-- Kits and Crates (Menu > Kits): what's for sale on the left, and on the right what the picked one gives, with every
-- prize's odds for anything random, and a Buy or Claim button. The button is under the odds on purpose: you can't buy
-- a crate without them on screen. See KitService.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local KitPowers = require(ReplicatedStorage.Shared.KitPowers)
local Kits = require(ReplicatedStorage.Shared.Kits)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CrateWindow = require(script.Parent.CrateWindow)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local DAY, HOUR, MINUTE = 86400, 3600, 60
local CRATE = "SingleCrate" -- the entry for buying one crate
local LIST_WIDTH = 270
local ROW_HEIGHT = 44
local POWER_HEIGHT = 62

export type KitRow = { Id: string, OnSale: boolean, Owned: boolean, Left: number, PassId: number }
export type State = { Kits: { KitRow }, Crate: { OnSale: boolean, ProductId: number } }

local KitsWindow = {}

local window: Window.Window
local heading: TextLabel
local status: TextLabel
local odds: ScrollingFrame
local rewards: ScrollingFrame
local button: Theme.Button
local entries: { [string]: Theme.Button } = {}
local state: State? = nil
local selected: string? = nil
local prices: { [string]: number } = {}
local asked: { [string]: boolean } = {}

local function timeLeft(seconds: number): string
	local days, hours, minutes = seconds // DAY, seconds % DAY // HOUR, seconds % HOUR // MINUTE
	if days > 0 then
		return `{days}d {hours}h`
	elseif hours > 0 then
		return `{hours}h {minutes}m`
	elseif minutes > 0 then
		return `{minutes}m`
	end
	return "under a minute"
end

local function rowOf(id: string): KitRow?
	if state then
		for _, row in state.Kits do
			if row.Id == id then
				return row
			end
		end
	end
	return nil
end

local function shown(id: string): boolean
	if not state then
		return false
	end
	if id == CRATE then
		return state.Crate.OnSale
	end
	local row = rowOf(id)
	return row ~= nil and (row.Owned or row.OnSale)
end

local function buyText(id: string): string
	local price = prices[id]
	return if price then `Buy for {price} Robux` else "Buy"
end

local function rewardRow(order: number, itemId: string, count: number)
	local row = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = rewards,
	})
	local holder = Theme.make("Frame", {
		Size = UDim2.fromOffset(ROW_HEIGHT - 4, ROW_HEIGHT - 4),
		Position = UDim2.fromOffset(0, 2),
		BackgroundTransparency = 1,
		Parent = row,
	})
	ItemIcon.create(holder, itemId, UDim2.fromScale(1, 1))
	local amount = if count > 1 then `{count} ` else ""
	local name = Theme.text(row, `{amount}{Items[itemId].Name}`, 16, Theme.Font.Medium, C.Ink)
	name.Position = UDim2.fromOffset(ROW_HEIGHT + 4, 0)
	name.Size = UDim2.new(1, -(ROW_HEIGHT + 4), 1, 0)
end

-- What a kit's sword and armour do: a heading in the kit's colour and a line about it
local function powerRow(order: number, title: string, text: string, color: Color3)
	local row = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, POWER_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = rewards,
	})
	local heading_ = Theme.text(row, title, 16, Theme.Font.Bold, color)
	heading_.Size = UDim2.new(1, -8, 0, 20)
	local line = Theme.text(row, text, 15, Theme.Font.Medium, C.Ink)
	line.Position = UDim2.fromOffset(0, 21)
	line.Size = UDim2.new(1, -8, 0, POWER_HEIGHT - 23)
	line.TextWrapped = true
	line.TextYAlignment = Enum.TextYAlignment.Top
end

local function refresh()
	if not state then
		return
	end
	-- Keep to something on the list
	if not selected or not shown(selected) then
		selected = nil
		for _, kit in Kits.List do
			if shown(kit.Id) then
				selected = kit.Id
				break
			end
		end
		if not selected and shown(CRATE) then
			selected = CRATE
		end
	end
	for id, entry in entries do
		entry.Holder.Visible = shown(id)
		entry.SetColor(if id == selected then C.Accent else C.Navy)
	end
	if not selected then
		return
	end

	if selected == CRATE then
		heading.Text = "Loot Crate"
		status.Text = CrateWindow.OddsText
		odds.Visible, rewards.Visible = true, false
		button.SetColor(C.Blue)
		button.SetEnabled(true)
		button.SetText(buyText(CRATE))
		return
	end

	local kit = Kits.ById[selected]
	local row = rowOf(selected) :: KitRow
	heading.Text = kit.Name
	status.Text = if kit.Random then `{kit.Text} {CrateWindow.OddsText}` else kit.Text
	odds.Visible, rewards.Visible = kit.Random, not kit.Random
	if not kit.Random then
		Window.clear(rewards)
		local special = KitPowers.Swords[`{kit.Id}Sword`]
		local bonus = KitPowers.Sets[kit.Id]
		if special and bonus then
			powerRow(-2, `Sword special: {special.Name}`, `Right-click while holding it. {special.Text}`, special.Color)
			powerRow(-1, `Wear all four: {bonus.Name}`, bonus.Text, special.Color)
		end
		for order, reward in kit.Rewards do
			rewardRow(order, reward.Item, reward.Count)
		end
	end
	if row.Owned then
		local ready = row.Left <= 0
		button.SetColor(C.Green)
		button.SetEnabled(ready)
		button.SetText(if ready then "Claim" else `Next claim in {timeLeft(row.Left)}`)
	else
		button.SetColor(C.Blue)
		button.SetEnabled(row.OnSale)
		button.SetText(buyText(selected))
	end
end

local function askPrice(id: string, productId: number, kind: Enum.InfoType)
	if asked[id] or productId == 0 then
		return
	end
	asked[id] = true
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(productId, kind)
		end)
		if ok and info and type(info.PriceInRobux) == "number" then
			prices[id] = info.PriceInRobux
			refresh()
		else
			asked[id] = nil
		end
	end)
end

-- Says whether there's anything to show, so the Menu can leave the button out when there isn't
function KitsWindow.SetState(newState: State): boolean
	state = newState
	for _, row in newState.Kits do
		askPrice(row.Id, row.PassId, Enum.InfoType.GamePass)
	end
	askPrice(CRATE, newState.Crate.ProductId, Enum.InfoType.Product)
	refresh()
	if newState.Crate.OnSale then
		return true
	end
	for _, row in newState.Kits do
		if row.Owned or row.OnSale then
			return true
		end
	end
	return false
end

function KitsWindow.Toggle()
	Remotes.KitOpen:FireServer()
	Window.toggle(window)
end

function KitsWindow.CrateOnSale(): boolean
	return state ~= nil and state.Crate.OnSale
end

-- Straight to buying a Loot Crate, with its odds on screen
function KitsWindow.OpenCrate()
	Remotes.KitOpen:FireServer()
	selected = CRATE
	if not window.IsOpen then
		Window.toggle(window)
	end
	refresh()
end

local function act()
	local now = selected
	if not now then
		return
	end
	if now == CRATE then
		Remotes.KitBuyCrate:FireServer()
		return
	end
	local row = rowOf(now)
	if row and row.Owned then
		Remotes.KitClaim:FireServer(now)
	else
		Remotes.KitBuy:FireServer(now)
	end
end

function KitsWindow.Start()
	window = Window.new("KitsWindow", "Kits and Crates", Vector2.new(860, 596))
	window.OnOpen = refresh

	local list = Window.scrollList(window.Body, UDim2.new(0, LIST_WIDTH, 1, 0))
	local function entry(id: string, name: string, order: number)
		local face = Theme.button(list, name, C.Navy, UDim2.new(1, 0, 0, 52), function()
			selected = id
			refresh()
		end)
		face.Holder.LayoutOrder = order
		face.Holder.Visible = false
		entries[id] = face
	end
	for order, kit in Kits.List do
		entry(kit.Id, kit.Name, order * 2)
	end
	entry(CRATE, "Loot Crate", 3) -- straight after the kit that pays them out

	local right = Theme.make("Frame", {
		Position = UDim2.fromOffset(LIST_WIDTH + 16, 0),
		Size = UDim2.new(1, -(LIST_WIDTH + 16), 1, 0),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	heading = Theme.title(right, "", 22)
	heading.Size = UDim2.new(1, 0, 0, 30)
	status = Theme.text(right, "", 16, Theme.Font.Medium, C.InkMuted)
	status.Position = UDim2.fromOffset(0, 34)
	status.Size = UDim2.new(1, 0, 0, 62)
	status.TextWrapped = true
	status.TextYAlignment = Enum.TextYAlignment.Top

	odds = Window.scrollList(right, UDim2.new(1, 0, 1, -166), UDim2.fromOffset(0, 100))
	for order, prize in LootCrates.Prizes do
		CrateWindow.PrizeRow(odds, order, prize)
	end
	rewards = Window.scrollList(right, UDim2.new(1, 0, 1, -166), UDim2.fromOffset(0, 100))
	rewards.Visible = false

	button = Theme.button(right, "Buy", C.Blue, UDim2.fromOffset(280, 48), act)
	button.Holder.AnchorPoint = Vector2.new(0.5, 1)
	button.Holder.Position = UDim2.fromScale(0.5, 1)
end

return KitsWindow
