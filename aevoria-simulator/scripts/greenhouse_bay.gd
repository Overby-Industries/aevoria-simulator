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

const H2O_COST: float = 10.0
const FOOD_YIELD: float = 6.0
const BAY_COUNT: int = 3

@onready var camera: Camera3D = $Camera3D

var _resources_label: Label
var _bay_buttons: Array = []
var _harvested_this_session: float = 0.0

func _ready():
	for i in range(BAY_COUNT):
		_spawn_bay_rack(i)
	_spawn_desk()
	_build_ui()
	_refresh()
	camera.make_current()

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

func _refresh():
	var state = FactionHomeBase.load_state(LevelContext.current_faction_id)
	var h2o = float(state["resources"].get("H2O", 0.0))
	var food = float(state["resources"].get("Food", 0.0))
	_resources_label.text = "Commons -- H2O: %.1f   Food: %.1f\nHarvested this visit: %.1f Food" % [h2o, food, _harvested_this_session]
	for button in _bay_buttons:
		button.disabled = h2o < H2O_COST

func _on_harvest_pressed():
	var ok = FactionHomeBase.spend_resource(LevelContext.current_faction_id, "H2O", H2O_COST)
	if not ok:
		return
	FactionHomeBase.add_resource(LevelContext.current_faction_id, "Food", FOOD_YIELD)
	_harvested_this_session += FOOD_YIELD

	if LevelContext.current_level_id != "":
		FactionHomeBase.mark_level_complete(LevelContext.current_faction_id, LevelContext.current_level_id)

	_refresh()
