class_name CheckDefinitions
## Kontrola spójności definicji wydarzeń i awarii. Uruchamiana argumentem --check,
## więc chodzi po tych samych autoloadach co gra:
##
##   godot --headless --path . -- --check
##
## Wyłapuje to, czego silnik nie zgłosi: literówkę w kluczu skutku, warunek na polu,
## którego nie ma, awarię albo inwestycję o nieistniejącym identyfikatorze, losowy
## skutek bez wersji przeciwnej.

const EFFECT_KEYS := ["money", "reputation", "condition", "trad", "young", "curia", "energy", "respect"]
const REQUIRE_KEYS := ["min_day", "max_day", "season", "part", "built", "not_built", "breakdown", "no_breakdown", "min", "max"]
const SPECIALS := ["honest_report", "visitation_ready", "visitation_raw", "viral_quiet", "viral_answer"]
const SEASONS := [Calendar.ADVENT, Calendar.CHRISTMAS, Calendar.LENT, Calendar.EASTER, Calendar.ORDINARY]
const PARTS := ["zima", "wiosna", "lato", "jesień"]
const STATE_KEYS := ["money", "reputation", "condition", "trad", "young", "curia", "respect", "day"]


## Lista problemów. Pusta, gdy definicje są spójne.
static func run() -> Array[String]:
	var problems: Array[String] = []
	_check_save(problems)

	var ids: Array[String] = []
	var counts := {"SCRIPTED": Events.SCRIPTED.size(), "POOL": Events.POOL.size(), "CRISES": Events.CRISES.size()}
	for entry in [["SCRIPTED", Events.SCRIPTED], ["POOL", Events.POOL], ["CRISES", Events.CRISES]]:
		var list_name: String = entry[0]
		var list: Array = entry[1]
		for ev in list:
			var id: String = str(ev.get("id", ""))
			var where := "%s/%s" % [list_name, id]
			if id == "":
				_e(problems, where, "brak identyfikatora")
			if ids.has(id):
				_e(problems, where, "identyfikator powtórzony")
			ids.append(id)
			if str(ev.get("title", "")) == "" or str(ev.get("text", "")) == "":
				_e(problems, where, "brak tytułu albo treści")
			var options: Array = ev.get("options", [])
			if options.size() < 2:
				_e(problems, where, "mniej niż dwie opcje")
			if list_name == "SCRIPTED" and not ev.has("day"):
				_e(problems, where, "scenariusz bez dnia")
			if list_name != "SCRIPTED" and not ev.has("cooldown"):
				_e(problems, where, "brak karencji, wydarzenie wejdzie tylko raz")
			if list_name == "POOL" and not ev.has("weight"):
				_e(problems, where, "brak wagi")
			if list_name == "CRISES" and not ev.get("crisis", false):
				_e(problems, where, "kryzys bez znacznika crisis")
			for key in ev.get("require", {}):
				if not REQUIRE_KEYS.has(key):
					_e(problems, where, "nieznany warunek „%s”" % key)
			var req: Dictionary = ev.get("require", {})
			if req.has("season") and not SEASONS.has(str(req["season"])):
				_e(problems, where, "nieznany okres „%s”" % req["season"])
			if req.has("part") and not PARTS.has(str(req["part"])):
				_e(problems, where, "nieznana pora roku „%s”" % req["part"])
			for key in ["built", "not_built"]:
				if req.has(key) and not Game.INVESTMENTS.has(str(req[key])):
					_e(problems, where, "warunek %s wskazuje nieznaną inwestycję „%s”" % [key, req[key]])
			for key in ["breakdown", "no_breakdown"]:
				if req.has(key) and not Breakdowns.ALL.has(str(req[key])):
					_e(problems, where, "warunek %s wskazuje nieznaną awarię „%s”" % [key, req[key]])
			for bound in ["min", "max"]:
				for key in req.get(bound, {}):
					if not STATE_KEYS.has(key):
						_e(problems, where, "próg %s na nieznanym polu „%s”" % [bound, key])
			for i in options.size():
				var opt: Dictionary = options[i]
				var ow := "%s opcja %d" % [where, i + 1]
				if str(opt.get("label", "")) == "":
					_e(problems, ow, "brak etykiety")
				_ce(problems, ow, opt.get("effects", {}))
				if opt.has("special") and not SPECIALS.has(str(opt["special"])):
					_e(problems, ow, "nieznany special „%s”" % opt["special"])
				for key in ["breakdown", "fix"]:
					if opt.has(key) and not Breakdowns.ALL.has(str(opt[key])):
						_e(problems, ow, "nieznana awaria w „%s”" % key)
				if opt.has("delayed"):
					var d: Dictionary = opt["delayed"]
					if not d.has("days"):
						_e(problems, ow, "skutek odroczony bez liczby dni")
					_ce(problems, ow + " (odroczony)", d.get("effects", {}))
					_ce(problems, ow + " (odroczony, else)", d.get("else_effects", {}))
					if d.has("chance") and not d.has("else_text") and not d.has("else_breakdown"):
						_e(problems, ow, "losowy skutek bez wersji przeciwnej")
					if not d.has("chance") and (d.has("else_text") or d.has("else_effects")):
						_e(problems, ow, "wersja przeciwna bez „chance”")
					if d.has("special") and not SPECIALS.has(str(d["special"])):
						_e(problems, ow, "nieznany special w skutku odroczonym")
					for key in ["breakdown", "else_breakdown"]:
						if d.has(key) and not Breakdowns.ALL.has(str(d[key])):
							_e(problems, ow, "nieznana awaria w „%s”" % key)
				if opt.has("set"):
					for key in opt["set"]:
						if not ["sunday_hours", "weekday_hours"].has(key):
							_e(problems, ow, "„set” na nieobsługiwanym polu „%s”" % key)

	for id in Breakdowns.ALL:
		var def: Dictionary = Breakdowns.ALL[id]
		var where := "awaria/%s" % id
		for key in ["label", "daily", "daily_text", "cost", "days", "fixed_text"]:
			if not def.has(key):
				_e(problems, where, "brak pola „%s”" % key)
		_ce(problems, where + " (codziennie)", def.get("daily", {}))
		_ce(problems, where + " (po naprawie)", def.get("fixed_effects", {}))
		if def.has("blocks") and not Game.ACTIVITIES.has(str(def["blocks"])):
			_e(problems, where, "blokuje nieznaną czynność „%s”" % def["blocks"])
	return problems


