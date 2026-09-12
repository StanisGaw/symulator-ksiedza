class_name CheckProgression
## Deterministyczne scenariusze regresyjne rozwoju 2.5. Stan Game jest odtwarzany,
## a migracja korzysta wyłącznie ze słowników JSON w pamięci, bez dostępu do user://.


class ProgressionFixture extends Node:
	var stats: Variant = {"charyzma": 20, "wiarygodnosc": -2, "obca": 8}
	var stat_xp: Variant = {"charyzma": 7, "wiarygodnosc": 99, "obca": 4}
	var talents: Variant = ["admin_inspection", "admin_accounts", "admin_accounts", "obcy"]


static func run() -> Array[String]:
	var problems: Array[String] = []
	var before := _snapshot()
	_check_reset_normalize_and_migration(problems)
	_check_xp_sources_and_range(problems)
	_check_unlock_rules(problems)
	_check_option_needs_scale_and_idempotence(problems)
	_check_administrator_talents(problems)
	_check_pastor_talents(problems)
	_check_host_talents(problems)
	_check_save_round_trip(problems)
	_restore(before)
	return problems


static func report() -> bool:
	var problems := run()
	for problem in problems:
		printerr("BŁĄD ROZWOJU  " + problem)
	if problems.is_empty():
		print("Rozwój 2.5: cechy, progi, skalowanie, talenty i migracja są spójne.")
	return problems.is_empty()


static func _check_reset_normalize_and_migration(problems: Array[String]) -> void:
	var fixture := ProgressionFixture.new()
	Progression.normalize(fixture)
	_expect(problems, fixture.stats == {"charyzma": 10, "wiarygodnosc": 1, "zarzadzanie": 3,
		"wplywy": 3, "odpornosc": 3}, "normalizacja uzupełnia pięć cech i ogranicza je do 1–10")
	_expect(problems, fixture.stat_xp["charyzma"] == 0 and fixture.stat_xp["wiarygodnosc"] == 7 \
			and fixture.talents == ["admin_accounts", "admin_inspection"],
		"normalizacja ogranicza XP, usuwa obce i powtórzone talenty oraz zachowuje zależności")
	fixture.free()

	_reset_state()
	_expect(problems, Game.stats.values().all(func(value: Variant) -> bool: return int(value) == 3) \
			and Game.stat_xp.values().all(func(value: Variant) -> bool: return int(value) == 0) and Game.talents.is_empty(),
		"nowy rozwój zaczyna z pięcioma cechami 3/10, zerowym XP i bez talentów")
	_expect(problems, "bez wyraźnej specjalizacji" in Progression.profile_text(),
		"równy profil nie ogłasza sztucznej specjalizacji ani tej samej słabości")

	var legacy: Dictionary = JSON.parse_string(JSON.stringify({"version": SaveGame.VERSION, "day": 20, "rank": "proboszcz"}))
	SaveGame.apply(Game, legacy)
	_expect(problems, Game.stats.size() == 5 and Game.stats["charyzma"] == 3 \
			and Game.stat_xp["zarzadzanie"] == 0 and Game.talents.is_empty(),
		"stary zapis migruje do domyślnego rozwoju bez przyznawania talentów")


static func _check_xp_sources_and_range(problems: Array[String]) -> void:
	_reset_state()
	Progression.record("mass")
	Progression.record("confession")
	Progression.record("honest_report")
	Progression.record("balanced_week")
	Progression.record("media")
	Progression.record("festyn")
	Progression.record("short_sleep")
	_expect(problems, Game.stat_xp == {"charyzma": 2, "wiarygodnosc": 3, "zarzadzanie": 3,
		"wplywy": 4, "odpornosc": 1}, "każde wykonane źródło daje XP właściwej cesze i w umówionej wysokości")
	var before := Game.stat_xp.duplicate(true)
	Progression.record("unknown")
	_expect(problems, Game.stat_xp == before, "nieznany lub niewykonany rodzaj nie daje XP")
	for _i in 6:
		Progression.record("mass")
	_expect(problems, Game.stats["charyzma"] == 4 and Game.stat_xp["charyzma"] == 0,
		"osiem XP podnosi cechę o jeden punkt i zużywa próg")
	Game.stats["odpornosc"] = 9
	Game.stat_xp["odpornosc"] = 7
	Progression.record("short_sleep")
	_expect(problems, Game.stats["odpornosc"] == 10 and Game.stat_xp["odpornosc"] == 0,
		"cecha dochodzi do 10 i nie przenosi zbędnego XP")
	for _i in 20:
		Progression.record("short_sleep")
	_expect(problems, Game.stats["odpornosc"] == 10 and Game.stat_xp["odpornosc"] == 0,
		"cecha ani XP nie wychodzą poza zakres na maksimum")
	Game.stats["charyzma"] = 7
	Game.stats["zarzadzanie"] = 1
	Game.stats["odpornosc"] = 3
	var profile := Progression.profile_text()
	_expect(problems, "charyzmatyczny duszpasterz" in profile and "Zarządzanie 1/10" in profile \
			and "Odporność 3/10" in profile, "profil nazywa specjalizację, słabość i pokazuje wszystkie wartości")


