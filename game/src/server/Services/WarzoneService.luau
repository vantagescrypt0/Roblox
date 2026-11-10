--!strict
-- The Warzone: its own place, PvP across a net of floating islands (Worlds/Warzone), reached by
-- jumping into the void pit in Town (player level 10). The rules are yours ([[Warzone]]):
--   You arrive in the citadel, where nobody can hurt you; anywhere else, anyone can.
--   Hitting someone or being hit tags you for 20 seconds, and while tagged you can't leave.
--   Leaving is a button only this place has: hold it, and everyone nearby hears you going.
--   Fall off and you're back where you left the ground, with a little ticking poison.
--   Die and your body stays where you fell with everything you had (BodyService), and you're back in
--   Town. Jump back in within its 15 minutes and you land on this server (TravelService).
--   Quit and you have 5 minutes: any place you rejoin sends you straight back to this server and
--   spot (TravelService). Miss them and your body drops there. Quit while tagged and it drops at once.
--   Quit in the citadel, untagged, and you're simply safe.
--   A hunger bar drains as you run and fight, and only counts here. Health only regrows while
--   you're well fed, and at empty hunger you slowly lose it. Food is a crop in your hand: click.
--   Your shield (worn from the Bag) blocks every hit from the front while you hold right-click,
--   and you walk slowly while it's up.
-- Chests are in LootChestService, Skydrops in SkydropService.
-- The numbers not in your rules (how fast hunger drains, how much poison) are Claude's picks.

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Boosts = require(ReplicatedStorage.Shared.Boosts)
local Foods = require(ReplicatedStorage.Shared.Foods)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Items = require(ReplicatedStorage.Shared.Items)
local KitPowers = require(ReplicatedStorage.Shared.KitPowers)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Ambience = require(script.Parent.Parent.Util.Ambience)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local KitSets = require(script.Parent.Parent.Util.KitSets)
local Metrics = require(script.Parent.Parent.Util.Metrics)
local Move = require(script.Parent.Parent.Util.Move)
local Pace = require(script.Parent.Parent.Util.Pace)
local ShieldModel = require(script.Parent.Parent.Util.ShieldModel)
local Spawning = require(script.Parent.Parent.Util.Spawning)
local Speed = require(script.Parent.Parent.Util.Speed)
local Context = require(script.Parent.Parent.Worlds.Context)
local Warzone = require(script.Parent.Parent.Worlds.Warzone)
local AwardService = require(script.Parent.AwardService)
local BodyService = require(script.Parent.BodyService)
local ChestService = require(script.Parent.ChestService)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)
local TravelService = require(script.Parent.TravelService)

local SIZE = Blocks.Size
local CENTER = Vector3.new(0, 200, 0) -- top of the citadel's ground
local FALL_LIMIT = 230 -- below every island's rock
local COMBAT_TAG = 20
local LEAVE_HOLD = 7
local LEAVE_SOUND = "rbxassetid://15675046931" -- Roblox_UI_Sweep
local LEAVE_SOUND_RANGE = 220
local STUDIO_BACK_IN = 3 -- seconds; Studio can't travel to Town, so a test goes straight back in
local GROUND_SEARCH = 120 -- studs below where you fell to look for ground for your body
local SEND_TRIES = 3
local BACK_TOPIC = "WarzoneBack"

local TICK = 0.25
-- Hunger, out of 100, per second: a full bar lasts about 10 minutes of running
local HUNGER_MOVING = 0.16
local HUNGER_STILL = 0.04
local HUNGER_PER_SWING = 0.5
local WELL_FED = 60 -- health regrows at or above this
local REGEN_PER_SECOND = 1
local HUNGER_PER_HEALTH = 0.25 -- what regrowing one health costs
local STARVE_PER_SECOND = 0.5
local STARVE_FLOOR = 10 -- starving alone won't take you below this
local HUNGRY_WARNING = 25
local EAT_TIME = 1.2

local POISON_TIME = 8
local POISON_PER_SECOND = 2 -- 16 health in all; it never kills

