class_name Ui
extends CanvasLayer
## High-resolution UI layer (1280x720 base): status bar, interaction prompt, toasts and modal windows
## (events, reports, finance ledger, parish status). Modals block gameplay and pause the clock.

var _root: Control
var _hud: Label
var _prompt: Label
var _toasts: VBoxContainer
var _modal_layer: Control
var _cutscene_panel: PanelContainer
var _cutscene_label: Label
var _night: ColorRect
var _queue: Array = []
var _theme: Theme


func _ready() -> void:
	layer = 10
	_theme = _make_theme()
	_build()
	Game.prompt_changed.connect(_on_prompt)
	Game.toast.connect(_on_toast)
	Game.modal_requested.connect(_enqueue)
	Game.cutscene_started.connect(_on_cutscene_started)
	Game.cutscene_ended.connect(_on_cutscene_ended)
	# debug: godot --path . -- --modal=finance|status|event|report
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--modal="):
			call_deferred("_debug_modal", arg.trim_prefix("--modal="))
		elif arg.begins_with("--phone"):
			# debug: --phone albo --phone=bank|media otwiera telefon od razu po starcie
			var app := arg.trim_prefix("--phone").trim_prefix("=")
			call_deferred("_enqueue", "phone", {"app": app if app != "" else "poczta"})
		elif arg == "--sleep":
			Game.call_deferred("sleep_hours", 8.0)
		elif arg == "--mass":
			Game.call_deferred("do_activity", "mass")
		elif arg.begins_with("--do="):
			Game.call_deferred("do_activity", arg.trim_prefix("--do="))
		elif arg == "--continue":
			call_deferred("_enqueue", "continue", {"day": Game.saved_day()})
		elif arg == "--visit":
			Game.call_deferred("do_activity", "visit_sick")
		elif arg.begins_with("--event="):
			# --event=organ_silent otwiera konkretne wydarzenie, także kryzys
			var ev := Events.by_id(arg.trim_prefix("--event="))
			if ev.is_empty():
				push_warning("Nie ma wydarzenia o tym identyfikatorze.")
			else:
				call_deferred("_enqueue", "event", {"event": ev})


func _debug_modal(kind: String) -> void:
	match kind:
		"event": _enqueue("event", {"event": Events.POOL[0]})
		"report": _enqueue("report", {"title": "Poniedziałek, 8 grudnia   Adwent", "lines": ["Rozliczenie tygodnia: taca i ofiary 3 420 zł, wydatki 2 500 zł, rachunki i pensje 4 200 zł.", "Stan konta: 8 720 zł.", "Festyn parafialny: prace zakończone. młode rodziny +8, reputacja +4, tradycjonaliści -3."]})
		_: _enqueue(kind, {})


## Telefon otwiera się klawiszem, bo to nie jest sprzęt przy biurku - ksiądz nosi go
## przy sobie. Nie otwieramy go w trakcie scenki ani nad innym oknem.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("phone"):
		return
	if Game.modal_open or Game.cutscene:
		return
	get_viewport().set_input_as_handled()
	_enqueue("phone", {})


