extends Node3D

## Interactive kit-bashing builder: pick an open socket, pick a part that
## fits it, and the assembly rebuilds live. All interaction state lives
## here in GDScript; PartAssembler stays a pure "blueprint -> Node3D /
## aggregate stats" factory exactly as built for the non-interactive demo
## (parts-demo.gd) -- this UI just calls it again on every edit rather than
## needing any incremental attach/detach API on the C++ side.

const PartCatalog = preload("res://scripts/part_catalog.gd")

@onready var assembler: PartAssembler = $PartAssembler
@onready var camera: Camera3D = $Camera3D

var _catalog: Array = []
var _catalog_by_id: Dictionary = {}
var _blueprint: AssemblyBlueprint
var _preview_node: Node3D
var _open_sockets: Array = []  # [{parent_id, socket_id, accepts, label}]
var _selected_socket_index: int = -1

# UI
var _socket_list: ItemList
var _palette_vbox: VBoxContainer
var _stats_label: Label
var _status_label: Label
var _hull_button: Button
var _habitat_button: Button
var _finish_button: Button
var _skins_vbox: VBoxContainer
var _skins_status_label: Label
var _back_button: Button

func _ready():
	_catalog = PartCatalog.build_demo_catalog()
	for part in _catalog:
		_catalog_by_id[part.part_id] = part
	assembler.part_library = _catalog

	_build_ui()
	_start_new_blueprint("hull_mk1", "MyShip")

	AevoriaAuth.skins_fetched.connect(_on_skins_fetched)
	AevoriaAuth.skins_fetch_failed.connect(_on_skins_fetch_failed)
	_refresh_owned_skins()

# --- blueprint lifecycle -----------------------------------------------------

func _start_new_blueprint(root_part_id: String, ship_id: String):
	_blueprint = AssemblyBlueprint.new()
	_blueprint.ship_id = ship_id
	_blueprint.root_part_id = root_part_id
	_blueprint.attachments = []
	_blueprint.skin_recipe = {
		"seed": randi() % 100000, "frequency": 0.08,
		"dark_color": "#26201a", "base_color": "#8a8f96", "highlight_color": "#c7ccd1",
	}
	_selected_socket_index = -1
	_status_label.text = ""
	_refresh_all()

func _refresh_all():
	_rebuild_open_sockets()
	_rebuild_preview()
	_refresh_socket_list_ui()
	_refresh_palette_ui()
	_refresh_stats_ui()

# --- open-socket bookkeeping --------------------------------------------------

func _rebuild_open_sockets():
	_open_sockets.clear()

	var placed := {"root": _blueprint.root_part_id}
	for entry in _blueprint.attachments:
		placed[entry["attach_id"]] = entry["part_id"]

	var filled := {}
	for entry in _blueprint.attachments:
		filled[str(entry["parent_id"], "::", entry["socket_id"])] = true

	for attach_id in placed.keys():
		var part: PartDefinition = _catalog_by_id.get(placed[attach_id])
		if part == null:
			continue
		for socket in part.sockets:
			var key = str(attach_id, "::", socket["id"])
			if filled.has(key):
				continue
			_open_sockets.append({
				"parent_id": attach_id,
				"socket_id": socket["id"],
				"accepts": int(socket["accepts"]),
				"label": "%s -> %s" % [part.display_name, socket["id"]],
			})

func _rebuild_preview():
	if _preview_node != null:
		_preview_node.queue_free()
	_preview_node = assembler.assemble(_blueprint)
	add_child(_preview_node)
	camera.make_current()
	camera.look_at(_preview_node.global_position, Vector3.UP)

# --- UI construction (built in code, matching cur_fsm_display.gd's pattern) -

