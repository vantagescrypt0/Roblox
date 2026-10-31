--!strict
-- Shared look for every screen, the "Sky" style (2026-10-30, from the UI study in
-- 02 Research/UI Study.md): white panels with thick navy outlines, colored header bands,
-- chunky buttons with a darker lip, a bold rounded font (Fredoka One) and white text with
-- a navy outline over color and the world. Color means something: green buy / confirm /
-- done, red close / danger, orange sell and "selected", gold rewards, blue neutral, grey
-- not yet. No emoji. Small builders for panels, cards, text, buttons, progress bars and
-- chips keep every screen consistent.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Theme = {}

Theme.Color = {
	-- Surfaces
	Panel = Color3.fromRGB(255, 255, 255), -- windows
	Card = Color3.fromRGB(238, 246, 255), -- rows and boxes on a panel
	Inset = Color3.fromRGB(219, 231, 245), -- sunken boxes, empty slots
	Line = Color3.fromRGB(160, 184, 214), -- soft outlines on a panel
	Chip = Color3.fromRGB(230, 240, 252),
	Navy = Color3.fromRGB(42, 59, 94), -- the hotbar, bar tracks, locked things
	NavyLight = Color3.fromRGB(78, 100, 145),
	Outline = Color3.fromRGB(28, 43, 74), -- every thick outline, and text outlines
	-- Text
	Ink = Color3.fromRGB(28, 43, 74), -- text on white
	InkMuted = Color3.fromRGB(94, 112, 145),
	White = Color3.fromRGB(255, 255, 255), -- text on color and over the world (outlined)
	-- Colors with a meaning
	Gold = Color3.fromRGB(245, 184, 34), -- rewards, levels
	Orange = Color3.fromRGB(247, 141, 32), -- selling, the selected thing
	Green = Color3.fromRGB(76, 182, 72), -- buy, confirm, done
	Leaf = Color3.fromRGB(110, 214, 84), -- bar fills
	Red = Color3.fromRGB(232, 65, 60), -- close, danger
	Blue = Color3.fromRGB(59, 142, 232), -- neutral buttons, info
	Teal = Color3.fromRGB(31, 179, 166),
	Purple = Color3.fromRGB(138, 92, 246),
	Disabled = Color3.fromRGB(178, 189, 205),
}

local NUNITO = "rbxasset://fonts/families/Nunito.json"

Theme.Font = {
	Title = Font.fromEnum(Enum.Font.FredokaOne),
	Bold = Font.fromEnum(Enum.Font.FredokaOne),
	Medium = Font.new(NUNITO, Enum.FontWeight.Bold),
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

-- White (outlined) text on colors, navy ink on very light ones
function Theme.textOn(color: Color3): Color3
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return if luminance > 0.8 then C.Ink else C.White
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

-- Navy outline round a label's letters, so white text reads on any color or over the world
function Theme.outline(label: TextLabel, thickness: number?): UIStroke
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		return stroke
	end
	return Theme.make("UIStroke", {
		Color = C.Outline,
		Thickness = thickness or math.clamp(label.TextSize / 11, 1.5, 4),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = label,
	})
end

-- White window with a thick navy outline
function Theme.panel(parent: Instance, size: UDim2, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Panel,
		Parent = parent,
	})
	Theme.corner(frame, 14)
	Theme.stroke(frame, C.Outline, 3)
	return frame
end

-- Pale blue card that sits on a panel (list rows, detail boxes)
function Theme.card(parent: Instance, size: UDim2?, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Card,
		Parent = parent,
	})
	Theme.corner(frame, 10)
	Theme.stroke(frame, C.Outline, 2)
	return frame
end

-- Sunken box for icons, grids and photos
function Theme.inset(parent: Instance, size: UDim2?, position: UDim2?): Frame
	local frame = Theme.make("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = position or UDim2.new(),
		BackgroundColor3 = C.Inset,
		Parent = parent,
	})
	Theme.corner(frame, 8)
	Theme.stroke(frame, C.Line, 2)
	return frame
end

