class_name Visits
## Chorzy i samotni parafianie, do których ksiądz jeździ z posługą. Odwiedziny idą po kolei,
## a każdy chory ma inny pokój, inne rekwizyty i inne skutki wizyty.

const PEOPLE := [
	{
		"id": "halina", "name": "pani Halina",
		"scene": "U pani Haliny. W telewizorze leci Trwam",
		"toast": "Modlitwa u pani Haliny. Telewizor grał przez całą wizytę.",
		"wallpaper": "b8a890", "stripe": "a09078", "parquet": "5a4030", "parquet_light": "6a5040",
		"blanket": "6a4a4a", "blanket_dark": "4a3236", "hair": "b0aca0",
		"tv": true, "iv": true, "portrait": true, "clutter": 1.0,
		"effects": {"reputation": 2, "young": 1},
	},
	{
		"id": "zdzislaw", "name": "pan Zdzisław",
		"scene": "U pana Zdzisława, kolejarza na emeryturze",
		"toast": "Komunia u pana Zdzisława. Opowiadał o kolei przez pół godziny.",
		"wallpaper": "9a8f7a", "stripe": "857a66", "parquet": "4a3628", "parquet_light": "5c4634",
		"blanket": "4a5060", "blanket_dark": "343c4a", "hair": "8a8a84",
		"tv": false, "iv": false, "oxygen": true, "portrait": false, "clutter": 1.4,
		"effects": {"reputation": 2, "trad": 1},
	},
	{
		"id": "marianna", "name": "pani Marianna",
		"scene": "U pani Marianny. Na łóżku śpi kot",
		"toast": "Wizyta u pani Marianny. Wyprosiła jeszcze różaniec za wnuki.",
		"wallpaper": "c4b8a4", "stripe": "b0a48e", "parquet": "6a5038", "parquet_light": "7c6044",
		"blanket": "7a5a48", "blanket_dark": "5c4032", "hair": "c8c4b8",
		"tv": false, "iv": false, "cat": true, "portrait": true, "clutter": 0.25,
		"effects": {"reputation": 3},
	},
	{
		"id": "wojtek", "name": "Wojtek",
		"scene": "U Wojtka, trzydzieści cztery lata, po wypadku",
		"toast": "Rozmowa z Wojtkiem. Nie chciał modlitwy, chciał rozmowy. Młode rodziny +2.",
		"wallpaper": "a8b0a8", "stripe": "949c94", "parquet": "56483a", "parquet_light": "665846",
		"blanket": "4a5a4a", "blanket_dark": "364234", "hair": "3a2a1c",
		"tv": true, "iv": false, "wheelchair": true, "portrait": false, "clutter": 0.8,
		"effects": {"young": 2, "reputation": 1},
	},
	{
		"id": "stefania", "name": "siostra Stefania",
		"scene": "U siostry Stefanii, emerytowanej katechetki",
		"toast": "Wizyta u siostry Stefanii. Wypytała o frekwencję na katechezie.",
		"wallpaper": "b0a8b8", "stripe": "9c94a4", "parquet": "584058", "parquet_light": "6a5068",
		"blanket": "5a4a5a", "blanket_dark": "433843", "hair": "d8d4cc",
		"tv": false, "iv": true, "books": true, "portrait": true, "clutter": 0.5,
		"effects": {"trad": 2, "reputation": 1},
	},
]


## Kto jest następny w kolejce. Bez zmiany stanu, żeby napis przy samochodzie mógł podać imię.
static func current(game: Node) -> Dictionary:
	return PEOPLE[int(game.visit_index) % PEOPLE.size()]


static func advance(game: Node) -> void:
	game.visit_index = (int(game.visit_index) + 1) % PEOPLE.size()


static func color(variant: Dictionary, key: String, fallback: String) -> Color:
	return Color(str(variant.get(key, fallback)))
