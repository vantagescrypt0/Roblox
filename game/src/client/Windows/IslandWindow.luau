--!strict
-- Island expansion: shows your island's size and lets you buy the next tier with coins.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IslandTiers = require(ReplicatedStorage.Shared.IslandTiers)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local IslandWindow = {}

local window: Window.Window
local content: Frame
local state: any = nil

local function card(parent: Instance, height: number, order: number): Frame
	local frame = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = order,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = parent,
	})
	Theme.gradient(frame, Theme.lighten(C.Row, 0.08), C.Row)
	Theme.corner(frame, 12)
	Theme.stroke(frame, C.Stroke, 2)
	Theme.padding(frame, 14, 14, 10, 10)
	return frame
end

local function statRow(parent: Instance, tier: IslandTiers.Tier, prefix: string?)
	local row = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 36),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	Theme.list(row, Enum.FillDirection.Horizontal, 8)
	Theme.chip(row, `🌱 {prefix or ""}{tier.Plots} plots`, C.Green).LayoutOrder = 1
	Theme.chip(row, `🌳 {tier.Trees} trees`, C.Green).LayoutOrder = 2
	Theme.chip(row, `⛰️ {tier.Rocks} rocks`, C.Grey).LayoutOrder = 3
end

local function render()
	Window.clear(content)
	if not state then
		return
	end
	local tierIndex = state.Island.Tier
	local tier = IslandTiers[tierIndex]
	local nextTier = IslandTiers[tierIndex + 1]

	-- Size progress dots
	local dots = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Parent = content,
	})
	local dotsLayout = Theme.list(dots, Enum.FillDirection.Horizontal, 14)
	dotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	for i = 1, #IslandTiers do
		local reached = i <= tierIndex
		local dot = Theme.make("Frame", {
			Size = UDim2.fromOffset(40, 40),
			LayoutOrder = i,
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = dots,
		})
		local color = if reached then C.Green else C.Grey
		Theme.gradient(dot, Theme.lighten(color, 0.2), color)
		Theme.corner(dot, 999)
		Theme.stroke(dot, C.Stroke, 2.5)
		local number = Theme.title(dot, tostring(i), 20)
		number.Size = UDim2.fromScale(1, 1)
		number.TextXAlignment = Enum.TextXAlignment.Center
	end

	local now = card(content, 84, 2)
	local nowTitle = Theme.title(now, `🏝️ {tier.Name}`, 24)
	nowTitle.Size = UDim2.new(1, 0, 0, 30)
	statRow(now, tier)

	local nextCard = card(content, 150, 3)
	if nextTier then
		local nextTitle = Theme.title(nextCard, `NEXT: {nextTier.Name}`, 22, C.Gold)
		nextTitle.Size = UDim2.new(1, 0, 0, 30)
		statRow(nextCard, nextTier)
		local affordable = state.Coins >= nextTier.Cost
		local button = Theme.button(
			nextCard,
			`Expand for 💰 {Theme.formatNumber(nextTier.Cost)}`,
			C.Green,
			UDim2.new(1, 0, 0, 50),
			function()
				Remotes.Expand:FireServer()
			end
		)
		button.Holder.Position = UDim2.new(0, 0, 1, -52)
		button.Label.TextSize = 22
		button.SetEnabled(affordable)
		if not affordable then
			button.SetText(`Need 💰 {Theme.formatNumber(nextTier.Cost - state.Coins)} more`)
		end
	else
		local done = Theme.title(nextCard, "Your island is fully grown! 🎉", 24, C.Gold)
		done.Size = UDim2.fromScale(1, 1)
		done.TextXAlignment = Enum.TextXAlignment.Center
	end
end

function IslandWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
	end
end

function IslandWindow.Toggle()
	Window.toggle(window)
end

function IslandWindow.Close()
	Window.close(window)
end

function IslandWindow.Start()
	window = Window.new("IslandWindow", "My Island", "🏝️", Vector2.new(500, 420))
	window.OnOpen = render
	content = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	local layout = Theme.list(content, Enum.FillDirection.Vertical, 12)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
end

return IslandWindow
