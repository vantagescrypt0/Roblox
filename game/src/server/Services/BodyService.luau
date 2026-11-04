--!strict
-- Lootable bodies in the Warzone (your rules, 2026-11-02 and 2026-11-03). Die, or quit the wrong way
-- (WarzoneService), and everything you carried and wore stays with your body: your own avatar, lying
-- where you fell, still wearing what nobody's taken yet. Anyone in the Warzone can open it, right away,
-- with the traditional chest screen. Once it's emptied it vanishes; if it isn't, it's gone after 15
-- minutes with whatever's left on it.
--
-- A body only lives on its server. If that server closes first, it goes too.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gear = require(ReplicatedStorage.Shared.Gear)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Items = require(ReplicatedStorage.Shared.Items)
local Rig = require(ReplicatedStorage.Shared.Rig)
local ArmorModels = require(script.Parent.Parent.Util.ArmorModels)
local ChestService = require(script.Parent.ChestService)
local DataService = require(script.Parent.DataService)
local InboxService = require(script.Parent.InboxService)
local InventoryService = require(script.Parent.InventoryService)
local LootChestService = require(script.Parent.LootChestService)
local QuestService = require(script.Parent.QuestService)

local COLUMNS = 9
local MIN_ROWS = 3
local FALL_TIME = 0.55
local FALL_STEPS = 10
local EMPTY_BODY_STAYS = 6 -- seconds: nothing on it, so it's only there until you've gone
local LABEL_RANGE = 45
local LABEL_FONT = Font.new("rbxasset://fonts/families/Sarpanch.json", Enum.FontWeight.Bold)
local HEAD_END_CHECK = 3 -- studs above and below the ground where the head will land
local SHIELD_BESIDE = Vector3.new(-3, -0.5, 0)

-- How a body lies: arms a little out, one knee and the head turned, not stiff as a board
local LYING: { [string]: CFrame } = {
	LeftUpperArm = CFrame.Angles(math.rad(6), 0, math.rad(-26)),
	RightUpperArm = CFrame.Angles(math.rad(-4), 0, math.rad(34)),
	LeftLowerArm = CFrame.Angles(math.rad(14), 0, 0),
	RightLowerArm = CFrame.Angles(math.rad(8), 0, 0),
	LeftUpperLeg = CFrame.Angles(0, 0, math.rad(-8)),
	RightUpperLeg = CFrame.Angles(0, 0, math.rad(13)),
	Head = CFrame.Angles(0, math.rad(24), 0),
}

local TAKEN_OFF: { string } = { "Model", "Tool", "Folder" }
local LEFT_BEHIND: { string } = {
	"LuaSourceContainer",
	"Sound",
	"ForceField",
	"IKControl",
	"Animator",
	"BillboardGui",
	"LinearVelocity",
	"AlignPosition",
	"AlignOrientation",
}

-- What WarzoneService hands over to lay a body down
export type Drop = {
	UserId: number,
	Name: string,
	Stacks: { Inventory.Stack },
	Worn: { string }, -- which of the stacks were being worn
	Copy: Model?, -- from BodyService.Copy; if there's none (they'd left already), their avatar is fetched
	At: Vector3, -- the ground under their feet
	Facing: Vector3,
}

type Shape = { FeetBelow: number, Length: number, Thickness: number }

local BodyService = {}

local lifetime = 15 * 60
local folder: Folder
local count = 0

-- Studio tests only: a body that doesn't take 15 minutes to go
function BodyService.SetLifetime(seconds: number)
	lifetime = seconds
end

function BodyService.Lifetime(): number
	return lifetime
end

local function isAny(instance: Instance, classes: { string }): boolean
	for _, class in classes do
		if instance:IsA(class) then
			return true
		end
	end
	return false
end

-- Readies a copy of a character to lie on the ground: just the body, in the lying pose, standing at
-- the world's origin. Armour goes on afterwards, as it's taken off piece by piece.
local function prepare(copy: Model): Model?
	for _, child in copy:GetChildren() do
		if isAny(child, TAKEN_OFF) or child.Name == "Held" or child.Name == "Shield" then
			child:Destroy()
		end
	end
	for _, descendant in copy:GetDescendants() do
		if isAny(descendant, LEFT_BEHIND) then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
	local root = copy:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		copy:Destroy()
		return nil
	end
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.BreakJointsOnDeath = false
		humanoid.RequiresNeck = false
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.PlatformStand = true
		humanoid.EvaluateStateMachine = false
	end
	Rig.Settle(copy, root, nil, LYING)
	copy.PrimaryPart = root
	copy.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return copy
