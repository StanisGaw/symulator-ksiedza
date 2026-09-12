class_name CheckBudget
## Scenariusze regresyjne budżetu 2.3. Nie zapisują pliku; cały stan jest odtwarzany
## po kontroli, a runner CI dodatkowo uruchamia je z izolowanym user://.

const EXPECTED_COSTS := {
	"biezace": [0, 1800, 2400, 3000],
	"remonty": [0, 800, 1200, 1600],
	"infrastruktura": [0, 600, 900, 1200],
	"duszpasterstwo": [0, 600, 900, 1200],
	"ludzie": [0, 400, 600, 800],
}


static func run() -> Array[String]:
	var problems: Array[String] = []
	var before := _snapshot()
	_check_costs_and_forecast(problems)
	_check_normal_income_and_category_effects(problems)
	_check_weekly_settlement(problems)
	_check_investment_reservation(problems)
	_check_repairs_and_risk(problems)
	_check_save_compatibility(problems)
	_restore(before)
	return problems


static func report() -> bool:
	var problems := run()
	for problem in problems:
		printerr("BŁĄD BUDŻETU  " + problem)
	if problems.is_empty():
		print("Budżet 2.3: scenariusze finansowe spójne.")
	return problems.is_empty()


static func _check_costs_and_forecast(problems: Array[String]) -> void:
	_reset_state()
	_expect(problems, Finance.default_budget() == {
		"biezace": 1, "remonty": 1, "infrastruktura": 1, "duszpasterstwo": 1, "ludzie": 1},
		"domyślny plan ma pięć kategorii na poziomie 1")
	for id in EXPECTED_COSTS:
		for level in 4:
			_expect(problems, Finance.category_cost(id, level) == EXPECTED_COSTS[id][level],
				"%s poziom %d ma koszt %d zł" % [id, level, EXPECTED_COSTS[id][level]])
	_expect(problems, Finance.weekly_expenses(Finance.default_budget()) == 4200,
		"domyślny budżet kosztuje 4 200 zł")
	var maximum := {"biezace": 3, "remonty": 3, "infrastruktura": 3,
		"duszpasterstwo": 3, "ludzie": 3}
	_expect(problems, Finance.weekly_expenses(maximum) == 7800,
		"maksymalny budżet kosztuje 7 800 zł")
	_expect(problems, Finance.weekly_expenses(maximum) <= 2 * 6000,
		"maksymalny budżet nie przekracza dwukrotności typowego przychodu 6 000 zł")

	Game.money = 3000
	var forecast := Finance.forecast()
	_expect(problems, int(forecast.get("costs", -1)) == 4200, "prognoza obejmuje cały budżet")
	_expect(problems, int(forecast.get("income", -1)) == 0, "prognoza nie zakłada losowych wpływów")
	_expect(problems, int(forecast.get("interest", -1)) == 24, "prognoza liczy 2% odsetek w górę")
	_expect(problems, int(forecast.get("balance", 0)) == -1224, "prognoza odejmuje odsetki od salda")
	_expect(problems, int(forecast.get("curia_delta", 0)) == -3, "prognoza pokazuje karę kurii")
	_expect(problems, int(forecast.get("days", 0)) in range(1, 8), "prognoza wskazuje najbliższy poniedziałek")

	Game.money = 4200
	var original := Game.budget.duplicate(true)
	_expect(problems, not Finance.set_budget(maximum), "plan prowadzący do długu czeka na potwierdzenie")
	_expect(problems, Game.budget == original, "odmowa planu nie zmienia budżetu")
	_expect(problems, Finance.set_budget(maximum, true), "potwierdzony plan zadłużający zostaje przyjęty")
	_expect(problems, Game.budget == maximum, "potwierdzenie zapisuje cały plan atomowo")


static func _check_normal_income_and_category_effects(problems: Array[String]) -> void:
	_reset_state()
	seed(2307)
	Game.start_unix = int(Time.get_unix_time_from_datetime_dict({
		"year": 2026, "month": 9, "day": 7, "hour": 0, "minute": 0, "second": 0}))
	for game_day in range(1, 8):
		Game.day = game_day
		Game.done_today = {"sweep": true, "clean_church": true}
		for hour in Game.mass_hours_today():
			Game._mass_started_hour = int(hour)
			Game._cut_start = float(hour) * 60.0
			Game._hold_mass(Game._attendance(Game._cut_start))
	print("Zwykły tydzień mszy: %s zł przychodu." % Game.money_text(Game.week_income))
	_expect(problems, Game.week_income >= 4200 and Game.week_income <= 12000,
		"rzeczywisty tydzień zwykłych mszy daje przychód pokrywający 4 200 zł bez przekroczenia 12 000 zł")

	_reset_state()
	Game.money = 20000
	Game.budget = {"biezace": 0, "remonty": 0, "infrastruktura": 1,
		"duszpasterstwo": 2, "ludzie": 1}
	Finance.weekly_settlement()
	_expect(problems, Game.condition == 46, "bieżące 0 obniża stan budynków o 4")
	_expect(problems, Game.young == 51, "duszpasterstwo 2 podnosi młode rodziny o 1")

	_reset_state()
	Game.money = 20000
	Game.budget = {"biezace": 1, "remonty": 0, "infrastruktura": 1,
		"duszpasterstwo": 1, "ludzie": 1}
	Finance.weekly_settlement()
	_expect(problems, Game.condition == 48, "bieżące 1 obniża stan budynków o 2")


