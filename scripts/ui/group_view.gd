class_name GroupView
## Telefoniczny obraz sześciu stron parafii i prowadzonych dla nich wspólnot.


static func show_groups(ui: Ui, phone_box: VBoxContainer = null) -> void:
	var standalone := phone_box == null
	var box := phone_box
	if standalone:
		box = ui._window("Parafia", 920.0)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 475)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	_show_summary(ui, content)
	for group_id_variant in ["mlodziez", "rodziny", "pracujacy", "seniorzy", "przedsiebiorcy", "potrzebujacy"]:
		_show_group_card(ui, content, str(group_id_variant))
	_show_initiatives(ui, content)
	if standalone:
		ui._button(box, "Zamknij", ui._close_modal)


static func _show_summary(ui: Ui, content: VBoxContainer) -> void:
	ui._text(content, "Nastroje grup: %d/100. Wpływ powyżej 70 uruchamia tygodniową reakcję: przy zadowoleniu 60+ pomoc finansową, 30–59 wolontariat, poniżej 30 skargę do kurii." % int(round(Groups.support())), 17)
	var fracture: Array = Groups.fracture_members()
	if fracture.is_empty():
		ui._text(content, "Nie ma dziś silnych, skonfliktowanych stron. Kryzys frakcji grozi, gdy co najmniej dwie grupy mają zadowolenie poniżej 30 i wpływ powyżej 60.", 16)
		return
	var names: Array[String] = []
	for group_id_variant in fracture:
		names.append(str(Groups.LABELS.get(str(group_id_variant), group_id_variant)))
	ui._text(content, "Możliwe strony kryzysu: " + ", ".join(names) + ".", 17)


static func _show_group_card(ui: Ui, content: VBoxContainer, group_id: String) -> void:
	var group: Dictionary = Game.groups.get(group_id, {})
	if group.is_empty():
		return
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.14)
	style.border_color = Color(0.32, 0.29, 0.25)
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	content.add_child(card)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 4)
	card.add_child(detail)
	var satisfaction := int(group.get("satisfaction", 0))
	var influence := int(group.get("influence", 0))
	ui._text(detail, "%s — %d osób" % [str(Groups.LABELS.get(group_id, group_id)), int(group.get("size", 0))], 21)
	ui._text(detail, "Zadowolenie %d/100   Wpływ %d/100" % [satisfaction, influence], 17)
	var change: Dictionary = group.get("last_change", {})
	if not change.is_empty():
		var change_text := str(change.get("text", ""))
		var delta := int(change.get("delta", 0))
		var is_growth := change_text.to_lower().contains("osób") or change_text.to_lower().contains("liczebność")
		var unit := " osób" if is_growth else " pkt zadowolenia"
		ui._text(detail, "Ostatnia zmiana, dzień %d: %s%d%s — %s" % [
			int(change.get("day", 0)), "+" if delta >= 0 else "", delta, unit, change_text], 16)
	if influence > 60 and satisfaction < 30:
		ui._text(detail, "Silna niezadowolona strona — może wejść w kryzys frakcji.", 16)
	elif influence > 70:
		ui._text(detail, "Wpływ tej grupy może przynieść pomoc, wolontariat albo skargę w tygodniowym rozliczeniu.", 16)


static func _show_initiatives(ui: Ui, content: VBoxContainer) -> void:
	ui._text(content, "Wspólnoty i spotkania", 22)
	ui._text(content, "Finansowanie działa co tydzień. Spotkanie wykonujesz osobno: zużywa czas i energię, ale nie pobiera opłaty drugi raz.", 16)
	for initiative_id_variant in ["caritas", "swietlica", "katecheza"]:
		_show_initiative(ui, content, str(initiative_id_variant))


