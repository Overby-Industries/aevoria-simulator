extends Node3D

## The solar-system-scale table above situation_table.gd's per-faction
## asteroid field: a wide tactical view of the sun, a few decorative
## planets, the asteroid belt, a faint outer Oort-cloud ring, and every
## faction's claimed stations plotted on a fixed 12-slot ring
## (solar_system_state.gd). Your own claimed sectors open onto the
## existing shared Hangar Deck (main_hangar_deck.gd); unclaimed sectors
## can be built out into a new station by spending a fixed resource
## bundle. Also the one place a faction's whole population (summed
## across every station it holds) gets balanced against banked Food/
## Potable Water -- see the Civil Engineering section below.
##
## Same table-camera technique as situation_table.gd (look_at() once,
## then only tween the camera's world position by a fixed offset), and
## the same ItemList-driven selection instead of 3D picking -- there's no
## raycast/Area3D click pattern anywhere else in this codebase to break
## from.

const LevelCatalog = preload("res://scripts/level_catalog.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const SolarSystemState = preload("res://scripts/solar_system_state.gd")
const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelChrome = preload("res://scripts/level_chrome.gd")
const Starfield = preload("res://scripts/starfield.gd")
const SpaceEnvironment = preload("res://scripts/space_environment.gd")

const WIDE_OFFSET = Vector3(0, 26, 11)
const ZOOM_OFFSET = Vector3(0, 6, 2.6)
const CAMERA_MOVE_SECONDS = 0.6

## Fixed resource bundle to build a new station on an unclaimed sector --
## Steel/Gold spent directly, Nickel spent directly (structural alloy),
## and the two Regolith-derived refinery outputs (refinery_bay.gd) for
## the hull's pressure shell and radiation/debris shielding.
const EXPANSION_COST = {
	"Steel": 40.0, "Gold": 15.0, "Nickel": 25.0,
	"UHPC Concrete": 15.0, "Shield Plating": 10.0,
}

## Per-cycle upkeep, per resident -- deliberately not a real-time drain
## (nothing else in this codebase ticks an economy per-frame; mining/
## refining/growing are all explicit player-triggered actions), so
## consumption only happens when "Run Supply Cycle" is pressed.
const FOOD_PER_POP = 0.4
const WATER_PER_POP = 0.4

const GROW_AMOUNT = 5
const GROW_FOOD_COST = 10.0
const GROW_WATER_COST = 10.0

const HANGAR_LEVEL_ID_BY_FACTION = {
	LevelCatalog.AEVORIA_COMMONWEALTH: "main_hangar_deck",
	LevelCatalog.OLIGARCH_COMBINE: "oligarch_hangar_deck",
	LevelCatalog.NOMAD_FLOTILLA: "nomad_hangar_deck",
}

const PLANETS = [
	{"orbit_radius": 4.0, "angle_deg": 40.0, "size": 0.5, "color": "8a6a4a"},
	{"orbit_radius": 6.5, "angle_deg": 160.0, "size": 0.85, "color": "3d6b8a"},
	{"orbit_radius": 9.5, "angle_deg": 260.0, "size": 0.7, "color": "b8a06a"},
]
const BELT_RADIUS_RANGE = Vector2(10.5, 12.0)
const BELT_ROCK_COUNT = 40
const OORT_RADIUS = 19.0

@onready var camera: Camera3D = $Camera3D

var _claims: Dictionary = {}
var _slots_by_id: Dictionary = {}
var _table_root: Node3D
var _selected_sector_id: String = ""

var _sector_list: ItemList
var _list_index_to_id: Array = []
var _detail_label: Label
var _expand_button: Button
var _enter_button: Button
var _civil_label: Label
var _run_cycle_button: Button
var _grow_button: Button
var _status_label: Label

func _ready():
	add_child(LevelChrome.new())
	add_child(SpaceEnvironment.build())
	Starfield.spawn(self)
	_build_sun()
	_build_planets()
	_build_belt()
	_build_oort_cloud()

	for slot in SolarSystemState.sector_slots():
		_slots_by_id[slot["id"]] = slot

	camera.global_position = Vector3.ZERO + WIDE_OFFSET
	camera.look_at(Vector3.ZERO, Vector3.UP)

	_build_ui()
	_refresh_sectors()
	_refresh_ui()

func _slot_position(slot: Dictionary) -> Vector3:
	var rad = deg_to_rad(float(slot["angle_deg"]))
	var radius = float(slot["radius"])
	return Vector3(cos(rad) * radius, 0.0, sin(rad) * radius)

func _build_sun() -> void:
	var sun = SimpleShapes.make_mesh_instance({
		"shape": "sphere", "radius": 1.0, "radial_segments": 20, "rings": 12,
		"albedo_color": Color(1.0, 0.95, 0.8),
		"emission_color": Color(1.0, 0.9, 0.6), "emission_energy": 4.0,
	})
	add_child(sun)
	var light = SimpleShapes.make_point_light(Color(1.0, 0.92, 0.75), 2.5, 40.0)
	add_child(light)

func _build_planets() -> void:
	for planet in PLANETS:
		var rad = deg_to_rad(float(planet["angle_deg"]))
		var position = Vector3(cos(rad) * float(planet["orbit_radius"]), 0.0, sin(rad) * float(planet["orbit_radius"]))
		var mesh_instance = SimpleShapes.make_mesh_instance({
			"shape": "sphere", "radius": float(planet["size"]), "radial_segments": 14, "rings": 8,
			"albedo_color": Color(planet["color"]),
		})
		mesh_instance.position = position
		add_child(mesh_instance)

func _build_belt() -> void:
	var rng = RandomNumberGenerator.new()
	for i in range(BELT_ROCK_COUNT):
		var angle = rng.randf_range(0.0, TAU)
		var radius = rng.randf_range(BELT_RADIUS_RANGE.x, BELT_RADIUS_RANGE.y)
		var rock = SimpleShapes.make_mesh_instance({
			"shape": "sphere", "radius": rng.randf_range(0.04, 0.1), "radial_segments": 6, "rings": 4,
			"albedo_color": Color("6a6a64"),
		})
		rock.position = Vector3(cos(angle) * radius, rng.randf_range(-0.15, 0.15), sin(angle) * radius)
		add_child(rock)

func _build_oort_cloud() -> void:
	# Sparse, faint, far-out -- a second Starfield-style particle shell
	# well beyond the sector ring, distinguishing "deep, unclaimed
	# frontier" from the claimable ring at SolarSystemState.SLOT_RADIUS.
	var particles = GPUParticles3D.new()
	particles.amount = 220
	particles.lifetime = 60.0
	particles.preprocess = 60.0
	particles.emitting = true
	particles.visibility_aabb = AABB(Vector3(-OORT_RADIUS, -OORT_RADIUS, -OORT_RADIUS) * 1.3, Vector3(OORT_RADIUS, OORT_RADIUS, OORT_RADIUS) * 2.6)

	var mesh = SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	mesh.radial_segments = 4
	mesh.rings = 2
	particles.draw_pass_1 = mesh

	var process_material = ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	process_material.emission_ring_radius = OORT_RADIUS
	process_material.emission_ring_inner_radius = OORT_RADIUS * 0.85
	process_material.emission_ring_height = 1.5
	process_material.emission_ring_axis = Vector3.UP
	process_material.direction = Vector3.ZERO
	process_material.spread = 0.0
	process_material.gravity = Vector3.ZERO
	process_material.initial_velocity_min = 0.0
	process_material.initial_velocity_max = 0.0
	process_material.scale_min = 0.5
	process_material.scale_max = 1.6
	process_material.color = Color(0.55, 0.6, 0.7, 0.5)
	particles.process_material = process_material

	add_child(particles)

func _refresh_sectors() -> void:
	if _table_root:
		_table_root.queue_free()
	_table_root = Node3D.new()
	add_child(_table_root)

	_claims = SolarSystemState.get_claims()
	for slot_id in _slots_by_id.keys():
		_spawn_sector_marker(_slots_by_id[slot_id])

func _spawn_sector_marker(slot: Dictionary) -> void:
	var slot_id: String = slot["id"]
	var position = _slot_position(slot)
	var claim = _claims.get(slot_id)

	if claim == null:
		var outline = SimpleShapes.make_mesh_instance({
			"shape": "sphere", "radius": 0.18, "radial_segments": 8, "rings": 6,
			"albedo_color": Color(0.4, 0.45, 0.5, 0.5),
			"emission_color": Color(0.5, 0.55, 0.6), "emission_energy": 0.15,
		})
		outline.position = position
		_table_root.add_child(outline)

		var label = Label3D.new()
		label.text = "Unclaimed"
		label.font_size = 26
		label.pixel_size = 0.01
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = position + Vector3(0, 0.6, 0)
		label.modulate = Color(0.6, 0.65, 0.7)
		_table_root.add_child(label)
		return

	var faction_id: String = claim["faction_id"]
	var territory_color = FactionVisuals.territory_color(faction_id)

	var puck = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": 1.6, "height": 0.04,
		"albedo_color": Color(territory_color.r, territory_color.g, territory_color.b, 0.28),
	})
	puck.position = position
	var puck_material: StandardMaterial3D = puck.material_override
	puck_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puck_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_table_root.add_child(puck)

	var spec = FactionVisuals.ship_marker_spec(faction_id)
	var station_recipe = {"shape": spec["shape"], "emission_color": Color(spec["color"]), "emission_energy": 0.6}
	if spec.has("size"):
		station_recipe["size"] = spec["size"]
	if spec.has("radius"):
		station_recipe["radius"] = spec["radius"]
		station_recipe["height"] = spec["height"]
	var station = SimpleShapes.make_mesh_instance(station_recipe)
	station.position = position + Vector3(0, 0.3, 0)
	_table_root.add_child(station)

	var label = Label3D.new()
	label.text = "%s\n%s -- pop %d" % [claim["station_name"], LevelCatalog.faction_label(faction_id), int(claim["population"])]
	label.font_size = 26
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = position + Vector3(0, 0.9, 0)
	label.modulate = Color(spec["color"])
	_table_root.add_child(label)

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var root_panel = PanelContainer.new()
	root_panel.theme = ThemeBootstrap.theme
	root_panel.custom_minimum_size = Vector2(360, 0)
	root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_panel.position = Vector2(20, 20)
	canvas.add_child(root_panel)

	var bg = _make_glass_background(Color(0.05, 0.06, 0.12, 0.45))
	root_panel.add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 620)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "SOLAR SYSTEM SITUATION VIEW"
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)

	var subheader = Label.new()
	subheader.text = "Select a sector. Your own stations open onto the Hangar Deck; unclaimed sectors can be built out into a new station."
	subheader.add_theme_font_size_override("font_size", 10)
	subheader.add_theme_color_override("font_color", Color(0.6, 0.68, 0.78))
	subheader.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subheader.custom_minimum_size = Vector2(330, 0)
	outer.add_child(subheader)

	outer.add_child(HSeparator.new())

	var list_header = Label.new()
	list_header.text = "SECTORS (12 slots)"
	list_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(list_header)

	_sector_list = ItemList.new()
	_sector_list.custom_minimum_size = Vector2(0, 180)
	_sector_list.item_selected.connect(_on_list_item_selected)
	outer.add_child(_sector_list)

	_detail_label = Label.new()
	_detail_label.add_theme_font_size_override("font_size", 11)
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.custom_minimum_size = Vector2(330, 0)
	outer.add_child(_detail_label)

	_enter_button = Button.new()
	_enter_button.text = "Enter Hangar Deck"
	_enter_button.visible = false
	_enter_button.pressed.connect(_on_enter_hangar_pressed)
	outer.add_child(_enter_button)

	_expand_button = Button.new()
	_expand_button.visible = false
	_expand_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_expand_button.pressed.connect(_on_expand_pressed)
	outer.add_child(_expand_button)

	outer.add_child(HSeparator.new())

	var civil_header = Label.new()
	civil_header.text = "CIVIL ENGINEERING"
	civil_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(civil_header)

	_civil_label = Label.new()
	_civil_label.add_theme_font_size_override("font_size", 11)
	_civil_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_civil_label.custom_minimum_size = Vector2(330, 0)
	outer.add_child(_civil_label)

	_run_cycle_button = Button.new()
	_run_cycle_button.text = "Run Supply Cycle"
	_run_cycle_button.pressed.connect(_on_run_cycle_pressed)
	outer.add_child(_run_cycle_button)

	_grow_button = Button.new()
	_grow_button.text = "Grow Population (+%d) at selected station" % GROW_AMOUNT
	_grow_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_grow_button.pressed.connect(_on_grow_pressed)
	outer.add_child(_grow_button)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.7))
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(330, 0)
	outer.add_child(_status_label)

	outer.add_child(HSeparator.new())

	var back_button = Button.new()
	back_button.text = "Back to Level Select"
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	outer.add_child(back_button)

