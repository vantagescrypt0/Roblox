--!strict
-- Warzone monsters. Each type needs a minimum Combat level to damage, and drops
-- Combat XP, player XP and loot into the killer's raid bag.

local Players = game:GetService("Players")

local ProgressionService = require(script.Parent.ProgressionService)
local StateService = require(script.Parent.StateService)
local WarzoneService = require(script.Parent.WarzoneService)

type LootEntry = { Item: string, Min: number, Max: number, Chance: number }

type MobType = {
	Name: string,
	Zone: string,
	CombatLevel: number,
	Health: number,
	Damage: number,
	Speed: number,
	Size: Vector3,
	Color: Color3,
	CombatXP: number,
	PlayerXP: number,
	Loot: { LootEntry },
}

local MOB_TYPES: { MobType } = {
	{
		Name = "Slime",
		Zone = "Outer",
		CombatLevel = 1,
		Health = 40,
		Damage = 6,
		Speed = 10,
		Size = Vector3.new(3, 2.4, 3),
		Color = Color3.fromRGB(90, 200, 90),
		-- Rough, for the 2026-10-27 XP curves; fit with tools/balance.py when the Warzone opens
		CombatXP = 100,
		PlayerXP = 33,
		Loot = { { Item = "Scrap", Min = 1, Max = 1, Chance = 0.6 } },
	},
	{
		Name = "Brute",
		Zone = "Center",
		CombatLevel = 5,
		Health = 140,
		Damage = 14,
		Speed = 13,
		Size = Vector3.new(3.5, 5, 2.5),
		Color = Color3.fromRGB(150, 50, 50),
		CombatXP = 400,
		PlayerXP = 130,
		Loot = {
			{ Item = "Scrap", Min = 2, Max = 4, Chance = 1 },
			{ Item = "Crystal", Min = 1, Max = 1, Chance = 0.4 },
		},
	},
}

local AGGRO_RANGE = 45
local LEASH_RANGE = 60
local ATTACK_COOLDOWN = 1
local RESPAWN_TIME = 20
local TICK = 0.3

type Mob = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Type: MobType,
	Home: Vector3,
	LastAttack: number,
	LastHitBy: Player?,
}

local MobService = {}

local rng = Random.new()
local mobs: { [Model]: Mob } = {}
local folder: Folder
local lastWarning: { [Player]: number } = {}

local function spawnMob(mobType: MobType, home: Vector3)
	local model = Instance.new("Model")
	model.Name = mobType.Name
	model:SetAttribute("Mob", true)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = mobType.Size
	root.Color = mobType.Color
	root.Material = Enum.Material.SmoothPlastic
	root.CFrame = CFrame.new(home + Vector3.new(0, mobType.Size.Y / 2 + 0.5, 0))
	root.Parent = model

	-- The name and health bar show above the "Head"
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Transparency = 1
	head.CanCollide = false
	head.Massless = true
	head.CFrame = root.CFrame * CFrame.new(0, mobType.Size.Y / 2 + 0.5, 0)
	head.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = root

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = mobType.Health
	humanoid.Health = mobType.Health
	humanoid.WalkSpeed = mobType.Speed
	humanoid.HipHeight = 0.1
	humanoid.DisplayName = `{mobType.Name} [Combat {mobType.CombatLevel}]`
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.Parent = model

	model.PrimaryPart = root
	model.Parent = folder
	root:SetNetworkOwner(nil)

	local mob: Mob = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Type = mobType,
		Home = home,
		LastAttack = 0,
		LastHitBy = nil,
	}
	mobs[model] = mob

	humanoid.Died:Connect(function()
		mobs[model] = nil
		local killer = mob.LastHitBy
		if killer and killer.Parent == Players then
			ProgressionService.AddSkillXP(killer, "Combat", mobType.CombatXP)
			ProgressionService.AddPlayerXP(killer, mobType.PlayerXP)
			for _, entry in mobType.Loot do
				if rng:NextNumber() < entry.Chance then
					WarzoneService.AddToBag(killer, entry.Item, rng:NextInteger(entry.Min, entry.Max))
				end
			end
			StateService.Notify(killer, `Defeated a {mobType.Name}!`, "good")
		end
		task.delay(1, function()
			model:Destroy()
		end)
		task.delay(RESPAWN_TIME, spawnMob, mobType, home)
	end)
end

-- Called by combat when a player hits a mob
function MobService.Damage(model: Model, attacker: Player, amount: number)
	local mob = mobs[model]
	if not mob or mob.Humanoid.Health <= 0 then
		return
	end
	local combatLevel = ProgressionService.GetSkillLevel(attacker, "Combat")
	if combatLevel < mob.Type.CombatLevel then
		local now = os.clock()
		if now - (lastWarning[attacker] or 0) > 2 then
			lastWarning[attacker] = now
			StateService.Notify(
				attacker,
				`You need Combat level {mob.Type.CombatLevel} to fight a {mob.Type.Name}`,
				"bad"
			)
		end
		return
	end
	mob.LastHitBy = attacker
	mob.Humanoid:TakeDamage(amount)
end

local function nearestTarget(mob: Mob): (Humanoid?, BasePart?, number)
	local best, bestRoot, bestDistance = nil, nil, AGGRO_RANGE
	for _, player in Players:GetPlayers() do
		if not WarzoneService.IsInRaid(player) then
			continue
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			local distance = (root.Position - mob.Root.Position).Magnitude
			if distance < bestDistance then
				best, bestRoot, bestDistance = humanoid, root, distance
			end
		end
	end
	return best, bestRoot, bestDistance
end

local function think(mob: Mob, now: number)
	if mob.Humanoid.Health <= 0 then
		return
	end
	local target, targetRoot, distance = nearestTarget(mob)
	local fromHome = (mob.Root.Position - mob.Home).Magnitude

	if target and targetRoot and fromHome < LEASH_RANGE then
		mob.Humanoid:MoveTo(targetRoot.Position)
		local reach = math.max(mob.Type.Size.X, mob.Type.Size.Z) / 2 + 3
		if distance <= reach and now - mob.LastAttack >= ATTACK_COOLDOWN then
			mob.LastAttack = now
			target:TakeDamage(mob.Type.Damage)
		end
	elseif fromHome > 4 then
		mob.Humanoid:MoveTo(mob.Home)
	end
end

function MobService.Start()
	folder = Instance.new("Folder")
	folder.Name = "Mobs"
	folder.Parent = workspace

	for _, spot in WarzoneService.GetMobSpawns() do
		for _, mobType in MOB_TYPES do
			if mobType.Zone == spot.Zone then
				spawnMob(mobType, spot.Position)
			end
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		lastWarning[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(TICK)
			local now = os.clock()
			for _, mob in mobs do
				think(mob, now)
			end
		end
	end)
end

return MobService
