--!strict
-- Swimming in our own water: island water blocks (LiquidModels) and the worlds' water sheets
-- (Decor.Water), which the server tags "Water". Roblox only swims in terrain water, so this
-- does it by hand.
--   Deeper than your chest: you swim. You float up to the surface and bob there, head out.
--   Move as usual; Space (or the jump button) swims up, Ctrl or Q dives.
--   Space at the surface jumps you out, so you can climb onto the bank.
--   Shallow water (one block deep, like the worlds' ponds) is only waded through.
-- A pool's inner blocks have no part (BlockWorld draws only its outside), so being under a
-- water part with nothing solid in between counts as in the water too.
-- Like flying, the character's own physics carry it: a LinearVelocity on the root part, with
-- the humanoid held in its Swimming state so the swim animation plays.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Blocks = require(ReplicatedStorage.Shared.Blocks)

local TAG = "Water"
local SPEED = 12 -- studs per second, across
local RISE = 9 -- up, holding Space
local DIVE = 9 -- down, holding Ctrl or Q
local FLOAT = 1.6 -- how far the root part floats below the surface (head out)
local ENTER = 2.2 -- start swimming once the root part is this deep
local LEAVE = 0.4 -- stop once it's above this depth (climbed out)
local JUMP_OUT = 0.45 -- seconds after jumping out before the water can catch you again
local FLOOR_BELOW = 40 -- a pool's floor must be this close below you (studs)
local DOWN_KEYS = { Enum.KeyCode.LeftControl, Enum.KeyCode.Q, Enum.KeyCode.ButtonL2 }
-- States that would pull the humanoid out of Swimming
local BLOCKED = {
	Enum.HumanoidStateType.Running,
	Enum.HumanoidStateType.Freefall,
	Enum.HumanoidStateType.Landed,
	Enum.HumanoidStateType.Jumping,
	Enum.HumanoidStateType.GettingUp,
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.Climbing,
}

local SwimController = {}

local player = Players.LocalPlayer
local waters: { [BasePart]: true } = {}
local swimming = false
local jumpedAt = -math.huge
-- Phones: the jump button's JumpRequest repeats while it's held
local jumpRequestAt = -math.huge
local velocity: LinearVelocity? = nil
local attachment: Attachment? = nil

local function anyDown(keys: { Enum.KeyCode }): boolean
	for _, key in keys do
		if UserInputService:IsKeyDown(key) then
			return true
		end
	end
	return false
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

-- Is `point` inside the water part's footprint (its box seen from above), or within
-- `margin` studs of it?
local function over(part: BasePart, point: Vector3, margin: number): boolean
	local here = part.CFrame:PointToObjectSpace(point)
	local half = part.Size / 2
	return math.abs(here.X) <= half.X + margin and math.abs(here.Z) <= half.Z + margin
end

-- The surface of the water in the column of parts over `point` (or near it, `margin`), or
-- nil if `point` isn't in that water. Parts stacked on each other (a waterfall) count as one.
local function columnSurface(point: Vector3, margin: number, params: RaycastParams): number?
	local column: { { Low: number, High: number, Part: BasePart } } = {}
	for part in waters do
		if
			part.Parent
			and (part.Position - point).Magnitude < part.Size.Magnitude / 2 + 64
			and over(part, point, margin)
		then
			local halfY = part.Size.Y / 2
			table.insert(column, { Low = part.Position.Y - halfY, High = part.Position.Y + halfY, Part = part })
		end
	end
	if #column == 0 then
		return nil
	end
	table.sort(column, function(a, b)
		return a.Low < b.Low
	end)
	-- The first body that reaches above `point`
	local i = 1
	while i <= #column do
		local low, high, part = column[i].Low, column[i].High, column[i].Part
		-- Join the parts that stack on top of this one
		while column[i + 1] and column[i + 1].Low <= high + 0.05 do
			i += 1
			high = math.max(high, column[i].High)
		end
		if high > point.Y then
			if low <= point.Y then
				return high
			end
			-- Below the water's lowest part: still in it (a pool's inside) if nothing solid is
			-- in between and the pool has a floor below (not open air under a falling stream)
			local hit = Workspace:Raycast(point, Vector3.new(0, low - point.Y + 0.05, 0), params)
			if hit and hit.Instance ~= part and not CollectionService:HasTag(hit.Instance, TAG) then
				return nil
			end
			if not Workspace:Raycast(point, Vector3.new(0, -FLOOR_BELOW, 0), params) then
				return nil
			end
			return high
		end
		i += 1
	end
	return nil
