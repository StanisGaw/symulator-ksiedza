class_name CheckGroups
## Scenariusze regresyjne grup 2.6. Korzystają z prawdziwych publicznych punktów
## integracji, nie zapisują user:// i po zakończeniu odtwarzają cały zapisany stan.


class GroupsFixture extends Node:
	var day := 14
	var money := 4321
	var trad := 44
	var young := 66
	var flags: Dictionary = {}
	var groups: Variant = {
		"seniorzy": {"satisfaction": 140, "size": 0, "last_change": "bad"},
		"rodziny": {"satisfaction": -20, "size": 900},
	}
	var community: Variant = {"caritas": 1, "obca": true}
	var group_state: Variant = {"last_week": 5.0, "paid_week": {"caritas": 4.0, "obca": 9},
		"done_week": {"swietlica": 3.0}}


static func run() -> Array[String]:
	var problems: Array[String] = []
	var before := _snapshot()
	_check_reset_normalize_and_migration(problems)
	_check_effects_aliases_support_and_bounds(problems)
	_check_fracture(problems)
	_check_week_calendar_and_actions(problems)
	_check_funding_forecast_and_idempotence(problems)
	_check_initiative_run(problems)
	_check_save_round_trip(problems)
	_restore(before)
	return problems


static func report() -> bool:
	var problems := run()
	for problem in problems:
		printerr("BŁĄD GRUP  " + problem)
	if problems.is_empty():
		print("Grupy 2.6: migracja, wpływ, frakcje, wspólnoty i tygodnie są spójne.")
	return problems.is_empty()


static func _check_reset_normalize_and_migration(problems: Array[String]) -> void:
	var fixture := GroupsFixture.new()
	Groups.normalize(fixture)
	_expect(problems, fixture.day == 14 and fixture.money == 4321,
		"normalizacja grup nie zmienia dnia ani finansów")
	_expect(problems, fixture.groups.size() == 6 and fixture.groups["seniorzy"]["satisfaction"] == 100 \
			and fixture.groups["seniorzy"]["size"] == 1 and fixture.groups["rodziny"]["satisfaction"] == 0 \
			and fixture.groups["rodziny"]["size"] == 500,
		"normalizacja uzupełnia sześć grup i ogranicza zadowolenie oraz liczebność")
	_expect(problems, fixture.trad == 100 and fixture.young == 0 \
			and fixture.community == {"caritas": true, "swietlica": false, "katecheza": false},
		"normalizacja synchronizuje aliasy i usuwa obce wspólnoty")
	_expect(problems, fixture.group_state["last_week"] is int and fixture.group_state["paid_week"] == {"caritas": 4} \
			and fixture.group_state["done_week"] == {"swietlica": 3},
		"normalizacja przywraca całkowite identyfikatory tygodni i znane klucze")
	fixture.free()

	_reset_state()
	_expect(problems, Game.groups["seniorzy"]["satisfaction"] == 55 \
			and Game.groups["rodziny"]["satisfaction"] == 50 and Game.groups["pracujacy"]["size"] == 160,
		"nowa gra ma umówione nastroje i liczebności sześciu grup")
	var legacy: Dictionary = JSON.parse_string(JSON.stringify({"version": SaveGame.VERSION, "day": 31,
		"rank": "proboszcz", "trad": 73, "young": 24, "money": 7654}))
	SaveGame.apply(Game, legacy)
	_expect(problems, Game.groups["seniorzy"]["satisfaction"] == 73 \
			and Game.groups["rodziny"]["satisfaction"] == 24 and Game.trad == 73 and Game.young == 24,
		"stary zapis migruje trad do seniorów i young do młodych rodzin")
	_expect(problems, Game.money == 7654 and Game.day == 31 and Game.community.values().all(
		func(value: Variant) -> bool: return not bool(value)), "migracja nie zmienia finansów i nie przyznaje wspólnot")


