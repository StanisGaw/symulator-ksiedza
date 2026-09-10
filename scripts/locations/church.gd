extends LocationBase
## Church interior. Dollhouse view: only the north and west walls are visible, the other two are invisible colliders.

const W := 10.0
const D := 16.0


func _ready() -> void:
	_environment(Color("0e0d12"), Color("6a6478"), 1.3)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(W, D)
	_mesh(floor_mesh, ToonMaterial.make(Palette.FLOOR_STONE, Color.BLACK, 0.0, false), Vector3.ZERO)
	_collider(Vector3(W, 1, D), Vector3(0, -0.5, 0))
	# visible walls (north, west) and invisible ones (south, east)
	_box(Vector3(W + 0.4, 6, 0.4), Palette.WALL_INT, Vector3(0, 3, -D / 2 - 0.2))
	_box(Vector3(0.4, 6, D), Palette.WALL_INT_DARK, Vector3(-W / 2 - 0.2, 3, 0))
	_collider(Vector3(W, 6, 0.4), Vector3(0, 3, D / 2 + 0.2))
	_collider(Vector3(0.4, 6, D), Vector3(W / 2 + 0.2, 3, 0))
	# windows on the west wall glow warm
	for z in [-5.0, -2.0, 1.0, 4.0]:
		_glow_box(Vector3(0.2, 1.6, 0.7), Palette.WINDOW, 0.7, Vector3(-W / 2 + 0.05, 3.2, z))
	# altar
	_box(Vector3(2.6, 1.0, 1.1), Palette.ALTAR_CLOTH, Vector3(0, 0.5, -6.3))
	_box(Vector3(3.6, 0.3, 2.4), Palette.FLOOR_WOOD, Vector3(0, 0.15, -6.0))
	_collider(Vector3(2.8, 1.2, 1.3), Vector3(0, 0.6, -6.3))
	for x in [-0.9, 0.9]:
		_cyl(0.05, 0.05, 0.5, Palette.CANDLE, Vector3(x, 1.25, -6.3), Vector3.ZERO, 6)
		_glow_box(Vector3(0.12, 0.12, 0.12), Palette.CANDLE, 2.5, Vector3(x, 1.55, -6.3))
	_box(Vector3(0.14, 1.6, 0.14), Palette.CROSS, Vector3(0, 3.4, -D / 2 + 0.25))
	_box(Vector3(0.9, 0.14, 0.14), Palette.CROSS, Vector3(0, 3.9, -D / 2 + 0.25))
	_omni(Vector3(0, 2.5, -5.5), Color("ffb060"), 2.2, 9.0)
	_omni(Vector3(0, 3.0, 2.0), Color("d8c8a0"), 1.2, 10.0)
	_activity(Vector3(0, 1, -5.0), Vector3(3.2, 2, 1.4), "mass")
	# pews
	for row in range(6):
		var z := -3.0 + row * 1.4
		for x in [-2.6, 2.6]:
			_box(Vector3(3.4, 0.45, 0.4), Palette.PEW, Vector3(x, 0.45, z))
			_box(Vector3(3.4, 0.5, 0.08), Palette.PEW, Vector3(x, 0.9, z - 0.18))
			_box(Vector3(0.08, 0.45, 0.4), Palette.PEW, Vector3(x - 1.66, 0.22, z))
			_box(Vector3(0.08, 0.45, 0.4), Palette.PEW, Vector3(x + 1.66, 0.22, z))
			_collider(Vector3(3.4, 1, 0.5), Vector3(x, 0.5, z))
	# confessional by the west wall
	_box(Vector3(1.4, 2.4, 1.2), Palette.CONFESSIONAL, Vector3(-4.1, 1.2, 5.2))
	_box(Vector3(0.5, 1.6, 0.05), Palette.WALL_INT, Vector3(-3.38, 1.1, 5.2))
	_collider(Vector3(1.4, 2.4, 1.2), Vector3(-4.1, 1.2, 5.2))
	_activity(Vector3(-2.9, 1, 5.2), Vector3(1.4, 2, 1.6), "confession")
	# bucket and broom by the door
	_cyl(0.28, 0.22, 0.4, Palette.BUCKET, Vector3(3.6, 0.2, 6.8), Vector3.ZERO, 8)
	_cyl(0.03, 0.03, 1.4, Palette.TRUNK, Vector3(4.0, 0.7, 6.6), Vector3(0, 0, -12), 5)
	_activity(Vector3(3.6, 1, 6.6), Vector3(1.6, 2, 1.4), "clean_church")
	# door out
	_box(Vector3(1.6, 2.4, 0.2), Palette.DOOR, Vector3(0, 1.2, D / 2 + 0.1))
	_door(Vector3(0, 1, D / 2 - 0.9), Vector3(2.4, 2, 1.4), "Wyjdź na zewnątrz", "outside", "church_door")
	_spawn("door", Vector3(0, 0, D / 2 - 2.2))
