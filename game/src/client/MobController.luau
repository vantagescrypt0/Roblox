--!strict
-- Monsters on your own screen: the meshes are one solid piece, so this gives them life, on the
-- client only so a world of them costs nothing. They bob and waddle as they walk, hop if they're
-- hoppers, drift if they float, lunge when they swing at you, and fade away when they're killed.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monsters = require(ReplicatedStorage.Shared.Monsters)

local player = Players.LocalPlayer

local ANIMATE_DISTANCE = 130
local WALK_SPEED_SEEN = 2 -- moving faster than this counts as walking
local LUNGE_TIME = 0.32

type Tracked = {
	Model: Model,
	Root: BasePart,
	Body: BasePart,
	Weld: Weld,
	Rest: CFrame,
	Monster: Monsters.Monster,
	Lunge: number,
	Phase: number,
}

local MobController = {}

local tracked: { [Model]: Tracked } = {}
local rng = Random.new()

local function forget(model: Model)
	tracked[model] = nil
end

local function fade(item: Tracked)
	local body = item.Body
	local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(body, info, { Transparency = 1 }):Play()
	item.Weld.C0 = item.Rest * CFrame.new(0, -body.Size.Y * 0.1, 0)
	local poof = Instance.new("ParticleEmitter")
	poof.Texture = "rbxasset://textures/particles/smoke_main.dds"
	poof.Color = ColorSequence.new(Color3.new(1, 1, 1))
	poof.Size = NumberSequence.new(body.Size.Y * 0.35, body.Size.Y * 0.6)
	poof.Transparency = NumberSequence.new(0.2, 1)
	poof.Lifetime = NumberRange.new(0.5, 0.8)
	poof.Speed = NumberRange.new(2, 5)
	poof.SpreadAngle = Vector2.new(180, 180)
	poof.Parent = body
	poof:Emit(16)
end

local function track(model: Instance)
	if not model:IsA("Model") or tracked[model] then
		return
	end
	local monster = Monsters.ById[model:GetAttribute("Monster") :: any]
	local root = model:FindFirstChild("HumanoidRootPart")
	local body = model:FindFirstChild("Body")
	local weld = body and body:FindFirstChild("BodyWeld")
	local rest = weld and weld:GetAttribute("Rest")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if
		not monster
		or not root
		or not root:IsA("BasePart")
		or not body
		or not body:IsA("BasePart")
		or not weld
		or not weld:IsA("Weld")
		or typeof(rest) ~= "CFrame"
		or not humanoid
	then
		return
	end
	local item: Tracked = {
		Model = model,
		Root = root,
		Body = body,
		Weld = weld,
		Rest = rest,
		Monster = monster,
		Lunge = -10,
		Phase = rng:NextNumber(0, 6),
	}
	tracked[model] = item
	model:GetAttributeChangedSignal("Swings"):Connect(function()
		item.Lunge = os.clock()
	end)
	humanoid.Died:Connect(function()
		forget(model)
		fade(item)
	end)
	model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			forget(model)
		end
	end)
end

local function animate(item: Tracked, now: number, camera: Vector3)
	if (item.Root.Position - camera).Magnitude > ANIMATE_DISTANCE then
		return
	end
	local velocity = item.Root.AssemblyLinearVelocity
	local moving = Vector2.new(velocity.X, velocity.Z).Magnitude > WALK_SPEED_SEEN
	local t = now + item.Phase
	local offset = CFrame.identity
	local height = item.Body.Size.Y
	if item.Monster.Hovers then
		offset = CFrame.new(0, math.sin(t * 2.2) * 0.5, 0) * CFrame.Angles(0, 0, math.sin(t * 1.3) * 0.06)
	elseif moving then
		local step = t * 9
		offset = CFrame.new(0, math.abs(math.sin(step)) * height * 0.05, 0) * CFrame.Angles(0, 0, math.sin(step) * 0.12)
	elseif item.Monster.Hops then
		offset = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.sin(t * 2) * 0.03)
	else
		offset = CFrame.Angles(math.sin(t * 1.6) * 0.03, 0, math.sin(t * 1.1) * 0.02)
	end
	-- Lunging at you: leans in, then back
	local since = now - item.Lunge
	if since < LUNGE_TIME then
		local swing = math.sin(math.clamp(since / LUNGE_TIME, 0, 1) * math.pi)
		offset = CFrame.new(0, 0, -swing * height * 0.15) * CFrame.Angles(-swing * 0.45, 0, 0) * offset
	end
	item.Weld.C0 = item.Rest * offset
end

function MobController.Start()
	task.spawn(function()
		local folder = Workspace:WaitForChild("Mobs", 60)
		if not folder then
			return
		end
		folder.ChildAdded:Connect(function(child)
			task.defer(track, child)
		end)
		for _, child in folder:GetChildren() do
			track(child)
		end
	end)
	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if not camera or not player.Character then
			return
		end
		local now = os.clock()
		for _, item in tracked do
			if item.Body.Parent then
				animate(item, now, camera.CFrame.Position)
			end
		end
	end)
end

return MobController
