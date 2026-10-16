--!strict
-- Server entry point. Starts each service once.

local Services = script.Parent.Services

local CombatService = require(Services.CombatService)
local CraftingService = require(Services.CraftingService)
local DataService = require(Services.DataService)
local DevService = require(Services.DevService)
local FarmService = require(Services.FarmService)
local GatherService = require(Services.GatherService)
local IslandService = require(Services.IslandService)
local Leaderstats = require(Services.Leaderstats)
local MarketService = require(Services.MarketService)
local MobService = require(Services.MobService)
local StateService = require(Services.StateService)
local WarzoneService = require(Services.WarzoneService)

StateService.Start()
IslandService.Start()
GatherService.Start()
FarmService.Start()
MarketService.Start()
CraftingService.Start()
WarzoneService.Start()
MobService.Start()
CombatService.Start()
Leaderstats.Start()
DevService.Start()
-- Last, so every service is listening before player data loads
DataService.Start()
