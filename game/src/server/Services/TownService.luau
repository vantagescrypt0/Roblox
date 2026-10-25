--!strict
-- The Town place: a shared block plaza on its own servers. Players teleport here from
-- their island's portal (TravelService) and spawn on the plaza; anyone who falls off is
-- put back. It has the Market stall with the Merchant (a travelling trader with a huge
-- backpack; click or tap him to trade) and a runestone portal home. The Warzone gate will
-- be added here later.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Portal = require(script.Parent.Parent.Util.Portal)
local Props = require(script.Parent.Parent.Util.Props)
local DataService = require(script.Parent.DataService)
local QuestService = require(script.Parent.QuestService)
local TravelService = require(script.Parent.TravelService)

local TOWN_CENTER = Vector3.new(0, 200, 0)
local RADIUS = 14
local SIZE = Blocks.Size
local HOME_PORTAL_Z = -11
local FALL_LIMIT = 120

-- Merchant: an original travelling-trader design, built from parts measured in "pixels"
-- (1/16 of a block) so it matches the blocky world
local PIXEL = SIZE / 16
local SKIN = Color3.fromRGB(236, 194, 156)
local SKIN_SHADE = Color3.fromRGB(220, 170, 132)
local HAIR = Color3.fromRGB(104, 70, 46)
local SHIRT = Color3.fromRGB(236, 222, 188)
local VEST = Color3.fromRGB(64, 132, 92)
local PANTS = Color3.fromRGB(74, 70, 96)
local BOOTS = Color3.fromRGB(58, 40, 30)
local LEATHER = Color3.fromRGB(96, 64, 40)
local GOLD = Color3.fromRGB(232, 183, 64)
local SCARF = Color3.fromRGB(196, 72, 58)
local CAP = Color3.fromRGB(52, 92, 108)
local CAP_DARK = Color3.fromRGB(36, 66, 78)
local CANVAS = Color3.fromRGB(164, 132, 88)
local CANVAS_DARK = Color3.fromRGB(128, 98, 62)

local TownService = {}

local world: BlockWorld.World
local spawnPoint: SpawnLocation
local marketCounter: BasePart
local merchant: Model

function TownService.GetMarketCounter(): BasePart
	return marketCounter
end

-- The Merchant NPC model. Its "Head" model turns to look at players (on the client).
function TownService.GetMerchant(): Model
	return merchant
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
	label.FontFace = Font.fromEnum(Enum.Font.Fondamento)
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(251, 238, 211)
	label.Text = text
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(46, 28, 15)
	stroke.Thickness = 3
	stroke.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.12, 0)
	padding.PaddingBottom = UDim.new(0.12, 0)
	padding.Parent = label
end

-- One box of the merchant: size and center in pixels, in the frame `origin`
local function box(parent: Instance, name: string, origin: CFrame, size: Vector3, center: Vector3, color: Color3): Part
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
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5.4, 0) -- above the chat bubble
	gui.MaxDistance = 70
	-- Stays readable under the stall roof
	gui.AlwaysOnTop = true
	gui.Adornee = head
	gui.Parent = head
	local function line(text: string, size: number, y: number, color: Color3, font: Font)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, size + 4)
		label.Position = UDim2.fromOffset(0, y)
		label.BackgroundTransparency = 1
		label.FontFace = font
		label.TextSize = size
		label.TextColor3 = color
		label.Text = text
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(46, 28, 15)
		stroke.Thickness = 2
		stroke.Parent = label
	end
	-- Same fonts as the game's UI (client/UI/Theme.luau)
	line("Merchant", 26, 0, Color3.fromRGB(242, 193, 78), Font.fromEnum(Enum.Font.Fondamento))
	line(
		"Buys crops, sells seeds",
		15,
		31,
		Color3.fromRGB(251, 238, 211),
		Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold)
	)
end

