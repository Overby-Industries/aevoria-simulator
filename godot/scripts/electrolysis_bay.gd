extends Node3D

## Water split, first slice: raw H2O (mined as comets at the deep-space
## situation table, situation_table.gd)
## can now be split into Potable Water and O2 -- the life-support side
## of the resource loop, alongside Greenhouse Bay's direct H2O -> Food
## use. Three identical electrolysis tanks (unlike Refinery's three
## distinct recipes) since this is one recipe run in parallel, same
## shape as Greenhouse Bay's three grow bays. One split produces two
## outputs at once, which FactionHomeBase already supports -- it's just
## two add_resource calls, no new system needed.

const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const LevelChrome = preload("res://scripts/level_chrome.gd")
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

const H2O_COST: float = 10.0
const POTABLE_WATER_YIELD: float = 6.0
const O2_YIELD: float = 4.0
const TANK_COUNT: int = 3

# Room shell (see docs/GRAPHICS_GUIDE.md System 2 / hangar_backdrop.gd's
# worked example) -- scaled way down from that 100m hangar since this is a
# single small tank room. ElectrolysisBay.tscn's Camera3D sits at local
# (0, 5, 14) pitched upward, the same transform hangar_backdrop.gd's camera
# uses, so the ceiling reads more than the floor right under the camera.
# Depth/width picked to keep the electrolysis tanks (_spawn_tank(), x in
# [-3.9, 3.9], z = 0) comfortably inside the shell with some walking room,
# not to fill a big volume.
const ROOM_HALF_WIDTH := 7.0
const ROOM_DEPTH_NEAR := 16.0   # a bit past the camera, so the floor doesn't visibly end right under it
const ROOM_DEPTH_FAR := -9.0    # back wall, behind the tanks
const CEILING_HEIGHT := 6.0

# Tanks (_spawn_tank()) are 2.0-tall cylinders centered on y=0, so their
# lowest point is y = -1.0 -- the floor's top surface matches that exactly
# so they plant on it instead of floating above it or sinking through it.
const FLOOR_TOP_Y := -1.0

# Base tank-room colors -- dark clinical blue-gray, more technical than
# Greenhouse's green-black and less industrial-grimy than Refinery, per
# the brief. FactionVisuals.backdrop_palette() is blended in at
# FACTION_TINT_WEIGHT so the room still picks up a faint per-faction
# identity without losing that clinical mood or blowing out past what the
# dark glass UI (light_theme stays false) can stay readable against.
const BASE_WALL_COLOR := Color("0e161c")
const BASE_FLOOR_COLOR := Color("090f13")
const FACTION_TINT_WEIGHT := 0.18

@onready var camera: Camera3D = $Camera3D

var _resources_label: Label
var _tank_buttons: Array = []
var _potable_water_this_session: float = 0.0
var _o2_this_session: float = 0.0

func _ready():
	add_child(LevelChrome.new())
	_build_backdrop()
	for i in range(TANK_COUNT):
		_spawn_tank(i)
	_build_ui()
	_refresh()
	camera.make_current()

## Faction resolution mirrors level_chrome.gd's own fallback: correct for
## every level reached the normal way (LevelContext.start_level() sets
## current_faction_id before the scene loads), falls back to the
## Commonwealth if this scene is opened directly (editor "Run Current
## Scene", or a headless smoke test) and it's still "".
func _resolve_faction_id() -> String:
	var faction_id = LevelContext.current_faction_id
	if faction_id == "":
		faction_id = LevelCatalog.AEVORIA_COMMONWEALTH
	return faction_id

## Floor/walls/ceiling/environment around the tanks that were previously
## just floating in Godot's default grey void -- see the Room shell consts
## above for sizing. Called first from _ready() so the shell exists before
## the props that sit inside it.
func _build_backdrop() -> void:
	var palette = FactionVisuals.backdrop_palette(_resolve_faction_id())
	_build_environment(palette)
	_build_floor(palette)
	_build_walls(palette)
	_build_ceiling(palette)
	_build_overhead_lights()

func _build_environment(palette: Dictionary) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = palette["fog"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = palette["light"]
	env.ambient_light_energy = 0.35
	env.glow_enabled = false
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _build_floor(palette: Dictionary) -> void:
	var floor_mesh = SimpleShapes.make_mesh_instance({
		"shape": "box",
		"size": Vector3(ROOM_HALF_WIDTH * 2.0, 0.2, ROOM_DEPTH_NEAR - ROOM_DEPTH_FAR),
		"albedo_color": BASE_FLOOR_COLOR.lerp(palette["floor"], FACTION_TINT_WEIGHT),
	})
	floor_mesh.position = Vector3(0, FLOOR_TOP_Y - 0.1, (ROOM_DEPTH_NEAR + ROOM_DEPTH_FAR) * 0.5)
	add_child(floor_mesh)

func _build_walls(palette: Dictionary) -> void:
	var wall_color = BASE_WALL_COLOR.lerp(palette["wall"], FACTION_TINT_WEIGHT)
	var wall_height = CEILING_HEIGHT - FLOOR_TOP_Y
	var depth = ROOM_DEPTH_NEAR - ROOM_DEPTH_FAR
	var mid_z = (ROOM_DEPTH_NEAR + ROOM_DEPTH_FAR) * 0.5
	var mid_y = FLOOR_TOP_Y + wall_height * 0.5

	var back_wall = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(ROOM_HALF_WIDTH * 2.0, wall_height, 0.3),
		"albedo_color": wall_color,
	})
	back_wall.position = Vector3(0, mid_y, ROOM_DEPTH_FAR)
	add_child(back_wall)

	for x_sign in [-1.0, 1.0]:
		var side_wall = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.3, wall_height, depth),
			"albedo_color": wall_color,
		})
		side_wall.position = Vector3(x_sign * ROOM_HALF_WIDTH, mid_y, mid_z)
		add_child(side_wall)

