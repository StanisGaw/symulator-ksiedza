class_name Parish
## Parafia jako zbiór wskaźników: co robi z nimi skutek wydarzenia i jak się go opisuje
## graczowi. Same liczby siedzą w Game, bo się zapisują.
##
## To jest jedyne miejsce, przez które wskaźniki się zmieniają, więc sześć grup interesów
## (wydanie 2.6) wchodzi tutaj, a nie w dwudziestu miejscach naraz.

static func apply_effects(effects: Dictionary, label: String = "") -> void:
	var before_condition := WorldState.condition()
	var before_life := WorldState.life()
	for key in effects:
		var v: int = int(effects[key])
		match key:
			"money":
				Game.money += v
				if v >= 0:
					Game.week_income += v
				else:
					Game.week_expenses += -v
				Finance.bank_entry(label if label != "" else ("Wpływ" if v >= 0 else "Wydatek"), v)
			"reputation": Game.reputation = clampi(Game.reputation + v, 0, 100)
			"condition": Game.condition = clampi(Game.condition + v, 0, 100)
			"trad": Game.trad = clampi(Game.trad + v, 0, 100)
			"young": Game.young = clampi(Game.young + v, 0, 100)
			"curia": Game.curia = clampi(Game.curia + v, 0, 100)
			"respect": Game.respect += v
			"energy": Game.energy = clampf(Game.energy + v, 0.0, 100.0)
	Game.state_changed.emit()
	# świat pokazuje stan parafii progami, więc przebudowa tylko przy zmianie progu
	if WorldState.condition() != before_condition or WorldState.life() != before_life:
		Game.world_changed.emit()


static func effects_text(effects: Dictionary) -> String:
	var names := {"money": "zł", "reputation": "reputacja", "condition": "budynki", "trad": "tradycjonaliści",
		"young": "młode rodziny", "curia": "kuria", "energy": "energia", "respect": "szacunek"}
	var parts: Array[String] = []
	for key in effects:
		var v: int = int(effects[key])
		if key == "money":
			parts.append("%+d zł" % v)
		else:
			parts.append("%s %+d" % [names.get(key, key), v])
	return ", ".join(parts)
