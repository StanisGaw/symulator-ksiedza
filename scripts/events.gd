class_name Events
## Event definitions. Each event fires once, on the morning of its day or when a condition is met.
## Options carry immediate effects, optional state changes and an optional delayed consequence.

const EVENTS := [
	{
		"id": "mass_hour", "day": 2, "title": "Spór o godzinę głównej mszy w niedzielę",
		"text": "Po porannej mszy czekają na Ciebie dwie delegacje. W niedziele i święta odprawiasz o 7:00, 12:00 i 19:00, w dni powszednie o 7:00 i 19:00. Starsi parafianie chcą, żeby główna msza, którą po staremu nazywają sumą, wróciła na 7:00, a południową żebyś odwołał. Młode rodziny proszą o 11:00, bo dzieci nie wstaną wcześniej. Kościelny przypomina, że każda msza to godzina Twojego czasu, a opuszczonej nikt nie wybaczy. Zmiana dotyczy tylko niedziel i świąt.",
		"options": [
			{"label": "Niedziele i święta: 7:00 i 19:00, bez południowej", "effects": {"trad": 8, "young": -6}, "set": {"sunday_hours": [7, 19]},
				"delayed": {"days": 4, "text": "Kilka młodych rodzin zaczęło jeździć na mszę do sąsiedniej parafii. Młode rodziny -5, reputacja -2.", "effects": {"young": -5, "reputation": -2}}},
			{"label": "Niedziele i święta: 11:00 i 19:00, główna z dziećmi", "effects": {"young": 8, "trad": -6}, "set": {"sunday_hours": [11, 19]},
				"delayed": {"days": 4, "text": "Tradycjonaliści napisali list do kurii w sprawie „nowinek”. Kuria -4.", "effects": {"curia": -4}}},
			{"label": "Niedziele i święta: 7:00, 11:00 i 19:00, trzy msze", "effects": {"trad": 3, "young": 3}, "set": {"sunday_hours": [7, 11, 19]},
				"delayed": {"days": 7, "text": "Organista upomina się o dodatek za trzecią mszę w niedzielę. -600 zł.", "effects": {"money": -600}}},
		]
	},
	{
		"id": "funeral", "day": 3, "title": "Telefon: pogrzeb pana Zenona",
		"text": "Dzwoni rodzina Zenona Kowalczyka, znanego w parafii sołtysa. Pogrzeb ma być jutro, rodzina liczy na ciebie osobiście i sugeruje hojną ofiarę. Masz jednak już zaplanowany cały dzień.",
		"options": [
			{"label": "Odprawię pogrzeb osobiście", "effects": {"money": 800, "reputation": 2, "energy": -30}},
			{"label": "Poproszę księdza z sąsiedniej parafii", "effects": {"reputation": -2},
				"delayed": {"days": 3, "text": "Rodzina Zenona opowiada we wsi, że ksiądz nie miał czasu dla sołtysa. Reputacja -3.", "effects": {"reputation": -3}}},
		]
	},
	{
		"id": "curia_call", "day": 5, "title": "Telefon z kurii",
		"text": "Ksiądz kanclerz pyta uprzejmie o sprawozdanie finansowe za pierwszy tydzień. Dodaje, że biskup „interesuje się młodymi proboszczami”.",
		"options": [
			{"label": "Wyślę uczciwe sprawozdanie", "special": "honest_report"},
			{"label": "Poproszę o tydzień zwłoki",
				"delayed": {"days": 3, "text": "Kuria przypomina o zaległym sprawozdaniu, tym razem mniej uprzejmie. Kuria -5.", "effects": {"curia": -5}}},
			{"label": "Dołączę 1 500 zł „na cele diecezji”", "effects": {"money": -1500, "curia": 6},
				"delayed": {"days": 6, "text": "Ktoś z rady parafialnej dowiedział się o przelewie do kurii. Ludzie gadają. Reputacja -4.", "effects": {"reputation": -4}}},
		]
	},
	{
		"id": "roof_leak", "when": "condition_low", "title": "Przeciek w dachu",
		"text": "Kościelny pokazuje ci wiadro na środku nawy. Dach przecieka nad prezbiterium, tynk zaczyna odpadać. Ekipa może przyjechać od razu, ale za gotówkę.",
		"options": [
			{"label": "Doraźna naprawa za 2 000 zł", "effects": {"money": -2000, "condition": 8}},
			{"label": "Wiadro wystarczy do wiosny", "effects": {"trad": -3},
				"delayed": {"days": 4, "text": "Po ulewie zalało zakrystię. Stan budynków -12, tradycjonaliści -5.", "effects": {"condition": -12, "trad": -5}}},
		]
	},
]


static func due_events(game: Node) -> Array:
	var out: Array = []
	for ev in EVENTS:
		if game.fired_events.has(ev["id"]):
			continue
		if ev.has("day") and int(ev["day"]) == game.day:
			out.append(ev)
		elif ev.get("when", "") == "condition_low" and game.condition < 30:
			out.append(ev)
	return out
