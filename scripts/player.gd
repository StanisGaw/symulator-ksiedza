extends CharacterBody3D
## The priest. Movement is relative to the fixed camera. A sensor area finds nearby interactables.

@export var speed: float = 4.0
@export var camera_yaw_degrees: float = 35.0

## Poza rąk bierze się z tego, gdzie mają trafić dłonie, a nie z wpisanych kątów stawów:
## reach_hands() liczy je IK dwóch kości. Dzięki temu scena zamiatania może przesuwać
## miotłę, a ręce same się do niej dostosowują - zginają i prostują w łokciu.
## PHONE_HAND to jedyny cel wpisany na stałe: dłoń z telefonem przy twarzy.
const PHONE_HAND := Vector3(0.3, 0.65, 0.45)
## W którą stronę odchyla się łokieć, osobno dla każdej ręki, bo robią co innego. Prawa
## trzyma kij wysoko przy piersi i przy odchyleniu na zewnątrz sterczała łokciem na bok
## (0.6 m poza obrys sutanny), więc jej łokieć opada wzdłuż ciała. Lewa sięga po kij przed
## sobą i tam odchylenie do tyłu wpychało łokieć w sutannę, więc idzie na zewnątrz i w przód.
const ELBOW_POLE_RIGHT := Vector3(0.2, -1.4, 0.3)
const ELBOW_POLE_LEFT := Vector3(1.0, -0.2, 0.6)
## Wysokość, wokół której ksiądz zgina się w pasie. Pochyla się węzeł piersi, a nie cała
## sylwetka: przy obrocie wokół stóp ręce wyjeżdżały metr przed ciało i żadna miotła nie
## dawała się złapać po ludzku.
const CHEST_Y := 1.5
## Wymiary ręki: bark względem węzła piersi oraz długość ramienia i przedramienia. Razem
## dają zasięg 1.12 przy wzroście 2.8, czyli 40 procent - tyle, ile u człowieka. Pierwsza
## wersja miała rękę z jednej sztywnej bryły o zasięgu 0.58 i dolna dłoń nie sięgała kija.
const SHOULDER := Vector3(0.42, 0.45, -0.02)
const UPPER_ARM := 0.58
const FOREARM := 0.54

var _model: Node3D
## Bryły księdza wiszą na osobnym węźle, którego początek jest na wysokości stóp.
## Tu trzymamy nogi i sutannę oraz skalowanie całej sylwetki; pochylenia idą na _chest.
var _body: Node3D
## Wszystko od pasa w górę wisi tutaj: tors, głowa i ręce. Ten węzeł się pochyla.
var _chest: Node3D
## Ręce jako łańcuch bark -> łokieć -> dłoń, po jednym węźle na staw. Obrót barku bierze
## ze sobą całą rękę, obrót łokcia tylko przedramię z dłonią.
var _arm_right: Node3D
var _arm_left: Node3D
var _elbow_right: Node3D
var _elbow_left: Node3D
## Rekwizyty trzymane oburącz wiszą tutaj: węzeł stoi tam, gdzie stopy, ale nie pochyla
## się razem z tułowiem, więc kąt miotły liczy się wprost do ziemi.
var _props: Node3D
## Punkty chwytu w dłoniach. Wszystko, co ksiądz trzyma, wisi w prawej, więc jedzie razem
## z ręką zamiast wisieć obok niej w powietrzu; lewa łapie kij miotły niżej.
var _hand_right: Node3D
var _hand_left: Node3D
var _phone: MeshInstance3D
var _nearby: Array[Interactable] = []
var _current: Interactable


func _ready() -> void:
	add_to_group("player")
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	_build_model()
	var sensor := $Sensor as Area3D
	sensor.area_entered.connect(_on_area_entered)
	sensor.area_exited.connect(_on_area_exited)


func face(dir: Vector3) -> void:
	_model.rotation.y = atan2(dir.x, dir.z)


## Obrót modelu wokół pionu, do animacji scen.
func model_yaw() -> float:
	return _model.rotation.y


func set_model_yaw(value: float) -> void:
	_model.rotation.y = value


## Rekwizyt w rękach na czas sceny: miotła, brewiarz. Trzymany przez model,
## więc obraca się razem z księdzem.
func hold(prop: Node3D) -> void:
	drop_props()
	prop.add_to_group("player_prop")
	_hand_right.add_child(prop)


func drop_props() -> void:
	for parent in [_hand_right, _props]:
		for node in parent.get_children():
			if node.is_in_group("player_prop"):
				node.queue_free()


## Rekwizyt trzymany oburącz wisi na węźle rekwizytów, a nie w dłoni: przy dwóch chwytach
## to on decyduje, gdzie jest przedmiot, a dłonie dojeżdżają do niego przez reach_hands().
func hold_two_handed(prop: Node3D) -> void:
	drop_props()
	prop.add_to_group("player_prop")
	_props.add_child(prop)


