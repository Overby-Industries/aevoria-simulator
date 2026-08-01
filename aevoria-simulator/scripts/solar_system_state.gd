extends RefCounted

## Shared, cross-faction save for the Situation View's solar-system table:
## which of the fixed sector slots each faction has claimed, each claimed
## station's population, and the shared cycle/day counter. Deliberately
## NOT per-faction like faction_home_base.gd -- territory (and the clock)
## is world state every faction has to see the same view of (you need to
## see the Combine's claims to know which slots are still open, and every
## faction lives on the same calendar), so this lives at its own single
## user://solar_system.json instead of user://factions/<faction_id>.json.
##
## No class_name, matching faction_home_base.gd / part_catalog.gd's
## preload()-only convention.

const LevelCatalog = preload("res://scripts/level_catalog.gd")

const PATH = "user://solar_system.json"

const SLOT_COUNT = 12
const SLOT_RADIUS = 14.0

## Population is split into two categories rather than one headcount:
## Biological (needs Food/Potable Water, tracked as VCI's own "Biological
## Life Support") and Silicon-Based (autonomous/AI crews and mining
## drones -- VCI already has a whole "Silicon-Based Life Support"
## category tracking things like electrical power continuity, it just
## had no actual population driving upkeep against it until now). A new
## station leans further toward autonomous crews than a home station
## does -- cheaper to stand up, no life support to build out first.
const STARTING_POPULATION_BIOLOGICAL = 6
const STARTING_POPULATION_SILICON = 14
const NEW_STATION_POPULATION_BIOLOGICAL = 2
const NEW_STATION_POPULATION_SILICON = 5

## Per-cycle upkeep, per resident. Biological crews draw down Food/Potable
## Water like always; Silicon-Based crews don't eat, but autonomous
## hardware still needs spare parts to keep running, so they draw down
## Steel instead -- the same Steel a new station's construction cost also
## spends, on purpose (real tension: growing your autonomous workforce
## competes with your own expansion budget).
const FOOD_PER_BIO_POP = 0.4
const WATER_PER_BIO_POP = 0.4
const STEEL_PER_SILICON_POP = 0.2

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
			"population_biological": STARTING_POPULATION_BIOLOGICAL,
			"population_silicon": STARTING_POPULATION_SILICON,
		}
	return {"claims": claims, "cycle": 0}

static func load_state() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return _default_state()
	var file = FileAccess.open(PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("claims"):
		return _default_state()
	parsed["cycle"] = int(parsed.get("cycle", 0))
	return parsed

static func save_state(state: Dictionary) -> void:
	var file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(state))
	file.close()

static func get_claims() -> Dictionary:
	return load_state()["claims"]

static func get_current_cycle() -> int:
	return load_state()["cycle"]

## Called once per "Run Supply Cycle" press, in situation_view.gd, after
## upkeep has already been spent -- advances the one shared clock every
## faction reads (see cycle_status_panel.gd, docked on every level like
## VCI/Commons).
static func advance_cycle() -> int:
	var state = load_state()
	state["cycle"] = int(state["cycle"]) + 1
	save_state(state)
	return state["cycle"]

static func claim_sector(sector_id: String, faction_id: String, station_name: String) -> void:
	var state = load_state()
	state["claims"][sector_id] = {
		"faction_id": faction_id,
		"station_name": station_name,
		"population_biological": NEW_STATION_POPULATION_BIOLOGICAL,
		"population_silicon": NEW_STATION_POPULATION_SILICON,
	}
	save_state(state)

static func grow_population(sector_id: String, category: String, amount: int) -> void:
	var state = load_state()
	if not state["claims"].has(sector_id):
		return
	var key = "population_%s" % category
	state["claims"][sector_id][key] = int(state["claims"][sector_id].get(key, 0)) + amount
	save_state(state)

## {"biological": int, "silicon": int, "total": int} across every sector
## this faction holds.
static func total_population(faction_id: String) -> Dictionary:
	var biological = 0
	var silicon = 0
	for claim in load_state()["claims"].values():
		if claim["faction_id"] == faction_id:
			biological += int(claim.get("population_biological", 0))
			silicon += int(claim.get("population_silicon", 0))
	return {"biological": biological, "silicon": silicon, "total": biological + silicon}

## Shared math for "what does one supply cycle cost this faction" --
## used by both situation_view.gd's Civil Engineering panel and
## cycle_status_panel.gd's global HUD readout, so the two never drift
## out of sync with each other.
static func upkeep_cost(faction_id: String) -> Dictionary:
	var totals = total_population(faction_id)
	return {
		"Food": float(totals["biological"]) * FOOD_PER_BIO_POP,
		"Potable Water": float(totals["biological"]) * WATER_PER_BIO_POP,
		"Steel": float(totals["silicon"]) * STEEL_PER_SILICON_POP,
	}