func _make_glass_background(tint: Color) -> ColorRect:
	var bg = ColorRect.new()
	bg.color = Color(1, 1, 1, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = load("res://shaders/frosted_glass_panel.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("blur_amount", 2.0)
	mat.set_shader_parameter("tint_color", tint)
	bg.material = mat
	return bg

func _refresh_ui() -> void:
	_refresh_list()
	_refresh_detail_panel()
	_refresh_civil_panel()

func _refresh_list() -> void:
	_sector_list.clear()
	_list_index_to_id.clear()
	var slot_ids = _slots_by_id.keys()
	slot_ids.sort()
	for slot_id in slot_ids:
		var claim = _claims.get(slot_id)
		if claim == null:
			_sector_list.add_item("%s -- Unclaimed" % slot_id)
		else:
			_sector_list.add_item("%s -- %s (%s, pop %d)" % [slot_id, claim["station_name"], LevelCatalog.faction_label(claim["faction_id"]), int(claim["population"])])
		_list_index_to_id.append(slot_id)

func _on_list_item_selected(index: int) -> void:
	_selected_sector_id = _list_index_to_id[index]
	_zoom_to(_slot_position(_slots_by_id[_selected_sector_id]))
	_refresh_detail_panel()
	_refresh_civil_panel()

func _zoom_to(target: Vector3) -> void:
	var tween = create_tween()
	tween.tween_property(camera, "global_position", target + ZOOM_OFFSET, CAMERA_MOVE_SECONDS).set_trans(Tween.TRANS_SINE)

func _zoom_out() -> void:
	var tween = create_tween()
	tween.tween_property(camera, "global_position", Vector3.ZERO + WIDE_OFFSET, CAMERA_MOVE_SECONDS).set_trans(Tween.TRANS_SINE)

func _current_faction() -> String:
	var faction_id = LevelContext.current_faction_id
	if faction_id == "":
		faction_id = LevelCatalog.AEVORIA_COMMONWEALTH
	return faction_id

## Reads banked resources directly rather than calling spend_resource
## speculatively, so an unaffordable multi-line cost never partially
## spends before failing on a later line.
static func _can_afford(resources: Dictionary, cost: Dictionary) -> bool:
	for resource_name in cost.keys():
		if float(resources.get(resource_name, 0.0)) < float(cost[resource_name]):
			return false
	return true

func _refresh_detail_panel() -> void:
	_enter_button.visible = false
	_expand_button.visible = false
	if _selected_sector_id == "":
		_detail_label.text = "Select a sector from the list above."
		return

	var faction_id = _current_faction()
	var claim = _claims.get(_selected_sector_id)
	if claim == null:
		var state = FactionHomeBase.load_state(faction_id)
		var affordable = _can_afford(state["resources"], EXPANSION_COST)
		var cost_lines: Array = []
		for resource_name in EXPANSION_COST.keys():
			cost_lines.append("%s %.0f" % [resource_name, EXPANSION_COST[resource_name]])
		_detail_label.text = "%s is unclaimed. Building a station here costs: %s." % [_selected_sector_id, ", ".join(cost_lines)]
		_expand_button.text = "Expand Here" if affordable else "Expand Here (insufficient resources)"
		_expand_button.disabled = not affordable
		_expand_button.visible = true
	else:
		_detail_label.text = "%s -- %s\nOwned by %s, population %d." % [_selected_sector_id, claim["station_name"], LevelCatalog.faction_label(claim["faction_id"]), int(claim["population"])]
		if claim["faction_id"] == faction_id:
			_enter_button.visible = true

func _refresh_civil_panel() -> void:
	var faction_id = _current_faction()
	var total_population = SolarSystemState.total_population(faction_id)
	var food_needed = float(total_population) * FOOD_PER_POP
	var water_needed = float(total_population) * WATER_PER_POP
	var state = FactionHomeBase.load_state(faction_id)
	var food_have = float(state["resources"].get("Food", 0.0))
	var water_have = float(state["resources"].get("Potable Water", 0.0))
	var short = food_have < food_needed or water_have < water_needed

	var lines = [
		"Total population: %d" % total_population,
		"Per-cycle upkeep: %.1f Food, %.1f Potable Water" % [food_needed, water_needed],
		"Banked: %.1f Food, %.1f Potable Water" % [food_have, water_have],
	]
	if short:
		lines.append("WARNING: not enough banked to run a supply cycle -- grow greenhouse/electrolysis production before adding more population.")
	_civil_label.text = "\n".join(lines)
	_civil_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.5) if short else Color(0.75, 0.85, 0.95))
	_run_cycle_button.disabled = short

	var selected_claim = _claims.get(_selected_sector_id)
	var can_grow = selected_claim != null and selected_claim["faction_id"] == faction_id and _can_afford(state["resources"], {"Food": GROW_FOOD_COST, "Potable Water": GROW_WATER_COST})
	_grow_button.disabled = not can_grow

