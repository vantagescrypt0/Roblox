--!strict
-- Boost crystals (Menu > Boosts, see Boosts.luau and BoostService): how many you have and how many are free, then the
-- three trees side by side, each with its five boosts lit up to where your crystals reach and a button to put a free
-- crystal in. Buying one, how many you're carrying still to redeem (hold one and right-click), and the once-a-season
-- reassign are along the top.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boosts = require(ReplicatedStorage.Shared.Boosts)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local HEADER = 118
local GAP = 14
local ROW = 54
local CONFIRM_TIME = 4

export type State = {
	Crystals: number,
	Warzone: number,
	Player: number,
	Island: number,
	Free: number,
	CanReset: boolean,
	OnSale: boolean,
	ProductId: number,
}

type Column = {
	Count: TextLabel,
	Rows: { { Box: Frame, Mark: TextLabel, Text: TextLabel, Stroke: UIStroke } },
	Add: Theme.Button,
}

local TREE_COLOR: { [string]: Color3 } = {
	Warzone = C.Red,
	Player = C.Green,
	Island = C.Accent,
}

local BoostWindow = {}

local window: Window.Window
local summary: TextLabel
local buyButton: Theme.Button
local carryHint: TextLabel
local resetButton: Theme.Button
local columns: { [string]: Column } = {}
local state: State? = nil
local inBag = 0
local price: number? = nil
local askedPrice = false
local confirmUntil = 0

local function plural(n: number, one: string, many: string): string
	return `{n} {if n == 1 then one else many}`
end

local function refresh()
	local now = state
	if not window or not now then
		return
	end
	local placed = now.Warzone + now.Player + now.Island
	summary.Text = if now.Crystals == 0
		then "Each crystal you put into a tree unlocks its next boost, for good. Once a season you can move them."
		else `You have {plural(now.Crystals, "crystal", "crystals")}: {placed} in trees, {now.Free} free to place.`
			.. (if now.Crystals >= Boosts.Most then " Every boost is yours." else "")

	buyButton.Holder.Visible = now.OnSale
	buyButton.SetText(if price then `Buy a crystal · {price} Robux` else "Buy a crystal")
	carryHint.Visible = inBag > 0
	carryHint.Text = `{plural(inBag, "crystal", "crystals")} in your Bag: hold one and right-click to redeem it`
	resetButton.Holder.Visible = now.CanReset
	resetButton.SetText(if os.clock() < confirmUntil then "Sure? Press again" else "Take them all back out")

	for _, tree in Boosts.Trees do
		local column = columns[tree.Id]
		local level = (now :: any)[tree.Id] :: number
		local color = TREE_COLOR[tree.Id]
		column.Count.Text = `{level} / {Boosts.PerTree}`
		for index, row in column.Rows do
			local unlocked = index <= level
			local nextUp = index == level + 1
			row.Mark.Text = if unlocked then "✓" else tostring(index)
			row.Mark.TextColor3 = if unlocked then color elseif nextUp then C.Ink else C.Muted
			row.Text.TextColor3 = if unlocked then C.Ink elseif nextUp then C.Ink else C.Muted
			row.Text.TextTransparency = if unlocked or nextUp then 0 else 0.25
			row.Box.BackgroundColor3 = if unlocked then C.Panel else C.Card
			row.Stroke.Color = if unlocked then color else C.Edge
			row.Stroke.Transparency = if unlocked then 0.35 elseif nextUp then 0.7 else 0.88
		end
		local full = level >= Boosts.PerTree
		column.Add.SetText(
			if full then "All five unlocked" elseif now.Free > 0 then "Add a crystal" else "No free crystals"
		)
		column.Add.SetEnabled(not full and now.Free > 0)
	end
end

local function askPrice(productId: number)
	if askedPrice or productId == 0 then
		return
	end
	askedPrice = true
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
		end)
		if ok and info and type(info.PriceInRobux) == "number" then
			price = info.PriceInRobux
			refresh()
		else
			askedPrice = false
		end
	end)
end

function BoostWindow.SetState(newState: State)
	state = newState
	askPrice(newState.ProductId)
	refresh()
end

-- The game's state: how many crystals they're carrying
function BoostWindow.SetGameState(gameState: any)
	local count = gameState and gameState.Items and gameState.Items[Boosts.Item] or 0
	if count ~= inBag then
		inBag = count
		refresh()
	end
end

function BoostWindow.Toggle()
	Remotes.BoostOpen:FireServer()
	Window.toggle(window)
end

function BoostWindow.Open()
	Remotes.BoostOpen:FireServer()
	if not window.IsOpen then
		Window.toggle(window)
	end
end