static func _check_effects_aliases_support_and_bounds(problems: Array[String]) -> void:
	_reset_state()
	Groups.apply_effects({"seniorzy": 60, "rodziny": -70, "mlodziez": 5, "unknown": 99}, "Decyzja testowa")
	_expect(problems, Game.groups["seniorzy"]["satisfaction"] == 100 and Game.trad == 100 \
			and Game.groups["rodziny"]["satisfaction"] == 0 and Game.young == 0,
		"zagregowane skutki grup są ograniczone 0–100 i synchronizują oba aliasy")
	_expect(problems, Game.groups["seniorzy"]["last_change"] == {"day": 1,
		"text": "Decyzja testowa", "delta": 45}, "last_change zapisuje rzeczywistą zmianę po ograniczeniu")
	_expect(problems, Game.groups["mlodziez"]["influence"] == 46,
		"wpływ odświeża się według round(size*0.4+satisfaction*0.25)")

	# Bezpośrednia zmiana dawnego aliasu jest bazą, a Parish dokłada ją tylko raz.
	Game.trad = 40
	Parish.apply_effects({"trad": 5, "groups": {"seniorzy": 2}}, "Łączny skutek")
	_expect(problems, Game.groups["seniorzy"]["satisfaction"] == 47 and Game.trad == 47,
		"legacy trad i nested groups agregują się raz od bieżącej wartości aliasu")
	var support_before := Groups.support()
	Groups.grow({"mlodziez": 1000, "rodziny": -1000}, "Zmiana liczebności")
	_expect(problems, Game.groups["mlodziez"]["size"] == 500 and Game.groups["rodziny"]["size"] == 1 \
			and Game.groups["rodziny"]["last_change"]["delta"] == -119,
		"grow ogranicza liczebność 1–500 i zapisuje rzeczywistą zmianę")
	_expect(problems, not is_equal_approx(Groups.support(), support_before),
		"wsparcie jest średnią zadowolenia ważoną aktualną liczebnością")


static func _check_fracture(problems: Array[String]) -> void:
	_reset_state()
	Game.groups["pracujacy"]["satisfaction"] = 20
	Game.groups["seniorzy"]["satisfaction"] = 20
	Groups.refresh()
	_expect(problems, Groups.fracture_members() == ["pracujacy", "seniorzy"] \
			and Game.flags["group_fracture"], "dwie niezadowolone wpływowe grupy ustawiają flagę frakcji i jawne strony")
	Groups.apply_effects({"seniorzy": 10}, "Ugoda")
	_expect(problems, Groups.fracture_members() == ["pracujacy"] and not Game.flags["group_fracture"],
		"wyjście jednej strony ponad próg 30 natychmiast czyści flagę frakcji")


static func _check_week_calendar_and_actions(problems: Array[String]) -> void:
	_reset_state()
	_set_monday_start()
	var first_week := Groups.week_id()
	for day in range(1, 8):
		Game.day = day
		_expect(problems, Groups.week_id() == first_week, "poniedziałek–niedziela mają wspólny identyfikator tygodnia")
	Game.day = 8
	_expect(problems, Groups.week_id() == first_week + 1, "kolejny poniedziałek zaczyna następny stabilny tydzień")

	_reset_state()
	_set_monday_start()
	Game.money = 1000
	Game.reputation = 50
	Game.curia = 50
	# Trzy progi: zbiórka, wolontariusze, skarga. Pozostałe grupy poniżej wpływu 71.
	for id in Groups.GROUP_IDS:
		Game.groups[id]["size"] = 1
	Game.groups["mlodziez"].merge({"size": 200, "satisfaction": 70}, true)
	Game.groups["pracujacy"].merge({"size": 160, "satisfaction": 50}, true)
	Game.groups["seniorzy"].merge({"size": 180, "satisfaction": 20}, true)
	Groups.refresh()
	var lines := Groups.weekly()
	_expect(problems, Game.money == 1400 and Game.reputation == 51 and Game.curia == 48,
		"wpływowe grupy kolejno organizują zbiórkę, wolontariat albo skargę według nastroju")
	_expect(problems, lines.size() == 3 and "Młodzież" in lines[0] and "Pracujący" in lines[1] \
			and "Seniorzy" in lines[2], "raport tygodniowy wymienia każdą działającą stronę")
	_expect(problems, Groups.weekly().is_empty() and Game.money == 1400 and Game.reputation == 51 and Game.curia == 48,
		"działania grup nie powtarzają się drugi raz w tym samym tygodniu")
	_expect(problems, Game.faith == 0, "zbiórki i działania grup nie tworzą sztucznie wiary")


