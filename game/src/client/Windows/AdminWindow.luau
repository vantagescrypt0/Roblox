--!strict
-- The admin panel: F2 opens it, for Config.Admins only (anyone in Studio). Who's in this server is on the left; on the
-- right are tabs for the picked player (Player, Give & set) and for the whole server. Every button asks the server
-- (Services/AdminService), which checks you're an admin and answers in the line at the bottom and in your chat.
-- Watching someone moves your camera onto them; Stop watching brings it back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Skills = require(ReplicatedStorage.Shared.Skills)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Theme.Color

local KEY = Enum.KeyCode.F2
local LIST_WIDTH = 250
local REFRESH = 3 -- seconds between updates of the player list while the panel is open
local CONFIRM_TIME = 4 -- seconds the second press of Shut down has
local MAX_RESULTS = 30 -- items shown for a search
local RESULT_HEIGHT = 40

type Row = {
	UserId: number,
	Name: string,
	DisplayName: string,
	Level: number,
	Coins: number,
	Strikes: number,
	Catches: number,
	Kicks: number,
	Last: string,
	LastAt: number,
}

local AdminWindow = {}

local localPlayer = Players.LocalPlayer
local window: Window.Window
local rows: { Row } = {}
local selected = 0 -- user id of the picked player
local watching = 0 -- user id of who the camera follows (0 = yourself)
local tab = "Player"
local chosenItem: string? = nil
local chosenSkill: string? = nil
local confirmUntil = 0

local entries: { [number]: Theme.Button } = {}
local list: ScrollingFrame
local pages: { [string]: GuiObject } = {}
local tabs: { [string]: Theme.Button } = {}
local status: TextLabel
-- Player tab
local heading: TextLabel
local info: TextLabel
local record: TextLabel
local watchButton: Theme.Button
local reasonBox: TextBox
local daysBox: TextBox
-- Give & set tab
local giveHeading: TextLabel
local searchBox: TextBox
local results: ScrollingFrame
local resultButtons: { [string]: Theme.Button } = {}
local amountBox: TextBox
local coinsBox: TextBox
local levelBox: TextBox
local skillBox: TextBox
local skillButtons: { [string]: Theme.Button } = {}
-- Server tab
local announceBox: TextBox
local unbanBox: TextBox
local shutdownButton: Theme.Button

local function isAdmin(): boolean
	return Config.Admins[localPlayer.UserId] == true or RunService:IsStudio()
end

local function act(action: string, ...: any)
	Remotes.AdminAction:FireServer(action, ...)
end

local function rowOf(userId: number): Row?
	for _, row in rows do
		if row.UserId == userId then
			return row
		end
	end
	return nil
end

local function ago(seconds: number): string
	if seconds < 120 then
		return `{seconds}s ago`
	elseif seconds < 7200 then
		return `{seconds // 60} min ago`
	elseif seconds < 172800 then
		return `{seconds // 3600} h ago`
	end
	return `{seconds // 86400} days ago`
end

local function count(n: number, one: string, many: string): string
	return `{n} {if n == 1 then one else many}`
end

-- Building blocks ---------------------------------------------------------------------------------------------

local function input(parent: Instance, placeholder: string, width: UDim, order: number): TextBox
	local box = Theme.make("TextBox", {
		Size = UDim2.new(width, UDim.new(0, 40)),
		BackgroundColor3 = C.SlotBottom,
		BackgroundTransparency = 0.1,
		Text = "",
		PlaceholderText = placeholder,
		TextColor3 = C.Ink,
		PlaceholderColor3 = C.Muted,
		TextSize = 17,
		FontFace = Theme.Font.Bold,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = order,
		Parent = parent,
	})
	Theme.corner(box, 10)
	Theme.padding(box, 12, 12, 0, 0)
	Theme.stroke(box, C.Edge, 1, 0.85)
	return box
end