static func _check_weekly_settlement(problems: Array[String]) -> void:
	_reset_state()
	Game.money = 6000
	Game.week_income = 6000
	Finance.weekly_settlement()
	_expect(problems, Game.money == 1800, "zwykłe 6 000 zł przychodu pokrywa domyślny budżet")
	_expect(problems, Game.condition == 49, "bieżące i remonty sumują tygodniowy skutek stanu budynków")
	_expect(problems, Game.reputation == 50 and Game.young == 50 and Game.trad == 50,
		"pozostałe domyślne kategorie nie zmieniają relacji")
	_expect(problems, Game.week_income == 0 and Game.week_expenses == 0,
		"rozliczenie zeruje liczniki tygodnia")
	var categories: Array[String] = []
	for entry in Game.bank_log:
		categories.append(str(entry.get("category", "")))
	for id in EXPECTED_COSTS:
		_expect(problems, categories.has(id), "historia banku zawiera kategorię %s" % id)

	_reset_state()
	Game.money = 3000
	Finance.weekly_settlement()
	_expect(problems, Game.money == -1224, "poniedziałek pobiera 24 zł odsetek od długu 1 200 zł")
	_expect(problems, Game.curia == 47, "poniedziałek z długiem obniża kurię o 3")
	_expect(problems, str(Game.bank_log[0].get("category", "")) == "odsetki",
		"odsetki mają własną kategorię w historii")

	_reset_state()
	Game.money = 10000
	Game.condition = 29
	Finance.weekly_settlement()
	_expect(problems, Game.condition == 28 and Game.reputation == 48,
		"stary próg złego stanu budynków nadal obniża reputację")


static func _check_investment_reservation(problems: Array[String]) -> void:
	_reset_state()
	Game.money = 20000
	Game.budget["remonty"] = 0
	_expect(problems, Finance.investment_block_reason("roof") != "",
		"dachu nie można kupić bez poziomu remontów")

	Game.budget = Finance.default_budget()
	Game.money = 8000
	var before_money := Game.money
	_expect(problems, not Finance.invest("roof"), "dach czeka na potwierdzenie prognozowanego długu")
	_expect(problems, Game.money == before_money and Game.pending_investments.is_empty()
		and Game.budget_reservations.is_empty(), "odmowa dachu nie zmienia stanu")
	_expect(problems, Finance.invest("roof", true), "potwierdzenie pozwala zlecić dach")
	_expect(problems, Game.money == 0 and Game.young == 48, "zakup dachu pobiera 8 000 zł i młode rodziny -2")
	var reservation: Dictionary = Game.budget_reservations.get("remonty", {})
	_expect(problems, str(reservation.get("investment", "")) == "roof"
		and int(reservation.get("until_day", 0)) == Game.day + 14,
		"dach rezerwuje remonty na 14 dni")
	Game.money = 20000
	_expect(problems, Finance.investment_block_reason("hall") != "",
		"rezerwacja dachu blokuje salkę mimo wystarczającej gotówki")
	var blocked_plan := Game.budget.duplicate(true)
	blocked_plan["remonty"] = 0
	_expect(problems, not Finance.set_budget(blocked_plan, true) and Game.budget["remonty"] == 1,
		"aktywna rezerwacja nie pozwala wyzerować remontów")
	Game.day = int(reservation["until_day"])
	_expect(problems, Finance.reservation_text("remonty") == "", "rezerwacja wygasa w dniu until_day")
	_expect(problems, Finance.investment_block_reason("hall") == "", "po wygaśnięciu dach nie blokuje salki")
	_expect(problems, Finance.invest("hall"), "po wygaśnięciu można zlecić salkę")
	var hall_scheduled := false
	for item in Game.scheduled:
		if str(item.get("invest", "")) == "hall" and int(item.get("day", 0)) == Game.day + 4:
			hall_scheduled = true
	_expect(problems, Game.trad == 48 and hall_scheduled,
		"salka od razu obniża tradycjonalistów o 2 i kończy się po 4 dniach")


