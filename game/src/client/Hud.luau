--!strict
-- The always-on HUD, in the Night Glass look (Glass.luau): coins and a card with your level, name
-- and XP in the bottom-left corner (click it for the Skills window), the season's countdown
-- (when it has an end date), Warzone status, a Menu button in the corner that pops up the
-- Bag/Island/Skills/Challenges/Inbox buttons (badges count the mail waiting), pop-up messages
-- and big celebrations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Places = require(ReplicatedStorage.Shared.Places)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Glass = require(script.Parent.UI.Glass)
local ItemIcon = require(script.Parent.UI.ItemIcon)
local Sfx = require(script.Parent.UI.Sfx)
local Theme = require(script.Parent.UI.Theme)
local Window = require(script.Parent.UI.Window)

local C = Glass.Color
local localPlayer = Players.LocalPlayer :: Player

local Hud = {}

export type Callbacks = {
	OnBag: () -> (),
	OnIsland: () -> (),
	OnSkills: () -> (),
	OnChallenges: () -> (),
	OnInbox: () -> (),
	OnVisit: () -> (),
	OnSettings: () -> (),
	OnKits: () -> (),
	OnBoosts: () -> (),
}

local levelNumber: TextLabel
local xpBar: Theme.Bar
local xpText: TextLabel
local coinsText: TextLabel
local coinsRow: Frame
local warzoneChip: TextLabel
local seasonChip: TextLabel
local season: number? = nil
local toastHolder: Frame
local celebration: Frame
local celebrationTitle: TextLabel
local celebrationSub: TextLabel
local fadeFrame: Frame
local fadeTitle: TextLabel
local inboxBadge: TextLabel
local menuBadge: TextLabel
local menuFace: TextButton
local menuStroke: UIStroke
local menuPanel: Frame
local menuOpen = false
local kitsEntry: TextButton
local lastCoins: number? = nil
local lastLevel: number? = nil
local lastMail: number? = nil

-- The sound each kind of message makes ("info" makes none)
local TOAST_SOUNDS: { [string]: string } = {
	good = "Pop",
	coins = "Coins",
	bad = "Error",
	level = "Chime",
	harvest = "Harvest",
	craft = "Craft",
	smelt = "Smelt",
	timber = "TreeFall",
}

-- The colored edge on each kind of message
local TOAST_COLORS: { [string]: Color3 } = {
	info = C.Accent,
	good = C.Green,
	coins = C.Gold,
	bad = C.Red,
	level = C.Purple,
	levelup = C.Gold,
	harvest = C.Green,
	craft = C.Green,
	smelt = C.Hunger,
	timber = C.Green,
}

local BUTTON = 62 -- the Menu button and the buttons in its panel are square
local CARD_WIDTH = 270
local STATUS_HEIGHT = 98 -- the coins over the card
local TOUCH_GUI_WAIT = 30 -- seconds to wait for Roblox's touch controls to appear

