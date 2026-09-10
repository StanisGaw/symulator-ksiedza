extends LocationBase
## The parish grounds: church, rectory, parking, graveyard. Built from primitives.


func _ready() -> void:
	var env := _environment(Color("3a4452"), Color("8c98aa"), 2.4, 0.012)
	_build_ground()
	_build_church()
	_build_rectory()
	_build_parking_and_car()
	var lamp := _build_street_furniture()
	_build_graveyard()
	_build_tree(Vector3(-7.5, 0, 4))
	_build_tree(Vector3(15, 0, -12))
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.set_script(load("res://scripts/day_night.gd"))
	add_child(sun)
	sun.env = env
	sun.lamps.append(lamp)
	_spawn("start", Vector3(2.6, 0, 5))
	_spawn("church_door", Vector3(1, 0, 1.9))
	_spawn("rectory_door", Vector3(11, 0, -2.6))
	_spawn("car", Vector3(7.2, 0, 5.8))


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(70, 70)
	_mesh(plane, ToonMaterial.make(Palette.GRASS, Color.BLACK, 0.0, false), Vector3.ZERO)
	_collider(Vector3(70, 1, 70), Vector3(0, -0.5, 0))
	_box(Vector3(3.2, 0.06, 12), Palette.PATH, Vector3(0, 0.03, 6), Vector3.ZERO, false)
	_box(Vector3(2.0, 0.06, 6), Palette.PATH, Vector3(7, 0.03, -3), Vector3(0, -35, 0), false)
	_box(Vector3(8, 0.06, 6), Palette.PARKING, Vector3(9, 0.03, 3), Vector3.ZERO, false)
	for k in range(-1, 2):
		_box(Vector3(0.1, 0.07, 5), Palette.LINE, Vector3(9 + k * 2.4, 0.04, 3), Vector3.ZERO, false)
	for i in range(18):
		var x := -9.0 + float((i * 37) % 23)
		var z := 5.0 + float((i * 53) % 7)
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.15
		cone.height = 0.5
		cone.radial_segments = 4
		_mesh(cone, ToonMaterial.make(Color("5a5a3a"), Color.BLACK, 0.0, false), Vector3(x, 0.25, z))


func _build_church() -> void:
	_box(Vector3(6, 4, 9), Palette.WALL, Vector3(1, 2, -4.5))
	_collider(Vector3(6, 4, 9), Vector3(1, 2, -4.5))
	var roof := PrismMesh.new()
	roof.size = Vector3(6.6, 2.6, 9.6)
	_mesh(roof, ToonMaterial.make(Palette.ROOF), Vector3(1, 5.3, -4.5))
	_box(Vector3(2.4, 7, 2.4), Palette.WALL_DARK, Vector3(-3.2, 3.5, -0.5))
	_collider(Vector3(2.4, 7, 2.4), Vector3(-3.2, 3.5, -0.5))
	var spire := CylinderMesh.new()
	spire.top_radius = 0.0
	spire.bottom_radius = 1.9
	spire.height = 2.4
	spire.radial_segments = 4
	_mesh(spire, ToonMaterial.make(Palette.ROOF), Vector3(-3.2, 8.2, -0.5), Vector3(0, 45, 0))
	_box(Vector3(0.14, 1.2, 0.14), Palette.CROSS, Vector3(-3.2, 10, -0.5))
	_box(Vector3(0.7, 0.14, 0.14), Palette.CROSS, Vector3(-3.2, 10.3, -0.5))
	_box(Vector3(1.4, 2.2, 0.16), Palette.DOOR, Vector3(1, 1.1, 0.02))
	_glow_box(Vector3(1.4, 1.4, 0.16), Palette.WINDOW, 0.9, Vector3(1, 3.1, 0.02))
	for wz in [-7.5, -5.5, -3.5, -1.5]:
		_glow_box(Vector3(0.16, 1.4, 0.6), Palette.WINDOW, 0.9, Vector3(4.02, 2.4, wz))
		_glow_box(Vector3(0.16, 1.4, 0.6), Palette.WINDOW, 0.9, Vector3(-2.02, 2.4, wz))
	_glow_box(Vector3(0.16, 0.9, 0.5), Palette.WINDOW, 0.9, Vector3(-1.98, 4.8, -0.5))
	_omni(Vector3(1, 3, 1.5), Color("ffa550"), 2.5, 7.0)
	for i in range(3):
		_sphere(0.14, Palette.CROW, Vector3(-0.5 + i * 1.6, 6.75, -4.5))
		_sphere(0.09, Palette.CROW, Vector3(-0.35 + i * 1.6, 6.9, -4.5))
	_door(Vector3(1, 1, 1.2), Vector3(2.4, 2, 1.6), "Wejdź do kościoła", "church", "door")
	# gutter to repair by the tower, broom by the path, notice board
	_cyl(0.06, 0.06, 3.6, Palette.LAMP_POST, Vector3(-1.85, 2.0, 0.9), Vector3.ZERO, 6)
	_activity(Vector3(-1.85, 1, 1.6), Vector3(1.6, 2, 1.6), "repair_gutter")
	_cyl(0.03, 0.03, 1.4, Palette.TRUNK, Vector3(2.1, 0.7, 2.4), Vector3(0, 0, 12), 5)
	_box(Vector3(0.18, 0.35, 0.18), Color("8a7a4a"), Vector3(2.25, 0.18, 2.4))
	_activity(Vector3(2.2, 1, 2.6), Vector3(1.4, 2, 1.4), "sweep")


