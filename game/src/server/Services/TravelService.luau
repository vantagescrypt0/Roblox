--!strict
-- Moves players between the experience's places with TeleportService: from their island
-- to the Town (its own servers) and back. Walk into a portal's glowing field, or use its
-- prompt. The screen fades out first; if the teleport fails the player is told, the fade
-- lifts and they stay where they are. (Teleports don't work in Studio playtests.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Prompts = require(script.Parent.Parent.Util.Prompts)
local IslandService = require(script.Parent.IslandService)
local StateService = require(script.Parent.StateService)

local FADE_TIME = 0.4
local TOUCH_COOLDOWN = 4

local TravelService = {}

local travelling: { [Player]: boolean } = {}
local lastTouch: { [Player]: number } = {}

local function failed(player: Player, message: string)
	travelling[player] = nil
	Remotes.Travel:FireClient(player, "Failed")
	StateService.Notify(player, message, "bad")
end

function TravelService.Go(player: Player, destination: Places.Kind)
	if travelling[player] then
		return
	end
	local placeId = Places.Ids[destination]
	if RunService:IsStudio() then
		StateService.Notify(player, `Travelling to the {destination} only works in the published game`, "bad")
		return
	elseif placeId == 0 then
		StateService.Notify(player, `The {destination} isn't open yet`, "bad")
		return
	end
	travelling[player] = true
	Remotes.Travel:FireClient(player, destination)
	task.wait(FADE_TIME)
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ From = Places.Current() })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(placeId, { player }, options)
	end)
	if not ok then
		warn(`[TravelService] teleport to {destination} failed: {err}`)
		failed(player, "Couldn't travel right now. Try again in a moment.")
	end
end

-- Lets a portal field send players somewhere: walking into it or using its prompt.
-- `allowed` decides who may use it (the island portal is only for the island's owner).
function TravelService.AddPortal(
	field: BasePart,
	destination: Places.Kind,
	action: string,
	allowed: (Player) -> boolean
)
	local prompt = Prompts.Create(field, { Action = action, Object = "Portal", Hold = 0.4, Distance = 12 })
	prompt.Triggered:Connect(function(player)
		if allowed(player) then
			TravelService.Go(player, destination)
		end
	end)
	field.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or not allowed(player) then
			return
		end
		local now = os.clock()
		if now - (lastTouch[player] or 0) < TOUCH_COOLDOWN then
			return
		end
		lastTouch[player] = now
		TravelService.Go(player, destination)
	end)
end

function TravelService.Start()
	TeleportService.TeleportInitFailed:Connect(function(player, _result, message)
		warn(`[TravelService] teleport failed for {player.Name}: {message}`)
		failed(player, "Couldn't travel right now. Try again in a moment.")
	end)
	Players.PlayerRemoving:Connect(function(player)
		travelling[player] = nil
		lastTouch[player] = nil
	end)

	-- Island servers: each island's portal leads to the Town
	if Places.Current() == "Island" then
		IslandService.OnIslandCreated(function(owner, island)
			TravelService.AddPortal(island.PortalSurface, "Town", "Travel to Town", function(player)
				return player == owner
			end)
		end)
	end
end

return TravelService
