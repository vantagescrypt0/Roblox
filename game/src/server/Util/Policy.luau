--!strict
-- What Roblox allows each player (PolicyService), asked once and remembered while they're in the server. If Roblox
-- can't answer, the answer is no for now and it's asked again next time. Studio has no real answer, so tests are
-- allowed everything. See [[Kits]].

local PolicyService = game:GetService("PolicyService")
local RunService = game:GetService("RunService")

type Rules = { RandomItemsRestricted: boolean, TradingAllowed: boolean }

local Policy = {}

local known: { [Player]: Rules } = setmetatable({}, { __mode = "k" }) :: any

local function rulesFor(player: Player): Rules?
	local rules = known[player]
	if rules then
		return rules
	end
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok then
		return nil
	end
	local fresh: Rules = {
		RandomItemsRestricted = info.ArePaidRandomItemsRestricted == true,
		TradingAllowed = info.IsPaidItemTradingAllowed == true,
	}
	known[player] = fresh
	return fresh
end

-- Is this player barred from paid random items such as Loot Crates?
function Policy.PaidRandomRestricted(player: Player): boolean
	if RunService:IsStudio() then
		return false
	end
	local rules = rulesFor(player)
	return rules == nil or rules.RandomItemsRestricted
end

-- May this player trade? Where paid items can't be traded, Roblox recommends turning trading off altogether.
function Policy.TradingAllowed(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	local rules = rulesFor(player)
	return rules ~= nil and rules.TradingAllowed
end

return Policy