end

-- A copy of this character as they are now, to lay down now or later. Doesn't yield.
function BodyService.Copy(character: Model?): Model?
	if not character then
		return nil
	end
	local archivable = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = archivable
	return if copy then prepare(copy) else nil
end

-- Hides the real character once its body has been laid down, and holds it still, so the camera stays
-- over the body until you're on your way
function BodyService.Hide(character: Model)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			if descendant.Name == "HumanoidRootPart" then
				descendant.Anchored = true
			end
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Light") then
			local glow: any = descendant
			glow.Enabled = false
		end
	end
end

local function fetchAvatar(userId: number): Model?
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromUserId(userId)
	end)
	if ok and model then
		return prepare(model)
	end
	return prepare(
		Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	)
end

local function shapeOf(copy: Model): Shape
	local lowest, highest = 0, 0
	for _, part in copy:GetChildren() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			lowest = math.min(lowest, part.Position.Y - part.Size.Y / 2)
			highest = math.max(highest, part.Position.Y + part.Size.Y / 2)
		end
	end
	local chest = copy:FindFirstChild("UpperTorso") or copy:FindFirstChild("Torso")
	return {
		FeetBelow = -lowest,
		Length = highest - lowest,
		Thickness = if chest and chest:IsA("BasePart") then chest.Size.Z else 1,
	}
end

-- It falls backwards, unless there's a wall there or nothing to land on: then it turns until it fits
local function fallingWay(at: Vector3, facing: Vector3, length: number): CFrame
	local flat = facing * Vector3.new(1, 0, 1)
	if flat.Magnitude < 0.1 then
		flat = Vector3.zAxis
	end
	local first = CFrame.lookAt(at, at + flat)
	local world = workspace:FindFirstChild("World")
	if not world then
		return first
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	local above = Vector3.new(0, HEAD_END_CHECK, 0)
	for turn = 0, 3 do
		local frame = first * CFrame.Angles(0, turn * math.pi / 2, 0)
		local head = (frame * CFrame.new(0, 0, length)).Position
		local wall = workspace:Raycast(at + above, head - at, params)
		local ground = workspace:Raycast(head + above, above * -2, params)
		if not wall and ground then
			return frame
		end
	end
	return first
end

local function addLabel(hitbox: BasePart, name: string)
	local board = Instance.new("BillboardGui")
	board.Name = "Label"
	board.Size = UDim2.fromOffset(240, 26)
	board.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	board.MaxDistance = LABEL_RANGE
	board.LightInfluence = 0
	board.Parent = hitbox
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.FontFace = LABEL_FONT
	text.Text = `{name}'s body`
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.35
	text.TextSize = 18
	text.Parent = board
end

-- The shield lies flat beside the body, on the left
local function layShield(copy: Model, root: BasePart, shape: Shape)
	local models = ReplicatedStorage:FindFirstChild("ShieldModels")
	local template = models and models:FindFirstChild("Shield")
	if not template or not template:IsA("BasePart") then
		return
	end
	local shield = template:Clone()
	shield.Name = "ShieldOnGround"
	shield.Anchored = true
	shield.CanCollide = false
	shield.CanTouch = false
	shield.CanQuery = false
	-- A lying body's +Z points at the ground
	local down = shape.Thickness / 2 - shield.Size.Z / 2
	shield.CFrame = root.CFrame * CFrame.new(SHIELD_BESIDE + Vector3.new(0, 0, down))
	shield.Parent = copy
end

-- Makes the body show the worn pieces nobody's taken yet
local function dress(
	copy: Model,
	root: BasePart,
	shape: Shape,
	worn: { string },
	slots: { Inventory.Stack },
	last: string?
)
	local have: { [string]: number } = {}
	for _, stack in slots do
		if stack.Count > 0 then
			have[stack.Item] = (have[stack.Item] or 0) + stack.Count
		end
	end
	local pieces = {}
	local shown = {}
	local shield = false
	for _, itemId in worn do
		if (have[itemId] or 0) > 0 then
			have[itemId] -= 1
			table.insert(shown, itemId)
			local armor = Gear.Armors[itemId]
			if armor then
				table.insert(pieces, { Slot = armor.Slot, Skill = armor.Skill, Tier = armor.Tier })
			elseif Items[itemId] and Items[itemId].Equip == "Shield" then
				shield = true
			end
		end
	end
	local key = table.concat(shown, "|")
	if key == last then
		return key
	end
	local armor = copy:FindFirstChild("Armor")
	if armor then
		armor:Destroy()
	end
	local onGround = copy:FindFirstChild("ShieldOnGround")
	if onGround then
		onGround:Destroy()
	end
	-- Even with no pieces: this is what shows the skin and clothes under armour that's gone
	for _, part in ArmorModels.Apply(copy, pieces):GetChildren() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	if shield then
		layShield(copy, root, shape)
	end
	return key