## Obie dłonie jadą w podane punkty, a stawy układają się same. Punkty są w układzie
## węzła rekwizytów, czyli tam, gdzie scena buduje rekwizyt. Odchylenie łokci można podać,
## bo zależy od czynności: przy miotle idą na boki, przy brewiarzu mają zostać przy żebrach.
func reach_hands(target_right: Vector3, target_left: Vector3,
		pole_right: Vector3 = ELBOW_POLE_RIGHT, pole_left: Vector3 = ELBOW_POLE_LEFT) -> void:
	_reach(_arm_right, _elbow_right, 1, _to_chest(target_right), pole_right)
	_reach(_arm_left, _elbow_left, -1, _to_chest(target_left), pole_left)


## Punkt z układu rekwizytów na układ piersi, w którym wiszą ręce.
func _to_chest(point: Vector3) -> Vector3:
	return _chest.transform.affine_inverse() * (_body.transform.affine_inverse()
		* (_props.transform * point))


func _reach(arm: Node3D, elbow: Node3D, side: int, target: Vector3,
		pole_def: Vector3 = Vector3.ZERO) -> void:
	var shoulder := Vector3(SHOULDER.x * side, SHOULDER.y, SHOULDER.z)
	var to_target := target - shoulder
	var reach := UPPER_ARM + FOREARM
	var dist := clampf(to_target.length(), absf(UPPER_ARM - FOREARM) + 0.01, reach - 0.01)
	var axis := to_target.normalized()
	# twierdzenie cosinusów: długości są dane, więc kąt w barku wynika z odległości celu
	var cos_a := (UPPER_ARM * UPPER_ARM + dist * dist - FOREARM * FOREARM) / (2.0 * UPPER_ARM * dist)
	var angle := acos(clampf(cos_a, -1.0, 1.0))
	if pole_def == Vector3.ZERO:
		pole_def = ELBOW_POLE_RIGHT if side == 1 else ELBOW_POLE_LEFT
	var pole := Vector3(pole_def.x * side, pole_def.y, pole_def.z)
	var perp := pole - axis * pole.dot(axis)
	if perp.length() < 0.001:
		perp = axis.cross(Vector3.RIGHT)
	perp = perp.normalized()
	var elbow_pos := shoulder + (axis * cos(angle) + perp * sin(angle)) * UPPER_ARM
	var hand_pos := shoulder + axis * dist
	var to_elbow := (elbow_pos - shoulder).normalized()
	arm.quaternion = Quaternion(Vector3.DOWN, to_elbow)
	elbow.quaternion = Quaternion(Vector3.DOWN,
		(arm.quaternion.inverse() * (hand_pos - elbow_pos)).normalized())



## Pozy do scen: klęczenie, siedzenie, praca w pochyleniu, leżenie.
func set_pose(pose: String) -> void:
	_model.position.y = 0.0
	_model.rotation.x = 0.0
	_body.rotation.x = 0.0
	_chest.rotation.x = 0.0
	_body.scale = Vector3.ONE
	# telefon tylko na stojąco; w każdej innej pozie ręka opada, bo trzyma coś innego
	_phone.visible = pose == "stand" or pose == ""
	# ręce domyślnie zwisają; na stojąco prawa unosi telefon do twarzy, a przy pracy
	# chwyty ustawia scena przez reach_hands()
	_arm_right.rotation = Vector3.ZERO
	_elbow_right.rotation = Vector3.ZERO
	_arm_left.rotation = Vector3.ZERO
	_elbow_left.rotation = Vector3.ZERO
	if _phone.visible:
		_reach(_arm_right, _elbow_right, 1, PHONE_HAND)
	match pose:
		"kneel":
			_body.scale = Vector3(1, 0.78, 1)
			_chest.rotation.x = deg_to_rad(16)
		"sit":
			_body.scale = Vector3(1, 0.72, 1)
			_chest.rotation.x = deg_to_rad(6)
			_model.position.y = -0.3
		"work":
			# pochylony nad miotłą: zgina się w pasie, więc obraca się węzeł piersi,
			# a nogi i sutanna zostają pionowo. Obrót całego ciała wyrzucałby ręce
			# metr przed stopy i żadna miotła nie dawała się złapać oburącz.
			_body.scale = Vector3(1, 0.94, 1)
			_chest.rotation.x = deg_to_rad(26)
		"lie":
			# całe ciało kładzie się wzdłuż łóżka, głową w stronę poduszki
			_body.scale = Vector3(1, 0.95, 1)
			_model.rotation = Vector3(deg_to_rad(-90), 0, 0)


## Walking bob for cutscenes (the model has no legs yet).
func bob(t: float) -> void:
	_model.position.y = absf(sin(t * 9.0)) * 0.08


func clear_targets() -> void:
	_nearby.clear()
	_current = null


