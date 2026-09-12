class_name CheckBudgetUI
## Scenariusze przez handlery interfejsu. Runner uruchamia je z osobnym user://.

static var problems: Array[String] = []
static var ui: Ui


static func run() -> bool:
	problems.clear()
	await _frames()
	ui = Game.get_tree().current_scene.get_node("UI") as Ui
	Game.set_process(false)
	Game.budget = Finance.default_budget()
	Game.budget_reservations = {}
	Game.money = 12000
	await _open("phone", {"app": "bank"})
	_press("Budżet tygodnia")
	await _frames()
	_check_window("budżet")
	await _capture("budget")
	var sliders := _sliders()
	_expect(sliders.size() == 5, "Bank powinien mieć pięć suwaków")
	if sliders.size() != 5:
		return _report()
	sliders[0].value = 0
	_expect(Game.budget == Finance.default_budget(), "Suwak zmienił stan przed zapisem")
	_press("Anuluj zmiany")
	await _frames()
	_expect(Game.budget == Finance.default_budget(), "Anulowanie nie zachowało starego planu")

	Game.money = 1000
	await _open("phone", {"app": "bank"})
	_expect(_has_text("prognoz"), "Bank nie pokazuje prognozy od razu po otwarciu")
	_press("Budżet tygodnia")
	await _frames()
	sliders = _sliders()
	sliders[3].value = 2
	_press("Zapisz plan")
	await _frames()
	_check_window("potwierdzenie budżetu")
	await _capture("budget-debt")
	_expect(int(Game.budget["duszpasterstwo"]) == 1, "Plan zapisany przed zgodą na deficyt")
	_press("Wróć do planu")
	await _frames()
	sliders = _sliders()
	_expect(sliders.size() == 5 and int(sliders[3].value) == 2, "Powrót z potwierdzenia zgubił projekt planu")
	_press("Zapisz plan")
	await _frames()
	_press("Tak, zapisuję plan")
	await _frames()
	_expect(int(Game.budget["duszpasterstwo"]) == 2, "Zgoda nie zapisała projektu planu")

	Game.budget = Finance.default_budget()
	Game.money = 12000
	Game.built = []
	Game.pending_investments = []
	Game.breakdowns = []
	Game.scheduled = []
	await _open("finance", {})
	_check_window("inwestycje")
	await _capture("investments")
	_press("Zleć") # Dach jako pierwsza karta.
	await _frames()
	_expect(Game.money == 12000, "Inwestycja pobrała pieniądze przed zgodą na deficyt")
	_press("Wróć")
	await _frames()
	_expect(Game.pending_investments.is_empty(), "Anulowana inwestycja została zlecona")
	_press("Zleć")
	await _frames()
	_press("Tak, potwierdzam")
	await _frames()
	_expect(Game.money == 4000 and Game.pending_investments.has("roof"), "Potwierdzony dach nie został zlecony")
	_expect(not Finance.can_invest("hall"), "Salka dostępna podczas rezerwacji dachu")

	var event := {"id": "ui_budget_test", "title": "Test wydatku", "text": "Wybierz wydatek.",
		"options": [{"label": "Zapłać", "effects": {"money": -1000}}]}
	Game.money = 100
	await _open("event", {"event": event})
	_press_prefix("Zapłać")
	await _frames()
	_expect(Game.money == 100, "Wydarzenie pobrało wydatek bez zgody")
	_press("Wróć")
	await _frames()
	_expect(not Game.fired_events.has("ui_budget_test"), "Anulowanie rozliczyło wydarzenie")
	_press_prefix("Zapłać")
	await _frames()
	_press("Tak, potwierdzam")
	await _frames()
	_expect(Game.money == -900, "Zgoda nie rozliczyła wydatku wydarzenia")

	Game.money = 100
	Game.phone_inbox = [{"app": "poczta", "from": "Kuria", "title": "Prośba o wpłatę",
		"text": "Wybierz odpowiedź.", "day": Game.day, "read": false, "answered": -1,
		"options": [{"label": "Wpłać", "effects": {"money": -1000}}]}]
	await _open("phone", {"app": "poczta"})
	_press_prefix("Wpłać")
	await _frames()
	_expect(Game.money == 100 and int(Game.phone_inbox[0]["answered"]) == -1,
		"Płatna odpowiedź rozliczona przed zgodą")
	_press("Wróć")
	await _frames()
	_expect(Game.money == 100 and int(Game.phone_inbox[0]["answered"]) == -1,
		"Anulowanie oznaczyło płatną odpowiedź jako udzieloną")
	_press_prefix("Wpłać")
	await _frames()
	_press("Tak, potwierdzam")
	await _frames()
	_expect(Game.money == -900 and int(Game.phone_inbox[0]["answered"]) == 0,
		"Potwierdzona odpowiedź nie została rozliczona")

	Game.money = 900
	Game.breakdowns = ["martens"]
	Game.breakdown_since = {"martens": Game.day}
	Game.pending_repairs = []
	await _open("finance", {})
	_press("Napraw")
	await _frames()
	_expect(Game.money == 900 and Game.pending_repairs.is_empty(), "Naprawa rozliczona przed zgodą")
	_press("Wróć")
	await _frames()
	_press("Napraw")
	await _frames()
	_press("Tak, potwierdzam")
	await _frames()
	_expect(Game.money == 0 and Game.pending_repairs.has("martens"), "Potwierdzona naprawa nie została zlecona")

	await _clear()
	Game.money = 100
	Game.energy = 50
	Game.meals_today = 0
	Game.minutes = 600.0
	Game.do_activity("meal")
	await _frames()
	_expect(Game.money == 100 and Game.meals_today == 0, "Obiad rozliczony przed zgodą")
	_press("Wróć")
	await _frames()
	_expect(Game.money == 100 and Game.meals_today == 0, "Anulowany obiad zmienił stan")
	Game.do_activity("meal")
	await _frames()
	_press("Tak, potwierdzam")
	await _frames()
	_expect(Game.money == 75 and Game.meals_today == 1, "Potwierdzony obiad nie został rozliczony")
	var report := Finance.weekly_settlement()
	await _open("report", {"title": "Poniedziałkowe rozliczenie", "lines": report})
	_check_window("raport tygodnia")
	await _capture("weekly-report")
	return _report()