func _build_rectory() -> void:
	var rx := 11.0
	var rz := -7.0
	_box(Vector3(5, 3.2, 5), Palette.RECTORY_WALL, Vector3(rx, 1.6, rz))
	_collider(Vector3(5, 3.2, 5), Vector3(rx, 1.6, rz))
	var roof := PrismMesh.new()
	roof.size = Vector3(5.6, 1.8, 5.6)
	_mesh(roof, ToonMaterial.make(Palette.ROOF), Vector3(rx, 4.1, rz))
	_box(Vector3(1.0, 2.0, 0.16), Palette.DOOR, Vector3(rx, 1.0, rz + 2.52))
	_glow_box(Vector3(0.9, 0.9, 0.16), Palette.WINDOW, 0.7, Vector3(rx - 1.6, 1.7, rz + 2.52))
	_glow_box(Vector3(0.16, 0.9, 0.9), Palette.WINDOW, 0.7, Vector3(rx + 2.52, 1.7, rz + 0.5))
	_box(Vector3(0.5, 1.0, 0.5), Palette.WALL_DARK, Vector3(rx + 1.5, 4.9, rz - 1.5))
	_door(Vector3(rx, 1, rz + 3.3), Vector3(2.0, 2, 1.4), "Wejdź na plebanię", "rectory", "door")


func _build_parking_and_car() -> void:
	var cx := 9.0
	var cz := 3.2
	_box(Vector3(4, 0.75, 1.9), Palette.CAR, Vector3(cx, 0.65, cz))
	_box(Vector3(2.2, 0.7, 1.7), Palette.CAR_DARK, Vector3(cx - 0.2, 1.37, cz))
	_box(Vector3(2.0, 0.5, 1.74), Palette.GLASS, Vector3(cx - 0.2, 1.42, cz), Vector3.ZERO, false)
	for off in [Vector2(-1.3, -0.95), Vector2(1.3, -0.95), Vector2(-1.3, 0.95), Vector2(1.3, 0.95)]:
		_cyl(0.36, 0.36, 0.3, Palette.WHEEL, Vector3(cx + off.x, 0.36, cz + off.y), Vector3(90, 0, 0), 12)
	_collider(Vector3(4.2, 2, 2.2), Vector3(cx, 1, cz))
	_activity(Vector3(cx, 1, cz + 1.9), Vector3(4.4, 2, 1.6), "visit_sick")


