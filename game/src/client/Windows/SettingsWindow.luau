--!strict
-- Settings (Menu > Settings): how loud the music and the sound effects are. They're the volumes of the "Music" and
-- "Effects" sound groups, and they're kept in your save, so they follow you between places.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local KNOB = 26

type Slider = { Set: (value: number) -> () }

local SettingsWindow = {}

local window: Window.Window
local music: Slider
local effects: Slider
local values = { Music = 1, Effects = 1 }
local applied = false

local function applyVolumes()
	for name, value in values do
		local group = SoundService:FindFirstChild(name)
		if group and group:IsA("SoundGroup") then
			group.Volume = value
		end
	end
end

local function save()
	Remotes.SaveSettings:FireServer(values.Music, values.Effects)
end

local function slider(parent: Instance, title: string, key: "Music" | "Effects", top: number): Slider
	local row = Theme.make("Frame", {
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 0, 76),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local name = Theme.title(row, title, 20)
	name.Size = UDim2.new(0.7, 0, 0, 28)
	local percent = Theme.text(row, "100%", 16, Theme.Font.Medium, C.InkMuted)
	percent.AnchorPoint = Vector2.new(1, 0)
	percent.Position = UDim2.fromScale(1, 0)
	percent.Size = UDim2.new(0.3, 0, 0, 28)
	percent.TextXAlignment = Enum.TextXAlignment.Right

	local track = Theme.make("TextButton", {
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = C.Well,
		AutoButtonColor = false,
		Text = "",
		Parent = row,
	})
	Theme.corner(track, 6)
	local fill = Theme.make("Frame", { BackgroundColor3 = C.Blue, BorderSizePixel = 0, Parent = track })
	Theme.corner(fill, 6)
	local knob = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(KNOB, KNOB),
		BackgroundColor3 = C.Ink,
		Parent = track,
	})
	Theme.corner(knob, KNOB // 2)

	local function show(value: number)
		fill.Size = UDim2.fromScale(value, 1)
		knob.Position = UDim2.fromScale(value, 0.5)
		percent.Text = `{math.round(value * 100)}%`
	end

	local function setFrom(x: number)
		local value = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		values[key] = value
		show(value)
		applyVolumes()
	end

	local dragging: Enum.UserInputType? = nil
	track.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = input.UserInputType
			setFrom(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		local moved = input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		if dragging and moved then
			setFrom(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and input.UserInputType == dragging then
			dragging = nil
			save()
		end
	end)
	show(values[key])
	return { Set = show }
end

-- Takes the saved volumes the first time the game's state arrives
function SettingsWindow.SetState(state: any)
	if applied or not state.Settings then
		return
	end
	applied = true
	values.Music = state.Settings.Music
	values.Effects = state.Settings.Effects
	music.Set(values.Music)
	effects.Set(values.Effects)
	applyVolumes()
end

function SettingsWindow.Toggle()
	Window.toggle(window)
end

function SettingsWindow.Start()
	window = Window.new("SettingsWindow", "Settings", Vector2.new(520, 300))
	music = slider(window.Body, "Music", "Music", 4)
	effects = slider(window.Body, "Sound effects", "Effects", 96)
end

return SettingsWindow
