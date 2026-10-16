--!strict
-- Minecraft-style building on your island:
--   aim at a block -> black outline
--   hold left click (or hold a finger on it) -> it darkens, then breaks
--   right click (or tap) -> place the selected hotbar block against the face you aim at
-- The server double-checks everything.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Hotbar = require(script.Parent.Hotbar)

local player = Players.LocalPlayer :: Player

local TOUCH_HOLD = 0.3
local TAP_TIME = 0.25
local CLICK_SLOP = 6 -- pixels the mouse may move and still count as a click
local DEBRIS_COLORS: { [string]: Color3 } = {
	Grass = Color3.fromRGB(95, 159, 53),
	Dirt = Color3.fromRGB(134, 96, 67),
	Stone = Color3.fromRGB(125, 125, 125),
	Cobblestone = Color3.fromRGB(120, 120, 120),
	Wood = Color3.fromRGB(104, 82, 51),
	Planks = Color3.fromRGB(162, 130, 78),
	Leaves = Color3.fromRGB(58, 120, 38),
	RedWool = Color3.fromRGB(168, 42, 36),
	WhiteWool = Color3.fromRGB(232, 234, 234),
}

type Target = {
	Part: BasePart,
	X: number,
	Y: number,
	Z: number,
	-- Empty cell next to the face being aimed at
	PX: number,
	PY: number,
	PZ: number,
}

local BlockController = {}

local selection: SelectionBox
local target: Target? = nil
local pointer: Vector2? = nil -- screen position used for aiming
local breaking = false
local progress = 0
local progressPart: BasePart? = nil
local cooldown = 0
local rightDown: Vector2? = nil
local touchStart: { Position: Vector2, Time: number }? = nil

local function myIsland(): Instance?
	local islands = Workspace:FindFirstChild("Islands")
	return islands and islands:FindFirstChild(`Island_{player.UserId}`)
end

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function aim(): Target?
	local island = myIsland()
	local origin = rootPosition()
	local camera = Workspace.CurrentCamera
	if not island or not origin or not camera then
		return nil
	end
	local screen = pointer or UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { island }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 120, params)
	if not hit then
		return nil
	end
	local part = hit.Instance
	local x, y, z = part:GetAttribute("X"), part:GetAttribute("Y"), part:GetAttribute("Z")
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return nil
	end
	if (part.Position - origin).Magnitude > Blocks.Reach then
		return nil
	end
	local n = hit.Normal
	return {
		Part = part,
		X = x,
		Y = y,
		Z = z,
		PX = x + math.round(n.X),
		PY = y + math.round(n.Y),
		PZ = z + math.round(n.Z),
	}
end

local function burst(position: Vector3, color: Color3)
	for _ = 1, 8 do
		local bit = Instance.new("Part")
		bit.Size = Vector3.one * 0.45
		bit.Color = color
		bit.Material = Enum.Material.SmoothPlastic
		bit.CanCollide = false
		bit.CanQuery = false
		bit.CFrame =
			CFrame.new(position + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2)
		bit.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), math.random(8, 18), math.random(-10, 10))
		bit.Parent = Workspace
		Debris:AddItem(bit, 0.6)
	end
end

local function place()
	local itemId = Hotbar.SelectedItem()
	local item = itemId and Items[itemId]
	local current = target
	if not item or not item.Block or not current then
		return
	end
	Remotes.PlaceBlock:FireServer(current.PX, current.PY, current.PZ, itemId)
end

local function update(dt: number)
	target = aim()
	local current = target
	selection.Adornee = if current then current.Part else nil

	cooldown = math.max(0, cooldown - dt)
	local def = current and Blocks.Types[current.Part.Name]
	if not breaking or not current or not def or not def.Breakable or cooldown > 0 then
		progress = 0
		progressPart = nil
		selection.SurfaceTransparency = 1
		return
	end
	if progressPart ~= current.Part then
		progressPart = current.Part
		progress = 0
	end
	progress += dt / def.BreakTime
	-- The block darkens as it cracks
	selection.SurfaceTransparency = 1 - math.min(progress, 1) * 0.55
	if progress >= 1 then
		Remotes.BreakBlock:FireServer(current.X, current.Y, current.Z)
		burst(current.Part.Position, DEBRIS_COLORS[current.Part.Name] or Color3.fromRGB(120, 120, 120))
		progress = 0
		progressPart = nil
		cooldown = 0.15
	end
end

function BlockController.Start()
	selection = Instance.new("SelectionBox")
	selection.Color3 = Color3.new(0, 0, 0)
	selection.LineThickness = 0.03
	selection.SurfaceColor3 = Color3.new(0, 0, 0)
	selection.SurfaceTransparency = 1
	selection.Parent = player:WaitForChild("PlayerGui")

	RunService.RenderStepped:Connect(update)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pointer = nil
			breaking = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			rightDown = UserInputService:GetMouseLocation()
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local position = Vector2.new(input.Position.X, input.Position.Y)
			pointer = position
			touchStart = { Position = position, Time = os.clock() }
			task.delay(TOUCH_HOLD, function()
				local start = touchStart
				if start and start.Time <= os.clock() - TOUCH_HOLD + 0.01 then
					breaking = true
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and touchStart then
			pointer = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			breaking = false
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			local start = rightDown
			rightDown = nil
			-- A right click (not a camera drag) places a block
			if start and (UserInputService:GetMouseLocation() - start).Magnitude <= CLICK_SLOP then
				place()
			end
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local start = touchStart
			touchStart = nil
			breaking = false
			if start and os.clock() - start.Time < TAP_TIME then
				place()
			end
		end
	end)
end

return BlockController
