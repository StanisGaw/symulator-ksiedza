class_name Finance
## Pieniądze parafii: budżet kategorii, inwestycje, prognoza i rozliczenie tygodnia.
##
## Stan siedzi w autoloadzie Game, bo to on się zapisuje. Ten moduł jest jedynym
## miejscem, które interpretuje poziomy budżetu i finansowe reguły inwestycji.

const BANK_LOG_MAX := 40
const INTEREST_RATE := 0.02
const DEBT_CURIA_DELTA := -3
const RESERVATION_DAYS := 14

const BUDGET_CATEGORIES := {
	"biezace": {
		"label": "Bieżące wydatki", "costs": [0, 1800, 2400, 3000],
		"effects": [{"condition": -4}, {"condition": -2}, {"condition": -1}, {"condition": 0}],
		"notes": [
			"Rachunki czekają, a budynki niszczeją szybko: stan budynków -4 i ryzyko naturalnych awarii x1,5.",
			"Najpilniejsze rachunki są opłacone. Stan budynków -2.",
			"Jest zapas na drobną konserwację. Stan budynków -1.",
			"Pełne utrzymanie bieżące zatrzymuje zużycie budynków.",
		],
	},
	"remonty": {
		"label": "Remonty", "costs": [0, 800, 1200, 1600],
		"effects": [{"condition": 0}, {"condition": 1}, {"condition": 2}, {"condition": 2}],
		"notes": [
			"Brak zaplanowanych remontów. Stan budynków bez poprawy.",
			"Najpilniejsze usterki są usuwane. Stan budynków +1.",
			"Regularne prace poprawiają stan budynków o 2.",
			"Stała ekipa remontowa poprawia stan budynków o 2 i wyłącza naturalne awarie.",
		],
	},
	"infrastruktura": {
		"label": "Infrastruktura parafii", "costs": [0, 600, 900, 1200],
		"effects": [{"reputation": -1}, {"reputation": 0}, {"reputation": 1}, {"reputation": 2}],
		"notes": [
			"Otoczenie parafii jest zaniedbane. Reputacja -1.",
			"Podstawowa infrastruktura działa bez zmiany reputacji.",
			"Parafia dba o swoje otoczenie. Reputacja +1.",
			"Infrastruktura jest wizytówką parafii. Reputacja +2.",
		],
	},
	"duszpasterstwo": {
		"label": "Działalność duszpasterska", "costs": [0, 600, 900, 1200],
		"effects": [{"young": -1}, {"young": 0}, {"young": 1}, {"young": 2}],
		"notes": [
			"Nie ma środków na działalność. Młode rodziny -1.",
			"Podstawowe spotkania odbywają się bez zmiany nastrojów.",
			"Regularna działalność dociera do młodych rodzin. Młode rodziny +1.",
			"Bogaty program parafii angażuje młode rodziny. Młode rodziny +2.",
		],
	},
	"ludzie": {
		"label": "Ludzie i pensje", "costs": [0, 400, 600, 800],
		"effects": [{"trad": -1}, {"trad": 0}, {"trad": 1}, {"trad": 2}],
		"notes": [
			"Brakuje ludzi do stałych obowiązków. Tradycjonaliści -1.",
			"Najważniejsze dyżury są obsadzone bez zmiany nastrojów.",
			"Parafianie widzą sprawną pracę zespołu. Tradycjonaliści +1.",
			"Pełna obsada dba o porządek i zwyczaje. Tradycjonaliści +2.",
		],
	},
}

