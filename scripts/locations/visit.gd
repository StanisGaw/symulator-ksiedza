extends LocationBase
## Cutscene location for visiting a sick parishioner. Two sets far apart in one scene:
## A) an old tenement façade by day, strongly backlit. The car pulls in, the priest walks in through
##    the gate and only his dark silhouette is seen climbing past the big glazed stairwell windows.
##    The sick room's window glows weakly through dusty net curtains: an IV stand, bottles on the sill.
## C) the sick room by day: pale cold light through a dirty window, dust in the air, an IV stand,
##    a nightstand buried in pill blisters and tissues, rumpled bedding. Through the frosted glass of the
##    door a dark figure climbs the stairs, then the door opens and the priest comes in to pray.
## The location itself is the director: it moves the player between sets and reports progress.

const SET_A := Vector3(0, 0, 0)
const SET_C := Vector3(0, 0, -160)
const WALK := 3.0
const CAR_SPEED := 7.0
const GATE_X := -3.0
const STAIR_BOTTOM := 4.2
const STAIR_TOP := 11.2

const FACADE := Color("a89a80")
const FACADE_DARK := Color("7c705c")
const CORNICE := Color("bfb298")
const ASPHALT := Color("3a3a3c")
const COURTYARD := Color("5a5a52")
const GLASS_DARK := Color("2e3440")
const GLASS_BACKLIT := Color("d8dce4")
const GLASS_DUSTY := Color("b8b4a8")
const LIT_WARM := Color("ffc070")
var WALLPAPER := Color("b8a890")
var WALLPAPER_STRIPE := Color("a09078")
const WALLPAPER_PEEL := Color("cbbda4")
var PARQUET := Color("5a4030")
var PARQUET_LIGHT := Color("6a5040")
const WOOD := Color("5a3a22")
const WOOD_LIGHT := Color("8a6a42")
var BLANKET := Color("6a4a4a")
var BLANKET_DARK := Color("4a3236")
const LINEN := Color("d8d2c4")
const LINEN_DIRTY := Color("c4bcaa")
const LACE := Color("e8e2d4")
const TV_BODY := Color("2a2622")
const LIT_TV := Color("8ab0ff")
var GREY_HAIR := Color("b0aca0")
const BRASS := Color("c9a227")
const PLANT := Color("3a4a2c")
const CLAY := Color("9a5a3a")
const STEEL := Color("9aa0a8")
const BLISTER := Color("c8ccd0")
const AMBER := Color("8a5a1a")
const CORRIDOR := Color("3a3830")

var _player: Node3D
var _rig: Node3D
var _car: Node3D
var _silhouette: Node3D
var _door_shadow: Node3D
var _door_hinge: Node3D
var _tv_light: OmniLight3D
var _phase := 0
var _t := 0.0
var _walk_t := 0.0
var _path: Array = []
var _running := false
## Kogo odwiedzamy: kolory pokoju i rekwizyty biorą się stąd.
var _v: Dictionary = {}
var _clutter := 1.0


func _ready() -> void:
	_apply_variant()
	_environment(Color("8a949e"), Color("6a7480"), 0.85, 0.003)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("e8e4dc")
	sun.light_energy = 2.2
	sun.rotation_degrees = Vector3(-32, 150, 0)
	sun.shadow_enabled = true
	sun.light_cull_mask = 1
	add_child(sun)
	_build_set_a()
	var before := get_child_count()
	_build_set_c()
	for i in range(before, get_child_count()):
		_assign_layer(get_child(i), 2)
	_spawn("start", SET_A + Vector3(17, 0, 6))
	Game.cutscene_skip.connect(_skip)
	call_deferred("_start")


## Pokój dostosowany do tego, kto w nim leży.
func _apply_variant() -> void:
	_v = Game.next_visit()
	WALLPAPER = Visits.color(_v, "wallpaper", "b8a890")
	WALLPAPER_STRIPE = Visits.color(_v, "stripe", "a09078")
	PARQUET = Visits.color(_v, "parquet", "5a4030")
	PARQUET_LIGHT = Visits.color(_v, "parquet_light", "6a5040")
	BLANKET = Visits.color(_v, "blanket", "6a4a4a")
	BLANKET_DARK = Visits.color(_v, "blanket_dark", "4a3236")
	GREY_HAIR = Visits.color(_v, "hair", "b0aca0")
	_clutter = float(_v.get("clutter", 1.0))


# ---------- direction ----------

func _start() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_rig = get_tree().get_first_node_in_group("camera_rig") as Node3D
	if _player == null:
		return
	_running = true
	_phase = 0
	_t = 0.0
	_player.visible = false
	_car.position = SET_A + Vector3(17, 0, 6)


func _process(delta: float) -> void:
	if not _running or _player == null:
		return
	_t += delta
	if _tv_light:
		_tv_light.light_energy = 0.8 + 0.4 * sin(_t * 23.0) * sin(_t * 7.0)
	match _phase:
		0: _phase_drive(delta)
		1: _phase_walk(delta, 0.15, 0.3, 2)
		2: _phase_climb()
		3: _phase_door()
		4: _phase_walk(delta, 0.65, 0.8, 5)
		5: _phase_pray()


func _phase_drive(delta: float) -> void:
	var goal := SET_A + Vector3(5, 0, 6)
	_car.position.x = move_toward(_car.position.x, goal.x, CAR_SPEED * delta)
	_car.position.y = 0.03 * absf(sin(_t * 30.0))
	_player.global_position = _car.position + Vector3(0, 1.1, 0)
	Game.cutscene_progress(0.15 * (1.0 - (_car.position.x - goal.x) / 12.0))
	if is_equal_approx(_car.position.x, goal.x):
		_car.position.y = 0.0
		_player.visible = true
		_player.global_position = _car.position + Vector3(-1.2, 1.1, 1.4)
		_path = [SET_A + Vector3(-1.5, 0, 3.2), SET_A + Vector3(GATE_X, 0, 1.4)]
		_phase = 1
		_t = 0.0


