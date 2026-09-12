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
	if app == "bank":
		_phone_bank(ui, box)
	else:
		_phone_inbox(ui, box, app)
	ui._button(box, "Zamknij", ui._close_modal)


static func _phone_bank(ui: Ui, box: VBoxContainer) -> void:
	ui._text(box, "Stan konta: %s zł" % ui._money(Game.money), 24)
	ui._text(box, "W tym tygodniu: wpływy %s zł, wydatki %s zł. Stałe rachunki i pensje: %s zł na koniec tygodnia." % [
		ui._money(Game.week_income), ui._money(Game.week_expenses), ui._money(Finance.WEEKLY_EXPENSES)], 17)
	var yield_total: int = Finance.weekly_yield()
	if yield_total > 0:
		ui._text(box, "Dochód z inwestycji: %s zł tygodniowo." % ui._money(yield_total), 17)
	ui._text(box, "Historia operacji", 22)
	if Game.bank_log.is_empty():
		ui._text(box, "Konto jeszcze nic nie widziało.", 17)
		return
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 280)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for entry in Game.bank_log:
		var amount := int(entry["amount"])
		var l := Label.new()
		l.text = "dzień %d   %s   %s%s zł" % [int(entry["day"]), str(entry["text"]),
			"+" if amount >= 0 else "-", ui._money(absi(amount))]
		l.add_theme_font_size_override("font_size", 17)
		l.add_theme_color_override("font_color",
			Color(0.62, 0.82, 0.6) if amount >= 0 else Color(0.92, 0.6, 0.5))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(l)


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
				Inbox.answer(index, oi)
				ui._close_modal()
				ui._enqueue("phone", {"app": app}))
	var sep := HSeparator.new()
	list.add_child(sep)
