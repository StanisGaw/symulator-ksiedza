class_name Breakdowns
## Awarie: stany trwałe, a nie jednorazowe zdarzenia. Awaria kosztuje co rano,
## dopóki gracz jej nie naprawi, a część z nich blokuje czynności.
##
## "daily" to skutki naliczane każdego poranka, "cost" i "days" to naprawa
## (rozliczana tak samo jak inwestycja), "blocks" to czynność, której nie da się
## wykonać, dopóki awaria trwa.

const ALL := {
	"roof_storm": {
		"label": "Zerwana część dachu",
		"daily": {"condition": -2},
		"daily_text": "Przez dziurę w dachu leje się do nawy. Stan budynków -2.",
		"cost": 6000, "days": 2,
		"note": "Plandeka na połaci trzyma się na dwóch cegłach i dobrej woli.",
		"fixed_text": "Dach połatany, plandeka zdjęta. Stan budynków +10.",
		"fixed_effects": {"condition": 10},
		"world": true,
	},
	"furnace": {
		"label": "Padnięty piec",
		"daily": {"trad": -1, "money": -120},
		"daily_text": "W kościele jest zimno, farelki z plebanii idą na prąd. Tradycjonaliści -1, -120 zł.",
		"cost": 3500, "days": 2,
		"note": "Palnik gaśnie po dwóch minutach. Serwis mówi, że to sterownik, ale trzeba go zamówić.",
		"fixed_text": "Piec chodzi. W kościele znów da się wytrzymać mszę. Tradycjonaliści +4.",
		"fixed_effects": {"trad": 4},
	},
	"martens": {
		"label": "Kuny na strychu",
		"daily": {"condition": -1},
		"daily_text": "Kuny znowu chodziły nad sklepieniem i zrzuciły tynk. Stan budynków -1.",
		"cost": 900, "days": 1,
		"note": "Słychać je od drugiej w nocy. Kościelny twierdzi, że jedna jest wielkości psa.",
		"fixed_text": "Strych zabezpieczony, kuny wyprowadzone.",
		"fixed_effects": {},
	},
	"water_leak": {
		"label": "Pęknięta rura na plebanii",
		"daily": {"condition": -1, "money": -60},
		"daily_text": "Woda kapie do wiadra w korytarzu plebanii. Stan budynków -1, -60 zł.",
		"cost": 1800, "days": 1,
		"note": "Hydraulik może być w czwartek. Od trzech czwartków.",
		"fixed_text": "Rura wymieniona, korytarz suchy.",
		"fixed_effects": {"condition": 2},
	},
	"car": {
		"label": "Samochód nie odpala",
		"daily": {"reputation": -1},
		"daily_text": "Chorzy czekają, a ty nie masz czym do nich dojechać. Reputacja -1.",
		"cost": 2400, "days": 1,
		"blocks": "visit_sick",
		"note": "Rozrusznik. Mechanik ze wsi mówi, że w tym roczniku to normalne.",
		"fixed_text": "Samochód wrócił z warsztatu. Można znów jeździć do chorych.",
		"fixed_effects": {},
	},
}


static func has(id: String) -> bool:
	return ALL.has(id)


static func label(id: String) -> String:
	return str(ALL.get(id, {}).get("label", id))


## Awarie, które mogą się zdarzyć same z siebie przy zaniedbanej parafii.
## Zima dokłada piec, bo wtedy dopiero widać, że nie grzeje.
static func natural_risk(id: String, season_part: String) -> float:
	match id:
		"furnace":
			return 1.6 if season_part == "zima" else 0.3
		"roof_storm":
			return 1.3 if season_part == "jesień" or season_part == "zima" else 0.6
		_:
			return 1.0
