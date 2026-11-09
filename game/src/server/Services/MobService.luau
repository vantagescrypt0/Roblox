--!strict
-- Monsters (Monsters.luau), real meshes made in Studio: they live in the Slaying World's zones
-- (SlayingService) and beside spawners on your own island (SpawnerService). None in the Warzone:
-- it's PvP (your call, 2026-11-02).
--
-- A monster stands around near home, wandering a little. Slimes leave you alone until you hit
-- them; the others come for you when you get close, hit for a little damage, and give up and go
-- home if you run too far. You need the monster's Combat level to hurt it. Killing it pays Combat
-- and player XP, its drop straight into your Bag, counts toward the Combat challenges, and in
-- the Slaying World sometimes gives a sliver (Slivers.luau). Nothing is lost when one kills you.
--
-- Each is a Humanoid with an invisible box for a body (what you aim at and bump into) and the
-- mesh welded to it. MobController swings and bobs the mesh on your own screen, and fades it when
-- it dies; the server only says where it is, so idle monsters cost next to nothing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Items = require(ReplicatedStorage.Shared.Items)
local Monsters = require(ReplicatedStorage.Shared.Monsters)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Slivers = require(ReplicatedStorage.Shared.Slivers)
local MonsterModels = require(script.Parent.Parent.Util.MonsterModels)
local AwardService = require(script.Parent.AwardService)
local ChallengeService = require(script.Parent.ChallengeService)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

local TICK = 0.25
local WAKE_RANGE = 140 -- nobody this close and it goes to sleep (anchored, thinking nothing)
local AGGRO_RANGE = 26
local LEASH_RANGE = 62 -- further than this from home and it gives up
local ATTACK_COOLDOWN = 2
local ATTACK_WINDUP = 0.35 -- how long you've got to step back once it swings
local KNOCK_AWAY, KNOCK_UP = 16, 20 -- what a hit from a monster does to you
local ANGRY_TIME = 10 -- a passive monster you hit fights back this long
local WANDER = 12 -- how far from home it strolls
local WANDER_MIN, WANDER_MAX = 4, 9 -- seconds between strolls
local RESPAWN_WORLD = 18
local FALL_LIMIT = 40 -- this far below home and it's put back
local PLATE_RANGE = 70 -- studs: how far off a monster's name and health bar can be read
local PLATE_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local HEALTH_FULL, HEALTH_LOW = Color3.fromRGB(96, 214, 96), Color3.fromRGB(226, 72, 60)

export type Options = {
	Owner: Player?, -- only they can fight it (a spawner on their island)
	Respawn: number?, -- seconds until the next one; nil = never (the spawner says when)
	Slivers: boolean?, -- in the Slaying World, it can drop a sliver
	OnDied: (() -> ())?,
	-- Would it step here? (keeps it on its own island when something chases it near the edge)
	CanStand: ((position: Vector3) -> boolean)?,
}

type Mob = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Monster: Monsters.Monster,
	Home: Vector3,
	Options: Options,
	Awake: boolean,
	LastAttack: number,
	NextWander: number,
	AngryUntil: number,
	FrozenUntil: number?, -- a kit's Frost Nova: it stands still till then
	LastHitBy: Player?,
	LastMove: number,
	LastAt: Vector3,
}

local MobService = {}

local rng = Random.new()
local mobs: { [Model]: Mob } = {}
local folder: Folder? = nil
local lastWarning: { [Player]: number } = {}
local running = false

local function mobsFolder(): Folder
	if folder then
		return folder
	end
	local made = Instance.new("Folder")
	made.Name = "Mobs"
	made.Parent = workspace
	folder = made
	return made
end

local function warnOnce(player: Player, text: string)
	local now = os.clock()
	if now - (lastWarning[player] or 0) > 2 then
		lastWarning[player] = now
		StateService.Notify(player, text, "bad")
	end
end

-- The reward for the kill
local function reward(mob: Mob, killer: Player)
	local monster = mob.Monster
	ProgressionService.AddSkillXP(killer, "Combat", monster.XP)
	ProgressionService.AddPlayerXP(killer, monster.PlayerXP)
	InventoryService.AddGathered(killer, monster.Drop, 1)
	ChallengeService.Count(killer, monster.Id)
	QuestService.Record(killer, "Kill")
	QuestService.Record(killer, `Kill:{monster.Id}`)
	AwardService.Give(killer, "FirstKill")
	local sliver = Slivers.ByOre[monster.Drop]
	if mob.Options.Slivers and sliver and rng:NextNumber() < sliver.Chance then
		InventoryService.AddGathered(killer, sliver.Item, 1)
		StateService.Notify(killer, `Found a {sliver.Name}! {sliver.Need} craft a {Items[sliver.Node].Name}`, "level")
	end
