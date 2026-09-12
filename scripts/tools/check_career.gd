class_name CheckCareer
## Deterministyczne scenariusze regresyjne kariery 2.4. Nie czytają ani nie
## zapisują slotu gracza, a po zakończeniu odtwarzają zmieniony stan Game.

const STATE_KEYS := [
	"day", "start_unix", "money", "reputation", "condition", "trad", "young", "curia", "faith",
	"week_income", "week_expenses", "meals_today", "apples_picked", "visit_index", "respect",
	"funerals_pending", "funeral_deadline", "quiet_days", "_last_curia_mail", "_last_bank_alert",
	"energy", "deceased_name", "rank", "done_today", "breakdown_since", "event_cooldowns",
	"media_recent", "budget", "budget_reservations", "career", "flags", "scheduled",
	"pending_investments", "fired_events", "log_lines", "built", "seen", "masses_done",
	"masses_missed", "sunday_hours", "weekday_hours", "breakdowns", "pending_repairs",
	"phone_inbox", "bank_log", "faith_history", "chronicle", "pending_events",
]


class CareerFixture extends Node:
	var day := 12
	var rank := "nieznana"
	var faith := 140
	var career: Variant = {"pastor_relation": -4, "resolved_crises": ["a", "a", "b"]}
	var faith_history: Variant = [{"day": 11.0, "attendance": 20.0}]
	var chronicle: Variant = ["Starszy wpis"]


static func run() -> Array[String]:
	var problems: Array[String] = []
	var before := _snapshot()
	_check_reset_normalize_and_migration(problems)
	_check_faith_window_and_formula(problems)
	_check_review_calendar_and_streaks(problems)
	_check_promotion(problems)
	_check_approval_delay_and_exactly_once(problems)
	_check_pending_approval_round_trip(problems)
	_check_crisis_uniqueness(problems)
	_restore(before)
	return problems


static func report() -> bool:
	var problems := run()
	for problem in problems:
		printerr("BŁĄD KARIERY  " + problem)
	if problems.is_empty():
		print("Kariera 2.4: wiara, oceny, awans, migracja i uzgodnienia są spójne.")
	return problems.is_empty()


static func _check_reset_normalize_and_migration(problems: Array[String]) -> void:
	var fixture := CareerFixture.new()
	Career.normalize(fixture)
	_expect(problems, fixture.rank == "wikary" and fixture.faith == 100,
		"normalizacja ogranicza rangę i wiarę także na niezależnym obiekcie stanu")
	_expect(problems, fixture.career["pastor_relation"] == 0 and fixture.career["resolved_crises"] == ["a", "b"],
		"normalizacja naprawia relację i usuwa duplikaty kryzysów")
	_expect(problems, fixture.faith_history[0] == {"day": 11, "attendance": 20, "sacraments": 0, "groups": 0},
		"normalizacja odtwarza pełny wiersz historii wiary")
	fixture.free()

	_reset_state()
	Career.reset(Game)
	_expect(problems, Game.rank == "wikary" and Career.next_review_day() == 92,
		"nowa gra zaczyna jako wikary z oceną za 91 dni")
	Game.day = 37
	Career.reset(Game, true)
	_expect(problems, Game.rank == "proboszcz" and Career.next_review_day() == 128,
		"stara gra zachowuje samodzielność proboszcza i nie dostaje ocen wstecz")

	# JSON.parse_string odwzorowuje typy starego pliku, ale test nie otwiera user://.
	var legacy_data: Dictionary = JSON.parse_string(JSON.stringify({"version": 1, "day": 37, "money": 7777}))
	SaveGame.apply(Game, legacy_data)
	_expect(problems, Game.rank == "proboszcz" and Game.money == 7777 and Career.next_review_day() == 128,
		"rzeczywista migracja starego słownika nadaje proboszcza i termin +91 dni")


static func _check_faith_window_and_formula(problems: Array[String]) -> void:
	_reset_state()
	Career.record("attendance", 1200)
	Career.record("sacraments", 15)
	Career.record("groups", 5)
	_expect(problems, Game.faith == 0, "czynności nie ustawiają wiary przed kolejnym porankiem")
	_expect(problems, Game.faith_history == [{"day": 1, "attendance": 1200, "sacraments": 15, "groups": 5}],
		"czynności jednego dnia składają się w jeden pełny wiersz historii")
	Game.day = 2
	Career.morning()
	var components := Career.faith_components()
	_expect(problems, Game.faith == 100 and int(components["attendance"]["weight"]) == 50 \
			and int(components["sacraments"]["weight"]) == 30 and int(components["groups"]["weight"]) == 20,
		"pełny tydzień daje 100 wiary według jawnych wag 50/30/20")
	_expect(problems, Career.morning().is_empty() and Game.faith == 100,
		"ten sam poranek nie jest rozliczany drugi raz")
	for day in range(3, 10):
		Game.day = day
		Career.morning()
	_expect(problems, Game.faith == 0 and Game.faith_history.is_empty(),
		"czynności wypadają z ruchomego okna po siedmiu zakończonych dniach")

	_reset_state()
	Game.money = 999999
	Game.reputation = 100
	Game.day = 2
	Career.morning()
	_expect(problems, Game.faith == 0, "sama kasa i reputacja nie dają ani punktu wiary")
	Career.record("attendance", -100)
	Career.record("unknown", 100)
	_expect(problems, Game.faith_history.is_empty(), "ujemne i nieznane czynności nie zmieniają historii")


