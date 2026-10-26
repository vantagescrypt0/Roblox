--!strict
-- Little motions in the scenery, done on your screen only (no network traffic): any
-- Model tagged "Spin" turns around its pivot's Z axis at its "Spin" attribute (degrees
-- per second), like the Farming World's windmill sails (Util/Decor.Spin on the server).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AmbientController = {}

local spinning: { [Model]: { Base: CFrame, Speed: number, Angle: number } } = {}

local function watch(model: Instance)
	if model:IsA("Model") and type(model:GetAttribute("Spin")) == "number" and not spinning[model] then
		spinning[model] = { Base = model:GetPivot(), Speed = math.rad(model:GetAttribute("Spin") :: number), Angle = 0 }
	end
end

function AmbientController.Start()
	for _, model in CollectionService:GetTagged("Spin") do
		watch(model)
	end
	CollectionService:GetInstanceAddedSignal("Spin"):Connect(watch)
	CollectionService:GetInstanceRemovedSignal("Spin"):Connect(function(model)
		if model:IsA("Model") then
			spinning[model] = nil
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		for model, spin in spinning do
			if not model:IsDescendantOf(Workspace) then
				spinning[model] = nil
				continue
			end
			spin.Angle = (spin.Angle + spin.Speed * dt) % (2 * math.pi)
			model:PivotTo(spin.Base * CFrame.Angles(0, 0, spin.Angle))
		end
	end)
end

return AmbientController
