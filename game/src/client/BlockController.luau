--!strict
-- Minecraft-style controls on your island (and in Town):
--   aim at a block -> black outline
--   hold left click (or hold a finger on it) -> you swing and it cracks, then breaks.
--     How long depends on the block's toughness and the tool you hold (Mining.luau).
--   right click (or tap) -> place the selected hotbar block against the face you aim at
--   click / tap farmland -> plant the seeds you hold (or harvest when it's ripe)
--   click / tap the crafting table or the Merchant -> open crafting / the market
--   right click / tap a furnace -> smelting (left click breaks it, so you can move it)
-- The server double-checks everything.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Items = require(ReplicatedStorage.Shared.Items)
local Mining = require(ReplicatedStorage.Shared.Mining)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Hotbar = require(script.Parent.Hotbar)

local player = Players.LocalPlayer :: Player

local TOUCH_HOLD = 0.3
local TAP_TIME = 0.25
local CLICK_SLOP = 6 -- pixels the mouse may move and still count as a click
local CRACK_STAGES = 10 -- the block darkens in steps, like Minecraft's crack texture
local SWING_EVERY = 0.3 -- seconds between mining swings
local TALK_DISTANCE = 16 -- how close you must be to trade with the Merchant
local SLASH_ANIMATION = {
	[Enum.HumanoidRigType.R15] = "rbxassetid://522635514",
	[Enum.HumanoidRigType.R6] = "rbxassetid://129967478",
}
local DEBRIS_COLORS: { [string]: Color3 } = {
	Grass = Color3.fromRGB(95, 159, 53),
	Dirt = Color3.fromRGB(134, 96, 67),
	Stone = Color3.fromRGB(125, 125, 125),
	Cobblestone = Color3.fromRGB(120, 120, 120),
	CoalOre = Color3.fromRGB(70, 70, 72),
	IronOre = Color3.fromRGB(176, 140, 112),
	Furnace = Color3.fromRGB(110, 110, 110),
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

export type Callbacks = {
	OpenCrafting: (station: Recipes.Station) -> (),
	OpenMarket: () -> (),
}

local BlockController = {}

local callbacks: Callbacks
local selection: SelectionBox
local target: Target? = nil
local pointer: Vector2? = nil -- screen position used for aiming
local breaking = false
local progress = 0
local progressPart: BasePart? = nil
local cooldown = 0
local rightDown: Vector2? = nil
local touchStart: { Position: Vector2, Time: number }? = nil
local swingTimer = 0
local swingTrack: AnimationTrack? = nil
local swingCharacter: Model? = nil

local function myIsland(): Instance?
	local islands = Workspace:FindFirstChild("Islands")
	return islands and islands:FindFirstChild(`Island_{player.UserId}`)
end

local function merchant(): Model?
	local town = Workspace:FindFirstChild("Town")
	local model = town and town:FindFirstChild("Merchant")
	return if model and model:IsA("Model") then model else nil
end

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function screenRay(): Ray?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local screen = pointer or UserInputService:GetMouseLocation()
	return camera:ViewportPointToRay(screen.X, screen.Y)
end

local function aim(): Target?
	local island = myIsland()
	local origin = rootPosition()
	local ray = screenRay()
	if not island or not origin or not ray then
		return nil
	end
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

-- Is the pointer on the Merchant, and are we close enough to talk?
local function aimingAtMerchant(): boolean
	local model = merchant()
	local origin = rootPosition()
	local ray = screenRay()
	if not model or not origin or not ray or not model.PrimaryPart then
		return false
	end
	if (model.PrimaryPart.Position - origin).Magnitude > TALK_DISTANCE then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { model }
	return Workspace:Raycast(ray.Origin, ray.Direction * 120, params) ~= nil
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

-- The arm swing played while mining (the same slash a tool click plays)
local function swing()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not character or not humanoid or not animator then
		return
	end
	if swingCharacter ~= character then
		swingCharacter = character
		local animation = Instance.new("Animation")
		animation.AnimationId = SLASH_ANIMATION[humanoid.RigType]
		swingTrack = animator:LoadAnimation(animation)
		local track = swingTrack :: AnimationTrack
		track.Priority = Enum.AnimationPriority.Action
	end
	local track = swingTrack
	if track then
		track:Play(0.05)
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

-- Clicking something you use rather than break. Returns true if the click was used.
-- `secondary` is a right click or a tap; breakable stations (the furnace) only open on
-- those, so a left click can still break them.
local function interact(secondary: boolean): boolean
	local current = target
	if current and current.Part.Name == "Farmland" then
		Remotes.FarmClick:FireServer(current.X, current.Y, current.Z)
		return true
	elseif current and current.Part.Name == "CraftingTable" then
		callbacks.OpenCrafting("CraftingTable")
		return true
	elseif current and secondary and current.Part.Name == "Furnace" then
		callbacks.OpenCrafting("Furnace")
		return true
	elseif aimingAtMerchant() then
		callbacks.OpenMarket()
		return true
	end
	return false
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
		swingTimer = 0
		return
	end
	if progressPart ~= current.Part then
		progressPart = current.Part
		progress = 0
	end

	-- Toughness vs tool power; switching tools mid-way changes the speed
	local breakTime = Mining.BreakTime(current.Part.Name, Hotbar.SelectedItem())
	progress += dt / breakTime
	local stage = math.floor(math.min(progress, 1) * CRACK_STAGES) / CRACK_STAGES
	selection.SurfaceTransparency = 1 - stage * 0.6

	swingTimer -= dt
	if swingTimer <= 0 then
		swingTimer = SWING_EVERY
		swing()
	end

	if progress >= 1 then
		Remotes.BreakBlock:FireServer(current.X, current.Y, current.Z)
		burst(current.Part.Position, DEBRIS_COLORS[current.Part.Name] or Color3.fromRGB(120, 120, 120))
		progress = 0
		progressPart = nil
		cooldown = 0.15
	end
end

function BlockController.Start(handlers: Callbacks)
	callbacks = handlers

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
			target = aim()
			if not interact(false) then
				breaking = true
			end
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
			-- A right click (not a camera drag) uses or places
			if start and (UserInputService:GetMouseLocation() - start).Magnitude <= CLICK_SLOP then
				target = aim()
				if not interact(true) then
					place()
				end
			end
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local start = touchStart
			touchStart = nil
			breaking = false
			if start and os.clock() - start.Time < TAP_TIME then
				target = aim()
				if not interact(true) then
					place()
				end
			end
		end
	end)
end

return BlockController
