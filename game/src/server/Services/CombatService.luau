--!strict
-- Whatever is in your selected hotbar slot shows in your hand (HeldModel): a generated sword, a
-- pixel-art tool or crop model (ReplicatedStorage.ItemModels) or a small block.
-- Swinging follows Minecraft 1.9+ (Combat.luau): the client says who's under its aim and whether
-- it's falling, the server checks them and works out everything else. Mobs can be hit anywhere; other players only when both
-- of you are in the Warzone and outside its citadel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Foods = require(ReplicatedStorage.Shared.Foods)
local ItemArt = require(ReplicatedStorage.Shared.ItemArt)
local Decorations = require(ReplicatedStorage.Shared.Decorations)
local Items = require(ReplicatedStorage.Shared.Items)
local Knockback = require(ReplicatedStorage.Shared.Knockback)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SwordArt = require(ReplicatedStorage.Shared.SwordArt)
local Tools = require(ReplicatedStorage.Shared.Tools)
local DecorModels = require(script.Parent.Parent.Util.DecorModels)
local HeldModel = require(script.Parent.Parent.Util.HeldModel)
local DataService = require(script.Parent.DataService)
local KitPowerService = require(script.Parent.KitPowerService)
local MobService = require(script.Parent.MobService)
local SprintService = require(script.Parent.SprintService)
local QuestService = require(script.Parent.QuestService)
local WarzoneService = require(script.Parent.WarzoneService)
local Move = require(script.Parent.Parent.Util.Move)

-- Where the hand holds each item model and which way its head points come from
-- ItemArt.luau (generated with the models). These are the fallback for models without
-- an entry: handle at bottom-right, head at top-left, flat in the XY plane.
local HOLD_POINT = Vector3.new(1.0, -1.0, 0)
local HANDLE_TO_HEAD = Vector3.new(-1, 1, 0).Unit
local MODEL_GRIPS = ItemArt.Models :: { [string]: { Grip: Vector3, Up: Vector3 } }
local BLOCK_IN_HAND = 0.9 -- studs
local QUICKEST_SWING = 0.05 -- faster clicks than this aren't real
local GROUND_BELOW = 3.6 -- from the middle of a character to just under their feet
local FRONT = -0.2 -- how far round a target can be and still count as in front of you

type Swing = { Damage: number, Kind: string, Charge: number, Sprinting: boolean, Falling: boolean }
type Hurt = { At: number, Amount: number }

local CombatService = {}

local lastSwing: { [Player]: number } = {}
local lastHurt: { [Model]: Hurt } = {}

local function heldItem(player: Player): string?
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local item = tool and tool:GetAttribute("Held")
	return if type(item) == "string" then item else nil
end

-- Coming down with nothing under you. The server sees a jump a moment after the client does, so near
-- the top of one it would still see you going up: it takes the client's word that you're falling and
-- checks that you really are in the air.
local function isFalling(character: Model, root: BasePart, clientSays: unknown): boolean
	if clientSays ~= true then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	return workspace:Raycast(root.Position, Vector3.new(0, -GROUND_BELOW, 0), params) == nil
end

-- Half a second after a hit, only a harder one counts, and only for the difference
local function throughHurtTime(model: Model, damage: number): number
	local now = os.clock()
	local last = lastHurt[model]
	local left = damage
	if last and now - last.At < Combat.HurtTime then
		left = damage - last.Amount
		if left <= 0 then
			return 0
		end
		lastHurt[model] = { At = last.At, Amount = damage }
	else
		lastHurt[model] = { At = now, Amount = damage }
	end
	return left
end

local function protection(victim: Player): (number, number)
	local data = DataService.GetData(victim)
	if not data then
		return 0, 0
	end
	return Combat.Armor(data.Equipped :: any)
end

local function knockbackFrom(root: BasePart, targetRoot: BasePart, speed: number): Vector3
	local flat = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)
	local away = if flat.Magnitude > 0.01 then flat.Unit else root.CFrame.LookVector
	return away * speed + Vector3.new(0, Combat.KnockUp, 0)
end

