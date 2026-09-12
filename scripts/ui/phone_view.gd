class_name PhoneView
## Telefon: poczta, media i bank. Ekran rysuje się z Game.phone_inbox, odpowiedzi
## idą przez Inbox.
##
## Widok „Parafia” z sześcioma grupami (wydanie 2.6) dopisuje się tutaj.


## Telefon: trzy zakładki. Lista wiadomości z poczty i mediów, a w banku historia
## operacji. Wiadomość z pytaniem pokazuje przyciski odpowiedzi razem ze skutkami.
static func _show_phone(ui: Ui, app: String) -> void:
	var waiting := Inbox.waiting()
	var title := "Telefon"
	if waiting > 0:
		title += "   •   %d czeka na odpowiedź" % waiting
	var box := ui._window(title, 900.0)
	_phone_app_tabs(ui, box, app)
	if app == "bank":
		_phone_bank(ui, box, "historia")
	else:
		_phone_inbox(ui, box, app)
	ui._button(box, "Zamknij", ui._close_modal)


static func _phone_app_tabs(ui: Ui, box: VBoxContainer, app: String) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	for id in Phone.APPS:
		var label: String = Phone.APP_LABELS[id]
		if id != "bank":
			var n := 0
			for m in Game.phone_inbox:
				if m.get("app", "") == id and not bool(m.get("read", true)):
					n += 1
			if n > 0:
				label += " (%d)" % n
		var button := ui._button(tabs, label, func() -> void:
			ui._close_modal()
			ui._enqueue("phone", {"app": id}))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = id == app


static func _phone_bank(ui: Ui, box: VBoxContainer, tab: String, draft: Dictionary = {}) -> void:
	ui._text(box, "Stan konta: %s zł" % ui._money(Game.money), 24)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	var history := ui._button(tabs, "Historia operacji", func() -> void:
		_replace_phone_modal(ui, "historia"))
	history.disabled = tab == "historia"
	var budget := ui._button(tabs, "Budżet tygodnia", func() -> void:
		_replace_phone_modal(ui, "budzet"))
	budget.disabled = tab == "budzet"
	if tab == "budzet":
		_phone_budget(ui, box, draft)
		return
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	_bank_forecast(ui, list)
	ui._text(list, "W tym tygodniu: wpływy %s zł, wydatki %s zł. Rachunki i pensje: %s zł w najbliższy poniedziałek." % [
		ui._money(Game.week_income), ui._money(Game.week_expenses), ui._money(Finance.weekly_expenses())], 17)
	var yield_total: int = Finance.weekly_yield()
	if yield_total > 0:
		ui._text(list, "Dochód z inwestycji: %s zł tygodniowo." % ui._money(yield_total), 17)
	ui._text(list, "Historia operacji", 22)
	if Game.bank_log.is_empty():
		ui._text(list, "Konto jeszcze nic nie widziało.", 17)
		return
	for entry in Game.bank_log:
		var amount := int(entry["amount"])
		var l := Label.new()
		l.text = "dzień %d   [%s] %s   %s%s zł" % [int(entry["day"]), _bank_category(entry), str(entry["text"]),
			"+" if amount >= 0 else "-", ui._money(absi(amount))]
		l.add_theme_font_size_override("font_size", 17)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_color_override("font_color",
			Color(0.62, 0.82, 0.6) if amount >= 0 else Color(0.92, 0.6, 0.5))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(l)


## Wymiana treści modalu zostawia telefon otwarty i nie przesuwa kolejki innych okien.
static func _replace_phone_modal(ui: Ui, tab: String, draft: Dictionary = {}) -> void:
	for child in ui._modal_layer.get_children():
		child.queue_free()
	var box := ui._window("Telefon", 900.0)
	_phone_app_tabs(ui, box, "bank")
	_phone_bank(ui, box, tab, draft)
	ui._button(box, "Zamknij", ui._close_modal)