static func _check_review_calendar_and_streaks(problems: Array[String]) -> void:
	_reset_state()
	_expect(problems, Career.next_review_day() == 92, "pierwszy cykl ma dokładnie 91 dni")
	Game.day = 85
	var reminder := Career.morning()
	_expect(problems, reminder.size() == 1 and "za 7 dni" in reminder[0].to_lower(),
		"kuria przypomina dokładnie siedem dni przed oceną")
	_expect(problems, Game.phone_inbox.size() == 1 and Game.phone_inbox[0]["id"] == "career_reminder_92",
		"przypomnienie przychodzi jako prawdziwy list w telefonie")
	_expect(problems, Career.morning().is_empty(), "przypomnienie nie powtarza się tego samego ranka")
	Game.day = 92
	Career.morning()
	_expect(problems, Game.career["reviews"].size() == 1 and Career.next_review_day() == 183,
		"ocena powstaje w terminie, a następna jest po kolejnych 91 dniach")
	_expect(problems, Game.phone_inbox.size() == 2 and Game.phone_inbox[0]["id"] == "career_review_92",
		"pisemna ocena z rozbiciem trafia do skrzynki telefonu")

	# 70 jest oceną dobrą.
	_reset_state()
	_prepare_review(92, 12000, 50, 50, 0, true)
	Career.morning()
	_expect(problems, Game.career["reviews"][0]["score"] == 70 and Game.career["reviews"][0]["result"] == "good",
		"próg dobry jest domknięty przy 70 punktach")
	# Ocena 40 jest neutralna i przerywa obie serie.
	Game.career["good_streak"] = 1
	Game.career["bad_streak"] = 1
	_prepare_review(183, 0, 50, 50, 0, false)
	Career.morning()
	_expect(problems, Game.career["reviews"].back()["score"] == 40 and Game.career["reviews"].back()["result"] == "neutral" \
			and Game.career["good_streak"] == 0 and Game.career["bad_streak"] == 0,
		"wynik 40 jest neutralny i przerywa serie")

	_reset_state()
	for due in [92, 183, 274]:
		_prepare_review(due, -12000, 0, 0, 0, false)
		Career.morning()
	_expect(problems, Game.career["bad_streak"] == 3 and Game.career["transfer_pending"],
		"trzecia zła ocena zapisuje decyzję o przeniesieniu bez kończenia gry")
	_expect(problems, _chronicle_has("ostrzeżenia") and _chronicle_has("przeniesieniu"),
		"ostrzeżenie i decyzja o przeniesieniu zostają w kronice")


static func _check_promotion(problems: Array[String]) -> void:
	_reset_state()
	for due in [92, 183]:
		_prepare_review(due, 12000, 100, 100, 4, true)
		Career.morning()
	_expect(problems, Game.rank == "wikary" and Game.career["promotion_offer"] == "proboszcz",
		"dwie dobre oceny proponują awans, ale nie zmieniają rangi automatycznie")
	_expect(problems, Career.accept_promotion() and Game.rank == "proboszcz" and Career.rank_label() == "Proboszcz",
		"przyjęcie propozycji awansuje o dokładnie jedną rangę")
	_expect(problems, not Career.accept_promotion(), "tej samej propozycji awansu nie można przyjąć dwa razy")


static func _check_approval_delay_and_exactly_once(problems: Array[String]) -> void:
	_reset_state()
	Game.money = 1000
	var option := {"label": "Przesuń mszę", "set": {"weekday_hours": [8]}, "effects": {"money": -123}}
	var event := {"id": "career_check_approval", "title": "Próba uzgodnienia", "options": [option]}
	var second_option := {"label": "Ogłoś plan", "needs_approval": true, "effects": {"reputation": -7}}
	var second_event := {"id": "career_check_approval_2", "title": "Druga próba", "options": [second_option]}
	_expect(problems, Career.needs_approval(option), "wikary uzgadnia zmianę rozkładu nawet bez osobnej flagi")
	_expect(problems, Career.request_approval(event, option), "pierwsza prośba o zgodę zostaje przyjęta")
	_expect(problems, not Career.request_approval(event, option), "identyczna oczekująca prośba nie jest dublowana")
	_expect(problems, Career.request_approval(second_event, second_option), "druga niezależna prośba może czekać na ten sam dzień")
	_expect(problems, Game.career["pastor_relation"] == 66 and Game.money == 1000 and Game.reputation == 50 \
			and Game.weekday_hours == [7, 19], "każda prośba kosztuje 2 relacji, ale odracza wszystkie skutki")
	Game.day = 2
	Career.morning()
	_expect(problems, Game.money == 1000 and Game.weekday_hours == [7, 19], "po jednym dniu nadal nie ma skutków")
	Game.day = 3
	Career.morning()
	_expect(problems, Game.money == 877 and Game.reputation == 43 and Game.weekday_hours == [8] \
			and Game.career["approvals"][0]["status"] == "approved" \
			and Game.career["approvals"][1]["status"] == "approved",
		"po dwóch dniach wszystkie skutki obu zgód wchodzą razem")
	Career.morning()
	Game.day = 4
	Career.morning()
	_expect(problems, Game.money == 877 and Game.reputation == 43, "zatwierdzone opcje wykonują skutki dokładnie raz")
	Game.rank = "proboszcz"
	_expect(problems, not Career.needs_approval(option), "proboszcz nie podlega ograniczeniu wikarego")


