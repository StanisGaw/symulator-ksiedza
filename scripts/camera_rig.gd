extends Node3D
## Fixed-angle orthographic camera that follows the player. The player never rotates it.

@export var pitch_degrees: float = -35.0
@export var yaw_degrees: float = 35.0
@export var follow_speed: float = 6.0

var target: Node3D


func _ready() -> void:
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0)


func snap() -> void:
	if target:
		var goal := target.global_position
		goal.y = 0.0
		global_position = goal


func _process(delta: float) -> void:
	if target == null:
		return
	var goal := target.global_position
	goal.y = 0.0
	global_position = global_position.lerp(goal, clampf(follow_speed * delta, 0.0, 1.0))