local BLOCK_SOUND = "rbxassetid://9113447467" -- Blacksmith Anvil Hammer Hits

local WarzoneService = {}

-- Changed only by Studio tests
local rejoinTime = 5 * 60
local rejoinGrace = 20 -- seconds more, for someone already on their way back

-- Someone who quit away from the citadel: what would drop if they don't come back in time, by user id
type Quitter = {
	Name: string,
	Stacks: { Inventory.Stack },
	Worn: { string },
	Copy: Model?,
	At: Vector3,
	Facing: Vector3,
}

local arrival: CFrame
local quitters: { [number]: Quitter } = {}
local leaving: { [Player]: Sound } = {}
local hunger: { [Player]: number } = {}
local warned: { [Player]: boolean } = {}
local poisonUntil: { [Player]: number } = {}
local poisonRate: { [Player]: number } = {}
local lastGround: { [Player]: Vector3 } = {}
local blockingSpeed: { [Player]: boolean } = {}
local eating: { [Player]: {} } = {}
-- Left through the button or by dying, so there's nothing to come back to
local leftOnPurpose: { [Player]: boolean } = {}

function WarzoneService.IsPlaying(player: Player): boolean
	local data = DataService.GetData(player)
	return player:GetAttribute("InWarzone") == true and data ~= nil and data.Raid.Active
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function isSafeSpot(position: Vector3): boolean
	local flat = Vector3.new(position.X - CENTER.X, 0, position.Z - CENTER.Z)
	return flat.Magnitude <= Warzone.SafeRadius * SIZE
end

local function inSafeZone(player: Player): boolean
	local root = rootOf(player)
	return root == nil or isSafeSpot(root.Position)
end

-- Can this player hurt that one? Both must be in the Warzone, outside the citadel
function WarzoneService.CanHit(attacker: Player, victim: Player): boolean
	return WarzoneService.IsPlaying(attacker)
		and WarzoneService.IsPlaying(victim)
		and not inSafeZone(attacker)
		and not inSafeZone(victim)
end

local function playSound(parent: Instance, soundId: string, volume: number)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.RollOffMaxDistance = 120
	sound.Parent = parent
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
end

-- Hunger ------------------------------------------------------------------------------

local function setHunger(player: Player, value: number)
	local amount = math.clamp(value, 0, 100)
	hunger[player] = amount
	-- Only whole numbers go to the client
	local shown = math.ceil(amount)
	if player:GetAttribute("Hunger") ~= shown then
		player:SetAttribute("Hunger", shown)
	end
	if amount >= HUNGRY_WARNING then
		warned[player] = nil
	elseif not warned[player] then
		warned[player] = true
		StateService.Notify(player, "You're getting hungry! Hold food and click to eat", "bad")
	end
end

-- Of all the hunger they lose: the Warzone tree's second boost halves it
local function hungerScale(player: Player): number
	return if Boosts.Has(DataService.GetData(player), "Warzone", 2) then Boosts.HungerScale else 1
end

-- Swinging a sword makes you hungrier
function WarzoneService.Exert(player: Player)
	if hunger[player] then
		setHunger(player, hunger[player] - HUNGER_PER_SWING * hungerScale(player))
	end
end

-- Burning hunger on anything else that tires you, like sprinting
function WarzoneService.Burn(player: Player, amount: number)
	if hunger[player] then
		setHunger(player, hunger[player] - amount * hungerScale(player))
	end
end

-- Health: 100, or 130 with the Warzone tree's last boost (three more hearts)
local function maxHealthOf(player: Player): number
	return 100 + (if Boosts.Has(DataService.GetData(player), "Warzone", 5) then Boosts.ExtraHealth else 0)
end

local function fitHealth(player: Player, refill: boolean)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local most = maxHealthOf(player)
	local wasFull = humanoid.Health >= humanoid.MaxHealth
	if humanoid.MaxHealth ~= most then
		humanoid.MaxHealth = most
	end
	humanoid.Health = if refill or wasFull then most else math.min(humanoid.Health, most)