func _process(_delta: float) -> void:
	var head := "%s   %s   dzień %d" % [Game.date_text(), Game.season(), Game.day]
	var feast: String = Game.feast_name()
	if feast != "":
		head += "   •   " + feast
	# telefon zawsze pod ręką; w górnej linii, bo dolna jest już pełna wskaźników
	var unread := Inbox.unread()
	var waiting := Inbox.waiting()
	head += "   •   [P] Telefon"
	if unread > 0:
		head += ": %d nowe" % unread
	if waiting > 0:
		head += ", %d czeka" % waiting
	var line := "%s      Energia %d%%      %s zł      Reputacja %d   Budynki %d   Tradycjonaliści %d   Młode rodziny %d   Kuria %d   Szacunek %d" % [
		Game.clock_text(), int(Game.energy), _money(Game.money),
		Game.reputation, Game.condition, Game.trad, Game.young, Game.curia, Game.respect]
	# awaria kosztuje codziennie, więc musi być widoczna bez otwierania okna
	if not Game.breakdowns.is_empty():
		line += "   •   Awarie: %d" % Game.breakdowns.size()

	_hud.text = "%s\n%s" % [head, line]


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

	_night = ColorRect.new()
	_night.color = Color(0.02, 0.02, 0.04, 0.8)
	_night.set_anchors_preset(Control.PRESET_FULL_RECT)
	_night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_night.visible = false
	_root.add_child(_night)

	_modal_layer = Control.new()
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_modal_layer)

	_cutscene_panel = PanelContainer.new()
	_cutscene_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_cutscene_panel.offset_left = -560
	_cutscene_panel.offset_top = -150
	_cutscene_panel.offset_right = -24
	_cutscene_panel.offset_bottom = -24
	var cut_box := HBoxContainer.new()
	cut_box.add_theme_constant_override("separation", 16)
	_cutscene_label = Label.new()
	_cutscene_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cutscene_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cutscene_label.add_theme_font_size_override("font_size", 18)
	cut_box.add_child(_cutscene_label)
	var skip := Button.new()
	skip.text = "Pomiń"
	skip.custom_minimum_size = Vector2(140, 52)
	skip.pressed.connect(Game.skip_cutscene)
	cut_box.add_child(skip)
	_cutscene_panel.add_child(cut_box)
	_cutscene_panel.visible = false
	_root.add_child(_cutscene_panel)


func _money(v: int) -> String:
	return Game.money_text(v)


func _on_cutscene_started(label: String) -> void:
	# stan sceny, nie jej napis: zmiana tekstu nie może po cichu wyłączyć wygaszania
	if Game.cutscene_id == "night":
		_night.visible = true
		_night.modulate.a = 0.0
		create_tween().tween_property(_night, "modulate:a", 1.0, 0.7)
	_cutscene_label.text = label + "…"
	_cutscene_panel.visible = true
	_prompt.visible = false


func _on_cutscene_ended() -> void:
	if _night.visible:
		var tween := create_tween()
		tween.tween_property(_night, "modulate:a", 0.0, 0.6)
		tween.tween_callback(func() -> void: _night.visible = false)
	_cutscene_panel.visible = false
	_prompt.visible = true


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
		"finance": FinanceView._show_finance(self)
		"status": StatusView._show_status(self)
		"sleep": _show_sleep()
		"bench": _show_bench()
		"phone": PhoneView._show_phone(self, item["data"].get("app", "poczta"))
		"continue": _show_continue(item["data"])
		"confirm_new": _show_confirm_new()


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


func _show_bench() -> void:
	var box := _window("Ławka przed kościołem", 720.0)
	_text(box, "Brewiarz, ptaki i spokój. Godzina siedzenia to +%d energii. Dobre miejsce, żeby doczekać do mszy. Do końca doby zostało %s." % [
		int(Game.READ_ENERGY_PER_HOUR), Game.duration_text(24.0 * 60.0 - Game.minutes)])
	var info := _text(box, "", 22)
	var slider := HSlider.new()
	slider.min_value = Game.READ_MIN_MINUTES
	# na ławce da się siedzieć najwyżej do końca doby, potem trzeba iść spać
	slider.max_value = maxf(float(Game.READ_MIN_MINUTES),
		floor((24.0 * 60.0 - Game.minutes) / Game.READ_STEP_MINUTES) * Game.READ_STEP_MINUTES)
	slider.step = Game.READ_STEP_MINUTES
	slider.value = minf(60.0, slider.max_value)
	slider.custom_minimum_size = Vector2(0, 44)
	box.add_child(slider)
	var describe := func(span: float) -> void:
		var energy := mini(100, int(Game.energy) + Game.read_gain(span))
		info.text = "%s  •  wstajesz o %s  •  energia %d%%" % [
			Game.duration_text(span), Game.clock_text_at(Game.minutes + span), energy]
	slider.value_changed.connect(describe)
	describe.call(slider.value)
	_button(box, "Siedź", func() -> void:
		var span: float = slider.value
		_close_modal()
		Game.call_deferred("read_breviary", span))
	var wait := Game.minutes_to_next_mass()
	if wait >= float(Game.READ_MIN_MINUTES) and wait <= float(Game.READ_MAX_MINUTES):
		_button(box, "Poczekaj do mszy o %02d:00 (%s)" % [Game.next_mass_hour(), Game.duration_text(wait)], func() -> void:
			_close_modal()
			Game.call_deferred("read_breviary", wait))
	_button(box, "Wróć", _close_modal)


