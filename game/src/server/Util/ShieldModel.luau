--!strict
-- The shield on a character: the generated model (ReplicatedStorage.ShieldModels), held the way
-- Minecraft holds one: low at your side with the arm hanging and its face turned out; while you block
-- it comes up in front of your chest. Either way your left hand really holds its grip (an IKControl, which
-- every player's screen runs on top of the walk and run animations). An R6 arm is one piece and
-- can't reach, so there the shield is strapped along the arm.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SwordArt = require(ReplicatedStorage.Shared.SwordArt)

-- The model's front is its -Z. The hanging hand's place is from the shoulder, in arm lengths: avatars
-- differ. The elbow bends a little so the shield clears the ground.
local HAND_HANGING = Vector3.new(-0.1, -0.74, -0.34)
local HELD_TURN = CFrame.Angles(0, math.rad(62), 0)
local RAISED = CFrame.new(-0.35, 0.15, -1.75) * CFrame.Angles(0, math.rad(6), 0)
local ON_ARM_R6 = CFrame.new(-1.05, -0.45, 0) * CFrame.Angles(0, math.rad(90), 0)
local GRIP = CFrame.new(0.05, -0.05, 0.75)

local ShieldModel = {}

local function findPart(character: Model, name: string): BasePart?
	local found = character:FindFirstChild(name)
	return if found and found:IsA("BasePart") then found else nil
end

-- Sets where the shield sits. False if the character has nothing to mount it on.
local function seat(character: Model, mount: Weld, raised: boolean): boolean
	local chest = findPart(character, "UpperTorso")
	if chest then
		mount.Part0 = chest
		local shoulder, reach = SwordArt.ArmOf(character, "Left")
		local held = CFrame.new(shoulder + HAND_HANGING * reach) * HELD_TURN * GRIP:Inverse()
		mount.C0 = if raised then RAISED else held
		return true
	end
	local part = if raised then findPart(character, "Torso") else findPart(character, "Left Arm")
	if part then
		mount.Part0 = part
		mount.C0 = if raised then RAISED else ON_ARM_R6
	end
	return part ~= nil
end

-- Puts the shield in a character's left hand (a part named "Shield")
function ShieldModel.Apply(character: Model)
	local folder = ReplicatedStorage:FindFirstChild("ShieldModels")
	local template = folder and folder:FindFirstChild("Shield")
	if not template or not template:IsA("BasePart") then
		return
	end
	local shield = template:Clone()
	shield.Name = "Shield"
	local mount = Instance.new("Weld")
	mount.Name = "Mount"
	mount.Part1 = shield
	if not seat(character, mount, false) then
		shield:Destroy()
		return
	end
	mount.Parent = shield
	local grip = Instance.new("Attachment")
	grip.Name = "Grip"
	grip.CFrame = GRIP
	grip.Parent = shield
	shield.Parent = character

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local shoulder = character:FindFirstChild("LeftUpperArm")
	local hand = character:FindFirstChild("LeftHand")
	if humanoid and shoulder and hand then
		local reach = Instance.new("IKControl")
		reach.Name = "ShieldArm"
		reach.Type = Enum.IKControlType.Position
		reach.ChainRoot = shoulder
		reach.EndEffector = hand
		reach.Target = grip
		reach.Parent = humanoid
		shield.Destroying:Once(function()
			reach:Destroy()
		end)
	end
end

-- Lifts the shield in front of the chest, or lowers it back to your side. The hand follows.
function ShieldModel.SetRaised(character: Model, raised: boolean)
	local shield = character:FindFirstChild("Shield")
	local mount = shield and shield:FindFirstChild("Mount")
	if mount and mount:IsA("Weld") then
		seat(character, mount, raised)
	end
end

return ShieldModel
