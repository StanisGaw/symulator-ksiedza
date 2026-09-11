class_name Calendar
## Prawdziwa data, okres liturgiczny i święta. Gra zaczyna się w dniu, w którym
## zaczęto nową grę, i toczy się bez końca: rok liturgiczny wraca co roku,
## a święta ruchome liczą się z Wielkanocy.

const DAY_SECONDS := 86400

const WEEKDAYS := ["Niedziela", "Poniedziałek", "Wtorek", "Środa", "Czwartek", "Piątek", "Sobota"]
const MONTHS := ["stycznia", "lutego", "marca", "kwietnia", "maja", "czerwca",
	"lipca", "sierpnia", "września", "października", "listopada", "grudnia"]

const ADVENT := "Adwent"
const CHRISTMAS := "Boże Narodzenie"
const LENT := "Wielki Post"
const EASTER := "Wielkanoc"
const ORDINARY := "Okres zwykły"

## Święta stałe: [miesiąc, dzień] -> opis. „attendance” i „taca” to mnożniki,
## „from_hour” ogranicza je do mszy o właściwej porze, „holy_day” to święto nakazane.
const FIXED_FEASTS := {
	"1-1": {"name": "Nowy Rok, Świętej Bożej Rodzicielki", "attendance": 2.0, "taca": 1.3, "holy_day": true,
		"note": "Święto nakazane, choć połowa parafii spała trzy godziny."},
	"1-6": {"name": "Trzech Króli", "attendance": 2.5, "taca": 1.5, "holy_day": true,
		"note": "Orszak przejdzie przez wieś, kreda i kadzidło rozejdą się po mszy."},
	"2-2": {"name": "Matki Bożej Gromnicznej", "attendance": 1.8, "taca": 1.2,
		"note": "Gromnice przyniosą przede wszystkim najstarsi."},
	"5-3": {"name": "NMP Królowej Polski", "attendance": 1.8, "taca": 1.2, "holy_day": true,
		"note": "Flagi na plebanii i na maszcie przy gablocie."},
	"6-29": {"name": "Odpust parafialny", "attendance": 3.0, "taca": 2.0,
		"note": "Dzień patrona parafii. Przyjadą księża z dekanatu i będą patrzeć."},
	"8-15": {"name": "Wniebowzięcie NMP", "attendance": 2.0, "taca": 1.3, "holy_day": true,
		"note": "Święcenie ziół i kwiatów."},
	"11-1": {"name": "Wszystkich Świętych", "attendance": 3.0, "taca": 1.8, "holy_day": true,
		"note": "Cmentarz pełny od rana. Wrócą ludzie, których nie ma tu przez cały rok."},
	"11-2": {"name": "Dzień Zaduszny", "attendance": 2.0, "taca": 1.5,
		"note": "Wypominki, procesja na cmentarz."},
	"12-6": {"name": "Świętego Mikołaja", "attendance": 1.2, "taca": 1.1,
		"note": "Dzieci liczą na prezenty, rodzice na to, że ksiądz o nich wspomni."},
	"12-8": {"name": "Niepokalane Poczęcie NMP", "attendance": 2.0, "taca": 1.4, "holy_day": true,
		"note": "Święto nakazane. Kościół pełny nawet w poniedziałek."},
	"12-24": {"name": "Wigilia i Pasterka", "attendance": 4.0, "taca": 2.2, "from_hour": 20,
		"note": "Noc, na którą czeka cała parafia. Przyjdą nawet ci, których nie widziałeś od pogrzebu."},
	"12-25": {"name": "Boże Narodzenie", "attendance": 3.0, "taca": 2.0, "holy_day": true,
		"note": "Pierwszy dzień świąt. Kościół pełny, wszyscy w nowych kurtkach."},
	"12-26": {"name": "Świętego Szczepana", "attendance": 2.2, "taca": 1.5, "holy_day": true,
		"note": "Drugi dzień świąt. Taca jest dziś przeznaczona na uczelnie katolickie."},
	"12-31": {"name": "Sylwester, nabożeństwo dziękczynne", "attendance": 1.4, "taca": 1.2,
		"note": "Podsumowanie roku przy pustawym kościele."},
}

