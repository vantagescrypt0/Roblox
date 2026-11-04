--!strict
-- Pop-up windows (Bag, Island, Shop, Crafting, Trade...) in Night Glass: a dark panel with its
-- title top left and an X top right. The game dims and blurs behind it. Only one is open at a time.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Glass = require(script.Parent.Glass)
local Sfx = require(script.Parent.Sfx)
local Theme = require(script.Parent.Theme)

local HEADER = 68

export type Window = {
	Gui: ScreenGui,
	Root: Frame,
	Body: Frame,
	Title: TextLabel,
	IsOpen: boolean,
	OnOpen: (() -> ())?,
	OnClose: (() -> ())?,
}

local Window = {}

local current: Window? = nil
local switching = false -- opening another window closes this one: no closing whoosh then

-- One blur for all windows, on while any window is open (Lighting changes from a client stay local)
local blur = Instance.new("BlurEffect")
blur.Name = "WindowBlur"
blur.Size = 0
blur.Enabled = false
blur.Parent = Lighting
local BLUR_SIZE = 14

local function setBlur(on: boolean)
	if on then
		blur.Enabled = true
	end
	local tween = TweenService:Create(blur, TweenInfo.new(0.18), { Size = if on then BLUR_SIZE else 0 })
	tween.Completed:Connect(function()
		if not current then
			blur.Enabled = false
		end
	end)
	tween:Play()
end

function Window.close(window: Window)
	if not window.IsOpen then
		return
	end
	window.IsOpen = false
	if current == window then
		current = nil
	end
	window.Gui.Enabled = false
	if not current then
		setBlur(false)
	end
	if not switching then
		Sfx.play("Close")
	end
	if window.OnClose then
		window.OnClose()
	end
end

function Window.open(window: Window)
	if current and current ~= window then
		switching = true
		Window.close(current)
		switching = false
	end
	Sfx.play("Open")
	current = window
	window.IsOpen = true
	if window.OnOpen then
		window.OnOpen()
	end
	window.Gui.Enabled = true
	setBlur(true)
	local scale = window.Root:FindFirstChild("OpenScale") :: UIScale
	scale.Scale = 0.92
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
end

function Window.toggle(window: Window)
	if window.IsOpen then
		Window.close(window)
	else
		Window.open(window)
	end
end

function Window.new(name: string, title: string, size: Vector2): Window
	local window: Window
	local gui = Theme.screen(name, 10)
	gui.Enabled = false
	gui.IgnoreGuiInset = true

	-- The dim behind it closes it when clicked. Modal frees the mouse while you're in first person.
	local dim = Theme.make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Color.Outline,
		BackgroundTransparency = 0.55,
		Text = "",
		AutoButtonColor = false,
		Modal = true,
		Parent = gui,
	})
	dim.Activated:Connect(function()
		Window.close(window)
	end)

	-- Outer holder shrinks on phones; the panel inside does the open animation
	local holder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Name = "Holder",
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(holder)

	local root = Glass.panel(holder, UDim2.fromScale(1, 1))
	root.Name = "Root"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	Theme.make("UIScale", { Name = "OpenScale", Parent = root })

	local titleLabel = Glass.text(root, string.upper(title), 26, Glass.Font.Title)
	titleLabel.Position = UDim2.fromOffset(28, 16)
	titleLabel.Size = UDim2.new(0.6, 0, 0, 32)

	local close = Glass.button(root, "X", UDim2.fromOffset(40, 40), function()
		Window.close(window)
	end)
	close.Face.AnchorPoint = Vector2.new(1, 0)
	close.Face.Position = UDim2.new(1, -24, 0, 12)
	close.Stroke.Color = Glass.Color.Edge
	close.Stroke.Transparency = 0.84
	close.Label.TextSize = 20

	local body = Theme.make("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(24, HEADER),
		Size = UDim2.new(1, -48, 1, -(HEADER + 20)),
		BackgroundTransparency = 1,
		Parent = root,
	})

	window = {
		Gui = gui,
		Root = root,
		Body = body,
		Title = titleLabel,
		IsOpen = false,
		OnOpen = nil,
		OnClose = nil,
	}
	return window
end

-- Titles are always in capitals
function Window.setTitle(window: Window, title: string)
	window.Title.Text = string.upper(title)
end

-- Scrolling list area inside a window body
function Window.scrollList(parent: Instance, size: UDim2, position: UDim2?): ScrollingFrame
	local list = Theme.make("ScrollingFrame", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 7,
		ScrollBarImageColor3 = Theme.Color.NavyLight,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
	Theme.make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})
	Theme.padding(list, 2, 10, 4, 4)
	return list
end

-- Removes rows (but keeps layouts/padding) before re-rendering a list
function Window.clear(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

return Window
