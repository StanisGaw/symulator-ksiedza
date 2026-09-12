class_name CheckGroupsUI
## Scenariusze wspólnot przez telefon, potwierdzenie finansowania i prawdziwe spotkanie.


static func run() -> bool:
	await CheckBudgetUI._frames()
	CheckBudgetUI.problems.clear()
	CheckBudgetUI.ui = Game.get_tree().current_scene.get_node("UI") as Ui
	Game.set_process(false)
	Game.start_new_game()
	Game.money = 1000

	# Parafia jest zwykłą, dostępną z telefonu zakładką, nie tylko trasą wewnętrzną.
	await CheckBudgetUI._open("phone", {"app": "poczta"})
	CheckBudgetUI._press("Parafia")
	await CheckBudgetUI._frames()
	CheckBudgetUI._check_window("parafia")
	for label_variant in Groups.LABELS.values():
		var label := str(label_variant).to_lower()
		CheckBudgetUI._expect(CheckBudgetUI._has_text(label), "Parafia nie pokazuje wspólnoty: " + str(label_variant))
	CheckBudgetUI._expect(CheckBudgetUI._has_text("możliwe strony") or CheckBudgetUI._has_text("nie ma dziś"),
		"Parafia nie opisuje stron kryzysu")
	await CheckBudgetUI._capture("groups-start")
	await _scroll_to_bottom()
	await CheckBudgetUI._capture("groups-initiatives")

	# Włączenie jest zawsze czytelną decyzją finansową; anulowanie nie zmienia stanu.
	var money_before := Game.money
	CheckBudgetUI._press("Włącz")
	await CheckBudgetUI._frames()
	CheckBudgetUI._check_window("potwierdzenie wspólnoty")
	CheckBudgetUI._expect(CheckBudgetUI._has_text("bieżąca opłata") and CheckBudgetUI._has_text("stała opłata") and CheckBudgetUI._has_text("prognoza"),
		"Potwierdzenie nie pokazuje bieżącej i stałej opłaty oraz prognozy")
	await CheckBudgetUI._capture("groups-confirm")
	CheckBudgetUI._press("Anuluj")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(not bool(Game.community.get("caritas", false)) and Game.money == money_before,
		"Anulowanie zmieniło finansowanie wspólnoty")

	CheckBudgetUI._press("Włącz")
	await CheckBudgetUI._frames()
	CheckBudgetUI._press("Włącz i opłać")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(bool(Game.community.get("caritas", false)), "Potwierdzenie nie włączyło Caritas")
	CheckBudgetUI._expect(Game.money == money_before - int(Groups.INITIATIVES["caritas"]["cost"]),
		"Włączenie nie pobrało bieżącej opłaty dokładnie raz")

	# Powody czasu i energii mają być widoczne mimo otwartego telefonu.
	Game.location = "rectory"
	Game.minutes = 23.0 * 60.0
	Game.energy = 100.0
	await CheckBudgetUI._open("phone", {"app": "parafia"})
	CheckBudgetUI._expect(CheckBudgetUI._has_text("jest za późno") and _button_disabled("Przeprowadź spotkanie"),
		"Telefon nie pokazuje blokady późnej pory spotkania")
	Game.minutes = 600.0
	Game.energy = 1.0
	await CheckBudgetUI._open("phone", {"app": "parafia"})
	CheckBudgetUI._expect(CheckBudgetUI._has_text("za mało energii") and _button_disabled("Przeprowadź spotkanie"),
		"Telefon nie pokazuje blokady braku energii")

	# Spotkanie wychodzi z modalu i zużywa faktyczny czas oraz energię tylko raz w tygodniu.
	Game.location = "rectory"
	Game.minutes = 600.0
	Game.energy = 100.0
	Game.group_state["done_week"] = {}
	var satisfaction_before := int(Game.groups["potrzebujacy"]["satisfaction"])
	var size_before := int(Game.groups["potrzebujacy"]["size"])
	await CheckBudgetUI._open("phone", {"app": "parafia"})
	CheckBudgetUI._press("Przeprowadź spotkanie")
	await CheckBudgetUI._frames()
	CheckBudgetUI._expect(Game.minutes == 660.0 and Game.energy == 90.0,
		"Spotkanie Caritas nie zużyło 60 minut i 10 energii")
	CheckBudgetUI._expect(int(Game.groups["potrzebujacy"]["satisfaction"]) > satisfaction_before,
		"Spotkanie nie poprawiło wskazanej wspólnoty")
	CheckBudgetUI._expect(int(Game.groups["potrzebujacy"]["size"]) > size_before,
		"Spotkanie nie zwiększyło liczebności wskazanej wspólnoty")
	await CheckBudgetUI._open("phone", {"app": "parafia"})
	CheckBudgetUI._expect(_button_disabled("Przeprowadź spotkanie"), "Drugie spotkanie w tygodniu pozostało dostępne")
	await CheckBudgetUI._capture("groups-meeting")

	# Zapis zachowuje finansowanie i skutek spotkania; bank ujawnia stałą opłatę.
	var saved_satisfaction := int(Game.groups["potrzebujacy"]["satisfaction"])
	Game.save_now()
	Game.community["caritas"] = false
	Game.groups["potrzebujacy"]["satisfaction"] = 0
	CheckBudgetUI._expect(Game.continue_game(), "Nie udało się wczytać zapisu wspólnot")
	CheckBudgetUI._expect(bool(Game.community.get("caritas", false)) and int(Game.groups["potrzebujacy"]["satisfaction"]) == saved_satisfaction,
		"Wczytanie zgubiło wspólnotę albo jej stan")
	await CheckBudgetUI._open("phone", {"app": "parafia"})
	CheckBudgetUI._expect(_button_disabled("Przeprowadź spotkanie"),
		"Wczytanie zgubiło blokadę drugiego spotkania w tym tygodniu")
	await CheckBudgetUI._open("phone", {"app": "bank"})
	CheckBudgetUI._expect(CheckBudgetUI._has_text("aktywne wspólnoty"), "Bank nie pokazuje dodatkowej opłaty wspólnot")

	# Dwie silne niezadowolone strony są czytelnie nazwane w widoku kryzysu.
	Game.groups["seniorzy"]["satisfaction"] = 10
	Game.groups["seniorzy"]["size"] = 500
	Game.groups["pracujacy"]["satisfaction"] = 10
	Game.groups["pracujacy"]["size"] = 500
	Groups.refresh()
	await CheckBudgetUI._open("phone", {"app": "parafia"})
	CheckBudgetUI._expect(CheckBudgetUI._has_text("możliwe strony kryzysu"), "Widok nie nazwał stron kryzysu frakcji")
	CheckBudgetUI._expect(CheckBudgetUI._has_text("seniorzy") and CheckBudgetUI._has_text("pracujący"),
		"Widok kryzysu nie wymienia Seniorów i Pracujących")
	await CheckBudgetUI._capture("groups-faction")
	return _report()


static func _button_disabled(prefix: String) -> bool:
	for node in CheckBudgetUI.ui._modal_layer.find_children("*", "Button", true, false):
		if node.text.begins_with(prefix) and not node.is_queued_for_deletion():
			return node.disabled
	return false


static func _scroll_to_bottom() -> void:
	for node in CheckBudgetUI.ui._modal_layer.find_children("*", "ScrollContainer", true, false):
		var scroll := node as ScrollContainer
		scroll.get_v_scroll_bar().value = scroll.get_v_scroll_bar().max_value
	await CheckBudgetUI._frames()


static func _report() -> bool:
	if CheckBudgetUI.problems.is_empty():
		print("GROUPS UI CHECK OK: telefon, opłaty, anulowanie, spotkanie, zapis i widok.")
	else:
		for problem in CheckBudgetUI.problems:
			printerr("GROUPS UI CHECK FAILED: " + problem)
	return CheckBudgetUI.problems.is_empty()
