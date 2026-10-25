--!strict
-- Skills window: your player level up top, then every skill (Farming, Mining, Woodcutting,
-- Crafting, Combat) with its level and XP. Pick a skill to see how to train it, its
-- double-drop bonus and everything it unlocks: recipes that need it (Recipes.luau) and,
-- for Farming, better crops. Open it with the Skills button or by clicking your profile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local ItemOrder = require(ReplicatedStorage.Shared.ItemOrder)
local Items = require(ReplicatedStorage.Shared.Items)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Skills = require(ReplicatedStorage.Shared.Skills)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local LEFT_WIDTH = 360
local ROW_HEIGHT = 64
local TILE = 58

-- Something a skill level unlocks: an item to craft (or seeds to plant) at a level
type Unlock = { Item: string, Level: number, Text: string, Requires: { [string]: number } }
type Row = { Button: TextButton, Stroke: UIStroke, Level: TextLabel, Bar: Theme.Bar }

local SkillsWindow = {}

local window: Window.Window
local levelNumber: TextLabel
local playerBar: Theme.Bar
local seasonText: TextLabel
local rows: { [string]: Row } = {}
local detailIcon: Frame
local detailName: TextLabel
local detailLevel: TextLabel
local detailTrains: TextLabel
local detailBonus: TextLabel
local unlockGrid: Frame
local unlockEmpty: TextLabel
local info: TextLabel

local state: any = nil
local selected = Skills.List[1].Id

local orderIndex: { [string]: number } = {}
for index, itemId in ItemOrder do
	orderIndex[itemId] = index
end

-- Everything each skill unlocks, lowest level first
local unlocks: { [string]: { Unlock } } = {}
for _, skill in Skills.List do
	unlocks[skill.Id] = {}
end
for _, recipe in Recipes.List do
	for skillId, level in recipe.Requires do
		local verb = if recipe.Station == "Furnace" then "Smelt" else "Craft"
		table.insert(unlocks[skillId], {
			Item = recipe.Output,
			Level = level,
			Text = `{verb} {Items[recipe.Output].Name}`,
			Requires = recipe.Requires,
		})
	end
end
for _, crop in Crops.List do
	if crop.FarmingLevel > 1 then
		table.insert(unlocks.Farming, {
			Item = crop.Seed,
			Level = crop.FarmingLevel,
			Text = `Plant {crop.Id}`,
			Requires = { Farming = crop.FarmingLevel },
		})
	end
end
for _, list in unlocks do
	table.sort(list, function(a, b)
		if a.Level ~= b.Level then
			return a.Level < b.Level
		end
		return (orderIndex[a.Item] or math.huge) < (orderIndex[b.Item] or math.huge)
	end)
end

local function skillState(skillId: string): { Level: number, XP: number, XPToNext: number }
	local skill = state and state.Skills[skillId]
	return skill or { Level = 1, XP = 0, XPToNext = Leveling.XPToNext(1) }
end

local function levelOf(skillId: string): number
	return skillState(skillId).Level
end

local function xpText(level: number, xp: number, toNext: number, max: number): (number, string)
	if level >= max then
		return 1, "Max level"
	end
	return xp / toNext, `{Theme.formatNumber(xp)} / {Theme.formatNumber(toNext)} XP`
end

