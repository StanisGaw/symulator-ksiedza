extends Node
## Global parish state: clock, energy, money, relations, activities, investments,
## scheduled consequences and events. Autoloaded as "Game".

signal state_changed
signal prompt_changed(text: String)
signal toast(text: String)
signal modal_requested(kind: String, data: Dictionary)
signal location_change_requested(location: String, spawn: String)
signal cutscene_started(label: String)
signal cutscene_ended
signal cutscene_skip
signal world_changed

const MINUTES_PER_SECOND := 2.0
const FAST_MULT := 10.0
const DAY_START := 7 * 60
const WEEKLY_EXPENSES := 4200

const ACTIVITIES := {
	"repair_gutter": {"label": "Napraw rynnę", "minutes": 60, "energy": 20, "once": true,
		"effects": {"condition": 6}, "toast": "Rynna naprawiona. Stan budynków +6.", "builds": "gutter"},
	"sweep": {"label": "Zamieć plac", "minutes": 30, "energy": 10, "once": true,
		"effects": {"reputation": 1}, "toast": "Plac zamieciony. Reputacja +1.", "world": true,
		"cutscene": "Zamiatanie placu", "director_group": "activity_scene", "scene": {"kind": "sweep", "seconds": 4.5}},
	"visit_sick": {"label": "Odwiedziny chorego (samochód)", "minutes": 90, "energy": 20, "once": true,
		"visit": true, "effects": {}, "toast": "",
		"cutscene": "Odwiedziny", "cut_location": "visit", "return_location": "outside", "return_spawn": "car"},
	"mass": {"label": "Odpraw mszę", "minutes": 60, "energy": 25, "once": true, "mass": true,
		"cutscene": "Msza święta", "director_group": "mass_director"},
	"confession": {"label": "Spowiadaj", "minutes": 45, "energy": 10, "once": true,
		"effects": {"trad": 2, "reputation": 1}, "toast": "Trzy spowiedzi. Tradycjonaliści +2.",
		"cutscene": "Spowiedź", "director_group": "activity_scene", "scene": {"kind": "confession", "seconds": 6.0}},
	"read_breviary": {"label": "Usiądź z brewiarzem", "minutes": 60, "energy": -25, "rest": true,
		"toast": "Godzina na ławce z brewiarzem. Głowa lżejsza.",
		"cutscene": "Brewiarz", "director_group": "activity_scene", "scene": {"kind": "read", "seconds": 3.5}},
	"night": {"label": "Sen", "minutes": 0, "energy": 0, "night": true,
		"cutscene": "Noc", "director_group": "activity_scene", "scene": {"kind": "sleep", "seconds": 2.5}},
	"meal": {"label": "Zjedz obiad", "minutes": 45, "energy": -20, "rest": true, "money": -25,
		"toast": "Obiad zjedzony. Za zakupy poszło 25 zł."},
	"clean_church": {"label": "Posprzątaj kościół", "minutes": 45, "energy": 15, "once": true,
		"effects": {"condition": 3, "trad": 1}, "toast": "Kościół posprzątany. Stan budynków +3.", "world": true,
		"cutscene": "Sprzątanie kościoła", "director_group": "activity_scene", "scene": {"kind": "sweep", "walk": false, "seconds": 4.0, "zoom": 9.0}},
}

const INVESTMENTS := {
	"roof": {"label": "Remont dachu", "cost": 8000, "days": 3, "effects": {"condition": 30},
		"desc": "Ekipa potrzebuje 3 dni. Stan budynków +30."},
	"heating": {"label": "Ogrzewanie w kościele", "cost": 5000, "days": 2, "effects": {"trad": 8, "condition": 5},
		"desc": "Starsi parafianie przestaną marznąć. Tradycjonaliści +8."},
	"sound": {"label": "Nagłośnienie", "cost": 3000, "days": 1, "effects": {"young": 6},
		"desc": "Słychać kazanie w ostatniej ławce. Młode rodziny +6."},
	"festyn": {"label": "Festyn parafialny", "cost": 2500, "days": 4, "effects": {"young": 8, "reputation": 4, "trad": -3},
		"desc": "Dmuchaniec, grill, zespół. Młode rodziny +8, reputacja +4, tradycjonaliści -3."},
	"curia_gift": {"label": "Przelew do kurii", "cost": 1500, "days": 0, "effects": {"curia": 6},
		"desc": "Dobrowolna ofiara na cele diecezji. Kuria +6."},
}

