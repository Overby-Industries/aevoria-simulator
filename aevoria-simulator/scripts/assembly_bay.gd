extends Node3D

## Interactive kit-bashing builder: pick an open socket, pick a part that
## fits it, and the assembly rebuilds live. All interaction state lives
## here in GDScript; PartAssembler stays a pure "blueprint -> Node3D /
## aggregate stats" factory exactly as built for the non-interactive demo
## (parts-demo.gd) -- this UI just calls it again on every edit rather than
## needing any incremental attach/detach API on the C++ side.

const PartCatalog = preload("res://scripts/part_catalog.gd")
const CameraFraming = preload("res://scripts/camera_framing.gd")
const Tier1SkinCatalog = preload("res://scripts/tier1_skin_catalog.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")
const LevelChrome = preload("res://scripts/level_chrome.gd")

# Part IDs that count toward the Commonwealth's VCI tracking when a ship
# including one is saved -- see faction_home_base.gd's
# mark_infrastructure_built() and vci_tracker.gd's "Shelter
# availability"/"Electrical power continuity" sub-measures.
const SHELTER_PART_ID = "habitat_ring_mk1"
const POWER_PART_ID = "power_cell_mk1"
const SANITATION_PART_ID = "waste_recycler_mk1"
const HEALTHCARE_PART_ID = "medbay_mk1"

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
var _hulls_vbox: VBoxContainer
var _habitat_button: Button
var _finish_button: Button
var _skins_vbox: VBoxContainer
var _skins_status_label: Label
var _my_creations_vbox: VBoxContainer
var _my_creations_status_label: Label
var _back_button: Button
var _active_special_effect: String = ""

# Drag-to-orbit / scroll-to-zoom camera state. _rebuild_preview() runs on
# every socket/skin edit and used to call CameraFraming.frame() outright,
# which reset the camera to its default angle on every single click --
# _apply_orbit_camera() re-centers on the ship's current geometry each
# time but reapplies these stored angles/zoom instead, so a part edit
# mid-inspection doesn't yank the view back to square one.
var _orbit_yaw: float = 0.0
var _orbit_pitch: float = 0.4636  # matches CameraFraming's old default direction Vector3(0, 0.5, 1)
var _orbit_zoom: float = 1.0
var _orbit_dragging: bool = false
const ORBIT_MARGIN = 1.3
const ORBIT_PITCH_LIMIT = 1.4
const ORBIT_ZOOM_MIN = 0.35
const ORBIT_ZOOM_MAX = 3.0
const ORBIT_DRAG_SPEED = 0.008
const ORBIT_ZOOM_STEP = 0.9

# Ship naming + custom color picker UI
var _ship_name_input: LineEdit
var _badge_label: Label
var _badge_detail_vbox: VBoxContainer
var _base_color_button: ColorPickerButton
var _dark_color_button: ColorPickerButton
var _highlight_color_button: ColorPickerButton

func _ready():
	add_child(LevelChrome.new())
	_catalog = PartCatalog.build_demo_catalog()
	for part in _catalog:
		_catalog_by_id[part.part_id] = part
	assembler.part_library = _catalog

	_build_ui()
	_start_new_blueprint("hull_mk1", "MyShip")

	AevoriaAuth.skins_fetched.connect(_on_skins_fetched)
	AevoriaAuth.skins_fetch_failed.connect(_on_skins_fetch_failed)
	AevoriaAuth.my_creations_fetched.connect(_on_my_creations_fetched)
	AevoriaAuth.my_creations_fetch_failed.connect(_on_my_creations_fetch_failed)
	# _refresh_owned_skins() below runs immediately in _ready(), but a
	# returning player's session restore (AevoriaAuth._load_session() ->
	# _refresh_now(), fired from AevoriaAuth's own _ready()) is still async
	# at that point -- is_logged_in() reads false and both fetches silently
	# skip with "log in first" messages that then never retry. Re-running
	# on login_succeeded covers both that race and a fresh in-scene login.
	AevoriaAuth.login_succeeded.connect(func(_info): _refresh_owned_skins())
	PlayerProfile.badges_updated.connect(_refresh_badge_ui)
	_refresh_owned_skins()
	_refresh_badge_ui()

