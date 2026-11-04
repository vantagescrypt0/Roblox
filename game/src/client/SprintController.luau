--!strict
-- Sprinting, like Minecraft: double-tap W or hold Ctrl while you move. The view widens a little and
-- everyone who's sprinting leans into it. A charged hit ends your sprint, as it does there, so you
-- press again to carry on.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DOUBLE_TAP = 0.3
local VIEW_WALKING = 70
local VIEW_SPRINTING = 78
local LEAN = math.rad(11)
local LEAN_SPEED = 8

local localPlayer = Players.LocalPlayer

local SprintController = {}

local wanted = false
local asked = false
local lastForward = 0
local leans: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local function moving(): boolean
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1
end

-- Tilts anyone sprinting forward, on top of their run animation
local function lean(dt: number)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local hips = character and character:FindFirstChild("LowerTorso")
		local joint: any = hips and hips:FindFirstChild("Root")
		if character and joint then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local running = player:GetAttribute("Sprinting") and humanoid and humanoid.MoveDirection.Magnitude > 0.1
			local amount = leans[character] or 0
			amount += ((if running then 1 else 0) - amount) * math.min(1, dt * LEAN_SPEED)
			leans[character] = amount
			if amount > 0.01 then
				joint.Transform = CFrame.Angles(-LEAN * amount, 0, 0) * joint.Transform
			end
		end
	end
end

function SprintController.Start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.W then
			local now = os.clock()
			if now - lastForward < DOUBLE_TAP then
				wanted = true
			end
			lastForward = now
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			wanted = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.LeftControl then
			wanted = false
		end
	end)

	RunService.Heartbeat:Connect(function()
		local want = wanted and moving()
		if want ~= asked then
			asked = want
			Remotes.Sprint:FireServer(want)
		end
	end)

	-- The server stopped your sprint (a hit, your shield, hunger): press again to carry on
	localPlayer:GetAttributeChangedSignal("Sprinting"):Connect(function()
		local on = localPlayer:GetAttribute("Sprinting") == true
		if not on then
			wanted = false
			asked = false
		end
		local camera = Workspace.CurrentCamera
		if camera then
			TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				FieldOfView = if on then VIEW_SPRINTING else VIEW_WALKING,
			}):Play()
		end
	end)

	RunService.Stepped:Connect(function(_, dt)
		lean(dt)
	end)
end

return SprintController
