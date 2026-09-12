class_name ReleaseNotesView


static func show_notes(ui: Ui, releases: Array) -> void:
	var version := ReleaseNotes.current_version()
	var box := ui._window("Co nowego w parafii?", 900.0)
	ui._text(box, "Wersja gry: %s • Zmiany, których jeszcze nie potwierdzono" % version, 18)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	for release in releases:
		ui._text(content, "%s — %s" % [release["version"], release["title"]], 23)
		for change in release["changes"]:
			ui._text(content, "• " + str(change), 18)
		content.add_child(HSeparator.new())
	ui._button(box, "Rozumiem, graj", func() -> void:
		if OS.has_feature("web") and not ReleaseNotes.acknowledge(version):
			Game.toast.emit("Przeglądarka nie zapamiętała potwierdzenia. Lista zmian może pojawić się ponownie.")
		ui._close_modal())
