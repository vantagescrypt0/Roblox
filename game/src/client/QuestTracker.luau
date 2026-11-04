--!strict
-- Shows the current beginner quest on the right side of the screen and outlines the
-- object on your island it's about, so new players always know where to go. Click it for
-- the Challenges board.

local Players = game:GetService("Players")

local Glass = require(script.Parent.UI.Glass)
local Theme = require(script.Parent.UI.Theme)

local C = Glass.Color
local localPlayer = Players.LocalPlayer :: Player

local QuestTracker = {}

local card: Frame
local title: TextLabel
local header: TextLabel
local questText: TextLabel
local bar: Theme.Bar
local highlight: Highlight
local highlightName: string? = nil -- what the current quest outlines on your island
local lastQuest: number? = nil

local function build(onOpen: () -> ())
	local gui = Theme.screen("Quests", 1)

	card = Glass.card(gui, UDim2.fromOffset(270, 0))
	-- Right side, below Roblox's player list
	card.AnchorPoint = Vector2.new(1, 0.5)
	card.Position = UDim2.new(1, -14, 0.5, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Visible = false
	Theme.autoScale(card)
	Theme.padding(card, 14, 14, 10, 12)
	Theme.list(card, Enum.FillDirection.Vertical, 6)

	local top = Theme.make("Frame", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Parent = card,
	})
	title = Glass.text(top, "Quest", 16, Glass.Font.Bold, C.Gold)
	title.Size = UDim2.new(1, -70, 1, 0)
	-- Quest number on the right of the title
	header = Glass.text(top, "", 14, Glass.Font.Bold, C.Muted)
	header.AnchorPoint = Vector2.new(1, 0)
	header.Position = UDim2.fromScale(1, 0)
	header.Size = UDim2.new(0, 70, 1, 0)
	header.TextXAlignment = Enum.TextXAlignment.Right

	questText = Glass.text(card, "", 16, Glass.Font.Body)
	questText.LayoutOrder = 2
	questText.TextWrapped = true
	questText.TextTruncate = Enum.TextTruncate.None
	questText.AutomaticSize = Enum.AutomaticSize.Y
	questText.Size = UDim2.new(1, 0, 0, 20)

	bar = Glass.bar(card, C.Gold, UDim2.new(1, 0, 0, 16))
	bar.Track.LayoutOrder = 3
	bar.Label.TextSize = 12

	-- The whole card opens the Challenges board
	card.Active = true
	card.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			onOpen()
		end
	end)

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
	-- "Quest" for the beginner chain, else the Challenges group you track
	title.Text = quest.Board or "Quest"
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

function QuestTracker.Start(onOpen: () -> ())
	build(onOpen)
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
