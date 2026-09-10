extends Node3D
## Builds the placeholder parish out of primitive meshes. Every piece here is meant to be
## replaced by real low-poly models later; positions and sizes are the design reference.


func _ready() -> void:
	_build_ground()
	_build_church()
	_build_parking_and_car()
	_build_street_furniture()
	_build_graveyard()
	_build_tree(Vector3(-7.5, 0, 4))


# ---------- helpers ----------

func _mesh(mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _box(size: Vector3, color: Color, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, outline: bool = true, parent: Node = self) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _mesh(m, ToonMaterial.make(color, Color.BLACK, 0.0, outline), pos, rot_deg, parent)


func _cyl(top: float, bottom: float, height: float, color: Color, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, segments: int = 10, parent: Node = self) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return _mesh(m, ToonMaterial.make(color), pos, rot_deg, parent)


func _sphere(radius: float, color: Color, pos: Vector3, parent: Node = self) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 10
	m.rings = 6
	return _mesh(m, ToonMaterial.make(color), pos, Vector3.ZERO, parent)


func _emissive_box(size: Vector3, color: Color, strength: float, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _mesh(m, ToonMaterial.make(color, color, strength, false), pos, rot_deg)


func _collider(size: Vector3, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = pos
	body.rotation_degrees = rot_deg
	add_child(body)
	return body


# ---------- pieces ----------

func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	_mesh(plane, ToonMaterial.make(Palette.GRASS, Color.BLACK, 0.0, false), Vector3.ZERO)
	_collider(Vector3(60, 1, 60), Vector3(0, -0.5, 0))
	# path to the church door and the parking lot
	_box(Vector3(3.2, 0.06, 12), Palette.PATH, Vector3(0, 0.03, 6), Vector3.ZERO, false)
	_box(Vector3(8, 0.06, 6), Palette.PARKING, Vector3(9, 0.03, 3), Vector3.ZERO, false)
	for k in range(-1, 2):
		_box(Vector3(0.1, 0.07, 5), Palette.LINE, Vector3(9 + k * 2.4, 0.04, 3), Vector3.ZERO, false)
	# dead grass tufts
	for i in range(14):
		var x := -9.0 + float((i * 37) % 19)
		var z := 5.0 + float((i * 53) % 5)
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.15
		cone.height = 0.5
		cone.radial_segments = 4
		_mesh(cone, ToonMaterial.make(Color("5a5a3a"), Color.BLACK, 0.0, false), Vector3(x, 0.25, z))


func _build_church() -> void:
	# nave
	_box(Vector3(6, 4, 9), Palette.WALL, Vector3(1, 2, -4.5))
	_collider(Vector3(6, 4, 9), Vector3(1, 2, -4.5))
	var roof := PrismMesh.new()
	roof.size = Vector3(6.6, 2.6, 9.6)
	_mesh(roof, ToonMaterial.make(Palette.ROOF), Vector3(1, 5.3, -4.5))
	# tower
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
	# door and windows (warm, lit from inside)
	_box(Vector3(1.4, 2.2, 0.16), Palette.DOOR, Vector3(1, 1.1, 0.02))
	_emissive_box(Vector3(1.4, 1.4, 0.16), Palette.WINDOW, 0.9, Vector3(1, 3.1, 0.02))
	for wz in [-7.5, -5.5, -3.5, -1.5]:
		_emissive_box(Vector3(0.16, 1.4, 0.6), Palette.WINDOW, 0.9, Vector3(4.02, 2.4, wz))
		_emissive_box(Vector3(0.16, 1.4, 0.6), Palette.WINDOW, 0.9, Vector3(-2.02, 2.4, wz))
	_emissive_box(Vector3(0.16, 0.9, 0.5), Palette.WINDOW, 0.9, Vector3(-1.98, 4.8, -0.5))
	var door_light := OmniLight3D.new()
	door_light.light_color = Color("ffa550")
	door_light.light_energy = 2.5
	door_light.omni_range = 7.0
	door_light.position = Vector3(1, 3, 1.5)
	door_light.name = "DoorLight"
	add_child(door_light)
	# crows on the ridge
	for i in range(3):
		_sphere(0.14, Palette.CROW, Vector3(-0.5 + i * 1.6, 6.75, -4.5))
		_sphere(0.09, Palette.CROW, Vector3(-0.35 + i * 1.6, 6.9, -4.5))


func _build_parking_and_car() -> void:
	var cx := 9.0
	var cz := 3.2
	_box(Vector3(4, 0.75, 1.9), Palette.CAR, Vector3(cx, 0.65, cz))
	_box(Vector3(2.2, 0.7, 1.7), Palette.CAR_DARK, Vector3(cx - 0.2, 1.37, cz))
	_box(Vector3(2.0, 0.5, 1.74), Palette.GLASS, Vector3(cx - 0.2, 1.42, cz), Vector3.ZERO, false)
	for off in [Vector2(-1.3, -0.95), Vector2(1.3, -0.95), Vector2(-1.3, 0.95), Vector2(1.3, 0.95)]:
		_cyl(0.36, 0.36, 0.3, Palette.WHEEL, Vector3(cx + off.x, 0.36, cz + off.y), Vector3(90, 0, 0), 12)
	_collider(Vector3(4.2, 2, 2.2), Vector3(cx, 1, cz))


func _build_street_furniture() -> void:
	# lamp post with a light that the day cycle switches on at dusk
	_cyl(0.08, 0.1, 4.2, Palette.LAMP_POST, Vector3(5.4, 2.1, 7), Vector3.ZERO, 8)
	_box(Vector3(0.9, 0.22, 0.4), Palette.LAMP_POST, Vector3(5.1, 4.25, 7))
	_emissive_box(Vector3(0.7, 0.08, 0.3), Palette.LAMP_LIGHT, 1.5, Vector3(5.1, 4.1, 7))
	_collider(Vector3(0.3, 4, 0.3), Vector3(5.4, 2, 7))
	var lamp := OmniLight3D.new()
	lamp.name = "LampLight"
	lamp.light_color = Palette.LAMP_LIGHT
	lamp.light_energy = 0.0
	lamp.omni_range = 10.0
	lamp.position = Vector3(5.1, 3.9, 7)
	add_child(lamp)
	# bench
	_box(Vector3(1.8, 0.1, 0.5), Palette.BENCH, Vector3(-3.4, 0.5, 5.5))
	_box(Vector3(1.8, 0.5, 0.08), Palette.BENCH, Vector3(-3.4, 0.85, 5.25))
	_box(Vector3(0.1, 0.5, 0.45), Palette.BENCH_LEG, Vector3(-4.2, 0.25, 5.5))
	_box(Vector3(0.1, 0.5, 0.45), Palette.BENCH_LEG, Vector3(-2.6, 0.25, 5.5))
	_collider(Vector3(1.9, 1, 0.6), Vector3(-3.4, 0.5, 5.4))
	# parish notice board
	_box(Vector3(0.08, 1.2, 1.8), Palette.BOARD_FRAME, Vector3(-1.6, 1.4, 2.6))
	_box(Vector3(0.04, 1.0, 1.6), Palette.BOARD_FACE, Vector3(-1.54, 1.4, 2.6), Vector3.ZERO, false)
	_cyl(0.05, 0.05, 0.9, Palette.BOARD_FRAME, Vector3(-1.6, 0.45, 2.0), Vector3.ZERO, 6)
	_cyl(0.05, 0.05, 0.9, Palette.BOARD_FRAME, Vector3(-1.6, 0.45, 3.2), Vector3.ZERO, 6)
	_collider(Vector3(0.3, 2, 1.9), Vector3(-1.6, 1, 2.6))


func _build_graveyard() -> void:
	for g in range(6):
		var gx := -6.5 + float(g % 3) * 1.4
		var gz := -6.0 + float(g / 3) * 1.8
		var tilt := 0.15 if g % 2 == 1 else -0.1
		_box(Vector3(0.5, 0.9 + float(g % 2) * 0.25, 0.14), Palette.STONE, Vector3(gx, 0.45, gz), Vector3(0, rad_to_deg(tilt), 0))
		if g % 3 == 1:
			_box(Vector3(0.4, 0.08, 0.14), Palette.STONE, Vector3(gx, 0.8, gz))
	_box(Vector3(0.12, 1.1, 5), Palette.WALL_DARK, Vector3(-7.6, 0.55, -5))
	_collider(Vector3(0.3, 1.2, 5), Vector3(-7.6, 0.55, -5))


func _build_tree(pos: Vector3) -> void:
	_cyl(0.18, 0.26, 1.6, Palette.TRUNK, pos + Vector3(0, 0.8, 0), Vector3.ZERO, 7)
	_collider(Vector3(0.5, 2, 0.5), pos + Vector3(0, 1, 0))
	_sphere(1.5, Palette.CANOPY, pos + Vector3(0, 2.5, 0))
	_sphere(1.1, Palette.CANOPY_2, pos + Vector3(0.3, 3.6, 0.2))
