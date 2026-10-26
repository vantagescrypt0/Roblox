--!strict
-- Minecraft-style controls on your island and in the resource worlds (and in Town):
--   aim at a block -> black outline
--   hold left click (or hold a finger on it) -> you swing and it cracks, then breaks.
--     How long depends on the block's toughness and the tool you hold (Mining.luau).
--     Blocks the server marked Locked (the worlds' ground, portals) don't crack.
--   right click (or tap) -> place the selected hotbar block against the face you aim at
--     (only on your island)
--   click / tap farmland -> plant the seeds you hold (or harvest when it's ripe)
--   right click / tap grass or dirt while holding a hoe -> till it into farmland
--   right click / tap grass or dirt while holding a sapling -> plant it
--   click a growing sapling -> dig it up
--   click / tap the crafting table or a shopkeeper in Town -> open crafting / their shop
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
local Places = require(ReplicatedStorage.Shared.Places)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Hotbar = require(script.Parent.Hotbar)

local player = Players.LocalPlayer :: Player

local TOUCH_HOLD = 0.3
local TAP_TIME = 0.25
local CLICK_SLOP = 6 -- pixels the mouse may move and still count as a click
local CRACK_STAGES = 10 -- the block darkens in steps, like Minecraft's crack texture
local SWING_EVERY = 0.3 -- seconds between mining swings
local TALK_DISTANCE = 16 -- how close you must be to trade with a shopkeeper
local ON_ISLAND = Places.Current() == "Island"
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
	GoldOre = Color3.fromRGB(236, 196, 64),
	Furnace = Color3.fromRGB(110, 110, 110),
	Wood = Color3.fromRGB(104, 82, 51),
	BirchWood = Color3.fromRGB(220, 216, 204),
	SpruceWood = Color3.fromRGB(70, 50, 30),
	CherryWood = Color3.fromRGB(92, 52, 56),
	Planks = Color3.fromRGB(162, 130, 78),
	Leaves = Color3.fromRGB(58, 120, 38),
	BirchLeaves = Color3.fromRGB(110, 160, 70),
	SpruceLeaves = Color3.fromRGB(46, 84, 58),
	CherryLeaves = Color3.fromRGB(238, 164, 196),
	RedWool = Color3.fromRGB(168, 42, 36),
	WhiteWool = Color3.fromRGB(232, 234, 234),
	StoneBricks = Color3.fromRGB(122, 122, 124),
	SmoothStone = Color3.fromRGB(162, 162, 164),
	Bricks = Color3.fromRGB(152, 74, 56),
	Plaster = Color3.fromRGB(230, 222, 202),
	DarkPlanks = Color3.fromRGB(96, 66, 40),
	Glass = Color3.fromRGB(200, 230, 242),
	RoofRed = Color3.fromRGB(176, 80, 50),
	RoofSlate = Color3.fromRGB(84, 96, 118),
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
	OpenShop: (shopId: string) -> (),
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

-- The blocks you can work on here: your own island, or the shared resource world
local function workArea(): Instance?
	if ON_ISLAND then
		local islands = Workspace:FindFirstChild("Islands")
		return islands and islands:FindFirstChild(`Island_{player.UserId}`)
	end
	return Workspace:FindFirstChild("World")
end

local function shopkeepers(): { Instance }
	local town = Workspace:FindFirstChild("Town")
	local folder = town and town:FindFirstChild("Npcs")
	return if folder then folder:GetChildren() else {}
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
	local area = workArea()
	local origin = rootPosition()
	local ray = screenRay()
	if not area or not origin or not ray then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { area }
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

-- The shop of the shopkeeper under the pointer, if we're close enough to talk
local function aimedShop(): string?
	local keepers = shopkeepers()
	local origin = rootPosition()
	local ray = screenRay()
	if #keepers == 0 or not origin or not ray then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = keepers
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 120, params)
	if not hit or (hit.Position - origin).Magnitude > TALK_DISTANCE then
		return nil
	end
	local model = hit.Instance:FindFirstAncestorWhichIsA("Model")
	while model and not model:GetAttribute("Shop") do
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	local shopId = model and model:GetAttribute("Shop")
	return if type(shopId) == "string" then shopId else nil
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
	if not ON_ISLAND or not item or not item.Block or not current then
		return
	end
	Remotes.PlaceBlock:FireServer(current.PX, current.PY, current.PZ, itemId)
end

-- Right-clicking a block on your island with something that works on it: a hoe tills
-- grass or dirt, a sapling is planted on it. Returns true if used.
local function useHeld(current: Target): boolean
	if not ON_ISLAND then
		return false
	end
	local itemId = Hotbar.SelectedItem()
	local tool = itemId and Tools.ByItem[itemId]
	local name = current.Part.Name
	local remote: RemoteEvent? = nil
	if (name == "Grass" or name == "Dirt") and tool and tool.Kind == "Hoe" then
		remote = Remotes.Till
	elseif (name == "Grass" or name == "Dirt") and itemId == "Sapling" then
		remote = Remotes.PlantSapling
	end
	if remote then
		remote:FireServer(current.X, current.Y, current.Z)
		return true
	end
	return false
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
	elseif current and current.Part.Name == "Sapling" then
		Remotes.Uproot:FireServer(current.X, current.Y, current.Z)
		return true
	elseif current and secondary and useHeld(current) then
		return true
	end
	local shopId = aimedShop()
	if shopId then
		callbacks.OpenShop(shopId)
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
	local locked = current ~= nil and current.Part:GetAttribute("Locked") == true
	if not breaking or not current or not def or not def.Breakable or locked or cooldown > 0 then
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
