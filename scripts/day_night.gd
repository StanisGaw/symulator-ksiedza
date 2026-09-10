extends DirectionalLight3D
## Day cycle for the "mroczny" direction: overcast, cold daylight; amber accents at night.
## Time is a fraction of a day: 0.0 = midnight, 0.5 = noon.

signal time_changed(time_of_day: float, day: int)

@export var day_length_seconds: float = 240.0
@export var start_time: float = 0.42
@export var fast_multiplier: float = 12.0
@export var environment_path: NodePath
@export var lamp_paths: Array[NodePath] = []

const SUN_DAY := Color("c9d6ec")
const SUN_DUSK := Color("b08060")
const SUN_NIGHT := Color("6a7ab8")
const SKY_DAY := Color("3a4452")
const SKY_NIGHT := Color("141a26")
const AMBIENT_DAY := Color("8c98aa")
const AMBIENT_NIGHT := Color("3a4458")

var time_of_day: float
var day: int = 1
var _env: Environment


func _ready() -> void:
	time_of_day = start_time
	var we := get_node_or_null(environment_path) as WorldEnvironment
	if we:
		_env = we.environment
	shadow_enabled = true
	_apply()


func _process(delta: float) -> void:
	var mult := fast_multiplier if Input.is_action_pressed("time_faster") else 1.0
	time_of_day += delta / day_length_seconds * mult
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		day += 1
	_apply()
	time_changed.emit(time_of_day, day)


func _apply() -> void:
	# daylight amount: 0 at night, 1 at noon, with dawn ~0.22 and dusk ~0.78
	var daylight := clampf((cos((time_of_day - 0.5) * TAU) + 0.35) / 1.35, 0.0, 1.0)
	var dusk := clampf(1.0 - absf(daylight - 0.35) / 0.35, 0.0, 1.0)
	var col := SUN_NIGHT.lerp(SUN_DAY, daylight).lerp(SUN_DUSK, dusk * 0.6)
	light_color = col
	light_energy = lerpf(0.6, 3.2, daylight)
	var elevation := lerpf(-10.0, 55.0, daylight)
	var azimuth := lerpf(-70.0, 70.0, time_of_day)
	rotation_degrees = Vector3(-elevation, azimuth, 0)
	if _env:
		var sky := SKY_NIGHT.lerp(SKY_DAY, daylight)
		_env.background_color = sky
		_env.fog_light_color = sky
		_env.ambient_light_color = AMBIENT_NIGHT.lerp(AMBIENT_DAY, daylight)
		_env.ambient_light_energy = lerpf(1.2, 2.4, daylight)
	var lamps_on := daylight < 0.45
	for path in lamp_paths:
		var lamp := get_node_or_null(path) as OmniLight3D
		if lamp:
			lamp.light_energy = 4.0 if lamps_on else 0.0


func clock_text() -> String:
	var minutes := int(time_of_day * 24.0 * 60.0)
	return "%02d:%02d" % [minutes / 60, minutes % 60]
