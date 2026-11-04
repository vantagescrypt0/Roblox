--!strict
-- The fighting side of your screen. Left click swings, at whoever's under your mouse or crosshair
-- within reach; the server checks it and works out the hit (Combat.luau). A bar shows your swing
-- charging, under the crosshair in first person and under the mouse otherwise. Hits flash red, and
-- a hit on you knocks you back.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Foods = require(ReplicatedStorage.Shared.Foods)
local Knockback = require(ReplicatedStorage.Shared.Knockback)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tools = require(ReplicatedStorage.Shared.Tools)
local BlockController = require(script.Parent.BlockController)
local FirstPersonController = require(script.Parent.FirstPersonController)
local Hotbar = require(script.Parent.Hotbar)
local Glass = require(script.Parent.UI.Glass)
local Sfx = require(script.Parent.UI.Sfx)
local Theme = require(script.Parent.UI.Theme)

local C = Glass.Color
local player = Players.LocalPlayer

local BAR_WIDTH = 44
local BAR_HEIGHT = 5
local BAR_BELOW = 18 -- pixels below the mouse or crosshair
local HIT_FLASH = 0.18
local CRIT_SPARKS = 16

local CombatController = {}

local lastSwing = 0
local crosshair: Frame
local barTrack: Frame
local barFill: Frame

local function cooldownOf(itemId: string?): (number, boolean)
	local tool = itemId and Tools.ByItem[itemId]
	if tool then
		return tool.Cooldown, tool.Kind == "Sword" or tool.Kind == "Axe"
	end
	return Combat.FistCooldown, itemId == nil
end

-- The character under the aim, if one's in reach and nothing's in the way
local function aimedCharacter(screen: Vector2): Model?
	local camera = Workspace.CurrentCamera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not camera or not character or not root or not root:IsA("BasePart") then
		return nil
	end
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, camera }
	local far = (camera.CFrame.Position - root.Position).Magnitude + Combat.Reach
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * far, params)
	local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	if not model or not model:FindFirstChildOfClass("Humanoid") then
		return nil
	end
	local targetRoot = model:FindFirstChild("HumanoidRootPart")
	if not targetRoot or not targetRoot:IsA("BasePart") then
		return nil
	end
	return if (targetRoot.Position - root.Position).Magnitude <= Combat.Reach + 1.5 then model else nil
end

-- You turn to face who you swing at; in first person you already are
local function faceTarget(target: Model)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and targetRoot and targetRoot:IsA("BasePart") then
		local flat = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)
		if flat.Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
		end
	end
end

-- Your screen knows first; the server only sees your jump a moment later (it checks you're in the air)
local function isFalling(): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root ~= nil
		and root:IsA("BasePart")
		and humanoid ~= nil
		and humanoid.FloorMaterial == Enum.Material.Air
		and root.AssemblyLinearVelocity.Y < -1
end

local function attack(screen: Vector2)
	local held = Hotbar.SelectedItem()
	if player:GetAttribute("Blocking") or (held and Foods[held]) then
		return
	end
	local target = aimedCharacter(screen)
	local _, weapon = cooldownOf(held)
	if not target and not weapon then
		return
	end
	if target and not FirstPersonController.IsActive() then
		faceTarget(target)
	end
	lastSwing = os.clock()
	BlockController.Swing()
	Sfx.play("Swing")
	Remotes.Attack:FireServer(target, isFalling())
end

local function showCharge()
	local held = Hotbar.SelectedItem()
	local cooldown, weapon = cooldownOf(held)
	local charge = Combat.Charge(os.clock() - lastSwing, cooldown)
	FirstPersonController.SetCharge(charge)
	local first = FirstPersonController.IsActive()
	crosshair.Visible = first
	barTrack.Visible = weapon and charge < 1
	if barTrack.Visible then
		barFill.Size = UDim2.fromScale(charge, 1)
		local camera = Workspace.CurrentCamera
		local at = if first and camera then camera.ViewportSize / 2 else UserInputService:GetMouseLocation()
		barTrack.Position = UDim2.fromOffset(at.X - BAR_WIDTH / 2, at.Y + BAR_BELOW)
	end
end

local function buildGui()
	local gui = Theme.screen("Crosshair", 3)
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	crosshair = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	for _, size in { UDim2.fromOffset(16, 2), UDim2.fromOffset(2, 16) } do
		local line = Theme.make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = size,
			BackgroundColor3 = C.Ink,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Parent = crosshair,
		})
		Theme.stroke(line, C.Black, 1, 0.55)
	end
	barTrack = Theme.make("Frame", {
		Size = UDim2.fromOffset(BAR_WIDTH, BAR_HEIGHT),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.15,
		Visible = false,
		Parent = gui,
	})
	Theme.corner(barTrack, 3)
	barFill = Theme.make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.Accent,
		Parent = barTrack,
	})
	Theme.corner(barFill, 3)
end

local function flash(model: Model)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = C.Red
	highlight.FillTransparency = 0.45
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
	Debris:AddItem(highlight, HIT_FLASH)
end

local function sparks(root: BasePart)
	local at = Instance.new("Attachment")
	at.Parent = root
	local burst = Instance.new("ParticleEmitter")
	burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	burst.Color = ColorSequence.new(C.Gold)
	burst.LightEmission = 1
	burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	burst.Lifetime = NumberRange.new(0.25, 0.5)
	burst.Speed = NumberRange.new(10, 18)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Rate = 0
	burst.Parent = at
	burst:Emit(CRIT_SPARKS)
	Debris:AddItem(at, 0.6)
end

local function onHitEffect(model: Model?, kind: string)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not model or not root or not root:IsA("BasePart") then
		return
	end
	if kind == "block" then
		return -- the server plays the shield's clang
	end
	flash(model)
	if kind == "crit" then
		sparks(root)
		Sfx.play("Crit", root.Position)
	else
		Sfx.play("Hit", root.Position)
	end
end

local function onKnockback(velocity: Vector3)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		Knockback.Apply(root, velocity)
	end
end

function CombatController.Start()
	buildGui()
	Hotbar.OnChanged(function()
		-- Switching items starts the charge over
		lastSwing = os.clock()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			attack(UserInputService:GetMouseLocation())
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local screen = Vector2.new(input.Position.X, input.Position.Y)
			if aimedCharacter(screen) then
				attack(screen)
			end
		end
	end)
	RunService.RenderStepped:Connect(showCharge)
	Remotes.HitEffect.OnClientEvent:Connect(onHitEffect)
	Remotes.Knockback.OnClientEvent:Connect(onKnockback)
end

return CombatController
