extends RefCounted

## Computes the Commonwealth's Vital Continuity Index (VCI) inputs from real
## banked-resource state (FactionHomeBase), for CURComplianceMonitor's
## update_vital_continuity() (src/cur_compliance_monitor.cpp, mirroring the
## existing capture-risk binding). See docs/VCI_TRACKING.md for the full
## constitutional background (FOUNDATION-003 §11 / FOUNDATION-013) and the
## complete mapping this file implements.
##
## VCI has four top-level category scores (0-100, higher is better), each
## conceptually an average of several sub-measures (FOUNDATION-003 §11's
## "VCI Variables"). Most sub-measures have no backing game system yet --
## no AI miner swarms, no power grid, no habitat count, no multi-citizen
## population/equity model -- so they're scored at a flat 100 (neutral,
## not a false "everything's fine") and marked `"tracked": false` so the
## UI can show them honestly instead of pretending they're real. Every
## `"tracked": true` entry below is computed from an actual resource
## banked through real gameplay (mining, refining, greenhouse,
## electrolysis, CUR walkthroughs).
##
## Sub-measure scoring: a per-resource "target" is the banked amount
## considered fully sufficient; below that it scales linearly to 0. No
## consumption/decay model exists yet (resources only ever accumulate),
## so this is intentionally the simplest scoring that's still real.

const TARGETS = {
	"O2": 50.0,
	"Potable Water": 50.0,
	"Food": 50.0,
	"PGM": 30.0,
	"Gold": 15.0,
	"Platinum": 15.0,
	"Steel": 20.0,
	"CompliancePoints": 20.0,
}

# Distinct constructed ships/structures providing a given infrastructure
# category (see faction_home_base.gd's mark_infrastructure_built(),
# written from assembly_bay.gd whenever a saved ship includes the
# relevant part) considered "fully sufficient" for a score of 100. Small
# numbers on purpose -- there's no population model yet to size these
# against, so this is a floor to build real numbers up from, not a
# researched target.
const BUILT_TARGETS = {
	"shelter": 3.0,
	"power": 3.0,
}

static func _availability(resources: Dictionary, key: String) -> float:
	var banked = float(resources.get(key, 0.0))
	var target = float(TARGETS.get(key, 1.0))
	return clamp(banked / target * 100.0, 0.0, 100.0)

static func _built_availability(state: Dictionary, category: String) -> float:
	var built: Array = state.get("built_infrastructure", {}).get(category, [])
	var target = float(BUILT_TARGETS.get(category, 1.0))
	return clamp(float(built.size()) / target * 100.0, 0.0, 100.0)

static func _category(sub_measures: Array) -> Dictionary:
	var total = 0.0
	for measure in sub_measures:
		total += measure["score"]
	return {"score": total / sub_measures.size(), "sub_measures": sub_measures}

## Returns {inputs: {...4 category scores, keyed for
## CURComplianceMonitor.update_vital_continuity()...}, categories: {label:
## {score, sub_measures: [{label, score, tracked}, ...]}, ...}}.
static func compute(state: Dictionary) -> Dictionary:
	var resources: Dictionary = state.get("resources", {})

	var biological = _category([
		{"label": "Air (O2 reserves)", "score": _availability(resources, "O2"), "tracked": true},
		{"label": "Water (Potable Water reserves)", "score": _availability(resources, "Potable Water"), "tracked": true},
		{"label": "Food reserves", "score": _availability(resources, "Food"), "tracked": true},
		{"label": "Shelter availability", "score": _built_availability(state, "shelter"), "tracked": true},
		{"label": "Sanitation availability", "score": 100.0, "tracked": false},
		{"label": "Basic healthcare access", "score": 100.0, "tracked": false},
	])

	var silicon = _category([
		{"label": "Electrical power continuity", "score": _built_availability(state, "power"), "tracked": true},
		{"label": "Computational continuity", "score": 100.0, "tracked": false},
		{"label": "Data integrity preservation", "score": 100.0, "tracked": false},
		{"label": "Memory continuity protection", "score": 100.0, "tracked": false},
		{"label": "Communication network availability", "score": 100.0, "tracked": false},
	])

	# The one Infrastructure sub-measure that's real today: banked raw +
	# refined industrial materials, as a proxy for "the Commonwealth has
	# reserves it could draw on." Everything else in this category
	# (redundancy, recovery, distribution, habitat reliability) needs a
	# system that doesn't exist yet (no multi-habitat tracking, no failure/
	# recovery simulation).
	var reserve_capacity = _availability(resources, "PGM") * 0.4 \
		+ _availability(resources, "Gold") * 0.2 \
		+ _availability(resources, "Platinum") * 0.2 \
		+ _availability(resources, "Steel") * 0.2
	var infrastructure = _category([
		{"label": "Reserve capacity (raw + refined materials)", "score": reserve_capacity, "tracked": true},
		{"label": "System redundancy", "score": 100.0, "tracked": false},
		{"label": "Recovery capability", "score": 100.0, "tracked": false},
		{"label": "Distribution network reliability", "score": 100.0, "tracked": false},
		{"label": "Habitat life-support reliability", "score": 100.0, "tracked": false},
	])

	# CompliancePoints (earned by completing governance/CUR levels) is used
	# as a thin proxy for "the constitutional/service oversight apparatus is
	# functioning" -- there's only one faction/player today, so equity has
	# nothing real to measure yet.
	var accessibility = _category([
		{"label": "Service availability (CUR engagement)", "score": _availability(resources, "CompliancePoints"), "tracked": true},
		{"label": "Distribution effectiveness", "score": 100.0, "tracked": false},
		{"label": "Access equity", "score": 100.0, "tracked": false},
		{"label": "Continuity consistency", "score": 100.0, "tracked": false},
	])

	return {
		"inputs": {
			"biological_life_support": biological["score"],
			"silicon_life_support": silicon["score"],
			"infrastructure_resilience": infrastructure["score"],
			"accessibility": accessibility["score"],
		},
		"categories": {
			"Biological Life Support": biological,
			"Silicon-Based Life Support": silicon,
			"Infrastructure Resilience": infrastructure,
			"Accessibility": accessibility,
		},
	}