end

-- Clicking with food in your hand: a moment later it's eaten, if nothing interrupted you
function WarzoneService.Eat(player: Player, itemId: string)
	local value = Foods[itemId]
	if not value or eating[player] or blockingSpeed[player] or not WarzoneService.IsPlaying(player) then
		return
	end
	if (hunger[player] or 0) >= 99 then
		StateService.Notify(player, "You're full", "info")
		return
	end
	local token = {}
	eating[player] = token
	task.delay(EAT_TIME, function()
		if eating[player] ~= token then
			return
		end
		eating[player] = nil
		local character = player.Character
		local tool = character and character:FindFirstChildOfClass("Tool")
		if tool and tool:GetAttribute("Held") == itemId and InventoryService.Remove(player, itemId, 1) then
			setHunger(player, (hunger[player] or 0) + value)
			StateService.Notify(player, `Ate {Items[itemId].Name}: +{value} hunger`, "good")
		end
	end)
end

-- Poison ------------------------------------------------------------------------------

-- Poison never kills. A full set of Venomfang keeps it out altogether.
function WarzoneService.Poison(player: Player, seconds: number, perSecond: number)
	if KitSets.Wearing(player) == "Venomfang" then
		return
	end
	poisonUntil[player] = os.clock() + seconds
	poisonRate[player] = perSecond
	player:SetAttribute("PoisonUntil", workspace:GetServerTimeNow() + seconds)
end

-- Falling: back where you left the ground, poisoned
local function onFell(player: Player, character: Model)
	local root = rootOf(player)
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
	end
	local spot = lastGround[player]
	if not spot or not WarzoneService.IsPlaying(player) then
		Move.To(character, arrival)
		return
	end
	local facing = if root then root.CFrame.LookVector * Vector3.new(1, 0, 1) else Vector3.zAxis
	if facing.Magnitude < 0.1 then
		facing = Vector3.zAxis
	end
	Move.To(character, CFrame.lookAt(spot + Vector3.new(0, 1, 0), spot + Vector3.new(0, 1, 0) + facing))
	WarzoneService.Poison(player, POISON_TIME, POISON_PER_SECOND)
	if KitSets.Wearing(player) ~= "Venomfang" then
		StateService.Notify(player, "You fell! Poison ticks away your health for a few seconds", "bad")
	end
end

-- Blocking ----------------------------------------------------------------------------

function WarzoneService.IsBlocking(player: Player): boolean
	return blockingSpeed[player] ~= nil
end

local function stopBlocking(player: Player)
	if not blockingSpeed[player] then
		return
	end
	blockingSpeed[player] = nil
	player:SetAttribute("Blocking", nil)
	Speed.Apply(player)
	if player.Character then
		ShieldModel.SetRaised(player.Character, false)
	end
end

local function startBlocking(player: Player)
	local data = DataService.GetData(player)
	local humanoid = humanoidOf(player)
	if not data or data.Equipped.Shield == "" or not humanoid or humanoid.Health <= 0 then
		return
	end
	if blockingSpeed[player] or not WarzoneService.IsPlaying(player) then
		return
	end
	eating[player] = nil
	blockingSpeed[player] = true
	player:SetAttribute("Blocking", true)
	Speed.Apply(player)
	if player.Character then
		ShieldModel.SetRaised(player.Character, true)
	end
end

-- A hit from `from` on someone who may be blocking: true if the shield stopped it
function WarzoneService.Blocks(victim: Player, from: Vector3): boolean
	local root = rootOf(victim)
	if not blockingSpeed[victim] or not root then
		return false
	end
	local toAttacker = (from - root.Position) * Vector3.new(1, 0, 1)
	if toAttacker.Magnitude < 0.01 or root.CFrame.LookVector:Dot(toAttacker.Unit) <= 0 then
		return false
	end
	playSound(root, BLOCK_SOUND, 0.6)
	QuestService.Record(victim, "BlockHit")
	return true
end

-- Leaving -----------------------------------------------------------------------------

