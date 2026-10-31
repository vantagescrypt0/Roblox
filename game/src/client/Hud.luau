--!strict
-- The always-on HUD: coins, the level badge and XP bar in the bottom-left corner (click
-- them for the Skills window), the season's countdown (when it has an end date), Warzone
-- status, a Menu button in the corner that pops up the Bag/Island/Skills/Challenges/Inbox
-- buttons (badges count the mail waiting), the raid banner, pop-up messages and big
-- celebrations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Items = require(ReplicatedStorage.Shared.Items)
local Places = require(ReplicatedStorage.Shared.Places)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local ItemIcon = require(script.Parent.UI.ItemIcon)
local Theme = require(script.Parent.UI.Theme)

local C = Theme.Color
local localPlayer = Players.LocalPlayer :: Player

local Hud = {}

export type Callbacks = {
	OnBag: () -> (),
	OnIsland: () -> (),
	OnSkills: () -> (),
	OnChallenges: () -> (),
	OnInbox: () -> (),
}

local levelNumber: TextLabel
local xpBar: Theme.Bar
local coinsText: TextLabel
local coinsRow: Frame
local warzoneChip: TextLabel
local seasonChip: TextLabel
local season: number? = nil
local raidBanner: Frame
local raidBag: TextLabel
local toastHolder: Frame
local celebration: Frame
local celebrationTitle: TextLabel
local celebrationSub: TextLabel
local fadeFrame: Frame
local fadeTitle: TextLabel
local inboxBadge: TextLabel
local menuBadge: TextLabel
local menuButton: Theme.Button
local menuPanel: Frame
local menuOpen = false
local lastCoins: number? = nil
local lastLevel: number? = nil
local lastMail: number? = nil

-- The colored edge on each kind of message
local TOAST_COLORS: { [string]: Color3 } = {
	info = C.Blue,
	good = C.Leaf,
	coins = C.Orange,
	bad = C.Red,
	level = C.Purple,
	levelup = C.Gold,
}

local BUTTON = 64 -- the menu's buttons are square
local STATUS_WIDTH = 300
local STATUS_HEIGHT = 126

-- Coins, level and XP at the bottom of the left-hand group, right of the Menu. No card
-- behind them: outlined numbers straight over the world.
local function buildStatus(group: Frame, onSkills: () -> ())
	local holder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, BUTTON + 14, 1, 0),
		Size = UDim2.fromOffset(STATUS_WIDTH, STATUS_HEIGHT),
		BackgroundTransparency = 1,
		Parent = group,
	})

	-- Coins: a coin and a big outlined number
	coinsRow = Theme.make("Frame", {
		Size = UDim2.fromOffset(300, 38),
		BackgroundTransparency = 1,
		Parent = holder,
	})
	Theme.list(coinsRow, Enum.FillDirection.Horizontal, 6)
	local coinIcon = Theme.make("Frame", {
		Size = UDim2.fromOffset(38, 38),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = coinsRow,
	})
	Theme.coin(coinIcon)
	coinsText = Theme.text(coinsRow, "0", 30, Theme.Font.Bold, C.White)
	coinsText.AutomaticSize = Enum.AutomaticSize.X
	coinsText.Size = UDim2.fromOffset(0, 38)
	coinsText.TextTruncate = Enum.TextTruncate.None
	coinsText.LayoutOrder = 2

	-- Level badge: a gold circle with the level in big outlined numbers
	local badge = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.fromOffset(80, 80),
		BackgroundColor3 = C.Gold,
		Parent = holder,
	})
	Theme.corner(badge, 999)
	Theme.stroke(badge, C.Outline, 3)
	local ring = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -12, 1, -12),
		BackgroundTransparency = 1,
		Parent = badge,
	})
	Theme.corner(ring, 999)
	Theme.stroke(ring, Theme.lighten(C.Gold, 0.45), 2)
	local lv = Theme.text(badge, "LEVEL", 12, Theme.Font.Bold, C.White)
	lv.Position = UDim2.fromOffset(0, 12)
	lv.Size = UDim2.new(1, 0, 0, 14)
	lv.TextXAlignment = Enum.TextXAlignment.Center
	levelNumber = Theme.text(badge, "1", 34, Theme.Font.Bold, C.White)
	levelNumber.Position = UDim2.fromOffset(0, 26)
	levelNumber.Size = UDim2.new(1, 0, 0, 40)
	levelNumber.TextXAlignment = Enum.TextXAlignment.Center

	local name = Theme.title(holder, localPlayer.DisplayName, 22, C.White)
	name.Position = UDim2.fromOffset(90, 54)
	name.Size = UDim2.fromOffset(210, 26)

	xpBar = Theme.bar(holder, C.Leaf, UDim2.fromOffset(208, 24))
	xpBar.Track.Position = UDim2.fromOffset(90, 86)
	xpBar.Label.TextSize = 14

	-- The badge, name and bar open the Skills window
	local open = Theme.make("TextButton", {
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Parent = holder,
	})
	open.Activated:Connect(onSkills)

	-- Warzone status sits just above the coins
	warzoneChip = Theme.chip(holder, "Warzone at level 10", C.Purple)
	-- Hidden until the Warzone opens in Town
	warzoneChip.Visible = false
	warzoneChip.AnchorPoint = Vector2.new(0, 1)
	warzoneChip.Position = UDim2.fromOffset(0, -8)

	-- The season's countdown, above the right end (hidden while it has no end date)
	seasonChip = Theme.chip(holder, "", C.Orange)
	seasonChip.Visible = false
	seasonChip.AnchorPoint = Vector2.new(1, 1)
	seasonChip.Position = UDim2.new(1, 0, 0, -8)
