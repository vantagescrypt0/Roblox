--!strict
-- Loot Crate window: everything a crate can give and its odds, how many crates you have, and an
-- Open button. Click a Loot Crate in your Bag to get here. See CrateService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local ROW_HEIGHT = 40

local CrateWindow = {}

local window: Window.Window
local status: TextLabel
local openButton: Theme.Button
local state: any = nil

local function refresh()
	local count = if state then state.Items[LootCrates.Item] or 0 else 0
	openButton.SetEnabled(count > 0)
	openButton.SetText(if count > 0 then `Open ({count} left)` else "No crates left")
end

local function prizeRow(list: Instance, order: number, prize: LootCrates.Prize)
	local row = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = list,
	})
	local holder = Theme.make("Frame", {
		Size = UDim2.fromOffset(ROW_HEIGHT - 4, ROW_HEIGHT - 4),
		Position = UDim2.fromOffset(0, 2),
		BackgroundTransparency = 1,
		Parent = row,
	})
	ItemIcon.create(holder, prize.Item, UDim2.fromScale(1, 1))
	local amount = if prize.Min == prize.Max then "" else `{prize.Min}-{prize.Max} `
	local name = Theme.text(row, `{amount}{Items[prize.Item].Name}`, 16, Theme.Font.Medium, C.Ink)
	name.Position = UDim2.fromOffset(ROW_HEIGHT + 4, 0)
	name.Size = UDim2.new(1, -(ROW_HEIGHT + 90), 1, 0)
	local odds = Theme.text(row, `{prize.Weight}%`, 16, Theme.Font.Bold, C.Ink)
	odds.AnchorPoint = Vector2.new(1, 0)
	odds.Position = UDim2.fromScale(1, 0)
	odds.Size = UDim2.new(0, 80, 1, 0)
	odds.TextXAlignment = Enum.TextXAlignment.Right
end

function CrateWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		refresh()
	end
end

function CrateWindow.Open()
	status.Text = "Every crate gives one of these. The chance of each is shown."
	Window.toggle(window)
end

function CrateWindow.Start()
	window = Window.new("CrateWindow", "Loot Crate", Vector2.new(580, 596))
	window.OnOpen = refresh

	status = Theme.text(window.Body, "", 16, Theme.Font.Medium, C.InkMuted)
	status.Size = UDim2.new(1, 0, 0, 44)
	status.TextWrapped = true

	local list = Window.scrollList(window.Body, UDim2.new(1, 0, 1, -112))
	list.Position = UDim2.fromOffset(0, 48)
	for order, prize in LootCrates.Prizes do
		prizeRow(list, order, prize)
	end

	openButton = Theme.button(window.Body, "Open", C.Green, UDim2.fromOffset(220, 48), function()
		Remotes.OpenCrate:FireServer()
	end)
	openButton.Holder.AnchorPoint = Vector2.new(0.5, 1)
	openButton.Holder.Position = UDim2.fromScale(0.5, 1)

	Remotes.CrateOpened.OnClientEvent:Connect(function(itemId: string, count: number)
		status.Text = `You got {count} {Items[itemId].Name}!`
	end)
end

return CrateWindow
