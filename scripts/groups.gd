class_name Groups
## Sześć grup parafian, ich wpływ, samodzielne działania tygodniowe oraz stale
## finansowane wspólnoty. Game przechowuje stan; ten moduł jest jedynym miejscem
## obliczania wpływu i pilnuje tygodniowej idempotencji.

const LABELS := {
	"mlodziez": "Młodzież",
	"rodziny": "Młode rodziny",
	"pracujacy": "Pracujący",
	"seniorzy": "Seniorzy",
	"przedsiebiorcy": "Przedsiębiorcy",
	"potrzebujacy": "Potrzebujący",
}

const START_SIZES := {
	"mlodziez": 80,
	"rodziny": 120,
	"pracujacy": 160,
	"seniorzy": 150,
	"przedsiebiorcy": 80,
	"potrzebujacy": 110,
}

const INITIATIVES := {
	"caritas": {"label": "Caritas", "cost": 300, "minutes": 60, "energy": 10,
		"groups": {"potrzebujacy": 6, "seniorzy": 2}, "size_groups": {"potrzebujacy": 3, "seniorzy": 1}},
	"swietlica": {"label": "Świetlica", "cost": 450, "minutes": 90, "energy": 15,
		"groups": {"mlodziez": 6, "rodziny": 3}, "size_groups": {"mlodziez": 3, "rodziny": 2}},
	"katecheza": {"label": "Katecheza", "cost": 150, "minutes": 45, "energy": 8,
		"groups": {"rodziny": 4, "mlodziez": 2}, "size_groups": {"rodziny": 2, "mlodziez": 1}},
}

const GROUP_IDS := ["mlodziez", "rodziny", "pracujacy", "seniorzy", "przedsiebiorcy", "potrzebujacy"]
const INITIATIVE_IDS := ["caritas", "swietlica", "katecheza"]
const WEEK_SECONDS := 7 * Calendar.DAY_SECONDS


static func reset(game: Node, legacy_trad: int = 55, legacy_young: int = 50) -> void:
	var rows := {}
	for id in GROUP_IDS:
		var satisfaction := 50
		if id == "seniorzy":
			satisfaction = legacy_trad
		elif id == "rodziny":
			satisfaction = legacy_young
		rows[id] = _row(satisfaction, int(START_SIZES[id]), int(game.get("day")), "Początek gry", 0)
	game.set("groups", rows)
	var community := {}
	for id in INITIATIVE_IDS:
		community[id] = false
	game.set("community", community)
	game.set("group_state", {"last_week": -1, "paid_week": {}, "done_week": {}})
	_refresh_game(game)


static func normalize(game: Node) -> void:
	var raw_groups: Variant = game.get("groups")
	var source: Dictionary = raw_groups if raw_groups is Dictionary else {}
	var normalized := {}
	for id in GROUP_IDS:
		var default_satisfaction := 50
		if id == "seniorzy":
			default_satisfaction = int(game.get("trad"))
		elif id == "rodziny":
			default_satisfaction = int(game.get("young"))
		var raw: Variant = source.get(id, {})
		var row: Dictionary = raw if raw is Dictionary else {}
		var change_value: Variant = row.get("last_change", {})
		var change: Dictionary = change_value if change_value is Dictionary else {}
		normalized[id] = _row(int(row.get("satisfaction", default_satisfaction)),
			int(row.get("size", START_SIZES[id])), int(change.get("day", game.get("day"))),
			str(change.get("text", "Migracja danych grupy")), int(change.get("delta", 0)))
	game.set("groups", normalized)

	var raw_community: Variant = game.get("community")
	var source_community: Dictionary = raw_community if raw_community is Dictionary else {}
	var community := {}
	for id in INITIATIVE_IDS:
		community[id] = bool(source_community.get(id, false))
	game.set("community", community)

	var raw_state: Variant = game.get("group_state")
	var source_state: Dictionary = raw_state if raw_state is Dictionary else {}
	game.set("group_state", {
		"last_week": int(source_state.get("last_week", -1)),
		"paid_week": _normalize_week_map(source_state.get("paid_week", {})),
		"done_week": _normalize_week_map(source_state.get("done_week", {})),
	})
	_refresh_game(game)


