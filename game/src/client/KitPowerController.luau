--!strict
-- The armour kits' specials on your screen (KitPowers.luau): a quick right-click with a kit's sword fires its special, a
-- button beside the hotbar shows what it is and how long until it's back, and tapping that button does the same on a
-- touch screen. Also draws everyone's specials going off. The server decides whether any of it happens.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local KitPowers = require(ReplicatedStorage.Shared.KitPowers)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Hotbar = require(script.Parent.Hotbar)
local Glass = require(script.Parent.UI.Glass)
local Sfx = require(script.Parent.UI.Sfx)
local Theme = require(script.Parent.UI.Theme)

local C = Glass.Color
local player = Players.LocalPlayer

local AIM_RANGE = 80
local BUTTON_WIDTH = 190
local BUTTON_HEIGHT = 56
local FROM_MIDDLE = 300 -- pixels right of the middle of the screen: just past the hotbar
local WHITE = Color3.new(1, 1, 1)

local KitPowerController = {}

local face: TextButton
local nameLabel: TextLabel
local hintLabel: TextLabel
local cover: Frame
local timeLabel: TextLabel
local buffBar: Frame
local shownSword: string? = nil
local lastReady = true

local function heldSpecial(): KitPowers.Special?
	local held = Hotbar.SelectedItem()
	return if held then KitPowers.Swords[held] else nil
end

local function secondsLeft(): number
	local ready = player:GetAttribute("KitReadyAt")
	return if type(ready) == "number" then math.max(0, ready - Workspace:GetServerTimeNow()) else 0
end

-- The character under the pointer or crosshair, if any
local function aimed(): Model?
	local camera = Workspace.CurrentCamera
	local character = player.Character
	if not camera or not character then
		return nil
	end
	local at = UserInputService:GetMouseLocation()
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		at = camera.ViewportSize / 2
	end
	local ray = camera:ViewportPointToRay(at.X, at.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, camera, Workspace:FindFirstChild("Bodies") :: Instance }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * AIM_RANGE, params)
	local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	return if model and model:FindFirstChildOfClass("Humanoid") then model else nil
end

local function fire()
	local special = heldSpecial()
	if not special then
		return
	end
	if secondsLeft() > 0 then
		Sfx.play("Error")
		return
	end
	Remotes.KitPower:FireServer(aimed())
end

-- A quick right-click, already known not to have opened or placed anything. True if a kit's sword used it.
function KitPowerController.RightClick(): boolean
	if not heldSpecial() then
		return false
	end
	fire()
	return true
end

KitPowerController.QuickClick = KitPowers.QuickClick

-- The button -------------------------------------------------------------------------

local function showFor(special: KitPowers.Special?, sword: string?)
	if sword == shownSword then
		return
	end
	shownSword = sword
	face.Visible = special ~= nil
	if special then
		nameLabel.Text = special.Name
		nameLabel.TextColor3 = special.Color
		local stroke = face:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = special.Color
		end
		buffBar.BackgroundColor3 = special.Color
	end
end

local function refresh()
	local held = Hotbar.SelectedItem()
	local special = held and KitPowers.Swords[held] or nil
	showFor(special, if special then held else nil)
	if not special then
		return
	end
	local left = secondsLeft()
	local ready = left <= 0
	if ready ~= lastReady then
		lastReady = ready
		if ready then
			Sfx.play("Chime")
		end
	end
	local total = player:GetAttribute("KitCooldown")
	cover.Visible = not ready
	timeLabel.Visible = not ready
	hintLabel.Visible = ready
	if not ready then
		cover.Size = UDim2.fromScale(if type(total) == "number" then math.clamp(left / total, 0, 1) else 1, 1)
		timeLabel.Text = `{math.ceil(left)}s`
	end
	local buff = player:GetAttribute("KitBuffUntil")
	local buffLeft = if type(buff) == "number" then buff - Workspace:GetServerTimeNow() else 0
	buffBar.Visible = buffLeft > 0
	if buffLeft > 0 then
		buffBar.Size = UDim2.new(math.clamp(buffLeft / (special.Lasts or 10), 0, 1), 0, 0, 4)
	end
end

local function build()
	local gui = Theme.screen("KitPower", 3)
	local holder = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0.5, FROM_MIDDLE, 1, -14),
		Size = UDim2.fromOffset(BUTTON_WIDTH, BUTTON_HEIGHT),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.autoScale(holder)
	local button = Glass.button(holder, "", UDim2.fromScale(1, 1), fire)
	face = button.Face
	face.Visible = false
	face.ClipsDescendants = true
	cover = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 3,
		Visible = false,
		Parent = face,
	})
	nameLabel = Glass.text(face, "", 18, Glass.Font.Bold)
	nameLabel.Position = UDim2.fromOffset(12, 7)
	nameLabel.Size = UDim2.new(1, -24, 0, 22)
	nameLabel.ZIndex = 4
	local hint = if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then "Tap" else "Right-click"
	hintLabel = Glass.text(face, hint, 14, Glass.Font.Body, C.InkMuted)
	hintLabel.Position = UDim2.fromOffset(12, 30)
	hintLabel.Size = UDim2.new(1, -24, 0, 18)
	hintLabel.ZIndex = 4
	timeLabel = Glass.text(face, "", 16, Glass.Font.Bold, C.Ink)
	timeLabel.Position = UDim2.fromOffset(12, 29)
	timeLabel.Size = UDim2.new(1, -24, 0, 18)
	timeLabel.ZIndex = 4
	timeLabel.Visible = false
	buffBar = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 4),
		BorderSizePixel = 0,
		ZIndex = 5,
		Visible = false,
		Parent = face,
	})
