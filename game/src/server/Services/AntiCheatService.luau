--!strict
-- The anti-cheat, as you set it (2026-11-09): someone caught doing what the game can't is pulled back to where they
-- last legitimately were, and kicked if it keeps happening. Nobody is banned automatically: that's an admin's call.
-- Autoclickers are fine (the server already caps how fast blocks break), so there's no bot hunting.
--   Movement   faster than they can walk or sprint (allowing for lag catching up), higher than a jump, hanging in
--              the air, or into or through solid blocks. Water, knockback and the server's own moves
--              (Util/Move.luau) are allowed for, and Config.Flyers aren't checked.
--   Requests   each player can only send so many requests a second, of each kind and in all.
-- Admins see strikes and catches, and kick, ban and unban, through AdminService (its panel and chat commands).
-- Every catch counts in the player's save (data.AntiCheat), which /flags shows.
-- Studio, from the Server command bar: workspace:SetAttribute("AntiCheatOff", true) pauses the movement checks, for
-- tests that move characters by hand; workspace:SetAttribute("AntiCheatTestOwner", true) checks Config.Flyers too,
-- since Studio plays as the owner.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Move = require(script.Parent.Parent.Util.Move)
local DataService = require(script.Parent.DataService)

local AntiCheatService = {}

-- Movement
local CHECK_EVERY = 0.1 -- seconds between checks
local SPEED_SCALE = 1.15 -- on top of their speed, for timing differences
local SPEED_SLACK = 6 -- studs, the same
local CATCH_UP = 1.5 -- seconds of moving that a lag spike can deliver at once
local SPEED_LINGERS = 1 -- seconds a higher speed still counts after the server lowers it
local JUMP_SLACK = 2.5 -- studs above a jump's height
local HOVER_TIME = 2 -- seconds in the air without coming down
local FALL_STEP = 1.5 -- studs down that count as coming down
local PUSH_CARRY = 0.6 -- a knockback carries them this many seconds of its sideways speed
local PUSH_TIME = 1.5 -- seconds a knockback's rise and hang are allowed for
local SPAWN_GRACE = 3 -- seconds after a character appears
local PLACED_GRACE = 1.5 -- after the server moves someone: where they were can still arrive for a moment
local PULLED_GRACE = 0.75 -- the same after a pull back
local GRACE_REACH = 6 -- studs from where they were put, plus how far they could have walked since, that counts as there
local HISTORY = 10 -- checks of where they've been: too fast puts them back where they were a second ago
local THROUGH_STEP = 3 -- studs: a step at least this long is checked for passing through blocks between checks
local PROBE = Vector3.new(0.5, 0.5, 0.5) -- the point tested for being inside a block
local FEET = Vector3.new(2.2, 0.2, 1.6) -- the box swept down to find what they stand on
local WATER_ABOVE = 40 -- studs: under water this far down still counts as in it (a pool's inner blocks have no part)
local WATER_NEAR = 4 -- studs
-- Strikes
local SAME_INCIDENT = 2 -- seconds: catches this close together count once
local STRIKES_TO_KICK = 5
local STRIKE_WEARS_OFF = 30 -- seconds for one strike to be forgotten
-- Requests, per player: each kind of request, and all of them together
local PER_KIND = { Burst = 40, PerSecond = 20 }
local ALL_KINDS = { Burst = 150, PerSecond = 60 }
local FLOOD = 400 -- requests in one second: no real player sends this many, so it's a kick at once

type Track = {
	Character: Model,
	Root: BasePart,
	Humanoid: Humanoid,
	Trusted: CFrame, -- where they last legitimately were
	Ground: CFrame, -- where they last stood
	GroundY: number,
	Last: Vector3,
	LastCheck: number,
	Budget: number, -- studs they may still cover across before it's too fast
	TopSpeed: number,
	TopSpeedUntil: number,
	AirMarkY: number?, -- in the air: the height they last came down past
	AirMarkAt: number,
	PushUntil: number,
	PushRise: number,
	GraceUntil: number,
	GraceTarget: Vector3?, -- where the server put them (nil after spawning: anywhere goes)
	GraceStart: number,
	Pulled: boolean, -- the grace is after a pull back
	History: { CFrame }, -- where they've legitimately been, oldest first
	Feet: RaycastParams,
}
type Record = { Strikes: number, LastStrike: number, Reason: string, Kicked: boolean }
type Bucket = { Tokens: number, At: number }
type Rule = { Burst: number, PerSecond: number }

local tracks: { [Player]: Track } = {}
local records: { [Player]: Record } = {}
local buckets: { [Player]: { [string]: Bucket } } = {}
local perSecond: { [Player]: { Second: number, Count: number } } = {}
local waters: { Instance } = {}
local watersDirty = true

local function paused(): boolean
	return RunService:IsStudio() and Workspace:GetAttribute("AntiCheatOff") == true
end

-- Flyers move however they like, except in a Studio test of the anti-cheat itself
local function exempt(player: Player): boolean
	return Config.Flyers[player.UserId] == true
		and not (RunService:IsStudio() and Workspace:GetAttribute("AntiCheatTestOwner") == true)
end

local function recordOf(player: Player): Record
	local record = records[player]
	if not record then
		record = { Strikes = 0, LastStrike = -math.huge, Reason = "", Kicked = false }
		records[player] = record
	end
	return record
end

local function kick(player: Player, reason: string)
	local record = recordOf(player)
	if record.Kicked then
		return
	end
	record.Kicked = true
	local data = DataService.GetData(player)
	if data then
		data.AntiCheat.Kicks += 1
	end
	warn(`[AntiCheat] kicked {player.Name} ({player.UserId}): {reason}`)
	player:Kick(`Skycore removed you from this server for {reason}. If that was a mistake, just rejoin.`)
end

-- One catch: a strike, forgotten over time, and a kick when they pile up
local function strike(player: Player, reason: string)
	local record = recordOf(player)
	local now = os.clock()
	if now - record.LastStrike < SAME_INCIDENT then
		return
	end
	record.Strikes = math.max(0, record.Strikes - (now - record.LastStrike) / STRIKE_WEARS_OFF) + 1
	record.LastStrike = now
	record.Reason = reason
	local data = DataService.GetData(player)
	if data then
		data.AntiCheat.Flags += 1
		data.AntiCheat.Last = reason
		data.AntiCheat.LastAt = os.time()
	end
	warn(`[AntiCheat] {player.Name} ({player.UserId}): {reason} (strike {math.floor(record.Strikes * 10) / 10})`)
	if record.Strikes >= STRIKES_TO_KICK then
		kick(player, reason)
	end
end

-- Movement ------------------------------------------------------------------------------------------------------

local function jumpHeight(humanoid: Humanoid): number
	if humanoid.UseJumpPower then
		return humanoid.JumpPower ^ 2 / (2 * Workspace.Gravity)
	end
	return humanoid.JumpHeight
end

local function speedOf(track: Track): number
	return math.max(track.TopSpeed, track.Humanoid.WalkSpeed) * SPEED_SCALE
end

local function budgetCap(track: Track): number
	return speedOf(track) * CATCH_UP + SPEED_SLACK
end

-- Characters, monsters and bodies move, so they never count as walls
local function movingThings(): { Instance }
	local list: { Instance } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	for _, name in { "Mobs", "Bodies" } do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			table.insert(list, folder)
		end
	end
	return list
end

-- Inside a solid block (or a box-shaped solid part). Only shapes whose box is exact are tested, so a building's
-- doorway never counts as inside it.
local function solidAt(at: Vector3, overlap: OverlapParams): boolean
	for _, part in Workspace:GetPartBoundsInBox(CFrame.new(at), PROBE, overlap) do
		local exact = (part:IsA("Part") and part.Shape == Enum.PartType.Block)
			or (part:IsA("MeshPart") and part.CollisionFidelity == Enum.CollisionFidelity.Box)
		if exact and part.CanCollide then
			local inside = part.CFrame:PointToObjectSpace(at)
			local half = part.Size / 2
			if math.abs(inside.X) < half.X and math.abs(inside.Y) < half.Y and math.abs(inside.Z) < half.Z then
				return true
			end
		end
	end
	return false
end

local function blocked(from: Vector3, to: Vector3, rays: RaycastParams): boolean
	return Workspace:Raycast(from, to - from, rays) ~= nil
end

-- A long step whose every way round is blocked went through something. Walking round a corner, or jumping up
-- onto a block, always leaves one of these ways clear.
local function wentThrough(from: Vector3, to: Vector3, rays: RaycastParams): boolean
	if not blocked(from, to, rays) then
		return false
	end
	local high = math.max(from.Y, to.Y)
	for _, via in
		{
			Vector3.new(to.X, from.Y, from.Z),
			Vector3.new(from.X, from.Y, to.Z),
			Vector3.new(from.X, high, from.Z),
			Vector3.new(to.X, high, to.Z),
		}
	do
		if not blocked(from, via, rays) and not blocked(via, to, rays) then
			return false
		end
	end
	return true
end

local function waterParts(): { Instance }
	if watersDirty then
		watersDirty = false
		table.clear(waters)
		for _, part in CollectionService:GetTagged("Water") do
			if part:IsA("BasePart") and part:IsDescendantOf(Workspace) then
				table.insert(waters, part)
			end
		end
	end
	return waters
end

-- In the water, as client/SwimController sees it: near a water part, or under one with nothing solid between
local function inWater(at: Vector3, rays: RaycastParams): boolean
	local list = waterParts()
	if #list == 0 then
		return false
	end
	local near = OverlapParams.new()
	near.FilterType = Enum.RaycastFilterType.Include
	near.FilterDescendantsInstances = list
	if #Workspace:GetPartBoundsInRadius(at, WATER_NEAR, near) > 0 then
		return true
	end
	local up = RaycastParams.new()
	up.FilterType = Enum.RaycastFilterType.Include
	up.FilterDescendantsInstances = list
	local water = Workspace:Raycast(at, Vector3.new(0, WATER_ABOVE, 0), up)
	return water ~= nil and not blocked(at, water.Position, rays)
end

local function standing(track: Track): boolean
	local reach = track.Root.Size.Y / 2 + track.Humanoid.HipHeight + 1.5
	return Workspace:Blockcast(track.Root.CFrame, FEET, Vector3.new(0, -reach, 0), track.Feet) ~= nil
end

local function settle(track: Track, at: CFrame)
	track.Trusted = at
	track.History = { at }
	track.Ground = at
	track.GroundY = at.Position.Y
	track.Last = at.Position
	track.Budget = budgetCap(track)
	track.AirMarkY = nil
end

-- A moment after the server puts someone somewhere, while their game catches up with it
local function beginGrace(track: Track, to: CFrame, seconds: number, pulled: boolean)
	settle(track, to)
	local now = os.clock()
	track.GraceUntil = now + seconds
	track.GraceTarget = to.Position
	track.GraceStart = now
	track.Pulled = pulled
end

local function pullBack(player: Player, track: Track, to: CFrame, reason: string)
	beginGrace(track, to, PULLED_GRACE, true)
	track.Root.AssemblyLinearVelocity = Vector3.zero
	track.Character:PivotTo(to)
	strike(player, reason)
end

local function check(player: Player, track: Track, overlap: OverlapParams, rays: RaycastParams)
	local root, humanoid = track.Root, track.Humanoid
	if humanoid.Health <= 0 or not root:IsDescendantOf(Workspace) then
		return
	end
	local now = os.clock()
	local dt = now - track.LastCheck
	track.LastCheck = now

	-- How fast they may go: the server's speed for them, and for a moment any higher one it just lowered
	local walk = humanoid.WalkSpeed
	if walk >= track.TopSpeed then
		track.TopSpeed = walk
		track.TopSpeedUntil = now + SPEED_LINGERS
	elseif now > track.TopSpeedUntil then
		track.TopSpeed = walk
	end
	local cap = budgetCap(track)
	if track.Budget < cap then
		track.Budget = math.min(cap, track.Budget + speedOf(track) * dt)
	end

	local at = root.Position
	if now < track.GraceUntil then
		local target = track.GraceTarget
		local near = not target or (at - target).Magnitude <= GRACE_REACH + speedOf(track) * (now - track.GraceStart)
		-- Never inside a block, unless that's where the server put them, and never through one to get there
		local clear = not solidAt(at, overlap) or (target ~= nil and solidAt(target, overlap))
		local open = target == nil or not wentThrough(target, at, rays)
		if near and clear and open then
			settle(track, root.CFrame)
		elseif track.Pulled then
			-- Their game hasn't taken the pull back yet (where they cheated to can still arrive): again, no new strike
			root.AssemblyLinearVelocity = Vector3.zero
			track.Character:PivotTo(track.Trusted)
		end
		return
	end

	-- Too fast (a speed hack, or a teleport)
	local step = at - track.Last
	track.Budget -= Vector3.new(step.X, 0, step.Z).Magnitude
	track.Last = at
	if track.Budget < 0 then
		-- The server smooths a teleport over a frame or two, so the last check may have seen it halfway
		pullBack(player, track, track.History[1] or track.Trusted, "moving faster than possible")
		return
	end

	-- Into or through solid blocks. Someone a block appeared on (a tree, a block placed on them) can walk out.
	local from = track.Trusted.Position
	if solidAt(at, overlap) and not solidAt(from, overlap) then
		pullBack(player, track, track.Trusted, "going through blocks")
		return
	end
	if (at - from).Magnitude >= THROUGH_STEP and wentThrough(from, at, rays) then
		pullBack(player, track, track.Trusted, "going through blocks")
		return
	end

	-- Higher than a jump, or hanging in the air
	if standing(track) then
		track.Ground = root.CFrame
		track.GroundY = at.Y
		track.AirMarkY = nil
	elseif inWater(at, rays) then
		track.GroundY = at.Y
		track.AirMarkY = nil
	else
		local pushed = now < track.PushUntil
		local rise = at.Y - track.GroundY
		if rise > jumpHeight(humanoid) + JUMP_SLACK + (if pushed then track.PushRise else 0) then
			pullBack(player, track, track.Ground, "flying")
			return
		end
		local mark = track.AirMarkY
		if not mark or at.Y < mark - FALL_STEP then
			track.AirMarkY = at.Y
			track.AirMarkAt = now
		elseif now - track.AirMarkAt > HOVER_TIME and not pushed then
			pullBack(player, track, track.Ground, "flying")
			return
		end
	end
	track.Trusted = root.CFrame
	table.insert(track.History, root.CFrame)
	if #track.History > HISTORY then
		table.remove(track.History, 1)
	end
end

local function watch(player: Player, character: Model)
	tracks[player] = nil
	if exempt(player) then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not root or not root:IsA("BasePart") or not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	if player.Character ~= character then
		return
	end
	local feet = RaycastParams.new()
	feet.FilterType = Enum.RaycastFilterType.Exclude
	feet.FilterDescendantsInstances = { character }
	feet.RespectCanCollide = true
	local track: Track = {
		Character = character,
		Root = root,
		Humanoid = humanoid,
		Trusted = root.CFrame,
		Ground = root.CFrame,
		GroundY = root.Position.Y,
		Last = root.Position,
		LastCheck = os.clock(),
		Budget = 0,
		TopSpeed = humanoid.WalkSpeed,
		TopSpeedUntil = 0,
		AirMarkY = nil,
		AirMarkAt = 0,
		PushUntil = 0,
		PushRise = 0,
		GraceUntil = os.clock() + SPAWN_GRACE,
		GraceTarget = nil,
		GraceStart = os.clock(),
		Pulled = false,
		History = { root.CFrame },
		Feet = feet,
	}
	track.Budget = budgetCap(track)
	tracks[player] = track
end

-- Requests ------------------------------------------------------------------------------------------------------

local function take(bucket: Bucket, rule: Rule, now: number): boolean
	bucket.Tokens = math.clamp(bucket.Tokens + (now - bucket.At) * rule.PerSecond, -rule.Burst, rule.Burst) - 1
	bucket.At = now
	return bucket.Tokens >= 0
end

local function onRequest(player: Player, kind: string)
	local mine = buckets[player]
	local count = perSecond[player]
	if not mine or not count then
		return
	end
	local now = os.clock()
	local second = math.floor(now)
	if count.Second ~= second then
		count.Second = second
		count.Count = 0
	end
	count.Count += 1
	if count.Count >= FLOOD then
		kick(player, "sending too many requests")
		return
	end
	local ofKind = mine[kind]
	if not ofKind then
		ofKind = { Tokens = PER_KIND.Burst, At = now }
		mine[kind] = ofKind
	end
	local all = mine["*"]
	local okKind = take(ofKind, PER_KIND, now)
	local okAll = take(all, ALL_KINDS, now)
	if not okKind or not okAll then
		strike(player, "sending too many requests")
	end
end

-- For the admin panel and /flags (AdminService) ----------------------------------------------------------------

-- How many strikes someone has right now, after wearing off
function AntiCheatService.Strikes(player: Player): number
	local record = records[player]
	if not record then
		return 0
	end
	return math.max(0, record.Strikes - (os.clock() - record.LastStrike) / STRIKE_WEARS_OFF)
end

-- Start ---------------------------------------------------------------------------------------------------------

function AntiCheatService.Start()
	CollectionService:GetInstanceAddedSignal("Water"):Connect(function()
		watersDirty = true
	end)
	CollectionService:GetInstanceRemovedSignal("Water"):Connect(function()
		watersDirty = true
	end)

	Move.OnPlaced(function(player, to)
		local track = tracks[player]
		if track then
			beginGrace(track, to, PLACED_GRACE, false)
		end
	end)
	Move.OnPushed(function(player, velocity)
		local track = tracks[player]
		if track then
			local now = os.clock()
			local up = math.max(velocity.Y, 0)
			track.PushRise =
				math.max(if now < track.PushUntil then track.PushRise else 0, up ^ 2 / (2 * Workspace.Gravity) + 1)
			track.PushUntil = now + PUSH_TIME
			track.AirMarkAt = now
			track.Budget += Vector3.new(velocity.X, 0, velocity.Z).Magnitude * PUSH_CARRY + 2
		end
	end)

	local function onPlayer(player: Player)
		buckets[player] = { ["*"] = { Tokens = ALL_KINDS.Burst, At = os.clock() } }
		perSecond[player] = { Second = 0, Count = 0 }
		player.CharacterAdded:Connect(function(character)
			watch(player, character)
		end)
		player.CharacterRemoving:Connect(function()
			tracks[player] = nil
		end)
		if player.Character then
			task.spawn(watch, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		tracks[player] = nil
		records[player] = nil
		buckets[player] = nil
		perSecond[player] = nil
	end)
	if RunService:IsStudio() then
		Workspace:GetAttributeChangedSignal("AntiCheatTestOwner"):Connect(function()
			for _, player in Players:GetPlayers() do
				if player.Character then
					task.spawn(watch, player, player.Character)
				end
			end
		end)
	end

	-- Every request from a client counts toward that player's limits
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	for _, remote in folder:GetChildren() do
		if remote:IsA("RemoteEvent") then
			local kind = remote.Name
			remote.OnServerEvent:Connect(function(player)
				onRequest(player, kind)
			end)
		end
	end

	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.RespectCanCollide = true
	local rays = RaycastParams.new()
	rays.FilterType = Enum.RaycastFilterType.Exclude
	rays.RespectCanCollide = true
	local since = 0
	RunService.Heartbeat:Connect(function(dt)
		since += dt
		if since < CHECK_EVERY then
			return
		end
		since = 0
		if paused() then
			for _, track in tracks do
				track.GraceUntil = os.clock() + PLACED_GRACE
				track.GraceTarget = nil
			end
			return
		end
		local moving = movingThings()
		overlap.FilterDescendantsInstances = moving
		rays.FilterDescendantsInstances = moving
		for player, track in tracks do
			check(player, track, overlap, rays)
		end
	end)
end

return AntiCheatService
