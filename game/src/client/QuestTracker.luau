--!strict
-- Shows the current beginner quest on the right side of the screen and outlines the
-- object on your island it's about, so new players always know where to go.

local Players = game:GetService("Players")

local QuestTracker = {}

local localPlayer = Players.LocalPlayer :: Player

local panel: Frame
local titleText: TextLabel
local questText: TextLabel
local progressText: TextLabel
local highlight: Highlight

local function makeLabel(parent: Instance, height: number, textSize: number, font: Enum.Font): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, height)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = font
	l.TextSize = textSize
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Quests"
	gui.ResetOnSpawn = false

	panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -12, 0, 190)
	panel.Size = UDim2.fromOffset(240, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = Color3.fromRGB(30, 40, 70)
	panel.BackgroundTransparency = 0.15
	panel.Visible = false
	panel.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = panel

	titleText = makeLabel(panel, 18, 13, Enum.Font.GothamBold)
	titleText.LayoutOrder = 1
	titleText.TextColor3 = Color3.fromRGB(255, 215, 90)
	questText = makeLabel(panel, 0, 17, Enum.Font.GothamBold)
	questText.LayoutOrder = 2
	questText.AutomaticSize = Enum.AutomaticSize.Y
	progressText = makeLabel(panel, 18, 14, Enum.Font.Gotham)
	progressText.LayoutOrder = 3

	highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 215, 90)
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.fromRGB(255, 235, 140)
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = false
	highlight.Parent = gui

	gui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local function findOnMyIsland(name: string): Instance?
	local islands = workspace:FindFirstChild("Islands")
	local island = islands and islands:FindFirstChild(`Island_{localPlayer.UserId}`)
	return island and island:FindFirstChild(name, true)
end

function QuestTracker.Render(state: any)
	local quest = state.Quest
	-- Hide during a raid so the Warzone screen stays clear
	if not quest or state.Raid.Active then
		panel.Visible = false
		highlight.Enabled = false
		return
	end
	panel.Visible = true
	titleText.Text = `QUEST {quest.Number}/{quest.Total}`
	questText.Text = quest.Text
	progressText.Text = `{quest.Progress} / {quest.Target}`

	local target = if quest.Highlight then findOnMyIsland(quest.Highlight) else nil
	highlight.Adornee = target
	highlight.Enabled = target ~= nil
end

function QuestTracker.Start()
	build()
end

return QuestTracker