end

-- The water's surface above (or around) `point`, or nil if `point` isn't in water
local function surfaceAt(point: Vector3, character: Model): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local own = columnSurface(point, 0, params)
	if own then
		return own
	end
	-- A water block with a block right on top (a dock, a tree) has no part at all, so look at
	-- the water next to it: it counts if a roof sits on the water's surface right above you
	-- (and not, say, beside a waterfall in the open)
	local beside = columnSurface(point, Blocks.Size / 2 + 0.1, params)
	if beside then
		local hit = Workspace:Raycast(point, Vector3.new(0, beside - point.Y + 1, 0), params)
		if hit and not CollectionService:HasTag(hit.Instance, TAG) and hit.Position.Y >= beside - 0.1 then
			return beside
		end
	end
	return nil
end

local function stopSwimming(humanoid: Humanoid?, jump: boolean?)
	swimming = false
	if velocity then
		velocity:Destroy()
		velocity = nil
	end
	if attachment then
		attachment:Destroy()
		attachment = nil
	end
	if humanoid then
		for _, state in BLOCKED do
			humanoid:SetStateEnabled(state, true)
		end
		humanoid:ChangeState(if jump then Enum.HumanoidStateType.Jumping else Enum.HumanoidStateType.Freefall)
	end
end

local function startSwimming(humanoid: Humanoid, root: BasePart)
	swimming = true
	local a = Instance.new("Attachment")
	a.Name = "SwimAttachment"
	a.Parent = root
	local v = Instance.new("LinearVelocity")
	v.Name = "SwimVelocity"
	v.Attachment0 = a
	v.RelativeTo = Enum.ActuatorRelativeTo.World
	v.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	v.MaxForce = 1e6
	v.VectorVelocity = Vector3.zero
	v.Parent = root
	attachment, velocity = a, v
	for _, state in BLOCKED do
		humanoid:SetStateEnabled(state, false)
	end
	humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
end

local function step()
	local humanoid, root = characterParts()
	if not humanoid or not root then
		if swimming then
			stopSwimming(nil)
		end
		return
	end
	-- Flying (FlightController) takes over the character
	if humanoid.PlatformStand then
		if swimming then
			stopSwimming(humanoid)
		end
		return
	end
	local character = root.Parent :: Model
	local surface = surfaceAt(root.Position, character)
	local depth = if surface then surface - root.Position.Y else nil

	if not swimming then
		if depth and depth > ENTER and os.clock() - jumpedAt > JUMP_OUT then
			startSwimming(humanoid, root)
		else
			return
		end
	end
	if not depth or depth < LEAVE or not velocity or not velocity.Parent then
		stopSwimming(humanoid)
		return
	end

	-- (humanoid.Jump is cleared while jumping is switched off, so read the input itself)
	local typing = UserInputService:GetFocusedTextBox() ~= nil
	local up = not typing
		and (
			UserInputService:IsKeyDown(Enum.KeyCode.Space)
			or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
			or os.clock() - jumpRequestAt < 0.2
		)
	local down = not typing and anyDown(DOWN_KEYS)
	-- At the surface, Space jumps out (onto the bank, or just a hop)
	if up and depth <= FLOAT + 0.35 then
		jumpedAt = os.clock()
		stopSwimming(humanoid, true)
		return
	end
	local climb
	if up then
		climb = RISE
	elseif down then
		climb = -DIVE
	else
		-- Float gently up to the surface and settle there
		climb = math.clamp((depth - FLOAT) * 3, -RISE, 4)
	end
	local across = humanoid.MoveDirection * SPEED
	if velocity then
		velocity.VectorVelocity = Vector3.new(across.X, climb, across.Z)
	end
	if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
		humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
	end
end

-- Only water out in the world (not the block templates in ReplicatedStorage, or icons)
local function add(part: Instance)
	if part:IsA("BasePart") and part:IsDescendantOf(Workspace) then
		waters[part] = true
	end
end

function SwimController.Start()
	for _, part in CollectionService:GetTagged(TAG) do
		add(part)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(part)
		waters[part :: BasePart] = nil
	end)
	UserInputService.JumpRequest:Connect(function()
		jumpRequestAt = os.clock()
	end)
	player.CharacterAdded:Connect(function()
		swimming = false
		velocity, attachment = nil, nil
	end)
	RunService.Heartbeat:Connect(step)
end

return SwimController
