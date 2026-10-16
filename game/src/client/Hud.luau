--!strict
-- The on-screen HUD: level + XP bar, coins, skills, inventory, and pop-up messages.
-- Built in code for now; swap for a proper UI library later.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Items = require(ReplicatedStorage.Shared.Items)

local Hud = {}

local PANEL_COLOR = Color3.fromRGB(24, 28, 38)
local ACCENT = Color3.fromRGB(110, 200, 90)
local GOLD = Color3.fromRGB(255, 210, 80)
local TOAST_COLORS = {
	info = Color3.fromRGB(60, 70, 90),
	good = Color3.fromRGB(46, 140, 70),
	bad = Color3.fromRGB(170, 60, 60),
	level = Color3.fromRGB(200, 150, 30),
}

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function label(parent: Instance, name: string, size: UDim2, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = textSize
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = ""
	l.Parent = parent
	return l
end

local gui: ScreenGui
local levelText: TextLabel
local xpFill: Frame
local xpText: TextLabel
local coinsText: TextLabel
local skillsText: TextLabel
local warzoneText: TextLabel
local inventoryList: Frame
local toastHolder: Frame
local raidPanel: Frame
local raidBagText: TextLabel

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Top-left stats panel
	local panel = Instance.new("Frame")
	panel.Name = "Stats"
	panel.Position = UDim2.fromOffset(12, 60)
	panel.Size = UDim2.fromOffset(230, 128)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.2
	panel.Parent = gui
	corner(panel, 10)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.Parent = panel

	levelText = label(panel, "Level", UDim2.new(1, 0, 0, 22), 20)

	local bar = Instance.new("Frame")
	bar.Name = "XPBar"
	bar.Position = UDim2.fromOffset(0, 26)
	bar.Size = UDim2.new(1, 0, 0, 14)
	bar.BackgroundColor3 = Color3.fromRGB(50, 56, 70)
	bar.Parent = panel
	corner(bar, 7)
	xpFill = Instance.new("Frame")
	xpFill.Name = "Fill"
	xpFill.Size = UDim2.fromScale(0, 1)
	xpFill.BackgroundColor3 = ACCENT
	xpFill.Parent = bar
	corner(xpFill, 7)
	xpText = label(bar, "Text", UDim2.fromScale(1, 1), 11)
	xpText.TextXAlignment = Enum.TextXAlignment.Center

	coinsText = label(panel, "Coins", UDim2.new(1, 0, 0, 20), 17)
	coinsText.Position = UDim2.fromOffset(0, 46)
	coinsText.TextColor3 = GOLD

	skillsText = label(panel, "Skills", UDim2.new(1, 0, 0, 18), 14)
	skillsText.Position = UDim2.fromOffset(0, 70)

	warzoneText = label(panel, "Warzone", UDim2.new(1, 0, 0, 18), 12)
	warzoneText.Position = UDim2.fromOffset(0, 94)
	warzoneText.TextColor3 = Color3.fromRGB(255, 140, 120)

	-- Inventory under the stats panel
	inventoryList = Instance.new("Frame")
	inventoryList.Name = "Inventory"
	inventoryList.Position = UDim2.fromOffset(12, 196)
	inventoryList.Size = UDim2.fromOffset(230, 0)
	inventoryList.AutomaticSize = Enum.AutomaticSize.Y
	inventoryList.BackgroundColor3 = PANEL_COLOR
	inventoryList.BackgroundTransparency = 0.35
	inventoryList.Parent = gui
	corner(inventoryList, 10)
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingLeft = UDim.new(0, 10)
	listPadding.PaddingTop = UDim.new(0, 6)
	listPadding.PaddingBottom = UDim.new(0, 6)
	listPadding.Parent = inventoryList
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.Name
	layout.Parent = inventoryList

	-- Warzone banner + raid bag, only shown during a raid
	raidPanel = Instance.new("Frame")
	raidPanel.Name = "Raid"
	raidPanel.AnchorPoint = Vector2.new(0.5, 0)
	raidPanel.Position = UDim2.new(0.5, 0, 0, 56)
	raidPanel.Size = UDim2.fromOffset(380, 0)
	raidPanel.AutomaticSize = Enum.AutomaticSize.Y
	raidPanel.BackgroundColor3 = Color3.fromRGB(90, 30, 30)
	raidPanel.BackgroundTransparency = 0.15
	raidPanel.Visible = false
	raidPanel.Parent = gui
	corner(raidPanel, 10)
	local raidPadding = Instance.new("UIPadding")
	raidPadding.PaddingLeft = UDim.new(0, 10)
	raidPadding.PaddingRight = UDim.new(0, 10)
	raidPadding.PaddingTop = UDim.new(0, 6)
	raidPadding.PaddingBottom = UDim.new(0, 6)
	raidPadding.Parent = raidPanel
	local raidLayout = Instance.new("UIListLayout")
	raidLayout.SortOrder = Enum.SortOrder.LayoutOrder
	raidLayout.Parent = raidPanel
	local raidTitle = label(raidPanel, "Title", UDim2.new(1, 0, 0, 22), 17)
	raidTitle.LayoutOrder = 1
	raidTitle.TextXAlignment = Enum.TextXAlignment.Center
	raidTitle.Text = "WARZONE - reach a green pad to extract"
	raidBagText = label(raidPanel, "Bag", UDim2.fromScale(1, 0), 14)
	raidBagText.LayoutOrder = 2
	raidBagText.AutomaticSize = Enum.AutomaticSize.Y
	raidBagText.TextWrapped = true
	raidBagText.TextXAlignment = Enum.TextXAlignment.Center

	-- Pop-up messages stack above the bottom of the screen
	toastHolder = Instance.new("Frame")
	toastHolder.Name = "Toasts"
	toastHolder.AnchorPoint = Vector2.new(0.5, 1)
	toastHolder.Position = UDim2.new(0.5, 0, 1, -110)
	toastHolder.Size = UDim2.fromOffset(320, 200)
	toastHolder.BackgroundTransparency = 1
	toastHolder.Parent = gui
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.Parent = toastHolder

	gui.Parent = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
end

function Hud.Render(state: any)
	levelText.Text = `Level {state.Level}`
	if state.Level >= state.MaxLevel then
		xpFill.Size = UDim2.fromScale(1, 1)
		xpText.Text = "MAX"
	else
		xpFill.Size = UDim2.fromScale(math.clamp(state.XP / state.XPToNext, 0, 1), 1)
		xpText.Text = `{state.XP} / {state.XPToNext} XP`
	end
	coinsText.Text = `Coins: {state.Coins}`

	local farming = state.Skills.Farming
	local combat = state.Skills.Combat
	skillsText.Text = `Farming Lv {farming and farming.Level or 1}  ·  Combat Lv {combat and combat.Level or 1}`

	warzoneText.Text = if state.Level >= state.WarzoneLevel
		then "Warzone unlocked!"
		else `Warzone unlocks at level {state.WarzoneLevel}`

	raidPanel.Visible = state.Raid.Active
	local bag = {}
	for id, count in state.Raid.Bag do
		local item = Items[id]
		table.insert(bag, `{item and item.Name or id} x{count}`)
	end
	raidBagText.Text = if #bag > 0
		then "Raid bag: " .. table.concat(bag, ", ")
		else "Raid bag empty - open chests, defeat monsters"

	for _, child in inventoryList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local any = false
	for id, count in state.Items do
		local item = Items[id]
		local row = label(inventoryList, item and item.Name or id, UDim2.new(1, 0, 0, 18), 14)
		row.Text = `{item and item.Name or id}  x{count}`
		any = true
	end
	if not any then
		local row = label(inventoryList, "Empty", UDim2.new(1, 0, 0, 18), 14)
		row.Text = "Inventory empty"
		row.TextTransparency = 0.4
	end
end

local toastCount = 0
function Hud.Toast(text: string, kind: string)
	toastCount += 1
	local toast = Instance.new("TextLabel")
	toast.LayoutOrder = toastCount
	toast.Size = UDim2.fromOffset(0, 34)
	toast.AutomaticSize = Enum.AutomaticSize.X
	toast.BackgroundColor3 = TOAST_COLORS[kind] or TOAST_COLORS.info
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = if kind == "level" then 20 else 16
	toast.Text = text
	toast.Parent = toastHolder
	corner(toast, 8)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = toast

	task.delay(if kind == "level" then 3.5 else 2, function()
		local fade = TweenInfo.new(0.4)
		TweenService:Create(toast, fade, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.4)
		toast:Destroy()
	end)
end

function Hud.Start()
	build()
end

return Hud
