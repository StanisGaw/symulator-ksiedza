class_name Career
## Zasady życia religijnego, kwartalnych ocen, awansów i uzgodnień wikarego.
## Wszystkie metody operują na stanie Game, z wyjątkiem reset/normalize używanych
## także przez migrację zapisu.

const REVIEW_DAYS := 91
const REMINDER_DAYS := 7
const APPROVAL_DAYS := 2
const FAITH_DAYS := 7

const RANKS := ["wikary", "proboszcz", "dziekan"]
const RANK_LABELS := {
	"wikary": "Wikary",
	"proboszcz": "Proboszcz",
	"dziekan": "Dziekan",
}
const REVIEW_LABELS := {
	"finances": "Finanse",
	"faith": "Życie religijne",
	"buildings": "Stan budynków",
	"reputation": "Reputacja",
	"crises": "Rozwiązane kryzysy",
}

## Cele oznaczają wynik 100 pkt. Wiara jest ważoną średnią: frekwencja 50%,
## sakramenty 30%, aktywność duszpasterska 20%. Liczą się tylko wykonane czynności.
const FAITH_TARGETS := {"attendance": 1200, "sacraments": 15, "groups": 5}
const FAITH_WEIGHTS := {"attendance": 50, "sacraments": 30, "groups": 20}


static func reset(game: Node, legacy: bool = false) -> void:
	game.set("rank", "proboszcz" if legacy else "wikary")
	game.set("faith", 0)
	game.set("career", _default_career(int(game.get("day"))))
	game.set("faith_history", [])
	game.set("chronicle", [])


static func normalize(game: Node) -> void:
	var rank := str(game.get("rank"))
	if not RANKS.has(rank):
		rank = "wikary"
	game.set("rank", rank)
	game.set("faith", clampi(int(game.get("faith")), 0, 100))

	var raw_career: Variant = game.get("career")
	var source: Dictionary = raw_career if raw_career is Dictionary else {}
	var normalized := _default_career(int(game.get("day")))
	# Termin równy dzisiejszemu dniowi jest poprawny: morning ma właśnie wtedy
	# wystawić ocenę. Migracja starego zapisu dostaje osobno domyślne day + 91.
	normalized["next_review"] = maxi(1, int(source.get("next_review", normalized["next_review"])))
	normalized["good_streak"] = maxi(0, int(source.get("good_streak", 0)))
	normalized["bad_streak"] = maxi(0, int(source.get("bad_streak", 0)))
	var offer := str(source.get("promotion_offer", ""))
	normalized["promotion_offer"] = offer if RANKS.has(offer) else ""
	normalized["transfer_pending"] = bool(source.get("transfer_pending", false))
	normalized["pastor_relation"] = clampi(int(source.get("pastor_relation", 70)), 0, 100)
	normalized["last_morning"] = int(source.get("last_morning", -1))
	normalized["reminder_day"] = int(source.get("reminder_day", -1))
	normalized["reviews"] = _normalize_reviews(source.get("reviews", []))
	normalized["approvals"] = _normalize_approvals(source.get("approvals", []))
	normalized["resolved_crises"] = _unique_strings(source.get("resolved_crises", []))
	game.set("career", normalized)
	game.set("faith_history", _normalize_history(game.get("faith_history")))
	game.set("chronicle", _normalize_chronicle(game.get("chronicle")))


static func record(kind: String, amount: int = 1) -> void:
	if not FAITH_TARGETS.has(kind) or amount <= 0:
		return
	_ensure_game()
	var history: Array = Game.faith_history
	var today: Dictionary = {}
	for row in history:
		if int(row.get("day", -1)) == Game.day:
			today = row
			break
	if today.is_empty():
		today = {"day": Game.day, "attendance": 0, "sacraments": 0, "groups": 0}
		history.append(today)
	today[kind] = maxi(0, int(today.get(kind, 0)) + amount)