static func _check_unlock_rules(problems: Array[String]) -> void:
	_reset_state()
	Game.respect = 100
	_expect(problems, Progression.unlock_reason("admin_inspection").begins_with("Najpierw") \
			and not Progression.unlock("admin_inspection") and Game.respect == 100,
		"drugi talent wymaga pierwszego i odmowa nic nie kosztuje")
	Game.respect = 19
	_expect(problems, "Potrzeba 20" in Progression.unlock_reason("admin_accounts") \
			and not Progression.unlock("admin_accounts") and Game.respect == 19,
		"pierwszy talent kosztuje 20 szacunku")
	Game.respect = 100
	_expect(problems, Progression.unlock("admin_accounts") and Game.respect == 80,
		"odblokowanie pierwszego talentu pobiera dokładnie 20 szacunku")
	_expect(problems, not Progression.unlock("admin_accounts") and Game.respect == 80 \
			and "już" in Progression.unlock_reason("admin_accounts"),
		"tego samego talentu nie można kupić drugi raz")
	_expect(problems, Progression.unlock("admin_inspection") and Game.respect == 45,
		"drugi talent po spełnieniu zależności kosztuje dokładnie 35 szacunku")
	_expect(problems, not Progression.unlock("missing") and Progression.unlock_reason("missing") == "Nieznany talent.",
		"nieznany identyfikator nie zmienia stanu")


static func _check_option_needs_scale_and_idempotence(problems: Array[String]) -> void:
	_reset_state()
	var gated := {"label": "Przekonaj radę", "needs": {"charyzma": 4}, "effects": {"reputation": 2}}
	var state := Progression.option_state(gated)
	_expect(problems, not state["enabled"] and "Charyzma 4/10" in state["reason"],
		"opcja poniżej progu zostaje widoczna z konkretnym wyjaśnieniem")
	Game.stats["charyzma"] = 4
	_expect(problems, Progression.option_state(gated) == {"enabled": true, "reason": ""},
		"opcja odblokowuje się dokładnie na wymaganym progu")

	Game.stats["zarzadzanie"] = 5
	var source := {"label": "Rozlicz", "scale": "zarzadzanie", "effects": {"money": 100, "reputation": 1}}
	var source_before := source.duplicate(true)
	var resolved := Progression.resolve_option(source)
	_expect(problems, resolved["effects"] == {"money": 120, "reputation": 1} and not resolved.has("scale") \
			and source == source_before, "zarządzanie skaluje tylko dodatnie pieniądze i nie mutuje definicji")
	_expect(problems, Progression.resolve_option(resolved) == resolved,
		"ponowne rozliczenie opcji jest bajtowo stabilne")
	var expense := Progression.resolve_option({"scale": "zarzadzanie", "effects": {"money": -100, "curia": 3}})
	_expect(problems, expense["effects"] == {"money": -90, "curia": 3},
		"zarządzanie zmniejsza ujemny koszt bez skalowania innych skutków")


static func _check_administrator_talents(problems: Array[String]) -> void:
	_reset_state()
	Game.respect = 100
	_expect(problems, Progression.investment_cost(1000) == 1000 \
			and Finance.investment_cost("sound") == 3000 and Repairs.repair_cost("car") == 2400,
		"bez talentu koszty inwestycji i napraw nie mają premii")
	Progression.unlock("admin_accounts")
	_expect(problems, Progression.investment_cost(1000) == 900 \
			and Finance.investment_cost("sound") == 2700 and Repairs.repair_cost("car") == 2160,
		"Administrator obniża oba publiczne rodzaje kosztów o 10%")

	Game.location = "rectory"
	Game.minutes = 360.0
	Game.energy = 100.0
	Game.condition = 50
	Game.done_today = {}
	Game.do_activity("inspection")
	_expect(problems, Game.condition == 50 and Game.minutes == 360.0,
		"sam pierwszy talent nie odblokowuje przeglądu")
	Progression.unlock("admin_inspection")
	Game.do_activity("inspection")
	_expect(problems, Game.condition == 53 and Game.minutes == 405.0 and Game.energy == 90.0 \
			and Game.done_today.has("inspection"), "Przegląd gospodarski odblokowuje czynność 45 min, 10 energii, stan +3")


