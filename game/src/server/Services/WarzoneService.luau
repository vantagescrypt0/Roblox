--!strict
-- The Warzone: a shared arena unlocked at player level 10. Everything you pick up goes
-- into a raid bag. Reach an extraction pad to bring it home; die and it drops as a
-- loot head anyone can open. Greybox layout for the prototype.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local Props = require(script.Parent.Parent.Util.Props)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

-- Well clear of the islands (they start at z = 0 and go back in rows of Config.Island.Spacing)
local ARENA_CENTER = Vector3.new(0, 200, -6000)
local ARENA_SIZE = 300
local CENTER_ZONE_RADIUS = 55
local PORTAL_OFFSET = Vector3.new(-1, 0, -14)
local CHEST_RESPAWN = 60
local LOOT_HEAD_LIFETIME = 120
local EXTRACT_HOLD = 3

type LootEntry = { Item: string, Min: number, Max: number, Chance: number }

local CHEST_LOOT: { [string]: { LootEntry } } = {
	Outer = {
		{ Item = "Scrap", Min = 1, Max = 3, Chance = 1 },
		{ Item = "Crystal", Min = 1, Max = 1, Chance = 0.25 },
		{ Item = "GlowberrySeeds", Min = 1, Max = 1, Chance = 0.1 },
	},
	Center = {
		{ Item = "Scrap", Min = 3, Max = 6, Chance = 1 },
		{ Item = "Crystal", Min = 1, Max = 2, Chance = 0.7 },
		{ Item = "GlowberrySeeds", Min = 1, Max = 2, Chance = 0.35 },
	},
}

export type MobSpawn = { Position: Vector3, Zone: string }

local WarzoneService = {}

local rng = Random.new()
local arena: Model
local spawnPoints: { Vector3 } = {}
local mobSpawns: { MobSpawn } = {}

local function isInRaid(player: Player): boolean
	local data = DataService.GetData(player)
	return player:GetAttribute("InWarzone") == true and data ~= nil and data.Raid.Active
end

function WarzoneService.IsInRaid(player: Player): boolean
	return isInRaid(player)
end

function WarzoneService.GetMobSpawns(): { MobSpawn }
	return mobSpawns
end

function WarzoneService.AddToBag(player: Player, itemId: string, amount: number)
	local data = DataService.GetData(player)
	assert(Items[itemId], `Unknown item {itemId}`)
	if not data or not isInRaid(player) or amount <= 0 then
		return
	end
	data.Raid.Bag[itemId] = (data.Raid.Bag[itemId] or 0) + amount
	DataService.MarkChanged(player)
end

local function rollLoot(table_: { LootEntry }): { [string]: number }
	local loot = {}
	for _, entry in table_ do
		if rng:NextNumber() < entry.Chance then
			loot[entry.Item] = (loot[entry.Item] or 0) + rng:NextInteger(entry.Min, entry.Max)
		end
	end
	return loot
end

local function describe(loot: { [string]: number }): string
	local parts = {}
	for itemId, count in loot do
		table.insert(parts, `{count} {Items[itemId].Name}`)
	end
	return table.concat(parts, ", ")
end

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

-- Taking players in and out --------------------------------------------------------

