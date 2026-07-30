extends RefCounted

## Shared demo parts catalog -- used by both parts-demo.gd (a fixed,
## non-interactive showcase) and assembly_bay.gd (the interactive builder),
## so the two never drift out of sync with each other.
##
## No class_name on purpose: consumers preload() this file instead of
## relying on the editor's global class_name cache, which is only
## populated by an editor scan and isn't reliably warm in a headless run.
##
## SCALE CONVENTION: 1 Godot unit = 1 meter. Every hull below is sized to
## real-world aerospace proportions rather than the small arbitrary numbers
## used before -- ssto_hull_helga's 36.58m/30.48m (120ft/100ft) is the
## user-specified anchor; the other hulls and every accessory are sized
## proportionally against it, not to any specific real vehicle. Camera
## framing (assembly_bay.gd, parts-demo.gd) auto-fits to the assembled
## ship's actual bounding box via camera_framing.gd, so it no longer
## depends on a hand-picked distance matching this scale.

const LevelCatalog = preload("res://scripts/level_catalog.gd")

## The three faction-exclusive ship hulls from the user's sketch. Each is a
## drop-in root part like hull_mk1 (same fore/aft socket shape, so the
## existing universal thruster/drill accessories still attach to any of
## them) -- the exclusivity and flavor live in PartDefinition.faction_id,
## the mesh shape, and the stat spread, not in a separate part tree.
## Suggested skin recipes (not part of PartDefinition -- assembly_bay.gd
## applies these itself when a hull is picked) give each faction's ship
## its sketched look without needing per-part color on the C++ side.
const HULL_SKIN_SUGGESTIONS = {
	"ssto_hull_helga": {
		"seed": 0, "frequency": 0.06,
		"dark_color": "#c9ced4", "base_color": "#f0f2f5", "highlight_color": "#ffffff",
	},
	"tube_rocket_hull_mk1": {
		"seed": 0, "frequency": 0.10,
		"dark_color": "#1a1a1a", "base_color": "#4a4a4a", "highlight_color": "#b8862b",
	},
	"drift_hull_mk1": {
		"seed": 0, "frequency": 0.14,
		"dark_color": "#3a2a1a", "base_color": "#8a7a5a", "highlight_color": "#c9a227",
	},
}

