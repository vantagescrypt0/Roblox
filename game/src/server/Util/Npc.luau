--!strict
-- The Town's shopkeepers: original blocky characters built from parts measured in
-- "pixels" (1/16 of a block) so they match the world. They all share one body (boots,
-- legs, arms at their sides, a cube head that pivots at the neck so the client can turn it
-- to watch players) and each has their own clothes and gear:
--   Merchant    traveling trader: newsboy cap, bushy mustache, green vest, red scarf and a
--               big canvas backpack with a bedroll and a lantern
--   Miner       yellow hard hat with a headlamp, grey beard, denim overalls, pickaxe on his back
--   Lumberjack  red plaid shirt, suspenders, green beanie, big brown beard, axe on his back
--   Builder     white shirt, blue overalls, red bandana, tool belt with a hammer and a pouch
-- Each gets a name tag (their name and what they trade) and a Shop attribute.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Shops = require(ReplicatedStorage.Shared.Shops)

local PIXEL = Blocks.Size / 16
local BACK_TILT = math.rad(35) -- tools slung across the back lean this far

type Add = (name: string, size: Vector3, center: Vector3, color: Color3, rotation: CFrame?) -> Part
type Look = {
	Skin: Color3,
	Shirt: Color3,
	Pants: Color3,
	Boots: Color3,
	Brows: Color3,
	Body: (add: Add) -> (),
	Head: (add: Add) -> (),
}

local SKIN = Color3.fromRGB(236, 194, 156)
local SKIN_TAN = Color3.fromRGB(214, 164, 122)
local EYE = Color3.fromRGB(40, 34, 40)
local CHEEK = Color3.fromRGB(238, 150, 136)
local LEATHER = Color3.fromRGB(96, 64, 40)
local GOLD = Color3.fromRGB(232, 183, 64)
local HANDLE = Color3.fromRGB(128, 90, 52)
local IRON = Color3.fromRGB(156, 158, 168)

-- A tool slung diagonally across the back: adds the handle and returns where its top end
-- is (low enough that the tool's head stays clear of the character's head)
local function slung(add: Add): Vector3
	local tilt = CFrame.Angles(0, 0, BACK_TILT)
	local center = Vector3.new(0, 14, 3.9)
	add("Handle", Vector3.new(1, 12, 1), center, HANDLE, tilt)
	return center + tilt:VectorToWorldSpace(Vector3.new(0, 5.5, 0))
end

