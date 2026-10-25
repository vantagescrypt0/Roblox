--!strict
-- Trading with another player in Town. Walk up to them and use their Trade prompt (T, or
-- tap it); they get an invite card. In the window, click an item in your bag to move one
-- into the trade (click it under "You give" to take one back), or pick it and use the
-- buttons. Both press Accept, a short countdown runs, then the server swaps everything.
-- The server checks every step: this window only shows what it says and asks for changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Economy = require(ReplicatedStorage.Shared.Economy)
local ItemOrder = require(ReplicatedStorage.Shared.ItemOrder)
local Items = require(ReplicatedStorage.Shared.Items)
local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tools = require(ReplicatedStorage.Shared.Tools)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color
local localPlayer = Players.LocalPlayer :: Player

local SLOT = 50
local GAP = 6
local SIDE_WIDTH = 380
local SIDE_HEIGHT = 206
local INVITE_TIME = 20 -- matches TradeService
local PROMPT_DISTANCE = 10

type Row = { Id: string, Count: number, Value: number, UsesLeft: number? }
type Side = { Items: { Row }, Value: number, Accepted: boolean }
type View = { Partner: string, Version: number, Countdown: number?, Mine: Side, Theirs: Side }
type SidePanel = { Title: TextLabel, Chip: TextLabel, Grid: Frame, Empty: TextLabel, Worth: TextLabel }

local TradeWindow = {}

local window: Window.Window
local mineSide: SidePanel
local theirSide: SidePanel
local warning: TextLabel
local bagGrid: ScrollingFrame
local bagEmpty: TextLabel
local selectedIcon: Frame
local selectedName: TextLabel
local selectedSub: TextLabel
local amountButtons: { [string]: Theme.Button } = {}
local info: TextLabel
local acceptButton: Theme.Button

local inviteGui: ScreenGui
local inviteCard: Frame
local inviteTitle: TextLabel
local inviteTimer: Frame
local inviteFrom: Player? = nil
local inviteToken = 0

local state: any = nil
local view: View? = nil
local active = false -- a trade is open on the server
local closing = false -- we cancelled; ignore updates until the server confirms
local selected: string? = nil
-- Counts we've asked the server for but haven't heard back about, so quick clicks add up
local pending: { [string]: number } = {}
local countdownEnds = 0
local countdownToken = 0

local prompts: { [Player]: ProximityPrompt } = {}
local promptsEnabled = true

local orderIndex: { [string]: number } = {}
for index, itemId in ItemOrder do
	orderIndex[itemId] = index
end

local function offered(itemId: string): number
	if pending[itemId] then
		return pending[itemId]
	end
	if view then
		for _, row in view.Mine.Items do
			if row.Id == itemId then
				return row.Count
			end
		end
	end
	return 0
end

local function setOffer(itemId: string, count: number)
	local have = if state then state.Items[itemId] or 0 else 0
	count = math.clamp(count, 0, have)
	if count == offered(itemId) then
		return
	end
	pending[itemId] = count
	Remotes.TradeOffer:FireServer(itemId, count)
end

local function sorted(rows: { Row }): { Row }
	local copy = table.clone(rows)
	table.sort(copy, function(a, b)
		return (orderIndex[a.Id] or math.huge) < (orderIndex[b.Id] or math.huge)
	end)
	return copy
end

local function slot(parent: Instance, itemId: string, count: number, order: number, hover: string): TextButton
	local isSelected = itemId == selected
	local button = Theme.make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(SLOT, SLOT),
		BackgroundColor3 = C.ParchmentDark,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	Theme.corner(button, 5)
	Theme.stroke(button, if isSelected then C.Ochre else C.TanEdge, if isSelected then 3 else 2)
	ItemIcon.create(button, itemId, UDim2.fromScale(0.8, 0.8))
	if count ~= 1 then
		local label = Theme.text(button, tostring(count), 15, Theme.Font.Bold)
		label.AnchorPoint = Vector2.new(1, 1)
		label.Position = UDim2.new(1, -4, 1, -4)
		label.Size = UDim2.fromOffset(40, 17)
		label.TextXAlignment = Enum.TextXAlignment.Right
		label.ZIndex = 3
	end
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = C.Parchment
		info.Text = hover
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = C.ParchmentDark
	end)
	return button
end

