--!strict
-- The sky and air for the Town and the worlds: a soft atmosphere for depth and haze, a
-- little bloom on lanterns and glowing portals, gentle colour grading, and the sun in
-- the south, so what players face when they arrive (everything is built facing south)
-- is lit. (Islands keep the place's own lighting.)

local Lighting = game:GetService("Lighting")

local Ambience = {}

local function ensure(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing then
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = Lighting
	return instance
end

-- `haze` 0..1: how misty the distance looks (the Mining World is dustier). `caves`:
-- shadows go properly dark, so tunnels are lit by their lanterns.
function Ambience.Apply(haze: number?, caves: boolean?)
	local mist = haze or 0
	local atmosphere = ensure("Atmosphere", "Atmosphere") :: Atmosphere
	atmosphere.Density = 0.28 + mist * 0.15
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(214, 226, 240)
	atmosphere.Decay = Color3.fromRGB(120, 132, 150)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1 + mist * 1.5

	local bloom = ensure("BloomEffect", "Bloom") :: BloomEffect
	bloom.Intensity = 0.45
	bloom.Size = 22
	bloom.Threshold = 1.6

	local grade = ensure("ColorCorrectionEffect", "Grade") :: ColorCorrectionEffect
	grade.Saturation = 0.08
	grade.Contrast = 0.05
	grade.Brightness = 0.01

	Lighting.GeographicLatitude = -20
	if caves then
		Lighting.OutdoorAmbient = Color3.fromRGB(95, 95, 105)
		Lighting.EnvironmentDiffuseScale = 0.05
		Lighting.EnvironmentSpecularScale = 0.1
	else
		Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
		Lighting.EnvironmentDiffuseScale = 0.4
		Lighting.EnvironmentSpecularScale = 0.4
	end
end

return Ambience
