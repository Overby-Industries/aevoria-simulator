# VCI tracking: the Commonwealth's health meter

The Vital Continuity Index (VCI) is the "is this civilization actually
thriving" number shown top-right on the game's front door (LevelSelect).
It isn't a game-specific invention — it's a real, fully-specified metric
from the CUR regulations library (`cur/foundation/cur-foundation-003.md`
§11, and `cur/foundation/cur-foundation-013.md`), already implemented in
the C++ state machine (`cur::CURStateMachine::update_vital_continuity()`).
This doc explains the Godot-side binding, exactly what's real vs. placeholder
in the current score, and how to make more of it real over time.

## The constitutional background (read this before changing scoring)

FOUNDATION-003 §11: VCI measures "the reliability, availability,
resilience, and accessibility of constitutionally guaranteed
life-supporting services," 0-100, **higher is better** (opposite of the
Capture Risk Index, which is 0-100 with higher being *worse* — see the
big warning comment in `cur/include/cur/cur_capture_index.h`). Bands:

| Score  | Band          |
| ------ | ------------- |
| 80-100 | Stable        |
| 60-79  | Observation   |
| 40-59  | Elevated Risk |
| 20-39  | High Risk     |
| 0-19   | Critical      |

A critical score is a **hard constitutional trigger** — FOUNDATION-013
says no compliance state gates a Vital Continuity Service, and a critical
VCI drives STATE-010 Vital Continuity Response with no second condition
and no approval needed. This is why the library treats VCI as a
first-class, always-on measure rather than a cosmetic stat.

`cur::VitalContinuityModel::may_gate_service_access()` returns `false`,
unconditionally, on purpose — **never use a low VCI score to lock a
player out of anything**, in the game or otherwise. Its only legitimate
use is diagnostic: showing the player (and eventually a whole voting
community, see `docs/MULTIPLAYER_ROADMAP.md`) that something needs
attention.

## The Godot binding (`src/cur_compliance_monitor.{h,cpp}`)

Mirrors the existing Capture Risk Index binding exactly:

- `update_vital_continuity(entity_handle, inputs: Dictionary, tick) -> float`
  — `inputs` keys: `biological_life_support`, `silicon_life_support`,
  `infrastructure_resilience`, `accessibility` (each 0-100; these are the
  library's four top-level VCI categories — the sub-measures listed in
  FOUNDATION-003 §11, like "air availability" or "power continuity," are
  **not** separate C++ fields; the caller is responsible for rolling those
  up into the four category scores before calling this).
- `get_vital_continuity() -> float`, `get_vital_continuity_band() -> int`,
  `vital_continuity_band_name(band) -> String`.
- `VCB_STABLE` / `VCB_OBSERVATION` / `VCB_ELEVATED` / `VCB_HIGH_RISK` /
  `VCB_CRITICAL` integer constants (note the direction: `VCB_STABLE` is
  the *top* band, opposite of `CRB_STABLE` being the bottom band for
  Capture Risk — see the comment on the binding).

Unlike Capture Risk, `update_vital_continuity` takes an `EntityHandle` —
this is attribution for audit/logging (which entity's continuity failure
this is), not a way to track multiple simultaneous VCI scores. The score
itself is machine-wide, one number, same as Capture Risk. `level_select.gd`
registers a single throwaway `"commonwealth-vci"` entity for this.

## The Godot-side rollup (`aevoria-simulator/scripts/vci_tracker.gd`)

This is the actual game-design work: turning real banked-resource state
(`FactionHomeBase`) into the four category scores above. **Most of VCI's
~20 sub-measures have no backing game system yet** — there's no AI miner
swarm, no power grid, no habitat count, no multi-citizen population/equity
model. Rather than fake those, every sub-measure is either:

- **`"tracked": true`** — computed from a real banked resource, scaled
  0-100 against a target amount in `vci_tracker.gd`'s `TARGETS` dict
  (banked amount ÷ target, clamped 0-100; no decay/consumption model
  exists yet, so this is deliberately the simplest scoring that's still
  real), or
