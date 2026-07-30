extends Node

## The game's front door: pick a level (hardware build vs governance/CUR
## walkthrough), see faction standing, or drop into the full Main.tscn
## sandbox that all the earlier demo/dev work still lives in. Login
## (account_panel.gd / AccountHud) is declared as a sibling node in
## LevelSelect.tscn so it's available from the hub too. Docked top-left;
## the resource/status readout is a separate small panel docked top-right,
## the account panel (with Exit Game) docks bottom-right, and the system
## log (console_log_panel.gd) docks bottom-left.

const LevelCatalog = preload("res://scripts/level_catalog.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const GlassPanel = preload("res://scripts/glass_panel.gd")
const FoundersMonument = preload("res://scripts/founders_monument.gd")
const HeroBackdrop = preload("res://scripts/hero_backdrop.gd")
const ConsoleLogPanel = preload("res://scripts/console_log_panel.gd")
const VCITracker = preload("res://scripts/vci_tracker.gd")

var _faction_id = LevelCatalog.AEVORIA_COMMONWEALTH
var _founders_monument: CanvasLayer

func _ready() -> void:
	add_child(HeroBackdrop.new())
	add_child(ConsoleLogPanel.new())
	SystemLog.log("Level Select loaded.")
	_build_ui()
	# Shown automatically on the game's front door (see founders_monument.gd);
	# the "Admire" button below reopens it any time after this first look.
	_founders_monument = FoundersMonument.new()
	add_child(_founders_monument)

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "GlassPanelFrame"
	panel.custom_minimum_size = Vector2(420, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	canvas.add_child(panel)

	var panel_bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.35), 1.0)
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
	sandbox_button.theme_type_variation = "GlassButton"
	sandbox_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	outer.add_child(sandbox_button)

	var monument_button = Button.new()
	monument_button.text = "Admire the Founders Monument"
	monument_button.theme_type_variation = "GlassButton"
	monument_button.pressed.connect(func(): _founders_monument.show_monument())
	outer.add_child(monument_button)

	_build_resources_panel(canvas, state)

func _build_resources_panel(canvas: CanvasLayer, state: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.custom_minimum_size = Vector2(360, 0)
	# Real corner anchor (see account_panel.gd's matching comment) so this
	# follows the window on resize/fullscreen instead of staying put at
	# wherever the window happened to be sized at launch.
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.LayoutPresetMode.PRESET_MODE_MINSIZE, 20)
	# The preset alone leaves grow_horizontal at its default (END, i.e.
	# grows further right) -- for a right-docked panel that grows the
	# minimum-size rect off the edge of the screen instead of leftward
	# from the anchor. Force it explicitly.
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.theme_type_variation = "GlassPanelFrame"
	canvas.add_child(panel)

	var bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.35), 1.0)
	panel.add_child(bg)

	# The full VCI breakdown (4 categories x several sub-measures each,
	# plus the raw resource list) is taller than the window in a lot of
	# cases -- same off-screen-content lesson as the level list and
	# AssemblyBay before it: cap the panel height and scroll instead of
	# letting it run off-screen.
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 4)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "VITAL CONTINUITY INDEX"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)

	var vci = _compute_vci(state)
	var overall_label = Label.new()
	overall_label.text = "%.0f / 100 -- %s" % [vci["score"], vci["band_name"]]
	overall_label.add_theme_font_size_override("font_size", 22)
	overall_label.add_theme_color_override("font_color", vci["band_color"])
	outer.add_child(overall_label)

	outer.add_child(HSeparator.new())

	for category_label in vci["categories"].keys():
		var category = vci["categories"][category_label]
		var cat_label = Label.new()
		cat_label.text = "%s -- %.0f" % [category_label, category["score"]]
		cat_label.add_theme_font_size_override("font_size", 12)
		cat_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		cat_label.custom_minimum_size = Vector2(330, 0)
		cat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outer.add_child(cat_label)

		for measure in category["sub_measures"]:
			var m_label = Label.new()
			var suffix = "" if measure["tracked"] else "  (baseline -- not yet tracked)"
			m_label.text = "   - %s: %.0f%s" % [measure["label"], measure["score"], suffix]
			m_label.add_theme_font_size_override("font_size", 10)
			var tracked_color = Color(0.75, 0.85, 0.95) if measure["tracked"] else Color(0.5, 0.53, 0.58)
			m_label.add_theme_color_override("font_color", tracked_color)
			# autowrap alone does nothing without an explicit width to wrap
			# within -- a Label's minimum size is otherwise however wide its
			# unwrapped text is, which pushed this panel past the window
			# edge before this was added (same fix _build_level_card's
			# objective label already needed).
			m_label.custom_minimum_size = Vector2(330, 0)
			m_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			outer.add_child(m_label)

	outer.add_child(HSeparator.new())

	var resources_header = Label.new()
	resources_header.text = "COMMONS (raw banked resources)"
	resources_header.add_theme_font_size_override("font_size", 12)
	resources_header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(resources_header)

	var resources_label = Label.new()
	resources_label.add_theme_font_size_override("font_size", 11)
	resources_label.custom_minimum_size = Vector2(330, 0)
	resources_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resources_label.text = _format_resources(state["resources"])
	outer.add_child(resources_label)

