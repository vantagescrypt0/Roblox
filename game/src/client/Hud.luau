--!strict
-- The always-on HUD: profile card (level badge, XP bar, coins, skills), Warzone status,
-- Bag/Island buttons, the raid banner, pop-up messages and big celebrations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Items = require(ReplicatedStorage.Shared.Items)
local Theme = require(script.Parent.UI.Theme)

local C = Theme.Color
local localPlayer = Players.LocalPlayer :: Player

local Hud = {}

export type Callbacks = { OnBag: () -> (), OnIsland: () -> () }

local levelNumber: TextLabel
local xpBar: Theme.Bar
local coinsText: TextLabel
local farmingChip: TextLabel
local combatChip: TextLabel
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

local TOAST_COLORS: { [string]: Color3 } = {
	info = C.Blue,
	good = C.Green,
	coins = C.Gold,
	bad = C.Red,
	level = C.Purple,
	levelup = C.Gold,
}
local TOAST_ICONS: { [string]: string } = {
	info = "💬",
	good = "✅",
	coins = "💰",
	bad = "⛔",
	level = "⭐",
	levelup = "⭐",
}

local function buildProfile(gui: ScreenGui)
	-- Bottom-left, so it never sits under Roblox's chat window (top-left)
	local card = Theme.panel(gui, UDim2.fromOffset(318, 104))
	card.AnchorPoint = Vector2.new(0, 1)
	card.Position = UDim2.new(0, 12, 1, -12)
	Theme.autoScale(card)

	-- Round gold level badge
	local badge = Theme.make("Frame", {
		Size = UDim2.fromOffset(78, 78),
		Position = UDim2.fromOffset(12, 13),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = card,
	})
	Theme.gradient(badge, Theme.lighten(C.Gold, 0.25), Theme.darken(C.Gold, 0.2))
	Theme.corner(badge, 999)
	Theme.stroke(badge, C.Stroke, 3)
	local lv = Theme.title(badge, "LV", 14)
	lv.Position = UDim2.fromOffset(0, 8)
	lv.TextXAlignment = Enum.TextXAlignment.Center
	levelNumber = Theme.title(badge, "1", 36)
	levelNumber.Position = UDim2.fromOffset(0, 24)
	levelNumber.Size = UDim2.new(1, 0, 0, 40)
	levelNumber.TextXAlignment = Enum.TextXAlignment.Center

	local name = Theme.title(card, localPlayer.DisplayName, 20)
	name.Position = UDim2.fromOffset(102, 10)
	name.Size = UDim2.new(1, -112, 0, 24)

	xpBar = Theme.bar(card, C.Green, UDim2.fromOffset(204, 20))
	xpBar.Track.Position = UDim2.fromOffset(102, 38)

	local row = Theme.make("Frame", {
		Position = UDim2.fromOffset(102, 66),
		Size = UDim2.fromOffset(210, 28),
		BackgroundTransparency = 1,
		Parent = card,
	})
	Theme.list(row, Enum.FillDirection.Horizontal, 6)
	coinsText = Theme.chip(row, "💰 0", C.Gold)
	coinsText.LayoutOrder = 1
	farmingChip = Theme.chip(row, "🌾 1", C.Green)
	farmingChip.LayoutOrder = 2
	combatChip = Theme.chip(row, "🗡️ 1", C.Red)
	combatChip.LayoutOrder = 3

	-- Warzone status sits just above the card
	warzoneChip = Theme.chip(card, "🔒 Warzone at Lv 10", C.Purple)
	-- Hidden until the Warzone opens in Town
	warzoneChip.Visible = false
	warzoneChip.AnchorPoint = Vector2.new(0, 1)
	warzoneChip.Position = UDim2.fromOffset(4, -8)
end