static func refresh() -> void:
	_ensure_game()
	_refresh_game(Game)


static func apply_effects(deltas: Dictionary, label: String = "") -> void:
	_ensure_game()
	var description := label.strip_edges() if label.strip_edges() != "" else "Zmiana nastawienia grupy"
	for id_variant in deltas:
		var id := str(id_variant)
		if not LABELS.has(id):
			continue
		var row: Dictionary = Game.groups[id]
		var before := int(row["satisfaction"])
		var after := clampi(before + int(deltas[id_variant]), 0, 100)
		row["satisfaction"] = after
		row["last_change"] = {"day": Game.day, "text": description, "delta": after - before}
	_refresh_game(Game)
	Game.state_changed.emit()


## Zmiana liczebności jest osobna od nastroju, żeby wydarzenia nie mogły
## przypadkiem potraktować liczby osób jak punktów zadowolenia.
static func grow(deltas: Dictionary, label: String = "") -> void:
	_ensure_game()
	var description := label.strip_edges() if label.strip_edges() != "" else "Zmiana liczebności grupy"
	for id_variant in deltas:
		var id := str(id_variant)
		if not LABELS.has(id):
			continue
		var row: Dictionary = Game.groups[id]
		var before := int(row["size"])
		var after := clampi(before + int(deltas[id_variant]), 1, 500)
		var actual := after - before
		row["size"] = after
		row["last_change"] = {"day": Game.day,
			"text": "%s (%+d osób)" % [description, actual], "delta": actual}
	_refresh_game(Game)
	Game.state_changed.emit()


static func support() -> float:
	_ensure_game()
	var weighted := 0.0
	var people := 0
	for id in GROUP_IDS:
		var row: Dictionary = Game.groups[id]
		var size := int(row["size"])
		people += size
		weighted += float(row["satisfaction"]) * size
	return weighted / people if people > 0 else 0.0


static func fracture_members() -> Array[String]:
	_ensure_game()
	return _fracture_members(Game)


static func weekly() -> Array[String]:
	_ensure_game()
	_refresh_game(Game)
	var lines: Array[String] = []
	var current_week := week_id()
	if int(Game.group_state.get("last_week", -1)) == current_week:
		return lines
	# Znacznik idzie przed skutkami: sygnały i zapis w trakcie rozliczenia nie mogą
	# drugi raz pobrać opłat ani powtórzyć działań wpływowych grup.
	Game.group_state["last_week"] = current_week
	for initiative_id in INITIATIVE_IDS:
		if not bool(Game.community[initiative_id]) or int(Game.group_state["paid_week"].get(initiative_id, -1)) == current_week:
			continue
		Game.group_state["paid_week"][initiative_id] = current_week
		var initiative: Dictionary = INITIATIVES[initiative_id]
		var cost := int(initiative["cost"])
		Parish.apply_effects({"money": -cost}, "Wspólnota: %s" % initiative["label"], "duszpasterstwo")
		lines.append("%s: tygodniowe finansowanie -%d zł." % [initiative["label"], cost])

	for id in GROUP_IDS:
		var row: Dictionary = Game.groups[id]
		if int(row["influence"]) <= 70:
			continue
		var label := str(LABELS[id])
		var satisfaction := int(row["satisfaction"])
		if satisfaction >= 60:
			var collection := 2 * int(row["size"])
			Parish.apply_effects({"money": collection}, "Zbiórka grupy: %s" % label, "taca")
			lines.append("%s przeprowadzili własną zbiórkę: +%d zł." % [label, collection])
		elif satisfaction >= 30:
			Parish.apply_effects({"reputation": 1}, "Wolontariusze: %s" % label)
			lines.append("%s zorganizowali wolontariuszy. Reputacja +1." % label)
		else:
			Parish.apply_effects({"curia": -2}, "Skarga grupy: %s" % label)
			lines.append("%s wysłali skargę do kurii. Kuria -2." % label)
	_refresh_game(Game)
	Game.state_changed.emit()
	return lines


