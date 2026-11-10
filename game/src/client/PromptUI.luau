--!strict
-- Draws our custom-style ProximityPrompts: a dark glass card with the key to press, what it
-- does, and a fill bar while holding. On phones the whole card is a tap/hold button.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Glass = require(script.Parent.UI.Glass)
local Theme = require(script.Parent.UI.Theme)
local Window = require(script.Parent.UI.Window)

local C = Glass.Color

local PromptUI = {}

-- The cards showing now. They switch off while a window is open: a card is drawn behind the window but, being a
-- 3D label, it can still catch clicks meant for the window's buttons (the Auction House's Cancel sat right where
-- the Auctioneer's card was, live, 2026-11-10)
local showing: { [BillboardGui]: boolean } = {}

local GAMEPAD_LABELS: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonB] = "B",
}

local function keyLabel(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "Tap"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return GAMEPAD_LABELS[prompt.GamepadKeyCode] or prompt.GamepadKeyCode.Name
	end
	return UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
end

local function show(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType, gui: Instance)
	local parent = prompt.Parent
	local adornee = if parent and parent:IsA("BasePart") then parent else nil
	if not adornee then
		return
	end

	-- Height of the part in world space (imported meshes are often rotated)
	local cf, half = adornee.CFrame, adornee.Size / 2
	local halfHeight = math.abs(cf.XVector.Y) * half.X
		+ math.abs(cf.YVector.Y) * half.Y
		+ math.abs(cf.ZVector.Y) * half.Z

	local billboard = Theme.make("BillboardGui", {
		Size = UDim2.fromOffset(250, 70),
		StudsOffsetWorldSpace = Vector3.new(0, math.min(halfHeight, 1.5) + 1.5, 0),
		AlwaysOnTop = true,
		Active = true,
		Adornee = adornee,
		Enabled = not Window.anyOpen(),
		Parent = gui,
	})
	showing[billboard] = true
	local card = Theme.make("TextButton", {
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.08,
		AutoButtonColor = false,
		Text = "",
		Parent = billboard,
	})
	Theme.corner(card, 12)
	Theme.stroke(card, C.Edge, 1, 0.82)
	local scale = Theme.make("UIScale", { Scale = 0.7, Parent = card })
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Scale = 1 }):Play()

	-- The key to press, on a key cap with the accent's edge
	local key = Theme.make("TextLabel", {
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.fromOffset(9, 9),
		BackgroundColor3 = C.SlotBottom,
		Text = keyLabel(prompt, inputType),
		FontFace = Glass.Font.Bold,
		TextSize = 24,
		TextColor3 = C.Ink,
		Parent = card,
	})
	Theme.corner(key, 10)
	Theme.stroke(key, C.Accent, 1.5, 0.2)

	local action = Glass.text(card, prompt.ActionText, 21, Glass.Font.Bold)
	action.Position = UDim2.fromOffset(64, 6)
	action.Size = UDim2.new(1, -72, 0, 28)
	local object = Glass.text(card, prompt.ObjectText, 14, Glass.Font.Body, C.Muted)
	object.Position = UDim2.fromOffset(64, 34)
	object.Size = UDim2.new(1, -72, 0, 18)

	-- Hold progress along the bottom edge
	local fill = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 9, 1, -4),
		Size = UDim2.fromOffset(0, 4),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = card,
	})
	Theme.corner(fill, 2)

	local connections = {}
	local holdTween: Tween? = nil
	table.insert(
		connections,
		prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
			action.Text = prompt.ActionText
		end)
	)
	table.insert(
		connections,
		prompt.PromptButtonHoldBegan:Connect(function()
			if prompt.HoldDuration > 0 then
				holdTween = TweenService:Create(fill, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), {
					Size = UDim2.new(1, -18, 0, 4),
				});
				(holdTween :: Tween):Play()
			end
		end)
	)
	table.insert(
		connections,
		prompt.PromptButtonHoldEnded:Connect(function()
			if holdTween then
				holdTween:Cancel()
			end
			fill.Size = UDim2.fromOffset(0, 4)
		end)
	)
	table.insert(
		connections,
		prompt.Triggered:Connect(function()
			Theme.pop(key, 1.3)
		end)
	)

	-- Touch: hold the card itself
	table.insert(
		connections,
		card.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				prompt:InputHoldBegin()
			end
		end)
	)
	table.insert(
		connections,
		card.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				prompt:InputHoldEnd()
			end
		end)
	)

	prompt.PromptHidden:Once(function()
		for _, connection in connections do
			connection:Disconnect()
		end
		showing[billboard] = nil
		billboard:Destroy()
	end)
end

function PromptUI.Start()
	Window.watchOpen(function(open)
		for billboard in showing do
			billboard.Enabled = not open
		end
	end)
	-- BillboardGuis only render and take input when parented straight to PlayerGui
	local playerGui = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			show(prompt, inputType, playerGui)
		end
	end)
end

return PromptUI