var day := 1
var start_unix := 0
var visit_index := 0
var minutes := float(DAY_START)
var energy := 100.0
var money := 12000
var reputation := 50
var condition := 55
var trad := 55
var young := 50
var curia := 50
var week_income := 0
var week_expenses := 0
var mass_hour := 0
var location := "outside"
var done_today: Dictionary = {}
var rests_today := 0
var scheduled: Array = []
var pending_investments: Array = []
var fired_events: Array = []
var built: Array = []
var seen: Array = []
var log_lines: Array = []
var modal_open := false
var cutscene := false
var cutscene_id := ""
var _cut_start := 0.0
var _cut_len := 0.0
var mass_attendance := 0
var _mass_roraty := false
var _sleep_minutes := 480.0


func _ready() -> void:
	# debug: --wipe kasuje zapis, --condition/--rep ustawiają wskaźniki,
	# --built=roof,heating stawia inwestycje (z --unseen kamera je pokaże)
	var args := OS.get_cmdline_user_args()
	if args.has("--wipe"):
		SaveGame.wipe()
	if start_unix == 0:
		start_unix = Calendar.today_start_unix()
	for arg in args:
		if arg.begins_with("--start="):
			# --start=2025-12-24 zaczyna grę w wybranym dniu roku
			var parts := arg.trim_prefix("--start=").split("-", false)
			if parts.size() == 3:
				start_unix = int(Time.get_unix_time_from_datetime_dict({
					"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
					"hour": 0, "minute": 0, "second": 0}))
		elif arg.begins_with("--day="):
			day = maxi(int(arg.trim_prefix("--day=")), 1)
		elif arg.begins_with("--visitor="):
			visit_index = maxi(int(arg.trim_prefix("--visitor=")), 0)
		elif arg.begins_with("--energy="):
			energy = clampf(float(arg.trim_prefix("--energy=")), 0.0, 100.0)
		elif arg.begins_with("--condition="):
			condition = clampi(int(arg.trim_prefix("--condition=")), 0, 100)
		elif arg.begins_with("--hour="):
			minutes = clampf(float(arg.trim_prefix("--hour=")) * 60.0, 0.0, 24.0 * 60.0 - 1.0)
		elif arg.begins_with("--rep="):
			reputation = clampi(int(arg.trim_prefix("--rep=")), 0, 100)
			trad = reputation
			young = reputation
		elif arg.begins_with("--built="):
			for id in arg.trim_prefix("--built=").split(",", false):
				built.append(id)
				if not args.has("--unseen"):
					mark_seen(id)


func _process(delta: float) -> void:
	if modal_open or cutscene:
		return
	var mult := FAST_MULT if Input.is_action_pressed("time_faster") else 1.0
	minutes += delta * MINUTES_PER_SECOND * mult
	if minutes >= 24 * 60:
		_force_sleep()


# ---------- clock ----------

func time_of_day() -> float:
	return minutes / (24.0 * 60.0)


func clock_text() -> String:
	return clock_text_at(minutes)


## Godzina dowolnego momentu doby, także po przekroczeniu północy.
static func clock_text_at(value: float) -> String:
	var m := int(value) % (24 * 60)
	return "%02d:%02d" % [m / 60, m % 60]


func day_name() -> String:
	return Calendar.day_name(day)


## „Poniedziałek, 1 grudnia”
func date_text() -> String:
	return Calendar.date_text(day)


func season() -> String:
	return Calendar.season(day)


func feast_name() -> String:
	return Calendar.feast_name(day)


func is_sunday() -> bool:
	return Calendar.is_sunday(day)


# ---------- effects ----------

