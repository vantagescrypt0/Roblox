--!strict
-- Skydrops (your rules, [[Warzone]]): chests that fall from the sky onto the inner islands, not far from the citadel
-- but not next to it. Anyone can take what's in them, and an emptied one vanishes, like any Warzone chest.
--   A regular one is a chest with gold sparkles, every 10 minutes, and everyone gets a marker to it.
--   A Legendary one is a chest with purple sparkles, every 4 to 8 hours, with no marker. It stays sealed, with a
--   health bar over it: hold mine with a pickaxe and it cracks like a block, but stays there and the bar goes down.
--   At zero it opens, and it's up for grabs. Claude's picks: a line on everyone's screen when one falls (the
--   Legendary's doesn't say where), the bar is the same for everyone and never grows back, and only a pickaxe mines.
-- The numbers are in shared/Skydrops.luau, what they hold in shared/WarzoneLoot.luau, and the fall and marker on each
-- screen in client/SkydropController.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Skydrops = require(ReplicatedStorage.Shared.Skydrops)
local WarzoneLoot = require(ReplicatedStorage.Shared.WarzoneLoot)
local Warzone = require(script.Parent.Parent.Worlds.Warzone)
local AwardService = require(script.Parent.AwardService)
local ChestService = require(script.Parent.ChestService)
local LootChestService = require(script.Parent.LootChestService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)
local WarzoneService = require(script.Parent.WarzoneService)

type Kind = "Skydrop" | "Legendary"
type Sealed = { Part: BasePart, Chest: ChestService.Chest, Fill: Frame, Label: TextLabel, Left: number, Most: number }

local WHITE = Color3.new(1, 1, 1)
local INNER_ISLANDS = 180 -- blocks from the middle: the nine nearest islands
local BAR_RANGE = 70 -- studs: no further, or the bar would be its marker
local OPENED_RANGE = 120 -- studs: who hears it's open
local BAR_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local OPEN_SOUND = "rbxassetid://15675043410" -- Roblox_UI_Tonal_Stinger
local QUICKEST = 0.85 -- of a crack's time: the server's allowance for a laggy click

local SkydropService = {}

local rng = Random.new()
local count = 0
local regulars: { { Chest: ChestService.Chest, Remove: () -> () } } = {}
local sealed: { [string]: Sealed } = {}
local legendaryOut = false
local lastCrack: { [Player]: number } = {}
local markers: Folder

local function addSparkles(part: BasePart, color: Color3, rate: number, rise: number)
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkles"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(color:Lerp(WHITE, 0.45), color)
	sparkles.LightEmission = 1
	sparkles.LightInfluence = 0
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(1.2, 2.6)
	sparkles.Rate = rate
	sparkles.Speed = NumberRange.new(0.5, 2)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	-- Up the world, whichever way the mesh's own axes run
	sparkles.Acceleration = Vector3.new(0, rise, 0)
	sparkles.Parent = part
end

local function playSound(part: BasePart, soundId: string)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.8
	sound.RollOffMaxDistance = 220
	sound.Parent = part
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

-- The health bar over a sealed chest. The chest's model is the same as any other's.
local function addBar(part: BasePart): (Frame, TextLabel)
	local board = Instance.new("BillboardGui")
	board.Name = "HealthBar"
	board.Size = UDim2.fromOffset(230, 48)
	board.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	board.MaxDistance = BAR_RANGE
	board.LightInfluence = 0
	board.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 24)
	label.BackgroundTransparency = 1
	label.FontFace = BAR_FONT
	label.Text = "Legendary Skydrop"
	label.TextColor3 = Skydrops.Purple:Lerp(WHITE, 0.45)
	label.TextStrokeTransparency = 0.35
	label.TextSize = 18
	label.Parent = board
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.fromOffset(0, 28)
	track.Size = UDim2.new(1, 0, 0, 16)
	track.BackgroundColor3 = Color3.fromRGB(16, 18, 30)
	track.BackgroundTransparency = 0.15
	track.BorderSizePixel = 0
	track.Parent = board
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Skydrops.Purple
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner:Clone().Parent = fill
	return fill, label
end

local function tellEveryone(text: string)
	for _, player in Players:GetPlayers() do
		StateService.Notify(player, text, "level")
	end
end

local function innerIslands(): { Warzone.IslandSpot }
	local list = {}
	for _, island in Warzone.IslandSpots() do
		if math.sqrt(island.X * island.X + island.Z * island.Z) <= INNER_ISLANDS then
			table.insert(list, island)
		end
	end
	return list
end

