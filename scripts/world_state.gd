class_name WorldState
## Jak stan parafii przekłada się na wygląd świata. Lokacje czytają to przy budowie,
## a sygnał Game.world_changed przebudowuje je, gdy stan się zmieni.

enum {BAD, FAIR, GOOD}

const BAD_BELOW := 30
const GOOD_ABOVE := 70


## Komunikat pokazywany, gdy gracz pierwszy raz zobaczy nową rzecz w lokacji.
const REVEALS := {
	"roof": "Nowy dach nad kościołem.",
	"heating": "Grzejniki pod ścianami. Nikt już nie marznie.",
	"sound": "Nagłośnienie gotowe. Słychać w ostatniej ławce.",
	"gutter": "Rynna trzyma się prosto.",
}


static func reveal_text(id: String) -> String:
	return REVEALS.get(id, "Coś się w parafii zmieniło.")


static func tier(value: int) -> int:
	if value < BAD_BELOW:
		return BAD
	if value > GOOD_ABOVE:
		return GOOD
	return FAIR


## Stan budynków: zaniedbane, znośne, zadbane.
static func condition() -> int:
	return tier(Game.condition)


## Jak żywa jest parafia: ilu ludzi kręci się po placu, ile aut na parkingu.
static func life() -> int:
	return tier(int(round((Game.reputation + Game.trad + Game.young) / 3.0)))


## Czy dana inwestycja albo trwała naprawa jest już zrobiona.
static func has(id: String) -> bool:
	return Game.built.has(id)


## Czy czynność została dziś wykonana. Efekty codzienne (zamiecony plac) znikają rano.
static func done_today(id: String) -> bool:
	return Game.done_today.has(id)


## Dach: nowy po remoncie, inaczej tym bardziej wyblakły, im gorszy stan budynków.
static func roof_color() -> Color:
	if has("roof"):
		return Palette.ROOF_NEW
	match condition():
		BAD:
			return Palette.ROOF_BAD
		GOOD:
			return Palette.ROOF
		_:
			return Palette.ROOF.lerp(Palette.ROOF_BAD, 0.45)


# ---------- klimat okresu liturgicznego i pory roku ----------

## Kolor nakrycia ołtarza: fiolet w Adwencie i Wielkim Poście, biel i złoto w świętach.
static func altar_cloth() -> Color:
	match Calendar.season(Game.day):
		Calendar.ADVENT, Calendar.LENT:
			return Palette.CLOTH_VIOLET
		Calendar.CHRISTMAS, Calendar.EASTER:
			return Palette.CLOTH_GOLD
		_:
			return Palette.ALTAR_CLOTH


## Światło wnętrza: [kolor otoczenia, siła]. Wielki Post jest zimny i ciemny,
## Wielkanoc jasna, święta ciepłe.
static func church_ambient() -> Array:
	match Calendar.season(Game.day):
		Calendar.LENT:
			return [Color("5a5a6e"), 0.95]
		Calendar.EASTER:
			return [Color("8a8496"), 1.9]
		Calendar.CHRISTMAS:
			return [Color("7a6e70"), 1.6]
		_:
			return [Color("6a6478"), 1.3]


static func snow() -> bool:
	return Calendar.is_snowy(Game.day)


static func grass_color() -> Color:
	if snow():
		return Palette.SNOW
	match Calendar.time_of_year(Game.day):
		"lato":
			return Palette.GRASS.lerp(Palette.CANOPY_SUMMER, 0.4)
		"jesień":
			return Palette.GRASS.lerp(Palette.LEAF_AUTUMN, 0.25)
		_:
			return Palette.GRASS


static func canopy_color(base: Color) -> Color:
	match Calendar.time_of_year(Game.day):
		"jesień":
			return Palette.CANOPY_AUTUMN
		"zima":
			return base.lerp(Palette.GRIME, 0.5)
		"lato":
			return Palette.CANOPY_SUMMER
		_:
			return base


static func wall_color(base: Color) -> Color:
	match condition():
		BAD:
			return base.lerp(Palette.GRIME, 0.35)
		GOOD:
			return base.lerp(Color.WHITE, 0.08)
		_:
			return base