func _on_expand_pressed() -> void:
	if _selected_sector_id == "" or _claims.has(_selected_sector_id):
		return
	var faction_id = _current_faction()
	var state = FactionHomeBase.load_state(faction_id)
	if not _can_afford(state["resources"], EXPANSION_COST):
		return
	for resource_name in EXPANSION_COST.keys():
		FactionHomeBase.spend_resource(faction_id, resource_name, EXPANSION_COST[resource_name])

	var station_name = "%s Outpost (%s)" % [LevelCatalog.faction_label(faction_id), _selected_sector_id]
	SolarSystemState.claim_sector(_selected_sector_id, faction_id, station_name)
	SystemLog.log("[Situation View] %s claimed %s -- new station founded." % [LevelCatalog.faction_label(faction_id), _selected_sector_id])
	_status_label.text = "Claimed %s. New station founded." % _selected_sector_id

	_refresh_sectors()
	_refresh_ui()

func _on_run_cycle_pressed() -> void:
	var faction_id = _current_faction()
	var total_population = SolarSystemState.total_population(faction_id)
	var food_needed = float(total_population) * FOOD_PER_POP
	var water_needed = float(total_population) * WATER_PER_POP
	var state = FactionHomeBase.load_state(faction_id)
	if not _can_afford(state["resources"], {"Food": food_needed, "Potable Water": water_needed}):
		return
	FactionHomeBase.spend_resource(faction_id, "Food", food_needed)
	FactionHomeBase.spend_resource(faction_id, "Potable Water", water_needed)
	SystemLog.log("[Situation View] %s ran a supply cycle: -%.1f Food, -%.1f Potable Water." % [LevelCatalog.faction_label(faction_id), food_needed, water_needed])
	_status_label.text = "Supply cycle complete."
	_refresh_ui()