-- The travelling trader: newsboy cap, bushy mustache, green vest, red scarf, arms at his
-- sides and a big canvas backpack with a bedroll and a lantern. Stands at `feet`, facing `facing`.
local function makeMerchant(feet: Vector3, facing: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Merchant"
	model:SetAttribute("Interact", "Market")
	local origin = CFrame.lookAt(feet, feet + facing) -- front is -Z

	for _, side in { -1, 1 } do
		box(model, "Boot", origin, Vector3.new(4.4, 2.4, 5.4), Vector3.new(side * 2.2, 1.2, -0.5), BOOTS)
		box(model, "Leg", origin, Vector3.new(4, 8, 4), Vector3.new(side * 2.2, 6.4, 0), PANTS)
		box(model, "Sleeve", origin, Vector3.new(3, 8, 3.4), Vector3.new(side * 6.6, 16.2, 0), SHIRT)
		box(model, "Hand", origin, Vector3.new(3, 2.6, 3), Vector3.new(side * 6.6, 10.9, 0), SKIN)
		box(model, "Strap", origin, Vector3.new(1.2, 9, 0.4), Vector3.new(side * 2.6, 16.4, -3.4), LEATHER)
	end
	local body = box(model, "Body", origin, Vector3.new(10, 10, 6), Vector3.new(0, 15.4, 0), SHIRT)
	box(model, "Vest", origin, Vector3.new(10.4, 8.6, 6.4), Vector3.new(0, 15.8, 0), VEST)
	box(model, "VestOpening", origin, Vector3.new(2.4, 8.6, 0.3), Vector3.new(0, 15.8, -3.3), SHIRT)
	box(model, "Belt", origin, Vector3.new(10.8, 1.4, 6.8), Vector3.new(0, 11.2, 0), LEATHER)
	box(model, "Buckle", origin, Vector3.new(2, 1.8, 0.4), Vector3.new(0, 11.2, -3.5), GOLD)
	box(model, "Scarf", origin, Vector3.new(11, 2.2, 7), Vector3.new(0, 20.6, 0), SCARF)
	box(model, "ScarfTail", origin, Vector3.new(2.2, 5, 0.6), Vector3.new(-2.6, 17.8, -3.7), SCARF)

	-- Backpack piled with a rolled bedroll, and a lantern hanging off the side
	box(model, "Pack", origin, Vector3.new(9, 11, 4), Vector3.new(0, 16, 5.2), CANVAS)
	box(model, "PackFlap", origin, Vector3.new(9.4, 3, 4.4), Vector3.new(0, 20.2, 5.2), CANVAS_DARK)
	box(model, "Bedroll", origin, Vector3.new(11, 3, 3), Vector3.new(0, 23.2, 5.2), SCARF)
	for _, x in { -3, 3 } do
		box(model, "BedrollTie", origin, Vector3.new(0.6, 3.2, 3.2), Vector3.new(x, 23.2, 5.2), LEATHER)
	end
	box(model, "LanternFrame", origin, Vector3.new(2, 2.6, 2), Vector3.new(5.6, 14.4, 5.2), LEATHER)
	local glass = box(
		model,
		"Lantern",
		origin,
		Vector3.new(1.4, 2, 1.4),
		Vector3.new(5.6, 14.4, 5.2),
		Color3.fromRGB(255, 214, 128)
	)
	glass.Material = Enum.Material.Neon
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 150)
	light.Brightness = 1.2
	light.Range = 14
	light.Shadows = false
	light.Parent = glass

	-- Head (pivots at the neck so it can turn to watch players)
	local headModel = Instance.new("Model")
	headModel.Name = "Head"
	headModel.Parent = model
	local neck = origin * CFrame.new(0, 21.6 * PIXEL, 0)
	local head = box(headModel, "Head", neck, Vector3.new(8, 8, 8), Vector3.new(0, 4, 0), SKIN)
	box(headModel, "Nose", neck, Vector3.new(1.4, 1.4, 1), Vector3.new(0, 3.4, -4.4), SKIN_SHADE)
	box(headModel, "Mustache", neck, Vector3.new(5.6, 1.3, 0.6), Vector3.new(0, 2.3, -4.2), HAIR)
	box(headModel, "HairBack", neck, Vector3.new(8.2, 4, 1), Vector3.new(0, 4.2, 3.9), HAIR)
	for _, side in { -1, 1 } do
		box(
			headModel,
			"Eye",
			neck,
			Vector3.new(1.2, 1.8, 0.3),
			Vector3.new(side * 1.8, 4.6, -4.05),
			Color3.fromRGB(40, 34, 40)
		)
		box(
			headModel,
			"Glint",
			neck,
			Vector3.new(0.5, 0.5, 0.3),
			Vector3.new(side * 1.6, 5.2, -4.15),
			Color3.new(1, 1, 1)
		)
		box(headModel, "Brow", neck, Vector3.new(2.2, 0.6, 0.3), Vector3.new(side * 1.9, 6.1, -4.05), HAIR)
		box(
			headModel,
			"Cheek",
			neck,
			Vector3.new(1.2, 0.9, 0.2),
			Vector3.new(side * 2.9, 2.9, -4.05),
			Color3.fromRGB(238, 150, 136)
		)
		box(headModel, "MustacheEnd", neck, Vector3.new(1.2, 1, 0.6), Vector3.new(side * 3.2, 1.9, -4.2), HAIR)
		box(headModel, "Sideburn", neck, Vector3.new(0.6, 3, 3), Vector3.new(side * 4.05, 4.4, 1), HAIR)
	end
	box(headModel, "Cap", neck, Vector3.new(8.8, 2.6, 8.8), Vector3.new(0, 8.8, 0.2), CAP)
	box(headModel, "CapTop", neck, Vector3.new(7.6, 0.8, 7.6), Vector3.new(0, 10.3, 0.4), CAP)
	box(headModel, "Visor", neck, Vector3.new(6.4, 0.6, 3), Vector3.new(0, 7.7, -5.2), CAP_DARK)
	box(headModel, "CapButton", neck, Vector3.new(1, 0.6, 1), Vector3.new(0, 10.9, 0.4), GOLD)
	headModel.PrimaryPart = head
	addNameTag(head)

	model.PrimaryPart = body
	model.Parent = world.Model
	return model
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

	-- Runestone portal home at the far end of the path
	Portal.addCells(world.Cells, world.Protected, 0, HOME_PORTAL_Z)

	BlockWorld.drawAll(world)

	-- Players arrive between the portal and the plaza, facing the Market
	local spawnAt = TOWN_CENTER + Vector3.new(0, 0, -5 * SIZE)
	spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "TownSpawn"
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.CFrame = CFrame.lookAt(spawnAt - Vector3.new(0, 0.5, 0), spawnAt - Vector3.new(0, 0.5, -1))
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Transparency = 1
	spawnPoint.Duration = 0
	spawnPoint.Neutral = true
	spawnPoint.Parent = world.Model

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

	local home = Portal.makeField(world, 0, HOME_PORTAL_Z)
	TravelService.AddPortal(home, "Island", "Go home", function()
		return true
	end)
end

local function spawnCharacter(player: Player)
	if player.Parent == Players then
		player:LoadCharacterAsync()
	end
end

local function onDataLoaded(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			task.wait(Players.RespawnTime)
			if player.Character == character then
				spawnCharacter(player)
			end
		end)
	end)
	spawnCharacter(player)
	QuestService.Record(player, "VisitTown")
end

-- Anyone who falls off the plaza lands back at the spawn point
local function catchFallers()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and root and root:IsA("BasePart") and root.Position.Y < TOWN_CENTER.Y - FALL_LIMIT then
			root.AssemblyLinearVelocity = Vector3.zero
			character:PivotTo(spawnPoint.CFrame + Vector3.new(0, 4, 0))
		end
	end
end

function TownService.Start()
	Players.CharacterAutoLoads = false
	build()
	DataService.OnDataLoaded(onDataLoaded)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.5 then
			elapsed = 0
			catchFallers()
		end
	end)
end

return TownService
