--!strict
-- The Slaying World's generated meshes: the monsters, what they drop, the spawner cage and the big
-- props, as generate_mesh made them (art/generated/). Written by art/scripts/monster_art.py; don't
-- edit by hand. Util/MonsterModels makes them at server start.

export type Art = { Mesh: string, Texture: string, Size: Vector3, Turn: CFrame }

local MonsterArt: { [string]: Art } = {
	BoarBrute = {
		Mesh = "rbxassetid://78911242334942",
		Texture = "rbxassetid://121874900488733",
		Size = Vector3.new(8, 8.4659, 4.9586),
		Turn = CFrame.identity,
	},
	Cinderkin = {
		Mesh = "rbxassetid://75577242651221",
		Texture = "rbxassetid://135427490141660",
		Size = Vector3.new(6.2434, 9, 3.076),
		Turn = CFrame.identity,
	},
	EmberCore = {
		Mesh = "rbxassetid://114266976407012",
		Texture = "rbxassetid://109450464286215",
		Size = Vector3.new(2.9901, 2.7497, 3),
		Turn = CFrame.identity,
	},
	FrostFur = {
		Mesh = "rbxassetid://119003899988535",
		Texture = "rbxassetid://115960193852716",
		Size = Vector3.new(2.4564, 3, 2.542),
		Turn = CFrame.identity,
	},
	FrostYeti = {
		Mesh = "rbxassetid://121245903661124",
		Texture = "rbxassetid://77061307470854",
		Size = Vector3.new(12, 12.8622, 6.1366),
		Turn = CFrame.identity,
	},
	GiantCactus = {
		Mesh = "rbxassetid://96100646269575",
		Texture = "rbxassetid://80531731744112",
		Size = Vector3.new(14, 22.0956, 5.2322),
		Turn = CFrame.identity,
	},
	GlowMushroom = {
		Mesh = "rbxassetid://125902818213487",
		Texture = "rbxassetid://97233433893618",
		Size = Vector3.new(12, 13.3055, 11.5937),
		Turn = CFrame.identity,
	},
	Glowcap = {
		Mesh = "rbxassetid://89802035218019",
		Texture = "rbxassetid://108725610550249",
		Size = Vector3.new(2.6498, 2.5, 2.6509),
		Turn = CFrame.identity,
	},
	IceCrystal = {
		Mesh = "rbxassetid://98645755954374",
		Texture = "rbxassetid://112754331901689",
		Size = Vector3.new(9.0239, 14, 8.569),
		Turn = CFrame.identity,
	},
	OldBone = {
		Mesh = "rbxassetid://109011381790509",
		Texture = "rbxassetid://90134368476498",
		Size = Vector3.new(0.5285, 0.324, 1.5),
		Turn = CFrame.identity,
	},
	Rattlebones = {
		Mesh = "rbxassetid://83393836641541",
		Texture = "rbxassetid://71422837146504",
		Size = Vector3.new(5, 6.0869, 2.4799),
		Turn = CFrame.identity,
	},
	Slime = {
		Mesh = "rbxassetid://133096438957772",
		Texture = "rbxassetid://97381844803720",
		Size = Vector3.new(4.1491, 5, 4.1662),
		Turn = CFrame.identity,
	},
	SlimeGel = {
		Mesh = "rbxassetid://97262879937977",
		Texture = "rbxassetid://136529084477043",
		Size = Vector3.new(3, 2.9897, 2.9873),
		Turn = CFrame.identity,
	},
	Spawner = {
		Mesh = "rbxassetid://112315161905551",
		Texture = "rbxassetid://70856888145677",
		Size = Vector3.new(2.3081, 3, 2.3487),
		Turn = CFrame.identity,
	},
	Sporeling = {
		Mesh = "rbxassetid://136328397556654",
		Texture = "rbxassetid://85360402106719",
		Size = Vector3.new(6.6257, 7.6215, 7),
		Turn = CFrame.identity,
	},
	Thorn = {
		Mesh = "rbxassetid://118427596511707",
		Texture = "rbxassetid://134444883536770",
		Size = Vector3.new(1.9964, 2.0286, 2),
		Turn = CFrame.identity,
	},
	Thornling = {
		Mesh = "rbxassetid://139463780950272",
		Texture = "rbxassetid://74051885437779",
		Size = Vector3.new(5, 5.6444, 3.852),
		Turn = CFrame.identity,
	},
	ToughHide = {
		Mesh = "rbxassetid://127992921543002",
		Texture = "rbxassetid://71999913832901",
		Size = Vector3.new(1.9886, 2, 1.5518),
		Turn = CFrame.identity,
	},
	VoidShard = {
		Mesh = "rbxassetid://113657332342990",
		Texture = "rbxassetid://94075106041808",
		Size = Vector3.new(1.8646, 4, 1.8611),
		Turn = CFrame.identity,
	},
	Voidling = {
		Mesh = "rbxassetid://80841244976189",
		Texture = "rbxassetid://119169807832980",
		Size = Vector3.new(6.9055, 9, 6.9136),
		Turn = CFrame.identity,
	},
}

return MonsterArt
