--!strict
-- How armour looks on a body: each piece is several meshes (ArmorArt.luau), modelled for one body part and scaled by
-- how the wearer's part compares with it, so they fit whatever avatar you have. A chestplate is the coat, both
-- shoulders, both sleeves and both forearms; leggings are the hips and thighs; boots go on both lower legs. Each
-- tier has its own colour (bronze, silver, gold, emerald, diamond, amethyst, ruby, starlight...), and from tier 3 it
-- sparkles, from 5 it gives a little light, and from 7 embers rise from the shoulders and boots.
-- What armour covers is hidden while it's on: the body parts, as Roblox bodies would poke straight through, and
-- whatever the avatar wears there (hats, hair, layered clothes, shoes). Works on R15 and R6 characters (an R6 limb is
-- one piece, so its armour fits less well there).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArmorArt = require(ReplicatedStorage.Shared.ArmorArt)
local Gear = require(ReplicatedStorage.Shared.Gear)

local ArmorModels = {}

export type Piece = { Slot: string, Skill: string, Tier: number }

local WHITE = Color3.new(1, 1, 1)
local NOTHING: { string } = {}
local SPARKLE_FROM = 3
local GLOW_FROM = 5
local EMBER_FROM = 7

-- Where each mesh goes. Ref is the body part it was modelled on (ArmorArt.Reference), Hides what it covers, and Embers
-- where the top tiers' embers come out, as a share of the part's size.
type Place = {
	Slot: string,
	Piece: string,
	Ref: string,
	Parts: { string },
	Hides: { string }?,
	Embers: Vector3?,
}
local PLACES: { Place } = {
	{ Slot = "Helmet", Piece = "Helmet", Ref = "Head", Parts = { "Head" } },
	{
		Slot = "Chest",
		Piece = "Chest",
		Ref = "Chest",
		Parts = { "UpperTorso", "Torso" },
		Hides = { "UpperTorso" },
	},
	-- On the chest, not the arm: on the arm, lifting a sword swings what's on the shoulder across your face
	{
		Slot = "Chest",
		Piece = "PauldronRight",
		Ref = "Chest",
		Parts = { "UpperTorso", "Torso" },
		Embers = Vector3.new(0.75, 0.62, 0),
	},
	{
		Slot = "Chest",
		Piece = "PauldronLeft",
		Ref = "Chest",
		Parts = { "UpperTorso", "Torso" },
		Embers = Vector3.new(-0.75, 0.62, 0),
	},
	{
		Slot = "Chest",
		Piece = "SleeveRight",
		Ref = "Shoulder",
		Parts = { "RightUpperArm", "Right Arm" },
		Hides = { "RightUpperArm" },
	},
	{
		Slot = "Chest",
		Piece = "SleeveLeft",
		Ref = "Shoulder",
		Parts = { "LeftUpperArm", "Left Arm" },
		Hides = { "LeftUpperArm" },
	},
	{
		Slot = "Chest",
		Piece = "ForearmRight",
		Ref = "Forearm",
		Parts = { "RightLowerArm" },
		Hides = { "RightLowerArm" },
	},
	{
		Slot = "Chest",
		Piece = "ForearmLeft",
		Ref = "Forearm",
		Parts = { "LeftLowerArm" },
		Hides = { "LeftLowerArm" },
	},
	{ Slot = "Legs", Piece = "Hips", Ref = "Hips", Parts = { "LowerTorso" }, Hides = { "LowerTorso" } },
	{
		Slot = "Legs",
		Piece = "ThighRight",
		Ref = "Thigh",
		Parts = { "RightUpperLeg", "Right Leg" },
		Hides = { "RightUpperLeg" },
	},
	{
		Slot = "Legs",
		Piece = "ThighLeft",
		Ref = "Thigh",
		Parts = { "LeftUpperLeg", "Left Leg" },
		Hides = { "LeftUpperLeg" },
	},
	{
		Slot = "Boots",
		Piece = "BootRight",
		Ref = "Boot",
		Parts = { "RightLowerLeg" },
		Hides = { "RightLowerLeg", "RightFoot" },
		Embers = Vector3.new(0.1, -0.3, 0),
	},
	{
		Slot = "Boots",
		Piece = "BootLeft",
		Ref = "Boot",
		Parts = { "LeftLowerLeg" },
		Hides = { "LeftLowerLeg", "LeftFoot" },
		Embers = Vector3.new(-0.1, -0.3, 0),
	},
}