local LOOKS: { [string]: Look } = {
	Merchant = {
		Skin = SKIN,
		Shirt = Color3.fromRGB(236, 222, 188),
		Pants = Color3.fromRGB(74, 70, 96),
		Boots = Color3.fromRGB(58, 40, 30),
		Brows = Color3.fromRGB(104, 70, 46),
		Body = function(add)
			local vest = Color3.fromRGB(64, 132, 92)
			local scarf = Color3.fromRGB(196, 72, 58)
			local canvas = Color3.fromRGB(164, 132, 88)
			for _, side in { -1, 1 } do
				add("Strap", Vector3.new(1.2, 9, 0.4), Vector3.new(side * 2.6, 16.4, -3.4), LEATHER)
			end
			add("Vest", Vector3.new(10.4, 8.6, 6.4), Vector3.new(0, 15.8, 0), vest)
			add("VestOpening", Vector3.new(2.4, 8.6, 0.3), Vector3.new(0, 15.8, -3.3), Color3.fromRGB(236, 222, 188))
			add("Belt", Vector3.new(10.8, 1.4, 6.8), Vector3.new(0, 11.2, 0), LEATHER)
			add("Buckle", Vector3.new(2, 1.8, 0.4), Vector3.new(0, 11.2, -3.5), GOLD)
			add("Scarf", Vector3.new(11, 2.2, 7), Vector3.new(0, 20.6, 0), scarf)
			add("ScarfTail", Vector3.new(2.2, 5, 0.6), Vector3.new(-2.6, 17.8, -3.7), scarf)
			-- Backpack piled with a rolled bedroll, and a lantern hanging off the side
			add("Pack", Vector3.new(9, 11, 4), Vector3.new(0, 16, 5.2), canvas)
			add("PackFlap", Vector3.new(9.4, 3, 4.4), Vector3.new(0, 20.2, 5.2), Color3.fromRGB(128, 98, 62))
			add("Bedroll", Vector3.new(11, 3, 3), Vector3.new(0, 23.2, 5.2), scarf)
			for _, x in { -3, 3 } do
				add("BedrollTie", Vector3.new(0.6, 3.2, 3.2), Vector3.new(x, 23.2, 5.2), LEATHER)
			end
			add("LanternFrame", Vector3.new(2, 2.6, 2), Vector3.new(5.6, 14.4, 5.2), LEATHER)
			local glass =
				add("Lantern", Vector3.new(1.4, 2, 1.4), Vector3.new(5.6, 14.4, 5.2), Color3.fromRGB(255, 214, 128))
			glass.Material = Enum.Material.Neon
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 210, 150)
			light.Brightness = 1.2
			light.Range = 14
			light.Shadows = false
			light.Parent = glass
		end,
		Head = function(add)
			local hair = Color3.fromRGB(104, 70, 46)
			local cap = Color3.fromRGB(52, 92, 108)
			add("Mustache", Vector3.new(5.6, 1.3, 0.6), Vector3.new(0, 2.3, -4.2), hair)
			add("HairBack", Vector3.new(8.2, 4, 1), Vector3.new(0, 4.2, 3.9), hair)
			for _, side in { -1, 1 } do
				add("MustacheEnd", Vector3.new(1.2, 1, 0.6), Vector3.new(side * 3.2, 1.9, -4.2), hair)
				add("Sideburn", Vector3.new(0.6, 3, 3), Vector3.new(side * 4.05, 4.4, 1), hair)
			end
			add("Cap", Vector3.new(8.8, 2.6, 8.8), Vector3.new(0, 8.8, 0.2), cap)
			add("CapTop", Vector3.new(7.6, 0.8, 7.6), Vector3.new(0, 10.3, 0.4), cap)
			add("Visor", Vector3.new(6.4, 0.6, 3), Vector3.new(0, 7.7, -5.2), Color3.fromRGB(36, 66, 78))
			add("CapButton", Vector3.new(1, 0.6, 1), Vector3.new(0, 10.9, 0.4), GOLD)
		end,
	},

	Miner = {
		Skin = SKIN_TAN,
		Shirt = Color3.fromRGB(176, 92, 52),
		Pants = Color3.fromRGB(58, 84, 122),
		Boots = Color3.fromRGB(48, 36, 28),
		Brows = Color3.fromRGB(150, 150, 150),
		Body = function(add)
			local denim = Color3.fromRGB(58, 84, 122)
			add("Bib", Vector3.new(7, 6, 6.4), Vector3.new(0, 14, 0), denim)
			for _, side in { -1, 1 } do
				add("Strap", Vector3.new(1.4, 5, 6.4), Vector3.new(side * 2.4, 18.4, 0), denim)
				add("StrapButton", Vector3.new(0.8, 0.8, 0.3), Vector3.new(side * 2.4, 16.8, -3.3), GOLD)
			end
			add("Pocket", Vector3.new(3, 2.4, 0.3), Vector3.new(0, 14.4, -3.3), Color3.fromRGB(46, 68, 102))
			add("Belt", Vector3.new(10.8, 1.4, 6.8), Vector3.new(0, 11.2, 0), LEATHER)
			-- Pickaxe slung across his back
			local top = slung(add)
			add(
				"PickHead",
				Vector3.new(8, 1.6, 1.6),
				top + Vector3.new(0, 0, 0.3),
				IRON,
				CFrame.Angles(0, 0, BACK_TILT)
			)
		end,
		Head = function(add)
			local beard = Color3.fromRGB(176, 176, 176)
			local hat = Color3.fromRGB(240, 192, 48)
			add("Beard", Vector3.new(7.4, 3.4, 1), Vector3.new(0, 1.3, -4.1), beard)
			add("Mustache", Vector3.new(5, 1.2, 0.6), Vector3.new(0, 2.6, -4.5), beard)
			for _, side in { -1, 1 } do
				add("Sideburn", Vector3.new(0.6, 4, 4), Vector3.new(side * 4.05, 3.6, 0), beard)
			end
			add("HairBack", Vector3.new(8.2, 3, 1), Vector3.new(0, 4.8, 3.9), beard)
			add("Hat", Vector3.new(8.8, 2.8, 8.8), Vector3.new(0, 8.6, 0), hat)
			add("HatTop", Vector3.new(7, 1.2, 7), Vector3.new(0, 10.6, 0), hat)
			add("Brim", Vector3.new(10.4, 0.6, 10.4), Vector3.new(0, 7.4, -0.2), Color3.fromRGB(222, 170, 36))
			add("LampMount", Vector3.new(2.4, 2.2, 0.8), Vector3.new(0, 8.8, -4.6), Color3.fromRGB(70, 70, 76))
			local lamp =
				add("Lamp", Vector3.new(1.6, 1.4, 0.4), Vector3.new(0, 8.8, -5.1), Color3.fromRGB(255, 240, 190))
			lamp.Material = Enum.Material.Neon
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Front
			light.Color = Color3.fromRGB(255, 236, 190)
			light.Brightness = 2
			light.Range = 16
			light.Angle = 50
			light.Shadows = false
			light.Parent = lamp
		end,
	},

	Lumberjack = {
		Skin = SKIN,
		Shirt = Color3.fromRGB(184, 46, 42),
		Pants = Color3.fromRGB(92, 70, 48),
		Boots = Color3.fromRGB(58, 40, 30),
		Brows = Color3.fromRGB(110, 62, 34),
		Body = function(add)
			local check = Color3.fromRGB(58, 26, 30)
			-- Plaid: dark bands around the shirt and sleeves
			for _, y in { 12.6, 16.2, 19.4 } do
				add("Plaid", Vector3.new(10.2, 1, 6.2), Vector3.new(0, y, 0), check)
			end
			for _, side in { -1, 1 } do
				for _, y in { 14, 18 } do
					add("SleevePlaid", Vector3.new(3.2, 1, 3.6), Vector3.new(side * 6.6, y, 0), check)
				end
				add(
					"Suspender",
					Vector3.new(1.4, 10, 6.4),
					Vector3.new(side * 2.6, 15.6, 0),
					Color3.fromRGB(40, 40, 46)
				)
			end
			add("Belt", Vector3.new(10.8, 1.4, 6.8), Vector3.new(0, 11.2, 0), LEATHER)
			add("Buckle", Vector3.new(2, 1.8, 0.4), Vector3.new(0, 11.2, -3.5), IRON)
			-- Axe slung across his back
			local top = slung(add)
			local tilt = CFrame.Angles(0, 0, BACK_TILT)
			local blade = top + tilt:VectorToWorldSpace(Vector3.new(2, -1, 0)) + Vector3.new(0, 0, 0.5)
			add("AxeHead", Vector3.new(3.4, 3.4, 1), blade, IRON, tilt)
			add(
				"AxeEdge",
				Vector3.new(0.8, 4, 1.1),
				blade + tilt:VectorToWorldSpace(Vector3.new(1.9, 0, 0)),
				Color3.fromRGB(214, 218, 226),
				tilt
			)
		end,
		Head = function(add)
			local beard = Color3.fromRGB(110, 62, 34)
			local beanie = Color3.fromRGB(58, 110, 64)
			add("Beard", Vector3.new(8.2, 4.4, 1.4), Vector3.new(0, 1.2, -4.1), beard)
			add("BeardTip", Vector3.new(5, 2, 1.4), Vector3.new(0, -1.4, -4), beard)
			add("Mustache", Vector3.new(5.4, 1.4, 0.6), Vector3.new(0, 2.8, -4.8), Color3.fromRGB(92, 50, 26))
			for _, side in { -1, 1 } do
				add("Sideburn", Vector3.new(0.6, 5, 4.4), Vector3.new(side * 4.05, 3.4, -0.4), beard)
			end
			add("HairBack", Vector3.new(8.2, 4, 1), Vector3.new(0, 4.4, 3.9), beard)
			add("Beanie", Vector3.new(8.8, 3.6, 8.8), Vector3.new(0, 8.6, 0), beanie)
			add("BeanieFold", Vector3.new(9.2, 1.6, 9.2), Vector3.new(0, 7.2, 0), Color3.fromRGB(46, 90, 52))
			add("Pompom", Vector3.new(2.4, 2, 2.4), Vector3.new(0, 11.2, 0), Color3.fromRGB(236, 230, 214))
		end,
	},

	Builder = {
		Skin = SKIN_TAN,
		Shirt = Color3.fromRGB(240, 236, 226),
		Pants = Color3.fromRGB(60, 96, 156),
		Boots = Color3.fromRGB(122, 82, 44),
		Brows = Color3.fromRGB(46, 36, 32),
		Body = function(add)
			local denim = Color3.fromRGB(60, 96, 156)
			add("Bib", Vector3.new(7, 5.6, 6.4), Vector3.new(0, 14, 0), denim)
			for _, side in { -1, 1 } do
				add("Strap", Vector3.new(1.4, 5, 6.4), Vector3.new(side * 2.4, 18.4, 0), denim)
			end
			-- Tool belt with a hammer and a pouch of nails
			add("ToolBelt", Vector3.new(11, 1.8, 7), Vector3.new(0, 11, 0), Color3.fromRGB(150, 98, 48))
			add("HammerHandle", Vector3.new(1, 5.4, 1), Vector3.new(3.2, 8.4, -3.9), HANDLE)
			add("HammerHead", Vector3.new(3.6, 1.6, 1.6), Vector3.new(3.2, 11.6, -4.2), IRON)
			add("Pouch", Vector3.new(3.4, 3.2, 1.6), Vector3.new(-3.2, 9.4, -3.9), Color3.fromRGB(122, 78, 38))
			add("PouchFlap", Vector3.new(3.6, 1, 1.8), Vector3.new(-3.2, 10.8, -3.9), Color3.fromRGB(100, 62, 30))
		end,
		Head = function(add)
			local hair = Color3.fromRGB(46, 36, 32)
			local bandana = Color3.fromRGB(196, 58, 52)
			add("Hair", Vector3.new(8.4, 2.4, 8.4), Vector3.new(0, 8.6, 0.2), hair)
			add("HairBack", Vector3.new(8.2, 4, 1), Vector3.new(0, 5.4, 3.9), hair)
			add("Bandana", Vector3.new(8.6, 1.6, 8.6), Vector3.new(0, 7.2, 0), bandana)
			add("Knot", Vector3.new(2, 2, 1.4), Vector3.new(0, 6.8, 4.8), bandana)
			add("KnotTail", Vector3.new(1.2, 2.6, 0.6), Vector3.new(0.8, 5.2, 5), bandana)
			add("Stubble", Vector3.new(5.6, 1.8, 0.2), Vector3.new(0, 1.4, -4.05), Color3.fromRGB(176, 132, 98))
			-- Pencil tucked behind his ear
			add("Pencil", Vector3.new(0.6, 0.6, 3.4), Vector3.new(4.3, 5.4, 0.6), Color3.fromRGB(240, 196, 64))
		end,
	},
}

