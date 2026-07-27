extends Node3D

## First slice of the asteroid-mining idea: a field of asteroids (PGM) and
## comets (H2O), each mined via an explicit UI command rather than real
## flight/collision -- matches the user's own "event based commands to
## start searching and prospecting" framing, and keeps this testable the
## same way the rest of the level scenes are (headless + screenshot, no
## 3D-click automation needed). Deliberately no processing chain, no
## faction-locked ships, no food growing yet -- just the core mine-and-bank
## loop, per the "start small" call on 2026-07-27.

const ResourceNodeCatalog = preload("res://scripts/resource_node_catalog.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")

@onready var camera: Camera3D = $Camera3D

var _nodes: Array = []  # matches ResourceNodeCatalog.build_field() shape
var _mesh_by_id: Dictionary = {}
var _mined_ids: Dictionary = {}
var _banked_this_session: Dictionary = {}

var _node_list: ItemList
var _list_index_to_id: Array = []
var _banked_label: Label
var _mine_button: Button

func _ready():
	_nodes = ResourceNodeCatalog.build_field(5, 3)
	for node_data in _nodes:
		_spawn_node_mesh(node_data)

	_build_ui()
	_refresh_list()
	camera.make_current()

func _spawn_node_mesh(node_data: Dictionary) -> void:
	var mesh = SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 8

	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.name = node_data["id"]
	instance.position = node_data["position"]
	# Cheap stand-in for irregular rock/ice shapes without real mesh
	# deformation -- non-uniform scale on a sphere reads as "chunky" at
	# this size, and the graphics can be improved later per the user.
	instance.scale = Vector3(
		randf_range(0.7, 1.3), randf_range(0.6, 1.1), randf_range(0.7, 1.3)
	)

	var generator = ProceduralArtGenerator.new()
	var texture = generator.generate_procedural_texture(node_data["texture_recipe"], 128, 128)
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	if node_data["node_type"] == "comet":
		material.emission_enabled = true
		material.emission = Color("6fb8ff")
		material.emission_energy_multiplier = 0.4
	else:
		material.emission_enabled = true
		material.emission = Color("ffd54a")
		material.emission_energy_multiplier = 0.25
	instance.material_override = material

	add_child(instance)
	_mesh_by_id[node_data["id"]] = instance

func _build_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var root_panel = PanelContainer.new()
	root_panel.theme = ThemeBootstrap.theme
	root_panel.custom_minimum_size = Vector2(320, 0)
	root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_panel.position = Vector2(20, 20)
	canvas.add_child(root_panel)

	var bg = _make_glass_background(Color(0.05, 0.08, 0.15, 0.45))
	root_panel.add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(320, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "ASTEROID FIELD"
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)

	_banked_label = Label.new()
	_banked_label.add_theme_font_size_override("font_size", 12)
	_banked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_banked_label)

	outer.add_child(HSeparator.new())

	var list_header = Label.new()
	list_header.text = "SCANNED CONTACTS (select one)"
	list_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(list_header)

	_node_list = ItemList.new()
	_node_list.custom_minimum_size = Vector2(0, 180)
	outer.add_child(_node_list)

	_mine_button = Button.new()
	_mine_button.text = "Mine Selected"
	_mine_button.pressed.connect(_on_mine_pressed)
	outer.add_child(_mine_button)

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

func _refresh_list():
	_node_list.clear()
	_list_index_to_id.clear()
	for node_data in _nodes:
		if _mined_ids.has(node_data["id"]):
			continue
		_node_list.add_item("%s -- %s ~%.1f" % [node_data["display_name"], node_data["resource_name"], node_data["yield_amount"]])
		_list_index_to_id.append(node_data["id"])

	var lines = ["Banked this visit:"]
	var keys = _banked_this_session.keys()
	keys.sort()
	for key in keys:
		lines.append("  %s: %.1f" % [key, float(_banked_this_session[key])])
	if keys.is_empty():
		lines.append("  (nothing yet)")
	_banked_label.text = "\n".join(lines)

func _on_mine_pressed():
	var selected = _node_list.get_selected_items()
	if selected.is_empty():
		return
	var node_id = _list_index_to_id[selected[0]]
	var node_data = null
	for candidate in _nodes:
		if candidate["id"] == node_id:
			node_data = candidate
			break
	if node_data == null:
		return

	_mined_ids[node_id] = true
	var resource_name = node_data["resource_name"]
	var amount = node_data["yield_amount"]
	FactionHomeBase.add_resource(LevelContext.current_faction_id, resource_name, amount)
	_banked_this_session[resource_name] = float(_banked_this_session.get(resource_name, 0.0)) + amount

	if LevelContext.current_level_id != "":
		FactionHomeBase.mark_level_complete(LevelContext.current_faction_id, LevelContext.current_level_id)

	var mesh_instance = _mesh_by_id.get(node_id)
	if mesh_instance:
		mesh_instance.queue_free()
		_mesh_by_id.erase(node_id)

	_refresh_list()