func apply_effects(effects: Dictionary) -> void:
	var before_condition := WorldState.condition()
	var before_life := WorldState.life()
	for key in effects:
		var v: int = int(effects[key])
		match key:
			"money":
				money += v
				if v >= 0:
					week_income += v
				else:
					week_expenses += -v
			"reputation": reputation = clampi(reputation + v, 0, 100)
			"condition": condition = clampi(condition + v, 0, 100)
			"trad": trad = clampi(trad + v, 0, 100)
			"young": young = clampi(young + v, 0, 100)
			"curia": curia = clampi(curia + v, 0, 100)
			"energy": energy = clampf(energy + v, 0.0, 100.0)
	state_changed.emit()
	# świat pokazuje stan parafii progami, więc przebudowa tylko przy zmianie progu
	if WorldState.condition() != before_condition or WorldState.life() != before_life:
		world_changed.emit()


## „12 000” zamiast „12000”, w jednym miejscu dla całej gry.
static func money_text(v: int) -> String:
	var digits := str(absi(v))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = " " + out
	return ("-" if v < 0 else "") + out


func effects_text(effects: Dictionary) -> String:
	var names := {"money": "zł", "reputation": "reputacja", "condition": "budynki", "trad": "tradycjonaliści",
		"young": "młode rodziny", "curia": "kuria", "energy": "energia"}
	var parts: Array[String] = []
	for key in effects:
		var v: int = int(effects[key])
		if key == "money":
			parts.append("%+d zł" % v)
		else:
			parts.append("%s %+d" % [names.get(key, key), v])
	return ", ".join(parts)


func add_log(text: String) -> void:
	log_lines.push_front("Dzień %d, %s: %s" % [day, clock_text(), text])
	if log_lines.size() > 30:
		log_lines.resize(30)


# ---------- activities ----------

func do_activity(id: String) -> void:
	if modal_open:
		return
	var def: Dictionary = ACTIVITIES[id]
	var is_rest: bool = def.get("rest", false)
	if is_rest:
		if not _can_rest(def):
			return
	else:
		if def.get("once", false) and done_today.has(id):
			toast.emit("To już dziś zrobione.")
			return
		if energy < def["energy"]:
			toast.emit("Za mało energii. Usiądź z brewiarzem albo idź spać.")
			return
	if minutes + def["minutes"] > 24 * 60:
		toast.emit("Za późno na to dzisiaj.")
		return
	minutes += def["minutes"]
	if not is_rest:
		energy = maxf(0.0, energy - def["energy"])
		done_today[id] = true
	if def.has("cutscene"):
		_begin_cutscene(id, def)
	else:
		_finish_activity(def)
	state_changed.emit()


## Odpoczynek w ciągu dnia. Każdy kolejny daje mniej, bo od leżenia człowiek nie wypoczywa
## w nieskończoność: pełna wartość, potem 60, 40 i 20 procent.
const REST_FALLOFF := [1.0, 0.6, 0.4, 0.2]


func rest_gain(def: Dictionary) -> int:
	var base := -int(def["energy"])
	var factor: float = REST_FALLOFF[mini(rests_today, REST_FALLOFF.size() - 1)]
	return maxi(1, int(round(base * factor)))


func _can_rest(def: Dictionary) -> bool:
	if energy >= 99.0:
		toast.emit("Nie jesteś zmęczony.")
		return false
	if def.has("money") and money + int(def["money"]) < 0:
		toast.emit("Nie ma za co.")
		return false
	return true


func _take_rest(def: Dictionary) -> void:
	var gain := rest_gain(def)
	energy = clampf(energy + gain, 0.0, 100.0)
	rests_today += 1
	if def.has("money"):
		apply_effects({"money": def["money"]})
	toast.emit("%s Energia +%d." % [def["toast"], gain])
	state_changed.emit()


## Kto jest następny w kolejce do odwiedzin.
func next_visit() -> Dictionary:
	return Visits.current(self)