## Święta ruchome: przesunięcie w dniach względem Niedzieli Wielkanocnej.
const MOVABLE_FEASTS := {
	-46: {"name": "Środa Popielcowa", "attendance": 1.8, "taca": 1.0,
		"note": "Popiół na głowy. Przyjdą nawet ci, którzy nie chodzą do spowiedzi."},
	-7: {"name": "Niedziela Palmowa", "attendance": 2.2, "taca": 1.3,
		"note": "Palmy, konkurs na najwyższą, dzieci w kolejce."},
	-3: {"name": "Wielki Czwartek", "attendance": 1.8, "taca": 1.1,
		"note": "Msza Wieczerzy Pańskiej, obmycie nóg, ciemnica."},
	-2: {"name": "Wielki Piątek", "attendance": 2.5, "taca": 1.0,
		"note": "Adoracja przy grobie. Taca idzie na Ziemię Świętą, nie do parafii."},
	-1: {"name": "Wielka Sobota", "attendance": 2.2, "taca": 1.2,
		"note": "Święcenie pokarmów przez cały dzień, koszyki od rana."},
	0: {"name": "Niedziela Wielkanocna, Rezurekcja", "attendance": 4.0, "taca": 2.2,
		"note": "Największy dzień w roku. Procesja, dzwony, pełny kościół."},
	1: {"name": "Poniedziałek Wielkanocny", "attendance": 2.0, "taca": 1.3, "holy_day": true,
		"note": "Śmigus i msza, w tej kolejności zależnie od wieku."},
	60: {"name": "Boże Ciało", "attendance": 2.5, "taca": 1.4, "holy_day": true,
		"note": "Procesja do czterech ołtarzy. Cała wieś patrzy, jak to zorganizowałeś."},
}


## Północ dnia, w którym zaczęto grę, w czasie lokalnym.
static func today_start_unix() -> int:
	var now := Time.get_datetime_dict_from_system()
	now["hour"] = 0
	now["minute"] = 0
	now["second"] = 0
	return int(Time.get_unix_time_from_datetime_dict(now))


static func date(day: int) -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(Game.start_unix + (day - 1) * DAY_SECONDS)


static func day_name(day: int) -> String:
	return WEEKDAYS[int(date(day)["weekday"])]


## „1 grudnia”
static func short_date(day: int) -> String:
	var d := date(day)
	return "%d %s" % [int(d["day"]), MONTHS[int(d["month"]) - 1]]


## „Poniedziałek, 1 grudnia”
static func date_text(day: int) -> String:
	return "%s, %s" % [day_name(day), short_date(day)]


static func is_sunday(day: int) -> bool:
	return int(date(day)["weekday"]) == 0


static func is_monday(day: int) -> bool:
	return int(date(day)["weekday"]) == 1


# ---------- święta ruchome ----------

## Niedziela Wielkanocna danego roku, algorytmem Meeusa i Jonesa.
static func easter(year: int) -> Dictionary:
	var a := year % 19
	var b := year / 100
	var c := year % 100
	var d := b / 4
	var e := b % 4
	var f := (b + 8) / 25
	var g := (b - f + 1) / 3
	var h := (19 * a + b - d - g + 15) % 30
	var i := c / 4
	var k := c % 4
	var l := (32 + 2 * e + 2 * i - h - k) % 7
	var m := (a + 11 * h + 22 * l) / 451
	var month := (h + l - 7 * m + 114) / 31
	var dom := ((h + l - 7 * m + 114) % 31) + 1
	return {"year": year, "month": month, "day": dom}


static func _midnight(dict: Dictionary) -> int:
	var d := dict.duplicate()
	d["hour"] = 0
	d["minute"] = 0
	d["second"] = 0
	return int(Time.get_unix_time_from_datetime_dict(d))


## Ile dni dzieli dany dzień gry od Niedzieli Wielkanocnej jego roku.
static func days_from_easter(day: int) -> int:
	var d := date(day)
	var e := _midnight(easter(int(d["year"])))
	return int(round(float(_midnight(d) - e) / float(DAY_SECONDS)))