func _show_sleep() -> void:
	var box := _window("Łóżko", 720.0)
	_text(box, "Godzina snu to +%d energii, osiem godzin stawia na nogi. Dłuższy sen zabiera dzień, a msze same się nie odprawią." % int(Game.ENERGY_PER_HOUR))
	var info := _text(box, "", 22)
	var slider := HSlider.new()
	slider.min_value = 1
	slider.max_value = Game.MAX_SLEEP_HOURS
	slider.step = 1
	slider.value = 8
	slider.custom_minimum_size = Vector2(0, 44)
	box.add_child(slider)
	var describe := func(hours: float) -> void:
		var energy := mini(100, int(Game.energy + hours * Game.ENERGY_PER_HOUR))
		var wake := Game.clock_text_at(Game.minutes + hours * 60.0)
		var next_day := " (jutro)" if Game.minutes + hours * 60.0 >= 24.0 * 60.0 else ""
		info.text = "%s  •  pobudka o %s%s  •  energia %d%%" % [Game.hours_text(hours), wake, next_day, energy]
	slider.value_changed.connect(describe)
	describe.call(slider.value)
	_button(box, "Śpij", func() -> void:
		var hours: float = slider.value
		_close_modal()
		Game.call_deferred("sleep_hours", hours))
	var to_six := Game.hours_until_six()
	if to_six > 0.0:
		_button(box, "Śpij do 6:00 (%s)" % Game.hours_text(to_six), func() -> void:
			_close_modal()
			Game.call_deferred("sleep_hours", to_six))
	_button(box, "Wróć", _close_modal)


func _show_continue(data: Dictionary) -> void:
	var box := _window("Symulator Księdza", 640.0)
	_text(box, "Jest zapis z poranka dnia %d. Gra zapisuje się sama przy każdym przejściu do nowego dnia." % int(data.get("day", 1)))
	_button(box, "Kontynuuj", func() -> void:
		if not Game.continue_game():
			Game.toast.emit("Zapis jest uszkodzony. Zaczynamy od nowa.")
			Game.start_new_game()
		_close_modal())
	_button(box, "Nowa gra", func() -> void:
		_close_modal()
		_enqueue("confirm_new", {}))


func _show_confirm_new() -> void:
	var box := _window("Nowa gra", 640.0)
	_text(box, "Dotychczasowy zapis zostanie skasowany. Na pewno?")
	_button(box, "Tak, zaczynam od nowa", func() -> void:
		Game.start_new_game()
		_close_modal())
	_button(box, "Wróć", func() -> void:
		_close_modal()
		_enqueue("continue", {"day": Game.saved_day()}))


func _show_event(ev: Dictionary) -> void:
	var box := _window(ev["title"])
	if ev.get("crisis", false):
		var warn := _text(box, "To jest kryzys. Nie da się go odłożyć i każde wyjście coś kosztuje.", 18)
		warn.add_theme_color_override("font_color", Color(0.92, 0.45, 0.35))
	_text(box, ev["text"])
	var opts := VBoxContainer.new()
	opts.add_theme_constant_override("separation", 8)
	box.add_child(opts)
	for i in ev["options"].size():
		var opt: Dictionary = ev["options"][i]
		var label: String = opt["label"]
		if opt.has("effects"):
			label += "   (" + Parish.effects_text(opt["effects"]) + ")"
		_button(opts, label, func() -> void:
			EventFlow.choose_option(ev, i)
			_close_modal())


func _show_report(title: String, lines: Array) -> void:
	var box := _window(title)
	for line in lines:
		_text(box, "• " + str(line))
	_button(box, "Dalej", _close_modal)


