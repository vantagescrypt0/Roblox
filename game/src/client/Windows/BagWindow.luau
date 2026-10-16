--!strict
-- Inventory grid: every item you own with its icon and count.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

-- Display order: resources, seeds, crops, Warzone materials, gear
local ORDER = {
	"Wood",
	"Stone",
	"WheatSeeds",
	"CarrotSeeds",
	"PotatoSeeds",
	"GlowberrySeeds",
	"Wheat",
	"Carrot",
	"Potato",
	"Glowberry",
	"Scrap",
	"Crystal",
	"WoodenSword",
	"StoneSword",
	"CrystalSword",
}

local BagWindow = {}

local window: Window.Window
local grid: ScrollingFrame
local state: any = nil

local function slot(itemId: string, count: number, order: number)
	local item = Items[itemId]
	local card = Theme.make("Frame", {
		LayoutOrder = order,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = grid,
	})
	Theme.gradient(card, Theme.lighten(C.Row, 0.08), C.Row)
	Theme.corner(card, 12)
	Theme.stroke(card, C.Stroke, 2)
	Theme.make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 56),
		Position = UDim2.fromOffset(0, 6),
		BackgroundTransparency = 1,
		Text = item and item.Icon or "❔",
		TextSize = 40,
		Parent = card,
	})
	local name = Theme.text(card, item and item.Name or itemId, 12, Theme.Font.Bold, C.Muted)
	name.Position = UDim2.new(0, 4, 1, -34)
	name.Size = UDim2.new(1, -8, 0, 30)
	name.TextWrapped = true
	name.TextTruncate = Enum.TextTruncate.None
	name.TextXAlignment = Enum.TextXAlignment.Center
	name.TextYAlignment = Enum.TextYAlignment.Center
	local badge = Theme.chip(card, `x{count}`, C.Gold)
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, -4, 0, 4)
	badge.Size = UDim2.fromOffset(0, 22)
	badge.TextSize = 13
end

local function render()
	Window.clear(grid)
	if not state then
		return
	end
	local shown = 0
	for index, itemId in ORDER do
		local count = state.Items[itemId] or 0
		if count > 0 then
			slot(itemId, count, index)
			shown += 1
		end
	end
	if shown == 0 then
		local empty = Theme.title(grid, "Your bag is empty.\nChop trees and farm to fill it!", 20, C.Muted)
		empty.Size = UDim2.new(1, 0, 0, 60)
		empty.TextWrapped = true
		empty.TextXAlignment = Enum.TextXAlignment.Center
	end
end

function BagWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
	end
end

function BagWindow.Toggle()
	Window.toggle(window)
end

function BagWindow.Start()
	window = Window.new("BagWindow", "Bag", "🎒", Vector2.new(540, 430))
	window.OnOpen = render
	grid = Theme.make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = window.Body,
	})
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(92, 108),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	Theme.padding(grid, 4, 4, 4, 4)
end

return BagWindow
