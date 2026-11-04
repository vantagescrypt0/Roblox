--!strict
-- The traditional chest screen, for every chest in the game: the chest's 27 slots over your 36. It
-- plays like the Bag: click a stack to pick it up and click again to put it down, right-click takes
-- half or leaves one, shift-click sends it straight across. What's in your hand never leaves its slot
-- on the server: it's only drawn that way, so closing the window can't lose anything. In a shared chest
-- someone else can take what you were about to; your hand simply empties.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Glass = require(script.Parent.Parent.UI.Glass)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Glass.Color

local SLOT = 56
local GAP = 5
local COLUMNS = 9
local TITLE_ROW = 24
local WINDOW = Vector2.new(COLUMNS * SLOT + (COLUMNS - 1) * GAP + 48, 552)
local OFFSET = Inventory.ChestOffset
local LID_OPEN = math.rad(-72)
local LID_TIME = 0.28

local ChestWindow = {}

type Carried = { Item: string, Count: number, From: number }
type How = "left" | "right" | "shift"

local window: Window.Window
local state: any = nil
local chestId: string? = nil
local chestSlots: { Inventory.Stack } = {}
local bagButtons: { Glass.Slot } = {}
local chestButtons: { Glass.Slot } = {}
local carried: Carried? = nil
local floating: Frame
local floatingIcon: Frame
local floatingCount: TextLabel
local floatingItem = ""
local hoverName: TextLabel

local function listOf(index: number): ({ Inventory.Stack }, number)
	if index > OFFSET then
		return chestSlots, index - OFFSET
	end
	return state.Slots, index
end

-- What each slot shows: minus what's in your hand
local function shownStack(index: number): (string, number)
	local list, here = listOf(index)
	local stack = list[here]
	local item = if stack then stack.Item else ""
	local count = if stack then stack.Count else 0
	local held = carried
	if held and held.From == index then
		count = math.max(count - held.Count, 0)
	end
	return item, count
end

local function renderCarried()
	local held = carried
	-- Someone else took it, or something used it up
	if held then
		local list, here = listOf(held.From)
		local stack = list[here]
		if not stack or stack.Item ~= held.Item or stack.Count < held.Count then
			carried = nil
			held = nil
		end
	end
	local item = if held then held.Item else ""
	if item ~= floatingItem then
		floatingItem = item
		for _, child in floatingIcon:GetChildren() do
			child:Destroy()
		end
		if item ~= "" then
			ItemIcon.create(floatingIcon, item, UDim2.fromScale(0.9, 0.9))
		end
	end
	floating.Visible = held ~= nil
	floatingCount.Text = if held and held.Count > 1 then tostring(held.Count) else ""
end

local function render()
	if not state or not window.IsOpen then
		return
	end
	renderCarried()
	for index, slot in bagButtons do
		local item, count = shownStack(index)
		Glass.setSlot(slot, item, count)
	end
	for index, slot in chestButtons do
		local item, count = shownStack(index + OFFSET)
		Glass.setSlot(slot, item, count)
	end
end

local function howClicked(): How
	local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	return if shift then "shift" else "left"
end

-- Moves items now on this screen, and tells the server
local function move(from: number, to: number, amount: number): boolean
	local fromList, i = listOf(from)
	local toList, j = listOf(to)
	if from <= Inventory.Size and to <= Inventory.Size then
		if Inventory.Move(state.Slots, from, to, amount) then
			Remotes.MoveStack:FireServer(from, to, amount)
			return true
		end
		return false
	end
	if Inventory.Across(fromList, i, toList, j, amount, state.Slots) then
		Remotes.ChestMove:FireServer(from, to, amount)
		return true
	end
	return false
end

local function quick(index: number)
	local done = if index > OFFSET
		then Inventory.Send(chestSlots, index - OFFSET, state.Slots, state.Slots)
		else Inventory.Send(state.Slots, index, chestSlots, state.Slots)
	if done then
		Remotes.ChestQuick:FireServer(index)
	end
end

local function onSlot(index: number, how: How)
	if not state then
		return
	end
	local item, count = shownStack(index)
	local held = carried
	if not held then
		if count <= 0 then
			return
		end
		if how == "shift" then
			quick(index)
		else
			carried = {
				Item = item,
				Count = if how == "right" then math.ceil(count / 2) else count,
				From = index,
			}
		end
	elseif held.From == index then
		if how == "right" then
			held.Count -= 1
			if held.Count <= 0 then
				carried = nil
			end
		else
			carried = nil
		end
	else
		local amount = if how == "right" then 1 else held.Count
		if move(held.From, index, amount) then
			held.Count -= amount
			if held.Count <= 0 then
				carried = nil
			end
		end
	end
	render()
end

local function setHover(index: number)
	local item, count = shownStack(index)
	hoverName.Text = if count > 0 and Items[item] then Items[item].Name else ""
end

