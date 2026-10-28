--!strict
-- Shows the current beginner quest on the right side of the screen and outlines the
-- object on your island it's about, so new players always know where to go.

local Players = game:GetService("Players")

local Theme = require(script.Parent.UI.Theme)

local C = Theme.Color
local localPlayer = Players.LocalPlayer :: Player

local HEADER = 34

local QuestTracker = {}

local card: Frame
local header: TextLabel
local questText: TextLabel
local bar: Theme.Bar
local highlight: Highlight
local highlightName: string? = nil -- what the current quest outlines on your island
local lastQuest: number? = nil

local function build()
	local gui = Theme.screen("Quests", 1)

	card = Theme.panel(gui, UDim2.fromOffset(270, 0))
	-- Right side, below Roblox's player list
	card.AnchorPoint = Vector2.new(1, 0.5)
	card.Position = UDim2.new(1, -14, 0.5, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Visible = false
	Theme.autoScale(card)

	Theme.header(card, "Quest", HEADER)
	-- Quest number on the right of the title bar
	header = Theme.text(card, "", 14, Theme.Font.Bold, C.Gold)
	header.AnchorPoint = Vector2.new(1, 0)
	header.Position = UDim2.new(1, -14, 0, 0)
	header.Size = UDim2.fromOffset(80, HEADER - 3)
	header.TextXAlignment = Enum.TextXAlignment.Right
	header.ZIndex = 3

	local body = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = card,
	})
	Theme.padding(body, 12, 12, 10, 12)
	Theme.list(body, Enum.FillDirection.Vertical, 8)

	questText = Theme.text(body, "", 17, Theme.Font.Bold)
	questText.LayoutOrder = 1
	questText.TextWrapped = true
	questText.TextTruncate = Enum.TextTruncate.None
	questText.AutomaticSize = Enum.AutomaticSize.Y
	questText.Size = UDim2.new(1, 0, 0, 20)

	bar = Theme.bar(body, C.Ochre, UDim2.new(1, 0, 0, 18))
	bar.Track.LayoutOrder = 2

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

-- The island can be rebuilt (expansion), so look the target up every time
local function aimHighlight()
	local target = if highlightName then findOnMyIsland(highlightName) else nil
	highlight.Adornee = target
	highlight.Enabled = target ~= nil
end

function QuestTracker.Render(state: any)
	local quest = state.Quest
	-- Hidden during a raid so the Warzone screen stays clear
	if not quest or state.Raid.Active then
		card.Visible = false
		highlightName = nil
		highlight.Enabled = false
		return
	end
	card.Visible = true
	header.Text = `{quest.Number} / {quest.Total}`
	questText.Text = quest.Text
	bar.Set(quest.Progress / quest.Target, `{quest.Progress} / {quest.Target}`)
	if lastQuest and lastQuest ~= quest.Number then
		Theme.pop(header, 1.2)
	end
	lastQuest = quest.Number

	highlightName = quest.Highlight
	aimHighlight()
end

function QuestTracker.Start()
	build()
	-- With streaming on, the island's parts can still be loading in (after joining or
	-- expanding), and parts far away leave again: keep looking until the target is there
	task.spawn(function()
		while true do
			task.wait(1)
			local adornee = highlight.Adornee
			if highlightName and (not adornee or not adornee:IsDescendantOf(workspace)) then
				aimHighlight()
			end
		end
	end)
end

return QuestTracker
