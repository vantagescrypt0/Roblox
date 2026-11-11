--!strict
-- Another player's profile (ProfileService): left-click (tap) them anywhere but the Warzone. On the left, their
-- character as they look right now, armour, pet and all, turning slowly on a lit stage (drag to spin it), with their
-- name and a title from their best skill. On the right: level, coins and skill total; what they're wearing and
-- holding; each skill's level; their season, island, boosts, kits and trades. Along the bottom, Trade (any distance,
-- both players level Leveling.TradeLevel), Add Friend, and Visit Island when you're both on island servers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local BetaTag = require(ReplicatedStorage.Shared.BetaTag)
local Items = require(ReplicatedStorage.Shared.Items)
local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Glass = require(script.Parent.Parent.UI.Glass)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color
local localPlayer = Players.LocalPlayer

local STAGE_WIDTH = 300
local GAP = 12
local SLOT = 60
local SPIN = 0.45 -- radians a second while nobody's dragging
local PET_SPOT = CFrame.new(2.3, 0.2, 0.6) -- where the pet stands on the stage, from the character's middle
local SLOTS = {
	{ Key = "Helmet", Label = "Helmet" },
	{ Key = "Chest", Label = "Chest" },
	{ Key = "Legs", Label = "Legs" },
	{ Key = "Boots", Label = "Boots" },
	{ Key = "Shield", Label = "Shield" },
	{ Key = "Pet", Label = "Pet" },
	{ Key = "Held", Label = "In hand" },
}

export type Snapshot = {
	UserId: number,
	Name: string,
	DisplayName: string,
	Title: string,
	Level: number,
	MaxLevel: number,
	Progress: number,
	Coins: number,
	Season: number,
	Skills: { { Id: string, Name: string, Icon: string, Level: number, Progress: number } },
	SkillTotal: number,
	Equipped: { [string]: string },
	Held: string?,
	Boosts: { Warzone: number, Player: number, Island: number, Most: number },
	IslandTier: number,
	Trades: number,
	Kits: number,
	TradeLevel: number,
	Beta: number?,
}

type SlotView = { Box: Frame, Icon: Frame, Name: TextLabel }
type SkillView = { Icon: Frame, Level: TextLabel, Bar: Theme.Bar }

local ProfileWindow = {}

local window: Window.Window
local viewport: ViewportFrame
local world: WorldModel
local camera: Camera
local headshot: ImageLabel
local nameLabel: TextLabel
local handleLabel: TextLabel
local titleChip: TextLabel
local betaChip: TextLabel
local levelNumber: TextLabel
local levelBar: Theme.Bar
local coinsLabel: TextLabel
local totalLabel: TextLabel
local slots: { [string]: SlotView } = {}
local skillViews: { [string]: SkillView } = {}
local chips: Frame
local tradeButton: Theme.Button
local friendButton: Theme.Button
local visitButton: Theme.Button
local loading: TextLabel

local target: Player? = nil
local shown: Snapshot? = nil
local myLevel = 1
local model: Model? = nil
local angle = math.pi
local dragging: Vector2? = nil
local spinConnection: RBXScriptConnection? = nil

-- A still copy of their character for the stage: no scripts, nothing that moves or talks
local function copyOf(player: Player): Model?
	local character = player.Character
	if not character then
		return nil
	end
	local was = character.Archivable
	character.Archivable = true
	local ok, copy = pcall(function()
		return character:Clone()
	end)
	character.Archivable = was
	if not ok or not copy then
		return nil
	end
	for _, item in copy:GetDescendants() do
		if
			item:IsA("BaseScript")
			or item:IsA("ModuleScript")
			or item:IsA("Sound")
			or item:IsA("ProximityPrompt")
			or item:IsA("BillboardGui")
			or item:IsA("Constraint")
			or item:IsA("IKControl")
			or item:IsA("Tool")
		then
			item:Destroy()
		elseif item:IsA("BasePart") then
			item.Anchored = true
		end
	end
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	-- Their pet (a model on the character, GearService) stands close at their side on the stage
	local root = copy.PrimaryPart
	for _, child in copy:GetChildren() do
		if root and child:IsA("Model") and child.PrimaryPart and string.find(child.Name, "'s ", 1, true) then
			child:PivotTo(root.CFrame * PET_SPOT)
		end
	end
	return copy
