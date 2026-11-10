--!strict
-- The armour's look (ref_armour_blocky_themes in 02 Research/References/Gear; all armour, your call 2026-11-03): blocky
-- coats modelled in Blender (art/scripts/armour.py) to fit the body's boxes, one bold colour, thick outlines and big
-- themed shoulders. Mining has crystals, Woodcutting leaves and thorny vines, Farming wheat sheaves and sunflowers, and
-- the armour kits their own themes: Stormcaller has a storm cloud and lightning.
-- One mesh serves every tier: each tier has a colour sheet, with the coat dark and the trim in the tier's colour.
--   Mesh     the asset id
--   Centre   the middle of the mesh, in its body part's space, on the avatar it was modelled for
--   Size     how big it is there

export type Mesh = { Mesh: string, Centre: Vector3, Size: Vector3 }
export type Set = { [string]: Mesh }

local ArmorArt = {}

-- The colour sheets, by tier (the order of Gear.TierColors)
ArmorArt.Palettes = {
	"rbxassetid://101274027908034",
	"rbxassetid://117210990007211",
	"rbxassetid://126279165491531",
	"rbxassetid://92697030716447",
	"rbxassetid://104535486601133",
	"rbxassetid://71600748031771",
	"rbxassetid://113212380823740",
	"rbxassetid://96094527610943",
	"rbxassetid://97621528908176",
	"rbxassetid://100790618588750",
}

-- How big each body part is on the avatar these were modelled for: a wearer's parts are compared with these
ArmorArt.Reference = {
	Head = Vector3.new(1.11, 1.12, 1.12),
	Chest = Vector3.new(1.54, 1.84, 1.01),
	Shoulder = Vector3.new(0.81, 1.18, 0.71),
	Forearm = Vector3.new(0.70, 1.13, 0.84),
	Hips = Vector3.new(1.42, 0.59, 0.97),
	Thigh = Vector3.new(0.66, 1.78, 0.77),
	Boot = Vector3.new(0.61, 1.27, 0.77),
} :: { [string]: Vector3 }

-- The meshes that make each armour item: a chestplate is the coat, both shoulders, both sleeves and both forearms
ArmorArt.SlotPieces = {
	Helmet = { "Helmet" },
	Chest = { "Chest", "PauldronRight", "PauldronLeft", "SleeveRight", "SleeveLeft", "ForearmRight", "ForearmLeft" },
	Legs = { "Hips", "ThighRight", "ThighLeft" },
	Boots = { "BootRight", "BootLeft" },
} :: { [string]: { string } }

-- Where each mesh's body part sits on that avatar, from the middle of its chest (BODY in art/scripts/armour.py; a
-- shoulder's Centre is already from the chest). On a player the real body places them (Util/ArmorModels.luau); this
-- puts a piece together on its own, for its picture (UI/ItemIcon.luau).
ArmorArt.BodyAt = {
	Helmet = Vector3.new(0, 1.47, 0.01),
	Chest = Vector3.zero,
	PauldronRight = Vector3.zero,
	PauldronLeft = Vector3.zero,
	SleeveRight = Vector3.new(0.97, 0.25, 0.09),
	SleeveLeft = Vector3.new(-0.97, 0.25, 0.09),
	ForearmRight = Vector3.new(1.18, -0.27, 0.02),
	ForearmLeft = Vector3.new(-1.18, -0.27, 0.02),
	Hips = Vector3.new(0, -0.70, 0.04),
	ThighRight = Vector3.new(0.34, -1.45, 0.03),
	ThighLeft = Vector3.new(-0.34, -1.45, 0.03),
	BootRight = Vector3.new(0.36, -2.26, 0.03),
	BootLeft = Vector3.new(-0.36, -2.26, 0.03),
} :: { [string]: Vector3 }

-- Import 3D stores them in centimetres, with their axes turned: their X is our -X, their Y our Z, their Z our Y
ArmorArt.MeshTurn = CFrame.fromMatrix(Vector3.zero, Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 1, 0))
ArmorArt.MeshScale = 100