func _physics_process(delta: float) -> void:
	if Game.cutscene:
		velocity = Vector3.ZERO
		return
	var input := Vector2.ZERO
	if not Game.modal_open:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, deg_to_rad(camera_yaw_degrees))
	if dir.length() > 0.0:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(dir.x, dir.z), 12.0 * delta)
		Game.energy = maxf(0.0, Game.energy - 0.4 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_update_target()
	if _current and not Game.modal_open and not Game.cutscene and Input.is_action_just_pressed("interact"):
		_current.activate()


func _on_area_entered(area: Area3D) -> void:
	if area is Interactable:
		_nearby.append(area)


func _on_area_exited(area: Area3D) -> void:
	if area is Interactable:
		_nearby.erase(area)


func _update_target() -> void:
	var best: Interactable = null
	var best_d := INF
	for a in _nearby:
		if not is_instance_valid(a):
			continue
		var d := global_position.distance_to(a.global_position)
		if d < best_d:
			best_d = d
			best = a
	if best != _current:
		_current = best
		Game.set_prompt(best.prompt_text() if best else "")
	elif best:
		Game.set_prompt(best.prompt_text())


# Placeholder priest built from primitives; origin at the feet after the -1.1 offset.
func _build_model() -> void:
	var root := Node3D.new()
	root.position = Vector3(0, -1.1, 0)
	_model.add_child(root)
	_body = root
	_props = Node3D.new()
	_props.position = root.position
	_model.add_child(_props)
	_part(root, _cyl(0.34, 0.52, 1.5), Palette.CASSOCK, Vector3(0, 0.75, 0))
	# od pasa w górę: własny węzeł, żeby pochylenie zginało księdza w pasie
	_chest = Node3D.new()
	_chest.position = Vector3(0, CHEST_Y, 0)
	root.add_child(_chest)
	_part(_chest, _cyl(0.3, 0.34, 0.55), Palette.CASSOCK, Vector3(0, 0.27, 0))
	_part(_chest, _cyl(0.2, 0.2, 0.12), Palette.COLLAR, Vector3(0, 0.59, 0))
	_part(_chest, _cyl(0.12, 0.12, 0.14, 8), Palette.SKIN, Vector3(0, 0.7, 0))
	_part(_chest, _sphere(0.29), Palette.SKIN, Vector3(0, 1.0, 0))
	var hair := _part(_chest, _sphere(0.31), Palette.HAIR, Vector3(0, 1.08, 0))
	hair.scale = Vector3(1, 0.55, 1)
	var arm_r := _build_arm(_chest, 1)
	_arm_right = arm_r[0]
	_elbow_right = arm_r[1]
	_hand_right = arm_r[2]
	var arm_l := _build_arm(_chest, -1)
	_arm_left = arm_l[0]
	_elbow_left = arm_l[1]
	_hand_left = arm_l[2]
	var phone := BoxMesh.new()
	phone.size = Vector3(0.14, 0.26, 0.03)
	# telefon trzyma się dłoni, więc jedzie razem z nią, gdy ręka opada do pracy
	_phone = _part(_hand_right, phone, Palette.PHONE, Vector3(0, 0.12, 0.08), Vector3(-17, 0, 0))
	_phone.material_override = ToonMaterial.make(Palette.PHONE, Palette.PHONE, 0.9)
	var shoe := BoxMesh.new()
	shoe.size = Vector3(0.22, 0.1, 0.34)
	_part(root, shoe, Palette.SHOES, Vector3(-0.16, 0.05, 0.05))
	_part(root, shoe, Palette.SHOES, Vector3(0.16, 0.05, 0.05))


## Ręka jako łańcuch trzech węzłów: bark, łokieć, dłoń. W pozie zerowej zwisa prosto w dół,
## więc każda poza to dwa obroty liczone od pionu. side: 1 prawa ręka, -1 lewa.
func _build_arm(chest: Node3D, side: int) -> Array:
	var shoulder := Node3D.new()
	shoulder.position = Vector3(SHOULDER.x * side, SHOULDER.y, SHOULDER.z)
	chest.add_child(shoulder)
	# kula barku ma promień większy niż odstęp barku od tułowia (0.42 wobec 0.31 promienia
	# torsu), więc wtapia się w niego i nie zostaje szpara między ręką a ciałem
	_part(shoulder, _sphere(0.17), Palette.CASSOCK_SLEEVE, Vector3.ZERO)
	_part(shoulder, _cyl(0.09, 0.09, UPPER_ARM, 8), Palette.CASSOCK_SLEEVE, Vector3(0, -UPPER_ARM / 2.0, 0))
	var elbow := Node3D.new()
	elbow.position = Vector3(0, -UPPER_ARM, 0)
	shoulder.add_child(elbow)
	# kula w stawie zakrywa szczelinę między ramieniem a przedramieniem przy zgięciu
	_part(elbow, _sphere(0.09), Palette.CASSOCK_SLEEVE, Vector3.ZERO)
	_part(elbow, _cyl(0.08, 0.08, FOREARM, 8), Palette.CASSOCK_SLEEVE, Vector3(0, -FOREARM / 2.0, 0))
	var hand := Node3D.new()
	hand.position = Vector3(0, -FOREARM, 0)
	elbow.add_child(hand)
	# dłoń o kilka centymetrów większa, bo przy 320x180 miała ledwie dwa piksele
	_part(hand, _sphere(0.13), Palette.SKIN, Vector3.ZERO)
	return [shoulder, elbow, hand]


func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMaterial.make(color)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _cyl(top: float, bottom: float, height: float, segments: int = 10) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return m


func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 10
	m.rings = 6
	return m
