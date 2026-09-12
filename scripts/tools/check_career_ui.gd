class_name CheckCareerUI
## Scenariusz integracyjny przez UI i rzeczywistą pętlę czynności/poranka.
## Uruchamiany wyłącznie przez izolowany runner, jak CheckBudgetUI.

static func run() -> bool:
	await CheckBudgetUI._frames()
	CheckBudgetUI.problems.clear()
	CheckBudgetUI.ui = Game.get_tree().current_scene.get_node("UI") as Ui
	Game.set_process(false)
	Game.start_new_game()
	await CheckBudgetUI._open("phone", {"app": "poczta"})
	CheckBudgetUI._press("Kariera")
	await CheckBudgetUI._frames()
	CheckBudgetUI._check_window("kariera nowego wikarego")
	CheckBudgetUI._expect(CheckBudgetUI._has_text("wikary"), "Nowa kariera nie pokazuje wikarego")
	CheckBudgetUI._expect(CheckBudgetUI._has_text("życie religijne"), "Brak wskaźnika życia religijnego")
	await CheckBudgetUI._capture("career-start")

	await CheckBudgetUI._open("event", {"event": Events.by_id("mass_hour")})
	CheckBudgetUI._check_window("uzgodnienie godzin mszy")
	await CheckBudgetUI._capture("career-approval")
	CheckBudgetUI._press_prefix("Niedziele i święta: 7:00 i 19:00")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.sunday_hours == [7, 12, 19], "Wikary zmienił godziny bez oczekiwania na proboszcza")
	CheckBudgetUI._expect(Game.career.get("approvals", []).size() == 1, "Decyzja nie trafiła do uzgodnienia")
	await CheckBudgetUI._open("career", {})
	CheckBudgetUI._expect(CheckBudgetUI._has_text("do uzgodnienia"), "Kariera nie pokazuje oczekującej decyzji")
	await CheckBudgetUI._capture("career-pending")

	# Faktyczna msza, spowiedź i odwiedziny karmią wskaźnik; sam podgląd go nie zmienia.
	await CheckBudgetUI._clear()
	Game.minutes = 7 * 60
	Game.energy = 100
	await _complete_activity("mass")
	Game.energy = 100
	await _complete_activity("confession")
	Game.energy = 100
	await _complete_activity("visit_sick")
	CheckBudgetUI._expect(Game.faith == 0, "Wiara zmieniła się przed porannym przeliczeniem")
	var empty: Array[String] = []
	Game._start_new_day(100.0, empty)
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.faith > 0, "Poranek nie uwzględnił odprawionej mszy i czynności")
	CheckBudgetUI._expect(Game.sunday_hours == [7, 12, 19], "Proboszcz odpowiedział za wcześnie")
	await CheckBudgetUI._clear()
	Game._start_new_day(100.0, empty)
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.sunday_hours == [7, 19], "Poranek nie rozliczył uzgodnienia po dwóch dniach")

	# Utrwalony stan przechodzi przez prawdziwy plik zapisu w izolowanym user://.
	var faith_before := Game.faith
	Game.flags["ui_chain"] = "chosen"
	Game.save_now()
	Game.flags.clear()
	Game.faith = 0
	await CheckBudgetUI._clear()
	CheckBudgetUI._expect(Game.continue_game(), "Nie udało się wczytać zapisu z karierą")
	CheckBudgetUI._expect(Game.faith == faith_before and Game.flags.get("ui_chain", "") == "chosen",
		"Wczytanie zgubiło życie religijne lub flagi")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(CheckBudgetUI._has_text("ksiądz marek"), "Wczytanie nie pokazało oczekującego wydarzenia sąsiada")
	CheckBudgetUI._press_prefix("Uzgodnijcie godziny")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.pending_events.is_empty(), "Odpowiedź po wczytaniu nie zamknęła kolejki")
	Game.career["promotion_offer"] = "proboszcz"
	await CheckBudgetUI._open("career", {})
	CheckBudgetUI._press("Przyjmij awans")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.rank == "proboszcz", "Przycisk nie przyjął propozycji awansu")
	CheckBudgetUI._expect(not Career.needs_approval(Events.by_id("mass_hour")["options"][0]),
		"Po awansie nadal wymagane uzgodnienie")

	# Dużo danych musi pozostać dostępne bez wypychania przycisku poza ekran.
	for i in 50:
		Career.add_chronicle("Próba długiej kroniki: decyzja %d i konsekwencje dla parafii." % i)
	Game.career["transfer_pending"] = true
	await CheckBudgetUI._open("career", {})
	CheckBudgetUI._check_window("długa kronika kariery")
	await CheckBudgetUI._capture("career-history")
	await CheckBudgetUI._open("status", {})
	CheckBudgetUI._check_window("stan parafii")
	await CheckBudgetUI._capture("career-status")
	for problem in CheckBudgetUI.problems:
		printerr("CAREER UI CHECK FAILED: " + problem)
	if CheckBudgetUI.problems.is_empty():
		print("CAREER UI CHECK OK: telefon, wikary, zgoda, czynności, poranek, zapis, awans, długa kronika.")
	return CheckBudgetUI.problems.is_empty()


static func _complete_activity(id: String) -> void:
	Game.do_activity(id)
	await CheckBudgetUI._frames()
	Game.skip_cutscene()
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(not Game.cutscene, "Czynność nie zakończyła się po pominięciu scenki: " + id)
