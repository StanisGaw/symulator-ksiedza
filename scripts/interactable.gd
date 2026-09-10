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
			Game.sleep()
		"status":
			Game.request_modal("status", {})
