--!strict
-- The armour's look (ref_armour_blocky_themes in 02 Research/References/Gear; all armour, your call 2026-11-03): blocky
-- coats modelled in Blender (art/scripts/armour.py) to fit the body's boxes, one bold colour, thick outlines and big
-- themed shoulders. Mining has crystals, Woodcutting leaves and thorny vines, Farming wheat sheaves and sunflowers.
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
} :: { [string]: Set }

return ArmorArt