func _phase_walk(delta: float, p0: float, p1: float, next_phase: int) -> void:
	if _path.is_empty():
		_enter_phase(next_phase)
		return
	var target: Vector3 = _path[0]
	var pos := _player.global_position
	var to := target + Vector3(0, 1.1, 0) - pos
	var dist := to.length()
	var step := WALK * delta
	_walk_t += delta
	if _player.has_method("bob"):
		_player.bob(_walk_t)
	if dist <= step:
		_player.global_position = target + Vector3(0, 1.1, 0)
		_path.pop_front()
	else:
		_player.global_position = pos + to / dist * step
		if _player.has_method("face"):
			_player.face(Vector3(to.x, 0, to.z))
	Game.cutscene_progress(lerpf(p0, p1, 1.0 - float(_path.size()) / 3.0))


## The priest is inside; his shadow climbs the glazed stairwell in one smooth zigzag, never hidden,
## and stops on the sick woman's floor.
func _phase_climb() -> void:
	var total := 5.5
	var f := clampf(_t / total, 0.0, 1.0)
	var eased := f * f * (3.0 - 2.0 * f)
	var y: float = lerpf(STAIR_BOTTOM, STAIR_TOP, eased) + 0.03 * sin(_t * 9.0)
	var sway := sin(eased * PI * 2.0) * 0.55
	var dir := cos(eased * PI * 2.0)
	_silhouette.visible = true
	_silhouette.position = SET_A + Vector3(GATE_X + sway, y, 0.2)
	_silhouette.scale = Vector3(1.3 * (1.0 if dir >= 0.0 else -1.0), 1.2, 1.0)
	Game.cutscene_progress(0.3 + 0.25 * f)
	if _t >= total + 0.3:
		_silhouette.visible = false
		_enter_phase(3)


## Inside the room: a dark figure behind the frosted door climbs the last steps, then the door opens.
func _phase_door() -> void:
	var climb := 1.6
	var pause := 0.5
	var swing := 0.7
	if _t < climb:
		# seen through the frosted panel: the figure comes up the last flight, growing as it nears the door
		var f := _t / climb
		_door_shadow.visible = true
		var grow := 0.55 + 0.45 * f
		_door_shadow.scale = Vector3(grow, grow * (0.96 + 0.04 * sin(f * PI * 6.0)), grow)
		_door_shadow.position = SET_C + Vector3(-3.6, 0.32 + 0.12 * f, 2.35 - 0.55 * f)
	elif _t < climb + pause:
		_door_shadow.scale = Vector3.ONE
		_door_shadow.position = SET_C + Vector3(-3.6, 0.44, 1.8)
	elif _t < climb + pause + swing:
		var f := (_t - climb - pause) / swing
		_door_hinge.rotation.y = deg_to_rad(100.0 * f)
		_door_shadow.visible = f < 0.4
	else:
		_door_hinge.rotation.y = deg_to_rad(100.0)
		_door_shadow.visible = false
		_player.visible = true
		_player.global_position = SET_C + Vector3(-4.0, 1.1, 2.0)
		_path = [SET_C + Vector3(-2.2, 0, 2.0), SET_C + Vector3(0.8, 0, 0.9), SET_C + Vector3(1.0, 0, -0.9)]
		_phase = 4
		_t = 0.0
		return
	Game.cutscene_progress(0.55 + 0.1 * clampf(_t / (climb + pause + swing), 0.0, 1.0))


func _enter_phase(next_phase: int) -> void:
	_phase = next_phase
	_t = 0.0
	if OS.get_cmdline_user_args().has("--trace"):
		print("visit: phase %d at %s" % [next_phase, Game.clock_text()])
	match next_phase:
		2:
			_player.visible = false
			_player.global_position = SET_A + Vector3(GATE_X, 1.1, 0.8)
			if _rig and _rig.has_method("set_offset"):
				_rig.set_offset(Vector3(1.0, 7.5, 0))
			if _rig and _rig.has_method("set_zoom"):
				_rig.set_zoom(16.0)
		3:
			if _rig and _rig.has_method("set_offset"):
				_rig.set_offset(Vector3.ZERO, true)
			_player.visible = false
			_player.global_position = SET_C + Vector3(-1.2, 1.1, 0.6)
			_snap()
			if _rig and _rig.has_method("set_zoom"):
				_rig.set_zoom(9.5, true)
		5:
			if _rig and _rig.has_method("set_zoom"):
				_rig.set_zoom(6.0)
			if _player.has_method("face"):
				_player.face(Vector3(-0.2, 0, -1))
			if _player.has_method("set_pose"):
				_player.set_pose("kneel")
			_player.position.y = 1.1
			if _player.has_method("bob"):
				_player.bob(0.0)


func _phase_pray() -> void:
	Game.cutscene_progress(0.8 + 0.2 * clampf(_t / 5.0, 0.0, 1.0))
	if _t >= 5.0:
		_finish()


func _snap() -> void:
	if _rig and _rig.has_method("snap"):
		_rig.snap()


func _skip() -> void:
	if _running:
		_finish()


func _finish() -> void:
	if OS.get_cmdline_user_args().has("--trace"):
		print("visit: finish at %s" % Game.clock_text())
	_running = false
	if _player:
		_player.visible = true
		if _player.has_method("set_pose"):
			_player.set_pose("stand")
		if _player.has_method("bob"):
			_player.bob(0.0)
	if _rig and _rig.has_method("set_offset"):
		_rig.set_offset(Vector3.ZERO, true)
	Game.finish_cutscene()


## Puts a subtree on a render layer so only that layer's lights affect it (sun stays outside).
func _assign_layer(node: Node, layer: int) -> void:
	if node is VisualInstance3D:
		node.layers = layer
	if node is Light3D:
		node.light_cull_mask = layer
	for c in node.get_children():
		_assign_layer(c, layer)


func _shadow_figure(frosted: bool = false) -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("101014")
	if frosted:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.12, 0.13, 0.17, 0.85)
		mat.render_priority = 2
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.55, 1.35, 0.04)
	body.mesh = bm
	body.material_override = mat
	body.position = Vector3(0, 0.68, 0)
	root.add_child(body)
	var shoulders := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.7, 0.3, 0.04)
	shoulders.mesh = sm
	shoulders.material_override = mat
	shoulders.position = Vector3(0, 1.25, 0)
	root.add_child(shoulders)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.2
	hm.height = 0.4
	hm.radial_segments = 8
	hm.rings = 5
	head.mesh = hm
	head.material_override = mat
	head.position = Vector3(0, 1.55, 0)
	head.scale = Vector3(1, 1, 0.15)
	root.add_child(head)
	root.visible = false
	return root


