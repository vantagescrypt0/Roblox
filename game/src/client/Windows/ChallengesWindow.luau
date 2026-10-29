--!strict
-- Challenges window: the beginner challenges (Quests.luau) as a board, like the Skybounds
-- tutorial screen: a tile for each, green once done, gold for the one you're on, purple for
-- the ones ahead. Point at (or tap) a tile to see what it asks and what it gives; some give
-- nodes for your island. Open it with the Challenges button or by clicking the quest tracker.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Quests = require(ReplicatedStorage.Shared.Quests)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local TILE = 60
local DONE = Color3.fromRGB(120, 178, 82)
local CURRENT = Color3.fromRGB(232, 196, 72)
local AHEAD = Color3.fromRGB(150, 108, 196)

local ChallengesWindow = {}

local window: Window.Window
local countChip: TextLabel
local grid: ScrollingFrame
local detailTitle: TextLabel
local detailText: TextLabel
local detailStatus: TextLabel
local progressBar: Theme.Bar
local rewardRow: Frame

local state: any = nil
local selected: number? = nil

local function currentIndex(): number
	return if state then state.QuestIndex or 1 else 1
end

-- A reward chip: an item picture (or a coin / star) and how many
local function rewardChip(order: number, icon: string?, text: string, color: Color3?)
	local chip = Theme.make("Frame", {
		LayoutOrder = order,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 40),
		BackgroundColor3 = C.ParchmentDark,
		Parent = rewardRow,
	})
	Theme.corner(chip, 6)
	Theme.stroke(chip, C.TanEdge, 2)
	Theme.padding(chip, 4, 10, 0, 0)
	Theme.list(chip, Enum.FillDirection.Horizontal, 6).VerticalAlignment = Enum.VerticalAlignment.Center
	if icon then
		local box = Theme.make("Frame", {
			LayoutOrder = 1,
			Size = UDim2.fromOffset(32, 32),
			BackgroundTransparency = 1,
			Parent = chip,
		})
		ItemIcon.create(box, icon, UDim2.fromScale(1, 1))
	end
	local label = Theme.text(chip, text, 15, Theme.Font.Bold, color)
	label.LayoutOrder = 2
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, 32)
end

local function renderDetail()
	local index = selected or currentIndex()
	local quest = Quests[index]
	Window.clear(rewardRow)
	if not quest then
		detailTitle.Text = "All done!"
		detailText.Text = "You've finished every beginner challenge. The Grinding Worlds are yours."
		detailStatus.Text = ""
		progressBar.Track.Visible = false
		return
	end
	local current = currentIndex()
	detailTitle.Text = `Challenge {index}`
	detailText.Text = quest.Text
	progressBar.Track.Visible = index == current
	if index < current then
		detailStatus.Text = "Complete"
		detailStatus.TextColor3 = C.Green
	elseif index == current then
		detailStatus.Text = "In progress"
		detailStatus.TextColor3 = C.Ochre
		local progress = if state and state.Quest then state.Quest.Progress else 0
		progressBar.Set(progress / quest.Target, `{progress} / {quest.Target}`)
	else
		detailStatus.Text = "Finish the challenges before it first"
		detailStatus.TextColor3 = C.Purple
	end

	local reward = quest.Reward
	local order = 0
	if reward.Items then
		for itemId, count in reward.Items do
			order += 1
			local item = Items[itemId]
			rewardChip(order, itemId, `{count} {if item then item.Name else itemId}`)
		end
	end
	if reward.Coins then
		order += 1
		rewardChip(order, nil, `{Theme.formatNumber(reward.Coins)} coins`, C.Ochre)
	end
	if reward.XP then
		order += 1
		rewardChip(order, nil, `{Theme.formatNumber(reward.XP)} XP`, C.Leaf)
	end
end

