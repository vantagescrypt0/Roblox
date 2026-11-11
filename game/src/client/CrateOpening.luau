--!strict
-- Opening a Loot Crate, your design (2026-11-10). Hold a crate and right-click (or tap) anywhere: it drops there, in
-- any place, and a chest-style window shows its 6 slots spaced out in the middle, each with a "?" to click. Clicking a
-- slot spins it: a reel of the things a crate can hold runs past and slows down, landing on what you got. Close the
-- window whenever you like: everything is already in your Bag (the server rolled it all when the crate landed), so
-- closing early only skips the show. Then the crate goes, in a burst of confetti everyone nearby sees.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Config = require(ReplicatedStorage.Shared.Config)
local Items = require(ReplicatedStorage.Shared.Items)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Glass = require(script.Parent.UI.Glass)
local ItemIcon = require(script.Parent.UI.ItemIcon)
local Sfx = require(script.Parent.UI.Sfx)
local Theme = require(script.Parent.UI.Theme)
local Window = require(script.Parent.UI.Window)

local C = Theme.Color
local player = Players.LocalPlayer :: Player

local SLOT = 108
local GAP = 20
local SLOTS = LootCrates.Slots
local WINDOW = Vector2.new(SLOTS * SLOT + (SLOTS - 1) * GAP + 48, 420)
local REEL = 18 -- pictures that run past in a spin, the last one being what you got
local SPIN_TIME = 1.9
local CONFETTI = "rbxasset://textures/particles/SquareParticle.png"
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 82, 82),
	Color3.fromRGB(255, 196, 46),
	Color3.fromRGB(78, 214, 112),
	Color3.fromRGB(64, 170, 255),
	Color3.fromRGB(196, 110, 255),
	Color3.fromRGB(255, 140, 200),
}

type Result = { Item: string, Count: number, Good: boolean }
type Spinner = {
	Slot: Glass.Slot,
	Filler: Frame,
	Clip: Frame,
	Strip: Frame?,
	Glow: ImageLabel,
	Name: TextLabel,
	Result: Result?,
	StartedAt: number?,
	Duration: number,
	LastTick: number,
	Landed: boolean,
}

local CrateOpening = {}

local window: Window.Window
local prompt: TextLabel
local hint: TextLabel
local againButton: Theme.Button
local doneButton: Theme.Button
local spinners: { Spinner } = {}
local results: { Result } = {}
local crateId: string? = nil
local connection: RBXScriptConnection? = nil
local rng = Random.new()
local cratesLeft: () -> number = function()
	return 0
end
local onSale: () -> boolean = function()
	return false
end
local onBuy: (() -> ())? = nil

local function outQuart(x: number): number
	return 1 - (1 - x) ^ 4
end

local function landedCount(): number
	local count = 0
	for _, spinner in spinners do
		if spinner.Landed then
			count += 1
		end
	end
	return count
end

local function goodCount(): number
	local count = 0
	for _, result in results do
		if result.Good then
			count += 1
		end
	end
	return count
end

-- Once every slot has landed: how it went, and what you can do next
local function showEnd()
	local good = goodCount()
	prompt.Text = if good >= 2
		then `{good} good things!`
		elseif good == 1 then "Something good!"
		else "Nothing rare this time"
	prompt.TextColor3 = if good > 0 then C.Gold else C.Ink
	hint.Text = "It's all in your Bag"
	doneButton.Holder.Visible = true
	local left = cratesLeft()
	if left > 0 then
		againButton.Holder.Visible = true
		againButton.SetColor(C.Green)
		againButton.SetText(`Open another ({left} left)`)
	elseif onSale() and onBuy then
		againButton.Holder.Visible = true
		againButton.SetColor(C.Blue)
		againButton.SetText("Get another crate")
	else
		againButton.Holder.Visible = false
	end
	if good > 0 then
		Sfx.play("Coins")
	end
end

local function cellAt(strip: Frame, index: number, itemId: string)
	local cell = Theme.make("Frame", {
		Position = UDim2.fromScale(0, (index - 1) / REEL),
		Size = UDim2.fromScale(1, 1 / REEL),
		BackgroundTransparency = 1,
		Parent = strip,
	})
	ItemIcon.create(cell, itemId, UDim2.fromScale(0.8, 0.8))
