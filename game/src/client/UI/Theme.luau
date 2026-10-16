--!strict
-- Shared look for every screen: colors, fonts and small builders for panels, text,
-- chunky 3D buttons, progress bars and chips. Keeps the whole UI consistent.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Theme = {}

Theme.Color = {
	Panel = Color3.fromRGB(30, 36, 54),
	PanelTop = Color3.fromRGB(48, 57, 86),
	Inset = Color3.fromRGB(20, 24, 37),
	Row = Color3.fromRGB(39, 46, 69),
	Stroke = Color3.fromRGB(10, 12, 20),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(170, 180, 205),
	Gold = Color3.fromRGB(255, 200, 60),
	Green = Color3.fromRGB(88, 204, 102),
	Red = Color3.fromRGB(240, 82, 90),
	Blue = Color3.fromRGB(70, 160, 255),
	Purple = Color3.fromRGB(160, 110, 255),
	Orange = Color3.fromRGB(255, 150, 60),
	Grey = Color3.fromRGB(95, 102, 125),
}

Theme.Font = {
	Title = Font.fromEnum(Enum.Font.FredokaOne),
	Bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	Medium = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
}

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

function Theme.darken(color: Color3, amount: number): Color3
	return color:Lerp(BLACK, amount)
end

function Theme.lighten(color: Color3, amount: number): Color3
	return color:Lerp(WHITE, amount)
end

-- Creates an instance from a property table (Parent is set last)
function Theme.make(className: string, props: { [string]: any }): any
	local inst = Instance.new(className) :: any
	for key, value in props do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Theme.corner(parent: Instance, radius: number?): UICorner
	return Theme.make("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = parent })
end

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Theme.make("UIStroke", {
		Color = color or Theme.Color.Stroke,
		Thickness = thickness or 2.5,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- Vertical gradient. The object's BackgroundColor3 should be white.
function Theme.gradient(parent: Instance, top: Color3, bottom: Color3): UIGradient
	return Theme.make("UIGradient", {
		Color = ColorSequence.new(top, bottom),
		Rotation = 90,
		Parent = parent,
	})
end

function Theme.padding(parent: Instance, left: number, right: number?, top: number?, bottom: number?): UIPadding
	return Theme.make("UIPadding", {
		PaddingLeft = UDim.new(0, left),
		PaddingRight = UDim.new(0, right or left),
		PaddingTop = UDim.new(0, top or left),
		PaddingBottom = UDim.new(0, bottom or top or left),
		Parent = parent,
	})
end

function Theme.list(parent: Instance, direction: Enum.FillDirection?, gap: number?): UIListLayout
	return Theme.make("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = parent,
	})
end

-- Dark card with a soft top highlight and a thick outline
function Theme.panel(parent: Instance, size: UDim2, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = WHITE,
		Parent = parent,
	})
	Theme.gradient(frame, Theme.Color.PanelTop, Theme.Color.Panel)
	Theme.corner(frame, 14)
	Theme.stroke(frame)
	return frame
end

function Theme.text(parent: Instance, text: string, size: number, font: Font?, color: Color3?): TextLabel
	return Theme.make("TextLabel", {
		Text = text,
		TextSize = size,
		FontFace = font or Theme.Font.Bold,
		TextColor3 = color or Theme.Color.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, size + 4),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
end

-- Cartoon title: chunky font with a dark outline
function Theme.title(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local label = Theme.text(parent, text, size, Theme.Font.Title, color)
	Theme.make("UIStroke", {
		Color = Theme.Color.Stroke,
		Thickness = math.max(1.5, size / 12),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = label,
	})
	return label
end

export type Button = {
	Holder: Frame,
	Face: TextButton,
	Label: TextLabel,
	SetEnabled: (enabled: boolean) -> (),
	SetColor: (color: Color3) -> (),
	SetText: (text: string) -> (),
}

-- Chunky 3D button: a darker "lip" under the face; the face presses down when clicked
function Theme.button(parent: Instance, text: string, color: Color3, size: UDim2, onClick: () -> ()): Button
	local holder = Theme.make("Frame", { Size = size, BackgroundTransparency = 1, Parent = parent })
	local lip = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 1, -2),
		Position = UDim2.fromOffset(0, 2),
		BackgroundColor3 = Theme.darken(color, 0.35),
		Parent = holder,
	})
	Theme.corner(lip, 10)
	Theme.stroke(lip, Theme.Color.Stroke, 2)
	local face = Theme.make("TextButton", {
		Size = UDim2.new(1, 0, 1, -5),
		BackgroundColor3 = WHITE,
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	})
	Theme.corner(face, 10)
	local gradient = Theme.gradient(face, Theme.lighten(color, 0.18), color)
	-- Text lives on its own label so the face gradient doesn't tint it
	local label = Theme.make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 18,
		FontFace = Theme.Font.Title,
		TextColor3 = WHITE,
		Parent = face,
	})
	Theme.make("UIStroke", {
		Color = Theme.Color.Stroke,
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = label,
	})
	local scale = Theme.make("UIScale", { Parent = holder })

	local enabled = true
	local current = color
	local quick = TweenInfo.new(0.08)
	face.MouseEnter:Connect(function()
		if enabled then
			TweenService:Create(scale, quick, { Scale = 1.04 }):Play()
		end
	end)
	face.MouseLeave:Connect(function()
		TweenService:Create(scale, quick, { Scale = 1 }):Play()
		face.Position = UDim2.new()
	end)
	face.MouseButton1Down:Connect(function()
		if enabled then
			face.Position = UDim2.fromOffset(0, 3)
		end
	end)
	face.MouseButton1Up:Connect(function()
		face.Position = UDim2.new()
	end)
	face.Activated:Connect(function()
		if enabled then
			onClick()
		end
	end)

	local button: Button
	button = {
		Holder = holder,
		Face = face,
		Label = label,
		SetEnabled = function(value: boolean)
			enabled = value
			local shown = if value then current else Theme.Color.Grey
			gradient.Color = ColorSequence.new(Theme.lighten(shown, 0.18), shown)
			lip.BackgroundColor3 = Theme.darken(shown, 0.35)
			label.TextTransparency = if value then 0 else 0.35
		end,
		SetColor = function(value: Color3)
			current = value
			button.SetEnabled(enabled)
		end,
		SetText = function(value: string)
			label.Text = value
		end,
	}
	return button