## Suwaki pracują na lokalnym draftcie. Dopiero Zapisz wywołuje atomowy zapis Finance.
static func _phone_budget(ui: Ui, box: VBoxContainer, draft_seed: Dictionary = {}) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	ui._text(list, "Plan do najbliższego poniedziałku", 22)
	ui._text(list, "Prognoza jest konserwatywna: liczy stan konta, stałe dochody i budżet. Nie zakłada tacy, ofiar ani kosztów awarii.", 16)
	var draft: Dictionary = Finance.normalize_budget(Game.budget if draft_seed.is_empty() else draft_seed)
	var preview := Label.new()
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.add_theme_font_size_override("font_size", 17)
	list.add_child(preview)
	for id_variant in Finance.BUDGET_CATEGORIES:
		var id := str(id_variant)
		var def: Dictionary = Finance.BUDGET_CATEGORIES[id]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		list.add_child(row)
		var title := Label.new()
		title.text = "%s — poziom %d/3" % [str(def["label"]), int(draft[id])]
		title.add_theme_font_size_override("font_size", 18)
		row.add_child(title)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 3
		slider.step = 1
		slider.value = int(draft[id])
		slider.custom_minimum_size = Vector2(0, 24)
		row.add_child(slider)
		var detail := Label.new()
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 15)
		detail.add_theme_color_override("font_color", Color(0.78, 0.75, 0.7))
		row.add_child(detail)
		var refresh := func() -> void:
			title.text = "%s — poziom %d/3" % [str(def["label"]), int(draft[id])]
			detail.text = "%s zł tygodniowo. %s" % [ui._money(Finance.category_cost(id, int(draft[id]))), _budget_note(def, int(draft[id]))]
			_budget_preview(ui, preview, draft)
		refresh.call()
		slider.value_changed.connect(func(value: float) -> void:
			draft[id] = int(value)
			refresh.call())
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	list.add_child(actions)
	var save := ui._button(actions, "Zapisz plan", func() -> void:
		if Finance.needs_confirmation(0, draft):
			_budget_confirmation(ui, draft)
			return
		if Finance.set_budget(draft):
			ui._close_modal()
			ui._enqueue("phone", {"app": "bank"})
		else:
			Game.toast.emit("Nie można zapisać planu: aktywna rezerwacja wymaga poziomu remontów.")
			_replace_phone_modal(ui, "budzet", draft))
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cancel := ui._button(actions, "Anuluj zmiany", func() -> void:
		ui._close_modal()
		ui._enqueue("phone", {"app": "bank"}))
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL


static func _budget_note(def: Dictionary, level: int) -> String:
	var notes: Array = def.get("notes", [])
	if level >= 0 and level < notes.size():
		return str(notes[level])
	var effects: Array = def.get("effects", [])
	if level >= 0 and level < effects.size():
		return Parish.effects_text(effects[level])
	return "Skutek zostanie rozliczony w poniedziałek."


static func _budget_preview(ui: Ui, label: Label, draft: Dictionary) -> void:
	var forecast: Dictionary = Finance.forecast(draft)
	label.text = "Podgląd: koszty %s zł • stałe dochody %s zł • prognoza na poniedziałek %s zł" % [
		ui._money(int(forecast.get("costs", 0))), ui._money(int(forecast.get("income", 0))), ui._money(int(forecast.get("balance", 0)))]
	if int(forecast.get("balance", 0)) < 0:
		label.text += "\nDeficyt: odsetki %s zł, kuria %d przy rozliczeniu. Zapis wymaga potwierdzenia." % [
			ui._money(int(forecast.get("interest", 0))), int(forecast.get("curia_delta", -3))]
		label.add_theme_color_override("font_color", Color(0.95, 0.65, 0.45))
	else:
		label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.68))


## Bank pokazuje ostrzeżenie już przy wejściu, zanim gracz dotknie planu tygodnia.
static func _bank_forecast(ui: Ui, box: VBoxContainer) -> void:
	var forecast: Dictionary = Finance.forecast()
	var text := "Prognoza do najbliższego poniedziałku: %s zł (koszty %s zł, stałe dochody %s zł)." % [
		ui._money(int(forecast.get("balance", 0))), ui._money(int(forecast.get("costs", 0))), ui._money(int(forecast.get("income", 0)))]
	if int(forecast.get("balance", 0)) < 0:
		text += " Deficyt oznacza odsetki %s zł i kurię %d." % [
			ui._money(int(forecast.get("interest", 0))), int(forecast.get("curia_delta", -3))]
	text += " Prognoza pomija niepewną tacę, ofiary, zdarzenia i koszty awarii."
	var label := ui._text(box, text, 17)
	if int(forecast.get("balance", 0)) < 0:
		label.add_theme_color_override("font_color", Color(0.95, 0.65, 0.45))


