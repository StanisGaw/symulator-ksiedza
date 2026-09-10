class_name LocationBase
extends Node3D
## Shared helpers for placeholder locations built from primitives: meshes, colliders,
## spawn markers and interactables. Concrete locations extend this and build in _ready().


var landmarks: Dictionary = {}


## Miejsce, które kamera pokaże, gdy pojawi się tu coś nowego.
func _landmark(id: String, pos: Vector3) -> void:
	landmarks[id] = pos


func _mesh(mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	add_child(mi)
	return mi


func _box(size: Vector3, color: Color, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, outline: bool = true) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _mesh(m, ToonMaterial.make(color, Color.BLACK, 0.0, outline), pos, rot_deg)


func _glow_box(size: Vector3, color: Color, strength: float, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _mesh(m, ToonMaterial.make(color, color, strength, false), pos, rot_deg)


func _cyl(top: float, bottom: float, height: float, color: Color, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, segments: int = 10) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return _mesh(m, ToonMaterial.make(color), pos, rot_deg)


func _sphere(radius: float, color: Color, pos: Vector3, outline: bool = true) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 10
	m.rings = 6
	return _mesh(m, ToonMaterial.make(color, Color.BLACK, 0.0, outline), pos)


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


func _spawn(spawn_name: String, pos: Vector3) -> Marker3D:
	var m := Marker3D.new()
	m.name = "Spawn_" + spawn_name
	m.position = pos
	add_child(m)
	return m


func _interactable(pos: Vector3, size: Vector3, label: String, kind: String, params: Dictionary = {}) -> Interactable:
	var area := Interactable.new()
	area.label = label
	area.kind = kind
	area.params = params
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	area.position = pos
	add_child(area)
	return area


func _door(pos: Vector3, size: Vector3, label: String, location: String, spawn: String) -> Interactable:
	return _interactable(pos, size, label, "door", {"location": location, "spawn": spawn})


func _activity(pos: Vector3, size: Vector3, id: String) -> Interactable:
	var def: Dictionary = Game.ACTIVITIES[id]
	return _interactable(pos, size, def["label"], "activity", {"id": id})


func _omni(pos: Vector3, color: Color, energy: float, range_: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_
	add_child(l)
	return l


func _environment(bg: Color, ambient: Color, ambient_energy: float, fog_density: float = 0.0) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_energy
	if fog_density > 0.0:
		env.fog_enabled = true
		env.fog_light_color = bg
		env.fog_density = fog_density
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	return env
