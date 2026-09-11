extends LocationBase
## Church interior. Dollhouse view: only the north and west walls are visible, the other two are invisible colliders.

const MASS_DIRECTOR := preload("res://scripts/mass_director.gd")
const W := 10.0
const D := 16.0


## Wystrój zależny od okresu liturgicznego: wieniec i szopka zimą, zasłonięty krzyż
## w Wielkim Poście, kwiaty i paschał w Wielkanoc.
func _build_season() -> void:
	match Game.season():
		Calendar.ADVENT:
			_build_advent()
		Calendar.CHRISTMAS:
			_build_christmas()
		Calendar.LENT:
			_build_lent()
		Calendar.EASTER:
			_build_easter()


func _build_lent() -> void:
	# krzyż zasłonięty fioletem, ołtarz bez kwiatów, świece zgaszone
	_box(Vector3(1.1, 1.9, 0.1), Palette.CLOTH_VIOLET, Vector3(0, 3.5, -D / 2 + 0.32), Vector3(0, 0, 4))
	_box(Vector3(0.6, 0.5, 0.06), Palette.CLOTH_VIOLET, Vector3(-2.4, 3.0, -D / 2 + 0.05), Vector3(0, 0, -6))


func _build_easter() -> void:
	# paschał przy ołtarzu i kwiaty dookoła
	_cyl(0.09, 0.11, 1.5, Palette.CANDLE, Vector3(-1.7, 0.75, -6.0), Vector3.ZERO, 8)
	_glow_box(Vector3(0.14, 0.18, 0.14), Palette.CANDLE, 3.0, Vector3(-1.7, 1.6, -6.0))
	for k in range(6):
		var a := PI * float(k) / 5.0
		var pos := Vector3(cos(a) * 2.0, 0.18, -5.3 + sin(a) * 0.5)
		_cyl(0.2, 0.24, 0.36, Palette.CANOPY_SUMMER, pos, Vector3.ZERO, 6)
		_sphere(0.13, Palette.FLOWER if k % 2 == 0 else Palette.CANDLE, pos + Vector3(0, 0.3, 0), false)


func _build_christmas() -> void:
	_build_tree_and_crib()


func _build_advent() -> void:
	var lit: int = Calendar.advent_candles(Game.day)
	_cyl(0.5, 0.55, 0.12, Palette.CANOPY, Vector3(-2.6, 0.9, -5.2), Vector3.ZERO, 12)
	_cyl(0.08, 0.1, 0.9, Palette.DESK, Vector3(-2.6, 0.45, -5.2), Vector3.ZERO, 6)
	for k in range(4):
		var a := TAU * float(k) / 4.0
		var pos := Vector3(-2.6 + cos(a) * 0.42, 1.18, -5.2 + sin(a) * 0.42)
		_cyl(0.05, 0.05, 0.36, Palette.CONFESSIONAL if k >= lit else Palette.CANDLE, pos, Vector3.ZERO, 6)
		if k < lit:
			_glow_box(Vector3(0.1, 0.1, 0.1), Palette.CANDLE, 2.5, pos + Vector3(0, 0.24, 0))
	if Calendar.feast_name(Game.day).begins_with("Wigilia"):
		# choinkę stawia się w Wigilię, jeszcze w Adwencie
		_build_tree_and_crib()


## Choinka i szopka pod ścianą, od Wigilii do końca okresu Bożego Narodzenia.
func _build_tree_and_crib() -> void:
	_cyl(0.0, 0.9, 2.4, Palette.CANOPY, Vector3(-3.4, 1.2, -4.4), Vector3.ZERO, 8)
	_cyl(0.0, 0.6, 1.2, Palette.CANOPY_2, Vector3(-3.4, 2.0, -4.4), Vector3.ZERO, 8)
	for k in range(6):
		_sphere(0.08, Palette.CANDLE if k % 2 == 0 else Palette.FLOWER, Vector3(-3.4 + cos(k * 1.1) * 0.6, 0.9 + k * 0.22, -4.4 + sin(k * 1.1) * 0.6), false)
	# szopka pod ścianą: skrzynia, daszek i ciepłe światło w środku
	_box(Vector3(1.4, 0.5, 1.0), Palette.DESK, Vector3(-3.2, 0.25, -2.6))
	_box(Vector3(1.7, 0.12, 1.3), Palette.BOARD, Vector3(-3.2, 0.62, -2.6), Vector3(0, 0, 7))
	_glow_box(Vector3(0.5, 0.34, 0.42), Palette.CANDLE, 1.8, Vector3(-3.0, 0.4, -2.3))
	_omni(Vector3(-3.0, 0.9, -2.2), Color("ffc070"), 1.8, 4.0)
	_collider(Vector3(1.5, 1, 1.1), Vector3(-3.2, 0.5, -2.6))


