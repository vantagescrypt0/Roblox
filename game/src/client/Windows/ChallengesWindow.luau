--!strict
-- Challenges window. First a square for each group (Boards.luau: Beginner, Mining,
-- Woodcutting, Farming, Crafting, Island, Slaying, Warzone) with how far along it you are;
-- pick one to see its board, like the Skybounds tutorial screen: a numbered tile for each
-- challenge, green once done, gold for the one you're on, purple for the ones ahead. Point
-- at (or tap) a tile to see what it asks and what it gives; some give nodes for your island.
-- "Track" puts a group's current challenge in the quest tracker. Open it from the Menu, or
-- click the quest tracker to go straight to the group it shows.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boards = require(ReplicatedStorage.Shared.Boards)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local TILE = 60
local SQUARE = Vector2.new(146, 200)
local DONE = Color3.fromRGB(120, 178, 82)
local CURRENT = Color3.fromRGB(232, 196, 72)
local AHEAD = Color3.fromRGB(150, 108, 196)

local ChallengesWindow = {}

local window: Window.Window
local groupsView: Frame
local squares: Frame
local boardView: Frame
local countChip: TextLabel
local trackButton: Theme.Button
local grid: ScrollingFrame
local detailTitle: TextLabel
local detailText: TextLabel
local detailStatus: TextLabel
local progressBar: Theme.Bar
local rewardRow: Frame

local state: any = nil
local board: Boards.Board? = nil -- the group being looked at (nil: the groups)
local selected: number? = nil

type BoardState = { Index: number, Progress: number, Done: { boolean } }

local function stateOf(id: string): BoardState
	local boards = state and state.Boards
	return (boards and boards[id]) or { Index = 1, Progress = 0, Done = {} }
end

local function doneCount(id: string): number
	local count = 0
	for _, done in stateOf(id).Done do
		if done then
			count += 1
		end
	end
	return count
end

local function colorOf(group: Boards.Board): Color3
	return (C :: any)[group.Color] or C.Blue
end

-- A reward chip: an item picture (or a coin / star) and how many
local function rewardChip(order: number, icon: string?, text: string, color: Color3?)
	local chip = Theme.make("Frame", {
		LayoutOrder = order,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 40),
		BackgroundColor3 = C.Card,
		Parent = rewardRow,
	})
	Theme.corner(chip, 6)
	Theme.stroke(chip, C.Line, 2)
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

-- The groups -------------------------------------------------------------------------

local function renderGroups()
	Window.clear(squares)
	for order, group in Boards.List do
		local soon = group.Soon ~= nil
		local total = #group.Challenges
		local done = doneCount(group.Id)
		local button = Theme.button(
			squares,
			"",
			if soon then C.Disabled else colorOf(group),
			UDim2.fromOffset(SQUARE.X, SQUARE.Y),
			function()
				board = group
				selected = nil
				ChallengesWindow.Render()
			end
		)
		button.Holder.LayoutOrder = order
		local face = button.Face
		local picture = Theme.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 12),
			Size = UDim2.fromOffset(84, 84),
			BackgroundTransparency = 1,
			Parent = face,
		})
		ItemIcon.create(picture, group.Icon, UDim2.fromScale(1, 1))
		local name = Theme.text(face, group.Name, 22, Theme.Font.Title, C.White)
		name.Position = UDim2.fromOffset(0, 102)
		name.Size = UDim2.new(1, 0, 0, 28)
		name.TextXAlignment = Enum.TextXAlignment.Center
		name.TextScaled = true
		Theme.make("UITextSizeConstraint", { MaxTextSize = 22, Parent = name })
		Theme.padding(name, 6, 6, 0, 0)
		if soon then
			local note = Theme.text(face, "Coming soon", 15, Theme.Font.Bold, C.White)
			note.Position = UDim2.fromOffset(0, 140)
			note.Size = UDim2.new(1, 0, 0, 20)
			note.TextXAlignment = Enum.TextXAlignment.Center
		else
			local bar = Theme.bar(face, C.Leaf, UDim2.new(1, -24, 0, 22))
			bar.Track.Position = UDim2.fromOffset(12, 140)
			bar.Set(done / total, `{done} / {total}`)
		end
		-- The group the quest tracker shows
		if state and state.Tracked == group.Id and not soon then
			local tag = Theme.chip(face, "Tracking", C.Gold)
			tag.AnchorPoint = Vector2.new(0.5, 0.5)
			tag.Position = UDim2.new(0.5, 0, 0, 2)
			tag.Size = UDim2.fromOffset(0, 24)
			tag.TextSize = 13
			tag.ZIndex = 3
		end
	end
end

-- One group's board ------------------------------------------------------------------

local function renderDetail(group: Boards.Board)
	local info = stateOf(group.Id)
	local index = selected or info.Index
	local challenge = group.Challenges[index]
	Window.clear(rewardRow)
	if not challenge then
		detailTitle.Text = "All done!"
		detailText.Text = if group.Id == "Beginner"
			then "You've finished every beginner challenge. The Grinding Worlds are yours."
			else `You've finished every {group.Name} challenge. More are on the way!`
		detailStatus.Text = ""
		progressBar.Track.Visible = false
		return
	end
	detailTitle.Text = `Challenge {index}`
	detailText.Text = challenge.Text
	progressBar.Track.Visible = false
	if group.Soon then
		detailStatus.Text = group.Soon
		detailStatus.TextColor3 = C.Purple
	elseif info.Done[index] then
		detailStatus.Text = "Complete"
		detailStatus.TextColor3 = C.Green
	elseif index == info.Index then
		detailStatus.Text = "In progress"
		detailStatus.TextColor3 = C.Orange
		progressBar.Track.Visible = true
		local progress = math.min(info.Progress, challenge.Target)
		progressBar.Set(
			progress / challenge.Target,
			`{Theme.formatNumber(progress)} / {Theme.formatNumber(challenge.Target)}`
		)
	else
		detailStatus.Text = "Finish the challenges before it first"
		detailStatus.TextColor3 = C.Purple
	end

	local reward = challenge.Reward
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
		rewardChip(order, nil, `{Theme.formatNumber(reward.Coins)} coins`, C.Orange)
	end
	if reward.XP then
		order += 1
		rewardChip(order, nil, `{Theme.formatNumber(reward.XP)} XP`, C.Leaf)
	end
