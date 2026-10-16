-- Paste into the Roblox Studio command bar (Edit mode) right after importing
-- art/export/Islands.fbx and art/export/Props.fbx (Anchored on, Scale Unit = Stud).
-- Builds ServerStorage.Islands (Tier1..4) and ServerStorage.Props, ready to
-- "Save to File" as game/assets/Islands.rbxm and game/assets/Props.rbxm.
-- Then delete the two temporary folders; Rojo syncs the files into ServerStorage.Assets.

-- Islands: split *_T<n> objects into one model per tier
local SS = game.ServerStorage
local src = workspace:FindFirstChild("Islands")
local islands = Instance.new("Folder")
islands.Name = "Islands"
for tier = 1, 4 do
	local m = Instance.new("Model")
	m.Name = "Tier" .. tier
	for _, p in src:GetDescendants() do
		if p:IsA("BasePart") then
			local base, t = p.Name:match("^(.-)_T(%d+)$")
			if not base and p.Parent then
				base, t = p.Parent.Name:match("^(.-)_T(%d+)$")
			end
			if base and tonumber(t) == tier then
				p.Name = base
				p.Anchored = true
				if base == "Decor" then
					p.CanCollide = false
					p.CanQuery = false
				end
				if base:match("^TreeLeaves") then
					p.CanCollide = false
				end
				if base:match("^Marker_") then
					p.Transparency = 1
					p.CanCollide = false
					p.CanQuery = false
					p.CastShadow = false
				end
				if base == "GrassTop" then
					p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
				end
				p.Parent = m
			end
		end
	end
	m.PrimaryPart = m:FindFirstChild("GrassTop")
	m.Parent = islands
end
islands.Parent = SS
src:Destroy()

-- Props: group parts into one model per prop; glowing parts become Neon
local srcP = workspace:FindFirstChild("Props")
local props = Instance.new("Folder")
props.Name = "Props"
local byName = {}
for _, p in srcP:GetDescendants() do
	if p:IsA("BasePart") then
		byName[p.Name] = p
	end
end
local groups = {
	Workbench = { "Workbench" },
	Market = { "MarketStall", "MarketSignFace", "MarketLanternGlow" },
	Portal = { "PortalFrame", "PortalRunes", "PortalSurface" },
	Planter = { "PlanterBed" },
	Crop_Sprout = { "Crop_Sprout" },
	Crop_Young = { "Crop_Young" },
	Crop_Wheat = { "Crop_Wheat" },
	Crop_Carrot = { "Crop_Carrot" },
	Crop_Potato = { "Crop_Potato" },
	Crop_Glowberry = { "Crop_Glowberry", "Crop_GlowberryGlow" },
}
local glow = {
	MarketLanternGlow = Color3.fromRGB(255, 210, 122),
	PortalRunes = Color3.fromRGB(181, 124, 255),
	Crop_GlowberryGlow = Color3.fromRGB(122, 232, 255),
}
for groupName, names in groups do
	local m = Instance.new("Model")
	m.Name = groupName
	for _, n in names do
		local p = byName[n]
		p.Anchored = true
		if groupName:match("^Crop") then
			p.CanCollide = false
			p.CanQuery = false
		end
		if glow[n] then
			p.TextureID = ""
			p.Color = glow[n]
			p.Material = Enum.Material.Neon
		end
		if n == "PortalSurface" then
			p.TextureID = ""
			p.CanCollide = false
		end
		p.Parent = m
	end
	m.PrimaryPart = m:FindFirstChild(names[1])
	m.Parent = props
end
props.Parent = SS
srcP:Destroy()
