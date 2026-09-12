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
## Telefon: ile pozycji trzymamy w historii konta i w skrzynce oraz jaka jest szansa
## na post w mediach każdego ranka. Powtórki blokuje karencja w Phone.MEDIA_COOLDOWN.
## Kiedy kuria sama pisze z prośbą o wyjaśnienia i jak często bank przypomina o debecie.

const ACTIVITIES := {
	"inspection": {"label": "Przegląd budynków", "minutes": 45, "energy": 10, "once": true,
		"effects": {"condition": 3}, "toast": "Przegląd wykonany, drobne usterki usunięte. Stan budynków +3."},
	"repair_gutter": {"label": "Napraw rynnę", "minutes": 60, "energy": 20, "once": true,
		"effects": {"condition": 6}, "toast": "Rynna naprawiona. Stan budynków +6.", "builds": "gutter"},
	"sweep": {"label": "Zamieć plac", "minutes": 30, "energy": 10, "once": true,
		"effects": {"reputation": 1}, "toast": "Plac zamieciony. Reputacja +1.", "world": true,
		"cutscene": "Zamiatanie placu", "director_group": "activity_scene", "scene": {"kind": "sweep", "seconds": 4.5, "zoom": 7.0}},
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
var stats: Dictionary = {}
var stat_xp: Dictionary = {}
var talents: Array = []
var rank := "wikary"
var faith := 0
var career: Dictionary = {}
var faith_history: Array = []
var flags: Dictionary = {}
var chronicle: Array = []
var pending_events: Array = []
var week_income := 0
var week_expenses := 0
var budget: Dictionary = {"biezace": 1, "remonty": 1, "infrastruktura": 1, "duszpasterstwo": 1, "ludzie": 1}
var budget_reservations: Dictionary = {}
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
## Telefon: skrzynka wiadomości (poczta, media, bank) i historia operacji na koncie.
## Wiadomości z terminem rozliczają się rano - brak odpowiedzi to też decyzja.
var phone_inbox: Array = []
var bank_log: Array = []
var media_recent: Dictionary = {}
var _last_curia_mail := -99
var _last_bank_alert := -99
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
	for arg in args:
		# --seed=7 ustala ziarno losowania, żeby dwa przebiegi --simulate dały ten sam
		# wynik. Bez tego symulacji nie da się użyć jako dowodu, że zmiana w kodzie
		# niczego nie przestawiła. Musi być przed pierwszym losowaniem, czyli tutaj.
		if arg.begins_with("--seed="):
			seed(int(arg.trim_prefix("--seed=")))
	if args.has("--wipe"):
		SaveGame.wipe()
	if start_unix == 0:
		start_unix = Calendar.today_start_unix()
	Progression.reset(self)
	Career.reset(self)
	# pierwszy list czeka już na starcie, także wtedy, gdy gra rusza bez menu nowej gry
	if phone_inbox.is_empty():
		Inbox.send(Inbox.WELCOME_MAIL)
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
		elif arg == "--mail":
			# debug: wrzuca do telefonu list z kurii i post w mediach, żeby dało się
			# obejrzeć wiadomość z terminem i przyciskami odpowiedzi
			Inbox.send.call_deferred(Phone.curia_mail("przeniesienie sumy na 11:00", Phone.excuses()))
			Inbox.send.call_deferred(Phone.MEDIA[0].duplicate(true).merged(
				{"app": "media", "read": false, "answered": -1}, true))
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
		elif arg == "--check-progression":
			call_deferred("_run_behavior_check", "res://scripts/tools/check_progression.gd")
		elif arg == "--check-progression-events":
			call_deferred("_run_behavior_check", "res://scripts/tools/check_progression_events.gd")
		elif arg == "--check-progression-ui":
			call_deferred("_run_progression_ui_check")
		elif arg == "--check-career":
			call_deferred("_run_career_check")
		elif arg == "--check-chains":
			call_deferred("_run_chains_check")
		elif arg == "--check-career-ui":
			call_deferred("_run_career_ui_check")
		elif arg == "--check-budget":
			call_deferred("_run_budget_check")
		elif arg == "--check-budget-ui":
			call_deferred("_run_budget_ui_check")
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
			Parish.apply_effects({"trad": -2, "reputation": -1})
			var text := "Msza o %02d:00 się nie odbyła. Szacunek -%d, tradycjonaliści -2." % [h, RESPECT_PER_MISSED]
			toast.emit(text)
			add_log(text)


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


func add_log(text: String) -> void:
	log_lines.push_front("Dzień %d, %s: %s" % [day, clock_text(), text])
	if log_lines.size() > 30:
		log_lines.resize(30)


# ---------- activities ----------

func do_activity(id: String, confirmed_expense: bool = false) -> void:
	if modal_open:
		return
	if id == "inspection" and (not Progression.has_talent("admin_inspection") or location != "rectory"):
		toast.emit("Przegląd wymaga talentu „%s” i wizyty przy biurku na plebanii." % Progression.TALENTS["admin_inspection"]["label"])
		return
	var def: Dictionary = ACTIVITIES[id].duplicate(true)
	def["minutes"] = activity_minutes(id)
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
	var blocker := Repairs.blocked_by(id)
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
	if is_meal and not confirmed_expense and Finance.needs_confirmation(-int(def["money"])):
		request_modal("confirm_activity_expense", {"id": id, "expense": -int(def["money"]), "label": str(def["label"])})
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
	Parish.apply_effects({"money": def["money"]}, "Zakupy na obiad", "biezace")
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
		Parish.apply_effects({"money": offering, "reputation": 2, "trad": 1}, "Ofiara pogrzebowa", "ofiary")
		respect += 2
		funerals_pending = maxi(0, funerals_pending - 1)
		var text := "Pogrzeb: %s. Rodzina złożyła %d zł. Reputacja +2, szacunek +2." % [deceased_name, offering]
		toast.emit(text)
		add_log(text)
		return
	if def.get("visit", false):
		Career.record("groups")
		var person := next_visit()
		Parish.apply_effects(person["effects"])
		toast.emit(person["toast"])
		add_log(person["toast"])
		Visits.advance(self)
		return
	if def == ACTIVITIES["confession"]:
		Career.record("sacraments", 3)
		Progression.record("confession")
	Parish.apply_effects(def["effects"])
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
	return Progression.attendance(mini(attendance, 500))


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
	Career.record("attendance", attendance)
	Progression.record("mass")
	var taca := int(attendance * randf_range(3.2, 5.0) * Calendar.taca_multiplier(day, _cut_start))
	Parish.apply_effects({"money": taca, "reputation": 1}, "Taca z mszy", "taca")
	var respect_gain := RESPECT_PER_MASS * (2 if is_sunday() or Calendar.feast_name(day) != "" else 1)
	respect += respect_gain
	if _mass_started_hour < 9:
		Parish.apply_effects({"trad": 1})
	elif _mass_started_hour >= 16:
		# wieczorna msza dla tych, którzy rano są w pracy
		Parish.apply_effects({"reputation": 1})
	else:
		Parish.apply_effects({"young": 1})
	var label := "Msza"
	if _mass_roraty:
		# ciemny poranek, świece i ci, którym naprawdę zależy
		label = "Roraty"
		Parish.apply_effects({"trad": 2})
	elif Calendar.feast_name(day) != "" and Calendar.attendance_multiplier(day, _cut_start) > 1.0:
		label = Calendar.feast_name(day)
	var text := "%s o %02d:00: %d osób, taca %d zł. Szacunek +%d." % [label, _mass_started_hour, attendance, taca, respect_gain]
	var mess := _mess_seen()
	if not mess.is_empty():
		var penalty := MESS_PENALTY * mess.size()
		Parish.apply_effects({"reputation": -penalty})
		respect -= penalty
		text += " Ludzie zobaczyli bałagan (%s): reputacja -%d, szacunek -%d." % [", ".join(mess), penalty, penalty]
	toast.emit(text)
	add_log(text)


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
		if _sleep_minutes >= 180 and _sleep_minutes < 360 and energy + gained >= 40:
			Progression.record("short_sleep")
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
		EventFlow.apply_delayed_branch(item, hit)
		var text: String = str(item.get("text", "")) if hit else str(item.get("else_text", ""))
		Parish.apply_effects(item.get("effects", {}) if hit else item.get("else_effects", {}))
		var broke: String = str(item.get("breakdown", "")) if hit else str(item.get("else_breakdown", ""))
		if broke != "" and Repairs.add(broke, false):
			text += "  Awaria: %s. %s" % [Breakdowns.label(broke), Breakdowns.ALL[broke].get("note", "")]
		if item.has("special"):
			var msg := EventFlow._apply_special(str(item["special"]))
			if msg != "":
				text = (text + " " + msg).strip_edges()
		if item.has("invest"):
			if item["invest"] == "festyn":
				Progression.record("festyn")
			pending_investments.erase(item["invest"])
			if not built.has(item["invest"]):
				built.append(item["invest"])
			world_changed.emit()
		if item.has("repair"):
			Repairs.clear(str(item["repair"]))
			world_changed.emit()
		# list, który miał przyjść po kilku dniach - ląduje w telefonie, nie w oknie.
		# Skrót "curia_about" składa prośbę kurii o wyjaśnienie danej decyzji.
		if item.has("mail") and hit:
			var mail: Dictionary = item["mail"]
			if mail.has("curia_about"):
				Inbox.send(Phone.curia_mail(str(mail["curia_about"]), Phone.excuses()))
			else:
				Inbox.send(mail)
		EventFlow.record_delayed_crisis(item)
		if text != "":
			lines.append(text)
			add_log(text)
	scheduled = remaining

	if missed_holy_day:
		# święto nakazane bez mszy zauważą wszyscy, łącznie z kurią
		Parish.apply_effects({"trad": -6, "reputation": -3, "curia": -3})
		lines.append("Wczoraj było święto nakazane (%s), a mszy nie było. Tradycjonaliści -6, reputacja -3, kuria -3." % missed_name)
	# rozliczenie tygodnia w poniedziałek rano, według prawdziwego kalendarza
	if Calendar.is_monday(day):
		lines.append_array(Finance.weekly_settlement())
	lines.append_array(_funeral_morning())
	lines.append_array(Career.morning())
	lines.append_array(Inbox.morning())
	lines.append_array(Repairs.morning())
	lines.append_array(Repairs.risk())
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
	var has_pending := _queue_pending_events()
	var forced: Array = Events.due_events(self)
	for ev in forced:
		request_modal("event", {"event": ev})
	if has_pending or not forced.is_empty():
		quiet_days = 0
		return
	if randf() < Events.daily_chance(quiet_days):
		var drawn: Dictionary = Events.draw(self)
		if not drawn.is_empty():
			quiet_days = 0
			request_modal("event", {"event": drawn})
			return
	quiet_days += 1


## Kolejka jest częścią zapisu poranka; dopiero decyzja usuwa z niej wydarzenie.
func _queue_pending_events() -> bool:
	var queued := false
	for id in pending_events.duplicate():
		var ev := Events.by_id(str(id))
		if ev.is_empty() or fired_events.has(id):
			pending_events.erase(id)
			continue
		if not Events._eligible(self, ev):
			continue
		request_modal("event", {"event": ev})
		queued = true
	return queued


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
		Parish.apply_effects({"reputation": -3})
		respect -= 2
		lines.append("Rodzina nie doczekała się pogrzebu i pochowała %s w sąsiedniej parafii. Reputacja -3, szacunek -2." % deceased_name)
	if funerals_pending == 0 and randf() < 0.22:
		funerals_pending = 1
		funeral_deadline = day + 1
		deceased_name = DECEASED[(day * 31) % DECEASED.size()]
		lines.append("W nocy zmarł(a) %s. Rodzina prosi o pogrzeb dziś albo jutro. Idź na cmentarz za kościołem." % deceased_name)
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
	_queue_pending_events()
	return true


## Pierwszy list w telefonie: kuria wita nowego proboszcza i od razu ustawia ton.


func start_new_game() -> void:
	SaveGame.wipe()
	start_unix = Calendar.today_start_unix()
	day = 1
	Progression.reset(self)
	Career.reset(self)
	flags.clear()
	pending_events.clear()
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
	budget = Finance.default_budget()
	budget_reservations.clear()
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
	phone_inbox.clear()
	bank_log.clear()
	media_recent.clear()
	Inbox.send(Inbox.WELCOME_MAIL)
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


func _run_budget_check() -> void:
	var checks: Script = load("res://scripts/tools/check_budget.gd")
	get_tree().quit(0 if checks != null and checks.report() else 1)


func _run_budget_ui_check() -> void:
	var passed: bool = await CheckBudgetUI.run()
	get_tree().quit(0 if passed else 1)


func _run_simulation() -> void:
	Simulate.run(_simulate_days)
	get_tree().quit()


func _run_career_check() -> void:
	_run_behavior_check("res://scripts/tools/check_career.gd")


func _run_chains_check() -> void:
	_run_behavior_check("res://scripts/tools/check_chains.gd")


func _run_behavior_check(path: String) -> void:
	var checks: Script = load(path)
	var problems: Array[String] = checks.run()
	for problem in problems:
		printerr(problem)
	if problems.is_empty():
		print("BEHAVIOR CHECK OK: ", path)
	get_tree().quit(0 if problems.is_empty() else 1)


func _run_career_ui_check() -> void:
	var checks: Script = load("res://scripts/tools/check_career_ui.gd")
	var passed: bool = await checks.run()
	get_tree().quit(0 if passed else 1)


func activity_minutes(id: String) -> int:
	return Progression.activity_minutes(id, int(ACTIVITIES[id]["minutes"]))


func _run_progression_ui_check() -> void:
	var checks: Script = load("res://scripts/tools/check_progression_ui.gd")
	var passed: bool = await checks.run()
	get_tree().quit(0 if passed else 1)
