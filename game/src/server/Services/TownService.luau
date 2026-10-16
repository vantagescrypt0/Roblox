--!strict
-- The Town: a shared block plaza everyone can visit through their island portal.
-- For now it has the Market (selling and seeds) and a portal home. The Warzone gate
-- will be added here later.

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

local world: BlockWorld.World
local spawnPosition: Vector3
local marketCounter: BasePart

function TownService.GetMarketCounter(): BasePart
	return marketCounter
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
