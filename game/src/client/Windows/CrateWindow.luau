--!strict
-- Loot Crate window: everything a crate can give and its odds, how many crates you have, and an Open
-- button that puts one down in front of you (client/CrateOpening). Shift-click a Loot Crate in your Bag to get here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local CrateOpening = require(script.Parent.Parent.CrateOpening)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local ROW_HEIGHT = 40

local CrateWindow = {
	OddsText = `Every crate gives {LootCrates.Slots} things, each rolled from this list. There's a {LootCrates.GoodCratePercent}% chance a crate holds something good, shown in gold.`,
}

local window: Window.Window
local status: TextLabel
local openButton: Theme.Button
local state: any = nil

local function refresh()
	local count = if state then state.Items[LootCrates.Item] or 0 else 0
	openButton.SetEnabled(count > 0)
	openButton.SetText(if count > 0 then `Open ({count} left)` else "No crates left")
end

-- One line of the odds; the Kits window lists them too
function CrateWindow.PrizeRow(list: Instance, order: number, prize: LootCrates.Prize)
	local color = if prize.Good then C.Gold else C.Ink
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
	local name = Theme.text(row, `{amount}{Items[prize.Item].Name}`, 16, Theme.Font.Medium, color)
	name.Position = UDim2.fromOffset(ROW_HEIGHT + 4, 0)
	name.Size = UDim2.new(1, -(ROW_HEIGHT + 90), 1, 0)
	local odds = Theme.text(row, string.format("%.2f%%", prize.Chance), 16, Theme.Font.Bold, color)
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
	status.Text = CrateWindow.OddsText
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
		CrateWindow.PrizeRow(list, order, prize)
	end

	openButton = Theme.button(window.Body, "Open", C.Green, UDim2.fromOffset(220, 48), function()
		Window.close(window)
		CrateOpening.Place(nil)
	end)
	openButton.Holder.AnchorPoint = Vector2.new(0.5, 1)
	openButton.Holder.Position = UDim2.fromScale(0.5, 1)
end

-- How many Loot Crates you have right now
function CrateWindow.Count(): number
	return if state then state.Items[LootCrates.Item] or 0 else 0
end

return CrateWindow
