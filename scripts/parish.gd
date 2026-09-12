class_name Parish
## Wspólne nakładanie i opisywanie skutków, w tym zgodność dawnych trad/young
## z sześcioma grupami. Stan nadal zapisuje autoload Game.

static func apply_effects(effects: Dictionary, label: String = "", category: String = "inne") -> void:
	var before_condition := WorldState.condition()
	var before_life := WorldState.life()
	var group_deltas: Dictionary = (effects.get("groups", {}) as Dictionary).duplicate(true)
	if Game.groups.is_empty():
		Groups.reset(Game, Game.trad, Game.young)
	for legacy_key in {"trad": "seniorzy", "young": "rodziny"}:
		if effects.has(legacy_key):
			var group_id: String = {"trad": "seniorzy", "young": "rodziny"}[legacy_key]
			Game.groups[group_id]["satisfaction"] = int(Game.get(legacy_key))
			group_deltas[group_id] = int(group_deltas.get(group_id, 0)) + int(effects[legacy_key])
	for key in effects:
		if key in ["groups", "trad", "young"]:
			continue
		var v: int = int(effects[key])
		match key:
			"money":
				Game.money += v
				if v >= 0:
					Game.week_income += v
				else:
					Game.week_expenses += -v
				Finance.bank_entry(label if label != "" else ("Wpływ" if v >= 0 else "Wydatek"), v, category)
			"reputation": Game.reputation = clampi(Game.reputation + v, 0, 100)
			"condition": Game.condition = clampi(Game.condition + v, 0, 100)
			"curia": Game.curia = clampi(Game.curia + v, 0, 100)
			"respect": Game.respect += v
			"energy": Game.energy = clampf(Game.energy + v, 0.0, 100.0)
	if not group_deltas.is_empty():
		Groups.apply_effects(group_deltas, label)
	Game.state_changed.emit()
	# świat pokazuje stan parafii progami, więc przebudowa tylko przy zmianie progu
	if WorldState.condition() != before_condition or WorldState.life() != before_life:
		Game.world_changed.emit()


static func effects_text(effects: Dictionary) -> String:
	var names := {"money": "zł", "reputation": "reputacja", "condition": "budynki", "trad": "seniorzy",
		"young": "młode rodziny", "curia": "kuria", "energy": "energia", "respect": "szacunek"}
	var parts: Array[String] = []
	for key in effects:
		if key == "groups":
			for group_id in effects[key]:
				parts.append("%s %+d" % [Groups.LABELS.get(group_id, group_id), int(effects[key][group_id])])
			continue
		var v: int = int(effects[key])
		if key == "money":
			parts.append("%+d zł" % v)
		else:
			parts.append("%s %+d" % [names.get(key, key), v])
	return ", ".join(parts)