-- Coins over a card with your level, name and XP, right of the Menu
local function buildStatus(group: Frame, onSkills: () -> ())
	local holder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, BUTTON + 10, 1, 0),
		Size = UDim2.fromOffset(CARD_WIDTH, STATUS_HEIGHT),
		BackgroundTransparency = 1,
		Parent = group,
	})

	-- Coins: a coin and an outlined number straight over the world
	coinsRow = Theme.make("Frame", {
		Size = UDim2.fromOffset(CARD_WIDTH, 30),
		BackgroundTransparency = 1,
		Parent = holder,
	})
	Theme.list(coinsRow, Enum.FillDirection.Horizontal, 6)
	local coinIcon = Theme.make("Frame", {
		Size = UDim2.fromOffset(28, 28),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = coinsRow,
	})
	Theme.coin(coinIcon)
	coinsText = Glass.worldText(coinsRow, "0", 22, Glass.Font.Bold)
	coinsText.AutomaticSize = Enum.AutomaticSize.X
	coinsText.Size = UDim2.fromOffset(0, 30)
	coinsText.TextTruncate = Enum.TextTruncate.None
	coinsText.LayoutOrder = 2

	-- The card opens the Skills window
	local card = Glass.card(holder, UDim2.fromOffset(CARD_WIDTH, BUTTON), UDim2.new(0, 0, 1, -BUTTON))
	local badge = Theme.make("Frame", {
		Position = UDim2.fromOffset(9, 9),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = C.Gold,
		Parent = card,
	})
	Theme.corner(badge, 999)
	levelNumber = Glass.text(badge, "1", 21, Glass.Font.Bold, C.Well)
	levelNumber.Size = UDim2.fromScale(1, 1)
	levelNumber.TextXAlignment = Enum.TextXAlignment.Center

	local name = Glass.text(card, localPlayer.DisplayName, 16, Glass.Font.Bold)
	name.Position = UDim2.fromOffset(62, 8)
	name.Size = UDim2.fromOffset(100, 20)
	xpText = Glass.text(card, "", 12, Glass.Font.Body, C.Muted)
	xpText.AnchorPoint = Vector2.new(1, 0)
	xpText.Position = UDim2.new(1, -12, 0, 10)
	xpText.Size = UDim2.fromOffset(110, 16)
	xpText.TextXAlignment = Enum.TextXAlignment.Right

	xpBar = Glass.bar(card, C.Accent, UDim2.fromOffset(CARD_WIDTH - 74, 12), false)
	xpBar.Track.Position = UDim2.fromOffset(62, 35)

	local open = Theme.make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Parent = card,
	})
	open.Activated:Connect(onSkills)

	-- Warzone status sits just above the coins
	warzoneChip = Glass.chip(holder, "Warzone at level 10", C.Purple)
	-- Hidden until the Warzone opens in Town
	warzoneChip.Visible = false
	warzoneChip.AnchorPoint = Vector2.new(0, 1)
	warzoneChip.Position = UDim2.fromOffset(0, -8)

	-- The season's countdown, above the right end (hidden while it has no end date)
	seasonChip = Glass.chip(holder, "", C.Hunger)
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

-- A square glass button: a picture with a one-word label under it. Returns the button and the
-- frame to put its picture in.
local function squareButton(parent: Instance, label: string, onClick: () -> ()): (Glass.Button, Frame)
	local button = Glass.button(parent, "", UDim2.fromOffset(BUTTON, BUTTON), onClick)
	button.Stroke.Color = C.Edge
	button.Stroke.Transparency = 0.84
	local picture = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(BUTTON - 28, BUTTON - 28),
		BackgroundTransparency = 1,
		Parent = button.Face,
	})
	local text = Glass.text(button.Face, label, 13, Glass.Font.Bold)
	text.AnchorPoint = Vector2.new(0.5, 1)
	text.Position = UDim2.new(0.5, 0, 1, -3)
	text.Size = UDim2.new(1, -4, 0, 16)
	text.TextXAlignment = Enum.TextXAlignment.Center
	text.TextTruncate = Enum.TextTruncate.None
	text.TextScaled = true
	text.ZIndex = 2
	Theme.make("UITextSizeConstraint", { MaxTextSize = 13, Parent = text })
	return button, picture
end

-- Three bars
local function drawMenuBars(picture: Frame)
	for row = 0, 2 do
		local bar = Theme.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, (row - 1) * 9),
			Size = UDim2.new(0.8, 0, 0, 4),
			BackgroundColor3 = C.Ink,
			Parent = picture,
		})
		Theme.corner(bar, 2)
	end
end

-- Three sliders, for Settings
local function drawSliders(picture: Frame)
	for row = 0, 2 do
		local bar = Theme.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, (row - 1) * 10),
			Size = UDim2.new(0.86, 0, 0, 3),
			BackgroundColor3 = C.Ink,
			Parent = picture,
		})
		Theme.corner(bar, 2)
		local knob = Theme.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(({ 0.3, 0.72, 0.45 })[row + 1], 0.5),
			Size = UDim2.fromOffset(9, 9),
			BackgroundColor3 = C.Blue,
			Parent = bar,
		})
		Theme.corner(knob, 5)
	end
