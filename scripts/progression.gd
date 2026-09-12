class_name Progression
## Rozwój księdza: pięć cech zdobywanych przez działanie, trzy dwupoziomowe
## drzewka talentów oraz jedno źródło prawdy dla progów i końcowych skutków opcji.

const XP_PER_POINT := 8
const STAT_MIN := 1
const STAT_MAX := 10

const STAT_LABELS := {
	"charyzma": "Charyzma",
	"wiarygodnosc": "Wiarygodność",
	"zarzadzanie": "Zarządzanie",
	"wplywy": "Wpływy",
	"odpornosc": "Odporność",
}

const TALENTS := {
	"admin_accounts": {"label": "Administrator", "tree": "administrator", "cost": 20,
		"requires": "", "description": "Naprawy i inwestycje kosztują o 10% mniej."},
	"admin_inspection": {"label": "Przegląd gospodarski", "tree": "administrator", "cost": 35,
		"requires": "admin_accounts", "description": "Odblokowuje codzienny przegląd budynków przy biurku."},
	"pastor_presence": {"label": "Duszpasterz", "tree": "duszpasterz", "cost": 20,
		"requires": "", "description": "Frekwencja na mszach rośnie o 10%, maksymalnie do 500 osób."},
	"pastor_visits": {"label": "Blisko ludzi", "tree": "duszpasterz", "cost": 35,
		"requires": "pastor_presence", "description": "Odwiedziny chorego trwają o 15 minut krócej."},
	"host_media": {"label": "Gospodarz", "tree": "gospodarz", "cost": 20,
		"requires": "", "description": "Każda wykonana odpowiedź w mediach daje dodatkowo 2 reputacji."},
	"host_curia": {"label": "Zaufanie kurii", "tree": "gospodarz", "cost": 35,
		"requires": "host_media", "description": "Uczciwa odpowiedź kurii daje dodatkowo 2 relacji z kurią."},
}

const TALENT_IDS := ["admin_accounts", "admin_inspection", "pastor_presence",
	"pastor_visits", "host_media", "host_curia"]

const XP_REWARDS := {
	"mass": ["charyzma", 1],
	"confession": ["charyzma", 1],
	"honest_report": ["wiarygodnosc", 3],
	"balanced_week": ["zarzadzanie", 3],
	"media": ["wplywy", 1],
	"festyn": ["wplywy", 3],
	"short_sleep": ["odpornosc", 1],
}


static func reset(game: Node) -> void:
	var stats := {}
	var xp := {}
	for id in STAT_LABELS:
		stats[id] = 3
		xp[id] = 0
	game.set("stats", stats)
	game.set("stat_xp", xp)
	game.set("talents", [])


static func normalize(game: Node) -> void:
	var raw_stats: Variant = game.get("stats")
	var raw_xp: Variant = game.get("stat_xp")
	var source_stats: Dictionary = raw_stats if raw_stats is Dictionary else {}
	var source_xp: Dictionary = raw_xp if raw_xp is Dictionary else {}
	var stats := {}
	var xp := {}
	for id in STAT_LABELS:
		stats[id] = clampi(int(source_stats.get(id, 3)), STAT_MIN, STAT_MAX)
		xp[id] = clampi(int(source_xp.get(id, 0)), 0, XP_PER_POINT - 1) if stats[id] < STAT_MAX else 0
	game.set("stats", stats)
	game.set("stat_xp", xp)

	var talent_value: Variant = game.get("talents")
	var requested: Array = talent_value if talent_value is Array else []
	var normalized: Array = []
	for id in TALENT_IDS:
		if not requested.has(id):
			continue
		var required := str(TALENTS[id]["requires"])
		if required == "" or normalized.has(required):
			normalized.append(id)
	game.set("talents", normalized)


static func record(kind: String) -> void:
	if not XP_REWARDS.has(kind):
		return
	_ensure_game()
	var reward: Array = XP_REWARDS[kind]
	var stat := str(reward[0])
	if int(Game.stats[stat]) >= STAT_MAX:
		Game.stat_xp[stat] = 0
		return
	var before := int(Game.stats[stat])
	Game.stat_xp[stat] = int(Game.stat_xp[stat]) + int(reward[1])
	while int(Game.stat_xp[stat]) >= XP_PER_POINT and int(Game.stats[stat]) < STAT_MAX:
		Game.stat_xp[stat] = int(Game.stat_xp[stat]) - XP_PER_POINT
		Game.stats[stat] = int(Game.stats[stat]) + 1
	if int(Game.stats[stat]) >= STAT_MAX:
		Game.stat_xp[stat] = 0
	if int(Game.stats[stat]) > before:
		Career.add_chronicle("Rozwój: %s osiąga poziom %d. %s" % [
			STAT_LABELS[stat], Game.stats[stat], profile_text()])
	Game.state_changed.emit()


