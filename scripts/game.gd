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
const DAY_START := 6 * 60
const WEEKLY_EXPENSES := 4200
## Msze są o stałych porach. Żeby zacząć, trzeba być w kościele najwyżej kwadrans przed
## i najwyżej dziesięć minut po. Opuszczona msza kosztuje szacunek i tradycjonalistów.
const MASS_HOURS_SUNDAY := [7, 12, 19]
const MASS_HOURS_WEEKDAY := [7, 19]
const MASS_WINDOW_BEFORE := 15
const MASS_WINDOW_AFTER := 10

const RESPECT_PER_MASS := 2
const RESPECT_PER_MISSED := 3
## Za każde miejsce, w którym parafianie zobaczą bałagan, schodzi punkt reputacji
## i punkt szacunku. Liczy się to przy każdej mszy, bo wtedy ludzie to widzą.
const MESS_PENALTY := 1

const ACTIVITIES := {
	"repair_gutter": {"label": "Napraw rynnę", "minutes": 60, "energy": 20, "once": true,
		"effects": {"condition": 6}, "toast": "Rynna naprawiona. Stan budynków +6.", "builds": "gutter"},
	"sweep": {"label": "Zamieć plac", "minutes": 30, "energy": 10, "once": true,
		"effects": {"reputation": 1}, "toast": "Plac zamieciony. Reputacja +1.", "world": true,
		"cutscene": "Zamiatanie placu", "director_group": "activity_scene", "scene": {"kind": "sweep", "seconds": 4.5}},
	"visit_sick": {"label": "Odwiedziny chorego (samochód)", "minutes": 90, "energy": 20, "once": true,
		"visit": true, "effects": {}, "toast": "",
		"cutscene": "Odwiedziny", "cut_location": "visit", "return_location": "outside", "return_spawn": "car"},
	"mass": {"label": "Odpraw mszę", "minutes": 60, "energy": 25, "mass": true,
		"cutscene": "Msza święta", "director_group": "mass_director"},
	"confession": {"label": "Spowiadaj", "minutes": 45, "energy": 10, "once": true,
		"effects": {"trad": 2, "reputation": 1}, "toast": "Trzy spowiedzi. Tradycjonaliści +2.",
		"cutscene": "Spowiedź", "director_group": "activity_scene", "scene": {"kind": "confession", "seconds": 6.0}},
	"read_breviary": {"label": "Usiądź z brewiarzem", "minutes": 0, "energy": 0, "read": true,
		"cutscene": "Brewiarz", "director_group": "activity_scene", "scene": {"kind": "read", "seconds": 3.5}},
	"night": {"label": "Sen", "minutes": 0, "energy": 0, "night": true,
		"cutscene": "Noc", "director_group": "activity_scene", "scene": {"kind": "sleep", "seconds": 2.5}},
	"pick_apple": {"label": "Zerwij jabłko", "minutes": 5, "energy": -6, "apple": true,
		"toast": "Jabłko prosto z drzewa."},
	"funeral": {"label": "Odpraw pogrzeb", "minutes": 90, "energy": 25, "funeral": true,
		"cutscene": "Pogrzeb", "director_group": "activity_scene", "scene": {"kind": "funeral", "seconds": 6.5, "zoom": 10.0}},
	"meal": {"label": "Zjedz obiad", "minutes": 45, "energy": -20, "meal": true, "money": -25,
		"toast": "Obiad zjedzony. Za zakupy poszło 25 zł."},
	"clean_church": {"label": "Posprzątaj kościół", "minutes": 45, "energy": 15, "once": true,
		"effects": {"condition": 3, "trad": 1}, "toast": "Kościół posprzątany. Stan budynków +3.", "world": true,
		"cutscene": "Sprzątanie kościoła", "director_group": "activity_scene", "scene": {"kind": "sweep", "seconds": 4.0, "zoom": 9.0}},
}

