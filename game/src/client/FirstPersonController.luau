--!strict
-- First person, for anyone who wants it to feel like Minecraft: V switches (or scroll all the way in).
-- It copies Minecraft's own numbers, which is why they're measured in blocks from the camera: what you
-- hold sits low on the right with its tip leaning toward you, your shield sits low on the left with its
-- back to you, both mostly off screen, and no arm shows unless your hand is empty
-- (02 Research/References/Gear/yours_minecraft_first_person.png). After a swing the item dips and comes
-- back up as it charges. These are copies held in front of the camera, only on your screen; your real
-- character is hidden, as Roblox does in first person.
-- With V, the scroll wheel picks hotbar slots, as it does there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Inventory = require(ReplicatedStorage.Shared.Inventory)
local SwordArt = require(ReplicatedStorage.Shared.SwordArt)
local HeldController = require(script.Parent.HeldController)
local Hotbar = require(script.Parent.Hotbar)

local NEAR_HEAD = 1.5 -- studs: the camera's this close when you're in first person

-- All from the camera: X right, Y up, -Z ahead
local HAND = Vector3.new(0.56, -0.52, -0.72)
local DIP = 0.6 -- how far an uncharged item sinks
local RISE_SPEED = 8 -- how fast it moves toward where the charge says, per second
-- An item's place relative to the hand, turned so its tip leans up and toward you
local ITEM_FRAME = CFrame.new(1.13 / 16, 3.2 / 16, 1.13 / 16)
	* CFrame.Angles(0, math.rad(-90), 0)
	* CFrame.Angles(0, 0, math.rad(25))
-- Minecraft's item picture runs corner to corner: these are its handle-to-tip line and the line across
local ALONG_ITEM = Vector3.new(1, 1, 0).Unit
local ACROSS_ITEM = Vector3.new(1, -1, 0).Unit
local ITEM_AXES = CFrame.fromMatrix(Vector3.zero, ACROSS_ITEM, ALONG_ITEM, ACROSS_ITEM:Cross(ALONG_ITEM))
local ITEM_LENGTH = 0.95 -- how long what you hold looks, in blocks
-- A crescent is nearly as wide as it's long: smaller, with its bulk turned away from the camera
local WIDE = 0.6 -- wider than this share of its length
local WIDE_SCALE = 0.72
local WIDE_TURN = CFrame.Angles(0, math.pi, 0)
local GRIP_ON_ITEM = -0.25 -- where the hand is along it, from its middle, in blocks
local BLOCK_SIZE = 0.4
local BLOCK_TURN = CFrame.Angles(0, math.rad(45), 0)

local ARM_SCALE = 0.42
local ARM_BACK = Vector3.new(0.22, -0.6, 0.77).Unit -- from the hand toward the elbow

local SHIELD_WIDTH = 1 -- blocks across
local SHIELD_REST = CFrame.new(-0.72, -0.76, -1) * CFrame.Angles(0, 0, math.rad(-3))
local SHIELD_UP = CFrame.new(-0.3, -0.38, -0.95) * CFrame.Angles(0, math.rad(-4), 0)

local localPlayer = Players.LocalPlayer

local FirstPersonController = {}

type Held = { Part: BasePart, Offset: CFrame }

local rig: Model? = nil
local builtFor = ""
local heldParts: { Held } = {}
local shieldPart: BasePart? = nil
local forced = false
local active = false
local swingStart = 0
local bob = 0
local shieldBlend = 0
local charge = 1
local height = 0 -- 1 when the item is fully up

function FirstPersonController.IsActive(): boolean
	return active
end

-- How charged your swing is, 0 to 1 (CombatController)
function FirstPersonController.SetCharge(value: number)
	charge = value
end

