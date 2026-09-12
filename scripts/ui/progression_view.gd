class_name ProgressionView
## Telefoniczny profil księdza i trwałe wybory rozwoju za szacunek.

const TREES := {
	"administrator": {"label": "Administrator", "talents": ["admin_accounts", "admin_inspection"]},
	"duszpasterz": {"label": "Duszpasterz", "talents": ["pastor_presence", "pastor_visits"]},
	"gospodarz": {"label": "Gospodarz", "talents": ["host_media", "host_curia"]},
}


static func show_progression(ui: Ui) -> void:
	var box := ui._window("Rozwój księdza", 920.0)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 475)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	ui._text(content, Progression.profile_text(), 19)
	ui._text(content, "Szacunek do wydania: %d" % Game.respect, 20)
	_show_stats(ui, content)
	for tree_id_variant in ["administrator", "duszpasterz", "gospodarz"]:
		_show_tree(ui, content, str(tree_id_variant))
	ui._button(box, "Zamknij", ui._close_modal)


static func _show_stats(ui: Ui, content: VBoxContainer) -> void:
	ui._text(content, "Cechy", 22)
	var stats: Dictionary = Game.stats
	var xp: Dictionary = Game.stat_xp
	for stat_id_variant in ["charyzma", "wiarygodnosc", "zarzadzanie", "wplywy", "odpornosc"]:
		var stat_id := str(stat_id_variant)
		ui._text(content, "• %s: %d/10   %d/8 XP" % [
			str(Progression.STAT_LABELS.get(stat_id, stat_id)), int(stats.get(stat_id, 1)), int(xp.get(stat_id, 0))], 17)


static func _show_tree(ui: Ui, content: VBoxContainer, tree_id: String) -> void:
	var tree: Dictionary = TREES[tree_id]
	ui._text(content, str(tree["label"]), 22)
	for talent_id_variant in tree["talents"]:
		_show_talent(ui, content, str(talent_id_variant))


static func _show_talent(ui: Ui, content: VBoxContainer, talent_id: String) -> void:
	var talent: Dictionary = Progression.TALENTS[talent_id]
	var unlocked := Progression.has_talent(talent_id)
	var reason := Progression.unlock_reason(talent_id)
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.14)
	style.border_color = Color(0.32, 0.29, 0.25)
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
	ui._text(info, "%s — %d szacunku" % [str(talent["label"]), int(talent["cost"])], 19)
	ui._text(info, str(talent["description"]), 16)
	var requires := str(talent.get("requires", ""))
	if requires != "" and not unlocked:
		var required: Dictionary = Progression.TALENTS.get(requires, {})
		ui._text(info, "Wymaga: " + str(required.get("label", requires)) + ".", 16)
	if unlocked:
		ui._text(info, "Odblokowane.", 16)
	elif reason != "":
		ui._text(info, reason, 16)
	var label := "Odblokowane" if unlocked else "Odblokuj"
	var button := ui._button(row, label, func() -> void:
		if Progression.unlock(talent_id):
			_replace_progression_modal(ui)
		else:
			Game.toast.emit(Progression.unlock_reason(talent_id)), not unlocked and reason == "")
	button.custom_minimum_size = Vector2(160, 52)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER


static func _replace_progression_modal(ui: Ui) -> void:
	for child in ui._modal_layer.get_children():
		child.queue_free()
	show_progression(ui)