end

local function stopSpin()
	if spinConnection then
		spinConnection:Disconnect()
		spinConnection = nil
	end
end

local function pose()
	local current = model
	if current and current.PrimaryPart then
		current:PivotTo(CFrame.Angles(0, angle, 0))
	end
end

-- Puts their character on the stage and frames it
local function stage(player: Player)
	if model then
		model:Destroy()
		model = nil
	end
	local copy = copyOf(player)
	headshot.Visible = copy == nil
	headshot.Image = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=420&h=420`
	if not copy or not copy.PrimaryPart then
		if copy then
			copy:Destroy()
		end
		return
	end
	model = copy
	angle = math.pi
	copy.Parent = world
	pose()
	-- Frame them so they stay in view all the way round: how far anything reaches from the middle, and how
	-- high and low it goes
	local reach, top, bottom = 1, -math.huge, math.huge
	for _, part in copy:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local at = part.Position
			local half = part.Size.Magnitude / 2
			reach = math.max(reach, Vector2.new(at.X, at.Z).Magnitude + half * 0.6)
			top = math.max(top, at.Y + half * 0.7)
			bottom = math.min(bottom, at.Y - half * 0.7)
		end
	end
	if top < bottom then
		top, bottom = 3, -3
	end
	local tall = math.tan(math.rad(camera.FieldOfView / 2))
	local frame = viewport.AbsoluteSize
	local aspect = if frame.Y > 0 then frame.X / frame.Y else 0.75
	local distance = math.max((top - bottom) / 2 / tall, reach / (tall * aspect)) * 1.15
	local middle = Vector3.new(0, (top + bottom) / 2, 0)
	camera.CFrame = CFrame.lookAt(middle + Vector3.new(0, 0.6, distance), middle)
	stopSpin()
	spinConnection = RunService.RenderStepped:Connect(function(dt)
		if not dragging then
			angle += SPIN * dt
			pose()
		end
	end)
end

local function setSlot(view: SlotView, itemId: string?)
	Window.clear(view.Icon)
	local item = if itemId and itemId ~= "" then Items[itemId] else nil
	if item and itemId then
		ItemIcon.create(view.Icon, itemId, UDim2.fromScale(0.92, 0.92))
		view.Name.Text = item.Name
		view.Name.TextColor3 = C.Ink
	else
		view.Name.Text = "None"
		view.Name.TextColor3 = C.Muted
	end
end

local function addChip(text: string, color: Color3?, order: number)
	local chip = Theme.chip(chips, text, color)
	chip.LayoutOrder = order
end

local function updateTrade()
	local now = shown
	if not now then
		return
	end
	if Places.Current() == "Warzone" then
		tradeButton.SetText("No trading here")
		tradeButton.SetEnabled(false)
	elseif myLevel < now.TradeLevel then
		tradeButton.SetText(`Trade at level {now.TradeLevel}`)
		tradeButton.SetEnabled(false)
	elseif now.Level < now.TradeLevel then
		tradeButton.SetText(`They trade at level {now.TradeLevel}`)
		tradeButton.SetEnabled(false)
	else
		tradeButton.SetText("Trade")
		tradeButton.SetEnabled(true)
	end
end

local function render(now: Snapshot)
	loading.Visible = false
	Window.setTitle(window, `{now.DisplayName}'s Profile`)
	nameLabel.Text = now.DisplayName
	handleLabel.Text = `@{now.Name}`
	titleChip.Text = now.Title
	local beta = now.Beta or 0
	betaChip.Text = `BETA TESTER #{beta}`
	betaChip.Visible = beta > 0
	levelNumber.Text = tostring(now.Level)
	levelBar.Set(
		now.Progress,
		if now.Level >= now.MaxLevel then "Max level" else `{math.floor(now.Progress * 100)}% to level {now.Level + 1}`
	)
	coinsLabel.Text = Theme.formatNumber(now.Coins)
	totalLabel.Text = tostring(now.SkillTotal)

	for _, info in SLOTS do
		local itemId = if info.Key == "Held" then now.Held else now.Equipped[info.Key]
		setSlot(slots[info.Key], itemId)
	end
	for _, skill in now.Skills do
		local view = skillViews[skill.Id]
		if view then
			view.Level.Text = tostring(skill.Level)
			view.Bar.Set(skill.Progress)
		end
	end

	Window.clear(chips)
	addChip(`Season {now.Season}`, C.Gold, 1)
	addChip(`Island tier {now.IslandTier}`, C.Green, 2)
	local boosts = now.Boosts
	addChip(`Boosts {boosts.Warzone} · {boosts.Player} · {boosts.Island}`, C.Teal, 3)
	if now.Kits > 0 then
		addChip(`{now.Kits} {if now.Kits == 1 then "kit" else "kits"}`, C.Purple, 4)
	end
	addChip(`{now.Trades} {if now.Trades == 1 then "trade" else "trades"}`, nil, 5)

	updateTrade()
	visitButton.Holder.Visible = Places.Current() == "Island"
	friendButton.SetText("Add Friend")
	friendButton.SetEnabled(true)
	local userId = now.UserId
	task.spawn(function()
		local ok, friends = pcall(function()
			return localPlayer:IsFriendsWith(userId)
		end)
		if ok and friends and shown and shown.UserId == userId then
			friendButton.SetText("Friends ✓")
			friendButton.SetEnabled(false)
		end
	end)
