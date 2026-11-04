--!strict
-- What Skydrops look like on this screen (Services/SkydropService): a chest coming down out of the sky, on every
-- screen in step, and a marker to each regular one, on your screen over everything, saying how far it is. If it's
-- off the screen the marker waits at the edge, on the way to it. A Legendary has no marker. The server's copy of the
-- chest is already where it lands, so the fall is only drawn here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Places = require(ReplicatedStorage.Shared.Places)
local Skydrops = require(ReplicatedStorage.Shared.Skydrops)
local Glass = require(script.Parent.UI.Glass)
local Sfx = require(script.Parent.UI.Sfx)
local Theme = require(script.Parent.UI.Theme)

local STUDS_PER_METRE = 3 -- a block is a metre, as in Minecraft
local MARKER_ABOVE = 6 -- studs over the chest
local EDGE = 90 -- pixels: how near the screen's edge a marker comes

local SkydropController = {}

type Falling = { Land: CFrame, At: number }
type Marker = { Text: TextLabel, At: Vector3 }

local gui: ScreenGui
local falling: { [BasePart]: Falling } = {}
local shown: { [Instance]: Marker } = {}

local function watchChest(child: Instance)
	local landsAt = child:GetAttribute("LandsAt")
	if child:IsA("BasePart") and type(landsAt) == "number" and workspace:GetServerTimeNow() < landsAt then
		falling[child] = { Land = child.CFrame, At = landsAt }
	end
end

local function addMarker(marker: Instance)
	if not marker:IsA("Vector3Value") then
		return
	end
	local text = Glass.worldText(gui, "SKYDROP", 20, nil, Skydrops.Gold)
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Size = UDim2.fromOffset(170, 52)
	text.TextXAlignment = Enum.TextXAlignment.Center
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.TextTruncate = Enum.TextTruncate.None
	shown[marker] = { Text = text, At = marker.Value + Vector3.new(0, MARKER_ABOVE, 0) }
end

local function removeMarker(marker: Instance)
	local entry = shown[marker]
	if entry then
		entry.Text:Destroy()
		shown[marker] = nil
	end
end

-- Over the chest if it's on screen. If it's off the screen or behind you, at the edge nearest the way to it.
local function placeMarker(entry: Marker, camera: Camera)
	local screen = camera:WorldToScreenPoint(entry.At)
	local middle = gui.AbsoluteSize / 2
	local x, y = screen.X - middle.X, screen.Y - middle.Y
	local behind = screen.Z < 0
	if behind then
		x, y = -x, -y
	end
	local past = math.max(math.abs(x) / (middle.X - EDGE), math.abs(y) / (middle.Y - EDGE))
	if past > 0 and (behind or past > 1) then
		x, y = x / past, y / past
	end
	entry.Text.Position = UDim2.fromOffset(middle.X + x, middle.Y + y)
end

local function update()
	local now = workspace:GetServerTimeNow()
	for part, fall in falling do
		local left = fall.At - now
		if left <= 0 or not part.Parent then
			falling[part] = nil
			if part.Parent then
				part.CFrame = fall.Land
				Sfx.play("Place", fall.Land.Position)
				Sfx.play("Sparkle", fall.Land.Position)
			end
		else
			part.CFrame = fall.Land + Vector3.new(0, left / Skydrops.FallTime * Skydrops.FallFrom, 0)
		end
	end
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	for _, entry in shown do
		if root and root:IsA("BasePart") then
			local metres = math.round((root.Position - entry.At).Magnitude / STUDS_PER_METRE)
			entry.Text.Text = `SKYDROP\n{metres}m`
		end
		if camera then
			placeMarker(entry, camera)
		end
	end
end

function SkydropController.Start()
	if Places.Current() ~= "Warzone" then
		return
	end
	gui = Theme.screen("SkydropMarkers", 3)
	-- The map takes a while to build before these exist
	local chests = workspace:WaitForChild("LootChests", math.huge)
	chests.ChildAdded:Connect(watchChest)
	for _, child in chests:GetChildren() do
		watchChest(child)
	end
	local markers = ReplicatedStorage:WaitForChild("SkydropMarkers", math.huge)
	markers.ChildAdded:Connect(addMarker)
	markers.ChildRemoved:Connect(removeMarker)
	for _, marker in markers:GetChildren() do
		addMarker(marker)
	end
	RunService.RenderStepped:Connect(update)
end

return SkydropController
