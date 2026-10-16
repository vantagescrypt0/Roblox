--!strict
-- Minecraft-style hotbar: 5 slots along the bottom of the screen. Keys 1-5 or tapping a
-- slot selects it; the selected item's name pops up above the bar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemIcon = require(script.Parent.UI.ItemIcon)
local Theme = require(script.Parent.UI.Theme)

local SLOTS = 5
local SLOT = 62
local GAP = 4
local PIXEL = Font.fromEnum(Enum.Font.Arcade)
local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }

local Hotbar = {}

type Slot = { Frame: Frame, Icon: Frame, Count: TextLabel, CountShadow: TextLabel, ItemId: string }

local slots: { Slot } = {}
local selector: Frame
local nameLabel: TextLabel
local nameShadow: TextLabel
local selected = 1
local state: any = nil
local listeners: { () -> () } = {}
local nameToken = 0

-- Pixel text with a dark drop shadow, like Minecraft's
local function pixelText(parent: Instance, size: number): (TextLabel, TextLabel)
	local shadow = Theme.make("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = PIXEL,
		TextSize = size,
		TextColor3 = Color3.fromRGB(62, 62, 62),
		Text = "",
		Parent = parent,
	})
	local text = Theme.make("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = PIXEL,
		TextSize = size,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "",
		ZIndex = 3,
		Parent = parent,
	})
	return text, shadow
end

function Hotbar.Selected(): number
	return selected
end

-- Item id in the selected slot (nil if empty)
function Hotbar.SelectedItem(): string?
	local itemId = state and state.Hotbar[selected]
	if itemId and itemId ~= "" and (state.Items[itemId] or 0) > 0 then
		return itemId
	end
	return nil
end

function Hotbar.OnChanged(listener: () -> ())
	table.insert(listeners, listener)
end

local function showName()
	nameToken += 1
	local token = nameToken
	local itemId = Hotbar.SelectedItem()
	local text = if itemId then Items[itemId].Name else ""
	nameLabel.Text = text
	nameShadow.Text = text
	nameLabel.TextTransparency = 0
	nameShadow.TextTransparency = 0
	task.delay(1.6, function()
		if token == nameToken then
			local fade = TweenInfo.new(0.4)
			TweenService:Create(nameLabel, fade, { TextTransparency = 1 }):Play()
			TweenService:Create(nameShadow, fade, { TextTransparency = 1 }):Play()
		end
	end)
end

function Hotbar.Select(slot: number)
	selected = math.clamp(slot, 1, SLOTS)
	selector.Position = UDim2.fromOffset(6 + (selected - 1) * (SLOT + GAP) - 4, 2)
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
		local itemId = state.Hotbar[index] or ""
		local count = if itemId ~= "" then state.Items[itemId] or 0 else 0
		if count <= 0 then
			itemId = ""
		end
		if slot.ItemId ~= itemId then
			slot.ItemId = itemId
			for _, child in slot.Icon:GetChildren() do
				child:Destroy()
			end
			if itemId ~= "" then
				ItemIcon.create(slot.Icon, itemId, UDim2.fromScale(0.82, 0.82))
			end
		end
		local countText = if count > 1 then tostring(count) else ""
		slot.Count.Text = countText
		slot.CountShadow.Text = countText
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
	local width = SLOTS * SLOT + (SLOTS - 1) * GAP + 12
	local bar = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(width, SLOT + 12),
		BackgroundColor3 = Color3.fromRGB(16, 16, 16),
		BackgroundTransparency = 0.35,
		Parent = gui,
	})
	Theme.stroke(bar, Color3.new(0, 0, 0), 2)
	Theme.autoScale(bar)

	for index = 1, SLOTS do
		local frame = Theme.make("TextButton", {
			Position = UDim2.fromOffset(6 + (index - 1) * (SLOT + GAP), 6),
			Size = UDim2.fromOffset(SLOT, SLOT),
			BackgroundColor3 = Color3.fromRGB(110, 110, 110),
			BackgroundTransparency = 0.45,
			AutoButtonColor = false,
			Text = "",
			Parent = bar,
		})
		Theme.stroke(frame, Color3.fromRGB(58, 58, 58), 2)
		local number = Theme.make("TextLabel", {
			Position = UDim2.fromOffset(4, 2),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			FontFace = PIXEL,
			TextSize = 11,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextTransparency = 0.3,
			Text = tostring(index),
			Parent = frame,
		})
		number.TextXAlignment = Enum.TextXAlignment.Left
		local icon = Theme.make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = frame,
		})
		local count, shadow = pixelText(frame, 20)
		count.AnchorPoint = Vector2.new(1, 1)
		count.Position = UDim2.new(1, -4, 1, -2)
		count.Size = UDim2.fromOffset(40, 20)
		count.TextXAlignment = Enum.TextXAlignment.Right
		shadow.AnchorPoint = Vector2.new(1, 1)
		shadow.Position = UDim2.new(1, -2, 1, 0)
		shadow.Size = UDim2.fromOffset(40, 20)
		shadow.TextXAlignment = Enum.TextXAlignment.Right
		frame.Activated:Connect(function()
			Hotbar.Select(index)
		end)
		slots[index] = { Frame = frame, Icon = icon, Count = count, CountShadow = shadow, ItemId = "" }
	end

	-- Selected-slot frame: white with a dark outline
	selector = Theme.make("Frame", {
		Size = UDim2.fromOffset(SLOT + 8, SLOT + 8),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = bar,
	})
	Theme.stroke(selector, Color3.new(0, 0, 0), 2)
	local inner = Theme.make("Frame", {
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = selector,
	})
	Theme.stroke(inner, Color3.fromRGB(240, 240, 240), 3)

	nameLabel, nameShadow = pixelText(bar, 22)
	nameLabel.AnchorPoint = Vector2.new(0.5, 1)
	nameLabel.Position = UDim2.new(0.5, 0, 0, -10)
	nameLabel.Size = UDim2.fromOffset(width, 24)
	nameShadow.AnchorPoint = Vector2.new(0.5, 1)
	nameShadow.Position = UDim2.new(0.5, 2, 0, -8)
	nameShadow.Size = UDim2.fromOffset(width, 24)

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