## Skutki czynności: liczby, komunikat i ślad w świecie.
func _finish_activity(def: Dictionary) -> void:
	if def.get("rest", false):
		_take_rest(def)
		return
	if def.get("visit", false):
		var person := next_visit()
		apply_effects(person["effects"])
		toast.emit(person["toast"])
		add_log(person["toast"])
		Visits.advance(self)
		return
	apply_effects(def["effects"])
	toast.emit(def["toast"])
	add_log(def["toast"])
	if def.has("builds") and not built.has(def["builds"]):
		built.append(def["builds"])
		mark_seen(def["builds"])
	if def.has("builds") or def.get("world", false):
		world_changed.emit()


func _attendance(start_minutes: float) -> int:
	var attendance := int(clampf(40.0 + reputation * 1.2 + (trad + young) * 0.5 + (condition - 50) * 0.4, 15.0, 300.0))
	if is_sunday():
		attendance = int(attendance * 2.2)
	if mass_hour == 99:
		attendance = int(attendance * 1.25)
	# święta ściągają ludzi, którzy nie przychodzą w zwykłą niedzielę
	attendance = int(attendance * Calendar.attendance_multiplier(day, start_minutes))
	if Calendar.is_roraty(day, start_minutes):
		attendance = int(attendance * 1.4)
	# w kościele jest tyle miejsca, ile jest; reszta stoi na zewnątrz i tacy nie wrzuca
	return mini(attendance, 500)


func _begin_cutscene(id: String, def: Dictionary) -> void:
	cutscene_id = id
	_cut_len = float(def["minutes"])
	_cut_start = minutes - _cut_len
	cutscene = true
	if def.get("mass", false):
		_mass_roraty = Calendar.is_roraty(day, _cut_start)
		mass_attendance = _attendance(_cut_start)
	var label: String = def["cutscene"]
	if def.get("visit", false):
		label = next_visit()["scene"]
	cutscene_started.emit(label)
	if def.has("cut_location"):
		location_change_requested.emit(def["cut_location"], "start")
	elif def.has("director_group"):
		var director := get_tree().get_first_node_in_group(def["director_group"])
		if director:
			director.start(def)
		else:
			finish_cutscene()
	else:
		finish_cutscene()


func cutscene_progress(p: float) -> void:
	minutes = _cut_start + _cut_len * clampf(p, 0.0, 1.0)


func skip_cutscene() -> void:
	cutscene_skip.emit()


func finish_cutscene() -> void:
	if not cutscene:
		return
	minutes = _cut_start + _cut_len
	cutscene = false
	var id := cutscene_id
	cutscene_id = ""
	var def: Dictionary = ACTIVITIES[id]
	cutscene_ended.emit()
	if def.get("night", false):
		_wake_up()
		return
	if def.get("mass", false):
		_hold_mass(mass_attendance)
	else:
		_finish_activity(def)
	if def.has("return_location"):
		location_change_requested.emit(def["return_location"], def["return_spawn"])
	state_changed.emit()


func _hold_mass(attendance: int) -> void:
	var taca := int(attendance * randf_range(3.2, 5.0) * Calendar.taca_multiplier(day, _cut_start))
	apply_effects({"money": taca, "reputation": 1})
	if mass_hour == 7:
		apply_effects({"trad": 1})
	elif mass_hour == 11:
		apply_effects({"young": 1})
	var label := "Msza"
	if _mass_roraty:
		# ciemny poranek, świece i ci, którym naprawdę zależy
		label = "Roraty"
		apply_effects({"trad": 2})
	elif Calendar.feast_name(day) != "" and Calendar.attendance_multiplier(day, _cut_start) > 1.0:
		label = Calendar.feast_name(day)
	var text := "%s: %d osób, taca %d zł." % [label, attendance, taca]
	toast.emit(text)
	add_log(text)


# ---------- investments ----------

func can_invest(id: String) -> bool:
	var def: Dictionary = INVESTMENTS[id]
	return money >= def["cost"] and not pending_investments.has(id)


