--!strict
-- Tunable numbers shared by server and client.

local Config = {}

Config.Island = table.freeze({
	-- Y position of each island's grass surface
	Height = 200,
	-- Distance between island centers
	Spacing = 220,
	PlotsPerRow = 6,
	Radius = 20,
	-- Model in ServerStorage.Assets; a greybox island is built if it's missing
	TemplateName = "StarterIsland",
	-- Fall this far below your island and you're put back on it
	FallLimit = 120,
})

return table.freeze(Config)