## Feeds real banked-resource state (via vci_tracker.gd's mapping) into
## the VCI binding added to CURComplianceMonitor. The monitor here is a
## throwaway, scene-tree-free instance -- update_vital_continuity() only
## touches the C++ machine object, not anything that needs to be in the
## tree (unlike the per-level monitors in governance_level.gd/
## advocate_level.gd, which also load configured regulations on _ready()
## -- this one has none to load).
func _compute_vci(state: Dictionary) -> Dictionary:
	var computed = VCITracker.compute(state)
	var monitor = CURComplianceMonitor.new()
	var handle = monitor.register_entity("commonwealth-vci", monitor.EC_CIVIC, monitor.SUBJ_INFRASTRUCTURE, "Aevoria Commonwealth")
	var score = monitor.update_vital_continuity(handle, computed["inputs"], int(Time.get_unix_time_from_system()))
	var band = monitor.get_vital_continuity_band()
	var band_name = monitor.vital_continuity_band_name(band)
	var result = {
		"score": score,
		"band_name": band_name,
		"band_color": _band_color(band),
		"categories": computed["categories"],
	}
	monitor.free()
	return result

func _band_color(band: int) -> Color:
	match band:
		CURComplianceMonitor.VCB_STABLE:
			return Color(0.45, 0.85, 0.55)
		CURComplianceMonitor.VCB_OBSERVATION:
			return Color(0.6, 0.8, 0.95)
		CURComplianceMonitor.VCB_ELEVATED:
			return Color(0.95, 0.75, 0.35)
		CURComplianceMonitor.VCB_HIGH_RISK:
			return Color(0.95, 0.55, 0.3)
		_:
			return Color(0.95, 0.35, 0.35)

func _format_resources(resources: Dictionary) -> String:
	if resources.is_empty():
		return "(nothing banked yet)"
	var parts: Array = []
	var keys = resources.keys()
	keys.sort()
	for key in keys:
		parts.append("%s: %.1f" % [key, float(resources[key])])
	return ", ".join(parts)

func _build_level_card(level: Dictionary, state: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.theme_type_variation = "GlassPanelFrame"
	var card_bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.3), 1.0)
	card.add_child(card_bg)

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

	var launch_button = Button.new()
	launch_button.text = "Launch"
	launch_button.theme_type_variation = "GlassButton"
	var level_id = level["id"]
	var faction_id = level["faction_id"]
	var scene_path = level["scene_path"]
	launch_button.pressed.connect(func():
		LevelContext.start_level(level_id, faction_id)
		get_tree().change_scene_to_file(scene_path)
	)
	inner.add_child(launch_button)

	return card