local function makeColumn(parent: Instance, tree: Boosts.Tree, order: number)
	local color = TREE_COLOR[tree.Id]
	local card = Theme.card(parent, UDim2.new(1 / 3, -GAP * 2 / 3, 1, 0))
	card.LayoutOrder = order
	Theme.padding(card, 14, 14, 12, 12)

	local title = Theme.title(card, tree.Name, 21, color)
	title.Size = UDim2.new(1, -60, 0, 26)
	local count = Theme.text(card, "", 17, Theme.Font.Bold, C.Ink)
	count.AnchorPoint = Vector2.new(1, 0)
	count.Position = UDim2.new(1, 0, 0, 2)
	count.Size = UDim2.fromOffset(60, 22)
	count.TextXAlignment = Enum.TextXAlignment.Right
	local where = Theme.text(card, tree.Where, 14, Theme.Font.Medium, C.InkMuted)
	where.Position = UDim2.fromOffset(0, 28)
	where.Size = UDim2.new(1, 0, 0, 18)

	local rows = {}
	for index, text in tree.Boosts do
		local box = Theme.make("Frame", {
			Position = UDim2.fromOffset(0, 54 + (index - 1) * (ROW + 6)),
			Size = UDim2.new(1, 0, 0, ROW),
			BackgroundColor3 = C.Card,
			BackgroundTransparency = 0.15,
			Parent = card,
		})
		Theme.corner(box, 10)
		local stroke = Theme.stroke(box, C.Edge, 1.5, 0.88)
		local mark = Theme.text(box, tostring(index), 18, Theme.Font.Bold, C.Muted)
		mark.Size = UDim2.new(0, 34, 1, 0)
		mark.TextXAlignment = Enum.TextXAlignment.Center
		local label = Theme.text(box, text, 15, Theme.Font.Medium, C.Muted)
		label.Position = UDim2.fromOffset(34, 0)
		label.Size = UDim2.new(1, -42, 1, 0)
		label.TextWrapped = true
		table.insert(rows, { Box = box, Mark = mark, Text = label, Stroke = stroke })
	end

	local add = Theme.button(card, "Add a crystal", color, UDim2.new(1, 0, 0, 46), function()
		Remotes.BoostAdd:FireServer(tree.Id)
	end)
	add.Holder.AnchorPoint = Vector2.new(0, 1)
	add.Holder.Position = UDim2.fromScale(0, 1)
	columns[tree.Id] = { Count = count, Rows = rows, Add = add }
end

function BoostWindow.Start()
	window = Window.new("BoostWindow", "Boosts", Vector2.new(940, 640))
	window.OnOpen = refresh

	-- Along the top: the crystal, what you have, and what you can do with them
	local header = Theme.make("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER - GAP),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	local picture = Theme.inset(header, UDim2.fromOffset(84, 84), UDim2.fromOffset(0, 4))
	ItemIcon.create(picture, Boosts.Item, UDim2.fromScale(0.9, 0.9))
	local heading = Theme.title(header, "Boost Crystals", 23)
	heading.Position = UDim2.fromOffset(100, 4)
	heading.Size = UDim2.new(1, -100, 0, 28)
	summary = Theme.text(header, "", 15, Theme.Font.Medium, C.InkMuted)
	summary.Position = UDim2.fromOffset(100, 34)
	summary.Size = UDim2.new(1, -100, 0, 22)
	summary.TextWrapped = true

	local actions = Theme.make("Frame", {
		Position = UDim2.fromOffset(100, 60),
		Size = UDim2.new(1, -100, 0, 44),
		BackgroundTransparency = 1,
		Parent = header,
	})
	Theme.list(actions, Enum.FillDirection.Horizontal, 10)
	buyButton = Theme.button(actions, "Buy a crystal", C.Green, UDim2.fromOffset(250, 44), function()
		Remotes.BoostBuy:FireServer()
	end)
	buyButton.Holder.LayoutOrder = 1
	carryHint = Theme.text(actions, "", 15, Theme.Font.Bold, C.Purple)
	carryHint.Size = UDim2.fromOffset(300, 44)
	carryHint.TextWrapped = true
	carryHint.LayoutOrder = 2
	resetButton = Theme.button(actions, "Take them all back out", C.Orange, UDim2.fromOffset(240, 44), function()
		if os.clock() < confirmUntil then
			confirmUntil = 0
			Remotes.BoostReset:FireServer()
		else
			confirmUntil = os.clock() + CONFIRM_TIME
			task.delay(CONFIRM_TIME, refresh)
		end
		refresh()
	end)
	resetButton.Holder.LayoutOrder = 3

	-- The three trees
	local trees = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.new(1, 0, 1, -HEADER),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	Theme.list(trees, Enum.FillDirection.Horizontal, GAP)
	for order, tree in Boosts.Trees do
		makeColumn(trees, tree, order)
	end
	buyButton.Holder.Visible = false
	carryHint.Visible = false
	resetButton.Holder.Visible = false
end

return BoostWindow