# --- blueprint lifecycle -----------------------------------------------------

func _start_new_blueprint(root_part_id: String, ship_id: String):
	_blueprint = AssemblyBlueprint.new()
	_blueprint.ship_id = ship_id
	_blueprint.root_part_id = root_part_id
	_blueprint.attachments = []
	# Faction-exclusive hulls get their sketched look (e.g. the SSTO's
	# white) as a starting suggestion; anything else falls back to the
	# original generic skin. Player can still Random Skin over it.
	var suggested = PartCatalog.HULL_SKIN_SUGGESTIONS.get(root_part_id)
	_blueprint.skin_recipe = suggested.duplicate() if suggested != null else {
		"seed": randi() % 100000, "frequency": 0.08,
		"dark_color": "#26201a", "base_color": "#8a8f96", "highlight_color": "#c7ccd1",
	}
	if suggested != null:
		_blueprint.skin_recipe["seed"] = randi() % 100000
	_active_special_effect = ""
	_selected_socket_index = -1
	_status_label.text = ""
	_orbit_yaw = 0.0
	_orbit_pitch = 0.4636
	_orbit_zoom = 1.0
	if _ship_name_input != null:
		_ship_name_input.text = ship_id
	_refresh_all()
	_refresh_color_pickers_ui()

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
	if _active_special_effect == "zero_waste_exhaust":
		_spawn_exhaust_effect()
	camera.make_current()
	_apply_orbit_camera()

func _apply_orbit_camera() -> void:
	if _preview_node == null:
		return
	var bounds = CameraFraming.compute_bounds([_preview_node])
	var direction = Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch),
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos(_orbit_pitch),
	)
	camera.global_position = bounds["center"] + direction * bounds["extent"] * ORBIT_MARGIN * _orbit_zoom
	camera.look_at(bounds["center"], Vector3.UP)

## Left-drag to orbit, scroll to zoom -- lets the player spin the ship
## around to inspect its skin/livery from any angle. _unhandled_input
## (not _input) so it only fires once the UI's own Controls (buttons,
## sliders, the ItemList) have had first refusal on the event.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_orbit_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_orbit_zoom = clampf(_orbit_zoom * ORBIT_ZOOM_STEP, ORBIT_ZOOM_MIN, ORBIT_ZOOM_MAX)
			_apply_orbit_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_orbit_zoom = clampf(_orbit_zoom / ORBIT_ZOOM_STEP, ORBIT_ZOOM_MIN, ORBIT_ZOOM_MAX)
			_apply_orbit_camera()
	elif event is InputEventMouseMotion and _orbit_dragging:
		_orbit_yaw -= event.relative.x * ORBIT_DRAG_SPEED
		_orbit_pitch = clampf(_orbit_pitch - event.relative.y * ORBIT_DRAG_SPEED, -ORBIT_PITCH_LIMIT, ORBIT_PITCH_LIMIT)
		_apply_orbit_camera()