-- One hit on one character. Returns true if it landed. A kit's special goes through armour (`pierce`), and only swings
-- set off armour that bites back.
local function hit(
	player: Player,
	root: BasePart,
	model: Model,
	damage: number,
	speed: number,
	effect: string,
	pierce: boolean?
): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local targetRoot = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not targetRoot or not targetRoot:IsA("BasePart") then
		return false
	end

	if model:GetAttribute("Mob") then
		MobService.Damage(model, player, damage, root)
		Remotes.HitEffect:FireAllClients(model, effect)
		return true
	end

	-- A dummy to practise on, only in Studio (Dev "Dummy")
	if model:GetAttribute("Dummy") and RunService:IsStudio() then
		local left = throughHurtTime(model, damage)
		if left > 0 then
			humanoid:TakeDamage(left)
			Knockback.Apply(targetRoot, knockbackFrom(root, targetRoot, speed))
			Remotes.HitEffect:FireAllClients(model, effect)
		end
		print(
			`[Combat] dummy: {effect}, {string.format("%.1f", damage)} damage, {string.format("%.1f", left)} landed, health {string.format(
				"%.1f",
				humanoid.Health
			)}`
		)
		return left > 0
	end

	local victim = Players:GetPlayerFromCharacter(model)
	if not victim or not WarzoneService.CanHit(player, victim) then
		return false
	end
	WarzoneService.Tag(player)
	WarzoneService.Tag(victim)
	if WarzoneService.Blocks(victim, root.Position) then
		-- Bouncing off a shield pushes you back a little
		Move.Push(player, knockbackFrom(targetRoot, root, Combat.BlockedPush))
		Remotes.HitEffect:FireAllClients(model, "block")
		return false
	end
	local points, toughness = protection(victim)
	local left = throughHurtTime(model, if pierce then damage else Combat.Reduce(damage, points, toughness))
	if left <= 0 then
		return false
	end
	humanoid:SetAttribute("LastAttacker", player.UserId)
	humanoid:TakeDamage(left)
	Move.Push(victim, knockbackFrom(root, targetRoot, speed) * KitPowerService.KnockbackScale(victim))
	Remotes.HitEffect:FireAllClients(model, effect)
	if not pierce then
		KitPowerService.Struck(victim, player, root)
	end
	QuestService.Record(player, "PvPHit")
	if effect == "crit" then
		QuestService.Record(player, "PvPCrit")
	end
	return true
end