-- Thin bar along the bottom of a slot: how much of a worn tool is left
local function wearBar(button: Instance, itemId: string, usesLeft: number)
	local tool = Tools.ByItem[itemId]
	if not tool then
		return
	end
	local track = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -3),
		Size = UDim2.new(1, -12, 0, 4),
		BackgroundColor3 = C.WoodEdge,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = button,
	})
	Theme.make("Frame", {
		Size = UDim2.fromScale(math.clamp(usesLeft / tool.Durability, 0, 1), 1),
		BackgroundColor3 = C.Leaf,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = track,
	})
end

local function renderSide(panel: SidePanel, side: Side, mine: boolean)
	Window.clear(panel.Grid)
	for order, row in sorted(side.Items) do
		local item = Items[row.Id]
		local hover = `{item.Name} x{row.Count} · worth {Theme.coins(row.Value)}`
		if row.UsesLeft then
			hover ..= ` · one has {row.UsesLeft} uses left`
		end
		local button = slot(panel.Grid, row.Id, row.Count, order, hover)
		if row.UsesLeft then
			wearBar(button, row.Id, row.UsesLeft)
		end
		button.Activated:Connect(function()
			info.Text = hover
			if mine then
				selected = row.Id
				setOffer(row.Id, offered(row.Id) - 1)
				TradeWindow.Render()
			end
		end)
	end
	panel.Empty.Visible = #side.Items == 0
	panel.Worth.Text = `Worth {Theme.coins(side.Value)}`
	panel.Chip.Text = if side.Accepted then "Ready" else "Not ready"
	panel.Chip.TextColor3 = if side.Accepted then C.Leaf else C.InkMuted
end

local function renderBag()
	Window.clear(bagGrid)
	local shown = 0
	for order, itemId in ItemOrder do
		local have = state.Items[itemId] or 0
		if have <= 0 then
			continue
		end
		shown += 1
		local free = have - offered(itemId)
		local hover = `{Items[itemId].Name} · {have} in your bag · worth {Theme.coins(Economy.Value(itemId))} each`
		local button = slot(bagGrid, itemId, free, order, hover)
		local wear = state.Wear[itemId]
		local tool = Tools.ByItem[itemId]
		if wear and wear > 0 and tool then
			wearBar(button, itemId, tool.Durability - wear)
		end
		if free <= 0 then
			-- Everything you have of it is already in the trade
			local shade = Theme.make("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = C.Tan,
				BackgroundTransparency = 0.35,
				ZIndex = 5,
				Parent = button,
			})
			Theme.corner(shade, 5)
		end
		button.Activated:Connect(function()
			info.Text = hover
			selected = itemId
			setOffer(itemId, offered(itemId) + 1)
			TradeWindow.Render()
		end)
	end
	bagEmpty.Visible = shown == 0
end

local function renderSelected()
	Window.clear(selectedIcon)
	local have = if selected then state.Items[selected] or 0 else 0
	if not selected or have <= 0 then
		selected = nil
		selectedName.Text = "Pick an item"
		selectedSub.Text = "Click something in your bag to add it"
		for _, button in amountButtons do
			button.SetEnabled(false)
		end
		return
	end
	local inTrade = offered(selected)
	ItemIcon.create(selectedIcon, selected, UDim2.fromScale(0.86, 0.86))
	selectedName.Text = Items[selected].Name
	selectedSub.Text = `{inTrade} of {have} in the trade · worth {Theme.coins(Economy.Value(selected))} each`
	amountButtons.Less.SetEnabled(inTrade > 0)
	amountButtons.None.SetEnabled(inTrade > 0)
	amountButtons.More.SetEnabled(inTrade < have)
	amountButtons.Ten.SetEnabled(inTrade < have)
	amountButtons.All.SetEnabled(inTrade < have)
end

local function countdownText(): string
	return `Trading in {math.max(1, math.ceil(countdownEnds - os.clock()))}... press to stop`
end

