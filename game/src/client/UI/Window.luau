--!strict
-- Pop-up windows (Bag, Island, Shop, Crafting, Trade...): a white panel with a colored header
-- band, the title sticking out of its top-left and a red X on the top-right corner. The game
-- dims and blurs behind it. Only one is open at a time.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local HEADER = 46

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
	if window.OnClose then
		window.OnClose()
	end
end

function Window.open(window: Window)
	if current and current ~= window then
		Window.close(current)
	end
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

-- `color` is the header band's color (each window has its own, see the UI study)
function Window.new(name: string, title: string, size: Vector2, color: Color3?): Window
	local gui = Theme.screen(name, 10)
	gui.Enabled = false
	gui.IgnoreGuiInset = true

	local window: Window

	-- Dim the game behind the window; clicking it closes the window
	local dim = Theme.make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Color.Outline,
		BackgroundTransparency = 0.55,
		Text = "",
		AutoButtonColor = false,
		Parent = gui,
	})
	dim.Activated:Connect(function()
		Window.close(window)
	end)

	-- Outer holder shrinks on phones; the panel inside does the open animation
	local holder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(holder)
	local root = Theme.panel(holder, UDim2.fromScale(1, 1))
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	Theme.make("UIScale", { Name = "OpenScale", Parent = root })

	local titleLabel = Theme.header(root, title, HEADER, color)

	-- The X straddles the panel's top-right corner
	local close = Theme.closeButton(root, function()
		Window.close(window)
	end)
	close.Holder.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Holder.Position = UDim2.new(1, -8, 0, 6)
	close.Holder.ZIndex = 5

	local body = Theme.make("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(14, HEADER + 12),
		Size = UDim2.new(1, -28, 1, -(HEADER + 26)),
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

-- Repaints a window's header band (e.g. a Challenges group in its own color)
function Window.setColor(window: Window, color: Color3)
	local band = window.Root:FindFirstChild("Header") :: Frame
	band.BackgroundColor3 = color
	local fill = band:FindFirstChild("Fill") :: Frame
	fill.BackgroundColor3 = color
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
