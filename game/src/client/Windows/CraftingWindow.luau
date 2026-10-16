--!strict
-- Crafting table window, laid out like Minecraft's recipe book: a grid of item photos on
-- the left (green outline = you can craft it now), and on the right the selected item up
-- close with its tool stats (mining speed, damage, durability), what it's good for, what
-- it costs and a Craft button. The server decides whether crafting actually works.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Items = require(ReplicatedStorage.Shared.Items)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tools = require(ReplicatedStorage.Shared.Tools)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local TILE = 72
local GAP = 8
local COLUMNS = 4
local GRID_WIDTH = COLUMNS * TILE + (COLUMNS - 1) * GAP + 12

-- Stat bars are relative to the best tool in the game
local BEST = { Efficiency = 1, Damage = 1, Durability = 1 }
for _, tool in Tools.List do
	BEST.Efficiency = math.max(BEST.Efficiency, tool.Efficiency)
	BEST.Damage = math.max(BEST.Damage, tool.Damage)
	BEST.Durability = math.max(BEST.Durability, tool.Durability)
end

-- What each tool kind is good for, from the block toughness table
local GOOD_FOR: { [string]: string } = { Sword = "Fighting monsters (and players in the Warzone)" }
do
	local names: { [string]: { string } } = {}
	for _, def in Blocks.Types do
		if def.Tool and def.Breakable then
			names[def.Tool] = names[def.Tool] or {}
			table.insert(names[def.Tool], def.Name)
		end
	end
	for kind, list in names do
		table.sort(list)
		GOOD_FOR[kind] = `Fast on {table.concat(list, ", ")}`
	end
end

type Tile = { Button: TextButton, Stroke: UIStroke, Lock: TextLabel }
type StatRow = { Frame: Frame, Value: TextLabel, Bar: Theme.Bar }

local CraftingWindow = {}

local window: Window.Window
local state: any = nil
local selectedId = Recipes.List[1].Id
local tiles: { [string]: Tile } = {}

local photo: Frame
local photoId: string? = nil
local nameLabel: TextLabel
local kindLabel: TextLabel
local goodFor: TextLabel
local stats: { [string]: StatRow } = {}
local costRow: Frame
local lockLabel: TextLabel
local craftButton: Theme.Button

-- Is the recipe craftable right now? (enough materials, high enough level)
local function check(recipe: Recipes.Recipe): (boolean, boolean)
	local enough = true
	for itemId, need in recipe.Inputs do
		if (state.Items[itemId] or 0) < need then
			enough = false
		end
	end
	return enough, state.Level >= recipe.PlayerLevel
end