## Inwestycje. "builds" mówi, co stanie w świecie, "unlocks" co stanie się możliwe,
## "weekly" ile zł tygodniowo to daje po ukończeniu, "repeatable" czy można zlecać wielokrotnie.
const INVESTMENTS := {
	"roof": {"label": "Remont dachu", "cost": 8000, "days": 3, "effects": {"condition": 30},
		"builds": "Nowa połać dachu nad nawą, bez łat i plandeki. Znika zaciek i wiadro w kościele.",
		"unlocks": "Stan budynków +30 i koniec strat na przeciekach.", "weekly": 0},
	"heating": {"label": "Ogrzewanie w kościele", "cost": 5000, "days": 2, "effects": {"trad": 8, "condition": 5},
		"builds": "Grzejniki wzdłuż zachodniej ściany, komin z dymem za kościołem, cieplejsze światło.",
		"unlocks": "Tradycjonaliści +8 i pełna frekwencja zimą.", "weekly": 0},
	"sound": {"label": "Nagłośnienie", "cost": 3000, "days": 1, "effects": {"young": 6},
		"builds": "Kolumny na wieży i przy prezbiterium, mikrofon przy ołtarzu.",
		"unlocks": "Słychać kazanie w ostatniej ławce. Młode rodziny +6.", "weekly": 0},
	"cemetery": {"label": "Cmentarz parafialny", "cost": 12000, "days": 5, "effects": {"reputation": 3, "trad": 4},
		"builds": "Cmentarz za kościołem: mur, brama, żwirowa alejka, kwatery z nagrobkami, kaplica cmentarna.",
		"unlocks": "Pogrzeby w parafii zamiast u sąsiada: ofiara 800–1 200 zł i szacunek za każdy. Do tego opłaty za miejsca.",
		"weekly": 150, "expected_weekly": 1700,
		"yield_note": "150 zł opłat tygodniowo plus około 1 000 zł za pogrzeb, średnio półtora pogrzebu w tygodniu"},
	"festyn": {"label": "Festyn parafialny", "cost": 2500, "days": 4, "effects": {"young": 8, "reputation": 4, "trad": -3}, "repeatable": true,
		"builds": "Na razie nic trwałego. Namioty, grill i tłum na placu dojdą razem z rozbudową terenu.",
		"unlocks": "Młode rodziny +8, reputacja +4, tradycjonaliści -3.", "weekly": 0},
	"curia_gift": {"label": "Przelew do kurii", "cost": 1500, "days": 0, "effects": {"curia": 6}, "repeatable": true,
		"builds": "Nic. Pieniądze idą do diecezji.",
		"unlocks": "Kuria +6. Kuria pamięta ofiarodawców.", "weekly": 0},
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
## Rozkład mszy. Wydarzenia potrafią go zmienić, więc to stan gry, a nie stała:
## po sporze o godzinę sumy w niedzielę mogą być trzy msze zamiast dwóch.
var sunday_hours: Array = MASS_HOURS_SUNDAY.duplicate()
var weekday_hours: Array = MASS_HOURS_WEEKDAY.duplicate()
var respect := 0
var masses_done: Array = []
var masses_missed: Array = []
var location := "outside"
var done_today: Dictionary = {}
var meals_today := 0
## Pogrzeby czekające na odprawienie i dzień, po którym rodzina pójdzie do sąsiedniej parafii.
var funerals_pending := 0
var funeral_deadline := 0
var deceased_name := ""
var apples_picked := 0
var scheduled: Array = []
var pending_investments: Array = []
var fired_events: Array = []
## Trwające awarie: lista identyfikatorów z Breakdowns.ALL. Kosztują co rano,
## dopóki nie zostaną naprawione, a niektóre blokują czynności.
var breakdowns: Array = []
var breakdown_since: Dictionary = {}
var pending_repairs: Array = []
## Dzień, od którego wydarzenie może wrócić. Bez tego pula powtarzałaby się co chwilę.
var event_cooldowns: Dictionary = {}
## Ile poranków z rzędu nic się nie wydarzyło. Podbija szansę, żeby gra nie milkła.
var quiet_days := 0
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
var _mass_started_hour := 12
var _sleep_minutes := 480.0
var _read_minutes := 60.0
var _simulate_days := 0


func _ready() -> void:
	# debug: --wipe kasuje zapis, --condition/--rep ustawiają wskaźniki,
	# --built=roof,heating stawia inwestycje (z --unseen kamera je pokaże)
	var args := OS.get_cmdline_user_args()
	if args.has("--wipe"):
		SaveGame.wipe()
	if start_unix == 0:
		start_unix = Calendar.today_start_unix()
	# po wczytaniu albo starcie o późniejszej godzinie msze, których pora minęła,
	# muszą być od razu rozliczone, a nie dopiero przy pierwszej klatce bez okna
	call_deferred("_check_missed_masses")
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
		elif arg == "--check":
			# kontrola definicji wydarzeń i awarii, bez uruchamiania gry
			call_deferred("_run_check")
		elif arg.begins_with("--simulate="):
			# przebieg wielu dni bez gracza, żeby zobaczyć, co pula wydarzeń robi w praktyce
			_simulate_days = maxi(int(arg.trim_prefix("--simulate=")), 1)
			call_deferred("_run_simulation")
		elif arg.begins_with("--breakdown="):
			# --breakdown=car,furnace startuje z trwającymi awariami
			for id in arg.trim_prefix("--breakdown=").split(",", false):
				if Breakdowns.has(id):
					breakdowns.append(id)
					breakdown_since[id] = day
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
	_check_missed_masses()
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


# ---------- msze ----------

## W dzień powszedni są dwie msze, rano i wieczorem. W niedziele i święta nakazane
## obowiązuje rozkład niedzielny, który mogły zmienić wcześniejsze decyzje.
func mass_hours_today() -> Array:
	if is_sunday() or Calendar.is_holy_day(day):
		return sunday_hours
	return weekday_hours


## Jak pora dnia wpływa na frekwencję: rano przychodzą najwytrwalsi, w południe
## wszyscy, wieczorem ci po pracy. Liczy się godzina, a nie miejsce na liście.
static func hour_attendance(hour: int) -> float:
	if hour < 9:
		return 0.75
	if hour >= 16:
		return 0.85
	return 1.0


func schedule_text() -> String:
	var parts: Array[String] = []
	for h in mass_hours_today():
		parts.append("%02d:00" % int(h))
	return ", ".join(parts)


## Godzina mszy, której okno jest teraz otwarte. -1, gdy żadnej.
func open_mass_hour() -> int:
	for h in mass_hours_today():
		if masses_done.has(h):
			continue
		if minutes >= h * 60 - MASS_WINDOW_BEFORE and minutes <= h * 60 + MASS_WINDOW_AFTER:
			return int(h)
	return -1


## Najbliższa msza, której jeszcze nie odprawiono i której pora nie minęła.
## Godziny po czasie pomijamy tu same, nie czekając na rozliczenie opuszczonych,
## żeby podpowiedź nigdy nie wskazywała mszy sprzed kilku godzin.
func next_mass_hour() -> int:
	for h in mass_hours_today():
		if masses_done.has(h) or masses_missed.has(h):
			continue
		if minutes > h * 60 + MASS_WINDOW_AFTER:
			continue
		return int(h)
	return -1


## Podpowiedź przy ołtarzu zawsze podaje cały dzisiejszy rozkład, żeby nie trzeba było
## zgadywać, o której są msze i której się nie zdążyło odprawić.
func mass_hint() -> String:
	var plan := "Msze dziś: %s." % schedule_text()
	var next := next_mass_hour()
	if next < 0:
		return "%s Na dziś już po wszystkich." % plan
	var wait := int(next * 60 - MASS_WINDOW_BEFORE - minutes)
	if wait <= 0:
		return "%s Ta o %02d:00 zaczyna się teraz, stań przy ołtarzu." % [plan, next]
	return "%s Najbliższa o %02d:00, wejdź najwyżej kwadrans wcześniej, czyli za %s." % [plan, next, duration_text(float(wait))]


## Msze, na które ksiądz nie zdążył, rozliczają się same, gdy minie ich pora.
func _check_missed_masses() -> void:
	for h in mass_hours_today():
		if masses_done.has(h) or masses_missed.has(h):
			continue
		if minutes > h * 60 + MASS_WINDOW_AFTER:
			masses_missed.append(h)
			respect -= RESPECT_PER_MISSED
			apply_effects({"trad": -2, "reputation": -1})
			var text := "Msza o %02d:00 się nie odbyła. Szacunek -%d, tradycjonaliści -2." % [h, RESPECT_PER_MISSED]
			toast.emit(text)
			add_log(text)


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
			"respect": respect += v
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
		"young": "młode rodziny", "curia": "kuria", "energy": "energia", "respect": "szacunek"}
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
	if def.get("apple", false):
		_pick_apple(def)
		return
	var mass_hour_now := -1
	if def.get("mass", false):
		mass_hour_now = open_mass_hour()
		if mass_hour_now < 0:
			toast.emit(mass_hint())
			return
	if def.has("builds") and built.has(def["builds"]):
		toast.emit("To już naprawione.")
		return
	var blocker := blocked_by(id)
	if blocker != "":
		toast.emit(blocker)
		return
	if def.get("funeral", false) and funerals_pending <= 0:
		toast.emit("Nikt nie czeka na pogrzeb. Bogu dzięki.")
		return
	var is_meal: bool = def.get("meal", false)
	if is_meal:
		if meals_today >= MEALS_PER_DAY:
			toast.emit("Dwa posiłki dziennie wystarczą.")
			return
		if energy >= 99.0:
			toast.emit("Nie jesteś głodny.")
			return
		if money + int(def["money"]) < 0:
			toast.emit("Nie ma za co.")
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
	if not is_meal:
		energy = maxf(0.0, energy - def["energy"])
		done_today[id] = true
	if mass_hour_now >= 0:
		# msza liczy się jako odprawiona dopiero tutaj, po wszystkich kontrolach
		_mass_started_hour = mass_hour_now
		masses_done.append(mass_hour_now)
	if def.has("cutscene"):
		_begin_cutscene(id, def)
	else:
		_finish_activity(def)
	state_changed.emit()


