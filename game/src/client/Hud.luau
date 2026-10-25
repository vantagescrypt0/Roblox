--!strict
-- The always-on HUD: profile card (level badge, XP bar, coins; click it for the Skills
-- window), Warzone status, Bag/Island/Skills buttons, the raid banner, pop-up messages and
-- big celebrations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Items = require(ReplicatedStorage.Shared.Items)
local Theme = require(script.Parent.UI.Theme)

local C = Theme.Color
local localPlayer = Players.LocalPlayer :: Player

local Hud = {}

export type Callbacks = { OnBag: () -> (), OnIsland: () -> (), OnSkills: () -> () }

local levelNumber: TextLabel
local xpBar: Theme.Bar
local coinsText: TextLabel
local coinsChip: Frame
local warzoneChip: TextLabel
local raidBanner: Frame
local raidBag: TextLabel
local toastHolder: Frame
local celebration: Frame
local celebrationTitle: TextLabel
local celebrationSub: TextLabel
local fadeFrame: Frame
local fadeTitle: TextLabel
local lastCoins: number? = nil
local lastLevel: number? = nil

-- The colored edge on each kind of message
local TOAST_COLORS: { [string]: Color3 } = {
	info = C.Blue,
	good = C.Leaf,
	coins = C.Ochre,
	bad = C.Red,
	level = C.Purple,
	levelup = C.Gold,
}

local function buildProfile(gui: ScreenGui, onSkills: () -> ())
	-- Bottom-left, so it never sits under Roblox's chat window (top-left)
	local card = Theme.panel(gui, UDim2.fromOffset(316, 100))
	card.AnchorPoint = Vector2.new(0, 1)
	card.Position = UDim2.new(0, 14, 1, -14)
	Theme.autoScale(card)
	-- The whole card opens the Skills window
	local open = Theme.make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Parent = card,
	})
	open.Activated:Connect(onSkills)

	-- Level badge: a round wooden plaque with a gold rim
	local badge = Theme.make("Frame", {
		Size = UDim2.fromOffset(74, 74),
		Position = UDim2.fromOffset(12, 13),
		BackgroundColor3 = C.WoodLight,
		Parent = card,
	})
	Theme.corner(badge, 999)
	Theme.stroke(badge, C.Gold, 3)
	local lv = Theme.text(badge, "LEVEL", 10, Theme.Font.Bold, C.Gold)
	lv.Position = UDim2.fromOffset(0, 11)
	lv.TextXAlignment = Enum.TextXAlignment.Center
	-- Numbers in the rounded font: Fondamento's old-style digits are hard to read
	levelNumber = Theme.text(badge, "1", 32, Theme.Font.Bold, C.Cream)
	levelNumber.Position = UDim2.fromOffset(0, 24)
	levelNumber.Size = UDim2.new(1, 0, 0, 36)
	levelNumber.TextXAlignment = Enum.TextXAlignment.Center

	local name = Theme.title(card, localPlayer.DisplayName, 22)
	name.Position = UDim2.fromOffset(98, 6)
	name.Size = UDim2.new(1, -108, 0, 26)

	xpBar = Theme.bar(card, C.Leaf, UDim2.fromOffset(206, 18))
	xpBar.Track.Position = UDim2.fromOffset(98, 36)

	local row = Theme.make("Frame", {
		Position = UDim2.fromOffset(98, 62),
		Size = UDim2.fromOffset(212, 30),
		BackgroundTransparency = 1,
		Parent = card,
	})
	Theme.list(row, Enum.FillDirection.Horizontal, 5)
	local coins = Theme.iconChip(row, "0")
	coins.Frame.LayoutOrder = 1
	Theme.coin(coins.Icon)
	coinsText = coins.Label
	coinsChip = coins.Frame
	-- Skill levels live in the Skills window; this hints the card opens it
	local skills = Theme.chip(row, "Skills", C.WoodLight)
	skills.LayoutOrder = 2

	-- Warzone status sits just above the card
	warzoneChip = Theme.chip(card, "Warzone at level 10", C.Purple)
	-- Hidden until the Warzone opens in Town
	warzoneChip.Visible = false
	warzoneChip.AnchorPoint = Vector2.new(0, 1)
	warzoneChip.Position = UDim2.fromOffset(0, -10)
