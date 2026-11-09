--!strict
-- The armour kits' specials and set bonuses (KitPowers.luau). The client says "I right-clicked with this sword" and who's
-- under its aim; everything else is checked and worked out here. Hits go through CombatService's own rules, so nobody
-- can be hurt where they couldn't be hit by a sword, and a raised shield stops a special too.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KitPowers = require(ReplicatedStorage.Shared.KitPowers)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local KitSets = require(script.Parent.Parent.Util.KitSets)
local Speed = require(script.Parent.Parent.Util.Speed)
local MobService = require(script.Parent.MobService)
local StateService = require(script.Parent.StateService)
local WarzoneService = require(script.Parent.WarzoneService)

local FRONT = 0.2 -- how far round you someone can be and still count as ahead of you, when nobody's aimed at
local FLARE_KNOCKBACK = 70
local NOVA_KNOCKBACK = 6
local LIGHTNING_KNOCKBACK = 12
local POISON_TICK = 0.5

type HitFn = (
	player: Player,
	root: BasePart,
	model: Model,
	damage: number,
	speed: number,
	effect: string,
	pierce: boolean?
) -> boolean
type Poisoned = { Until: number, By: Player, PerSecond: number }

local KitPowerService = {}

local hit: HitFn
local readyAt: { [Player]: number } = {}
local rageUntil: { [Player]: number } = {}
local venomUntil: { [Player]: number } = {}
local shockedAt: { [Player]: number } = {}
local poisoned: { [Model]: Poisoned } = {}
local tokens: { [Player]: { [string]: {} } } = {}

local function parts(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character and humanoid and root and root:IsA("BasePart") and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return nil, nil, nil
end

local function heldSpecial(character: Model): KitPowers.Special?
	local tool = character:FindFirstChildOfClass("Tool")
	local item = tool and tool:GetAttribute("Held")
	return if type(item) == "string" then KitPowers.Swords[item] else nil
end

-- Someone a special may land on: another player, a monster, or Studio's practice dummy. Shopkeepers aren't.
local function isTarget(player: Player, model: Model): boolean
	if model == player.Character then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or not model:FindFirstChild("HumanoidRootPart") then
		return false
	end
	if model:GetAttribute("Mob") then
		return true
	end
	if model:GetAttribute("Dummy") then
		return RunService:IsStudio()
	end
	local victim = Players:GetPlayerFromCharacter(model)
	return victim ~= nil and WarzoneService.CanHit(player, victim)
end

local function near(player: Player, centre: Vector3, radius: number, skip: { [Model]: boolean }?): { Model }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Model }
	local seen: { [Model]: boolean } = {}
	local found: { Model } = {}
	for _, part in workspace:GetPartBoundsInRadius(centre, radius, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not seen[model] and not (skip and skip[model]) then
			seen[model] = true
			if isTarget(player, model) then
				table.insert(found, model)
			end
		end
	end
	return found
end

local function rootOf(model: Model): BasePart
	return model:FindFirstChild("HumanoidRootPart") :: BasePart
end

local function closest(models: { Model }, to: Vector3): Model?
	local best, distance = nil, math.huge
	for _, model in models do
		local gap = (rootOf(model).Position - to).Magnitude
		if gap < distance then
			best, distance = model, gap
		end
	end
	return best
end

local function clearLine(character: Model, from: Vector3, model: Model): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, model, workspace:FindFirstChild("Bodies") :: Instance }
	return workspace:Raycast(from, rootOf(model).Position - from, params) == nil
end

local function damageFor(model: Model, amount: number): number
	return if model:GetAttribute("Mob") then amount * KitPowers.MobScale else amount
end

-- Only the newest call of each kind gets to end what it started
local function newToken(player: Player, kind: string): {}
	local mine = tokens[player] or {}
	tokens[player] = mine
	local token = {}
	mine[kind] = token
	return token
end

local function current(player: Player, kind: string, token: {}): boolean
	local mine = tokens[player]
	return mine ~= nil and mine[kind] == token
end

-- Flames round someone or a glow on their sword for as long as a special lasts, seen by everyone
local function aura(character: Model, color: Color3, seconds: number)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local at = Instance.new("Attachment")
	at.Name = "KitAura"
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.9
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Rate = 45
	emitter.Speed = NumberRange.new(2, 5)
	emitter.SpreadAngle = Vector2.new(70, 70)
	emitter.Acceleration = Vector3.new(0, 8, 0)
	emitter.Parent = at
	at.Parent = root
	local glow = Instance.new("Highlight")
	glow.Name = "KitAura"
	glow.FillColor = color
	glow.FillTransparency = 0.72
	glow.OutlineColor = color
	glow.OutlineTransparency = 0.25
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = character
	Debris:AddItem(at, seconds)
	Debris:AddItem(glow, seconds)
end

