--!strict
-- Moves what's in everyone's hands on this screen, yours and theirs (SwordArt.luau). A sword rests over
-- the shoulder, leans back while sprinting, changes its hold when a helmet or chest armour goes on or off, and swings
-- through its poses. Anything else hangs in the hand, swings with your walk and chops the way Minecraft's arm
-- does. The weld is only moved here, on each screen; the hand follows because it holds the grip. Anyone else's
-- swing starts when the server says so; yours starts the moment you click.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SwordArt = require(ReplicatedStorage.Shared.SwordArt)

local OWN_SWING_WINDOW = 0.4 -- the server's word on your own swing, arriving late, is ignored
local TRAIL_UNTIL = 0.2 -- seconds into a swing
local RUN_BLEND_SPEED = 8
local ARMOUR_BLEND_SPEED = 8
local WALK_SPEED = 16 -- studs a second that count as a full arm swing
local MOST_SWING = 1.3 -- sprinting swings further
local SWING_EASE = 8

-- Where the grip goes, from the chest. A step with no Frame goes home.
type HoldFrames = { Rest: CFrame, Run: CFrame }
type SwingStep = { Time: number, Frame: CFrame? }
type SwordFrames = { Bare: HoldFrames, Armoured: HoldFrames, Steps: { SwingStep } }
type ItemFrames = { Mount: CFrame, Shoulder: CFrame }

local localPlayer = Players.LocalPlayer

local HeldController = {}

local WEAK = { __mode = "k" }
local swords: { [BasePart]: SwordFrames } = setmetatable({}, WEAK) :: any
local items: { [BasePart]: ItemFrames } = setmetatable({}, WEAK) :: any
local started: { [BasePart]: number } = setmetatable({}, WEAK) :: any
local seen: { [BasePart]: number } = setmetatable({}, WEAK) :: any
local runBlend: { [BasePart]: number } = setmetatable({}, WEAK) :: any
local armourBlend: { [BasePart]: number } = setmetatable({}, WEAK) :: any
local walkPhase: { [BasePart]: number } = setmetatable({}, WEAK) :: any
local walkAmount: { [BasePart]: number } = setmetatable({}, WEAK) :: any
local listeners: { () -> () } = {}

local function ownHeld(): BasePart?
	local character = localPlayer.Character
	local held = character and character:FindFirstChild("Held")
	return if held and held:IsA("BasePart") then held else nil
end

-- Is something in your hand? It swings itself; an empty hand plays a slash.
function HeldController.Holding(): boolean
	return ownHeld() ~= nil
end

-- Your own swing, however it started (a hit, or mining)
function HeldController.Swing()
	local held = ownHeld()
	if held then
		started[held] = os.clock()
	end
	for _, listener in listeners do
		listener()
	end
end

-- Calls back on each of your own swings (first person)
function HeldController.OnSwing(listener: () -> ())
	table.insert(listeners, listener)
end

-- How far into a swing this is, in seconds, if it's in one. Picks up anyone's swing from the server.
local function swingAge(player: Player, held: BasePart): number?
	local swungAt = held:GetAttribute("SwungAt")
	if type(swungAt) == "number" and swungAt ~= seen[held] then
		seen[held] = swungAt
		local mine = player == localPlayer and os.clock() - (started[held] or 0) < OWN_SWING_WINDOW
		if not mine then
			started[held] = os.clock()
		end
	end
	local start = started[held]
	return if start then os.clock() - start else nil
end

local function swordFrames(character: Model, held: BasePart, art: SwordArt.Art): SwordFrames
	local known = swords[held]
	if known then
		return known
	end
	local shoulder, reach = SwordArt.ArmOf(character)
	local carry = SwordArt.CarryOf(art)
	local function holdFrames(hold: SwordArt.Hold): HoldFrames
		return {
			Rest = SwordArt.PoseFrame(hold.Rest, shoulder, reach),
			Run = SwordArt.PoseFrame(hold.Run, shoulder, reach),
		}
	end
	local made: SwordFrames = { Bare = holdFrames(carry.Bare), Armoured = holdFrames(carry.Armoured), Steps = {} }
	for _, key in carry.Swing do
		local frame = if key.Pose then SwordArt.PoseFrame(key.Pose, shoulder, reach) else nil
		table.insert(made.Steps, { Time = key.Time, Frame = frame })
	end
	swords[held] = made
	return made
