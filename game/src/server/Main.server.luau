--!strict
-- Server entry point. Starts each service once.

local Services = script.Parent.Services

local DataService = require(Services.DataService)
local IslandService = require(Services.IslandService)
local Leaderstats = require(Services.Leaderstats)

IslandService.Start()
Leaderstats.Start()
DataService.Start()
