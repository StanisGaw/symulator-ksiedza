class_name GroupEvents
## Społeczne skutki decyzji. Każda znana opcja ma jawnie dobraną reakcję grup;
## brak wpisu oznacza błąd definicji, a nie losowy lub wspólny fallback.

const IDS := ["mlodziez", "rodziny", "pracujacy", "seniorzy", "przedsiebiorcy", "potrzebujacy"]

const OPTION_REACTIONS := {
	"mass_hour": [
		{"pracujacy": -3, "mlodziez": -2}, {"mlodziez": 5, "pracujacy": 3},
		{"pracujacy": 2, "potrzebujacy": 1}],
	"funeral": [
		{"seniorzy": 5, "rodziny": 3, "potrzebujacy": 2},
		{"seniorzy": -4, "rodziny": -3, "pracujacy": -1}],
	"curia_call": [
		{"pracujacy": 3, "przedsiebiorcy": 2}, {"pracujacy": -2, "seniorzy": -1},
		{"przedsiebiorcy": -4, "pracujacy": -2}],
	"organ_silent": [
		{"seniorzy": 4, "pracujacy": 2}, {"mlodziez": 4, "seniorzy": -4},
		{"seniorzy": 3, "rodziny": 1}],
	"first_communion": [
		{"rodziny": 5, "potrzebujacy": 4, "seniorzy": 2},
		{"rodziny": 6, "przedsiebiorcy": 3, "potrzebujacy": -3},
		{"rodziny": -4, "pracujacy": -2}],
	"local_media": [
		{"pracujacy": 4, "przedsiebiorcy": 3}, {"pracujacy": -4, "przedsiebiorcy": -2},
		{"przedsiebiorcy": 2, "seniorzy": 1}],
	"caritas_fire": [
		{"potrzebujacy": 9, "rodziny": 5, "pracujacy": 3},
		{"potrzebujacy": 6, "rodziny": 3, "przedsiebiorcy": 2},
		{"potrzebujacy": -6, "rodziny": -3}],
	"rich_wedding": [
		{"przedsiebiorcy": 6, "seniorzy": -5, "rodziny": 2},
		{"seniorzy": 5, "rodziny": -3},
		{"rodziny": 4, "przedsiebiorcy": 3, "seniorzy": -1}],
	"school_hours": [
		{"seniorzy": 4, "rodziny": -4, "mlodziez": -3},
		{"rodziny": 5, "mlodziez": 4, "seniorzy": -4},
		{"rodziny": 2, "pracujacy": -2}],
	"sacristan_drinking": [
		{"seniorzy": -5, "pracujacy": 3}, {"seniorzy": 3, "pracujacy": -3},
		{"seniorzy": -4, "rodziny": -2}],
	"grave_vandalism": [
		{"rodziny": 5, "seniorzy": 4, "pracujacy": 2},
		{"rodziny": 6, "przedsiebiorcy": 3}, {"rodziny": -7, "seniorzy": -5}],
	"bishop_visitation": [
		{"seniorzy": 3, "przedsiebiorcy": 2}, {"pracujacy": 2, "seniorzy": -1}],
	"heating_bill": [
		{"seniorzy": 4, "rodziny": 2}, {"pracujacy": 2, "seniorzy": -4},
		{"seniorzy": -7, "rodziny": -5, "potrzebujacy": -3}],
	"youth_band": [
		{"mlodziez": 8, "seniorzy": -5, "rodziny": 3},
		{"mlodziez": 5, "rodziny": 2, "seniorzy": -1},
		{"mlodziez": -7, "seniorzy": 4, "rodziny": -3}],
	"attic_noise": [
		{"seniorzy": 2, "pracujacy": 1}, {"pracujacy": 3, "seniorzy": 1},
		{"seniorzy": -3, "rodziny": -1}],
	"storm_warning": [
		{"seniorzy": 3, "pracujacy": 2}, {"pracujacy": 2, "rodziny": 1},
		{"seniorzy": -3, "pracujacy": -2}],
	"tax_office": [
		{"pracujacy": 3, "przedsiebiorcy": 2}, {"przedsiebiorcy": 3, "pracujacy": 1},
		{"przedsiebiorcy": -4, "pracujacy": -2}],
	"homeless_man": [
		{"potrzebujacy": 8, "seniorzy": -4, "rodziny": 2},
		{"potrzebujacy": 6, "pracujacy": 3}, {"potrzebujacy": -8, "seniorzy": 3}],
	"businessman_donation": [
		{"przedsiebiorcy": 7, "pracujacy": -3}, {"przedsiebiorcy": 4, "pracujacy": -2},
		{"pracujacy": 5, "przedsiebiorcy": -4, "seniorzy": 2}],
	"pilgrimage": [
		{"seniorzy": 7, "mlodziez": 5, "pracujacy": -2},
		{"seniorzy": 3, "rodziny": 2}, {"seniorzy": -5, "mlodziez": -3}],
	"advent_prep": [
		{"seniorzy": 6, "rodziny": 4, "mlodziez": 3},
		{"seniorzy": 3, "rodziny": 2}, {"seniorzy": -6, "rodziny": -4}],
	"neighbour_parish": [
		{"pracujacy": 3, "rodziny": 2}, {"seniorzy": 4, "rodziny": -5},
		{"pracujacy": 1, "rodziny": -2}],
	"choir_conflict": [
		{"seniorzy": 7, "mlodziez": -5}, {"mlodziez": 7, "seniorzy": -5},
		{"seniorzy": 5, "mlodziez": 4, "rodziny": 3},
		{"seniorzy": 3, "mlodziez": 2, "pracujacy": -1}],
	"night_call": [
		{"seniorzy": 6, "rodziny": 4, "potrzebujacy": 2},
		{"seniorzy": -5, "rodziny": -3}],
	"viral_sermon": [
		{"mlodziez": 3, "pracujacy": -1}, {"mlodziez": 6, "pracujacy": 3},
		{"mlodziez": -5, "pracujacy": -2}],
	"collection_theft": [
		{"seniorzy": -4, "pracujacy": 2}, {"seniorzy": 2, "pracujacy": -2},
		{"seniorzy": -5, "przedsiebiorcy": -3}],
	"roof_leak": [
		{"seniorzy": 4, "pracujacy": 2}, {"seniorzy": -6, "rodziny": -3}],
	"parish_council": [
		{"pracujacy": 6, "przedsiebiorcy": 5, "seniorzy": 2},
		{"pracujacy": 3, "przedsiebiorcy": 1}, {"pracujacy": -5, "seniorzy": -3}],
	"car_dies": [
		{"pracujacy": 2, "seniorzy": 1}, {"seniorzy": -3, "potrzebujacy": -1},
		{"seniorzy": 4, "pracujacy": 3, "potrzebujacy": 2}],
	"anonymous_letter": [
		{"pracujacy": 3, "przedsiebiorcy": 2}, {"seniorzy": 2, "pracujacy": -3},
		{"pracujacy": -3, "przedsiebiorcy": -2}],
	"harvest_festival": [
		{"seniorzy": 5, "pracujacy": 3}, {"seniorzy": 3, "pracujacy": -4},
		{"seniorzy": 6, "pracujacy": 4, "rodziny": 2}],
	"revolt": [
		{"pracujacy": 7, "rodziny": 5, "seniorzy": 3},
		{"seniorzy": 4, "mlodziez": -6}, {"pracujacy": -6, "rodziny": -4}],
	"curia_intervention": [
		{"pracujacy": 3, "przedsiebiorcy": 2}, {"seniorzy": 2, "pracujacy": -1},
		{"pracujacy": -5, "seniorzy": -3}],
	"debt": [
		{"potrzebujacy": 3, "przedsiebiorcy": -4}, {"przedsiebiorcy": 4, "seniorzy": -6},
		{"pracujacy": 5, "potrzebujacy": 3, "przedsiebiorcy": -2}],
	"ruin": [
		{"seniorzy": -5, "rodziny": -3, "pracujacy": 2},
		{"seniorzy": -2, "pracujacy": 2}, {"seniorzy": -6, "rodziny": -4}],
	"group_faction": [
		{"potrzebujacy": 12, "pracujacy": 11, "rodziny": 10, "mlodziez": 9,
			"seniorzy": 8, "przedsiebiorcy": 7},
		{"pracujacy": 6, "rodziny": 5, "seniorzy": 3, "mlodziez": 2},
		{"seniorzy": 4, "przedsiebiorcy": 2, "mlodziez": -5, "pracujacy": -3}],
	"dean_indulgence": [
		{"rodziny": 5, "seniorzy": 4, "pracujacy": 3},
		{"przedsiebiorcy": 5, "pracujacy": 2, "rodziny": -2},
		{"pracujacy": 5, "potrzebujacy": 3, "seniorzy": 2}],
	"neighbour_mass_hours": [
		{"rodziny": 4, "pracujacy": 3}, {"seniorzy": 2, "rodziny": -4}],
	"dean_indulgence_together_success": [
		{"pracujacy": 5, "rodziny": 3}, {"seniorzy": 3, "pracujacy": -2}],
	"dean_indulgence_together_failure": [
		{"pracujacy": 2, "rodziny": -2}, {"pracujacy": -5, "przedsiebiorcy": -3}],
	"dean_indulgence_rival_success": [
		{"pracujacy": 4, "rodziny": 2}, {"przedsiebiorcy": 5, "pracujacy": -2}],
	"dean_indulgence_rival_failure": [
		{"pracujacy": 1, "rodziny": -3}, {"seniorzy": 2, "pracujacy": -4}],
	"dean_indulgence_support_success": [
		{"pracujacy": 6, "potrzebujacy": 3}, {"pracujacy": 5, "rodziny": 3}],
	"dean_indulgence_support_failure": [
		{"pracujacy": 4, "rodziny": 2}, {"pracujacy": -4, "przedsiebiorcy": -2}],
	"media_remont": [
		{"pracujacy": 3, "przedsiebiorcy": 2}, {"pracujacy": 5, "przedsiebiorcy": 4},
		{"pracujacy": -4, "przedsiebiorcy": -2}],
	"media_mlodzi": [
		{"rodziny": 5, "mlodziez": 4}, {"rodziny": 3, "mlodziez": 1}],
	"media_tradycja": [
		{"seniorzy": 5, "pracujacy": 2}, {"seniorzy": -4, "pracujacy": -2}],
	"media_dobra_opinia": [{"pracujacy": 4, "rodziny": 2}],
	"media_dziura": [
		{"pracujacy": 3, "przedsiebiorcy": 2}, {"pracujacy": -4, "przedsiebiorcy": -3}],
	"phone_curia": [
		{"pracujacy": 3, "przedsiebiorcy": 2}, {"seniorzy": 2, "pracujacy": -2},
		{"pracujacy": -4, "przedsiebiorcy": -2}],
}

