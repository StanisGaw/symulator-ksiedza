class_name MassDirector
extends Node3D
## Plays the mass as a fast cutscene inside the church: parishioners walk in and sit in the pews,
## come up for communion one after another, then leave. Reports progress to Game so the clock
## advances with the scene. Can be skipped from the UI.

const WALK_SPEED := 7.0
const DOOR_OUT := Vector3(0, 0, 10.5)
const DOOR_IN := Vector3(0, 0, 7.4)
const COMMUNION := Vector3(0, 0, -4.3)
const COATS := [Color("3a3a44"), Color("4a3a30"), Color("2f3a4a"), Color("5a5048"), Color("3a2e3a"), Color("4a4a3a"), Color("6a5a4a")]
const HAIRS := [Color("2e1c14"), Color("6a6a6a"), Color("1a1a1a"), Color("8a7a5a"), Color("b0a090")]
const SKINS := [Color("c9a58a"), Color("d9b8a0"), Color("b89478")]

var active := false
var phase := 0
var phase_time := 0.0
var people: Array = []
var seats: Array = []
var comm_next := 0
var comm_timer := 0.0


func _ready() -> void:
	add_to_group("mass_director")
	Game.cutscene_skip.connect(_skip)
	for row in range(6):
		var z := -3.0 + row * 1.4
		for side in [-2.6, 2.6]:
			for k in range(4):
				seats.append(Vector3(side + (k - 1.5) * 0.8, 0, z + 0.1))


func start(attendance: int) -> void:
	active = true
	phase = 0
	phase_time = 0.0
	comm_next = 0
	comm_timer = 0.0
	var count := clampi(attendance / 8, 6, seats.size())
	var order := range(seats.size())
	order.shuffle()
	for i in range(count):
		var seat: Vector3 = seats[order[i]]
		var node := _make_person(i)
		node.position = DOOR_OUT + Vector3(randf_range(-1.2, 1.2), 0, i * 0.5)
		add_child(node)
		people.append({
			"node": node, "seat": seat, "state": "wait", "delay": i * 0.18, "wait": 0.0,
			"path": [DOOR_IN, Vector3(0, 0, seat.z + 0.75), seat], "seated": false, "communed": false,
		})
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		player.global_position = global_position + Vector3(0, 1.1, -5.0)
		if player.has_method("face"):
			player.face(Vector3(0, 0, 1))


func _make_person(i: int) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.28
	cyl.bottom_radius = 0.36
	cyl.height = 1.3
	cyl.radial_segments = 8
	cyl.rings = 1
	body.mesh = cyl
	body.material_override = ToonMaterial.make(COATS[i % COATS.size()])
	body.position = Vector3(0, 0.65, 0)
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.24
	sph.height = 0.48
	sph.radial_segments = 8
	sph.rings = 5
	head.mesh = sph
	head.material_override = ToonMaterial.make(SKINS[i % SKINS.size()])
	head.position = Vector3(0, 1.55, 0)
	root.add_child(head)
	var hair := MeshInstance3D.new()
	hair.mesh = sph
	hair.material_override = ToonMaterial.make(HAIRS[i % HAIRS.size()])
	hair.position = Vector3(0, 1.62, 0)
	hair.scale = Vector3(1.05, 0.55, 1.05)
	root.add_child(hair)
	return root


func _process(delta: float) -> void:
	if not active:
		return
	phase_time += delta
	match phase:
		0: _phase_enter(delta)
		1: _phase_liturgy()
		2: _phase_communion(delta)
		3: _phase_leave(delta)


func _phase_enter(delta: float) -> void:
	var seated := 0
	for p in people:
		if p["state"] == "wait":
			p["delay"] -= delta
			if p["delay"] <= 0.0:
				p["state"] = "walk"
		elif p["state"] == "walk":
			if _step(p, delta):
				_sit(p, true)
				p["state"] = "seated"
		if p["state"] == "seated":
			seated += 1
	Game.cutscene_progress(0.35 * float(seated) / float(people.size()))
	if seated == people.size():
		_next_phase()


func _phase_liturgy() -> void:
	Game.cutscene_progress(0.35 + 0.15 * clampf(phase_time / 2.5, 0.0, 1.0))
	if phase_time >= 2.5:
		_next_phase()


func _phase_communion(delta: float) -> void:
	comm_timer -= delta
	if comm_next < people.size() and comm_timer <= 0.0:
		var p: Dictionary = people[comm_next]
		var seat: Vector3 = p["seat"]
		_sit(p, false)
		p["path"] = [Vector3(0, 0, seat.z + 0.75), COMMUNION + Vector3(randf_range(-0.3, 0.3), 0, 0)]
		p["state"] = "to_altar"
		comm_next += 1
		comm_timer = 0.3
	var done := 0
	for p in people:
		match p["state"]:
			"to_altar":
				if _step(p, delta):
					p["state"] = "receive"
					p["wait"] = 0.35
			"receive":
				p["wait"] -= delta
				if p["wait"] <= 0.0:
					var seat: Vector3 = p["seat"]
					p["path"] = [Vector3(0, 0, seat.z + 0.75), seat]
					p["state"] = "back"
			"back":
				if _step(p, delta):
					_sit(p, true)
					p["state"] = "seated"
					p["communed"] = true
		if p["communed"] and p["state"] == "seated":
			done += 1
	Game.cutscene_progress(0.5 + 0.35 * float(done) / float(people.size()))
	if done == people.size():
		for i in people.size():
			people[i]["delay"] = i * 0.12
			people[i]["state"] = "wait"
		_next_phase()


func _phase_leave(delta: float) -> void:
	var gone := 0
	for p in people:
		match p["state"]:
			"wait":
				p["delay"] -= delta
				if p["delay"] <= 0.0:
					_sit(p, false)
					var seat: Vector3 = p["seat"]
					p["path"] = [Vector3(0, 0, seat.z + 0.75), DOOR_IN, DOOR_OUT]
					p["state"] = "walk"
			"walk":
				if _step(p, delta):
					p["state"] = "gone"
					p["node"].visible = false
		if p["state"] == "gone":
			gone += 1
	Game.cutscene_progress(0.85 + 0.15 * float(gone) / float(people.size()))
	if gone == people.size():
		_finish()


func _step(p: Dictionary, delta: float) -> bool:
	var node: Node3D = p["node"]
	var path: Array = p["path"]
	if path.is_empty():
		return true
	var target: Vector3 = path[0]
	var to := target - node.position
	to.y = 0.0
	var dist := to.length()
	var move := WALK_SPEED * delta
	if dist <= move:
		node.position = Vector3(target.x, node.position.y, target.z)
		path.pop_front()
		return path.is_empty()
	node.position += to / dist * move
	node.rotation.y = atan2(to.x, to.z)
	return false


func _sit(p: Dictionary, seated: bool) -> void:
	var node: Node3D = p["node"]
	node.scale = Vector3(1, 0.72, 1) if seated else Vector3.ONE
	if seated:
		node.rotation.y = 0.0


func _next_phase() -> void:
	phase += 1
	phase_time = 0.0


func _skip() -> void:
	if active:
		_finish()


func _finish() -> void:
	active = false
	for p in people:
		p["node"].queue_free()
	people.clear()
	Game.finish_cutscene()
