--!strict
-- Shared look for every screen, Night Glass (Figma file "Skycore UI", Look A; your pick,
-- 2026-11-03): dark glass panels with thin light edges, one bright cyan accent and gold for
-- what's special. Color means something: green buy / confirm / done, red close / danger, orange
-- selling, gold rewards, cyan neutral and "picked", grey not yet. No emoji. Small builders for
-- panels, cards, text, buttons, progress bars and chips keep every screen consistent; Glass.luau
-- adds the inventory's parts on top of these.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Sfx = require(script.Parent.Sfx)

local rgb = Color3.fromRGB

local Theme = {}

Theme.Color = {
	-- Surfaces
	PanelTop = rgb(24, 40, 72), -- a window's gradient
	PanelBottom = rgb(11, 20, 39),
	StageTop = rgb(39, 66, 122), -- the lit stage your character stands on
	StageBottom = rgb(10, 18, 36),
	SlotTop = rgb(34, 54, 95),
	SlotBottom = rgb(22, 35, 63),
	Well = rgb(11, 20, 40), -- sunken boxes, bar tracks, dark text on bright colors
	Panel = rgb(44, 68, 118), -- a row or tile that's picked or pointed at
	Card = rgb(22, 35, 63), -- rows and boxes on a panel
	Inset = rgb(11, 20, 40), -- sunken boxes, a button or tab that's off
	Line = rgb(58, 78, 118), -- soft outlines on a panel
	Chip = rgb(11, 20, 40),
	Navy = rgb(66, 92, 150),
	NavyLight = rgb(78, 100, 145), -- scrollbars
	Outline = rgb(16, 26, 50), -- the dim behind a window, dark outlines
	Edge = rgb(255, 255, 255), -- thin light edges, always mostly see-through
	Black = rgb(0, 0, 0),
	-- Text
	Ink = rgb(238, 244, 255),
	Muted = rgb(144, 164, 200),
	InkMuted = rgb(144, 164, 200),
	White = rgb(255, 255, 255),
	-- Colors with a meaning
	Accent = rgb(79, 227, 245), -- what's picked, neutral buttons
	Blue = rgb(79, 227, 245),
	Gold = rgb(255, 194, 75), -- rewards, levels
	Orange = rgb(255, 165, 61), -- selling, warnings
	Hunger = rgb(255, 165, 61),
	Green = rgb(91, 227, 138), -- buy, confirm, done
	Leaf = rgb(91, 227, 138), -- bar fills
	Red = rgb(255, 93, 102), -- close, danger
	Health = rgb(255, 93, 102),
	Teal = rgb(64, 214, 190),
	Purple = rgb(176, 140, 255),
	Disabled = rgb(84, 98, 128),
}

local TITILLIUM = "rbxasset://fonts/families/TitilliumWeb.json"

Theme.Font = {
	Title = Font.new(TITILLIUM, Enum.FontWeight.Bold),
	Bold = Font.new(TITILLIUM, Enum.FontWeight.Bold),
	Medium = Font.new(TITILLIUM, Enum.FontWeight.SemiBold),
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

local function luminance(color: Color3): number
	return 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
end

-- For text on a solid color: dark on the bright ones, white on the rest
function Theme.textOn(color: Color3): Color3
	return if luminance(color) > 0.6 then C.Well else C.White
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
	return Theme.make("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Theme.make("UIStroke", {
		Color = color or C.Outline,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- A top-to-bottom fade. Give the frame a white background so the colors come through.
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

-- A soft dark edge round a label's letters, so it reads over the world or a color
function Theme.outline(label: TextLabel, thickness: number?): UIStroke
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		return stroke
	end
	return Theme.make("UIStroke", {
		Color = BLACK,
		Thickness = thickness or math.clamp(label.TextSize / 14, 1, 3),
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = label,
	})
end

-- A window or anything else that floats on its own
function Theme.panel(parent: Instance, size: UDim2, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Edge,
		BackgroundTransparency = 0.03,
		Parent = parent,
	})
	Theme.gradient(frame, C.PanelTop, C.PanelBottom)
	Theme.corner(frame, 20)
	Theme.stroke(frame, C.Edge, 1.5, 0.82)
	return frame
end

-- A card that sits on a panel (list rows, detail boxes)
function Theme.card(parent: Instance, size: UDim2?, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Card,
		BackgroundTransparency = 0.1,
		Parent = parent,
	})
	Theme.corner(frame, 12)
	Theme.stroke(frame, C.Edge, 1, 0.88)
	return frame
end

-- Sunken box for icons, grids and photos
function Theme.inset(parent: Instance, size: UDim2?, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Inset,
		BackgroundTransparency = 0.15,
		Parent = parent,
	})
	Theme.corner(frame, 10)
	Theme.stroke(frame, C.Edge, 1, 0.9)
	return frame
end

