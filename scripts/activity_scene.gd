class_name ActivityScene
extends Node3D
## Krótkie sceny czynności: zamiatanie, sprzątanie, spowiedź, czytanie brewiarza i sen.
## Jeden reżyser na lokację. Miejsca akcji podaje lokacja przez _spot(), więc ta sama
## scena wygląda inaczej na placu i w kościele. Każdą można pominąć.

const WALK_SPEED := 3.2
const SWEEP_SPEED := 5.5
const SWEEP_ARC := 0.55

var active := false
var kind := ""
var elapsed := 0.0
var length := 4.0
var people: Array = []
var _base_yaw := 0.0
var _player: Node3D
var _spots: Dictionary = {}
var _rig: Node3D
var _return_pos := Vector3.ZERO
var _zoom_before := 14.0


func _ready() -> void:
	add_to_group("activity_scene")
	Game.cutscene_skip.connect(_skip)


func start(def: Dictionary) -> void:
	var scene: Dictionary = def.get("scene", {})
	kind = str(scene.get("kind", ""))
	length = float(scene.get("seconds", 4.0))
	elapsed = 0.0
	people.clear()
	_player = get_tree().get_first_node_in_group("player") as Node3D
	# po scenie ksiądz wraca tam, gdzie stał, żeby nie wylądować w ławkach
	_return_pos = _player.global_position
	var parent := get_parent() as LocationBase
	_spots = parent.spots if parent else {}
	# scena zasługuje na bliższy kadr
	_rig = get_tree().get_first_node_in_group("camera_rig") as Node3D
	if _rig:
		_zoom_before = _rig.zoom_goal()
		_rig.set_zoom(float(scene.get("zoom", 10.0)))
	match kind:
		"sweep":
			_start_sweep()
		"confession":
			_start_confession()
		"read":
			_start_seated("bench_seat", Vector3(0, 0, 1))
			_player.hold(_book())
		"sleep":
			_start_sleep()
		_:
			Game.finish_cutscene()
			return
	active = true


func _spot(name: String, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	return _spots.get(name, fallback)


# ---------- poszczególne sceny ----------

## Zamiatanie w miejscu: krótkie ruchy miotłą w lewo i w prawo. Ta sama animacja
## na placu i w kościele, więc nigdzie nie da się wejść w ławki ani w ścianę.
func _start_sweep() -> void:
	_base_yaw = _player.model_yaw()
	_player.set_pose("work")
	_player.hold(_broom())


func _broom() -> Node3D:
	var root := Node3D.new()
	var stick := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.03
	cyl.bottom_radius = 0.03
	cyl.height = 1.7
	cyl.radial_segments = 5
	stick.mesh = cyl
	stick.material_override = ToonMaterial.make(Palette.TRUNK)
	stick.position = Vector3(0.52, 0.9, 0.6)
	stick.rotation_degrees = Vector3(44, 0, -18)
	root.add_child(stick)
	var head := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.12, 0.22)
	head.mesh = box
	head.material_override = ToonMaterial.make(Color("8a7a4a"))
	head.position = Vector3(0.68, 0.08, 1.18)
	root.add_child(head)
	return root


func _book() -> Node3D:
	var root := Node3D.new()
	var cover := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.04, 0.22)
	cover.mesh = box
	cover.material_override = ToonMaterial.make(Palette.BOOK_A)
	cover.position = Vector3(0.0, 1.02, 0.34)
	cover.rotation_degrees = Vector3(-24, 0, 0)
	root.add_child(cover)
	var pages := MeshInstance3D.new()
	var page_box := BoxMesh.new()
	page_box.size = Vector3(0.27, 0.03, 0.19)
	pages.mesh = page_box
	pages.material_override = ToonMaterial.make(Palette.PAPER)
	pages.position = Vector3(0.0, 1.06, 0.33)
	pages.rotation_degrees = Vector3(-24, 0, 0)
	root.add_child(pages)
	return root


func _start_seated(spot_name: String, facing: Vector3) -> void:
	_player.global_position = _spot(spot_name) + Vector3(0, 1.1, 0)
	_player.face(facing)
	_player.set_pose("sit")


func _start_sleep() -> void:
	# materac ma wierzch na wysokości 0.5, więc ciało kładzie się tuż nad nim
	_player.global_position = _spot("bed_spot") + Vector3(0, 0.62, 0)
	_player.set_pose("lie")


func _start_confession() -> void:
	_start_seated("confession_seat", Vector3(1, 0, 0))
	var entry := _spot("scene_door")
	for i in 3:
		var node := Person.make(Game.day * 100 + i)
		node.position = entry + Vector3(randf_range(-0.5, 0.5), 0, i * 0.9)
		add_child(node)
		people.append({"node": node, "goal": _spot("confession_kneel") + Vector3(0, 0, i * 0.05),
			"state": "wait", "delay": i * 1.1, "timer": 0.0})


# ---------- przebieg ----------

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	Game.cutscene_progress(clampf(elapsed / length, 0.0, 1.0))
	match kind:
		"sweep":
			_run_sweep(delta)
		"confession":
			_run_confession(delta)
		"read", "sleep":
			_player.bob(elapsed * 0.25)
	if elapsed >= length:
		_finish()


func _run_sweep(_delta: float) -> void:
	# wymach miotłą: ciało skręca w lewo i w prawo, ramiona idą razem z nim
	var swing := sin(elapsed * SWEEP_SPEED)
	_player.set_model_yaw(_base_yaw + swing * SWEEP_ARC)
	_player.bob(elapsed * 0.7)


func _run_confession(delta: float) -> void:
	for p in people:
		match p["state"]:
			"wait":
				p["delay"] -= delta
				if p["delay"] <= 0.0:
					p["state"] = "walk"
			"walk":
				if _step(p["node"], p["goal"], delta):
					p["state"] = "kneel"
					p["node"].scale = Vector3(1, 0.78, 1)
					p["timer"] = 1.2
			"kneel":
				p["timer"] -= delta
				if p["timer"] <= 0.0:
					p["state"] = "leave"
					p["node"].scale = Vector3.ONE
			"leave":
				_step(p["node"], _spot("scene_door"), delta)


func _step(node: Node3D, goal: Vector3, delta: float) -> bool:
	var pos := node.global_position
	var flat_goal := Vector3(goal.x, pos.y, goal.z)
	var to_goal := flat_goal - pos
	if to_goal.length() < 0.15:
		return true
	var step := to_goal.normalized() * WALK_SPEED * delta
	if step.length() >= to_goal.length():
		node.global_position = flat_goal
		return true
	node.global_position = pos + step
	if node.has_method("face"):
		node.face(to_goal)
	return false


func _skip() -> void:
	if active:
		_finish()


func _finish() -> void:
	if not active:
		return
	active = false
	for p in people:
		p["node"].queue_free()
	people.clear()
	if _player:
		_player.set_pose("stand")
		_player.bob(0.0)
		_player.drop_props()
		_player.global_position = _return_pos
		if _player is CharacterBody3D:
			(_player as CharacterBody3D).velocity = Vector3.ZERO
	if _rig:
		_rig.set_zoom(_zoom_before)
	Game.finish_cutscene()