local function findLanding(): CFrame?
	local list = innerIslands()
	for _ = 1, 20 do
		local spot = LootChestService.FindSpot(list[rng:NextInteger(1, #list)])
		if spot then
			return spot
		end
	end
	return nil
end

local function addMarker(id: string, position: Vector3, landsAt: number)
	local marker = Instance.new("Vector3Value")
	marker.Name = id
	marker.Value = position
	marker:SetAttribute("LandsAt", landsAt)
	marker.Parent = markers
end

local function removeMarker(id: string)
	local marker = markers:FindFirstChild(id)
	if marker then
		marker:Destroy()
	end
end

-- Drops one now. `cracks` shortens a Legendary's bar, for tests.
function SkydropService.Drop(kind: Kind, cracks: number?): boolean
	local template = ReplicatedStorage:WaitForChild("Blocks"):FindFirstChild("LootChest")
	local spot = findLanding()
	if not template or not template:IsA("BasePart") or not spot then
		warn(`[Skydrop] nowhere to land a {kind}`)
		return false
	end
	if kind == "Legendary" and legendaryOut then
		return false
	end
	count += 1
	local id = `sky{count}`
	local landsAt = workspace:GetServerTimeNow() + Skydrops.FallTime
	local part = template:Clone()
	part.Name = if kind == "Legendary" then "LegendarySkydrop" else "Skydrop"
	part:PivotTo(spot)
	part:SetAttribute("ChestId", id)
	part:SetAttribute("LandsAt", landsAt)
	if kind == "Legendary" then
		addSparkles(part, Skydrops.Purple, 80, 8)
	else
		addSparkles(part, Skydrops.Gold, 45, 6)
	end

	local slots = Inventory.EmptyOf(Inventory.ChestSize)
	LootChestService.Refill(slots, kind)
	local chest: ChestService.Chest
	local gone = false
	local function remove()
		if gone then
			return
		end
		gone = true
		ChestService.CloseAll(chest)
		LootChestService.Remove(id)
		removeMarker(id)
		sealed[id] = nil
		if kind == "Legendary" then
			legendaryOut = false
		else
			for index, entry in regulars do
				if entry.Chest == chest then
					table.remove(regulars, index)
					break
				end
			end
		end
		part:Destroy()
	end
	chest = {
		Id = id,
		Title = if kind == "Legendary" then "Legendary Skydrop" else "Skydrop",
		Slots = slots,
		Part = part,
		Position = spot.Position,
		Viewers = {},
		OnChanged = function(self: ChestService.Chest)
			for _, stack in self.Slots do
				if stack.Count > 0 then
					return
				end
			end
			remove()
		end,
		CanOpen = function(player: Player): boolean
			if workspace:GetServerTimeNow() < landsAt then
				return false
			end
			if sealed[id] then
				StateService.Notify(player, "It's sealed! Hold mine on it with a pickaxe", "bad")
				return false
			end
			return true
		end,
		OnFirstOpen = function(player: Player)
			QuestService.Record(player, "OpenSkydrop")
		end,
	}
	if kind == "Legendary" then
		legendaryOut = true
		local most = cracks or Skydrops.Cracks
		part:SetAttribute("Sealed", true)
		local fill, label = addBar(part)
		sealed[id] = { Part = part, Chest = chest, Fill = fill, Label = label, Left = most, Most = most }
		tellEveryone("A Legendary Skydrop has fallen somewhere. Find it!")
	else
		table.insert(regulars, { Chest = chest, Remove = remove })
		if #regulars > Skydrops.MostOut then
			regulars[1].Remove()
		end
		addMarker(id, spot.Position, landsAt)
		tellEveryone("A Skydrop is falling!")
	end
	part.Parent = LootChestService.Folder()
	LootChestService.Add(chest)
	return true
end

local function open(entry: Sealed, player: Player)
	local id = entry.Chest.Id
	sealed[id] = nil
	entry.Part:SetAttribute("Sealed", nil)
	entry.Fill.Parent = nil
	entry.Label.Text = "Legendary Skydrop: open!"
	playSound(entry.Part, OPEN_SOUND)
	local sparkles = entry.Part:FindFirstChild("Sparkles")
	if sparkles and sparkles:IsA("ParticleEmitter") then
		sparkles.Rate = 150
	end
	QuestService.Record(player, "BreakLegendary")
	AwardService.Give(player, "Legendary")
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - entry.Part.Position).Magnitude <= OPENED_RANGE then
			StateService.Notify(other, `{player.DisplayName} broke the Legendary Skydrop open! Grab it!`, "level")
		end
	end
end

-- One finished crack, from someone mining a sealed chest
local function onMine(player: Player, id: unknown)
	local entry = if type(id) == "string" then sealed[id] else nil
	if not entry or player:GetAttribute("InWarzone") ~= true then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end
	if (root.Position - entry.Part.Position).Magnitude > Blocks.Reach + 3 then
		return
	end
	local landsAt = entry.Part:GetAttribute("LandsAt")
	if type(landsAt) ~= "number" or workspace:GetServerTimeNow() < landsAt then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	local held = tool and tool:GetAttribute("Held")
	local crackTime = Skydrops.CrackTime(if type(held) == "string" then held else nil)
	if not crackTime then
		StateService.Notify(player, "You need a pickaxe to mine this", "bad")
		return
	end
	local now = os.clock()
	if now - (lastCrack[player] or 0) < crackTime * QUICKEST then
		return
	end
	lastCrack[player] = now
	WarzoneService.Exert(player)
	entry.Left -= 1
	entry.Fill.Size = UDim2.fromScale(math.max(entry.Left, 0) / entry.Most, 1)
	if entry.Left <= 0 then
		open(entry, player)
	end
end

function SkydropService.Start()
	markers = Instance.new("Folder")
	markers.Name = "SkydropMarkers"
	markers.Parent = ReplicatedStorage
	Remotes.MineSkydrop.OnServerEvent:Connect(onMine)
	Players.PlayerRemoving:Connect(function(player)
		lastCrack[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(Skydrops.Every)
			SkydropService.Drop("Skydrop")
		end
	end)
	task.spawn(function()
		while true do
			task.wait(math.max(Skydrops.NextLegendary(os.time()) - os.time(), 1))
			SkydropService.Drop("Legendary")
			task.wait(1)
		end
	end)
	-- Checks the table now, not when a chest finally rolls a bad name
	local Items = require(ReplicatedStorage.Shared.Items) :: any
	for kind, loot in WarzoneLoot.Tables do
		for _, entry in loot.Stacks do
			if not Items[entry.Item] then
				warn(`[Skydrop] {kind} loot has an item that doesn't exist: {entry.Item}`)
			end
		end
	end
end

return SkydropService
