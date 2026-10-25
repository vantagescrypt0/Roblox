--!strict
-- The Bag: every item you own in a slot grid, with your hotbar along the bottom. Click a
-- hotbar slot to pick it, then click an item to put it there. Right-click a hotbar slot to
-- empty it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Hotbar = require(script.Parent.Parent.Hotbar)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local SLOT = 54
local GAP = 6
local COLUMNS = 7
local ROWS = 3

-- Display order: blocks, materials, seeds, crops, Warzone materials, then every tool
local ORDER = {
	"Grass",
	"Dirt",
	"Wood",
	"Planks",
	"Stone",
	"Sticks",
	"Furnace",
	"Coal",
	"RawIron",
	"IronIngot",
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
}
for _, tool in Tools.List do
	table.insert(ORDER, tool.Item)
end

local BagWindow = {}

local window: Window.Window
local grid: ScrollingFrame
local hotbarRow: Frame
local info: TextLabel
local state: any = nil

local function slotFrame(parent: Instance, order: number): TextButton
	local slot = Theme.make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(SLOT, SLOT),
		BackgroundColor3 = C.ParchmentDark,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	Theme.corner(slot, 5)
	Theme.stroke(slot, C.TanEdge, 2)
	slot.MouseEnter:Connect(function()
		slot.BackgroundColor3 = C.Parchment
	end)
	slot.MouseLeave:Connect(function()
		slot.BackgroundColor3 = C.ParchmentDark
	end)
	return slot
end

local function countLabel(slot: Instance, count: number)
	if count <= 1 then
		return
	end
	local label = Theme.text(slot, tostring(count), 15, Theme.Font.Bold)
	label.AnchorPoint = Vector2.new(1, 1)
	label.Position = UDim2.new(1, -4, 1, 0)
	label.Size = UDim2.fromOffset(40, 17)
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.ZIndex = 3
end

local function render()
	Window.clear(grid)
	Window.clear(hotbarRow)
	if not state then
		return
	end

	for order, itemId in ORDER do
		local count = state.Items[itemId] or 0
		if count > 0 then
			local slot = slotFrame(grid, order)
			ItemIcon.create(slot, itemId, UDim2.fromScale(0.8, 0.8))
			countLabel(slot, count)
			slot.MouseEnter:Connect(function()
				local tool = Tools.ByItem[itemId]
				local uses = if tool then ` - {tool.Durability - (state.Wear[itemId] or 0)} uses left` else ""
				info.Text = `{Items[itemId].Name}{uses}`
			end)
			slot.Activated:Connect(function()
				Remotes.SetHotbar:FireServer(Hotbar.Selected(), itemId)
			end)
		end
	end

	for index = 1, 5 do
		local slot = slotFrame(hotbarRow, index)
		local itemId = state.Hotbar[index] or ""
		local count = if itemId ~= "" then state.Items[itemId] or 0 else 0
		if count > 0 then
			ItemIcon.create(slot, itemId, UDim2.fromScale(0.8, 0.8))
			countLabel(slot, count)
		end
		local stroke = slot:FindFirstChildOfClass("UIStroke")
		if index == Hotbar.Selected() and stroke then
			stroke.Color = C.Ochre
			stroke.Thickness = 3
		end
		slot.Activated:Connect(function()
			Hotbar.Select(index)
			render()
		end)
		slot.MouseButton2Click:Connect(function()
			Remotes.SetHotbar:FireServer(index, "")
		end)
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
	local gridWidth = COLUMNS * SLOT + (COLUMNS - 1) * GAP + 14
	local gridHeight = ROWS * SLOT + (ROWS - 1) * GAP + 10
	window = Window.new("Inventory", "Bag", Vector2.new(gridWidth + 28 + 20, gridHeight + SLOT + 184))
	window.OnOpen = function()
		info.Text = ""
		render()
	end
	local body = window.Body

	local well = Theme.inset(body, UDim2.new(1, 0, 0, gridHeight + 4))
	grid = Theme.make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.WoodLight,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = well,
	})
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(SLOT, SLOT),
		CellPadding = UDim2.fromOffset(GAP, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	Theme.padding(grid, 7, 7, 7, 7)

	info = Theme.text(body, "", 15, Theme.Font.Bold, C.InkMuted)
	info.Position = UDim2.fromOffset(2, gridHeight + 12)
	info.Size = UDim2.new(1, -4, 0, 20)

	local hotbarTitle = Theme.title(body, "Hotbar", 22)
	hotbarTitle.AnchorPoint = Vector2.new(0, 1)
	hotbarTitle.Position = UDim2.new(0, 2, 1, -(SLOT + 6))
	hotbarTitle.Size = UDim2.new(1, -4, 0, 26)

	hotbarRow = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(5 * SLOT + 4 * GAP, SLOT),
		BackgroundTransparency = 1,
		Parent = body,
	})
	local layout = Theme.list(hotbarRow, Enum.FillDirection.Horizontal, GAP)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
end

return BagWindow