end

local function sleep(mob: Mob)
	mob.Awake = false
	mob.Humanoid:Move(Vector3.zero)
	mob.Root.AssemblyLinearVelocity = Vector3.zero
	mob.Root.Anchored = true
end

local function wake(mob: Mob)
	mob.Awake = true
	mob.Root.Anchored = false
	mob.Root:SetNetworkOwner(nil)
	mob.LastAt = mob.Root.Position
	mob.LastMove = os.clock()
end

-- A monster that isn't hit stops being angry; everyone else's anger is just being close
local function isAngry(mob: Mob, now: number): boolean
	return now < mob.AngryUntil
end

local function nearest(mob: Mob, range: number): (Player?, Humanoid?, BasePart?, number)
	local bestPlayer, bestHumanoid, bestRoot, bestDistance = nil, nil, nil, range
	local owner = mob.Options.Owner
	for _, player in Players:GetPlayers() do
		if not owner or player == owner then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
				local distance = (root.Position - mob.Root.Position).Magnitude
				if distance < bestDistance then
					bestPlayer, bestHumanoid, bestRoot, bestDistance = player, humanoid, root, distance
				end
			end
		end
	end
	return bestPlayer, bestHumanoid, bestRoot, bestDistance
end

local function protection(player: Player): (number, number)
	local data = DataService.GetData(player)
	if not data then
		return 0, 0
	end
	return Combat.Armor(data.Equipped :: any)
end

local function hurt(mob: Mob, player: Player, humanoid: Humanoid, root: BasePart)
	local points, toughness = protection(player)
	local damage = Combat.Reduce(mob.Monster.Damage, points, toughness)
	humanoid:TakeDamage(damage)
	local flat = (root.Position - mob.Root.Position) * Vector3.new(1, 0, 1)
	local away = if flat.Magnitude > 0.01 then flat.Unit else mob.Root.CFrame.LookVector
	Remotes.Knockback:FireClient(player, away * KNOCK_AWAY + Vector3.new(0, KNOCK_UP, 0))
	Remotes.HitEffect:FireAllClients(root.Parent, "hit")
end

local function swing(mob: Mob, now: number, player: Player, humanoid: Humanoid, root: BasePart)
	mob.LastAttack = now
	mob.Model:SetAttribute("Swings", (mob.Model:GetAttribute("Swings") or 0) :: number + 1)
	task.delay(ATTACK_WINDUP, function()
		if mob.Humanoid.Health > 0 and humanoid.Health > 0 and root.Parent then
			local reach = MobService.ReachOf(mob) + 1.5
			if (root.Position - mob.Root.Position).Magnitude <= reach then
				hurt(mob, player, humanoid, root)
			end
		end
	end)
end

-- How close a monster has to get to hit you: bigger monsters reach further
function MobService.ReachOf(mob: Mob): number
	return math.max(mob.Root.Size.X, mob.Root.Size.Z) / 2 + 3.5
end

-- Stepping: hop over the blocks in the way when it's stopped moving
local function unstick(mob: Mob, now: number)
	if mob.Monster.Hovers then
		return
	end
	if (mob.Root.Position - mob.LastAt).Magnitude > 1 then
		mob.LastAt = mob.Root.Position
		mob.LastMove = now
	elseif now - mob.LastMove > 0.6 then
		mob.Humanoid.Jump = true
		mob.LastMove = now
	end
end

local function wander(mob: Mob, now: number)
	if now < mob.NextWander then
		return
	end
	mob.NextWander = now + rng:NextNumber(WANDER_MIN, WANDER_MAX)
	local angle = rng:NextNumber(0, 2 * math.pi)
	local goal = mob.Home + Vector3.new(math.cos(angle), 0, math.sin(angle)) * rng:NextNumber(3, WANDER)
	if not mob.Options.CanStand or mob.Options.CanStand(goal) then
		mob.Humanoid:MoveTo(goal)
	end
end

local function chase(mob: Mob, now: number, player: Player, humanoid: Humanoid, root: BasePart, distance: number)
	mob.Humanoid:MoveTo(root.Position)
	if mob.Monster.Hops and mob.Humanoid.FloorMaterial ~= Enum.Material.Air then
		mob.Humanoid.Jump = true
	end
	if distance <= MobService.ReachOf(mob) and now - mob.LastAttack >= ATTACK_COOLDOWN then
		swing(mob, now, player, humanoid, root)
	end