# The Stardust Vanguard Livery Pack's "zero-waste" particle exhaust --
# purely cosmetic, so it's handled here in GDScript rather than added to
# AssemblyBlueprint/PartAssembler. Positioned at the root hull's "aft"
# socket (the same point thrusters attach to) so it reads as engine
# exhaust regardless of which hull is currently selected.
func _spawn_exhaust_effect():
	var root_part: PartDefinition = _catalog_by_id.get(_blueprint.root_part_id)
	if root_part == null:
		return
	var aft_socket = root_part.find_socket("aft")
	if aft_socket.is_empty():
		return

	var particles = GPUParticles3D.new()
	particles.position = aft_socket["position"]
	particles.amount = 40
	particles.lifetime = 1.2
	particles.emitting = true

	var mesh = SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	particles.draw_pass_1 = mesh

	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 0, 1)  # "aft" is +Z in this project's socket convention
	process_material.spread = 12.0
	process_material.initial_velocity_min = 6.0
	process_material.initial_velocity_max = 10.0
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 0.5
	process_material.scale_max = 1.0
	process_material.color = Color(0.6, 0.9, 1.0, 0.55)
	particles.process_material = process_material

	_preview_node.add_child(particles)

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

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	outer.add_child(name_row)

	var name_label = Label.new()
	name_label.text = "Ship Name:"
	name_label.add_theme_font_size_override("font_size", 11)
	name_row.add_child(name_label)

	_ship_name_input = LineEdit.new()
	_ship_name_input.placeholder_text = "Name your ship"
	_ship_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ship_name_input.text_submitted.connect(func(_text): _on_ship_name_committed())
	_ship_name_input.focus_exited.connect(_on_ship_name_committed)
	name_row.add_child(_ship_name_input)

	# Free for every player, paid or not -- only the badge text itself
	# (PlayerProfile.badge_suffix()) depends on having bought something.
	_badge_label = Label.new()
	_badge_label.add_theme_font_size_override("font_size", 11)
	_badge_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
	outer.add_child(_badge_label)

	# The fuller badge/perk breakdown (was account_panel.gd's "BADGES &
	# PERKS" list -- moved here so all of a player's account-earned
	# personalization lives in one place, alongside the skin picker it
	# already shares a purchases fetch with).
	_badge_detail_vbox = VBoxContainer.new()
	outer.add_child(_badge_detail_vbox)

	var hulls_header = Label.new()
	hulls_header.text = "NEW SHIP -- HULLS AVAILABLE TO YOUR FACTION"
	hulls_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(hulls_header)

	_hulls_vbox = VBoxContainer.new()
	outer.add_child(_hulls_vbox)
	_refresh_hull_picker_ui()

	_habitat_button = Button.new()
	_habitat_button.text = "New Habitat"
	_habitat_button.pressed.connect(func(): _start_new_blueprint("habitat_ring_mk1", "MyHabitat"))
	outer.add_child(_habitat_button)

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

	# A creator's own designs (from the web Skin Creator) are usable here
	# with no purchase needed -- ownership is "you authored it", not "you
	# bought it". Separate list from the purchased-skins one above since
	# the two fetches (AevoriaAuth.fetch_owned_skins() /
	# fetch_my_creations()) complete independently.
	var my_creations_header = Label.new()
	my_creations_header.text = "MY CREATIONS (no purchase needed)"
	my_creations_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(my_creations_header)

	_my_creations_status_label = Label.new()
	_my_creations_status_label.add_theme_font_size_override("font_size", 11)
	_my_creations_status_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	_my_creations_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_my_creations_status_label)

	var my_creations_scroll = ScrollContainer.new()
	my_creations_scroll.custom_minimum_size = Vector2(0, 60)
	outer.add_child(my_creations_scroll)
	_my_creations_vbox = VBoxContainer.new()
	_my_creations_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_creations_scroll.add_child(_my_creations_vbox)

	var random_skin_button = Button.new()
	random_skin_button.text = "Random Skin"
	random_skin_button.pressed.connect(_on_random_skin_pressed)
	outer.add_child(random_skin_button)

	# Custom color wheel -- free for every player (not gated behind a
	# purchase), so free-to-play still gets real personalization beyond
	# whatever skins happen to be owned.
	var custom_color_header = Label.new()
	custom_color_header.text = "CUSTOM COLOR (free)"
	custom_color_header.add_theme_font_size_override("font_size", 12)
	outer.add_child(custom_color_header)

	var color_row = HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 10)
	outer.add_child(color_row)

	_base_color_button = _make_color_picker_column(color_row, "Base")
	_dark_color_button = _make_color_picker_column(color_row, "Dark")
	_highlight_color_button = _make_color_picker_column(color_row, "Highlight")
	_base_color_button.color_changed.connect(func(color): _on_custom_color_changed("base_color", color))
	_dark_color_button.color_changed.connect(func(color): _on_custom_color_changed("dark_color", color))
	_highlight_color_button.color_changed.connect(func(color): _on_custom_color_changed("highlight_color", color))

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

