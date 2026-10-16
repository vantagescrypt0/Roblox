--!strict
-- Draws our custom-style ProximityPrompts: a rounded card with the key to press, what it
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
		return "👆"
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
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		Parent = billboard,
	})
	Theme.gradient(card, C.PanelTop, C.Panel)
	Theme.corner(card, 16)
	Theme.stroke(card)
	local scale = Theme.make("UIScale", { Scale = 0.6, Parent = card })
	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	local key = Theme.make("TextLabel", {
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = keyLabel(prompt, inputType),
		FontFace = Theme.Font.Title,
		TextSize = 26,
		TextColor3 = C.Stroke,
		Parent = card,
	})
	Theme.gradient(key, Color3.new(1, 1, 1), Color3.fromRGB(205, 212, 230))
	Theme.corner(key, 12)
	Theme.stroke(key, C.Stroke, 2.5)

	local action = Theme.title(card, prompt.ActionText, 22)
	action.Position = UDim2.fromOffset(72, 10)
	action.Size = UDim2.new(1, -82, 0, 28)
	local object = Theme.text(card, prompt.ObjectText, 14, Theme.Font.Medium, C.Muted)
	object.Position = UDim2.fromOffset(72, 38)
	object.Size = UDim2.new(1, -82, 0, 18)

	-- Hold progress along the bottom edge
	local fill = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -5),
		Size = UDim2.fromOffset(0, 5),
		BackgroundColor3 = C.Gold,
		BorderSizePixel = 0,
		Parent = card,
	})
	Theme.corner(fill, 999)

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
					Size = UDim2.new(1, -20, 0, 5),
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
			fill.Size = UDim2.fromOffset(0, 5)
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
