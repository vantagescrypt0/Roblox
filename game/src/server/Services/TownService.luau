--!strict
-- The Town: a shared block plaza everyone can visit through their island portal.
-- For now it has the Market stall with its Merchant (a blocky villager-style NPC you
-- trade with) and a portal home. The Warzone gate will be added here later.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local Props = require(script.Parent.Parent.Util.Props)
local IslandService = require(script.Parent.IslandService)
local QuestService = require(script.Parent.QuestService)

local TOWN_CENTER = Vector3.new(0, 200, -2600)
local RADIUS = 14
local SIZE = Blocks.Size
local TRAVEL_DELAY = 0.35

local TownService = {}

-- Merchant look (Minecraft villager proportions: 1 pixel = 1/16 of a block)
local PIXEL = SIZE / 16
local SKIN = Color3.fromRGB(189, 139, 114)
local ROBE = Color3.fromRGB(125, 86, 56)
local ROBE_DARK = Color3.fromRGB(96, 64, 42)
local BELT = Color3.fromRGB(66, 45, 28)
local STRAW = Color3.fromRGB(222, 190, 110)
local HAT_BAND = Color3.fromRGB(168, 64, 52)

local world: BlockWorld.World
local spawnPosition: Vector3
local marketCounter: BasePart
local merchant: Model

function TownService.GetMarketCounter(): BasePart
	return marketCounter
end

-- The Merchant NPC model. Its "Head" model turns to look at players (on the client).
function TownService.GetMerchant(): Model
	return merchant
end

local function travel(player: Player, destination: string, go: () -> ())
	Remotes.Travel:FireClient(player, destination)
	task.delay(TRAVEL_DELAY, go)
end

function TownService.Enter(player: Player)
	local character = player.Character
	if not character then
		return
	end
	travel(player, "Town", function()
		if player.Character then
			player.Character:PivotTo(
				CFrame.lookAt(spawnPosition + Vector3.new(0, 4, 0), spawnPosition + Vector3.new(0, 4, 10))
			)
		end
	end)
	QuestService.Record(player, "VisitTown")
end

local function set(x: number, y: number, z: number, blockType: string)
	BlockWorld.setRaw(world, x, y, z, blockType)
	world.Protected[BlockWorld.key(x, y, z)] = true
end

local function addSign(part: BasePart, text: string, front: Vector3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Props.FaceToward(part, front)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.Arcade)
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = text
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(50, 30, 10)
	stroke.Thickness = 3
	stroke.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.12, 0)
	padding.PaddingBottom = UDim.new(0.12, 0)
	padding.Parent = label
end

-- One box of the merchant: size and center in pixels, in the frame `origin`
local function box(parent: Instance, name: string, origin: CFrame, size: Vector3, center: Vector3, color: Color3)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size * PIXEL
	part.CFrame = origin * CFrame.new(center * PIXEL)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

local function addNameTag(head: BasePart)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(220, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0) -- above the chat bubble
	gui.MaxDistance = 70
	-- Stays readable under the stall roof
	gui.AlwaysOnTop = true
	gui.Adornee = head
	gui.Parent = head
	local function line(text: string, size: number, y: number, color: Color3)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, size + 4)
		label.Position = UDim2.fromOffset(0, y)
		label.BackgroundTransparency = 1
		label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		label.TextSize = size
		label.TextColor3 = color
		label.Text = text
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(20, 22, 32)
		stroke.Thickness = 2
		stroke.Parent = label
	end
	line("Merchant", 24, 0, Color3.fromRGB(255, 214, 92))
	line("Buys crops - Sells seeds", 15, 30, Color3.fromRGB(235, 238, 245))
end

