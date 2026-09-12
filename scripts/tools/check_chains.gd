class_name CheckChains
## Scenariusze mechaniki łańcuchów 2.4. Nie zapisują pliku gracza i odtwarzają
## cały dotknięty stan po wykonaniu.


static func run() -> Array[String]:
	var problems: Array[String] = []
	var before: Dictionary = _snapshot()
	_check_catalog_and_costs(problems)
	_check_choice_and_delayed_branches(problems)
	_check_mass_hours_reaction(problems)
	_check_pastor_approval(problems)
	_check_crisis_recording(problems)
	_restore(before)
	return problems


static func report() -> bool:
	var problems := run()
	for problem in problems:
		printerr("BŁĄD ŁAŃCUCHA  " + problem)
	if problems.is_empty():
		print("Łańcuchy 2.4: flagi, losowe gałęzie, zgody i dziekanat spójne.")
	return problems.is_empty()


static func _check_catalog_and_costs(problems: Array[String]) -> void:
	var root: Dictionary = Events.by_id("dean_indulgence")
	_expect(problems, not root.is_empty(), "początek odpustu jest dostępny przez Events.by_id")
	var options: Array = root.get("options", [])
	_expect(problems, options.size() == 3, "odpust ma dokładnie trzy grywalne gałęzie")
	for index in options.size():
		var option: Dictionary = options[index]
		var effects: Dictionary = option.get("effects", {})
		_expect(problems, int(effects.get("money", 0)) < 0,
			"gałąź %d odpustu ma bezpośredni koszt pieniędzy" % (index + 1))
		var delayed: Dictionary = option.get("delayed", {})
		_expect(problems, int(delayed.get("days", 0)) in range(14, 36),
			"gałąź %d wraca po 14–35 dniach" % (index + 1))
		_expect(problems, delayed.has("chance") and delayed.has("event") and delayed.has("else_event"),
			"gałąź %d ma losowy wynik w dwóch wydarzeniach" % (index + 1))
		_expect(problems, not Events.by_id(str(delayed.get("event", ""))).is_empty()
			and not Events.by_id(str(delayed.get("else_event", ""))).is_empty(),
			"gałąź %d wskazuje istniejące wyniki" % (index + 1))


