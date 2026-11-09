--!strict
-- The monsters of the Slaying World ([[Slaying Proposal]]). The first six live on its six zones
-- (a Combat level to enter each, Worlds/Slaying); the last two are late game, and only come from
-- spawners found in loot crates and Warzone chests ([[Late-game Rule]]).
--
-- Each one's numbers are fitted by tools/balance.py so Combat takes about as long as the other
-- skills to reach 99. Health is how many sword hits it takes; Damage is "a little" (health is 100
-- and comes back on its own). Respawn is how long a spawner on your island takes to make another,
-- the same as the node of the same rank.
--
-- Model is the name of its mesh in ReplicatedStorage.MonsterModels (generated in Studio, see
-- art/generated/monster_prompts.json). Height is how tall it stands, in studs.

export type Monster = {
	Id: string, -- also what Challenges counts
	Name: string,
	Zone: string?, -- the zone it lives in (nil = late game: spawners only)
	Level: number, -- Combat level needed to hit it
	Health: number,
	Damage: number,
	Speed: number,
	Height: number,
	Hops: boolean?, -- moves in bounces instead of walking
	Hovers: boolean?, -- floats off the ground
	XP: number,
	PlayerXP: number,
	Drop: string, -- item id
	Spawner: string, -- the item that makes one on your island
	Respawn: number, -- seconds, from a spawner on your island
	Model: string,
}

export type Zone = {
	Id: string,
	Name: string,
	Level: number,
	Monster: string,
}

local List: { Monster } = {
	{
		Id = "Slime",
		Name = "Slime",
		Zone = "SlimeMeadow",
		Level = 1,
		Health = 60,
		Damage = 2,
		Speed = 9,
		Height = 5,
		Hops = true,
		XP = 145,
		PlayerXP = 48,
		Drop = "SlimeGel",
		Spawner = "SlimeSpawner",
		Respawn = 90,
		Model = "Slime",
	},
	{
		Id = "Thornling",
		Name = "Thornling",
		Zone = "BrambleWoods",
		Level = 10,
		Health = 110,
		Damage = 3,
		Speed = 11,
		Height = 7,
		XP = 230,
		PlayerXP = 77,
		Drop = "Thorn",
		Spawner = "ThornlingSpawner",
		Respawn = 120,
		Model = "Thornling",
	},
	{
		Id = "BoarBrute",
		Name = "Boar Brute",
		Zone = "RustCanyon",
		Level = 20,
		Health = 180,
		Damage = 4,
		Speed = 12,
		Height = 9,
		XP = 330,
		PlayerXP = 110,
		Drop = "ToughHide",
		Spawner = "BoarBruteSpawner",
		Respawn = 150,
		Model = "BoarBrute",
	},
	{
		Id = "Rattlebones",
		Name = "Rattlebones",
		Zone = "BoneFlats",
		Level = 30,
		Health = 260,
		Damage = 5,
		Speed = 12,
		Height = 8,
		XP = 480,
		PlayerXP = 160,
		Drop = "OldBone",
		Spawner = "RattlebonesSpawner",
		Respawn = 180,
		Model = "Rattlebones",
	},
	{
		Id = "Sporeling",
		Name = "Sporeling",
		Zone = "SporewoodBog",
		Level = 40,
		Health = 360,
		Damage = 6,
		Speed = 10,
		Height = 8,
		XP = 690,
		PlayerXP = 230,
		Drop = "Glowcap",
		Spawner = "SporelingSpawner",
		Respawn = 210,
		Model = "Sporeling",
	},
	{
		Id = "FrostYeti",
		Name = "Frost Yeti",
		Zone = "FrostfangPeaks",
		Level = 55,
		Health = 520,
		Damage = 8,
		Speed = 13,
		Height = 13,
		XP = 1030,
		PlayerXP = 343,
		Drop = "FrostFur",
		Spawner = "FrostYetiSpawner",
		Respawn = 240,
		Model = "FrostYeti",
	},
	-- Late game: island only, from loot crates and Warzone chests
	{
		Id = "Cinderkin",
		Name = "Cinderkin",
		Level = 70,
		Health = 700,
		Damage = 10,
		Speed = 13,
		Height = 9,
		XP = 1435,
		PlayerXP = 478,
		Drop = "EmberCore",
		Spawner = "CinderkinSpawner",
		Respawn = 240,
		Model = "Cinderkin",
	},
	{
		Id = "Voidling",
		Name = "Voidling",
		Level = 85,
		Health = 900,
		Damage = 12,
		Speed = 14,
		Height = 9,
		Hovers = true,
		XP = 2000,
		PlayerXP = 667,
		Drop = "VoidShard",
		Spawner = "VoidlingSpawner",
		Respawn = 300,
		Model = "Voidling",
	},
}

-- The six zones, in the order you reach them
local Zones: { Zone } = {
	{ Id = "SlimeMeadow", Name = "Slime Meadow", Level = 1, Monster = "Slime" },
	{ Id = "BrambleWoods", Name = "Bramble Woods", Level = 10, Monster = "Thornling" },
	{ Id = "RustCanyon", Name = "Rust Canyon", Level = 20, Monster = "BoarBrute" },
	{ Id = "BoneFlats", Name = "Bone Flats", Level = 30, Monster = "Rattlebones" },
	{ Id = "SporewoodBog", Name = "Sporewood Bog", Level = 40, Monster = "Sporeling" },
	{ Id = "FrostfangPeaks", Name = "Frostfang Peaks", Level = 55, Monster = "FrostYeti" },
}

local byId: { [string]: Monster } = {}
local bySpawner: { [string]: Monster } = {}
for _, monster in List do
	byId[monster.Id] = monster
	bySpawner[monster.Spawner] = monster
end

return table.freeze({
	List = table.freeze(List),
	Zones = table.freeze(Zones),
	ById = table.freeze(byId),
	BySpawner = table.freeze(bySpawner),
})