-- A blocky villager-style merchant standing at `feet`, facing `facing`
local function makeMerchant(feet: Vector3, facing: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Merchant"
	model:SetAttribute("Interact", "Market")
	local origin = CFrame.lookAt(feet, feet + facing)

	-- Legs peek out under a long robe; front is -Z
	box(model, "LeftLeg", origin, Vector3.new(4, 6, 4), Vector3.new(-2, 3, 0), ROBE_DARK)
	box(model, "RightLeg", origin, Vector3.new(4, 6, 4), Vector3.new(2, 3, 0), ROBE_DARK)
	local body = box(model, "Body", origin, Vector3.new(8, 18, 6), Vector3.new(0, 15, 0), ROBE)
	box(model, "Belt", origin, Vector3.new(8.3, 1.2, 6.3), Vector3.new(0, 12, 0), BELT)

	-- Crossed arms, tilted forward from the shoulders like a Minecraft villager
	local shoulders = origin * CFrame.new(0, 22 * PIXEL, -1 * PIXEL) * CFrame.Angles(0.75, 0, 0)
	box(model, "LeftArm", shoulders, Vector3.new(4, 8, 4), Vector3.new(-6, -4, 0), ROBE)
	box(model, "RightArm", shoulders, Vector3.new(4, 8, 4), Vector3.new(6, -4, 0), ROBE)
	box(model, "Hands", shoulders, Vector3.new(8, 4, 4), Vector3.new(0, -6, 0), SKIN)
	box(model, "Sleeves", shoulders, Vector3.new(8.4, 2, 4.4), Vector3.new(0, -3.6, 0), ROBE_DARK)

	-- Head (pivots at the neck), big nose, unibrow and a farmer's straw hat
	local headModel = Instance.new("Model")
	headModel.Name = "Head"
	headModel.Parent = model
	local neck = origin * CFrame.new(0, 24 * PIXEL, 0)
	local head = box(headModel, "Head", neck, Vector3.new(8, 10, 8), Vector3.new(0, 5, 0), SKIN)
	box(headModel, "Nose", neck, Vector3.new(2, 4, 2), Vector3.new(0, 2.5, -5), Color3.fromRGB(176, 124, 100))
	for _, side in { -1, 1 } do
		box(
			headModel,
			"Eye",
			neck,
			Vector3.new(2, 1, 0.3),
			Vector3.new(side * 2, 5.5, -4.1),
			Color3.fromRGB(240, 240, 240)
		)
		box(
			headModel,
			"Pupil",
			neck,
			Vector3.new(1, 1, 0.4),
			Vector3.new(side * 1.5, 5.5, -4.15),
			Color3.fromRGB(64, 140, 62)
		)
	end
	box(headModel, "Brow", neck, Vector3.new(8, 1, 0.3), Vector3.new(0, 6.5, -4.1), Color3.fromRGB(70, 46, 30))
	box(headModel, "HatBrim", neck, Vector3.new(14, 1, 14), Vector3.new(0, 9.5, 0), STRAW)
	box(headModel, "HatTop", neck, Vector3.new(8.6, 3, 8.6), Vector3.new(0, 11.5, 0), STRAW)
	box(headModel, "HatBand", neck, Vector3.new(8.8, 1, 8.8), Vector3.new(0, 10.5, 0), HAT_BAND)
	headModel.PrimaryPart = head
	addNameTag(head)

	-- A warm lantern glow so the Merchant isn't lost in the stall's shade
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 214, 160)
	light.Brightness = 1.1
	light.Range = 14
	light.Shadows = false
	light.Parent = head

	model.PrimaryPart = body
	model.Parent = world.Model
	return model
end

local function makePortalSurface(position: Vector3): BasePart
	local surface = Instance.new("Part")
	surface.Name = "PortalSurface"
	surface.Size = Vector3.new(2 * SIZE, 3 * SIZE, 0.4)
	surface.CFrame = CFrame.new(position)
	surface.Material = Enum.Material.Neon
	surface.Color = Color3.fromRGB(140, 70, 255)
	surface.Transparency = 0.3
	surface.Anchored = true
	surface.CanCollide = false
	surface.Parent = world.Model
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 100, 255)
	light.Range = 16
	light.Brightness = 2
	light.Parent = surface
	return surface
