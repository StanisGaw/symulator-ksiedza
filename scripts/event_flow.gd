class_name EventFlow
## Co się dzieje po wyborze opcji w wydarzeniu: skutki od ręki, skutki odroczone,
## karencje i skutki, których nie da się zapisać liczbami.
##
## Definicje wydarzeń siedzą w events.gd, tutaj jest ich wykonanie. Łańcuchy wydarzeń
## z pamięcią (wydanie 2.4) i warunki na statystyki księdza (2.5) dopisują się tutaj.

const DELAYED_KEYS := ["chance", "else_text", "else_effects", "breakdown", "else_breakdown", "special", "mail"]


static func choose_option(event: Dictionary, index: int) -> void:
	var opt: Dictionary = event["options"][index]
	if opt.has("special"):
		var msg := EventFlow._apply_special(str(opt["special"]))
		if msg != "":
			Game.toast.emit(msg)
			Game.add_log(msg)
	if opt.has("effects"):
		Parish.apply_effects(opt["effects"], str(event.get("title", "Wydarzenie")), "wydarzenia")
	if opt.has("set"):
		for key in opt["set"]:
			Game.set(key, opt["set"][key])
	if opt.has("breakdown"):
		Repairs.add(str(opt["breakdown"]))
	if opt.has("fix"):
		Repairs.clear(str(opt["fix"]))
	if opt.has("delayed"):
		var d: Dictionary = opt["delayed"]
		var item := {"day": Game.day + int(d["days"]), "text": str(d.get("text", "")), "effects": d.get("effects", {})}
		for key in DELAYED_KEYS:
			if d.has(key):
				item[key] = d[key]
		Game.scheduled.append(item)
	# scenariusz pierwszego tygodnia znika na zawsze, pula i kryzysy wracają po karencji
	if event.has("cooldown"):
		Game.event_cooldowns[event["id"]] = Game.day + int(event["cooldown"])
	else:
		Game.fired_events.append(event["id"])
	Game.add_log("%s: %s." % [event["title"], opt["label"]])
	Game.state_changed.emit()


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
			# biskup nie czyta wskaźników, tylko widzi kościół i to, co mówią ludzie
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
			# tu liczy się to, ile ksiądz zdążył sobie wyrobić szacunku
			if Game.respect >= 30:
				Parish.apply_effects({"young": 8, "reputation": 5, "respect": 2})
				return "Odpowiedź obejrzało więcej ludzi niż samo nagranie i wypadła dobrze. Młode rodziny +8, reputacja +5."
			Parish.apply_effects({"young": -3, "reputation": -4, "curia": -2})
			return "Odpowiedź wypadła nerwowo i to ona stała się materiałem. Młode rodziny -3, reputacja -4, kuria -2."
	return ""
