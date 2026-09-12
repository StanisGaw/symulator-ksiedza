class_name FinanceView
## Okno finansów: awarie do naprawy przed inwestycjami, każda z kartą mówiącą,
## co postawi, co odblokuje i po ilu tygodniach się zwróci.
##
## Zakładka budżetu w kategoriach (wydanie 2.3) dopisuje się tutaj.


static func _show_finance(ui: Ui) -> void:
	var box := ui._window("Finanse i inwestycje", 940.0)
	ui._text(box, "Konto: %s zł      W tym tygodniu: wpływy %s zł, wydatki %s zł      Stałe koszty tygodnia: %s zł      Stały dochód z inwestycji: %s zł" % [
		ui._money(Game.money), ui._money(Game.week_income), ui._money(Game.week_expenses), ui._money(Finance.WEEKLY_EXPENSES), ui._money(Finance.weekly_yield())], 17)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	# awarie idą przed inwestycjami, bo każdy dzień zwłoki kosztuje
	if not Game.breakdowns.is_empty():
		var head := ui._text(list, "Awarie do naprawy", 22)
		head.add_theme_color_override("font_color", Color(0.92, 0.45, 0.35))
		for id in Game.breakdowns:
			_breakdown_card(ui, list, id)
		ui._text(list, "Inwestycje", 22)
	for id in Finance.INVESTMENTS:
		_investment_card(ui, list, id)
	ui._button(box, "Zamknij", ui._close_modal)


## Karta awarii: co się psuje każdego dnia, ile kosztuje naprawa i jak długo potrwa.
static func _breakdown_card(ui: Ui, list: Control, id: String) -> void:
	var def: Dictionary = Breakdowns.ALL[id]
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.1, 0.1)
	style.border_color = Color(0.55, 0.3, 0.25)
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	list.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var open_days: int = Game.day - int(Game.breakdown_since.get(id, Game.day))
	var since := "od dziś" if open_days <= 0 else "trwa %s" % Game.days_text(open_days)
	ui._text(info, "%s   —   %s zł, %s naprawy" % [def["label"], ui._money(def["cost"]), Game.days_text(int(def["days"]))], 21)
	_card_line(ui, info, "Stan", "%s. %s" % [since, def.get("note", "")])
	_card_line(ui, info, "Kosztuje co dzień", Parish.effects_text(def.get("daily", {})))
	if def.has("blocks"):
		_card_line(ui, info, "Blokuje", str(Game.ACTIVITIES[def["blocks"]]["label"]))
	var label := "Napraw"
	if Game.pending_repairs.has(id):
		label = "W trakcie"
	elif Game.money < int(def["cost"]):
		label = "Za drogo"
	var b := ui._button(row, label, func() -> void:
		Repairs.repair(id)
		ui._close_modal()
		ui._enqueue("finance", {}), Repairs.can_repair(id))
	b.custom_minimum_size = Vector2(150, 52)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER


## Karta inwestycji: co stanie w świecie, co się odblokuje, ile to daje i kiedy się zwróci.
static func _investment_card(ui: Ui, list: Control, id: String) -> void:
	var def: Dictionary = Finance.INVESTMENTS[id]
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.14)
	style.border_color = Color(0.32, 0.29, 0.25)
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	list.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var days_text := "od ręki" if int(def["days"]) == 0 else "%s prac" % Game.days_text(int(def["days"]))
	ui._text(info, "%s   —   %s zł, %s" % [def["label"], ui._money(def["cost"]), days_text], 21)
	_card_line(ui, info, "Postawi", str(def.get("builds", "")))
	_card_line(ui, info, "Odblokuje", str(def.get("unlocks", "")))
	var weekly := int(def.get("weekly", 0))
	if weekly > 0:
		var note := str(def.get("yield_note", "%s zł tygodniowo" % ui._money(weekly)))
		_card_line(ui, info, "Zysk", "%s. Zwrot po około %d tygodniach." % [note, Finance.payback_weeks(id)])
	else:
		_card_line(ui, info, "Zysk", "bez stałego dochodu")
	if not (def["effects"] as Dictionary).is_empty():
		_card_line(ui, info, "Po ukończeniu", Parish.effects_text(def["effects"]))
	var label := "Zleć"
	if Game.pending_investments.has(id):
		label = "W trakcie"
	elif not def.get("repeatable", false) and Game.built.has(id):
		label = "Gotowe"
	elif Game.money < int(def["cost"]):
		label = "Za drogo"
	var b := ui._button(row, label, func() -> void:
		Finance.invest(id)
		ui._close_modal()
		ui._enqueue("finance", {}), Finance.can_invest(id))
	b.custom_minimum_size = Vector2(150, 52)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER


static func _card_line(ui: Ui, box: Control, head: String, text: String) -> void:
	var l := Label.new()
	l.text = "%s: %s" % [head, text]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.78, 0.75, 0.7))
	box.add_child(l)