static func week_id() -> int:
	var timestamp := Game.start_unix + (Game.day - 1) * Calendar.DAY_SECONDS
	var weekday := int(Calendar.date(Game.day)["weekday"])
	var days_since_monday := (weekday + 6) % 7
	return int(floor(float(timestamp - days_since_monday * Calendar.DAY_SECONDS) / float(WEEK_SECONDS)))


static func weekly_cost() -> int:
	_ensure_game()
	var total := 0
	for id in INITIATIVE_IDS:
		if bool(Game.community[id]):
			total += int(INITIATIVES[id]["cost"])
	return total


static func activation_cost(id: String) -> int:
	_ensure_game()
	if not INITIATIVES.has(id):
		return 0
	return 0 if int(Game.group_state["paid_week"].get(id, -1)) == week_id() else int(INITIATIVES[id]["cost"])


static func activation_forecast(id: String) -> Dictionary:
	_ensure_game()
	if not INITIATIVES.has(id):
		return {}
	if bool(Game.community[id]):
		return Finance.forecast()
	var weekly_fee := int(INITIATIVES[id]["cost"])
	var result := Finance.forecast({}, activation_cost(id) + weekly_fee)
	if not result.is_empty():
		# Finance traktuje opłatę aktywacyjną jako jednorazowy wydatek. Dodatkowy
		# koszt tygodniowy należy jednak do pola kosztów pokazywanego w prognozie.
		result["costs"] = int(result["costs"]) + weekly_fee
	return result


static func set_initiative(id: String, enabled: bool, confirmed: bool = false) -> bool:
	_ensure_game()
	if not INITIATIVES.has(id):
		return false
	if bool(Game.community[id]) == enabled:
		return true
	if not enabled:
		Game.community[id] = false
		Game.add_log("Wyłączono tygodniowe finansowanie: %s." % INITIATIVES[id]["label"])
		Game.state_changed.emit()
		return true
	var forecast := activation_forecast(id)
	if (forecast.is_empty() or int(forecast.get("balance", -1)) < 0) and not confirmed:
		return false
	var cost := activation_cost(id)
	Game.community[id] = true
	if cost > 0:
		Game.group_state["paid_week"][id] = week_id()
		Parish.apply_effects({"money": -cost}, "Uruchomienie wspólnoty: %s" % INITIATIVES[id]["label"], "duszpasterstwo")
	Game.add_log("Włączono tygodniowe finansowanie: %s (%d zł/tydzień)." % [
		INITIATIVES[id]["label"], INITIATIVES[id]["cost"]])
	Game.state_changed.emit()
	return true


static func run_reason(id: String) -> String:
	_ensure_game()
	if not INITIATIVES.has(id):
		return "Nieznana wspólnota."
	if not bool(Game.community[id]):
		return "Najpierw włącz tygodniowe finansowanie."
	if int(Game.group_state["done_week"].get(id, -1)) == week_id():
		return "Spotkanie tej wspólnoty już odbyło się w tym tygodniu."
	if Game.location != "rectory":
		return "Spotkanie można przeprowadzić tylko na plebanii."
	var initiative: Dictionary = INITIATIVES[id]
	if Game.minutes + int(initiative["minutes"]) > 23 * 60:
		return "Jest za późno; spotkanie musi skończyć się do 23:00."
	if Game.energy < float(initiative["energy"]):
		return "Za mało energii na spotkanie."
	if Game.modal_open or Game.cutscene:
		return "Najpierw zamknij inne okno lub zakończ scenę."
	return ""