end

local function renderSeason()
	local endsAt = if season then Seasons.EndsAt(season) else nil
	seasonChip.Visible = endsAt ~= nil
	if endsAt then
		seasonChip.Text = `Season {season} · {Seasons.FormatLeft(endsAt - workspace:GetServerTimeNow())} left`
	end
end

-- Square colored button: a picture with a one-word label under it. Returns the button and
-- the frame to put its picture in.
local function squareButton(parent: Instance, label: string, color: Color3, onClick: () -> ()): (Theme.Button, Frame)
	local button = Theme.button(parent, "", color, UDim2.fromOffset(BUTTON, BUTTON + 4), onClick)
	local picture = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 4),
		Size = UDim2.fromOffset(BUTTON - 24, BUTTON - 24),
		BackgroundTransparency = 1,
		Parent = button.Face,
	})
	local text = Theme.text(button.Face, label, 15, Theme.Font.Bold, C.White)
	text.AnchorPoint = Vector2.new(0.5, 1)
	text.Position = UDim2.new(0.5, 0, 1, -3)
	text.Size = UDim2.new(1, -6, 0, 17)
	text.TextXAlignment = Enum.TextXAlignment.Center
	text.TextTruncate = Enum.TextTruncate.None
	text.TextScaled = true
	text.ZIndex = 2
	Theme.make("UITextSizeConstraint", { MaxTextSize = 15, Parent = text })
	return button, picture
end

-- Three white bars with navy edges
local function drawMenuBars(picture: Frame)
	for row = 0, 2 do
		local bar = Theme.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, (row - 1) * 10),
			Size = UDim2.new(0.8, 0, 0, 6),
			BackgroundColor3 = C.White,
			Parent = picture,
		})
		Theme.corner(bar, 3)
		Theme.stroke(bar, C.Outline, 2)
	end
end

local function setMenu(open: boolean)
	menuOpen = open
	menuPanel.Visible = open
	menuButton.SetColor(if open then C.Orange else C.Navy)
	if open then
		Theme.pop(menuPanel, 0.85)
	end
end

-- The Menu button in the bottom-left corner. It pops up a small panel above it with the
-- Bag, Island, Skills, Challenges and Inbox buttons, so they're only on screen when wanted.
local function buildMenu(group: Frame, callbacks: Callbacks)
	local picture
	menuButton, picture = squareButton(group, "Menu", C.Navy, function()
		setMenu(not menuOpen)
	end)
	menuButton.Holder.AnchorPoint = Vector2.new(0, 1)
	menuButton.Holder.Position = UDim2.fromScale(0, 1)
	drawMenuBars(picture)
	-- The menu's own badge counts the mail waiting too, so it shows while the menu is shut
	menuBadge = Theme.badge(menuButton.Holder)

	local columns, rows, gap, pad = 3, 2, 8, 12
	menuPanel = Theme.panel(
		group,
		UDim2.fromOffset(
			columns * BUTTON + (columns - 1) * gap + pad * 2,
			rows * (BUTTON + 4) + (rows - 1) * gap + pad * 2
		)
	)
	menuPanel.AnchorPoint = Vector2.new(0, 1)
	-- Above the coins, so they stay in sight while the menu is open
	menuPanel.Position = UDim2.new(0, 0, 1, -STATUS_HEIGHT - 6)
	menuPanel.Visible = false
	menuPanel.ZIndex = 4
	Theme.padding(menuPanel, pad)
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(BUTTON, BUTTON + 4),
		CellPadding = UDim2.fromOffset(gap, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = menuPanel,
	})

	local function entry(order: number, label: string, color: Color3, icon: string, onClick: () -> ()): Theme.Button
		local button, slot = squareButton(menuPanel, label, color, function()
			setMenu(false)
			onClick()
		end)
		button.Holder.LayoutOrder = order
		ItemIcon.create(slot, icon, UDim2.fromScale(1, 1))
		return button
	end
	entry(1, "Bag", C.Blue, "IconBag", callbacks.OnBag)
	entry(2, "Island", C.Green, "Grass", callbacks.OnIsland)
	entry(3, "Skills", C.Teal, "IronPickaxe", callbacks.OnSkills)
	entry(4, "Challenges", C.Gold, "IconTrophy", callbacks.OnChallenges)
	local inbox = entry(5, "Inbox", C.Purple, "IconMail", callbacks.OnInbox)
	-- Red badge on the corner: how many letters are waiting
	inboxBadge = Theme.badge(inbox.Holder)

	-- A click or tap on the game itself (not on a button) shuts the menu
	UserInputService.InputBegan:Connect(function(input, processed)
		local press = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		if menuOpen and press and not processed then
			setMenu(false)
		end
	end)