- **`"tracked": false`** — a flat 100 (neutral, not a false "everything's
  fine" claim skewed either direction), shown dimmed in the UI with a
  "(baseline — not yet tracked)" suffix so it's never presented as more
  real than it is.

Current mapping:

| Category | Sub-measure | Status |
|---|---|---|
| Biological Life Support | Air (O2 reserves) | ✅ tracked — `O2` resource |
| | Water (Potable Water reserves) | ✅ tracked — `Potable Water` resource |
| | Food reserves | ✅ tracked — `Food` resource |
| | Shelter availability | ✅ tracked — distinct saved ships including `habitat_ring_mk1` (`FactionHomeBase.mark_infrastructure_built`, written from `assembly_bay.gd`'s save handler) |
| | Sanitation availability | ✅ tracked — distinct saved ships including the `waste_recycler_mk1` part, same mechanism as Shelter |
| | Basic healthcare access | ✅ tracked — distinct saved ships including the `medbay_mk1` part, same mechanism as Shelter |
| Silicon-Based Life Support | Electrical power continuity | ✅ tracked — distinct saved ships including `power_cell_mk1`, same mechanism as Shelter above |
| | Computational / data / memory / comms continuity | baseline — no silicon-based-life system exists in the game yet at all |
| Infrastructure Resilience | Reserve capacity | ✅ tracked — banked `PGM`/`Gold`/`Platinum`/`Steel` |
| | Life-support surplus | ✅ tracked — `O2`/`Potable Water`/`Food` banked *beyond* their Biological Life Support target, a second reserve-capacity signal from the same resources |
| | System redundancy | ✅ tracked — average across Shelter/Power/Sanitation/Healthcare of distinct built ships *beyond* `BUILT_TARGETS`' base "sufficient" count |
| | Recovery capability / distribution network reliability | baseline — no system yet |
| Accessibility | Service availability | ✅ tracked — banked `CompliancePoints`, as a thin proxy for "the CUR/governance apparatus is functioning" |
| | Distribution effectiveness / equity / consistency | baseline — only one faction/player exists, nothing to be inequitable about yet |

**Shelter/Power/Sanitation/Healthcare scoring**: `FactionHomeBase.mark_infrastructure_built(faction_id, category, ship_id)` records a *distinct* ship id per category (deduped, so re-saving the same ship after a paint job doesn't inflate the count). `vci_tracker.gd`'s `BUILT_TARGETS` currently considers 3 distinct ships equipped with the relevant part (`habitat_ring_mk1`, `power_cell_mk1`, `waste_recycler_mk1`, `medbay_mk1` respectively) "fully sufficient" — a floor to build real numbers up from later, not a researched target, same spirit as the resource `TARGETS` above. The habitat ring gained two new sockets (`sanitation_mount`, `medbay_mount`) to carry the last two parts — `PART_CAT_WASTE_RECYCLER` already existed in `src/part_types.h` unused since the original kit-bashing pass, so only the Medbay category (`PART_CAT_MEDBAY`) needed a new C++ enum entry + rebuild.

**Life-support surplus scoring**: `vci_tracker.gd`'s `_surplus(resources, key)` scores `(banked - target) / target`, clamped 0-100 — banking a full second target's worth beyond what Biological Life Support already needs reads as 100. This double-counts the same banked resource across two categories on purpose: a stockpile beyond immediate needs is a real resilience signal distinct from "are current needs met," which is exactly what FOUNDATION-003 §11 means by Infrastructure Resilience as opposed to the raw life-support scores.

**System redundancy scoring**: `_redundancy_availability(state, category)` reuses the exact same `built_infrastructure` arrays as Shelter/Power/Sanitation/Healthcare above (`mark_infrastructure_built` dedupes by *ship id*, not part id, so a player who saves 6 differently-named habitat ships already produces the data this needs) — 0 at `BUILT_TARGETS`' base count (that's "sufficient," not "redundant" yet), 100 at 2x that count. Averaged across all four categories so backup shelter with zero backup power doesn't read as fully redundant. No new part type was needed for this one, unlike Sanitation/Healthcare above — worth remembering the next time a sub-measure looks "blocked on a missing system": check whether the existing dedup-by-ship-id data already carries the signal before assuming it doesn't.

## How to make more of this real

Each new tracked sub-measure follows the same shape:

1. A gameplay system needs to produce a **banked, queryable value** —
   either a new `FactionHomeBase` resource (cheapest: just call
   `FactionHomeBase.add_resource(...)` from wherever the thing happens,
   same as every existing bay script) or a new piece of state entirely
   (e.g., a habitat count would need something that doesn't exist yet:
   tracking *built* ships/structures, not just banked raw materials).
2. Add a `TARGETS` entry in `vci_tracker.gd` for what "fully sufficient"
   looks like.
3. Flip the relevant sub-measure's `{"score": ..., "tracked": false}` to
   read from that resource with `"tracked": true`.

Good next candidates, roughly in order of how little new infrastructure
they'd need:
- **Recovery capability** (Infrastructure Resilience) still needs an actual
  failure/recovery simulation (something breaking and being repaired) to
  mean anything real — unlike System redundancy above, "having spares"
  and "successfully recovering from a failure" aren't the same claim, so
  this one is still genuinely blocked on a system that doesn't exist yet.
- **Distribution network reliability** and **Distribution effectiveness /
  access equity** (Accessibility) both need more than one faction/player
  actually playing at once to mean anything — natural to revisit once
  `docs/MULTIPLAYER_ROADMAP.md`'s async governance layer exists.
- Everything under Silicon-Based Life Support past Electrical power
  (compute, data integrity, memory continuity, comms) is blocked on the
  "AI Cognitive Health Management" mechanic from the README's vision even
  existing in any form — there's no AI miner swarm system in the game yet
  at all, just the concept.

## Where this is headed

Per the current plan (discussed 2026-07-29): finish fleshing out VCI
tracking as more real systems get built, then use VCI's score/band as the
actual pass/fail and pacing signal for longer campaigns/missions that
span multiple core levels — e.g., "keep the Commonwealth's VCI above
Elevated Risk for N in-game days" as a real objective, instead of each
level being an isolated, disconnected checklist item. That's also the
point at which giving each level a real 3D scene (most are still plain
gray backgrounds) becomes worth the investment — see the front-of-mind
note in CONTRIBUTING.md.
