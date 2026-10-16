--!strict
-- Workbench menu: lists recipes with what you have vs. what you need. The server
-- decides whether crafting actually works.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CraftingMenu = {}

local gui: ScreenGui
local list: ScrollingFrame
local state: any = nil

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function render()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local items = if state then state.Items else {}
	local level = if state then state.Level else 1

	for index, recipe in Recipes.List do
		local row = Instance.new("Frame")
		row.LayoutOrder = index
		row.Size = UDim2.new(1, -8, 0, 64)
		row.BackgroundColor3 = Color3.fromRGB(40, 46, 60)
		row.Parent = list
		corner(row, 8)

		local title = Instance.new("TextLabel")
		title.Position = UDim2.fromOffset(10, 6)
		title.Size = UDim2.new(1, -120, 0, 22)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 17
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = Color3.new(1, 1, 1)
		title.Text = Items[recipe.Output].Name
		title.Parent = row

		local canCraft = level >= recipe.PlayerLevel
		local needs = {}
		for itemId, count in recipe.Inputs do
			local have = items[itemId] or 0
			if have < count then
				canCraft = false
			end
			table.insert(needs, `{Items[itemId].Name} {have}/{count}`)
		end
		if level < recipe.PlayerLevel then
			table.insert(needs, `needs level {recipe.PlayerLevel}`)
		end

		local cost = Instance.new("TextLabel")
		cost.Position = UDim2.fromOffset(10, 32)
		cost.Size = UDim2.new(1, -120, 0, 24)
		cost.BackgroundTransparency = 1
		cost.Font = Enum.Font.Gotham
		cost.TextSize = 13
		cost.TextWrapped = true
		cost.TextXAlignment = Enum.TextXAlignment.Left
		cost.TextColor3 = if canCraft then Color3.fromRGB(170, 230, 170) else Color3.fromRGB(230, 170, 170)
		cost.Text = table.concat(needs, "  ·  ")
		cost.Parent = row

		local button = Instance.new("TextButton")
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, -10, 0.5, 0)
		button.Size = UDim2.fromOffset(96, 40)
		button.BackgroundColor3 = if canCraft then Color3.fromRGB(70, 170, 80) else Color3.fromRGB(80, 80, 90)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 16
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Text = "Craft"
		button.AutoButtonColor = canCraft
		button.Parent = row
		corner(button, 8)
		button.Activated:Connect(function()
			Remotes.Craft:FireServer(recipe.Id)
		end)
	end
end

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "Crafting"
	gui.ResetOnSpawn = false
	gui.Enabled = false

	local window = Instance.new("Frame")
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromOffset(420, 320)
	window.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	window.Parent = gui
	corner(window, 12)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(420, 320)
	sizeLimit.Parent = window

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(14, 8)
	title.Size = UDim2.new(1, -60, 0, 30)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = "Workbench"
	title.Parent = window

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -8, 0, 8)
	close.Size = UDim2.fromOffset(34, 34)
	close.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "X"
	close.Parent = window
	corner(close, 8)
	close.Activated:Connect(function()
		gui.Enabled = false
	end)

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(10, 46)
	list.Size = UDim2.new(1, -20, 1, -56)
	list.BackgroundTransparency = 1
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = window
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	gui.Parent = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
end

function CraftingMenu.SetState(newState: any)
	state = newState
	if gui.Enabled then
		render()
	end
end

function CraftingMenu.Open()
	render()
	gui.Enabled = true
end

function CraftingMenu.Start()
	build()
end

return CraftingMenu
