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

const FACTION_LABELS = {
	AEVORIA_COMMONWEALTH: "Commonwealth",
	OLIGARCH_COMBINE: "Oligarch Combine",
	NOMAD_FLOTILLA: "Nomad Flotilla",
}

## Single source of truth for display names -- level_select.gd's faction
## switcher and assembly_bay.gd's shared-scene log lines both read off
## this instead of keeping their own copies in sync by hand.
static func faction_label(faction_id: String) -> String:
	return FACTION_LABELS.get(faction_id, faction_id)

## Each faction's own name for its hardware/production hub, used both as
## main_hangar_deck's card title in build_levels() and as
## main_hangar_deck.gd's own header -- see docs/FACTIONS.md for why these
## aren't just "Hangar Deck" with a faction label stapled on: the
## Commonwealth's is a station bay, the Combine's a corporate floor, the
## Flotilla's a shared deck with no ownership implied.
const HANGAR_DECK_LABELS = {
	AEVORIA_COMMONWEALTH: "Main Hangar Deck",
	OLIGARCH_COMBINE: "Combine Production Floor",
	NOMAD_FLOTILLA: "Flotilla Common Deck",
}

static func hangar_deck_label(faction_id: String) -> String:
	return HANGAR_DECK_LABELS.get(faction_id, "Hangar Deck")

## The Assembly Bay entry differs per faction only in which faction-
## exclusive hull it calls out (part_catalog.gd) -- the scene itself
## (assembly_bay.gd) already faction-filters its own part list, so this is
## flavor text and level-id/reward tracking, not a different scene per
## faction. Ids match what shipped before the Hangar Deck consolidation
## (extraction_prospector_run predates it) so nobody's completed-levels
## history resets for the Commonwealth.
const ASSEMBLY_LEVEL_BY_FACTION = {
	AEVORIA_COMMONWEALTH: {
		"id": "extraction_prospector_run",
		"title": "Assembly Bay",
		"objective": "Assemble a mining ship -- attach a drill arm and a thruster to the hull -- then save it.",
		"scene_path": "res://scenes/AssemblyBay.tscn",
	},
	OLIGARCH_COMBINE: {
		"id": "oligarch_fabrication_yard",
		"title": "Assembly Bay",
		"objective": "Assemble a mining ship -- attach a drill arm and a thruster to the Tube Rocket Hull, the Combine's own faction-exclusive hull -- then save it.",
		"scene_path": "res://scenes/AssemblyBay.tscn",
	},
	NOMAD_FLOTILLA: {
		"id": "nomad_refit_deck",
		"title": "Assembly Bay",
		"objective": "Assemble a mining ship -- attach a drill arm and a thruster to the Drift Hull, the Flotilla's own faction-exclusive hull -- then save it.",
		"scene_path": "res://scenes/AssemblyBay.tscn",
	},
}

## The three production bays are already faction-agnostic (greenhouse_bay.gd/
## refinery_bay.gd/electrolysis_bay.gd all spend/bank through
## LevelContext.current_faction_id, never a hardcoded faction) -- one set of
## ids shared by every faction. FactionHomeBase already namespaces
## completed_levels/resources by faction_id, so the same level id
## completed by two different factions doesn't collide.
const PRODUCTION_LEVELS = [
	{
		"id": "production_greenhouse_bay",
		"title": "Greenhouse Bay",
		"objective": "Spend banked H2O in the station's LED grow bays to produce Food.",
		"scene_path": "res://scenes/GreenhouseBay.tscn",
	},
	{
		"id": "production_refinery_bay",
		"title": "Refinery Bay",
		"objective": "Smelt banked PGM into Gold, Platinum, and Steel.",
		"scene_path": "res://scenes/RefineryBay.tscn",
	},
	{
		"id": "production_electrolysis_bay",
		"title": "Electrolysis Bay",
		"objective": "Split banked H2O into Potable Water and O2.",
		"scene_path": "res://scenes/ElectrolysisBay.tscn",
	},
]

## What main_hangar_deck.gd shows as sub-options for the given faction --
## Assembly Bay first (that's the one with a faction-specific flavor),
## then the three shared production bays.
static func hangar_levels(faction_id: String) -> Array:
	var levels: Array = [ASSEMBLY_LEVEL_BY_FACTION.get(faction_id, ASSEMBLY_LEVEL_BY_FACTION[AEVORIA_COMMONWEALTH])]
	levels.append_array(PRODUCTION_LEVELS)
	return levels

static func build_levels() -> Array:
	return [
		{
			"id": "main_hangar_deck",
			"kind": Kind.PRODUCTION,
			"faction_id": AEVORIA_COMMONWEALTH,
			"title": HANGAR_DECK_LABELS[AEVORIA_COMMONWEALTH],
			"objective": "Head inside the station: build ships in the Assembly Bay, grow Food, process metals, or split water for O2 -- everything the Commonwealth's hardware side does lives behind this one door now.",
			"scene_path": "res://scenes/MainHangarDeck.tscn",
		},
		{
			"id": "oligarch_hangar_deck",
			"kind": Kind.PRODUCTION,
			"faction_id": OLIGARCH_COMBINE,
			"title": HANGAR_DECK_LABELS[OLIGARCH_COMBINE],
			"objective": "Head inside Combine holdings: build ships, grow Food, process metals, or split water for O2 -- the Combine's own hardware side, same floor plan as the Commonwealth's.",
			"scene_path": "res://scenes/MainHangarDeck.tscn",
		},
		{
			"id": "nomad_hangar_deck",
			"kind": Kind.PRODUCTION,
			"faction_id": NOMAD_FLOTILLA,
			"title": HANGAR_DECK_LABELS[NOMAD_FLOTILLA],
			"objective": "Head into whichever hull is serving as the Flotilla's common deck this leg: build ships, grow Food, process metals, or split water for O2.",
			"scene_path": "res://scenes/MainHangarDeck.tscn",
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
	]
