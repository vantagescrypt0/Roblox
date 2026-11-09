--!strict
-- Monster spawners on your own island (Monsters.luau, Slivers.luau; the late game's two only come
-- from loot crates and Warzone chests). One keeps a monster standing next to it: kill it and
-- another comes after a while (the same wait as the node of the same rank). Only you can fight
-- them, and they give no slivers, as slivers only come from the Slaying World.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Monsters = require(ReplicatedStorage.Shared.Monsters)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local IslandService = require(script.Parent.IslandService)
local MobService = require(script.Parent.MobService)

local SIZE = Blocks.Size
local CHECK_EVERY = 1

-- What one spawner is doing
type Spawner = { Model: Model?, NextAt: number }

local SpawnerService = {}

local spawners: { [Player]: { [string]: Spawner } } = {}

-- A free spot beside the spawner, on the ground it stands on: first the sides, then on top
local function besideSpawner(world: BlockWorld.World, x: number, y: number, z: number): Vector3
	for _, d in { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 } } do
		local nx, nz = x + d[1], z + d[2]
		if
			not BlockWorld.get(world, nx, y, nz)
			and not BlockWorld.get(world, nx, y + 1, nz)
			and BlockWorld.get(world, nx, y - 1, nz)
		then
			return BlockWorld.position(world, nx, y, nz) - Vector3.new(0, SIZE / 2, 0)
		end
	end
	return BlockWorld.position(world, x, y + 1, z) - Vector3.new(0, SIZE / 2, 0)
end

local function check(player: Player, now: number)
	local island = IslandService.GetIsland(player)
	if not island then
		return
	end
	local list = spawners[player]
	if not list then
		list = {}
		spawners[player] = list
	end
	for cellKey, node in island.Nodes do
		local monster = Monsters.BySpawner[node.Block]
		if monster then
			local spawner = list[cellKey]
			if not spawner then
				spawner = { Model = nil, NextAt = now }
				list[cellKey] = spawner
			end
			if not spawner.Model and now >= spawner.NextAt then
				local this = spawner
				this.Model = MobService.Spawn(monster, besideSpawner(island.World, node.X, node.Y, node.Z), {
					Owner = player,
					OnDied = function()
						this.Model = nil
						this.NextAt = os.clock() + monster.Respawn
					end,
				})
			end
		end
	end
end

function SpawnerService.Start()
	MobService.Start()
	Players.PlayerRemoving:Connect(function(player)
		spawners[player] = nil
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= CHECK_EVERY then
			elapsed = 0
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				check(player, now)
			end
		end
	end)
end

return SpawnerService