## Pierwsza niedziela Adwentu: czwarta niedziela przed Bożym Narodzeniem.
static func advent_start(year: int) -> int:
	var christmas := {"year": year, "month": 12, "day": 25}
	var weekday := int(Time.get_datetime_dict_from_unix_time(_midnight(christmas))["weekday"])
	# cofamy się do niedzieli przed Bożym Narodzeniem, potem o trzy tygodnie
	var back := 7 if weekday == 0 else weekday
	return _midnight(christmas) - (back + 21) * DAY_SECONDS


# ---------- okres liturgiczny ----------

static func season(day: int) -> String:
	var d := date(day)
	var today := _midnight(d)
	var year := int(d["year"])
	var from_easter := days_from_easter(day)
	if from_easter >= -46 and from_easter <= -1:
		return LENT
	if from_easter >= 0 and from_easter <= 49:
		return EASTER
	var christmas := _midnight({"year": year, "month": 12, "day": 25})
	# Adwent zaczyna się pod koniec listopada, więc liczy się data, a nie sam grudzień
	if today >= advent_start(year) and today < christmas:
		return ADVENT
	if today >= christmas:
		return CHRISTMAS
	if int(d["month"]) == 1 and int(d["day"]) <= 6:
		return CHRISTMAS
	return ORDINARY


## Ile świec pali się na wieńcu adwentowym: jedna za każdą minioną niedzielę Adwentu.
static func advent_candles(day: int) -> int:
	if season(day) != ADVENT:
		return 0
	var d := date(day)
	var passed := int(floor(float(_midnight(d) - advent_start(int(d["year"]))) / float(DAY_SECONDS * 7)))
	return clampi(passed + 1, 1, 4)


# ---------- pory roku ----------

## Do klimatu, nie do liturgii: zima, przedwiośnie, lato, jesień.
static func time_of_year(day: int) -> String:
	match int(date(day)["month"]):
		12, 1, 2:
			return "zima"
		3, 4, 5:
			return "wiosna"
		6, 7, 8:
			return "lato"
		_:
			return "jesień"


static func is_snowy(day: int) -> bool:
	var month := int(date(day)["month"])
	return month == 12 or month == 1 or month == 2


# ---------- święta ----------

static func feast(day: int) -> Dictionary:
	var moved: Dictionary = MOVABLE_FEASTS.get(days_from_easter(day), {})
	if not moved.is_empty():
		return moved
	var d := date(day)
	return FIXED_FEASTS.get("%d-%d" % [int(d["month"]), int(d["day"])], {})


static func feast_name(day: int) -> String:
	return str(feast(day).get("name", ""))


## Mnożniki święta liczą się tylko dla mszy o właściwej porze: na Pasterkę przychodzi
## cała parafia, ale na poranną mszę 24 grudnia już nie.
static func _applies(day: int, start_minutes: float) -> bool:
	var f := feast(day)
	if f.is_empty():
		return false
	return start_minutes >= float(f.get("from_hour", 0)) * 60.0


static func attendance_multiplier(day: int, start_minutes: float) -> float:
	return float(feast(day).get("attendance", 1.0)) if _applies(day, start_minutes) else 1.0


static func taca_multiplier(day: int, start_minutes: float) -> float:
	return float(feast(day).get("taca", 1.0)) if _applies(day, start_minutes) else 1.0


static func is_holy_day(day: int) -> bool:
	return bool(feast(day).get("holy_day", false))


## Ile dni do najbliższego święta, licząc od jutra. Zero, gdy w ciągu dwóch miesięcy nic nie ma.
static func days_to_next_feast(day: int, limit: int = 60) -> int:
	for k in range(1, limit + 1):
		if not feast(day + k).is_empty():
			return k
	return 0


## Roraty: msza w dzień powszedni Adwentu odprawiona przed ósmą rano.
static func is_roraty(day: int, minutes: float) -> bool:
	return season(day) == ADVENT and not is_sunday(day) and minutes < 8 * 60