end

local function buildRaidBanner(gui: ScreenGui)
	raidBanner = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(440, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.darken(C.Red, 0.3),
		Visible = false,
		Parent = gui,
	})
	Theme.corner(raidBanner, 12)
	Theme.stroke(raidBanner, C.Outline, 3)
	Theme.padding(raidBanner, 12, 12, 8, 10)
	Theme.list(raidBanner, Enum.FillDirection.Vertical, 2)
	Theme.autoScale(raidBanner)
	local title = Theme.worldTitle(raidBanner, "Warzone", 30, C.Gold)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.LayoutOrder = 1
	local hint = Theme.text(raidBanner, "Reach a green pad to extract your loot", 14, Theme.Font.Medium, C.White)
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.LayoutOrder = 2
	raidBag = Theme.text(raidBanner, "", 16, Theme.Font.Bold, C.White)
	raidBag.TextXAlignment = Enum.TextXAlignment.Center
	raidBag.TextWrapped = true
	raidBag.AutomaticSize = Enum.AutomaticSize.Y
	raidBag.TextTruncate = Enum.TextTruncate.None
	raidBag.LayoutOrder = 3
end

local function buildToasts(gui: ScreenGui)
	toastHolder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -140),
		Size = UDim2.fromOffset(420, 220),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(toastHolder)
	local layout = Theme.list(toastHolder, Enum.FillDirection.Vertical, 6)
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
end

local function buildCelebration(gui: ScreenGui)
	celebration = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromOffset(640, 150),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	celebrationTitle = Theme.worldTitle(celebration, "Level Up!", 76, C.Gold)
	celebrationTitle.Size = UDim2.new(1, 0, 0, 86)
	celebrationTitle.TextXAlignment = Enum.TextXAlignment.Center
	celebrationSub = Theme.worldTitle(celebration, "", 34)
	celebrationSub.Position = UDim2.fromOffset(0, 88)
	celebrationSub.Size = UDim2.new(1, 0, 0, 40)
	celebrationSub.TextXAlignment = Enum.TextXAlignment.Center
	Theme.make("UIScale", { Parent = celebration })
end

-- Fades a label and its outline in or out (straight away without `info`)
local function fadeLabel(label: TextLabel, info: TweenInfo?, transparency: number)
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if info then
		TweenService:Create(label, info, { TextTransparency = transparency }):Play()
		if stroke then
			TweenService:Create(stroke, info, { Transparency = transparency }):Play()
		end
	else
		label.TextTransparency = transparency
		if stroke then
			stroke.Transparency = transparency
		end
	end
end

local celebrateToken = 0
function Hud.Celebrate(title: string, subtitle: string, color: Color3?)
	celebrateToken += 1
	local token = celebrateToken
	celebrationTitle.Text = title
	celebrationTitle.TextColor3 = color or C.Gold
	celebrationSub.Text = subtitle
	fadeLabel(celebrationTitle, nil, 0)
	fadeLabel(celebrationSub, nil, 0)
	celebration.Visible = true
	local scale = celebration:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 0.4
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	task.delay(2.2, function()
		if token ~= celebrateToken then
			return
		end
		local fade = TweenInfo.new(0.5)
		fadeLabel(celebrationTitle, fade, 1)
		fadeLabel(celebrationSub, fade, 1)
		task.wait(0.5)
		if token == celebrateToken then
			celebration.Visible = false
		end
	end)
end