local function buffOn(player: Player, character: Model, special: KitPowers.Special)
	local seconds = special.Lasts :: number
	player:SetAttribute("KitBuffUntil", workspace:GetServerTimeNow() + seconds)
	aura(character, special.Color, seconds)
end

-- The specials ------------------------------------------------------------------------

local function chainLightning(
	player: Player,
	character: Model,
	root: BasePart,
	special: KitPowers.Special,
	aimed: unknown
): boolean
	local range = special.Range :: number
	local first: Model? = nil
	if typeof(aimed) == "Instance" and aimed:IsA("Model") and isTarget(player, aimed) then
		if
			(rootOf(aimed).Position - root.Position).Magnitude <= range and clearLine(character, root.Position, aimed)
		then
			first = aimed
		end
	end
	if not first then
		-- Nobody under the aim: the nearest one ahead of you
		local ahead = {}
		for _, model in near(player, root.Position, range) do
			local flat = (rootOf(model).Position - root.Position) * Vector3.new(1, 0, 1)
			if flat.Magnitude < 1 or root.CFrame.LookVector:Dot(flat.Unit) > FRONT then
				if clearLine(character, root.Position, model) then
					table.insert(ahead, model)
				end
			end
		end
		first = closest(ahead, root.Position)
	end
	if not first then
		return false
	end
	local struck: { [Model]: boolean } = { [first] = true }
	local points = { rootOf(first).Position }
	hit(player, root, first, damageFor(first, special.Damage :: number), LIGHTNING_KNOCKBACK, "crit", true)
	local last = first
	for _ = 1, special.Jumps :: number do
		local nextOne =
			closest(near(player, rootOf(last).Position, special.JumpRange :: number, struck), rootOf(last).Position)
		if not nextOne then
			break
		end
		struck[nextOne] = true
		table.insert(points, rootOf(nextOne).Position)
		hit(player, root, nextOne, damageFor(nextOne, special.JumpDamage :: number), LIGHTNING_KNOCKBACK, "hit", true)
		last = nextOne
	end
	Remotes.KitFx:FireAllClients("Lightning", root.Position, points)
	return true
end

local function solarFlare(player: Player, humanoid: Humanoid, root: BasePart, special: KitPowers.Special): boolean
	for _, model in near(player, root.Position, special.Range :: number) do
		hit(player, root, model, damageFor(model, special.Damage :: number), FLARE_KNOCKBACK, "crit", true)
	end
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (special.Heal :: number))
	Remotes.KitFx:FireAllClients("Flare", root.Position, special.Range)
	return true
end

local function rage(player: Player, character: Model, special: KitPowers.Special): boolean
	local seconds = special.Lasts :: number
	rageUntil[player] = os.clock() + seconds
	Speed.Set(player, "Rage", special.SpeedScale)
	buffOn(player, character, special)
	Remotes.KitFx:FireAllClients("Rage", character:GetPivot().Position)
	local token = newToken(player, "Rage")
	task.delay(seconds, function()
		if current(player, "Rage", token) then
			rageUntil[player] = nil
			Speed.Set(player, "Rage", nil)
		end
	end)
	return true
end

local function freezePlayer(victim: Player, special: KitPowers.Special)
	local character = victim.Character
	if not character then
		return
	end
	local freeze, chill = special.Freeze :: number, special.Chill :: number
	Speed.Set(victim, "Frost", 0)
	local ice = Instance.new("Highlight")
	ice.Name = "Frozen"
	ice.FillColor = special.Color
	ice.FillTransparency = 0.35
	ice.OutlineColor = Color3.new(1, 1, 1)
	ice.OutlineTransparency = 0.2
	ice.Parent = character
	Debris:AddItem(ice, freeze)
	local token = newToken(victim, "Frost")
	task.delay(freeze, function()
		if current(victim, "Frost", token) then
			Speed.Set(victim, "Frost", special.ChillScale)
		end
	end)
	task.delay(freeze + chill, function()
		if current(victim, "Frost", token) then
			Speed.Set(victim, "Frost", nil)
		end
	end)
end

local function frostNova(player: Player, root: BasePart, special: KitPowers.Special): boolean
	for _, model in near(player, root.Position, special.Range :: number) do
		if hit(player, root, model, damageFor(model, special.Damage :: number), NOVA_KNOCKBACK, "hit", true) then
			local victim = Players:GetPlayerFromCharacter(model)
			if victim then
				freezePlayer(victim, special)
			elseif model:GetAttribute("Mob") then
				MobService.Freeze(model, special.Freeze :: number)
			end
		end
	end
	Remotes.KitFx:FireAllClients("Nova", root.Position, special.Range)
	return true
end

local function venomCoat(player: Player, character: Model, special: KitPowers.Special): boolean
	venomUntil[player] = os.clock() + (special.Lasts :: number)
	buffOn(player, character, special)
	Remotes.KitFx:FireAllClients("Venom", character:GetPivot().Position)
	return true