local function renderDetail()
	local skill = Skills.ById[selected]
	local current = skillState(selected)

	Window.clear(detailIcon)
	ItemIcon.create(detailIcon, skill.Icon, UDim2.fromScale(0.86, 0.86))
	detailName.Text = skill.Name
	detailLevel.Text = `Level {current.Level}`
	detailTrains.Text = `Train it: {skill.Trains}`
	if skill.Bonus then
		local chance = math.floor(Leveling.BonusChance(current.Level) * 100 + 0.5)
		detailBonus.Text = `Double drops: {chance}% chance (+1% each level)`
	elseif skill.Id == "Crafting" then
		detailBonus.Text = "Every craft and smelt gives Crafting XP"
	else
		detailBonus.Text = "Tougher monsters need a higher Combat level"
	end

	Window.clear(unlockGrid)
	local list = unlocks[selected]
	unlockEmpty.Visible = #list == 0
	for order, unlock in list do
		local reached = current.Level >= unlock.Level
		local _, ready = Skills.Check(unlock.Requires, levelOf)
		local tile = Theme.make("TextButton", {
			LayoutOrder = order,
			BackgroundColor3 = C.ParchmentDark,
			AutoButtonColor = false,
			Text = "",
			Parent = unlockGrid,
		})
		Theme.corner(tile, 6)
		Theme.stroke(tile, if ready then C.Green elseif reached then C.Ochre else C.TanEdge, if ready then 2.5 else 2)
		local icon = ItemIcon.create(tile, unlock.Item, UDim2.fromScale(0.74, 0.74))
		icon.Position = UDim2.fromScale(0.5, 0.44)
		-- Level tag along the bottom
		local tag = Theme.make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -3),
			Size = UDim2.new(1, -8, 0, 15),
			BackgroundColor3 = if reached then C.Leaf else C.WoodLight,
			FontFace = Theme.Font.Bold,
			TextSize = 11,
			TextColor3 = C.Cream,
			Text = `Lv {unlock.Level}`,
			ZIndex = 3,
			Parent = tile,
		})
		Theme.corner(tag, 4)
		if not reached then
			local shade = Theme.make("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = C.Tan,
				BackgroundTransparency = 0.45,
				ZIndex = 2,
				Parent = tile,
			})
			Theme.corner(shade, 6)
		end

		local needs = {}
		for _, need in (Skills.Check(unlock.Requires, levelOf)) do
			table.insert(needs, `{need.Skill.Name} {need.Level}`)
		end
		local status = if ready then "ready" elseif reached then "also needs more" else "locked"
		local text = `{unlock.Text} · needs {table.concat(needs, " + ")} · {status}`
		tile.MouseEnter:Connect(function()
			info.Text = text
		end)
		tile.Activated:Connect(function()
			info.Text = text
		end)
	end
end

local function render()
	if not state then
		return
	end
	levelNumber.Text = tostring(state.Level)
	playerBar.Set(xpText(state.Level, state.XP, state.XPToNext, state.MaxLevel))
	seasonText.Text = `Season {state.Season} · everything you do gives player XP`

	for _, skill in Skills.List do
		local row = rows[skill.Id]
		local current = skillState(skill.Id)
		row.Level.Text = `Lv {current.Level}`
		row.Bar.Set(xpText(current.Level, current.XP, current.XPToNext, Leveling.MaxSkillLevel))
		local isSelected = skill.Id == selected
		row.Stroke.Color = if isSelected then C.Ochre else C.TanEdge
		row.Stroke.Thickness = if isSelected then 3 else 2
		row.Button.BackgroundColor3 = if isSelected then C.Parchment else C.ParchmentDark
	end
	renderDetail()
end

local function buildPlayerCard(body: Frame)
	local card = Theme.card(body, UDim2.new(1, 0, 0, 100))
	-- Round wooden plaque with a gold rim, like the HUD's
	local badge = Theme.make("Frame", {
		Size = UDim2.fromOffset(78, 78),
		Position = UDim2.fromOffset(12, 11),
		BackgroundColor3 = C.WoodLight,
		Parent = card,
	})
	Theme.corner(badge, 999)
	Theme.stroke(badge, C.Gold, 3)
	local lv = Theme.text(badge, "LEVEL", 10, Theme.Font.Bold, C.Gold)
	lv.Position = UDim2.fromOffset(0, 12)
	lv.TextXAlignment = Enum.TextXAlignment.Center
	levelNumber = Theme.text(badge, "1", 32, Theme.Font.Bold, C.Cream)
	levelNumber.Position = UDim2.fromOffset(0, 26)
	levelNumber.Size = UDim2.new(1, 0, 0, 36)
	levelNumber.TextXAlignment = Enum.TextXAlignment.Center

	local title = Theme.title(card, "Player level", 24)
	title.Position = UDim2.fromOffset(106, 8)
	title.Size = UDim2.new(1, -120, 0, 30)
	seasonText = Theme.text(card, "", 14, Theme.Font.Medium, C.InkMuted)
	seasonText.Position = UDim2.fromOffset(106, 38)
	seasonText.Size = UDim2.new(1, -120, 0, 18)
	playerBar = Theme.bar(card, C.Leaf, UDim2.new(1, -122, 0, 22))
	playerBar.Track.Position = UDim2.fromOffset(106, 64)
	playerBar.Label.TextSize = 14
end

