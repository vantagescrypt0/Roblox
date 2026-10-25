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
	local frame = Theme.card(parent, UDim2.new(1, 0, 0, height))
	frame.LayoutOrder = order
	Theme.padding(frame, 14, 14, 10, 10)
	return frame
end

local function statRow(parent: Instance, tier: IslandTiers.Tier)
	local row = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 36),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	Theme.list(row, Enum.FillDirection.Horizontal, 8)
	Theme.chip(row, `{tier.Plots} farm plots`).LayoutOrder = 1
	Theme.chip(row, `{tier.Trees} trees`).LayoutOrder = 2
	Theme.chip(row, `{tier.Rocks} boulders`).LayoutOrder = 3
end

local function render()
	Window.clear(content)
	if not state then
		return
	end
	local tierIndex = state.Island.Tier
	local tier = IslandTiers[tierIndex]
	local nextTier = IslandTiers[tierIndex + 1]

	-- Size progress: one marker per tier, joined by a line
	local track = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Parent = content,
	})
	local count = #IslandTiers
	Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset((count - 1) * 76, 4),
		BackgroundColor3 = C.TanEdge,
		BorderSizePixel = 0,
		Parent = track,
	})
	for i = 1, count do
		local reached = i <= tierIndex
		local marker = Theme.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, (i - (count + 1) / 2) * 76, 0.5, 0),
			Size = UDim2.fromOffset(38, 38),
			BackgroundColor3 = if reached then C.Green else C.ParchmentDark,
			ZIndex = 2,
			Parent = track,
		})
		Theme.corner(marker, 999)
		Theme.stroke(marker, if reached then Theme.darken(C.Green, 0.4) else C.TanEdge, 2.5)
		local number = Theme.text(marker, tostring(i), 18, Theme.Font.Bold, if reached then C.Cream else C.InkMuted)
		number.Size = UDim2.fromScale(1, 1)
		number.TextXAlignment = Enum.TextXAlignment.Center
		number.ZIndex = 2
	end

	local now = card(content, 84, 2)
	local nowTitle = Theme.title(now, tier.Name, 26)
	nowTitle.Size = UDim2.new(1, 0, 0, 30)
	statRow(now, tier)

	local nextCard = card(content, 150, 3)
	if nextTier then
		local nextTitle = Theme.title(nextCard, `Next: {nextTier.Name}`, 24, C.WoodLight)
		nextTitle.Size = UDim2.new(1, 0, 0, 30)
		statRow(nextCard, nextTier)
		local affordable = state.Coins >= nextTier.Cost
		local button = Theme.button(
			nextCard,
			`Expand for {Theme.coins(nextTier.Cost)}`,
			C.Green,
			UDim2.new(1, 0, 0, 48),
			function()
				Remotes.Expand:FireServer()
			end
		)
		button.Holder.Position = UDim2.new(0, 0, 1, -50)
		button.Label.TextSize = 19
		button.SetEnabled(affordable)
		if not affordable then
			button.SetText(`Need {Theme.coins(nextTier.Cost - state.Coins)} more`)
		end
	else
		local done = Theme.title(nextCard, "Your island is fully grown!", 26, C.WoodLight)
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
	window = Window.new("IslandWindow", "My Island", Vector2.new(500, 400))
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
