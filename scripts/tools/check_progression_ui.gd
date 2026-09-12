class_name CheckProgressionUI
## Scenariusze rozwoju przez rzeczywiste przyciski i czynności, w izolowanym runnerze.


static func run() -> bool:
	await CheckBudgetUI._frames()
	CheckBudgetUI.problems.clear()
	CheckBudgetUI.ui = Game.get_tree().current_scene.get_node("UI") as Ui
	Game.set_process(false)
	Game.start_new_game()
	Game.respect = 120

	# Profil i pierwsze dwa węzły administratora są dostępne z telefonu.
	await CheckBudgetUI._open("phone", {"app": "poczta"})
	CheckBudgetUI._press("Rozwój")
	await CheckBudgetUI._frames()
	CheckBudgetUI._check_window("rozwój księdza")
	CheckBudgetUI._expect(CheckBudgetUI._has_text("charyzma"), "Profil nie pokazuje pięciu cech")
	CheckBudgetUI._expect(CheckBudgetUI._has_text("administrator"), "Brak drzewka administratora")
	await CheckBudgetUI._capture("progression-start")
	CheckBudgetUI._press("Odblokuj")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Progression.has_talent("admin_accounts"), "Pierwszy przycisk nie odblokował administratora")
	CheckBudgetUI._press("Odblokuj")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Progression.has_talent("admin_inspection"), "Drugi przycisk nie odblokował przeglądu")

	# Zablokowany przegląd nie robi nic nawet przy wywołaniu poza UI.
	await CheckBudgetUI._clear()
	Game.talents.erase("admin_inspection")
	Game.location = "rectory"
	Game.minutes = 600.0
	Game.energy = 100.0
	Game.condition = 50
	Game.done_today.clear()
	Game.do_activity("inspection")
	CheckBudgetUI._expect(Game.minutes == 600.0 and Game.energy == 100.0 and Game.condition == 50,
		"Zablokowany przegląd zmienił stan gry")
	Game.talents.append("admin_inspection")

	# Cena na karcie, w potwierdzeniu i w transakcji bierze tę samą zniżkę talentu.
	Game.money = Finance.investment_cost("roof")
	Game.built = []
	Game.pending_investments = []
	Game.budget_reservations = {}
	Game.budget = Finance.default_budget()
	await CheckBudgetUI._open("finance", {})
	CheckBudgetUI._expect(CheckBudgetUI._has_text(CheckBudgetUI.ui._money(Finance.investment_cost("roof"))),
		"Finanse nie pokazują ceny po talencie")
	CheckBudgetUI._press("Zleć")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.money == Finance.investment_cost("roof"), "Inwestycja pobrała pieniądze przed potwierdzeniem")
	CheckBudgetUI._expect(CheckBudgetUI._has_text(CheckBudgetUI.ui._money(Finance.investment_cost("roof"))),
		"Potwierdzenie nie pokazuje ceny po talencie")
	CheckBudgetUI._press("Tak, potwierdzam")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.money == 0 and Game.pending_investments.has("roof"),
		"Potwierdzony dach nie użył ceny po talencie")

	# Przegląd dostępny w finansach zamyka modal i zużywa czas, energię oraz dzienny limit.
	Game.location = "rectory"
	Game.minutes = 600.0
	Game.energy = 100.0
	Game.condition = 50
	Game.done_today.clear()
	await CheckBudgetUI._open("finance", {})
	CheckBudgetUI._press("Wykonaj przegląd")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.minutes == 645.0 and Game.energy == 90.0 and Game.condition == 53,
		"Przegląd z finansów nie wykonał pełnego skutku")
	Game.do_activity("inspection")
	CheckBudgetUI._expect(Game.minutes == 645.0 and Game.energy == 90.0 and Game.condition == 53,
		"Przegląd można wykonać drugi raz tego samego dnia")

	# Druga ścieżka zmienia rzeczywisty czas odwiedzin.
	Game.respect = 100
	await CheckBudgetUI._open("progression", {})
	CheckBudgetUI._press("Odblokuj")
	await CheckBudgetUI._frames()
	CheckBudgetUI._press("Odblokuj")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Progression.has_talent("pastor_visits"), "Nie odblokowano talentu odwiedzin")
	await CheckBudgetUI._clear()
	if Game.cutscene:
		Game.skip_cutscene()
		await CheckBudgetUI._frames()
		if Game.cutscene:
			Game.finish_cutscene()
			await CheckBudgetUI._frames()
	Game.location = "outside"
	Game.minutes = 600.0
	Game.energy = 100.0
	Game.done_today.clear()
	Game.do_activity("visit_sick")
	await CheckBudgetUI._frames()
	Game.skip_cutscene()
	await CheckBudgetUI._frames()
	if Game.cutscene:
		Game.finish_cutscene()
		await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.minutes == 675.0, "Odwiedziny nie skróciły się do 75 minut (jest %d)." % int(Game.minutes))

	# Próba o progu cechy pozostaje widoczna z wyjaśnieniem, potem staje się dostępna.
	Game.stats["charyzma"] = 3
	var gated := {"id": "ui_stat_gate", "title": "Próba cechy", "text": "Wybierz odpowiedź.",
		"options": [{"label": "Przemów do ludzi", "needs": {"charyzma": 10}, "effects": {"reputation": 1}}]}
	await CheckBudgetUI._open("event", {"event": gated})
	CheckBudgetUI._check_window("opcja z progiem")
	CheckBudgetUI._expect(_button_text_contains("wymaga"), "Opcja z progiem nie wyjaśnia blokady")
	CheckBudgetUI._expect(_button_disabled("Przemów do ludzi"), "Opcja z progiem nie jest zablokowana")
	await CheckBudgetUI._capture("progression-gate")
	Game.stats["charyzma"] = 10
	await CheckBudgetUI._open("event", {"event": gated})
	CheckBudgetUI._expect(not _button_disabled("Przemów do ludzi"), "Opcja nie odblokowała się po osiągnięciu progu")
	return _report()


static func _button_disabled(prefix: String) -> bool:
	for node in CheckBudgetUI.ui._modal_layer.find_children("*", "Button", true, false):
		if node.text.begins_with(prefix) and not node.is_queued_for_deletion():
			return node.disabled
	return false


static func _button_text_contains(fragment: String) -> bool:
	for node in CheckBudgetUI.ui._modal_layer.find_children("*", "Button", true, false):
		if str(node.text).to_lower().contains(fragment) and not node.is_queued_for_deletion():
			return true
	return false


static func _report() -> bool:
	if CheckBudgetUI.problems.is_empty():
		print("PROGRESSION UI CHECK OK: profil, drzewka, ceny, przegląd, odwiedziny, progi i widok.")
	else:
		for problem in CheckBudgetUI.problems:
			printerr("PROGRESSION UI CHECK FAILED: " + problem)
	return CheckBudgetUI.problems.is_empty()