end

-- Wooden sign button on the left edge
local function sideButton(parent: Instance, label: string, order: number, onClick: () -> ())
	local button = Theme.button(parent, label, C.WoodLight, UDim2.fromOffset(104, 46), onClick)
	button.Holder.LayoutOrder = order
	button.Label.FontFace = Theme.Font.Title
	button.Label.TextSize = 22
end

local function buildButtons(gui: ScreenGui, callbacks: Callbacks)
	local column = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(110, 160),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(column)
	Theme.list(column, Enum.FillDirection.Vertical, 10)
	sideButton(column, "Bag", 1, callbacks.OnBag)
	sideButton(column, "Island", 2, callbacks.OnIsland)
	sideButton(column, "Skills", 3, callbacks.OnSkills)
end

local function buildRaidBanner(gui: ScreenGui)
	raidBanner = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(440, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(122, 44, 32),
		Visible = false,
		Parent = gui,
	})
	Theme.corner(raidBanner, 7)
	Theme.stroke(raidBanner, C.WoodEdge, 4)
	Theme.padding(raidBanner, 12, 12, 8, 10)
	Theme.list(raidBanner, Enum.FillDirection.Vertical, 2)
	Theme.autoScale(raidBanner)
	local title = Theme.title(raidBanner, "Warzone", 28, C.Gold)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.LayoutOrder = 1
	local hint = Theme.text(raidBanner, "Reach a green pad to extract your loot", 14, Theme.Font.Medium, C.Cream)
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.LayoutOrder = 2
	raidBag = Theme.text(raidBanner, "", 16, Theme.Font.Bold, C.Cream)
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
		xpBar.Set(state.XP / state.XPToNext, `{state.XP} / {state.XPToNext} XP`)
	end

	coinsText.Text = Theme.formatNumber(state.Coins)
	if lastCoins and state.Coins ~= lastCoins then
		Theme.pop(coinsChip, 1.15)
	end
	lastCoins = state.Coins

	if state.Level >= state.WarzoneLevel then
		warzoneChip.Text = "Warzone open!"
	else
		warzoneChip.Text = `Warzone at level {state.WarzoneLevel}`
	end

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
	end
	toastCount += 1
	local color = TOAST_COLORS[kind] or C.Blue
	-- A paper tag with a colored edge on the left
	local toast = Theme.make("Frame", {
		LayoutOrder = toastCount,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 38),
		BackgroundColor3 = C.Parchment,
		Parent = toastHolder,
	})
	Theme.corner(toast, 6)
	local stroke = Theme.stroke(toast, C.Wood, 2.5)
	Theme.padding(toast, 0, 14, 0, 0)
	Theme.list(toast, Enum.FillDirection.Horizontal, 10)
	local edge = Theme.make("Frame", {
		Size = UDim2.fromOffset(8, 38),
		BackgroundColor3 = color,
		LayoutOrder = 1,
		Parent = toast,
	})
	Theme.corner(edge, 5)
	local label = Theme.text(toast, text, 17, Theme.Font.Bold)
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
	fadeTitle.Text = if destination == "Town" then "Travelling to Town..." else "Heading home..."
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
	buildProfile(gui, callbacks.OnSkills)
	buildButtons(gui, callbacks)
	buildRaidBanner(gui)
	buildToasts(gui)
	buildCelebration(gui)

	-- Full-screen fade for portal travel
	local fadeGui = Theme.screen("Fade", 20)
	fadeGui.IgnoreGuiInset = true
	fadeFrame = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 38, 42),
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