end

local function setMenu(open: boolean)
	menuOpen = open
	menuPanel.Visible = open
	menuStroke.Color = if open then C.Accent else C.Edge
	menuStroke.Transparency = if open then 0 else 0.84
	if open then
		Theme.pop(menuPanel, 0.85)
	end
end

-- The Menu button in the bottom-left corner. It pops up a small panel above it with the
-- Bag, Island, Skills, Challenges and Inbox buttons, so they're only on screen when wanted.
local function buildMenu(group: Frame, callbacks: Callbacks)
	local menu, picture = squareButton(group, "Menu", function()
		setMenu(not menuOpen)
	end)
	menuFace = menu.Face
	menuStroke = menu.Stroke
	menuFace.AnchorPoint = Vector2.new(0, 1)
	menuFace.Position = UDim2.fromScale(0, 1)
	drawMenuBars(picture)
	-- The menu's own badge counts the mail waiting too, so it shows while the menu is shut
	menuBadge = Theme.badge(menuFace)

	local columns, rows, gap, pad = 5, 2, 8, 12
	menuPanel = Glass.panel(
		group,
		UDim2.fromOffset(columns * BUTTON + (columns - 1) * gap + pad * 2, rows * BUTTON + (rows - 1) * gap + pad * 2)
	)
	menuPanel.AnchorPoint = Vector2.new(0, 1)
	-- Above the coins, so they stay in sight while the menu is open
	menuPanel.Position = UDim2.new(0, 0, 1, -STATUS_HEIGHT - 8)
	menuPanel.Visible = false
	menuPanel.ZIndex = 4
	Theme.padding(menuPanel, pad)
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(BUTTON, BUTTON),
		CellPadding = UDim2.fromOffset(gap, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = menuPanel,
	})

	local function entry(order: number, label: string, icon: string?, onClick: () -> ()): TextButton
		local button, slot = squareButton(menuPanel, label, function()
			setMenu(false)
			onClick()
		end)
		button.Face.LayoutOrder = order
		if icon then
			ItemIcon.create(slot, icon, UDim2.fromScale(1, 1))
		else
			drawSliders(slot)
		end
		return button.Face
	end
	entry(1, "Bag", "IconBag", callbacks.OnBag)
	entry(2, "Island", "Grass", callbacks.OnIsland)
	entry(3, "Skills", "IronPickaxe", callbacks.OnSkills)
	entry(4, "Challenges", "IconTrophy", callbacks.OnChallenges)
	entry(5, "Boosts", "BoostCrystal", callbacks.OnBoosts)
	local inbox = entry(6, "Inbox", "IconMail", callbacks.OnInbox)
	entry(7, "Visit", "Sign", callbacks.OnVisit)
	entry(8, "Settings", nil, callbacks.OnSettings)
	-- Hidden unless the server says the Crate Keeper Kit is on sale to you, or you own it
	kitsEntry = entry(9, "Kits", "LootCrate", callbacks.OnKits)
	kitsEntry.Visible = false
	-- Red badge on the corner: how many letters are waiting
	inboxBadge = Theme.badge(inbox)

	-- A click or tap on the game itself (not on a button) shuts the menu
	UserInputService.InputBegan:Connect(function(input, processed)
		local press = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		if menuOpen and press and not processed then
			setMenu(false)
		end
	end)
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
	celebrationTitle = Glass.worldText(celebration, "Level Up!", 68, Glass.Font.Title, C.Gold)
	celebrationTitle.Size = UDim2.new(1, 0, 0, 86)
	celebrationTitle.TextXAlignment = Enum.TextXAlignment.Center
	celebrationSub = Glass.worldText(celebration, "", 32, Glass.Font.Bold)
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
-- A big title across the screen (level ups, admin announcements); `seconds` is how long it stays, 2.2 if not given
function Hud.Celebrate(title: string, subtitle: string, color: Color3?, seconds: number?)
	celebrateToken += 1
	local token = celebrateToken
	Sfx.play("Stinger")
	Sfx.play("Sparkle")
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
	task.delay(seconds or 2.2, function()
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
		xpBar.Set(1)
		xpText.Text = "Max level"
	else
		xpBar.Set(state.XP / state.XPToNext)
		xpText.Text = `{Theme.formatNumber(state.XP)} / {Theme.formatNumber(state.XPToNext)} XP`
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
		Sfx.play("Mail")
		Theme.pop(menuBadge, 1.5)
	end
	lastMail = mail
end

local toastCount = 0
function Hud.ShowKits(visible: boolean)
	kitsEntry.Visible = visible
end

function Hud.Toast(text: string, kind: string)
	if kind == "levelup" then
		Hud.Celebrate("Level Up!", text, C.Gold)
		return
	elseif kind == "season" then
		Hud.Celebrate("New Season!", text, C.Gold)
		return
	end
	toastCount += 1
	local sound = TOAST_SOUNDS[kind]
	if sound then
		Sfx.play(sound)
	end
	local color = TOAST_COLORS[kind] or C.Accent
	-- A dark glass tag with an edge and a dot in the message's colour
	local toast = Theme.make("Frame", {
		LayoutOrder = toastCount,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 38),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.06,
		Parent = toastHolder,
	})
	Theme.corner(toast, 11)
	local stroke = Theme.stroke(toast, color, 1, 0.45)
	Theme.padding(toast, 12, 16, 0, 0)
	Theme.list(toast, Enum.FillDirection.Horizontal, 10)
	local edge = Theme.make("Frame", {
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = color,
		LayoutOrder = 1,
		Parent = toast,
	})
	Theme.corner(edge, 999)
	local label = Glass.text(toast, text, 17, Glass.Font.Bold)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, 30)
	label.LayoutOrder = 2
	label.TextTruncate = Enum.TextTruncate.None
	Theme.pop(toast, 0.7)

	task.delay(if kind == "level" then 3.5 else 2.2, function()
		local fade = TweenInfo.new(0.35)
		TweenService:Create(toast, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(edge, fade, { BackgroundTransparency = 1 }):Play()
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
	fadeTitle.Text = if destination == "Visit"
		then "Heading to their island..."
		elseif destination == "Island" or not name then "Heading home..."
		else `Traveling to {name}...`
	setFade(true, TweenInfo.new(0.35))
	Sfx.play("Travel")
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
		Position = UDim2.new(0, Theme.edge(), 1, -14),
		Size = UDim2.fromOffset(BUTTON + 10 + CARD_WIDTH, STATUS_HEIGHT),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(group)
	Window.hideWhenCovered(group)
	buildMenu(group, callbacks)
	buildStatus(group, callbacks.OnSkills)
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
	fadeGui.ScreenInsets = Enum.ScreenInsets.None
	fadeFrame = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 1,
		Parent = fadeGui,
	})
	fadeTitle = Glass.worldText(fadeFrame, "", 48, Glass.Font.Title)
	fadeTitle.Size = UDim2.new(1, 0, 0, 70)
	fadeTitle.Position = UDim2.fromScale(0, 0.42)
	fadeTitle.TextXAlignment = Enum.TextXAlignment.Center
	fadeLabel(fadeTitle, nil, 1)

	-- Roblox's jump button and thumbstick go out to the real edges with everything else
	if Theme.isPhone() then
		task.spawn(function()
			local touch = localPlayer:WaitForChild("PlayerGui"):WaitForChild("TouchGui", TOUCH_GUI_WAIT)
			if touch and touch:IsA("ScreenGui") then
				touch.ScreenInsets = Enum.ScreenInsets.None
			end
		end)
	end
end

return Hud