end

local function think(mob: Mob, now: number)
	if mob.Humanoid.Health <= 0 then
		return
	end
	if not mob.Awake or now < (mob.FrozenUntil or 0) then
		return
	end
	local position = mob.Root.Position
	if position.Y < mob.Home.Y - FALL_LIMIT then
		mob.Root.AssemblyLinearVelocity = Vector3.zero
		mob.Root.CFrame = CFrame.new(mob.Home + Vector3.new(0, mob.Root.Size.Y, 0))
		return
	end
	local fromHome = (position - mob.Home).Magnitude
	if fromHome > LEASH_RANGE then
		mob.Humanoid:MoveTo(mob.Home)
		mob.AngryUntil = 0
		unstick(mob, now)
		return
	end
	local player, humanoid, root, distance = nearest(mob, AGGRO_RANGE)
	local hunting = player ~= nil and (not mob.Monster.Hops or isAngry(mob, now))
	if hunting and humanoid and root and (not mob.Options.CanStand or mob.Options.CanStand(root.Position)) then
		chase(mob, now, player :: Player, humanoid, root, distance)
		unstick(mob, now)
		return
	end
	if
		mob.Monster.Hops
		and mob.Humanoid.MoveDirection.Magnitude > 0
		and mob.Humanoid.FloorMaterial ~= Enum.Material.Air
	then
		mob.Humanoid.Jump = true
	end
	wander(mob, now)
	unstick(mob, now)
end

-- A monster's name and health bar. Roblox's own never drew over these meshes (seen live,
-- 2026-11-09), so it's our own board, and it's only touched when the monster's health changes.
local function addPlate(head: BasePart, humanoid: Humanoid, monster: Monsters.Monster)
	local board = Instance.new("BillboardGui")
	board.Name = "Nameplate"
	board.Size = UDim2.fromOffset(150, 34)
	board.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
	board.MaxDistance = PLATE_RANGE
	board.LightInfluence = 0
	board.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.FontFace = PLATE_FONT
	label.Text = `{monster.Name} [{monster.Level}]`
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.35
	label.TextSize = 15
	label.Parent = board

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.new(0.1, 0, 0, 23)
	track.Size = UDim2.new(0.8, 0, 0, 9)
	track.BackgroundColor3 = Color3.fromRGB(16, 18, 30)
	track.BackgroundTransparency = 0.15
	track.BorderSizePixel = 0
	track.Parent = board
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner:Clone().Parent = fill

	local function show()
		local share = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		fill.Size = UDim2.fromScale(share, 1)
		fill.BackgroundColor3 = HEALTH_LOW:Lerp(HEALTH_FULL, share)
	end
	show()
	humanoid.HealthChanged:Connect(show)
end

local function build(monster: Monsters.Monster, home: Vector3): (Model, Humanoid, BasePart)
	local template = MonsterModels.Get(monster.Model)
	local size = template.Size * (monster.Height / template.Size.Y)
	local model = Instance.new("Model")
	model.Name = monster.Name
	model:SetAttribute("Mob", true)
	model:SetAttribute("Monster", monster.Id)
	-- With streaming on, the whole monster arrives on a screen at once
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	local rootSize = Vector3.new(size.X * 0.7, size.Y * 0.8, size.Z * 0.7)
	local hover = if monster.Hovers then 3 else 0
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = rootSize
	root.Transparency = 1
	root.CFrame = CFrame.new(home + Vector3.new(0, rootSize.Y / 2 + 0.2 + hover, 0))
	root.Parent = model

	local body = template:Clone() :: MeshPart
	body.Name = "Body"
	body.Size = size
	body.CFrame = root.CFrame * CFrame.new(0, (size.Y - rootSize.Y) / 2, 0)
	body.Anchored = false
	body.Massless = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = true
	body.Parent = model
	local joint = Instance.new("Weld")
	joint.Name = "BodyWeld"
	joint.Part0 = root
	joint.Part1 = body
	joint.C0 = root.CFrame:ToObjectSpace(body.CFrame)
	joint:SetAttribute("Rest", joint.C0)
	joint.Parent = body

	-- The name and health bar hang above this
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Transparency = 1
	head.CanCollide = false
	head.CanQuery = false
	head.CanTouch = false
	head.Massless = true
	head.CFrame = root.CFrame * CFrame.new(0, (size.Y - rootSize.Y) + rootSize.Y / 2 + 0.5, 0)
	head.Parent = model
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = root
	headWeld.Part1 = head
	headWeld.Parent = head

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = monster.Health
	humanoid.Health = monster.Health
	humanoid.WalkSpeed = monster.Speed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 38
	humanoid.HipHeight = 0.2 + hover
	humanoid.BreakJointsOnDeath = false
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model
	addPlate(head, humanoid, monster)

	model.PrimaryPart = root
	return model, humanoid, root