## Jabłka z przykościelnego drzewa: mały zastrzyk energii, trzy dziennie,
## do zerwania tylko wtedy, gdy owoce są na drzewie.
const APPLES_PER_DAY := 3


func apples_left() -> int:
	return maxi(0, APPLES_PER_DAY - apples_picked)


func _pick_apple(def: Dictionary) -> void:
	if apples_left() <= 0:
		toast.emit("Na dolnych gałęziach nic już nie ma. Jutro dojrzeją następne.")
		return
	if minutes + def["minutes"] > 24 * 60:
		toast.emit("Za późno na to dzisiaj.")
		return
	minutes += def["minutes"]
	apples_picked += 1
	var gain := -int(def["energy"])
	energy = clampf(energy + gain, 0.0, 100.0)
	toast.emit("%s Energia +%d. Zostały jabłka: %d." % [def["toast"], gain, apples_left()])
	world_changed.emit()
	state_changed.emit()


## Ławka z brewiarzem: energia rośnie z czasem, który się na niej spędzi.
## Sen daje 12 na godzinę, czytanie 10, więc siedzenie nigdy nie bije nocy.
const READ_ENERGY_PER_HOUR := 10.0
const READ_MIN_MINUTES := 30
const READ_MAX_MINUTES := 24 * 60
const READ_STEP_MINUTES := 30
const MEALS_PER_DAY := 2