## Wypisuje wynik i mówi, czy wszystko jest w porządku.
static func report() -> bool:
	var problems := run()
	print("Wydarzenia: scenariusz %d, pula %d, kryzysy %d. Awarie: %d." % [
		Events.SCRIPTED.size(), Events.POOL.size(), Events.CRISES.size(), Breakdowns.ALL.size()])
	for p in problems:
		printerr("BŁĄD  " + p)
	if problems.is_empty():
		print("Definicje spójne.")
	return problems.is_empty()


## JSON nie zna liczb całkowitych, więc każde nowe pole stanu może wrócić z zapisu
## jako zmiennoprzecinkowe i zepsuć porównania dni. Sprawdzamy to na kopii stanu,
## bez dotykania pliku zapisu gracza.
static func _check_save(problems: Array[String]) -> void:
	var before := {}
	for key in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS:
		before[key] = Game.get(key)
	# stan zasiany tak, żeby przeszły przez JSON wszystkie nowe pola naraz
	Game.breakdowns = ["car"]
	Game.breakdown_since = {"car": 7}
	Game.pending_repairs = []
	Game.event_cooldowns = {"organ_silent": 41}
	Game.scheduled = [{"day": 9, "text": "próba", "effects": {"money": -100},
		"chance": 0.5, "else_text": "druga wersja", "else_effects": {"reputation": -2}}]
	var data := {}
	for key in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS:
		data[key] = Game.get(key)
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	if typeof(parsed) != TYPE_DICTIONARY:
		_e(problems, "zapis", "stanu gry nie da się zapisać do JSON")
	else:
		SaveGame.apply(Game, parsed)
		if typeof(Game.breakdown_since.get("car")) != TYPE_INT:
			_e(problems, "zapis", "dzień początku awarii wraca jako zmiennoprzecinkowy")
		if typeof(Game.event_cooldowns.get("organ_silent")) != TYPE_INT:
			_e(problems, "zapis", "karencja wydarzenia wraca jako zmiennoprzecinkowa")
		var item: Dictionary = Game.scheduled[0]
		if typeof(item["day"]) != TYPE_INT:
			_e(problems, "zapis", "termin skutku odroczonego wraca jako zmiennoprzecinkowy")
		if typeof((item["effects"] as Dictionary)["money"]) != TYPE_INT:
			_e(problems, "zapis", "skutek odroczony wraca jako zmiennoprzecinkowy")
		if typeof((item["else_effects"] as Dictionary)["reputation"]) != TYPE_INT:
			_e(problems, "zapis", "przeciwna wersja skutku wraca jako zmiennoprzecinkowa")
		if not Game.breakdowns.has("car"):
			_e(problems, "zapis", "trwająca awaria nie przeżyła zapisu")
	for key in before:
		Game.set(key, before[key])


static func _e(problems: Array[String], where: String, what: String) -> void:
	problems.append("%s: %s" % [where, what])


static func _ce(problems: Array[String], where: String, effects: Dictionary) -> void:
	for key in effects:
		if not EFFECT_KEYS.has(key):
			_e(problems, where, "nieznany skutek „%s”" % key)
		elif typeof(effects[key]) != TYPE_INT:
			_e(problems, where, "skutek „%s” nie jest liczbą całkowitą" % key)
