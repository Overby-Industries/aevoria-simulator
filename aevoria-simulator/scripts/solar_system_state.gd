extends RefCounted

## Shared, cross-faction save for the Situation View's solar-system table:
## which of the fixed sector slots each faction has claimed, and each
## claimed station's population. Deliberately NOT per-faction like
## faction_home_base.gd -- territory is world state every faction has to
## see the same view of (you need to see the Combine's claims to know
## which slots are still open), so this lives at its own single
## user://solar_system.json instead of user://factions/<faction_id>.json.
##
## No class_name, matching faction_home_base.gd / part_catalog.gd's
## preload()-only convention.

const LevelCatalog = preload("res://scripts/level_catalog.gd")

const PATH = "user://solar_system.json"

const SLOT_COUNT = 12
const SLOT_RADIUS = 14.0

const STARTING_POPULATION = 20
const NEW_STATION_POPULATION = 5

## Fixed table positions, same "hand-placed slots" spirit as
## resource_node_catalog.gd's field -- 12 slots, 30 degrees apart, all at
## the same radius (a single claimable ring between the asteroid belt and
## the Oort cloud, not a free-form starfield).
static func sector_slots() -> Array:
	var slots: Array = []
	for i in range(SLOT_COUNT):
		slots.append({"id": "sector_%d" % i, "angle_deg": float(i) * (360.0 / SLOT_COUNT), "radius": SLOT_RADIUS})
	return slots

## Every faction starts with exactly one home station, 120 degrees apart
## (slots 0/4/8 of 12) -- mirrors how FactionHomeBase already gives every
## faction a home base with no build step required.
const HOME_SLOT_BY_FACTION = {
	LevelCatalog.AEVORIA_COMMONWEALTH: "sector_0",
	LevelCatalog.OLIGARCH_COMBINE: "sector_4",
	LevelCatalog.NOMAD_FLOTILLA: "sector_8",
}

static func _default_state() -> Dictionary:
	var claims = {}
	for faction_id in HOME_SLOT_BY_FACTION.keys():
		var slot_id = HOME_SLOT_BY_FACTION[faction_id]
		claims[slot_id] = {
			"faction_id": faction_id,
			"station_name": "%s Home Station" % LevelCatalog.faction_label(faction_id),
			"population": STARTING_POPULATION,
		}
	return {"claims": claims}

static func load_state() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return _default_state()
	var file = FileAccess.open(PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("claims"):
		return _default_state()
	return parsed

static func save_state(state: Dictionary) -> void:
	var file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(state))
	file.close()

static func get_claims() -> Dictionary:
	return load_state()["claims"]

static func claim_sector(sector_id: String, faction_id: String, station_name: String) -> void:
	var state = load_state()
	state["claims"][sector_id] = {
		"faction_id": faction_id,
		"station_name": station_name,
		"population": NEW_STATION_POPULATION,
	}
	save_state(state)

static func grow_population(sector_id: String, amount: int) -> void:
	var state = load_state()
	if not state["claims"].has(sector_id):
		return
	state["claims"][sector_id]["population"] = int(state["claims"][sector_id]["population"]) + amount
	save_state(state)

static func total_population(faction_id: String) -> int:
	var total = 0
	for claim in load_state()["claims"].values():
		if claim["faction_id"] == faction_id:
			total += int(claim["population"])
	return total
