--!strict
-- Skill challenges (Challenges.luau): counts every crop, log and ore a player gathers this
-- season, and marks a milestone reached when the count gets there. BlockService and
-- FarmService call ChallengeService.Count when something is gathered (only natural blocks
-- and wild or planted crops, the same things that give skill XP).
-- The rewards (pets, armor sets, trophies) arrive with those systems; until then a reached
-- milestone is remembered and shown in the Skills window.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Challenges = require(ReplicatedStorage.Shared.Challenges)
local DataService = require(script.Parent.DataService)
local StateService = require(script.Parent.StateService)

local ChallengeService = {}

-- Counts `amount` (default 1) of a resource gathered: "Wheat", "Wood", "CoalOre"...
function ChallengeService.Count(player: Player, resourceId: string, amount: number?)
	local resource = Challenges.ById[resourceId]
	local data = DataService.GetData(player)
	if not resource or not data then
		return
	end
	local counts = data.Challenges.Counts
	local count = (counts[resourceId] or 0) + (amount or 1)
	counts[resourceId] = count
	for _, milestone in resource.Milestones do
		if count >= milestone.Count and not data.Challenges.Reached[milestone.Id] then
			data.Challenges.Reached[milestone.Id] = true
			StateService.Notify(player, `Challenge complete: {milestone.Name} unlocked!`, "level")
		end
	end
	DataService.MarkChanged(player)
end

return ChallengeService
