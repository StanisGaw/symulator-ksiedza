class_name Interactable
extends Area3D
## Something the priest can use when standing next to it. The kind decides what happens.

var label: String = ""
var kind: String = "activity"
var params: Dictionary = {}


func _init() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true


func prompt_text() -> String:
	match kind:
		"door":
			return label
		"activity":
			var def: Dictionary = Game.ACTIVITIES[params["id"]]
			if def.get("apple", false):
				if Game.apples_left() <= 0:
					return "Jabłoń (na dziś nic już nie zostało)"
				return "%s (%d min, +%d energii, zostały %d)" % [def["label"], def["minutes"], -int(def["energy"]), Game.apples_left()]
			if def.get("meal", false):
				return "%s (%d min, +%d energii, %d zł)" % [def["label"], def["minutes"], -int(def["energy"]), -int(def["money"])]
			if def.get("funeral", false):
				if Game.funerals_pending > 0:
					return "Pogrzeb: %s czeka na pochówek (%d min, -%d energii)" % [Game.deceased_name, def["minutes"], def["energy"]]
				return "Cmentarz: nikt nie czeka na pogrzeb"
			if def.get("mass", false):
				if Game.open_mass_hour() >= 0:
					return "Odpraw mszę o %02d:00 (%d min, -%d energii)" % [Game.open_mass_hour(), def["minutes"], def["energy"]]
				return Game.mass_hint()
			if def.get("visit", false) and not Game.done_today.has(params["id"]):
				return "Odwiedź: %s (%d min, -%d energii)" % [Game.next_visit()["name"], def["minutes"], def["energy"]]
			var done: bool = Game.done_today.has(params["id"]) and bool(def.get("once", false))
			if done:
				return "%s (zrobione dziś)" % def["label"]
			return "%s (%d min, -%d energii)" % [def["label"], def["minutes"], def["energy"]]
		_:
			return label


func activate() -> void:
	match kind:
		"door":
			Game.location_change_requested.emit(params["location"], params["spawn"])
		"activity":
			Game.do_activity(params["id"])
		"desk":
			Game.request_modal("finance", {})
		"bed":
			Game.request_modal("sleep", {})
		"status":
			Game.request_modal("status", {})
		"bench":
			Game.request_modal("bench", {})
