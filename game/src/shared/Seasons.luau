--!strict
-- Seasons: each one ends at a fixed time (UTC) and the next starts right then. At the
-- change every player starts the new season fresh (SeasonService): player level and every
-- skill back to 1, the skill challenges start over and their rewards (pets, armor sets,
-- trophies) are taken away. Islands, the Bag and coins stay. Someone who was away catches
-- up the next time they join.
-- A season with no end date runs until one is added, so nothing resets and the HUD shows no
-- countdown. Resets are on hold (your call 2026-10-29): Season 1 has no end date.

-- Ends: an ISO 8601 time in UTC, e.g. "2027-01-30T18:00:00Z" (nil: no end date yet)
export type Season = { Number: number, Ends: string? }

local LIST: { Season } = {
	{ Number = 1 },
}

-- Each season's end as a Unix time (seconds), up to the first season with no end date
local ends: { number } = {}
for index, season in LIST do
	assert(season.Number == index, "Seasons are numbered 1, 2, 3... in order")
	if not season.Ends then
		break
	end
	ends[index] = DateTime.fromIsoDate(season.Ends).UnixTimestamp
	assert(index == 1 or ends[index] > ends[index - 1], "Each season must end after the one before it")
end

local Seasons = {}

-- The season running at `now` (Unix time: os.time() on servers, GetServerTimeNow() on
-- clients) and when it ends (nil: no end date yet)
function Seasons.At(now: number): (number, number?)
	for index, endsAt in ends do
		if now < endsAt then
			return index, endsAt
		end
	end
	return #ends + 1, nil
end

-- When season `number` ends (nil: no end date yet)
function Seasons.EndsAt(number: number): number?
	return ends[number]
end

-- Time left, short: "92 days", "1 day 4 h", "3 h 20 min", "12 min 5 s", "45 s"
function Seasons.FormatLeft(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local days, hours, minutes = s // 86400, s // 3600 % 24, s // 60 % 60
	if days >= 2 then
		return `{days} days`
	elseif days == 1 then
		return `1 day {hours} h`
	elseif hours > 0 then
		return `{hours} h {minutes} min`
	elseif minutes > 0 then
		return `{minutes} min {s % 60} s`
	end
	return `{s} s`
end

return table.freeze(Seasons)
