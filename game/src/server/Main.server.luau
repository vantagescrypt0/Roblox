--!strict
-- Server entry point. Starts each service once.
-- The Warzone (WarzoneService, MobService) is built but switched off until it's added
-- to the Town.

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

StateService.Start()
IslandService.Start()
TownService.Start()
BlockService.Start()
FarmService.Start()
MarketService.Start()
CraftingService.Start()
CombatService.Start()
HotbarService.Start()
QuestService.Start()
Leaderstats.Start()
DevService.Start()
-- Last, so every service is listening before player data loads
DataService.Start()