func _build_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var root_panel = PanelContainer.new()
	root_panel.theme = ThemeBootstrap.theme
	root_panel.custom_minimum_size = Vector2(300, 0)
	root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_panel.position = Vector2(20, 20)
	canvas.add_child(root_panel)

	var bg = _make_glass_background(Color(0.05, 0.08, 0.15, 0.45))
	root_panel.add_child(bg)

	# The full control list (skins, sockets, parts, stats, actions) is taller
	# than a lot of real window sizes -- without a height cap here, Save /
	# Finish / Back end up positioned entirely off-screen with no way to
	# reach them, since a PanelContainer floating under a CanvasLayer has no
	# size limit of its own and just grows to fit its content.
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "ASSEMBLY BAY"
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)

	var new_row = HBoxContainer.new()
	outer.add_child(new_row)
	_hull_button = Button.new()
	_hull_button.text = "New Ship"
	_hull_button.pressed.connect(func(): _start_new_blueprint("hull_mk1", "MyShip"))
	new_row.add_child(_hull_button)
	_habitat_button = Button.new()
	_habitat_button.text = "New Habitat"
	_habitat_button.pressed.connect(func(): _start_new_blueprint("habitat_ring_mk1", "MyHabitat"))
	new_row.add_child(_habitat_button)

	outer.add_child(HSeparator.new())

	var skins_header = Label.new()
	skins_header.text = "SKIN (from your Commonwealth account)"
	skins_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(skins_header)

	_skins_status_label = Label.new()
	_skins_status_label.add_theme_font_size_override("font_size", 11)
	_skins_status_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	_skins_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_skins_status_label)

	var skins_scroll = ScrollContainer.new()
	skins_scroll.custom_minimum_size = Vector2(0, 60)
	outer.add_child(skins_scroll)
	_skins_vbox = VBoxContainer.new()
	_skins_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skins_scroll.add_child(_skins_vbox)

	var random_skin_button = Button.new()
	random_skin_button.text = "Random Skin"
	random_skin_button.pressed.connect(_on_random_skin_pressed)
	outer.add_child(random_skin_button)

	outer.add_child(HSeparator.new())

	var socket_header = Label.new()
	socket_header.text = "OPEN SOCKETS (select one)"
	socket_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(socket_header)

	_socket_list = ItemList.new()
	_socket_list.custom_minimum_size = Vector2(0, 100)
	_socket_list.item_selected.connect(_on_socket_item_selected)
	outer.add_child(_socket_list)

	outer.add_child(HSeparator.new())

	var palette_header = Label.new()
	palette_header.text = "PARTS (fits selected socket)"
	palette_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(palette_header)

	var palette_scroll = ScrollContainer.new()
	palette_scroll.custom_minimum_size = Vector2(0, 160)
	outer.add_child(palette_scroll)
	_palette_vbox = VBoxContainer.new()
	_palette_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette_scroll.add_child(_palette_vbox)

	outer.add_child(HSeparator.new())

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 12)
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_stats_label)

	outer.add_child(HSeparator.new())

	var action_row = HBoxContainer.new()
	outer.add_child(action_row)
	var save_button = Button.new()
	save_button.text = "Save Blueprint"
	save_button.pressed.connect(_on_save_pressed)
	action_row.add_child(save_button)
	var reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.pressed.connect(func(): _start_new_blueprint(_blueprint.root_part_id, _blueprint.ship_id))
	action_row.add_child(reset_button)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7))
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_status_label)

	_finish_button = Button.new()
	_finish_button.text = "Finish & Return to Level Select"
	_finish_button.visible = false
	_finish_button.pressed.connect(_on_finish_pressed)
	outer.add_child(_finish_button)

	_back_button = Button.new()
	_back_button.text = "Back to Level Select"
	_back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	outer.add_child(_back_button)

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

# --- UI refresh ---------------------------------------------------------------

func _refresh_socket_list_ui():
	_socket_list.clear()
	for socket in _open_sockets:
		_socket_list.add_item(socket["label"])
	if _selected_socket_index >= 0 and _selected_socket_index < _open_sockets.size():
		_socket_list.select(_selected_socket_index)

func _refresh_palette_ui():
	for child in _palette_vbox.get_children():
		child.queue_free()

	var has_selection = _selected_socket_index >= 0 and _selected_socket_index < _open_sockets.size()
	var accepts_mask = int(_open_sockets[_selected_socket_index]["accepts"]) if has_selection else 0

	for part in _catalog:
		var bit = 1 << int(part.category)
		var fits = has_selection and (bit & accepts_mask) != 0
		var button = Button.new()
		button.text = part.display_name
		button.disabled = not fits
		if fits:
			var part_id = part.part_id
			button.pressed.connect(func(): _on_part_button_pressed(part_id))
		_palette_vbox.add_child(button)

	if not has_selection:
		var hint = Label.new()
		hint.text = "Select an open socket above first."
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		_palette_vbox.add_child(hint)

