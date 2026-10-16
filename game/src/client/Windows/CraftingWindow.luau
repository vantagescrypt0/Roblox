--!strict
-- Workbench window: each recipe shows what it needs (green = you have enough) and a Craft
-- button. The server decides whether crafting actually works.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local CraftingWindow = {}

local window: Window.Window
local list: ScrollingFrame
local state: any = nil

local function render()
	Window.clear(list)
	if not state then
		return
	end
	for index, recipe in Recipes.List do
		local output = Items[recipe.Output]
		local frame = Theme.make("Frame", {
			Size = UDim2.new(1, 0, 0, 100),
			LayoutOrder = index,
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = list,
		})
		Theme.gradient(frame, Theme.lighten(C.Row, 0.08), C.Row)
		Theme.corner(frame, 12)
		Theme.stroke(frame, C.Stroke, 2)

		local icon = Theme.make("TextLabel", {
			Size = UDim2.fromOffset(76, 76),
			Position = UDim2.fromOffset(12, 12),
			BackgroundColor3 = C.Inset,
			Text = output.Icon,
			TextSize = 44,
			Parent = frame,
		})
		Theme.corner(icon, 12)

		local weapon = Weapons.ByItem[recipe.Output]
		local name = Theme.title(frame, output.Name, 22)
		name.Position = UDim2.fromOffset(100, 10)
		name.Size = UDim2.new(1, -230, 0, 26)
		if weapon then
			local stats = Theme.text(frame, `💥 {weapon.Damage} damage`, 14, Theme.Font.Medium, C.Muted)
			stats.Position = UDim2.fromOffset(100, 36)
			stats.Size = UDim2.new(1, -230, 0, 18)
		end

		-- Ingredient chips: green when you have enough
		local chips = Theme.make("Frame", {
			Position = UDim2.fromOffset(100, 62),
			Size = UDim2.new(1, -230, 0, 28),
			BackgroundTransparency = 1,
			Parent = frame,
		})
		Theme.list(chips, Enum.FillDirection.Horizontal, 6)
		local canCraft = state.Level >= recipe.PlayerLevel
		local order = 0
		for itemId, need in recipe.Inputs do
			local have = state.Items[itemId] or 0
			local enough = have >= need
			canCraft = canCraft and enough
			order += 1
			Theme.chip(chips, `{Items[itemId].Icon} {have}/{need}`, if enough then C.Green else C.Red).LayoutOrder =
				order
		end
		if state.Level < recipe.PlayerLevel then
			Theme.chip(chips, `🔒 Lv {recipe.PlayerLevel}`, C.Purple).LayoutOrder = 99
		end

		local button = Theme.button(frame, "CRAFT", C.Orange, UDim2.fromOffset(112, 56), function()
			Remotes.Craft:FireServer(recipe.Id)
		end)
		button.Holder.AnchorPoint = Vector2.new(1, 0.5)
		button.Holder.Position = UDim2.new(1, -12, 0.5, 0)
		button.Label.TextSize = 22
		button.SetEnabled(canCraft)
	end
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

function CraftingWindow.Start()
	window = Window.new("CraftingWindow", "Workbench", "🔨", Vector2.new(600, 440))
	window.OnOpen = render
	list = Window.scrollList(window.Body, UDim2.fromScale(1, 1))
end

return CraftingWindow