-- A label. White text gets a soft outline by itself (it's on a color or the world).
function Theme.text(parent: Instance, text: string, size: number, font: Font?, color: Color3?): TextLabel
	local label = Theme.make("TextLabel", {
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
	if color == C.White then
		Theme.outline(label)
	end
	return label
end

-- Heading text
function Theme.title(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	return Theme.text(parent, text, size, Theme.Font.Title, color or C.Ink)
end

export type Button = {
	Holder: Frame,
	Face: TextButton,
	Label: TextLabel,
	SetEnabled: (enabled: boolean) -> (),
	SetColor: (color: Color3) -> (),
	SetText: (text: string) -> (),
}

-- A button: glass tinted with its color, with an edge of the same color. A color as dark as the
-- glass (C.Inset, a tab that's off) stays plain with a faint edge.
function Theme.button(parent: Instance, text: string, color: Color3, size: UDim2, onClick: () -> ()): Button
	local holder = Theme.make("Frame", { Size = size, BackgroundTransparency = 1, Parent = parent })
	local face = Theme.make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Edge,
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	})
	Theme.corner(face, 12)
	local fill = Theme.gradient(face, C.SlotTop, C.SlotBottom)
	local stroke = Theme.stroke(face, C.Edge, 1.5)
	local label = Theme.make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 18,
		FontFace = Theme.Font.Bold,
		Parent = face,
	})
	Theme.outline(label, 1.2)

	local enabled = true
	local current = color
	local hovering = false
	local function paint()
		local shown = if enabled then current else C.Disabled
		local lift = if hovering and enabled then 0.14 else 0
		fill.Color = ColorSequence.new(C.SlotBottom:Lerp(shown, 0.62 + lift), C.SlotBottom:Lerp(shown, 0.34 + lift))
		local faint = luminance(shown) < 0.2
		stroke.Color = if faint then C.Edge else shown
		stroke.Transparency = if faint then 0.84 elseif hovering and enabled then 0 else 0.25
		label.TextColor3 = if enabled then C.Ink else C.Muted
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
			face.Position = UDim2.fromOffset(0, 2)
		end
	end)
	face.MouseButton1Up:Connect(function()
		face.Position = UDim2.new()
	end)
	face.Activated:Connect(function()
		if enabled then
			Sfx.play("Click")
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

export type Bar = { Track: Frame, Fill: Frame, Label: TextLabel, Set: (ratio: number, text: string?) -> () }

-- Slim progress bar with text on top (`showText` false leaves the text out)
function Theme.bar(parent: Instance, color: Color3, size: UDim2, showText: boolean?): Bar
	local track = Theme.make("Frame", {
		Size = size,
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.1,
		Parent = parent,
	})
	Theme.corner(track, 7)
	Theme.stroke(track, C.Edge, 1, 0.84)
	local fill = Theme.make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = color,
		Parent = track,
	})
	Theme.corner(fill, 7)
	local label = Theme.make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		FontFace = Theme.Font.Bold,
		TextSize = 13,
		TextColor3 = C.Ink,
		Text = "",
		ZIndex = 3,
		Visible = showText ~= false,
		Parent = track,
	})
	Theme.outline(label)
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

-- Small tag, e.g. "6 plots". A color goes on its letters and edge; without one it's plain.
function Theme.chip(parent: Instance, text: string, color: Color3?): TextLabel
	local chip = Theme.make("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 28),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.1,
		Text = text,
		TextSize = 15,
		FontFace = Theme.Font.Bold,
		TextColor3 = color or C.Ink,
		Parent = parent,
	})
	Theme.corner(chip, 9)
	Theme.stroke(chip, color or C.Edge, 1.5, if color then 0.2 else 0.84)
	Theme.padding(chip, 12, 12, 0, 0)
	return chip
end

export type IconChip = { Frame: Frame, Icon: Frame, Label: TextLabel }

-- A tag with a picture in front of the text; put an icon in .Icon
function Theme.iconChip(parent: Instance, text: string, height: number?): IconChip
	local h = height or 30
	local chip = Theme.make("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, h),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.1,
		Parent = parent,
	})
	Theme.corner(chip, 9)
	Theme.stroke(chip, C.Edge, 1, 0.84)
	Theme.padding(chip, 3, 10, 0, 0)
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
		Size = UDim2.fromScale(0.82, 0.82),
		BackgroundColor3 = Color3.fromRGB(245, 184, 34),
		Parent = parent,
	})
	Theme.corner(coin, 999)
	Theme.stroke(coin, C.Outline, 2.5)
	local face = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.56, 0.56),
		BackgroundColor3 = Color3.fromRGB(255, 214, 92),
		Parent = coin,
	})
	Theme.corner(face, 999)
	Theme.stroke(face, Color3.fromRGB(214, 146, 20), 1.5)
	return coin
end

-- A red count badge for the corner of a button ("3", "99+"); hidden while empty
function Theme.badge(parent: Instance): TextLabel
	local badge = Theme.make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(26, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = C.Red,
		Text = "",
		TextSize = 15,
		FontFace = Theme.Font.Bold,
		TextColor3 = C.White,
		Visible = false,
		ZIndex = 6,
		Parent = parent,
	})
	Theme.corner(badge, 999)
	Theme.stroke(badge, C.Outline, 2.5)
	Theme.padding(badge, 6, 6, 0, 0)
	return badge
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