local Npc = {}

-- One box: size and center in pixels, in the frame `origin`
local function box(
	parent: Instance,
	name: string,
	origin: CFrame,
	size: Vector3,
	center: Vector3,
	color: Color3,
	rotation: CFrame?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size * PIXEL
	part.CFrame = origin * CFrame.new(center * PIXEL) * (rotation or CFrame.identity)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

local function addNameTag(head: BasePart, name: string, tagline: string)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(220, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5.4, 0) -- above the chat bubble
	-- Seen through the shop door, not through the walls from across town
	gui.MaxDistance = 45
	gui.AlwaysOnTop = false
	gui.Adornee = head
	gui.Parent = head
	local function line(text: string, size: number, y: number, color: Color3, font: Font)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, size + 4)
		label.Position = UDim2.fromOffset(0, y)
		label.BackgroundTransparency = 1
		label.FontFace = font
		label.TextSize = size
		label.TextColor3 = color
		label.Text = text
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(46, 28, 15)
		stroke.Thickness = 2
		stroke.Parent = label
	end
	-- Same fonts as the game's UI (client/UI/Theme.luau)
	line(name, 26, 0, Color3.fromRGB(242, 193, 78), Font.fromEnum(Enum.Font.Fondamento))
	line(
		tagline,
		15,
		31,
		Color3.fromRGB(251, 238, 211),
		Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold)
	)
