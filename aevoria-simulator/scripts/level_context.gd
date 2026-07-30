extends Node

## Small transition-context bus, registered as the LevelContext autoload.
## level_select.gd sets this right before change_scene_to_file()-ing into
## a level scene (Assembly Bay or a governance level), since Godot's
## scene switch takes no arguments of its own. The level scene reads it
## in _ready() and calls finish_current_level() when its objective is met.

const FactionHomeBase = preload("res://scripts/faction_home_base.gd")

signal level_finished(level_id: String)

var current_level_id: String = ""
var current_faction_id: String = ""

func start_level(level_id: String, faction_id: String) -> void:
	current_level_id = level_id
	current_faction_id = faction_id

func finish_current_level(reward: Dictionary = {}) -> void:
	if current_level_id == "":
		return
	FactionHomeBase.mark_level_complete(current_faction_id, current_level_id)
	for resource_name in reward.keys():
		FactionHomeBase.add_resource(current_faction_id, resource_name, float(reward[resource_name]))
	if reward.is_empty():
		SystemLog.log("Level complete: %s." % current_level_id)
	else:
		var parts: Array = []
		for resource_name in reward.keys():
			parts.append("+%.1f %s" % [float(reward[resource_name]), resource_name])
		SystemLog.log("Level complete: %s (%s)." % [current_level_id, ", ".join(parts)])
	level_finished.emit(current_level_id)
	current_level_id = ""
