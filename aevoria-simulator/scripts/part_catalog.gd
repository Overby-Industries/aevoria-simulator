extends RefCounted

## Shared demo parts catalog -- used by both parts-demo.gd (a fixed,
## non-interactive showcase) and assembly_bay.gd (the interactive builder),
## so the two never drift out of sync with each other.
##
## No class_name on purpose: consumers preload() this file instead of
## relying on the editor's global class_name cache, which is only
## populated by an editor scan and isn't reliably warm in a headless run.

static func build_demo_catalog() -> Array:
	var hull := PartDefinition.new()
	hull.part_id = "hull_mk1"
	hull.display_name = "Prospector Hull"
	hull.category = PartDefinition.CAT_HULL_SEGMENT
	hull.mesh_recipe = {"shape": "box", "size": Vector3(1.0, 1.0, 3.0)}
	hull.sockets = [
		{"id": "fore", "position": Vector3(0, 0, -1.5), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_DRILL_ARM},
		{"id": "aft", "position": Vector3(0, 0, 1.5), "rotation_deg": Vector3.ZERO, "accepts": 1 << PartDefinition.CAT_THRUSTER},
	]
	hull.stats = {"mass": 50.0, "cargo_capacity": 10.0}

	var thruster := PartDefinition.new()
	thruster.part_id = "thruster_mk1"
	thruster.display_name = "Ion Thruster"
	thruster.category = PartDefinition.CAT_THRUSTER
	thruster.mesh_recipe = {"shape": "cylinder", "radius": 0.3, "height": 0.8}
	thruster.stats = {"mass": 8.0, "power_draw": 2.0, "thrust": 120.0}

	var drill := PartDefinition.new()
	drill.part_id = "drill_arm_mk1"
	drill.display_name = "Drill Arm"
	drill.category = PartDefinition.CAT_DRILL_ARM
	drill.mesh_recipe = {"shape": "capsule", "radius": 0.2, "height": 1.2}
	drill.stats = {"mass": 12.0, "power_draw": 5.0, "mining_yield": 3.5}

	var habitat_ring := PartDefinition.new()
	habitat_ring.part_id = "habitat_ring_mk1"
	habitat_ring.display_name = "Habitat Ring Segment"
	habitat_ring.category = PartDefinition.CAT_HABITAT_RING
	habitat_ring.mesh_recipe = {"shape": "cylinder", "radius": 1.2, "height": 0.6}
	habitat_ring.sockets = [
		{"id": "bay_1", "position": Vector3(1.4, 0, 0), "rotation_deg": Vector3(0, 0, 90), "accepts": (1 << PartDefinition.CAT_O2_SCRUBBER) | (1 << PartDefinition.CAT_HYDROPONICS_BAY)},
		{"id": "power_mount", "position": Vector3(-1.4, 0, 0), "rotation_deg": Vector3(0, 0, 90), "accepts": 1 << PartDefinition.CAT_POWER_CELL},
	]
	habitat_ring.stats = {"mass": 200.0}

	var scrubber := PartDefinition.new()
	scrubber.part_id = "algae_scrubber_mk1"
	scrubber.display_name = "Algae O2 Scrubber"
	scrubber.category = PartDefinition.CAT_O2_SCRUBBER
	scrubber.mesh_recipe = {"shape": "capsule", "radius": 0.4, "height": 1.0}
	scrubber.stats = {"mass": 15.0, "power_draw": 3.0, "o2_throughput": 2.4}

	var power_cell := PartDefinition.new()
	power_cell.part_id = "power_cell_mk1"
	power_cell.display_name = "Power Cell"
	power_cell.category = PartDefinition.CAT_POWER_CELL
	power_cell.mesh_recipe = {"shape": "cylinder", "radius": 0.35, "height": 0.9}
	power_cell.stats = {"mass": 20.0, "power_generation": 10.0}

	return [hull, thruster, drill, habitat_ring, scrubber, power_cell]