local function sideButton(
	parent: Instance,
	icon: string,
	label: string,
	color: Color3,
	order: number,
	onClick: () -> ()
)
	local button = Theme.button(parent, "", color, UDim2.fromOffset(74, 74), onClick)
	button.Holder.LayoutOrder = order
	local iconLabel = Theme.make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.fromOffset(0, 4),
		BackgroundTransparency = 1,
		Text = icon,
		TextSize = 32,
		Parent = button.Face,
	})
	iconLabel.Active = false
	local text = Theme.title(button.Face, label, 14)
	text.Position = UDim2.new(0, 0, 1, -22)
	text.TextXAlignment = Enum.TextXAlignment.Center
end

local function buildButtons(gui: ScreenGui, callbacks: Callbacks)
	local column = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(80, 170),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(column)
	Theme.list(column, Enum.FillDirection.Vertical, 10)
	sideButton(column, "🎒", "BAG", C.Blue, 1, callbacks.OnBag)
	sideButton(column, "🏝️", "ISLAND", C.Green, 2, callbacks.OnIsland)
end

local function buildRaidBanner(gui: ScreenGui)
	raidBanner = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(440, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Visible = false,
		Parent = gui,
	})
	Theme.gradient(raidBanner, Color3.fromRGB(200, 60, 60), Color3.fromRGB(120, 25, 35))
	Theme.corner(raidBanner, 14)
	Theme.stroke(raidBanner)
	Theme.padding(raidBanner, 12, 12, 8, 10)
	Theme.list(raidBanner, Enum.FillDirection.Vertical, 2)
	Theme.autoScale(raidBanner)
	local title = Theme.title(raidBanner, "🗡️ WARZONE", 26)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.LayoutOrder = 1
	local hint = Theme.text(
		raidBanner,
		"Reach a green pad to extract your loot",
		14,
		Theme.Font.Medium,
		Color3.fromRGB(255, 220, 220)
	)
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.LayoutOrder = 2
	raidBag = Theme.text(raidBanner, "", 16, Theme.Font.Title)
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
		Size = UDim2.fromOffset(600, 150),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	celebrationTitle = Theme.title(celebration, "LEVEL UP!", 72, C.Gold)
	celebrationTitle.Size = UDim2.new(1, 0, 0, 84)
	celebrationTitle.TextXAlignment = Enum.TextXAlignment.Center
	celebrationSub = Theme.title(celebration, "", 34)
	celebrationSub.Position = UDim2.fromOffset(0, 88)
	celebrationSub.Size = UDim2.new(1, 0, 0, 40)
	celebrationSub.TextXAlignment = Enum.TextXAlignment.Center
	Theme.make("UIScale", { Parent = celebration })
end

