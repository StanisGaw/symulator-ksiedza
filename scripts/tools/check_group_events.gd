class_name CheckGroupEvents
## Zachowanie integracji decyzji z grupami. Test używa wyłącznie kopii stanu w pamięci.


static func run() -> Array[String]:
	var before := _snapshot()
	var problems: Array[String] = []
	_check_catalog_decoration(problems)
	_check_actual_decision(problems)
	_check_inbox_decision(problems)
	_check_frozen_approval_roundtrip(problems)
	_check_delayed_roundtrip(problems)
	_check_faction_crisis(problems)
	_restore(before)
	return problems


static func report() -> bool:
	var problems := run()
	for problem in problems:
		printerr("BŁĄD GRUP/WYDARZEŃ  " + problem)
	if problems.is_empty():
		print("Wydarzenia grup 2.6: pokrycie, decyzje, zgody, zapis i kryzys frakcji spójne.")
	return problems.is_empty()


static func _check_catalog_decoration(problems: Array[String]) -> void:
	for entry in Events.catalogs():
		for event in entry[1]:
			_expect(problems, GroupEvents.has_complete_mapping(event),
				"%s/%s ma mapę dla każdej opcji" % [entry[0], event.get("id", "?")])
			var twice := GroupEvents.decorate_event(event)
			_expect(problems, twice == event, "%s dekoruje się idempotentnie" % event.get("id", "?"))
			for option in event.get("options", []):
				var effects: Dictionary = option.get("effects", {})
				var deltas: Dictionary = effects.get("groups", {})
				_expect(problems, deltas.size() >= 2,
					"%s: opcja dotyka co najmniej dwóch grup" % event.get("id", "?"))
				_expect(problems, _distinct_nonzero(deltas) >= 2,
					"%s: opcja ma różne reakcje grup" % event.get("id", "?"))
				_expect(problems, not effects.has("trad") and not effects.has("young"),
					"%s: legacy nie zostaje obok nested groups" % event.get("id", "?"))
	var raw: Dictionary = Events.SCRIPTED[0]
	_expect(problems, (raw["options"][0]["effects"] as Dictionary).has("trad")
		and not (raw["options"][0]["effects"] as Dictionary).has("groups"),
		"dekorowanie nie mutuje źródłowych stałych")
	var fixture := {"id": "fixture_unknown", "options": [{"label": "x", "effects": {"trad": 3}}]}
	_expect(problems, GroupEvents.decorate_event(fixture) == fixture,
		"nieznany identyfikator testowy pozostaje nietknięty")


