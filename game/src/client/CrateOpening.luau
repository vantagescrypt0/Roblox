--!strict
-- Opening a Loot Crate, full screen. The server has already rolled the crate and the things are already in your Bag: this
-- only shows what you got, in order, so nothing in it can tease a prize you didn't get.
--
-- A chest drops out of the sky onto a floating stone with six rune stones round it, one for each thing inside. They light
-- one by one, faster and higher each time, and the chest shakes harder. A rune lit gold means that slot is something good,
-- and the rays behind the chest catch it. Then the lid blows off and the six things fly out into cards. Click to skip.
--
-- It's all worked out from one clock, so skipping is only moving the clock. ParticleEmitters don't draw inside a
-- ViewportFrame, so the glows and rays are pictures laid over it at the right places on screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local CrateArt = require(ReplicatedStorage.Shared.CrateArt)
local Items = require(ReplicatedStorage.Shared.Items)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemIcon = require(script.Parent.UI.ItemIcon)
local Sfx = require(script.Parent.UI.Sfx)
local Theme = require(script.Parent.UI.Theme)

local C = Theme.Color
local WHITE = Color3.new(1, 1, 1)

-- The timeline, in seconds
local DAIS_RISE = 0.7
local DROP_END = 1.05
local FIRST_RUNE = 1.5
local RUNE_GAPS = { 0.52, 0.47, 0.42, 0.37, 0.32 } -- they come faster
local CHARGE = 0.8 -- from the last rune to the burst
local CARDS_AFTER = 0.2 -- from the burst to the first card
local CARD_GAP = 0.16
local BUTTONS_AFTER = 0.55

local FOV = 30
local CAMERA_FROM = Vector3.new(0, 6.4, -20)
local CAMERA_AT = Vector3.new(0, 0.9, 0)
local RUNE_RING = 3.5
local RUNE_HOVER = 0.35
local DROP_FROM = 17

local CARD_WIDTH = 122
local CARD_HEIGHT = 158
local CARD_GAP_PX = 12
local STAGE_WIDTH = 1040

local COMMON_RUNE = Color3.fromRGB(110, 210, 255)
local DARK_RUNE = Color3.fromRGB(52, 60, 84)

type Result = { Item: string, Count: number, Good: boolean }
type Rune = { Part: BasePart, Glow: ImageLabel, Orb: ImageLabel, At: Vector3, LitAt: number, Good: boolean }
type Card = { Holder: Frame, Scale: UIScale, Shine: ImageLabel?, At: number, Good: boolean, Popped: boolean }
type Cue = { At: number, Run: () -> () }

local CrateOpening = {}

local gui: ScreenGui
local backdrop: TextButton
local viewport: ViewportFrame
local camera: Camera
local rays: ImageLabel
local burstGlow: ImageLabel
local whiteFlash: Frame
local cardsRow: Frame
local heading: TextLabel
local skipHint: TextLabel
local buttons: Frame
local againButton: Theme.Button
local doneButton: Theme.Button
local dais: BasePart?
local body: BasePart?
local lid: BasePart?
local runes: { Rune } = {}
local cards: { Card } = {}
local cues: { Cue } = {}
local stars: { Frame } = {}
local connection: RBXScriptConnection? = nil
local clock = 0
local burstAt = 0
local endAt = 0
local goodCount = 0
local cratesLeft: () -> number = function()
	return 0
end
local onSale: () -> boolean = function()
	return false
end
local onBuy: (() -> ())? = nil
local rng = Random.new()

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

local function outBack(x: number): number
	local p = x - 1
	return 1 + 2.7 * p * p * p + 1.7 * p * p
end

local function outCubic(x: number): number
	return 1 - (1 - x) ^ 3
end

-- Where a point in the scene falls on the screen, as shares of it
local function project(point: Vector3): Vector2
	local there = camera.CFrame:PointToObjectSpace(point)
	local halfHeight = math.tan(math.rad(FOV / 2))
	local size = viewport.AbsoluteSize
	local aspect = if size.Y > 0 then size.X / size.Y else 16 / 9
	local depth = math.max(0.1, -there.Z)
	return Vector2.new(0.5 + there.X / depth / (halfHeight * aspect) / 2, 0.5 - there.Y / depth / halfHeight / 2)
end

local function place(part: BasePart?, name: string, cframe: CFrame)
	if part then
		part.CFrame = cframe * CFrame.new(CrateArt.Parts[name].Offset)
	end
end

