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

-- Uploaded copies of the icon sheets, art/textures/item_icons.png then item_icons_2.png and on
-- (64 icons to a sheet, see ItemArt.luau). An icon whose sheet isn't listed falls back to a
-- live 3D preview. Uploaded as the texture of a plane imported with Import 3D (see
-- art/README.md); every re-render of the sheets needs a new upload, since cells move.
Config.ItemIconSheets = table.freeze({
	"rbxassetid://105422127167243",
	"rbxassetid://137178541756025",
})

-- Who can fly (double-tap Space, see client/FlightController): user ids. Only the game's
-- owner for now (koiopio).
Config.Flyers = table.freeze({
	[545120355] = true,
})
Config.FlySpeed = 70 -- studs per second, across
Config.FlyClimb = 45 -- studs per second, up and down

return table.freeze(Config)