static func build_demo_catalog() -> Array:
	var hull := PartDefinition.new()
	hull.part_id = "hull_mk1"
	hull.display_name = "Prospector Hull"
	hull.category = PartDefinition.CAT_HULL_SEGMENT
	hull.mesh_recipe = {"shape": "box", "size": Vector3(4.0, 4.0, 14.0)}
	hull.sockets = [
		{"id": "fore", "position": Vector3(0, 0, -7.0), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_DRILL_ARM},
		{"id": "aft", "position": Vector3(0, 0, 7.0), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_THRUSTER},
	]
	hull.stats = {"mass": 50.0, "cargo_capacity": 10.0}

	var thruster := PartDefinition.new()
	thruster.part_id = "thruster_mk1"
	thruster.display_name = "Ion Thruster"
	thruster.category = PartDefinition.CAT_THRUSTER
	thruster.mesh_recipe = {"shape": "cylinder", "radius": 1.4, "height": 3.5}
	thruster.stats = {"mass": 8.0, "power_draw": 2.0, "thrust": 120.0}

	var drill := PartDefinition.new()
	drill.part_id = "drill_arm_mk1"
	drill.display_name = "Drill Arm"
	drill.category = PartDefinition.CAT_DRILL_ARM
	drill.mesh_recipe = {"shape": "capsule", "radius": 0.9, "height": 6.0}
	drill.stats = {"mass": 12.0, "power_draw": 5.0, "mining_yield": 3.5}

	var habitat_ring := PartDefinition.new()
	habitat_ring.part_id = "habitat_ring_mk1"
	habitat_ring.display_name = "Habitat Ring Segment"
	habitat_ring.category = PartDefinition.CAT_HABITAT_RING
	habitat_ring.mesh_recipe = {"shape": "cylinder", "radius": 6.0, "height": 3.0}
	habitat_ring.sockets = [
		{"id": "bay_1", "position": Vector3(7.0, 0, 0), "rotation_deg": Vector3(0, 0, 90), "accepts": (1 << PartDefinition.CAT_O2_SCRUBBER) | (1 << PartDefinition.CAT_HYDROPONICS_BAY)},
		{"id": "power_mount", "position": Vector3(-7.0, 0, 0), "rotation_deg": Vector3(0, 0, 90), "accepts": 1 << PartDefinition.CAT_POWER_CELL},
	]
	habitat_ring.stats = {"mass": 200.0}

	var scrubber := PartDefinition.new()
	scrubber.part_id = "algae_scrubber_mk1"
	scrubber.display_name = "Algae O2 Scrubber"
	scrubber.category = PartDefinition.CAT_O2_SCRUBBER
	scrubber.mesh_recipe = {"shape": "capsule", "radius": 1.2, "height": 3.0}
	scrubber.stats = {"mass": 15.0, "power_draw": 3.0, "o2_throughput": 2.4}

	var power_cell := PartDefinition.new()
	power_cell.part_id = "power_cell_mk1"
	power_cell.display_name = "Power Cell"
	power_cell.category = PartDefinition.CAT_POWER_CELL
	power_cell.mesh_recipe = {"shape": "cylinder", "radius": 1.1, "height": 2.8}
	power_cell.stats = {"mass": 20.0, "power_generation": 10.0}

	# Faction-exclusive hulls -- same fore/aft socket shape as hull_mk1 so
	# thruster_mk1/drill_arm_mk1 still fit, but each is gated to one faction.
	var ssto_hull := PartDefinition.new()
	ssto_hull.part_id = "ssto_hull_helga"
	ssto_hull.display_name = "SSTO Hull -- Project Helga"
	ssto_hull.category = PartDefinition.CAT_HULL_SEGMENT
	ssto_hull.faction_id = LevelCatalog.AEVORIA_COMMONWEALTH
	# 36.58m fuselage / 30.48m wingspan = the user-specified 120ft/100ft for
	# Project Helga, not a scaled-up version of the old toy numbers -- the
	# old radius:height ratio would've given an unrealistically fat ~11m
	# fuselage diameter, so radius/nose/wing proportions below are instead
	# picked to read as shuttle-like (real Space Shuttle orbiter: ~37m
	# length, ~5.3m fuselage diameter) rather than mechanically rescaled.
	ssto_hull.mesh_recipe = {
		"shape": "winged_fuselage", "radius": 2.7, "height": 36.58,
		"nose_length": 4.5, "nose_tip_radius": 0.15,
		"wing_span": 15.24, "wing_root_chord": 12.0, "wing_tip_sweep": 12.7,
		"wing_thickness": 0.6, "wing_y_offset": -3.05,
	}
	ssto_hull.sockets = [
		{"id": "fore", "position": Vector3(0, 0, -18.29), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_DRILL_ARM},
		{"id": "aft", "position": Vector3(0, 0, 18.29), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_THRUSTER},
	]
	ssto_hull.stats = {"mass": 35.0, "cargo_capacity": 6.0}

	var tube_rocket_hull := PartDefinition.new()
	tube_rocket_hull.part_id = "tube_rocket_hull_mk1"
	tube_rocket_hull.display_name = "Tube Rocket Hull"
	tube_rocket_hull.category = PartDefinition.CAT_HULL_SEGMENT
	tube_rocket_hull.faction_id = LevelCatalog.OLIGARCH_COMBINE
	tube_rocket_hull.mesh_recipe = {"shape": "cylinder", "radius": 4.5, "height": 42.0}
	tube_rocket_hull.sockets = [
		{"id": "fore", "position": Vector3(0, 0, -21.0), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_DRILL_ARM},
		{"id": "aft", "position": Vector3(0, 0, 21.0), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_THRUSTER},
	]
	tube_rocket_hull.stats = {"mass": 70.0, "cargo_capacity": 18.0}

	var drift_hull := PartDefinition.new()
	drift_hull.part_id = "drift_hull_mk1"
	drift_hull.display_name = "Drift Hull"
	drift_hull.category = PartDefinition.CAT_HULL_SEGMENT
	drift_hull.faction_id = LevelCatalog.NOMAD_FLOTILLA
	drift_hull.mesh_recipe = {"shape": "box", "size": Vector3(5.5, 4.5, 19.0)}
	drift_hull.sockets = [
		{"id": "fore", "position": Vector3(0, 0, -9.5), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_DRILL_ARM},
		{"id": "aft", "position": Vector3(0, 0, 9.5), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_THRUSTER},
	]
	drift_hull.stats = {"mass": 45.0, "cargo_capacity": 14.0}

	return [hull, thruster, drill, habitat_ring, scrubber, power_cell, ssto_hull, tube_rocket_hull, drift_hull]