local function stopLeaving(player: Player)
	local sound = leaving[player]
	if sound then
		leaving[player] = nil
		sound:Destroy()
		player:SetAttribute("LeavingUntil", nil)
	end
end

local function tagLeft(player: Player): number
	local untilTime = player:GetAttribute("CombatTag")
	if typeof(untilTime) ~= "number" then
		return 0
	end
	return math.max(0, untilTime - workspace:GetServerTimeNow())
end

-- A hit tags whoever gave or took it, stops them leaving and interrupts eating
function WarzoneService.Tag(player: Player)
	player:SetAttribute("CombatTag", workspace:GetServerTimeNow() + COMBAT_TAG)
	stopLeaving(player)
	eating[player] = nil
end

local function finishLeaving(player: Player)
	stopLeaving(player)
	if RunService:IsStudio() then
		StateService.Notify(player, "You'd be back in Town now (Studio can't travel)", "info")
		local character = player.Character
		if character then
			Move.To(character, arrival)
		end
	else
		leftOnPurpose[player] = true
		TravelService.Go(player, "Town")
		-- If the teleport failed they're still here, and quitting counts again
		task.delay(15, function()
			leftOnPurpose[player] = nil
		end)
	end
end

local function startLeaving(player: Player)
	if leaving[player] or not WarzoneService.IsPlaying(player) then
		return
	end
	local left = tagLeft(player)
	if left > 0 then
		StateService.Notify(player, `You're in combat! You can leave in {math.ceil(left)}s`, "bad")
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	-- Played on the character, so everyone nearby hears it
	local sound = Instance.new("Sound")
	sound.Name = "Leaving"
	sound.SoundId = LEAVE_SOUND
	sound.Looped = true
	sound.Volume = 1
	sound.RollOffMaxDistance = LEAVE_SOUND_RANGE
	sound.Parent = root
	sound:Play()
	leaving[player] = sound
	local hold = if Boosts.Has(DataService.GetData(player), "Warzone", 1) then Boosts.LeaveSeconds else LEAVE_HOLD
	player:SetAttribute("LeavingFor", hold)
	player:SetAttribute("LeavingUntil", workspace:GetServerTimeNow() + hold)
	task.delay(hold, function()
		if leaving[player] == sound then
			finishLeaving(player)
		end
	end)
end

-- Taking players in and out --------------------------------------------------------

local function enter(player: Player)
	local data = DataService.GetData(player)
	local character = player.Character
	if not data or not character or WarzoneService.IsPlaying(player) then
		return
	end
	local back = data.Rejoin
	local quitter = quitters[player.UserId]
	local returning = quitter ~= nil or back.Until > os.time()
	if quitter then
		quitters[player.UserId] = nil
		if quitter.Copy then
			quitter.Copy:Destroy()
		end
	elseif returning then
		-- Back in time, but on another server (that one's full now): it mustn't drop their body
		task.spawn(pcall, function()
			MessagingService:PublishAsync(BACK_TOPIC, player.UserId)
		end)
	end
	if not Leveling.CanEnterWarzone(player, data.Level) and not returning then
		StateService.Notify(player, `The Warzone unlocks at level {Leveling.WarzoneLevel}`, "bad")
		TravelService.Go(player, "Town")
		return
	end
	data.Raid.Active = true
	data.Raid.Bag = {}
	player:SetAttribute("InWarzone", true)
	Metrics.Event(player, "WarzoneEntered")
	AwardService.Give(player, "WarzoneEntered")
	if returning then
		local spot = Vector3.new(back.X, back.Y, back.Z)
		Move.To(character, CFrame.new(spot))
		lastGround[player] = spot
		setHunger(player, back.Hunger)
		StateService.Notify(player, "You're back where you left off", "level")
	else
		Move.To(character, arrival)
		setHunger(player, 100)
		StateService.Notify(player, "Welcome to the Warzone! The citadel is safe. Everywhere else isn't.", "level")
	end
	back.Until = 0
	DataService.MarkChanged(player)
end

-- Back to Town after you die
local function goHome(player: Player)
	if RunService:IsStudio() then
		task.delay(STUDIO_BACK_IN, enter, player)
	else
		TravelService.Go(player, "Town")
	end
end

local function endRun(player: Player)
	local data = DataService.GetData(player)
	stopLeaving(player)
	stopBlocking(player)
	player:SetAttribute("InWarzone", false)
	player:SetAttribute("CombatTag", nil)
	player:SetAttribute("PoisonUntil", nil)
	eating[player] = nil
	poisonUntil[player] = nil
	hunger[player] = nil
	if data then
		data.Raid.Active = false
		data.Rejoin.Until = 0
		DataService.MarkChanged(player)
	end
end

-- The ground under where someone went down: straight below, or if that's the void, where they last stood
local function groundFor(player: Player, position: Vector3?): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace:FindFirstChild("World") :: Instance }
	local function below(from: Vector3?): Vector3?
		local hit = from and workspace:Raycast(from, Vector3.new(0, -GROUND_SEARCH, 0), params)
		return hit and hit.Position
	end
	return below(position) or below(lastGround[player]) or arrival.Position - Vector3.new(0, 4, 0)
