extends RefCounted

## Per-faction persistent save: banked commons resources and which levels
## a faction has completed. Lives at user://factions/<faction_id>.json --
## the same "plain JSON to user://" pattern AssemblyBlueprint's save file
## already uses (see assembly_bay.gd's _on_save_pressed), just keyed by
## faction instead of by ship. Only one faction exists today
## (aevoria_commonwealth, see level_catalog.gd) but every call here is
## already keyed by faction_id so more factions are just more callers,
## not a new system.
##
## No class_name, matching part_catalog.gd / theme_builder.gd's
## preload()-only convention.
##
## This stays local-only on purpose even if community voting/multiplayer
## gets built later -- it's personal ship/mining/resource progress, not
## shared Commonwealth state. See docs/MULTIPLAYER_ROADMAP.md for what
## *would* move to a shared Supabase backend (governance/voting) vs. what
## wouldn't (this file).

const DIR = "user://factions"

static func _path(faction_id: String) -> String:
	return "%s/%s.json" % [DIR, faction_id]

static func load_state(faction_id: String) -> Dictionary:
	var path = _path(faction_id)
	if not FileAccess.file_exists(path):
		return {"faction_id": faction_id, "resources": {}, "completed_levels": []}
	var file = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"faction_id": faction_id, "resources": {}, "completed_levels": []}
	parsed["resources"] = parsed.get("resources", {})
	parsed["completed_levels"] = parsed.get("completed_levels", [])
	return parsed

static func save_state(state: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var file = FileAccess.open(_path(state["faction_id"]), FileAccess.WRITE)
	file.store_string(JSON.stringify(state))
	file.close()

static func mark_level_complete(faction_id: String, level_id: String) -> void:
	var state = load_state(faction_id)
	if not state["completed_levels"].has(level_id):
		state["completed_levels"].append(level_id)
	save_state(state)

static func is_level_complete(faction_id: String, level_id: String) -> bool:
	return load_state(faction_id)["completed_levels"].has(level_id)

static func add_resource(faction_id: String, resource_name: String, amount: float) -> void:
	var state = load_state(faction_id)
	state["resources"][resource_name] = float(state["resources"].get(resource_name, 0.0)) + amount
	save_state(state)

## Returns false (no state change) if the faction doesn't have enough
## banked -- callers gate their action on this rather than letting the
## commons go negative.
static func spend_resource(faction_id: String, resource_name: String, amount: float) -> bool:
	var state = load_state(faction_id)
	var current = float(state["resources"].get(resource_name, 0.0))
	if current < amount:
		return false
	state["resources"][resource_name] = current - amount
	save_state(state)
	return true
