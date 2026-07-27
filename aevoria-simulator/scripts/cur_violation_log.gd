extends PanelContainer
class_name CURViolationLog

## Live, newest-first violation feed driven by CURComplianceMonitor's
## violation_detected signal. Purely additive display -- the real record
## lives in the FSM's own ViolationLedger; this just mirrors it for players.
##
## Call set_monitor() once after both this node and the monitor exist; see
## the note in cur_fsm_display.gd for why this isn't a NodePath export.
##
## Themed as "AevoriaPanel" to match cur_fsm_display.gd -- this is the same
## governance-data surface, just the violation half of it.

@export var max_entries: int = 30

const ThemeBuilder = preload("res://scripts/theme_builder.gd")

var monitor: CURComplianceMonitor
var _list_vbox: VBoxContainer

func _ready():
	_build_ui()

func set_monitor(p_monitor: CURComplianceMonitor):
	monitor = p_monitor
	monitor.violation_detected.connect(_on_violation_detected)

func _build_ui():
	theme = ThemeBootstrap.theme
	custom_minimum_size = Vector2(380, 220)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(360, 20)
	theme_type_variation = "AevoriaPanel"

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	var header = Label.new()
	header.text = "VIOLATION LOG"
	header.add_theme_color_override("font_color", Color("7a1f1f"))
	header.tooltip_text = "Every violation CUR detects lands here, newest first. This is a mirror for players -- the authoritative record is the FSM's own ViolationLedger, which citation strings in each row point back to."
	outer.add_child(header)

	outer.add_child(HSeparator.new())

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 170)
	# Scroll vertically only -- horizontal scroll disabled forces row labels
	# to respect the panel's width instead of overflowing past it, which is
	# what makes autowrap on each row actually wrap instead of just clipping.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(_list_vbox)

	var empty_label = Label.new()
	empty_label.name = "EmptyLabel"
	empty_label.text = "No violations recorded."
	empty_label.add_theme_color_override("font_color", Color("6b7280"))
	_list_vbox.add_child(empty_label)

func _on_violation_detected(entity_id: String, violation_id: String, citation: String):
	var empty_label = _list_vbox.get_node_or_null("EmptyLabel")
	if empty_label:
		empty_label.queue_free()

	var row = Label.new()
	row.text = "[%s] %s — %s" % [violation_id, entity_id, citation]
	row.add_theme_color_override("font_color", Color("8a2a2a"))
	row.add_theme_font_size_override("font_size", 12)
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_child(row)
	_list_vbox.move_child(row, 0)

	while _list_vbox.get_child_count() > max_entries:
		_list_vbox.get_child(_list_vbox.get_child_count() - 1).queue_free()