static func _check_funding_forecast_and_idempotence(problems: Array[String]) -> void:
	_reset_state()
	_set_monday_start()
	Game.money = 10000
	var ordinary := Finance.forecast()
	var activation := Groups.activation_forecast("caritas")
	_expect(problems, Groups.weekly_cost() == 0 and Groups.activation_cost("caritas") == 300 \
			and int(ordinary["balance"]) - int(activation["balance"]) == 600 \
			and int(activation["costs"]) == int(ordinary["costs"]) + 300,
		"prognoza nowej wspólnoty obejmuje opłatę bieżącą i dodatkowe 300 zł w poniedziałek")
	_expect(problems, Groups.set_initiative("caritas", true) and Game.money == 9700 \
			and Groups.weekly_cost() == 300 and Groups.activation_cost("caritas") == 0,
		"pierwsza aktywacja od razu pobiera bieżący koszt i włącza koszt stały")
	var active_forecast := Groups.activation_forecast("caritas")
	_expect(problems, active_forecast == Finance.forecast(), "aktywna wspólnota pokazuje zwykłą prognozę bez podwójnej dopłaty")
	Groups.set_initiative("caritas", false)
	Groups.set_initiative("caritas", true)
	_expect(problems, Game.money == 9700 and Groups.activation_cost("caritas") == 0,
		"wyłączenie nie zwraca pieniędzy, a ponowne włączenie w tygodniu nie pobiera drugi raz")

	Game.day = 8
	var before_settlement := Game.money
	Finance.weekly_settlement()
	var expected_budget := 4200 + 300
	_expect(problems, before_settlement - Game.money == expected_budget \
			and Game.group_state["paid_week"]["caritas"] == Groups.week_id(),
		"Finance pobiera zwykły budżet i jedną opłatę wspólnoty w następnym tygodniu")
	var after_settlement := Game.money
	Groups.weekly()
	_expect(problems, Game.money == after_settlement, "bezpośrednie ponowienie weekly nie dubluje rozliczenia")

	_reset_state()
	_set_monday_start()
	Game.money = 0
	var before_community: Dictionary = Game.community.duplicate(true)
	_expect(problems, not Groups.set_initiative("swietlica", true) and Game.community == before_community and Game.money == 0,
		"ujemna prognoza wymaga potwierdzenia i anulowanie nie mutuje stanu")
	_expect(problems, Groups.set_initiative("swietlica", true, true) and Game.money == -450,
		"jawnie potwierdzona aktywacja może utworzyć deficyt i pobiera dokładny koszt")


