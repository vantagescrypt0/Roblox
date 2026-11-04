--!strict
-- What's in a character's right hand (SwordArt.luau): welded to the chest with the hand on its grip (an
-- IKControl, like the shield's). A generated sword rides over the shoulder and gets its glow: a neon
-- shell, a light and embers. Anything else hangs in the hand. Each player's screen moves the weld for
-- walking and swings (client/HeldController). An R6 arm is one piece and can't reach, so there it's
-- fixed to the arm.

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SwordArt = require(ReplicatedStorage.Shared.SwordArt)

local WHITE = Color3.new(1, 1, 1)

local HeldModel = {}

-- The loaded swords, by item id. They're in ReplicatedStorage so icons can show them too.
local templates = Instance.new("Folder")
templates.Name = "SwordModels"
templates.Parent = ReplicatedStorage

local function ghost(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
end

-- Length is along the blade, and a sword's handle-to-tip line is its mesh's Y
local function swordSize(art: SwordArt.Art, meshSize: Vector3): Vector3
	local scale = art.Length / meshSize.Y
	return meshSize * scale
end

local function templateFor(itemId: string, art: SwordArt.Art): MeshPart?
	local known = templates:FindFirstChild(itemId)
	if known then
		return known :: MeshPart
	end
	local ok, part = pcall(function()
		return AssetService:CreateMeshPartAsync(art.Mesh)
	end)
	if not ok then
		warn(`[HeldModel] {itemId} didn't load: {part}`)
		return nil
	end
	part.Name = itemId
	part.TextureID = art.Texture
	part.Size = swordSize(art, part.MeshSize)
	ghost(part)
	part.Parent = templates
	return part
end

local function addGlow(sword: MeshPart, glow: SwordArt.Glow, art: SwordArt.Art)
	local shell = sword:Clone()
	-- Its copy of the sword's mount would hold the glow at the chest while the sword itself moved
	shell:ClearAllChildren()
	shell.Name = "Glow"
	shell.TextureID = ""
	shell.Material = Enum.Material.Neon
	shell.Color = glow.Color
	shell.Transparency = glow.Shell
	shell.Size = sword.Size * 1.025
	shell.CastShadow = false
	local hold = Instance.new("Weld")
	hold.Part0 = sword
	hold.Part1 = shell
	hold.Parent = shell
	shell.Parent = sword

	local light = Instance.new("PointLight")
	light.Color = glow.Color
	-- Held low and close now: any stronger and it colours your whole body
	light.Range = 5
	light.Brightness = glow.Light * 0.35
	light.Shadows = false
	light.Parent = sword

	for _, point in art.Embers do
		local at = Instance.new("Attachment")
		at.Position = point * sword.Size
		at.Parent = sword
		local embers = Instance.new("ParticleEmitter")
		embers.Name = "Embers"
		embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		embers.Color = ColorSequence.new(glow.Color:Lerp(WHITE, 0.55), glow.Color)
		embers.LightEmission = 1
		embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
		embers.Lifetime = NumberRange.new(0.5, 1.1)
		embers.Rate = glow.Embers
		embers.Speed = NumberRange.new(0.3, 1)
		embers.SpreadAngle = Vector2.new(180, 180)
		embers.Acceleration = Vector3.new(0, 2.5, 0)
		embers.Parent = at
	end
end

-- The streak a swing leaves. Each screen switches it on for the strike.
local function addTrail(sword: MeshPart, art: SwordArt.Art)
	local from = Instance.new("Attachment")
	from.Position = art.TrailFrom * sword.Size
	from.Parent = sword
	local to = Instance.new("Attachment")
	to.Position = art.TrailTo * sword.Size
	to.Parent = sword
	local trail = Instance.new("Trail")
	local color = if art.Glow then art.Glow.Color else WHITE
	trail.Attachment0 = from
	trail.Attachment1 = to
	trail.Color = ColorSequence.new(color:Lerp(WHITE, 0.35), color)
	trail.Transparency = NumberSequence.new(0.25, 1)
	trail.LightEmission = if art.Glow then 1 else 0
	trail.Lifetime = 0.16
	trail.Enabled = false
	trail.Parent = sword
end

function HeldModel.Remove(character: Model)
	local held = character:FindFirstChild("Held")
	if held then
		held:Destroy()
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local reach = humanoid and humanoid:FindFirstChild("HeldArm")
	if reach then
		reach:Destroy()
	end
	local chest = character:FindFirstChild("UpperTorso")
	local elbow = chest and chest:FindFirstChild("HeldElbow")
	if elbow then
		elbow:Destroy()
	end
end

-- Mounts a part in the right hand. `grip` is the hold on the part: its place, Y up the handle.
local function mountHeld(character: Model, held: BasePart, itemId: string, grip: CFrame): boolean
	held.Name = "Held"
	held:SetAttribute("Item", itemId)
	held:SetAttribute("Grip", grip)
	local chest = character:FindFirstChild("UpperTorso")
	local arm = character:FindFirstChild("Right Arm")
	local mount = Instance.new("Weld")
	mount.Name = "Mount"
	mount.Part1 = held
	if chest and chest:IsA("BasePart") then
		local shoulder, reach = SwordArt.ArmOf(character)
		mount.Part0 = chest
		local art = SwordArt.List[itemId]
		if art then
			local carry = SwordArt.CarryOf(art)
			local hold = if SwordArt.WearsArmourUp(character) then carry.Armoured else carry.Bare
			mount.C0 = SwordArt.PoseFrame(hold.Rest, shoulder, reach) * grip:Inverse()
		else
			mount.C0 = SwordArt.RestMount(grip, shoulder, reach)
		end
	elseif arm and arm:IsA("BasePart") then
		mount.Part0 = arm
		mount.C0 = SwordArt.ArmMount(grip)
	else
		return false
	end
	mount.Parent = held
	local gripAt = Instance.new("Attachment")
	gripAt.Name = "Grip"
	gripAt.Position = grip.Position
	gripAt.Parent = held
	return true
end

local function reachFor(character: Model, held: BasePart, isSword: boolean)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local shoulder = character:FindFirstChild("RightUpperArm")
	local hand = character:FindFirstChild("RightHand")
	local gripAt = held:FindFirstChild("Grip")
	if humanoid and shoulder and hand and gripAt and gripAt:IsA("Attachment") then
		local reach = Instance.new("IKControl")
		reach.Name = "HeldArm"
		reach.Type = Enum.IKControlType.Position
		reach.ChainRoot = shoulder
		reach.EndEffector = hand
		reach.Target = gripAt
		reach.SmoothTime = 0.02
		local chest = character:FindFirstChild("UpperTorso")
		if isSword and chest then
			-- Its elbow goes down and behind you, so the arm stays clear of the guard above it
			local joint, length = SwordArt.ArmOf(character)
			local elbow = Instance.new("Attachment")
			elbow.Name = "HeldElbow"
			elbow.Position = joint + SwordArt.SwordElbow * length
			elbow.Parent = chest
			reach.Pole = elbow
			-- By itself this puts your wrist on the grip, with your forearm round the handle. This puts your palm there.
			local wrist = hand:FindFirstChild("RightWristRigAttachment")
			if wrist and wrist:IsA("Attachment") then
				reach.EndEffectorOffset = CFrame.new(wrist.Position)
			end
		end
		reach.Parent = humanoid
	end
end

-- Puts a generated sword in a character's hand. The first of each kind has to load, so this can wait.
function HeldModel.ApplySword(character: Model, itemId: string)
	local art = SwordArt.List[itemId]
	local template = art and templateFor(itemId, art)
	if not art or not template then
		return
	end
	-- You may have switched to something else while it loaded
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or tool:GetAttribute("Held") ~= itemId then
		return
	end
	HeldModel.Remove(character)

	local sword = template:Clone()
	if not mountHeld(character, sword, itemId, SwordArt.GripOf(art, sword.Size)) then
		sword:Destroy()
		return
	end
	if art.Glow then
		addGlow(sword, art.Glow, art)
	end
	addTrail(sword, art)
	sword.Parent = character
	reachFor(character, sword, true)
end

-- Puts anything else in a character's hand: a tool's or crop's model, or a small block
function HeldModel.ApplyItem(character: Model, itemId: string, part: BasePart, grip: CFrame)
	HeldModel.Remove(character)
	ghost(part)
	if not mountHeld(character, part, itemId, grip) then
		part:Destroy()
		return
	end
	part.Parent = character
	reachFor(character, part, false)
end

-- Tells every screen a swing started
function HeldModel.Swung(character: Model)
	local held = character:FindFirstChild("Held")
	if held then
		held:SetAttribute("SwungAt", workspace:GetServerTimeNow())
	end
end

-- Loads the swords up front, so nobody waits when they first draw one
function HeldModel.Start()
	for itemId, art in SwordArt.List do
		task.spawn(templateFor, itemId, art)
	end
end

return HeldModel
