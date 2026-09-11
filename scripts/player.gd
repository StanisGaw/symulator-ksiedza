extends CharacterBody3D
## The priest. Movement is relative to the fixed camera. A sensor area finds nearby interactables.

@export var speed: float = 4.0
@export var camera_yaw_degrees: float = 35.0

var _model: Node3D
var _nearby: Array[Interactable] = []
var _current: Interactable


func _ready() -> void:
	add_to_group("player")
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	_build_model()
	var sensor := $Sensor as Area3D
	sensor.area_entered.connect(_on_area_entered)
	sensor.area_exited.connect(_on_area_exited)


func face(dir: Vector3) -> void:
	_model.rotation.y = atan2(dir.x, dir.z)


## Obrót modelu wokół pionu, do animacji scen.
func model_yaw() -> float:
	return _model.rotation.y


func set_model_yaw(value: float) -> void:
	_model.rotation.y = value


## Rekwizyt w rękach na czas sceny: miotła, brewiarz. Trzymany przez model,
## więc obraca się razem z księdzem.
func hold(prop: Node3D) -> void:
	drop_props()
	prop.add_to_group("player_prop")
	_model.add_child(prop)


func drop_props() -> void:
	for node in _model.get_children():
		if node.is_in_group("player_prop"):
			node.queue_free()


## Pozy do scen: klęczenie, siedzenie, praca w pochyleniu, leżenie.
func set_pose(pose: String) -> void:
	_model.position.y = 0.0
	match pose:
		"kneel":
			_model.scale = Vector3(1, 0.78, 1)
			_model.rotation.x = deg_to_rad(16)
		"sit":
			_model.scale = Vector3(1, 0.72, 1)
			_model.rotation.x = deg_to_rad(6)
			_model.position.y = -0.3
		"work":
			# pochylony nad miotłą
			_model.scale = Vector3(1, 0.94, 1)
			_model.rotation.x = deg_to_rad(24)
		"lie":
			# obrót o prosty kąt kładzie ciało wzdłuż łóżka, głową w stronę poduszki
			_model.scale = Vector3(1, 0.95, 1)
			_model.rotation = Vector3(deg_to_rad(-90), 0, 0)
		_:
			_model.scale = Vector3.ONE
			_model.rotation.x = 0.0


## Walking bob for cutscenes (the model has no legs yet).
func bob(t: float) -> void:
	_model.position.y = absf(sin(t * 9.0)) * 0.08


func clear_targets() -> void:
	_nearby.clear()
	_current = null


func _physics_process(delta: float) -> void:
	if Game.cutscene:
		velocity = Vector3.ZERO
		return
	var input := Vector2.ZERO
	if not Game.modal_open:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, deg_to_rad(camera_yaw_degrees))
	if dir.length() > 0.0:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(dir.x, dir.z), 12.0 * delta)
		Game.energy = maxf(0.0, Game.energy - 0.4 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_update_target()
	if _current and not Game.modal_open and not Game.cutscene and Input.is_action_just_pressed("interact"):
		_current.activate()


func _on_area_entered(area: Area3D) -> void:
	if area is Interactable:
		_nearby.append(area)


func _on_area_exited(area: Area3D) -> void:
	if area is Interactable:
		_nearby.erase(area)


func _update_target() -> void:
	var best: Interactable = null
	var best_d := INF
	for a in _nearby:
		if not is_instance_valid(a):
			continue
		var d := global_position.distance_to(a.global_position)
		if d < best_d:
			best_d = d
			best = a
	if best != _current:
		_current = best
		Game.set_prompt(best.prompt_text() if best else "")
	elif best:
		Game.set_prompt(best.prompt_text())


# Placeholder priest built from primitives; origin at the feet after the -1.1 offset.
func _build_model() -> void:
	var root := Node3D.new()
	root.position = Vector3(0, -1.1, 0)
	_model.add_child(root)
	_part(root, _cyl(0.34, 0.52, 1.5), Palette.CASSOCK, Vector3(0, 0.75, 0))
	_part(root, _cyl(0.3, 0.34, 0.55), Palette.CASSOCK, Vector3(0, 1.77, 0))
	_part(root, _cyl(0.2, 0.2, 0.12), Palette.COLLAR, Vector3(0, 2.09, 0))
	_part(root, _cyl(0.12, 0.12, 0.14, 8), Palette.SKIN, Vector3(0, 2.2, 0))
	_part(root, _sphere(0.29), Palette.SKIN, Vector3(0, 2.5, 0))
	var hair := _part(root, _sphere(0.31), Palette.HAIR, Vector3(0, 2.58, 0))
	hair.scale = Vector3(1, 0.55, 1)
	_part(root, _cyl(0.09, 0.09, 0.75, 8), Palette.CASSOCK, Vector3(-0.42, 1.65, 0), Vector3(0, 0, 10))
	_part(root, _cyl(0.09, 0.09, 0.7, 8), Palette.CASSOCK, Vector3(0.4, 1.72, 0.12), Vector3(-52, 0, -29))
	_part(root, _sphere(0.1), Palette.SKIN, Vector3(-0.49, 1.27, 0))
	_part(root, _sphere(0.1), Palette.SKIN, Vector3(0.36, 1.9, 0.42))
	var phone := BoxMesh.new()
	phone.size = Vector3(0.14, 0.26, 0.03)
	var p := _part(root, phone, Palette.PHONE, Vector3(0.36, 2.02, 0.5), Vector3(-17, 0, 0))
	p.material_override = ToonMaterial.make(Palette.PHONE, Palette.PHONE, 0.9)
	var shoe := BoxMesh.new()
	shoe.size = Vector3(0.22, 0.1, 0.34)
	_part(root, shoe, Palette.SHOES, Vector3(-0.16, 0.05, 0.05))
	_part(root, shoe, Palette.SHOES, Vector3(0.16, 0.05, 0.05))


func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMaterial.make(color)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _cyl(top: float, bottom: float, height: float, segments: int = 10) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return m


func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 10
	m.rings = 6
	return m