end

local function land(spinner: Spinner)
	local result = spinner.Result :: Result
	spinner.Landed = true
	-- Lit like a full slot, and Selected so hovering doesn't dim its edge
	local slot = spinner.Slot
	slot.Item = result.Item
	slot.Selected = true
	slot.Fill.Enabled = true
	slot.Button.BackgroundColor3 = C.Edge
	slot.Button.BackgroundTransparency = 0
	slot.Count.Text = if result.Count > 1 then tostring(result.Count) else ""
	spinner.Slot.Stroke.Color = if result.Good then C.Gold else C.Accent
	spinner.Slot.Stroke.Thickness = if result.Good then 3 else 1.5
	spinner.Slot.Stroke.Transparency = if result.Good then 0 else 0.35
	spinner.Name.Text = Items[result.Item].Name
	spinner.Name.TextColor3 = if result.Good then C.Gold else C.Ink
	spinner.Glow.ImageColor3 = if result.Good then C.Gold else C.Accent
	spinner.Glow.ImageTransparency = if result.Good then 0.1 else 0.55
	-- A little pop as it lands
	local pop: UIScale = (slot.Button:FindFirstChildOfClass("UIScale") :: UIScale?)
		or Theme.make("UIScale", { Parent = slot.Button })
	pop.Scale = 1.14
	TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	if result.Good then
		Sfx.play("Stinger")
		Sfx.play("Chime")
	else
		Sfx.play("Pop", nil, 1.15)
	end
	if landedCount() == #spinners then
		task.delay(0.35, function()
			if landedCount() == #spinners and crateId then
				showEnd()
			end
		end)
	end
end

-- Starts a slot's reel: random things from the crate's list run past, then what you got
local function spin(spinner: Spinner)
	if spinner.StartedAt or not spinner.Result then
		return
	end
	local result = spinner.Result :: Result
	spinner.Filler.Visible = false
	local strip = Theme.make("Frame", {
		Size = UDim2.fromScale(1, REEL),
		BackgroundTransparency = 1,
		Parent = spinner.Clip,
	})
	for index = 1, REEL - 1 do
		local prize = LootCrates.Prizes[rng:NextInteger(1, #LootCrates.Prizes)]
		cellAt(strip, index, prize.Item)
	end
	cellAt(strip, REEL, result.Item)
	spinner.Strip = strip
	spinner.Duration = SPIN_TIME + rng:NextNumber(-0.15, 0.25)
	spinner.StartedAt = os.clock()
	spinner.LastTick = 0
	Sfx.play("Click")
	if prompt.Text == "Click a slot to spin it" then
		prompt.Text = "Click the others too, or close it to skip"
	end
end

-- Every frame: the reels run, and the "?" slots breathe so you can see where to click
local function step()
	local now = os.clock()
	for index, spinner in spinners do
		local started = spinner.StartedAt
		local strip = spinner.Strip
		if not started then
			local breathe = 0.5 + 0.5 * math.sin(now * 3 + index * 0.6)
			spinner.Slot.Stroke.Transparency = 0.15 + 0.5 * breathe
			spinner.Glow.ImageTransparency = 0.55 + 0.3 * breathe
		elseif not spinner.Landed and strip then
			local t = math.clamp((now - started) / spinner.Duration, 0, 1)
			local run = (REEL - 1) * outQuart(t)
			strip.Position = UDim2.fromScale(0, -run)
			local passed = math.floor(run + 0.5)
			if passed > spinner.LastTick then
				spinner.LastTick = passed
				Sfx.play("Pop", nil, 0.85 + 0.5 * t)
			end
			if t >= 1 then
				land(spinner)
			end
		end
	end
end

local function clear()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	for _, spinner in spinners do
		if spinner.Strip then
			spinner.Strip:Destroy()
			spinner.Strip = nil
		end
	end
end

-- The window's slots, made once
local function buildSlots()
	local row = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 58),
		Size = UDim2.fromOffset(SLOTS * SLOT + (SLOTS - 1) * GAP, SLOT + 48),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	for index = 1, SLOTS do
		local x = (index - 1) * (SLOT + GAP)
		local glow = Glass.glow(
			row,
			C.Accent,
			UDim2.fromOffset(SLOT * 1.9, SLOT * 1.9),
			UDim2.fromOffset(x + SLOT / 2, SLOT / 2)
		)
		local slot = Glass.slot(row, SLOT, UDim2.fromOffset(x, 0))
		slot.Button.ZIndex = 1
		local clip = Theme.make("Frame", {
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(1, -12, 1, -12),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = 2,
			Parent = slot.Button,
		})
		-- The filler: a "?" that says "click me"
		local filler = Theme.make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Parent = slot.Button,
		})
		local mark = Glass.worldText(filler, "?", 54, Glass.Font.Title, C.Ink)
		mark.Size = UDim2.fromScale(1, 0.78)
		mark.TextXAlignment = Enum.TextXAlignment.Center
		mark.ZIndex = 2
		local click = Glass.text(filler, "CLICK", 13, Glass.Font.Bold, C.InkMuted)
		click.AnchorPoint = Vector2.new(0, 1)
		click.Position = UDim2.new(0, 0, 1, -8)
		click.TextXAlignment = Enum.TextXAlignment.Center
		click.ZIndex = 2
		local name = Glass.text(row, "", 14, Glass.Font.Bold, C.Ink)
		name.Position = UDim2.fromOffset(x - GAP / 2, SLOT + 6)
		name.Size = UDim2.fromOffset(SLOT + GAP, 38)
		name.TextWrapped = true
		name.TextTruncate = Enum.TextTruncate.None
		name.TextXAlignment = Enum.TextXAlignment.Center
		name.TextYAlignment = Enum.TextYAlignment.Top
		local spinner: Spinner = {
			Slot = slot,
			Filler = filler,
			Clip = clip,
			Strip = nil,
			Glow = glow,
			Name = name,
			Result = nil,
			StartedAt = nil,
			Duration = SPIN_TIME,
			LastTick = 0,
			Landed = false,
		}
		slot.Button.Activated:Connect(function()
			spin(spinner)
		end)
		table.insert(spinners, spinner)
	end
