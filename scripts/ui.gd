extends CanvasLayer
## High-resolution UI layer (1280x720 base): status bar, interaction prompt, toasts and modal windows
## (events, reports, finance ledger, parish status). Modals block gameplay and pause the clock.

var _root: Control
var _hud: Label
var _prompt: Label
var _toasts: VBoxContainer
var _modal_layer: Control
var _queue: Array = []
var _theme: Theme


func _ready() -> void:
	layer = 10
	_theme = _make_theme()
	_build()
	Game.prompt_changed.connect(_on_prompt)
	Game.toast.connect(_on_toast)
	Game.modal_requested.connect(_enqueue)
	# debug: godot --path . -- --modal=finance|status|event|report
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--modal="):
			call_deferred("_debug_modal", arg.trim_prefix("--modal="))
		elif arg == "--sleep":
			Game.call_deferred("sleep")


func _debug_modal(kind: String) -> void:
	match kind:
		"event": _enqueue("event", {"event": Events.EVENTS[0]})
		"report": _enqueue("report", {"title": "Dzień 8, Poniedziałek", "lines": ["Rozliczenie tygodnia: taca i ofiary 3 420 zł, wydatki 2 500 zł, rachunki i pensje 4 200 zł.", "Stan konta: 8 720 zł.", "Festyn parafialny: prace zakończone. młode rodziny +8, reputacja +4, tradycjonaliści -3."]})
		_: _enqueue(kind, {})


func _process(_delta: float) -> void:
	_hud.text = "Dzień %d, %s   %s      Energia %d%%      %s zł      Reputacja %d   Budynki %d   Tradycjonaliści %d   Młode rodziny %d   Kuria %d" % [
		Game.day, Game.day_name(), Game.clock_text(), int(Game.energy), _money(Game.money),
		Game.reputation, Game.condition, Game.trad, Game.young, Game.curia]


# ---------- building blocks ----------

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.07, 0.075, 0.095, 0.96)
	panel.border_color = Color(0.5, 0.45, 0.36)
	panel.set_border_width_all(2)
	panel.set_content_margin_all(26)
	panel.set_corner_radius_all(3)
	t.set_stylebox("panel", "PanelContainer", panel)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.17, 0.16, 0.2)
	normal.border_color = Color(0.4, 0.36, 0.3)
	normal.set_border_width_all(1)
	normal.set_content_margin_all(12)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.25, 0.23, 0.28)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.45, 0.32, 0.2)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.11, 0.11, 0.13)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", hover)
	t.set_color("font_color", "Button", Color(0.92, 0.9, 0.86))
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.48, 0.45))
	t.set_color("font_color", "Label", Color(0.9, 0.88, 0.84))
	return t


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _theme
	add_child(_root)

	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0, 0, 0, 0.55)
	bar_style.set_content_margin_all(8)
	bar_style.content_margin_left = 16
	bar.add_theme_stylebox_override("panel", bar_style)
	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 18)
	bar.add_child(_hud)
	_root.add_child(bar)

	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -120
	_prompt.offset_bottom = -80
	_prompt.offset_left = -400
	_prompt.offset_right = 400
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_prompt.add_theme_constant_override("outline_size", 6)
	_root.add_child(_prompt)

	_toasts = VBoxContainer.new()
	_toasts.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toasts.offset_left = -520
	_toasts.offset_top = 56
	_toasts.offset_right = -16
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.add_theme_constant_override("separation", 8)
	_root.add_child(_toasts)

	_modal_layer = Control.new()
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_modal_layer)


func _money(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = " " + out
	return ("-" if v < 0 else "") + out


func _on_prompt(text: String) -> void:
	_prompt.text = "[E]  " + text if text != "" else ""


func _on_toast(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 18)
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.09, 0.08, 0.92)
	st.border_color = Color(0.8, 0.6, 0.3)
	st.set_border_width_all(1)
	st.border_width_left = 6
	st.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", st)
	p.add_child(l)
	_toasts.add_child(p)
	get_tree().create_timer(5.0).timeout.connect(p.queue_free)


# ---------- modals ----------

