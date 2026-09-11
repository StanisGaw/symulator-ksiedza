class_name ActivityScene
extends Node3D
## Krótkie sceny czynności: zamiatanie, sprzątanie, spowiedź, czytanie brewiarza i sen.
## Jeden reżyser na lokację. Miejsca akcji podaje lokacja przez _spot(), więc ta sama
## scena wygląda inaczej na placu i w kościele. Każdą można pominąć.

const WALK_SPEED := 3.2
## Jedno pociągnięcie miotłą. Ruch prowadzimy punktem styku szczotki z ziemią, bo to on
## ma się zachowywać sensownie: w przód szczotka sunie po ziemi tak daleko, jak sięgają
## ręce, a w drodze powrotnej ksiądz ją lekko unosi i podnosi kij, przez co dłonie na
## moment zrównują się wysokością. Kotwica i chwyty wynikają z tego, a stawy układa IK.
const SWEEP_SPEED := 3.4
## Zasięg pociągnięcia w przód i w tył, licząc od położenia spoczynkowego szczotki.
const SWEEP_PUSH := 0.22
## O ile szczotka odrywa się od ziemi i o ile stopni kładzie się kij w drodze powrotnej.
## Kij jest sztywną dźwignią o ramieniu 1.68, więc każdy stopień położenia kija przesuwa
## dłonie o kilka centymetrów: powyżej ośmiu stopni dolny chwyt ucieka lewej ręce poza
## zasięg. Dlatego ręce zrównują się wysokością tylko częściowo.
const SWEEP_LIFT := 0.12
const SWEEP_TILT := 8.0
## Ile stopni tułów odprowadza wymach - tylko tyle, żeby ksiądz nie stał jak słup.
const SWEEP_BODY_YAW := 0.06
## Ile kija wystaje ponad wyższą dłoń; reszta długości idzie w dół, do główki. Końcówka
## jest krótka, bo dłuższa podjeżdżała księdzu pod pachę: przy 0.4 mijała ją o 7 cm, przy
## 0.12 o 12. Skracając ją, skracamy o tyle samo całą miotłę, żeby część pod dłońmi
## została ta sama i szczotka dalej dotykała ziemi.
const BROOM_GRIP := 0.12
## Odstęp między dłońmi na kiju. Szerzej rozstawione dłonie wyglądają lepiej, ale dolny
## chwyt ucieka wtedy lewej ręce poza zasięg na końcu pociągnięcia.
const BROOM_SPREAD := 0.42
## Połowa grubości główki, czyli o ile jej środek jest nad punktem styku z ziemią.
const BROOM_HEAD_HALF := 0.08
## Brewiarz: gdzie wisi przed siedzącym księdzem i jak szeroko rozstawione są na nim dłonie.
## Trzymamy go tak samo jak miotłę - na węźle rekwizytów, a nie w jednej dłoni - bo wtedy
## jego położenie nie zależy od tego, jak akurat ułożona jest ręka.
const BOOK_POS := Vector3(0.0, 1.18, 0.46)
const BOOK_GRIP := 0.2
## Przy brewiarzu łokcie opadają wzdłuż żeber, a nie sterczą na boki jak przy miotle.
const BOOK_ELBOW_POLE := Vector3(0.25, -1.5, 0.15)

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
var _kneeling := false
## Ułożenie miotły: kąt kija do pionu, skręt w bok i długość. Miotła wisi na węźle
## rekwizytów, który nie pochyla się razem z tułowiem, więc kąt liczy się wprost do ziemi.
## Kotwica to punkt, w którym kij przechodzi przez wyższą (prawą) dłoń - reszta pozy
## wynika z niej, bo dłonie dostają go jako cel, a stawy układa IK w player.gd.
## debug: --broom=34.4,-35.2,1.861 nadpisuje kąt, skręt i długość.
var broom_tilt := 34.4
var broom_yaw := -35.2
var broom_length := 1.861
var broom_anchor := Vector3(0.24, 1.456, 0.402)
var _broom_node: Node3D
## Punkt styku szczotki z ziemią w spoczynku i kierunek, w którym ksiądz pcha miotłę.
var _brush_base := Vector3.ZERO
var _push_dir := Vector3.FORWARD
var _zoom_before := 14.0