-- A label. White text gets a navy outline by itself (it's always on color or the world).
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

-- Big rounded title (navy on white unless a color is given)
function Theme.title(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	return Theme.text(parent, text, size, Theme.Font.Title, color or C.Ink)
end

-- Title drawn straight over the game (no panel behind it), outlined
function Theme.worldTitle(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local label = Theme.title(parent, text, size, color or C.White)
	Theme.outline(label)
	return label
end

-- Colored band across the top of a panel, with the title in big outlined letters that
-- poke above the panel's edge like a sticker. Returns the title label.
function Theme.header(panel: Instance, text: string, height: number?, color: Color3?): TextLabel
	local h = height or 46
	local band = color or C.Blue
	local bar = Theme.make("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, h),
		BackgroundColor3 = band,
		Parent = panel,
	})
	Theme.corner(bar, 12)
	-- Square off the bottom corners, with a navy line under the band
	Theme.make("Frame", {
		Name = "Fill",
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(1, 0.5),
		BackgroundColor3 = band,
		BorderSizePixel = 0,
		Parent = bar,
	})
	Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = C.Outline,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = bar,
	})
	local label = Theme.title(bar, text, math.floor(h * 0.78), C.White)
	label.Position = UDim2.fromOffset(16, -math.floor(h * 0.3))
	label.Size = UDim2.new(1, -72, 1, 0)
	label.ZIndex = 3
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

-- Chunky button: a colored face with a navy outline over a darker lip; the face presses down
-- onto the lip when clicked
function Theme.button(parent: Instance, text: string, color: Color3, size: UDim2, onClick: () -> ()): Button
	local holder = Theme.make("Frame", { Size = size, BackgroundTransparency = 1, Parent = parent })
	local lip = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 1, -4),
		Position = UDim2.fromOffset(0, 4),
		Parent = holder,
	})
	Theme.corner(lip, 10)
	Theme.stroke(lip, C.Outline, 2.5)
	local face = Theme.make("TextButton", {
		Size = UDim2.new(1, 0, 1, -4),
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	})
	Theme.corner(face, 10)
	Theme.stroke(face, C.Outline, 2.5)
	local label = Theme.make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 18,
		FontFace = Theme.Font.Bold,
		Parent = face,
	})
	local outline = Theme.outline(label, 1.6)

	local enabled = true
	local current = color
	local hovering = false
	local function paint()
		local shown = if enabled then current else C.Disabled
		face.BackgroundColor3 = if hovering and enabled then Theme.lighten(shown, 0.12) else shown
		lip.BackgroundColor3 = Theme.darken(shown, 0.35)
		local ink = Theme.textOn(shown)
		label.TextColor3 = ink
		outline.Enabled = ink == C.White
		label.TextTransparency = if enabled then 0 else 0.2
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

-- Red rounded "X" for a window's corner
function Theme.closeButton(parent: Instance, onClick: () -> ()): Button
	local button = Theme.button(parent, "X", C.Red, UDim2.fromOffset(42, 42), onClick)
	button.Label.TextSize = 24
	return button
end

export type Bar = { Track: Frame, Fill: Frame, Label: TextLabel, Set: (ratio: number, text: string?) -> () }

-- Progress bar: a navy track with a bright fill and white outlined text on top
function Theme.bar(parent: Instance, color: Color3, size: UDim2): Bar
	local track = Theme.make("Frame", { Size = size, BackgroundColor3 = C.Navy, Parent = parent })
	Theme.corner(track, 8)
	Theme.stroke(track, C.Outline, 2.5)
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
		TextColor3 = C.White,
		Text = "",
		ZIndex = 3,
		Parent = track,
	})
	Theme.outline(label, 1.4)
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

-- Small tag, e.g. "6 plots". With a color it's a filled pill with white text; without one,
-- a pale tag with navy text.
function Theme.chip(parent: Instance, text: string, color: Color3?): TextLabel
	local chip = Theme.make("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 28),
		BackgroundColor3 = color or C.Chip,
		Text = text,
		TextSize = 15,
		FontFace = Theme.Font.Bold,
		TextColor3 = if color then Theme.textOn(color) else C.Ink,
		Parent = parent,
	})
	Theme.corner(chip, 8)
	Theme.stroke(chip, C.Outline, 2)
	Theme.padding(chip, 10, 10, 0, 0)
	return chip
end

export type IconChip = { Frame: Frame, Icon: Frame, Label: TextLabel }

-- Pale tag with a picture in front of the text; put an icon in .Icon
function Theme.iconChip(parent: Instance, text: string, height: number?): IconChip
	local h = height or 30
	local chip = Theme.make("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, h),
		BackgroundColor3 = C.Chip,
		Parent = parent,
	})
	Theme.corner(chip, 8)
	Theme.stroke(chip, C.Outline, 2)
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
