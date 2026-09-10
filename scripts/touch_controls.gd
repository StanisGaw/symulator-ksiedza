extends Control
## Virtual joystick (left half of the screen) and round buttons (right side) for touch devices.
## Feeds the same input actions the keyboard uses, so gameplay code does not care which one is active.
## Shown automatically on touchscreens; on the web add "?touch" to the URL to force it.

const JOY_CENTER := Vector2(46, 134)
const JOY_RADIUS := 26.0
const KNOB_RADIUS := 11.0
const DEAD_ZONE := 0.15
const BUTTONS := [
	{"action": "interact", "label": "E", "pos": Vector2(280, 134), "r": 17.0},
	{"action": "time_faster", "label": "T", "pos": Vector2(244, 152), "r": 12.0},
]

var _joy_touch := -1
var _joy_vec := Vector2.ZERO
var _button_touch := {}
var _font: Font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	visible = _should_show()


func _should_show() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		if q is String and q.find("touch") != -1:
			return true
	return false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag and event.index == _joy_touch:
		_joy_move(event.position)


func _touch_down(index: int, pos: Vector2) -> void:
	if pos.x < size.x * 0.5:
		if _joy_touch == -1:
			_joy_touch = index
			_joy_move(pos)
		return
	for i in BUTTONS.size():
		var b: Dictionary = BUTTONS[i]
		if pos.distance_to(b["pos"]) <= b["r"] * 1.3:
			_button_touch[index] = i
			Input.action_press(b["action"])
			queue_redraw()
			return


func _touch_up(index: int) -> void:
	if index == _joy_touch:
		_joy_touch = -1
		_apply_joy(Vector2.ZERO)
	elif _button_touch.has(index):
		var b: Dictionary = BUTTONS[_button_touch[index]]
		Input.action_release(b["action"])
		_button_touch.erase(index)
		queue_redraw()


func _joy_move(pos: Vector2) -> void:
	var v := (pos - JOY_CENTER) / JOY_RADIUS
	if v.length() > 1.0:
		v = v.normalized()
	if v.length() < DEAD_ZONE:
		v = Vector2.ZERO
	_apply_joy(v)


func _apply_joy(v: Vector2) -> void:
	_joy_vec = v
	_set_axis("move_left", "move_right", v.x)
	_set_axis("move_up", "move_down", v.y)
	queue_redraw()


func _set_axis(neg: String, pos: String, value: float) -> void:
	if value < -DEAD_ZONE:
		Input.action_release(pos)
		Input.action_press(neg, -value)
	elif value > DEAD_ZONE:
		Input.action_release(neg)
		Input.action_press(pos, value)
	else:
		Input.action_release(neg)
		Input.action_release(pos)


func _draw() -> void:
	var base := Color(1, 1, 1, 0.10)
	var ring := Color(1, 1, 1, 0.35)
	var knob := Color(0.9, 0.88, 0.95, 0.55 if _joy_touch != -1 else 0.35)
	draw_circle(JOY_CENTER, JOY_RADIUS, base)
	draw_arc(JOY_CENTER, JOY_RADIUS, 0.0, TAU, 32, ring, 1.0)
	draw_circle(JOY_CENTER + _joy_vec * JOY_RADIUS * 0.75, KNOB_RADIUS, knob)
	for i in BUTTONS.size():
		var b: Dictionary = BUTTONS[i]
		var pressed := _button_touch.values().has(i)
		draw_circle(b["pos"], b["r"], Color(1, 0.75, 0.4, 0.45) if pressed else base)
		draw_arc(b["pos"], b["r"], 0.0, TAU, 24, ring, 1.0)
		var label: String = b["label"]
		var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 8).x
		draw_string(_font, b["pos"] + Vector2(-w * 0.5, 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.85))