local function glowLabel(color: Color3, size: number, zIndex: number): ImageLabel
	return Theme.make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Image = Config.GlowImage,
		ImageColor3 = color,
		ImageTransparency = 1,
		ZIndex = zIndex,
		Parent = backdrop,
	})
end

local function template(name: string): BasePart?
	local folder = ReplicatedStorage:FindFirstChild("CrateModels")
	local part = folder and folder:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		local copy = part:Clone()
		copy.Parent = viewport
		return copy
	end
	return nil
end

local function clearScene()
	for _, child in viewport:GetChildren() do
		if child:IsA("BasePart") then
			child:Destroy()
		end
	end
	for _, rune in runes do
		rune.Glow:Destroy()
		rune.Orb:Destroy()
	end
	runes = {}
	for _, child in cardsRow:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	cards = {}
	cues = {}
end

local function cue(at: number, run: () -> ())
	table.insert(cues, { At = at, Run = run })
end

local function stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	gui.Enabled = false
	clearScene()
end

local function makeCard(index: number, result: Result, at: number)
	local total = LootCrates.Slots
	local width = total * CARD_WIDTH + (total - 1) * CARD_GAP_PX
	local holder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, (index - 0.5) * (CARD_WIDTH + CARD_GAP_PX) - CARD_GAP_PX / 2 - width / 2, 0.5, 0),
		Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT),
		BackgroundTransparency = 1,
		Parent = cardsRow,
	})
	local scale = Theme.make("UIScale", { Scale = 0, Parent = holder })
	local color = if result.Good then C.Gold else C.Accent
	local shine: ImageLabel? = nil
	if result.Good then
		shine = Theme.make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(CARD_WIDTH * 2.5, CARD_WIDTH * 2.5),
			BackgroundTransparency = 1,
			Image = Config.RaysImage,
			ImageColor3 = C.Gold,
			ImageTransparency = 0.25,
			ZIndex = 1,
			Parent = holder,
		})
	end
	local face = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Edge,
		ZIndex = 2,
		Parent = holder,
	})
	Theme.gradient(
		face,
		if result.Good then Color3.fromRGB(96, 70, 22) else C.SlotTop,
		if result.Good then Color3.fromRGB(46, 32, 10) else C.SlotBottom
	)
	Theme.corner(face, 14)
	Theme.stroke(face, color, if result.Good then 3 else 1.5, if result.Good then 0 else 0.35)
	local iconHolder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(76, 76),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = face,
	})
	ItemIcon.create(iconHolder, result.Item, UDim2.fromScale(1, 1))
	local name = Theme.text(face, Items[result.Item].Name, 15, Theme.Font.Bold, if result.Good then C.Gold else C.Ink)
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.new(0.5, 0, 0, 96)
	name.Size = UDim2.new(1, -12, 0, 38)
	name.TextWrapped = true
	name.TextTruncate = Enum.TextTruncate.None
	name.TextXAlignment = Enum.TextXAlignment.Center
	name.TextYAlignment = Enum.TextYAlignment.Top
	name.ZIndex = 3
	if result.Count > 1 then
		local count = Theme.text(face, `x{result.Count}`, 15, Theme.Font.Bold, C.InkMuted)
		count.AnchorPoint = Vector2.new(0.5, 1)
		count.Position = UDim2.new(0.5, 0, 1, -6)
		count.Size = UDim2.new(1, 0, 0, 18)
		count.TextXAlignment = Enum.TextXAlignment.Center
		count.ZIndex = 3
	end
	table.insert(cards, { Holder = holder, Scale = scale, Shine = shine, At = at, Good = result.Good, Popped = false })
end

local function headingText(): string
	if goodCount >= 2 then
		return `{goodCount} good things!`
	elseif goodCount == 1 then
		return "Something good!"
	end
	return "Nothing rare this time"
end

local function showButtons()
	heading.Text = headingText()
	heading.TextColor3 = if goodCount > 0 then C.Gold else C.Ink
	heading.Visible = true
	skipHint.Visible = false
	buttons.Visible = true
	local left = cratesLeft()
	if left > 0 then
		againButton.Holder.Visible = true
		againButton.SetColor(C.Green)
		againButton.SetText(`Open another ({left} left)`)
	elseif onSale() then
		againButton.Holder.Visible = true
		againButton.SetColor(C.Blue)
		againButton.SetText("Get another crate")
	else
		againButton.Holder.Visible = false
	end
end