func read_breviary(total_minutes: float) -> void:
	if modal_open or cutscene:
		return
	var span := clampf(total_minutes, float(READ_MIN_MINUTES), float(READ_MAX_MINUTES))
	if minutes + span > 24 * 60:
		toast.emit("Za późno, żeby tyle siedzieć. Idź spać.")
		return
	_read_minutes = span
	minutes += span
	_begin_cutscene("read_breviary", ACTIVITIES["read_breviary"])


func read_gain(total_minutes: float) -> int:
	return int(round(total_minutes / 60.0 * READ_ENERGY_PER_HOUR))


## „1 dzień”, „3 dni”
static func days_text(days: int) -> String:
	return "1 dzień" if days == 1 else "%d dni" % days


## „45 minut”, „1 h 30 min”
static func duration_text(total_minutes: float) -> String:
	var m := int(round(total_minutes))
	if m < 60:
		return "%d minut" % m
	if m % 60 == 0:
		return hours_text(float(m) / 60.0)
	return "%d h %d min" % [m / 60, m % 60]


## Ile minut zostało do otwarcia okna najbliższej mszy. Zero, gdy okno już otwarte
## albo gdy na dziś nie ma czego czekać.
func minutes_to_next_mass() -> float:
	var next := next_mass_hour()
	if next < 0:
		return 0.0
	return maxf(0.0, next * 60 - MASS_WINDOW_BEFORE - minutes)


func _take_meal(def: Dictionary) -> void:
	var gain := -int(def["energy"])
	energy = clampf(energy + gain, 0.0, 100.0)
	meals_today += 1
	apply_effects({"money": def["money"]})
	toast.emit("%s Energia +%d." % [def["toast"], gain])
	state_changed.emit()


## Kto jest następny w kolejce do odwiedzin.
func next_visit() -> Dictionary:
	return Visits.current(self)


