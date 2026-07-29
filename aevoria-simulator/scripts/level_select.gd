extends Node

## The game's front door: pick a level (hardware build vs governance/CUR
## walkthrough), see faction standing, or drop into the full Main.tscn
## sandbox that all the earlier demo/dev work still lives in. Login
## (account_panel.gd / AccountHud) is declared as a sibling node in
## LevelSelect.tscn so it's available from the hub too. Docked top-left;
## the resource/status readout is a separate small panel docked top-right,
## and the account panel (with Exit Game) docks bottom-right.

const LevelCatalog = preload("res://scripts/level_catalog.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const GlassPanel = preload("res://scripts/glass_panel.gd")

var _faction_id = LevelCatalog.AEVORIA_COMMONWEALTH

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.custom_minimum_size = Vector2(420, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	canvas.add_child(panel)

	var panel_bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.45))
	panel.add_child(panel_bg)

	# The level roster no longer fits a fixed-height window now that
	# there are five cards -- same off-screen-content bug that hit
	# AssemblyBay earlier, same fix: cap the panel height and scroll.
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "AEVORIA COMMONWEALTH — LEVEL SELECT"
	outer.add_child(header)

	outer.add_child(HSeparator.new())

	var state = FactionHomeBase.load_state(_faction_id)
	for level in LevelCatalog.build_levels():
		outer.add_child(_build_level_card(level, state))

	outer.add_child(HSeparator.new())

	var sandbox_button = Button.new()
	sandbox_button.text = "Open Sandbox / Dev Demos"
	sandbox_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	outer.add_child(sandbox_button)

	_build_resources_panel(canvas, state)

func _build_resources_panel(canvas: CanvasLayer, state: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.custom_minimum_size = Vector2(280, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var viewport_size = canvas.get_viewport().get_visible_rect().size
	panel.position = Vector2(viewport_size.x - 300, 20)
	canvas.add_child(panel)

	var bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.45))
	panel.add_child(bg)

	var inner = VBoxContainer.new()
	panel.add_child(inner)

	var header = Label.new()
	header.text = "COMMONS"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	inner.add_child(header)

	var resources_label = Label.new()
	resources_label.add_theme_font_size_override("font_size", 12)
	resources_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resources_label.text = _format_resources(state["resources"])
	inner.add_child(resources_label)

func _format_resources(resources: Dictionary) -> String:
	if resources.is_empty():
		return "Commons: (nothing banked yet)"
	var parts: Array = []
	var keys = resources.keys()
	keys.sort()
	for key in keys:
		parts.append("%s: %.1f" % [key, float(resources[key])])
	return "Commons: " + ", ".join(parts)

func _build_level_card(level: Dictionary, state: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var is_governance = level["kind"] == LevelCatalog.Kind.GOVERNANCE
	if is_governance:
		card.theme_type_variation = "AevoriaPanel"

	var inner = VBoxContainer.new()
	card.add_child(inner)

	var complete = state["completed_levels"].has(level["id"])
	var title = Label.new()
	title.text = "%s%s" % [level["title"], "  [DONE]" if complete else ""]
	inner.add_child(title)

	var objective = Label.new()
	objective.text = level["objective"]
	objective.add_theme_font_size_override("font_size", 11)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size = Vector2(380, 0)
	inner.add_child(objective)

	if is_governance:
		title.add_theme_color_override("font_color", Color("1a1f26"))
		objective.add_theme_color_override("font_color", Color("3a4148"))

	var launch_button = Button.new()
	launch_button.text = "Launch"
	if is_governance:
		launch_button.theme_type_variation = "AevoriaButton"
	var level_id = level["id"]
	var faction_id = level["faction_id"]
	var scene_path = level["scene_path"]
	launch_button.pressed.connect(func():
		LevelContext.start_level(level_id, faction_id)
		get_tree().change_scene_to_file(scene_path)
	)
	inner.add_child(launch_button)

	return card