static func _check_initiative_run(problems: Array[String]) -> void:
	_reset_state()
	_set_monday_start()
	Game.community["caritas"] = true
	_expect(problems, "plebanii" in Groups.run_reason("caritas"), "spotkanie wymaga obecności na plebanii")
	Game.location = "rectory"
	Game.modal_open = true
	_expect(problems, Groups.run_reason("caritas") != "", "otwarte okno blokuje wykonanie spotkania")
	Game.minutes = 22.0 * 60.0 + 1.0
	_expect(problems, "23:00" in Groups.run_reason("caritas"), "spotkanie nie może kończyć się po 23:00")
	Game.minutes = 22.0 * 60.0
	Game.energy = 9.0
	_expect(problems, "energii" in Groups.run_reason("caritas"), "spotkanie pilnuje kosztu energii")
	Game.energy = 100.0
	_expect(problems, "zamknij" in Groups.run_reason("caritas"),
		"po sprawdzeniu czasu i energii otwarte okno nadal blokuje wykonanie")
	Game.modal_open = false
	# Testuje tylko koszt spotkania; wcześniejsze msze są już odprawione, więc
	# advance_time nie dokłada tu niezależnych kar za opuszczony plan dnia.
	Game.masses_done = Game.mass_hours_today().duplicate()
	var needy_before: Dictionary = Game.groups["potrzebujacy"].duplicate(true)
	var senior_before: Dictionary = Game.groups["seniorzy"].duplicate(true)
	_expect(problems, Groups.run_initiative("caritas"), "aktywne spotkanie spełniające warunki wykonuje się")
	_expect(problems, Game.minutes == 23.0 * 60.0 and Game.energy == 90.0 \
			and Game.groups["potrzebujacy"]["satisfaction"] == int(needy_before["satisfaction"]) + 6 \
			and Game.groups["seniorzy"]["satisfaction"] == int(senior_before["satisfaction"]) + 2,
		"Caritas zużywa 60 minut i 10 energii oraz poprawia umówione nastroje")
	_expect(problems, Game.groups["potrzebujacy"]["size"] == int(needy_before["size"]) + 3 \
			and Game.groups["seniorzy"]["size"] == int(senior_before["size"]) + 1,
		"spotkanie Caritas zwiększa liczebność według kontraktu 1.1")
	_expect(problems, "nastawienie +6" in Game.groups["potrzebujacy"]["last_change"]["text"] \
			and "+3 osób" in Game.groups["potrzebujacy"]["last_change"]["text"],
		"ostatnia zmiana spotkania opisuje osobno nastrój i faktyczny wzrost liczebności")
	_expect(problems, Game.faith_history == [{"day": 1, "attendance": 0, "sacraments": 0, "groups": 2}] \
			and not Game.chronicle.is_empty(), "wykonane spotkanie daje 2 aktywności wiary i trwały wpis")
	var after := {"minutes": Game.minutes, "energy": Game.energy, "groups": Game.groups.duplicate(true)}
	_expect(problems, not Groups.run_initiative("caritas") and Game.minutes == after["minutes"] \
			and Game.energy == after["energy"] and Game.groups == after["groups"],
		"tej samej wspólnoty nie można przeprowadzić drugi raz w tygodniu")


static func _check_save_round_trip(problems: Array[String]) -> void:
	_reset_state()
	_set_monday_start()
	Game.community["katecheza"] = true
	Game.group_state = {"last_week": Groups.week_id(), "paid_week": {"katecheza": Groups.week_id()},
		"done_week": {"katecheza": Groups.week_id()}}
	Groups.apply_effects({"rodziny": 7}, "Przed zapisem")
	Groups.grow({"rodziny": 4}, "Wzrost przed zapisem")
	var expected_groups: Dictionary = Game.groups.duplicate(true)
	var data := {"version": SaveGame.VERSION}
	for key in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS:
		data[key] = _copy(Game.get(key))
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(data))
	Groups.reset(Game)
	SaveGame.apply(Game, parsed)
	_expect(problems, Game.groups == expected_groups and Game.community["katecheza"],
		"JSON i prawdziwy SaveGame.apply zachowują pełne zagnieżdżone wiersze grup")
	_expect(problems, Game.group_state["last_week"] is int \
			and Game.group_state["paid_week"]["katecheza"] is int \
			and Game.group_state["done_week"]["katecheza"] is int,
		"zapis przywraca tygodnie rozliczenia, opłaty i wykonania jako int")
	_expect(problems, Groups.activation_cost("katecheza") == 0 and Groups.run_reason("katecheza").contains("już"),
		"po wczytaniu nie można ponownie zapłacić ani wykonać inicjatywy w tym tygodniu")


static func _reset_state() -> void:
	Game.day = 1
	Game.start_unix = int(Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 9, "day": 7,
		"hour": 0, "minute": 0, "second": 0}))
	Game.trad = 55
	Game.young = 50
	Game.flags = {}
	Groups.reset(Game, 55, 50)
	Career.reset(Game)
	Game.money = 12000
	Game.week_income = 0
	Game.week_expenses = 0
	Game.reputation = 50
	Game.condition = 55
	Game.curia = 50
	Game.energy = 100.0
	Game.minutes = 360.0
	Game.location = "outside"
	Game.modal_open = false
	Game.cutscene = false
	Game.cutscene_id = ""
	Game.done_today = {}
	Game.bank_log = []
	Game.log_lines = []
	Game.budget = Finance.default_budget()
	Game.built = []
	Game.breakdowns = []


static func _set_monday_start() -> void:
	Game.day = 1
	Game.start_unix = int(Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 9, "day": 7,
		"hour": 0, "minute": 0, "second": 0}))


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
