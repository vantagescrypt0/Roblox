--!strict
-- Shows the current beginner quest on the right side of the screen and outlines the
-- object on your island it's about, so new players always know where to go.

local Players = game:GetService("Players")

local Theme = require(script.Parent.UI.Theme)

local C = Theme.Color
local localPlayer = Players.LocalPlayer :: Player

local QuestTracker = {}

local card: Frame
local header: TextLabel
local questText: TextLabel
local bar: Theme.Bar
local highlight: Highlight
local lastQuest: number? = nil

local function build()
	local gui = Theme.screen("Quests", 1)

	card = Theme.panel(gui, UDim2.fromOffset(270, 0))
	-- Right side, below Roblox's player list
	card.AnchorPoint = Vector2.new(1, 0.5)
	card.Position = UDim2.new(1, -12, 0.5, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Visible = false
	Theme.autoScale(card)
	Theme.padding(card, 12, 12, 0, 12)
	Theme.list(card, Enum.FillDirection.Vertical, 6)

	-- Gold ribbon header
	local ribbon = Theme.make("Frame", {
		Size = UDim2.new(1, 24, 0, 32),
		Position = UDim2.fromOffset(-12, 0),
		LayoutOrder = 1,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = card,
	})
	Theme.gradient(ribbon, Theme.lighten(C.Gold, 0.2), Theme.darken(C.Gold, 0.1))
	Theme.corner(ribbon, 14)
	header = Theme.title(ribbon, "📜 QUEST", 18)
	header.Size = UDim2.fromScale(1, 1)
	header.TextXAlignment = Enum.TextXAlignment.Center

	questText = Theme.title(card, "", 20)
	questText.LayoutOrder = 2
	questText.TextWrapped = true
	questText.TextTruncate = Enum.TextTruncate.None
	questText.AutomaticSize = Enum.AutomaticSize.Y
	questText.Size = UDim2.new(1, 0, 0, 24)

	bar = Theme.bar(card, C.Gold, UDim2.new(1, 0, 0, 20))
	bar.Track.LayoutOrder = 3

	highlight = Theme.make("Highlight", {
		FillColor = C.Gold,
		FillTransparency = 0.75,
		OutlineColor = Theme.lighten(C.Gold, 0.4),
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		Enabled = false,
		Parent = gui,
	})
end

local function findOnMyIsland(name: string): Instance?
	local islands = workspace:FindFirstChild("Islands")
	local island = islands and islands:FindFirstChild(`Island_{localPlayer.UserId}`)
	return island and island:FindFirstChild(name, true)
end

function QuestTracker.Render(state: any)
	local quest = state.Quest
	-- Hidden during a raid so the Warzone screen stays clear
	if not quest or state.Raid.Active then
		card.Visible = false
		highlight.Enabled = false
		return
	end
	card.Visible = true
	header.Text = `📜 QUEST {quest.Number}/{quest.Total}`
	questText.Text = quest.Text
	bar.Set(quest.Progress / quest.Target, `{quest.Progress} / {quest.Target}`)
	if lastQuest and lastQuest ~= quest.Number then
		Theme.pop(questText, 1.25)
	end
	lastQuest = quest.Number

	-- The island can be rebuilt (expansion), so look the target up every time
	local target = if quest.Highlight then findOnMyIsland(quest.Highlight) else nil
	highlight.Adornee = target
	highlight.Enabled = target ~= nil
end

function QuestTracker.Start()
	build()
end

return QuestTracker