-- A copy that only shows, with what made it work on the character stripped off
local function copyOf(part: BasePart, scale: number): BasePart
	local copy = part:Clone()
	for _, child in copy:GetChildren() do
		if not child:IsA("SurfaceAppearance") and not child:IsA("SpecialMesh") then
			child:Destroy()
		end
	end
	-- Armour hides the body part it covers, but this copy isn't wearing any
	local before = part:GetAttribute("BeforeArmor")
	if type(before) == "number" then
		copy.Transparency = before
	end
	for name in copy:GetAttributes() do
		copy:SetAttribute(name, nil)
	end
	copy.Anchored = true
	copy.CanCollide = false
	copy.CanQuery = false
	copy.CanTouch = false
	copy.CastShadow = false
	copy.Massless = true
	copy.LocalTransparencyModifier = 0
	copy.Size = part.Size * scale
	return copy
end

local function clearRig()
	if rig then
		rig:Destroy()
	end
	rig = nil
	builtFor = ""
	heldParts = {}
	shieldPart = nil
end

local function add(model: Model, part: BasePart, offset: CFrame)
	part.Parent = model
	table.insert(heldParts, { Part = part, Offset = offset })
end

-- What's in your hand, in view, with its glow if it has one
local function addHeld(model: Model, held: BasePart)
	local grip = held:GetAttribute("Grip")
	if typeof(grip) ~= "CFrame" then
		return
	end
	local longest = math.max(held.Size.X, held.Size.Y, held.Size.Z)
	local scale = ITEM_LENGTH / longest
	local offset: CFrame
	if held:GetAttribute("IsBlock") == true then
		scale = BLOCK_SIZE / longest
		offset = BLOCK_TURN
	else
		local wide = held.Size.X / held.Size.Y > WIDE
		scale *= if wide then WIDE_SCALE else 1
		local gripAt = ALONG_ITEM * GRIP_ON_ITEM
		offset = ITEM_FRAME
			* CFrame.new(gripAt)
			* ITEM_AXES
			* (if wide then WIDE_TURN else CFrame.identity)
			* (CFrame.new(grip.Position * scale) * grip.Rotation):Inverse()
	end
	add(model, copyOf(held, scale), offset)
	local shell = held:FindFirstChild("Glow")
	if shell and shell:IsA("BasePart") then
		add(model, copyOf(shell, scale), offset)
	end
end

-- An empty hand: your arm shows, as it does there
local function addArm(model: Model, character: Model)
	local right = ARM_BACK:Cross(Vector3.new(0, 0, 1)).Unit
	local rotation = CFrame.fromMatrix(Vector3.zero, right, ARM_BACK, right:Cross(ARM_BACK))
	local hand = character:FindFirstChild("RightHand")
	local lower = character:FindFirstChild("RightLowerArm")
	if hand and hand:IsA("BasePart") and lower and lower:IsA("BasePart") then
		local handCopy = copyOf(hand, ARM_SCALE)
		local lowerCopy = copyOf(lower, ARM_SCALE)
		add(model, handCopy, rotation)
		add(model, lowerCopy, CFrame.new(ARM_BACK * (handCopy.Size.Y + lowerCopy.Size.Y) / 2) * rotation)
	end
end

local function build(character: Model, key: string)
	clearRig()
	builtFor = key
	local model = Instance.new("Model")
	model.Name = "FirstPerson"
	rig = model

	local held = character:FindFirstChild("Held")
	if held and held:IsA("BasePart") then
		addHeld(model, held)
	else
		addArm(model, character)
	end

	local shield = character:FindFirstChild("Shield")
	if shield and shield:IsA("BasePart") then
		local copy = copyOf(shield, SHIELD_WIDTH / math.max(shield.Size.X, shield.Size.Y))
		copy.Parent = model
		shieldPart = copy
	end
	model.Parent = Workspace.CurrentCamera
	height = 0
end

-- What's on you decides what's shown: rebuilt when it changes
local function keyFor(character: Model): string
	local held = character:FindFirstChild("Held")
	local shield = character:FindFirstChild("Shield")
	return `{held and held:GetAttribute("Item") or ""}|{shield and "b" or ""}`
end