func _part_available_to_current_faction(part: PartDefinition) -> bool:
	var faction_id: String = part.faction_id
	return faction_id.is_empty() or faction_id == LevelContext.current_faction_id

func _refresh_hull_picker_ui():
	for child in _hulls_vbox.get_children():
		child.queue_free()

	for part in _catalog:
		if part.category != PartDefinition.CAT_HULL_SEGMENT:
			continue
		if not _part_available_to_current_faction(part):
			continue
		var button = Button.new()
		button.text = part.display_name
		var part_id = part.part_id
		button.pressed.connect(func(): _start_new_blueprint(part_id, "MyShip"))
		_hulls_vbox.add_child(button)

func _refresh_palette_ui():
	for child in _palette_vbox.get_children():
		child.queue_free()

	var has_selection = _selected_socket_index >= 0 and _selected_socket_index < _open_sockets.size()
	var accepts_mask = int(_open_sockets[_selected_socket_index]["accepts"]) if has_selection else 0

	for part in _catalog:
		var bit = 1 << int(part.category)
		var fits = has_selection and (bit & accepts_mask) != 0 and _part_available_to_current_faction(part)
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

# --- ship naming + account badge -------------------------------------------------

func _on_ship_name_committed() -> void:
	var name_text = _ship_name_input.text.strip_edges()
	if name_text.is_empty():
		return
	_blueprint.ship_id = name_text
	PlayerProfile.set_active_ship_name(name_text)

func _refresh_badge_ui() -> void:
	if _badge_label == null:
		return
	var suffix = PlayerProfile.badge_suffix()
	_badge_label.text = suffix.strip_edges() if not suffix.is_empty() else ""
	_badge_label.visible = not suffix.is_empty()

## Fuller breakdown than _badge_label's short suffix -- ported from
## account_panel.gd's old "BADGES & PERKS" list (see that file's history):
## the Founder/Patron thank-you line plus any per-pack cosmetic perk
## (decal/special effect) a Tier 1 store purchase unlocks.
func _refresh_badge_detail_ui(purchases: Array) -> void:
	for child in _badge_detail_vbox.get_children():
		child.queue_free()

	var lines: Array = []
	if PlayerProfile.is_founder:
		lines.append("★ Founding Citizen -- name etched on the Founders Monument")
	elif PlayerProfile.is_paid:
		lines.append("✦ Founder Aevoria -- thank you for supporting the Commonwealth")

	for purchase in purchases:
		var product_name = purchase.get("product_name")
		if product_name == null:
			continue
		var reward = Tier1SkinCatalog.get_reward(product_name)
		if reward.is_empty():
			continue
		if not reward.get("decal_path", "").is_empty():
			lines.append("- %s: decal unlocked" % product_name)
		if not reward.get("special_effect", "").is_empty():
			lines.append("- %s: %s effect unlocked" % [product_name, reward["special_effect"].replace("_", " ")])

	if lines.is_empty():
		return

	for line in lines:
		var label = Label.new()
		label.text = line
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_badge_detail_vbox.add_child(label)

# --- custom color wheel (free for every player) -----------------------------------

func _make_color_picker_column(parent: HBoxContainer, label_text: String) -> ColorPickerButton:
	var column = VBoxContainer.new()
	parent.add_child(column)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 10)
	column.add_child(label)

	var picker = ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(60, 24)
	# Godot's built-in ColorPicker already includes a color-wheel mode
	# (HSV wheel picker) alongside the sliders -- no need to build a
	# custom wheel widget for this.
	column.add_child(picker)
	return picker

func _on_custom_color_changed(recipe_key: String, color: Color) -> void:
	_blueprint.skin_recipe[recipe_key] = "#%s" % color.to_html(false)
	_active_special_effect = ""
	_rebuild_preview()

