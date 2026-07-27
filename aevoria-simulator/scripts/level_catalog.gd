extends RefCounted

## The starting level roster -- deliberately just two, one per activity
## type, per the "start small" call: build hardware (Overby Industries,
## dark console theme) vs. handle governance (Aevoria Commonwealth, flat
## civil theme). Both belong to the Commonwealth's one faction for now;
## faction_id is already plumbed through FactionHomeBase/LevelContext so
## adding more factions later is just more catalog entries, not a new
## system.

enum Kind { EXTRACTION, GOVERNANCE }

const AEVORIA_COMMONWEALTH = "aevoria_commonwealth"

static func build_levels() -> Array:
	return [
		{
			"id": "extraction_prospector_run",
			"kind": Kind.EXTRACTION,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": "Prospector Run",
			"objective": "Assemble a mining ship in the Assembly Bay -- attach a drill arm and a thruster to the hull -- then save it.",
			"scene_path": "res://scenes/AssemblyBay.tscn",
		},
		{
			"id": "governance_first_violation",
			"kind": Kind.GOVERNANCE,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": "First Violation",
			"objective": "Walk a mining charter through the Code of Universal Regulations and see what happens when it breaks its debris limit.",
			"scene_path": "res://scenes/GovernanceLevel.tscn",
		},
		{
			"id": "prospecting_asteroid_field",
			"kind": Kind.EXTRACTION,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": "Asteroid Field Prospecting",
			"objective": "Scan the field and mine asteroids for PGMs, comets for H2O -- resources bank straight to the Commonwealth commons.",
			"scene_path": "res://scenes/AsteroidField.tscn",
		},
	]