end

-- Opens the profile of another player on this server
function ProfileWindow.Open(player: Player)
	if player == localPlayer or player.Parent ~= Players then
		return
	end
	target = player
	shown = nil
	loading.Visible = true
	Window.setTitle(window, `{player.DisplayName}'s Profile`)
	nameLabel.Text = player.DisplayName
	handleLabel.Text = `@{player.Name}`
	titleChip.Text = "..."
	betaChip.Visible = false
	Remotes.ProfileOpen:FireServer(player)
	if not window.IsOpen then
		Window.open(window)
	end
	stage(player)
end

function ProfileWindow.SetState(state: any)
	if state and type(state.Level) == "number" then
		myLevel = state.Level
		updateTrade()
	end
end

local function statTile(parent: Instance, x: number, width: number, heading: string): Frame
	local tile = Theme.card(parent, UDim2.fromOffset(width, 92), UDim2.fromOffset(x, 0))
	local label = Theme.text(tile, heading, 14, Theme.Font.Bold, C.Muted)
	label.Position = UDim2.fromOffset(14, 8)
	label.Size = UDim2.new(1, -28, 0, 18)
	return tile
end

local function build()
	window = Window.new("ProfileWindow", "Profile", Vector2.new(900, 590))
	window.OnClose = function()
		stopSpin()
		if model then
			model:Destroy()
			model = nil
		end
		target = nil
	end

	-- The stage
	local stageFrame = Glass.stage(window.Body, UDim2.new(0, STAGE_WIDTH, 1, 0))
	Glass.glow(stageFrame, C.Accent, UDim2.fromScale(1.3, 0.9), UDim2.fromScale(0.5, 0.45), 0.55)
	viewport = Theme.make("ViewportFrame", {
		Size = UDim2.new(1, 0, 1, -96),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 180, 200),
		LightColor = Color3.fromRGB(255, 248, 235),
		LightDirection = Vector3.new(-0.4, -1, -0.6),
		ZIndex = 2,
		Parent = stageFrame,
	})
	world = Theme.make("WorldModel", { Parent = viewport })
	camera = Theme.make("Camera", { FieldOfView = 30, Parent = viewport })
	viewport.CurrentCamera = camera
	headshot = Theme.make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -48),
		Size = UDim2.fromOffset(200, 200),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 2,
		Parent = stageFrame,
	})
	-- Drag across the stage to turn them
	viewport.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		local from = dragging
		if
			from
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local at = Vector2.new(input.Position.X, input.Position.Y)
			angle += (at.X - from.X) * 0.012
			dragging = at
			pose()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = nil
		end
	end)

	local nameplate = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 96),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = stageFrame,
	})
	Theme.padding(nameplate, 16, 16, 0, 12)
	nameLabel = Theme.title(nameplate, "", 26, C.White)
	nameLabel.Size = UDim2.new(1, 0, 0, 30)
	handleLabel = Theme.text(nameplate, "", 15, Theme.Font.Medium, C.Muted)
	handleLabel.Position = UDim2.fromOffset(0, 30)
	titleChip = Theme.chip(nameplate, "", C.Gold)
	titleChip.Position = UDim2.fromOffset(0, 54)
	-- A Beta Tester's number, in the stage's top corner
	betaChip = Theme.chip(stageFrame, "", BetaTag.Color)
	betaChip.Position = UDim2.fromOffset(14, 14)
	betaChip.ZIndex = 3
	betaChip.Visible = false

	-- The right-hand side
	local side = Theme.make("Frame", {
		Position = UDim2.fromOffset(STAGE_WIDTH + GAP + 4, 0),
		Size = UDim2.new(1, -(STAGE_WIDTH + GAP + 4), 1, 0),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	local width = 900 - 48 - STAGE_WIDTH - GAP - 4
	local tileWidth = math.floor((width - GAP * 2) / 3)

	local levelTile = statTile(side, 0, tileWidth, "LEVEL")
	levelNumber = Theme.title(levelTile, "1", 34, C.Gold)
	levelNumber.Position = UDim2.fromOffset(14, 24)
	levelNumber.Size = UDim2.new(1, -28, 0, 38)
	levelBar = Theme.bar(levelTile, C.Gold, UDim2.new(1, -28, 0, 16), true)
	levelBar.Track.Position = UDim2.fromOffset(14, 66)
	levelBar.Label.TextSize = 11

	local coinsTile = statTile(side, tileWidth + GAP, tileWidth, "COINS")
	local coinHolder = Theme.make("Frame", {
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		Parent = coinsTile,
	})
	Theme.coin(coinHolder)
	coinsLabel = Theme.title(coinsTile, "0", 28, C.Ink)
	coinsLabel.Position = UDim2.fromOffset(58, 34)
	coinsLabel.Size = UDim2.new(1, -70, 0, 34)

	local totalTile = statTile(side, (tileWidth + GAP) * 2, tileWidth, "SKILL TOTAL")
	totalLabel = Theme.title(totalTile, "5", 34, C.Accent)
	totalLabel.Position = UDim2.fromOffset(14, 28)
	totalLabel.Size = UDim2.new(1, -28, 0, 38)

	-- What they wear and hold
	local wearing = Theme.card(side, UDim2.new(1, 0, 0, 112), UDim2.fromOffset(0, 92 + GAP))
	local wearTitle = Theme.text(wearing, "WEARING", 14, Theme.Font.Bold, C.Muted)
	wearTitle.Position = UDim2.fromOffset(14, 6)
	local row = Theme.make("Frame", {
		Position = UDim2.fromOffset(10, 26),
		Size = UDim2.new(1, -20, 0, 84),
		BackgroundTransparency = 1,
		Parent = wearing,
	})
	local rowLayout = Theme.list(row, Enum.FillDirection.Horizontal, 8)
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	for order, info in SLOTS do
		local cell = Theme.make("Frame", {
			Size = UDim2.fromOffset(SLOT + 6, 84),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Parent = row,
		})
		local box = Theme.inset(cell, UDim2.fromOffset(SLOT, SLOT), UDim2.fromOffset(3, 0))
		local icon = Theme.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = box,
		})
		local name = Theme.text(cell, "", 11, Theme.Font.Bold, C.Muted)
		name.Position = UDim2.fromOffset(0, SLOT + 2)
		name.Size = UDim2.new(1, 0, 0, 12)
		name.TextXAlignment = Enum.TextXAlignment.Center
		local label = Theme.text(cell, info.Label, 10, Theme.Font.Medium, C.Muted)
		label.Position = UDim2.fromOffset(0, SLOT + 14)
		label.Size = UDim2.new(1, 0, 0, 10)
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextTransparency = 0.35
		slots[info.Key] = { Box = box, Icon = icon, Name = name }
	end

	-- Skills
	local skillsCard = Theme.card(side, UDim2.new(1, 0, 0, 128), UDim2.fromOffset(0, 92 + 112 + GAP * 2))
	local skillsTitle = Theme.text(skillsCard, "SKILLS", 14, Theme.Font.Bold, C.Muted)
	skillsTitle.Position = UDim2.fromOffset(14, 6)
	local skillRow = Theme.make("Frame", {
		Position = UDim2.fromOffset(10, 28),
		Size = UDim2.new(1, -20, 0, 92),
		BackgroundTransparency = 1,
		Parent = skillsCard,
	})
	local skillLayout = Theme.list(skillRow, Enum.FillDirection.Horizontal, 8)
	skillLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local Skills = require(ReplicatedStorage.Shared.Skills)
	local skillWidth = math.floor((width - 20 - 8 * (#Skills.List - 1)) / #Skills.List)
	for order, skill in Skills.List do
		local tile = Theme.inset(skillRow, UDim2.fromOffset(skillWidth, 92))
		tile.LayoutOrder = order
		local icon = Theme.make("Frame", {
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(34, 34),
			BackgroundTransparency = 1,
			Parent = tile,
		})
		ItemIcon.create(icon, skill.Icon, UDim2.fromScale(1, 1))
		local level = Theme.title(tile, "1", 26, C.Ink)
		level.Position = UDim2.fromOffset(46, 8)
		level.Size = UDim2.new(1, -54, 0, 30)
		local name = Theme.text(tile, skill.Name, 13, Theme.Font.Bold, C.Muted)
		name.Position = UDim2.fromOffset(8, 46)
		name.Size = UDim2.new(1, -16, 0, 16)
		local bar = Theme.bar(tile, C.Leaf, UDim2.new(1, -16, 0, 8), false)
		bar.Track.Position = UDim2.fromOffset(8, 70)
		skillViews[skill.Id] = { Icon = icon, Level = level, Bar = bar }
	end

	-- Season, island, boosts, kits, trades
	chips = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 92 + 112 + 128 + GAP * 3),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Parent = side,
	})
	Theme.list(chips, Enum.FillDirection.Horizontal, 8)

	-- Buttons
	local buttons = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		Parent = side,
	})
	Theme.list(buttons, Enum.FillDirection.Horizontal, 10)
	tradeButton = Theme.button(buttons, "Trade", C.Green, UDim2.fromOffset(200, 50), function()
		if target and target.Parent == Players then
			Remotes.TradeRequest:FireServer(target)
			Window.close(window)
		end
	end)
	tradeButton.Holder.LayoutOrder = 1
	tradeButton.Label.TextSize = 21
	friendButton = Theme.button(buttons, "Add Friend", C.Purple, UDim2.fromOffset(170, 50), function()
		if target and target.Parent == Players then
			pcall(function()
				StarterGui:SetCore("PromptSendFriendRequest", target)
			end)
		end
	end)
	friendButton.Holder.LayoutOrder = 2
	visitButton = Theme.button(buttons, "Visit Island", C.Accent, UDim2.fromOffset(160, 50), function()
		if target and target.Parent == Players then
			Remotes.VisitGo:FireServer(target.UserId)
			Window.close(window)
		end
	end)
	visitButton.Holder.LayoutOrder = 3
	visitButton.Holder.Visible = false

	loading = Theme.text(side, "Loading...", 18, Theme.Font.Bold, C.Muted)
	loading.AnchorPoint = Vector2.new(0.5, 0.5)
	loading.Position = UDim2.fromScale(0.5, 0.5)
	loading.TextXAlignment = Enum.TextXAlignment.Center
	loading.Visible = false
end

function ProfileWindow.Start()
	build()
	Remotes.ProfileShow.OnClientEvent:Connect(function(snapshot: Snapshot)
		if target and snapshot.UserId == target.UserId then
			shown = snapshot
			render(snapshot)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if player == target and window.IsOpen then
			Window.close(window)
		end
	end)
end

return ProfileWindow
