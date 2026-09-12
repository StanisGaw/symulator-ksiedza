class_name EventFlow
## Wybór najpierw zamyka wydarzenie. Skutki wykonują się od razu albo, gdy wikary
## potrzebuje zgody proboszcza, przez Career.morning po dwóch dniach.

const DELAYED_KEYS := ["chance", "else_text", "else_effects", "breakdown", "else_breakdown",
	"special", "mail", "event", "else_event", "flags", "else_flags"]
const MASS_HOURS_REACTION := "neighbour_mass_hours"


static func choose_option(event: Dictionary, index: int) -> void:
	var options: Array = event.get("options", [])
	if index < 0 or index >= options.size():
		return
	if not _mark_decision(event):
		return
	var opt: Dictionary = options[index]
	if Career.needs_approval(opt):
		Career.request_approval(event, opt)
		Game.state_changed.emit()
		return
	apply_option(event, opt)


## Wykonuje cały zatwierdzony wybór. Career wywołuje tę funkcję dla zgody, która
## dojrzała; nie pyta ona ponownie o zgodę i nie oznacza wydarzenia drugi raz.
static func apply_option(event: Dictionary, opt: Dictionary) -> void:
	if opt.has("special"):
		var msg := EventFlow._apply_special(str(opt["special"]))
		if msg != "":
			Game.toast.emit(msg)
			Game.add_log(msg)
	if opt.has("effects"):
		Parish.apply_effects(opt["effects"], str(event.get("title", "Wydarzenie")), "wydarzenia")
	if opt.has("flags"):
		_apply_flags(opt["flags"])
	var mass_hours_changed := false
	if opt.has("set"):
		for key in opt["set"]:
			Game.set(key, _copy_value(opt["set"][key]))
			if key == "sunday_hours" or key == "weekday_hours":
				mass_hours_changed = true
	if mass_hours_changed:
		_queue_event(MASS_HOURS_REACTION)
	if opt.has("breakdown"):
		Repairs.add(str(opt["breakdown"]))
	if opt.has("fix"):
		Repairs.clear(str(opt["fix"]))
	if opt.has("delayed"):
		_schedule(opt["delayed"], event)
	var title := str(event.get("title", "Wydarzenie"))
	var label := str(opt.get("label", "decyzja"))
	Game.add_log("%s: %s." % [title, label])
	Career.add_chronicle("%s — %s" % [title, label])
	if bool(event.get("crisis", false)) and _crisis_threshold_cleared(event):
		Career.record_crisis(str(event.get("id", "")))
	Game.state_changed.emit()


## Gałąź odroczonego skutku jest rozstrzygana raz w poranku. Tutaj zapisujemy tylko
## pamięć wyniku oraz ID wydarzenia; sam modal i trwałość kolejki należą do Game.
static func apply_delayed_branch(item: Dictionary, hit: bool) -> void:
	var flags_key := "flags" if hit else "else_flags"
	if item.has(flags_key):
		_apply_flags(item[flags_key])
	var event_key := "event" if hit else "else_event"
	var event_id := str(item.get(event_key, ""))
	if event_id != "":
		_queue_event(event_id)


## Game wywołuje to po liczbowych i specjalnych skutkach danego wpisu. Dzięki temu
## kryzys liczy się dopiero wtedy, gdy odroczona gałąź naprawdę przekroczyła próg.
static func record_delayed_crisis(item: Dictionary) -> void:
	var crisis_id := str(item.get("crisis_id", ""))
	if crisis_id == "":
		return
	var event: Dictionary = Events.by_id(crisis_id)
	if not event.is_empty() and bool(event.get("crisis", false)) and _crisis_threshold_cleared(event):
		Career.record_crisis(crisis_id)


