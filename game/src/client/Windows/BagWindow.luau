--!strict
-- Minecraft-style inventory: every item you own in a slot grid, with your hotbar along
-- the bottom. Click a hotbar slot to pick it, then click an item to put it there.
-- Right-click a hotbar slot to empty it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Hotbar = require(script.Parent.Parent.Hotbar)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)

local PIXEL = Font.fromEnum(Enum.Font.Arcade)
local PANEL = Color3.fromRGB(198, 198, 198)
local SLOT_BG = Color3.fromRGB(139, 139, 139)
local DARK = Color3.fromRGB(55, 55, 55)
local TEXT = Color3.fromRGB(63, 63, 63)
local SLOT = 54

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

local gui: ScreenGui
local panel: Frame
local grid: ScrollingFrame
local hotbarRow: Frame
local info: TextLabel
local state: any = nil
local isOpen = false

local function slotFrame(parent: Instance, order: number): TextButton
	local slot = Theme.make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(SLOT, SLOT),
		BackgroundColor3 = SLOT_BG,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	Theme.stroke(slot, DARK, 2)
	slot.MouseEnter:Connect(function()
		slot.BackgroundColor3 = Color3.fromRGB(165, 165, 165)
	end)
	slot.MouseLeave:Connect(function()
		slot.BackgroundColor3 = SLOT_BG
	end)
	return slot
end

local function countLabel(slot: Instance, count: number)
	if count <= 1 then
		return
	end
	for i, color in { Color3.fromRGB(62, 62, 62), Color3.new(1, 1, 1) } do
		local label = Theme.make("TextLabel", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, if i == 1 then -1 else -3, 1, if i == 1 then 1 else -1),
			Size = UDim2.fromOffset(40, 18),
			BackgroundTransparency = 1,
			FontFace = PIXEL,
			TextSize = 18,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = tostring(count),
			ZIndex = 2 + i,
			Parent = slot,
		})
		label.Active = false
	end
end

local function render()
	for _, child in grid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for _, child in hotbarRow:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
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
				local uses = if tool then `  ({tool.Durability - (state.Wear[itemId] or 0)} uses left)` else ""
				info.Text = `{Items[itemId].Name}{uses}  -  click to put in hotbar slot {Hotbar.Selected()}`
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
			stroke.Color = Color3.fromRGB(250, 250, 250)
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
	if isOpen then
		render()
	end
end

local function setOpen(open: boolean)
	isOpen = open
	gui.Enabled = open
	if open then
		render()
		local scale = panel:FindFirstChild("OpenScale") :: UIScale
		scale.Scale = 0.85
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

function BagWindow.Toggle()
	setOpen(not isOpen)
end

function BagWindow.Start()
	gui = Theme.screen("Inventory", 10)
	gui.IgnoreGuiInset = true
	gui.Enabled = false

	local dim = Theme.make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		AutoButtonColor = false,
		Text = "",
		Parent = gui,
	})
	dim.Activated:Connect(function()
		setOpen(false)
	end)

	local holder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 400),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(holder)
	panel = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = PANEL,
		Parent = holder,
	})
	Theme.stroke(panel, Color3.new(0, 0, 0), 3)
	Theme.corner(panel, 4)
	Theme.make("UIScale", { Name = "OpenScale", Parent = panel })

	local title = Theme.make("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -60, 0, 24),
		BackgroundTransparency = 1,
		FontFace = PIXEL,
		TextSize = 24,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Inventory",
		Parent = panel,
	})
	title.Active = false

	local close = Theme.make("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = SLOT_BG,
		FontFace = PIXEL,
		TextSize = 22,
		TextColor3 = TEXT,
		Text = "X",
		Parent = panel,
	})
	Theme.stroke(close, DARK, 2)
	close.Activated:Connect(function()
		setOpen(false)
	end)

	grid = Theme.make("ScrollingFrame", {
		Position = UDim2.fromOffset(14, 44),
		Size = UDim2.new(1, -28, 0, 3 * (SLOT + 4) + 6),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = DARK,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(SLOT, SLOT),
		CellPadding = UDim2.fromOffset(4, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	Theme.padding(grid, 2, 2, 2, 2)

	info = Theme.make("TextLabel", {
		Position = UDim2.fromOffset(14, 44 + 3 * (SLOT + 4) + 14),
		Size = UDim2.new(1, -28, 0, 36),
		BackgroundTransparency = 1,
		FontFace = PIXEL,
		TextSize = 16,
		TextColor3 = TEXT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Pick a hotbar slot below, then click an item to put it there.",
		Parent = panel,
	})

	local hotbarTitle = Theme.make("TextLabel", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -(SLOT + 22)),
		Size = UDim2.new(1, -28, 0, 20),
		BackgroundTransparency = 1,
		FontFace = PIXEL,
		TextSize = 18,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Hotbar  (right-click a slot to empty it)",
		Parent = panel,
	})
	hotbarTitle.Active = false

	hotbarRow = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(5 * SLOT + 4 * 6, SLOT),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	local layout = Theme.list(hotbarRow, Enum.FillDirection.Horizontal, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
end

return BagWindow