end

-- Lays a body down. Yields while it falls, or while fetching an avatar. Nothing on it means it can't be
-- opened, and it's soon gone.
function BodyService.Drop(drop: Drop)
	local copy = drop.Copy or fetchAvatar(drop.UserId)
	if not copy then
		warn(`[BodyService] no body for {drop.Name}: what they carried is lost`)
		return
	end
	local root = copy.PrimaryPart :: BasePart
	local shape = shapeOf(copy)

	count += 1
	local id = `body{count}`
	local rows = math.clamp(math.ceil(#drop.Stacks / COLUMNS), MIN_ROWS, Inventory.BiggestChest // COLUMNS)
	local slots = Inventory.EmptyOf(rows * COLUMNS)
	for index, stack in drop.Stacks do
		slots[index] = { Item = stack.Item, Count = stack.Count }
	end

	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = Vector3.new(3.4, shape.Length, 2)
	hitbox.CFrame = CFrame.new(0, shape.Length / 2 - shape.FeetBelow, 0)
	hitbox.Anchored = true
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox:SetAttribute("ChestId", id)
	hitbox.Parent = copy

	local frame = fallingWay(drop.At, drop.Facing, shape.Length)
	copy:PivotTo(frame * CFrame.new(0, shape.FeetBelow, 0))
	local shown = dress(copy, root, shape, drop.Worn, slots, nil)
	copy.Name = `{drop.Name}'s body`
	copy.Parent = folder

	for step = 1, FALL_STEPS do
		local fallen = (step / FALL_STEPS) ^ 2
		copy:PivotTo(
			frame
				* CFrame.Angles(fallen * math.pi / 2, 0, 0)
				* CFrame.new(0, shape.FeetBelow, -shape.Thickness / 2 * fallen)
		)
		task.wait(FALL_TIME / FALL_STEPS)
	end

	if #drop.Stacks == 0 then
		task.delay(EMPTY_BODY_STAYS, function()
			copy:Destroy()
		end)
		return
	end
	addLabel(hitbox, drop.Name)

	local gone = false
	local chest: ChestService.Chest
	local function remove()
		if gone then
			return
		end
		gone = true
		ChestService.CloseAll(chest)
		LootChestService.Remove(id)
		copy:Destroy()
	end
	chest = {
		Id = id,
		Title = `{drop.Name}'s Body`,
		Slots = slots,
		Position = hitbox.Position,
		Viewers = {},
		OnChanged = function(self: ChestService.Chest)
			local empty = true
			for _, stack in self.Slots do
				empty = empty and stack.Count <= 0
			end
			if empty then
				remove()
			else
				shown = dress(copy, root, shape, drop.Worn, self.Slots, shown)
			end
		end,
		OnFirstOpen = function(player: Player)
			if player.UserId ~= drop.UserId then
				QuestService.Record(player, "LootBody")
			end
		end,
	}
	LootChestService.Add(chest)
	task.delay(lifetime, remove)
end

-- In the Warzone: where bodies lie
function BodyService.StartWarzone()
	folder = Instance.new("Folder")
	folder.Name = "Bodies"
	folder.Parent = workspace
end

-- Everywhere: your body dropped while you were away. It holds what you had, so it comes off you now,
-- wherever you are, and a letter says why.
function BodyService.Start()
	DataService.OnMessage("BodyDropped", function(player: Player, data: DataService.Data, message: { [string]: any })
		InventoryService.TakeEverything(data)
		data.Rejoin.Until = 0
		if type(message.JobId) == "string" and type(message.Until) == "number" then
			data.Body.JobId = message.JobId
			data.Body.Until = message.Until
		end
		DataService.MarkChanged(player)
		InboxService.Send(player.UserId, {
			From = "The Warzone",
			Text = "You didn't get back within 5 minutes, so your body dropped where you left it, with everything on it. "
				.. "Anyone there can loot it for 15 minutes. Jump in the pit to go after it.",
		})
	end)
end

return BodyService