local function ingredientChip(itemId: string, need: number, order: number)
	local have = state.Items[itemId] or 0
	local color = if have >= need then C.Green else C.Red
	local chip = Theme.make("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 40),
		BackgroundColor3 = Theme.darken(color, 0.6),
		LayoutOrder = order,
		Parent = costRow,
	})
	Theme.corner(chip, 10)
	Theme.stroke(chip, Theme.darken(color, 0.15), 2)
	Theme.padding(chip, 4, 10, 0, 0)
	Theme.list(chip, Enum.FillDirection.Horizontal, 4)
	local iconHolder = Theme.make("Frame", {
		Size = UDim2.fromOffset(34, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = chip,
	})
	ItemIcon.create(iconHolder, itemId, UDim2.fromScale(1, 1))
	local text = Theme.text(chip, `{have}/{need}`, 17, Theme.Font.Title)
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromOffset(0, 34)
	text.LayoutOrder = 2
end

local function renderDetail()
	local recipe = Recipes.ById[selectedId]
	local output = Items[recipe.Output]
	local tool = Tools.ByItem[recipe.Output]

	-- Big photo of the item (only rebuilt when the selection changes)
	if photoId ~= selectedId then
		photoId = selectedId
		Window.clear(photo)
		ItemIcon.create(photo, recipe.Output, UDim2.fromScale(0.86, 0.86))
	end

	nameLabel.Text = if recipe.Amount > 1 then `{output.Name} x{recipe.Amount}` else output.Name
	if tool then
		kindLabel.Text = `Tier {tool.Tier} {tool.Kind}`
		goodFor.Text = GOOD_FOR[tool.Kind] or ""
	elseif output.Block then
		kindLabel.Text = "Building block"
		goodFor.Text = "Place it with right click"
	else
		kindLabel.Text = "Crafting material"
		goodFor.Text = "Used to make tools"
	end

	for _, row in stats do
		row.Frame.Visible = tool ~= nil
	end
	if tool then
		stats.Efficiency.Value.Text = `x{tool.Efficiency}`
		stats.Efficiency.Bar.Set(tool.Efficiency / BEST.Efficiency)
		stats.Damage.Value.Text = tostring(tool.Damage)
		stats.Damage.Bar.Set(tool.Damage / BEST.Damage)
		stats.Durability.Value.Text = `{tool.Durability} uses`
		stats.Durability.Bar.Set(tool.Durability / BEST.Durability)
	end

	Window.clear(costRow)
	local order = 0
	for itemId, need in recipe.Inputs do
		order += 1
		ingredientChip(itemId, need, order)
	end

	local enough, levelOk = check(recipe)
	lockLabel.Visible = not levelOk
	lockLabel.Text = `Unlocks at level {recipe.PlayerLevel}`
	craftButton.SetEnabled(enough and levelOk)
end

local function render()
	if not state then
		return
	end
	for _, recipe in Recipes.List do
		local tile = tiles[recipe.Id]
		local enough, levelOk = check(recipe)
		local selected = recipe.Id == selectedId
		tile.Stroke.Color = if selected then C.Gold elseif enough and levelOk then C.Green else C.Stroke
		tile.Stroke.Thickness = if selected then 3 else 2
		tile.Lock.Visible = not levelOk
	end
	renderDetail()
end

local function choose(recipeId: string)
	selectedId = recipeId
	render()
end

local function buildGrid(parent: Instance)
	local grid = Theme.make("ScrollingFrame", {
		Size = UDim2.new(0, GRID_WIDTH, 1, 0),
		BackgroundColor3 = C.Inset,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.Muted,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
	Theme.corner(grid, 12)
	Theme.padding(grid, 6, 6, 6, 6)
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(TILE, TILE),
		CellPadding = UDim2.fromOffset(GAP, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})

	for index, recipe in Recipes.List do
		local button = Theme.make("TextButton", {
			BackgroundColor3 = C.Row,
			AutoButtonColor = true,
			Text = "",
			LayoutOrder = index,
			Parent = grid,
		})
		Theme.corner(button, 10)
		local stroke = Theme.stroke(button, C.Stroke, 2)
		ItemIcon.create(button, recipe.Output, UDim2.fromScale(0.8, 0.8))
		if recipe.Amount > 1 then
			local amount = Theme.title(button, tostring(recipe.Amount), 16)
			amount.AnchorPoint = Vector2.new(1, 1)
			amount.Position = UDim2.new(1, -5, 1, -2)
			amount.Size = UDim2.fromOffset(30, 18)
			amount.TextXAlignment = Enum.TextXAlignment.Right
			amount.ZIndex = 3
		end
		local lock = Theme.make("TextLabel", {
			Position = UDim2.fromOffset(4, 2),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Text = "🔒",
			TextSize = 15,
			ZIndex = 3,
			Visible = false,
			Parent = button,
		})
		button.Activated:Connect(function()
			choose(recipe.Id)
		end)
		tiles[recipe.Id] = { Button = button, Stroke = stroke, Lock = lock }
	end
end

local function statRow(parent: Instance, key: string, label: string, color: Color3, order: number)
	local frame = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})
	local name = Theme.text(frame, label, 14, Theme.Font.Bold, C.Muted)
	name.Size = UDim2.new(0, 104, 1, 0)
	local bar = Theme.bar(frame, color, UDim2.new(1, -190, 0, 14))
	bar.Track.AnchorPoint = Vector2.new(0, 0.5)
	bar.Track.Position = UDim2.new(0, 106, 0.5, 0)
	local value = Theme.text(frame, "", 15, Theme.Font.Title)
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.fromScale(1, 0)
	value.Size = UDim2.new(0, 76, 1, 0)
	value.TextXAlignment = Enum.TextXAlignment.Right
	stats[key] = { Frame = frame, Value = value, Bar = bar }
