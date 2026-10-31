--!strict
-- Draws our custom-style ProximityPrompts: a white card with the key to press, what it
-- does, and a fill bar while holding. On phones the whole card is a tap/hold button.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.UI.Theme)

local C = Theme.Color

local PromptUI = {}

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
		Parent = gui,
	})
	local card = Theme.make("TextButton", {
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = C.Panel,
		AutoButtonColor = false,
		Text = "",
		Parent = billboard,
	})
	Theme.corner(card, 12)
	Theme.stroke(card, C.Outline, 3)
	local scale = Theme.make("UIScale", { Scale = 0.7, Parent = card })
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Scale = 1 }):Play()

	-- The key to press, on a blue key cap
	local key = Theme.make("TextLabel", {
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.fromOffset(9, 9),
		BackgroundColor3 = C.Blue,
		Text = keyLabel(prompt, inputType),
		FontFace = Theme.Font.Bold,
		TextSize = 24,
		TextColor3 = C.White,
		Parent = card,
	})
	Theme.corner(key, 10)
	Theme.stroke(key, C.Outline, 2.5)
	Theme.outline(key, 1.6)

	local action = Theme.title(card, prompt.ActionText, 22)
	action.Position = UDim2.fromOffset(64, 6)
	action.Size = UDim2.new(1, -72, 0, 28)
	local object = Theme.text(card, prompt.ObjectText, 14, Theme.Font.Medium, C.InkMuted)
	object.Position = UDim2.fromOffset(64, 34)
	object.Size = UDim2.new(1, -72, 0, 18)

	-- Hold progress along the bottom edge
	local fill = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 9, 1, -4),
		Size = UDim2.fromOffset(0, 4),
		BackgroundColor3 = C.Green,
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
		billboard:Destroy()
	end)
end

function PromptUI.Start()
	-- BillboardGuis only render and take input when parented straight to PlayerGui
	local playerGui = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			show(prompt, inputType, playerGui)
		end
	end)
end

return PromptUI