local function renderAccept(current: View)
	local mine, theirs = current.Mine, current.Theirs
	-- Lopsided: you'd get less than half of what you give
	local lopsided = mine.Value > 0 and theirs.Value < mine.Value / 2
	warning.Visible = lopsided
	warning.Text = if theirs.Value == 0
		then `Careful! You give items worth {Theme.coins(mine.Value)} and get nothing back`
		else `Careful! You give items worth {Theme.coins(mine.Value)} and get {Theme.coins(theirs.Value)} back`

	acceptButton.SetEnabled(true)
	if current.Countdown then
		acceptButton.SetColor(C.Ochre)
		acceptButton.SetText(countdownText())
	elseif mine.Accepted then
		acceptButton.SetColor(C.Tan)
		acceptButton.SetText(`Waiting for {current.Partner}... press to change`)
	elseif #mine.Items == 0 and #theirs.Items == 0 then
		acceptButton.SetEnabled(false)
		acceptButton.SetText("Add something to trade")
	else
		acceptButton.SetColor(if lopsided then C.Ochre else C.Green)
		acceptButton.SetText(if lopsided then "Accept anyway" else "Accept")
	end
end

function TradeWindow.Render()
	local current = view
	if not current or not state then
		return
	end
	renderSide(mineSide, current.Mine, true)
	renderSide(theirSide, current.Theirs, false)
	renderBag()
	renderSelected()
	renderAccept(current)
end

-- Keeps the Accept button's "Trading in 3..." counting down
local function runCountdown()
	countdownToken += 1
	local token = countdownToken
	task.spawn(function()
		while token == countdownToken and view and view.Countdown do
			acceptButton.SetText(countdownText())
			task.wait(0.1)
		end
	end)
end

local function setPromptsEnabled(enabled: boolean)
	promptsEnabled = enabled
	for _, prompt in prompts do
		prompt.Enabled = enabled
	end
end

local function hideInvite()
	inviteFrom = nil
	inviteToken += 1
	inviteGui.Enabled = false
end

local function showInvite(from: Player)
	inviteFrom = from
	inviteToken += 1
	local token = inviteToken
	inviteTitle.Text = `{from.DisplayName} wants to trade`
	inviteGui.Enabled = true
	Theme.pop(inviteCard, 0.85)
	inviteTimer.Size = UDim2.new(1, -20, 0, 4)
	TweenService:Create(inviteTimer, TweenInfo.new(INVITE_TIME, Enum.EasingStyle.Linear), {
		Size = UDim2.fromOffset(0, 4),
	}):Play()
	task.delay(INVITE_TIME, function()
		if token == inviteToken then
			hideInvite()
		end
	end)
end

local function answerInvite(accepted: boolean)
	local from = inviteFrom
	hideInvite()
	if from then
		Remotes.TradeRespond:FireServer(from, accepted)
	end
end

local function onUpdate(newView: View?)
	pending = {}
	if not newView then
		active = false
		closing = false
		view = nil
		countdownToken += 1
		Window.close(window)
		return
	elseif closing then
		return
	end
	local opening = not active
	active = true
	view = newView
	if newView.Countdown then
		countdownEnds = os.clock() + newView.Countdown
	end
	window.Title.Text = `Trade with {newView.Partner}`
	theirSide.Title.Text = `{newView.Partner} gives`
	if opening then
		hideInvite()
		selected = nil
		info.Text = "Click an item to move one across"
		Window.open(window)
	elseif window.IsOpen then
		TradeWindow.Render()
	end
	if newView.Countdown then
		runCountdown()
	else
		countdownToken += 1
	end
end

