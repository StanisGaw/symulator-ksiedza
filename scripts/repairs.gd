class_name Repairs
## Awarie jako stany trwałe: jak powstają, ile kosztują każdego ranka i jak się je naprawia.
##
## Definicje awarii siedzą w breakdowns.gd, lista trwających w Game.breakdowns.

## Nowa awaria. Zwraca false, gdy ta awaria już trwa albo identyfikator jest nieznany.
static func add(id: String, announce: bool = true) -> bool:
	if not Breakdowns.has(id) or Game.breakdowns.has(id):
		return false
	Game.breakdowns.append(id)
	Game.breakdown_since[id] = Game.day
	var def: Dictionary = Breakdowns.ALL[id]
	if announce:
		var text := "Awaria: %s. %s" % [def["label"], def.get("note", "")]
		Game.toast.emit(text)
		Game.add_log(text)
	if def.get("world", false):
		Game.world_changed.emit()
	Game.state_changed.emit()
	return true


static func clear(id: String) -> void:
	Game.breakdowns.erase(id)
	Game.breakdown_since.erase(id)
	Game.pending_repairs.erase(id)


static func can_repair(id: String) -> bool:
	if not Game.breakdowns.has(id) or Game.pending_repairs.has(id):
		return false
	return Game.money >= repair_cost(id)


## Naprawa idzie tą samą drogą co inwestycja: płacisz dziś, prace kończą się rano.
## Gdy wydatek oznacza debet przy najbliższym rozliczeniu, pierwsze wywołanie tylko
## prosi interfejs o potwierdzenie. Do tego czasu stan gry pozostaje bez zmian.
static func repair(id: String, confirmed: bool = false) -> bool:
	if not can_repair(id):
		Game.toast.emit("Nie stać parafii albo naprawa już trwa.")
		return false
	var def: Dictionary = Breakdowns.ALL[id]
	var cost := repair_cost(id)
	if Finance.needs_confirmation(cost) and not confirmed:
		return false
	Parish.apply_effects({"money": -cost}, "Naprawa: %s" % def["label"], "remonty")
	var days := int(def["days"])
	if days <= 0:
		Parish.apply_effects(def.get("fixed_effects", {}))
		clear(id)
		Game.toast.emit(str(def["fixed_text"]))
		Game.add_log(str(def["fixed_text"]))
		Game.world_changed.emit()
	else:
		Game.pending_repairs.append(id)
		Game.scheduled.append({"day": Game.day + days, "text": str(def["fixed_text"]),
			"effects": def.get("fixed_effects", {}), "repair": id})
		Game.toast.emit("%s: naprawa zlecona, gotowe za %s." % [def["label"], Game.days_text(days)])
		Game.add_log("Zlecono naprawę: %s (%s zł)." % [def["label"], Game.money_text(cost)])
	Game.state_changed.emit()
	return true


## Czynność odebrana przez awarię: bez samochodu nie pojedziesz do chorego.
## Zwraca komunikat dla gracza albo pusty napis, gdy nic nie blokuje.
static func blocked_by(activity_id: String) -> String:
	for id in Game.breakdowns:
		if str(Breakdowns.ALL[id].get("blocks", "")) == activity_id:
			return "%s. %s" % [Breakdowns.label(id), Breakdowns.ALL[id].get("note", "")]
	return ""


## Awarie kosztują co rano, dopóki trwają. To jest cena zwlekania z naprawą.
static func morning() -> Array[String]:
	var lines: Array[String] = []
	for id in Game.breakdowns:
		if Game.pending_repairs.has(id):
			continue
		var def: Dictionary = Breakdowns.ALL[id]
		Parish.apply_effects(def.get("daily", {}))
		var open_days := Game.day - int(Game.breakdown_since.get(id, Game.day))
		var suffix := "" if open_days < 3 else "  (%s bez naprawy)" % Game.days_text(open_days)
		lines.append(str(def["daily_text"]) + suffix)
	return lines


## Zaniedbana parafia psuje się sama. Im gorszy stan budynków, tym większa szansa,
## a pora roku decyduje, co konkretnie pada.
static func risk() -> Array[String]:
	var lines: Array[String] = []
	var chance := clampf((60.0 - float(Game.condition)) / 320.0, 0.0, 0.18)
	chance *= Finance.natural_risk_multiplier()
	if chance <= 0.0 or randf() >= chance:
		return lines
	var part := Calendar.time_of_year(Game.day)
	var pool: Array = []
	var total := 0.0
	for id in Breakdowns.ALL:
		if Game.breakdowns.has(id):
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
			if add(id, false):
				lines.append("Awaria: %s. %s" % [Breakdowns.label(id), Breakdowns.ALL[id].get("note", "")])
			break
	return lines


static func repair_cost(id: String) -> int:
	return Progression.investment_cost(int(Breakdowns.ALL[id]["cost"])) if Breakdowns.has(id) else 0