end

local function build()
	world = BlockWorld.new(TOWN_CENTER - Vector3.new(0, SIZE / 2, 0), "Town", workspace)

	-- Ground: a flat floating platform with a cobblestone plaza and path
	for x = -RADIUS, RADIUS do
		for z = -RADIUS, RADIUS do
			local distance = math.sqrt(x * x + z * z)
			if distance <= RADIUS + 0.4 then
				local plaza = math.abs(x) <= 3 and math.abs(z) <= 3
				local path = math.abs(x) <= 1 and z >= -10 and z <= 6
				set(x, 0, z, if plaza or path then "Cobblestone" else "Grass")
				local depth = 2 + math.floor((1 - distance / RADIUS) ^ 0.8 * 8)
				for y = -1, -depth, -1 do
					set(x, y, z, if y >= -2 then "Dirt" else "Stone")
				end
			end
		end
	end

	-- Market stall (faces the plaza, toward -Z)
	for x = -2, 2 do
		set(x, 1, 6, "Planks") -- counter
		set(x, 1, 8, "Planks") -- back wall
		set(x, 2, 8, "Planks")
	end
	for _, x in { -3, 3 } do
		for _, z in { 6, 8 } do
			for y = 1, 3 do
				set(x, y, z, "Wood")
			end
		end
	end
	for x = -3, 3 do
		for z = 6, 8 do
			set(x, 4, z, if x % 2 == 0 then "RedWool" else "WhiteWool")
		end
	end

	-- Portal home (obsidian frame at the far end of the path)
	local portalZ = -11
	for y = 1, 5 do
		for x = -2, 1 do
			if x == -2 or x == 1 or y == 1 or y == 5 then
				set(x, y, portalZ, "Obsidian")
			end
		end
	end

	BlockWorld.drawAll(world)

	spawnPosition = TOWN_CENTER + Vector3.new(0, 0, -4 * SIZE)

	-- Wooden sign hanging off the front of the roof (3 blocks wide)
	local roofFront = BlockWorld.position(world, 0, 5, 6) - Vector3.new(0, 0, SIZE / 2 + 0.25)
	local sign = Instance.new("Part")
	sign.Name = "MarketSign"
	sign.Size = Vector3.new(3 * SIZE, SIZE * 0.85, 0.4)
	sign.CFrame = CFrame.new(roofFront)
	sign.Color = Color3.fromRGB(162, 130, 78)
	sign.Material = Enum.Material.WoodPlanks
	sign.Anchored = true
	sign.Parent = world.Model
	addSign(sign, "MARKET", Vector3.new(0, 0, -1))
	marketCounter = BlockWorld.part(world, 0, 1, 6) :: BasePart

	-- The Merchant stands behind the counter, facing the plaza
	local feet = BlockWorld.position(world, 0, 1, 7) - Vector3.new(0, SIZE / 2, 0)
	merchant = makeMerchant(feet, Vector3.new(0, 0, -1))

	local home = makePortalSurface(BlockWorld.position(world, -0.5, 3, portalZ))
	local prompt =
		Prompts.Create(home, { Action = "Go home", Object = "Portal to your island", Hold = 0.5, Distance = 12 })
	prompt.Triggered:Connect(function(player)
		travel(player, "Island", function()
			IslandService.SendHome(player)
		end)
	end)
end

local function onIslandCreated(player: Player, island: IslandService.Island)
	local prompt = Prompts.Create(island.PortalSurface, {
		Action = "Travel to Town",
		Object = "Portal",
		Hold = 0.5,
		Distance = 12,
	})
	Prompts.OnTriggeredBy(prompt, player, function()
		TownService.Enter(player)
	end)
end

function TownService.Start()
	build()
	IslandService.OnIslandCreated(onIslandCreated)
end

return TownService