func _enqueue(kind: String, data: Dictionary) -> void:
	_queue.append({"kind": kind, "data": data})
	if not Game.modal_open:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		Game.modal_open = false
		return
	Game.modal_open = true
	var item: Dictionary = _queue.pop_front()
	match item["kind"]:
		"event": _show_event(item["data"]["event"])
		"report": _show_report(item["data"]["title"], item["data"]["lines"])
		"finance": _show_finance()
		"status": _show_status()


func _close_modal() -> void:
	for c in _modal_layer.get_children():
		c.queue_free()
	call_deferred("_show_next")


func _window(title: String, width: float = 760.0) -> VBoxContainer:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", Color(1, 0.88, 0.66))
	box.add_child(t)
	return box


func _text(box: VBoxContainer, text: String, size: int = 20) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	box.add_child(l)
	return l


func _button(box: Control, text: String, cb: Callable, enabled: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.disabled = not enabled
	b.pressed.connect(cb)
	box.add_child(b)
	return b


func _show_event(ev: Dictionary) -> void:
	var box := _window(ev["title"])
	_text(box, ev["text"])
	var opts := VBoxContainer.new()
	opts.add_theme_constant_override("separation", 8)
	box.add_child(opts)
	for i in ev["options"].size():
		var opt: Dictionary = ev["options"][i]
		var label: String = opt["label"]
		if opt.has("effects"):
			label += "   (" + Game.effects_text(opt["effects"]) + ")"
		_button(opts, label, func() -> void:
			Game.choose_option(ev, i)
			_close_modal())


func _show_report(title: String, lines: Array) -> void:
	var box := _window(title)
	for line in lines:
		_text(box, "• " + str(line))
	_button(box, "Dalej", _close_modal)


func _show_finance() -> void:
	var box := _window("Finanse parafii", 880.0)
	_text(box, "Konto: %s zł      W tym tygodniu: wpływy %s zł, wydatki %s zł      Stałe koszty tygodnia: %s zł (rachunki, organista, kościelny)" % [
		_money(Game.money), _money(Game.week_income), _money(Game.week_expenses), _money(Game.WEEKLY_EXPENSES)], 18)
	_text(box, "Inwestycje i wydatki", 22)
	var grid := VBoxContainer.new()
	grid.add_theme_constant_override("separation", 6)
	box.add_child(grid)
	for id in Game.INVESTMENTS:
		var def: Dictionary = Game.INVESTMENTS[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		grid.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_l := Label.new()
		name_l.text = "%s   %s zł" % [def["label"], _money(def["cost"])]
		info.add_child(name_l)
		var desc := Label.new()
		desc.text = def["desc"]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 16)
		desc.add_theme_color_override("font_color", Color(0.7, 0.68, 0.64))
		info.add_child(desc)
		var pending: bool = Game.pending_investments.has(id)
		var b := _button(row, "W trakcie" if pending else "Zleć", func() -> void:
			Game.invest(id)
			_close_modal()
			_enqueue("finance", {}), Game.can_invest(id))
		b.custom_minimum_size = Vector2(150, 52)
	_button(box, "Zamknij", _close_modal)


func _show_status() -> void:
	var box := _window("Stan parafii i kronika", 880.0)
	var hour_text := "nie ustalono"
	match Game.mass_hour:
		7: hour_text = "7:00"
		11: hour_text = "11:00"
		99: hour_text = "7:00 i 11:00"
	_text(box, "Reputacja %d   Stan budynków %d   Tradycjonaliści %d   Młode rodziny %d   Kuria %d   Godzina sumy: %s" % [
		Game.reputation, Game.condition, Game.trad, Game.young, Game.curia, hour_text], 18)
	if not Game.scheduled.is_empty():
		_text(box, "W toku:", 22)
		for item in Game.scheduled:
			_text(box, "• Dzień %d: %s" % [item["day"], item["text"]], 17)
	_text(box, "Kronika:", 22)
	if Game.log_lines.is_empty():
		_text(box, "Jeszcze nic się nie wydarzyło.", 17)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 220)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for line in Game.log_lines:
		var l := Label.new()
		l.text = "• " + str(line)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 17)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(l)
	_button(box, "Zamknij", _close_modal)