## Skutki czynności: liczby, komunikat i ślad w świecie.
func _finish_activity(def: Dictionary) -> void:
	if def.get("meal", false):
		_take_meal(def)
		return
	if def.get("read", false):
		var gain := read_gain(_read_minutes)
		energy = clampf(energy + gain, 0.0, 100.0)
		toast.emit("Na ławce z brewiarzem: %s. Energia +%d." % [duration_text(_read_minutes), gain])
		state_changed.emit()
		return
	if def.get("funeral", false):
		var offering := randi_range(800, 1200)
		apply_effects({"money": offering, "reputation": 2, "trad": 1})
		respect += 2
		funerals_pending = maxi(0, funerals_pending - 1)
		var text := "Pogrzeb: %s. Rodzina złożyła %d zł. Reputacja +2, szacunek +2." % [deceased_name, offering]
		toast.emit(text)
		add_log(text)
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
	attendance = int(attendance * hour_attendance(_mass_started_hour))
	if mass_hours_today().size() >= 3:
		# przy trzech mszach ludzie rozkładają się na wszystkie
		attendance = int(attendance * 0.8)
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


## Miejsca, w których dziś nie posprzątano, a ludzie tamtędy przechodzą.
func _mess_seen() -> Array[String]:
	var places: Array[String] = []
	if not done_today.has("sweep"):
		places.append("plac przed kościołem")
	if not done_today.has("clean_church"):
		places.append("wnętrze kościoła")
	return places


func _hold_mass(attendance: int) -> void:
	var taca := int(attendance * randf_range(3.2, 5.0) * Calendar.taca_multiplier(day, _cut_start))
	apply_effects({"money": taca, "reputation": 1})
	var respect_gain := RESPECT_PER_MASS * (2 if is_sunday() or Calendar.feast_name(day) != "" else 1)
	respect += respect_gain
	if _mass_started_hour < 9:
		apply_effects({"trad": 1})
	elif _mass_started_hour >= 16:
		# wieczorna msza dla tych, którzy rano są w pracy
		apply_effects({"reputation": 1})
	else:
		apply_effects({"young": 1})
	var label := "Msza"
	if _mass_roraty:
		# ciemny poranek, świece i ci, którym naprawdę zależy
		label = "Roraty"
		apply_effects({"trad": 2})
	elif Calendar.feast_name(day) != "" and Calendar.attendance_multiplier(day, _cut_start) > 1.0:
		label = Calendar.feast_name(day)
	var text := "%s o %02d:00: %d osób, taca %d zł. Szacunek +%d." % [label, _mass_started_hour, attendance, taca, respect_gain]
	var mess := _mess_seen()
	if not mess.is_empty():
		var penalty := MESS_PENALTY * mess.size()
		apply_effects({"reputation": -penalty})
		respect -= penalty
		text += " Ludzie zobaczyli bałagan (%s): reputacja -%d, szacunek -%d." % [", ".join(mess), penalty, penalty]
	toast.emit(text)
	add_log(text)


# ---------- investments ----------

func can_invest(id: String) -> bool:
	var def: Dictionary = INVESTMENTS[id]
	if not def.get("repeatable", false) and built.has(id):
		return false
	return money >= def["cost"] and not pending_investments.has(id)


## Ile tygodni zwraca się inwestycja z samego stałego dochodu. Zero, gdy nie daje pieniędzy.
static func payback_weeks(id: String) -> int:
	var def: Dictionary = INVESTMENTS[id]
	# do zwrotu liczy się cały spodziewany dochód, nie tylko stała opłata
	var weekly := int(def.get("expected_weekly", def.get("weekly", 0)))
	if weekly <= 0:
		return 0
	return int(ceil(float(def["cost"]) / float(weekly)))


## Stały dochód z ukończonych inwestycji, doliczany przy rozliczeniu tygodnia.
func weekly_yield() -> int:
	var total := 0
	for id in built:
		if INVESTMENTS.has(id):
			total += int(INVESTMENTS[id].get("weekly", 0))
	return total


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

const DELAYED_KEYS := ["chance", "else_text", "else_effects", "breakdown", "else_breakdown", "special"]


