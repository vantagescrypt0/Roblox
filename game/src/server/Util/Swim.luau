--!strict
-- Makes water swimmable. Roblox characters swim in terrain water, so every body of water
-- also gets terrain water in the same spot: the flat water sheets in the worlds and Town
-- (Decor.Water) and the water blocks on islands (LiquidService). The terrain water itself
-- is made invisible here, so the water still looks like our own (see-through blocks and
-- sheets); only the swimming, and the blue tint under water, come from Roblox.

local Workspace = game:GetService("Workspace")

local Swim = {}

local terrain = Workspace.Terrain
terrain.WaterTransparency = 1
terrain.WaterReflectance = 0
terrain.WaterWaveSize = 0
terrain.WaterWaveSpeed = 0
terrain.WaterColor = Color3.fromRGB(64, 140, 220) -- the tint you see under water

-- Fills a box with swimmable water
function Swim.Fill(cframe: CFrame, size: Vector3)
	terrain:FillBlock(cframe, size, Enum.Material.Water)
end

-- Takes the swimmable water out of a box (only water; nothing else is terrain)
function Swim.Clear(low: Vector3, high: Vector3)
	local region = Region3.new(low, high):ExpandToGrid(4)
	terrain:ReplaceMaterial(region, 4, Enum.Material.Water, Enum.Material.Air)
end

-- Every water sheet (a part named "Water") under `root` becomes swimmable
function Swim.FillSheets(root: Instance)
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "Water" then
			Swim.Fill(part.CFrame, part.Size)
		end
	end
end

return Swim
