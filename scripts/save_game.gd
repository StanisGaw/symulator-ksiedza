class_name SaveGame
## Jeden slot zapisu. Zapisujemy tylko stan poranka, bo zapis powstaje przy przejściu
## do nowego dnia. Dzięki temu nie trzeba odtwarzać pozycji gracza, trwającej scenki
## ani otwartego okna: po wczytaniu gra zawsze zaczyna się o 7:00 na plebanii.

const PATH := "user://parafia.save"
const VERSION := 1

const INTS := ["day", "start_unix", "money", "reputation", "condition", "trad", "young", "curia",
	"week_income", "week_expenses", "mass_hour", "rests_today", "visit_index"]
const FLOATS := ["energy"]
const DICTS := ["done_today"]
const ARRAYS := ["scheduled", "pending_investments", "fired_events", "log_lines", "built", "seen"]


static func has_save() -> bool:
	return FileAccess.file_exists(PATH)


static func write(game: Node) -> bool:
	var data := {"version": VERSION}
	for key in INTS + FLOATS + DICTS + ARRAYS:
		data[key] = game.get(key)
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Nie udało się zapisać gry: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true


## Zwraca zawartość zapisu albo pusty słownik, gdy zapisu nie ma, jest uszkodzony
## albo pochodzi z innej wersji formatu.
static func read() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Zapis gry jest uszkodzony.")
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != VERSION:
		push_warning("Zapis gry pochodzi z innej wersji i został pominięty.")
		return {}
	return data


## Pola nieznane są pomijane, brakujące zostawiają wartość domyślną. Dzięki temu
## dołożenie nowego pola stanu nie unieważnia zapisów z poprzedniej wersji gry.
static func apply(game: Node, data: Dictionary) -> void:
	for key in INTS:
		if data.has(key):
			game.set(key, int(data[key]))
	for key in FLOATS:
		if data.has(key):
			game.set(key, float(data[key]))
	for key in DICTS:
		if data.has(key) and typeof(data[key]) == TYPE_DICTIONARY:
			game.set(key, (data[key] as Dictionary).duplicate(true))
	for key in ARRAYS:
		if data.has(key) and typeof(data[key]) == TYPE_ARRAY:
			game.set(key, (data[key] as Array).duplicate(true))
	# JSON nie zna liczb całkowitych, więc terminy i skutki wracają jako zmiennoprzecinkowe
	for item in game.scheduled:
		item["day"] = int(item["day"])
		var effects: Dictionary = item.get("effects", {})
		for key in effects:
			effects[key] = int(effects[key])


static func wipe() -> void:
	if has_save():
		DirAccess.remove_absolute(PATH)
