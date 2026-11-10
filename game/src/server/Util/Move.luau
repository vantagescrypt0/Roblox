--!strict
-- Every move the server makes a player's character take goes through here: putting it somewhere (a spawn, out
-- of the void, a Warzone arrival) or throwing it (knockback, which the player's own client carries out). The
-- anti-cheat (Services/AntiCheatService) listens, so it never takes the server's own moves for cheating.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Move = {}

type PlacedListener = (player: Player, to: CFrame) -> ()
type PushedListener = (player: Player, velocity: Vector3) -> ()

local placedListeners: { PlacedListener } = {}
local pushedListeners: { PushedListener } = {}

-- Puts a character somewhere (its root part ends up at `to`)
function Move.To(character: Model, to: CFrame)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		for _, listener in placedListeners do
			listener(player, to)
		end
	end
	character:PivotTo(to)
end

-- Throws a player: their client carries it out (Shared/Knockback.luau)
function Move.Push(player: Player, velocity: Vector3)
	for _, listener in pushedListeners do
		listener(player, velocity)
	end
	Remotes.Knockback:FireClient(player, velocity)
end

function Move.OnPlaced(listener: PlacedListener)
	table.insert(placedListeners, listener)
end

function Move.OnPushed(listener: PushedListener)
	table.insert(pushedListeners, listener)
end

return Move
