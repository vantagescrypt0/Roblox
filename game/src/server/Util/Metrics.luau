--!strict
-- What shows up in Roblox's Analytics dashboard (Creator Hub > Analytics): how far new players get through the
-- beginner quests, where coins come from and go, and custom events for the moments that matter. It does nothing
-- in Studio, and a failed call never gets in the way of the game.

local AnalyticsService = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")

local LIVE = not RunService:IsStudio()

local Metrics = {}

local function send(call: () -> ())
	if LIVE then
		task.spawn(pcall, call)
	end
end

-- A new player finished this beginner quest (numbered from 1, in order)
function Metrics.Onboarding(player: Player, step: number, name: string)
	send(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
	end)
end

-- Coins earned (positive amount) or spent (negative), and what for
function Metrics.Coins(player: Player, amount: number, balance: number, kind: "Shop" | "Gameplay", what: string)
	send(function()
		local flow = if amount >= 0 then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink
		local transaction = Enum.AnalyticsEconomyTransactionType[kind].Name
		AnalyticsService:LogEconomyEvent(player, flow, "Coins", math.abs(amount), balance, transaction, what)
	end)
end

-- Something worth counting. Roblox allows 100 different event names, so names must be a fixed list, never built
-- from player input.
function Metrics.Event(player: Player, name: string, value: number?)
	send(function()
		AnalyticsService:LogCustomEvent(player, name, value or 1)
	end)
end

return Metrics
