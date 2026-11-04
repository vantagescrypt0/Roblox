--!strict
-- Puts a still copy of a character in a pose, part by part, for places with no animation to do it: the
-- Bag's preview, and a body lying on the ground (BodyService). Works on Motor6Ds and on the
-- AnimationConstraints and RigidConstraints that newer avatars have in their place.

local Rig = {}

-- One joint, seen from one of its parts: where it is on this part and on the other
type Link = { Part: BasePart, Near: CFrame, Far: CFrame }

-- Anchors everything and sets every joint at rest with `root` at the world's origin, and whatever's
-- welded on stays where it sits. Parts that shouldn't rest are given by name: `posed` as offsets from
-- the chest, `turned` as a turn at the part's own joint (what follows it turns too).
function Rig.Settle(copy: Model, root: BasePart, posed: { [string]: CFrame }?, turned: { [string]: CFrame }?)
	local chest = copy:FindFirstChild("UpperTorso") :: BasePart?
	local links: { [BasePart]: { Link } } = {}
	local function link(a: BasePart?, b: BasePart?, near: CFrame, far: CFrame)
		if a and b then
			links[a] = links[a] or {}
			table.insert(links[a], { Part = b, Near = near, Far = far })
			links[b] = links[b] or {}
			table.insert(links[b], { Part = a, Near = far, Far = near })
		end
	end
	for _, descendant in copy:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		elseif descendant:IsA("Motor6D") then
			link(descendant.Part0, descendant.Part1, descendant.C0, descendant.C1)
		elseif descendant:IsA("AnimationConstraint") or descendant:IsA("RigidConstraint") then
			local from, to = descendant.Attachment0, descendant.Attachment1
			if from and to then
				link(from.Parent :: any, to.Parent :: any, from.CFrame, to.CFrame)
			end
		elseif descendant:IsA("JointInstance") or descendant:IsA("WeldConstraint") then
			local a, b = descendant.Part0, descendant.Part1
			if a and b then
				link(a, b, a.CFrame:ToObjectSpace(b.CFrame), CFrame.identity)
			end
		end
	end
	root.CFrame = CFrame.identity
	local placed = { [root] = true }
	local queue = { root }
	while #queue > 0 do
		local part = table.remove(queue) :: BasePart
		local attached = links[part]
		if attached then
			for _, linked in attached do
				if not placed[linked.Part] then
					placed[linked.Part] = true
					local name = linked.Part.Name
					local pose = posed and posed[name]
					local turn = turned and turned[name] or CFrame.identity
					linked.Part.CFrame = if pose and chest
						then chest.CFrame * pose
						else part.CFrame * linked.Near * turn * linked.Far:Inverse()
					table.insert(queue, linked.Part)
				end
			end
		end
	end
end

return Rig