-- Everything at this moment of the clock
local function render(dt: number)
	-- The stars twinkle whatever the clock says
	for index, star in stars do
		star.BackgroundTransparency = 0.45 + 0.4 * math.sin(os.clock() * (0.8 + index % 5 * 0.3) + index)
	end

	local litCount, litGood = 0, 0
	for _, rune in runes do
		if clock >= rune.LitAt then
			litCount += 1
			if rune.Good then
				litGood += 1
			end
		end
	end

	-- Camera: leans in as it builds, then eases back to show the cards
	local build = clamp01((clock - FIRST_RUNE) / (burstAt - FIRST_RUNE))
	local after = clamp01((clock - burstAt) / 0.6)
	local shake = 0
	if clock >= DROP_END and clock < DROP_END + 0.3 then
		shake = 0.28 * (1 - (clock - DROP_END) / 0.3)
	end
	if clock >= burstAt and clock < burstAt + 0.35 then
		shake = 0.4 * (1 - (clock - burstAt) / 0.35)
	end
	local zoom = 0.82 ^ build
	local from = CAMERA_AT + (CAMERA_FROM - CAMERA_AT) * (zoom + (1.24 - zoom) * outCubic(after))
	local lift = Vector3.new(0, 1.6 * outCubic(after), 0)
	camera.CFrame = CFrame.lookAt(
		from + lift + Vector3.new(rng:NextNumber(-shake, shake), rng:NextNumber(-shake, shake), 0),
		CAMERA_AT + lift
	)

	-- The floating stone rises into place and bobs
	local rise = outBack(clamp01(clock / DAIS_RISE))
	local bob = math.sin(os.clock() * 1.3) * 0.08
	local floor = (1 - rise) * -9 + bob
	place(dais, "Dais", CFrame.new(0, floor, 0))

	-- The chest falls, lands, and shakes as the runes light
	local fall = clamp01((clock - DAIS_RISE) / (DROP_END - DAIS_RISE))
	local height = DROP_FROM * (1 - fall * fall)
	local charged = clamp01((clock - (burstAt - CHARGE)) / CHARGE)
	local tremble = 0.012 * litCount + 0.02 * litGood + 0.06 * charged * charged
	local jolt = if clock >= DROP_END and clock < burstAt
		then Vector3.new(
			rng:NextNumber(-tremble, tremble),
			rng:NextNumber(0, tremble),
			rng:NextNumber(-tremble, tremble)
		)
		else Vector3.zero
	local rise2 = 0.3 * charged * charged * (if clock < burstAt then 1 else 0)
	local chest = CFrame.new(Vector3.new(0, floor + height + rise2, 0) + jolt)
		* CFrame.Angles(0, 0, if clock < burstAt then rng:NextNumber(-tremble, tremble) * 0.5 else 0)
	place(body, "Body", chest)

	-- The lid sits on top until the burst, then it's thrown up and away, spinning
	local lidFrame = chest * CFrame.new(0, 1.3, 0)
	if clock >= burstAt then
		local gone = clock - burstAt
		lidFrame = CFrame.new(0, floor + 1.3 + 15 * gone - 16 * gone * gone, 0)
			* CFrame.new(3.4 * gone, 0, 6.5 * gone)
			* CFrame.Angles(5.4 * gone, 1.6 * gone, 3.8 * gone)
	end
	place(lid, "Lid", lidFrame)

	-- The runes: each lights in its turn and an orb of its light flies into the chest
	for _, rune in runes do
		local lit = clamp01((clock - rune.LitAt) / 0.18)
		local color = if rune.Good then C.Gold else COMMON_RUNE
		rune.Part.Color = DARK_RUNE:Lerp(color, lit)
		local up = RUNE_HOVER + 0.5 * outBack(lit) + 0.06 * math.sin(os.clock() * 2 + rune.At.X)
		local turn = (clock - rune.LitAt) * lit * 1.4
		place(rune.Part, "Rune", CFrame.new(rune.At + Vector3.new(0, floor + up, 0)) * CFrame.Angles(0, turn, 0))
		local spot = project(rune.At + Vector3.new(0, floor + up + 0.7, 0))
		rune.Glow.Position = UDim2.fromScale(spot.X, spot.Y)
		local pulse = 0.08 * math.sin(os.clock() * 6 + rune.At.Z)
		rune.Glow.ImageTransparency = 1 - lit * (if rune.Good then 0.92 else 0.62) + pulse * lit
		local size = (if rune.Good then 210 else 130) * (1 + 0.35 * clamp01(1 - (clock - rune.LitAt) / 0.3))
		rune.Glow.Size = UDim2.fromOffset(size, size)

		local flight = (clock - rune.LitAt) / 0.28
		if flight > 0 and flight < 1 then
			local crateSpot = project(Vector3.new(0, floor + 1.2, 0))
			local here = spot:Lerp(crateSpot, flight * flight)
			rune.Orb.Position = UDim2.fromScale(here.X, here.Y)
			rune.Orb.ImageTransparency = 0.05 + 0.4 * flight
		else
			rune.Orb.ImageTransparency = 1
		end
	end

	-- The chest's glow and the rays: they catch as soon as a gold rune lights
	local crateSpot = project(Vector3.new(0, floor + 1.1, 0))
	local rayColor = if litGood > 0 or (clock >= burstAt and goodCount > 0) then C.Gold else COMMON_RUNE
	rays.ImageColor3 = rayColor
	burstGlow.ImageColor3 = rayColor
	local before = (if litGood > 0 then 0.35 + 0.1 * litGood else 0.06 * litCount) * (if clock < burstAt then 1 else 0)
	local afterGlow = if clock >= burstAt then 0.85 - 0.25 * clamp01((clock - burstAt) / 1.2) else 0
	local rayStrength = math.max(before + 0.4 * charged * charged, afterGlow)
	rays.ImageTransparency = 1 - rayStrength
	rays.Position = UDim2.fromScale(crateSpot.X, crateSpot.Y)
	rays.Rotation += dt * (12 + 30 * rayStrength)
	burstGlow.ImageTransparency = 1 - rayStrength * 0.8
	burstGlow.Position = rays.Position
	whiteFlash.BackgroundTransparency = if clock >= burstAt then clamp01((clock - burstAt) / 0.32) else 1

	-- The cards pop out of the chest in order
	for _, card in cards do
		local shown = clamp01((clock - card.At) / 0.26)
		card.Scale.Scale = outBack(shown)
		if card.Shine then
			card.Shine.Rotation += dt * 40
			card.Shine.ImageTransparency = 1 - 0.75 * shown
		end
	end

	-- Sounds and the rest, each the moment the clock passes it
	for index = #cues, 1, -1 do
		local item = cues[index]
		if clock >= item.At then
			table.remove(cues, index)
			item.Run()
		end
	end
