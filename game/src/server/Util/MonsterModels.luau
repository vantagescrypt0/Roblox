--!strict
-- Real meshes for the monsters, drops and props of the Slaying World, generated in Studio
-- (art/generated/monster_prompts.json, ids in MonsterArt.luau). Made at server start and put in
-- ReplicatedStorage.MonsterModels, so monsters, statues, spawners and item pictures can copy them.

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonsterArt = require(ReplicatedStorage.Shared.MonsterArt)

local MonsterModels = {}

local folder: Folder?

local function make(name: string): BasePart
	local art = MonsterArt[name]
	local ok, part = pcall(function()
		return AssetService:CreateMeshPartAsync(art.Mesh)
	end)
	local mesh: BasePart
	if ok then
		local generated = part :: MeshPart
		if art.Texture ~= "" then
			generated.TextureID = art.Texture
		end
		mesh = generated
	else
		warn(`[MonsterModels] {name} didn't load: {part}`)
		local box = Instance.new("Part")
		box.Color = Color3.fromRGB(150, 120, 160)
		mesh = box
	end
	mesh.Name = name
	mesh.Size = art.Size
	mesh.CFrame = CFrame.new(0, 50000, 0) * art.Turn
	mesh.Anchored = true
	mesh.CanCollide = false
	mesh.CanTouch = false
	mesh.CanQuery = false
	mesh.CastShadow = true
	return mesh
end

-- Makes every model once (they're in ReplicatedStorage for the client's item pictures too)
function MonsterModels.Make()
	if folder then
		return
	end
	local made = Instance.new("Folder")
	made.Name = "MonsterModels"
	for name in MonsterArt do
		make(name).Parent = made
	end
	made.Parent = ReplicatedStorage
	folder = made
end

function MonsterModels.Get(name: string): BasePart
	MonsterModels.Make()
	local found = (folder :: Folder):FindFirstChild(name)
	assert(found and found:IsA("BasePart"), `No monster model {name}`)
	return found
end

-- A copy of a model, `height` studs tall, standing with its feet at `feet`, turned by `turn`
-- about the up axis and looking along -Z before that
local function place(parent: Instance, source: BasePart, feet: Vector3, height: number, frame: CFrame): BasePart
	local copy = source:Clone()
	local scale = height / source.Size.Y
	copy.Size = source.Size * scale
	copy.CFrame = CFrame.new(feet + Vector3.new(0, copy.Size.Y / 2, 0)) * frame
	copy.Anchored = true
	copy.Parent = parent
	return copy
end

-- A giant statue of a monster, looking along `facing`
function MonsterModels.Statue(parent: Instance, monster: any, feet: Vector3, height: number, facing: Vector3)
	local source = MonsterModels.Get(monster.Model)
	local look = CFrame.lookAt(Vector3.zero, facing)
	local statue = place(parent, source, feet, height, look * source.CFrame.Rotation)
	statue.Name = `{monster.Id}Statue`
	return statue
end

-- A generated prop standing on the ground, turned about the up axis
function MonsterModels.Prop(parent: Instance, name: string, feet: Vector3, height: number, turn: number)
	local source = MonsterModels.Get(name)
	local copy = place(parent, source, feet, height, CFrame.Angles(0, turn, 0) * source.CFrame.Rotation)
	copy.Name = name
	return copy
end

return MonsterModels
