class_name SaveGame
## Jeden slot zapisu. Zapisujemy tylko stan poranka, bo zapis powstaje przy przejściu
## do nowego dnia. Dzięki temu nie trzeba odtwarzać pozycji gracza, trwającej scenki
## ani otwartego okna: po wczytaniu gra zawsze zaczyna się o 7:00 na plebanii.

const PATH := "user://parafia.save"
const VERSION := 1

const INTS := ["day", "start_unix", "money", "reputation", "condition", "trad", "young", "curia",
	"week_income", "week_expenses", "meals_today", "apples_picked", "visit_index", "respect",
	"funerals_pending", "funeral_deadline", "quiet_days", "_last_curia_mail", "_last_bank_alert"]
const FLOATS := ["energy"]
const STRINGS := ["deceased_name"]
const DICTS := ["done_today", "breakdown_since", "event_cooldowns", "media_recent"]
const ARRAYS := ["scheduled", "pending_investments", "fired_events", "log_lines", "built", "seen",
	"masses_done", "masses_missed", "sunday_hours", "weekday_hours", "breakdowns", "pending_repairs",
	"phone_inbox", "bank_log"]
## Tablice, w których muszą siedzieć liczby całkowite: JSON oddaje wszystko jako zmiennoprzecinkowe.
const INT_ARRAYS := ["masses_done", "masses_missed", "sunday_hours", "weekday_hours"]
## To samo dla słowników: dzień początku awarii i dzień końca karencji wydarzenia.
const INT_DICTS := ["breakdown_since", "event_cooldowns", "media_recent"]
## Pola liczbowe w wiadomościach telefonu i historii konta - JSON oddaje je jako float,
## a porównujemy je z numerem dnia, więc muszą wrócić jako liczby całkowite.
const ITEM_INTS := {"phone_inbox": ["day", "due", "answered", "deadline"],
	"bank_log": ["day", "amount"]}


static func has_save() -> bool:
	return FileAccess.file_exists(PATH)


static func write(game: Node) -> bool:
	var data := {"version": VERSION}
	for key in INTS + FLOATS + STRINGS + DICTS + ARRAYS:
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
	for key in STRINGS:
		if data.has(key):
			game.set(key, str(data[key]))
	for key in DICTS:
		if data.has(key) and typeof(data[key]) == TYPE_DICTIONARY:
			game.set(key, (data[key] as Dictionary).duplicate(true))
	for key in ARRAYS:
		if data.has(key) and typeof(data[key]) == TYPE_ARRAY:
			game.set(key, (data[key] as Array).duplicate(true))
	# JSON nie zna liczb całkowitych, więc godziny, terminy i skutki wracają jako zmiennoprzecinkowe
	for key in INT_ARRAYS:
		var values: Array = game.get(key)
		for i in values.size():
			values[i] = int(values[i])
	for key in INT_DICTS:
		var dict: Dictionary = game.get(key)
		for k in dict:
			dict[k] = int(dict[k])
	# wiadomości telefonu i historia konta: dzień, termin i kwota muszą być całkowite
	for key in ITEM_INTS:
		var items: Array = game.get(key)
		for item in items:
			for field in ITEM_INTS[key]:
				if item.has(field):
					item[field] = int(item[field])
	for item in game.scheduled:
		item["day"] = int(item["day"])
		# skutek odroczony ma dwie wersje, obie z liczbami całkowitymi
		for field in ["effects", "else_effects"]:
			var effects: Dictionary = item.get(field, {})
			for key in effects:
				effects[key] = int(effects[key])


static func wipe() -> void:
	if has_save():
		DirAccess.remove_absolute(PATH)
