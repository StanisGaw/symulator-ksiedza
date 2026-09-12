class_name ChainEvents
## Wydarzenia dziekanatu i ich odroczone następstwa. POOL zawiera początek
## grywalnego łańcucha; FOLLOWUPS trafiają do kolejki Game.pending_events.

const POOL := [
	{
		"id": "dean_indulgence", "weight": 10, "cooldown": 365,
		"require": {"min_day": 14, "flags": {"dean_indulgence_chosen": false}},
		"title": "Wspólny odpust w dekanacie",
		"text": "Ksiądz Marek proponuje wspólny odpust. Termin jest jeden, a każda parafia chce zatrzymać swoich ludzi.",
		"options": [
			{
				"label": "Wspólny plac i wspólne koszty — 2 000 zł, energia -10",
				"effects": {"money": -2000, "energy": -10, "curia": 2},
				"flags": {"dean_indulgence_chosen": true, "dean_plan": "together"},
				"delayed": {"days": 14, "chance": 0.68,
					"text": "Odpust zgromadził oba kościoły.", "event": "dean_indulgence_together_success",
					"flags": {"dean_indulgence_result": "success"},
					"else_text": "Wspólny odpust ugrzązł w sporze o program.", "else_event": "dean_indulgence_together_failure",
					"else_flags": {"dean_indulgence_result": "failure"}}},
			{
				"label": "Zrób własny odpust wcześniej — 1 200 zł, energia -20",
				"effects": {"money": -1200, "energy": -20, "reputation": -1},
				"flags": {"dean_indulgence_chosen": true, "dean_plan": "rival"},
				"delayed": {"days": 21, "chance": 0.46,
					"text": "Wcześniejszy termin przyciągnął ludzi z obu parafii.", "event": "dean_indulgence_rival_success",
					"flags": {"dean_indulgence_result": "success"},
					"else_text": "Dwa odpusty podzieliły dekanat.", "else_event": "dean_indulgence_rival_failure",
					"else_flags": {"dean_indulgence_result": "failure"}}},
			{
				"label": "Oddaj termin i wyślij ludzi do pomocy — 700 zł, energia -15",
				"effects": {"money": -700, "energy": -15, "reputation": -2},
				"flags": {"dean_indulgence_chosen": true, "dean_plan": "support"},
				"delayed": {"days": 28, "chance": 0.76,
					"text": "Pomoc została zauważona w całym dekanacie.", "event": "dean_indulgence_support_success",
					"flags": {"dean_indulgence_result": "success"},
					"else_text": "Sąsiad przyjął pomoc, ale całą zasługę przypisał sobie.", "else_event": "dean_indulgence_support_failure",
					"else_flags": {"dean_indulgence_result": "failure"}}},
		]
	},
]


