--!strict
-- The hotbar: 5 white slots on a navy bar along the bottom of the screen. Keys 1-5
-- or tapping a slot selects it; the selected item's name shows above the bar for a moment.
-- Worn tools show a durability bar (green when fresh, red when nearly broken).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tools = require(ReplicatedStorage.Shared.Tools)
local ItemIcon = require(script.Parent.UI.ItemIcon)
local Theme = require(script.Parent.UI.Theme)

local C = Theme.Color

local SLOTS = 5
local SLOT = 60
local GAP = 6
local EDGE = 8
local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }

local Hotbar = {}

type Slot = {
	Frame: TextButton,
	Stroke: UIStroke,
	Icon: Frame,
	Count: TextLabel,
	Durability: Frame,
	DurabilityFill: Frame,
	ItemId: string,
}

local slots: { Slot } = {}
local selector: Frame
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
	nameLabel.Text = if itemId then Items[itemId].Name else ""
	nameLabel.TextTransparency = 0
	local stroke = nameLabel:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Transparency = 0
	task.delay(1.6, function()
		if token == nameToken then
			local fade = TweenInfo.new(0.4)
			TweenService:Create(nameLabel, fade, { TextTransparency = 1 }):Play()
			TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
		end
	end)
end

local function slotX(index: number): number
	return EDGE + (index - 1) * (SLOT + GAP)
end

function Hotbar.Select(slot: number)
	selected = math.clamp(slot, 1, SLOTS)
	selector.Position = UDim2.fromOffset(slotX(selected) - 4, EDGE - 4)
	for index, entry in slots do
		entry.Stroke.Color = if index == selected then C.Gold else C.NavyLight
	end
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
				ItemIcon.create(slot.Icon, itemId, UDim2.fromScale(0.8, 0.8))
			end
		end
		slot.Count.Text = if count > 1 then tostring(count) else ""

		-- Durability bar, only once a tool has been used
		local tool = Tools.ByItem[itemId]
		local wear = if tool then (state.Wear and state.Wear[itemId]) or 0 else 0
		slot.Durability.Visible = tool ~= nil and wear > 0
		if tool and wear > 0 then
			local left = math.clamp(1 - wear / tool.Durability, 0, 1)
			slot.DurabilityFill.Size = UDim2.fromScale(left, 1)
			slot.DurabilityFill.BackgroundColor3 = C.Red:Lerp(C.Leaf, left)
		end
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
	local width = SLOTS * SLOT + (SLOTS - 1) * GAP + EDGE * 2
	local bar = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(width, SLOT + EDGE * 2),
		BackgroundColor3 = C.Navy,
		Parent = gui,
	})
	Theme.corner(bar, 14)
	Theme.stroke(bar, C.Outline, 3)
	Theme.autoScale(bar)

	for index = 1, SLOTS do
		local frame = Theme.make("TextButton", {
			Position = UDim2.fromOffset(slotX(index), EDGE),
			Size = UDim2.fromOffset(SLOT, SLOT),
			BackgroundColor3 = C.Panel,
			AutoButtonColor = false,
			Text = "",
			Parent = bar,
		})
		Theme.corner(frame, 10)
		local stroke = Theme.stroke(frame, C.NavyLight, 3)
		local number = Theme.text(frame, tostring(index), 11, Theme.Font.Bold, C.InkMuted)
		number.Position = UDim2.fromOffset(5, 2)
		number.Size = UDim2.fromOffset(12, 13)
		local icon = Theme.make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = frame,
		})
		local count = Theme.text(frame, "", 16, Theme.Font.Bold, C.Ink)
		count.AnchorPoint = Vector2.new(1, 1)
		count.Position = UDim2.new(1, -5, 1, -1)
		count.Size = UDim2.fromOffset(40, 18)
		count.TextXAlignment = Enum.TextXAlignment.Right
		count.ZIndex = 3
		local durability = Theme.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -5),
			Size = UDim2.new(1, -16, 0, 5),
			BackgroundColor3 = C.Outline,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 4,
			Parent = frame,
		})
		Theme.corner(durability, 2)
		local durabilityFill = Theme.make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.Leaf,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = durability,
		})
		Theme.corner(durabilityFill, 2)
		frame.Activated:Connect(function()
			Hotbar.Select(index)
		end)
		slots[index] = {
			Frame = frame,
			Stroke = stroke,
			Icon = icon,
			Count = count,
			Durability = durability,
			DurabilityFill = durabilityFill,
			ItemId = "",
		}
	end

	-- Gold glow around the selected slot (its own outline turns gold too)
	selector = Theme.make("Frame", {
		Size = UDim2.fromOffset(SLOT + 8, SLOT + 8),
		BackgroundColor3 = C.Gold,
		ZIndex = 0,
		Parent = bar,
	})
	Theme.corner(selector, 13)
	Theme.stroke(selector, C.Outline, 2)

	nameLabel = Theme.worldTitle(bar, "", 24)
	nameLabel.AnchorPoint = Vector2.new(0.5, 1)
	nameLabel.Position = UDim2.new(0.5, 0, 0, -8)
	nameLabel.Size = UDim2.fromOffset(width, 28)
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
