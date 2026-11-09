--!strict
-- Hands out Roblox badges (shared/Badges.luau). A badge that hasn't been made on Roblox yet is
-- skipped, and Roblox ignores one you already have, so anything can call Give as often as it likes.

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badges = require(ReplicatedStorage.Shared.Badges)
local DataService = require(script.Parent.DataService)

local AwardService = {}

-- Asked for already this session, so a moment that repeats doesn't use up Roblox's request limit
local given: { [Player]: { [string]: boolean } } = {}

function AwardService.Give(player: Player, key: Badges.Key)
	local badge = Badges[key]
	if badge.Id == 0 then
		return
	end
	local mine = given[player]
	if not mine then
		mine = {}
		given[player] = mine
	end
	if mine[key] then
		return
	end
	mine[key] = true
	task.spawn(function()
		local ok = pcall(function()
			return BadgeService:AwardBadge(player.UserId, badge.Id)
		end)
		if not ok then
			mine[key] = nil -- the next time it happens can try again
		end
	end)
end

function AwardService.Start()
	DataService.OnDataLoaded(function(player)
		AwardService.Give(player, "Welcome")
	end)
	Players.PlayerRemoving:Connect(function(player)
		given[player] = nil
	end)
end

return AwardService