end

-- Everything you had goes onto your body, here and now. It can't wait: this also runs as you leave.
local function dropNow(player: Player, data: DataService.Data, character: Model?, position: Vector3?, facing: Vector3)
	local stacks, worn = InventoryService.TakeEverything(data)
	if #stacks > 0 then
		data.Body.JobId = game.JobId
		data.Body.Until = os.time() + BodyService.Lifetime()
	end
	DataService.MarkChanged(player)
	task.spawn(BodyService.Drop, {
		UserId = player.UserId,
		Name = player.DisplayName,
		Stacks = stacks,
		Worn = worn,
		Copy = BodyService.Copy(character),
		At = groundFor(player, position),
		Facing = facing,
	})
end

local function facingOf(root: BasePart?): Vector3
	return if root then root.CFrame.LookVector else Vector3.zAxis
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	fitHealth(player, true)
	-- Your body's laid down from a copy, so it needs its joints
	humanoid.BreakJointsOnDeath = false
	humanoid.Died:Connect(function()
		if not WarzoneService.IsPlaying(player) then
			return
		end
		Metrics.Event(player, "WarzoneDied")
		local data = DataService.GetData(player)
		local root = rootOf(player)
		ChestService.CloseFor(player)
		if data then
			dropNow(player, data, character, root and root.Position, facingOf(root))
		end
		BodyService.Hide(character)
		endRun(player)
		StateService.Notify(player, "You died! Your body stays here for 15 minutes with everything you had", "bad")
		local killerId = humanoid:GetAttribute("LastAttacker")
		local killer = if typeof(killerId) == "number" then Players:GetPlayerByUserId(killerId) else nil
		if killer and killer ~= player then
			StateService.Notify(killer, `You took down {player.DisplayName}!`, "good")
			QuestService.Record(killer, "PvPKill")
		end
	end)
end

-- Missed the 5 minutes: the body drops, and what's on it comes off them wherever they are, now or the
-- next time they join. If this server closes first nothing happens, and they keep it all.
local function dropForQuitter(userId: number, quitter: Quitter)
	task.spawn(BodyService.Drop, {
		UserId = userId,
		Name = quitter.Name,
		Stacks = quitter.Stacks,
		Worn = quitter.Worn,
		Copy = quitter.Copy,
		At = quitter.At,
		Facing = quitter.Facing,
	})
	local message = { Kind = "BodyDropped", JobId = game.JobId, Until = os.time() + BodyService.Lifetime() }
	for try = 1, SEND_TRIES do
		if DataService.SendMessage(userId, message) then
			return
		end
		task.wait(try * 2)
	end
	warn(`[Warzone] couldn't tell user {userId} their body dropped`)
end