local function buildRows(body: Frame, top: number)
	local column = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(0, LEFT_WIDTH, 1, -top),
		BackgroundTransparency = 1,
		Parent = body,
	})
	local layout = Theme.list(column, Enum.FillDirection.Vertical, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top

	for order, skill in Skills.List do
		local button = Theme.make("TextButton", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			BackgroundColor3 = C.ParchmentDark,
			AutoButtonColor = false,
			Text = "",
			Parent = column,
		})
		Theme.corner(button, 6)
		local stroke = Theme.stroke(button, C.TanEdge, 2)
		local box = Theme.inset(button, UDim2.fromOffset(48, 48), UDim2.fromOffset(8, 8))
		ItemIcon.create(box, skill.Icon, UDim2.fromScale(0.86, 0.86))
		local name = Theme.title(button, skill.Name, 20)
		name.Position = UDim2.fromOffset(66, 5)
		name.Size = UDim2.new(1, -140, 0, 26)
		local level = Theme.text(button, "Lv 1", 18, Theme.Font.Bold)
		level.AnchorPoint = Vector2.new(1, 0)
		level.Position = UDim2.new(1, -12, 0, 6)
		level.Size = UDim2.fromOffset(70, 24)
		level.TextXAlignment = Enum.TextXAlignment.Right
		local bar = Theme.bar(button, C.Leaf, UDim2.new(1, -78, 0, 18))
		bar.Track.Position = UDim2.fromOffset(66, 36)
		bar.Label.TextSize = 12
		button.Activated:Connect(function()
			selected = skill.Id
			info.Text = ""
			render()
		end)
		rows[skill.Id] = { Button = button, Stroke = stroke, Level = level, Bar = bar }
	end
end

local function buildDetail(body: Frame, top: number)
	local panel = Theme.card(body, UDim2.new(1, -(LEFT_WIDTH + 12), 1, -top), UDim2.fromOffset(LEFT_WIDTH + 12, top))
	Theme.padding(panel, 12, 12, 10, 10)

	detailIcon = Theme.inset(panel, UDim2.fromOffset(64, 64))
	detailName = Theme.title(panel, "", 26)
	detailName.Position = UDim2.fromOffset(76, 2)
	detailName.Size = UDim2.new(1, -76, 0, 32)
	detailLevel = Theme.text(panel, "", 16, Theme.Font.Bold, C.WoodLight)
	detailLevel.Position = UDim2.fromOffset(76, 36)
	detailLevel.Size = UDim2.new(1, -76, 0, 20)

	detailTrains = Theme.text(panel, "", 14, Theme.Font.Medium)
	detailTrains.Position = UDim2.fromOffset(0, 76)
	detailTrains.Size = UDim2.new(1, 0, 0, 18)
	detailBonus = Theme.text(panel, "", 14, Theme.Font.Medium, C.InkMuted)
	detailBonus.Position = UDim2.fromOffset(0, 98)
	detailBonus.Size = UDim2.new(1, 0, 0, 18)

	local unlockTitle = Theme.title(panel, "Unlocks", 20)
	unlockTitle.Position = UDim2.fromOffset(0, 126)
	unlockTitle.Size = UDim2.new(1, 0, 0, 24)
	local well = Theme.inset(panel, UDim2.new(1, 0, 1, -184), UDim2.fromOffset(0, 154))
	unlockGrid = Theme.make("ScrollingFrame", {
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
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = unlockGrid,
	})
	Theme.padding(unlockGrid, 7, 7, 7, 7)
	unlockEmpty = Theme.text(well, "Nothing to unlock yet", 15, Theme.Font.Medium, C.InkMuted)
	unlockEmpty.Size = UDim2.fromScale(1, 1)
	unlockEmpty.TextXAlignment = Enum.TextXAlignment.Center

	info = Theme.text(panel, "", 13, Theme.Font.Bold, C.InkMuted)
	info.AnchorPoint = Vector2.new(0, 1)
	info.Position = UDim2.fromScale(0, 1)
	info.Size = UDim2.new(1, 0, 0, 22)
	info.TextWrapped = true
end

function SkillsWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
	end
end

function SkillsWindow.Toggle()
	Window.toggle(window)
end

function SkillsWindow.Start()
	window = Window.new("SkillsWindow", "Skills", Vector2.new(780, 600))
	window.OnOpen = function()
		info.Text = "Point at an unlock to see what it needs"
		render()
	end
	buildPlayerCard(window.Body)
	buildRows(window.Body, 112)
	buildDetail(window.Body, 112)
end

return SkillsWindow