local celebrateToken = 0
function Hud.Celebrate(title: string, subtitle: string, color: Color3?)
	celebrateToken += 1
	local token = celebrateToken
	celebrationTitle.Text = title
	celebrationTitle.TextColor3 = color or C.Gold
	celebrationSub.Text = subtitle
	celebrationTitle.TextTransparency = 0
	celebrationSub.TextTransparency = 0
	celebration.Visible = true
	local scale = celebration:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 0.3
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	task.delay(2.2, function()
		if token ~= celebrateToken then
			return
		end
		local fade = TweenInfo.new(0.5)
		TweenService:Create(celebrationTitle, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(celebrationSub, fade, { TextTransparency = 1 }):Play()
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
		xpBar.Set(1, "MAX LEVEL")
	else
		xpBar.Set(state.XP / state.XPToNext, `{state.XP} / {state.XPToNext} XP`)
	end

	coinsText.Text = `💰 {Theme.formatNumber(state.Coins)}`
	if lastCoins and state.Coins ~= lastCoins then
		Theme.pop(coinsText, 1.2)
	end
	lastCoins = state.Coins

	farmingChip.Text = `🌾 {state.Skills.Farming and state.Skills.Farming.Level or 1}`
	combatChip.Text = `🗡️ {state.Skills.Combat and state.Skills.Combat.Level or 1}`

	if state.Level >= state.WarzoneLevel then
		warzoneChip.Text = "🗡️ Warzone open!"
	else
		warzoneChip.Text = `🔒 Warzone at Lv {state.WarzoneLevel}`
	end

	raidBanner.Visible = state.Raid.Active
	local bag = {}
	for id, count in state.Raid.Bag do
		local item = Items[id]
		table.insert(bag, `{item and item.Icon or ""} {count}`)
	end
	raidBag.Text = if #bag > 0 then table.concat(bag, "   ") else "Bag empty - open chests, beat monsters"
end

local toastCount = 0
function Hud.Toast(text: string, kind: string)
	if kind == "levelup" then
		Hud.Celebrate("LEVEL UP!", text, C.Gold)
		return
	end
	toastCount += 1
	local color = TOAST_COLORS[kind] or C.Blue
	local toast = Theme.make("Frame", {
		LayoutOrder = toastCount,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 40),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = toastHolder,
	})
	Theme.gradient(toast, Theme.lighten(C.Panel, 0.12), C.Panel)
	Theme.corner(toast, 999)
	Theme.stroke(toast, color, 2.5)
	Theme.padding(toast, 6, 16, 0, 0)
	Theme.list(toast, Enum.FillDirection.Horizontal, 8)
	local icon = Theme.make("TextLabel", {
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = color,
		Text = TOAST_ICONS[kind] or "💬",
		TextSize = 16,
		LayoutOrder = 1,
		Parent = toast,
	})
	Theme.corner(icon, 999)
	local label = Theme.title(toast, text, 18)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, 30)
	label.LayoutOrder = 2
	label.TextTruncate = Enum.TextTruncate.None
	Theme.pop(toast, 0.6)

	task.delay(if kind == "level" then 3.5 else 2.2, function()
		local fade = TweenInfo.new(0.35)
		TweenService:Create(toast, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(icon, fade, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		local stroke = toast:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
		end
		local labelStroke = label:FindFirstChildOfClass("UIStroke")
		if labelStroke then
			TweenService:Create(labelStroke, fade, { Transparency = 1 }):Play()
		end
		task.wait(0.35)
		toast:Destroy()
	end)
end

-- Purple fade in and out while a portal moves you
function Hud.Travel(destination: string)
	local title = if destination == "Town" then "Town" else "Your Island"
	fadeTitle.Text = title
	local quick = TweenInfo.new(0.3)
	TweenService:Create(fadeFrame, quick, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(fadeTitle, quick, { TextTransparency = 0 }):Play()
	local stroke = fadeTitle:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, quick, { Transparency = 0 }):Play()
	end
	task.delay(0.9, function()
		local slow = TweenInfo.new(0.6)
		TweenService:Create(fadeFrame, slow, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(fadeTitle, slow, { TextTransparency = 1 }):Play()
		if stroke then
			TweenService:Create(stroke, slow, { Transparency = 1 }):Play()
		end
	end)
end

function Hud.Start(callbacks: Callbacks)
	local gui = Theme.screen("HUD", 1)
	buildProfile(gui)
	buildButtons(gui, callbacks)
	buildRaidBanner(gui)
	buildToasts(gui)
	buildCelebration(gui)

	-- Full-screen fade for portal travel
	local fadeGui = Theme.screen("Fade", 20)
	fadeGui.IgnoreGuiInset = true
	fadeFrame = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(30, 10, 50),
		BackgroundTransparency = 1,
		Parent = fadeGui,
	})
	fadeTitle = Theme.title(fadeFrame, "", 56)
	fadeTitle.Size = UDim2.new(1, 0, 0, 70)
	fadeTitle.Position = UDim2.fromScale(0, 0.42)
	fadeTitle.TextXAlignment = Enum.TextXAlignment.Center
	fadeTitle.TextTransparency = 1
	local fadeStroke = fadeTitle:FindFirstChildOfClass("UIStroke")
	if fadeStroke then
		fadeStroke.Transparency = 1
	end
end

return Hud