func _ready() -> void:
	var ambient: Array = WorldState.church_ambient()
	_environment(Color("0e0d12"), ambient[0], ambient[1])
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(W, D)
	_mesh(floor_mesh, ToonMaterial.make(Palette.FLOOR_STONE, Color.BLACK, 0.0, false), Vector3.ZERO)
	_collider(Vector3(W, 1, D), Vector3(0, -0.5, 0))
	# visible walls (north, west) and invisible ones (south, east)
	var wall := WorldState.wall_color(Palette.WALL_INT)
	_box(Vector3(W + 0.4, 6, 0.4), wall, Vector3(0, 3, -D / 2 - 0.2))
	_box(Vector3(0.4, 6, D), WorldState.wall_color(Palette.WALL_INT_DARK), Vector3(-W / 2 - 0.2, 3, 0))
	_collider(Vector3(W + 0.4, 6, 0.4), Vector3(0, 3, -D / 2 - 0.2))
	_collider(Vector3(0.4, 6, D), Vector3(-W / 2 - 0.2, 3, 0))
	_collider(Vector3(W, 6, 0.4), Vector3(0, 3, D / 2 + 0.2))
	_collider(Vector3(0.4, 6, D), Vector3(W / 2 + 0.2, 3, 0))
	add_child(MASS_DIRECTOR.new())
	# windows on the west wall glow warm
	for z in [-5.0, -2.0, 1.0, 4.0]:
		_glow_box(Vector3(0.2, 1.6, 0.7), Palette.WINDOW, 0.7, Vector3(-W / 2 + 0.05, 3.2, z))
	if WorldState.condition() == WorldState.BAD and not WorldState.has("roof"):
		# przeciek nad prezbiterium: zaciek na ścianie i wiadro na środku nawy
		_box(Vector3(1.6, 1.8, 0.05), Palette.STAIN, Vector3(-1.6, 4.2, -D / 2 + 0.05), Vector3.ZERO, false)
		_cyl(0.28, 0.22, 0.4, Palette.BUCKET, Vector3(-1.4, 0.2, -4.6), Vector3.ZERO, 8)
		_box(Vector3(0.9, 0.02, 0.9), Palette.STAIN, Vector3(-1.4, 0.02, -4.6), Vector3.ZERO, false)
	if WorldState.has("heating"):
		# grzejniki pod ścianami i cieplejsze światło
		for z in [-4.0, -0.5, 3.0]:
			_box(Vector3(0.22, 0.6, 1.6), Palette.RADIATOR, Vector3(-W / 2 + 0.3, 0.6, z))
		_landmark("heating", Vector3(-W / 2 + 0.3, 0.6, -0.5))
	if WorldState.has("sound"):
		# kolumny przy prezbiterium i mikrofon przy ołtarzu
		for side in [-1.0, 1.0]:
			_box(Vector3(0.4, 0.9, 0.35), Palette.SPEAKER, Vector3(side * 3.4, 2.6, -5.6), Vector3(0, side * -12, 0))
		_cyl(0.03, 0.03, 1.2, Palette.SPEAKER, Vector3(1.6, 0.6, -5.6), Vector3.ZERO, 5)
		_sphere(0.08, Palette.SPEAKER, Vector3(1.6, 1.24, -5.6), false)
		_landmark("sound", Vector3(0, 2.6, -5.6))
	if not WorldState.done_today("clean_church"):
		# naniesione od drzwi: kurz, liście, ogarki świec i papierki po kartkach z ogłoszeniami
		for i in range(7):
			_box(Vector3(0.4, 0.02, 0.3), Palette.STAIN, Vector3(-3.0 + float((i * 17) % 7), 0.02, 4.0 + float((i * 23) % 4)), Vector3(0, i * 24, 0), false)
		for i in range(5):
			_cyl(0.035, 0.035, 0.06, Palette.CANDLE, Vector3(-2.2 + float((i * 29) % 6), 0.03, 1.2 + float((i * 19) % 7)), Vector3(90, float(i * 41), 0), 6)
		for i in range(4):
			_box(Vector3(0.14, 0.015, 0.1), Palette.PAPER, Vector3(-1.4 + float((i * 31) % 5), 0.015, 2.6 + float((i * 23) % 5)), Vector3(0, float(i * 37), 0), false)
	# altar
	_box(Vector3(2.6, 1.0, 1.1), WorldState.altar_cloth(), Vector3(0, 0.5, -6.3))
	_box(Vector3(3.6, 0.3, 2.4), Palette.FLOOR_WOOD, Vector3(0, 0.15, -6.0))
	_collider(Vector3(2.8, 1.2, 1.3), Vector3(0, 0.6, -6.3))
	for x in [-0.9, 0.9]:
		_cyl(0.05, 0.05, 0.5, Palette.CANDLE, Vector3(x, 1.25, -6.3), Vector3.ZERO, 6)
		# w zaniedbanej parafii pali się tylko jedna świeca
		if WorldState.condition() == WorldState.BAD and x < 0.0:
			continue
		_glow_box(Vector3(0.12, 0.12, 0.12), Palette.CANDLE, 2.5, Vector3(x, 1.55, -6.3))
	_box(Vector3(0.14, 1.6, 0.14), Palette.CROSS, Vector3(0, 3.4, -D / 2 + 0.25))
	_box(Vector3(0.9, 0.14, 0.14), Palette.CROSS, Vector3(0, 3.9, -D / 2 + 0.25))
	_omni(Vector3(0, 2.5, -5.5), Color("ffb060"), 2.2, 9.0)
	_omni(Vector3(0, 3.0, 2.0), Color("d8c8a0"), 1.6 if WorldState.has("heating") else 1.2, 10.0)
	_activity(Vector3(0, 1, -5.0), Vector3(3.2, 2, 1.4), "mass")
	_build_season()
	# pews
	for row in range(6):
		var z := -3.0 + row * 1.4
		for x in [-2.6, 2.6]:
			_box(Vector3(3.4, 0.45, 0.4), Palette.PEW, Vector3(x, 0.45, z))
			_box(Vector3(3.4, 0.5, 0.08), Palette.PEW, Vector3(x, 0.9, z - 0.18))
			_box(Vector3(0.08, 0.45, 0.4), Palette.PEW, Vector3(x - 1.66, 0.22, z))
			_box(Vector3(0.08, 0.45, 0.4), Palette.PEW, Vector3(x + 1.66, 0.22, z))
			_collider(Vector3(3.4, 1, 0.5), Vector3(x, 0.5, z))
	# confessional by the west wall
	_box(Vector3(1.4, 2.4, 1.2), Palette.CONFESSIONAL, Vector3(-4.1, 1.2, 5.2))
	_box(Vector3(0.5, 1.6, 0.05), Palette.WALL_INT, Vector3(-3.38, 1.1, 5.2))
	_collider(Vector3(1.4, 2.4, 1.2), Vector3(-4.1, 1.2, 5.2))
	_activity(Vector3(-2.9, 1, 5.2), Vector3(1.4, 2, 1.6), "confession")
	# bucket and broom by the door
	_cyl(0.28, 0.22, 0.4, Palette.BUCKET, Vector3(3.6, 0.2, 6.8), Vector3.ZERO, 8)
	_cyl(0.03, 0.03, 1.4, Palette.TRUNK, Vector3(4.0, 0.7, 6.6), Vector3(0, 0, -12), 5)
	_activity(Vector3(3.6, 1, 6.6), Vector3(1.6, 2, 1.4), "clean_church")
	# door out
	_box(Vector3(1.6, 2.4, 0.2), Palette.DOOR, Vector3(0, 1.2, D / 2 + 0.1))
	_door(Vector3(0, 1, D / 2 - 0.9), Vector3(2.4, 2, 1.4), "Wyjdź na zewnątrz", "outside", "church_door")
	_spawn("door", Vector3(0, 0, D / 2 - 2.2))
	_spot("sweep_a", Vector3(-2.0, 0, 5.4))
	_spot("sweep_b", Vector3(2.4, 0, 0.4))
	_spot("confession_seat", Vector3(-3.2, 0, 5.2))
	_spot("confession_kneel", Vector3(-2.1, 0, 5.4))
	_spot("scene_door", Vector3(0, 0, 6.6))
