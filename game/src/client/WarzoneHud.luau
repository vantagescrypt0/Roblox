--!strict
-- What only the Warzone's screen has: a chip saying whether you're in the citadel's safe zone,
-- your combat tag counting down, the Leave button you hold to get out, and holding right-click
-- to raise your shield (it turns you to face where you're looking, so you block what you can
-- see). The server does the deciding (Services/WarzoneService); this shows it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Glass = require(script.Parent.UI.Glass)
local Theme = require(script.Parent.UI.Theme)

local C = Glass.Color
local LEAVE_HOLD = 7 -- seconds; the server's LEAVE_HOLD

local WarzoneHud = {}

local player = Players.LocalPlayer

function WarzoneHud.Start()
	if Places.Current() ~= "Warzone" then
		return
	end
	local gui = Theme.screen("WarzoneHud", 4)

	local top = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(300, 64),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local layout = Theme.list(top, Enum.FillDirection.Vertical, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Theme.autoScale(top)
	local zone = Glass.chip(top, "SAFE ZONE", C.Green)
	zone.LayoutOrder = 1
	local tag = Glass.chip(top, "IN COMBAT", C.Red)
	tag.LayoutOrder = 2
	tag.Visible = false

	-- The Leave button: hold it down
	local leave = Glass.button(gui, "Hold to Leave", UDim2.fromOffset(170, 50))
	local button = leave.Face
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -18, 1, -18)
	button.ClipsDescendants = true
	Theme.autoScale(button)
	local fill = Theme.make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = button,
	})
	Theme.corner(fill, 12)
	local label = leave.Label

	local holding = false
	local function setHolding(on: boolean)
		if holding ~= on then
			holding = on
			Remotes.LeaveWarzone:FireServer(on)
		end
	end
	button.MouseButton1Down:Connect(function()
		setHolding(true)
	end)
	UserInputService.InputEnded:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			setHolding(false)
		end
	end)

	-- The shield: hold right-click (or the Block button on a touch screen)
	local blocking = false
	local function setBlocking(on: boolean)
		if blocking ~= on then
			blocking = on
			Remotes.Block:FireServer(on)
		end
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and not processed then
			setBlocking(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			setBlocking(false)
		end
	end)
	if UserInputService.TouchEnabled then
		local block = Glass.button(gui, "Hold to Block", UDim2.fromOffset(170, 50))
		local blockButton = block.Face
		blockButton.AnchorPoint = Vector2.new(1, 1)
		blockButton.Position = UDim2.new(1, -18, 1, -78)
		Theme.autoScale(blockButton)
		blockButton.MouseButton1Down:Connect(function()
			setBlocking(true)
		end)
		blockButton.MouseButton1Up:Connect(function()
			setBlocking(false)
		end)
		blockButton.MouseLeave:Connect(function()
			setBlocking(false)
		end)
	end
	-- Face where the camera looks while the shield's up (the server says when it is)
	local turned = false
	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or not root:IsA("BasePart") then
			return
		end
		local up = player:GetAttribute("Blocking") == true
		if up then
			local look = workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1)
			if look.Magnitude > 0.01 then
				humanoid.AutoRotate = false
				turned = true
				root.CFrame = CFrame.lookAt(root.Position, root.Position + look)
			end
		elseif turned then
			turned = false
			humanoid.AutoRotate = true
		end
	end)

	local center: unknown = nil
	local radius: unknown = nil
	RunService.Heartbeat:Connect(function()
		center = center or workspace:GetAttribute("WarzoneCenter")
		radius = radius or workspace:GetAttribute("WarzoneSafeRadius")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and typeof(center) == "Vector3" and type(radius) == "number" then
			local flat = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
			local safe = flat.Magnitude <= radius
			Glass.setChip(zone, if safe then "SAFE ZONE" else "PVP ZONE", if safe then C.Green else C.Red)
		end

		local now = workspace:GetServerTimeNow()
		local tagUntil = player:GetAttribute("CombatTag")
		local tagLeft = if type(tagUntil) == "number" then tagUntil - now else 0
		tag.Visible = tagLeft > 0
		if tagLeft > 0 then
			tag.Text = `IN COMBAT {math.ceil(tagLeft)}s`
		end

		local leaveUntil = player:GetAttribute("LeavingUntil")
		local leaveLeft = if type(leaveUntil) == "number" then leaveUntil - now else nil
		if leaveLeft then
			fill.Size = UDim2.fromScale(math.clamp(1 - leaveLeft / LEAVE_HOLD, 0, 1), 1)
			label.Text = `Leaving in {math.max(1, math.ceil(leaveLeft))}...`
		else
			fill.Size = UDim2.fromScale(0, 1)
			label.Text = if tagLeft > 0 then "Can't leave yet" else "Hold to Leave"
		end
	end)
end

return WarzoneHud