## Tylko gałęzie, w których późniejszy wynik sam wywołuje czytelną reakcję grup.
## Pozostałe decyzje mają pełny skutek społeczny od razu w OPTION_REACTIONS.
const DELAYED_REACTIONS := {
	"local_media": {1: {"hit": {"pracujacy": -3, "przedsiebiorcy": -2},
		"miss": {"pracujacy": 2, "przedsiebiorcy": 1}}},
	"sacristan_drinking": {1: {"hit": {"seniorzy": 4, "pracujacy": 2},
		"miss": {"seniorzy": -5, "pracujacy": -3}}},
	"neighbour_parish": {2: {"hit": {"rodziny": 4, "pracujacy": 2},
		"miss": {"rodziny": -5, "pracujacy": -2}}},
	"choir_conflict": {3: {"hit": {"seniorzy": 3, "mlodziez": 2},
		"miss": {"seniorzy": -4, "mlodziez": -3}}},
	"night_call": {1: {"hit": {"seniorzy": -6, "rodziny": -4},
		"miss": {"seniorzy": 4, "rodziny": 2}}},
	"collection_theft": {0: {"hit": {"pracujacy": 4, "seniorzy": 2},
		"miss": {"pracujacy": -4, "seniorzy": -3}}},
	"debt": {2: {"hit": {"pracujacy": 6, "potrzebujacy": 4},
		"miss": {"pracujacy": -3, "przedsiebiorcy": -2}}},
}