local function render()
	if not state then
		return
	end
	local current = currentIndex()
	local done = math.min(current - 1, #Quests)
	countChip.Text = `  {done} / {#Quests} done  `
	Window.clear(grid)
	for index, quest in Quests do
		local color = if index < current then DONE elseif index == current then CURRENT else AHEAD
		local tile = Theme.make("TextButton", {
			LayoutOrder = index,
			BackgroundColor3 = color,
			AutoButtonColor = false,
			Text = "",
			Parent = grid,
		})
		Theme.corner(tile, 6)
		local isSelected = index == (selected or current)
		Theme.stroke(tile, if isSelected then C.WoodEdge else Theme.darken(color, 0.35), if isSelected then 3 else 2)
		local number = Theme.text(tile, tostring(index), 22, Theme.Font.Title, Theme.textOn(color))
		number.Size = UDim2.fromScale(1, 1)
		number.TextXAlignment = Enum.TextXAlignment.Center
		if index < current then
			local tick = Theme.text(tile, "✓", 14, Theme.Font.Bold, C.Cream)
			tick.AnchorPoint = Vector2.new(1, 0)
			tick.Position = UDim2.new(1, -4, 0, 2)
			tick.Size = UDim2.fromOffset(16, 16)
		end
		-- A small picture of the first item it gives, in the corner
		local firstItem = quest.Reward.Items and next(quest.Reward.Items)
		if firstItem then
			local box = Theme.make("Frame", {
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -2, 1, -2),
				Size = UDim2.fromOffset(22, 22),
				BackgroundTransparency = 1,
				ZIndex = 2,
				Parent = tile,
			})
			ItemIcon.create(box, firstItem, UDim2.fromScale(1, 1))
		end
		local function pick()
			selected = index
			render()
		end
		tile.MouseEnter:Connect(function()
			if selected ~= index then
				pick()
			end
		end)
		tile.Activated:Connect(pick)
	end
	renderDetail()
end

function ChallengesWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
	end
end

function ChallengesWindow.Toggle()
	Window.toggle(window)
end

function ChallengesWindow.Start()
	window = Window.new("ChallengesWindow", "Challenges", Vector2.new(660, 560))
	window.OnOpen = function()
		selected = nil
		render()
	end
	local body = window.Body

	local title = Theme.title(body, "Beginner Challenges", 22)
	title.Size = UDim2.new(1, -150, 0, 30)
	countChip = Theme.chip(body, "", C.WoodLight)
	countChip.AnchorPoint = Vector2.new(1, 0)
	countChip.Position = UDim2.new(1, 0, 0, 1)

	local well = Theme.inset(body, UDim2.new(1, 0, 0, 262), UDim2.fromOffset(0, 38))
	grid = Theme.make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.WoodLight,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = well,
	})
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(TILE, TILE),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	Theme.padding(grid, 10, 10, 10, 10)

	local card = Theme.card(body, UDim2.new(1, 0, 1, -312), UDim2.fromOffset(0, 312))
	Theme.padding(card, 14, 14, 10, 10)
	detailTitle = Theme.title(card, "", 20)
	detailTitle.Size = UDim2.new(0.5, 0, 0, 26)
	detailStatus = Theme.text(card, "", 14, Theme.Font.Bold)
	detailStatus.AnchorPoint = Vector2.new(1, 0)
	detailStatus.Position = UDim2.new(1, 0, 0, 4)
	detailStatus.Size = UDim2.new(0.5, 0, 0, 20)
	detailStatus.TextXAlignment = Enum.TextXAlignment.Right
	detailText = Theme.text(card, "", 17, Theme.Font.Bold)
	detailText.Position = UDim2.fromOffset(0, 30)
	detailText.Size = UDim2.new(1, 0, 0, 44)
	detailText.TextWrapped = true
	progressBar = Theme.bar(card, C.Ochre, UDim2.new(1, 0, 0, 18))
	progressBar.Track.Position = UDim2.fromOffset(0, 78)
	local rewardsLabel = Theme.text(card, "Rewards", 14, Theme.Font.Bold, C.InkMuted)
	rewardsLabel.Position = UDim2.fromOffset(0, 104)
	rewardsLabel.Size = UDim2.new(1, 0, 0, 18)
	rewardRow = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 124),
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		Parent = card,
	})
	Theme.list(rewardRow, Enum.FillDirection.Horizontal, 8)
end

return ChallengesWindow
