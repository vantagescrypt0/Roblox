--!strict
-- Tunable numbers shared by server and client.

local Config = {}

Config.Island = table.freeze({
	-- Y position of each island's grass surface
	Height = 200,
	-- Distance between island centers (studs): room for the biggest build border
	-- (IslandTiers) on both neighbours, plus a gap
	Spacing = 2400,
	PlotsPerRow = 6,
	Radius = 20,
	-- Model in ServerStorage.Assets; a greybox island is built if it's missing
	TemplateName = "StarterIsland",
	-- Fall this far below your island and you're put back on it
	FallLimit = 120,
})

-- Uploaded copy of art/textures/item_icons.png (all item icons on one sheet, see ItemArt.luau).
-- Empty = icons fall back to live 3D previews. Uploaded 2026-10-26 with the zone items
-- (gold, pumpkins, melons, the new woods), as the texture of a plane imported with Import 3D
-- (see art/README.md).
Config.ItemIconSheet = "rbxassetid://108158291167421"

-- Who can fly (double-tap Space, see client/FlightController): user ids. Only the game's
-- owner for now (koiopio).
Config.Flyers = table.freeze({
	[545120355] = true,
})
Config.FlySpeed = 70 -- studs per second, across
Config.FlyClimb = 45 -- studs per second, up and down

return table.freeze(Config)
