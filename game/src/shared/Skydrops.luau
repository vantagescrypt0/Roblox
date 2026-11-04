--!strict
-- Skydrops: better chests that fall from the sky in the Warzone ([[Warzone]], Services/SkydropService).
-- Your rules: a regular one every 10 minutes with a marker, a Legendary one every 4 to 8 hours with none, and
-- a Legendary has a health bar and has to be mined open, slowly enough that people fight over it. How slow is
-- Claude's pick, all here: a crack takes as long as a block this tough, each crack takes one off the bar, and
-- it takes CRACKS of them. With one person mining: about 30 minutes with a Wooden Pickaxe, 10 with Iron, 5 with
-- Ruby. Several people mining bring the same bar down, so it's faster, and they're all there to fight.

local Tools = require(script.Parent.Tools)

local CHEST_HARDNESS = 8
-- All servers share one list of times: each 6-hour stretch has one, in its first 2 hours, so they're 4 to 8 hours
-- apart. A server rarely lives that long, so a timer of its own would hardly ever go off.
local LEGENDARY_STRETCH = 6 * 60 * 60
local LEGENDARY_SPREAD = 2 * 60 * 60

local Skydrops = {
	Every = 10 * 60, -- seconds between regular ones
	MostOut = 3, -- regular ones left lying about: the oldest goes when another falls
	FallTime = 8, -- seconds in the air
	FallFrom = 260, -- studs above where it lands
	Cracks = 300,
	Gold = Color3.fromRGB(255, 214, 110),
	Purple = Color3.fromRGB(190, 90, 255),
}

-- How long one crack takes with this in your hand. Only a pickaxe mines it, so you put your sword away to do it.
function Skydrops.CrackTime(heldItem: string?): number?
	local tool = if heldItem then Tools.ByItem[heldItem] else nil
	if not tool or tool.Kind ~= "Pickaxe" then
		return nil
	end
	return CHEST_HARDNESS * 1.5 / tool.Efficiency
end

local function legendaryIn(stretch: number): number
	return stretch * LEGENDARY_STRETCH + Random.new(stretch):NextNumber() * LEGENDARY_SPREAD
end

-- When the next Legendary falls, in seconds since 1970 (os.time)
function Skydrops.NextLegendary(now: number): number
	local stretch = math.floor(now / LEGENDARY_STRETCH)
	local at = legendaryIn(stretch)
	return if at > now then at else legendaryIn(stretch + 1)
end

return Skydrops
