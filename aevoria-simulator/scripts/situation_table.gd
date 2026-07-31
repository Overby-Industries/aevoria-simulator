extends Node3D

## The consolidated entry point for asteroid mining, replacing
## asteroid_field.gd's role: a top-down "situation table" (the sci-fi
## battle-scene tactical-display look the user asked for) instead of a
## free-floating 3D field browsed through a side list alone. Same
## underlying data (resource_node_catalog.gd's build_field() is untouched)
## and the same core loop (select a contact, mine it, bank the resource),
## but the camera now behaves the way a tactical table would:
##
## - Default view is wide, looking down at the whole table.
## - "Inspect" zooms the camera in on the selected contact -- explicitly a
##   command, not something that happens automatically.
## - "Direct Ship to Mine" moves the ship marker across the table over a
##   few real seconds (the automated part: no manual flight, no per-frame
##   piloting) and deliberately does NOT zoom the camera -- the table
##   stays wide while a unit is in transit, only zooming on an explicit
##   Inspect command. That's the "does not zoom unless commanded" rule the
##   user asked for.
##
## Camera technique: look_at() is called exactly once in _ready() to
## establish a fixed viewing angle, then every subsequent move only tweens
## camera.global_position using the SAME offset vector from whatever point
## it's centering on (table center or a contact's position). Translating
## a correctly-oriented camera by a fixed offset keeps the target centered
## without recomputing look_at() every frame -- simpler and cheaper than a
## continuously-retargeted camera.

const ResourceNodeCatalog = preload("res://scripts/resource_node_catalog.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

const WIDE_OFFSET = Vector3(0, 20, 9)
const ZOOM_OFFSET = Vector3(0, 5, 2.2)
const TRAVEL_SECONDS = 2.2
const CAMERA_MOVE_SECONDS = 0.6
const HOME_POSITION = Vector3(0, 0.3, 10.0)

## Table-icon stand-ins for each faction's real Assembly Bay hull
## (part_catalog.gd) -- SimpleShapes only knows box/cylinder/capsule/sphere,
## not the C++-side PartAssembler's composite "winged_fuselage" the SSTO
## hull actually uses, so the Commonwealth's marker approximates it with a
## capsule (a sleek fuselage silhouette) rather than literally reproducing
## the wings. The Combine's tube_rocket_hull_mk1 and the Flotilla's
## drift_hull_mk1 are already SimpleShapes-native primitives (cylinder/box
## respectively), so those two are exact shape matches, just at icon
## scale. Colors are each hull's HULL_SKIN_SUGGESTIONS highlight_color.
static func _ship_marker_spec(faction_id: String) -> Dictionary:
	match faction_id:
		LevelCatalog.OLIGARCH_COMBINE:
			return {"shape": "cylinder", "radius": 0.28, "height": 0.85, "color": "b8862b"}
		LevelCatalog.NOMAD_FLOTILLA:
			return {"shape": "box", "size": Vector3(0.45, 0.35, 1.0), "color": "c9a227"}
		_:
			return {"shape": "capsule", "radius": 0.22, "height": 0.9, "color": "ffffff"}

@onready var camera: Camera3D = $Camera3D

var _nodes: Array = []  # matches ResourceNodeCatalog.build_field() shape
var _mesh_by_id: Dictionary = {}
var _label_by_id: Dictionary = {}
var _mined_ids: Dictionary = {}
var _banked_this_session: Dictionary = {}

var _ship_marker: MeshInstance3D
var _ship_position: Vector3 = HOME_POSITION
var _traveling: bool = false
var _selected_id: String = ""

var _node_list: ItemList
var _list_index_to_id: Array = []
var _banked_label: Label
var _status_label: Label
var _inspect_button: Button
var _mine_button: Button
var _zoom_out_button: Button

func _ready():
	_nodes = ResourceNodeCatalog.build_field(6, 4)
	for node_data in _nodes:
		_spawn_node(node_data)
	_spawn_ship_marker()

	camera.global_position = Vector3.ZERO + WIDE_OFFSET
	camera.look_at(Vector3.ZERO, Vector3.UP)

	_build_ui()
	_refresh_list()

func _flat(position: Vector3) -> Vector3:
	# Table display flattens the field's small Y jitter (see
	# resource_node_catalog.gd's _random_position()) -- a tactical table is
	# a plane, not a 3D volume, even though the underlying node data keeps
	# its original position for anything that wants the un-flattened field.
	return Vector3(position.x, 0.0, position.z)

func _spawn_node(node_data: Dictionary) -> void:
	var generator = ProceduralArtGenerator.new()
	var texture = generator.generate_procedural_texture(node_data["texture_recipe"], 128, 128)
	var is_comet: bool = node_data["node_type"] == "comet"

	var instance = SimpleShapes.make_mesh_instance({
		"shape": "sphere", "radial_segments": 12, "rings": 8,
		"albedo_texture": texture,
		"emission_color": Color("6fb8ff") if is_comet else Color("ffd54a"),
		"emission_energy": 0.4 if is_comet else 0.25,
	})
	instance.name = node_data["id"]
	instance.position = _flat(node_data["position"])
	instance.scale = Vector3(0.6, 0.5, 0.6)
	add_child(instance)
	_mesh_by_id[node_data["id"]] = instance

	var label = Label3D.new()
	label.text = "%s\n%s" % [node_data["display_name"], node_data["resource_name"]]
	label.font_size = 32
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = instance.position + Vector3(0, 0.9, 0)
	label.modulate = Color("dff3ff") if is_comet else Color("ffe9a8")
	add_child(label)
	_label_by_id[node_data["id"]] = label

func _spawn_ship_marker() -> void:
	var spec = _ship_marker_spec(LevelContext.current_faction_id)
	var recipe = {"shape": spec["shape"], "emission_color": Color(spec["color"]), "emission_energy": 0.6}
	if spec.has("size"):
		recipe["size"] = spec["size"]
	if spec.has("radius"):
		recipe["radius"] = spec["radius"]
		recipe["height"] = spec["height"]

	_ship_marker = SimpleShapes.make_mesh_instance(recipe)
	_ship_marker.name = "ShipMarker"
	_ship_marker.position = HOME_POSITION
	add_child(_ship_marker)

	# Child of the marker, not a sibling at a fixed world position -- a
	# label added to `self` never moved when _ship_marker's own position
	# was tweened across the table. Local-space position here means it
	# now travels with the marker for free, no per-frame sync needed.
	var label = Label3D.new()
	label.text = "YOUR SHIP"
	label.font_size = 28
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.7, 0)
	label.modulate = Color(spec["color"])
	_ship_marker.add_child(label)

