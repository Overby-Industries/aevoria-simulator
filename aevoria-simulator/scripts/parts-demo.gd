extends Node

# Demonstrates the modular kit-bashing parts system end to end: builds a
# small parts catalog, assembles two blueprints (a mining ship and a
# habitat module) from it, and feeds the habitat's life-support output
# into ResourceCommons -- proving the "bad engineering trips governance"
# tie-in the civil-engineering direction calls for, not just a visual toy.

@onready var assembler: PartAssembler = $PartAssembler
@onready var resource_commons: ResourceCommons = $ResourceCommons

func _ready():
	var catalog := _build_catalog()
	assembler.part_library = catalog

	var ship := _build_ship(assembler)
	ship.position = Vector3(-3, 0, 0)
	add_child(ship)
	print("[PartsDemo] Assembled ship '", ship.name, "' with ", ship.get_child_count(), " attached parts.")

	var habitat := _build_habitat(assembler)
	habitat.position = Vector3(3, 0, 0)
	add_child(habitat)
	print("[PartsDemo] Assembled habitat '", habitat.name, "' with ", habitat.get_child_count(), " attached parts.")

func _build_catalog() -> Array:
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

func _build_ship(p_assembler: PartAssembler) -> Node3D:
	var blueprint := AssemblyBlueprint.new()
	blueprint.ship_id = "Prospector"
	blueprint.root_part_id = "hull_mk1"
	blueprint.attachments = [
		{"attach_id": "thruster_1", "parent_id": "root", "socket_id": "aft", "part_id": "thruster_mk1"},
		{"attach_id": "drill_1", "parent_id": "root", "socket_id": "fore", "part_id": "drill_arm_mk1"},
	]
	blueprint.skin_recipe = {
		"seed": 7, "frequency": 0.08,
		"dark_color": "#26201a", "base_color": "#8a8f96", "highlight_color": "#c7ccd1"
	}

	var stats = p_assembler.compute_aggregate_stats(blueprint)
	print("[PartsDemo] Prospector aggregate stats: ", stats)

	return p_assembler.assemble(blueprint)

func _build_habitat(p_assembler: PartAssembler) -> Node3D:
	var blueprint := AssemblyBlueprint.new()
	blueprint.ship_id = "HabitatAlpha"
	blueprint.root_part_id = "habitat_ring_mk1"
	blueprint.attachments = [
		{"attach_id": "scrubber_1", "parent_id": "root", "socket_id": "bay_1", "part_id": "algae_scrubber_mk1"},
		{"attach_id": "power_1", "parent_id": "root", "socket_id": "power_mount", "part_id": "power_cell_mk1"},
	]
	blueprint.skin_recipe = {
		"seed": 21, "frequency": 0.06,
		"dark_color": "#1a2620", "base_color": "#6ba888", "highlight_color": "#a8d9c1"
	}

	var stats = p_assembler.compute_aggregate_stats(blueprint)
	print("[PartsDemo] HabitatAlpha aggregate stats: ", stats)

	# The civil-engineering tie-in: an assembled habitat's life-support
	# throughput is a real ResourceCommons value, not a cosmetic number --
	# this is what a future CUR regulation would monitor for a shortfall.
	var o2_rate = float(stats.get("o2_throughput", 0.0))
	if o2_rate > 0.0:
		resource_commons.request_resource("O2", o2_rate, "habitat_alpha")
		print("[PartsDemo] O2 commons stock after HabitatAlpha comes online: ", resource_commons.get_resource_stock("O2"))

	return p_assembler.assemble(blueprint)
