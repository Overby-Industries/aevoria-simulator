extends Node3D

## Second half of the resource loop the first asteroid-mining slice
## started: banked H2O converts into Food here, in LED-lit grow bays
## inside the station -- matches the user's own framing almost verbatim
## ("growing food in another level inside the space station... rooms
## with LEDS lights could work for now, it all can be very basic").
## Same explicit-UI-command pattern as asteroid_field.gd (Plant &
## Harvest resolves instantly, no real-time grow wait) so this stays
## testable headless the same way -- no wall-clock timers to fake.

const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const LevelChrome = preload("res://scripts/level_chrome.gd")
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

const H2O_COST: float = 10.0
const FOOD_YIELD: float = 6.0
const BAY_COUNT: int = 3

# Room shell (see docs/GRAPHICS_GUIDE.md System 2 / hangar_backdrop.gd's
# worked example) -- scaled way down from that 100m hangar since this is a
# single small hydroponics bay. GreenhouseBay.tscn's Camera3D sits at local
# (0, 5, 14) pitched upward, the same transform hangar_backdrop.gd's camera
# uses, so the ceiling reads more than the floor right under the camera.
# Depth/width picked to keep the grow-bay racks (_spawn_bay_rack(), x in
# [-4.4, 4.4], z = 0) and the desk (_spawn_desk(), z = 3.0) comfortably
# inside the shell with some breathing room, not to fill a big volume.
const ROOM_HALF_WIDTH := 7.0
const ROOM_DEPTH_NEAR := 16.0   # a bit past the camera, so the floor doesn't visibly end right under it
const ROOM_DEPTH_FAR := -9.0    # back wall, behind the racks/desk
const CEILING_HEIGHT := 6.0

# Racks (_spawn_bay_rack()) and the desk (_spawn_desk()) both have their
# lowest point at y = -0.8 (rack: 1.6-tall box centered on y=0; desk
# support: 0.5-tall box centered on y=-0.55) -- the floor's top surface
# matches that exactly so those props plant on it instead of floating
# above it or sinking through it.
const FLOOR_TOP_Y := -0.8

# Base hydroponics-bay colors -- dark and green-black rather than the
# gunmetal an industrial room would use, per the "cleaner/greener/
# brighter-accented than Refinery" brief. FactionVisuals.backdrop_palette()
# is blended in at FACTION_TINT_WEIGHT so the room still picks up a faint
# per-faction identity without losing that greenhouse mood or blowing out
# past what the dark glass UI (light_theme stays false) can stay readable
# against.
const BASE_WALL_COLOR := Color("101a14")
const BASE_FLOOR_COLOR := Color("0b120d")
const FACTION_TINT_WEIGHT := 0.18

@onready var camera: Camera3D = $Camera3D

var _resources_label: Label
var _bay_buttons: Array = []
var _harvested_this_session: float = 0.0

func _ready():
	add_child(LevelChrome.new())
	_build_backdrop()
	for i in range(BAY_COUNT):
		_spawn_bay_rack(i)
	_spawn_desk()
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

## Floor/walls/ceiling/environment around the racks and desk that were
## previously just floating in Godot's default grey void -- see the Room
## shell consts above for sizing. Called first from _ready() so the shell
## exists before the props that sit inside it.
func _build_backdrop() -> void:
	var palette = FactionVisuals.backdrop_palette(_resolve_faction_id())
	_build_environment(palette)
	_build_floor(palette)
	_build_walls(palette)
	_build_ceiling(palette)
	_build_grow_lights()

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

## A couple of overhead grow-light fixtures beyond what each rack's own LED
## strip (_spawn_bay_rack()) already provides -- just a hint that the
## ceiling itself is doing hydroponic-lighting work, not a full grid like
## Main Hangar Deck's (hangar_backdrop.gd). Kept off to the side (x = +-1.6,
## z = -1.5) so neither fixture sits directly over a rack or blocks it.
func _build_grow_lights() -> void:
	for x_position in [-1.6, 1.6]:
		var fixture = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(2.6, 0.1, 0.8),
			"albedo_color": Color("d8fff0"),
			"emission_color": Color("8dffc2"), "emission_energy": 2.0,
		})
		fixture.position = Vector3(x_position, CEILING_HEIGHT - 0.3, -1.5)
		add_child(fixture)

		var light = SimpleShapes.make_point_light(Color("8dffc2"), 0.8, 5.0)
		light.position = fixture.position + Vector3(0, -0.3, 0)
		add_child(light)