end

local function show(id: string, opened: { Result })
	clear()
	crateId = id
	results = opened
	for index, spinner in spinners do
		spinner.Result = opened[index]
		spinner.StartedAt = nil
		spinner.Landed = false
		spinner.Filler.Visible = true
		spinner.Slot.Selected = false
		Glass.setSlot(spinner.Slot, "", 0)
		spinner.Slot.Stroke.Color = C.Accent
		spinner.Slot.Stroke.Thickness = 2
		spinner.Name.Text = ""
		spinner.Glow.ImageColor3 = C.Accent
	end
	prompt.Text = "Click a slot to spin it"
	prompt.TextColor3 = C.Ink
	hint.Text = "Closing this skips the spins: everything is already in your Bag"
	againButton.Holder.Visible = false
	doneButton.Holder.Visible = false
	Window.open(window)
	connection = RunService.RenderStepped:Connect(step)
	Sfx.play("Open", nil, 0.8)
end

-- Confetti where a crate was, for everyone who can see it
local function confetti(at: Vector3, good: boolean)
	local camera = Workspace.CurrentCamera
	if camera and (camera.CFrame.Position - at).Magnitude > 250 then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "CrateConfetti"
	anchor.Size = Vector3.one * 0.2
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = Workspace
	local each = if good then 32 else 22
	for _, color in CONFETTI_COLORS do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = CONFETTI
		emitter.Color = ColorSequence.new(color)
		emitter.LightEmission = 0
		emitter.LightInfluence = 0 -- its own colours whatever the light, so they stay bright
		emitter.Size = NumberSequence.new(0.36)
		emitter.Squash = NumberSequence.new(0.55)
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Lifetime = NumberRange.new(1.8, 2.8)
		emitter.Speed = NumberRange.new(16, 30)
		emitter.SpreadAngle = Vector2.new(60, 60)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.new(0, -30, 0)
		emitter.Drag = 2.6
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-420, 420)
		emitter.Rate = 0
		emitter.Parent = anchor
		emitter:Emit(each)
	end
	if good then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = Config.GlowImage
		sparkle.Color = ColorSequence.new(C.Gold)
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Lifetime = NumberRange.new(0.6, 1.1)
		sparkle.Speed = NumberRange.new(8, 16)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Rate = 0
		sparkle.Parent = anchor
		sparkle:Emit(24)
	end
	Debris:AddItem(anchor, 4)
	Sfx.play("Pop", at, 0.9)
	Sfx.play(if good then "Stinger" else "Sparkle", at)
