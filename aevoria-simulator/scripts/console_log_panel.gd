extends CanvasLayer

## Bottom-left "system log" console -- shows real events from the
## SystemLog autoload (logins, level completions, resource rewards) as
## they happen, in the same glassy/amber-adjacent style as every other
## HUD panel (glass_panel.gd + theme_builder.gd's GlassPanelFrame).
## Terminal-green text is the one deliberate departure from the amber
## accent, since this is meant to read as a console/log readout.

const GlassPanel = preload("res://scripts/glass_panel.gd")

const MAX_VISIBLE_LINES = 40
const BACKFILL_LINES = 20

var _lines_vbox: VBoxContainer
var _scroll: ScrollContainer

func _ready() -> void:
	_build_ui()
	SystemLog.message_logged.connect(_on_message_logged)
	for entry in SystemLog.get_recent(BACKFILL_LINES):
		_add_line(entry)
	_scroll_to_bottom()

func _build_ui() -> void:
	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "GlassPanelFrame"
	panel.custom_minimum_size = Vector2(440, 0)
	# Bottom-left dock, mirroring account_panel.gd's bottom-right anchor
	# setup -- PRESET_MODE_MINSIZE + an explicit grow direction so this
	# actually follows the window on resize instead of drifting off-screen.
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.LayoutPresetMode.PRESET_MODE_MINSIZE, 20)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)

	var bg = GlassPanel.make(Color(0.02, 0.03, 0.05, 0.4), 1.0)
	panel.add_child(bg)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	panel.add_child(outer)

	var header = Label.new()
	header.text = "SYSTEM LOG"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)
	outer.add_child(HSeparator.new())

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(440, 140)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)

	_lines_vbox = VBoxContainer.new()
	_lines_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_lines_vbox)

func _on_message_logged(entry: Dictionary) -> void:
	_add_line(entry)
	_scroll_to_bottom()

func _add_line(entry: Dictionary) -> void:
	var label = Label.new()
	label.text = "[%s] %s" % [entry["time"], entry["text"]]
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.75))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lines_vbox.add_child(label)
	while _lines_vbox.get_child_count() > MAX_VISIBLE_LINES:
		_lines_vbox.get_child(0).queue_free()

func _scroll_to_bottom() -> void:
	# The scrollbar's max_value isn't updated until layout recomputes on
	# the next frame -- setting scroll_vertical this frame would use the
	# stale (too-small) max and land one line short.
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