-- A row of things side by side on a page
local function line(page: Instance, order: number, height: number): Frame
	local frame = Theme.make("Frame", {
		Size = UDim2.new(1, -8, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = page,
	})
	local layout = Theme.list(frame, Enum.FillDirection.Horizontal, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	return frame
end

local function label(page: Instance, order: number, text: string, color: Color3?): TextLabel
	local text_ = Theme.text(page, text, 16, Theme.Font.Bold, color or C.InkMuted)
	text_.Size = UDim2.new(1, -8, 0, 22)
	text_.LayoutOrder = order
	return text_
end

local function button(parent: Instance, text: string, color: Color3, width: number, order: number, onClick: () -> ())
	local made = Theme.button(parent, text, color, UDim2.fromOffset(width, 40), onClick)
	made.Holder.LayoutOrder = order
	return made
end

local function numberIn(box: TextBox): number?
	return tonumber((string.gsub(box.Text, "[,%s]", "")))
end

-- Showing ------------------------------------------------------------------------------------------------------

local function refreshResults()
	for itemId, entry in resultButtons do
		entry.SetColor(if itemId == chosenItem then C.Accent else C.Navy)
	end
end

local function search()
	Window.clear(results)
	table.clear(resultButtons)
	local wanted = string.lower(searchBox.Text)
	local found = {}
	for itemId, item in Items do
		if
			wanted == ""
			or string.find(string.lower(item.Name), wanted, 1, true)
			or string.find(string.lower(itemId), wanted, 1, true)
		then
			table.insert(found, itemId)
		end
	end
	table.sort(found, function(a, b)
		return Items[a].Name < Items[b].Name
	end)
	for order = 1, math.min(#found, MAX_RESULTS) do
		local itemId = found[order]
		local entry = Theme.button(results, "", C.Navy, UDim2.new(1, -4, 0, RESULT_HEIGHT), function()
			chosenItem = itemId
			refreshResults()
		end)
		entry.Holder.LayoutOrder = order
		entry.Label.Text = Items[itemId].Name
		entry.Label.TextXAlignment = Enum.TextXAlignment.Left
		entry.Label.Position = UDim2.fromOffset(RESULT_HEIGHT + 4, 0)
		entry.Label.Size = UDim2.new(1, -(RESULT_HEIGHT + 8), 1, 0)
		entry.Label.TextSize = 16
		local icon = Theme.make("Frame", {
			Size = UDim2.fromOffset(RESULT_HEIGHT - 8, RESULT_HEIGHT - 8),
			Position = UDim2.fromOffset(6, 4),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = entry.Face,
		})
		ItemIcon.create(icon, itemId, UDim2.fromScale(1, 1))
		resultButtons[itemId] = entry
	end
	refreshResults()
end

local function refresh()
	if not rowOf(selected) then
		selected = localPlayer.UserId
	end
	-- The list: everyone here, with anyone carrying strikes in orange
	local seen: { [number]: boolean } = {}
	for order, row in rows do
		seen[row.UserId] = true
		local entry = entries[row.UserId]
		if not entry then
			local userId = row.UserId
			entry = Theme.button(list, "", C.Navy, UDim2.new(1, -4, 0, 46), function()
				selected = userId
				refresh()
			end)
			entries[userId] = entry
		end
		entry.Holder.LayoutOrder = order
		local strikes = if row.Strikes > 0 then `  ({row.Strikes})` else ""
		entry.SetText(`{row.DisplayName}{strikes}`)
		entry.SetColor(if row.UserId == selected then C.Accent elseif row.Strikes >= 1 then C.Orange else C.Navy)
	end
	for userId, entry in entries do
		if not seen[userId] then
			entry.Holder:Destroy()
			entries[userId] = nil
		end
	end

	for name, page in pages do
		page.Visible = name == tab
		tabs[name].SetColor(if name == tab then C.Accent else C.Inset)
	end

	local row = rowOf(selected)
	if row then
		local you = if row.UserId == localPlayer.UserId then " - you" else ""
		heading.Text = `{row.DisplayName} (@{row.Name}){you}`
		info.Text = `User id {row.UserId}  ·  Level {row.Level}  ·  {Theme.formatNumber(row.Coins)} coins`
		if row.Catches == 0 and row.Strikes == 0 then
			record.Text = "Never caught by the anti-cheat."
			record.TextColor3 = C.InkMuted
		else
			local last = if row.Last ~= "" then `  ·  last: {row.Last} ({ago(os.time() - row.LastAt)})` else ""
			record.Text = `{row.Strikes} strikes now  ·  {count(row.Catches, "catch", "catches")}, {count(
				row.Kicks,
				"kick",
				"kicks"
			)}{last}`
			record.TextColor3 = C.Orange
		end
		giveHeading.Text = `Give to {row.DisplayName}`
	end
	watchButton.SetText(if watching ~= 0 then "Stop watching" else "Watch")
	watchButton.SetColor(if watching ~= 0 then C.Orange else C.Accent)
	watchButton.SetEnabled(watching ~= 0 or selected ~= localPlayer.UserId)

	for skillId, entry in skillButtons do
		entry.SetColor(if skillId == chosenSkill then C.Accent else C.Navy)
	end
	local confirming = os.clock() < confirmUntil
	shutdownButton.SetText(if confirming then "Press again to shut down" else "Shut down this server")
end

-- Watching someone ---------------------------------------------------------------------------------------------

local function ownHumanoid(): Humanoid?
	return localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
end

local function stopWatching()
	watching = 0
	act("Spectate", 0)
	local camera = Workspace.CurrentCamera
	local humanoid = ownHumanoid()
	if camera and humanoid then
		camera.CameraSubject = humanoid
	end
	refresh()
end

-- The camera follows them (and keeps doing so if they respawn) until you stop
local function watch(userId: number)
	watching = userId
	act("Spectate", userId)
	refresh()
	task.spawn(function()
		while watching == userId do
			local target = Players:GetPlayerByUserId(userId)
			if not target then
				stopWatching()
				return
			end
			local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
			local camera = Workspace.CurrentCamera
			if humanoid and camera and camera.CameraSubject ~= humanoid then
				camera.CameraSubject = humanoid
			end
			task.wait(0.3)
		end
	end)
end

-- Building the window -----------------------------------------------------------------------------------------

local function page(parent: Instance, name: string): ScrollingFrame
	local frame = Window.scrollList(parent, UDim2.new(1, 0, 1, -92), UDim2.fromOffset(0, 52))
	frame.Visible = false
	pages[name] = frame
	return frame
end

local function buildPlayerPage(parent: Instance)
	local p = page(parent, "Player")
	heading = Theme.title(p, "", 22)
	heading.Size = UDim2.new(1, -8, 0, 28)
	heading.LayoutOrder = 1
	info = label(p, 2, "", C.InkMuted)
	record = label(p, 3, "", C.InkMuted)

	label(p, 4, "Move", C.Ink)
	local moves = line(p, 5, 44)
	button(moves, "Go to", C.Accent, 150, 1, function()
		act("GoTo", selected)
	end)
	button(moves, "Bring", C.Accent, 150, 2, function()
		act("Bring", selected)
	end)
	watchButton = button(moves, "Watch", C.Accent, 170, 3, function()
		if watching ~= 0 then
			stopWatching()
		elseif selected ~= localPlayer.UserId then
			watch(selected)
		end
	end)

	label(p, 6, "Moderate", C.Ink)
	reasonBox = input(p, "Reason (shown to them)", UDim.new(1, -8), 7)
	local mod = line(p, 8, 44)
	daysBox = input(mod, "Days (empty = for good)", UDim.new(0, 220), 1)
	button(mod, "Kick", C.Orange, 120, 2, function()
		act("Kick", selected, reasonBox.Text)
	end)
	button(mod, "Ban", C.Red, 120, 3, function()
		act("Ban", selected, numberIn(daysBox), reasonBox.Text)
	end)
	label(p, 9, "Kicks are for this server. Bans reach the whole game, alt accounts too.", C.InkMuted)
end

local function buildGivePage(parent: Instance)
	local p = page(parent, "Give")
	giveHeading = Theme.title(p, "", 22)
	giveHeading.Size = UDim2.new(1, -8, 0, 28)
	giveHeading.LayoutOrder = 1

	label(p, 2, "Items", C.Ink)
	local find = line(p, 3, 44)
	searchBox = input(find, "Search items", UDim.new(1, -310), 1)
	amountBox = input(find, "How many", UDim.new(0, 130), 2)
	amountBox.Text = "1"
	button(find, "Give", C.Green, 150, 3, function()
		act("Give", selected, chosenItem, numberIn(amountBox))
	end)
	results = Window.scrollList(p, UDim2.new(1, -8, 0, 176))
	results.LayoutOrder = 4
	searchBox:GetPropertyChangedSignal("Text"):Connect(search)

	label(p, 5, "Coins (a minus takes them away)", C.Ink)
	local coins = line(p, 6, 44)
	coinsBox = input(coins, "Coins", UDim.new(0, 220), 1)
	button(coins, "Give or take", C.Gold, 170, 2, function()
		act("Coins", selected, numberIn(coinsBox))
	end)

	label(p, 7, "Player level (1 to 50)", C.Ink)
	local level = line(p, 8, 44)
	levelBox = input(level, "Player level", UDim.new(0, 220), 1)
	button(level, "Set level", C.Gold, 170, 2, function()
		act("Level", selected, numberIn(levelBox))
	end)

	label(p, 9, "Skill level (1 to 99)", C.Ink)
	local pick = line(p, 10, 44)
	for order, skill in Skills.List do
		local skillId = skill.Id
		skillButtons[skillId] = button(pick, skill.Name, C.Navy, 112, order, function()
			chosenSkill = skillId
			refresh()
		end)
	end
	local set = line(p, 11, 44)
	skillBox = input(set, "Skill level", UDim.new(0, 220), 1)
	button(set, "Set skill", C.Gold, 170, 2, function()
		act("Skill", selected, chosenSkill, numberIn(skillBox))
	end)
end

local function buildServerPage(parent: Instance)
	local p = page(parent, "Server")
	label(p, 1, "Announcement to everyone in this server", C.Ink)
	local say = line(p, 2, 44)
	announceBox = input(say, "What to announce", UDim.new(1, -170), 1)
	button(say, "Announce", C.Accent, 160, 2, function()
		act("Announce", announceBox.Text)
		announceBox.Text = ""
	end)

	label(p, 3, "Unban someone (username or user id)", C.Ink)
	local free = line(p, 4, 44)
	unbanBox = input(free, "Username or user id", UDim.new(1, -170), 1)
	button(free, "Unban", C.Green, 160, 2, function()
		act("Unban", unbanBox.Text)
	end)

	label(p, 5, "Shut down this server: everyone is saved and sent out, you too", C.Ink)
	local stop = line(p, 6, 44)
	shutdownButton = button(stop, "Shut down this server", C.Red, 300, 1, function()
		if os.clock() < confirmUntil then
			act("Shutdown")
			return
		end
		confirmUntil = os.clock() + CONFIRM_TIME
		refresh()
		task.delay(CONFIRM_TIME, refresh)
	end)
end

function AdminWindow.Toggle()
	if window then
		Window.toggle(window)
	end
end

function AdminWindow.Start()
	if not isAdmin() then
		return
	end
	window = Window.new("AdminWindow", "Admin", Vector2.new(940, 620))
	window.OnOpen = function()
		act("List")
		refresh()
	end

	list = Window.scrollList(window.Body, UDim2.new(0, LIST_WIDTH, 1, 0))
	local right = Theme.make("Frame", {
		Position = UDim2.fromOffset(LIST_WIDTH + 16, 0),
		Size = UDim2.new(1, -(LIST_WIDTH + 16), 1, 0),
		BackgroundTransparency = 1,
		Parent = window.Body,
	})
	local tabRow = line(right, 0, 44)
	tabRow.Size = UDim2.new(1, 0, 0, 44)
	for order, name in { "Player", "Give", "Server" } do
		tabs[name] = button(tabRow, if name == "Give" then "Give & set" else name, C.Inset, 170, order, function()
			tab = name
			refresh()
		end)
	end
	buildPlayerPage(right)
	buildGivePage(right)
	buildServerPage(right)
	status = Theme.text(right, "F2 opens and closes this panel.", 15, Theme.Font.Medium, C.InkMuted)
	status.AnchorPoint = Vector2.new(0, 1)
	status.Position = UDim2.fromScale(0, 1)
	status.Size = UDim2.new(1, 0, 0, 30)
	search()

	Remotes.AdminState.OnClientEvent:Connect(function(newRows: { Row }, watchingId: number)
		rows = newRows
		if watching ~= 0 and watchingId == 0 then
			-- The server stopped it (they left)
			stopWatching()
		end
		refresh()
	end)
	Remotes.AdminReply.OnClientEvent:Connect(function(text: string)
		status.Text = text
		task.delay(0.3, act, "List")
	end)
	UserInputService.InputBegan:Connect(function(inputObject, processed)
		if not processed and inputObject.KeyCode == KEY then
			AdminWindow.Toggle()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(REFRESH)
			if window.IsOpen then
				act("List")
			end
		end
	end)
	refresh()
end

return AdminWindow