static func profile_text() -> String:
	_ensure_game()
	var strongest := _extreme_stat(true)
	var weakest := _extreme_stat(false)
	var style: String = {
		"charyzma": "charyzmatyczny duszpasterz",
		"wiarygodnosc": "wiarygodny duszpasterz",
		"zarzadzanie": "administrator",
		"wplywy": "gospodarz budujący wpływy",
		"odpornosc": "wytrwały duszpasterz",
	}.get(strongest, "duszpasterz")
	var values: Array[String] = []
	for id in STAT_LABELS:
		values.append("%s %d/10" % [STAT_LABELS[id], int(Game.stats[id])])
	if int(Game.stats[strongest]) - int(Game.stats[weakest]) < 2:
		return "Profil zrównoważony, bez wyraźnej specjalizacji. %s." % ", ".join(values)
	return "Profil: %s; najsłabsza cecha: %s %d/10. %s." % [style,
		STAT_LABELS[weakest], int(Game.stats[weakest]), ", ".join(values)]


static func has_talent(id: String) -> bool:
	_ensure_game()
	return Game.talents.has(id)


static func unlock_reason(id: String) -> String:
	_ensure_game()
	if not TALENTS.has(id):
		return "Nieznany talent."
	if Game.talents.has(id):
		return "Talent jest już odblokowany."
	var talent: Dictionary = TALENTS[id]
	var required := str(talent["requires"])
	if required != "" and not Game.talents.has(required):
		return "Najpierw odblokuj: %s." % TALENTS[required]["label"]
	var cost := int(talent["cost"])
	if Game.respect < cost:
		return "Potrzeba %d szacunku; masz %d." % [cost, Game.respect]
	return ""


static func unlock(id: String) -> bool:
	var reason := unlock_reason(id)
	if reason != "":
		return false
	var talent: Dictionary = TALENTS[id]
	Game.respect -= int(talent["cost"])
	Game.talents.append(id)
	Career.add_chronicle("Rozwój: odblokowano talent „%s”. %s" % [talent["label"], profile_text()])
	Game.state_changed.emit()
	return true


static func option_state(option: Dictionary, _context: String = "event") -> Dictionary:
	_ensure_game()
	var needs: Variant = option.get("needs", {})
	if not needs is Dictionary:
		return {"enabled": false, "reason": "Nieprawidłowe wymagania opcji."}
	for stat_variant in needs:
		var stat := str(stat_variant)
		if not STAT_LABELS.has(stat):
			return {"enabled": false, "reason": "Nieznana cecha: %s." % stat}
		var threshold := clampi(int(needs[stat_variant]), STAT_MIN, STAT_MAX)
		if int(Game.stats[stat]) < threshold:
			return {"enabled": false, "reason": "Wymaga: %s %d/10 (masz %d/10)." % [
				STAT_LABELS[stat], threshold, int(Game.stats[stat])]}
	return {"enabled": true, "reason": ""}


static func resolve_option(option: Dictionary, context: String = "event") -> Dictionary:
	_ensure_game()
	var resolved := option.duplicate(true)
	if bool(resolved.get("_progression_resolved", false)):
		return resolved
	var raw_effects: Variant = resolved.get("effects", {})
	var effects: Dictionary = raw_effects.duplicate(true) if raw_effects is Dictionary else {}
	var scale := str(resolved.get("scale", ""))
	if scale != "" and effects.has("money") and STAT_LABELS.has(scale):
		var amount := int(effects["money"])
		var level_delta := int(Game.stats[scale]) - 3
		var multiplier := 1.0 + 0.1 * level_delta if amount >= 0 else 1.0 - 0.05 * level_delta
		effects["money"] = int(round(amount * multiplier))
	if context == "media" and has_talent("host_media"):
		effects["reputation"] = int(effects.get("reputation", 0)) + 2
	var is_honest := bool(resolved.get("honest", false)) or str(resolved.get("special", "")) == "honest_report"
	if is_honest and has_talent("host_curia"):
		effects["curia"] = int(effects.get("curia", 0)) + 2
	if not effects.is_empty() or resolved.has("effects"):
		resolved["effects"] = effects
	resolved.erase("scale")
	resolved.erase("talent_bonus")
	resolved.erase("bonus_talent")
	resolved["_progression_resolved"] = true
	return resolved


static func investment_cost(base: int) -> int:
	_ensure_game()
	var safe := maxi(0, base)
	return int(round(safe * 0.9)) if has_talent("admin_accounts") else safe


static func attendance(base: int) -> int:
	_ensure_game()
	var safe := clampi(base, 0, 500)
	return mini(500, int(round(safe * 1.1))) if has_talent("pastor_presence") else safe


static func activity_minutes(id: String, base: int) -> int:
	_ensure_game()
	var safe := maxi(0, base)
	if id == "visit_sick" and has_talent("pastor_visits"):
		return maxi(0, safe - 15)
	return safe


static func _ensure_game() -> void:
	if not Game.stats is Dictionary or not Game.stat_xp is Dictionary or not Game.talents is Array \
			or Game.stats.size() != STAT_LABELS.size() or Game.stat_xp.size() != STAT_LABELS.size():
		normalize(Game)
		return
	for id in STAT_LABELS:
		if not Game.stats.has(id) or not Game.stat_xp.has(id):
			normalize(Game)
			return


static func _extreme_stat(highest: bool) -> String:
	var picked := str(STAT_LABELS.keys()[0])
	for id in STAT_LABELS:
		if highest and int(Game.stats[id]) > int(Game.stats[picked]):
			picked = id
		elif not highest and int(Game.stats[id]) < int(Game.stats[picked]):
			picked = id
	return picked