end

local function skip()
	if clock < endAt then
		-- Straight to the end, without every sound at once
		cues = {}
		clock = endAt
		for _, card in cards do
			card.Popped = true
		end
		showButtons()
	end
end

function CrateOpening.Play(results: { Result })
	if connection then
		connection:Disconnect()
		connection = nil
	end
	clearScene()
	goodCount = 0
	for _, result in results do
		if result.Good then
			goodCount += 1
		end
	end

	dais = template("Dais")
	body = template("Body")
	lid = template("Lid")
	local at = FIRST_RUNE
	for index, result in results do
		local angle = math.rad((index - 1) * 60)
		local part = template("Rune")
		if part then
			part.Material = Enum.Material.SmoothPlastic
			part.Color = DARK_RUNE
			table.insert(runes, {
				Part = part,
				Glow = glowLabel(if result.Good then C.Gold else COMMON_RUNE, 130, 4),
				Orb = glowLabel(if result.Good then C.Gold else WHITE, 46, 5),
				At = Vector3.new(math.cos(angle) * RUNE_RING, 0, math.sin(angle) * RUNE_RING),
				LitAt = at,
				Good = result.Good,
			})
		end
		local lit = index
		local good = result.Good
		cue(at, function()
			Sfx.play("Pop", nil, 0.8 + lit * 0.14)
			if good then
				Sfx.play("Stinger")
				Sfx.play("Coins")
			end
		end)
		at += RUNE_GAPS[index] or RUNE_GAPS[#RUNE_GAPS]
	end
	-- `at` is one gap past the last rune; the burst is counted from the last rune itself
	local last = at - (RUNE_GAPS[#results] or RUNE_GAPS[#RUNE_GAPS])
	burstAt = last + CHARGE
	cue(DROP_END, function()
		Sfx.play("StoneBreak", nil, 0.7)
		Sfx.play("Craft")
	end)
	cue(0.15, function()
		Sfx.play("Travel")
	end)
	cue(burstAt - CHARGE * 0.6, function()
		Sfx.play("Open", nil, 0.7)
	end)
	cue(burstAt, function()
		Sfx.play("TreeFall")
		Sfx.play(if goodCount > 0 then "Stinger" else "Sparkle")
	end)
	local cardAt = burstAt + CARDS_AFTER
	for index, result in results do
		makeCard(index, result, cardAt)
		local good = result.Good
		local step = index
		cue(cardAt, function()
			Sfx.play("Pop", nil, 0.9 + step * 0.06)
			if good then
				Sfx.play("Chime")
				Sfx.play("Sparkle")
			end
		end)
		cardAt += CARD_GAP
	end
	endAt = cardAt + BUTTONS_AFTER
	cue(endAt, showButtons)

	clock = 0
	heading.Visible = false
	buttons.Visible = false
	skipHint.Visible = true
	rays.ImageTransparency = 1
	burstGlow.ImageTransparency = 1
	whiteFlash.BackgroundTransparency = 1
	gui.Enabled = true
	connection = RunService.RenderStepped:Connect(function(dt: number)
		clock += dt
		render(dt)
	end)
end

-- `left` says how many crates you have now, `forSale` whether single crates are on sale to you, and `buyMore` opens the
-- window that sells them (its odds show before you can buy).
function CrateOpening.Start(left: () -> number, forSale: () -> boolean, buyMore: () -> ())
	cratesLeft, onSale, onBuy = left, forSale, buyMore
	gui = Theme.screen("CrateOpening", 100)
	gui.IgnoreGuiInset = true
	gui.Enabled = false

	backdrop = Theme.make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Edge,
		AutoButtonColor = false,
		Text = "",
		Parent = gui,
	})
	Theme.gradient(backdrop, Color3.fromRGB(10, 16, 44), Color3.fromRGB(3, 5, 16))
	backdrop.Activated:Connect(skip)

	local random = Random.new(7)
	for _ = 1, 70 do
		local size = random:NextInteger(2, 4)
		local star = Theme.make("Frame", {
			Position = UDim2.fromScale(random:NextNumber(), random:NextNumber()),
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			Parent = backdrop,
		})
		table.insert(stars, star)
	end

	rays = Theme.make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(1150, 1150),
		BackgroundTransparency = 1,
		Image = Config.RaysImage,
		ImageTransparency = 1,
		ZIndex = 1,
		Parent = backdrop,
	})
	burstGlow = glowLabel(C.Gold, 620, 1)

	viewport = Theme.make("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(150, 155, 185),
		LightColor = Color3.fromRGB(255, 244, 225),
		LightDirection = Vector3.new(-0.5, -1, 0.7),
		ZIndex = 2,
		Parent = backdrop,
	})
	camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	camera.CFrame = CFrame.lookAt(CAMERA_FROM, CAMERA_AT)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	whiteFlash = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = backdrop,
	})

	local stage = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(STAGE_WIDTH, 360),
		BackgroundTransparency = 1,
		ZIndex = 7,
		Parent = backdrop,
	})
	Theme.autoScale(stage)
	heading = Theme.title(stage, "", 32, C.Gold)
	heading.Position = UDim2.fromOffset(0, 0)
	heading.Size = UDim2.new(1, 0, 0, 40)
	heading.TextXAlignment = Enum.TextXAlignment.Center
	heading.ZIndex = 8
	heading.Visible = false
	Theme.outline(heading)
	cardsRow = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, CARD_HEIGHT + 16),
		BackgroundTransparency = 1,
		ZIndex = 8,
		Parent = stage,
	})
	buttons = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(560, 54),
		BackgroundTransparency = 1,
		ZIndex = 8,
		Visible = false,
		Parent = stage,
	})
	againButton = Theme.button(buttons, "Open another", C.Green, UDim2.fromOffset(330, 52), function()
		if cratesLeft() > 0 then
			Remotes.OpenCrate:FireServer()
		elseif onSale() and onBuy then
			stop()
			onBuy()
		end
	end)
	againButton.Holder.AnchorPoint = Vector2.new(0, 0.5)
	againButton.Holder.Position = UDim2.fromScale(0, 0.5)
	doneButton = Theme.button(buttons, "Done", C.Navy, UDim2.fromOffset(210, 52), stop)
	doneButton.Holder.AnchorPoint = Vector2.new(1, 0.5)
	doneButton.Holder.Position = UDim2.fromScale(1, 0.5)

	skipHint = Theme.text(backdrop, "Click to skip", 16, Theme.Font.Medium, C.InkMuted)
	skipHint.AnchorPoint = Vector2.new(0.5, 1)
	skipHint.Position = UDim2.new(0.5, 0, 1, -18)
	skipHint.Size = UDim2.fromOffset(300, 22)
	skipHint.TextXAlignment = Enum.TextXAlignment.Center
	skipHint.ZIndex = 8
end

return CrateOpening
