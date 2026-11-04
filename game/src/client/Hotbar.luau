--!strict
-- The hotbar: the inventory's first 9 slots along the bottom of the screen. Keys 1-9 or tapping a
-- slot selects it; the selected item's name shows above the bar for a moment.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Glass = require(script.Parent.UI.Glass)
local Theme = require(script.Parent.UI.Theme)

local C = Glass.Color

local SLOTS = Inventory.Hotbar
local SLOT = 56
local GAP = 5
local KEYS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
}

local Hotbar = {}

local slots: { Glass.Slot } = {}
local bar: Frame
local shine: ImageLabel
local nameLabel: TextLabel
local selected = 1
local state: any = nil
local listeners: { () -> () } = {}
local nameToken = 0

function Hotbar.Selected(): number
	return selected
end

-- Item id in the selected slot (nil if empty)
function Hotbar.SelectedItem(): string?
	local stack = state and state.Slots[selected]
	if stack and stack.Count > 0 then
		return stack.Item
	end
	return nil
end

-- The bar itself, for what sits on top of it (your hearts)
function Hotbar.Bar(): Frame
	return bar
end

function Hotbar.OnChanged(listener: () -> ())
	table.insert(listeners, listener)
end

local function showName()
	nameToken += 1
	local token = nameToken
	local itemId = Hotbar.SelectedItem()
	nameLabel.Text = if itemId then Items[itemId].Name else ""
	nameLabel.TextTransparency = 0
	local stroke = nameLabel:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Transparency = 0.35
	task.delay(1.6, function()
		if token == nameToken then
			local fade = TweenInfo.new(0.4)
			TweenService:Create(nameLabel, fade, { TextTransparency = 1 }):Play()
			TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
		end
	end)
end

local function slotCenter(index: number): UDim2
	return UDim2.fromOffset((index - 1) * (SLOT + GAP) + SLOT / 2, SLOT / 2)
end

function Hotbar.Select(slot: number)
	selected = math.clamp(slot, 1, SLOTS)
	for index, entry in slots do
		Glass.setSelected(entry, index == selected)
	end
	shine.Position = slotCenter(selected)
	Remotes.SelectSlot:FireServer(selected)
	showName()
	for _, listener in listeners do
		task.spawn(listener)
	end
end

local function render()
	if not state then
		return
	end
	for index, slot in slots do
		local stack = state.Slots[index]
		Glass.setSlot(slot, if stack then stack.Item else "", if stack then stack.Count else 0)
	end
	for _, listener in listeners do
		task.spawn(listener)
	end
end

function Hotbar.SetState(newState: any)
	state = newState
	render()
end

function Hotbar.Start()
	local gui = Theme.screen("Hotbar", 3)
	local width = SLOTS * SLOT + (SLOTS - 1) * GAP
	bar = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(width, SLOT),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(bar)

	shine = Glass.glow(bar, C.Accent, UDim2.fromOffset(SLOT + 34, SLOT + 34), slotCenter(1), 0.45)

	for index = 1, SLOTS do
		local slot = Glass.slot(bar, SLOT, UDim2.fromOffset((index - 1) * (SLOT + GAP), 0))
		-- A little more solid than in the Bag: it's over the world
		slot.Button.BackgroundTransparency = 0.05
		local number = Glass.worldText(slot.Button, tostring(index), 11, Glass.Font.Bold, C.Muted)
		number.Position = UDim2.fromOffset(5, 2)
		number.Size = UDim2.fromOffset(12, 13)
		number.ZIndex = 3
		slot.Button.Activated:Connect(function()
			Hotbar.Select(index)
		end)
		slots[index] = slot
	end

	nameLabel = Glass.worldText(bar, "", 22, Glass.Font.Bold)
	nameLabel.AnchorPoint = Vector2.new(0.5, 1)
	nameLabel.Position = UDim2.new(0.5, 0, 0, -66)
	nameLabel.Size = UDim2.fromOffset(width, 26)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local index = table.find(KEYS, input.KeyCode)
		if index then
			Hotbar.Select(index)
		end
	end)

	Hotbar.Select(1)
end

return Hotbar
