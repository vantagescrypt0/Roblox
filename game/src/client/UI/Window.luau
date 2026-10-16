--!strict
-- Pop-up windows (Bag, Island, Market, Workbench). Only one is open at a time.

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

export type Window = {
	Gui: ScreenGui,
	Root: Frame,
	Body: Frame,
	IsOpen: boolean,
	OnOpen: (() -> ())?,
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
	scale.Scale = 0.85
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
end

function Window.toggle(window: Window)
	if window.IsOpen then
		Window.close(window)
	else
		Window.open(window)
	end
end

function Window.new(name: string, title: string, icon: string, size: Vector2): Window
	local gui = Theme.screen(name, 10)
	gui.Enabled = false
	gui.IgnoreGuiInset = true

	local window: Window

	-- Dim the game behind the window; clicking it closes the window
	local dim = Theme.make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
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
	local inner = root

	-- Header: icon badge, title, close button
	local badge = Theme.make("Frame", {
		Size = UDim2.fromOffset(52, 52),
		Position = UDim2.fromOffset(14, -14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = inner,
	})
	Theme.gradient(badge, Theme.lighten(Theme.Color.Gold, 0.2), Theme.darken(Theme.Color.Gold, 0.15))
	Theme.corner(badge, 999)
	Theme.stroke(badge, Theme.Color.Stroke, 3)
	Theme.make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = icon,
		TextSize = 30,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = badge,
	})

	local titleLabel = Theme.title(inner, title, 28)
	titleLabel.Position = UDim2.fromOffset(78, 12)
	titleLabel.Size = UDim2.new(1, -140, 0, 34)

	local close = Theme.button(inner, "X", Theme.Color.Red, UDim2.fromOffset(44, 44), function()
		Window.close(window)
	end)
	close.Holder.AnchorPoint = Vector2.new(1, 0)
	close.Holder.Position = UDim2.new(1, -12, 0, 10)
	close.Label.TextSize = 22

	local body = Theme.make("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(14, 64),
		Size = UDim2.new(1, -28, 1, -78),
		BackgroundTransparency = 1,
		Parent = inner,
	})

	window = {
		Gui = gui,
		Root = root,
		Body = body,
		IsOpen = false,
		OnOpen = nil,
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
		ScrollBarImageColor3 = Theme.Color.Muted,
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
