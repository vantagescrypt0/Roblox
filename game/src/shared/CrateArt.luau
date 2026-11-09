--!strict
-- The meshes for opening a Loot Crate (art/scripts/crate_open.py, client/CrateOpening.luau). Offset is where each sits
-- from the scene's origin, the middle of the floor the crate stands on. The rune has no texture, so the game can colour it.

export type Part = { Mesh: string, Size: Vector3, Offset: Vector3, Textured: boolean }

return table.freeze({
	Texture = "rbxassetid://86257249155185",
	Parts = table.freeze({
		Body = {
			Mesh = "rbxassetid://102510277705939",
			Size = Vector3.new(2.5, 1.375, 2.235),
			Offset = Vector3.new(0, 0.6675, -0.0325),
			Textured = true,
		} :: Part,
		Lid = {
			Mesh = "rbxassetid://106576848191816",
			Size = Vector3.new(2.5, 0.86, 2.2894),
			Offset = Vector3.new(0, 0.31, -0.0353),
			Textured = true,
		} :: Part,
		Dais = {
			Mesh = "rbxassetid://99136031277640",
			Size = Vector3.new(9.12, 4.31, 9.12),
			Offset = Vector3.new(0, -2.045, 0),
			Textured = true,
		} :: Part,
		Rune = {
			Mesh = "rbxassetid://106665006906795",
			Size = Vector3.new(0.7275, 1.52, 0.84),
			Offset = Vector3.new(0, 0.76, 0),
			Textured = false,
		} :: Part,
	}),
})