static func _check_crisis_uniqueness(problems: Array[String]) -> void:
	_reset_state()
	Career.record_crisis("roof")
	Career.record_crisis("roof")
	Career.record_crisis("people")
	_expect(problems, Game.career["resolved_crises"] == ["roof", "people"],
		"kryzys liczy się tylko raz w kwartale")
	_expect(problems, Career.review_components()["crises"] == 100,
		"brak kryzysu ma neutralne 50, a dwa różne rozwiązane kryzysy dają 100")


static func _check_pending_approval_round_trip(problems: Array[String]) -> void:
	_reset_state()
	Game.day = 10
	Game.money = 500
	Game.faith_history = [{"day": 9, "attendance": 321, "sacraments": 3, "groups": 1}]
	Game.career["reviews"] = [{"day": 5, "components": {"finances": 60, "faith": 40,
		"buildings": 50, "reputation": 55, "crises": 50}, "score": 51, "result": "neutral"}]
	Career.add_chronicle("Wpis przed zapisem.")
	var first_option := {"label": "Pierwsza zgoda", "needs_approval": true, "effects": {"money": -10}}
	var second_option := {"label": "Druga zgoda", "needs_approval": true, "effects": {"reputation": -2}}
	Career.request_approval({"id": "save_approval_1", "title": "Pierwszy zapis"}, first_option)
	Career.request_approval({"id": "save_approval_2", "title": "Drugi zapis"}, second_option)

	var save_data := {"version": SaveGame.VERSION}
	for key in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS:
		save_data[key] = _copy(Game.get(key))
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(save_data))
	Career.reset(Game)
	Game.money = 0
	SaveGame.apply(Game, parsed)
	var approvals: Array = Game.career["approvals"]
	_expect(problems, approvals.size() == 2 and approvals[0]["due_day"] is int and approvals[0]["due_day"] == 12,
		"zapis przywraca dwie oczekujące zgody i całkowity dzień wykonania")
	_expect(problems, Game.faith_history[0]["attendance"] is int and Game.faith_history[0]["attendance"] == 321 \
			and Game.career["reviews"].size() == 1 and Game.chronicle[0]["text"] == "Wpis przed zapisem.",
		"zapis zachowuje historię wiary, ocenę i kronikę")
	Game.day = 11
	Career.morning()
	_expect(problems, Game.money == 500 and Game.reputation == 50, "wczytanie nie przyspiesza oczekujących skutków")
	Game.day = 12
	Career.morning()
	Career.morning()
	Game.day = 13
	Career.morning()
	_expect(problems, Game.money == 490 and Game.reputation == 48 \
			and approvals[0]["status"] == "approved" and approvals[1]["status"] == "approved",
		"obie wczytane zgody dojrzewają po terminie i wykonują się dokładnie raz")


static func _prepare_review(day: int, money: int, condition: int, reputation: int, crises: int, full_faith: bool) -> void:
	Game.day = day
	Game.career["next_review"] = day
	Game.career["last_morning"] = -1
	Game.money = money
	Game.condition = condition
	Game.reputation = reputation
	Game.career["resolved_crises"] = []
	for i in crises:
		Game.career["resolved_crises"].append("crisis_%d" % i)
	Game.faith_history = []
	if full_faith:
		Game.faith_history.append({"day": day - 1, "attendance": 1200, "sacraments": 15, "groups": 5})


static func _reset_state() -> void:
	Game.day = 1
	Career.reset(Game)
	Game.flags = {}
	Game.pending_events = []
	Game.money = 0
	Game.reputation = 50
	Game.condition = 50
	Game.curia = 50
	Game.weekday_hours = [7, 19]
	Game.sunday_hours = [7, 12, 19]
	Game.scheduled = []
	Game.fired_events = []
	Game.event_cooldowns = {}
	Game.breakdowns = []
	Game.breakdown_since = {}
	Game.log_lines = []
	Game.phone_inbox = []


static func _chronicle_has(fragment: String) -> bool:
	for entry in Game.chronicle:
		if fragment in str(entry.get("text", "")):
			return true
	return false


static func _snapshot() -> Dictionary:
	var snapshot := {}
	for key in STATE_KEYS:
		snapshot[key] = _copy(Game.get(key))
	return snapshot


static func _restore(snapshot: Dictionary) -> void:
	for key in snapshot:
		Game.set(key, _copy(snapshot[key]))


static func _copy(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


static func _expect(problems: Array[String], condition: bool, message: String) -> void:
	if not condition:
		problems.append(message)