func _refresh_color_pickers_ui() -> void:
	if _base_color_button == null:
		return
	_base_color_button.color = Color(_blueprint.skin_recipe.get("base_color", "#8a8f96"))
	_dark_color_button.color = Color(_blueprint.skin_recipe.get("dark_color", "#26201a"))
	_highlight_color_button.color = Color(_blueprint.skin_recipe.get("highlight_color", "#c7ccd1"))

# --- owned skins (Commonwealth account) -----------------------------------------

func _refresh_owned_skins():
	for child in _skins_vbox.get_children():
		child.queue_free()
	for child in _my_creations_vbox.get_children():
		child.queue_free()

	if not AevoriaAuth.is_logged_in():
		_skins_status_label.text = "Log in from the Level Select screen to use a purchased skin here."
		_my_creations_status_label.text = "Log in to use your own Skin Creator designs here."
		return

	_skins_status_label.text = "Loading your skins..."
	AevoriaAuth.fetch_owned_skins()
	_my_creations_status_label.text = "Loading your creations..."
	AevoriaAuth.fetch_my_creations()

func _on_my_creations_fetched(skins: Array) -> void:
	for child in _my_creations_vbox.get_children():
		child.queue_free()

	if skins.is_empty():
		_my_creations_status_label.text = "No designs yet -- make one at aevoria.space/creator/create."
		return

	_my_creations_status_label.text = "Pick one of your own designs:"
	for skin in skins:
		var recipe = skin.get("recipe")
		if typeof(recipe) != TYPE_DICTIONARY:
			continue
		var button = Button.new()
		var visibility_tag = "" if skin.get("is_public", true) else " (private)"
		button.text = "%s%s" % [skin.get("title", "(untitled)"), visibility_tag]
		button.pressed.connect(func(): _apply_owned_skin(recipe))
		_my_creations_vbox.add_child(button)

func _on_my_creations_fetch_failed(message: String) -> void:
	_my_creations_status_label.text = message

func _on_skins_fetched(purchases: Array):
	# update_from_purchases() already triggers _refresh_badge_ui() via the
	# badges_updated signal (connected in _ready()) -- the detail
	# breakdown below isn't state-gated the same way (it needs the full
	# purchases array every time, not just on a change), so it's called
	# directly here instead.
	PlayerProfile.update_from_purchases(purchases)
	_refresh_badge_detail_ui(purchases)
	for child in _skins_vbox.get_children():
		child.queue_free()

	if purchases.is_empty():
		_skins_status_label.text = "No purchased skins yet -- using a random skin."
		return

	_skins_status_label.text = "Pick one of your purchased skins:"
	var any_shown = false
	for purchase in purchases:
		# A Tier 1 (first-party store) purchase has no skin_id, so the
		# embedded "skins" join comes back as an explicit JSON null rather
		# than a missing key -- .get()'s default only covers the latter.
		var skin = purchase.get("skins", {})
		if skin == null:
			skin = {}
		var recipe = skin.get("recipe")
		if typeof(recipe) == TYPE_DICTIONARY:
			var button = Button.new()
			button.text = skin.get("title", "(untitled)")
			button.pressed.connect(func(): _apply_owned_skin(recipe))
			_skins_vbox.add_child(button)
			any_shown = true
			continue

		# Not a Tier 2 marketplace skin -- check if it's a Tier 1 store
		# item with a known fixed reward (see tier1_skin_catalog.gd).
		var product_name = purchase.get("product_name")
		if product_name == null:
			continue
		var reward = Tier1SkinCatalog.get_reward(product_name)
		if reward.is_empty():
			continue
		var button = Button.new()
		button.text = product_name
		button.pressed.connect(func(): _apply_tier1_reward(reward))
		_skins_vbox.add_child(button)
		any_shown = true

	if not any_shown:
		_skins_status_label.text = "No equippable skins yet -- using a random skin."

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
	_blueprint.decal_path = ""
	_active_special_effect = ""
	_rebuild_preview()
	_refresh_color_pickers_ui()