-- Quitting: runs before the save closes. Tagged, your body drops at once. In the citadel you're safe.
-- Otherwise it writes down where you were, for when you come back, and starts your 5 minutes.
local function onLeaving(player: Player, data: DataService.Data)
	if leftOnPurpose[player] or not WarzoneService.IsPlaying(player) then
		return
	end
	data.Raid.Active = false
	data.Rejoin.Until = 0
	local root = rootOf(player)
	local position = (root and root.Position) or lastGround[player]
	local facing = facingOf(root)
	local character = player.Character
	if tagLeft(player) > 0 then
		dropNow(player, data, character, position, facing)
		return
	end
	if not position or isSafeSpot(position) then
		return
	end
	local spot = lastGround[player] or position
	data.Rejoin = {
		JobId = game.JobId,
		Until = os.time() + rejoinTime,
		X = spot.X,
		Y = spot.Y + 4,
		Z = spot.Z,
		Hunger = hunger[player] or 100,
	}
	local stacks, worn = InventoryService.Everything(data)
	local userId = player.UserId
	local quitter: Quitter = {
		Name = player.DisplayName,
		Stacks = stacks,
		Worn = worn,
		Copy = BodyService.Copy(character),
		At = groundFor(player, position),
		Facing = facing,
	}
	quitters[userId] = quitter
	task.delay(rejoinTime + rejoinGrace, function()
		if quitters[userId] == quitter then
			quitters[userId] = nil
			dropForQuitter(userId, quitter)
		end
	end)
end

-- For Studio tests only: how long a quitter has, in seconds
function WarzoneService.SetRejoinTime(seconds: number, grace: number)
	rejoinTime = seconds
	rejoinGrace = grace
end

-- For testing in Studio, where nobody can really quit and come back: goes through the same
-- steps as quitting here and rejoining this server `away` seconds later (1 if not given)
function WarzoneService.TestQuit(player: Player, away: number?)
	local data = DataService.GetData(player)
	if not data or not WarzoneService.IsPlaying(player) then
		return
	end
	onLeaving(player, data)
	local saved = table.clone(data.Rejoin)
	endRun(player)
	data.Rejoin = saved
	local character = player.Character
	if character then
		Move.To(character, arrival)
	end
	task.delay(away or 1, enter, player)
end

function WarzoneService.SetHunger(player: Player, value: number)
	setHunger(player, value)
end

-- The clock: hunger, health, poison and remembering the last ground under your feet ----