end

-- Where a sword's swing has got to, from the pose it's in now
local function swungFrame(rest: CFrame, steps: { SwingStep }, elapsed: number): CFrame?
	local from = rest
	local left = elapsed
	for _, step in steps do
		local to = step.Frame or rest
		if left < step.Time then
			local t = left / step.Time
			return from:Lerp(to, 1 - (1 - t) * (1 - t))
		end
		left -= step.Time
		from = to
	end
	return nil
end

local function eased(from: number, to: number, speed: number, dt: number): number
	return from + (to - from) * math.min(1, dt * speed)
end

local function moveSword(
	player: Player,
	character: Model,
	held: BasePart,
	mount: Weld,
	grip: CFrame,
	art: SwordArt.Art,
	dt: number
)
	local frames = swordFrames(character, held, art)
	local running = eased(runBlend[held] or 0, if player:GetAttribute("Sprinting") then 1 else 0, RUN_BLEND_SPEED, dt)
	runBlend[held] = running
	local wearing = if SwordArt.WearsArmourUp(character) then 1 else 0
	-- A sword you've just drawn starts in the right hold; it only moves across when armour changes
	local armoured = eased(armourBlend[held] or wearing, wearing, ARMOUR_BLEND_SPEED, dt)
	armourBlend[held] = armoured
	local rest = frames.Bare.Rest
		:Lerp(frames.Bare.Run, running)
		:Lerp(frames.Armoured.Rest:Lerp(frames.Armoured.Run, running), armoured)

	local elapsed = swingAge(player, held)
	local swung = if elapsed then swungFrame(rest, frames.Steps, elapsed) else nil
	if not swung then
		started[held] = nil
	end
	mount.C0 = (swung or rest) * grip:Inverse()

	local trail = held:FindFirstChildOfClass("Trail")
	if trail then
		trail.Enabled = elapsed ~= nil and swung ~= nil and elapsed < TRAIL_UNTIL
	end
end

local function moveItem(player: Player, character: Model, held: BasePart, mount: Weld, grip: CFrame, dt: number)
	local frames = items[held]
	if not frames then
		local shoulder, reach = SwordArt.ArmOf(character)
		frames = { Mount = SwordArt.RestMount(grip, shoulder, reach), Shoulder = CFrame.new(shoulder) }
		items[held] = frames
	end

	-- The arm swings with your walking speed
	local root = character:FindFirstChild("HumanoidRootPart")
	local speed = 0
	if root and root:IsA("BasePart") then
		speed = (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
	end
	walkPhase[held] = (walkPhase[held] or 0) + dt * speed * SwordArt.WalkRate
	local wanted = math.min(speed / WALK_SPEED, MOST_SWING)
	local amount = walkAmount[held] or 0
	amount += (wanted - amount) * math.min(1, dt * SWING_EASE)
	walkAmount[held] = amount
	local turn = CFrame.Angles(math.sin(walkPhase[held]) * SwordArt.WalkSwing * amount, 0, 0)

	local elapsed = swingAge(player, held)
	if elapsed and elapsed < SwordArt.SwingTime then
		turn = SwordArt.SwingTurn(elapsed / SwordArt.SwingTime) * turn
	else
		started[held] = nil
	end
	mount.C0 = frames.Shoulder * turn * frames.Shoulder:Inverse() * frames.Mount
end

local function moveHeld(player: Player, character: Model, held: BasePart, dt: number)
	local mount = held:FindFirstChild("Mount")
	local grip = held:GetAttribute("Grip")
	local item = held:GetAttribute("Item")
	if typeof(grip) ~= "CFrame" or not mount or not mount:IsA("Weld") then
		return
	end
	if not mount.Part0 or mount.Part0.Name ~= "UpperTorso" then
		return
	end
	local art = if type(item) == "string" then SwordArt.List[item] else nil
	if art then
		moveSword(player, character, held, mount, grip, art, dt)
	else
		moveItem(player, character, held, mount, grip, dt)
	end
end

function HeldController.Start()
	RunService.RenderStepped:Connect(function(dt)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local held = character and character:FindFirstChild("Held")
			if character and held and held:IsA("BasePart") then
				moveHeld(player, character, held, dt)
			end
		end
	end)
end

return HeldController
