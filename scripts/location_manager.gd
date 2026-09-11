extends SubViewport
## Owns the persistent player and camera, swaps location scenes and places the player at spawn markers.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const REVEAL_ZOOM := 9.0
const REVEAL_SECONDS := 2.6

@export var start_location := "outside"
@export var start_spawn := "start"

## debug: --zoom=20 oddala kamerę do zrzutów
var _zoom := 14.0
var _reveal_pending := false
var _focus: Node3D

var player: CharacterBody3D
var rig: Node3D
var current: Node3D
var _rebuild_pending := false


func _ready() -> void:
	# debug: --hires renderuje świat w pełnej rozdzielczości zamiast w 320x180 upscalowanych
	# całkowitą krotnością. Do oglądania animacji i pozy, nie do grania.
	# rozmiaru SubViewportu nie ustawiamy wprost: przy stretch w kontenerze i tak liczy go
	# kontener, wystarczy zdjąć pomniejszenie, żeby świat renderował się w pełnym oknie
	var container := get_parent() as SubViewportContainer
	if container and OS.get_cmdline_user_args().has("--hires"):
		container.stretch_shrink = 1
		container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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
	Game.world_changed.connect(_rebuild)
	Game.cutscene_ended.connect(_on_cutscene_ended)
	# debug: godot --path . -- --loc=church  (spawn "door")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--loc="):
			start_location = arg.trim_prefix("--loc=")
			start_spawn = "door"
		elif arg.begins_with("--zoom="):
			_zoom = float(arg.trim_prefix("--zoom="))
	go_to(start_location, start_spawn)
	var saved := Game.saved_day()
	if saved > 0:
		# interfejs jest gotowy dopiero po tym węźle, więc okno prosimy na koniec klatki
		Game.call_deferred("request_modal", "continue", {"day": saved})


## Przebudowuje bieżącą lokację bez ruszania gracza. Lokacje budują się z brył
## i czytają stan parafii, więc to jedyny sposób, żeby zmiana stanu była widoczna od razu.
func _rebuild() -> void:
	if _rebuild_pending:
		return
	# jedno przejście dnia potrafi zmienić stan kilka razy, więc przebudowa raz na klatkę
	_rebuild_pending = true
	call_deferred("_flush_rebuild")


func _flush_rebuild() -> void:
	if not _rebuild_pending:
		return
	if not current:
		_rebuild_pending = false
		return
	if Game.cutscene:
		# lokacja trzyma reżysera sceny, więc przebudowa czeka na koniec scenki
		return
	_rebuild_pending = false
	go_to(Game.location, "", true)


func _on_cutscene_ended() -> void:
	if _rebuild_pending:
		# scenka kończy się razem ze zmianą lokacji, więc przebudowa czeka na koniec klatki
		call_deferred("_flush_rebuild")


func go_to(location_id: String, spawn: String, keep_pos: bool = false) -> void:
	var kept := player.global_position
	if current:
		# usuwamy od razu, żeby stare obiekty interakcji nie mieszały się z nowymi
		remove_child(current)
		current.queue_free()
		current = null
	var packed: PackedScene = load("res://scenes/locations/%s.tscn" % location_id)
	current = packed.instantiate()
	add_child(current)
	# każda lokacja dostaje reżysera krótkich scen czynności
	current.add_child(ActivityScene.new())
	var pos := kept - Vector3(0, 1.1, 0)
	if not keep_pos:
		var marker := current.find_child("Spawn_" + spawn, true, false) as Marker3D
		pos = marker.global_position if marker else Vector3.ZERO
	player.global_position = pos + Vector3(0, 1.1, 0)
	player.velocity = Vector3.ZERO
	player.clear_targets()
	if _focus != null and not keep_pos:
		# zmiana lokacji przerywa najazd; przebudowa w miejscu pozwala mu trwać dalej
		_end_reveal()
	if _focus == null:
		rig.set_zoom(_zoom, true)
		rig.set_offset(Vector3.ZERO, true)
		rig.snap()
	Game.location = location_id
	Game.set_prompt("")
	# na koniec klatki, bo przy starcie gry interfejs jest gotowy dopiero po tym węźle
	call_deferred("_maybe_reveal")


func _process(_delta: float) -> void:
	# najazd odłożony na bok czeka, aż gracz znów patrzy na świat
	if _reveal_pending and not Game.modal_open and not Game.cutscene:
		_maybe_reveal()


## Gdy w lokacji pojawiło się coś, czego gracz jeszcze nie widział, kamera to pokazuje.
func _maybe_reveal() -> void:
	if not (current is LocationBase):
		_reveal_pending = false
		return
	var id := Game.unseen((current as LocationBase).landmarks.keys())
	if id == "":
		_reveal_pending = false
		return
	if Game.modal_open or Game.cutscene:
		# okno albo scenka zasłoniłyby najazd, a pokazujemy każdą zmianę tylko raz
		_reveal_pending = true
		return
	_reveal_pending = false
	Game.mark_seen(id)
	_reveal((current as LocationBase).landmarks[id], id)


func _reveal(pos: Vector3, id: String) -> void:
	_end_reveal()
	# kamera celuje w stały punkt, a nie w gracza z przesunięciem, więc obiekt nie ucieka z kadru
	_focus = Node3D.new()
	_focus.position = pos
	add_child(_focus)
	var shown := _focus
	rig.target = _focus
	rig.set_zoom(REVEAL_ZOOM)
	Game.toast.emit(WorldState.reveal_text(id))
	await get_tree().create_timer(REVEAL_SECONDS).timeout
	if _focus == shown:
		_end_reveal()


func _end_reveal() -> void:
	if _focus == null:
		return
	_focus.queue_free()
	_focus = null
	rig.target = player
	rig.set_zoom(_zoom)