static func _budget_confirmation(ui: Ui, draft: Dictionary) -> void:
	var forecast: Dictionary = Finance.forecast(draft)
	for child in ui._modal_layer.get_children():
		child.queue_free()
	var box := ui._window("Potwierdź deficyt", 760.0)
	ui._text(box, "Plan daje prognozowane saldo %s zł do najbliższego poniedziałku." % ui._money(int(forecast["balance"])), 21)
	ui._text(box, "Odsetki: %s zł. Kuria: %d przy rozliczeniu. Prognoza nie liczy tacy, ofiar ani awarii." % [
		ui._money(int(forecast.get("interest", 0))), int(forecast.get("curia_delta", -3))], 17)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	ui._button(actions, "Tak, zapisuję plan", func() -> void:
		if Finance.set_budget(draft, true):
			ui._close_modal()
			ui._enqueue("phone", {"app": "bank"})
		else:
			Game.toast.emit("Plan nie został zapisany.")
			_replace_phone_modal(ui, "budzet", draft))
	ui._button(actions, "Wróć do planu", func() -> void:
		_replace_phone_modal(ui, "budzet", draft))


static func _bank_category(entry: Dictionary) -> String:
	var category := str(entry.get("category", "inne"))
	if Finance.BUDGET_CATEGORIES.has(category):
		return str((Finance.BUDGET_CATEGORIES[category] as Dictionary).get("label", category))
	match category:
		"taca": return "taca"
		"ofiary": return "ofiary"
		"odsetki": return "odsetki"
		"wydarzenia": return "wydarzenia"
		"inwestycje": return "inwestycje"
		"naprawy": return "naprawy"
	return "inne"


static func _phone_inbox(ui: Ui, box: VBoxContainer, app: String) -> void:
	var indexes: Array[int] = []
	for i in Game.phone_inbox.size():
		if Game.phone_inbox[i].get("app", "") == app:
			indexes.append(i)
	if indexes.is_empty():
		ui._text(box, "Nic nowego." if app == "media" else "Skrzynka pusta.", 18)
		return
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i in indexes:
		_phone_message(ui, list, i, Game.phone_inbox[i])


static func _phone_message(ui: Ui, list: VBoxContainer, index: int, msg: Dictionary) -> void:
	var head := Label.new()
	var mark := "" if bool(msg.get("read", true)) else "•  "
	head.text = "%s%s — %s   (dzień %d)" % [mark, str(msg.get("from", "")), str(msg.get("title", "")), int(msg.get("day", 0))]
	head.add_theme_font_size_override("font_size", 19)
	head.add_theme_color_override("font_color", Color(1, 0.88, 0.66) if mark != "" else Color(0.85, 0.85, 0.85))
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(head)
	var body := Label.new()
	body.text = str(msg.get("text", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 17)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(body)
	Inbox.mark_read(index)
	var answered := int(msg.get("answered", -1))
	if bool(msg.get("expired", false)):
		var late := Label.new()
		late.text = "Termin minął, sprawa potoczyła się bez ciebie."
		late.add_theme_font_size_override("font_size", 16)
		late.add_theme_color_override("font_color", Color(0.92, 0.45, 0.35))
		list.add_child(late)
	elif answered >= 0:
		var done := Label.new()
		done.text = "Odpowiedziano: %s" % str(msg["options"][answered]["label"])
		done.add_theme_font_size_override("font_size", 16)
		done.add_theme_color_override("font_color", Color(0.62, 0.82, 0.6))
		list.add_child(done)
	elif msg.has("options"):
		if msg.has("due"):
			var due := Label.new()
			var left: int = int(msg["due"]) - Game.day
			due.text = "Termin: dziś" if left <= 0 else "Termin: za %d dni" % left
			due.add_theme_font_size_override("font_size", 16)
			due.add_theme_color_override("font_color", Color(0.92, 0.78, 0.45))
			list.add_child(due)
		for oi in msg["options"].size():
			var opt: Dictionary = msg["options"][oi]
			var label: String = opt["label"]
			if opt.has("effects"):
				label += "   (" + Parish.effects_text(opt["effects"]) + ")"
			var app: String = str(msg.get("app", "poczta"))
			ui._button(list, label, func() -> void:
				var effects: Dictionary = opt.get("effects", {})
				var expense := maxi(0, -int(effects.get("money", 0)))
				if expense > 0 and Finance.needs_confirmation(expense):
					var accept := func() -> void:
						Inbox.answer(index, oi)
						ui._close_modal()
						ui._enqueue("phone", {"app": app})
					var cancel := func() -> void:
						ui._close_modal()
						ui._enqueue("phone", {"app": app})
					FinanceView.confirm_expense(ui, "wydatek z wiadomości: " + label, expense, accept, cancel)
					return
				Inbox.answer(index, oi)
				ui._close_modal()
				ui._enqueue("phone", {"app": app}))
	var sep := HSeparator.new()
	list.add_child(sep)