func _build_street_furniture() -> OmniLight3D:
	_cyl(0.08, 0.1, 4.2, Palette.LAMP_POST, Vector3(5.4, 2.1, 7), Vector3.ZERO, 8)
	_box(Vector3(0.9, 0.22, 0.4), Palette.LAMP_POST, Vector3(5.1, 4.25, 7))
	_glow_box(Vector3(0.7, 0.08, 0.3), Palette.LAMP_LIGHT, 1.5, Vector3(5.1, 4.1, 7))
	_collider(Vector3(0.3, 4, 0.3), Vector3(5.4, 2, 7))
	var lamp := _omni(Vector3(5.1, 3.9, 7), Palette.LAMP_LIGHT, 0.0, 10.0)
	lamp.name = "LampLight"
	_box(Vector3(1.8, 0.1, 0.5), Palette.BENCH, Vector3(-3.4, 0.5, 5.5))
	_box(Vector3(1.8, 0.5, 0.08), Palette.BENCH, Vector3(-3.4, 0.85, 5.25))
	_box(Vector3(0.1, 0.5, 0.45), Palette.BENCH_LEG, Vector3(-4.2, 0.25, 5.5))
	_box(Vector3(0.1, 0.5, 0.45), Palette.BENCH_LEG, Vector3(-2.6, 0.25, 5.5))
	_collider(Vector3(1.9, 1, 0.6), Vector3(-3.4, 0.5, 5.4))
	_box(Vector3(0.08, 1.2, 1.8), Palette.BOARD_FRAME, Vector3(-1.6, 1.4, 2.6))
	_box(Vector3(0.04, 1.0, 1.6), Palette.BOARD_FACE, Vector3(-1.54, 1.4, 2.6), Vector3.ZERO, false)
	_cyl(0.05, 0.05, 0.9, Palette.BOARD_FRAME, Vector3(-1.6, 0.45, 2.0), Vector3.ZERO, 6)
	_cyl(0.05, 0.05, 0.9, Palette.BOARD_FRAME, Vector3(-1.6, 0.45, 3.2), Vector3.ZERO, 6)
	_collider(Vector3(0.3, 2, 1.9), Vector3(-1.6, 1, 2.6))
	_interactable(Vector3(-0.9, 1, 2.6), Vector3(1.2, 2, 2.2), "Gablota: stan parafii", "status")
	return lamp


func _build_graveyard() -> void:
	for g in range(6):
		var gx := -6.5 + float(g % 3) * 1.4
		var gz := -6.0 + float(g / 3) * 1.8
		var tilt := 8.0 if g % 2 == 1 else -6.0
		_box(Vector3(0.5, 0.9 + float(g % 2) * 0.25, 0.14), Palette.STONE, Vector3(gx, 0.45, gz), Vector3(0, tilt, 0))
		if g % 3 == 1:
			_box(Vector3(0.4, 0.08, 0.14), Palette.STONE, Vector3(gx, 0.8, gz))
	_box(Vector3(0.12, 1.1, 5), Palette.WALL_DARK, Vector3(-7.6, 0.55, -5))
	_collider(Vector3(0.3, 1.2, 5), Vector3(-7.6, 0.55, -5))


func _build_tree(pos: Vector3) -> void:
	_cyl(0.18, 0.26, 1.6, Palette.TRUNK, pos + Vector3(0, 0.8, 0), Vector3.ZERO, 7)
	_collider(Vector3(0.5, 2, 0.5), pos + Vector3(0, 1, 0))
	_sphere(1.5, Palette.CANOPY, pos + Vector3(0, 2.5, 0))
	_sphere(1.1, Palette.CANOPY_2, pos + Vector3(0.3, 3.6, 0.2))