static func _show_initiative(ui: Ui, content: VBoxContainer, initiative_id: String) -> void:
	var initiative: Dictionary = Groups.INITIATIVES[initiative_id]
	var active := bool(Game.community.get(initiative_id, false))
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.13, 0.11) if active else Color(0.11, 0.11, 0.14)
	style.border_color = Color(0.45, 0.55, 0.35) if active else Color(0.32, 0.29, 0.25)
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	content.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	ui._text(info, "%s — %s" % [str(initiative["label"]), "aktywna" if active else "wyłączona"], 20)
	ui._text(info, "Opłata: %s zł tygodniowo. Spotkanie: %d minut, %d energii." % [
		ui._money(int(initiative["cost"])), int(initiative["minutes"]), int(initiative["energy"])], 16)
	ui._text(info, _initiative_effects(initiative), 16)
	var current_cost := Groups.activation_cost(initiative_id)
	ui._text(info, "Bieżąca opłata: %s." % ("opłacona w tym tygodniu" if current_cost == 0 else "%s zł" % ui._money(current_cost)), 16)
	var run_reason := Groups.run_reason(initiative_id)
	# Przycisk najpierw zamyka to okno, więc jego własna blokada modalu nie jest
	# przeszkodą dla odroczonego wykonania.
	var modal_only := run_reason.begins_with("Najpierw zamknij")
	if active and run_reason != "" and not modal_only:
		ui._text(info, run_reason, 16)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(180, 0)
	row.add_child(actions)
	if active:
		ui._button(actions, "Wyłącz", func() -> void:
			if Groups.set_initiative(initiative_id, false):
				_replace_groups_phone(ui))
	else:
		ui._button(actions, "Włącz", func() -> void:
			_confirm_activation(ui, initiative_id))
	var meeting := ui._button(actions, "Przeprowadź spotkanie", func() -> void:
		ui._close_modal()
		ui.call_deferred("_run_group_initiative", initiative_id), active and (run_reason == "" or modal_only))
	meeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func _initiative_effects(initiative: Dictionary) -> String:
	var parts: Array[String] = []
	for group_id_variant in (initiative.get("groups", {}) as Dictionary):
		var group_id := str(group_id_variant)
		parts.append("%s +%d zadowolenia" % [str(Groups.LABELS.get(group_id, group_id)), int(initiative["groups"][group_id_variant])])
	for group_id_variant in (initiative.get("size_groups", {}) as Dictionary):
		var group_id := str(group_id_variant)
		parts.append("%s +%d osób" % [str(Groups.LABELS.get(group_id, group_id)), int(initiative["size_groups"][group_id_variant])])
	return "Po spotkaniu: " + ", ".join(parts) + "."


static func _confirm_activation(ui: Ui, initiative_id: String) -> void:
	var initiative: Dictionary = Groups.INITIATIVES[initiative_id]
	var current_cost := Groups.activation_cost(initiative_id)
	var forecast: Dictionary = Groups.activation_forecast(initiative_id)
	for child in ui._modal_layer.get_children():
		child.queue_free()
	var box := ui._window("Włącz wspólnotę", 780.0)
	ui._text(box, "Włączasz: " + str(initiative["label"]), 22)
	ui._text(box, "Bieżąca opłata: %s zł. Stała opłata: %s zł tygodniowo." % [
		ui._money(current_cost), ui._money(int(initiative["cost"]))], 18)
	ui._text(box, "Prognoza na najbliższy poniedziałek po włączeniu: %s zł (koszty %s zł, stałe dochody %s zł)." % [
		ui._money(int(forecast.get("balance", 0))), ui._money(int(forecast.get("costs", 0))), ui._money(int(forecast.get("income", 0)))], 17)
	if int(forecast.get("balance", 0)) < 0:
		ui._text(box, "Deficyt oznacza odsetki %s zł i zmianę kurii o %d przy rozliczeniu." % [
			ui._money(int(forecast.get("interest", 0))), int(forecast.get("curia_delta", 0))], 17)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	ui._button(actions, "Włącz i opłać", func() -> void:
		if Groups.set_initiative(initiative_id, true, true):
			_replace_groups_phone(ui))
	ui._button(actions, "Anuluj", func() -> void:
		_replace_groups_phone(ui))


static func _replace_groups_phone(ui: Ui) -> void:
	for child in ui._modal_layer.get_children():
		child.queue_free()
	PhoneView._show_phone(ui, "parafia")