-- A "Trade" prompt over every other player, only on this screen
local function addPrompt(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not root:IsA("BasePart") or player.Parent ~= Players then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Trade"
	prompt.ObjectText = player.DisplayName
	prompt.KeyboardKeyCode = Enum.KeyCode.T
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Enabled = promptsEnabled
	prompt.Triggered:Connect(function()
		Remotes.TradeRequest:FireServer(player)
	end)
	prompt.Parent = root
	prompts[player] = prompt
end

local function watchPlayer(player: Player)
	if player == localPlayer then
		return
	end
	player.CharacterAdded:Connect(function(character)
		addPrompt(player, character)
	end)
	if player.Character then
		task.spawn(addPrompt, player, player.Character)
	end
end

local function sidePanel(parent: Instance, x: number, title: string, emptyText: string): SidePanel
	local card = Theme.card(parent, UDim2.fromOffset(SIDE_WIDTH, SIDE_HEIGHT), UDim2.fromOffset(x, 0))
	local heading = Theme.title(card, title, 22)
	heading.Position = UDim2.fromOffset(12, 6)
	heading.Size = UDim2.new(1, -130, 0, 28)
	local chip = Theme.chip(card, "Not ready")
	chip.AnchorPoint = Vector2.new(1, 0)
	chip.Position = UDim2.new(1, -10, 0, 8)

	local well = Theme.inset(card, UDim2.new(1, -20, 0, 2 * SLOT + GAP + 14), UDim2.fromOffset(10, 42))
	local grid = Theme.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = well })
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(SLOT, SLOT),
		CellPadding = UDim2.fromOffset(GAP, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	Theme.padding(grid, 7, 7, 7, 7)
	local empty = Theme.text(well, emptyText, 15, Theme.Font.Medium, C.InkMuted)
	empty.Size = UDim2.fromScale(1, 1)
	empty.TextXAlignment = Enum.TextXAlignment.Center

	local worth = Theme.text(card, "", 17, Theme.Font.Bold)
	worth.Position = UDim2.fromOffset(12, 172)
	worth.Size = UDim2.new(1, -24, 0, 22)
	return { Title = heading, Chip = chip, Grid = grid, Empty = empty, Worth = worth }
end

local function buildWindow()
	window = Window.new("TradeWindow", "Trade", Vector2.new(800, 600))
	window.OnOpen = function()
		setPromptsEnabled(false)
		TradeWindow.Render()
	end
	-- Closing the window (X, clicking outside, opening another window) ends the trade
	window.OnClose = function()
		setPromptsEnabled(true)
		if active then
			active = false
			closing = true
			view = nil
			countdownToken += 1
			Remotes.TradeCancel:FireServer()
		end
	end
	local body = window.Body

	mineSide = sidePanel(body, 0, "You give", "Click items in your bag to add them")
	theirSide = sidePanel(body, SIDE_WIDTH + 12, "They give", "Nothing yet")

	warning = Theme.text(body, "", 16, Theme.Font.Bold, C.Red)
	warning.Position = UDim2.fromOffset(0, SIDE_HEIGHT + 8)
	warning.Size = UDim2.new(1, 0, 0, 24)
	warning.TextXAlignment = Enum.TextXAlignment.Center
	warning.Visible = false

	-- Your bag (bottom left)
	local top = SIDE_HEIGHT + 40
	local bagTitle = Theme.title(body, "Your bag", 22)
	bagTitle.Position = UDim2.fromOffset(2, top)
	bagTitle.Size = UDim2.fromOffset(SIDE_WIDTH, 26)
	local well = Theme.inset(body, UDim2.new(0, SIDE_WIDTH, 1, -(top + 30)), UDim2.fromOffset(0, top + 30))
	bagGrid = Theme.make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.WoodLight,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = well,
	})
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(SLOT, SLOT),
		CellPadding = UDim2.fromOffset(GAP, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = bagGrid,
	})
	Theme.padding(bagGrid, 7, 7, 7, 7)
	bagEmpty = Theme.text(well, "Your bag is empty", 15, Theme.Font.Medium, C.InkMuted)
	bagEmpty.Size = UDim2.fromScale(1, 1)
	bagEmpty.TextXAlignment = Enum.TextXAlignment.Center

	-- The picked item and how many of it to trade (bottom right)
	local right = SIDE_WIDTH + 12
	local card = Theme.card(body, UDim2.fromOffset(SIDE_WIDTH, 132), UDim2.fromOffset(right, top))
	selectedIcon = Theme.inset(card, UDim2.fromOffset(64, 64), UDim2.fromOffset(10, 10))
	selectedName = Theme.title(card, "", 21)
	selectedName.Position = UDim2.fromOffset(84, 10)
	selectedName.Size = UDim2.new(1, -94, 0, 26)
	selectedSub = Theme.text(card, "", 14, Theme.Font.Medium, C.InkMuted)
	selectedSub.Position = UDim2.fromOffset(84, 40)
	selectedSub.Size = UDim2.new(1, -94, 0, 18)
	local amounts = Theme.make("Frame", {
		Position = UDim2.fromOffset(10, 82),
		Size = UDim2.new(1, -20, 0, 40),
		BackgroundTransparency = 1,
		Parent = card,
	})
	Theme.list(amounts, Enum.FillDirection.Horizontal, 6)
	-- Each button works out the new count from how many you have and how many are in
	local steps: { { Name: string, Label: string, Count: (have: number, inTrade: number) -> number } } = {
		{
			Name = "Less",
			Label = "-1",
			Count = function(_, inTrade)
				return inTrade - 1
			end,
		},
		{
			Name = "More",
			Label = "+1",
			Count = function(_, inTrade)
				return inTrade + 1
			end,
		},
		{
			Name = "Ten",
			Label = "+10",
			Count = function(_, inTrade)
				return inTrade + 10
			end,
		},
		{
			Name = "All",
			Label = "All",
			Count = function(have)
				return have
			end,
		},
		{
			Name = "None",
			Label = "None",
			Count = function()
				return 0
			end,
		},
	}
	for order, step in steps do
		local button = Theme.button(amounts, step.Label, C.WoodLight, UDim2.fromOffset(64, 40), function()
			local itemId = selected
			if itemId then
				setOffer(itemId, step.Count(state.Items[itemId] or 0, offered(itemId)))
				TradeWindow.Render()
			end
		end)
		button.Holder.LayoutOrder = order
		amountButtons[step.Name] = button
	end

	info = Theme.text(body, "", 14, Theme.Font.Bold, C.InkMuted)
	info.Position = UDim2.fromOffset(right + 2, top + 140)
	info.Size = UDim2.fromOffset(SIDE_WIDTH - 4, 20)

	acceptButton = Theme.button(body, "Accept", C.Green, UDim2.fromOffset(SIDE_WIDTH, 56), function()
		local current = view
		if current then
			Remotes.TradeAccept:FireServer(not current.Mine.Accepted, current.Version)
		end
	end)
	acceptButton.Holder.Position = UDim2.fromOffset(right, top + 166)
	acceptButton.Label.TextSize = 20

	local cancel = Theme.button(body, "Cancel trade", C.Red, UDim2.fromOffset(SIDE_WIDTH, 44), function()
		Window.close(window)
	end)
	cancel.Holder.AnchorPoint = Vector2.new(0, 1)
	cancel.Holder.Position = UDim2.new(0, right, 1, 0)