static func _check_actual_decision(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	var event := Events.by_id("funeral")
	EventFlow.choose_option(event, 0)
	_expect(problems, _sat("seniorzy") == 60 and _sat("rodziny") == 53
		and _sat("potrzebujacy") == 52,
		"rzeczywista decyzja stosuje jawne reakcje grup")
	_expect(problems, Game.trad == _sat("seniorzy") and Game.young == _sat("rodziny"),
		"aliasy po decyzji są zsynchronizowane")


static func _check_inbox_decision(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	var message := Phone.curia_mail("próba reakcji grup", Phone.excuses())
	_expect(problems, GroupEvents.decorate_message(message) == message,
		"wygenerowana wiadomość nie podwaja reakcji przy ponownej dekoracji")
	Inbox.send(message)
	_roundtrip()
	var working_before := _sat("pracujacy")
	var owners_before := _sat("przedsiebiorcy")
	_expect(problems, Inbox.answer(0, 0), "rzeczywista odpowiedź w skrzynce wykonuje opcję")
	_expect(problems, _sat("pracujacy") == working_before + 3
		and _sat("przedsiebiorcy") == owners_before + 2,
		"odpowiedź w telefonie stosuje własne reakcje grup")
	_expect(problems, not Inbox.answer(0, 0) and _sat("pracujacy") == working_before + 3,
		"ponowna odpowiedź nie powiela reakcji grup")


static func _check_frozen_approval_roundtrip(problems: Array[String]) -> void:
	_reset_state("wikary")
	var event := Events.by_id("mass_hour")
	EventFlow.choose_option(event, 0)
	_expect(problems, Game.career.get("approvals", []).size() == 1,
		"zmiana godzin tworzy jedno oczekujące uzgodnienie")
	var frozen: Dictionary = Game.career["approvals"][0]["option"]
	var frozen_groups: Dictionary = frozen.get("effects", {}).get("groups", {})
	_expect(problems, int(frozen_groups.get("seniorzy", 0)) == 8
		and int(frozen_groups.get("rodziny", 0)) == -6,
		"zgoda przechowuje zamrożone nested groups bez legacy")
	_roundtrip()
	var approval: Dictionary = Game.career["approvals"][0]
	Game.day = int(approval["due_day"])
	Career.morning()
	_expect(problems, _sat("seniorzy") == 63 and _sat("rodziny") == 44
		and _sat("pracujacy") == 47 and _sat("mlodziez") == 48,
		"zgoda po JSON wykonuje reakcje dokładnie raz")
	Career.morning()
	_expect(problems, _sat("seniorzy") == 63 and _sat("rodziny") == 44,
		"kolejne rozliczenie nie powiela grup ze zgody")


static func _check_delayed_roundtrip(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	EventFlow.choose_option(Events.by_id("local_media"), 1)
	_expect(problems, Game.scheduled.size() == 1, "losowa odpowiedź planuje jedną gałąź")
	_roundtrip()
	var item: Dictionary = Game.scheduled[0]
	var hit_groups: Dictionary = item.get("effects", {}).get("groups", {})
	var miss_groups: Dictionary = item.get("else_effects", {}).get("groups", {})
	_expect(problems, hit_groups == {"pracujacy": -3, "przedsiebiorcy": -2}
		and miss_groups == {"pracujacy": 2, "przedsiebiorcy": 1},
		"obie gałęzie nested groups przeżywają JSON")
	var working_before := _sat("pracujacy")
	Parish.apply_effects(item["effects"], "Wynik publikacji")
	_expect(problems, _sat("pracujacy") == working_before - 3,
		"trafiona gałąź wykonuje zapisany skutek grup")

	_reset_state("proboszcz")
	EventFlow.choose_option(Events.by_id("local_media"), 1)
	_roundtrip()
	item = Game.scheduled[0]
	working_before = _sat("pracujacy")
	Parish.apply_effects(item["else_effects"], "Brak publikacji")
	_expect(problems, _sat("pracujacy") == working_before + 2,
		"przeciwna gałąź wykonuje własny skutek grup")


static func _check_faction_crisis(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	Game.reputation = 10
	Game.groups["pracujacy"]["satisfaction"] = 25
	Game.groups["seniorzy"]["satisfaction"] = 25
	Groups.refresh()
	_expect(problems, bool(Game.flags.get("group_fracture", false)),
		"dwie wpływowe niezadowolone grupy ustawiają rozłam")
	var due := Events.due_events(Game)
	var ids: Array[String] = []
	for event in due:
		ids.append(str(event.get("id", "")))
	_expect(problems, ids.has("group_faction") and not ids.has("revolt"),
		"kryzys frakcji ma pierwszeństwo przed ogólnym buntem")
	var crisis := Events.by_id("group_faction")
	_expect(problems, str(crisis.get("title", "")).contains("Pracujący")
		and str(crisis.get("title", "")).contains("Seniorzy"),
		"runtime wymienia rzeczywiste strony w tytule")
	var all_groups: Dictionary = crisis["options"][0].get("effects", {}).get("groups", {})
	_expect(problems, all_groups.size() == Groups.GROUP_IDS.size()
		and _distinct_nonzero(all_groups) == Groups.GROUP_IDS.size(),
		"kosztowny plan poprawia wszystkie sześć grup o różne wartości")
	var money_before := Game.money
	EventFlow.choose_option(crisis, 0)
	_expect(problems, Game.money == money_before - 9000, "plan dla wszystkich ma realny koszt")
	_expect(problems, not bool(Game.flags.get("group_fracture", true)),
		"poprawa rzeczywistych stron usuwa próg rozłamu")
	_expect(problems, Game.career.get("resolved_crises", []).has("group_faction"),
		"usunięty próg zapisuje rozwiązanie kryzysu frakcji")

	_reset_state("proboszcz")
	Game.reputation = 10
	Groups.refresh()
	ids.clear()
	for event in Events.due_events(Game):
		ids.append(str(event.get("id", "")))
	_expect(problems, ids.has("revolt") and not ids.has("group_faction"),
		"ogólny bunt nadal działa bez rozłamu grup")


static func _reset_state(rank: String) -> void:
	Game.day = 20
	Game.money = 20000
	Game.reputation = 50
	Game.condition = 50
	Game.trad = 55
	Game.young = 50
	Game.curia = 50
	Game.energy = 100.0
	Game.week_income = 0
	Game.week_expenses = 0
	Game.sunday_hours = Game.MASS_HOURS_SUNDAY.duplicate()
	Game.weekday_hours = Game.MASS_HOURS_WEEKDAY.duplicate()
	Game.scheduled = []
	Game.fired_events = []
	Game.event_cooldowns = {}
	Game.flags = {}
	Game.pending_events = []
	Game.phone_inbox = []
	Game.bank_log = []
	Game.log_lines = []
	Career.reset(Game)
	Progression.reset(Game)
	Groups.reset(Game, 55, 50)
	Game.rank = rank


static func _roundtrip() -> void:
	var data: Dictionary = {}
	for key in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS:
		data[key] = EventFlow._copy_value(Game.get(key))
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	SaveGame.apply(Game, parsed)


static func _snapshot() -> Dictionary:
	var state: Dictionary = {}
	for key in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS:
		state[key] = EventFlow._copy_value(Game.get(key))
	return state


static func _restore(state: Dictionary) -> void:
	for key in state:
		Game.set(key, EventFlow._copy_value(state[key]))
	Groups.normalize(Game)
	Progression.normalize(Game)
	Career.normalize(Game)


static func _sat(id: String) -> int:
	return int(Game.groups[id]["satisfaction"])


static func _distinct_nonzero(deltas: Dictionary) -> int:
	var values: Array[int] = []
	for value in deltas.values():
		var delta := int(value)
		if delta != 0 and not values.has(delta):
			values.append(delta)
	return values.size()


static func _expect(problems: Array[String], condition: bool, message: String) -> void:
	if not condition:
		problems.append(message)
