--!strict
-- Writing on a sign on your island: it opens when you place one, and when you right-click one.
-- The server runs the words through Roblox's filter before they go on the sign.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Glass = require(script.Parent.Parent.UI.Glass)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local MAX_LENGTH = 48

local SignWindow = {}

local window: Window.Window
local box: TextBox
local count: TextLabel
local cell: { X: number, Y: number, Z: number }? = nil

local function save()
	local where = cell
	if where then
		Remotes.EditSign:FireServer(where.X, where.Y, where.Z, box.Text)
	end
	Window.close(window)
end

local function open(x: number, y: number, z: number, text: string)
	cell = { X = x, Y = y, Z = z }
	box.Text = text
	Window.open(window)
	box:CaptureFocus()
end

function SignWindow.Start()
	window = Window.new("Sign", "Write on the sign", Vector2.new(460, 280))
	local body = window.Body
	box = Theme.make("TextBox", {
		Size = UDim2.new(1, 0, 0, 110),
		BackgroundColor3 = Glass.Color.SlotBottom,
		BackgroundTransparency = 0.1,
		Text = "",
		PlaceholderText = "Your words",
		TextColor3 = Glass.Color.Ink,
		PlaceholderColor3 = Glass.Color.Muted,
		TextSize = 20,
		FontFace = Glass.Font.Bold,
		ClearTextOnFocus = false,
		MultiLine = true,
		TextWrapped = true,
		Parent = body,
	})
	Theme.corner(box, 10)
	Theme.padding(box, 10)

	count = Glass.text(body, "", 14, Glass.Font.Bold)
	count.Position = UDim2.fromOffset(0, 118)
	count.Size = UDim2.new(0.5, 0, 0, 20)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if #box.Text > MAX_LENGTH then
			box.Text = string.sub(box.Text, 1, MAX_LENGTH)
		end
		count.Text = `{#box.Text} / {MAX_LENGTH}`
	end)

	local done = Glass.button(body, "Save", UDim2.fromOffset(140, 44), save)
	done.Face.AnchorPoint = Vector2.new(1, 1)
	done.Face.Position = UDim2.fromScale(1, 1)

	Remotes.OpenSign.OnClientEvent:Connect(open)
end

return SignWindow