# tier1_skin_catalog.gd's reward dicts already use AssemblyBlueprint's
# native snake_case/hex shape directly (no web camelCase conversion
# needed, unlike _apply_owned_skin) since they're authored here in Godot.
func _apply_tier1_reward(reward: Dictionary):
	_blueprint.skin_recipe = reward.get("skin_recipe", {}).duplicate()
	_blueprint.decal_path = reward.get("decal_path", "")
	_active_special_effect = reward.get("special_effect", "")
	_rebuild_preview()
	_refresh_color_pickers_ui()

func _on_random_skin_pressed():
	_blueprint.skin_recipe = {
		"seed": randi() % 100000, "frequency": 0.08,
		"dark_color": "#26201a", "base_color": "#8a8f96", "highlight_color": "#c7ccd1",
	}
	_blueprint.decal_path = ""
	_active_special_effect = ""
	_rebuild_preview()
	_refresh_color_pickers_ui()

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
	_on_ship_name_committed()
	var dir = "user://blueprints"
	DirAccess.make_dir_recursive_absolute(dir)
	var path = "%s/%s.json" % [dir, _blueprint.ship_id]
	# AssemblyBlueprint.to_json() (C++, assembly_blueprint.cpp) only knows
	# ship_id/root_part_id/attachments/skin_recipe/decal_path -- nothing
	# reads this file back in, so it's safe to fold the display name and
	# current account badge on top here in GDScript rather than adding a
	# new field to the C++ resource and rebuilding the extension for it.
	var save_data = JSON.parse_string(_blueprint.to_json())
	save_data["display_name"] = _blueprint.ship_id
	save_data["badge"] = PlayerProfile.badge_suffix().strip_edges()
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	_status_label.text = "Saved: " + ProjectSettings.globalize_path(path)
	_record_infrastructure()
	if LevelContext.current_level_id != "":
		_finish_button.visible = true

## Distinct saved ships that include a habitat or power part count toward
## the building faction's Vital Continuity Index -- see the constants above
## and docs/VCI_TRACKING.md. Deduped by ship_id (FactionHomeBase's job),
## so tweaking and re-saving the same ship doesn't inflate the count.
## LevelCatalog._faction_label() names the log lines rather than hardcoding
## "Commonwealth" -- the Assembly Bay is shared by all three factions'
## catalog entries (Prospector Run/Combine Fabrication Yard/Flotilla Refit
## Deck all point at this same scene), so the grid a Tube Rocket Hull's
## power source feeds is the Combine's, not the Commonwealth's.
func _record_infrastructure() -> void:
	var faction_id = LevelContext.current_faction_id
	if faction_id == "":
		return
	var faction_label = LevelCatalog.faction_label(faction_id)
	var part_ids: Array = [_blueprint.root_part_id]
	for attachment in _blueprint.attachments:
		part_ids.append(attachment["part_id"])

	if part_ids.has(SHELTER_PART_ID):
		FactionHomeBase.mark_infrastructure_built(faction_id, "shelter", _blueprint.ship_id)
		SystemLog.log("Shelter registered: %s now provides habitat capacity." % _blueprint.ship_id)
	if part_ids.has(POWER_PART_ID):
		FactionHomeBase.mark_infrastructure_built(faction_id, "power", _blueprint.ship_id)
		SystemLog.log("Power source registered: %s now feeds the %s grid." % [_blueprint.ship_id, faction_label])
	if part_ids.has(SANITATION_PART_ID):
		FactionHomeBase.mark_infrastructure_built(faction_id, "sanitation", _blueprint.ship_id)
		SystemLog.log("Sanitation registered: %s now processes %s waste." % [_blueprint.ship_id, faction_label])
	if part_ids.has(HEALTHCARE_PART_ID):
		FactionHomeBase.mark_infrastructure_built(faction_id, "healthcare", _blueprint.ship_id)
		SystemLog.log("Healthcare registered: %s now provides medical capacity." % _blueprint.ship_id)

func _on_finish_pressed():
	LevelContext.finish_current_level({"Platinum": 25.0})
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
