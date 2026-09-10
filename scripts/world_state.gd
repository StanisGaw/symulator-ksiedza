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


static func wall_color(base: Color) -> Color:
	match condition():
		BAD:
			return base.lerp(Palette.GRIME, 0.35)
		GOOD:
			return base.lerp(Color.WHITE, 0.08)
		_:
			return base
