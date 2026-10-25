--!strict
-- Crafting window, laid out like Minecraft's recipe book: a grid of item photos on the
-- left (green outline = you can craft it now), and on the right the selected item up
-- close with its tool stats (mining speed, damage, durability), what it's good for, the
-- skill levels it needs (red until you have them), what it costs and a Craft button. The
-- same window serves the Crafting Table and the Furnace (smelting); each shows only its
-- own recipes. The server decides whether crafting works.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Items = require(ReplicatedStorage.Shared.Items)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Skills = require(ReplicatedStorage.Shared.Skills)
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

-- Window title and button text for each station
local STATIONS = {
	CraftingTable = { Title = "Crafting Table", Verb = "Craft" },
	Furnace = { Title = "Furnace", Verb = "Smelt" },
}
type StatRow = { Frame: Frame, Value: TextLabel, Bar: Theme.Bar }

local CraftingWindow = {}

local window: Window.Window
local state: any = nil
local station: Recipes.Station = "CraftingTable"
local selectedId = Recipes.List[1].Id
local tiles: { [string]: Tile } = {}

local photo: Frame
local photoId: string? = nil
local nameLabel: TextLabel
local kindLabel: TextLabel
local goodFor: TextLabel
local stats: { [string]: StatRow } = {}
local needsRow: Frame
local costRow: Frame
local lockLabel: TextLabel
local craftButton: Theme.Button

local function levelOf(skillId: string): number
	local skill = state.Skills[skillId]
	return if skill then skill.Level else 1
end

-- Is the recipe craftable right now? (enough materials, high enough skill levels)
local function check(recipe: Recipes.Recipe): (boolean, boolean)
	local enough = true
	for itemId, need in recipe.Inputs do
		if (state.Items[itemId] or 0) < need then
			enough = false
		end
	end
	local _, skilled = Skills.Check(recipe.Requires, levelOf)
	return enough, skilled
end

-- "Mining 4" with the skill's picture; red until you reach it
local function skillChip(need: Skills.Need, order: number)
	local chip = Theme.iconChip(needsRow, `{need.Skill.Name} {need.Level}`, 32)
	chip.Frame.LayoutOrder = order
	chip.Label.TextColor3 = if levelOf(need.Skill.Id) >= need.Level then C.Ink else C.Red
	ItemIcon.create(chip.Icon, need.Skill.Icon, UDim2.fromScale(1, 1))
end

local function ingredientChip(itemId: string, need: number, order: number)
	local have = state.Items[itemId] or 0
	local chip = Theme.iconChip(costRow, `{have}/{need}`, 40)
	chip.Frame.LayoutOrder = order
	chip.Label.TextSize = 17
	-- Red when you don't have enough yet
	chip.Label.TextColor3 = if have >= need then C.Ink else C.Red
	ItemIcon.create(chip.Icon, itemId, UDim2.fromScale(1, 1))
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
	elseif recipe.Output == "Furnace" then
		kindLabel.Text = "Station"
		goodFor.Text = "Place it, then right-click it to smelt ores"
	elseif output.Block then
		kindLabel.Text = "Building block"
		goodFor.Text = "Place it with right click"
	elseif recipe.Station == "Furnace" then
		kindLabel.Text = "Smelted material"
		goodFor.Text = "Used to make iron tools, or sell it at the Market"
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

	-- Skill levels it needs (the row's title stays; chips are rebuilt)
	local needs = Skills.Check(recipe.Requires, levelOf)
	needsRow.Visible = #needs > 0
	for _, child in needsRow:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for index, need in needs do
		skillChip(need, index + 1)
	end

	local enough, skilled = check(recipe)
	lockLabel.Visible = not skilled
	lockLabel.Text = `Needs {Skills.Describe(recipe.Requires, levelOf)}`
	craftButton.SetEnabled(enough and skilled)
end

local function render()
	if not state then
		return
	end
	for _, recipe in Recipes.List do
		local tile = tiles[recipe.Id]
		tile.Button.Visible = recipe.Station == station
		local enough, skilled = check(recipe)
		local selected = recipe.Id == selectedId
		tile.Stroke.Color = if selected then C.Ochre elseif enough and skilled then C.Green else C.TanEdge
		tile.Stroke.Thickness = if selected then 3.5 elseif enough and skilled then 2.5 else 2
		tile.Button.BackgroundColor3 = if selected then C.Parchment else C.ParchmentDark
		tile.Lock.Visible = not skilled
	end
	renderDetail()
end

local function choose(recipeId: string)
	selectedId = recipeId
	render()
end

local function buildGrid(parent: Instance)
	local well = Theme.inset(parent, UDim2.new(0, GRID_WIDTH, 1, 0))
	local grid = Theme.make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.WoodLight,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = well,
	})
	Theme.padding(grid, 6, 6, 6, 6)
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(TILE, TILE),
		CellPadding = UDim2.fromOffset(GAP, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})

	for index, recipe in Recipes.List do
		local button = Theme.make("TextButton", {
			BackgroundColor3 = C.ParchmentDark,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			Parent = grid,
		})
		Theme.corner(button, 6)
		local stroke = Theme.stroke(button, C.TanEdge, 2)
		ItemIcon.create(button, recipe.Output, UDim2.fromScale(0.8, 0.8))
		if recipe.Amount > 1 then
			local amount = Theme.text(button, tostring(recipe.Amount), 15, Theme.Font.Bold)
			amount.AnchorPoint = Vector2.new(1, 1)
			amount.Position = UDim2.new(1, -5, 1, -1)
			amount.Size = UDim2.fromOffset(30, 18)
			amount.TextXAlignment = Enum.TextXAlignment.Right
			amount.ZIndex = 3
		end
		-- Tag on recipes your skills can't make yet
		local lock = Theme.make("TextLabel", {
			Position = UDim2.fromOffset(3, 3),
			Size = UDim2.fromOffset(46, 16),
			BackgroundColor3 = C.WoodLight,
			FontFace = Theme.Font.Bold,
			TextSize = 11,
			TextColor3 = C.Cream,
			Text = "Locked",
			ZIndex = 3,
			Visible = false,
			Parent = button,
		})
		Theme.corner(lock, 4)
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
	local name = Theme.text(frame, label, 14, Theme.Font.Bold, C.InkMuted)
	name.Size = UDim2.new(0, 104, 1, 0)
	local bar = Theme.bar(frame, color, UDim2.new(1, -190, 0, 12))
	bar.Track.AnchorPoint = Vector2.new(0, 0.5)
	bar.Track.Position = UDim2.new(0, 106, 0.5, 0)
	local value = Theme.text(frame, "", 15, Theme.Font.Bold)
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.fromScale(1, 0)
	value.Size = UDim2.new(0, 76, 1, 0)
	value.TextXAlignment = Enum.TextXAlignment.Right
	stats[key] = { Frame = frame, Value = value, Bar = bar }