end

local function spawnMob(monster: Monsters.Monster, home: Vector3, options: Options): Model
	local model, humanoid, root = build(monster, home)
	root.Anchored = true -- until someone's near (spawned out of sight)
	model.Parent = mobsFolder()

	local mob: Mob = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Monster = monster,
		Home = home,
		Options = options,
		Awake = false,
		LastAttack = 0,
		NextWander = 0,
		AngryUntil = 0,
		LastHitBy = nil,
		LastMove = 0,
		LastAt = root.Position,
	}
	mobs[model] = mob

	humanoid.Died:Connect(function()
		if mobs[model] ~= mob then
			return
		end
		mobs[model] = nil
		local killer = mob.LastHitBy
		if killer and killer.Parent == Players then
			reward(mob, killer)
		end
		task.delay(0.9, function()
			model:Destroy()
		end)
		if options.OnDied then
			options.OnDied()
		end
		if options.Respawn then
			task.delay(options.Respawn, spawnMob, monster, home, options)
		end
	end)
	return model
end

-- Puts a monster at `home`
function MobService.Spawn(monster: Monsters.Monster, home: Vector3, options: Options): Model
	return spawnMob(monster, home, options)
end

-- A kill-happy player's XP is the same on any server, but a spawner's monsters are only yours
function MobService.Remove(model: Model)
	local mob = mobs[model]
	if mob then
		mobs[model] = nil
		model:Destroy()
	end
end

-- Stops a monster where it stands for a few seconds (a kit's Frost Nova)
function MobService.Freeze(model: Model, seconds: number)
	local mob = mobs[model]
	if mob then
		mob.FrozenUntil = os.clock() + seconds
		mob.Humanoid:MoveTo(mob.Root.Position)
	end
end

-- Called by combat when a player hits a mob
function MobService.Damage(model: Model, attacker: Player, amount: number, from: BasePart?)
	local mob = mobs[model]
	if not mob or mob.Humanoid.Health <= 0 then
		return
	end
	if mob.Options.Owner and mob.Options.Owner ~= attacker then
		warnOnce(attacker, "That one's only for the island's owner")
		return
	end
	local combatLevel = ProgressionService.GetSkillLevel(attacker, "Combat")
	if combatLevel < mob.Monster.Level then
		warnOnce(attacker, `You need Combat level {mob.Monster.Level} to fight a {mob.Monster.Name}`)
		return
	end
	mob.LastHitBy = attacker
	mob.AngryUntil = os.clock() + ANGRY_TIME
	mob.Humanoid:TakeDamage(amount)
	if mob.Humanoid.Health > 0 and from and mob.Awake then
		local flat = (mob.Root.Position - from.Position) * Vector3.new(1, 0, 1)
		if flat.Magnitude > 0.01 then
			mob.Root.AssemblyLinearVelocity = flat.Unit * 26 + Vector3.new(0, 24, 0)
		end
	end
end

local function loop()
	local timer = 0
	while true do
		local dt = task.wait(TICK)
		timer += dt
		local now = os.clock()
		for _, mob in mobs do
			local near = nearest(mob, WAKE_RANGE)
			if near and not mob.Awake then
				wake(mob)
			elseif not near and mob.Awake then
				sleep(mob)
			end
			think(mob, now)
		end
	end
end

-- Runs them; every world or island that has any calls this once
function MobService.Start()
	if running then
		return
	end
	running = true
	mobsFolder()
	Players.PlayerRemoving:Connect(function(player)
		lastWarning[player] = nil
		for model, mob in mobs do
			if mob.Options.Owner == player then
				mobs[model] = nil
				model:Destroy()
			end
		end
	end)
	task.spawn(loop)
end

-- The Slaying World's zones: `spots` is each zone's monster and where they stand
function MobService.StartWorld(zones: { { Monster: Monsters.Monster, Spots: { Vector3 } } })
	MobService.Start()
	for _, zone in zones do
		for _, spot in zone.Spots do
			spawnMob(zone.Monster, spot, { Respawn = RESPAWN_WORLD, Slivers = true })
		end
	end
end

return MobService