static func morning() -> Array[String]:
	_ensure_game()
	var lines: Array[String] = []
	if int(Game.career.get("last_morning", -1)) == Game.day:
		return lines
	Game.career["last_morning"] = Game.day
	_prune_history()
	Game.faith = int(faith_components()["score"])
	lines.append_array(_finish_approvals())

	var review_day := next_review_day()
	if Game.day == review_day - REMINDER_DAYS and int(Game.career.get("reminder_day", -1)) != Game.day:
		Game.career["reminder_day"] = Game.day
		var reminder_text := "Za 7 dni kwartalna ocena parafii. Kryteria i bieżące wyniki są rozpisane w Karierze."
		Inbox.send(Phone.make("poczta", "Kuria diecezjalna", "Zapowiedź oceny kwartalnej",
			reminder_text, {"id": "career_reminder_%d" % review_day}))
		lines.append("List z kurii: " + reminder_text)
	if Game.day >= review_day:
		lines.append(_make_review())
	return lines


static func rank_label() -> String:
	return str(RANK_LABELS.get(str(Game.rank), str(Game.rank).capitalize()))


static func next_review_day() -> int:
	return int(Game.career.get("next_review", Game.day + REVIEW_DAYS))


## Pięć jawnych ocen 0–100. Saldo -12 000 zł daje 0, +12 000 zł daje 100;
## brak kryzysu to neutralne 50, a każdy rozwiązany daje 25 pkt. Pozostałe
## składowe są bezpośrednimi wskaźnikami gry.
static func review_components() -> Dictionary:
	return {
		"finances": clampi(int(round((float(Game.money) + 12000.0) / 240.0)), 0, 100),
		"faith": clampi(int(Game.faith), 0, 100),
		"buildings": clampi(int(Game.condition), 0, 100),
		"reputation": clampi(int(Game.reputation), 0, 100),
		"crises": mini(100, 50 + Game.career.get("resolved_crises", []).size() * 25),
	}


## Rozbicie siedmiodniowej wiary dla UI. `score` jest wartością zapisywaną w Game.faith.
static func faith_components() -> Dictionary:
	var totals := {"attendance": 0, "sacraments": 0, "groups": 0}
	var first_day := Game.day - FAITH_DAYS
	var last_day := Game.day - 1
	var days := 0
	for row in Game.faith_history:
		var row_day := int(row.get("day", -1))
		if row_day < first_day or row_day > last_day:
			continue
		days += 1
		for kind in totals:
			totals[kind] += maxi(0, int(row.get(kind, 0)))
	var result := {"days": days, "formula": "50% frekwencja + 30% sakramenty + 20% aktywność duszpasterska"}
	var score := 0.0
	var labels := {"attendance": "Frekwencja", "sacraments": "Sakramenty", "groups": "Aktywność duszpasterska"}
	for kind in totals:
		var component_score := clampi(int(round(float(totals[kind]) * 100.0 / float(FAITH_TARGETS[kind]))), 0, 100)
		result[kind] = {"label": labels[kind], "total": totals[kind], "target": FAITH_TARGETS[kind],
			"score": component_score, "weight": FAITH_WEIGHTS[kind]}
		score += component_score * float(FAITH_WEIGHTS[kind]) / 100.0
	result["score"] = clampi(int(round(score)), 0, 100)
	return result


static func accept_promotion() -> bool:
	_ensure_game()
	var offer := str(Game.career.get("promotion_offer", ""))
	var current_index := RANKS.find(str(Game.rank))
	if offer == "" or current_index < 0 or current_index + 1 >= RANKS.size() or RANKS[current_index + 1] != offer:
		return false
	Game.rank = offer
	Game.career["promotion_offer"] = ""
	Game.career["good_streak"] = 0
	add_chronicle("Przyjęto nominację na stanowisko: %s." % rank_label())
	Game.state_changed.emit()
	return true


static func needs_approval(option: Dictionary) -> bool:
	if str(Game.rank) != "wikary":
		return false
	if bool(option.get("needs_approval", false)):
		return true
	var set_values: Variant = option.get("set", {})
	return set_values is Dictionary and (set_values.has("sunday_hours") or set_values.has("weekday_hours"))