ArmorArt.Sets = {
	Mining = {
		Helmet = {
			Mesh = "rbxassetid://114902964003986",
			Centre = Vector3.new(0.0, 0.4503, -0.0223),
			Size = Vector3.new(1.3713, 1.9519, 1.4054),
		},
		Chest = {
			Mesh = "rbxassetid://140671420931279",
			Centre = Vector3.new(0.0, -0.2897, -0.02),
			Size = Vector3.new(1.7913, 3.0307, 1.2713),
		},
		PauldronRight = {
			Mesh = "rbxassetid://81539656715966",
			Centre = Vector3.new(1.2814, 1.3752, 0.0485),
			Size = Vector3.new(1.3541, 1.4217, 1.0463),
		},
		PauldronLeft = {
			Mesh = "rbxassetid://118284588117765",
			Centre = Vector3.new(-1.2814, 1.3752, 0.0485),
			Size = Vector3.new(1.3541, 1.4217, 1.0463),
		},
		SleeveRight = {
			Mesh = "rbxassetid://112720604266348",
			Centre = Vector3.new(0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		SleeveLeft = {
			Mesh = "rbxassetid://117033434255536",
			Centre = Vector3.new(-0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		ForearmRight = {
			Mesh = "rbxassetid://80067032441522",
			Centre = Vector3.new(0.1988, -0.1, -0.09),
			Size = Vector3.new(1.329, 1.0913, 0.9513),
		},
		ForearmLeft = {
			Mesh = "rbxassetid://97181279209397",
			Centre = Vector3.new(-0.1988, -0.1, -0.09),
			Size = Vector3.new(1.329, 1.0913, 0.9513),
		},
		Hips = {
			Mesh = "rbxassetid://124686580443268",
			Centre = Vector3.new(0.0, -0.13, -0.02),
			Size = Vector3.new(1.6113, 0.6313, 1.0913),
		},
		ThighRight = {
			Mesh = "rbxassetid://105639025134024",
			Centre = Vector3.new(0.105, -0.0921, -0.0348),
			Size = Vector3.new(0.8213, 1.2355, 0.9609),
		},
		ThighLeft = {
			Mesh = "rbxassetid://75666620299665",
			Centre = Vector3.new(-0.105, -0.0921, -0.0348),
			Size = Vector3.new(0.8213, 1.2355, 0.9609),
		},
		BootRight = {
			Mesh = "rbxassetid://111015656746805",
			Centre = Vector3.new(0.193, -0.2, -0.25),
			Size = Vector3.new(1.1173, 1.2113, 1.4313),
		},
		BootLeft = {
			Mesh = "rbxassetid://97516994708379",
			Centre = Vector3.new(-0.193, -0.2, -0.25),
			Size = Vector3.new(1.1173, 1.2113, 1.4313),
		},
	},
	Woodcutting = {
		Helmet = {
			Mesh = "rbxassetid://98544832633025",
			Centre = Vector3.new(0.0, 0.601, -0.0298),
			Size = Vector3.new(1.3713, 2.2533, 1.4188),
		},
		Chest = {
			Mesh = "rbxassetid://107227676349712",
			Centre = Vector3.new(0.0, -0.2782, -0.0092),
			Size = Vector3.new(1.7913, 3.0076, 1.3031),
		},
		PauldronRight = {
			Mesh = "rbxassetid://114381448090597",
			Centre = Vector3.new(1.3419, 1.4503, -0.0253),
			Size = Vector3.new(1.4751, 1.5719, 1.4229),
		},
		PauldronLeft = {
			Mesh = "rbxassetid://89207529189351",
			Centre = Vector3.new(-1.3419, 1.4503, -0.0253),
			Size = Vector3.new(1.4751, 1.5719, 1.4229),
		},
		SleeveRight = {
			Mesh = "rbxassetid://113318900858320",
			Centre = Vector3.new(0.2099, 0.02, -0.05),
			Size = Vector3.new(1.111, 1.0113, 0.8713),
		},
		SleeveLeft = {
			Mesh = "rbxassetid://132756111328162",
			Centre = Vector3.new(-0.2099, 0.02, -0.05),
			Size = Vector3.new(1.111, 1.0113, 0.8713),
		},
		ForearmRight = {
			Mesh = "rbxassetid://119347551717804",
			Centre = Vector3.new(0.218, -0.1, -0.09),
			Size = Vector3.new(1.3673, 1.0913, 0.9513),
		},
		ForearmLeft = {
			Mesh = "rbxassetid://86801575807210",
			Centre = Vector3.new(-0.218, -0.1, -0.09),
			Size = Vector3.new(1.3673, 1.0913, 0.9513),
		},
		Hips = {
			Mesh = "rbxassetid://124686580443268",
			Centre = Vector3.new(0.0, -0.13, -0.02),
			Size = Vector3.new(1.6113, 0.6313, 1.0913),
		},
		ThighRight = {
			Mesh = "rbxassetid://87524160372198",
			Centre = Vector3.new(0.105, -0.0596, -0.0233),
			Size = Vector3.new(0.8213, 1.1706, 0.938),
		},
		ThighLeft = {
			Mesh = "rbxassetid://100454758093991",
			Centre = Vector3.new(-0.105, -0.0596, -0.0233),
			Size = Vector3.new(0.8213, 1.1706, 0.938),
		},
		BootRight = {
			Mesh = "rbxassetid://79447909900738",
			Centre = Vector3.new(0.2174, -0.2, -0.25),
			Size = Vector3.new(1.1661, 1.2113, 1.4313),
		},
		BootLeft = {
			Mesh = "rbxassetid://100630766425027",
			Centre = Vector3.new(-0.2174, -0.2, -0.25),
			Size = Vector3.new(1.1661, 1.2113, 1.4313),
		},
	},
	Farming = {
		Helmet = {
			Mesh = "rbxassetid://130148074142479",
			Centre = Vector3.new(0.0, 0.4042, 0.0),
			Size = Vector3.new(2.0955, 1.7796, 2.0955),
		},
		Chest = {
			Mesh = "rbxassetid://126284949713619",
			Centre = Vector3.new(0.02, -0.1472, 0.002),
			Size = Vector3.new(1.897, 2.7456, 1.4151),
		},
		PauldronRight = {
			Mesh = "rbxassetid://135806114025513",
			Centre = Vector3.new(1.356, 1.4668, 0.0301),
			Size = Vector3.new(1.5034, 1.9076, 1.1391),
		},
		PauldronLeft = {
			Mesh = "rbxassetid://71225313021171",
			Centre = Vector3.new(-1.356, 1.4668, 0.0301),
			Size = Vector3.new(1.5034, 1.9076, 1.1391),
		},
		SleeveRight = {
			Mesh = "rbxassetid://111470110415400",
			Centre = Vector3.new(0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		SleeveLeft = {
			Mesh = "rbxassetid://104736401986620",
			Centre = Vector3.new(-0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		ForearmRight = {
			Mesh = "rbxassetid://103190618826053",
			Centre = Vector3.new(0.2236, -0.1, -0.09),
			Size = Vector3.new(1.3784, 1.0913, 0.9513),
		},
		ForearmLeft = {
			Mesh = "rbxassetid://110928624212806",
			Centre = Vector3.new(-0.2236, -0.1, -0.09),
			Size = Vector3.new(1.3784, 1.0913, 0.9513),
		},
		Hips = {
			Mesh = "rbxassetid://124686580443268",
			Centre = Vector3.new(0.0, -0.13, -0.02),
			Size = Vector3.new(1.6113, 0.6313, 1.0913),
		},
		ThighRight = {
			Mesh = "rbxassetid://70379028656852",
			Centre = Vector3.new(0.105, -0.0759, -0.0599),
			Size = Vector3.new(0.8213, 1.203, 1.0112),
		},
		ThighLeft = {
			Mesh = "rbxassetid://99033990081135",
			Centre = Vector3.new(-0.105, -0.0759, -0.0599),
			Size = Vector3.new(0.8213, 1.203, 1.0112),
		},
		BootRight = {
			Mesh = "rbxassetid://118239112315549",
			Centre = Vector3.new(0.2757, -0.2, -0.25),
			Size = Vector3.new(1.2827, 1.2113, 1.4313),
		},
		BootLeft = {
			Mesh = "rbxassetid://82266235765844",
			Centre = Vector3.new(-0.2757, -0.2, -0.25),
			Size = Vector3.new(1.2827, 1.2113, 1.4313),
		},
	},
	Stormcaller = {
		Helmet = {
			Mesh = "rbxassetid://82997437678848",
			Centre = Vector3.new(0.0, 0.474, -0.0247),
			Size = Vector3.new(1.3713, 1.9993, 1.4006),
		},
		Chest = {
			Mesh = "rbxassetid://140701780686708",
			Centre = Vector3.new(0.0, -0.2877, -0.0002),
			Size = Vector3.new(1.7913, 3.0667, 1.416),
		},
		PauldronRight = {
			Mesh = "rbxassetid://90998908634020",
			Centre = Vector3.new(1.5131, 1.4408, 0.04),
			Size = Vector3.new(1.8176, 1.5529, 1.0193),
		},
		PauldronLeft = {
			Mesh = "rbxassetid://110245790796782",
			Centre = Vector3.new(-1.5131, 1.4408, 0.04),
			Size = Vector3.new(1.8176, 1.5529, 1.0193),
		},
		SleeveRight = {
			Mesh = "rbxassetid://123714499199798",
			Centre = Vector3.new(0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		SleeveLeft = {
			Mesh = "rbxassetid://76206369791250",
			Centre = Vector3.new(-0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		ForearmRight = {
			Mesh = "rbxassetid://111685689137689",
			Centre = Vector3.new(0.2127, -0.1, -0.09),
			Size = Vector3.new(1.3566, 1.0913, 0.9513),
		},
		ForearmLeft = {
			Mesh = "rbxassetid://125228885199564",
			Centre = Vector3.new(-0.2127, -0.1, -0.09),
			Size = Vector3.new(1.3566, 1.0913, 0.9513),
		},
		Hips = {
			Mesh = "rbxassetid://75384940251645",
			Centre = Vector3.new(0.0, -0.13, -0.02),
			Size = Vector3.new(1.6113, 0.6313, 1.0913),
		},
		ThighRight = {
			Mesh = "rbxassetid://92196189494442",
			Centre = Vector3.new(0.105, -0.0921, -0.0413),
			Size = Vector3.new(0.8213, 1.2355, 0.9738),
		},
		ThighLeft = {
			Mesh = "rbxassetid://103829668368578",
			Centre = Vector3.new(-0.105, -0.0921, -0.0413),
			Size = Vector3.new(0.8213, 1.2355, 0.9738),
		},
		BootRight = {
			Mesh = "rbxassetid://105035461174083",
			Centre = Vector3.new(0.2245, -0.2, -0.25),
			Size = Vector3.new(1.1802, 1.2113, 1.4313),
		},
		BootLeft = {
			Mesh = "rbxassetid://119007405329508",
			Centre = Vector3.new(-0.2245, -0.2, -0.25),
			Size = Vector3.new(1.1802, 1.2113, 1.4313),
		},
	},
	Sunforged = {
		Helmet = {
			Mesh = "rbxassetid://126220810569884",
			Centre = Vector3.new(0.0, 0.4764, -0.0247),
			Size = Vector3.new(1.6847, 2.0041, 1.4006),
		},
		Chest = {
			Mesh = "rbxassetid://122260252023424",
			Centre = Vector3.new(0.0, -0.2905, -0.0132),
			Size = Vector3.new(1.7913, 3.0724, 1.3236),
		},
		PauldronRight = {
			Mesh = "rbxassetid://135045695897822",
			Centre = Vector3.new(1.439, 1.3584, 0.04),
			Size = Vector3.new(1.6692, 1.3881, 0.9913),
		},
		PauldronLeft = {
			Mesh = "rbxassetid://81000879987756",
			Centre = Vector3.new(-1.439, 1.3584, 0.04),
			Size = Vector3.new(1.6692, 1.3881, 0.9913),
		},
		SleeveRight = {
			Mesh = "rbxassetid://111998083858849",
			Centre = Vector3.new(0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		SleeveLeft = {
			Mesh = "rbxassetid://119086603496274",
			Centre = Vector3.new(-0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		ForearmRight = {
			Mesh = "rbxassetid://124713465809481",
			Centre = Vector3.new(0.2456, -0.1, -0.09),
			Size = Vector3.new(1.4225, 1.0913, 0.9513),
		},
		ForearmLeft = {
			Mesh = "rbxassetid://126348248733465",
			Centre = Vector3.new(-0.2456, -0.1, -0.09),
			Size = Vector3.new(1.4225, 1.0913, 0.9513),
		},
		Hips = {
			Mesh = "rbxassetid://102232135645145",
			Centre = Vector3.new(0.0, -0.13, -0.02),
			Size = Vector3.new(1.6113, 0.6313, 1.0913),
		},
		ThighRight = {
			Mesh = "rbxassetid://117751886539546",
			Centre = Vector3.new(0.105, -0.0921, -0.0395),
			Size = Vector3.new(0.8213, 1.2355, 0.9703),
		},
		ThighLeft = {
			Mesh = "rbxassetid://135673216579307",
			Centre = Vector3.new(-0.105, -0.0921, -0.0395),
			Size = Vector3.new(0.8213, 1.2355, 0.9703),
		},
		BootRight = {
			Mesh = "rbxassetid://130933297423764",
			Centre = Vector3.new(0.2597, -0.2, -0.25),
			Size = Vector3.new(1.2507, 1.2113, 1.4313),
		},
		BootLeft = {
			Mesh = "rbxassetid://95633458332179",
			Centre = Vector3.new(-0.2597, -0.2, -0.25),
			Size = Vector3.new(1.2507, 1.2113, 1.4313),
		},
	},
	Emberguard = {
		Helmet = {
			Mesh = "rbxassetid://88556203333651",
			Centre = Vector3.new(0.0, 0.4835, -0.0247),
			Size = Vector3.new(1.3713, 2.0182, 1.4006),
		},
		Chest = {
			Mesh = "rbxassetid://89732521279360",
			Centre = Vector3.new(0.0, -0.2905, -0.0),
			Size = Vector3.new(1.7913, 3.0724, 1.4174),
		},
		PauldronRight = {
			Mesh = "rbxassetid://94499131398359",
			Centre = Vector3.new(1.3705, 1.3709, 0.04),
			Size = Vector3.new(1.5324, 1.4131, 0.9913),
		},
		PauldronLeft = {
			Mesh = "rbxassetid://94258693228137",
			Centre = Vector3.new(-1.3705, 1.3709, 0.04),
			Size = Vector3.new(1.5324, 1.4131, 0.9913),
		},
		SleeveRight = {
			Mesh = "rbxassetid://84507907798025",
			Centre = Vector3.new(0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		SleeveLeft = {
			Mesh = "rbxassetid://87824568266931",
			Centre = Vector3.new(-0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		ForearmRight = {
			Mesh = "rbxassetid://117934943820384",
			Centre = Vector3.new(0.2325, -0.1072, -0.09),
			Size = Vector3.new(1.3962, 1.1058, 0.9513),
		},
		ForearmLeft = {
			Mesh = "rbxassetid://120389042745358",
			Centre = Vector3.new(-0.2325, -0.1072, -0.09),
			Size = Vector3.new(1.3962, 1.1058, 0.9513),
		},
		Hips = {
			Mesh = "rbxassetid://90361609115822",
			Centre = Vector3.new(0.0, -0.13, -0.02),
			Size = Vector3.new(1.6113, 0.6313, 1.0913),
		},
		ThighRight = {
			Mesh = "rbxassetid://73799909790840",
			Centre = Vector3.new(0.105, -0.0921, -0.0666),
			Size = Vector3.new(0.8213, 1.2355, 1.0244),
		},
		ThighLeft = {
			Mesh = "rbxassetid://121101195086711",
			Centre = Vector3.new(-0.105, -0.0921, -0.0666),
			Size = Vector3.new(0.8213, 1.2355, 1.0244),
		},
		BootRight = {
			Mesh = "rbxassetid://121843235144387",
			Centre = Vector3.new(0.2574, -0.2, -0.25),
			Size = Vector3.new(1.2461, 1.2113, 1.4313),
		},
		BootLeft = {
			Mesh = "rbxassetid://137263361968230",
			Centre = Vector3.new(-0.2574, -0.2, -0.25),
			Size = Vector3.new(1.2461, 1.2113, 1.4313),
		},
	},
	Frostwarden = {
		Helmet = {
			Mesh = "rbxassetid://95507513013784",
			Centre = Vector3.new(0.0, 0.4816, -0.0247),
			Size = Vector3.new(1.739, 2.0146, 1.4006),
		},
		Chest = {
			Mesh = "rbxassetid://90953093924640",
			Centre = Vector3.new(0.0, -0.0821, 0.0203),
			Size = Vector3.new(1.7913, 2.6555, 1.4739),
		},
		PauldronRight = {
			Mesh = "rbxassetid://95889269132479",
			Centre = Vector3.new(1.3891, 1.1946, 0.04),
			Size = Vector3.new(1.5695, 1.8276, 0.9913),
		},
		PauldronLeft = {
			Mesh = "rbxassetid://95144713193669",
			Centre = Vector3.new(-1.3891, 1.1946, 0.04),
			Size = Vector3.new(1.5695, 1.8276, 0.9913),
		},
		SleeveRight = {
			Mesh = "rbxassetid://94803042761852",
			Centre = Vector3.new(0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		SleeveLeft = {
			Mesh = "rbxassetid://127524164915741",
			Centre = Vector3.new(-0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		ForearmRight = {
			Mesh = "rbxassetid://94978813283130",
			Centre = Vector3.new(0.2262, -0.1, -0.09),
			Size = Vector3.new(1.3837, 1.0913, 0.9513),
		},
		ForearmLeft = {
			Mesh = "rbxassetid://135853803946129",
			Centre = Vector3.new(-0.2262, -0.1, -0.09),
			Size = Vector3.new(1.3837, 1.0913, 0.9513),
		},
		Hips = {
			Mesh = "rbxassetid://93811821242764",
			Centre = Vector3.new(0.0, -0.13, -0.02),
			Size = Vector3.new(1.6113, 0.6313, 1.0913),
		},
		ThighRight = {
			Mesh = "rbxassetid://99196960380996",
			Centre = Vector3.new(0.2326, -0.212, -0.0626),
			Size = Vector3.new(1.0766, 1.4752, 1.0165),
		},
		ThighLeft = {
			Mesh = "rbxassetid://133899835883442",
			Centre = Vector3.new(-0.2326, -0.212, -0.0626),
			Size = Vector3.new(1.0766, 1.4752, 1.0165),
		},
		BootRight = {
			Mesh = "rbxassetid://77084629307743",
			Centre = Vector3.new(0.2615, -0.2, -0.25),
			Size = Vector3.new(1.2543, 1.2113, 1.4313),
		},
		BootLeft = {
			Mesh = "rbxassetid://118826724325052",
			Centre = Vector3.new(-0.2615, -0.2, -0.25),
			Size = Vector3.new(1.2543, 1.2113, 1.4313),
		},
	},
	Venomfang = {
		Helmet = {
			Mesh = "rbxassetid://119169563759998",
			Centre = Vector3.new(0.0, 0.2804, -0.0608),
			Size = Vector3.new(1.3713, 2.2115, 1.473),
		},
		Chest = {
			Mesh = "rbxassetid://123316223164956",
			Centre = Vector3.new(0.0, -0.2905, 0.02),
			Size = Vector3.new(1.7913, 3.0724, 1.7146),
		},
		PauldronRight = {
			Mesh = "rbxassetid://76165746321522",
			Centre = Vector3.new(1.4214, 1.2804, 0.04),
			Size = Vector3.new(1.6341, 1.232, 0.9913),
		},
		PauldronLeft = {
			Mesh = "rbxassetid://91338921303056",
			Centre = Vector3.new(-1.4214, 1.2804, 0.04),
			Size = Vector3.new(1.6341, 1.232, 0.9913),
		},
		SleeveRight = {
			Mesh = "rbxassetid://84507907798025",
			Centre = Vector3.new(0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		SleeveLeft = {
			Mesh = "rbxassetid://87824568266931",
			Centre = Vector3.new(-0.1, 0.02, -0.05),
			Size = Vector3.new(0.8913, 1.0113, 0.8713),
		},
		ForearmRight = {
			Mesh = "rbxassetid://130649693980445",
			Centre = Vector3.new(0.2382, -0.1, -0.09),
			Size = Vector3.new(1.4076, 1.0913, 0.9513),
		},
		ForearmLeft = {
			Mesh = "rbxassetid://99157832882850",
			Centre = Vector3.new(-0.2382, -0.1, -0.09),
			Size = Vector3.new(1.4076, 1.0913, 0.9513),
		},
		Hips = {
			Mesh = "rbxassetid://90361609115822",
			Centre = Vector3.new(0.0, -0.13, -0.02),
			Size = Vector3.new(1.6113, 0.6313, 1.0913),
		},
		ThighRight = {
			Mesh = "rbxassetid://103642496113650",
			Centre = Vector3.new(0.105, -0.0921, -0.2516),
			Size = Vector3.new(0.8213, 1.2355, 1.3945),
		},
		ThighLeft = {
			Mesh = "rbxassetid://92207364843002",
			Centre = Vector3.new(-0.105, -0.0921, -0.2516),
			Size = Vector3.new(0.8213, 1.2355, 1.3945),
		},
		BootRight = {
			Mesh = "rbxassetid://126828536419328",
			Centre = Vector3.new(0.2211, -0.2, -0.25),
			Size = Vector3.new(1.1735, 1.2113, 1.4313),
		},
		BootLeft = {
			Mesh = "rbxassetid://112084566901938",
			Centre = Vector3.new(-0.2211, -0.2, -0.25),
			Size = Vector3.new(1.1735, 1.2113, 1.4313),
		},
	},
} :: { [string]: Set }

return ArmorArt
