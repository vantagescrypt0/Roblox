--!strict
-- The game's logo, SKYBLOX, built out of parts: chunky pixel letters ("SKY" in sky blue,
-- "BLOX" in gold) with a dark outline and a drop shadow, a rainbow arching over them and
-- blocky clouds round its feet. Also the clouds that drift around the islands.
--
-- Each row of same-coloured pixels is one part, so the whole logo is a few hundred parts.

local Decor = require(script.Parent.Decor)

local PIXEL = 2.2 -- studs per pixel
local GLYPH_WIDTH, GLYPH_HEIGHT, GAP = 6, 10, 2

-- Bold 6 x 10 letters, top row first
local FONT: { [string]: { string } } = {
	S = { ".#####", "######", "##....", "##....", "#####.", ".#####", "....##", "....##", "######", "#####." },
	K = { "##..##", "##..##", "##.##.", "####..", "###...", "###...", "####..", "##.##.", "##..##", "##..##" },
	Y = { "##..##", "##..##", "##..##", "######", ".####.", "..##..", "..##..", "..##..", "..##..", "..##.." },
	B = { "#####.", "######", "##..##", "##..##", "#####.", "######", "##..##", "##..##", "######", "#####." },
	L = { "##....", "##....", "##....", "##....", "##....", "##....", "##....", "##....", "######", "######" },
	O = { ".####.", "######", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", "######", ".####." },
	X = { "##..##", "##..##", ".####.", ".####.", "..##..", "..##..", ".####.", ".####.", "##..##", "##..##" },
}

-- The two halves of the word and their colours, top to bottom
local HALVES = {
	{ Letters = 3, Top = Color3.fromRGB(196, 242, 255), Bottom = Color3.fromRGB(46, 146, 236) },
	{ Letters = 4, Top = Color3.fromRGB(255, 240, 112), Bottom = Color3.fromRGB(246, 140, 28) },
}
local OUTLINE = Color3.fromRGB(26, 32, 68)
local SHADOW = Color3.fromRGB(12, 14, 36)
local RAINBOW = {
	Color3.fromRGB(232, 62, 60),
	Color3.fromRGB(246, 150, 42),
	Color3.fromRGB(250, 222, 64),
	Color3.fromRGB(92, 196, 82),
	Color3.fromRGB(70, 138, 232),
	Color3.fromRGB(148, 92, 208),
}
local RAINBOW_OUTER, BAND = 34, 2 -- pixels
local CLOUD_TOP = Color3.fromRGB(252, 252, 255)
local CLOUD_UNDER = Color3.fromRGB(212, 224, 242)

-- A cloud, top row first
local CLOUD = {
	"......####.......",
	"....########.....",
	"..###########.##.",
	".################",
	"#################",
	".###############.",
}

local Logo = {}

-- Draws a layer of pixels: each run of same-coloured pixels in a row becomes one part.
-- Pixel (c, r) sits at ((c + offset) * size, (r + 0.5) * size) in `frame`, r counting up
-- from the bottom; `colorAt` gives its colour, or nil where there's none.
local function layer(
	parent: Instance,
	frame: CFrame,
	size: number,
	c1: number,
	c2: number,
	r1: number,
	r2: number,
	offset: number,
	colorAt: (c: number, r: number) -> Color3?,
	z: number,
	depth: number,
	name: string,
	shadows: boolean
)
	for r = r1, r2 do
		local c = c1
		while c <= c2 do
			local color = colorAt(c, r)
			if color then
				local last = c
				while last < c2 and colorAt(last + 1, r) == color do
					last += 1
				end
				local x = ((c + last) / 2 + offset) * size
				local piece = Decor.Part(
					parent,
					name,
					Vector3.new((last - c + 1) * size, size, depth),
					frame * CFrame.new(x, (r + 0.5) * size, z),
					color
				)
				piece.CanCollide = false
				piece.CastShadow = shadows
				c = last + 1
			else
				c += 1
			end
		end
	end
end

-- A flat blocky cloud standing up in `frame`, its bottom middle at local (x, y, z), in
-- pixels of `size` studs; `flip` mirrors it
local function cloud(
	parent: Instance,
	frame: CFrame,
	size: number,
	x: number,
	y: number,
	z: number,
	depth: number,
	flip: boolean
)
	local rows, width = #CLOUD, #CLOUD[1]
	local at = frame * CFrame.new(x, y, z)
	layer(parent, at, size, 0, width - 1, 0, rows - 1, -(width - 1) / 2, function(c, r)
		local line = CLOUD[rows - r]
		local k = if flip then width - c else c + 1
		if string.sub(line, k, k) ~= "#" then
			return nil
		end
		return if r == 0 then CLOUD_UNDER else CLOUD_TOP
	end, 0, depth, "Cloud", false)
end

-- Builds the logo: `base` is the middle of the bottom of the letters, and it reads from
-- `facing` (the way its readers are)
function Logo.Build(parent: Instance, base: Vector3, facing: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Logo"
	model.Parent = parent
	-- Looking the way its readers look: x is their right, +z comes toward them
	local frame = CFrame.lookAt(base, base - facing)

	-- Which half of the word inks each pixel (1 = SKY, 2 = BLOX), by row (0 = bottom)
	local word = "SKYBLOX"
	local width = #word * GLYPH_WIDTH + (#word - 1) * GAP
	local ink: { [number]: { [number]: number } } = {}
	for r = -2, GLYPH_HEIGHT + 1 do
		ink[r] = {}
	end
	for i = 1, #word do
		local glyph = FONT[string.sub(word, i, i)]
		local left = (i - 1) * (GLYPH_WIDTH + GAP)
		local half = if i <= HALVES[1].Letters then 1 else 2
		for row, line in glyph do
			for k = 1, GLYPH_WIDTH do
				if string.sub(line, k, k) == "#" then
					ink[GLYPH_HEIGHT - row][left + k - 1] = half
				end
			end
		end
	end
	local function inked(c: number, r: number): boolean
		return ink[r] ~= nil and ink[r][c] ~= nil
	end
	-- Is there ink within one pixel of (c, r)?
	local function near(c: number, r: number): boolean
		for dc = -1, 1 do
			for dr = -1, 1 do
				if inked(c + dc, r + dr) then
					return true
				end
			end
		end
		return false
	end
	local centre = -(width - 1) / 2

	-- The letters, each half shading from its top colour down to its bottom one
	layer(model, frame, PIXEL, 0, width - 1, 0, GLYPH_HEIGHT - 1, centre, function(c, r)
		local half = ink[r][c]
		if not half then
			return nil
		end
		local colors = HALVES[half]
		return colors.Top:Lerp(colors.Bottom, (GLYPH_HEIGHT - 1 - r) / (GLYPH_HEIGHT - 1))
	end, 0, 2, "Letter", true)
	-- A dark outline a pixel wide just behind them, and a shadow below and to the right
	layer(model, frame, PIXEL, -1, width, -1, GLYPH_HEIGHT, centre, function(c, r)
		return if near(c, r) then OUTLINE else nil
	end, -1.6, 2, "Outline", true)
	layer(model, frame, PIXEL, 0, width + 1, -2, GLYPH_HEIGHT - 1, centre, function(c, r)
		return if near(c - 1, r + 1) then SHADOW else nil
	end, -2.8, 1.6, "Shadow", true)

	-- Clouds round the rainbow's feet, behind the end letters
	local edge = (width / 2 + 4) * PIXEL
	cloud(model, frame, PIXEL, -edge, -3 * PIXEL, -5, 3, false)
	cloud(model, frame, PIXEL, edge, -3 * PIXEL, -5, 3, true)

	-- The rainbow: bands of colour round a half circle from the letters' bottom middle
	local reach = RAINBOW_OUTER
	layer(model, frame, PIXEL, -reach, reach - 1, 0, reach - 1, 0.5, function(c, r)
		local d = math.sqrt((c + 0.5) ^ 2 + (r + 0.5) ^ 2)
		local band = math.floor((RAINBOW_OUTER - d) / BAND) + 1
		return if d < RAINBOW_OUTER then RAINBOW[band] else nil
	end, -8, 1.5, "Rainbow", false)

	return model
end

-- A puffy cloud drifting in the sky: a flat base with blocky puffs on top, `size` studs
-- across (about), centred on `centre`
function Logo.SkyCloud(parent: Instance, centre: Vector3, size: number, rng: Random)
	local base = CFrame.new(centre) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
	local thick = size * 0.16
	local function puff(sizeVec: Vector3, at: Vector3, color: Color3)
		local p = Decor.Part(parent, "Cloud", sizeVec, base * CFrame.new(at), color)
		p.CanCollide = false
		p.CastShadow = false
	end
	puff(Vector3.new(size, thick, size * 0.55), Vector3.zero, CLOUD_UNDER)
	puff(Vector3.new(size * 0.94, thick, size * 0.5), Vector3.new(0, thick * 0.6, 0), CLOUD_TOP)
	for _ = 1, 4 do
		local w = size * rng:NextNumber(0.22, 0.38)
		puff(
			Vector3.new(w, thick * rng:NextNumber(1, 1.8), w * rng:NextNumber(0.8, 1.2)),
			Vector3.new(size * rng:NextNumber(-0.3, 0.3), thick * 1.4, size * rng:NextNumber(-0.12, 0.12)),
			CLOUD_TOP
		)
	end
end

return Logo