# ---------- set A: the tenement ----------

func _build_set_a() -> void:
	var o := SET_A
	var ground := PlaneMesh.new()
	ground.size = Vector2(60, 40)
	_mesh(ground, ToonMaterial.make(COURTYARD, Color.BLACK, 0.0, false), o)
	_box(Vector3(60, 0.05, 6), ASPHALT, o + Vector3(0, 0.025, 6), Vector3.ZERO, false)
	_box(Vector3(60, 0.08, 2.4), Color("6a6a62"), o + Vector3(0, 0.04, 2.2), Vector3.ZERO, false)
	for i in range(5):
		_box(Vector3(1.2 + i * 0.4, 0.02, 0.8), Color("4a4e52"), o + Vector3(-9 + i * 4.5, 0.06, 5.2 + (i % 2)), Vector3.ZERO, false)
	# façade: plaster body, rusticated ground floor, cornices, roof edge
	_box(Vector3(22, 17, 10), FACADE, o + Vector3(0, 8.5, -5))
	_box(Vector3(22.04, 4.0, 0.08), FACADE_DARK, o + Vector3(0, 2.0, 0.04), Vector3.ZERO, false)
	for i in range(7):
		_box(Vector3(22.06, 0.06, 0.1), Color("6a6050"), o + Vector3(0, 0.55 + i * 0.5, 0.05), Vector3.ZERO, false)
	for y in [4.0, 8.0, 12.0]:
		_box(Vector3(22.4, 0.25, 0.35), CORNICE, o + Vector3(0, y, 0.15))
	_box(Vector3(22.8, 0.5, 0.6), CORNICE, o + Vector3(0, 16.9, 0.25))
	_box(Vector3(22.8, 0.3, 10.6), Color("4a3a32"), o + Vector3(0, 17.2, -5))
	# tall windows: frame, dark glass, lintel and sill; a few faintly lit
	var seed := 5
	for f in range(4):
		for c in range(6):
			var x := -8.35 + c * 3.33
			if c == 2:
				continue
			var y := 2.4 + f * 4.0
			seed = (seed * 9301 + 49297) % 233280
			var r := seed % 10
			_box(Vector3(1.5, 2.5, 0.06), CORNICE, o + Vector3(x, y, 0.05), Vector3.ZERO, false)
			if f == 2 and c == 3:
				_glow_box(Vector3(1.24, 2.24, 0.06), GLASS_DUSTY, 0.22, o + Vector3(x, y, 0.09))
				_box(Vector3(0.04, 1.6, 0.03), Color("14141a"), o + Vector3(x - 0.35, y + 0.1, 0.13), Vector3.ZERO, false)
				_box(Vector3(0.16, 0.3, 0.03), Color("d0d4d8"), o + Vector3(x - 0.35, y + 0.75, 0.13), Vector3.ZERO, false)
				_box(Vector3(0.3, 0.03, 0.03), Color("14141a"), o + Vector3(x - 0.35, y - 0.7, 0.13), Vector3.ZERO, false)
				for b in range(4):
					_cyl(0.04, 0.04, 0.16 + (b % 2) * 0.08, [AMBER, Color("e8e8e8"), AMBER, Color("6a8ab0")][b], o + Vector3(x - 0.2 + b * 0.16, y - 1.0, 0.2), Vector3.ZERO, 6)
				_box(Vector3(0.5, 0.18, 0.05), LINEN_DIRTY, o + Vector3(x + 0.3, y - 0.6, 0.12), Vector3(0, 0, 8), false)
			elif r < 2:
				_glow_box(Vector3(1.24, 2.24, 0.06), LIT_WARM, 0.2, o + Vector3(x, y, 0.09))
			else:
				_box(Vector3(1.24, 2.24, 0.06), GLASS_DARK, o + Vector3(x, y, 0.09), Vector3.ZERO, false)
			_box(Vector3(0.05, 2.24, 0.07), Color("e8e4d8"), o + Vector3(x, y, 0.11), Vector3.ZERO, false)
			_box(Vector3(1.24, 0.05, 0.07), Color("e8e4d8"), o + Vector3(x, y + 0.5, 0.11), Vector3.ZERO, false)
			_box(Vector3(1.7, 0.18, 0.3), CORNICE, o + Vector3(x, y + 1.4, 0.12))
			_box(Vector3(1.6, 0.12, 0.3), CORNICE, o + Vector3(x, y - 1.3, 0.12))
	# stairwell column: gate with an arch below, big glazed windows on the landings, backlit
	_box(Vector3(2.6, 17, 0.1), FACADE_DARK, o + Vector3(GATE_X, 8.5, 0.02), Vector3.ZERO, false)
	_glow_box(Vector3(2.0, 9.4, 0.08), GLASS_BACKLIT, 1.5, o + Vector3(GATE_X, 8.6, 0.09))
	_box(Vector3(2.2, 0.1, 0.14), CORNICE, o + Vector3(GATE_X, 13.35, 0.1), Vector3.ZERO, false)
	_box(Vector3(2.2, 0.1, 0.14), CORNICE, o + Vector3(GATE_X, 3.85, 0.1), Vector3.ZERO, false)
	_box(Vector3(0.05, 9.4, 0.12), Color("3a3a3c"), o + Vector3(GATE_X, 8.6, 0.13), Vector3.ZERO, false)
	for k in range(8):
		_box(Vector3(2.0, 0.05, 0.12), Color("3a3a3c"), o + Vector3(GATE_X, 4.5 + k * 1.2, 0.13), Vector3.ZERO, false)
	_box(Vector3(2.0, 3.0, 0.14), WOOD, o + Vector3(GATE_X, 1.5, 0.1))
	_cyl(1.05, 1.05, 0.16, WOOD, o + Vector3(GATE_X, 3.0, 0.1), Vector3(90, 0, 0), 12)
	_cyl(1.3, 1.3, 0.3, CORNICE, o + Vector3(GATE_X, 3.0, 0.02), Vector3(90, 0, 0), 12)
	_box(Vector3(0.06, 2.9, 0.16), Color("2a1a10"), o + Vector3(GATE_X, 1.45, 0.14), Vector3.ZERO, false)
	var num := Label3D.new()
	num.text = "12"
	num.font_size = 48
	num.pixel_size = 0.008
	num.modulate = Color("1a1a1a")
	num.position = o + Vector3(GATE_X + 1.6, 4.6, 0.1)
	add_child(num)
	_silhouette = _shadow_figure()
	add_child(_silhouette)
	# courtyard: bins, a bench, a bare tree, a bicycle rack
	for i in range(3):
		_box(Vector3(1.1, 1.2, 0.9), [Color("2f5a3a"), Color("3a3a5a"), Color("5a5a3a")][i], o + Vector3(7 + i * 1.3, 0.6, 1.4))
	_box(Vector3(1.8, 0.1, 0.5), WOOD_LIGHT, o + Vector3(-6.5, 0.5, 1.6))
	_box(Vector3(1.8, 0.5, 0.08), WOOD_LIGHT, o + Vector3(-6.5, 0.85, 1.36))
	_cyl(0.12, 0.18, 3.4, Color("4a4038"), o + Vector3(12, 1.7, 2.0), Vector3.ZERO, 7)
	for b in range(5):
		_cyl(0.03, 0.05, 1.6, Color("4a4038"), o + Vector3(12, 3.9, 2.0), Vector3(30 + b * 15, b * 72, 0), 5)
	for i in range(4):
		_box(Vector3(0.06, 0.7, 0.4), STEEL, o + Vector3(-11 + i * 0.5, 0.35, 3.4))
	# the priest's car
	_car = Node3D.new()
	_car_part(_car, Vector3(4, 0.75, 1.9), Palette.CAR, Vector3(0, 0.65, 0))
	_car_part(_car, Vector3(2.2, 0.7, 1.7), Palette.CAR_DARK, Vector3(-0.2, 1.37, 0))
	_car_part(_car, Vector3(2.0, 0.5, 1.74), Palette.GLASS, Vector3(-0.2, 1.42, 0), false)
	for off in [Vector2(-1.3, -0.95), Vector2(1.3, -0.95), Vector2(-1.3, 0.95), Vector2(1.3, 0.95)]:
		var w := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.36
		cyl.bottom_radius = 0.36
		cyl.height = 0.3
		cyl.radial_segments = 12
		w.mesh = cyl
		w.material_override = ToonMaterial.make(Palette.WHEEL)
		w.position = Vector3(off.x, 0.36, off.y)
		w.rotation_degrees = Vector3(90, 0, 0)
		_car.add_child(w)
	add_child(_car)
	_car.position = o + Vector3(17, 0, 6)