func _ready() -> void:
	add_to_group("activity_scene")
	Game.cutscene_skip.connect(_skip)


func start(def: Dictionary) -> void:
	var scene: Dictionary = def.get("scene", {})
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--broom="):
			var parts := arg.trim_prefix("--broom=").split(",", false)
			if parts.size() == 3:
				broom_tilt = float(parts[0])
				broom_yaw = float(parts[1])
				broom_length = float(parts[2])
	kind = str(scene.get("kind", ""))
	length = float(scene.get("seconds", 4.0))
	elapsed = 0.0
	_kneeling = false
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
			_player.hold_two_handed(_book())
			_player.reach_hands(BOOK_POS + Vector3(BOOK_GRIP, -0.05, -0.04),
				BOOK_POS + Vector3(-BOOK_GRIP, -0.05, -0.04),
				BOOK_ELBOW_POLE, BOOK_ELBOW_POLE)
		"sleep":
			_start_sleep()
		"funeral":
			_start_funeral()
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
	_broom_node = _broom()
	_player.hold_two_handed(_broom_node)
	# punkt styku szczotki liczony z ustawienia spoczynkowego; to on prowadzi animację
	var down := _stick_dir(broom_tilt)
	_brush_base = (broom_anchor + down * (broom_length - BROOM_GRIP - 0.06)
		- Vector3(0, BROOM_HEAD_HALF, 0))
	# pionowy kij (np. z --broom=0,...) nie ma poziomego kierunku, więc pchamy w przód
	var flat := Vector3(down.x, 0, down.z)
	_push_dir = flat.normalized() if flat.length() > 0.001 else Vector3.FORWARD
	_run_sweep(0.0)
	# miotła stojąca w lokacji znika, bo to właśnie ją ksiądz wziął do ręki
	for node in get_tree().get_nodes_in_group("prop_broom"):
		node.visible = false


## Miotła jako jedna bryła: kij i główka są dziećmi tego samego węzła, więc nie da się
## ich rozjechać. Węzeł wisi na rekwizytach księdza, bo miotła trzymana oburącz nie może
## dyndać u jednej dłoni - to ona wyznacza chwyty, a ręce się do nich dopasowują.
func _broom() -> Node3D:
	var root := Node3D.new()
	root.position = broom_anchor
	# węzeł rekwizytów nie jest pochylony, więc kąt kija to wprost kąt do pionu
	root.rotation_degrees = Vector3(-broom_tilt, broom_yaw, 0)
	var length := broom_length
	var stick := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	# grubszy niż prawdziwy trzonek, żeby przy 320x180 nie znikał między pikselami
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.04
	cyl.height = length
	cyl.radial_segments = 5
	stick.mesh = cyl
	stick.material_override = ToonMaterial.make(Palette.TRUNK)
	stick.position = Vector3(0, BROOM_GRIP - length / 2.0, 0)
	root.add_child(stick)
	var head := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.38, 0.16, 0.14)
	head.mesh = box
	head.material_override = ToonMaterial.make(Palette.CROSS)
	# tuż pod końcem kija, żeby główka trzymała się trzonka; obrót zwrotny kładzie ją płasko
	head.position = Vector3(0, BROOM_GRIP - length + 0.06, 0.02)
	head.rotation_degrees = Vector3(broom_tilt, 0, 0)
	root.add_child(head)
	return root


func _book() -> Node3D:
	var root := Node3D.new()
	root.position = BOOK_POS
	root.rotation_degrees = Vector3(-24, 0, 0)
	var cover := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.04, 0.22)
	cover.mesh = box
	cover.material_override = ToonMaterial.make(Palette.BOOK_A)
	root.add_child(cover)
	var pages := MeshInstance3D.new()
	var page_box := BoxMesh.new()
	page_box.size = Vector3(0.27, 0.03, 0.19)
	pages.mesh = page_box
	pages.material_override = ToonMaterial.make(Palette.PAPER)
	pages.position = Vector3(0, 0.035, -0.01)
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


