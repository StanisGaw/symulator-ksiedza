extends SubViewport
## Owns the persistent player and camera, swaps location scenes and places the player at spawn markers.

const PLAYER_SCENE := preload("res://scenes/player.tscn")

@export var start_location := "outside"
@export var start_spawn := "start"

var player: CharacterBody3D
var rig: Node3D
var current: Node3D


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	rig = Node3D.new()
	rig.name = "CameraRig"
	rig.add_to_group("camera_rig")
	rig.set_script(load("res://scripts/camera_rig.gd"))
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 14.0
	cam.near = 0.1
	cam.far = 120.0
	cam.position = Vector3(0, 0, 30)
	rig.add_child(cam)
	add_child(rig)
	rig.target = player
	cam.current = true
	Game.location_change_requested.connect(go_to)
	# debug: godot --path . -- --loc=church  (spawn "door")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--loc="):
			start_location = arg.trim_prefix("--loc=")
			start_spawn = "door"
	go_to(start_location, start_spawn)


func go_to(location_id: String, spawn: String) -> void:
	if current:
		current.queue_free()
		current = null
	var packed: PackedScene = load("res://scenes/locations/%s.tscn" % location_id)
	current = packed.instantiate()
	add_child(current)
	var marker := current.find_child("Spawn_" + spawn, true, false) as Marker3D
	var pos := marker.global_position if marker else Vector3.ZERO
	player.global_position = pos + Vector3(0, 1.1, 0)
	player.velocity = Vector3.ZERO
	player.clear_targets()
	rig.set_zoom(14.0, true)
	rig.set_offset(Vector3.ZERO, true)
	rig.snap()
	Game.location = location_id
	Game.set_prompt("")
