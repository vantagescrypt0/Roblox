--!strict
-- The water and lava blocks' look (Liquids.luau), built in code when a server starts and put
-- in ReplicatedStorage.Blocks next to the block meshes, so islands draw them like any block
-- and icons show them. Water is see-through blue glass like the worlds' ponds; lava glows.
-- Each is as tall as Blocks says (sources nearly full, flowing ones lower); BlockWorld stands
-- it on the cell's floor. Nobody collides with them: you wade through.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Liquids = require(ReplicatedStorage.Shared.Liquids)

local SIZE = Blocks.Size
local WATER = Color3.fromRGB(56, 128, 206)
local LAVA = Color3.fromRGB(255, 100, 20)
local LAVA_LIGHT = Color3.fromRGB(255, 140, 50)

local LiquidModels = {}

local function make(blockType: string, cell: Liquids.Cell): Part
	local def = Blocks.Types[blockType]
	local part = Instance.new("Part")
	part.Name = blockType
	part.Size = Vector3.new(SIZE, SIZE * (def.Height or 1), SIZE)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if cell.Kind.Id == "Water" then
		part.Color = WATER
		part.Material = Enum.Material.Glass
		part.Transparency = 0.35
		part.Reflectance = 0.12
	else
		part.Color = LAVA
		part.Material = Enum.Material.Neon
		-- Only sources light up their surroundings, so a big lava flow stays cheap
		if cell.Source then
			local light = Instance.new("PointLight")
			light.Color = LAVA_LIGHT
			light.Range = 12
			light.Brightness = 1.5
			light.Shadows = false
			light.Parent = part
		end
	end
	return part
end

-- Puts every liquid block's look into ReplicatedStorage.Blocks (replacing any older one)
function LiquidModels.Make()
	local folder = ReplicatedStorage:FindFirstChild("Blocks")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Blocks"
		folder.Parent = ReplicatedStorage
	end
	for blockType, cell in Liquids.ByBlock do
		local old = folder:FindFirstChild(blockType)
		if old then
			old:Destroy()
		end
		make(blockType, cell).Parent = folder
	end
end

return LiquidModels