static func _check_repairs_and_risk(problems: Array[String]) -> void:
	_reset_state()
	Game.breakdowns = ["martens"]
	Game.breakdown_since = {"martens": Game.day}
	Game.money = 900
	_expect(problems, Repairs.can_repair("martens"), "naprawa jest dostępna przy gotówce równej cenie")
	_expect(problems, not Repairs.repair("martens"), "naprawa czeka na potwierdzenie prognozowanego długu")
	_expect(problems, Game.money == 900 and Game.pending_repairs.is_empty()
		and Game.scheduled.is_empty(), "odmowa naprawy nie zmienia stanu")
	_expect(problems, Repairs.repair("martens", true), "potwierdzenie zleca naprawę")
	_expect(problems, Game.money == 0 and Game.pending_repairs.has("martens"),
		"potwierdzona naprawa pobiera właściwą kwotę")
	_expect(problems, str(Game.bank_log[0].get("category", "")) == "remonty",
		"naprawa trafia do kategorii remonty")

	Game.budget = Finance.default_budget()
	_expect(problems, is_equal_approx(Finance.natural_risk_multiplier(), 1.0),
		"domyślny budżet zachowuje zwykłe ryzyko awarii")
	Game.budget["biezace"] = 0
	_expect(problems, is_equal_approx(Finance.natural_risk_multiplier(), 1.5),
		"bieżące 0 mnoży ryzyko awarii przez 1,5")
	Game.budget["remonty"] = 3
	_expect(problems, is_equal_approx(Finance.natural_risk_multiplier(), 0.0),
		"remonty 3 wyłącza naturalne awarie")


static func _check_save_compatibility(problems: Array[String]) -> void:
	_reset_state()
	Game.budget = {"biezace": 3, "remonty": 3, "infrastruktura": 3,
		"duszpasterstwo": 3, "ludzie": 3}
	Game.budget_reservations = {"remonty": {"investment": "roof", "until_day": 99}}
	SaveGame.apply(Game, {"day": 4, "bank_log": [{"day": 2.0, "text": "Stary wpis", "amount": -20.0}]})
	_expect(problems, Game.budget == Finance.default_budget() and Game.budget_reservations.is_empty(),
		"stary zapis dostaje domyślny budżet bez rezerwacji")
	_expect(problems, str(Game.bank_log[0].get("category", "")) == "inne",
		"stary wpis bankowy dostaje kategorię inne")

	var encoded := JSON.stringify({"day": 5, "budget": {"biezace": -1, "remonty": 0,
		"infrastruktura": 2, "duszpasterstwo": 7, "obca": 3},
		"budget_reservations": {"remonty": {"investment": "roof", "until_day": 12.0, "min_level": 3.0}}})
	var parsed: Dictionary = JSON.parse_string(encoded)
	SaveGame.apply(Game, parsed)
	_expect(problems, Game.budget == {"biezace": 0, "remonty": 1, "infrastruktura": 2,
		"duszpasterstwo": 3, "ludzie": 1}, "nowy zapis normalizuje poziomy i uzupełnia kategorię")
	var reservation: Dictionary = Game.budget_reservations.get("remonty", {})
	_expect(problems, typeof(reservation.get("until_day")) == TYPE_INT
		and int(reservation.get("until_day", 0)) == 12 and int(reservation.get("min_level", 0)) == 1,
		"nowa rezerwacja wraca z JSON jako znormalizowane liczby całkowite")
	SaveGame.apply(Game, {"day": 5, "budget_reservations": {
		"remonty": {"investment": "heating", "until_day": 12}}})
	_expect(problems, Game.budget_reservations.is_empty(),
		"zapis nie przyjmuje sfałszowanej rezerwacji inwestycji spoza remontów")
	SaveGame.apply(Game, {"day": 12, "budget_reservations": {
		"remonty": {"investment": "roof", "until_day": 12}}})
	_expect(problems, Game.budget_reservations.is_empty(), "wygasła rezerwacja nie wraca z zapisu")


static func _reset_state() -> void:
	Game.day = 1
	Game.money = 12000
	Game.reputation = 50
	Game.condition = 50
	Game.trad = 50
	Game.young = 50
	# Te scenariusze izolują budżet od osobno testowanych działań wpływowych grup.
	Groups.reset(Game, 50, 50)
	for group_id in Game.groups:
		Game.groups[group_id]["size"] = 100
	Groups.refresh()
	Game.curia = 50
	Game.week_income = 0
	Game.week_expenses = 0
	Game.budget = Finance.default_budget()
	Game.budget_reservations = {}
	Game.pending_investments = []
	Game.built = []
	Game.scheduled = []
	Game.breakdowns = []
	Game.breakdown_since = {}
	Game.pending_repairs = []
	Game.bank_log = []
	Game.log_lines = []


static func _snapshot() -> Dictionary:
	var result := {}
	for key in SaveGame.INTS + SaveGame.FLOATS + SaveGame.STRINGS + SaveGame.DICTS + SaveGame.ARRAYS \
		+ ["_mass_started_hour", "_cut_start"]:
		var value: Variant = Game.get(key)
		result[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	return result


static func _restore(snapshot: Dictionary) -> void:
	for key in snapshot:
		Game.set(key, snapshot[key])


static func _expect(problems: Array[String], condition: bool, message: String) -> void:
	if not condition:
		problems.append(message)
