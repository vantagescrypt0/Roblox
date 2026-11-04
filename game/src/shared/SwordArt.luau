--!strict
-- The generated swords (Studio's generate_mesh), and how what's in your hand is held in third person
-- (your call, 2026-11-03). A sword rides over your right shoulder at its full size, going back behind your
-- head, as in your photo, and a swing strikes across in front of you (first person is Minecraft's: see
-- client/FirstPersonController). Anything else, like a tool or a block, is held Minecraft's way: the arm
-- hangs 18 degrees forward, swings half as far as a free arm while you walk, and a swing lifts it from
-- the shoulder and chops down.
-- Poses are from the shoulder: Hand in arm lengths, so they fit any avatar, Along the way the handle points
-- toward the blade, Turn the way the blade's curve bends. X is your right, Y up, -Z ahead of you.
-- Each sword's points (Grip, Embers, Trail) are shares of its size, from -0.5 to 0.5 each way.

export type Pose = { Hand: Vector3, Along: Vector3, Turn: Vector3 }
export type Hold = { Rest: Pose, Run: Pose }
export type Glow = { Color: Color3, Shell: number, Light: number, Embers: number }
export type Art = {
	Mesh: string,
	Texture: string,
	Length: number, -- studs along the blade, handle to tip
	Grip: Vector3,
	Up: Vector3, -- in the mesh: the way the handle points
	Spine: Vector3, -- in the mesh: away from the way the curve bends
	Hold: Hold?, -- its own way of resting on your shoulder, if not the straight swords' one
	Embers: { Vector3 },
	TrailFrom: Vector3,
	TrailTo: Vector3,
	Glow: Glow?,
}

local SwordArt = {}

-- A straight sword's blade, as points on a line from `from` to `to` (Y shares), for its embers
local function bladeLine(from: number, to: number, x: number?): { Vector3 }
	local points = {}
	for index = 0, 4 do
		table.insert(points, Vector3.new(x or 0, from + (to - from) * index / 4, 0))
	end
	return points
end

local HANDLE_UP = Vector3.new(0, -1, 0) -- some meshes come with the blade pointing down
local BLADE_UP = Vector3.new(0, 1, 0)
local SIDE = Vector3.new(1, 0, 0)

-- Over the shoulder, as in your photo (02 Research/References/Gear/yours_ruby_hold_LOVED.webp). A straight blade
-- rises past your head leaning back, on edge so its guard stays off your head, and you can see it from behind.
local STRAIGHT_HOLD: Hold = {
	Rest = {
		Hand = Vector3.new(0.62, -0.1, -0.25),
		Along = Vector3.new(-0.2, 0.76, 0.58),
		Turn = Vector3.new(0, -0.6, 0.8),
	},
	Run = {
		Hand = Vector3.new(0.53, -0.16, -0.2),
		Along = Vector3.new(-0.3, 0.6, 0.74),
		Turn = Vector3.new(0, -0.75, 0.65),
	},
}
-- The crescent's curve faces back, as in your photo: your head sits inside it, its back behind you and its tip
-- up over you. The arm has to reach out to hold it there: any further in and, at this size, it hits your face.
local CURVED_HOLD: Hold = {
	Rest = {
		Hand = Vector3.new(0.75, -0.2, -0.05),
		Along = Vector3.new(-0.8, 0.05, 0.76),
		Turn = Vector3.new(-0.3, 1, 0),
	},
	Run = {
		Hand = Vector3.new(0.72, -0.26, 0),
		Along = Vector3.new(-0.76, 0.14, 0.76),
		Turn = Vector3.new(-0.3, 1, 0.1),
	},
}

SwordArt.List = {
	-- Early swords: no glow. A pale wood blade with a living vine round it
	WoodenSword = {
		Mesh = "rbxassetid://135387470589005",
		Texture = "rbxassetid://122317991476753",
		Length = 4.6,
		Grip = Vector3.new(0, 0.31, 0),
		Up = HANDLE_UP,
		Spine = SIDE,
		Embers = {},
		TrailFrom = Vector3.new(0, 0.05, 0),
		TrailTo = Vector3.new(0, -0.495, 0),
	} :: Art,
	-- Chiselled stone with blue runes
	StoneSword = {
		Mesh = "rbxassetid://126317354664830",
		Texture = "rbxassetid://118263845321127",
		Length = 4.6,
		Grip = Vector3.new(0, 0.333, 0),
		Up = HANDLE_UP,
		Spine = SIDE,
		Embers = {},
		TrailFrom = Vector3.new(0, 0.05, 0),
		TrailTo = Vector3.new(0, -0.495, 0),
	} :: Art,
	-- Polished steel, a gold guard and a blue gem
	IronSword = {
		Mesh = "rbxassetid://86490425635781",
		Texture = "rbxassetid://112630712577691",
		Length = 5.2,
		Grip = Vector3.new(0, 0.292, 0),
		Up = HANDLE_UP,
		Spine = SIDE,
		Embers = {},
		TrailFrom = Vector3.new(0, 0.03, 0),
		TrailTo = Vector3.new(0, -0.495, 0),
	} :: Art,
	-- From here on they glow. A lilac blade with a purple ribbon spiralling round it
	AmethystSword = {
		Mesh = "rbxassetid://111822731636384",
		Texture = "rbxassetid://98871090415263",
		Length = 6,
		Grip = Vector3.new(0, 0.375, 0),
		Up = HANDLE_UP,
		Spine = SIDE,
		Embers = bladeLine(0.13, -0.46),
		TrailFrom = Vector3.new(0, 0.13, 0),
		TrailTo = Vector3.new(0, -0.495, 0),
		Glow = { Color = Color3.fromRGB(176, 80, 255), Shell = 0.97, Light = 1, Embers = 6 },
	} :: Art,
	-- A blue blade with water swirling inside it
	SapphireSword = {
		Mesh = "rbxassetid://127787590989333",
		Texture = "rbxassetid://82662981022015",
		Length = 6.2,
		Grip = Vector3.new(0, -0.354, 0),
		Up = BLADE_UP,
		Spine = SIDE,
		Embers = bladeLine(-0.13, 0.46),
		TrailFrom = Vector3.new(0, -0.13, 0),
		TrailTo = Vector3.new(0, 0.495, 0),
		Glow = { Color = Color3.fromRGB(50, 130, 255), Shell = 0.96, Light = 1, Embers = 7 },
	} :: Art,
	-- An ice blade with shards bursting off it, and a frosted guard
	CrystalSword = {
		Mesh = "rbxassetid://93251680434750",
		Texture = "rbxassetid://114013704200509",
		Length = 6.4,
		Grip = Vector3.new(0, 0.333, 0),
		Up = HANDLE_UP,
		Spine = SIDE,
		Embers = bladeLine(0.1, -0.46),
		TrailFrom = Vector3.new(0, 0.1, 0),
		TrailTo = Vector3.new(0, -0.495, 0),
		Glow = { Color = Color3.fromRGB(80, 230, 255), Shell = 0.95, Light = 1, Embers = 8 },
	} :: Art,
	-- Your pick: the crescent, with a spiked spine and molten cracks
	RubySword = {
		Mesh = "rbxassetid://122809265869106",
		Texture = "rbxassetid://117265405660187",
		Length = 6.8,
		Grip = Vector3.new(0.039, -0.36, 0),
		Up = Vector3.new(0.526, 0.85, 0),
		Spine = Vector3.new(0.85, -0.526, 0),
		Hold = CURVED_HOLD,
		Embers = {
			Vector3.new(0.197, -0.149, 0),
			Vector3.new(0.341, 0.021, 0),
			Vector3.new(0.381, 0.188, 0),
			Vector3.new(0.288, 0.36, 0),
			Vector3.new(0.077, 0.455, 0),
			Vector3.new(-0.184, 0.455, 0),
			Vector3.new(-0.367, 0.381, 0),
		},
		TrailFrom = Vector3.new(0.197, -0.149, 0),
		TrailTo = Vector3.new(-0.496, 0.263, 0),
		Glow = { Color = Color3.fromRGB(255, 45, 30), Shell = 0.9, Light = 1.2, Embers = 9 },
	} :: Art,
	-- The top: midnight blue running into a sunset, gold stars, a gold ribbon of energy round it
	StarsteelSword = {
		Mesh = "rbxassetid://119269159910623",
		Texture = "rbxassetid://98848118153640",
		Length = 7,
		Grip = Vector3.new(0, -0.333, 0),
		Up = BLADE_UP,
		Spine = SIDE,
		Embers = bladeLine(-0.09, 0.46),
		TrailFrom = Vector3.new(0, -0.09, 0),
		TrailTo = Vector3.new(0, 0.495, 0),
		Glow = { Color = Color3.fromRGB(255, 196, 80), Shell = 0.975, Light = 1.5, Embers = 10 },
	} :: Art,
} :: { [string]: Art }

-- A sword's swing: how long each part takes to reach its pose. It comes up beside your head, strikes down in
-- front of you, follows through across your body, and comes back up and home.
SwordArt.Swing = {
	{
		Time = 0.08,
		Pose = {
			Hand = Vector3.new(0.68, 0.3, -0.3),
			Along = Vector3.new(-0.08, 0.85, 0.5),
			Turn = Vector3.new(0, -0.5, 0.85),
		} :: Pose,
	},
	{
		Time = 0.06,
		Pose = {
			Hand = Vector3.new(0.35, -0.08, -0.88),
			Along = Vector3.new(0.1, 0.45, -0.87),
			Turn = Vector3.new(-1, 0.1, 0),
		} :: Pose,
	},
	{
		Time = 0.08,
		Pose = {
			Hand = Vector3.new(-0.05, -0.42, -0.85),
			Along = Vector3.new(-0.55, -0.15, -0.8),
			Turn = Vector3.new(0.1, -0.3, 1),
		} :: Pose,
	},
	-- Back up beside your head, so it comes home past your shoulder and not through you
	{
		Time = 0.12,
		Pose = {
			Hand = Vector3.new(0.68, 0.1, -0.5),
			Along = Vector3.new(0.1, 0.85, -0.3),
			Turn = Vector3.new(-1, 0.1, 0),
		} :: Pose,
	},
	-- Home, to whichever rest you're in now
	{ Time = 0.16, Pose = STRAIGHT_HOLD.Rest },
}

-- What a sword rests in, and when you're running: its own hold, or the straight one
function SwordArt.HoldOf(art: Art): Hold
	return art.Hold or STRAIGHT_HOLD
end

-- A sword's offset from the chest for a pose
function SwordArt.PoseMount(grip: CFrame, pose: Pose, shoulder: Vector3, reach: number): CFrame
	local along = pose.Along.Unit
	local out = -(pose.Turn - along * along:Dot(pose.Turn)).Unit
	return CFrame.fromMatrix(shoulder + pose.Hand * reach, out, along, out:Cross(along)) * grip:Inverse()
end

-- A swing of anything else lasts as long as Minecraft's: 6 ticks
SwordArt.SwingTime = 0.3

-- From the shoulder, in arm lengths: the arm hangs 18 degrees forward. From the chest: X your right,
-- Y up, -Z ahead of you.
local ARM_REST = Vector3.new(0.04, -0.95, -0.31)
-- The way what you hold points (forward and up, flat side out, as in Minecraft), and the way a curved
-- blade bends (up and back, so its long edge faces forward)
local ALONG = Vector3.new(0, 0.62, -0.78).Unit
local BEND = Vector3.new(0, 0.78, 0.62).Unit
local HELD_AXES = CFrame.fromMatrix(Vector3.zero, -BEND, ALONG, (-BEND):Cross(ALONG))
-- How far a hanging arm swings while you walk, in radians, and how fast at walking speed
SwordArt.WalkSwing = 0.4
SwordArt.WalkRate = 0.55 -- radians of the swing for each stud walked

-- A held thing's hold on the mesh: the grip's place, Y up the handle, X away from the curve
function SwordArt.GripOf(art: Art, size: Vector3): CFrame
	local up = art.Up.Unit
	local spine = (art.Spine - up * up:Dot(art.Spine)).Unit
	return CFrame.fromMatrix(art.Grip * size, spine, up, spine:Cross(up))
end

-- A little short of the arm's full length, so the elbow never locks and the hand always gets there
local REACH_SHARE = 0.95

local function jointAt(part: Instance?, name: string): Vector3?
	local joint = part and part:FindFirstChild(name)
	return if joint and joint:IsA("Attachment") then joint.Position else nil
end

-- Where this body's shoulder is on its chest, and how far its arm really reaches, joint to joint. Avatars
-- differ, and their arm parts overlap, so the hand's place is worked out from them.
function SwordArt.ArmOf(character: Model, side: string?): (Vector3, number)
	local which = side or "Right"
	local chest = character:FindFirstChild("UpperTorso")
	local upper = character:FindFirstChild(which .. "UpperArm")
	local lower = character:FindFirstChild(which .. "LowerArm")
	local hand = character:FindFirstChild(which .. "Hand")
	local shoulder = jointAt(chest, `{which}ShoulderRigAttachment`)
		or Vector3.new(if which == "Right" then 1 else -1, 0.5, 0)
	local topOfUpper = jointAt(upper, `{which}ShoulderRigAttachment`)
	local elbowOnUpper = jointAt(upper, `{which}ElbowRigAttachment`)
	local elbowOnLower = jointAt(lower, `{which}ElbowRigAttachment`)
	local wristOnLower = jointAt(lower, `{which}WristRigAttachment`)
	local wristOnHand = jointAt(hand, `{which}WristRigAttachment`)
	if topOfUpper and elbowOnUpper and elbowOnLower and wristOnLower and wristOnHand then
		local length = (topOfUpper - elbowOnUpper).Magnitude
			+ (elbowOnLower - wristOnLower).Magnitude
			+ wristOnHand.Magnitude
		return shoulder, length * REACH_SHARE
	end
	return shoulder, 2
end

-- The held thing's offset from the chest while you're doing nothing else
function SwordArt.RestMount(grip: CFrame, shoulder: Vector3, reach: number): CFrame
	return CFrame.new(shoulder + ARM_REST * reach) * HELD_AXES * grip:Inverse()
end

-- For an R6 arm, which is one piece: the held thing's offset from the arm
function SwordArt.ArmMount(grip: CFrame): CFrame
	return CFrame.new(0, -1.1, 0) * HELD_AXES * grip:Inverse()
end

-- How the arm has turned at the shoulder, this far (0 to 1) through a swing: Minecraft's swing
function SwordArt.SwingTurn(progress: number): CFrame
	local p = math.clamp(progress, 0, 1)
	local eased = 1 - (1 - p) ^ 4
	local lift = math.sin(eased * math.pi) * 1.2 + math.sin(p * math.pi) * 0.525
	local across = -0.4 * math.sin(p * math.pi)
	local twist = -0.4 * math.sin(math.sqrt(p) * 2 * math.pi)
	return CFrame.Angles(0, 0, across) * CFrame.Angles(0, twist, 0) * CFrame.Angles(lift, 0, 0)
end

return SwordArt
