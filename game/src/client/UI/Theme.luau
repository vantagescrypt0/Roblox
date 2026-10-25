--!strict
-- Shared look for every screen, the "Workshop" style: parchment panels in wooden frames,
-- storybook serif titles (Fondamento) and a rounded body font (Nunito). Flat colors, no
-- gradients and no emoji, so it reads as a crafted game UI rather than a template.
-- Small builders for panels, cards, text, buttons, progress bars and chips keep every
-- screen consistent. Mockup: art/renders/ui-styles.html (style A).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Theme = {}

Theme.Color = {
	-- Paper
	Parchment = Color3.fromRGB(241, 226, 192), -- panels
	ParchmentDark = Color3.fromRGB(232, 213, 174), -- cards and slots on a panel
	Tan = Color3.fromRGB(217, 195, 154), -- insets, bar tracks
	TanEdge = Color3.fromRGB(184, 156, 107), -- outlines on paper
	Chip = Color3.fromRGB(227, 207, 163),
	-- Wood
	WoodLight = Color3.fromRGB(122, 82, 48), -- title bars, wooden buttons
	Wood = Color3.fromRGB(90, 59, 34), -- panel frames
	WoodDark = Color3.fromRGB(74, 47, 27), -- the hotbar
	WoodEdge = Color3.fromRGB(46, 28, 15), -- darkest outline
	SlotEdge = Color3.fromRGB(107, 74, 43),
	-- Text
	Ink = Color3.fromRGB(74, 51, 32), -- text on paper
	InkMuted = Color3.fromRGB(122, 90, 58),
	Cream = Color3.fromRGB(251, 238, 211), -- text on wood and over the world
	-- Accents
	Gold = Color3.fromRGB(242, 193, 78),
	Ochre = Color3.fromRGB(183, 131, 47),
	Green = Color3.fromRGB(92, 154, 62), -- buttons
	Leaf = Color3.fromRGB(78, 154, 107), -- bar fills
	Red = Color3.fromRGB(182, 81, 60),
	Blue = Color3.fromRGB(94, 127, 184),
	Purple = Color3.fromRGB(138, 95, 176),
	Disabled = Color3.fromRGB(179, 163, 133),
}

local NUNITO = "rbxasset://fonts/families/Nunito.json"

Theme.Font = {
	Title = Font.fromEnum(Enum.Font.Fondamento),
	Bold = Font.new(NUNITO, Enum.FontWeight.ExtraBold),
	Medium = Font.new(NUNITO, Enum.FontWeight.SemiBold),
}

local C = Theme.Color
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

function Theme.darken(color: Color3, amount: number): Color3
	return color:Lerp(BLACK, amount)
end

function Theme.lighten(color: Color3, amount: number): Color3
	return color:Lerp(WHITE, amount)
end

-- Cream text on dark colors, ink on light ones
function Theme.textOn(color: Color3): Color3
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return if luminance > 0.6 then C.Ink else C.Cream
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
	return Theme.make("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Theme.make("UIStroke", {
		Color = color or C.Wood,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
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

-- Parchment sheet in a wooden frame
function Theme.panel(parent: Instance, size: UDim2, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Parchment,
		Parent = parent,
	})
	Theme.corner(frame, 7)
	Theme.stroke(frame, C.Wood, 4)
	return frame
end

-- Slightly darker paper card that sits on a panel (list rows, detail boxes)
function Theme.card(parent: Instance, size: UDim2?, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = position or UDim2.new(),
		BackgroundColor3 = C.ParchmentDark,
		Parent = parent,
	})
	Theme.corner(frame, 6)
	Theme.stroke(frame, C.TanEdge, 2)
	return frame
end

-- Sunken box for icons, grids and photos
function Theme.inset(parent: Instance, size: UDim2?, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Tan,
		Parent = parent,
	})
	Theme.corner(frame, 5)
	Theme.stroke(frame, C.TanEdge, 2)
	return frame
end

function Theme.text(parent: Instance, text: string, size: number, font: Font?, color: Color3?): TextLabel
	return Theme.make("TextLabel", {
		Text = text,
		TextSize = size,
		FontFace = font or Theme.Font.Medium,
		TextColor3 = color or C.Ink,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, size + 4),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
end

-- Storybook serif title (ink on paper unless a color is given)
function Theme.title(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	return Theme.text(parent, text, size, Theme.Font.Title, color or C.Ink)
end

-- Dark outline so text stays readable over the 3D world
function Theme.outline(label: TextLabel, thickness: number?): UIStroke
	return Theme.make("UIStroke", {
		Color = C.WoodEdge,
		Thickness = thickness or math.max(1.5, label.TextSize / 14),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = label,
	})
end

-- Title drawn straight over the game (no panel behind it)
function Theme.worldTitle(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local label = Theme.title(parent, text, size, color or C.Cream)
	Theme.outline(label)
	return label
end

-- Wooden title bar across the top of a panel. Returns the title label.
function Theme.header(panel: Instance, text: string, height: number?): TextLabel
	local h = height or 44
	local bar = Theme.make("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, h),
		BackgroundColor3 = C.WoodLight,
		Parent = panel,
	})
	Theme.corner(bar, 5)
	-- Square off the bottom corners
	Theme.make("Frame", {
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(1, 0.5),
		BackgroundColor3 = C.WoodLight,
		BorderSizePixel = 0,
		Parent = bar,
	})
	Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = C.Wood,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = bar,
	})
	local label = Theme.title(bar, text, math.floor(h * 0.56), C.Cream)
	label.Position = UDim2.fromOffset(16, 0)
	label.Size = UDim2.new(1, -32, 1, -3)
	label.ZIndex = 2
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

