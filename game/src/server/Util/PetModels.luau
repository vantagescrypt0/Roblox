--!strict
-- The pets' looks (Gear.luau), built from blocky parts: a chicken for Farming, a beaver for
-- Woodcutting and a mole in a miner's helmet for Mining. A pet's tier shows as a coloured
-- collar (bronze, silver, gold, emerald, diamond) and it grows a little with each tier; the
-- top tiers sparkle. Every part is welded to an invisible root ("Root", the PrimaryPart),
-- which GearService floats along beside its owner.

local PetModels = {}

local TIER_COLORS = {
	Color3.fromRGB(205, 127, 50),
	Color3.fromRGB(196, 200, 208),
	Color3.fromRGB(242, 193, 78),
	Color3.fromRGB(80, 200, 120),
	Color3.fromRGB(120, 222, 244),
}
local BLACK = Color3.fromRGB(28, 24, 22)

type Builder = (
	root: BasePart,
	add: (name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?) -> BasePart
) -> ()

local KINDS: { [string]: Builder } = {
	Chicken = function(_root, add)
		local white, red, yellow =
			Color3.fromRGB(246, 244, 236), Color3.fromRGB(214, 52, 46), Color3.fromRGB(246, 196, 54)
		add("Body", Vector3.new(1.3, 1.1, 1.5), CFrame.new(0, 0, 0.1), white)
		add("Head", Vector3.new(0.85, 0.9, 0.8), CFrame.new(0, 0.75, -0.65), white)
		add("Comb", Vector3.new(0.2, 0.35, 0.5), CFrame.new(0, 1.3, -0.65), red)
		add("Beak", Vector3.new(0.35, 0.25, 0.35), CFrame.new(0, 0.7, -1.2), yellow)
		add("Wattle", Vector3.new(0.2, 0.3, 0.15), CFrame.new(0, 0.42, -1.1), red)
		for _, side in { -1, 1 } do
			add("Eye", Vector3.new(0.12, 0.18, 0.12), CFrame.new(side * 0.43, 0.85, -0.85), BLACK)
			add(
				"Wing",
				Vector3.new(0.18, 0.75, 1.0),
				CFrame.new(side * 0.73, 0.05, 0.15),
				Color3.fromRGB(226, 224, 214)
			)
			add("Leg", Vector3.new(0.15, 0.55, 0.15), CFrame.new(side * 0.3, -0.8, 0.1), yellow)
		end
		add("Tail", Vector3.new(0.9, 0.7, 0.3), CFrame.new(0, 0.45, 0.95) * CFrame.Angles(math.rad(-25), 0, 0), white)
	end,
	Beaver = function(_root, add)
		local brown, dark = Color3.fromRGB(132, 86, 52), Color3.fromRGB(84, 58, 40)
		add("Body", Vector3.new(1.3, 1.05, 1.7), CFrame.new(0, 0, 0.1), brown)
		add("Head", Vector3.new(1.0, 0.85, 0.85), CFrame.new(0, 0.35, -1.0), brown)
		add("Nose", Vector3.new(0.3, 0.2, 0.15), CFrame.new(0, 0.45, -1.45), BLACK)
		add("Teeth", Vector3.new(0.3, 0.3, 0.1), CFrame.new(0, 0.05, -1.43), Color3.fromRGB(250, 244, 226))
		for _, side in { -1, 1 } do
			add("Eye", Vector3.new(0.12, 0.15, 0.12), CFrame.new(side * 0.3, 0.6, -1.4), BLACK)
			add("Ear", Vector3.new(0.25, 0.25, 0.15), CFrame.new(side * 0.42, 0.85, -0.85), dark)
			add("Paw", Vector3.new(0.3, 0.3, 0.35), CFrame.new(side * 0.4, -0.55, -0.6), dark)
		end
		add("Tail", Vector3.new(0.85, 0.18, 1.2), CFrame.new(0, -0.35, 1.45) * CFrame.Angles(math.rad(12), 0, 0), dark)
	end,
	Mole = function(_root, add)
		local fur, pink = Color3.fromRGB(70, 66, 72), Color3.fromRGB(240, 150, 170)
		add("Body", Vector3.new(1.3, 1.0, 1.6), CFrame.new(0, 0, 0.1), fur)
		add("Head", Vector3.new(0.9, 0.8, 0.8), CFrame.new(0, 0.2, -0.9), fur)
		add("Snout", Vector3.new(0.4, 0.3, 0.35), CFrame.new(0, 0.1, -1.4), pink)
		for _, side in { -1, 1 } do
			add("Eye", Vector3.new(0.1, 0.1, 0.1), CFrame.new(side * 0.25, 0.4, -1.3), BLACK)
			add("Claw", Vector3.new(0.45, 0.2, 0.45), CFrame.new(side * 0.55, -0.45, -0.75), pink)
		end
		-- A little miner's helmet with a glowing lamp
		add("Helmet", Vector3.new(1.0, 0.35, 0.95), CFrame.new(0, 0.72, -0.9), Color3.fromRGB(240, 196, 48))
		local lamp = add(
			"Lamp",
			Vector3.new(0.3, 0.25, 0.15),
			CFrame.new(0, 0.75, -1.4),
			Color3.fromRGB(255, 244, 196),
			Enum.Material.Neon
		)
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Front
		light.Range = 14
		light.Brightness = 1.5
		light.Angle = 50
		light.Parent = lamp
	end,
}

-- Builds a pet of `kind` ("Chicken", "Beaver", "Mole") at `tier`, standing at `at`
function PetModels.Build(kind: string, tier: number, at: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Pet"
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.CFrame = at
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Parent = model
	model.PrimaryPart = root

	-- A bit smaller than a player, growing a little with each tier
	local scale = 0.75 + 0.06 * (tier - 1)
	local function add(name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?): BasePart
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size * scale
		part.CFrame = root.CFrame * (offset - offset.Position + offset.Position * scale)
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Massless = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		return part
	end
	local builder = KINDS[kind] or KINDS.Chicken
	builder(root, add)

	-- The tier's collar, and sparkles on the top tiers
	local color = TIER_COLORS[math.clamp(tier, 1, #TIER_COLORS)]
	local collar = add("Collar", Vector3.new(1.05, 0.2, 0.9), CFrame.new(0, 0.35, -0.55), color, Enum.Material.Foil)
	if tier >= 4 then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = ColorSequence.new(color)
		sparkles.LightEmission = 0.6
		sparkles.Size = NumberSequence.new(0.25, 0)
		sparkles.Lifetime = NumberRange.new(0.6, 1)
		sparkles.Rate = 6
		sparkles.Speed = NumberRange.new(0.5, 1.5)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Parent = collar
	end
	return model
end

return PetModels