end

-- The effects ------------------------------------------------------------------------

local rng = Random.new()

-- A jagged bolt from one point to another
local function bolt(from: Vector3, to: Vector3, color: Color3, width: number)
	local steps = math.clamp(math.floor((to - from).Magnitude / 5), 3, 14)
	local attachments = {}
	for index = 0, steps do
		local point = from:Lerp(to, index / steps)
		if index > 0 and index < steps then
			point += Vector3.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(-1.6, 1.6), rng:NextNumber(-1.6, 1.6))
		end
		local at = Instance.new("Attachment")
		at.WorldPosition = point
		at.Parent = Workspace.Terrain
		table.insert(attachments, at)
		Debris:AddItem(at, 0.3)
	end
	for index = 1, steps do
		local beam = Instance.new("Beam")
		beam.Attachment0 = attachments[index]
		beam.Attachment1 = attachments[index + 1]
		beam.Width0, beam.Width1 = width, width
		beam.Color = ColorSequence.new(color:Lerp(WHITE, 0.55))
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.FaceCamera = true
		beam.Parent = attachments[index]
	end
end

local function flash(at: Vector3, color: Color3, range: number)
	local holder = Instance.new("Attachment")
	holder.WorldPosition = at
	holder.Parent = Workspace.Terrain
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 6
	light.Parent = holder
	TweenService:Create(light, TweenInfo.new(0.35), { Brightness = 0 }):Play()
	Debris:AddItem(holder, 0.4)
end

local function sparks(at: Vector3, color: Color3, amount: number, speed: number)
	local holder = Instance.new("Attachment")
	holder.WorldPosition = at
	holder.Parent = Workspace.Terrain
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color:Lerp(WHITE, 0.4), color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.4, 0.9)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = holder
	emitter:Emit(amount)
	Debris:AddItem(holder, 1.2)
end

-- A ball of light swelling out to the special's range and fading
local function swell(at: Vector3, color: Color3, range: number)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CastShadow = false
	ball.Transparency = 0.45
	ball.Size = Vector3.one * 3
	ball.CFrame = CFrame.new(at)
	ball.Parent = Workspace
	TweenService:Create(ball, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * range * 2,
		Transparency = 1,
	}):Play()
	Debris:AddItem(ball, 0.45)
end

local function onFx(kind: string, at: Vector3, extra: any)
	if kind == "Lightning" then
		local color = KitPowers.Swords.StormcallerSword.Color
		local from = at
		for _, point in extra :: { Vector3 } do
			-- It comes down from the sky, then arcs on from each one to the next
			bolt(point + Vector3.new(rng:NextNumber(-8, 8), 70, rng:NextNumber(-8, 8)), point, color, 0.9)
			bolt(from, point, color, 0.5)
			sparks(point, color, 24, 22)
			flash(point, color, 26)
			Sfx.play("Crit", point)
			from = point
		end
		Sfx.play("Stinger", at)
	elseif kind == "Flare" then
		local color = KitPowers.Swords.SunforgedSword.Color
		swell(at, color, extra :: number)
		sparks(at, color, 60, 40)
		flash(at, color, 40)
		Sfx.play("Sparkle", at)
		Sfx.play("Stinger", at)
	elseif kind == "Nova" then
		local color = KitPowers.Swords.FrostwardenSword.Color
		swell(at, color, extra :: number)
		sparks(at, color, 70, 34)
		flash(at, color, 34)
		Sfx.play("Sparkle", at)
		Sfx.play("StoneBreak", at)
	elseif kind == "Rage" then
		local color = KitPowers.Swords.EmberguardSword.Color
		sparks(at, color, 50, 26)
		flash(at, color, 24)
		Sfx.play("Smelt", at)
		Sfx.play("Stinger", at)
	elseif kind == "Venom" then
		local color = KitPowers.Swords.VenomfangSword.Color
		sparks(at, color, 40, 16)
		flash(at, color, 20)
		Sfx.play("Sizzle", at)
	end
end

function KitPowerController.Start()
	build()
	RunService.Heartbeat:Connect(refresh)
	Remotes.KitFx.OnClientEvent:Connect(onFx)
end

return KitPowerController
