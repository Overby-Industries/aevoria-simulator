extends PanelContainer
class_name CURFSMDisplay

## Live compliance dashboard driven entirely by CURComplianceMonitor's
## signals -- never polls. One row per entity, auto-created the first time a
## transition for that entity is observed.
##
## Call set_monitor() once after both this node and the monitor exist; there
## is no NodePath auto-resolution here on purpose. Godot readies children
## before parents, so a parent-supplied NodePath set in _ready() would still
## arrive one frame too late for this node's own _ready() to use it.
##
## Themed as "AevoriaPanel" (flat civil slate) rather than the Overby dark
## console default -- compliance/constitutional state is Commonwealth
## governance data, not hardware telemetry. See theme_builder.gd.

const ThemeBuilder = preload("res://scripts/theme_builder.gd")

var monitor: CURComplianceMonitor
var _list_vbox: VBoxContainer
var _capture_risk_label: Label
var _entity_rows: Dictionary = {}  # entity_id -> {row, compliance, detail}

func _ready():
	_build_ui()

func set_monitor(p_monitor: CURComplianceMonitor):
	monitor = p_monitor
	monitor.transition_accepted.connect(_on_transition)
	monitor.protected_mode_changed.connect(_on_protected_mode)
	monitor.certification_changed.connect(_on_certification)
	monitor.capture_risk_updated.connect(_on_capture_risk)

func _build_ui():
	theme = ThemeBootstrap.theme
	custom_minimum_size = Vector2(320, 200)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(20, 20)
	theme_type_variation = "AevoriaPanel"

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	var header = Label.new()
	header.text = "COMPLIANCE STATUS"
	header.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DARK)
	header.tooltip_text = "Every entity that touches shared resources runs through the CUR compliance FSM. This panel mirrors its live state -- it never polls, it only reacts to signals."
	outer.add_child(header)

	_capture_risk_label = Label.new()
	_capture_risk_label.text = "Capture Risk: —"
	_capture_risk_label.add_theme_font_size_override("font_size", 12)
	_capture_risk_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DARK)
	_capture_risk_label.tooltip_text = "Capture Risk Index: how close this entity's governance influence is to regulatory capture. Low is safe; the band name (e.g. ELEVATED, CRITICAL) is what actually triggers protective measures."
	outer.add_child(_capture_risk_label)

	outer.add_child(HSeparator.new())

	_list_vbox = VBoxContainer.new()
	_list_vbox.add_theme_constant_override("separation", 8)
	outer.add_child(_list_vbox)

func _ensure_row(entity_id: String) -> Dictionary:
	if _entity_rows.has(entity_id):
		return _entity_rows[entity_id]

	var row = VBoxContainer.new()

	var id_label = Label.new()
	id_label.text = entity_id
	id_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DARK)
	row.add_child(id_label)

	var compliance_label = Label.new()
	compliance_label.tooltip_text = "Compliance state: whether this entity's latest reported activity satisfied the rules it's currently bound by. Distinct from the constitutional/governance states shown below it, which track deeper standing."
	row.add_child(compliance_label)

	var detail_label = Label.new()
	detail_label.add_theme_font_size_override("font_size", 11)
	detail_label.add_theme_color_override("font_color", Color("5a6470"))
	row.add_child(detail_label)

	_list_vbox.add_child(row)

	var entry = {"row": row, "compliance": compliance_label, "detail": detail_label}
	_entity_rows[entity_id] = entry
	return entry

func _refresh_entity(entity_id: String):
	if monitor == null:
		return
	var handle = monitor.find_entity(entity_id)
	if handle == monitor.INVALID_ENTITY:
		return

	var entry = _ensure_row(entity_id)
	var compliance = monitor.get_compliance_state(handle)
	var constitutional = monitor.get_constitutional_state(handle)
	var governance = monitor.get_governance_state(handle)
	var in_protected = monitor.in_protected_mode(handle)

	# .capitalize() is display-only cosmetics (SCREAMING_SNAKE_CASE -> Title
	# Case) -- the underlying name still comes from libcur's own
	# cur::to_string(), so there's still exactly one source of truth for
	# what these states are actually called.
	entry.compliance.text = "Compliance: %s" % monitor.compliance_state_name(compliance).capitalize()
	entry.compliance.add_theme_color_override("font_color", _compliance_color(compliance))

	var protected_suffix = "  [PROTECTED MODE]" if in_protected else ""
	entry.detail.text = "%s | %s%s" % [
		monitor.constitutional_state_name(constitutional).capitalize(),
		monitor.governance_state_name(governance).capitalize(),
		protected_suffix,
	]

func _compliance_color(state: int) -> Color:
	if state == monitor.KS_COMPLIANT or state == monitor.KS_CERTIFIED:
		return Color("1f7a3a")
	elif state == monitor.KS_PENDING_REVIEW:
		return Color("8a6b06")
	else:
		return Color("a1272a")

func _on_transition(entity_id, _axis, _from_state, _to_state, _trigger, _citation):
	_refresh_entity(entity_id)

func _on_protected_mode(entity_id, _entered, _citation):
	_refresh_entity(entity_id)

func _on_certification(entity_id, _granted):
	_refresh_entity(entity_id)

func _on_capture_risk(cri, band):
	_capture_risk_label.text = "Capture Risk: %.1f (%s)" % [cri, monitor.capture_risk_band_name(band)]