const FOLLOWUPS := [
	{
		"id": "neighbour_mass_hours",
		"require": {"flags": {"mass_hours_changed": true}},
		"title": "Telefon od sąsiedniego proboszcza",
		"text": "Ksiądz Marek zauważył zmianę godzin. Mówi, że teraz wasze msze konkurują o te same rodziny.",
		"options": [
			{"label": "Uzgodnijcie godziny — energia -10", "effects": {"energy": -10, "curia": 3},
				"flags": {"neighbour_mass_hours_seen": true, "neighbour_relation": "cooperation"}},
			{"label": "Godziny parafii ustalasz sam — reputacja -2", "effects": {"reputation": -2, "curia": -2},
				"flags": {"neighbour_mass_hours_seen": true, "neighbour_relation": "conflict"}},
		]
	},
	{
		"id": "dean_indulgence_together_success",
		"require": {"flags": {"dean_plan": "together", "dean_indulgence_result": "success"}},
		"title": "Wspólny odpust: pełny plac",
		"text": "Plac był pełny. Ksiądz Marek proponuje wspólny komunikat do kurii.",
		"options": [
			{"label": "Podkreśl wspólną pracę", "effects": {"curia": 5, "reputation": 3},
				"flags": {"dean_indulgence_resolved": true}},
			{"label": "Pochwal swoją parafię", "effects": {"reputation": 5, "curia": -2},
				"flags": {"dean_indulgence_resolved": true}},
		]
	},
	{
		"id": "dean_indulgence_together_failure",
		"require": {"flags": {"dean_plan": "together", "dean_indulgence_result": "failure"}},
		"title": "Wspólny odpust: spór przy ołtarzu",
		"text": "Organizatorzy pokłócili się o program. Ksiądz Marek chce wspólnie wyjaśnić sprawę dziekanowi.",
		"options": [
			{"label": "Weź odpowiedzialność", "effects": {"curia": 2, "reputation": -2},
				"flags": {"dean_indulgence_resolved": true}},
			{"label": "Obwiń organizatorów sąsiada", "effects": {"curia": -5, "reputation": 1},
				"flags": {"dean_indulgence_resolved": true}},
		]
	},
	{
		"id": "dean_indulgence_rival_success",
		"require": {"flags": {"dean_plan": "rival", "dean_indulgence_result": "success"}},
		"title": "Własny odpust: tłum z dekanatu",
		"text": "Wcześniejszy odpust przyciągnął także ludzi sąsiada. Ksiądz Marek dzwoni bez gratulacji.",
		"options": [
			{"label": "Przeproś i zaproponuj wspólne rekolekcje", "effects": {"money": -500, "curia": 3},
				"flags": {"dean_indulgence_resolved": true}},
			{"label": "Frekwencja mówi sama za siebie", "effects": {"reputation": 5, "curia": -4},
				"flags": {"dean_indulgence_resolved": true}},
		]
	},
	{
		"id": "dean_indulgence_rival_failure",
		"require": {"flags": {"dean_plan": "rival", "dean_indulgence_result": "failure"}},
		"title": "Dwa odpusty, dwa puste place",
		"text": "Podział terminów zaszkodził obu parafiom. Dziekan oczekuje wspólnego wyjaśnienia.",
		"options": [
			{"label": "Przyznaj, że termin był błędem", "effects": {"curia": 1, "reputation": -3},
				"flags": {"dean_indulgence_resolved": true}},
			{"label": "Broń swojej decyzji", "effects": {"curia": -5, "respect": 1},
				"flags": {"dean_indulgence_resolved": true}},
		]
	},
	{
		"id": "dean_indulgence_support_success",
		"require": {"flags": {"dean_plan": "support", "dean_indulgence_result": "success"}},
		"title": "Pomoc zauważona w dekanacie",
		"text": "Ksiądz Marek dziękuje publicznie twoim wolontariuszom i zaprasza cię do rady dekanatu.",
		"options": [
			{"label": "Przyjmij zaproszenie", "effects": {"energy": -10, "curia": 6, "respect": 2},
				"flags": {"dean_indulgence_resolved": true}},
			{"label": "Oddaj uznanie wolontariuszom", "effects": {"reputation": 5, "curia": 2},
				"flags": {"dean_indulgence_resolved": true}},
		]
	},
	{
		"id": "dean_indulgence_support_failure",
		"require": {"flags": {"dean_plan": "support", "dean_indulgence_result": "failure"}},
		"title": "Pomoc bez podziękowania",
		"text": "Sąsiad przypisał sobie całą organizację. Twoi ludzie pytają, po co poświęcili weekend.",
		"options": [
			{"label": "Podziękuj im z własnej ambony", "effects": {"reputation": 3, "money": -300},
				"flags": {"dean_indulgence_resolved": true}},
			{"label": "Zażądaj sprostowania", "effects": {"curia": -3, "respect": 2},
				"flags": {"dean_indulgence_resolved": true}},
		]
	},
]


static func catalogs() -> Array:
	return [["CHAIN_POOL", POOL], ["CHAIN_FOLLOWUPS", FOLLOWUPS]]
