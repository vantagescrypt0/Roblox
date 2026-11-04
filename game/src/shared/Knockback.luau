--!strict
-- Throws a character the way Minecraft does: up once, and away at a speed that fades over half a
-- second. Roblox's Humanoid cancels sideways speed at once, even in the air, so a single push
-- wouldn't carry; a constraint holds the fading speed on it instead. Whoever simulates the character
-- runs this: the player's own client, or the server for a character with no player.

local RunService = game:GetService("RunService")

local TIME = 0.5
local FADE = 1.886 -- Minecraft keeps 91% of your speed each tick in the air
local FORCE = 60000

local Knockback = {}

function Knockback.Apply(root: BasePart, velocity: Vector3)
	local attachment = root:FindFirstChild("RootAttachment") or root:FindFirstChild("RootRigAttachment")
	if not attachment or not attachment:IsA("Attachment") then
		root.AssemblyLinearVelocity = velocity
		return
	end
	local old = root:FindFirstChild("Knockback")
	if old then
		old:Destroy()
	end
	local current = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(current.X, velocity.Y, current.Z)

	local away = velocity * Vector3.new(1, 0, 1)
	local push = Instance.new("LinearVelocity")
	push.Name = "Knockback"
	push.Attachment0 = attachment
	push.RelativeTo = Enum.ActuatorRelativeTo.World
	push.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	push.MaxAxesForce = Vector3.new(FORCE, 0, FORCE)
	push.VectorVelocity = away
	push.Parent = root

	local elapsed = 0
	local stepping: RBXScriptConnection
	stepping = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= TIME or not push.Parent then
			stepping:Disconnect()
			push:Destroy()
			return
		end
		push.VectorVelocity = away * math.exp(-FADE * elapsed)
	end)
end

return Knockback
