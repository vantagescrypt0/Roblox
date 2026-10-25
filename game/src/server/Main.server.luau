--!strict
-- Server entry point. Starts each service once, depending on which place this server is
-- running (Places.luau):
--   Island  everyone's islands: blocks, farming, crafting, island expansion
--   Town    the shared plaza with the Market, the Merchant and player trading
-- The Warzone (WarzoneService, MobService) is built but switched off until it's added
-- to the Town.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Places = require(ReplicatedStorage.Shared.Places)
local Services = script.Parent.Services

local BlockService = require(Services.BlockService)
local CombatService = require(Services.CombatService)
local CraftingService = require(Services.CraftingService)
local DataService = require(Services.DataService)
local DevService = require(Services.DevService)
local FarmService = require(Services.FarmService)
local HotbarService = require(Services.HotbarService)
local IslandService = require(Services.IslandService)
local Leaderstats = require(Services.Leaderstats)
local MarketService = require(Services.MarketService)
local QuestService = require(Services.QuestService)
local StateService = require(Services.StateService)
local TownService = require(Services.TownService)
local TradeService = require(Services.TradeService)
local TravelService = require(Services.TravelService)

StateService.Start()
if Places.Current() == "Town" then
	TownService.Start()
	MarketService.Start()
	TradeService.Start()
else
	IslandService.Start()
	BlockService.Start()
	FarmService.Start()
	CraftingService.Start()
end
TravelService.Start()
CombatService.Start()
HotbarService.Start()
QuestService.Start()
Leaderstats.Start()
DevService.Start()
-- Last, so every service is listening before player data loads
DataService.Start()