end

local function buildDetail(parent: Instance)
	local panel = Theme.make("Frame", {
		Position = UDim2.fromOffset(GRID_WIDTH + 14, 0),
		Size = UDim2.new(1, -(GRID_WIDTH + 14), 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = parent,
	})
	Theme.gradient(panel, Theme.lighten(C.Row, 0.08), C.Row)
	Theme.corner(panel, 12)
	Theme.stroke(panel, C.Stroke, 2)
	Theme.padding(panel, 14, 14, 12, 12)

	-- Photo of the item on a soft "studio" backdrop
	photo = Theme.make("Frame", {
		Size = UDim2.fromOffset(132, 132),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = panel,
	})
	Theme.gradient(photo, Color3.fromRGB(120, 170, 220), Color3.fromRGB(62, 92, 140))
	Theme.corner(photo, 14)
	Theme.stroke(photo, C.Stroke, 2.5)

	nameLabel = Theme.title(panel, "", 24)
	nameLabel.Position = UDim2.fromOffset(146, 4)
	nameLabel.Size = UDim2.new(1, -146, 0, 30)
	kindLabel = Theme.text(panel, "", 15, Theme.Font.Bold, C.Gold)
	kindLabel.Position = UDim2.fromOffset(146, 38)
	kindLabel.Size = UDim2.new(1, -146, 0, 20)
	goodFor = Theme.text(panel, "", 13, Theme.Font.Medium, C.Muted)
	goodFor.Position = UDim2.fromOffset(146, 62)
	goodFor.Size = UDim2.new(1, -146, 0, 60)
	goodFor.TextWrapped = true
	goodFor.TextYAlignment = Enum.TextYAlignment.Top
	goodFor.TextTruncate = Enum.TextTruncate.None

	local statList = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 144),
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	Theme.list(statList, Enum.FillDirection.Vertical, 5)
	statRow(statList, "Efficiency", "Mining speed", C.Blue, 1)
	statRow(statList, "Damage", "Damage", C.Red, 2)
	statRow(statList, "Durability", "Durability", C.Green, 3)

	local costTitle = Theme.text(panel, "NEEDS", 13, Theme.Font.Bold, C.Muted)
	costTitle.AnchorPoint = Vector2.new(0, 1)
	costTitle.Position = UDim2.new(0, 0, 1, -66)
	costRow = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -14),
		Size = UDim2.new(1, -130, 0, 48),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	Theme.list(costRow, Enum.FillDirection.Horizontal, 6)

	lockLabel = Theme.text(panel, "", 13, Theme.Font.Bold, C.Purple)
	lockLabel.AnchorPoint = Vector2.new(1, 1)
	lockLabel.Position = UDim2.new(1, 0, 1, -70)
	lockLabel.Size = UDim2.fromOffset(160, 18)
	lockLabel.TextXAlignment = Enum.TextXAlignment.Right

	craftButton = Theme.button(panel, "CRAFT", C.Orange, UDim2.fromOffset(120, 58), function()
		Remotes.Craft:FireServer(selectedId)
	end)
	craftButton.Holder.AnchorPoint = Vector2.new(1, 1)
	craftButton.Holder.Position = UDim2.new(1, 0, 1, -6)
	craftButton.Label.TextSize = 22
end

function CraftingWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
	end
end

function CraftingWindow.Open()
	Window.open(window)
end

function CraftingWindow.IsOpen(): boolean
	return window.IsOpen
end

function CraftingWindow.Start()
	window = Window.new("CraftingWindow", "Crafting Table", "🔨", Vector2.new(760, 470))
	window.OnOpen = render
	buildGrid(window.Body)
	buildDetail(window.Body)
end

return CraftingWindow
