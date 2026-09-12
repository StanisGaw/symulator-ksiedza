class_name CheckProgressionEvents
## Integracja cech z wydarzeniami i telefonem. Scenariusze nie zapisują pliku
## gracza i po wykonaniu odtwarzają cały dotknięty stan.


static func run() -> Array[String]:
	var problems: Array[String] = []
	var before: Dictionary = _snapshot()
	_check_failed_needs_are_atomic(problems)
	_check_approval_freezes_scaled_option(problems)
	_check_honest_execution(problems)
	_check_media_execution(problems)
	_restore(before)
	return problems


static func _check_failed_needs_are_atomic(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	var choir: Dictionary = Events.by_id("choir_conflict")
	var cooperative: Dictionary = choir.get("options", [])[2]
	_expect(problems, cooperative.get("needs", {}) == {"charyzma": 6},
		"kooperacyjna rozmowa chóru wymaga charyzmy 6/10")
	var organs: Dictionary = Events.by_id("organ_silent")
	_expect(problems, str(organs.get("options", [])[0].get("scale", "")) == "zarzadzanie",
		"koszt naprawy organów skaluje zarządzanie")
	var event := {"id": "needs_guard", "title": "Próg cechy", "options": [{
		"label": "Trudna rozmowa", "needs": {"charyzma": 6}, "effects": {"money": -500},
		"flags": {"guard_failed": true}, "delayed": {"days": 3, "effects": {"curia": 1}}}]}
	Game.pending_events = ["needs_guard"]
	var before_chronicle := Game.chronicle.size()
	EventFlow.choose_option(event, 0)
	_expect(problems, Game.money == 10000 and Game.pending_events == ["needs_guard"],
		"niespełniony próg nie pobiera kosztu ani nie usuwa wydarzenia z kolejki")
	_expect(problems, not Game.fired_events.has("needs_guard") and Game.scheduled.is_empty()
		and not Game.flags.has("guard_failed"),
		"niespełniony próg nie oznacza decyzji, flagi ani odroczonego skutku")
	_expect(problems, Game.chronicle.size() == before_chronicle,
		"odrzucona przez próg opcja nie trafia do kroniki")

	Game.phone_inbox = [Phone.make("media", "Portal", "Trudne pytanie", "Treść", {
		"context": "media", "options": [{"label": "Odpowiedz", "needs": {"wplywy": 6},
			"effects": {"reputation": 4}}]})]
	var before_reputation := Game.reputation
	_expect(problems, not Inbox.answer(0, 0), "telefon odrzuca opcję bez wymaganej cechy")
	_expect(problems, int(Game.phone_inbox[0].get("answered", -1)) == -1
		and Game.reputation == before_reputation and int(Game.stat_xp["wplywy"]) == 0,
		"niedostępna odpowiedź nie mutuje wiadomości, skutków ani XP")


static func _check_approval_freezes_scaled_option(problems: Array[String]) -> void:
	_reset_state("wikary")
	Game.stats["zarzadzanie"] = 6
	var event := {"id": "frozen_approval", "title": "Zakup do uzgodnienia", "options": [{
		"label": "Kup wyposażenie", "needs_approval": true, "scale": "zarzadzanie",
		"effects": {"money": -1000}}]}
	var preview: Dictionary = Progression.resolve_option(event["options"][0], "event")
	_expect(problems, int(preview["effects"]["money"]) == -850,
		"podgląd skaluje koszt dla zarządzania 6/10")
	EventFlow.choose_option(event, 0)
	var approvals: Array = Game.career["approvals"]
	_expect(problems, approvals.size() == 1 and Game.money == 10000,
		"opcja czeka na zgodę bez wykonania skutku")
	var frozen: Dictionary = approvals[0].get("option", {})
	_expect(problems, bool(frozen.get("_progression_resolved", false))
		and not frozen.has("scale") and int(frozen.get("effects", {}).get("money", 0)) == -850,
		"zgoda przechowuje rozliczoną kwotę i znacznik idempotencji")
	Game.stats["zarzadzanie"] = 10
	Game.day = int(approvals[0]["due_day"])
	Career.morning()
	_expect(problems, Game.money == 9150, "późniejszy wzrost cechy nie przelicza zamrożonego kosztu")
	Career.morning()
	_expect(problems, Game.money == 9150, "zatwierdzona opcja wykonuje się tylko raz")


static func _check_honest_execution(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	Game.talents = ["host_media", "host_curia"]
	var event: Dictionary = Events.by_id("curia_call")
	var preview: Dictionary = Progression.resolve_option(event["options"][0], "event")
	_expect(problems, int(preview.get("effects", {}).get("curia", 0)) == 2,
		"podgląd uczciwego sprawozdania pokazuje premię talentu kurii")
	EventFlow.choose_option(event, 0)
	_expect(problems, Game.curia == 55 and int(Game.stat_xp["wiarygodnosc"]) == 3,
		"wykonane sprawozdanie stosuje premię i przyznaje XP raz")
	EventFlow.choose_option(event, 0)
	_expect(problems, Game.curia == 55 and int(Game.stat_xp["wiarygodnosc"]) == 3,
		"ponowna próba tej samej decyzji nie powiela premii ani XP")

	_reset_state("proboszcz")
	Game.talents = ["host_media", "host_curia"]
	Inbox.send(Phone.curia_mail("próba", Phone.excuses()))
	_expect(problems, Inbox.answer(0, 0), "uczciwa odpowiedź kurii jest wykonywana")
	_expect(problems, Game.curia == 57 and Game.energy == 90.0
		and int(Game.stat_xp["wiarygodnosc"]) == 3,
		"uczciwa odpowiedź dostaje premię kurii i XP po wykonaniu")
	_expect(problems, not Inbox.answer(0, 0) and Game.curia == 57
		and int(Game.stat_xp["wiarygodnosc"]) == 3,
		"odpowiedziana wiadomość nie nalicza skutków drugi raz")


static func _check_media_execution(problems: Array[String]) -> void:
	_reset_state("proboszcz")
	Game.talents = ["host_media"]
	Inbox.send(Phone.make("media", "Portal", "Komentarz", "Treść", {"context": "media",
		"options": [{"label": "Odpowiedz", "effects": {"reputation": 1}}]}))
	var source: Dictionary = Game.phone_inbox[0]["options"][0]
	var preview: Dictionary = Progression.resolve_option(source, "media")
	_expect(problems, int(preview["effects"]["reputation"]) == 3,
		"podgląd mediów pokazuje tę samą premię reputacji co wykonanie")
	_expect(problems, Inbox.answer(0, 0), "odpowiedź medialna jest wykonywana")
	_expect(problems, Game.reputation == 53 and int(Game.stat_xp["wplywy"]) == 1,
		"wykonana odpowiedź stosuje premię i przyznaje XP wpływów")
	_expect(problems, not Inbox.answer(0, 0) and Game.reputation == 53
		and int(Game.stat_xp["wplywy"]) == 1,
		"media nie naliczają premii ani XP drugi raz")


static func _reset_state(rank: String) -> void:
	Game.day = 20
	Game.money = 10000
	Game.reputation = 50
	Game.condition = 50
	Game.trad = 50
	Game.young = 50
	Game.curia = 50
	Game.energy = 100.0
	Game.respect = 100
	Game.scheduled = []
	Game.fired_events = []
	Game.event_cooldowns = {}
	Game.flags = {}
	Game.pending_events = []
	Game.phone_inbox = []
	Game.log_lines = []
	Career.reset(Game)
	Progression.reset(Game)
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
