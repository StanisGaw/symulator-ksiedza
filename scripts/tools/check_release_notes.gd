class_name CheckReleaseNotes


static func run() -> Array[String]:
	var problems: Array[String] = []
	var releases := [{"version": "2.2"}, {"version": "2.3"}, {"version": "2.3.1"},
		{"version": "2.4"}, {"version": "2.9"}, {"version": "2.10"}, {"version": "3.0"}]
	var cases := [
		["", "2.3", ["2.3"]],
		["", "2.3.1", ["2.3.1", "2.3"]],
		["uszkodzony zapis", "2.3.1", ["2.3.1", "2.3"]],
		["2.3", "2.3.1", ["2.3.1"]],
		["2.3", "2.10", ["2.10", "2.9", "2.4", "2.3.1"]],
		["2.9", "2.10", ["2.10"]],
		["2.3.0", "2.3", []],
		["2.3.1", "2.3.1", []],
		["3.0", "2.3.1", []],
	]
	for scenario in cases:
		var actual: Array = ReleaseNotes.pending_since(scenario[0], scenario[1], releases).map(
			func(release: Dictionary) -> String: return str(release["version"]))
		if actual != scenario[2]:
			problems.append("Release notes: %s → %s: oczekiwano %s, otrzymano %s" % [
				scenario[0], scenario[1], scenario[2], actual])
	if problems.is_empty():
		print("Release notes: pierwszy start, pominięte wydania, porównanie numeryczne i starsza karta OK.")
	return problems
