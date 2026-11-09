--!strict
-- How fast someone walks: blocking, sprinting or neither (their attributes), times anything speeding or slowing them,
-- like Rage or being frozen. Everything that changes one of those calls Apply, so they can't undo each other.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(ReplicatedStorage.Shared.Combat)

local Speed = {}

local scales: { [Player]: { [string]: number } } = {}
local frozen: { [Player]: { Height: number, Power: number } } = {}

function Speed.Apply(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local base = if player:GetAttribute("Blocking")
		then Combat.BlockSpeed
		elseif player:GetAttribute("Sprinting") then Combat.SprintSpeed
		else Combat.WalkSpeed
	local scale = 1
	local mine = scales[player]
	if mine then
		for _, value in mine do
			scale *= value
		end
	end
	humanoid.WalkSpeed = base * scale
	local stuck = scale == 0
	-- A frozen character can't jump either. Only these properties reach the player's own machine, which moves them.
	if stuck and not frozen[player] then
		frozen[player] = { Height = humanoid.JumpHeight, Power = humanoid.JumpPower }
		humanoid.JumpHeight, humanoid.JumpPower = 0, 0
	elseif not stuck and frozen[player] then
		local before = frozen[player]
		frozen[player] = nil
		humanoid.JumpHeight, humanoid.JumpPower = before.Height, before.Power
	end
end

-- `source` is what's doing it; nil takes that one off
function Speed.Set(player: Player, source: string, scale: number?)
	local mine = scales[player] or {}
	mine[source] = scale
	scales[player] = mine
	Speed.Apply(player)
end

-- Back to normal: a new character, or they've left
function Speed.Clear(player: Player)
	scales[player] = nil
	frozen[player] = nil
end

return Speed
