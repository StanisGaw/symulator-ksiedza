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
			if def.get("rest", false):
				return "%s (%d min, +%d energii)" % [def["label"], def["minutes"], Game.rest_gain(def)]
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