-- Your real item's embers would float in the view
local function hideReal(character: Model, hidden: boolean)
	local held = character:FindFirstChild("Held")
	if held then
		for _, descendant in held:GetDescendants() do
			if descendant:IsA("ParticleEmitter") then
				descendant.Enabled = not hidden
			elseif descendant:IsA("Trail") then
				descendant.Enabled = false
			end
		end
	end
end

-- Minecraft's swing: the hand moves over and the item turns round a point in the hand
local function swingMove(p: number): CFrame
	return CFrame.new(
		-0.4 * math.sin(math.sqrt(p) * math.pi),
		0.2 * math.sin(math.sqrt(p) * 2 * math.pi),
		-0.2 * math.sin(p * math.pi)
	)
end

local function swingTurn(p: number): CFrame
	local slow = math.sin(p * p * math.pi)
	local quick = math.sin(math.sqrt(p) * math.pi)
	return CFrame.Angles(0, math.rad(45 - 20 * slow), 0)
		* CFrame.Angles(0, 0, math.rad(-20 * quick))
		* CFrame.Angles(math.rad(-80 * quick), 0, 0)
		* CFrame.Angles(0, math.rad(-45), 0)
end

local function place(camera: Camera, dt: number)
	local p = math.clamp((os.clock() - swingStart) / SwordArt.SwingTime, 0, 1)
	if p >= 1 then
		p = 0
	end
	-- It sinks after a swing and rises as the charge comes back
	local wanted = charge * charge * charge
	height += math.clamp(wanted - height, -RISE_SPEED * dt, RISE_SPEED * dt)

	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local speed = if humanoid then humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed else 0
	bob += dt * speed * 0.55
	local amount = math.min(speed / 16, 1.3)
	local bobbing = CFrame.new(math.cos(bob) * 0.012 * amount, math.abs(math.sin(bob)) * 0.016 * amount, 0)
	local base = camera.CFrame * bobbing

	local hand = base * swingMove(p) * CFrame.new(HAND + Vector3.new(0, -DIP * (1 - height), 0)) * swingTurn(p)
	for _, held in heldParts do
		held.Part.CFrame = hand * held.Offset
	end
	local shield = shieldPart
	if shield then
		local blocking = localPlayer:GetAttribute("Blocking") == true
		shieldBlend += ((if blocking then 1 else 0) - shieldBlend) * math.min(1, dt * 14)
		shield.CFrame = base * SHIELD_REST:Lerp(SHIELD_UP, shieldBlend)
	end
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	local character = localPlayer.Character
	local head = character and character:FindFirstChild("Head")
	local inFirst = camera ~= nil
		and head ~= nil
		and head:IsA("BasePart")
		and camera.CameraType == Enum.CameraType.Custom
		and (camera.CFrame.Position - head.Position).Magnitude < NEAR_HEAD
	if character and inFirst ~= active then
		hideReal(character, inFirst)
	end
	active = inFirst
	if not active or not character or not camera then
		if rig then
			clearRig()
		end
		return
	end
	local key = keyFor(character)
	if key ~= builtFor then
		build(character, key)
		hideReal(character, true)
	end
	place(camera, dt)
end

local function setForced(on: boolean)
	forced = on
	if on then
		localPlayer.CameraMaxZoomDistance = StarterPlayer.CameraMinZoomDistance
		return
	end
	-- Pull the camera back out, then let the scroll wheel go in again
	localPlayer.CameraMaxZoomDistance = StarterPlayer.CameraMaxZoomDistance
	localPlayer.CameraMinZoomDistance = 12
	task.delay(0.1, function()
		localPlayer.CameraMinZoomDistance = StarterPlayer.CameraMinZoomDistance
	end)
end

function FirstPersonController.Start()
	HeldController.OnSwing(function()
		swingStart = os.clock()
	end)
	RunService.RenderStepped:Connect(update)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.V then
			setForced(not forced)
		end
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		if forced and not processed and input.UserInputType == Enum.UserInputType.MouseWheel then
			local step = if input.Position.Z > 0 then -1 else 1
			Hotbar.Select((Hotbar.Selected() - 1 + step) % Inventory.Hotbar + 1)
		end
	end)
end

return FirstPersonController