const INVESTMENTS := {
	"roof": {"label": "Remont dachu", "cost": 8000, "days": 3, "effects": {"condition": 30},
		"purchase_effects": {"young": -2}, "category": "remonty", "reserves": true,
		"choice_note": "Dach zajmie budżet remontów na 14 dni. Młode rodziny -2, bo salka zostaje odłożona.",
		"builds": "Nowa połać dachu nad nawą, bez łat i plandeki. Znika zaciek i wiadro w kościele.",
		"unlocks": "Stan budynków +30 i koniec strat na przeciekach.", "weekly": 0},
	"hall": {"label": "Salka młodzieżowa", "cost": 7000, "days": 4,
		"effects": {"young": 10, "reputation": 2}, "purchase_effects": {"trad": -2},
		"category": "remonty", "reserves": true,
		"choice_note": "Salka zajmie budżet remontów na 14 dni. Tradycjonaliści -2, bo dach zostaje odłożony.",
		"builds": "Wyposażenie i zajęcia w istniejącej salce; bez budowy osobnego gmachu.",
		"unlocks": "Po 4 dniach: młode rodziny +10 i reputacja +2.", "weekly": 0},
	"heating": {"label": "Ogrzewanie w kościele", "cost": 5000, "days": 2,
		"effects": {"trad": 8, "condition": 5}, "category": "infrastruktura",
		"builds": "Grzejniki wzdłuż zachodniej ściany, komin z dymem za kościołem, cieplejsze światło.",
		"unlocks": "Tradycjonaliści +8 i pełna frekwencja zimą.", "weekly": 0},
	"sound": {"label": "Nagłośnienie", "cost": 3000, "days": 1, "effects": {"young": 6},
		"category": "infrastruktura",
		"builds": "Kolumny na wieży i przy prezbiterium, mikrofon przy ołtarzu.",
		"unlocks": "Słychać kazanie w ostatniej ławce. Młode rodziny +6.", "weekly": 0},
	"cemetery": {"label": "Cmentarz parafialny", "cost": 12000, "days": 5,
		"effects": {"reputation": 3, "trad": 4}, "category": "infrastruktura",
		"builds": "Cmentarz za kościołem: mur, brama, żwirowa alejka, kwatery z nagrobkami, kaplica cmentarna.",
		"unlocks": "Pogrzeby w parafii zamiast u sąsiada: ofiara 800–1 200 zł i szacunek za każdy. Do tego opłaty za miejsca.",
		"weekly": 150, "expected_weekly": 1700,
		"yield_note": "150 zł opłat tygodniowo plus około 1 000 zł za pogrzeb, średnio półtora pogrzebu w tygodniu"},
	"festyn": {"label": "Festyn parafialny", "cost": 2500, "days": 4,
		"effects": {"young": 8, "reputation": 4, "trad": -3}, "category": "duszpasterstwo", "repeatable": true,
		"builds": "Na razie nic trwałego. Namioty, grill i tłum na placu dojdą razem z rozbudową terenu.",
		"unlocks": "Młode rodziny +8, reputacja +4, tradycjonaliści -3.", "weekly": 0},
	"curia_gift": {"label": "Przelew do kurii", "cost": 1500, "days": 0,
		"effects": {"curia": 6}, "category": "inne", "repeatable": true,
		"builds": "Nic. Pieniądze idą do diecezji.",
		"unlocks": "Kuria +6. Kuria pamięta ofiarodawców.", "weekly": 0},
}


static func default_budget() -> Dictionary:
	return {"biezace": 1, "remonty": 1, "infrastruktura": 1, "duszpasterstwo": 1, "ludzie": 1}


## Dane z JSON mogą wrócić jako float albo zawierać niepełny stary plan.
static func normalize_budget(value: Dictionary) -> Dictionary:
	var result := default_budget()
	for id in BUDGET_CATEGORIES:
		if value.has(id) and (typeof(value[id]) == TYPE_INT or typeof(value[id]) == TYPE_FLOAT):
			result[id] = clampi(int(value[id]), 0, 3)
	return result


static func _valid_plan(plan: Dictionary) -> bool:
	if plan.size() != BUDGET_CATEGORIES.size():
		return false
	for id in BUDGET_CATEGORIES:
		if not plan.has(id) or typeof(plan[id]) != TYPE_INT:
			return false
		var level: int = plan[id]
		if level < 0 or level > 3:
			return false
	return true


static func category_cost(id: String, level: int) -> int:
	if not BUDGET_CATEGORIES.has(id) or level < 0 or level > 3:
		return -1
	return int((BUDGET_CATEGORIES[id] as Dictionary)["costs"][level])


static func weekly_expenses(plan: Dictionary = {}) -> int:
	var selected: Dictionary = Game.budget if plan.is_empty() else plan
	if not _valid_plan(selected):
		return -1
	var total := 0
	for id in BUDGET_CATEGORIES:
		total += category_cost(id, int(selected[id]))
	return total


static func _days_to_monday() -> int:
	for offset in range(1, 8):
		if Calendar.is_monday(Game.day + offset):
			return offset
	return 7


