class_name Finance
## Pieniądze parafii: stałe koszty, inwestycje, rozliczenie tygodnia i historia konta.
##
## Stan (money, built, pending_investments, bank_log, week_income, week_expenses) siedzi
## dalej w autoloadzie Game, bo to on się zapisuje. Tutaj jest tylko to, co z tym stanem
## robimy. Dzięki temu budżet w kategoriach (wydanie 2.3) rośnie w tym pliku, a nie
## w game.gd.

const WEEKLY_EXPENSES := 4200
const BANK_LOG_MAX := 40

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


## Dopisuje operację do historii konta w telefonie. Trzymamy ostatnie BANK_LOG_MAX pozycji,
## bo to podgląd, a nie księgowość.
static func bank_entry(text: String, amount: int) -> void:
	Game.bank_log.push_front({"day": Game.day, "text": text, "amount": amount})
	if Game.bank_log.size() > BANK_LOG_MAX:
		Game.bank_log.resize(BANK_LOG_MAX)


static func can_invest(id: String) -> bool:
	var def: Dictionary = INVESTMENTS[id]
	if not def.get("repeatable", false) and Game.built.has(id):
		return false
	return Game.money >= def["cost"] and not Game.pending_investments.has(id)


## Ile tygodni zwraca się inwestycja z samego stałego dochodu. Zero, gdy nie daje pieniędzy.
static func payback_weeks(id: String) -> int:
	var def: Dictionary = INVESTMENTS[id]
	# do zwrotu liczy się cały spodziewany dochód, nie tylko stała opłata
	var weekly := int(def.get("expected_weekly", def.get("weekly", 0)))
	if weekly <= 0:
		return 0
	return int(ceil(float(def["cost"]) / float(weekly)))


## Stały dochód z ukończonych inwestycji, doliczany przy rozliczeniu tygodnia.
static func weekly_yield() -> int:
	var total := 0
	for id in Game.built:
		if INVESTMENTS.has(id):
			total += int(INVESTMENTS[id].get("weekly", 0))
	return total


static func invest(id: String) -> void:
	if not can_invest(id):
		Game.toast.emit("Nie stać parafii albo prace już trwają.")
		return
	var def: Dictionary = INVESTMENTS[id]
	Parish.apply_effects({"money": -def["cost"]})
	if def["days"] == 0:
		Parish.apply_effects(def["effects"])
		Game.toast.emit("%s: %s" % [def["label"], Parish.effects_text(def["effects"])])
		Game.add_log("%s (%d zł)." % [def["label"], def["cost"]])
	else:
		Game.pending_investments.append(id)
		Game.scheduled.append({"day": Game.day + def["days"], "text": "%s: prace zakończone. %s." % [def["label"], Parish.effects_text(def["effects"])],
			"effects": def["effects"], "invest": id})
		Game.toast.emit("%s: zlecone, gotowe za %d dni." % [def["label"], def["days"]])
		Game.add_log("Zlecono: %s (%d zł)." % [def["label"], def["cost"]])
	Game.state_changed.emit()


## Poniedziałkowe rozliczenie tygodnia: stałe koszty, dochód z inwestycji i kary za to,
## czego nie widać na koncie (zaniedbane budynki, minus zauważony przez kurię).
static func weekly_settlement() -> Array[String]:
	var lines: Array[String] = []
	var expenses := WEEKLY_EXPENSES
	Game.money -= expenses
	var yield_total := weekly_yield()
	if yield_total > 0:
		# przez apply_effects, żeby dochód wszedł do wpływów tygodnia w raporcie i finansach
		Parish.apply_effects({"money": yield_total})
		lines.append("Opłaty i dochody z inwestycji: +%s zł." % Game.money_text(yield_total))
	lines.append("Rozliczenie tygodnia: taca i ofiary %s zł, wydatki %s zł, rachunki i pensje %s zł." % [
		Game.money_text(Game.week_income), Game.money_text(Game.week_expenses), Game.money_text(expenses)])
	lines.append("Stan konta: %s zł." % Game.money_text(Game.money))
	Game.condition = clampi(Game.condition - 2, 0, 100)
	if Game.money < 0:
		Game.curia = clampi(Game.curia - 3, 0, 100)
		lines.append("Konto na minusie. Kuria to widzi. Kuria -3.")
	if Game.condition < 30:
		Game.reputation = clampi(Game.reputation - 2, 0, 100)
		lines.append("Budynki niszczeją, parafianie to komentują. Reputacja -2.")
	Game.week_income = 0
	Game.week_expenses = 0
	return lines
