--!strict
-- The Slaying World's rules, on top of WorldService and Worlds/Slaying: each zone has a Combat
-- level to enter, and its gate turns you back at the end of the bridge if you're not there yet. If
-- you die or fall off you come back at the start of the zone you were in, with everything you
-- were carrying; only the Warzone keeps what you drop (no PvP here either).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Monsters = require(ReplicatedStorage.Shared.Monsters)
local Move = require(script.Parent.Parent.Util.Move)
local Spawning = require(script.Parent.Parent.Util.Spawning)
local SlayingWorld = require(script.Parent.Parent.Worlds.Slaying)
local MobService = require(script.Parent.MobService)
local ProgressionService = require(script.Parent.ProgressionService)
local StateService = require(script.Parent.StateService)

local SIZE = Blocks.Size
local CHECK_EVERY = 0.25
local NOTICE_EVERY = 3
-- How far in from an island's edge a zone starts counting: the gates stand right at the edge
local ZONE_MARGIN = -1

type Zone = SlayingWorld.ZoneInfo & { Spawn: SpawnLocation }

local SlayingService = {}

local zones: { Zone } = {}
local current: { [Player]: Zone } = {}
local lastSafe: { [Player]: CFrame } = {}
local lastNotice: { [Player]: number } = {}

-- Which zone a position is on, if any (the bridges between them aren't on one)
local function zoneAt(position: Vector3, centreY: number): Zone?
	local best: Zone? = nil
	local bestDistance = math.huge
	for _, zone in zones do
		local island = zone.Island
		local dx, dz = position.X / SIZE - island.X, position.Z / SIZE - island.Z
		local distance = math.sqrt(dx * dx + dz * dz)
		if distance <= island.Edge(island.X + dx, island.Z + dz) + ZONE_MARGIN and distance < bestDistance then
			best, bestDistance = zone, distance
		end
	end
	return if position.Y > centreY - 60 then best else nil
end

local function allowed(player: Player, zone: Zone): boolean
	return ProgressionService.GetSkillLevel(player, "Combat") >= zone.Zone.Level
end

local function notice(player: Player, text: string)
	local now = os.clock()
	if now - (lastNotice[player] or 0) >= NOTICE_EVERY then
		lastNotice[player] = now
		StateService.Notify(player, text, "bad")
	end
end

local function turnBack(player: Player, character: Model, root: BasePart, zone: Zone)
	notice(player, `{zone.Zone.Name} needs Combat level {zone.Zone.Level}`)
	root.AssemblyLinearVelocity = Vector3.zero
	Move.To(character, lastSafe[player] or (current[player] or zones[1]).Spawn.CFrame + Vector3.new(0, 4, 0))
end

local function checkPlayer(player: Player, centreY: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not root or not root:IsA("BasePart") then
		return
	end
	local zone = zoneAt(root.Position, centreY)
	if zone and not allowed(player, zone) then
		turnBack(player, character, root, zone)
		return
	end
	lastSafe[player] = root.CFrame
	if zone then
		current[player] = zone
	end
end

local function spawnFor(player: Player): SpawnLocation
	return (current[player] or zones[1]).Spawn
end

local function onFell(player: Player, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.AssemblyLinearVelocity = Vector3.zero
		Move.To(character, spawnFor(player).CFrame + Vector3.new(0, 4, 0))
	end
end

-- Makes the zones' spawn points, runs the gates and brings the monsters out. Returns who to
-- respawn where and what to do with someone who falls off, for Spawning.Start.
function SlayingService.Setup(parent: Instance, centreY: number): ((Player) -> SpawnLocation, (Player, Model) -> ())
	for _, info in SlayingWorld.Layout do
		local zone = info :: Zone
		zone.Spawn = Spawning.MakeSpawn(info.Start, info.StartFacing, parent)
		zone.Spawn.Name = `{info.Zone.Id}Spawn`
		table.insert(zones, zone)
	end

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CHECK_EVERY then
			return
		end
		elapsed = 0
		for _, player in Players:GetPlayers() do
			checkPlayer(player, centreY)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		current[player] = nil
		lastSafe[player] = nil
		lastNotice[player] = nil
	end)

	local mobZones: { { Monster: Monsters.Monster, Spots: { Vector3 } } } = {}
	for _, zone in zones do
		table.insert(mobZones, { Monster = Monsters.ById[zone.Zone.Monster], Spots = zone.MobSpots })
	end
	MobService.StartWorld(mobZones)
	return spawnFor, onFell
end

return SlayingService
