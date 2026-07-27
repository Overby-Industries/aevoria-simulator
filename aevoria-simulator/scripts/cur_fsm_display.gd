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
	custom_minimum_size = Vector2(320, 200)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(20, 20)

	add_child(_make_glass_background(Color(0.05, 0.08, 0.15, 0.45)))

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	var header = Label.new()
	header.text = "COMPLIANCE STATUS"
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)

	_capture_risk_label = Label.new()
	_capture_risk_label.text = "Capture Risk: —"
	_capture_risk_label.add_theme_font_size_override("font_size", 12)
	outer.add_child(_capture_risk_label)

	outer.add_child(HSeparator.new())

	_list_vbox = VBoxContainer.new()
	_list_vbox.add_theme_constant_override("separation", 8)
	outer.add_child(_list_vbox)

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

func _ensure_row(entity_id: String) -> Dictionary:
	if _entity_rows.has(entity_id):
		return _entity_rows[entity_id]

	var row = VBoxContainer.new()

	var id_label = Label.new()
	id_label.text = entity_id
	id_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	row.add_child(id_label)

	var compliance_label = Label.new()
	row.add_child(compliance_label)

	var detail_label = Label.new()
	detail_label.add_theme_font_size_override("font_size", 11)
	detail_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
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

	entry.compliance.text = "Compliance: %s" % monitor.compliance_state_name(compliance)
	entry.compliance.add_theme_color_override("font_color", _compliance_color(compliance))

	var protected_suffix = "  [PROTECTED MODE]" if in_protected else ""
	entry.detail.text = "%s | %s%s" % [
		monitor.constitutional_state_name(constitutional),
		monitor.governance_state_name(governance),
		protected_suffix,
	]

func _compliance_color(state: int) -> Color:
	if state == monitor.KS_COMPLIANT or state == monitor.KS_CERTIFIED:
		return Color(0.45, 0.9, 0.55)
	elif state == monitor.KS_PENDING_REVIEW:
		return Color(0.95, 0.85, 0.35)
	else:
		return Color(0.95, 0.4, 0.35)

func _on_transition(entity_id, _axis, _from_state, _to_state, _trigger, _citation):
	_refresh_entity(entity_id)

func _on_protected_mode(entity_id, _entered, _citation):
	_refresh_entity(entity_id)

func _on_certification(entity_id, _granted):
	_refresh_entity(entity_id)

func _on_capture_risk(cri, band):
	_capture_risk_label.text = "Capture Risk: %.1f (%s)" % [cri, monitor.capture_risk_band_name(band)]
