--!strict
-- The rules of a fight: Minecraft 1.9+ (your call, 2026-11-03). Health here is 100 where Minecraft's
-- is 20, so its damage numbers are x5; a block is 3 studs. The full table is in
-- 07 Roadmap/Combat & Gear Plan.

local Gear = require(script.Parent.Gear)

local Combat = {}

Combat.WalkSpeed = 16
Combat.SprintSpeed = 21
Combat.BlockSpeed = 8 -- with your shield up
Combat.SprintHunger = 30 -- no sprinting at or below this hunger, as in Minecraft (6 of 20)

Combat.Reach = 9
Combat.ReachSlack = 3.5 -- for lag, and because reach counts from your eyes to their edge

Combat.FistDamage = 5
Combat.FistCooldown = 0.25
Combat.SweepDamage = 5
Combat.SweepRadius = 4.5
Combat.FullCharge = 0.9 -- charged past this counts for crits, sprint hits and sweeps
Combat.CritScale = 1.5
Combat.HurtTime = 0.5 -- after a hit, only a harder one counts, for the difference

Combat.Knockback = 24
Combat.SprintKnockback = 40
Combat.KnockUp = 34
Combat.BlockedPush = 12

export type Protection = { Helmet: number, Chest: number, Legs: number, Boots: number, Toughness: number }

-- How well each kind of armour covers you. Armour stops at diamond: only tools go on into the late game (your call,
-- 2026-11-09). An armour piece says which of these it is (Gear.luau); skill armour is Leather.
Combat.ArmorClasses = {
	Leather = { Helmet = 1, Chest = 3, Legs = 2, Boots = 1, Toughness = 0 } :: Protection,
	Iron = { Helmet = 2, Chest = 6, Legs = 5, Boots = 2, Toughness = 0 } :: Protection,
	Amethyst = { Helmet = 3, Chest = 6, Legs = 5, Boots = 2, Toughness = 0 } :: Protection,
	Sapphire = { Helmet = 3, Chest = 7, Legs = 6, Boots = 2, Toughness = 4 } :: Protection,
	Kit = { Helmet = 3, Chest = 8, Legs = 6, Boots = 3, Toughness = 8 } :: Protection, -- diamond, the top
}

-- How charged a swing is, 0 to 1, this long after your last one
function Combat.Charge(elapsed: number, cooldown: number): number
	return math.clamp(elapsed / cooldown, 0, 1)
end

-- A swing's damage for how charged it is
function Combat.HitDamage(base: number, charge: number): number
	return base * (0.2 + charge * charge * 0.8)
end

-- What's left of a hit after armour, by Minecraft's formula
function Combat.Reduce(damage: number, armor: number, toughness: number): number
	local hearts = damage / 5
	local blocked = math.min(20, math.max(armor / 5, armor - hearts / (2 + toughness / 4)))
	return damage * (1 - blocked / 25)
end

-- The armour points and toughness of what someone's wearing (Equipped: slot -> item id)
function Combat.Armor(equipped: { [string]: string }): (number, number)
	local points, toughness = 0, 0
	for slot, itemId in equipped do
		local worn = Gear.Armors[itemId]
		if worn then
			local class = (Combat.ArmorClasses :: any)[worn.Class or "Leather"]
			points += class[slot] or 0
			toughness += class.Toughness / 4
		end
	end
	return points, toughness
end

return table.freeze(Combat)
