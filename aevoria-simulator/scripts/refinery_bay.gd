extends Node3D

## Ore processing chain, first slice: raw PGM (mined at the deep-space
## situation table, situation_table.gd) can
## now be smelted into Gold, Platinum, or Steel -- the "unlock more
## resources" step the user asked for after Greenhouse Bay closed the
## H2O -> Food loop. Same explicit-UI-command conversion pattern as
## greenhouse_bay.gd (instant, no real-time smelt wait), but three
## distinct recipes off one shared PGM stockpile rather than three
## identical bays -- each furnace here is a different output, not a
## repeat of the same one.

const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const LevelChrome = preload("res://scripts/level_chrome.gd")

const RECIPES = [
	{"name": "Smelt Gold", "input_resource": "PGM", "input_amount": 15.0, "output_resource": "Gold", "output_amount": 5.0, "glow": Color("ffd54a")},
	{"name": "Smelt Platinum", "input_resource": "PGM", "input_amount": 15.0, "output_resource": "Platinum", "output_amount": 8.0, "glow": Color("d8e4ea")},
	{"name": "Smelt Steel", "input_resource": "PGM", "input_amount": 10.0, "output_resource": "Steel", "output_amount": 12.0, "glow": Color("ff7a3d")},
	{"name": "Cure UHPC Concrete", "input_resource": "Regolith", "input_amount": 20.0, "output_resource": "UHPC Concrete", "output_amount": 10.0, "glow": Color("a68a5f")},
	{"name": "Press Shield Plating", "input_resource": "Regolith", "input_amount": 20.0, "output_resource": "Shield Plating", "output_amount": 8.0, "glow": Color("8fd6e6")},
]

@onready var camera: Camera3D = $Camera3D

var _resources_label: Label
var _recipe_buttons: Array = []
var _produced_this_session: Dictionary = {}

func _ready():
	add_child(LevelChrome.new())
	for i in range(RECIPES.size()):
		_spawn_furnace(i)
	_build_ui()
	_refresh()
	camera.make_current()

func _spawn_furnace(index: int) -> void:
	var recipe = RECIPES[index]
	var body_position = Vector3((index - 1) * 3.2, 0, 0)

	var body = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(2.0, 1.8, 1.4),
		"albedo_color": Color("221812"),
	})
	body.name = "Furnace%d" % index
	body.position = body_position
	add_child(body)

	# Molten-metal "window" in the furnace face -- an emissive slab
	# tinted per-recipe so the three furnaces read as different outputs
	# at a glance, same cheap-and-readable stand-in as Greenhouse's LEDs.
	var window = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(1.2, 0.7, 0.05),
		"albedo_color": recipe["glow"],
		"emission_color": recipe["glow"], "emission_energy": 2.2,
	})
	window.position = body_position + Vector3(0, 0, 0.72)
	add_child(window)

	var light = SimpleShapes.make_point_light(recipe["glow"], 1.1, 4.0)
	light.position = body_position + Vector3(0, 1.1, 0.7)
	add_child(light)

func _build_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var root_panel = PanelContainer.new()
	root_panel.theme = ThemeBootstrap.theme
	root_panel.custom_minimum_size = Vector2(360, 0)
	root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_panel.position = Vector2(20, 20)
	canvas.add_child(root_panel)

	var bg = _make_glass_background(Color(0.15, 0.07, 0.04, 0.45))
	root_panel.add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "REFINERY BAY"
	header.add_theme_color_override("font_color", Color(1.0, 0.88, 0.78))
	outer.add_child(header)

	_resources_label = Label.new()
	_resources_label.add_theme_font_size_override("font_size", 12)
	_resources_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_resources_label)

	outer.add_child(HSeparator.new())

	var recipe_header = Label.new()
	recipe_header.text = "SMELTING RECIPES"
	recipe_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(recipe_header)

	for i in range(RECIPES.size()):
		var recipe = RECIPES[i]
		var button = Button.new()
		button.text = "%s -- %.1f %s -> %.1f %s" % [recipe["name"], recipe["input_amount"], recipe["input_resource"], recipe["output_amount"], recipe["output_resource"]]
		button.pressed.connect(_on_smelt_pressed.bind(i))
		outer.add_child(button)
		_recipe_buttons.append(button)

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

	# One stockpile line per distinct input resource across all recipes
	# (used to be PGM-only before Regolith-fed recipes existed alongside
	# the PGM-fed ones).
	var input_resources: Array = []
	for recipe in RECIPES:
		if not input_resources.has(recipe["input_resource"]):
			input_resources.append(recipe["input_resource"])
	var lines = []
	for resource_name in input_resources:
		lines.append("Commons -- %s: %.1f" % [resource_name, float(state["resources"].get(resource_name, 0.0))])
	var produced_keys = _produced_this_session.keys()
	produced_keys.sort()
	for key in produced_keys:
		lines.append("Produced this visit: %.1f %s" % [float(_produced_this_session[key]), key])
	_resources_label.text = "\n".join(lines)

	for i in range(RECIPES.size()):
		var recipe = RECIPES[i]
		var have = float(state["resources"].get(recipe["input_resource"], 0.0))
		_recipe_buttons[i].disabled = have < recipe["input_amount"]

func _on_smelt_pressed(recipe_index: int):
	var recipe = RECIPES[recipe_index]
	var ok = FactionHomeBase.spend_resource(LevelContext.current_faction_id, recipe["input_resource"], recipe["input_amount"])
	if not ok:
		return
	FactionHomeBase.add_resource(LevelContext.current_faction_id, recipe["output_resource"], recipe["output_amount"])

	var output_name = recipe["output_resource"]
	_produced_this_session[output_name] = float(_produced_this_session.get(output_name, 0.0)) + float(recipe["output_amount"])

	if LevelContext.current_level_id != "":
		FactionHomeBase.mark_level_complete(LevelContext.current_faction_id, LevelContext.current_level_id)

	_refresh()
