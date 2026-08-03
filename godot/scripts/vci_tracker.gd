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
	"sanitation": 3.0,
	"healthcare": 3.0,
}

static func _availability(resources: Dictionary, key: String) -> float:
	var banked = float(resources.get(key, 0.0))
	var target = float(TARGETS.get(key, 1.0))
	return clamp(banked / target * 100.0, 0.0, 100.0)

static func _built_availability(state: Dictionary, category: String) -> float:
	var built: Array = state.get("built_infrastructure", {}).get(category, [])
	var target = float(BUILT_TARGETS.get(category, 1.0))
	return clamp(float(built.size()) / target * 100.0, 0.0, 100.0)

## System redundancy: distinct built ships *beyond* BUILT_TARGETS' "just
## sufficient" count. mark_infrastructure_built() already dedupes by ship
## id, not part id -- a player who saves 6 differently-named habitat ships
## already has the data to prove redundancy with the exact same part that
## exists today, no new part type required. 0 at the base target (that's
## "sufficient," not "redundant" yet), 100 at 2x the base target.
static func _redundancy_availability(state: Dictionary, category: String) -> float:
	var built: Array = state.get("built_infrastructure", {}).get(category, [])
	var base_target = float(BUILT_TARGETS.get(category, 1.0))
	var full_redundancy_target = base_target * 2.0
	return clamp((float(built.size()) - base_target) / (full_redundancy_target - base_target) * 100.0, 0.0, 100.0)

## Banked amount *beyond* the immediate-use target counts toward reserve
## capacity (Infrastructure Resilience) -- e.g. banking 2x the O2 target
## means half of it is genuinely spare, not just enough to get by. Scaled
## against the same target again, so a full second target's worth of
## surplus reads as 100.
static func _surplus(resources: Dictionary, key: String) -> float:
	var banked = float(resources.get(key, 0.0))
	var target = float(TARGETS.get(key, 1.0))
	return clamp((banked - target) / target * 100.0, 0.0, 100.0)

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
		{"label": "Sanitation availability", "score": _built_availability(state, "sanitation"), "tracked": true},
		{"label": "Basic healthcare access", "score": _built_availability(state, "healthcare"), "tracked": true},
	])

	var silicon = _category([
		{"label": "Electrical power continuity", "score": _built_availability(state, "power"), "tracked": true},
		{"label": "Computational continuity", "score": 100.0, "tracked": false},
		{"label": "Data integrity preservation", "score": 100.0, "tracked": false},
		{"label": "Memory continuity protection", "score": 100.0, "tracked": false},
		{"label": "Communication network availability", "score": 100.0, "tracked": false},
	])

	# Reserve capacity: banked raw + refined industrial materials, as a
	# proxy for "the Commonwealth has reserves it could draw on."
	var reserve_capacity = _availability(resources, "PGM") * 0.4 \
		+ _availability(resources, "Gold") * 0.2 \
		+ _availability(resources, "Platinum") * 0.2 \
		+ _availability(resources, "Steel") * 0.2
	# Life-support surplus: O2/Water/Food banked *beyond* what Biological
	# Life Support already counts as "sufficient" -- a second reserve
	# capacity signal from the same resources, since a civilization with a
	# stockpile beyond immediate needs is more resilient than one running
	# exactly at the line, even at the same headline life-support score.
	var life_support_surplus = (_surplus(resources, "O2") + _surplus(resources, "Potable Water") + _surplus(resources, "Food")) / 3.0
	# Average redundancy across all four "distinct built ships" categories --
	# a civilization with backup shelter but zero backup power isn't fully
	# redundant, so this deliberately can't be carried by just one category.
	var redundancy = (_redundancy_availability(state, "shelter") + _redundancy_availability(state, "power") \
		+ _redundancy_availability(state, "sanitation") + _redundancy_availability(state, "healthcare")) / 4.0
	var infrastructure = _category([
		{"label": "Reserve capacity (raw + refined materials)", "score": reserve_capacity, "tracked": true},
		{"label": "Life-support surplus (O2/Water/Food above target)", "score": life_support_surplus, "tracked": true},
		{"label": "System redundancy (2x built ships per category)", "score": redundancy, "tracked": true},
		{"label": "Recovery capability", "score": 100.0, "tracked": false},
		{"label": "Distribution network reliability", "score": 100.0, "tracked": false},
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

## The two raw feedstocks everything else in the resource chain is made
## from: H2O feeds both Greenhouse Bay (-> Food) and Electrolysis Bay
## (-> Potable Water + O2), and PGM feeds Refinery Bay (-> Gold/Platinum/
## Steel). Every other banked resource is downstream of one of these two,
## so a shortage here is the earliest warning something further down the
## chain is about to run dry -- distinct from VCI's own categories above,
## which score the downstream products themselves. Targets are the same
## kind of judgment-call floor as BUILT_TARGETS: PGM's matches TARGETS'
## own entry for consistency, H2O's is picked a little higher since two
## separate production chains draw on it instead of one.
const CRITICAL_SUPPLY_TARGETS = {
	"H2O": 40.0,
	"PGM": 30.0,
}

## Ordered (not a Dictionary) so callers display H2O before PGM every
## time -- H2O feeds two downstream chains to PGM's one, so it's the
## more critical of the two.
static func critical_supply_health(resources: Dictionary) -> Array:
	var result: Array = []
	for key in ["H2O", "PGM"]:
		var banked = float(resources.get(key, 0.0))
		var target = float(CRITICAL_SUPPLY_TARGETS[key])
		result.append({
			"resource": key,
			"banked": banked,
			"target": target,
			"pct": clamp(banked / target * 100.0, 0.0, 100.0),
		})
	return result