end

local function buildDetail(parent: Instance)
	local panel = Theme.card(parent, UDim2.new(1, -(GRID_WIDTH + 14), 1, 0), UDim2.fromOffset(GRID_WIDTH + 14, 0))
	Theme.padding(panel, 14, 14, 12, 12)

	-- Photo of the item in a sunken frame
	photo = Theme.inset(panel, UDim2.fromOffset(132, 132))

	nameLabel = Theme.title(panel, "", 28)
	nameLabel.Position = UDim2.fromOffset(146, 0)
	nameLabel.Size = UDim2.new(1, -146, 0, 34)
	kindLabel = Theme.text(panel, "", 15, Theme.Font.Bold, C.WoodLight)
	kindLabel.Position = UDim2.fromOffset(146, 38)
	kindLabel.Size = UDim2.new(1, -146, 0, 20)
	goodFor = Theme.text(panel, "", 14, Theme.Font.Medium, C.InkMuted)
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
	statRow(statList, "Efficiency", "Mining speed", C.Leaf, 1)
	statRow(statList, "Damage", "Damage", C.Red, 2)
	statRow(statList, "Durability", "Durability", C.Blue, 3)

	-- Skill levels the recipe needs
	needsRow = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 234),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	local needsLayout = Theme.list(needsRow, Enum.FillDirection.Horizontal, 6)
	needsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	local needsTitle = Theme.title(needsRow, "Skills", 18)
	needsTitle.AutomaticSize = Enum.AutomaticSize.X
	needsTitle.Size = UDim2.fromOffset(0, 24)
	needsTitle.TextTruncate = Enum.TextTruncate.None
	needsTitle.LayoutOrder = 1

	local costTitle = Theme.title(panel, "Needs", 18)
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

	lockLabel = Theme.text(panel, "", 14, Theme.Font.Bold, C.Red)
	lockLabel.AnchorPoint = Vector2.new(1, 1)
	lockLabel.Position = UDim2.new(1, 0, 1, -70)
	lockLabel.Size = UDim2.fromOffset(280, 18)
	lockLabel.TextXAlignment = Enum.TextXAlignment.Right

	craftButton = Theme.button(panel, "Craft", C.Green, UDim2.fromOffset(120, 54), function()
		Remotes.Craft:FireServer(selectedId)
	end)
	craftButton.Holder.AnchorPoint = Vector2.new(1, 1)
	craftButton.Holder.Position = UDim2.new(1, 0, 1, -8)
	craftButton.Label.TextSize = 21
end

function CraftingWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
	end
end

-- Opens the window for a station ("CraftingTable" by default, or "Furnace")
function CraftingWindow.Open(which: Recipes.Station?)
	local wanted: Recipes.Station = which or "CraftingTable"
	if wanted ~= station or Recipes.ById[selectedId].Station ~= wanted then
		station = wanted
		for _, recipe in Recipes.List do
			if recipe.Station == wanted then
				selectedId = recipe.Id
				break
			end
		end
	end
	local info = STATIONS[station]
	window.Title.Text = info.Title
	craftButton.SetText(info.Verb)
	Window.open(window)
end

function CraftingWindow.IsOpen(): boolean
	return window.IsOpen
end

function CraftingWindow.Start()
	window = Window.new("CraftingWindow", "Crafting Table", Vector2.new(760, 480))
	window.OnOpen = render
	buildGrid(window.Body)
	buildDetail(window.Body)
end

return CraftingWindow
