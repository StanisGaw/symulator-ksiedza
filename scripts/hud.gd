extends CanvasLayer
## Minimal HUD at the internal 320x180 resolution: day, clock, energy.

@export var sun_path: NodePath
@export var player_path: NodePath

@onready var _label: Label = $Label
var _sun: Node
var _player: Node


func _ready() -> void:
	_sun = get_node_or_null(sun_path)
	_player = get_node_or_null(player_path)
	_label.add_theme_font_size_override("font_size", 8)


func _process(_delta: float) -> void:
	if _sun == null or _player == null:
		return
	_label.text = "Dzien %d   %s   Energia %d%%   [T] szybciej" % [_sun.day, _sun.clock_text(), int(_player.energy)]
