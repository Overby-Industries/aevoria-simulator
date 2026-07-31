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

const H2O_COST: float = 10.0
const POTABLE_WATER_YIELD: float = 6.0
const O2_YIELD: float = 4.0
const TANK_COUNT: int = 3

@onready var camera: Camera3D = $Camera3D

var _resources_label: Label
var _tank_buttons: Array = []
var _potable_water_this_session: float = 0.0
var _o2_this_session: float = 0.0

func _ready():
	for i in range(TANK_COUNT):
		_spawn_tank(i)
	_build_ui()
	_refresh()
	camera.make_current()

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
	var potable_water = float(state["resources"].get("Potable Water", 0.0))
	var o2 = float(state["resources"].get("O2", 0.0))
	_resources_label.text = "Commons -- H2O: %.1f   Potable Water: %.1f   O2: %.1f\nSplit this visit: %.1f Potable Water, %.1f O2" % [h2o, potable_water, o2, _potable_water_this_session, _o2_this_session]
	for button in _tank_buttons:
		button.disabled = h2o < H2O_COST

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
