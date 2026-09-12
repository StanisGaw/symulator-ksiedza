class_name ReleaseNotes
## Historia zmian produktu; potwierdzenie Web jest niezależne od slotu gry.

const STORAGE_KEY := "symulator-ksiedza.release-notes.seen-version"
const BASELINE := "2.3"
const RELEASES := [
	{"version": "2.3", "title": "Budżet tygodnia", "changes": [
		"W banku ustawisz pięć kategorii budżetu: bieżące wydatki, remonty, infrastrukturę, duszpasterstwo i ludzi. Każda ma poziomy 0–3 oraz opis skutków.",
		"Przed wydatkiem zobaczysz prognozę salda. Deficyt wymaga potwierdzenia; debet kosztuje 2% odsetek tygodniowo i obniża zaufanie kurii.",
		"Dach czy salka młodzieżowa? Wybrana inwestycja zajmuje budżet remontów na 14 dni i odkłada drugi projekt.",
		"Historia banku pokazuje kategorie operacji, a dłuższe raporty tygodnia można przewijać. Dotychczasowe zapisy gry nadal działają.",
	]},
	{"version": "2.3.1", "title": "Co nowego w parafii?", "changes": [
		"Po aktualizacji zobaczysz wszystkie zmiany od ostatnio przeczytanej wersji, także gdy ominiesz kilka wydań.",
		"Po potwierdzeniu zapamiętamy przeczytaną wersję w tej przeglądarce. Rozpoczęcie nowej gry nie kasuje tej informacji.",
	]},
	{"version": "2.4", "title": "Kuria patrzy w kalendarz", "changes": [
		"Nową grę zaczynasz jako wikary. Zmianę godzin mszy uzgadniasz z proboszczem — odpowiedź zajmuje dwa dni i kosztuje relację. Dotychczasowe zapisy zachowują samodzielność proboszcza.",
		"Życie religijne wynika z odprawionych mszy, spowiedzi i odwiedzin z ostatnich siedmiu dni. Samo bogactwo lub popularność go nie podnoszą.",
		"Co 13 tygodni kuria wystawia pisemną ocenę z pięciu składowych. Dwie dobre oceny otwierają awans, a kolejne złe prowadzą do ostrzeżenia i decyzji o przeniesieniu. Sama zmiana parafii pozostaje zaplanowana na później.",
		"W telefonie znajdziesz Karierę: termin oceny, propozycje awansu, uzgodnienia i trwałą kronikę decyzji. Sąsiedni proboszcz reaguje na twoje decyzje, a wspólny odpust ma skutki wracające po tygodniach.",
	]},
	{"version": "2.5", "title": "Ksiądz nabiera doświadczenia", "changes": [
		"Charyzma, wiarygodność, zarządzanie, wpływy i odporność rosną z wykonywanych czynności. Profil i postępy znajdziesz w telefonie, w zakładce Rozwój.",
		"Wydawaj szacunek na trzy drzewka: administratora, duszpasterza i gospodarza. Odblokujesz zniżki, przegląd budynków, większą frekwencję, krótsze odwiedziny oraz skuteczniejsze odpowiedzi w mediach i kurii.",
		"Niektóre wydarzenia mają nowe opcje wymagające odpowiedniej cechy. Wymagania są widoczne, a przy decyzjach finansowych zobaczysz kwotę wynikającą z twojego zarządzania.",
		"Dotychczasowe zapisy otrzymują profil z cechami na poziomie 3/10; dalszy rozwój wynika z nowo zdobywanego doświadczenia.",
	]},
	{"version": "2.6", "title": "Parafia ma wiele głosów", "changes": [
		"W telefonie pojawiła się Parafia: sześć grup z własnym zadowoleniem, liczebnością, wpływem i historią ostatniej zmiany. Dotychczasowe nastroje przechodzą na seniorów i młode rodziny.",
		"Decyzje w wydarzeniach pokazują reakcje konkretnych grup. Wpływowe środowiska organizują zbiórki i wydarzenia albo skarżą się kurii. Dwie silne, niezadowolone grupy mogą stworzyć frakcję w radzie parafialnej.",
		"Uruchom Caritas, świetlicę lub katechezę. Finansowanie jest tygodniowe, a każde prowadzone spotkanie zajmuje czas i energię oraz zwiększa zadowolenie i liczebność wskazanych grup.",
		"Koszty wspólnot są widoczne w prognozie banku; włączenie programu przy deficycie wymaga potwierdzenia. Spotkania prowadzisz z widoku Parafia na plebanii, raz w tygodniu.",
	]},
]


static func current_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))


## Porównujemy liczby, nie napisy: 2.10 > 2.9, a 2.3 == 2.3.0.
static func _parts(version: String) -> Array[int]:
	var result: Array[int] = []
	var pieces := version.split(".")
	if pieces.is_empty() or pieces.size() > 3:
		return result
	for piece in pieces:
		if piece.is_empty():
			return []
		for character in piece:
			if character < "0" or character > "9":
				return []
		if piece.length() > 9:
			return []
		result.append(int(piece))
	while result.size() < 3:
		result.append(0)
	return result


static func compare(left: String, right: String) -> int:
	var a := _parts(left)
	var b := _parts(right)
	if a.is_empty() or b.is_empty():
		return 0
	for i in 3:
		if a[i] != b[i]:
			return 1 if a[i] > b[i] else -1
	return 0


static func pending_since(seen: String, current: String = "", releases: Array = RELEASES) -> Array:
	var result: Array = []
	if current.is_empty():
		current = current_version()
	if _parts(current).is_empty():
		return result
	var known := not _parts(seen).is_empty()
	for release in releases:
		var version := str(release["version"])
		if compare(version, BASELINE) < 0 or compare(version, current) > 0:
			continue
		if not known or compare(version, seen) > 0:
			result.append(release)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return compare(str(a["version"]), str(b["version"])) > 0)
	return result


static func read_seen(key: String = STORAGE_KEY) -> String:
	if not OS.has_feature("web"):
		return ""
	var value: Variant = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s) || '';}catch(e){return '';}})()" % JSON.stringify(key))
	return str(value) if value is String else ""


static func acknowledge(version: String, key: String = STORAGE_KEY) -> bool:
	if not OS.has_feature("web") or _parts(version).is_empty():
		return false
	# Starsza otwarta karta nie cofa znacznika ustawionego przez nowsze wydanie.
	var seen := read_seen(key)
	if not _parts(seen).is_empty() and compare(seen, version) >= 0:
		return true
	return JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s);return true;}catch(e){return false;}})()" % [JSON.stringify(key), JSON.stringify(version)]) == true


static func validate() -> Array[String]:
	var problems: Array[String] = []
	var versions: Array[String] = []
	for release in RELEASES:
		var version := str(release.get("version", ""))
		if _parts(version).is_empty() or versions.any(func(other: String) -> bool: return compare(other, version) == 0):
			problems.append("Release notes: nieprawidłowa albo powtórzona wersja " + version)
		versions.append(version)
		if str(release.get("title", "")).is_empty() or release.get("changes", []).is_empty():
			problems.append("Release notes: brak treści dla " + version)
	if not versions.has(BASELINE) or not versions.has(current_version()):
		problems.append("Release notes: wymagany wpis dla 2.3 i bieżącej wersji gry")
	return problems
