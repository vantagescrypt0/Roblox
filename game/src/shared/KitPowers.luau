--!strict
-- What makes each armour kit special ([[Kits]]; your call, 2026-11-09: "all kits have something special with the armour
-- and possibly the sword"). The sword has a special you fire with a quick right-click while holding it (holding the
-- button still raises your shield), and wearing all four pieces of the set gives a bonus. They're what makes a looted
-- sword or set worth carrying. KitPowerService does them; the numbers are Claude's picks, in one place to change them.
-- Health is 100. Damage from a special goes through armour, because armour already takes so much off a swing.

export type Special = {
	Kit: string,
	Name: string,
	Text: string,
	Cooldown: number,
	Color: Color3,
	Lasts: number?, -- seconds, for one that lasts
	Damage: number?,
	Range: number?, -- studs
	-- Chain Lightning
	Jumps: number?,
	JumpRange: number?,
	JumpDamage: number?,
	-- Solar Flare
	Heal: number?,
	-- Rage
	DamageScale: number?,
	SpeedScale: number?,
	-- Frost Nova
	Freeze: number?,
	Chill: number?,
	ChillScale: number?,
	-- Venom Coat
	PoisonTime: number?,
	PoisonPerSecond: number?,
}
export type Bonus = { Name: string, Text: string }

local rgb = Color3.fromRGB

local Swords: { [string]: Special } = {
	StormcallerSword = {
		Kit = "Stormcaller",
		Name = "Chain Lightning",
		Text = "Calls lightning down on who you aim at, then it jumps to two more nearby.",
		Cooldown = 30,
		Color = rgb(90, 200, 255),
		Range = 40,
		Damage = 20,
		Jumps = 2,
		JumpRange = 16,
		JumpDamage = 12,
	},
	SunforgedSword = {
		Kit = "Sunforged",
		Name = "Solar Flare",
		Text = "A burst of sunlight burns and throws back everyone around you, and heals you.",
		Cooldown = 40,
		Color = rgb(255, 208, 96),
		Range = 16,
		Damage = 15,
		Heal = 25,
	},
	EmberguardSword = {
		Kit = "Emberguard",
		Name = "Rage",
		Text = "For 10 seconds you hit 40% harder and run 25% faster.",
		Cooldown = 60,
		Color = rgb(255, 110, 32),
		Lasts = 10,
		DamageScale = 1.4,
		SpeedScale = 1.25,
	},
	FrostwardenSword = {
		Kit = "Frostwarden",
		Name = "Frost Nova",
		Text = "Freezes everyone around you solid for 2.5 seconds, then slows them.",
		Cooldown = 45,
		Color = rgb(150, 228, 255),
		Range = 16,
		Damage = 10,
		Freeze = 2.5,
		Chill = 4,
		ChillScale = 0.5,
	},
	VenomfangSword = {
		Kit = "Venomfang",
		Name = "Venom Coat",
		Text = "For 10 seconds every hit poisons who you hit, right through their armour.",
		Cooldown = 45,
		Color = rgb(96, 255, 120),
		Lasts = 10,
		PoisonTime = 5,
		PoisonPerSecond = 3,
	},
}

local Sets: { [string]: Bonus } = {
	Stormcaller = { Name = "Static Charge", Text = "Anyone who hits you gets shocked." },
	Sunforged = { Name = "Sun-Blessed", Text = "Your health regrows twice as fast, and it costs no hunger." },
	Emberguard = { Name = "Burning Blood", Text = "You hit 25% harder at 40 health or less." },
	Frostwarden = { Name = "Rooted", Text = "Hits knock you back half as far." },
	Venomfang = { Name = "Antivenom", Text = "Poison can't touch you, even from a fall." },
}

return table.freeze({
	Swords = table.freeze(Swords),
	Sets = table.freeze(Sets),
	-- Monsters have far more health than players, so a special hits them this many times as hard
	MobScale = 3,
	-- Static Charge
	ShockDamage = 5,
	ShockEvery = 1.5, -- seconds, so a flurry of hits doesn't fry someone
	-- Burning Blood
	LowHealth = 40,
	LowHealthScale = 1.25,
	-- Rooted
	KnockbackScale = 0.5,
	-- Sun-Blessed
	RegenScale = 2,
	-- A right-click held longer than this is the shield, not the special
	QuickClick = 0.25,
})
