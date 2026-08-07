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
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

const RECIPES = [
	{"name": "Smelt Gold", "input_resource": "PGM", "input_amount": 15.0, "output_resource": "Gold", "output_amount": 5.0, "glow": Color("ffd54a")},
	{"name": "Smelt Platinum", "input_resource": "PGM", "input_amount": 15.0, "output_resource": "Platinum", "output_amount": 8.0, "glow": Color("d8e4ea")},
	{"name": "Smelt Steel", "input_resource": "PGM", "input_amount": 10.0, "output_resource": "Steel", "output_amount": 12.0, "glow": Color("ff7a3d")},
	{"name": "Cure UHPC Concrete", "input_resource": "Regolith", "input_amount": 20.0, "output_resource": "UHPC Concrete", "output_amount": 10.0, "glow": Color("a68a5f")},
	{"name": "Press Shield Plating", "input_resource": "Regolith", "input_amount": 20.0, "output_resource": "Shield Plating", "output_amount": 8.0, "glow": Color("8fd6e6")},
]

## Smelting-floor shell around the furnaces below -- floor, back/side walls,
## and a couple of overhead duct silhouettes (docs/GRAPHICS_GUIDE.md System
## 2, same SimpleShapes-plus-own-WorldEnvironment technique as
## hangar_backdrop.gd, far simpler since RefineryBay.tscn's Camera3D is
## fixed -- see hangar_backdrop.gd's own doc comment on "camera never
## moves, geometry is placed to fit it"). _spawn_furnace() below places
## furnaces at x = (index - 1) * 3.2 for indices 0..4 (RECIPES.size()),
## i.e. x in [-3.2, 9.6] -- FLOOR_HALF_WIDTH/FLOOR_DEPTH_NEAR/FAR give a
## floor comfortably larger than that span, not a tight fit.
const FLOOR_HALF_WIDTH := 13.0
const FLOOR_DEPTH_NEAR := 16.0    # toward the camera (Camera3D sits at z=14)
const FLOOR_DEPTH_FAR := -12.0    # the back wall
const WALL_HEIGHT := 8.0
const DUCT_HEIGHT := WALL_HEIGHT - 1.2
const DUCT_RADIUS := 0.35

@onready var camera: Camera3D = $Camera3D

var _resources_label: Label
var _recipe_buttons: Array = []
var _produced_this_session: Dictionary = {}

func _ready():
	add_child(LevelChrome.new())
	_build_backdrop()
	for i in range(RECIPES.size()):
		_spawn_furnace(i)
	_build_ui()
	_refresh()
	camera.make_current()

# --- 3D backdrop (smelting-floor shell) -----------------------------------------

## Faction-agnostic gameplay (any faction can smelt here), faint
## faction-tinted look -- same "" -> AEVORIA_COMMONWEALTH fallback
## level_chrome.gd uses, since a scene opened directly (editor "Run Current
## Scene", headless smoke test) never goes through LevelContext.start_level().
func _build_backdrop() -> void:
	var faction_id = LevelContext.current_faction_id
	if faction_id == "":
		faction_id = LevelCatalog.AEVORIA_COMMONWEALTH
	var palette = FactionVisuals.backdrop_palette(faction_id)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = palette["fog"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = palette["light"]
	env.ambient_light_energy = 0.3
	env.glow_enabled = false
	# Real reflections, not just a flat specular highlight -- the furnaces'
	# glowing windows are what the glossy floor actually has to reflect,
	# same trick hangar_backdrop.gd uses for its ceiling fixtures.
	env.ssr_enabled = true
	env.ssr_max_steps = 48
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(FLOOR_HALF_WIDTH * 2.0, 0.2, FLOOR_DEPTH_NEAR - FLOOR_DEPTH_FAR)
	floor_mesh.mesh = floor_box
	floor_mesh.position = Vector3(0, -0.1, (FLOOR_DEPTH_NEAR + FLOOR_DEPTH_FAR) * 0.5)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = palette["floor"]
	floor_mat.metallic = 0.5
	floor_mat.roughness = 0.2
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)

	var back_wall = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(FLOOR_HALF_WIDTH * 2.0, WALL_HEIGHT, 0.4),
		"albedo_color": palette["wall"],
	})
	back_wall.position = Vector3(0, WALL_HEIGHT * 0.5 - 0.1, FLOOR_DEPTH_FAR)
	add_child(back_wall)

	for x_sign in [-1.0, 1.0]:
		var side_wall = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.4, WALL_HEIGHT, FLOOR_DEPTH_NEAR - FLOOR_DEPTH_FAR),
			"albedo_color": palette["wall"],
		})
		side_wall.position = Vector3(x_sign * FLOOR_HALF_WIDTH, WALL_HEIGHT * 0.5 - 0.1, (FLOOR_DEPTH_NEAR + FLOOR_DEPTH_FAR) * 0.5)
		add_child(side_wall)

	_build_ducts(palette)

	var key_light = SimpleShapes.make_point_light(palette["light"], 1.0, 20.0)
	key_light.position = Vector3(0, WALL_HEIGHT, 6.0)
	add_child(key_light)

## A couple of overhead venting pipes, running across the room above the
## furnace row -- just enough silhouette to read as "smelting floor with
## exhaust venting" without competing with the furnaces' own glow for
## attention.
func _build_ducts(palette: Dictionary) -> void:
	var duct_color = palette["wall"]
	for x_offset in [-2.5, 2.5]:
		var duct = SimpleShapes.make_mesh_instance({
			"shape": "cylinder", "radius": DUCT_RADIUS, "height": FLOOR_DEPTH_NEAR - FLOOR_DEPTH_FAR - 4.0,
			"albedo_color": duct_color,
		})
		duct.rotation.x = PI * 0.5
		duct.position = Vector3(x_offset, DUCT_HEIGHT, (FLOOR_DEPTH_NEAR + FLOOR_DEPTH_FAR) * 0.5)
		add_child(duct)

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

	# Two destinations, not one -- Refinery Bay is a room inside the
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
		_recipe_buttons[i].tooltip_text = "" if have >= recipe["input_amount"] else "Need %.1f %s (have %.1f)." % [recipe["input_amount"], recipe["input_resource"], have]

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