-- Everyone else right next to who you hit, with a fully charged sword on the ground
local function sweep(player: Player, root: BasePart, target: Model, targetRoot: BasePart)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Model, target }
	local seen: { [Model]: boolean } = {}
	for _, part in workspace:GetPartBoundsInRadius(targetRoot.Position, Combat.SweepRadius, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not seen[model] and model:FindFirstChildOfClass("Humanoid") then
			seen[model] = true
			hit(player, root, model, Combat.SweepDamage, Combat.Knockback, "sweep")
		end
	end
end

-- Can this swing reach that character? Near enough, in front of you, nothing solid between you
local function reachable(character: Model, root: BasePart, target: Model): BasePart?
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if not targetRoot or not targetRoot:IsA("BasePart") or target == character then
		return nil
	end
	local between = targetRoot.Position - root.Position
	if between.Magnitude > Combat.Reach + Combat.ReachSlack then
		return nil
	end
	local flat = between * Vector3.new(1, 0, 1)
	if flat.Magnitude > 1 and root.CFrame.LookVector:Dot(flat.Unit) < FRONT then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	-- A body on the ground doesn't stop a swing
	params.FilterDescendantsInstances = { character, target, workspace:FindFirstChild("Bodies") :: Instance }
	if workspace:Raycast(root.Position, between, params) then
		return nil
	end
	return targetRoot
end

local function strike(player: Player, root: BasePart, target: Model, targetRoot: BasePart, swing: Swing)
	local full = swing.Charge >= Combat.FullCharge
	local crit = full and swing.Falling and not swing.Sprinting
	local damage = Combat.HitDamage(swing.Damage, swing.Charge)
		* (if crit then Combat.CritScale else 1)
		* KitPowerService.DamageScale(player)
	local sprintHit = full and swing.Sprinting
	local speed = if sprintHit then Combat.SprintKnockback else Combat.Knockback
	local landed = hit(player, root, target, damage, speed, if crit then "crit" else "hit")
	if landed then
		KitPowerService.Landed(player, target)
	end
	if landed and sprintHit then
		SprintService.Stop(player)
	end
	if landed and full and swing.Kind == "Sword" and not swing.Sprinting and not swing.Falling then
		sweep(player, root, target, targetRoot)
	end
end

local function onAttack(player: Player, target: unknown, falling: unknown)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end
	local held = heldItem(player)
	if WarzoneService.IsBlocking(player) or (held and Foods[held]) then
		return
	end
	local tool = held and Tools.ByItem[held]
	local cooldown = if tool then tool.Cooldown else Combat.FistCooldown

	local now = os.clock()
	local elapsed = now - (lastSwing[player] or 0)
	if elapsed < QUICKEST_SWING then
		return
	end
	lastSwing[player] = now
	if tool and tool.Kind == "Sword" then
		WarzoneService.Exert(player)
	end
	HeldModel.Swung(character)

	if typeof(target) == "Instance" and target:IsA("Model") then
		local targetRoot = reachable(character, root, target)
		if targetRoot then
			strike(player, root, target, targetRoot, {
				Damage = if tool then tool.Damage else Combat.FistDamage,
				Kind = if tool then tool.Kind else "Fist",
				Charge = Combat.Charge(elapsed, cooldown),
				Sprinting = player:GetAttribute("Sprinting") == true,
				Falling = isFalling(character, root, falling),
			})
		end
	end
end

-- Builds the Handle for an item: its pixel-art model, a small block, or a plain stick
local function makeHandle(itemId: string): (BasePart, CFrame)
	local item = Items[itemId]
	local models = ReplicatedStorage:FindFirstChild("ItemModels")
	local model = item and item.Model and models and models:FindFirstChild(item.Model)
	if model and model:IsA("BasePart") then
		local handle = model:Clone()
		local art = item and item.Model and MODEL_GRIPS[item.Model]
		local holdPoint = if art then art.Grip else HOLD_POINT
		local towardHead = if art then art.Up else HANDLE_TO_HEAD
		-- Express the hold point and direction in the mesh's own space
		local rotation = model.CFrame.Rotation
		local up = rotation:VectorToObjectSpace(towardHead)
		local back = rotation:VectorToObjectSpace(Vector3.zAxis)
		local right = up:Cross(back).Unit
		return handle, CFrame.fromMatrix(rotation:PointToObjectSpace(holdPoint), right, up, back)
	end

	local decor = item and item.Block and Decorations.ByBlock[item.Block]
	if decor then
		-- Its main mesh, shrunk to fit in a hand
		local template = DecorModels.Get(decor.Model)
		local handle = template:Clone()
		handle:ClearAllChildren()
		handle.Size = template.Size
			* (BLOCK_IN_HAND * 1.3 / math.max(template.Size.X, template.Size.Y, template.Size.Z))
		if decor.Tint then
			handle.Color = decor.Tint
		end
		return handle, CFrame.new(0, 0, 0.2)
	end

	local blocks = ReplicatedStorage:FindFirstChild("Blocks")
	local block = item and item.Block and blocks and blocks:FindFirstChild(item.Block)
	if block and block:IsA("BasePart") then
		local handle = block:Clone()
		handle.Size = Vector3.one * BLOCK_IN_HAND
		return handle, CFrame.new(0, 0, 0.2)
	end

	local stick = Instance.new("Part")
	stick.Size = Vector3.new(0.3, 0.3, 2)
	stick.Color = Color3.fromRGB(104, 78, 46)
	return stick, CFrame.new(0, 0, -0.6)
end

-- The tool only says what you're holding. What shows is on the character (HeldModel): a Tool with a
-- Handle would make Roblox hold your arm straight out, which Minecraft doesn't.
local function makeTool(player: Player, itemId: string): Tool
	local tool = Instance.new("Tool")
	tool.Name = Items[itemId].Name
	tool.CanBeDropped = false
	tool.RequiresHandle = false
	tool:SetAttribute("Held", itemId)

	if Foods[itemId] then
		-- Food in the Warzone: click to eat
		tool.Activated:Connect(function()
			if WarzoneService.IsPlaying(player) then
				WarzoneService.Eat(player, itemId)
			end
		end)
	end
	return tool
end

local function currentTool(player: Player): Tool?
	local containers: { Instance? } = { player.Character, player:FindFirstChildOfClass("Backpack") }
	for _, container in containers do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("Held") then
					return child
				end
			end
		end
	end
	return nil
end

-- Shows the given item in the player's hand (from the selected hotbar slot), or nothing
function CombatService.Equip(player: Player, itemId: string?)
	local character = player.Character
	if not character then
		return
	end
	local tool = currentTool(player)
	if tool and itemId and tool:GetAttribute("Held") == itemId and tool.Parent == character then
		return
	end
	if tool then
		tool:Destroy()
	end
	HeldModel.Remove(character)
	-- Switching items starts the swing's charge over
	lastSwing[player] = os.clock()
	if itemId and Items[itemId] then
		makeTool(player, itemId).Parent = character
		if SwordArt.List[itemId] then
			task.spawn(HeldModel.ApplySword, character, itemId)
		else
			local part, grip = makeHandle(itemId)
			part:SetAttribute("IsBlock", Items[itemId].Model == nil and Items[itemId].Block ~= nil)
			HeldModel.ApplyItem(character, itemId, part, grip)
		end
	end
end

function CombatService.Start()
	HeldModel.Start()
	KitPowerService.Start(hit)
	Remotes.Attack.OnServerEvent:Connect(onAttack)
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		if player.Character then
			lastHurt[player.Character] = nil
		end
	end)
end

return CombatService