func _on_grow_pressed() -> void:
	var faction_id = _current_faction()
	var claim = _claims.get(_selected_sector_id)
	if claim == null or claim["faction_id"] != faction_id:
		return
	var state = FactionHomeBase.load_state(faction_id)
	if not _can_afford(state["resources"], {"Food": GROW_FOOD_COST, "Potable Water": GROW_WATER_COST}):
		return
	FactionHomeBase.spend_resource(faction_id, "Food", GROW_FOOD_COST)
	FactionHomeBase.spend_resource(faction_id, "Potable Water", GROW_WATER_COST)
	SolarSystemState.grow_population(_selected_sector_id, GROW_AMOUNT)
	SystemLog.log("[Situation View] %s grew %s by %d." % [LevelCatalog.faction_label(faction_id), _selected_sector_id, GROW_AMOUNT])
	_status_label.text = "Population grew at %s." % _selected_sector_id

	_refresh_sectors()
	_refresh_ui()

func _on_enter_hangar_pressed() -> void:
	var faction_id = _current_faction()
	var level_id = HANGAR_LEVEL_ID_BY_FACTION.get(faction_id, "main_hangar_deck")
	LevelContext.start_level(level_id, faction_id)
	get_tree().change_scene_to_file("res://scenes/MainHangarDeck.tscn")
