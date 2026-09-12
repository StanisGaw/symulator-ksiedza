class_name CareerView
## Ekran kariery: kuria pokazuje tu ocenę i termin, a nie ukryte mnożniki.


static func show_career(ui: Ui) -> void:
	var box := ui._window("Kariera i kuria", 920.0)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 475)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	_show_rank(ui, content)
	_show_faith(ui, content)
	_show_calendar(ui, content)
	_show_reviews(ui, content)
	_show_approvals(ui, content)
	_show_promotion(ui, content)
	_show_chronicle(ui, content)
	ui._button(box, "Zamknij", ui._close_modal)


static func _show_rank(ui: Ui, content: VBoxContainer) -> void:
	var rank := Career.rank_label()
	ui._text(content, "Stanowisko: %s" % rank, 23)
	if Game.rank == "wikary":
		var relation := int(Game.career.get("pastor_relation", 100))
		ui._text(content, "Jako wikary uzgadniasz zastrzeżone decyzje z proboszczem. Relacja z nim: %d/100." % relation, 17)
	else:
		ui._text(content, "Masz samodzielność właściwą dla tego stanowiska.", 17)


static func _show_faith(ui: Ui, content: VBoxContainer) -> void:
	ui._text(content, "Życie religijne: %d/100" % Game.faith, 22)
	var faith: Dictionary = Career.faith_components()
	ui._text(content, str(faith.get("formula", "Wynik obejmuje tylko ostatnie 7 zakończonych dni.")), 16)
	var current_days := int(faith.get("days", 0))
	ui._text(content, "Dni z odnotowaną aktywnością w ostatnim tygodniu: %d/7." % current_days, 16)
	for id_variant in ["attendance", "sacraments", "groups"]:
		var item: Dictionary = faith.get(id_variant, {})
		if item.is_empty():
			continue
		ui._text(content, "• %s: %d/%d (wynik %d/100)" % [
			str(item.get("label", id_variant)), int(item.get("total", 0)), int(item.get("target", 0)), int(item.get("score", 0))], 17)
	ui._text(content, "Pieniądze i popularność nie podnoszą tego wyniku same z siebie.", 16)


static func _show_calendar(ui: Ui, content: VBoxContainer) -> void:
	var review_day := Career.next_review_day()
	var days_left := maxi(0, review_day - Game.day)
	ui._text(content, "Kalendarz kurii", 22)
	ui._text(content, "Dobra ocena: od 70/100. Zła: poniżej 40. Dwie dobre z rzędu dają propozycję awansu; dwie złe — ostrzeżenie, trzecia — decyzję o przeniesieniu.", 16)
	if days_left == 0:
		ui._text(content, "Ocena kwartalna przypada dziś.", 17)
	elif days_left <= 7:
		ui._text(content, "Przypomnienie: ocena kwartalna za %s (dzień %d)." % [Game.days_text(days_left), review_day], 17)
	else:
		ui._text(content, "Najbliższa ocena za %s, w dniu %d. Oceny odbywają się co 91 dni." % [Game.days_text(days_left), review_day], 17)


static func _show_reviews(ui: Ui, content: VBoxContainer) -> void:
	ui._text(content, "Ostatnia ocena kurii", 22)
	var reviews: Array = Game.career.get("reviews", [])
	if reviews.is_empty():
		ui._text(content, "Jeszcze nie ma oceny. Pierwszy list obejmie finanse, życie religijne, stan budynków, reputację i rozwiązane kryzysy.", 17)
		return
	var latest: Dictionary = reviews.back()
	ui._text(content, "Dzień %d — wynik %d/100 (%s)." % [
		int(latest.get("day", 0)), int(latest.get("score", 0)), _review_result(str(latest.get("result", "")))], 17)
	var components: Dictionary = latest.get("components", Career.review_components())
	for id_variant in ["finances", "faith", "buildings", "reputation", "crises"]:
		var id := str(id_variant)
		ui._text(content, "• %s: %d/100" % [_component_label(id), int(components.get(id, 0))], 17)
	if reviews.size() > 1:
		var previous: Array[String] = []
		for review_variant in reviews.slice(maxi(0, reviews.size() - 3), reviews.size() - 1):
			var review: Dictionary = review_variant
			previous.append("dzień %d: %d" % [int(review.get("day", 0)), int(review.get("score", 0))])
		ui._text(content, "Wcześniejsze wyniki: " + ", ".join(previous) + ".", 16)
	if bool(Game.career.get("transfer_pending", false)):
		ui._text(content, "Decyzja o przeniesieniu jest odnotowana w kronice. Zmiana parafii będzie kolejnym etapem kariery.", 16)


static func _show_approvals(ui: Ui, content: VBoxContainer) -> void:
	var approvals: Array = Game.career.get("approvals", [])
	var pending: Array = []
	for approval_variant in approvals:
		var approval: Dictionary = approval_variant
		if str(approval.get("status", "")) == "pending":
			pending.append(approval)
	if pending.is_empty():
		return
	ui._text(content, "Do uzgodnienia z proboszczem", 22)
	for approval in pending:
		var due_day := int(approval.get("due_day", Game.day))
		var when := "gotowe dziś" if due_day <= Game.day else "odpowiedź w dniu %d" % due_day
		var option: Dictionary = approval.get("option", {})
		ui._text(content, "• %s — %s." % [str(option.get("label", approval.get("id", "decyzja"))), when], 17)


static func _show_promotion(ui: Ui, content: VBoxContainer) -> void:
	var offer := str(Game.career.get("promotion_offer", ""))
	if offer == "":
		return
	ui._text(content, "Propozycja kurii", 22)
	ui._text(content, "Po kolejnych dobrych ocenach kuria proponuje stanowisko: %s." % _rank_name(offer), 17)
	ui._button(content, "Przyjmij awans", func() -> void:
		if Career.accept_promotion():
			_replace_career_modal(ui)
		else:
			Game.toast.emit("Ta propozycja nie jest już dostępna."))


static func _show_chronicle(ui: Ui, content: VBoxContainer) -> void:
	ui._text(content, "Kronika decyzji", 22)
	if Game.chronicle.is_empty():
		ui._text(content, "Kluczowe decyzje i oceny pojawią się tutaj na stałe.", 17)
		return
	for entry_variant in Game.chronicle:
		var entry: Dictionary = entry_variant
		ui._text(content, "• Dzień %d: %s" % [int(entry.get("day", 0)), str(entry.get("text", ""))], 17)


static func _replace_career_modal(ui: Ui) -> void:
	for child in ui._modal_layer.get_children():
		child.queue_free()
	show_career(ui)


static func _rank_name(rank: String) -> String:
	match rank:
		"wikary": return "wikary"
		"proboszcz": return "proboszcz"
		"dziekan": return "dziekan"
	return rank.capitalize()


static func _review_result(result: String) -> String:
	match result:
		"good": return "dobra"
		"bad": return "zła"
		"warning": return "ostrzeżenie"
		"transfer": return "decyzja o przeniesieniu"
	return "ocena"


static func _component_label(id: String) -> String:
	match id:
		"finances": return "Finanse"
		"faith": return "Życie religijne"
		"buildings": return "Stan budynków"
		"reputation": return "Reputacja"
		"crises": return "Rozwiązane kryzysy"
	return id.capitalize()