end

local function onUse(player: Player, aimed: unknown)
	local character, humanoid, root = parts(player)
	if not character or not humanoid or not root then
		return
	end
	local special = heldSpecial(character)
	if not special then
		return
	end
	if os.clock() < (readyAt[player] or 0) then
		return
	end
	local used = false
	if special.Name == "Chain Lightning" then
		used = chainLightning(player, character, root, special, aimed)
		if not used then
			StateService.Notify(player, "Nobody in range to strike", "info")
		end
	elseif special.Name == "Solar Flare" then
		used = solarFlare(player, humanoid, root, special)
	elseif special.Name == "Rage" then
		used = rage(player, character, special)
	elseif special.Name == "Frost Nova" then
		used = frostNova(player, root, special)
	elseif special.Name == "Venom Coat" then
		used = venomCoat(player, character, special)
	end
	if used then
		readyAt[player] = os.clock() + special.Cooldown
		player:SetAttribute("KitReadyAt", workspace:GetServerTimeNow() + special.Cooldown)
		player:SetAttribute("KitCooldown", special.Cooldown)
	end
end

-- What CombatService asks ------------------------------------------------------------

-- How much harder this player's swings are hitting right now
function KitPowerService.DamageScale(player: Player): number
	local scale = 1
	if os.clock() < (rageUntil[player] or 0) then
		scale *= KitPowers.Swords.EmberguardSword.DamageScale :: number
	end
	if KitSets.Wearing(player) == "Emberguard" then
		local _, humanoid = parts(player)
		if humanoid and humanoid.Health <= KitPowers.LowHealth then
			scale *= KitPowers.LowHealthScale
		end
	end
	return scale
end

function KitPowerService.KnockbackScale(victim: Player): number
	return if KitSets.Wearing(victim) == "Frostwarden" then KitPowers.KnockbackScale else 1
end

local function poison(model: Model, by: Player, special: KitPowers.Special)
	local victim = Players:GetPlayerFromCharacter(model)
	if victim then
		WarzoneService.Poison(victim, special.PoisonTime :: number, special.PoisonPerSecond :: number)
	else
		poisoned[model] = {
			Until = os.clock() + (special.PoisonTime :: number),
			By = by,
			PerSecond = special.PoisonPerSecond :: number,
		}
	end
end

-- A swing of theirs landed on that character
function KitPowerService.Landed(player: Player, model: Model)
	if os.clock() < (venomUntil[player] or 0) then
		poison(model, player, KitPowers.Swords.VenomfangSword)
	end
end

-- A swing hit someone wearing armour that bites back
function KitPowerService.Struck(victim: Player, attacker: Player, attackerRoot: BasePart)
	if KitSets.Wearing(victim) ~= "Stormcaller" then
		return
	end
	local now = os.clock()
	if now - (shockedAt[victim] or 0) < KitPowers.ShockEvery then
		return
	end
	shockedAt[victim] = now
	local humanoid = attackerRoot.Parent and attackerRoot.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(KitPowers.ShockDamage)
		WarzoneService.Tag(attacker)
		Remotes.HitEffect:FireAllClients(attackerRoot.Parent, "hit")
		local at = victim.Character and victim.Character:GetPivot().Position or attackerRoot.Position
		Remotes.KitFx:FireAllClients("Lightning", at, { attackerRoot.Position })
	end
end

function KitPowerService.Start(hitFn: HitFn)
	hit = hitFn
	Remotes.KitPower.OnServerEvent:Connect(onUse)

	local function track(player: Player)
		player.CharacterAdded:Connect(function()
			rageUntil[player] = nil
			venomUntil[player] = nil
			tokens[player] = nil
			Speed.Clear(player)
			player:SetAttribute("KitBuffUntil", nil)
		end)
	end
	for _, player in Players:GetPlayers() do
		track(player)
	end
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(player)
		readyAt[player] = nil
		rageUntil[player] = nil
		venomUntil[player] = nil
		shockedAt[player] = nil
		tokens[player] = nil
		Speed.Clear(player)
	end)

	task.spawn(function()
		while true do
			task.wait(POISON_TICK)
			local now = os.clock()
			for model, state in poisoned do
				local humanoid = model.Parent and model:FindFirstChildOfClass("Humanoid")
				if now >= state.Until or not humanoid or humanoid.Health <= 0 or state.By.Parent ~= Players then
					poisoned[model] = nil
				elseif model:GetAttribute("Mob") then
					MobService.Damage(model, state.By, state.PerSecond * POISON_TICK * KitPowers.MobScale)
				else
					humanoid.Health = math.max(1, humanoid.Health - state.PerSecond * POISON_TICK)
				end
			end
		end
	end)
end

return KitPowerService