func choose_option(event: Dictionary, index: int) -> void:
	var opt: Dictionary = event["options"][index]
	if opt.has("special"):
		var msg := _apply_special(str(opt["special"]))
		if msg != "":
			toast.emit(msg)
			add_log(msg)
	if opt.has("effects"):
		apply_effects(opt["effects"])
	if opt.has("set"):
		for key in opt["set"]:
			set(key, opt["set"][key])
	if opt.has("breakdown"):
		add_breakdown(str(opt["breakdown"]))
	if opt.has("fix"):
		_clear_breakdown(str(opt["fix"]))
	if opt.has("delayed"):
		var d: Dictionary = opt["delayed"]
		var item := {"day": day + int(d["days"]), "text": str(d.get("text", "")), "effects": d.get("effects", {})}
		for key in DELAYED_KEYS:
			if d.has(key):
				item[key] = d[key]
		scheduled.append(item)
	# scenariusz pierwszego tygodnia znika na zawsze, pula i kryzysy wracają po karencji
	if event.has("cooldown"):
		event_cooldowns[event["id"]] = day + int(event["cooldown"])
	else:
		fired_events.append(event["id"])
	add_log("%s: %s." % [event["title"], opt["label"]])
	state_changed.emit()


## Skutki, których nie da się zapisać liczbami, bo zależą od stanu parafii.
## Zwraca komunikat do pokazania graczowi albo pusty napis.
func _apply_special(kind: String) -> String:
	match kind:
		"honest_report":
			if money >= 0:
				apply_effects({"curia": 3})
				return "Kuria przyjęła sprawozdanie. Kuria +3."
			apply_effects({"curia": -3})
			return "Kuria nie jest zachwycona minusem na koncie. Kuria -3."
		"visitation_ready", "visitation_raw":
			# biskup nie czyta wskaźników, tylko widzi kościół i to, co mówią ludzie
			var score := condition + reputation + (12 if kind == "visitation_ready" else 0)
			if score >= 130:
				apply_effects({"curia": 8, "respect": 3})
				return "Biskup obszedł kościół, przejrzał księgi i powiedział, że dawno nie widział tak prowadzonej parafii. Kuria +8, szacunek +3."
			if score >= 90:
				apply_effects({"curia": 2})
				return "Biskup nie miał uwag, ale też nie miał czasu na kawę. Kuria +2."
			apply_effects({"curia": -7, "reputation": -2})
			return "Biskup zapytał, od kiedy tak wygląda prezbiterium, i nie doczekał się odpowiedzi. Kuria -7, reputacja -2."
		"viral_quiet":
			if reputation >= 55:
				apply_effects({"young": 5, "reputation": 3})
				return "Nagranie obroniło się samo. Ludzie z powiatu piszą, że chcieliby takiego księdza. Młode rodziny +5, reputacja +3."
			apply_effects({"reputation": -5, "curia": -3})
			return "Fragment żyje własnym życiem i nikt nie pyta o kontekst. Reputacja -5, kuria -3."
		"viral_answer":
			# tu liczy się to, ile ksiądz zdążył sobie wyrobić szacunku
			if respect >= 30:
				apply_effects({"young": 8, "reputation": 5, "respect": 2})
				return "Odpowiedź obejrzało więcej ludzi niż samo nagranie i wypadła dobrze. Młode rodziny +8, reputacja +5."
			apply_effects({"young": -3, "reputation": -4, "curia": -2})
			return "Odpowiedź wypadła nerwowo i to ona stała się materiałem. Młode rodziny -3, reputacja -4, kuria -2."
	return ""


# ---------- awarie ----------

## Nowa awaria. Zwraca false, gdy ta awaria już trwa albo identyfikator jest nieznany.
func add_breakdown(id: String, announce: bool = true) -> bool:
	if not Breakdowns.has(id) or breakdowns.has(id):
		return false
	breakdowns.append(id)
	breakdown_since[id] = day
	var def: Dictionary = Breakdowns.ALL[id]
	if announce:
		var text := "Awaria: %s. %s" % [def["label"], def.get("note", "")]
		toast.emit(text)
		add_log(text)
	if def.get("world", false):
		world_changed.emit()
	state_changed.emit()
	return true


func _clear_breakdown(id: String) -> void:
	breakdowns.erase(id)
	breakdown_since.erase(id)
	pending_repairs.erase(id)


func can_repair(id: String) -> bool:
	if not breakdowns.has(id) or pending_repairs.has(id):
		return false
	return money >= int(Breakdowns.ALL[id]["cost"])