static func run_initiative(id: String) -> bool:
	var reason := run_reason(id)
	if reason != "":
		return false
	var initiative: Dictionary = INITIATIVES[id]
	# Znacznik przed upływem czasu zabezpiecza przed ponownym wejściem z sygnału.
	Game.group_state["done_week"][id] = week_id()
	Game.advance_time(int(initiative["minutes"]))
	Parish.apply_effects({"energy": -int(initiative["energy"])})
	var satisfaction_changes := _apply_initiative_groups(id, initiative["groups"])
	for group_id_variant in initiative["size_groups"]:
		var group_id := str(group_id_variant)
		grow({group_id: initiative["size_groups"][group_id_variant]},
			"Spotkanie: %s — nastawienie %+d, liczebność" % [
				initiative["label"], int(satisfaction_changes.get(group_id, 0))])
	Career.record("groups", 2)
	var text := "%s: spotkanie trwało %d min, energia -%d." % [
		initiative["label"], initiative["minutes"], initiative["energy"]]
	Game.add_log(text)
	Career.add_chronicle(text)
	Game.state_changed.emit()
	return true


static func _row(satisfaction: int, size: int, day: int, text: String, delta: int) -> Dictionary:
	var safe_satisfaction := clampi(satisfaction, 0, 100)
	var safe_size := clampi(size, 1, 500)
	return {"satisfaction": safe_satisfaction, "influence": _influence(safe_size, safe_satisfaction),
		"size": safe_size, "last_change": {"day": maxi(1, day), "text": text, "delta": delta}}


static func _influence(size: int, satisfaction: int) -> int:
	return clampi(int(round(size * 0.4 + satisfaction * 0.25)), 0, 100)


static func _refresh_game(game: Node) -> void:
	var rows: Dictionary = game.get("groups")
	for id in GROUP_IDS:
		var row: Dictionary = rows[id]
		row["satisfaction"] = clampi(int(row.get("satisfaction", 50)), 0, 100)
		row["size"] = clampi(int(row.get("size", START_SIZES[id])), 1, 500)
		row["influence"] = _influence(int(row["size"]), int(row["satisfaction"]))
	game.set("trad", int(rows["seniorzy"]["satisfaction"]))
	game.set("young", int(rows["rodziny"]["satisfaction"]))
	var flags_value: Variant = game.get("flags")
	var flags: Dictionary = flags_value if flags_value is Dictionary else {}
	flags["group_fracture"] = _fracture_members(game).size() >= 2
	game.set("flags", flags)


static func _fracture_members(game: Node) -> Array[String]:
	var result: Array[String] = []
	var rows: Dictionary = game.get("groups")
	for id in GROUP_IDS:
		var row: Dictionary = rows[id]
		if int(row["satisfaction"]) < 30 and int(row["influence"]) > 60:
			result.append(id)
	return result


static func _apply_initiative_groups(initiative_id: String, deltas: Dictionary) -> Dictionary:
	var initiative: Dictionary = INITIATIVES[initiative_id]
	var actual_changes := {}
	for id_variant in deltas:
		var id := str(id_variant)
		var row: Dictionary = Game.groups[id]
		var before := int(row["satisfaction"])
		var after := clampi(before + int(deltas[id_variant]), 0, 100)
		row["satisfaction"] = after
		actual_changes[id] = after - before
		row["last_change"] = {"day": Game.day, "text": "Spotkanie: %s" % initiative["label"], "delta": after - before}
	_refresh_game(Game)
	return actual_changes


static func _normalize_week_map(value: Variant) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	var result := {}
	for id in INITIATIVE_IDS:
		if source.has(id):
			result[id] = int(source[id])
	return result


static func _ensure_game() -> void:
	if not Game.groups is Dictionary or not Game.community is Dictionary or not Game.group_state is Dictionary:
		normalize(Game)
		return
	for id in GROUP_IDS:
		if not Game.groups.has(id) or not Game.groups[id] is Dictionary:
			normalize(Game)
			return
	for id in INITIATIVE_IDS:
		if not Game.community.has(id):
			normalize(Game)
			return
	for key in ["last_week", "paid_week", "done_week"]:
		if not Game.group_state.has(key):
			normalize(Game)
			return
