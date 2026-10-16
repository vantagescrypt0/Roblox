--!strict
-- Places prop models from ServerStorage.Assets.Props (made in Blender, see art/scripts/props.py).
-- Props are stored upright with their front facing -Z. Imported meshes carry their own
-- rotation, so placement works from each prop's world-space bottom center instead of
-- its pivot, and only ever moves and turns it around the vertical axis.

local ServerStorage = game:GetService("ServerStorage")

local Props = {}

local bases: { [Model]: CFrame } = {}

function Props.Get(name: string): Model?
	local assets = ServerStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Props")
	local template = folder and folder:FindFirstChild(name)
	return if template and template:IsA("Model") then template else nil
end

-- World-axis extents of a part (correct for rotated parts)
function Props.WorldExtents(part: BasePart): Vector3
	local cf, half = part.CFrame, part.Size / 2
	local x, y, z = cf.XVector, cf.YVector, cf.ZVector
	return Vector3.new(
		math.abs(x.X) * half.X + math.abs(y.X) * half.Y + math.abs(z.X) * half.Z,
		math.abs(x.Y) * half.X + math.abs(y.Y) * half.Y + math.abs(z.Y) * half.Z,
		math.abs(x.Z) * half.X + math.abs(y.Z) * half.Y + math.abs(z.Z) * half.Z
	)
end

-- Bottom center of the template in world space, with no rotation
local function baseOf(template: Model): CFrame
	local cached = bases[template]
	if cached then
		return cached
	end
	local low = Vector3.one * math.huge
	local high = -Vector3.one * math.huge
	for _, part in template:GetDescendants() do
		if part:IsA("BasePart") then
			local extents = Props.WorldExtents(part)
			low = low:Min(part.Position - extents)
			high = high:Max(part.Position + extents)
		end
	end
	local center = (low + high) / 2
	local base = CFrame.new(center.X, low.Y, center.Z)
	bases[template] = base
	return base
end

-- Clones a prop, stands it at `position` and turns its front toward `lookAt` (level only)
function Props.Place(name: string, position: Vector3, lookAt: Vector3?, parent: Instance): Model?
	local template = Props.Get(name)
	if not template then
		return nil
	end
	local target = if lookAt then Vector3.new(lookAt.X, position.Y, lookAt.Z) else position - Vector3.zAxis
	if (target - position).Magnitude < 0.01 then
		target = position - Vector3.zAxis
	end
	local placed = CFrame.lookAt(position, target)
	local move = placed * baseOf(template):Inverse()

	local model = template:Clone()
	model:PivotTo(move * template:GetPivot())
	-- Later moves and scaling work from the bottom center
	model.WorldPivot = placed
	if model.PrimaryPart then
		model.PrimaryPart.PivotOffset = model.PrimaryPart.CFrame:Inverse() * placed
	end
	model.Parent = parent
	return model
end

function Props.Part(model: Model, name: string): BasePart?
	local part = model:FindFirstChild(name, true)
	return if part and part:IsA("BasePart") then part else nil
end

-- The face of `part` that points most toward `direction` (for SurfaceGuis on rotated meshes)
function Props.FaceToward(part: BasePart, direction: Vector3): Enum.NormalId
	local best, bestDot = Enum.NormalId.Front, -math.huge
	for _, face in Enum.NormalId:GetEnumItems() do
		local normal = part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(face))
		local dot = normal:Dot(direction)
		if dot > bestDot then
			best, bestDot = face, dot
		end
	end
	return best
end

return Props
