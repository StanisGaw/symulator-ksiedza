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

const MINUTES_PER_SECOND := 2.0
const FAST_MULT := 10.0
const DAY_START := 7 * 60
const WEEKLY_EXPENSES := 4200
const DAY_NAMES := ["Poniedziałek", "Wtorek", "Środa", "Czwartek", "Piątek", "Sobota", "Niedziela"]

const ACTIVITIES := {
	"repair_gutter": {"label": "Napraw rynnę", "minutes": 60, "energy": 20, "once": true,
		"effects": {"condition": 6}, "toast": "Rynna naprawiona. Stan budynków +6."},
	"sweep": {"label": "Zamieć plac", "minutes": 30, "energy": 10, "once": true,
		"effects": {"reputation": 1}, "toast": "Plac zamieciony. Reputacja +1."},
	"visit_sick": {"label": "Odwiedź chorego (samochód)", "minutes": 90, "energy": 20, "once": true,
		"effects": {"reputation": 2, "young": 1}, "toast": "Odwiedziny u chorej pani Haliny. Reputacja +2."},
	"mass": {"label": "Odpraw mszę", "minutes": 60, "energy": 25, "once": true, "mass": true},
	"confession": {"label": "Spowiadaj", "minutes": 45, "energy": 10, "once": true,
		"effects": {"trad": 2, "reputation": 1}, "toast": "Trzy spowiedzi. Tradycjonaliści +2."},
	"clean_church": {"label": "Posprzątaj kościół", "minutes": 45, "energy": 15, "once": true,
		"effects": {"condition": 3, "trad": 1}, "toast": "Kościół posprzątany. Stan budynków +3."},
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
var scheduled: Array = []
var pending_investments: Array = []
var fired_events: Array = []
var log_lines: Array = []
var modal_open := false
var cutscene := false
var _mass_start := 0.0
var _mass_attendance := 0


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
	var m := int(minutes)
	return "%02d:%02d" % [m / 60, m % 60]


func day_name() -> String:
	return DAY_NAMES[(day - 1) % 7]


func is_sunday() -> bool:
	return day % 7 == 0


# ---------- effects ----------

func apply_effects(effects: Dictionary) -> void:
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
	if def.get("once", false) and done_today.has(id):
		toast.emit("To już dziś zrobione.")
		return
	if energy < def["energy"]:
		toast.emit("Za mało energii. Idź spać na plebanii.")
		return
	if minutes + def["minutes"] > 24 * 60:
		toast.emit("Za późno na to dzisiaj.")
		return
	minutes += def["minutes"]
	energy = maxf(0.0, energy - def["energy"])
	done_today[id] = true
	if def.get("mass", false):
		_begin_mass()
	else:
		apply_effects(def["effects"])
		toast.emit(def["toast"])
		add_log(def["toast"])
	state_changed.emit()


func _attendance() -> int:
	var attendance := int(clampf(40.0 + reputation * 1.2 + (trad + young) * 0.5 + (condition - 50) * 0.4, 15.0, 300.0))
	if is_sunday():
		attendance = int(attendance * 2.2)
	if mass_hour == 99:
		attendance = int(attendance * 1.25)
	return attendance


func _begin_mass() -> void:
	_mass_attendance = _attendance()
	_mass_start = minutes - ACTIVITIES["mass"]["minutes"]
	cutscene = true
	cutscene_started.emit("Msza święta")
	var director := get_tree().get_first_node_in_group("mass_director")
	if director:
		director.start(_mass_attendance)
	else:
		finish_mass()


func mass_progress(p: float) -> void:
	minutes = _mass_start + ACTIVITIES["mass"]["minutes"] * clampf(p, 0.0, 1.0)


func skip_cutscene() -> void:
	cutscene_skip.emit()


func finish_mass() -> void:
	minutes = _mass_start + ACTIVITIES["mass"]["minutes"]
	cutscene = false
	cutscene_ended.emit()
	_hold_mass(_mass_attendance)


func _hold_mass(attendance: int) -> void:
	var taca := int(attendance * randf_range(3.2, 5.0))
	apply_effects({"money": taca, "reputation": 1})
	if mass_hour == 7:
		apply_effects({"trad": 1})
	elif mass_hour == 11:
		apply_effects({"young": 1})
	var text := "Msza: %d osób, taca %d zł." % [attendance, taca]
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

func sleep() -> void:
	if modal_open:
		return
	var hour := minutes / 60.0
	var penalty := maxf(0.0, (hour - 22.0) * 8.0)
	_start_new_day(100.0 - penalty, [])


func _force_sleep() -> void:
	var lines: Array[String] = ["Zasnąłeś tam, gdzie stałeś. Energia rano tylko 60%."]
	_start_new_day(60.0, lines)


func _start_new_day(new_energy: float, extra_lines: Array[String]) -> void:
	day += 1
	minutes = float(DAY_START)
	energy = clampf(new_energy, 20.0, 100.0)
	done_today.clear()
	var lines: Array[String] = extra_lines.duplicate()
	# weekly settlement on Monday morning
	if (day - 1) % 7 == 0:
		lines.append_array(_weekly_settlement())
	# due consequences and finished works
	var remaining: Array = []
	for item in scheduled:
		if int(item["day"]) <= day:
			apply_effects(item.get("effects", {}))
			if item.has("invest"):
				pending_investments.erase(item["invest"])
			lines.append(item["text"])
			add_log(item["text"])
		else:
			remaining.append(item)
	scheduled = remaining
	state_changed.emit()
	if not lines.is_empty():
		request_modal("report", {"title": "Dzień %d, %s" % [day, day_name()], "lines": lines})
	for ev in Events.due_events(self):
		request_modal("event", {"event": ev})


func _weekly_settlement() -> Array[String]:
	var lines: Array[String] = []
	var expenses := WEEKLY_EXPENSES
	money -= expenses
	lines.append("Rozliczenie tygodnia: taca i ofiary %d zł, wydatki %d zł, rachunki i pensje %d zł." % [week_income, week_expenses, expenses])
	lines.append("Stan konta: %d zł." % money)
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


# ---------- ui ----------

func request_modal(kind: String, data: Dictionary) -> void:
	modal_requested.emit(kind, data)


func set_prompt(text: String) -> void:
	prompt_changed.emit(text)