local function addEffects(part: BasePart, body: BasePart, place: Place, tier: number)
	local color = Gear.TierColors[math.clamp(tier, 1, #Gear.TierColors)]
	if tier >= SPARKLE_FROM then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "Sparkle"
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(color:Lerp(WHITE, 0.5), color)
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.14), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Lifetime = NumberRange.new(0.5, 1)
		sparkle.Rate = if tier >= GLOW_FROM then 3 else 1
		sparkle.Speed = NumberRange.new(0.2, 0.6)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = part
	end
	if tier >= GLOW_FROM and place.Embers then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 5
		light.Brightness = 0.35
		light.Shadows = false
		light.Parent = part
	end
	if tier >= EMBER_FROM and place.Embers then
		local at = Instance.new("Attachment")
		at.Name = "Embers"
		at.Parent = part
		-- Turned with the body: a mesh's own axes can run any way, and embers go up
		at.WorldCFrame = body.CFrame * CFrame.new(place.Embers * body.Size)
		local embers = Instance.new("ParticleEmitter")
		embers.Name = "Embers"
		embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		embers.Color = ColorSequence.new(color:Lerp(WHITE, 0.4), color)
		embers.LightEmission = 1
		embers.LightInfluence = 0
		embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		embers.Lifetime = NumberRange.new(0.5, 0.9)
		embers.Rate = 12
		embers.Speed = NumberRange.new(1.5, 3)
		embers.SpreadAngle = Vector2.new(30, 30)
		embers.Parent = at
	end
end

-- One mesh on a body part: scaled by how that part compares with the one it was modelled on, in its tier's colour
-- sheet.
local function meshPart(set: ArmorArt.Set, place: Place, body: BasePart, tier: number): Part?
	local art = set[place.Piece]
	if not art then
		return nil
	end
	local ratio = body.Size / ArmorArt.Reference[place.Ref]
	local function toMesh(v: Vector3): Vector3
		return Vector3.new(v.X, v.Z, v.Y)
	end
	local part = Instance.new("Part")
	part.Name = place.Piece
	part.Size = toMesh(art.Size * ratio)
	part.CFrame = body.CFrame * CFrame.new(art.Centre * ratio) * ArmorArt.MeshTurn
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = art.Mesh
	mesh.TextureId = ArmorArt.Palettes[math.clamp(tier, 1, #ArmorArt.Palettes)]
	mesh.Scale = toMesh(ratio) / ArmorArt.MeshScale
	mesh.Parent = part
	addEffects(part, body, place, tier)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = part
	weld.Parent = part
	return part
end

-- Hides a part while armour covers it, remembering how it looked
local function setHidden(part: BasePart, hidden: boolean)
	local was = part:GetAttribute("BeforeArmor")
	if hidden and was == nil then
		part:SetAttribute("BeforeArmor", part.Transparency)
		part.Transparency = 1
	elseif not hidden and type(was) == "number" then
		part.Transparency = was
		part:SetAttribute("BeforeArmor", nil)
	end
end

-- What an avatar wears on top of its body isn't part of the body: hats and hair would poke through a
-- helmet, and layered clothes and shoes would go right over the armour. Each kind comes off while one of
-- these slots is worn.
local COVERED_BY: { [Enum.AccessoryType]: { string } } = {
	[Enum.AccessoryType.Hat] = { "Helmet" },
	[Enum.AccessoryType.Hair] = { "Helmet" },
	[Enum.AccessoryType.Shirt] = { "Chest" },
	[Enum.AccessoryType.TShirt] = { "Chest" },
	[Enum.AccessoryType.Sweater] = { "Chest" },
	[Enum.AccessoryType.Jacket] = { "Chest" },
	[Enum.AccessoryType.Waist] = { "Legs" },
	[Enum.AccessoryType.Pants] = { "Legs", "Boots" },
	[Enum.AccessoryType.Shorts] = { "Legs", "Boots" },
	[Enum.AccessoryType.DressSkirt] = { "Legs", "Boots" },
	[Enum.AccessoryType.LeftShoe] = { "Boots" },
	[Enum.AccessoryType.RightShoe] = { "Boots" },
}

local function hideClothing(character: Model, wornSlots: { [string]: boolean })
	for _, child in character:GetChildren() do
		local slots = if child:IsA("Accessory") then COVERED_BY[child.AccessoryType] else nil
		local handle = child:FindFirstChild("Handle")
		if slots and handle and handle:IsA("BasePart") then
			local hidden = false
			for _, slot in slots do
				hidden = hidden or wornSlots[slot] == true
			end
			setHidden(handle, hidden)
		end
	end
end

local function bodyPartOf(character: Model, place: Place): BasePart?
	for _, name in place.Parts do
		local found = character:FindFirstChild(name)
		if found and found:IsA("BasePart") then
			return found
		end
	end
	return nil
end

-- Puts armor pieces on a character (in a folder named "Armor")
function ArmorModels.Apply(character: Model, pieces: { Piece }): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Armor"
	local wornSlots: { [string]: boolean } = {}
	local covered: { [string]: boolean } = {}
	for _, piece in pieces do
		wornSlots[piece.Slot] = true
		local set = ArmorArt.Sets[piece.Skill]
		if set then
			for _, place in PLACES do
				local body = if place.Slot == piece.Slot then bodyPartOf(character, place) else nil
				local part = body and meshPart(set, place, body, piece.Tier)
				if part then
					part.Parent = folder
					for _, name in place.Hides or NOTHING do
						covered[name] = true
					end
				end
			end
		end
	end
	hideClothing(character, wornSlots)
	for _, place in PLACES do
		for _, name in place.Hides or NOTHING do
			local part = character:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				setHidden(part, covered[name] == true)
			end
		end
	end
	folder.Parent = character
	return folder
end

return ArmorModels