static func _check_choice_and_delayed_branches(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	var root: Dictionary = Events.by_id("dean_indulgence")
	_expect(problems, Events._eligible(Game, root), "łańcuch jest dostępny bez wcześniejszej zmiany godzin")
	EventFlow.choose_option(root, 0)
	_expect(problems, Game.money == 8000 and str(Game.flags.get("dean_plan", "")) == "together",
		"wybór zapisuje koszt i plan wspólny")
	_expect(problems, Game.scheduled.size() == 1 and int(Game.scheduled[0].get("day", 0)) == 34,
		"wybór planuje skutek po 14 dniach")
	_expect(problems, Game.chronicle.size() == 1, "wykonana decyzja trafia raz do kroniki")
	var item: Dictionary = Game.scheduled[0]
	EventFlow.apply_delayed_branch(item, true)
	_expect(problems, Game.pending_events == ["dean_indulgence_together_success"],
		"trafiona gałąź kolejkuje wynik wspólnego planu")
	_expect(problems, str(Game.flags.get("dean_indulgence_result", "")) == "success",
		"trafiona gałąź zapisuje wynik w flagach")
	var success: Dictionary = Events.by_id("dean_indulgence_together_success")
	_expect(problems, Events._eligible(Game, success), "wynik czyta plan i rezultat z flag")
	EventFlow.choose_option(success, 0)
	_expect(problems, Game.pending_events.is_empty() and bool(Game.flags.get("dean_indulgence_resolved", false)),
		"wybór wyniku usuwa go z trwałej kolejki")

	_reset_state("proboszcz")
	root = Events.by_id("dean_indulgence")
	EventFlow.choose_option(root, 1)
	item = Game.scheduled[0]
	EventFlow.apply_delayed_branch(item, false)
	_expect(problems, Game.pending_events == ["dean_indulgence_rival_failure"],
		"nietrafiona gałąź kolejkuje porażkę wybranego planu")
	_expect(problems, Events._eligible(Game, Events.by_id("dean_indulgence_rival_failure")),
		"porażka rywalizacji wymaga właściwego wcześniejszego wyboru")
	_expect(problems, not Events._eligible(Game, Events.by_id("dean_indulgence_support_failure")),
		"flagi blokują wynik innego wcześniejszego wyboru")


static func _check_mass_hours_reaction(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	var event: Dictionary = Events.by_id("mass_hour")
	EventFlow.choose_option(event, 1)
	_expect(problems, Game.sunday_hours == [11, 19], "zmiana zapisuje nowe godziny mszy")
	_expect(problems, bool(Game.flags.get("mass_hours_changed", false)), "zmiana godzin ustawia flagę decyzji")
	_expect(problems, Game.pending_events == ["neighbour_mass_hours"],
		"zmiana godzin kolejkuje reakcję sąsiedniego proboszcza")
	var reaction: Dictionary = Events.by_id("neighbour_mass_hours")
	_expect(problems, Events._eligible(Game, reaction), "reakcja sąsiada wymaga flagi zmiany godzin")
	EventFlow.choose_option(reaction, 0)
	_expect(problems, Game.pending_events.is_empty() and bool(Game.flags.get("neighbour_mass_hours_seen", false)),
		"odpowiedź sąsiadowi zamyka kolejkę i pamięta relację")


static func _check_pastor_approval(problems: Array[String]) -> void:
	_reset_state("wikary")
	var event: Dictionary = Events.by_id("mass_hour")
	EventFlow.choose_option(event, 0)
	_expect(problems, Game.sunday_hours == Game.MASS_HOURS_SUNDAY and Game.scheduled.is_empty(),
		"wikary nie wykonuje skutków przed zgodą")
	_expect(problems, Game.fired_events.has("mass_hour") and Game.career["approvals"].size() == 1,
		"prośba oznacza jedną decyzję i jedno uzgodnienie")
	var approval: Dictionary = Game.career["approvals"][0]
	Game.day = int(approval["due_day"])
	Career.morning()
	_expect(problems, Game.sunday_hours == [7, 19] and Game.scheduled.size() == 1,
		"zgoda po dwóch dniach wykonuje wszystkie skutki opcji")
	_expect(problems, Game.pending_events == ["neighbour_mass_hours"],
		"zatwierdzona zmiana wywołuje reakcję sąsiada")
	var scheduled_count := Game.scheduled.size()
	Career.morning()
	_expect(problems, Game.scheduled.size() == scheduled_count,
		"ten sam poranek nie wykonuje zgody drugi raz")


static func _check_crisis_recording(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	Game.reputation = 20
	var revolt: Dictionary = Events.by_id("revolt")
	EventFlow.choose_option(revolt, 0)
	_expect(problems, Game.career["resolved_crises"].has("revolt"),
		"wyjście ponad próg kryzysu rejestruje rozwiązanie")
	_reset_state("proboszcz")
	Game.curia = 20
	var intervention: Dictionary = Events.by_id("curia_intervention")
	EventFlow.choose_option(intervention, 2)
	_expect(problems, not Game.career["resolved_crises"].has("curia_intervention"),
		"decyzja pogarszająca kryzys nie rejestruje rozwiązania")
	_reset_state("proboszcz")
	Game.money = -10000
	var debt: Dictionary = Events.by_id("debt")
	EventFlow.choose_option(debt, 2)
	var delayed: Dictionary = Game.scheduled[0]
	Parish.apply_effects(delayed.get("effects", {}))
	EventFlow.record_delayed_crisis(delayed)
	_expect(problems, Game.money == -3500 and Game.career["resolved_crises"].has("debt"),
		"odroczony skutek rejestruje kryzys dopiero po wyjściu z długu")
	_reset_state("proboszcz")
	Game.money = -10000
	debt = Events.by_id("debt")
	EventFlow.choose_option(debt, 2)
	delayed = Game.scheduled[0]
	Parish.apply_effects(delayed.get("else_effects", {}))
	EventFlow.record_delayed_crisis(delayed)
	_expect(problems, Game.money == -8600 and not Game.career["resolved_crises"].has("debt"),
		"odroczony skutek pozostawiający dług nie rejestruje rozwiązania")


static func _reset_state(rank: String) -> void:
	Game.day = 20
	Game.money = 10000
	Game.reputation = 50
	Game.condition = 50
	Game.trad = 50
	Game.young = 50
	Game.curia = 50
	Game.energy = 100.0
	Game.sunday_hours = Game.MASS_HOURS_SUNDAY.duplicate()
	Game.weekday_hours = Game.MASS_HOURS_WEEKDAY.duplicate()
	Game.scheduled = []
	Game.fired_events = []
	Game.event_cooldowns = {}
	Game.flags = {}
	Game.pending_events = []
	Game.log_lines = []
	Career.reset(Game)
	Game.rank = rank


static func _snapshot() -> Dictionary:
	var state: Dictionary = {}
	for key in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS:
		state[key] = EventFlow._copy_value(Game.get(key))
	return state


static func _restore(state: Dictionary) -> void:
	for key in state:
		Game.set(key, EventFlow._copy_value(state[key]))


static func _expect(problems: Array[String], condition: bool, message: String) -> void:
	if not condition:
		problems.append(message)
