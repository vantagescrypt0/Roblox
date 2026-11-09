--!strict
-- Visiting islands (Services/VisitService): who you can visit on the left, the guestbook of the island you're on
-- on the right, and who can come to yours. While you're on someone else's island a small bar at the top takes you
-- home. Friends on other island servers come from Roblox's friends list; the server checks every visit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local InboxWindow = require(script.Parent.InboxWindow)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color
local localPlayer = Players.LocalPlayer :: Player

local MAX_WORDS = 80
local NEXT_RULE = { Everyone = "Friends", Friends = "Nobody", Nobody = "Everyone" }
local BUTTON_WIDTH = 96
local LEFT_SHARE = 0.54

type Row = { UserId: number, Name: string, Level: number, Tier: number, Open: boolean, Here: boolean }
type Friend = { UserId: number, Name: string }

local VisitWindow = {}

local window: Window.Window
local islandList: ScrollingFrame
local noIslands: TextLabel
local bookList: ScrollingFrame
local noEntries: TextLabel
local bookTitle: TextLabel
local box: TextBox
local signRow: Frame
local ruleButton: Theme.Button
local state: any = nil
local friendsAway: { Friend } = {}

local function headshot(parent: Instance, userId: number)
	local image = Theme.make("ImageLabel", {
		Size = UDim2.fromOffset(44, 44),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundColor3 = C.Well,
		Image = `rbxthumb://type=AvatarHeadShot&id={userId}&w=48&h=48`,
		Parent = parent,
	})
	Theme.corner(image, 22)
end

local function islandCard(name: string, userId: number, detail: string, order: number, label: string, enabled: boolean)
	local card = Theme.card(islandList, UDim2.new(1, -10, 0, 64))
	card.LayoutOrder = order
	Theme.padding(card, 10, 10, 0, 0)
	headshot(card, userId)
	local title = Theme.title(card, name, 18)
	title.Position = UDim2.fromOffset(54, 10)
	title.Size = UDim2.new(1, -(54 + BUTTON_WIDTH + 8), 0, 24)
	local sub = Theme.text(card, detail, 13, Theme.Font.Medium, C.InkMuted)
	sub.Position = UDim2.fromOffset(54, 34)
	sub.Size = UDim2.new(1, -(54 + BUTTON_WIDTH + 8), 0, 18)
	local button = Theme.button(
		card,
		label,
		if enabled then C.Green else C.NavyLight,
		UDim2.fromOffset(BUTTON_WIDTH, 40),
		function()
			Remotes.VisitGo:FireServer(userId)
			Window.close(window)
		end
	)
	button.Holder.AnchorPoint = Vector2.new(1, 0.5)
	button.Holder.Position = UDim2.fromScale(1, 0.5)
	button.SetEnabled(enabled)
end

local function bookEntry(entry: any, order: number)
	local card = Theme.card(bookList, UDim2.new(1, -10, 0, 0))
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.LayoutOrder = order
	Theme.padding(card, 10, 10, 8, 8)
	Theme.list(card, Enum.FillDirection.Vertical, 2)
	local header = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = card,
	})
	local name = Theme.title(header, entry.Name, 16)
	name.Size = UDim2.new(1, -90, 1, 0)
	local when = Theme.text(header, InboxWindow.Ago(entry.At), 12, Theme.Font.Medium, C.InkMuted)
	when.AnchorPoint = Vector2.new(1, 0)
	when.Position = UDim2.fromScale(1, 0)
	when.Size = UDim2.new(0, 86, 1, 0)
	when.TextXAlignment = Enum.TextXAlignment.Right
	local words = Theme.text(card, entry.Text, 14, Theme.Font.Medium)
	words.LayoutOrder = 2
	words.TextWrapped = true
	words.TextTruncate = Enum.TextTruncate.None
	words.AutomaticSize = Enum.AutomaticSize.Y
	words.Size = UDim2.new(1, 0, 0, 18)
end

local function render()
	if not state then
		return
	end
	Window.clear(islandList)
	local order = 0
	local here: { [number]: boolean } = {}
	for _, row: Row in state.Rows do
		order += 1
		here[row.UserId] = true
		local detail = `Level {row.Level}, island level {row.Tier}`
		if row.Here then
			islandCard(row.Name, row.UserId, detail, order, "Here", false)
		else
			islandCard(row.Name, row.UserId, detail, order, if row.Open then "Visit" else "Closed", row.Open)
		end
	end
	for _, friend in friendsAway do
		if not here[friend.UserId] then
			order += 1
			islandCard(friend.Name, friend.UserId, "Friend, on another server", order, "Visit", true)
		end
	end
	noIslands.Visible = order == 0

	Window.clear(bookList)
	for index, entry in state.Book do
		bookEntry(entry, index)
	end
	noEntries.Visible = #state.Book == 0
	noEntries.Text = if state.HostName
		then "Nobody has signed yet. Be the first."
		else "No signatures yet. Visitors can sign your book."
	bookTitle.Text = if state.HostName then `{state.HostName}'s guestbook` else "Your guestbook"
	signRow.Visible = state.HostName ~= nil
	ruleButton.SetText(`Who can visit: {state.Rule}`)
end