## Konserwatywna prognoza: tylko pewny dochód inwestycji, bez tacy, ofiar, zdarzeń
## i kosztów awarii. Saldo obejmuje już odsetki od debetu w najbliższy poniedziałek.
static func forecast(plan: Dictionary = {}, expense: int = 0) -> Dictionary:
	var selected: Dictionary = Game.budget if plan.is_empty() else plan
	var costs := weekly_expenses(selected)
	if expense < 0 or costs < 0:
		return {}
	var income := weekly_yield()
	var before_interest := Game.money - expense + income - costs
	var interest := int(ceil(absf(float(before_interest)) * INTEREST_RATE)) if before_interest < 0 else 0
	return {"balance": before_interest - interest, "costs": costs, "income": income,
		"interest": interest, "curia_delta": DEBT_CURIA_DELTA if before_interest < 0 else 0,
		"days": _days_to_monday()}


static func needs_confirmation(expense: int = 0, plan: Dictionary = {}) -> bool:
	var result := forecast(plan, expense)
	return result.is_empty() or int(result["balance"]) < 0


static func _active_reservation(category: String) -> Dictionary:
	var reservation: Variant = Game.budget_reservations.get(category, {})
	if typeof(reservation) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = reservation
	if typeof(data.get("until_day", -1)) not in [TYPE_INT, TYPE_FLOAT]:
		return {}
	if Game.day >= int(data.get("until_day", -1)):
		return {}
	return data


static func reservation_text(id: String = "remonty") -> String:
	var reservation := _active_reservation(id)
	if reservation.is_empty():
		return ""
	var investment_id := str(reservation.get("investment", ""))
	var label := str((INVESTMENTS.get(investment_id, {}) as Dictionary).get("label", investment_id))
	var left := maxi(0, int(reservation.get("until_day", Game.day)) - Game.day)
	return "%s zajmuje kategorię jeszcze przez %s; wymagany poziom co najmniej %d." % [
		label, Game.days_text(left), int(reservation.get("min_level", 1))]


static func set_budget(plan: Dictionary, confirmed: bool = false) -> bool:
	if not _valid_plan(plan):
		return false
	var reservation := _active_reservation("remonty")
	if not reservation.is_empty() and int(plan["remonty"]) < int(reservation.get("min_level", 1)):
		return false
	if needs_confirmation(0, plan) and not confirmed:
		return false
	Game.budget = plan.duplicate(true)
	Game.add_log("Ustalono budżet tygodnia: %s zł." % Game.money_text(weekly_expenses(plan)))
	Game.state_changed.emit()
	return true


## Dopisuje operację do historii konta. Kategoria jest jawna także dla starych wywołań.
static func bank_entry(text: String, amount: int, category: String = "inne") -> void:
	var safe_category := category if category != "" else "inne"
	Game.bank_log.push_front({"day": Game.day, "text": text, "amount": amount, "category": safe_category})
	if Game.bank_log.size() > BANK_LOG_MAX:
		Game.bank_log.resize(BANK_LOG_MAX)


static func investment_block_reason(id: String) -> String:
	if not INVESTMENTS.has(id):
		return "Nieznana inwestycja."
	var def: Dictionary = INVESTMENTS[id]
	if not def.get("repeatable", false) and Game.built.has(id):
		return "Ta inwestycja jest już ukończona."
	if Game.pending_investments.has(id):
		return "Prace nad tą inwestycją już trwają."
	var category := str(def.get("category", "inne"))
	if def.get("reserves", false):
		var budget := normalize_budget(Game.budget)
		if int(budget[category]) < 1:
			return "Najpierw ustaw budżet „%s” co najmniej na poziom 1." % (BUDGET_CATEGORIES[category] as Dictionary)["label"]
		var reservation := _active_reservation(category)
		if not reservation.is_empty() and str(reservation.get("investment", "")) != id:
			return reservation_text(category)
	if Game.money < int(def["cost"]):
		return "Na koncie brakuje pieniędzy na tę inwestycję."
	return ""


static func can_invest(id: String) -> bool:
	return investment_block_reason(id) == ""


static func payback_weeks(id: String) -> int:
	if not INVESTMENTS.has(id):
		return 0
	var def: Dictionary = INVESTMENTS[id]
	var weekly := int(def.get("expected_weekly", def.get("weekly", 0)))
	if weekly <= 0:
		return 0
	return int(ceil(float(def["cost"]) / float(weekly)))


static func weekly_yield() -> int:
	var total := 0
	for id in Game.built:
		if INVESTMENTS.has(id):
			total += int((INVESTMENTS[id] as Dictionary).get("weekly", 0))
	return total


