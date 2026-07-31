extends RefCounted

## The level roster. Started as just two Commonwealth levels (build
## hardware vs. handle governance) and has grown a level per faction beyond
## that -- faction_id is plumbed through FactionHomeBase/LevelContext, so
## each faction's levels are just more catalog entries, not a new system.
## See docs/FACTIONS.md for why the Combine and Flotilla each get a
## structurally different mechanic (Capture Risk vs. Vital Continuity)
## instead of a reskinned copy of the Commonwealth's.

enum Kind { EXTRACTION, GOVERNANCE, PRODUCTION }

const AEVORIA_COMMONWEALTH = "aevoria_commonwealth"

# Not Commonwealth citizens -- see docs/FACTIONS.md. Also the canonical
# ids part_catalog.gd's faction-exclusive hulls gate against.
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
			"id": "oligarch_boardroom_capture",
			"kind": Kind.GOVERNANCE,
			"faction_id": OLIGARCH_COMBINE,
			"title": "Boardroom Capture",
			"objective": "Run the Combine's quarter: three decisions, each with a clean option and a corrupt one. The same Capture Risk Index the Commonwealth is scored on scores the Combine too -- it just tolerates a much higher number before anything happens.",
			"scene_path": "res://scenes/OligarchBoardroom.tscn",
		},
		{
			"id": "nomad_long_drift",
			"kind": Kind.GOVERNANCE,
			"faction_id": NOMAD_FLOTILLA,
			"title": "The Long Drift",
			"objective": "Run three legs of a supply route with no charter and no home base: a safe choice and a risky one each leg, spending the Flotilla's own Vital Continuity Index instead of anyone else's trust.",
			"scene_path": "res://scenes/TheLongDrift.tscn",
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
