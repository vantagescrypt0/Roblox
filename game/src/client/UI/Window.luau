--!strict
-- Pop-up windows (Bag, Island, Market, Crafting, Trade): a parchment sheet in a wooden frame with
-- a wooden title bar and a close button. Only one is open at a time.

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

function Window.close(window: Window)
	if not window.IsOpen then
		return
	end
	window.IsOpen = false
	if current == window then
		current = nil
	end
	window.Gui.Enabled = false
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
	local gui = Theme.screen(name, 10)
	gui.Enabled = false
	gui.IgnoreGuiInset = true

	local window: Window

	-- Dim the game behind the window; clicking it closes the window
	local dim = Theme.make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 12, 6),
		BackgroundTransparency = 0.5,
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

	local titleLabel = Theme.header(root, title, HEADER)

	local close = Theme.closeButton(root, function()
		Window.close(window)
	end)
	close.Holder.AnchorPoint = Vector2.new(1, 0.5)
	close.Holder.Position = UDim2.new(1, -9, 0, HEADER / 2)
	close.Holder.ZIndex = 3

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

-- Scrolling list area inside a window body
function Window.scrollList(parent: Instance, size: UDim2, position: UDim2?): ScrollingFrame
	local list = Theme.make("ScrollingFrame", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.Color.WoodLight,
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
