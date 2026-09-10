extends Node3D
## Fixed-angle orthographic camera that follows the player. The player never rotates it.

@export var pitch_degrees: float = -35.0
@export var yaw_degrees: float = 35.0
@export var follow_speed: float = 6.0

var target: Node3D
var _zoom_goal := 14.0
var _offset := Vector3.ZERO


func _ready() -> void:
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0)


func _camera() -> Camera3D:
	for c in get_children():
		if c is Camera3D:
			return c
	return null


## Orthographic size; smaller is closer. Instant when immediate is true, otherwise eased.
func set_zoom(size: float, immediate: bool = false) -> void:
	_zoom_goal = size
	var cam := _camera()
	if cam and immediate:
		cam.size = size


## Extra world-space offset from the target, for cutscene framing.
func set_offset(v: Vector3, immediate: bool = false) -> void:
	_offset = v
	if immediate:
		snap()


func snap() -> void:
	if target:
		var goal := target.global_position
		goal.y = 0.0
		global_position = goal + _offset


func _process(delta: float) -> void:
	var cam := _camera()
	if cam and not is_equal_approx(cam.size, _zoom_goal):
		cam.size = lerpf(cam.size, _zoom_goal, clampf(3.0 * delta, 0.0, 1.0))
	if target == null:
		return
	var goal := target.global_position
	goal.y = 0.0
	goal += _offset
	global_position = global_position.lerp(goal, clampf(follow_speed * delta, 0.0, 1.0))
