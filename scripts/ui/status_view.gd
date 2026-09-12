class_name StatusView
## Okno stanu parafii i kroniki: wskaźniki, rozkład mszy, co w toku, co się wydarzyło.
##
## Drzewka rozwoju i statystyki księdza (wydanie 2.5) dopisują się tutaj.


static func _show_status(ui: Ui) -> void:
	var box := ui._window("Stan parafii i kronika", 880.0)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 475)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	ui._text(content, "Reputacja %d   Stan budynków %d   Tradycjonaliści %d   Młode rodziny %d   Kuria %d   Szacunek %d" % [
		Game.reputation, Game.condition, Game.trad, Game.young, Game.curia, Game.respect], 18)
	ui._text(content, "Rozkład mszy", 22)
	ui._text(content, "Dziś (%s): %s" % [Game.day_name().to_lower(), Game.schedule_text()], 17)
	ui._text(content, "Niedziele i święta nakazane: %s      Dni powszednie: %s" % [
		_hours_list(Game.sunday_hours), _hours_list(Game.weekday_hours)], 17)
	var saved := Game.saved_day()
	if saved > 0:
		ui._text(content, "Ostatni zapis: poranek dnia %d." % saved, 17)
	else:
		ui._text(content, "Gra zapisze się przy przejściu do nowego dnia.", 17)
	if not Game.breakdowns.is_empty():
		ui._text(content, "Awarie:", 22)
		for id in Game.breakdowns:
			var def: Dictionary = Breakdowns.ALL[id]
			var state := "naprawa w toku" if Game.pending_repairs.has(id) else "naprawa %s zł" % ui._money(def["cost"])
			ui._text(content, "• %s — %s" % [def["label"], state], 17)
	if not Game.scheduled.is_empty():
		ui._text(content, "W toku:", 22)
		for item in Game.scheduled:
			ui._text(content, "• Dzień %d: %s" % [item["day"], item["text"]], 17)
	ui._text(content, "Kronika:", 22)
	if Game.log_lines.is_empty():
		ui._text(content, "Jeszcze nic się nie wydarzyło.", 17)
	for line in Game.log_lines:
		var l := Label.new()
		l.text = "• " + str(line)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 17)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(l)
	ui._button(box, "Kariera i kuria", func() -> void:
		ui._close_modal()
		ui._enqueue("career", {}))
	ui._button(box, "Zamknij", ui._close_modal)



static func _hours_list(hours: Array) -> String:
	var parts: Array[String] = []
	for h in hours:
		parts.append("%02d:00" % int(h))
	return ", ".join(parts)
