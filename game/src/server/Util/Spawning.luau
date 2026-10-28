--!strict
-- Spawning in the shared places (Town and the resource worlds): a player's character
-- loads once their data has, comes back after they die, and anyone who falls off is put
-- back at the spawn point instead of dying in the void.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.Parent.Services.DataService)

local Spawning = {}

local function spawnCharacter(player: Player, spawnPoint: SpawnLocation)
	-- With streaming on, load the ground around the spawn on their screen first
	pcall(function()
		player:RequestStreamAroundAsync(spawnPoint.Position)
	end)
	if player.Parent == Players then
		player:LoadCharacterAsync()
	end
end

-- `fallY`: anyone below this height is put back. `onArrived` runs once per player, after
-- their first character spawns.
function Spawning.Start(spawnPoint: SpawnLocation, fallY: number, onArrived: ((Player) -> ())?)
	Players.CharacterAutoLoads = false

	DataService.OnDataLoaded(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.Died:Connect(function()
				task.wait(Players.RespawnTime)
				if player.Character == character then
					spawnCharacter(player, spawnPoint)
				end
			end)
		end)
		spawnCharacter(player, spawnPoint)
		if onArrived then
			onArrived(player)
		end
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.5 then
			return
		end
		elapsed = 0
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if character and root and root:IsA("BasePart") and root.Position.Y < fallY then
				root.AssemblyLinearVelocity = Vector3.zero
				character:PivotTo(spawnPoint.CFrame + Vector3.new(0, 4, 0))
			end
		end
	end)
end

-- An invisible spawn point standing on `feet`, facing `facing`
function Spawning.MakeSpawn(feet: Vector3, facing: Vector3, parent: Instance): SpawnLocation
	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "Spawn"
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.CFrame = CFrame.lookAt(feet - Vector3.new(0, 0.5, 0), feet - Vector3.new(0, 0.5, 0) + facing)
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Transparency = 1
	spawnPoint.Duration = 0
	spawnPoint.Neutral = true
	spawnPoint.Parent = parent
	return spawnPoint
end

return Spawning