func invest(id: String) -> void:
	if not can_invest(id):
		toast.emit("Nie stać parafii albo prace już trwają.")
		return
	var def: Dictionary = INVESTMENTS[id]
	apply_effects({"money": -def["cost"]})
	if def["days"] == 0:
		apply_effects(def["effects"])
		toast.emit("%s: %s" % [def["label"], effects_text(def["effects"])])
		add_log("%s (%d zł)." % [def["label"], def["cost"]])
	else:
		pending_investments.append(id)
		scheduled.append({"day": day + def["days"], "text": "%s: prace zakończone. %s." % [def["label"], effects_text(def["effects"])],
			"effects": def["effects"], "invest": id})
		toast.emit("%s: zlecone, gotowe za %d dni." % [def["label"], def["days"]])
		add_log("Zlecono: %s (%d zł)." % [def["label"], def["cost"]])
	state_changed.emit()


# ---------- events ----------

func choose_option(event: Dictionary, index: int) -> void:
	var opt: Dictionary = event["options"][index]
	if opt.has("special"):
		_apply_special(opt["special"])
	if opt.has("effects"):
		apply_effects(opt["effects"])
	if opt.has("set"):
		for key in opt["set"]:
			set(key, opt["set"][key])
	if opt.has("delayed"):
		var d: Dictionary = opt["delayed"]
		scheduled.append({"day": day + int(d["days"]), "text": d["text"], "effects": d.get("effects", {})})
	fired_events.append(event["id"])
	add_log("%s: %s." % [event["title"], opt["label"]])
	state_changed.emit()


func _apply_special(kind: String) -> void:
	match kind:
		"honest_report":
			if money >= 0:
				apply_effects({"curia": 3})
				toast.emit("Kuria przyjęła sprawozdanie. Kuria +3.")
			else:
				apply_effects({"curia": -3})
				toast.emit("Kuria nie jest zachwycona minusem na koncie. Kuria -3.")


# ---------- day flow ----------

## Ile energii daje godzina snu. Osiem godzin wystarcza na pełną regenerację,
## krótka noc zostawia człowieka zmęczonym i nie trzeba do tego osobnej kary.
const ENERGY_PER_HOUR := 12.0
const MAX_SLEEP_HOURS := 12


func sleep_hours(hours: float) -> void:
	if modal_open or cutscene:
		return
	_sleep_minutes = clampf(hours, 0.5, float(MAX_SLEEP_HOURS)) * 60.0
	_begin_cutscene("night", ACTIVITIES["night"])


## „godzinę”, „trzy godziny”, „osiem godzin” — polska odmiana w jednym miejscu.
static func hours_text(hours: float) -> String:
	var h := int(round(hours))
	if h == 1:
		return "godzinę"
	var last := h % 10
	if last >= 2 and last <= 4 and (h < 12 or h > 14):
		return "%d godziny" % h
	return "%d godzin" % h


## Ile godzin dzieli nas od najbliższej szóstej rano. Zero, gdy to za długo, żeby to był sen.
func hours_until_six() -> float:
	var target := 6.0 * 60.0
	var delta := target - minutes
	if delta <= 0.0:
		delta += 24.0 * 60.0
	var hours := delta / 60.0
	return hours if hours <= float(MAX_SLEEP_HOURS) else 0.0


func _wake_up() -> void:
	var target := minutes + _sleep_minutes
	var gained := _sleep_minutes / 60.0 * ENERGY_PER_HOUR
	if target >= 24.0 * 60.0:
		_start_new_day(energy + gained, [], target - 24.0 * 60.0)
	else:
		minutes = target
		energy = clampf(energy + gained, 0.0, 100.0)
		toast.emit("Przespane %s. Energia %d%%." % [hours_text(_sleep_minutes / 60.0), int(energy)])
		state_changed.emit()


func _force_sleep() -> void:
	var lines: Array[String] = ["Zasnąłeś tam, gdzie stałeś. Energia rano tylko 60%."]
	_start_new_day(60.0, lines)


