--!strict
-- Server entry point. Starts each service once.

local Services = script.Parent.Services

local DataService = require(Services.DataService)
local FarmService = require(Services.FarmService)
local GatherService = require(Services.GatherService)
local IslandService = require(Services.IslandService)
local Leaderstats = require(Services.Leaderstats)
local MarketService = require(Services.MarketService)
local StateService = require(Services.StateService)

StateService.Start()
IslandService.Start()
GatherService.Start()
FarmService.Start()
MarketService.Start()
Leaderstats.Start()
-- Last, so every service is listening before player data loads
DataService.Start()