func _spawn_bay_rack(index: int) -> void:
	var rack_position = Vector3((index - 1) * 3.2, 0, 0)

	var rack = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(2.4, 1.6, 1.2),
		"albedo_color": Color("15221a"),
		"emission_color": Color("59ff9c"), "emission_energy": 0.35,
	})
	rack.name = "GrowBay%d" % index
	rack.position = rack_position
	add_child(rack)

	# Stand-in "LED strip" -- a bright thin emissive slab along the top
	# of the rack, per the user's "rooms with LEDS lights" note. Cheap
	# and readable at this scale; real fixtures can come later.
	var led = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(2.2, 0.08, 1.0),
		"albedo_color": Color("d8fff0"),
		"emission_color": Color("8dffc2"), "emission_energy": 2.5,
	})
	led.position = rack_position + Vector3(0, 0.85, 0)
	add_child(led)

	var light = SimpleShapes.make_point_light(Color("8dffc2"), 1.2, 4.0)
	light.position = rack_position + Vector3(0, 1.3, 0)
	add_child(light)

## Worked example for docs/GRAPHICS_GUIDE.md's "add a prop to a room"
## walkthrough: a plain two-box desk (tabletop + support block), same
## SimpleShapes pattern as every other prop in this file. Copy this
## function as the starting point for any other static room furniture --
## no C++, no rebuild, just a new function and one call from _ready().
func _spawn_desk() -> void:
	var desk_top = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(1.4, 0.08, 0.8),
		"albedo_color": Color("2a3038"),
	})
	desk_top.name = "DeskTop"
	desk_top.position = Vector3(0, -0.3, 3.0)
	add_child(desk_top)

	var desk_support = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(1.2, 0.5, 0.6),
		"albedo_color": Color("1c2128"),
	})
	desk_support.name = "DeskSupport"
	desk_support.position = Vector3(0, -0.55, 3.0)
	add_child(desk_support)

func _build_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var root_panel = PanelContainer.new()
	root_panel.theme = ThemeBootstrap.theme
	root_panel.custom_minimum_size = Vector2(340, 0)
	root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_panel.position = Vector2(20, 20)
	canvas.add_child(root_panel)

	var bg = _make_glass_background(Color(0.05, 0.12, 0.09, 0.45))
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
	header.text = "GREENHOUSE BAY"
	header.add_theme_color_override("font_color", Color(0.85, 1.0, 0.92))
	outer.add_child(header)

	_resources_label = Label.new()
	_resources_label.add_theme_font_size_override("font_size", 12)
	_resources_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_resources_label)

	outer.add_child(HSeparator.new())

	var bay_header = Label.new()
	bay_header.text = "LED GROW BAYS (%.1f H2O -> %.1f Food each)" % [H2O_COST, FOOD_YIELD]
	bay_header.add_theme_font_size_override("font_size", 12)
	bay_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(bay_header)

	for i in range(BAY_COUNT):
		var button = Button.new()
		button.text = "Plant & Harvest -- Bay %d" % (i + 1)
		button.pressed.connect(_on_harvest_pressed)
		outer.add_child(button)
		_bay_buttons.append(button)

	outer.add_child(HSeparator.new())

	# Two destinations, not one -- Greenhouse Bay is a room inside the
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
	var food = float(state["resources"].get("Food", 0.0))
	_resources_label.text = "Commons -- H2O: %.1f   Food: %.1f\nHarvested this visit: %.1f Food" % [h2o, food, _harvested_this_session]
	for button in _bay_buttons:
		button.disabled = h2o < H2O_COST
		button.tooltip_text = "" if h2o >= H2O_COST else "Need %.1f H2O banked (have %.1f)." % [H2O_COST, h2o]

func _on_harvest_pressed():
	var ok = FactionHomeBase.spend_resource(LevelContext.current_faction_id, "H2O", H2O_COST)
	if not ok:
		return
	FactionHomeBase.add_resource(LevelContext.current_faction_id, "Food", FOOD_YIELD)
	_harvested_this_session += FOOD_YIELD

	if LevelContext.current_level_id != "":
		FactionHomeBase.mark_level_complete(LevelContext.current_faction_id, LevelContext.current_level_id)

	_refresh()