end

export type Bar = { Track: Frame, Fill: Frame, Label: TextLabel, Set: (ratio: number, text: string?) -> () }

-- Rounded progress bar with an optional label on top
function Theme.bar(parent: Instance, color: Color3, size: UDim2): Bar
	local track = Theme.make("Frame", { Size = size, BackgroundColor3 = Theme.Color.Inset, Parent = parent })
	Theme.corner(track, 999)
	Theme.stroke(track, Theme.Color.Stroke, 2)
	local fill = Theme.make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = WHITE,
		Parent = track,
	})
	Theme.corner(fill, 999)
	Theme.gradient(fill, Theme.lighten(color, 0.25), color)
	local label = Theme.make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		FontFace = Theme.Font.Title,
		TextSize = 13,
		TextColor3 = WHITE,
		Text = "",
		ZIndex = 3,
		Parent = track,
	})
	Theme.make("UIStroke", {
		Color = Theme.Color.Stroke,
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = label,
	})
	return {
		Track = track,
		Fill = fill,
		Label = label,
		Set = function(ratio: number, text: string?)
			TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
				Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1),
			}):Play()
			if text then
				label.Text = text
			end
		end,
	}
end

-- Small rounded tag, e.g. "🌾 3"
function Theme.chip(parent: Instance, text: string, color: Color3): TextLabel
	local chip = Theme.make("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 26),
		BackgroundColor3 = Theme.darken(color, 0.55),
		Text = text,
		TextSize = 15,
		FontFace = Theme.Font.Title,
		-- White keeps emoji in full color
		TextColor3 = WHITE,
		Parent = parent,
	})
	Theme.corner(chip, 999)
	Theme.stroke(chip, Theme.darken(color, 0.2), 1.5)
	Theme.padding(chip, 10, 10, 0, 0)
	return chip
end

function Theme.formatNumber(n: number): string
	local text = tostring(math.floor(n))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

-- Quick "pop" bounce on any GUI object
function Theme.pop(object: GuiObject, amount: number?)
	local scale = object:FindFirstChildOfClass("UIScale") or Theme.make("UIScale", { Parent = object })
	scale.Scale = amount or 1.15
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
end

-- Shrinks a panel on small (phone) screens. It scales around the panel's AnchorPoint,
-- so anchor panels to the screen edge they sit on.
function Theme.autoScale(object: GuiObject)
	local scale = object:FindFirstChildOfClass("UIScale") or Theme.make("UIScale", { Parent = object })
	local function update()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local size = camera.ViewportSize
		scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.62, 1)
	end
	update()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
end

function Theme.screen(name: string, order: number?): ScreenGui
	local gui = Theme.make("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 0,
	})
	gui.Parent = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
	return gui
end

return Theme
