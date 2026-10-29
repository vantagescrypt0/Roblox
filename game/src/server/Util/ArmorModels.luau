--!strict
-- The armor sets' look (Gear.luau): plates welded over a character's body, in the skill's
-- colours (Farming: green and straw, Woodcutting: brown leather, Mining: steel), shading
-- toward the tier's colour as the tier goes up (bronze, silver, gold, emerald, diamond);
-- the top tiers are metal with glowing trim. Works on R15 and R6 characters.

local ArmorModels = {}

local SKILL_COLORS: { [string]: { Main: Color3, Trim: Color3 } } = {
	Farming = { Main = Color3.fromRGB(104, 150, 64), Trim = Color3.fromRGB(226, 196, 108) },
	Woodcutting = { Main = Color3.fromRGB(122, 82, 50), Trim = Color3.fromRGB(176, 128, 74) },
	Mining = { Main = Color3.fromRGB(132, 138, 148), Trim = Color3.fromRGB(88, 92, 102) },
}
local TIER_COLORS = {
	Color3.fromRGB(205, 127, 50),
	Color3.fromRGB(196, 200, 208),
	Color3.fromRGB(242, 193, 78),
	Color3.fromRGB(80, 200, 120),
	Color3.fromRGB(120, 222, 244),
}

-- Which body part each plate covers, how much bigger than it, and where on it
type Plate = { Parts: { string }, Name: string, Scale: Vector3, Offset: Vector3, Trim: boolean? }
local PLATES: { Plate } = {
	{ Parts = { "Head" }, Name = "Helmet", Scale = Vector3.new(1.18, 0.55, 1.18), Offset = Vector3.new(0, 0.3, 0) },
	{
		Parts = { "UpperTorso", "Torso" },
		Name = "Chestplate",
		Scale = Vector3.new(1.12, 1.04, 1.3),
		Offset = Vector3.zero,
	},
	{
		Parts = { "LeftUpperArm", "Left Arm" },
		Name = "Pauldron",
		Scale = Vector3.new(1.35, 0.42, 1.35),
		Offset = Vector3.new(0, 0.35, 0),
		Trim = true,
	},
	{
		Parts = { "RightUpperArm", "Right Arm" },
		Name = "Pauldron",
		Scale = Vector3.new(1.35, 0.42, 1.35),
		Offset = Vector3.new(0, 0.35, 0),
		Trim = true,
	},
	{
		Parts = { "LeftLowerLeg", "Left Leg" },
		Name = "Boot",
		Scale = Vector3.new(1.18, 0.6, 1.25),
		Offset = Vector3.new(0, -0.25, 0),
		Trim = true,
	},
	{
		Parts = { "RightLowerLeg", "Right Leg" },
		Name = "Boot",
		Scale = Vector3.new(1.18, 0.6, 1.25),
		Offset = Vector3.new(0, -0.25, 0),
		Trim = true,
	},
	{
		Parts = { "LowerTorso" },
		Name = "Belt",
		Scale = Vector3.new(1.15, 0.5, 1.3),
		Offset = Vector3.zero,
		Trim = true,
	},
}

-- Puts a skill's armor set of `tier` on a character (in a folder named "Armor")
function ArmorModels.Apply(character: Model, skill: string, tier: number): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Armor"
	local colors = SKILL_COLORS[skill] or SKILL_COLORS.Farming
	local tierColor = TIER_COLORS[math.clamp(tier, 1, #TIER_COLORS)]
	local blend = 0.15 + 0.12 * (tier - 1)
	local metal = tier >= 3
	for _, plate in PLATES do
		local body: BasePart? = nil
		for _, name in plate.Parts do
			local found = character:FindFirstChild(name)
			if found and found:IsA("BasePart") then
				body = found
				break
			end
		end
		if body then
			local part = Instance.new("Part")
			part.Name = plate.Name
			part.Size = body.Size * plate.Scale
			part.CFrame = body.CFrame * CFrame.new(plate.Offset * body.Size)
			part.Color = (if plate.Trim then colors.Trim else colors.Main):Lerp(tierColor, blend)
			part.Material = if metal then Enum.Material.Metal else Enum.Material.Fabric
			part.Massless = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Parent = folder
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = part
			if tier >= 5 and plate.Trim then
				part.Material = Enum.Material.Neon
				part.Color = tierColor
			end
		end
	end
	folder.Parent = character
	return folder
end

return ArmorModels