static func _check_pastor_talents(problems: Array[String]) -> void:
	_reset_state()
	Game.respect = 100
	_expect(problems, Progression.attendance(100) == 100 and Progression.activity_minutes("visit_sick", 90) == 90,
		"bez talentów duszpasterza frekwencja i czas wizyty się nie zmieniają")
	Progression.unlock("pastor_presence")
	_expect(problems, Progression.attendance(100) == 110 and Progression.attendance(480) == 500,
		"Duszpasterz podnosi frekwencję o 10% z limitem 500")
	Progression.unlock("pastor_visits")
	_expect(problems, Progression.activity_minutes("visit_sick", 90) == 75 \
			and Progression.activity_minutes("confession", 45) == 45,
		"Blisko ludzi skraca wyłącznie odwiedziny chorego o 15 minut")


static func _check_host_talents(problems: Array[String]) -> void:
	_reset_state()
	Game.respect = 100
	var media := {"label": "Odpowiedz", "effects": {"reputation": -1}}
	_expect(problems, Progression.resolve_option(media, "media")["effects"]["reputation"] == -1,
		"bez talentu odpowiedź w mediach nie dostaje premii")
	Progression.unlock("host_media")
	var media_resolved := Progression.resolve_option(media, "media")
	_expect(problems, media_resolved["effects"]["reputation"] == 1 \
			and Progression.resolve_option(media_resolved, "media") == media_resolved,
		"Gospodarz dodaje 2 reputacji do odpowiedzi w mediach dokładnie raz")
	Progression.unlock("host_curia")
	var honest := Progression.resolve_option({"label": "Napisz prawdę", "honest": true,
		"effects": {"curia": 1}}, "event")
	var special := Progression.resolve_option({"label": "Wyślij liczby", "special": "honest_report"}, "event")
	_expect(problems, honest["effects"]["curia"] == 3 and special["effects"]["curia"] == 2 \
			and Progression.resolve_option(honest) == honest,
		"Zaufanie kurii dodaje 2 za oba jawne rodzaje uczciwej odpowiedzi dokładnie raz")


static func _check_save_round_trip(problems: Array[String]) -> void:
	_reset_state()
	Game.stats = {"charyzma": 6, "wiarygodnosc": 5, "zarzadzanie": 4, "wplywy": 7, "odpornosc": 2}
	Game.stat_xp = {"charyzma": 1, "wiarygodnosc": 2, "zarzadzanie": 3, "wplywy": 4, "odpornosc": 5}
	Game.talents = ["pastor_presence", "pastor_visits"]
	var data := {"version": SaveGame.VERSION}
	for key in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS:
		data[key] = _copy(Game.get(key))
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(data))
	Progression.reset(Game)
	SaveGame.apply(Game, parsed)
	_expect(problems, Game.stats == {"charyzma": 6, "wiarygodnosc": 5, "zarzadzanie": 4,
		"wplywy": 7, "odpornosc": 2} and Game.stat_xp == {"charyzma": 1, "wiarygodnosc": 2,
		"zarzadzanie": 3, "wplywy": 4, "odpornosc": 5} and Game.talents == ["pastor_presence", "pastor_visits"],
		"JSON i prawdziwy SaveGame.apply zachowują cechy, XP i zależne talenty")


static func _reset_state() -> void:
	Game.day = 1
	Progression.reset(Game)
	Career.reset(Game)
	Game.respect = 0
	Game.money = 12000
	Game.reputation = 50
	Game.condition = 50
	Game.curia = 50
	Game.location = "outside"
	Game.minutes = 360.0
	Game.energy = 100.0
	Game.done_today = {}
	Game.modal_open = false
	Game.cutscene = false
	Game.cutscene_id = ""


static func _snapshot() -> Dictionary:
	var result := {}
	for key in _state_keys():
		result[key] = _copy(Game.get(key))
	return result


static func _restore(snapshot: Dictionary) -> void:
	for key in snapshot:
		Game.set(key, _copy(snapshot[key]))


static func _state_keys() -> Array[String]:
	var result: Array[String] = []
	for key_variant in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS:
		var key := str(key_variant)
		if not result.has(key):
			result.append(key)
	for key in ["location", "minutes", "modal_open", "cutscene", "cutscene_id"]:
		if not result.has(key):
			result.append(key)
	return result


static func _copy(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


static func _expect(problems: Array[String], condition: bool, message: String) -> void:
	if not condition:
		problems.append(message)