static func request_approval(event: Dictionary, option: Dictionary) -> bool:
	_ensure_game()
	if not needs_approval(option):
		return false
	var event_id := str(event.get("id", event.get("title", "event")))
	var option_id := str(option.get("id", option.get("label", "option")))
	for existing in Game.career["approvals"]:
		if str(existing.get("event_id", "")) == event_id and str(existing.get("option_id", "")) == option_id \
				and str(existing.get("status", "")) == "pending":
			return false
	var approval := {
		"id": "%s:%s:%d" % [event_id, option_id, Game.day],
		"event_id": event_id,
		"option_id": option_id,
		"requested_day": Game.day,
		"due_day": Game.day + APPROVAL_DAYS,
		"event": event.duplicate(true),
		"option": option.duplicate(true),
		"status": "pending",
	}
	Game.career["approvals"].append(approval)
	Game.career["pastor_relation"] = clampi(int(Game.career["pastor_relation"]) - 2, 0, 100)
	add_chronicle("Poproszono proboszcza o zgodę: %s." % str(option.get("label", "decyzja")))
	return true


static func add_chronicle(text: String) -> void:
	var clean := text.strip_edges()
	if clean == "":
		return
	Game.chronicle.append({"day": Game.day, "text": clean})


static func record_crisis(id: String) -> void:
	_ensure_game()
	var clean := id.strip_edges()
	if clean == "" or Game.career["resolved_crises"].has(clean):
		return
	Game.career["resolved_crises"].append(clean)
	add_chronicle("Rozwiązano kryzys: %s." % clean)


static func _default_career(day: int) -> Dictionary:
	return {
		"next_review": maxi(day, 1) + REVIEW_DAYS,
		"good_streak": 0,
		"bad_streak": 0,
		"promotion_offer": "",
		"transfer_pending": false,
		"pastor_relation": 70,
		"reviews": [],
		"approvals": [],
		"resolved_crises": [],
		"last_morning": -1,
		"reminder_day": -1,
	}


static func _prune_history() -> void:
	var oldest := Game.day - FAITH_DAYS
	var kept: Array = []
	for row in Game.faith_history:
		if int(row.get("day", -1)) >= oldest and int(row.get("day", -1)) <= Game.day:
			kept.append(row)
	Game.faith_history = kept


static func _finish_approvals() -> Array[String]:
	var lines: Array[String] = []
	for approval in Game.career["approvals"]:
		if str(approval.get("status", "")) != "pending" or int(approval.get("due_day", Game.day + 1)) > Game.day:
			continue
		# Stan zmieniamy przed wykonaniem. Ponowne morning po zapisie lub sygnale nie
		# może drugi raz zastosować kosztów ani skutków odroczonych.
		approval["status"] = "approved"
		EventFlow.apply_option(approval.get("event", {}), approval.get("option", {}))
		var label := str(approval.get("option", {}).get("label", "decyzja"))
		lines.append("Proboszcz zatwierdził po dwóch dniach: %s." % label)
		add_chronicle("Proboszcz zatwierdził: %s." % label)
	return lines