end

-- "<name> wants to trade" card at the top of the screen
local function buildInvite()
	inviteGui = Theme.screen("TradeInvite", 12)
	inviteGui.Enabled = false
	local holder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 64),
		Size = UDim2.fromOffset(380, 128),
		BackgroundTransparency = 1,
		Parent = inviteGui,
	})
	Theme.autoScale(holder)
	inviteCard = Theme.panel(holder, UDim2.fromScale(1, 1))
	inviteTitle = Theme.title(inviteCard, "", 24)
	inviteTitle.Position = UDim2.fromOffset(16, 10)
	inviteTitle.Size = UDim2.new(1, -32, 0, 30)
	local sub = Theme.text(inviteCard, "Swap items with them?", 15, Theme.Font.Medium, C.InkMuted)
	sub.Position = UDim2.fromOffset(16, 42)
	sub.Size = UDim2.new(1, -32, 0, 20)
	local yes = Theme.button(inviteCard, "Trade", C.Green, UDim2.fromOffset(166, 44), function()
		answerInvite(true)
	end)
	yes.Holder.Position = UDim2.fromOffset(16, 70)
	local no = Theme.button(inviteCard, "No thanks", C.Tan, UDim2.fromOffset(166, 44), function()
		answerInvite(false)
	end)
	no.Holder.Position = UDim2.new(1, -182, 0, 70)
	-- Time left to answer, along the bottom edge
	inviteTimer = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -5),
		Size = UDim2.new(1, -20, 0, 4),
		BackgroundColor3 = C.Ochre,
		BorderSizePixel = 0,
		Parent = inviteCard,
	})
end

function TradeWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		TradeWindow.Render()
	end
end

function TradeWindow.Start()
	buildWindow()
	buildInvite()
	Remotes.TradeUpdate.OnClientEvent:Connect(onUpdate)
	Remotes.TradeInvite.OnClientEvent:Connect(function(from: Player, open: boolean)
		if open and not active then
			showInvite(from)
		elseif not open and inviteFrom == from then
			hideInvite()
		end
	end)

	if Places.Current() == "Town" then
		for _, player in Players:GetPlayers() do
			watchPlayer(player)
		end
		Players.PlayerAdded:Connect(watchPlayer)
		Players.PlayerRemoving:Connect(function(player)
			prompts[player] = nil
			if inviteFrom == player then
				hideInvite()
			end
		end)
	end
end

return TradeWindow
