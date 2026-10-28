--!strict
-- Inbox window: the mail you've received, newest first. Each letter shows who it's from,
-- when it came, its message and what comes with it (items, coins). Claim takes them; a
-- letter with nothing attached just has OK. Claim all takes everything at once. Open it
-- with the Inbox button (its badge counts the letters waiting). See InboxService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local BUTTON_WIDTH = 116

local InboxWindow = {}

local window: Window.Window
local list: ScrollingFrame
local empty: TextLabel
local claimAll: Theme.Button
local state: any = nil

-- "just now", "5 min ago", "3 h ago", "yesterday", "4 days ago"
local function ago(at: number): string
	local seconds = math.max(0, os.time() - at)
	if seconds < 60 then
		return "just now"
	elseif seconds < 3600 then
		return `{math.floor(seconds / 60)} min ago`
	elseif seconds < 86400 then
		return `{math.floor(seconds / 3600)} h ago`
	end
	local days = math.floor(seconds / 86400)
	return if days == 1 then "yesterday" else `{days} days ago`
end

local function hasGifts(letter: any): boolean
	return next(letter.Items) ~= nil or letter.Coins > 0
end

-- What comes with a letter: a chip per item (its picture and how many), and coins
local function gifts(parent: Instance, letter: any)
	local row = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = parent,
	})
	Theme.list(row, Enum.FillDirection.Horizontal, 6)
	local order = 0
	for itemId, count in letter.Items do
		local item = Items[itemId]
		order += 1
		local chip = Theme.iconChip(row, `{count} {if item then item.Name else itemId}`)
		chip.Frame.LayoutOrder = order
		ItemIcon.create(chip.Icon, itemId, UDim2.fromScale(1, 1))
	end
	if letter.Coins > 0 then
		local chip = Theme.iconChip(row, Theme.coins(letter.Coins))
		chip.Frame.LayoutOrder = order + 1
		Theme.coin(chip.Icon)
	end
end

local function letterCard(letter: any, order: number)
	local card = Theme.card(list, UDim2.fromScale(1, 0))
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.LayoutOrder = order
	Theme.padding(card, 12, 12, 10, 10)

	local content = Theme.make("Frame", {
		Size = UDim2.new(1, -(BUTTON_WIDTH + 12), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = card,
	})
	local layout = Theme.list(content, Enum.FillDirection.Vertical, 4)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top

	local header = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = content,
	})
	local from = Theme.title(header, letter.From, 21)
	from.Size = UDim2.new(1, -100, 1, 0)
	local when = Theme.text(header, ago(letter.At), 13, Theme.Font.Medium, C.InkMuted)
	when.AnchorPoint = Vector2.new(1, 0)
	when.Position = UDim2.fromScale(1, 0)
	when.Size = UDim2.new(0, 96, 1, 0)
	when.TextXAlignment = Enum.TextXAlignment.Right

	local text = Theme.text(content, letter.Text, 15, Theme.Font.Medium)
	text.LayoutOrder = 2
	text.TextWrapped = true
	text.TextTruncate = Enum.TextTruncate.None
	text.AutomaticSize = Enum.AutomaticSize.Y
	text.Size = UDim2.new(1, 0, 0, 19)

	local giving = hasGifts(letter)
	if giving then
		gifts(content, letter)
	end

	local button = Theme.button(
		card,
		if giving then "Claim" else "OK",
		if giving then C.Green else C.WoodLight,
		UDim2.fromOffset(BUTTON_WIDTH, 42),
		function()
			Remotes.ClaimMail:FireServer(letter.Id)
		end
	)
	button.Holder.AnchorPoint = Vector2.new(1, 0.5)
	button.Holder.Position = UDim2.fromScale(1, 0.5)
end

local function render()
	if not state then
		return
	end
	Window.clear(list)
	local mail = state.Inbox
	-- Newest first
	for i = #mail, 1, -1 do
		letterCard(mail[i], #mail - i + 1)
	end
	empty.Visible = #mail == 0
	local anyGifts = false
	for _, letter in mail do
		anyGifts = anyGifts or hasGifts(letter)
	end
	claimAll.SetEnabled(#mail > 0)
	claimAll.SetText(if anyGifts or #mail == 0 then "Claim all" else "Clear all")
	window.Title.Text = if #mail > 0 then `Inbox ({#mail})` else "Inbox"
end

function InboxWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
	end
end

function InboxWindow.Toggle()
	Window.toggle(window)
end

function InboxWindow.Start()
	window = Window.new("InboxWindow", "Inbox", Vector2.new(620, 520))
	window.OnOpen = render

	list = Window.scrollList(window.Body, UDim2.new(1, 0, 1, -58))
	empty = Theme.text(
		window.Body,
		"No mail yet. Starter kits, gifts and things sent to you arrive here.",
		16,
		Theme.Font.Medium,
		C.InkMuted
	)
	empty.Size = UDim2.new(1, 0, 1, -58)
	empty.TextWrapped = true
	empty.TextXAlignment = Enum.TextXAlignment.Center

	claimAll = Theme.button(window.Body, "Claim all", C.Green, UDim2.fromOffset(170, 44), function()
		Remotes.ClaimMail:FireServer("*")
	end)
	claimAll.Holder.AnchorPoint = Vector2.new(1, 1)
	claimAll.Holder.Position = UDim2.fromScale(1, 1)
end

return InboxWindow