end

local function renderBoard(group: Boards.Board)
	local info = stateOf(group.Id)
	local total = #group.Challenges
	countChip.Text = `  {doneCount(group.Id)} / {total} done  `
	local tracking = state and state.Tracked == group.Id
	trackButton.SetEnabled(group.Soon == nil and not tracking)
	trackButton.SetText(if tracking then "Tracking" else "Track")
	trackButton.SetColor(if tracking then C.Orange else C.Green)

	Window.clear(grid)
	for index, challenge in group.Challenges do
		local color = if info.Done[index] then DONE elseif index == info.Index and not group.Soon then CURRENT else AHEAD
		local tile = Theme.make("TextButton", {
			LayoutOrder = index,
			BackgroundColor3 = color,
			AutoButtonColor = false,
			Text = "",
			Parent = grid,
		})
		Theme.corner(tile, 6)
		local isSelected = index == (selected or info.Index)
		Theme.stroke(tile, if isSelected then C.Outline else Theme.darken(color, 0.35), if isSelected then 3 else 2)
		local number = Theme.text(tile, tostring(index), 22, Theme.Font.Title, Theme.textOn(color))
		number.Size = UDim2.fromScale(1, 1)
		number.TextXAlignment = Enum.TextXAlignment.Center
		if info.Done[index] then
			local tick = Theme.text(tile, "✓", 14, Theme.Font.Bold, C.White)
			tick.AnchorPoint = Vector2.new(1, 0)
			tick.Position = UDim2.new(1, -4, 0, 2)
			tick.Size = UDim2.fromOffset(16, 16)
		end
		-- A small picture of the first item it gives, in the corner
		local firstItem = challenge.Reward.Items and next(challenge.Reward.Items)
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
			renderBoard(group)
		end
		tile.MouseEnter:Connect(function()
			if selected ~= index then
				pick()
			end
		end)
		tile.Activated:Connect(pick)
	end
	renderDetail(group)
end

function ChallengesWindow.Render()
	if not state then
		return
	end
	local group = board
	groupsView.Visible = group == nil
	boardView.Visible = group ~= nil
	if group then
		window.Title.Text = `{group.Name} Challenges`
		Window.setColor(window, if group.Soon then C.Disabled else colorOf(group))
		renderBoard(group)
	else
		window.Title.Text = "Challenges"
		Window.setColor(window, C.Gold)
		renderGroups()
	end
end

function ChallengesWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		ChallengesWindow.Render()
	end
end

-- From the Menu: the groups
function ChallengesWindow.Toggle()
	if not window.IsOpen then
		board = nil
	end
	Window.toggle(window)
end

-- From the quest tracker: straight to the group it shows
function ChallengesWindow.OpenTracked()
	if window.IsOpen then
		Window.close(window)
		return
	end
	board = Boards.ById[state and state.Tracked or "Beginner"]
	Window.open(window)
end

local function buildGroups(body: Frame)
	groupsView = Theme.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = body })
	local hint = Theme.text(groupsView, "Pick a group. Finish its challenges in order for coins, XP and more.", 16)
	hint.Size = UDim2.new(1, 0, 0, 22)
	hint.TextColor3 = C.InkMuted
	squares = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		BackgroundTransparency = 1,
		Parent = groupsView,
	})
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(SQUARE.X, SQUARE.Y + 4),
		CellPadding = UDim2.fromOffset(9, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = squares,
	})
	Theme.padding(squares, 0, 0, 8, 0)
end

local function buildBoard(body: Frame)
	boardView = Theme.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = body })

	local back = Theme.button(boardView, "Back", C.Blue, UDim2.fromOffset(96, 40), function()
		board = nil
		ChallengesWindow.Render()
	end)
	back.Holder.Position = UDim2.fromOffset(0, -2)
	countChip = Theme.chip(boardView, "", C.Blue)
	countChip.AnchorPoint = Vector2.new(1, 0)
	countChip.Position = UDim2.new(1, 0, 0, 4)
	trackButton = Theme.button(boardView, "Track", C.Green, UDim2.fromOffset(120, 40), function()
		if board then
			Remotes.TrackBoard:FireServer(board.Id)
		end
	end)
	trackButton.Holder.AnchorPoint = Vector2.new(1, 0)
	trackButton.Holder.Position = UDim2.new(1, -130, 0, -2)

	local well = Theme.inset(boardView, UDim2.new(1, 0, 0, 256), UDim2.fromOffset(0, 46))
	grid = Theme.make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.NavyLight,
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

	local card = Theme.card(boardView, UDim2.new(1, 0, 1, -314), UDim2.fromOffset(0, 314))
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
	progressBar = Theme.bar(card, C.Orange, UDim2.new(1, 0, 0, 18))
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

function ChallengesWindow.Start()
	window = Window.new("ChallengesWindow", "Challenges", Vector2.new(660, 560), C.Gold)
	window.OnOpen = function()
		selected = nil
		ChallengesWindow.Render()
	end
	buildGroups(window.Body)
	buildBoard(window.Body)
end

return ChallengesWindow