func _car_part(parent: Node3D, size: Vector3, color: Color, pos: Vector3, outline: bool = true) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = ToonMaterial.make(color, Color.BLACK, 0.0, outline)
	mi.position = pos
	parent.add_child(mi)


# ---------- set C: the sick room ----------

func _build_set_c() -> void:
	var o := SET_C
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(7, 6)
	_mesh(floor_mesh, ToonMaterial.make(PARQUET, Color.BLACK, 0.0, false), o)
	for i in range(12):
		_box(Vector3(0.04, 0.01, 6), PARQUET_LIGHT, o + Vector3(-3.3 + i * 0.6, 0.005, 0), Vector3.ZERO, false)
	# north wall with the window; west wall split around the door; peeling wallpaper patches
	_box(Vector3(7.4, 3.2, 0.4), WALLPAPER, o + Vector3(0, 1.6, -3.2))
	_box(Vector3(0.4, 3.2, 4.0), WALLPAPER, o + Vector3(-3.7, 1.6, -1.0))
	_box(Vector3(0.4, 3.2, 0.4), WALLPAPER, o + Vector3(-3.7, 1.6, 2.8))
	_box(Vector3(0.4, 1.0, 1.6), WALLPAPER, o + Vector3(-3.7, 2.7, 1.8))
	for i in range(14):
		_box(Vector3(0.12, 3.0, 0.03), WALLPAPER_STRIPE, o + Vector3(-3.3 + i * 0.5, 1.5, -2.98), Vector3.ZERO, false)
	for i in range(8):
		_box(Vector3(0.03, 3.0, 0.12), WALLPAPER_STRIPE, o + Vector3(-3.48, 1.5, -2.8 + i * 0.5), Vector3.ZERO, false)
	_box(Vector3(0.6, 0.4, 0.035), WALLPAPER_PEEL, o + Vector3(2.9, 2.75, -2.97), Vector3(0, 0, 12), false)
	_box(Vector3(0.035, 0.5, 0.5), WALLPAPER_PEEL, o + Vector3(-3.47, 2.8, -2.2), Vector3(0, 0, -8), false)
	_box(Vector3(7.0, 0.14, 0.05), WOOD, o + Vector3(0, 0.07, -2.97), Vector3.ZERO, false)
	_box(Vector3(0.05, 0.14, 4.0), WOOD, o + Vector3(-3.47, 0.07, -1.0), Vector3.ZERO, false)
	# window on the north wall: dirty glass, cold light, net curtain, geranium long dead; radiator
	_glow_box(Vector3(1.6, 1.5, 0.08), Color("c8d0d8"), 1.0, o + Vector3(-1.6, 1.9, -2.97))
	_box(Vector3(0.05, 1.5, 0.1), Color("e8e4d8"), o + Vector3(-1.6, 1.9, -2.95), Vector3.ZERO, false)
	_box(Vector3(1.6, 0.05, 0.1), Color("e8e4d8"), o + Vector3(-1.6, 2.1, -2.95), Vector3.ZERO, false)
	_box(Vector3(1.8, 0.05, 0.05), LINEN_DIRTY, o + Vector3(-1.6, 1.4, -2.9), Vector3.ZERO, false)
	_box(Vector3(1.7, 1.4, 0.03), LINEN_DIRTY, o + Vector3(-1.6, 1.85, -2.88), Vector3.ZERO, false)
	_box(Vector3(0.35, 1.7, 0.06), Color("5a4a3a"), o + Vector3(-2.6, 1.85, -2.9))
	_box(Vector3(0.35, 1.7, 0.06), Color("5a4a3a"), o + Vector3(-0.6, 1.85, -2.9))
	_box(Vector3(1.9, 0.06, 0.3), LINEN_DIRTY, o + Vector3(-1.6, 1.12, -2.85), Vector3.ZERO, false)
	_cyl(0.09, 0.11, 0.16, CLAY, o + Vector3(-2.1, 1.22, -2.82), Vector3.ZERO, 7)
	_cyl(0.02, 0.03, 0.4, Color("4a3a2a"), o + Vector3(-2.1, 1.5, -2.82), Vector3(0, 0, 15), 4)
	for i in range(7):
		_box(Vector3(0.12, 0.5, 0.08), Color("c8c2b4"), o + Vector3(-2.0 + i * 0.13, 0.4, -2.9))
	var shaft := SpotLight3D.new()
	shaft.position = o + Vector3(-1.6, 2.2, -2.8)
	shaft.rotation_degrees = Vector3(-40, 180, 0)
	shaft.light_color = Color("c8d4e4")
	shaft.light_energy = 12.0
	shaft.spot_range = 12.0
	shaft.spot_angle = 55.0
	shaft.shadow_enabled = true
	add_child(shaft)
	_omni(o + Vector3(0.5, 2.4, 0.5), Color("8a98b0"), 1.6, 9.0)
	_omni(o + Vector3(-1.6, 2.4, -2.0), Color("c8d4e4"), 2.2, 6.0)
	# ile bałaganu na podłodze zależy od tego, kto tu mieszka i czy ma się kto zajmować
	if _clutter >= 0.6:
		# litter: cans, bottles, crumpled paper, a plastic bag, a plate with leftovers
		_cyl(0.05, 0.05, 0.16, Color("b8bcc0"), o + Vector3(1.9, 0.05, 1.9), Vector3(90, 0, 20), 8)
		_cyl(0.05, 0.05, 0.16, Color("a83a2a"), o + Vector3(2.3, 0.08, 0.2), Vector3.ZERO, 8)
		_cyl(0.05, 0.05, 0.16, Color("b8bcc0"), o + Vector3(-1.1, 0.05, 2.4), Vector3(90, 40, 0), 8)
		_cyl(0.045, 0.045, 0.3, Color("2f5a2c"), o + Vector3(0.2, 0.045, 2.5), Vector3(90, 60, 0), 7)
		_cyl(0.045, 0.045, 0.3, AMBER, o + Vector3(-2.2, 0.045, 0.4), Vector3(90, -30, 0), 7)
		for i in range(6):
			_box(Vector3(0.16, 0.05, 0.12), LACE, o + Vector3(-1.2 + i * 0.7, 0.03, 0.2 + (i % 3) * 0.8), Vector3(0, 30 * i, 0), false)
		_box(Vector3(0.4, 0.14, 0.3), Color("d8d8d8"), o + Vector3(2.6, 0.07, 1.4), Vector3(0, 25, 0), false)
		_cyl(0.16, 0.14, 0.03, Color("e0dcd0"), o + Vector3(1.4, 0.015, 2.2), Vector3.ZERO, 10)
		_box(Vector3(0.12, 0.03, 0.08), Color("8a6a3a"), o + Vector3(1.42, 0.045, 2.2), Vector3(0, 15, 0), false)
		_box(Vector3(0.3, 0.02, 0.4), Color("c8c0a8"), o + Vector3(-0.4, 0.02, 1.6), Vector3(0, -20, 0), false)
		_box(Vector3(0.3, 0.02, 0.4), Color("b8b0a0"), o + Vector3(-0.3, 0.04, 1.7), Vector3(0, 10, 0), false)
	else:
		# u kogoś zadbanego zostaje tylko talerz i szklanka przy łóżku
		_cyl(0.16, 0.14, 0.03, Color("e0dcd0"), o + Vector3(1.4, 0.015, 2.2), Vector3.ZERO, 10)
		_cyl(0.06, 0.05, 0.16, Color("a0c0d0"), o + Vector3(1.6, 0.08, 2.0), Vector3.ZERO, 8)
	if _clutter >= 1.2:
		# u zaniedbanego jeszcze więcej butelek i kubków
		for i in range(5):
			_cyl(0.045, 0.045, 0.3, AMBER, o + Vector3(-2.0 + i * 0.8, 0.045, 1.2 + (i % 2) * 0.9), Vector3(90, 20 * i, 0), 7)
		for i in range(4):
			_cyl(0.05, 0.05, 0.16, Color("b8bcc0"), o + Vector3(1.2 - i * 0.6, 0.05, 0.4 + (i % 2) * 0.7), Vector3(90, 30 * i, 0), 8)

	# bed along the north wall: rumpled bedding, the sick woman propped on two pillows, rosary in hand
	_box(Vector3(2.4, 0.5, 1.3), WOOD, o + Vector3(1.4, 0.25, -2.3))
	_box(Vector3(2.4, 0.9, 0.08), WOOD, o + Vector3(1.4, 0.45, -2.92))
	_box(Vector3(2.3, 0.16, 1.2), LINEN_DIRTY, o + Vector3(1.4, 0.58, -2.3), Vector3.ZERO, false)
	_box(Vector3(1.4, 0.26, 1.15), BLANKET, o + Vector3(1.85, 0.75, -2.3), Vector3(0, 4, 0))
	_box(Vector3(0.9, 0.16, 0.7), BLANKET_DARK, o + Vector3(2.2, 0.95, -2.1), Vector3(0, -12, 6), false)
	_box(Vector3(0.7, 0.14, 0.5), LINEN, o + Vector3(1.4, 0.9, -1.95), Vector3(0, 20, 0), false)
	_box(Vector3(0.5, 0.12, 0.4), LINEN, o + Vector3(2.5, 0.72, -1.72), Vector3(0, 35, -10), false)
	_box(Vector3(0.7, 0.3, 0.9), LINEN, o + Vector3(0.55, 0.8, -2.45), Vector3(0, 0, 12))
	_box(Vector3(0.7, 0.24, 0.8), LINEN_DIRTY, o + Vector3(0.45, 1.0, -2.45), Vector3(0, 0, 18))
	_sphere(0.22, Palette.SKIN, o + Vector3(0.65, 1.18, -2.35))
	var hair := _sphere(0.25, GREY_HAIR, o + Vector3(0.58, 1.24, -2.35))
	hair.scale = Vector3(0.9, 0.8, 1.05)
	_box(Vector3(0.5, 0.14, 0.34), LINEN, o + Vector3(1.05, 0.98, -2.1), Vector3.ZERO, false)
	_sphere(0.09, Palette.SKIN, o + Vector3(1.25, 1.04, -2.05))
	_sphere(0.09, Palette.SKIN, o + Vector3(1.08, 1.04, -1.98))
	for i in range(6):
		_sphere(0.025, Color("3a2a2a"), o + Vector3(1.12 + i * 0.05, 1.0 - i * 0.03, -1.9 + i * 0.02), false)
	if bool(_v.get("iv", true)):
		# IV stand by the bed, tube to the arm
		_box(Vector3(0.5, 0.04, 0.5), STEEL, o + Vector3(0.0, 0.02, -1.7), Vector3(0, 45, 0), false)
		_cyl(0.02, 0.02, 1.9, STEEL, o + Vector3(0.0, 0.97, -1.7), Vector3.ZERO, 6)
		_box(Vector3(0.4, 0.03, 0.03), STEEL, o + Vector3(0.0, 1.92, -1.7), Vector3.ZERO, false)
		_box(Vector3(0.14, 0.26, 0.06), Color("dde4ea"), o + Vector3(0.18, 1.72, -1.7), Vector3.ZERO, false)
		_box(Vector3(0.1, 0.16, 0.04), Color("b0d0e8"), o + Vector3(0.18, 1.66, -1.66), Vector3.ZERO, false)
		_cyl(0.008, 0.008, 1.0, Color("d8e0e8"), o + Vector3(0.6, 1.3, -1.9), Vector3(20, 0, -55), 4)
	elif bool(_v.get("oxygen", false)):
		# butla tlenowa z wąsem zamiast kroplówki
		_cyl(0.14, 0.14, 0.8, Color("3a6a8a"), o + Vector3(0.1, 0.4, -1.7), Vector3.ZERO, 10)
		_cyl(0.05, 0.05, 0.16, STEEL, o + Vector3(0.1, 0.88, -1.7), Vector3.ZERO, 8)
		_cyl(0.008, 0.008, 1.2, Color("d8e0e8"), o + Vector3(0.5, 1.15, -1.95), Vector3(25, 0, -50), 4)
	if bool(_v.get("wheelchair", false)):
		# wózek przy łóżku
		_box(Vector3(0.5, 0.08, 0.5), Color("2e3440"), o + Vector3(-0.1, 0.5, -1.2))
		_box(Vector3(0.5, 0.5, 0.08), Color("2e3440"), o + Vector3(-0.1, 0.75, -1.44))
		for side in [-0.3, 0.3]:
			_cyl(0.32, 0.32, 0.05, Color("1a1a1e"), o + Vector3(-0.1 + side, 0.32, -1.2), Vector3(90, 0, 0), 12)
	if bool(_v.get("cat", false)):
		# kot śpi w nogach łóżka
		var cat := _sphere(0.18, Color("52483e"), o + Vector3(2.35, 0.95, -2.5))
		cat.scale = Vector3(1.5, 0.8, 1.0)
		_sphere(0.11, Color("52483e"), o + Vector3(2.05, 1.0, -2.5), false)
	if bool(_v.get("books", false)):
		# stosy książek pod ścianą
		for i in range(7):
			_box(Vector3(0.24, 0.06, 0.18), [Palette.BOOK_A, Palette.BOOK_B, Palette.BOOK_C][i % 3],
				o + Vector3(-2.2 + (i % 2) * 0.3, 0.03 + float(i / 2) * 0.07, 1.6 + (i % 3) * 0.05), Vector3(0, 8 * i, 0), false)

	# nightstand buried in blisters, tissues, bottles; a chair with a coat over the back
	_box(Vector3(0.5, 0.6, 0.5), WOOD, o + Vector3(-0.7, 0.3, -2.55))
	for i in range(maxi(1, int(round(5.0 * _clutter)))):
		_box(Vector3(0.12, 0.01, 0.07), BLISTER, o + Vector3(-0.82 + i * 0.07, 0.61 + (i % 2) * 0.01, -2.45 - (i % 3) * 0.08), Vector3(0, 15 * i, 0), false)
	for i in range(3):
		_sphere(0.05, LACE, o + Vector3(-0.52 + i * 0.08, 0.66, -2.7 + i * 0.06), false)
	_sphere(0.05, LACE, o + Vector3(-0.45, 0.05, -2.2), false)
	_sphere(0.045, LACE, o + Vector3(-0.2, 0.045, -1.9), false)
	_cyl(0.05, 0.05, 0.2, AMBER, o + Vector3(-0.85, 0.71, -2.68), Vector3.ZERO, 6)
	_cyl(0.04, 0.04, 0.14, Color("e8e8e8"), o + Vector3(-0.74, 0.68, -2.72), Vector3.ZERO, 6)
	_cyl(0.06, 0.05, 0.16, Color("a0c0d0"), o + Vector3(-0.58, 0.69, -2.42), Vector3.ZERO, 8)
	_box(Vector3(0.22, 0.05, 0.16), Color("2a2a3a"), o + Vector3(-0.9, 0.64, -2.4), Vector3(0, -15, 0), false)
	_box(Vector3(0.5, 0.06, 0.5), WOOD_LIGHT, o + Vector3(2.7, 0.48, -1.5))
	_box(Vector3(0.5, 0.6, 0.06), WOOD_LIGHT, o + Vector3(2.7, 0.8, -1.75))
	_box(Vector3(0.56, 0.5, 0.14), Color("3a3a44"), o + Vector3(2.7, 0.95, -1.76), Vector3(0, 0, 3), false)
	for off in [Vector2(-0.2, -0.2), Vector2(0.2, -0.2), Vector2(-0.2, 0.2), Vector2(0.2, 0.2)]:
		_box(Vector3(0.05, 0.46, 0.05), WOOD_LIGHT, o + Vector3(2.7 + off.x, 0.23, -1.5 + off.y), Vector3.ZERO, false)
	# cross and the John Paul II portrait above the bed, a stopped clock
	_box(Vector3(0.08, 0.7, 0.05), Color("3a2416"), o + Vector3(1.9, 2.3, -2.96))
	_box(Vector3(0.42, 0.08, 0.05), Color("3a2416"), o + Vector3(1.9, 2.48, -2.96))
	_box(Vector3(0.05, 0.28, 0.03), BRASS, o + Vector3(1.9, 2.36, -2.93), Vector3.ZERO, false)
	if bool(_v.get("portrait", true)):
		_box(Vector3(0.78, 0.98, 0.05), BRASS, o + Vector3(0.6, 2.25, -2.97), Vector3(0, 0, -3))
		var portrait := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.66, 0.86)
		portrait.mesh = quad
		var pm := StandardMaterial3D.new()
		pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		pm.albedo_texture = _portrait_texture()
		portrait.material_override = pm
		portrait.position = o + Vector3(0.6, 2.25, -2.94)
		portrait.rotation_degrees = Vector3(0, 0, -3)
		add_child(portrait)
	else:
		# zamiast portretu: makatka z haftem
		_box(Vector3(0.8, 0.6, 0.04), Color("c8bca4"), o + Vector3(0.6, 2.3, -2.95), Vector3(0, 0, -2), false)
		for i in range(5):
			_box(Vector3(0.1, 0.1, 0.02), Color("8a5a4a"), o + Vector3(0.3 + i * 0.15, 2.3 + (i % 2) * 0.12, -2.92), Vector3(0, 0, 45), false)

	_cyl(0.16, 0.16, 0.04, Color("e8e2d4"), o + Vector3(3.0, 2.4, -2.95), Vector3(90, 0, 0), 12)
	_box(Vector3(0.03, 0.12, 0.02), Color("1a1a1a"), o + Vector3(3.0, 2.45, -2.92), Vector3.ZERO, false)
	_box(Vector3(0.1, 0.03, 0.02), Color("1a1a1a"), o + Vector3(3.04, 2.4, -2.92), Vector3.ZERO, false)
	# wall unit along the west wall with books and crystal, a dying ficus, CRT television playing Trwam
	_box(Vector3(0.55, 2.4, 2.4), WOOD, o + Vector3(-3.2, 1.2, -1.2))
	for y in [0.9, 1.5, 2.05]:
		_box(Vector3(0.5, 0.04, 2.3), WOOD_LIGHT, o + Vector3(-3.15, y, -1.2), Vector3.ZERO, false)
	var books := [Palette.BOOK_A, Palette.BOOK_B, Palette.BOOK_C, Color("3a5a3a")]
	for i in range(8):
		_box(Vector3(0.3, 0.3, 0.14), books[i % 4], o + Vector3(-3.1, 1.08, -2.2 + i * 0.22), Vector3.ZERO, false)
	_cyl(0.1, 0.07, 0.34, Color("bcd0e0"), o + Vector3(-3.1, 1.7, -0.6), Vector3.ZERO, 8)
	_box(Vector3(0.3, 0.02, 0.3), LACE, o + Vector3(-3.1, 1.53, -0.6), Vector3.ZERO, false)
	_box(Vector3(0.3, 0.02, 0.4), LACE, o + Vector3(-3.15, 2.42, -1.6), Vector3.ZERO, false)
	_cyl(0.16, 0.2, 0.3, CLAY, o + Vector3(-3.0, 0.15, 0.3), Vector3.ZERO, 8)
	_cyl(0.03, 0.04, 1.2, Color("4a3a2a"), o + Vector3(-3.0, 0.9, 0.3), Vector3.ZERO, 5)
	_sphere(0.4, PLANT, o + Vector3(-3.0, 1.5, 0.3))
	if bool(_v.get("tv", true)):
		_box(Vector3(0.8, 0.5, 0.7), WOOD, o + Vector3(-2.7, 0.25, -2.4))
		_box(Vector3(0.7, 0.58, 0.72), TV_BODY, o + Vector3(-2.65, 0.79, -2.4))
		var screen := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(0.54, 0.42)
		screen.mesh = sq
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		var tv_tex := _tv_texture()
		sm.albedo_texture = tv_tex
		sm.emission_enabled = true
		sm.emission_texture = tv_tex
		sm.emission_energy_multiplier = 1.2
		screen.material_override = sm
		screen.position = o + Vector3(-2.28, 0.8, -2.4)
		screen.rotation_degrees = Vector3(0, 90, 0)
		add_child(screen)
		_box(Vector3(0.5, 0.02, 0.5), LACE, o + Vector3(-2.65, 1.09, -2.4), Vector3.ZERO, false)
		_cyl(0.015, 0.015, 0.7, Color("aaaaaa"), o + Vector3(-2.75, 1.5, -2.3), Vector3(0, 0, 25), 5)
		_cyl(0.015, 0.015, 0.7, Color("aaaaaa"), o + Vector3(-2.75, 1.5, -2.5), Vector3(0, 0, -25), 5)
		_tv_light = _omni(o + Vector3(-1.6, 1.0, -2.3), LIT_TV, 1.0, 3.5)
	else:
		# bez telewizora: komoda, radio na serwetce i lampka
		_box(Vector3(0.9, 0.8, 0.5), WOOD, o + Vector3(-2.8, 0.4, -2.4))
		_box(Vector3(0.5, 0.02, 0.42), LACE, o + Vector3(-2.8, 0.81, -2.4), Vector3.ZERO, false)
		_box(Vector3(0.42, 0.24, 0.22), Color("6a5236"), o + Vector3(-2.78, 0.94, -2.4))
		_box(Vector3(0.3, 0.12, 0.02), Color("c8bc98"), o + Vector3(-2.57, 0.96, -2.4), Vector3.ZERO, false)
		_cyl(0.015, 0.015, 0.5, Color("aaaaaa"), o + Vector3(-2.9, 1.3, -2.5), Vector3(0, 0, 18), 5)
		_omni(o + Vector3(-2.2, 1.4, -2.2), Color("ffc070"), 1.1, 3.5)
	# rug, a lamp with a fringed shade, a wash bowl on the floor
	_box(Vector3(3.0, 0.02, 2.2), Color("5a2a2a"), o + Vector3(0.6, 0.02, 0.9), Vector3(0, -4, 0), false)
	_box(Vector3(2.6, 0.025, 1.8), Color("7a5a3a"), o + Vector3(0.6, 0.02, 0.9), Vector3(0, -4, 0), false)
	_cyl(0.3, 0.42, 0.26, Color("a8783a"), o + Vector3(0.2, 2.75, 0.2), Vector3.ZERO, 10)
	_cyl(0.28, 0.2, 0.1, Color("c8c2b4"), o + Vector3(2.4, 0.05, 0.6), Vector3.ZERO, 10)
	# the door on the west wall: frame, wooden panel with a frosted glass insert; corridor behind it
	_box(Vector3(0.42, 2.3, 0.1), WOOD, o + Vector3(-3.7, 1.15, 0.95))
	_box(Vector3(0.42, 2.3, 0.1), WOOD, o + Vector3(-3.7, 1.15, 2.65))
	_box(Vector3(0.42, 0.1, 1.8), WOOD, o + Vector3(-3.7, 2.25, 1.8))
	_door_hinge = Node3D.new()
	_door_hinge.position = o + Vector3(-3.7, 0, 1.0)
	add_child(_door_hinge)
	var panel := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(0.08, 2.2, 1.6)
	panel.mesh = pb
	panel.material_override = ToonMaterial.make(WOOD)
	panel.position = Vector3(0, 1.1, 0.8)
	_door_hinge.add_child(panel)
	var glass := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(0.1, 1.8, 1.3)
	glass.mesh = gb
	var gm := StandardMaterial3D.new()
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.albedo_color = Color(0.82, 0.86, 0.92, 0.8)
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.material_override = gm
	glass.position = Vector3(0, 1.2, 0.8)
	_door_hinge.add_child(glass)
	var knob := MeshInstance3D.new()
	var kb := SphereMesh.new()
	kb.radius = 0.04
	kb.height = 0.08
	knob.mesh = kb
	knob.material_override = ToonMaterial.make(BRASS, Color.BLACK, 0.0, false)
	knob.position = Vector3(0.06, 1.0, 1.45)
	_door_hinge.add_child(knob)
	# corridor behind the door is backlit by the big stairwell window, so the figure reads as a silhouette
	_box(Vector3(2.4, 0.02, 3.4), Color("8a8a80"), o + Vector3(-4.9, 0.01, 1.8), Vector3.ZERO, false)
	_glow_box(Vector3(0.1, 3.2, 3.4), GLASS_BACKLIT, 1.3, o + Vector3(-5.4, 1.6, 1.8))
	for dz in [-0.6, 0.6]:
		_box(Vector3(0.14, 3.2, 0.06), Color("3a3a3c"), o + Vector3(-5.35, 1.6, 1.8 + dz), Vector3.ZERO, false)
	_box(Vector3(0.14, 0.06, 3.4), Color("3a3a3c"), o + Vector3(-5.35, 1.6, 1.8), Vector3.ZERO, false)
	for i in range(5):
		_box(Vector3(0.6, 0.16, 1.0), Color("6a6a62"), o + Vector3(-4.4 - i * 0.3, -0.9 + i * 0.16, 2.9), Vector3.ZERO, false)
	_door_shadow = _shadow_figure(true)
	_door_shadow.rotation_degrees = Vector3(0, 90, 0)
	add_child(_door_shadow)