function Hud.Render(state: any)
	levelNumber.Text = tostring(state.Level)
	if lastLevel and state.Level > lastLevel then
		Theme.pop(levelNumber, 1.4)
	end
	lastLevel = state.Level

	if state.Level >= state.MaxLevel then
		xpBar.Set(1, "Max level")
	else
		xpBar.Set(state.XP / state.XPToNext, `{Theme.formatNumber(state.XP)} / {Theme.formatNumber(state.XPToNext)} XP`)
	end

	coinsText.Text = Theme.formatNumber(state.Coins)
	if lastCoins and state.Coins ~= lastCoins then
		Theme.pop(coinsRow, 1.15)
	end
	lastCoins = state.Coins

	season = state.Season
	renderSeason()

	if state.Level >= state.WarzoneLevel then
		warzoneChip.Text = "Warzone open!"
	else
		warzoneChip.Text = `Warzone at level {state.WarzoneLevel}`
	end

	local mail = #state.Inbox
	for _, badge in { inboxBadge, menuBadge } do
		badge.Visible = mail > 0
		badge.Text = if mail > 99 then "99+" else tostring(mail)
	end
	if lastMail and mail > lastMail then
		Theme.pop(menuBadge, 1.5)
	end
	lastMail = mail

	raidBanner.Visible = state.Raid.Active
	local bag = {}
	for id, count in state.Raid.Bag do
		local item = Items[id]
		table.insert(bag, `{item and item.Name or id} x{count}`)
	end
	raidBag.Text = if #bag > 0 then table.concat(bag, "   ") else "Bag empty - open chests, beat monsters"
end

local toastCount = 0
function Hud.Toast(text: string, kind: string)
	if kind == "levelup" then
		Hud.Celebrate("Level Up!", text, C.Gold)
		return
	elseif kind == "season" then
		Hud.Celebrate("New Season!", text, C.Gold)
		return
	end
	toastCount += 1
	local color = TOAST_COLORS[kind] or C.Blue
	-- A white tag with a navy outline and a colored dot in front
	local toast = Theme.make("Frame", {
		LayoutOrder = toastCount,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 40),
		BackgroundColor3 = C.Panel,
		Parent = toastHolder,
	})
	Theme.corner(toast, 12)
	local stroke = Theme.stroke(toast, C.Outline, 3)
	Theme.padding(toast, 12, 16, 0, 0)
	Theme.list(toast, Enum.FillDirection.Horizontal, 10)
	local edge = Theme.make("Frame", {
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = color,
		LayoutOrder = 1,
		Parent = toast,
	})
	Theme.corner(edge, 999)
	local edgeStroke = Theme.stroke(edge, C.Outline, 2)
	local label = Theme.text(toast, text, 18, Theme.Font.Bold)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, 30)
	label.LayoutOrder = 2
	label.TextTruncate = Enum.TextTruncate.None
	Theme.pop(toast, 0.7)

	task.delay(if kind == "level" then 3.5 else 2.2, function()
		local fade = TweenInfo.new(0.35)
		TweenService:Create(toast, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(edge, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(edgeStroke, fade, { Transparency = 1 }):Play()
		TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
		TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
		task.wait(0.35)
		toast:Destroy()
	end)
end

local travelToken = 0

local function setFade(visible: boolean, info: TweenInfo)
	local goal = if visible then 0 else 1
	TweenService:Create(fadeFrame, info, { BackgroundTransparency = goal }):Play()
	fadeLabel(fadeTitle, info, goal)
end

-- Fades the screen out while a portal teleports you to another server; "Failed" (the
-- teleport didn't happen) fades it back in
function Hud.Travel(destination: string)
	travelToken += 1
	local token = travelToken
	if destination == "Failed" then
		setFade(false, TweenInfo.new(0.5))
		return
	end
	local name = (Places.Names :: any)[destination]
	fadeTitle.Text = if destination == "Island" or not name then "Heading home..." else `Traveling to {name}...`
	setFade(true, TweenInfo.new(0.35))
	-- Never leave the screen dark if the teleport silently never happens
	task.delay(20, function()
		if token == travelToken then
			setFade(false, TweenInfo.new(0.6))
		end
	end)
end

function Hud.Start(callbacks: Callbacks)
	local gui = Theme.screen("HUD", 1)
	-- Menu and status sit side by side in the bottom-left corner as one group (scaled
	-- together on phones), clear of Roblox's chat window in the top-left
	local group = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -14),
		Size = UDim2.fromOffset(BUTTON + 14 + STATUS_WIDTH, STATUS_HEIGHT),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(group)
	buildMenu(group, callbacks)
	buildStatus(group, callbacks.OnSkills)
	buildRaidBanner(gui)
	buildToasts(gui)
	buildCelebration(gui)
	task.spawn(function()
		while true do
			task.wait(1)
			renderSeason()
		end
	end)

	-- Full-screen fade for portal travel
	local fadeGui = Theme.screen("Fade", 20)
	fadeGui.IgnoreGuiInset = true
	fadeFrame = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Outline,
		BackgroundTransparency = 1,
		Parent = fadeGui,
	})
	fadeTitle = Theme.worldTitle(fadeFrame, "", 56)
	fadeTitle.Size = UDim2.new(1, 0, 0, 70)
	fadeTitle.Position = UDim2.fromScale(0, 0.42)
	fadeTitle.TextXAlignment = Enum.TextXAlignment.Center
	fadeLabel(fadeTitle, nil, 1)
end

return Hud
