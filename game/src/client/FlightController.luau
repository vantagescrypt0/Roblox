--!strict
-- Flying, for the players in Config.Flyers only (the game's owner), in every place.
--   Double-tap Space (or the jump button) to take off; double-tap again to land.
--   While flying: move as usual (WASD / thumbstick, toward where the camera looks),
--   Space or E to go up, Ctrl or Q to go down. The character stays upright and turns to
--   face the way the camera points.
-- The character's own physics carry it (its client owns it), held by a LinearVelocity and
-- an AlignOrientation on the root part; the humanoid is set to PlatformStand meanwhile so
-- it doesn't fight them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local DOUBLE_TAP = 0.3 -- seconds between the two taps
local UP_KEYS = { Enum.KeyCode.Space, Enum.KeyCode.E, Enum.KeyCode.ButtonA }
local DOWN_KEYS = { Enum.KeyCode.LeftControl, Enum.KeyCode.Q, Enum.KeyCode.ButtonL2 }

local FlightController = {}

local player = Players.LocalPlayer
local flying = false
local lastTap = 0
local touchJumpHeld = false
local parts: { Instance } = {}
local stepConnection: RBXScriptConnection? = nil

local function anyDown(keys: { Enum.KeyCode }): boolean
	for _, key in keys do
		if UserInputService:IsKeyDown(key) then
			return true
		end
	end
	return false
end

-- Upright, facing along `look` flattened onto the ground (or `fallback` if that's straight up)
local function facing(look: Vector3, fallback: CFrame): CFrame
	local flat = look * Vector3.new(1, 0, 1)
	if flat.Magnitude < 1e-3 then
		return fallback
	end
	return CFrame.lookAlong(Vector3.zero, flat.Unit)
end

local function characterParts(): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and root:IsA("BasePart") and humanoid.Health > 0 then
		return humanoid, root
	end
	return nil, nil
end

local function land()
	flying = false
	if stepConnection then
		stepConnection:Disconnect()
		stepConnection = nil
	end
	for _, part in parts do
		part:Destroy()
	end
	table.clear(parts)
	local humanoid = characterParts()
	if humanoid then
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

local function takeOff()
	local humanoid, root = characterParts()
	if not humanoid or not root then
		return
	end
	flying = true
	local attachment = Instance.new("Attachment")
	attachment.Name = "FlightAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "FlightVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = root
	local align = Instance.new("AlignOrientation")
	align.Name = "FlightAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.MaxTorque = math.huge
	align.Responsiveness = 25
	align.CFrame = facing(root.CFrame.LookVector, CFrame.identity)
	align.Parent = root
	parts = { attachment, velocity, align }
	humanoid.PlatformStand = true

	stepConnection = RunService.RenderStepped:Connect(function()
		local h, r = characterParts()
		if not h or not r or not velocity.Parent then
			land()
			return
		end
		local across = h.MoveDirection * Config.FlySpeed
		local climb = 0
		if anyDown(UP_KEYS) or touchJumpHeld then
			climb += Config.FlyClimb
		end
		if anyDown(DOWN_KEYS) then
			climb -= Config.FlyClimb
		end
		velocity.VectorVelocity = Vector3.new(across.X, climb, across.Z)
		local camera = Workspace.CurrentCamera
		align.CFrame = facing(if camera then camera.CFrame.LookVector else r.CFrame.LookVector, align.CFrame)
	end)
end

-- One press of jump: a second one soon after toggles flying
local function jumpPressed()
	local now = os.clock()
	if now - lastTap <= DOUBLE_TAP then
		lastTap = 0
		if flying then
			land()
		else
			takeOff()
		end
	else
		lastTap = now
	end
end

function FlightController.Start()
	if not Config.Flyers[player.UserId] then
		return
	end
	UserInputService.InputBegan:Connect(function(input)
		-- (Space counts as "processed" by Roblox's own jump controls, so only skip typing)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
			jumpPressed()
		end
	end)
	-- Phones: the jump button (JumpRequest repeats while it's held, so count new presses)
	UserInputService.JumpRequest:Connect(function()
		if not UserInputService.TouchEnabled or UserInputService.KeyboardEnabled then
			return
		end
		if not touchJumpHeld then
			jumpPressed()
		end
		touchJumpHeld = true
	end)
	UserInputService.TouchEnded:Connect(function()
		touchJumpHeld = false
	end)
	player.CharacterAdded:Connect(function()
		if flying then
			land()
		end
	end)
end

return FlightController
