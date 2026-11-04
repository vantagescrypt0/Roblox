--!strict
-- Sprinting, like Minecraft: the client asks (double-tap W or hold Ctrl) and the server sets the
-- speed. In the Warzone it burns hunger and stops when you're too hungry. Blocking stops it, and so
-- does landing a charged hit (CombatService). The "Sprinting" attribute on the player is what the
-- rules and every screen's animations read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WarzoneService = require(script.Parent.WarzoneService)

local HUNGER_PER_SECOND = 0.3 -- on top of what running burns
local TICK = 0.25

local SprintService = {}

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function tooHungry(player: Player): boolean
	local hunger = player:GetAttribute("Hunger")
	return WarzoneService.IsPlaying(player) and type(hunger) == "number" and hunger <= Combat.SprintHunger
end

function SprintService.Stop(player: Player)
	if player:GetAttribute("Sprinting") then
		player:SetAttribute("Sprinting", nil)
		local humanoid = humanoidOf(player)
		if humanoid and not WarzoneService.IsBlocking(player) then
			humanoid.WalkSpeed = Combat.WalkSpeed
		end
	end
end

local function onSprint(player: Player, on: unknown)
	if on ~= true then
		SprintService.Stop(player)
		return
	end
	local humanoid = humanoidOf(player)
	if humanoid and humanoid.Health > 0 and not WarzoneService.IsBlocking(player) and not tooHungry(player) then
		player:SetAttribute("Sprinting", true)
		humanoid.WalkSpeed = Combat.SprintSpeed
	end
end

function SprintService.Start()
	Remotes.Sprint.OnServerEvent:Connect(onSprint)
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("Sprinting") then
					if WarzoneService.IsBlocking(player) or tooHungry(player) then
						SprintService.Stop(player)
					else
						WarzoneService.Burn(player, HUNGER_PER_SECOND * TICK)
					end
				end
			end
		end
	end)
end

return SprintService