local function refreshFriends()
	local ok, online = pcall(function()
		return localPlayer:GetFriendsOnline(200)
	end)
	local found: { Friend } = {}
	if ok then
		for _, friend in online do
			if friend.PlaceId == Places.Ids.Island then
				table.insert(found, { UserId = friend.VisitorId, Name = friend.DisplayName })
			end
		end
	end
	friendsAway = found
	if window.IsOpen then
		render()
	end
end

local function sign()
	local words = box.Text
	if words ~= "" then
		Remotes.GuestbookSign:FireServer(words)
		box.Text = ""
	end
end

local function buildBar()
	local gui = Theme.screen("VisitBar", 5)
	gui.Enabled = false
	local bar = Theme.card(gui, UDim2.fromOffset(380, 52))
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 10)
	Theme.autoScale(bar)
	Theme.padding(bar, 14, 8, 0, 0)
	local label = Theme.text(bar, "", 16, Theme.Font.Medium)
	label.Size = UDim2.new(1, -124, 1, 0)
	local home = Theme.button(bar, "Go home", C.Blue, UDim2.fromOffset(112, 38), function()
		Remotes.VisitGo:FireServer(0)
	end)
	home.Holder.AnchorPoint = Vector2.new(1, 0.5)
	home.Holder.Position = UDim2.fromScale(1, 0.5)
	local function update()
		local name = localPlayer:GetAttribute("VisitingName")
		gui.Enabled = type(name) == "string" and name ~= ""
		if gui.Enabled then
			label.Text = `Visiting {name}'s island`
		end
	end
	localPlayer:GetAttributeChangedSignal("VisitingName"):Connect(update)
	update()
end

function VisitWindow.Toggle()
	Window.toggle(window)
end

function VisitWindow.Start()
	window = Window.new("VisitWindow", "Visit islands", Vector2.new(820, 560))
	window.OnOpen = function()
		render()
		Remotes.VisitOpen:FireServer()
		task.spawn(refreshFriends)
	end

	local body = window.Body
	local foot = 56
	local left = Theme.make("Frame", {
		Size = UDim2.new(LEFT_SHARE, -8, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})
	local leftTitle = Theme.title(left, "Islands", 20)
	leftTitle.Size = UDim2.new(1, 0, 0, 28)
	islandList = Window.scrollList(left, UDim2.new(1, 0, 1, -(foot + 34)), UDim2.fromOffset(0, 34))
	noIslands = Theme.text(
		left,
		"Nobody else is on this server yet. Friends on other island servers show up here too.",
		15,
		Theme.Font.Medium,
		C.InkMuted
	)
	noIslands.Position = UDim2.fromOffset(0, 34)
	noIslands.Size = UDim2.new(1, -10, 1, -(foot + 34))
	noIslands.TextWrapped = true
	noIslands.TextTruncate = Enum.TextTruncate.None
	noIslands.TextXAlignment = Enum.TextXAlignment.Center
	ruleButton = Theme.button(left, "Who can visit: Everyone", C.Blue, UDim2.new(1, -10, 0, 44), function()
		if state then
			Remotes.VisitRule:FireServer(NEXT_RULE[state.Rule] or "Everyone")
		end
	end)
	ruleButton.Holder.AnchorPoint = Vector2.new(0, 1)
	ruleButton.Holder.Position = UDim2.fromScale(0, 1)

	local right = Theme.make("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(1 - LEFT_SHARE, -8, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})
	bookTitle = Theme.title(right, "Your guestbook", 20)
	bookTitle.Size = UDim2.new(1, 0, 0, 28)
	bookList = Window.scrollList(right, UDim2.new(1, 0, 1, -(foot + 34)), UDim2.fromOffset(0, 34))
	noEntries = Theme.text(right, "", 15, Theme.Font.Medium, C.InkMuted)
	noEntries.Position = UDim2.fromOffset(0, 34)
	noEntries.Size = UDim2.new(1, -10, 1, -(foot + 34))
	noEntries.TextWrapped = true
	noEntries.TextTruncate = Enum.TextTruncate.None
	noEntries.TextXAlignment = Enum.TextXAlignment.Center

	signRow = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = right,
	})
	box = Theme.make("TextBox", {
		Size = UDim2.new(1, -92, 1, 0),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.1,
		Text = "",
		PlaceholderText = "Write something nice",
		TextColor3 = C.Ink,
		PlaceholderColor3 = C.InkMuted,
		TextSize = 15,
		FontFace = Theme.Font.Medium,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = signRow,
	})
	Theme.corner(box, 10)
	Theme.padding(box, 10, 10, 0, 0)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if #box.Text > MAX_WORDS then
			box.Text = string.sub(box.Text, 1, MAX_WORDS)
		end
	end)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			sign()
		end
	end)
	local signButton = Theme.button(signRow, "Sign", C.Green, UDim2.fromOffset(84, 44), sign)
	signButton.Holder.AnchorPoint = Vector2.new(1, 0)
	signButton.Holder.Position = UDim2.fromScale(1, 0)

	Remotes.VisitState.OnClientEvent:Connect(function(newState: any)
		state = newState
		if window.IsOpen then
			render()
		end
	end)
	buildBar()
end

return VisitWindow