local function enter(player: Player)
	local data = DataService.GetData(player)
	local character = player.Character
	if not data or not character or isInRaid(player) then
		return
	end
	if data.Level < Leveling.WarzoneLevel then
		StateService.Notify(player, `The Warzone unlocks at level {Leveling.WarzoneLevel}`, "bad")
		return
	end
	data.Raid.Active = true
	data.Raid.Bag = {}
	player:SetAttribute("InWarzone", true)
	DataService.MarkChanged(player)

	local spot = spawnPoints[rng:NextInteger(1, #spawnPoints)]
	character:PivotTo(
		CFrame.lookAt(spot + Vector3.new(0, 4, 0), Vector3.new(ARENA_CENTER.X, spot.Y + 4, ARENA_CENTER.Z))
	)
	StateService.Notify(player, "Welcome to the Warzone! Loot, survive, extract.", "level")
end

local function endRaid(player: Player)
	local data = DataService.GetData(player)
	player:SetAttribute("InWarzone", false)
	if data then
		data.Raid.Active = false
		data.Raid.Bag = {}
		DataService.MarkChanged(player)
	end
end

local function extract(player: Player)
	local data = DataService.GetData(player)
	if not data or not isInRaid(player) then
		return
	end
	local bag = data.Raid.Bag
	local total = 0
	for itemId, count in bag do
		if count > 0 then
			InventoryService.Add(player, itemId, count)
			total += count
		end
	end
	endRaid(player)

	local island = IslandService.GetIsland(player)
	local character = player.Character
	if island and character then
		character:PivotTo(island.Spawn.CFrame + Vector3.new(0, 4, 0))
	end
	StateService.Notify(
		player,
		if total > 0 then `Extracted! Brought home {total} items` else "Extracted (empty bag)",
		"good"
	)
	QuestService.Record(player, "Extract")
end

-- Loot heads -----------------------------------------------------------------------

local function dropLootHead(victim: Player, position: Vector3, loot: { [string]: number })
	if next(loot) == nil then
		return
	end

	local head = part({
		Name = "LootHead",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.6, 2.6, 2.6),
		Color = Color3.fromRGB(255, 204, 153),
		Material = Enum.Material.SmoothPlastic,
		CFrame = CFrame.new(position.X, ARENA_CENTER.Y + 1.3, position.Z),
		CanCollide = false,
	})
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(160, 26)
	tag.StudsOffset = Vector3.new(0, 2.6, 0)
	tag.MaxDistance = 70
	tag.Parent = head
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = `{victim.DisplayName}'s loot`
	text.TextColor3 = Color3.fromRGB(255, 220, 120)
	text.TextStrokeTransparency = 0.3
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Parent = tag

	head.Parent = arena

	local claimed = false
	local prompt = Prompts.Create(head, { Action = "Open loot", Object = `{victim.DisplayName}'s head`, Hold = 1 })
	prompt.Triggered:Connect(function(opener)
		-- First opener takes everything; the flag makes the transfer happen only once
		if claimed or not isInRaid(opener) then
			return
		end
		claimed = true
		for itemId, count in loot do
			WarzoneService.AddToBag(opener, itemId, count)
		end
		StateService.Notify(opener, `Looted {describe(loot)}`, "good")
		head:Destroy()
	end)

	task.delay(LOOT_HEAD_LIFETIME, function()
		claimed = true
		if head.Parent then
			head:Destroy()
		end
	end)
end

-- Drops the raid bag where the player is and ends their raid
local function dropBag(player: Player, position: Vector3?)
	local data = DataService.GetData(player)
	if not data or not isInRaid(player) then
		return
	end
	local loot = table.clone(data.Raid.Bag)
	endRaid(player)
	if position then
		dropLootHead(player, position, loot)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		if not isInRaid(player) then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		local position = if root and root:IsA("BasePart") then root.Position else nil
		dropBag(player, position)
		StateService.Notify(player, "You died! Your raid bag dropped as a loot head.", "bad")

		local killerId = humanoid:GetAttribute("LastAttacker")
		local killer = if typeof(killerId) == "number" then Players:GetPlayerByUserId(killerId) else nil
		if killer and killer ~= player then
			StateService.Notify(killer, `You took down {player.DisplayName}! Grab their loot head.`, "good")
		end
	end)
end

-- Building the arena ---------------------------------------------------------------