static func invest(id: String, confirmed: bool = false) -> bool:
	var reason := investment_block_reason(id)
	if reason != "":
		Game.toast.emit(reason)
		return false
	var def: Dictionary = INVESTMENTS[id]
	var cost := int(def["cost"])
	if needs_confirmation(cost) and not confirmed:
		return false
	var category := str(def.get("category", "inne"))
	var purchase_effects: Dictionary = (def.get("purchase_effects", {}) as Dictionary).duplicate(true)
	purchase_effects["money"] = -cost
	Parish.apply_effects(purchase_effects, str(def["label"]), category)
	if def.get("reserves", false):
		Game.budget_reservations[category] = {
			"investment": id, "until_day": Game.day + RESERVATION_DAYS, "min_level": 1}
	var days := int(def["days"])
	if days == 0:
		Parish.apply_effects(def["effects"])
		Game.toast.emit("%s: %s" % [def["label"], Parish.effects_text(def["effects"])])
		Game.add_log("%s (%d zł)." % [def["label"], cost])
	else:
		Game.pending_investments.append(id)
		Game.scheduled.append({"day": Game.day + days,
			"text": "%s: prace zakończone. %s." % [def["label"], Parish.effects_text(def["effects"])],
			"effects": def["effects"], "invest": id})
		Game.toast.emit("%s: zlecone, gotowe za %d dni." % [def["label"], days])
		Game.add_log("Zlecono: %s (%d zł). %s" % [def["label"], cost, def.get("choice_note", "")])
	Game.state_changed.emit()
	return true


static func natural_risk_multiplier() -> float:
	var budget := normalize_budget(Game.budget)
	if int(budget["remonty"]) == 3:
		return 0.0
	if int(budget["biezace"]) == 0:
		return 1.5
	return 1.0


## Poniedziałkowe rozliczenie: każda kategoria ma osobny koszt, skutek i wpis bankowy.
static func weekly_settlement() -> Array[String]:
	var lines: Array[String] = []
	var plan := normalize_budget(Game.budget)
	Game.budget = plan
	var income_before := Game.week_income
	var expenses_before := Game.week_expenses
	var yield_total := weekly_yield()
	if yield_total > 0:
		Parish.apply_effects({"money": yield_total}, "Dochód z inwestycji", "inwestycje")
		lines.append("Stały dochód z inwestycji: +%s zł." % Game.money_text(yield_total))
	var budget_total := 0
	var settlement_effects: Dictionary = {}
	for id in BUDGET_CATEGORIES:
		var def: Dictionary = BUDGET_CATEGORIES[id]
		var level := int(plan[id])
		var cost := category_cost(id, level)
		budget_total += cost
		Parish.apply_effects({"money": -cost}, "Budżet: %s" % def["label"], id)
		for effect_id in def["effects"][level]:
			settlement_effects[effect_id] = int(settlement_effects.get(effect_id, 0)) + int(def["effects"][level][effect_id])
		lines.append("%s, poziom %d: -%s zł; %s. %s" % [
			def["label"], level, Game.money_text(cost), Parish.effects_text(def["effects"][level]), def["notes"][level]])
	# Sumowanie przed nałożeniem zachowuje wynik także przy granicach 0 i 100.
	Parish.apply_effects(settlement_effects)
	if Game.condition < 30:
		Parish.apply_effects({"reputation": -2})
		lines.append("Budynki niszczeją, parafianie to komentują. Reputacja -2.")
	var interest := 0
	if Game.money < 0:
		interest = int(ceil(absf(float(Game.money)) * INTEREST_RATE))
		Parish.apply_effects({"money": -interest}, "Odsetki od debetu", "odsetki")
		Parish.apply_effects({"curia": DEBT_CURIA_DELTA})
		lines.append("Konto na minusie: odsetki 2%% to %s zł, kuria %d." % [
			Game.money_text(interest), DEBT_CURIA_DELTA])
	lines.push_front("Rozliczenie tygodnia: wpływy %s zł, pozostałe wydatki %s zł, budżet %s zł." % [
		Game.money_text(income_before), Game.money_text(expenses_before), Game.money_text(budget_total)])
	lines.append("Stan konta po rozliczeniu: %s zł." % Game.money_text(Game.money))
	Game.week_income = 0
	Game.week_expenses = 0
	return lines
