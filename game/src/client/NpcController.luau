--!strict
-- Brings the Town's shopkeepers to life on your screen: each one's head turns to watch
-- you as you walk by (like a Minecraft villager), and they greet you with a chat bubble
-- (their own lines, from Shops.luau) when you come up to their stall.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

local Places = require(ReplicatedStorage.Shared.Places)
local Shops = require(ReplicatedStorage.Shared.Shops)

local player = Players.LocalPlayer :: Player

local WATCH_DISTANCE = 40
local GREET_DISTANCE = 18
local MAX_YAW = math.rad(70)
local MAX_PITCH = math.rad(35)
local TURN_SPEED = 8

local NpcController = {}

type Keeper = {
	Head: Model,
	Neck: CFrame, -- neck position and resting rotation
	Lift: CFrame, -- neck -> head center
	Yaw: number,
	Pitch: number,
	Greetings: { string },
	Greeted: boolean,
}

local keepers: { [Model]: Keeper } = {}

local function track(model: Instance)
	local head = model:FindFirstChild("Head")
	local shop = Shops.ById[model:GetAttribute("Shop") :: any]
	if not model:IsA("Model") or not head or not head:IsA("Model") or not head.PrimaryPart or not shop then
		return
	end
	local pivot = head:GetPivot()
	local lift = CFrame.new(0, head.PrimaryPart.Size.Y / 2, 0)
	keepers[model] = {
		Head = head,
		Neck = pivot * lift:Inverse(),
		Lift = lift,
		Yaw = 0,
		Pitch = 0,
		Greetings = shop.Greetings,
		Greeted = false,
	}
end

local function greet(keeper: Keeper)
	local message = keeper.Greetings[math.random(#keeper.Greetings)]
	local part = keeper.Head.PrimaryPart
	if part and message then
		pcall(function()
			TextChatService:DisplayBubble(part, message)
		end)
	end
end

local function update(dt: number)
	local character = player.Character
	local target = character and character:FindFirstChild("Head")
	local alpha = 1 - math.exp(-TURN_SPEED * dt)
	for model, keeper in keepers do
		if not model.Parent then
			keepers[model] = nil
			continue
		end
		local targetYaw, targetPitch = 0, 0
		local distance = math.huge
		if target and target:IsA("BasePart") then
			local offset = keeper.Neck:PointToObjectSpace(target.Position)
			distance = offset.Magnitude
			if distance < WATCH_DISTANCE then
				targetYaw = math.clamp(math.atan2(-offset.X, -offset.Z), -MAX_YAW, MAX_YAW)
				targetPitch =
					math.clamp(math.atan2(offset.Y, Vector2.new(offset.X, offset.Z).Magnitude), -MAX_PITCH, MAX_PITCH)
			end
		end
		keeper.Yaw += (targetYaw - keeper.Yaw) * alpha
		keeper.Pitch += (targetPitch - keeper.Pitch) * alpha
		keeper.Head:PivotTo(
			keeper.Neck * CFrame.Angles(0, keeper.Yaw, 0) * CFrame.Angles(keeper.Pitch, 0, 0) * keeper.Lift
		)

		if distance < GREET_DISTANCE and not keeper.Greeted then
			keeper.Greeted = true
			greet(keeper)
		elseif distance > GREET_DISTANCE + 8 then
			keeper.Greeted = false
		end
	end
end

function NpcController.Start()
	if Places.Current() ~= "Town" then
		return
	end
	task.spawn(function()
		local town = Workspace:WaitForChild("Town")
		local folder = town:WaitForChild("Npcs")
		-- Pick up shopkeepers as they arrive (their parts may still be loading in)
		while true do
			for _, model in folder:GetChildren() do
				if model:IsA("Model") and not keepers[model] then
					track(model)
				end
			end
			task.wait(1)
		end
	end)
	RunService.RenderStepped:Connect(update)
end

return NpcController
