extends Node3D
## Fixed-angle orthographic camera that follows the player. The player never rotates it.

@export var target_path: NodePath
@export var pitch_degrees: float = -35.0
@export var yaw_degrees: float = 35.0
@export var follow_speed: float = 6.0

var _target: Node3D


func _ready() -> void:
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0)
	_target = get_node_or_null(target_path)
	if _target:
		global_position = _target.global_position


func _process(delta: float) -> void:
	if _target == null:
		return
	var goal := _target.global_position
	goal.y = 0.0
	global_position = global_position.lerp(goal, clampf(follow_speed * delta, 0.0, 1.0))
