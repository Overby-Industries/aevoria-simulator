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

## Which faction the player is currently browsing/playing as -- set by
## level_select.gd's faction switcher, in every build, not just debug
## ones. Level Select filters its level cards down to only this faction's
## own catalog entries (see level_select.gd's _build_ui()), so switching
## here is what actually makes the Commonwealth/Combine/Flotilla separate
## playthroughs instead of one shared roster. That filtering is strict:
## most levels are still Commonwealth-only, so switching away from the
## Commonwealth currently narrows the roster to just that faction's own
## dedicated level(s) -- there's no longer a way to reach the Oligarch/
## Nomad exclusive hulls (part_catalog.gd) inside Commonwealth-only levels
## like Assembly Bay this way; that stays a known gap until those levels
## either go faction-agnostic or get their own faction-flagged variants.
## Empty string means "no override, default to the Commonwealth" -- the
## untouched, original behavior, and still level_select.gd's starting
## faction on first launch. Survives a scene reload (that's the whole
## point -- an ordinary var reset on every LevelSelect._ready() wouldn't).
var faction_override: String = ""

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