## Pogrzeb: trumna nad grobem, żałobnicy w półkolu, ksiądz przy głowie grobu.
## Klęka w połowie sceny, ludzie stoją ze spuszczonymi głowami.
func _start_funeral() -> void:
	var grave := _spot("grave")
	_player.global_position = _spot("grave_priest") + Vector3(0, 1.1, 0)
	_player.face(Vector3(0, 0, -1))
	var coffin := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.5, 1.9)
	coffin.mesh = box
	coffin.material_override = ToonMaterial.make(Palette.DESK)
	coffin.position = grave + Vector3(0, 0.55, 0)
	add_child(coffin)
	people.append({"node": coffin, "state": "prop"})
	for i in 7:
		# półkole od strony bramy, żeby nikt nie stał w cudzym nagrobku
		var a := PI * 0.15 + PI * 0.7 * float(i) / 6.0
		var node := Person.make(500 + i)
		node.position = grave + Vector3(cos(a) * 2.0, 0, sin(a) * 2.0 + 0.3)
		node.rotation.y = atan2(grave.x - node.position.x, grave.z - node.position.z)
		node.scale = Vector3(1, 0.96, 1)
		add_child(node)
		people.append({"node": node, "state": "mourn", "phase": float(i)})


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
		"funeral":
			_run_funeral()
	if elapsed >= length:
		_finish()


## Kierunek kija w dół dla zadanego kąta do pionu; skręt w bok jest stały.
func _stick_dir(tilt: float) -> Vector3:
	return Basis.from_euler(Vector3(deg_to_rad(-tilt), deg_to_rad(broom_yaw), 0)) * Vector3.DOWN


## Jedno pociągnięcie miotłą: szczotka sunie po ziemi w przód i w tył, a w drodze powrotnej
## odrywa się i kij się kłada. Z położenia szczotki wynika kotwica, a z niej punkty chwytu,
## które dostają dłonie - ręce nadążają za nimi, zginając i prostując łokcie, więc ruch
## wychodzi z ramion, a nie ze skręcania całego księdza.
func _run_sweep(_delta: float) -> void:
	var phase := elapsed * SWEEP_SPEED
	var swing := sin(phase)
	# cosinus mówi, w którą stronę jedzie miotła; ujemny to droga powrotna
	var back := maxf(0.0, -cos(phase))
	var down := _stick_dir(broom_tilt + SWEEP_TILT * back)
	var contact := _brush_base + _push_dir * (swing * SWEEP_PUSH) + Vector3(0, SWEEP_LIFT * back, 0)
	# kij jest sztywny, więc z punktu styku wynika, gdzie musi być kotwica, a z niej chwyty
	var anchor := (contact + Vector3(0, BROOM_HEAD_HALF, 0)
		- down * (broom_length - BROOM_GRIP - 0.06))
	_broom_node.position = anchor
	_broom_node.rotation_degrees = Vector3(-(broom_tilt + SWEEP_TILT * back), broom_yaw, 0)
	_player.reach_hands(anchor, anchor + down * BROOM_SPREAD)
	# tułów tylko towarzyszy ruchowi rąk
	_player.set_model_yaw(_base_yaw + swing * SWEEP_BODY_YAW)


func _run_funeral() -> void:
	var t := elapsed / length
	var should_kneel := t > 0.3 and t < 0.75
	if should_kneel != _kneeling:
		_kneeling = should_kneel
		_player.set_pose("kneel" if _kneeling else "stand")
	for p in people:
		if p["state"] == "mourn":
			# lekkie kołysanie, każdy w swoim tempie
			p["node"].position.y = sin(elapsed * 1.3 + float(p["phase"])) * 0.02


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
	_broom_node = null
	if _player:
		_player.set_pose("stand")
		_player.bob(0.0)
		_player.drop_props()
		_player.global_position = _return_pos
		if _player is CharacterBody3D:
			(_player as CharacterBody3D).velocity = Vector3.ZERO
	for node in get_tree().get_nodes_in_group("prop_broom"):
		node.visible = true
	if _rig:
		_rig.set_zoom(_zoom_before)
	Game.finish_cutscene()