static func _mark_decision(event: Dictionary) -> bool:
	var id := str(event.get("id", ""))
	if id == "":
		return true
	Game.pending_events.erase(id)
	if event.has("cooldown"):
		if int(Game.event_cooldowns.get(id, 0)) > Game.day:
			return false
		Game.event_cooldowns[id] = Game.day + int(event["cooldown"])
		return true
	if Game.fired_events.has(id):
		return false
	Game.fired_events.append(id)
	return true


static func _schedule(delayed: Dictionary, event: Dictionary = {}) -> void:
	var item := {"day": Game.day + int(delayed["days"]), "text": str(delayed.get("text", "")),
		"effects": _copy_value(delayed.get("effects", {}))}
	if bool(event.get("crisis", false)):
		item["crisis_id"] = str(event.get("id", ""))
	for key in DELAYED_KEYS:
		if delayed.has(key):
			item[key] = _copy_value(delayed[key])
	Game.scheduled.append(item)


static func _queue_event(id: String) -> void:
	if id == "" or _event_already_handled(id):
		return
	Game.pending_events.append(id)


static func _event_already_handled(id: String) -> bool:
	return Game.pending_events.has(id) or Game.fired_events.has(id) \
		or int(Game.event_cooldowns.get(id, 0)) > Game.day


static func _apply_flags(values: Dictionary) -> void:
	for key in values:
		Game.flags[str(key)] = _copy_value(values[key])


static func _copy_value(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


static func _crisis_threshold_cleared(event: Dictionary) -> bool:
	var require: Dictionary = event.get("require", {})
	for key in require.get("min", {}):
		if float(Game.get(key)) < float(require["min"][key]):
			return true
	for key in require.get("max", {}):
		if float(Game.get(key)) > float(require["max"][key]):
			return true
	return false


## Skutki, których nie da się zapisać liczbami, bo zależą od stanu parafii.
## Zwraca komunikat do pokazania graczowi albo pusty napis.
static func _apply_special(kind: String) -> String:
	match kind:
		"honest_report":
			if Game.money >= 0:
				Parish.apply_effects({"curia": 3})
				return "Kuria przyjęła sprawozdanie. Kuria +3."
			Parish.apply_effects({"curia": -3})
			return "Kuria nie jest zachwycona minusem na koncie. Kuria -3."
		"visitation_ready", "visitation_raw":
			var score := Game.condition + Game.reputation + (12 if kind == "visitation_ready" else 0)
			if score >= 130:
				Parish.apply_effects({"curia": 8, "respect": 3})
				return "Biskup obszedł kościół, przejrzał księgi i powiedział, że dawno nie widział tak prowadzonej parafii. Kuria +8, szacunek +3."
			if score >= 90:
				Parish.apply_effects({"curia": 2})
				return "Biskup nie miał uwag, ale też nie miał czasu na kawę. Kuria +2."
			Parish.apply_effects({"curia": -7, "reputation": -2})
			return "Biskup zapytał, od kiedy tak wygląda prezbiterium, i nie doczekał się odpowiedzi. Kuria -7, reputacja -2."
		"viral_quiet":
			if Game.reputation >= 55:
				Parish.apply_effects({"young": 5, "reputation": 3})
				return "Nagranie obroniło się samo. Ludzie z powiatu piszą, że chcieliby takiego księdza. Młode rodziny +5, reputacja +3."
			Parish.apply_effects({"reputation": -5, "curia": -3})
			return "Fragment żyje własnym życiem i nikt nie pyta o kontekst. Reputacja -5, kuria -3."
		"viral_answer":
			if Game.respect >= 30:
				Parish.apply_effects({"young": 8, "reputation": 5, "respect": 2})
				return "Odpowiedź obejrzało więcej ludzi niż samo nagranie i wypadła dobrze. Młode rodziny +8, reputacja +5."
			Parish.apply_effects({"young": -3, "reputation": -4, "curia": -2})
			return "Odpowiedź wypadła nerwowo i to ona stała się materiałem. Młode rodziny -3, reputacja -4, kuria -2."
	return ""
