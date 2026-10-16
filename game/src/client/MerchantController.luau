--!strict
-- Brings the Town Merchant to life on your screen: its head turns to watch you as you
-- walk by (like a Minecraft villager), and it greets you with a chat bubble when you
-- come up to the stall.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer :: Player

local WATCH_DISTANCE = 40
local GREET_DISTANCE = 18
local MAX_YAW = math.rad(70)
local MAX_PITCH = math.rad(35)
local TURN_SPEED = 8
local GREETINGS = {
	"Hrmm! Got crops to sell?",
	"Fresh seeds, fair prices!",
	"Bring me Wheat, Carrots and Potatoes!",
	"Welcome to the Market, friend!",
	"Hrmm... business is good today.",
}

local MerchantController = {}

type Head = {
	Model: Model,
	Neck: CFrame, -- neck position and resting rotation
	Lift: CFrame, -- neck -> head center
	Yaw: number,
	Pitch: number,
}

local head: Head? = nil
local greeted = false

local function findHead(): Head?
	local town = Workspace:FindFirstChild("Town")
	local merchant = town and town:FindFirstChild("Merchant")
	local model = merchant and merchant:FindFirstChild("Head")
	if not model or not model:IsA("Model") or not model.PrimaryPart then
		return nil
	end
	local pivot = model:GetPivot()
	local lift = CFrame.new(0, model.PrimaryPart.Size.Y / 2, 0)
	return { Model = model, Neck = pivot * lift:Inverse(), Lift = lift, Yaw = 0, Pitch = 0 }
end

local function greet(model: Model)
	local message = GREETINGS[math.random(#GREETINGS)]
	local part = model.PrimaryPart
	if part then
		pcall(function()
			TextChatService:DisplayBubble(part, message)
		end)
	end
end

local function update(dt: number)
	if not head or not head.Model.Parent then
		head = findHead()
		if not head then
			return
		end
	end
	local current = head :: Head
	local character = player.Character
	local target = character and character:FindFirstChild("Head")
	local targetYaw, targetPitch = 0, 0
	local distance = math.huge
	if target and target:IsA("BasePart") then
		local offset = current.Neck:PointToObjectSpace(target.Position)
		distance = offset.Magnitude
		if distance < WATCH_DISTANCE then
			targetYaw = math.clamp(math.atan2(-offset.X, -offset.Z), -MAX_YAW, MAX_YAW)
			targetPitch =
				math.clamp(math.atan2(offset.Y, Vector2.new(offset.X, offset.Z).Magnitude), -MAX_PITCH, MAX_PITCH)
		end
	end

	local alpha = 1 - math.exp(-TURN_SPEED * dt)
	current.Yaw += (targetYaw - current.Yaw) * alpha
	current.Pitch += (targetPitch - current.Pitch) * alpha
	current.Model:PivotTo(
		current.Neck * CFrame.Angles(0, current.Yaw, 0) * CFrame.Angles(current.Pitch, 0, 0) * current.Lift
	)

	if distance < GREET_DISTANCE and not greeted then
		greeted = true
		greet(current.Model)
	elseif distance > GREET_DISTANCE + 8 then
		greeted = false
	end
end

function MerchantController.Start()
	RunService.RenderStepped:Connect(update)
end

return MerchantController
