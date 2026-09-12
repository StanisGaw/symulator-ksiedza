class_name Simulate
## Przebieg wielu dni bez gracza, z losowym wyborem opcji w wydarzeniach.
## Służy do sprawdzenia, czy pula wydarzeń nie milknie i czy awarie się pojawiają:
##
##   godot --headless --path . -- --simulate=120
##   godot --headless --path . -- --simulate=120 --rep=15   (parafia w kryzysie)
##
## To nie jest test poprawności, tylko podgląd rozkładu. Każdy przebieg jest inny.


static func run(days: int) -> void:
	var fired := {}
	# lambda dostaje kopię liczby, ale ten sam słownik, więc liczniki muszą siedzieć w słowniku
	var count := {"crisis": 0}
	var event_days := 0
	var longest_silence := 0
	var silence := 0
	var seen_breakdowns := {}
	var today_had_event := [false]

	var answer := func(kind: String, data: Dictionary) -> void:
		if kind != "event":
			return
		var ev: Dictionary = data["event"]
		var id: String = ev["id"]
		fired[id] = int(fired.get(id, 0)) + 1
		if ev.get("crisis", false):
			count["crisis"] = int(count["crisis"]) + 1
		today_had_event[0] = true
		EventFlow.choose_option(ev, randi() % (ev["options"] as Array).size())
	Game.modal_requested.connect(answer)

	var empty: Array[String] = []
	for i in days:
		today_had_event[0] = false
		# ksiądz zagląda w telefon co drugi dzień i nie na wszystko zdąży odpowiedzieć,
		# więc w statystyce widać obie drogi: odpowiedź i termin, który minął
		if i % 2 == 0:
			for mi in Game.phone_inbox.size():
				var msg: Dictionary = Game.phone_inbox[mi]
				if msg.has("options") and int(msg.get("answered", -1)) < 0 and not bool(msg.get("expired", false)):
					if randf() < 0.7:
						Inbox.answer(mi, randi() % (msg["options"] as Array).size())
		var before: Array = Game.breakdowns.duplicate()
		Game._start_new_day(100.0, empty)
		for id in Game.breakdowns:
			if not before.has(id):
				seen_breakdowns[id] = int(seen_breakdowns.get(id, 0)) + 1
		if today_had_event[0]:
			event_days += 1
			silence = 0
		else:
			silence += 1
			longest_silence = maxi(longest_silence, silence)

	Game.modal_requested.disconnect(answer)

	print("--- symulacja %d dni ---" % days)
	print("Dni z wydarzeniem: %d (%d%%). Najdłuższa cisza: %s." % [
		event_days, int(round(100.0 * event_days / float(days))), Game.days_text(longest_silence)])
	var event_total := 0
	for catalog in Events.catalogs():
		event_total += catalog[1].size()
	print("Różnych wydarzeń: %d z %d dostępnych. Kryzysów: %d." % [
		fired.size(), event_total, count["crisis"]])
	var ids: Array = fired.keys()
	ids.sort_custom(func(a, b): return int(fired[a]) > int(fired[b]))
	for id in ids:
		print("   %-22s %d" % [id, fired[id]])
	if seen_breakdowns.is_empty():
		print("Awarii nie było.")
	else:
		print("Awarie:")
		for id in seen_breakdowns:
			print("   %-22s %d" % [id, seen_breakdowns[id]])
	# telefon ma własny rytm: część wiadomości ma termin, a nieodpowiedziane biją po kurii
	var by_app := {}
	var answered := 0
	var expired := 0
	for msg in Game.phone_inbox:
		var app: String = str(msg.get("app", "?"))
		by_app[app] = int(by_app.get(app, 0)) + 1
		if int(msg.get("answered", -1)) >= 0:
			answered += 1
		if bool(msg.get("expired", false)):
			expired += 1
	var parts: Array[String] = []
	for app in by_app:
		parts.append("%s %d" % [app, by_app[app]])
	print("Telefon: %d wiadomości (%s), odpowiedzianych %d, po terminie %d." % [
		Game.phone_inbox.size(), ", ".join(parts), answered, expired])
	print("Na koniec: reputacja %d, budynki %d, kuria %d, konto %s zł, trwających awarii %d." % [
		Game.reputation, Game.condition, Game.curia, Game.money_text(Game.money), Game.breakdowns.size()])