func _build_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var root_panel = PanelContainer.new()
	root_panel.theme = ThemeBootstrap.theme
	root_panel.custom_minimum_size = Vector2(340, 0)
	root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_panel.position = Vector2(20, 20)
	canvas.add_child(root_panel)

	var bg = _make_glass_background(Color(0.05, 0.08, 0.15, 0.45))
	root_panel.add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "DEEP-SPACE SITUATION TABLE"
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)

	var subheader = Label.new()
	subheader.text = "Select a contact, then Inspect to zoom in on it or direct your ship to mine it. The table stays wide while your ship is in transit -- it only zooms on command."
	subheader.add_theme_font_size_override("font_size", 10)
	subheader.add_theme_color_override("font_color", Color(0.6, 0.68, 0.78))
	subheader.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subheader.custom_minimum_size = Vector2(310, 0)
	outer.add_child(subheader)

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
	_node_list.item_selected.connect(_on_list_item_selected)
	outer.add_child(_node_list)

	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	outer.add_child(button_row)

	_inspect_button = Button.new()
	_inspect_button.text = "Inspect (zoom in)"
	_inspect_button.pressed.connect(_on_inspect_pressed)
	button_row.add_child(_inspect_button)

	_zoom_out_button = Button.new()
	_zoom_out_button.text = "Zoom Out"
	_zoom_out_button.pressed.connect(_zoom_out)
	button_row.add_child(_zoom_out_button)

	_mine_button = Button.new()
	_mine_button.text = "Direct Ship to Mine"
	_mine_button.pressed.connect(_on_mine_pressed)
	outer.add_child(_mine_button)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.7))
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(310, 0)
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

func _find_node_data(node_id: String) -> Dictionary:
	for candidate in _nodes:
		if candidate["id"] == node_id:
			return candidate
	return {}

func _on_list_item_selected(index: int) -> void:
	_selected_id = _list_index_to_id[index]

func _on_inspect_pressed() -> void:
	if _selected_id == "":
		return
	var node_data = _find_node_data(_selected_id)
	if node_data.is_empty():
		return
	_zoom_to(_flat(node_data["position"]))

func _zoom_to(target: Vector3) -> void:
	var tween = create_tween()
	tween.tween_property(camera, "global_position", target + ZOOM_OFFSET, CAMERA_MOVE_SECONDS).set_trans(Tween.TRANS_SINE)

func _zoom_out() -> void:
	var tween = create_tween()
	tween.tween_property(camera, "global_position", Vector3.ZERO + WIDE_OFFSET, CAMERA_MOVE_SECONDS).set_trans(Tween.TRANS_SINE)

func _on_mine_pressed() -> void:
	if _traveling or _selected_id == "":
		return
	var node_data = _find_node_data(_selected_id)
	if node_data.is_empty() or _mined_ids.has(_selected_id):
		return

	# Moving a unit across the table is not an inspection command -- stays
	# wide per the user's "does not zoom unless commanded" rule, even if
	# an Inspect zoom happened to be active from a previous selection.
	_zoom_out()

	_traveling = true
	_mine_button.disabled = true
	var target_id = _selected_id
	var target_position = _flat(node_data["position"])
	_status_label.text = "Ship en route to %s..." % node_data["display_name"]

	var tween = create_tween()
	tween.tween_property(_ship_marker, "position", target_position, TRAVEL_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_on_ship_arrived.bind(target_id))

func _on_ship_arrived(node_id: String) -> void:
	_traveling = false
	_mine_button.disabled = false
	_ship_position = _ship_marker.position

	var node_data = _find_node_data(node_id)
	if node_data.is_empty() or _mined_ids.has(node_id):
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
	var label = _label_by_id.get(node_id)
	if label:
		label.queue_free()
		_label_by_id.erase(node_id)

	_status_label.text = "Mined %s: +%.1f %s." % [node_data["display_name"], amount, resource_name]
	_selected_id = ""
	_refresh_list()