local function buildSlot(body: Frame, index: number, position: UDim2): Glass.Slot
	local slot = Glass.slot(body, SLOT, position)
	slot.Button.Name = if index > OFFSET then `Chest{index - OFFSET}` else `Bag{index}`
	slot.Button.Activated:Connect(function()
		onSlot(index, howClicked())
	end)
	slot.Button.MouseButton2Click:Connect(function()
		onSlot(index, "right")
	end)
	slot.Button.MouseEnter:Connect(function()
		setHover(index)
	end)
	slot.Button.MouseLeave:Connect(function()
		hoverName.Text = ""
	end)
	return slot
end

local function slotAt(column: number, y: number): UDim2
	return UDim2.fromOffset(column * (SLOT + GAP), y)
end

local function rowsHeight(rows: number): number
	return rows * SLOT + (rows - 1) * GAP
end

-- The lid swings up on this screen while the window's open
local function setLid(part: BasePart?, open: boolean)
	local weld = part and part:FindFirstChild("LidHinge", true)
	if not weld or not weld:IsA("Weld") then
		return
	end
	local rest = weld:GetAttribute("Rest")
	local hinge = weld:GetAttribute("Hinge")
	if typeof(rest) ~= "CFrame" or typeof(hinge) ~= "CFrame" then
		return
	end
	local lift = Instance.new("NumberValue")
	lift.Value = if open then 0 else LID_OPEN
	lift.Changed:Connect(function(value: number)
		if weld.Parent then
			weld.C0 = hinge * CFrame.Angles(value, 0, 0) * hinge:Inverse() * rest
		end
	end)
	local tween = TweenService:Create(
		lift,
		TweenInfo.new(LID_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = if open then LID_OPEN else 0 }
	)
	tween.Completed:Once(function()
		lift:Destroy()
	end)
	tween:Play()
end

local openPart: BasePart? = nil

local function onOpened(id: string, title: string, slots: { Inventory.Stack }, part: BasePart?)
	chestId = id
	chestSlots = slots
	openPart = part
	Window.setTitle(window, title)
	Window.open(window)
	setLid(part, true)
	render()
end

function ChestWindow.SetState(newState: any)
	state = newState
	render()
end

function ChestWindow.Start()
	window = Window.new("Chest", "Chest", WINDOW)
	local body = window.Body

	hoverName = Glass.text(window.Root, "", 17, Glass.Font.Bold, C.Accent)
	hoverName.AnchorPoint = Vector2.new(1, 0)
	hoverName.Position = UDim2.new(1, -76, 0, 22)
	hoverName.Size = UDim2.fromOffset(280, 22)
	hoverName.TextXAlignment = Enum.TextXAlignment.Right

	local y = 0
	for index = 1, Inventory.ChestSize do
		local here = index - 1
		chestButtons[index] =
			buildSlot(body, index + OFFSET, slotAt(here % COLUMNS, y + (here // COLUMNS) * (SLOT + GAP)))
	end
	y += rowsHeight(3) + 12

	local yours = Glass.text(body, "Your items", 16, Glass.Font.Bold)
	yours.Position = UDim2.fromOffset(0, y)
	yours.Size = UDim2.fromOffset(200, 20)
	y += TITLE_ROW
	for index = Inventory.Hotbar + 1, Inventory.Size do
		local here = index - Inventory.Hotbar - 1
		bagButtons[index] = buildSlot(body, index, slotAt(here % COLUMNS, y + (here // COLUMNS) * (SLOT + GAP)))
	end
	y += rowsHeight(3) + 10
	for index = 1, Inventory.Hotbar do
		bagButtons[index] = buildSlot(body, index, slotAt(index - 1, y))
	end

	floating = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(SLOT, SLOT),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Visible = false,
		Parent = window.Gui,
	})
	floatingIcon = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = floating,
	})
	floatingCount = Glass.worldText(floating, "", 16, Glass.Font.Bold)
	floatingCount.AnchorPoint = Vector2.new(1, 1)
	floatingCount.Position = UDim2.new(1, -4, 1, -2)
	floatingCount.Size = UDim2.new(1, 0, 0, 20)
	floatingCount.TextXAlignment = Enum.TextXAlignment.Right
	floatingCount.ZIndex = 21

	RunService.RenderStepped:Connect(function()
		if window.IsOpen and carried then
			local mouse = UserInputService:GetMouseLocation()
			floating.Position = UDim2.fromOffset(mouse.X, mouse.Y)
		end
	end)

	window.OnClose = function()
		carried = nil
		floating.Visible = false
		setLid(openPart, false)
		openPart = nil
		chestId = nil
		Remotes.ChestClose:FireServer()
		hoverName.Text = ""
	end

	Remotes.ChestOpened.OnClientEvent:Connect(onOpened)
	Remotes.ChestUpdate.OnClientEvent:Connect(function(id: string, slots: { Inventory.Stack })
		if id == chestId then
			chestSlots = slots
			render()
		end
	end)
	Remotes.ChestClosed.OnClientEvent:Connect(function(id: string)
		if id == chestId then
			Window.close(window)
		end
	end)
end

return ChestWindow