static func _frames() -> void:
	await Game.get_tree().process_frame
	await Game.get_tree().process_frame
	await Game.get_tree().process_frame


static func _clear() -> void:
	ui._queue.clear()
	for child in ui._modal_layer.get_children():
		child.queue_free()
	Game.modal_open = false
	await _frames()


static func _open(kind: String, data: Dictionary) -> void:
	await _clear()
	ui._enqueue(kind, data)
	await _frames()


static func _sliders() -> Array[HSlider]:
	var result: Array[HSlider] = []
	for node in ui._modal_layer.find_children("*", "HSlider", true, false):
		if not node.is_queued_for_deletion():
			result.append(node as HSlider)
	return result


static func _press(text: String) -> void:
	for node in ui._modal_layer.find_children("*", "Button", true, false):
		if node.text == text and not node.disabled and not node.is_queued_for_deletion():
			node.pressed.emit()
			return
	problems.append("Brak dostępnego przycisku: " + text)


static func _press_prefix(text: String) -> void:
	for node in ui._modal_layer.find_children("*", "Button", true, false):
		if node.text.begins_with(text) and not node.disabled and not node.is_queued_for_deletion():
			node.pressed.emit()
			return
	problems.append("Brak dostępnego przycisku zaczynającego się od: " + text)


static func _has_text(fragment: String) -> bool:
	for node in ui._modal_layer.find_children("*", "Label", true, false):
		if str(node.text).to_lower().contains(fragment):
			return true
	return false


static func _check_window(where: String) -> void:
	var viewport := ui.get_viewport().get_visible_rect()
	for child in ui._modal_layer.get_children():
		if child is CenterContainer:
			for panel in child.get_children():
				if panel is PanelContainer:
					var rect: Rect2 = panel.get_global_rect()
					_expect(viewport.grow(1).encloses(rect), "%s: okno %s poza ekranem %s" % [where, rect, viewport])


static func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ui-capture-dir="):
			var directory := arg.trim_prefix("--ui-capture-dir=")
			DirAccess.make_dir_recursive_absolute(directory)
			await RenderingServer.frame_post_draw
			var result := ui.get_viewport().get_texture().get_image().save_png(directory.path_join(name + ".png"))
			_expect(result == OK, "Nie udało się zapisać zrzutu: " + name)


static func _expect(condition: bool, message: String) -> void:
	if not condition:
		problems.append(message)


static func _report() -> bool:
	if problems.is_empty():
		print("BUDGET UI CHECK OK: suwaki, anulowanie, potwierdzenia, inwestycje, naprawy, wydarzenia, telefon, obiad i rozmiar okien.")
	else:
		for problem in problems:
			printerr("BUDGET UI CHECK FAILED: " + problem)
	return problems.is_empty()