func _start_new_day(new_energy: float, extra_lines: Array[String], wake_minutes: float = float(DAY_START)) -> void:
	var missed_holy_day := Calendar.is_holy_day(day) and not done_today.has("mass")
	var missed_name := Calendar.feast_name(day)
	day += 1
	minutes = clampf(wake_minutes, 0.0, 23.0 * 60.0)
	energy = clampf(new_energy, 20.0, 100.0)
	done_today.clear()
	rests_today = 0
	var lines: Array[String] = extra_lines.duplicate()
	if missed_holy_day:
		# święto nakazane bez mszy zauważą wszyscy, łącznie z kurią
		apply_effects({"trad": -6, "reputation": -3, "curia": -3})
		lines.append("Wczoraj było święto nakazane (%s), a mszy nie było. Tradycjonaliści -6, reputacja -3, kuria -3." % missed_name)
	# rozliczenie tygodnia w poniedziałek rano, według prawdziwego kalendarza
	if Calendar.is_monday(day):
		lines.append_array(_weekly_settlement())
	# due consequences and finished works
	var remaining: Array = []
	for item in scheduled:
		if int(item["day"]) <= day:
			apply_effects(item.get("effects", {}))
			if item.has("invest"):
				pending_investments.erase(item["invest"])
				built.append(item["invest"])
				world_changed.emit()
			lines.append(item["text"])
			add_log(item["text"])
		else:
			remaining.append(item)
	scheduled = remaining
	state_changed.emit()
	save_now()
	var feast: String = Calendar.feast_name(day)
	if feast != "":
		lines.push_front("Dziś %s. %s" % [feast, str(Calendar.feast(day).get("note", ""))])
	if not lines.is_empty():
		request_modal("report", {"title": "%s   %s" % [date_text(), season()], "lines": lines})
	for ev in Events.due_events(self):
		request_modal("event", {"event": ev})


func _weekly_settlement() -> Array[String]:
	var lines: Array[String] = []
	var expenses := WEEKLY_EXPENSES
	money -= expenses
	lines.append("Rozliczenie tygodnia: taca i ofiary %s zł, wydatki %s zł, rachunki i pensje %s zł." % [
		money_text(week_income), money_text(week_expenses), money_text(expenses)])
	lines.append("Stan konta: %s zł." % money_text(money))
	condition = clampi(condition - 2, 0, 100)
	if money < 0:
		curia = clampi(curia - 3, 0, 100)
		lines.append("Konto na minusie. Kuria to widzi. Kuria -3.")
	if condition < 30:
		reputation = clampi(reputation - 2, 0, 100)
		lines.append("Budynki niszczeją, parafianie to komentują. Reputacja -2.")
	week_income = 0
	week_expenses = 0
	return lines


# ---------- save ----------

## Zmiany, które gracz już zobaczył na własne oczy. Nowa rzecz w lokacji dostaje najazd kamery.
func mark_seen(id: String) -> void:
	if not seen.has(id):
		seen.append(id)


func unseen(ids: Array) -> String:
	for id in ids:
		if built.has(id) and not seen.has(id):
			return id
	return ""


func save_now() -> void:
	SaveGame.write(self)


func saved_day() -> int:
	return int(SaveGame.read().get("day", 0))


## Wczytuje zapis i wraca do poranka zapisanego dnia na plebanii.
func continue_game() -> bool:
	var data := SaveGame.read()
	if data.is_empty():
		return false
	SaveGame.apply(self, data)
	minutes = float(DAY_START)
	cutscene = false
	cutscene_id = ""
	state_changed.emit()
	world_changed.emit()
	location_change_requested.emit("rectory", "bed")
	return true


func start_new_game() -> void:
	SaveGame.wipe()
	start_unix = Calendar.today_start_unix()
	day = 1
	minutes = float(DAY_START)
	energy = 100.0
	money = 12000
	reputation = 50
	condition = 55
	trad = 55
	young = 50
	curia = 50
	week_income = 0
	week_expenses = 0
	mass_hour = 0
	done_today.clear()
	rests_today = 0
	scheduled.clear()
	pending_investments.clear()
	fired_events.clear()
	built.clear()
	seen.clear()
	log_lines.clear()
	cutscene = false
	cutscene_id = ""
	state_changed.emit()
	world_changed.emit()
	location_change_requested.emit("outside", "start")


# ---------- ui ----------

func request_modal(kind: String, data: Dictionary) -> void:
	modal_requested.emit(kind, data)


func set_prompt(text: String) -> void:
	prompt_changed.emit(text)