static func _make_review() -> String:
	var components := review_components()
	var total := 0
	for key in REVIEW_LABELS:
		total += int(components[key])
	var score := int(round(float(total) / float(REVIEW_LABELS.size())))
	var result := "neutral"
	if score >= 70:
		result = "good"
		Game.career["good_streak"] = int(Game.career["good_streak"]) + 1
		Game.career["bad_streak"] = 0
	elif score < 40:
		result = "bad"
		Game.career["bad_streak"] = int(Game.career["bad_streak"]) + 1
		Game.career["good_streak"] = 0
	else:
		Game.career["good_streak"] = 0
		Game.career["bad_streak"] = 0
	var review := {"day": Game.day, "components": components.duplicate(true), "score": score, "result": result}
	Game.career["reviews"].append(review)
	Game.career["next_review"] = Game.day + REVIEW_DAYS
	Game.career["reminder_day"] = -1
	Game.career["resolved_crises"] = []

	var decision := ""
	if result == "good" and int(Game.career["good_streak"]) >= 2:
		var current_index := RANKS.find(str(Game.rank))
		if current_index >= 0 and current_index + 1 < RANKS.size() and str(Game.career["promotion_offer"]) == "":
			Game.career["promotion_offer"] = RANKS[current_index + 1]
			decision = " Kuria proponuje awans na stanowisko: %s." % RANK_LABELS[RANKS[current_index + 1]]
	elif result == "bad" and int(Game.career["bad_streak"]) == 2:
		decision = " Kuria udziela ostrzeżenia przed kolejną oceną."
		add_chronicle("Kuria udzieliła ostrzeżenia po drugiej złej ocenie.")
	elif result == "bad" and int(Game.career["bad_streak"]) >= 3 and not bool(Game.career["transfer_pending"]):
		Game.career["transfer_pending"] = true
		decision = " Kuria podjęła decyzję o przeniesieniu; zmiana parafii nastąpi w wydaniu 3.3."
		add_chronicle("Kuria podjęła decyzję o przeniesieniu do innej parafii.")
	var text := "Ocena kwartalna: finanse %d, wiara %d, budynki %d, reputacja %d, kryzysy %d. Wynik: %d/100.%s" % [
		components["finances"], components["faith"], components["buildings"], components["reputation"],
		components["crises"], score, decision]
	add_chronicle(text)
	Inbox.send(Phone.make("poczta", "Kuria diecezjalna", "Ocena kwartalna — %d/100" % score,
		text + " Pełne zestawienie i ewentualną propozycję znajdziesz w Karierze.",
		{"id": "career_review_%d" % Game.day}))
	return text


static func _ensure_game() -> void:
	var value: Variant = Game.career
	if not value is Dictionary or not value.has("approvals") or not value.has("reviews") \
			or not value.has("resolved_crises") or not value.has("next_review"):
		normalize(Game)


static func _normalize_history(value: Variant) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for raw in value:
		if not raw is Dictionary:
			continue
		result.append({"day": maxi(1, int(raw.get("day", 1))),
			"attendance": maxi(0, int(raw.get("attendance", 0))),
			"sacraments": maxi(0, int(raw.get("sacraments", 0))),
			"groups": maxi(0, int(raw.get("groups", 0)))})
	return result


static func _normalize_reviews(value: Variant) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for raw in value:
		if not raw is Dictionary:
			continue
		var components: Dictionary = raw.get("components", {}) if raw.get("components", {}) is Dictionary else {}
		var normalized_components := {}
		for key in REVIEW_LABELS:
			normalized_components[key] = clampi(int(components.get(key, 0)), 0, 100)
		result.append({"day": maxi(1, int(raw.get("day", 1))), "components": normalized_components,
			"score": clampi(int(raw.get("score", 0)), 0, 100), "result": str(raw.get("result", "neutral"))})
	return result


static func _normalize_approvals(value: Variant) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for raw in value:
		if not raw is Dictionary or not raw.get("event", {}) is Dictionary or not raw.get("option", {}) is Dictionary:
			continue
		result.append({"id": str(raw.get("id", "")), "event_id": str(raw.get("event_id", "")),
			"option_id": str(raw.get("option_id", "")), "requested_day": maxi(1, int(raw.get("requested_day", 1))),
			"due_day": maxi(1, int(raw.get("due_day", 1))), "event": raw["event"].duplicate(true),
			"option": raw["option"].duplicate(true), "status": str(raw.get("status", "pending"))})
	return result


static func _normalize_chronicle(value: Variant) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for raw in value:
		if raw is Dictionary and str(raw.get("text", "")).strip_edges() != "":
			result.append({"day": maxi(1, int(raw.get("day", 1))), "text": str(raw["text"])})
		elif raw is String and str(raw).strip_edges() != "":
			result.append({"day": 1, "text": str(raw)})
	return result


static func _unique_strings(value: Variant) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for raw in value:
		var clean := str(raw).strip_edges()
		if clean != "" and not result.has(clean):
			result.append(clean)
	return result