const EXPIRE_REACTIONS := {
	"media_remont": {"pracujacy": -4, "przedsiebiorcy": -2},
	"media_tradycja": {"seniorzy": -5, "pracujacy": -2},
	"media_dziura": {"pracujacy": -5, "przedsiebiorcy": -3},
	"phone_curia": {"pracujacy": -3, "przedsiebiorcy": -2},
}


static func decorate_event(source: Dictionary) -> Dictionary:
	var event: Dictionary = source.duplicate(true)
	if bool(event.get("_groups_decorated", false)):
		return event
	var id := str(event.get("id", ""))
	if not OPTION_REACTIONS.has(id):
		return event
	var options: Array = event.get("options", [])
	var authored: Array = OPTION_REACTIONS[id]
	for index in options.size():
		if index >= authored.size():
			continue
		options[index] = _decorate_option(id, index, options[index], authored[index])
	event["_groups_decorated"] = true
	return event


static func decorate_message(source: Dictionary) -> Dictionary:
	var message: Dictionary = source.duplicate(true)
	if bool(message.get("_groups_decorated", false)):
		return message
	var id := str(message.get("group_event_id", message.get("id", "")))
	if not OPTION_REACTIONS.has(id):
		return message
	var options: Array = message.get("options", [])
	var authored: Array = OPTION_REACTIONS[id]
	for index in options.size():
		if index >= authored.size():
			continue
		options[index] = _decorate_option(id, index, options[index], authored[index])
	if message.has("expire") and EXPIRE_REACTIONS.has(id):
		var expire: Dictionary = message["expire"]
		expire["effects"] = _decorate_effects(expire.get("effects", {}), EXPIRE_REACTIONS[id])
	message["_groups_decorated"] = true
	return message