## Naprawa idzie tą samą drogą co inwestycja: płacisz dziś, prace kończą się rano.
func repair_breakdown(id: String) -> void:
	if not can_repair(id):
		toast.emit("Nie stać parafii albo naprawa już trwa.")
		return
	var def: Dictionary = Breakdowns.ALL[id]
	apply_effects({"money": -int(def["cost"])})
	var days := int(def["days"])
	if days <= 0:
		apply_effects(def.get("fixed_effects", {}))
		_clear_breakdown(id)
		toast.emit(str(def["fixed_text"]))
		add_log(str(def["fixed_text"]))
		world_changed.emit()
	else:
		pending_repairs.append(id)
		scheduled.append({"day": day + days, "text": str(def["fixed_text"]),
			"effects": def.get("fixed_effects", {}), "repair": id})
		toast.emit("%s: naprawa zlecona, gotowe za %s." % [def["label"], days_text(days)])
		add_log("Zlecono naprawę: %s (%s zł)." % [def["label"], money_text(int(def["cost"]))])
	state_changed.emit()


## Czynność odebrana przez awarię: bez samochodu nie pojedziesz do chorego.
## Zwraca komunikat dla gracza albo pusty napis, gdy nic nie blokuje.
func blocked_by(activity_id: String) -> String:
	for id in breakdowns:
		if str(Breakdowns.ALL[id].get("blocks", "")) == activity_id:
			return "%s. %s" % [Breakdowns.label(id), Breakdowns.ALL[id].get("note", "")]
	return ""


## Awarie kosztują co rano, dopóki trwają. To jest cena zwlekania z naprawą.
func _breakdown_morning() -> Array[String]:
	var lines: Array[String] = []
	for id in breakdowns:
		if pending_repairs.has(id):
			continue
		var def: Dictionary = Breakdowns.ALL[id]
		apply_effects(def.get("daily", {}))
		var open_days := day - int(breakdown_since.get(id, day))
		var suffix := "" if open_days < 3 else "  (%s bez naprawy)" % days_text(open_days)
		lines.append(str(def["daily_text"]) + suffix)
	return lines


## Zaniedbana parafia psuje się sama. Im gorszy stan budynków, tym większa szansa,
## a pora roku decyduje, co konkretnie pada.
func _breakdown_risk() -> Array[String]:
	var lines: Array[String] = []
	var risk := clampf((60.0 - float(condition)) / 320.0, 0.0, 0.18)
	if risk <= 0.0 or randf() >= risk:
		return lines
	var part := Calendar.time_of_year(day)
	var pool: Array = []
	var total := 0.0
	for id in Breakdowns.ALL:
		if breakdowns.has(id):
			continue
		var w := Breakdowns.natural_risk(id, part)
		if w <= 0.0:
			continue
		pool.append([id, w])
		total += w
	if pool.is_empty():
		return lines
	var roll := randf() * total
	for entry in pool:
		roll -= float(entry[1])
		if roll <= 0.0:
			var id: String = entry[0]
			if add_breakdown(id, false):
				lines.append("Awaria: %s. %s" % [Breakdowns.label(id), Breakdowns.ALL[id].get("note", "")])
			break
	return lines


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
	var missed_holy_day := Calendar.is_holy_day(day) and masses_done.is_empty()
	var missed_name := Calendar.feast_name(day)
	day += 1
	minutes = clampf(wake_minutes, 0.0, 23.0 * 60.0)
	energy = clampf(new_energy, 20.0, 100.0)
	done_today.clear()
	apples_picked = 0
	meals_today = 0
	masses_done.clear()
	masses_missed.clear()
	var lines: Array[String] = extra_lines.duplicate()
	# najpierw kończą się prace, żeby gotowa inwestycja liczyła się już od tego poranka
	var remaining: Array = []
	for item in scheduled:
		if int(item["day"]) > day:
			remaining.append(item)
			continue
		# skutek odroczony bywa niepewny: "chance" rozstrzyga, która wersja dziś wchodzi
		var hit := true
		if item.has("chance"):
			hit = randf() < float(item["chance"])
		var text: String = str(item.get("text", "")) if hit else str(item.get("else_text", ""))
		apply_effects(item.get("effects", {}) if hit else item.get("else_effects", {}))
		var broke: String = str(item.get("breakdown", "")) if hit else str(item.get("else_breakdown", ""))
		if broke != "" and add_breakdown(broke, false):
			text += "  Awaria: %s. %s" % [Breakdowns.label(broke), Breakdowns.ALL[broke].get("note", "")]
		if item.has("special"):
			var msg := _apply_special(str(item["special"]))
			if msg != "":
				text = (text + " " + msg).strip_edges()
		if item.has("invest"):
			pending_investments.erase(item["invest"])
			if not built.has(item["invest"]):
				built.append(item["invest"])
			world_changed.emit()
		if item.has("repair"):
			_clear_breakdown(str(item["repair"]))
			world_changed.emit()
		if text != "":
			lines.append(text)
			add_log(text)
	scheduled = remaining

	if missed_holy_day:
		# święto nakazane bez mszy zauważą wszyscy, łącznie z kurią
		apply_effects({"trad": -6, "reputation": -3, "curia": -3})
		lines.append("Wczoraj było święto nakazane (%s), a mszy nie było. Tradycjonaliści -6, reputacja -3, kuria -3." % missed_name)
	# rozliczenie tygodnia w poniedziałek rano, według prawdziwego kalendarza
	if Calendar.is_monday(day):
		lines.append_array(_weekly_settlement())
	lines.append_array(_funeral_morning())
	lines.append_array(_breakdown_morning())
	lines.append_array(_breakdown_risk())
	state_changed.emit()
	save_now()
	var feast: String = Calendar.feast_name(day)
	if feast != "":
		lines.push_front("Dziś %s. %s" % [feast, str(Calendar.feast(day).get("note", ""))])
	if not lines.is_empty():
		request_modal("report", {"title": "%s   %s" % [date_text(), season()], "lines": lines})
	_morning_events()


