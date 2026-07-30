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
		return {"faction_id": faction_id, "resources": {}, "completed_levels": [], "built_infrastructure": {}}
	var file = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"faction_id": faction_id, "resources": {}, "completed_levels": [], "built_infrastructure": {}}
	parsed["resources"] = parsed.get("resources", {})
	parsed["completed_levels"] = parsed.get("completed_levels", [])
	parsed["built_infrastructure"] = parsed.get("built_infrastructure", {})
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

## Records that a distinct ship/structure (identified by ship_id) provides
## a given infrastructure category ("shelter", "power", etc. -- see
## assembly_bay.gd's _on_save_pressed and vci_tracker.gd, which reads this
## back via count_built()). Deduped by ship_id so re-saving the same ship
## repeatedly doesn't inflate the count -- this counts distinct
## constructed units, not save events.
static func mark_infrastructure_built(faction_id: String, category: String, ship_id: String) -> void:
	var state = load_state(faction_id)
	var built: Array = state["built_infrastructure"].get(category, [])
	if not built.has(ship_id):
		built.append(ship_id)
	state["built_infrastructure"][category] = built
	save_state(state)

static func count_built(faction_id: String, category: String) -> int:
	var state = load_state(faction_id)
	var built: Array = state["built_infrastructure"].get(category, [])
	return built.size()
