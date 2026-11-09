--!strict
-- The monster spawners' look: a block-sized invisible part (what you aim at and stand on) holding
-- the generated cage with a little copy of its monster inside. Put in ReplicatedStorage.Blocks
-- like the trophies and stations, so islands draw them like any block and the Bag shows them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Monsters = require(ReplicatedStorage.Shared.Monsters)
local MonsterModels = require(script.Parent.MonsterModels)

local SIZE = Blocks.Size

local SpawnerModels = {}

local function weldTo(root: BasePart, part: BasePart)
	local joint = Instance.new("Weld")
	joint.Part0 = root
	joint.Part1 = part
	joint.C0 = root.CFrame:ToObjectSpace(part.CFrame)
	joint.Parent = part
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

local function build(monster: Monsters.Monster): Part
	local root = Instance.new("Part")
	root.Name = monster.Spawner
	root.Size = Vector3.one * SIZE
	root.CFrame = CFrame.new()
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = true

	local cage = MonsterModels.Get("Spawner"):Clone()
	cage.Size = cage.Size * (SIZE / cage.Size.Y)
	cage.Name = "Cage"
	cage.CFrame = root.CFrame
	cage.Parent = root
	weldTo(root, cage)

	local source = MonsterModels.Get(monster.Model)
	local little = source:Clone()
	little.Size = source.Size * (1.5 / source.Size.Y)
	little.Name = "Monster"
	little.CFrame = root.CFrame * CFrame.new(0, -0.4, 0)
	little.Parent = root
	weldTo(root, little)
	return root
end

function SpawnerModels.Make()
	local blocks = ReplicatedStorage:FindFirstChild("Blocks")
	if not blocks then
		return
	end
	for _, monster in Monsters.List do
		if not blocks:FindFirstChild(monster.Spawner) then
			build(monster).Parent = blocks
		end
	end
end

return SpawnerModels