## Scenariusz pierwszego tygodnia i kryzysy wchodzą zawsze. Pula tylko wtedy, gdy dzień
## nie jest już nimi zajęty, i tylko z pewną szansą, która rośnie po cichych dniach.
func _morning_events() -> void:
	var forced: Array = Events.due_events(self)
	for ev in forced:
		request_modal("event", {"event": ev})
	if not forced.is_empty():
		quiet_days = 0
		return
	if randf() < Events.daily_chance(quiet_days):
		var drawn: Dictionary = Events.draw(self)
		if not drawn.is_empty():
			quiet_days = 0
			request_modal("event", {"event": drawn})
			return
	quiet_days += 1


const DECEASED := ["pani Genowefa Kruk", "pan Tadeusz Wrona", "pani Zofia Maj", "pan Henryk Sowa",
	"pani Jadwiga Bąk", "pan Kazimierz Lis", "pani Irena Kos", "pan Stanisław Gil"]


## Z cmentarzem parafia grzebie swoich. Co kilka dni ktoś umiera, a rodzina czeka
## najwyżej dwa dni; potem pogrzeb odbywa się u sąsiada i ludzie to zapamiętują.
func _funeral_morning() -> Array[String]:
	var lines: Array[String] = []
	if not built.has("cemetery"):
		return lines
	if funerals_pending > 0 and day > funeral_deadline:
		funerals_pending = 0
		apply_effects({"reputation": -3})
		respect -= 2
		lines.append("Rodzina nie doczekała się pogrzebu i pochowała %s w sąsiedniej parafii. Reputacja -3, szacunek -2." % deceased_name)
	if funerals_pending == 0 and randf() < 0.22:
		funerals_pending = 1
		funeral_deadline = day + 1
		deceased_name = DECEASED[(day * 31) % DECEASED.size()]
		lines.append("W nocy zmarł(a) %s. Rodzina prosi o pogrzeb dziś albo jutro. Idź na cmentarz za kościołem." % deceased_name)
	return lines


func _weekly_settlement() -> Array[String]:
	var lines: Array[String] = []
	var expenses := WEEKLY_EXPENSES
	money -= expenses
	var yield_total := weekly_yield()
	if yield_total > 0:
		# przez apply_effects, żeby dochód wszedł do wpływów tygodnia w raporcie i finansach
		apply_effects({"money": yield_total})
		lines.append("Opłaty i dochody z inwestycji: +%s zł." % money_text(yield_total))
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
	sunday_hours = MASS_HOURS_SUNDAY.duplicate()
	weekday_hours = MASS_HOURS_WEEKDAY.duplicate()
	done_today.clear()
	apples_picked = 0
	meals_today = 0
	masses_done.clear()
	masses_missed.clear()
	respect = 0
	funerals_pending = 0
	funeral_deadline = 0
	deceased_name = ""
	scheduled.clear()
	pending_investments.clear()
	fired_events.clear()
	breakdowns.clear()
	breakdown_since.clear()
	pending_repairs.clear()
	event_cooldowns.clear()
	quiet_days = 0
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


# ---------- narzędzia ----------

func _run_check() -> void:
	get_tree().quit(0 if CheckDefinitions.report() else 1)


func _run_simulation() -> void:
	Simulate.run(_simulate_days)
	get_tree().quit()