-- Solid button with a darker lip underneath; the face presses down onto it when clicked
function Theme.button(parent: Instance, text: string, color: Color3, size: UDim2, onClick: () -> ()): Button
	local holder = Theme.make("Frame", { Size = size, BackgroundTransparency = 1, Parent = parent })
	local lip = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 1, -3),
		Position = UDim2.fromOffset(0, 3),
		Parent = holder,
	})
	Theme.corner(lip, 6)
	local face = Theme.make("TextButton", {
		Size = UDim2.new(1, 0, 1, -4),
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	})
	Theme.corner(face, 6)
	local edge = Theme.stroke(face, BLACK, 2)
	local label = Theme.make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 17,
		FontFace = Theme.Font.Bold,
		Parent = face,
	})

	local enabled = true
	local current = color
	local hovering = false
	local function paint()
		local shown = if enabled then current else C.Disabled
		face.BackgroundColor3 = if hovering and enabled then Theme.lighten(shown, 0.1) else shown
		lip.BackgroundColor3 = Theme.darken(shown, 0.4)
		edge.Color = Theme.darken(shown, 0.4)
		label.TextColor3 = Theme.textOn(shown)
		label.TextTransparency = if enabled then 0 else 0.25
	end
	paint()

	face.MouseEnter:Connect(function()
		hovering = true
		paint()
	end)
	face.MouseLeave:Connect(function()
		hovering = false
		paint()
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

	return {
		Holder = holder,
		Face = face,
		Label = label,
		SetEnabled = function(value: boolean)
			enabled = value
			paint()
		end,
		SetColor = function(value: Color3)
			current = value
			paint()
		end,
		SetText = function(value: string)
			label.Text = value
		end,
	}
end

-- Small square "X" in the corner of a window
function Theme.closeButton(parent: Instance, onClick: () -> ()): Button
	local button = Theme.button(parent, "X", C.Red, UDim2.fromOffset(32, 32), onClick)
	button.Label.TextSize = 18
	return button
end

export type Bar = { Track: Frame, Fill: Frame, Label: TextLabel, Set: (ratio: number, text: string?) -> () }

-- Progress bar in a paper groove, with an optional label on top
function Theme.bar(parent: Instance, color: Color3, size: UDim2): Bar
	local track = Theme.make("Frame", { Size = size, BackgroundColor3 = C.Tan, Parent = parent })
	Theme.corner(track, 4)
	Theme.stroke(track, C.TanEdge, 2)
	local fill = Theme.make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = color,
		Parent = track,
	})
	Theme.corner(fill, 3)
	local label = Theme.make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		FontFace = Theme.Font.Bold,
		TextSize = 13,
		TextColor3 = C.Ink,
		Text = "",
		ZIndex = 3,
		Parent = track,
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

-- Small paper tag with bold text, e.g. "6 plots"
function Theme.chip(parent: Instance, text: string, color: Color3?): TextLabel
	local chip = Theme.make("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 28),
		BackgroundColor3 = C.Chip,
		Text = text,
		TextSize = 15,
		FontFace = Theme.Font.Bold,
		TextColor3 = color or C.Ink,
		Parent = parent,
	})
	Theme.corner(chip, 6)
	Theme.stroke(chip, C.TanEdge, 2)
	Theme.padding(chip, 9, 9, 0, 0)
	return chip
end

export type IconChip = { Frame: Frame, Icon: Frame, Label: TextLabel }

-- Paper tag with a picture in front of the text; put an icon in .Icon
function Theme.iconChip(parent: Instance, text: string, height: number?): IconChip
	local h = height or 30
	local chip = Theme.make("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, h),
		BackgroundColor3 = C.Chip,
		Parent = parent,
	})
	Theme.corner(chip, 6)
	Theme.stroke(chip, C.TanEdge, 2)
	Theme.padding(chip, 3, 9, 0, 0)
	Theme.list(chip, Enum.FillDirection.Horizontal, 4)
	local icon = Theme.make("Frame", {
		Size = UDim2.fromOffset(h - 4, h - 4),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = chip,
	})
	local label = Theme.text(chip, text, 15, Theme.Font.Bold)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, h)
	label.TextTruncate = Enum.TextTruncate.None
	label.LayoutOrder = 2
	return { Frame = chip, Icon = icon, Label = label }
end

-- A gold coin drawn with two circles (fills its parent)
function Theme.coin(parent: Instance): Frame
	local coin = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.78, 0.78),
		BackgroundColor3 = Color3.fromRGB(232, 179, 58),
		Parent = parent,
	})
	Theme.corner(coin, 999)
	Theme.stroke(coin, Color3.fromRGB(138, 90, 26), 2)
	local face = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.56, 0.56),
		BackgroundColor3 = Color3.fromRGB(246, 205, 98),
		Parent = coin,
	})
	Theme.corner(face, 999)
	Theme.stroke(face, Color3.fromRGB(196, 140, 40), 1.5)
	return coin
end

function Theme.formatNumber(n: number): string
	local text = tostring(math.floor(n))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

-- "1 coin" / "25 coins"
function Theme.coins(n: number): string
	return if n == 1 then "1 coin" else `{Theme.formatNumber(n)} coins`
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