func _build_ceiling(palette: Dictionary) -> void:
	var ceiling = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(ROOM_HALF_WIDTH * 2.0, 0.2, ROOM_DEPTH_NEAR - ROOM_DEPTH_FAR),
		"albedo_color": BASE_WALL_COLOR.lerp(palette["wall"], FACTION_TINT_WEIGHT),
	})
	ceiling.position = Vector3(0, CEILING_HEIGHT, (ROOM_DEPTH_NEAR + ROOM_DEPTH_FAR) * 0.5)
	add_child(ceiling)

## A couple of plain overhead fixtures -- cool white, not tinted to the
## tanks' cyan glow (_spawn_tank() already covers that accent) -- just
## enough to read as a lit lab ceiling rather than a full grid like Main
## Hangar Deck's (hangar_backdrop.gd). Kept off to the side (x = +-1.6,
## z = -1.5) so neither fixture sits directly over a tank or blocks it.
func _build_overhead_lights() -> void:
	for x_position in [-1.6, 1.6]:
		var fixture = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(2.6, 0.1, 0.8),
			"albedo_color": Color("eaf4ff"),
			"emission_color": Color("cfeeff"), "emission_energy": 2.0,
		})
		fixture.position = Vector3(x_position, CEILING_HEIGHT - 0.3, -1.5)
		add_child(fixture)

		var light = SimpleShapes.make_point_light(Color("cfeeff"), 0.8, 5.0)
		light.position = fixture.position + Vector3(0, -0.3, 0)
		add_child(light)

func _spawn_tank(index: int) -> void:
	var tank_position = Vector3((index - 1) * 3.0, 0, 0)

	var tank = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": 0.9, "height": 2.0,
		"albedo_color": Color("0e2230"),
		"emission_color": Color("4ad6ff"), "emission_energy": 0.5,
	})
	tank.name = "ElectrolysisTank%d" % index
	tank.position = tank_position
	add_child(tank)

	var light = SimpleShapes.make_point_light(Color("4ad6ff"), 1.2, 4.0)
	light.position = tank_position + Vector3(0, 1.3, 0)
	add_child(light)

func _build_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var root_panel = PanelContainer.new()
	root_panel.theme = ThemeBootstrap.theme
	root_panel.custom_minimum_size = Vector2(340, 0)
	root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_panel.position = Vector2(20, 20)
	canvas.add_child(root_panel)

	var bg = _make_glass_background(Color(0.04, 0.09, 0.16, 0.45))
	root_panel.add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "ELECTROLYSIS BAY"
	header.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0))
	outer.add_child(header)

	_resources_label = Label.new()
	_resources_label.add_theme_font_size_override("font_size", 12)
	_resources_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_resources_label)

	outer.add_child(HSeparator.new())

	var tank_header = Label.new()
	tank_header.text = "ELECTROLYSIS TANKS (%.1f H2O -> %.1f Potable Water + %.1f O2 each)" % [H2O_COST, POTABLE_WATER_YIELD, O2_YIELD]
	tank_header.add_theme_font_size_override("font_size", 12)
	tank_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(tank_header)

	for i in range(TANK_COUNT):
		var button = Button.new()
		button.text = "Split Water -- Tank %d" % (i + 1)
		button.pressed.connect(_on_split_pressed)
		outer.add_child(button)
		_tank_buttons.append(button)

	outer.add_child(HSeparator.new())

	# Two destinations, not one -- Electrolysis Bay is a room inside the
	# Hangar Deck, not a direct child of Level Select, so "back" is
	# ambiguous without both options (see main_hangar_deck.gd).
	var nav_row = HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 6)
	outer.add_child(nav_row)

	var hangar_button = Button.new()
	hangar_button.text = "Back to Hangar Deck"
	hangar_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hangar_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainHangarDeck.tscn"))
	nav_row.add_child(hangar_button)

	var back_button = Button.new()
	back_button.text = "Back to Level Select"
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	nav_row.add_child(back_button)

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

func _refresh():
	var state = FactionHomeBase.load_state(LevelContext.current_faction_id)
	var h2o = float(state["resources"].get("H2O", 0.0))
	var potable_water = float(state["resources"].get("Potable Water", 0.0))
	var o2 = float(state["resources"].get("O2", 0.0))
	_resources_label.text = "Commons -- H2O: %.1f   Potable Water: %.1f   O2: %.1f\nSplit this visit: %.1f Potable Water, %.1f O2" % [h2o, potable_water, o2, _potable_water_this_session, _o2_this_session]
	for button in _tank_buttons:
		button.disabled = h2o < H2O_COST
		button.tooltip_text = "" if h2o >= H2O_COST else "Need %.1f H2O banked (have %.1f)." % [H2O_COST, h2o]

func _on_split_pressed():
	var ok = FactionHomeBase.spend_resource(LevelContext.current_faction_id, "H2O", H2O_COST)
	if not ok:
		return
	FactionHomeBase.add_resource(LevelContext.current_faction_id, "Potable Water", POTABLE_WATER_YIELD)
	FactionHomeBase.add_resource(LevelContext.current_faction_id, "O2", O2_YIELD)
	_potable_water_this_session += POTABLE_WATER_YIELD
	_o2_this_session += O2_YIELD

	if LevelContext.current_level_id != "":
		FactionHomeBase.mark_level_complete(LevelContext.current_faction_id, LevelContext.current_level_id)

	_refresh()
