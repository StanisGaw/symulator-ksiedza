extends LocationBase
## Rectory (plebania): bed, desk with the finance ledger, phone, bookshelf. Dollhouse view.

const S := 8.0


func _ready() -> void:
	_environment(Color("0e0d12"), Color("7a7060"), 1.4)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(S, S)
	_mesh(floor_mesh, ToonMaterial.make(Palette.FLOOR_WOOD, Color.BLACK, 0.0, false), Vector3.ZERO)
	_collider(Vector3(S, 1, S), Vector3(0, -0.5, 0))
	_box(Vector3(S + 0.4, 3.2, 0.4), Palette.WALL_INT, Vector3(0, 1.6, -S / 2 - 0.2))
	_box(Vector3(0.4, 3.2, S), Palette.WALL_INT_DARK, Vector3(-S / 2 - 0.2, 1.6, 0))
	_collider(Vector3(S + 0.4, 3.2, 0.4), Vector3(0, 1.6, -S / 2 - 0.2))
	_collider(Vector3(0.4, 3.2, S), Vector3(-S / 2 - 0.2, 1.6, 0))
	_collider(Vector3(S, 3.2, 0.4), Vector3(0, 1.6, S / 2 + 0.2))
	_collider(Vector3(0.4, 3.2, S), Vector3(S / 2 + 0.2, 1.6, 0))
	_glow_box(Vector3(1.2, 1.0, 0.2), Palette.WINDOW, 0.5, Vector3(-1.5, 1.8, -S / 2 + 0.05))
	_box(Vector3(2.6, 0.04, 3.2), Palette.RUG, Vector3(0.4, 0.02, 0.4), Vector3.ZERO, false)
	# bed
	_box(Vector3(1.3, 0.5, 2.2), Palette.BED, Vector3(-2.9, 0.25, -2.4))
	_box(Vector3(1.0, 0.16, 0.5), Palette.PILLOW, Vector3(-2.9, 0.58, -3.2))
	_box(Vector3(1.3, 0.9, 0.1), Palette.DESK, Vector3(-2.9, 0.45, -3.55))
	_collider(Vector3(1.3, 1, 2.2), Vector3(-2.9, 0.5, -2.4))
	_interactable(Vector3(-1.8, 1, -2.4), Vector3(1.2, 2, 2.4), "Łóżko: sen albo przewinięcie dni", "bed")
	# desk with lamp, ledger and phone
	_box(Vector3(1.8, 0.08, 0.9), Palette.DESK, Vector3(2.3, 0.78, -3.2))
	for x in [1.5, 3.1]:
		_box(Vector3(0.08, 0.76, 0.8), Palette.DESK, Vector3(x, 0.38, -3.2))
	# papiery na biurku rosną z liczbą spraw w toku
	for k in range(1 + mini(Game.scheduled.size(), 4)):
		_box(Vector3(0.5, 0.03, 0.7), Palette.PAPER, Vector3(2.0 + k * 0.04, 0.83 + k * 0.03, -3.15 - k * 0.03), Vector3(0, 8 - k * 7, 0), false)
	_box(Vector3(0.14, 0.26, 0.05), Palette.PHONE, Vector3(2.9, 0.84, -3.0), Vector3(0, -20, 0), false)
	_cyl(0.05, 0.08, 0.5, Palette.LAMP_POST, Vector3(3.0, 1.05, -3.5), Vector3.ZERO, 6)
	_glow_box(Vector3(0.36, 0.18, 0.36), Palette.LAMP_LIGHT, 1.2, Vector3(3.0, 1.35, -3.5))
	_omni(Vector3(2.8, 1.6, -3.0), Color("ffc070"), 1.6, 6.0)
	_box(Vector3(0.6, 0.06, 0.6), Palette.DESK, Vector3(2.3, 0.5, -2.2))
	_box(Vector3(0.6, 0.6, 0.06), Palette.DESK, Vector3(2.3, 0.8, -2.5))
	_collider(Vector3(1.9, 1, 1.0), Vector3(2.3, 0.5, -3.2))
	_interactable(Vector3(2.3, 1, -1.9), Vector3(2.0, 2, 1.4), "Biurko: finanse parafii", "desk")
	# kitchen corner: table, chairs, stove
	_box(Vector3(1.4, 0.08, 1.0), Palette.DESK, Vector3(2.6, 0.76, 1.6))
	for x in [2.0, 3.2]:
		for z in [1.2, 2.0]:
			_box(Vector3(0.08, 0.74, 0.08), Palette.DESK, Vector3(x, 0.37, z))
	_box(Vector3(0.44, 0.5, 0.44), Palette.BENCH, Vector3(1.6, 0.25, 1.6))
	_box(Vector3(0.44, 0.5, 0.44), Palette.BENCH, Vector3(3.6, 0.25, 1.6))
	_box(Vector3(0.9, 0.9, 0.7), Palette.WALL_INT, Vector3(3.4, 0.45, 3.0))
	_glow_box(Vector3(0.5, 0.06, 0.4), Palette.LAMP_LIGHT, 0.8, Vector3(3.4, 0.92, 3.0))
	_box(Vector3(0.3, 0.16, 0.3), Palette.BUCKET, Vector3(3.3, 1.0, 3.0))
	_collider(Vector3(1.5, 1, 1.1), Vector3(2.6, 0.5, 1.6))
	_collider(Vector3(1.0, 1, 0.8), Vector3(3.4, 0.5, 3.0))
	_activity(Vector3(2.6, 1, 0.6), Vector3(2.0, 2, 1.2), "meal")
	# bookshelf on the west wall
	_box(Vector3(0.4, 2.2, 1.8), Palette.DESK, Vector3(-S / 2 + 0.25, 1.1, 1.6))
	var books := [Palette.BOOK_A, Palette.BOOK_B, Palette.BOOK_C]
	for row in range(3):
		for i in range(7):
			_box(Vector3(0.26, 0.34, 0.16), books[(row + i) % 3], Vector3(-S / 2 + 0.3, 0.45 + row * 0.62, 0.85 + i * 0.24), Vector3.ZERO, false)
	_collider(Vector3(0.5, 2.2, 1.8), Vector3(-S / 2 + 0.25, 1.1, 1.6))
	_interactable(Vector3(-S / 2 + 1.1, 1, 1.6), Vector3(1.2, 2, 2.0), "Telefon i kronika: wiadomości", "status")
	_omni(Vector3(0, 2.6, 0), Color("d8c8a0"), 1.0, 7.0)
	# door out (south)
	_box(Vector3(1.2, 2.2, 0.2), Palette.DOOR, Vector3(0, 1.1, S / 2 + 0.1))
	_door(Vector3(0, 1, S / 2 - 0.8), Vector3(2.0, 2, 1.2), "Wyjdź na zewnątrz", "outside", "rectory_door")
	_spawn("door", Vector3(0, 0, S / 2 - 2.0))
	_spawn("bed", Vector3(-1.6, 0, -2.4))
	_spot("bed_spot", Vector3(-2.9, 0, -1.35))
	_spot("sweep_a", Vector3(-1.0, 0, 1.0))
	_spot("sweep_b", Vector3(2.0, 0, -1.0))