static func decorate_options(id: String, source: Array) -> Array:
	var message := decorate_message({"group_event_id": id, "options": source})
	return (message.get("options", []) as Array).duplicate(true)


static func runtime_event(source: Dictionary, _game: Node) -> Dictionary:
	var event := decorate_event(source)
	if str(event.get("id", "")) != "group_faction":
		return event
	var sides: Array[String] = Groups.fracture_members()
	var labels: Array[String] = []
	for id in sides:
		labels.append(str(Groups.LABELS.get(id, id)))
	var side_text := ", ".join(labels) if not labels.is_empty() else "skonfliktowane grupy parafii"
	event["title"] = "KRYZYS: rada parafialna — %s" % side_text
	event["text"] = "Do rady wpłynęły skargi. %s mają duży wpływ i zadowolenie poniżej 30. " % side_text \
		+ "Przedstawiciele siedzą przy jednym stole i żądają konkretnego planu dla całej parafii."
	return event


static func has_complete_mapping(event: Dictionary) -> bool:
	var id := str(event.get("id", ""))
	return OPTION_REACTIONS.has(id) \
		and (OPTION_REACTIONS[id] as Array).size() == (event.get("options", []) as Array).size()


static func _decorate_option(id: String, index: int, source: Dictionary, reaction: Dictionary) -> Dictionary:
	var option: Dictionary = source.duplicate(true)
	option["effects"] = _decorate_effects(option.get("effects", {}), reaction)
	if option.has("delayed"):
		option["delayed"] = _decorate_delayed(id, index, option["delayed"])
	return option


static func _decorate_delayed(id: String, index: int, source: Dictionary) -> Dictionary:
	var delayed: Dictionary = source.duplicate(true)
	# Legacy w gałęziach także przechodzi do jednego, zagnieżdżonego kanału grup.
	delayed["effects"] = _decorate_effects(delayed.get("effects", {}), {})
	if delayed.has("else_effects"):
		delayed["else_effects"] = _decorate_effects(delayed.get("else_effects", {}), {})
	var by_option: Dictionary = DELAYED_REACTIONS.get(id, {})
	if not by_option.has(index):
		return delayed
	var reactions: Dictionary = by_option[index]
	delayed["effects"] = _decorate_effects(delayed.get("effects", {}), reactions.get("hit", {}))
	if delayed.has("chance"):
		delayed["else_effects"] = _decorate_effects(delayed.get("else_effects", {}), reactions.get("miss", {}))
	return delayed


static func _decorate_effects(source: Dictionary, reaction: Dictionary) -> Dictionary:
	var effects: Dictionary = source.duplicate(true)
	var groups: Dictionary = (effects.get("groups", {}) as Dictionary).duplicate(true)
	# Produkcyjne definicje tracą legacy klucze, więc Parish nie może zastosować ich dwa razy.
	if effects.has("trad"):
		groups["seniorzy"] = int(groups.get("seniorzy", 0)) + int(effects["trad"])
		effects.erase("trad")
	if effects.has("young"):
		groups["rodziny"] = int(groups.get("rodziny", 0)) + int(effects["young"])
		effects.erase("young")
	for id in reaction:
		groups[str(id)] = int(groups.get(str(id), 0)) + int(reaction[id])
	if not groups.is_empty():
		effects["groups"] = groups
	return effects