end

-- Builds the shopkeeper for a shop in Shops.luau, standing at `feet` and facing `facing`.
-- Its "Head" model turns to look at players (on the client).
function Npc.Build(shopId: string, feet: Vector3, facing: Vector3, parent: Instance): Model
	local shop = Shops.ById[shopId]
	local look = LOOKS[shopId]
	assert(shop and look, `No shopkeeper look for {shopId}`)

	local model = Instance.new("Model")
	model.Name = shopId
	model:SetAttribute("Shop", shopId)
	local origin = CFrame.lookAt(feet, feet + facing) -- front is -Z
	local function add(name: string, size: Vector3, center: Vector3, color: Color3, rotation: CFrame?): Part
		return box(model, name, origin, size, center, color, rotation)
	end

	for _, side in { -1, 1 } do
		add("Boot", Vector3.new(4.4, 2.4, 5.4), Vector3.new(side * 2.2, 1.2, -0.5), look.Boots)
		add("Leg", Vector3.new(4, 8, 4), Vector3.new(side * 2.2, 6.4, 0), look.Pants)
		add("Sleeve", Vector3.new(3, 8, 3.4), Vector3.new(side * 6.6, 16.2, 0), look.Shirt)
		add("Hand", Vector3.new(3, 2.6, 3), Vector3.new(side * 6.6, 10.9, 0), look.Skin)
	end
	local body = add("Body", Vector3.new(10, 10, 6), Vector3.new(0, 15.4, 0), look.Shirt)
	look.Body(add)

	-- Head (pivots at the neck so it can turn to watch players)
	local headModel = Instance.new("Model")
	headModel.Name = "Head"
	headModel.Parent = model
	local neck = origin * CFrame.new(0, 21.6 * PIXEL, 0)
	local function addHead(name: string, size: Vector3, center: Vector3, color: Color3, rotation: CFrame?): Part
		return box(headModel, name, neck, size, center, color, rotation)
	end
	local head = addHead("Head", Vector3.new(8, 8, 8), Vector3.new(0, 4, 0), look.Skin)
	addHead(
		"Nose",
		Vector3.new(1.4, 1.4, 1),
		Vector3.new(0, 3.4, -4.4),
		look.Skin:Lerp(Color3.new(0.5, 0.2, 0.1), 0.12)
	)
	for _, side in { -1, 1 } do
		addHead("Eye", Vector3.new(1.2, 1.8, 0.3), Vector3.new(side * 1.8, 4.6, -4.05), EYE)
		addHead("Glint", Vector3.new(0.5, 0.5, 0.3), Vector3.new(side * 1.6, 5.2, -4.15), Color3.new(1, 1, 1))
		addHead("Brow", Vector3.new(2.2, 0.6, 0.3), Vector3.new(side * 1.9, 6.1, -4.05), look.Brows)
		addHead("Cheek", Vector3.new(1.2, 0.9, 0.2), Vector3.new(side * 2.9, 2.9, -4.05), CHEEK)
	end
	look.Head(addHead)
	headModel.PrimaryPart = head
	addNameTag(head, shop.Name, shop.Tagline)

	model.PrimaryPart = body
	model.Parent = parent
	return model
end

return Npc
