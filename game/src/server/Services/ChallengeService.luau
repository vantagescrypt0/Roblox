--!strict
-- Skill challenges (Challenges.luau): counts every crop, log and ore a player gathers this
-- season, and marks a milestone reached when the count gets there. BlockService and
-- FarmService call ChallengeService.Count when something is gathered (only natural blocks
-- and wild or planted crops, the same things that give skill XP).
-- Each milestone gives its reward (Gear.luau): a pet, an armor set or a trophy, straight into
-- the Bag. Reached milestones are remembered, so each gives its reward once a season.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Challenges = require(ReplicatedStorage.Shared.Challenges)
local Gear = require(ReplicatedStorage.Shared.Gear)
local Items = require(ReplicatedStorage.Shared.Items)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
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
			local reward = Gear.Rewards[milestone.Id]
			if reward then
				InventoryService.Add(player, reward, 1)
				StateService.Notify(player, `Challenge complete! {Items[reward].Name} is in your Bag`, "level")
			end
		end
	end
	DataService.MarkChanged(player)
end

return ChallengeService