local function buildArena()
	arena = Instance.new("Model")
	arena.Name = "Warzone"

	local floor = part({
		Name = "Floor",
		Size = Vector3.new(ARENA_SIZE, 4, ARENA_SIZE),
		CFrame = CFrame.new(ARENA_CENTER - Vector3.new(0, 2, 0)),
		Color = Color3.fromRGB(96, 88, 78),
		Material = Enum.Material.Ground,
	})
	floor.Parent = arena

	local danger = part({
		Name = "CenterZone",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, CENTER_ZONE_RADIUS * 2, CENTER_ZONE_RADIUS * 2),
		CFrame = CFrame.new(ARENA_CENTER + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(120, 50, 50),
		Material = Enum.Material.Slate,
		CanCollide = false,
	})
	danger.Parent = arena

	-- Invisible walls so nobody falls off the edge
	local half = ARENA_SIZE / 2
	for _, side in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
		local size = if side.X ~= 0 then Vector3.new(2, 40, ARENA_SIZE) else Vector3.new(ARENA_SIZE, 40, 2)
		local wall = part({
			Name = "Wall",
			Size = size,
			CFrame = CFrame.new(ARENA_CENTER + side * (half + 1) + Vector3.new(0, 20, 0)),
			Transparency = 1,
		})
		wall.Parent = arena
	end

	-- Cover: the same layout every time
	local layout = Random.new(2026)
	for i = 1, 36 do
		local angle = layout:NextNumber() * math.pi * 2
		local radius = layout:NextNumber(25, half - 20)
		local size = Vector3.new(layout:NextNumber(5, 14), layout:NextNumber(4, 10), layout:NextNumber(5, 14))
		local position = ARENA_CENTER + Vector3.new(math.cos(angle) * radius, size.Y / 2, math.sin(angle) * radius)
		local block = part({
			Name = `Cover{i}`,
			Size = size,
			CFrame = CFrame.new(position) * CFrame.Angles(0, layout:NextNumber() * math.pi, 0),
			Color = Color3.fromRGB(110, 110, 115),
			Material = Enum.Material.Concrete,
		})
		block.Parent = arena
	end

	-- Spawn points around the edge, extraction pads at the corners. Spawns sit halfway
	-- between pads so nobody can extract the moment they arrive.
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2 + math.pi / 8
		table.insert(spawnPoints, ARENA_CENTER + Vector3.new(math.cos(angle) * 130, 0, math.sin(angle) * 130))
	end

	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2 + math.pi / 4
		local position = ARENA_CENTER + Vector3.new(math.cos(angle) * 125, 0.3, math.sin(angle) * 125)
		local pad = part({
			Name = "ExtractPad",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 10, 10),
			CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(70, 230, 120),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		pad.Parent = arena
		local prompt = Prompts.Create(pad, { Action = "Extract", Object = "Extraction", Hold = EXTRACT_HOLD })
		prompt.Triggered:Connect(extract)
	end

	-- Chests: more in the outer ring, better ones in the center
	local chestSpots: { MobSpawn } = {}
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2 + 0.3
		table.insert(chestSpots, {
			Position = ARENA_CENTER + Vector3.new(math.cos(angle) * 95, 0, math.sin(angle) * 95),
			Zone = "Outer",
		})
	end
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		table.insert(chestSpots, {
			Position = ARENA_CENTER + Vector3.new(math.cos(angle) * 25, 0, math.sin(angle) * 25),
			Zone = "Center",
		})
	end
	for _, spot in chestSpots do
		local rare = spot.Zone == "Center"
		local chest = part({
			Name = `{spot.Zone}Chest`,
			Size = Vector3.new(3, 2.4, 2),
			CFrame = CFrame.new(spot.Position + Vector3.new(0, 1.2, 0)),
			Color = if rare then Color3.fromRGB(80, 60, 140) else Color3.fromRGB(130, 85, 45),
			Material = Enum.Material.WoodPlanks,
		})
		chest.Parent = arena
		local prompt =
			Prompts.Create(chest, { Action = "Open", Object = if rare then "Rare chest" else "Chest", Hold = 1.2 })
		prompt.Triggered:Connect(function(player)
			if not isInRaid(player) or not prompt.Enabled then
				return
			end
			prompt.Enabled = false
			chest.Transparency = 0.8
			local loot = rollLoot(CHEST_LOOT[spot.Zone])
			for itemId, count in loot do
				WarzoneService.AddToBag(player, itemId, count)
			end
			StateService.Notify(player, `Found {describe(loot)}`, "good")
			QuestService.Record(player, "OpenChest")
			task.delay(CHEST_RESPAWN, function()
				chest.Transparency = 0
				prompt.Enabled = true
			end)
		end)
	end

	-- Mob spawns: slimes in the outer ring, brutes in the center
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		table.insert(mobSpawns, {
			Position = ARENA_CENTER + Vector3.new(math.cos(angle) * 80, 0, math.sin(angle) * 80),
			Zone = "Outer",
		})
	end
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2 + 0.4
		table.insert(mobSpawns, {
			Position = ARENA_CENTER + Vector3.new(math.cos(angle) * 35, 0, math.sin(angle) * 35),
			Zone = "Center",
		})
	end

	arena.Parent = workspace
end

-- Sparkles drifting up through the portal plus a purple glow
local function addPortalEffects(surface: BasePart)
	surface.Material = Enum.Material.Neon
	surface.Color = Color3.fromRGB(140, 80, 255)
	surface.Transparency = 0.3
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 110, 255)
	light.Range = 18
	light.Brightness = 2
	light.Parent = surface

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(Color3.fromRGB(200, 160, 255), Color3.fromRGB(120, 80, 255))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkles.Transparency = NumberSequence.new(0.2)
	sparkles.Lifetime = NumberRange.new(1.2, 2)
	sparkles.Rate = 18
	sparkles.Speed = NumberRange.new(1, 2.5)
	sparkles.SpreadAngle = Vector2.new(25, 25)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Parent = surface
end

local function buildPortal(player: Player, island: IslandService.Island)
	local position = island.Center + PORTAL_OFFSET
	local model = Props.Place("Portal", position, island.Spawn.Position, island.Model)
	local portal: BasePart
	if model then
		model.Name = "WarzonePortal"
		portal = Props.Part(model, "PortalSurface") :: BasePart
		addPortalEffects(portal)
	else
		portal = part({
			Name = "WarzonePortal",
			Size = Vector3.new(6, 8, 1),
			CFrame = CFrame.new(position + Vector3.new(0, 4, 0)),
			Color = Color3.fromRGB(150, 70, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.25,
			CanCollide = false,
		})
		portal.Parent = island.Model
	end
	local prompt = Prompts.Create(portal, {
		Action = "Enter Warzone",
		Object = `Warzone (level {Leveling.WarzoneLevel}+)`,
		Hold = 0.5,
		Distance = 12,
	})
	Prompts.OnTriggeredBy(prompt, player, function()
		enter(player)
	end)
end

function WarzoneService.Start()
	buildArena()
	IslandService.OnIslandCreated(buildPortal)

	local function track(player: Player)
		player:SetAttribute("InWarzone", false)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end
	for _, player in Players:GetPlayers() do
		track(player)
	end
	Players.PlayerAdded:Connect(track)

	-- Leaving the game mid-raid drops your bag for others, so logging out can't save it
	Players.PlayerRemoving:Connect(function(player: Player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		dropBag(player, if root and root:IsA("BasePart") then root.Position else nil)
	end)
end

return WarzoneService
