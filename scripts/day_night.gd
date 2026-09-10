extends DirectionalLight3D
## Day cycle for the "mroczny" direction: overcast, cold daylight; amber accents at night.
## Reads the clock from Game and drives sun, sky, ambient, fog and lamps of the outside location.

const SUN_DAY := Color("c9d6ec")
const SUN_DUSK := Color("b08060")
const SUN_NIGHT := Color("6a7ab8")
const SKY_DAY := Color("3a4452")
const SKY_NIGHT := Color("141a26")
const AMBIENT_DAY := Color("8c98aa")
const AMBIENT_NIGHT := Color("3a4458")

var env: Environment
var lamps: Array[OmniLight3D] = []


func _ready() -> void:
	shadow_enabled = true
	directional_shadow_max_distance = 60.0
	_apply()


func _process(_delta: float) -> void:
	_apply()


func _apply() -> void:
	var t := Game.time_of_day()
	var daylight := clampf((cos((t - 0.5) * TAU) + 0.35) / 1.35, 0.0, 1.0)
	var dusk := clampf(1.0 - absf(daylight - 0.35) / 0.35, 0.0, 1.0)
	light_color = SUN_NIGHT.lerp(SUN_DAY, daylight).lerp(SUN_DUSK, dusk * 0.6)
	light_energy = lerpf(0.6, 3.2, daylight)
	var elevation := lerpf(-10.0, 55.0, daylight)
	var azimuth := lerpf(-70.0, 70.0, t)
	rotation_degrees = Vector3(-elevation, azimuth, 0)
	if env:
		var sky := SKY_NIGHT.lerp(SKY_DAY, daylight)
		env.background_color = sky
		env.fog_light_color = sky
		env.ambient_light_color = AMBIENT_NIGHT.lerp(AMBIENT_DAY, daylight)
		env.ambient_light_energy = lerpf(1.2, 2.4, daylight)
	var lamps_on := daylight < 0.45
	for lamp in lamps:
		lamp.light_energy = 4.0 if lamps_on else 0.0
