extends RefCounted

## The starting level roster -- deliberately just two, one per activity
## type, per the "start small" call: build hardware (Overby Industries,
## dark console theme) vs. handle governance (Aevoria Commonwealth, flat
## civil theme). Both belong to the Commonwealth's one faction for now;
## faction_id is already plumbed through FactionHomeBase/LevelContext so
## adding more factions later is just more catalog entries, not a new
## system.

enum Kind { EXTRACTION, GOVERNANCE, PRODUCTION }

const AEVORIA_COMMONWEALTH = "aevoria_commonwealth"

# The other two factions from the user's sketch -- no levels or home bases
# of their own yet (that's the later "spheres of influence" pass), but
# part_catalog.gd's faction-exclusive hulls need canonical ids to gate
# against now, and this is the single place faction ids are defined.
const OLIGARCH_COMBINE = "oligarch_combine"
const NOMAD_FLOTILLA = "nomad_flotilla"

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
			"id": "governance_reef_advocate",
			"kind": Kind.GOVERNANCE,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": "The Reef's Advocate",
			"objective": "Appoint an advocate for a reef habitat that can't speak for itself before a mining expansion determination can proceed -- CUR-E §1.6.",
			"scene_path": "res://scenes/AdvocateLevel.tscn",
		},
		{
			"id": "governance_standing_review",
			"kind": Kind.GOVERNANCE,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": "The Standing Review",
			"objective": "Watch what happens when a routine restriction review is never filed -- CUR-H.7 §7.12(c)(3)/(d), the built-in test no guard could catch.",
			"scene_path": "res://scenes/ObligationLevel.tscn",
		},
		{
			"id": "prospecting_asteroid_field",
			"kind": Kind.EXTRACTION,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": "Asteroid Field Prospecting",
			"objective": "Scan the field and mine asteroids for PGMs, comets for H2O -- resources bank straight to the Commonwealth commons.",
			"scene_path": "res://scenes/AsteroidField.tscn",
		},
		{
			"id": "production_greenhouse_bay",
			"kind": Kind.PRODUCTION,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": "Greenhouse Bay",
			"objective": "Spend banked H2O in the station's LED grow bays to produce Food for the Commonwealth commons.",
			"scene_path": "res://scenes/GreenhouseBay.tscn",
		},
		{
			"id": "production_refinery_bay",
			"kind": Kind.PRODUCTION,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": "Refinery Bay",
			"objective": "Smelt banked PGM into Gold, Platinum, and Steel for the Commonwealth commons.",
			"scene_path": "res://scenes/RefineryBay.tscn",
		},
		{
			"id": "production_electrolysis_bay",
			"kind": Kind.PRODUCTION,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": "Electrolysis Bay",
			"objective": "Split banked H2O into Potable Water and O2 to sustain the station's life support.",
			"scene_path": "res://scenes/ElectrolysisBay.tscn",
		},
	]
