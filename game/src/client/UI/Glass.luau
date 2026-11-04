--!strict
-- The parts of Night Glass (see Theme.luau) the inventory and the HUD use: a stage for your
-- character, inventory slots, cards over the world, text that reads on anything.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemIcon = require(script.Parent.ItemIcon)
local Sfx = require(script.Parent.Sfx)
local Theme = require(script.Parent.Theme)

local Glass = {}

Glass.Color = Theme.Color

Glass.Font = {
	Title = Font.new("rbxasset://fonts/families/Sarpanch.json", Enum.FontWeight.Bold),
	Bold = Theme.Font.Bold,
	Body = Theme.Font.Medium,
}

Glass.panel = Theme.panel
Glass.bar = Theme.bar
Glass.chip = Theme.chip

local C = Glass.Color
local gradient = Theme.gradient

-- A thin light edge. `strength` is how much of it shows, 0 to 1.
local function edge(parent: Instance, strength: number, color: Color3?, thickness: number?): UIStroke
	return Theme.stroke(parent, color or C.Edge, thickness or 1, 1 - strength)
end

-- The small kind of panel that sits over the world: a card or a pill
function Glass.card(parent: Instance, size: UDim2, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.12,
		Parent = parent,
	})
	Theme.corner(frame, 14)
	edge(frame, 0.14)
	return frame
end

-- A lighter box inside a panel
function Glass.inset(parent: Instance, size: UDim2, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Edge,
		BackgroundTransparency = 0.95,
		Parent = parent,
	})
	Theme.corner(frame, 12)
	edge(frame, 0.1)
	return frame
end

-- The lit stage your character stands on
function Glass.stage(parent: Instance, size: UDim2, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Edge,
		ClipsDescendants = true,
		Parent = parent,
	})
	gradient(frame, C.StageTop, C.StageBottom)
	Theme.corner(frame, 14)
	edge(frame, 0.1)
	return frame
end

-- A soft round light. It can't show behind its own parent, so put it under what it lights up.
function Glass.glow(parent: Instance, color: Color3, size: UDim2, position: UDim2, transparency: number?): ImageLabel
	return Theme.make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		Image = Config.GlowImage,
		ImageColor3 = color,
		ImageTransparency = transparency or 0,
		ZIndex = 0,
		Parent = parent,
	})
end

function Glass.text(parent: Instance, text: string, size: number, font: Font?, color: Color3?): TextLabel
	return Theme.make("TextLabel", {
		Text = text,
		TextSize = size,
		FontFace = font or Glass.Font.Body,
		TextColor3 = color or C.Ink,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, size + 4),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
end

-- Text straight over the world gets a soft dark edge so it reads on anything
function Glass.worldText(parent: Instance, text: string, size: number, font: Font?, color: Color3?): TextLabel
	local label = Glass.text(parent, text, size, font or Glass.Font.Bold, color)
	Theme.outline(label)
	return label
end

export type Button = { Face: TextButton, Label: TextLabel, Stroke: UIStroke, SetText: (text: string) -> () }

function Glass.button(parent: Instance, text: string, size: UDim2, onClick: (() -> ())?): Button
	local face = Theme.make("TextButton", {
		Size = size,
		BackgroundColor3 = C.Edge,
		BackgroundTransparency = 0.05,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	gradient(face, C.SlotTop, C.SlotBottom)
	Theme.corner(face, 12)
	local stroke = edge(face, 0.7, C.Accent, 1.5)
	local label = Glass.text(face, text, 17, Glass.Font.Bold)
	label.Size = UDim2.fromScale(1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.ZIndex = 2
	local hover = TweenInfo.new(0.1)
	face.MouseEnter:Connect(function()
		TweenService:Create(stroke, hover, { Transparency = 0 }):Play()
	end)
	face.MouseLeave:Connect(function()
		TweenService:Create(stroke, hover, { Transparency = 0.3 }):Play()
	end)
	if onClick then
		face.Activated:Connect(function()
			Sfx.play("Click")
			onClick()
		end)
	end
	return {
		Face = face,
		Label = label,
		Stroke = stroke,
		SetText = function(value: string)
			label.Text = value
		end,
	}
end

function Glass.setChip(chip: TextLabel, text: string, color: Color3)
	chip.Text = text
	chip.TextColor3 = color
	local stroke = chip:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end
end

export type Slot = {
	Button: TextButton,
	Stroke: UIStroke,
	Fill: UIGradient,
	Icon: Frame,
	Count: TextLabel,
	Item: string,
	Selected: boolean,
}

-- An inventory slot: dark and sunken while it's empty, lit when it holds something
function Glass.slot(parent: Instance, size: number, position: UDim2?): Slot
	local button = Theme.make("TextButton", {
		Size = UDim2.fromOffset(size, size),
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.15,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	Theme.corner(button, math.round(size * 0.17))
	local stroke = edge(button, 0.09, nil, 1.5)
	local fill = gradient(button, C.SlotTop, C.SlotBottom)
	fill.Enabled = false
	local icon = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = button,
	})
	local count = Glass.worldText(button, "", math.round(size * 0.24), Glass.Font.Bold)
	count.AnchorPoint = Vector2.new(1, 1)
	count.Position = UDim2.new(1, -5, 1, -2)
	count.Size = UDim2.new(1, -8, 0, math.round(size * 0.3))
	count.TextXAlignment = Enum.TextXAlignment.Right
	count.ZIndex = 3
	local slot: Slot = {
		Button = button,
		Stroke = stroke,
		Fill = fill,
		Icon = icon,
		Count = count,
		Item = "",
		Selected = false,
	}
	button.MouseEnter:Connect(function()
		if not slot.Selected then
			stroke.Transparency = 0.55
		end
	end)
	button.MouseLeave:Connect(function()
		if not slot.Selected then
			stroke.Transparency = if slot.Item ~= "" then 0.8 else 0.91
		end
	end)
	return slot
end

-- Shows an item in a slot ("" for empty). Only redraws the picture when the item changes.
function Glass.setSlot(slot: Slot, itemId: string, count: number)
	local item = if count > 0 then itemId else ""
	if slot.Item ~= item then
		slot.Item = item
		for _, child in slot.Icon:GetChildren() do
			child:Destroy()
		end
		if item ~= "" then
			ItemIcon.create(slot.Icon, item, UDim2.fromScale(0.78, 0.78))
		end
		slot.Fill.Enabled = item ~= ""
		slot.Button.BackgroundColor3 = if item ~= "" then C.Edge else C.Well
		slot.Button.BackgroundTransparency = if item ~= "" then 0 else 0.15
		if not slot.Selected then
			slot.Stroke.Transparency = if item ~= "" then 0.8 else 0.91
		end
	end
	slot.Count.Text = if count > 1 then tostring(count) else ""
end

function Glass.setSelected(slot: Slot, selected: boolean, color: Color3?)
	slot.Selected = selected
	slot.Stroke.Color = if selected then color or C.Accent else C.Edge
	slot.Stroke.Thickness = if selected then 3 else 1.5
	slot.Stroke.Transparency = if selected then 0 elseif slot.Item ~= "" then 0.8 else 0.91
end

return Glass
