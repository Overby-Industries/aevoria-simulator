extends Node

# Demonstrates the modular kit-bashing parts system end to end: builds a
# small parts catalog, assembles two blueprints (a mining ship and a
# habitat module) from it, and feeds the habitat's life-support output
# into ResourceCommons -- proving the "bad engineering trips governance"
# tie-in the civil-engineering direction calls for, not just a visual toy.

const PartCatalog = preload("res://scripts/part_catalog.gd")

@onready var assembler: PartAssembler = $PartAssembler
@onready var resource_commons: ResourceCommons = $ResourceCommons
@onready var camera: Camera3D = $Camera3D

func _ready():
	var catalog := PartCatalog.build_demo_catalog()
	assembler.part_library = catalog

	var ship := _build_ship(assembler)
	ship.position = Vector3(-3, 0, 0)
	add_child(ship)
	print("[PartsDemo] Assembled ship '", ship.name, "' with ", ship.get_child_count(), " attached parts.")

	var habitat := _build_habitat(assembler)
	habitat.position = Vector3(3, 0, 0)
	add_child(habitat)
	print("[PartsDemo] Assembled habitat '", habitat.name, "' with ", habitat.get_child_count(), " attached parts.")

	# Frame both assembled objects regardless of the camera's starting
	# transform in the .tscn -- guarantees they're actually on-screen
	# instead of relying on hand-picked numbers being exactly right.
	camera.make_current()
	camera.look_at((ship.position + habitat.position) * 0.5, Vector3.UP)

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
