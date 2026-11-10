--!nocheck
-- A photo booth for badge and pass pictures (art/scripts/badge_icons.ps1): run it in Edit mode of any Rojo-built place
-- (tools/studio_mcp.py luau art/scripts/badge_booth.luau <studio_id> Edit), then take the picture with Studio MCP's
-- screen_capture from about 4-8 studs in front, looking at BOOTH (camera_position {0, 3000.2, 4.2}, look_at {0, 3000, 0}
-- for the swords). Never save or publish the window afterwards. The captures land in tools/: move them to
-- art/renders/badges/<Key>_raw.png. Magenta works for everything; green suits things with no green in them.
-- Change SUBJECT to choose what's in it. Close the camera in until the subject fills most of the frame: Studio's
-- viewport is smaller than the capture, so a far subject comes out soft.

local SUBJECT = "Swords" -- Swords, Slime, OpenCrate, Crate
local BACKDROP = Color3.fromRGB(255, 0, 255)

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BOOTH = Vector3.new(0, 3000, 0)
local old = workspace:FindFirstChild("BadgeBooth")
if old then
	old:Destroy()
end
local booth = Instance.new("Folder")
booth.Name = "BadgeBooth"
booth.Parent = workspace

-- Matte, not Neon: Neon's glow bleeds onto the subject's edges
local back = Instance.new("Part")
back.Anchored = true
back.Size = Vector3.new(600, 600, 1)
back.Material = Enum.Material.SmoothPlastic
back.Color = BACKDROP
back.CFrame = CFrame.new(BOOTH + Vector3.new(0, 0, -60))
back.CastShadow = false
back.Parent = booth

local function put(source: BasePart, cf: CFrame, scale: number?): BasePart
	local part = source:Clone()
	part.Anchored = true
	part.Size *= scale or 1
	part.CFrame = cf
	part.Parent = booth
	return part
end

local function mesh(meshId: string, textureId: string?, size: Vector3, cf: CFrame): MeshPart
	local part = AssetService:CreateMeshPartAsync(Content.fromUri(meshId))
	part.TextureID = textureId or ""
	part.Anchored = true
	part.Size = size
	part.CFrame = cf
	part.Parent = booth
	return part
end

local Items = ReplicatedStorage.ItemModels
if SUBJECT == "Swords" then -- Warzone Ready: crossed Crystal and Ruby swords behind the shield
	put(Items.CrystalSword, CFrame.new(BOOTH + Vector3.new(0, 0, -0.3)), 1.3)
	put(Items.RubySword, CFrame.new(BOOTH + Vector3.new(0, 0, -0.5)) * CFrame.Angles(0, math.pi, 0), 1.3)
	put(ReplicatedStorage.ShieldModels.Shield, CFrame.new(BOOTH + Vector3.new(0, -0.35, 0.4)), 0.62)
elseif SUBJECT == "Slime" then -- Monster Slayer: camera {0, 3002.2, 8.2} looking at {0, 2999.9, 0}
	local art = require(ReplicatedStorage.Shared.MonsterArt).Slime
	mesh(art.Mesh, art.Texture, art.Size, CFrame.new(BOOTH + Vector3.new(0.5, 0, 0)) * CFrame.Angles(0, math.rad(162), 0))
	put(Items.IronSword, CFrame.new(BOOTH + Vector3.new(-1.7, -0.9, 2.3)) * CFrame.Angles(0, 0, math.rad(8)), 1.45)
elseif SUBJECT == "OpenCrate" then -- Crate Opener: camera {0, 3002, 4.6} looking at {0, 2999.95, 0}
	local CrateArt = require(ReplicatedStorage.Shared.CrateArt)
	local turn = CFrame.Angles(0, math.rad(152), 0)
	local body, lid = CrateArt.Parts.Body, CrateArt.Parts.Lid
	mesh(body.Mesh, CrateArt.Texture, body.Size, CFrame.new(BOOTH + Vector3.new(0, -0.6, 0)) * turn)
	mesh(
		lid.Mesh,
		CrateArt.Texture,
		lid.Size,
		CFrame.new(BOOTH + Vector3.new(0.1, 0.75, -0.3)) * turn * CFrame.Angles(math.rad(24), 0, math.rad(-10))
	)
elseif SUBJECT == "Crate" then -- the crate pass and product: camera {0, 3001.6, 4.2} looking at {0, 2999.95, 0}
	put(Items.LootCrate, CFrame.new(BOOTH) * CFrame.Angles(0, math.rad(150), 0), 2.2)
end
return "booth ready: " .. SUBJECT