## 16x12 pixel television picture: a studio guest in a white collar on a blue set, caption bar below.
func _tv_texture() -> ImageTexture:
	var rows := [
		"BBBBBBBBBBBBBBBB",
		"BBBBBBbbbbBBBBBB",
		"BBBBBbSSSSbBBBBB",
		"BBBBBBSSSSBBBBBB",
		"BBBBBBSESEBBBBBB",
		"BBBBBBBSSBBBBBBB",
		"BBBBBKWWWWKBBBBB",
		"BBBBKKKWWKKKBBBB",
		"BBBKKKKKKKKKKBBB",
		"WWWWWWWWWWWWWWWW",
		"WBBWBBBWBWBBBWBW",
		"WWWWWWWWWWWWWWWW",
	]
	var colors := {"B": Color("2a4a9a"), "b": Color("1a2a6a"), "S": Color("e0b898"), "E": Color("2a1a14"), "K": Color("14141c"), "W": Color("f2f2f2")}
	var img := Image.create(16, 12, false, Image.FORMAT_RGBA8)
	for y in range(12):
		for x in range(16):
			img.set_pixel(x, y, colors[rows[y][x]])
	return ImageTexture.create_from_image(img)


## 12x16 pixel portrait: white cassock and zucchetto on a dark red ground.
func _portrait_texture() -> ImageTexture:
	var rows := [
		"............",
		"....WWWW....",
		"...WWWWWW...",
		"...SSSSSS...",
		"...SSSSSS...",
		"...SESSES...",
		"...SSSSSS...",
		"....SSSS....",
		"..WWWSSWWW..",
		".WWWWWWWWWW.",
		".WWWWWWWWWW.",
		".WWWWGWWWWW.",
		".WWWWGWWWWW.",
		".WWWWWWWWWW.",
		".WWWWWWWWWW.",
		".WWWWWWWWWW.",
	]
	var colors := {".": Color("5a1a1a"), "W": Color("f2f0ea"), "S": Color("e0b898"), "E": Color("2a1a14"), "G": Color("c9a227")}
	var img := Image.create(12, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(12):
			img.set_pixel(x, y, colors[rows[y][x]])
	return ImageTexture.create_from_image(img)