end

-- Puts the crate you hold down where you're pointing (`ray`), or in front of you when that's out of reach or
-- there's no ray. Anywhere you can reach works: the ground, a roof, a table. A wall puts it on the floor below.
function CrateOpening.Place(ray: Ray?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local ignore: { Instance } = {}
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	local crates = Workspace:FindFirstChild("Crates")
	if crates then
		table.insert(ignore, crates)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local down = Vector3.new(0, -40, 0)
	local position: Vector3? = nil
	if ray then
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 150, params)
		if hit and (hit.Position - root.Position).Magnitude <= Blocks.Reach then
			if hit.Normal.Y >= 0.6 then
				position = hit.Position
			else
				local floor = Workspace:Raycast(hit.Position + hit.Normal * 1.5, down, params)
				position = if floor then floor.Position else nil
			end
		end
	end
	if not position then
		local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		look = if look.Magnitude > 0.01 then look.Unit else Vector3.zAxis
		local floor = Workspace:Raycast(root.Position + look * 5 + Vector3.new(0, 2, 0), down, params)
		position = if floor then floor.Position else root.Position + look * 5 - Vector3.new(0, 3, 0)
	end
	Remotes.PlaceCrate:FireServer(position)
end

-- `left` says how many crates you have now, `forSale` whether single crates are on sale to you, and `buyMore` opens the
-- window that sells them (its odds show before you can buy).
function CrateOpening.Start(left: () -> number, forSale: () -> boolean, buyMore: () -> ())
	cratesLeft, onSale, onBuy = left, forSale, buyMore
	window = Window.new("CrateOpening", "Loot Crate", WINDOW)
	window.HidesHud = true -- the hotbar would show what you got before the slots do
	window.OnClose = function()
		local id = crateId
		local skipped = landedCount() < #spinners
		clear()
		crateId = nil
		if id then
			Remotes.CrateDone:FireServer(id, skipped)
		end
	end

	prompt = Glass.text(window.Body, "", 22, Glass.Font.Bold, C.Ink)
	prompt.Position = UDim2.fromOffset(0, 8)
	prompt.TextXAlignment = Enum.TextXAlignment.Center
	buildSlots()

	hint = Glass.text(window.Body, "", 14, Glass.Font.Body, C.InkMuted)
	hint.AnchorPoint = Vector2.new(0, 1)
	hint.Position = UDim2.new(0, 0, 1, -62)
	hint.TextXAlignment = Enum.TextXAlignment.Center

	local buttons = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(560, 50),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	againButton = Theme.button(buttons, "Open another", C.Green, UDim2.fromOffset(330, 50), function()
		if cratesLeft() > 0 then
			Window.close(window)
			CrateOpening.Place(nil)
		elseif onSale() and onBuy then
			Window.close(window)
			onBuy()
		end
	end)
	againButton.Holder.AnchorPoint = Vector2.new(0, 0.5)
	againButton.Holder.Position = UDim2.fromScale(0, 0.5)
	doneButton = Theme.button(buttons, "Collect", C.Navy, UDim2.fromOffset(210, 50), function()
		Window.close(window)
	end)
	doneButton.Holder.AnchorPoint = Vector2.new(1, 0.5)
	doneButton.Holder.Position = UDim2.fromScale(1, 0.5)

	Remotes.CrateOpened.OnClientEvent:Connect(show)
	Remotes.CratePopped.OnClientEvent:Connect(confetti)
end

return CrateOpening
