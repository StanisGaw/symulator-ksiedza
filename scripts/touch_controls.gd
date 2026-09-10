extends Control
## Virtual joystick (left half of the screen) and round buttons (right side) for touch devices.
## Feeds the same input actions the keyboard uses. Coordinates are in the 1280x720 UI space.
## Shown automatically on touchscreens; on the web add "?touch" to the URL to force it.

const JOY_CENTER := Vector2(184, 540)
const JOY_RADIUS := 104.0
const KNOB_RADIUS := 44.0
const DEAD_ZONE := 0.15
const BUTTONS := [
	{"action": "interact", "label": "E", "pos": Vector2(1120, 540), "r": 68.0},
	{"action": "time_faster", "label": "T", "pos": Vector2(976, 612), "r": 48.0},
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
	if OS.has_feature("web"):
		var r = JavaScriptBridge.eval("(navigator.maxTouchPoints > 0) || (window.location.search.indexOf('touch') >= 0)", true)
		return bool(r)
	if OS.has_feature("mobile"):
		return true
	return OS.get_cmdline_user_args().has("--touch")


func _input(event: InputEvent) -> void:
	if not visible or Game.modal_open:
		if _joy_touch != -1:
			_joy_touch = -1
			_apply_joy(Vector2.ZERO)
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
	if Game.modal_open:
		return
	var base := Color(1, 1, 1, 0.10)
	var ring := Color(1, 1, 1, 0.35)
	var knob := Color(0.9, 0.88, 0.95, 0.55 if _joy_touch != -1 else 0.35)
	draw_circle(JOY_CENTER, JOY_RADIUS, base)
	draw_arc(JOY_CENTER, JOY_RADIUS, 0.0, TAU, 48, ring, 3.0)
	draw_circle(JOY_CENTER + _joy_vec * JOY_RADIUS * 0.75, KNOB_RADIUS, knob)
	for i in BUTTONS.size():
		var b: Dictionary = BUTTONS[i]
		var pressed := _button_touch.values().has(i)
		draw_circle(b["pos"], b["r"], Color(1, 0.75, 0.4, 0.45) if pressed else base)
		draw_arc(b["pos"], b["r"], 0.0, TAU, 40, ring, 3.0)
		var label: String = b["label"]
		var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 34).x
		draw_string(_font, b["pos"] + Vector2(-w * 0.5, 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1, 1, 1, 0.85))


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()