func _refresh_stats_ui():
	var stats = assembler.compute_aggregate_stats(_blueprint)
	var lines = ["STATS"]
	var keys = stats.keys()
	keys.sort()
	for key in keys:
		lines.append("  %s: %.1f" % [key, float(stats[key])])
	if keys.is_empty():
		lines.append("  (none yet)")
	_stats_label.text = "\n".join(lines)

# --- owned skins (Commonwealth account) -----------------------------------------

func _refresh_owned_skins():
	for child in _skins_vbox.get_children():
		child.queue_free()

	if not AevoriaAuth.is_logged_in():
		_skins_status_label.text = "Log in from the Level Select screen to use a purchased skin here."
		return

	_skins_status_label.text = "Loading your skins..."
	AevoriaAuth.fetch_owned_skins()

func _on_skins_fetched(purchases: Array):
	for child in _skins_vbox.get_children():
		child.queue_free()

	if purchases.is_empty():
		_skins_status_label.text = "No purchased skins yet -- using a random skin."
		return

	_skins_status_label.text = "Pick one of your purchased skins:"
	for purchase in purchases:
		var skin = purchase.get("skins", {})
		var recipe = skin.get("recipe")
		if typeof(recipe) != TYPE_DICTIONARY:
			continue
		var button = Button.new()
		button.text = skin.get("title", "(untitled)")
		button.pressed.connect(func(): _apply_owned_skin(recipe))
		_skins_vbox.add_child(button)

func _on_skins_fetch_failed(message: String):
	_skins_status_label.text = message

func _apply_owned_skin(web_recipe: Dictionary):
	# web/lib/skin-recipe.ts uses camelCase hex-string colors; AssemblyBlueprint's
	# skin_recipe uses snake_case (see part_assembler.cpp's hex_to_color) --
	# converting here is the one place those two conventions meet.
	_blueprint.skin_recipe = {
		"seed": web_recipe.get("seed", 0),
		"frequency": web_recipe.get("frequency", 0.08),
		"dark_color": web_recipe.get("darkColor", "#26201a"),
		"base_color": web_recipe.get("baseColor", "#8a8f96"),
		"highlight_color": web_recipe.get("highlightColor", "#c7ccd1"),
	}
	_rebuild_preview()

func _on_random_skin_pressed():
	_blueprint.skin_recipe = {
		"seed": randi() % 100000, "frequency": 0.08,
		"dark_color": "#26201a", "base_color": "#8a8f96", "highlight_color": "#c7ccd1",
	}
	_rebuild_preview()

# --- interaction handlers ------------------------------------------------------

func _on_socket_item_selected(index: int):
	_selected_socket_index = index
	_refresh_palette_ui()

func _on_part_button_pressed(part_id: String):
	if _selected_socket_index < 0 or _selected_socket_index >= _open_sockets.size():
		return
	var socket = _open_sockets[_selected_socket_index]
	var attach_id = "attach_%d" % _blueprint.attachments.size()
	_blueprint.attachments.append({
		"attach_id": attach_id,
		"parent_id": socket["parent_id"],
		"socket_id": socket["socket_id"],
		"part_id": part_id,
	})
	_selected_socket_index = -1
	_status_label.text = ""
	_refresh_all()

func _on_save_pressed():
	var dir = "user://blueprints"
	DirAccess.make_dir_recursive_absolute(dir)
	var path = "%s/%s.json" % [dir, _blueprint.ship_id]
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(_blueprint.to_json())
	file.close()
	_status_label.text = "Saved: " + ProjectSettings.globalize_path(path)
	if LevelContext.current_level_id != "":
		_finish_button.visible = true

func _on_finish_pressed():
	LevelContext.finish_current_level({"Platinum": 25.0})
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