local function tick(player: Player, params: RaycastParams)
	local humanoid = humanoidOf(player)
	local root = rootOf(player)
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end
	params.FilterDescendantsInstances = { player.Character :: Model }
	local below = workspace:Raycast(root.Position, Vector3.new(0, -7, 0), params)
	if below then
		lastGround[player] = below.Position + Vector3.new(0, 3, 0)
	end

	local moving = (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude > 2
	local scale = hungerScale(player)
	local food = (hunger[player] or 100) - (if moving then HUNGER_MOVING else HUNGER_STILL) * TICK * scale
	local health = humanoid.Health
	local poisoned = os.clock() < (poisonUntil[player] or 0)
	if poisoned then
		health = math.max(1, health - (poisonRate[player] or POISON_PER_SECOND) * TICK)
	elseif food >= WELL_FED and health < humanoid.MaxHealth then
		local sunBlessed = KitSets.Wearing(player) == "Sunforged"
		local boosted = Boosts.Has(DataService.GetData(player), "Warzone", 3)
		local rate = REGEN_PER_SECOND
			* (if sunBlessed then KitPowers.RegenScale else 1)
			* (if boosted then Boosts.RegenScale else 1)
		local gain = math.min(rate * TICK, humanoid.MaxHealth - health)
		health += gain
		if not sunBlessed then
			food -= gain * HUNGER_PER_HEALTH * scale
		end
	elseif food <= 0 and health > STARVE_FLOOR then
		health = math.max(STARVE_FLOOR, health - STARVE_PER_SECOND * TICK)
	end
	if health ~= humanoid.Health then
		humanoid.Health = health
	end
	setHunger(player, food)
	if not poisoned and poisonUntil[player] then
		poisonUntil[player] = nil
		poisonRate[player] = nil
		player:SetAttribute("PoisonUntil", nil)
	end
end

local function runClock()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	while true do
		task.wait(TICK)
		for _, player in Players:GetPlayers() do
			if WarzoneService.IsPlaying(player) then
				tick(player, params)
			end
		end
	end
end

-- The map ---------------------------------------------------------------------------

local function buildMap(): SpawnLocation
	local world = BlockWorld.new(CENTER - Vector3.new(0, SIZE / 2, 0), "World", workspace)
	world.Model:SetAttribute("Kind", "Warzone")
	local decor = Instance.new("Folder")
	decor.Name = "WorldDecor"
	decor.Parent = workspace

	local started = os.clock()
	Pace.Begin()
	local ctx = Context.new(world, decor, Warzone.Seed, Warzone.SouthZ)
	Warzone.Build(ctx)
	BlockWorld.drawAll(world, true)
	Pace.Finish()
	print(
		`[World] Warzone: built in {string.format("%.1f", os.clock() - started)}s,`,
		`{BlockWorld.partCount(world)} block parts, {#decor:GetDescendants()} decor instances`
	)

	-- The client shows which zone you're in from these
	workspace:SetAttribute("WarzoneCenter", CENTER)
	workspace:SetAttribute("WarzoneSafeRadius", Warzone.SafeRadius * SIZE)

	local spot = Warzone.Arrival
	local feet = ctx.Top(spot.X, spot.Y, spot.Z)
	arrival = CFrame.lookAt(feet + Vector3.new(0, 4, 0), feet + Vector3.new(0, 4, -10))
	return Spawning.MakeSpawn(feet, -Vector3.zAxis, world.Model)
end

function WarzoneService.Start()
	Ambience.Warzone()
	-- Roblox's own script regrows everyone's health all the time. Here hunger decides: an empty
	-- script of the same name takes its place.
	local noRegen = Instance.new("Script")
	noRegen.Name = "Health"
	noRegen.Parent = StarterPlayer:WaitForChild("StarterCharacterScripts")

	local spawnPoint = buildMap()

	local arrived: { [Player]: boolean } = {}
	Spawning.Start(spawnPoint, CENTER.Y - FALL_LIMIT, function(player)
		arrived[player] = true
		enter(player)
	end, onFell)

	local function track(player: Player)
		player:SetAttribute("InWarzone", false)
		-- Their crystals arrive with their save, and can move while they're here
		player:GetAttributeChangedSignal("BoostWarzone"):Connect(function()
			fitHealth(player, false)
		end)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
			-- Back on your feet after dying: that's your run over
			if arrived[player] then
				goHome(player)
			end
		end)
	end
	for _, player in Players:GetPlayers() do
		track(player)
	end
	Players.PlayerAdded:Connect(track)

	Remotes.LeaveWarzone.OnServerEvent:Connect(function(player: Player, holding: unknown)
		if holding == true then
			startLeaving(player)
		else
			stopLeaving(player)
		end
	end)
	Remotes.Block.OnServerEvent:Connect(function(player: Player, holding: unknown)
		if holding == true then
			startBlocking(player)
		else
			stopBlocking(player)
		end
	end)

	DataService.OnLeaving(onLeaving)
	task.spawn(pcall, function()
		MessagingService:SubscribeAsync(BACK_TOPIC, function(message: any)
			local quitter = quitters[message.Data]
			if quitter then
				quitters[message.Data] = nil
				if quitter.Copy then
					quitter.Copy:Destroy()
				end
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		-- A moment later, so the save's last look at them sees them as they were
		task.delay(1, function()
			leaving[player] = nil
			arrived[player] = nil
			hunger[player] = nil
			warned[player] = nil
			poisonUntil[player] = nil
			poisonRate[player] = nil
			lastGround[player] = nil
			blockingSpeed[player] = nil
			eating[player] = nil
			leftOnPurpose[player] = nil
		end)
	end)

	task.spawn(runClock)
end

return WarzoneService
