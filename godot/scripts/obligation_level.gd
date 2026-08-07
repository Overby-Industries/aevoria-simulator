extends Node

## The built-in-test teaching level: a restriction on liberty that requires
## periodic review -- CUR-H.7 §7.12(c)(3) -- and what happens when nobody
## files it. Mirrors advocate_level.gd's step-by-step walkthrough pattern,
## but for CURComplianceMonitor's obligation register / run_builtin_test()
## bound in this session's obligation-binding pass.
##
## The whole point of this system is that a lapse is caught by the CLOCK,
## not by a submission -- so this walkthrough advances an in-level tick
## counter across steps instead of driving events one submit at a time,
## which is how every other level here works.

const LevelChrome = preload("res://scripts/level_chrome.gd")
const StandingReviewBackdrop = preload("res://scripts/standing_review_backdrop.gd")

@onready var monitor: CURComplianceMonitor = $CURComplianceMonitor
@onready var hud = $CurHud

const DUE_TICK = 10
const LAPSE_CHECK_TICK = 20

var _oversight_office
var _oversight_office_id = "commonwealth-oversight-office"
var _restricted_being
var _restricted_being_id = "detained-citizen-07"
var _obligation_id: int = -1
var _step: int = 0
var _steps: Array = []
var _tutorial_label: Label
var _next_button: Button
var _finish_button: Button
var _back_button: Button

func _ready():
	var chrome = LevelChrome.new()
	chrome.light_theme = true
	add_child(chrome)
	add_child(StandingReviewBackdrop.new())
	hud.set_monitor(monitor)
	monitor.obligation_lapsed.connect(_on_obligation_lapsed)
	_build_steps()
	_build_tutorial_ui()
	_show_step(0)

func _build_steps() -> void:
	_steps = [
		{
			"text": "A being is under a restriction on liberty. CUR-H.7 §7.12(c)(3) requires the restriction be reviewed at intervals to remain lawful -- opening that obligation now, due at tick %d." % DUE_TICK,
			"action": _step_open_obligation,
		},
		{
			"text": "Tick 5, before the review is due: the restriction is still supported. run_builtin_test() runs anyway -- it always can, that's the point -- but finds nothing to catch yet.",
			"action": _step_check_before_due,
		},
		{
			"text": "Tick %d: the due date passed and nobody filed the review. No guard could have caught this -- a guard is only checked when something is submitted, and the failure here IS that nothing was submitted. Running the built-in test now." % LAPSE_CHECK_TICK,
			"action": _step_run_builtin_test,
		},
		{
			"text": "Watch where the fault landed: the oversight office that owed the review, never the detained citizen. CUR-H.7 §7.11(c) forbids a measure attaching to the being an obligation protects -- check the Violation Log for both entities below.",
			"action": _step_show_violations,
		},
		{
			"text": "That's the built-in test: obligations run on the clock, not on submission, and CUR-H.7 §7.12(d) puts the direction of failure on whoever owed the obligation. The being did nothing, and the restriction stopped being supported on its own -- no petition, no advocate needing to be awake at the right moment.",
			"action": func(): pass,
		},
	]

func _step_open_obligation() -> void:
	_oversight_office = monitor.register_entity(_oversight_office_id, monitor.EC_INSTITUTIONAL, monitor.SUBJ_INSTITUTION)
	_restricted_being = monitor.register_entity(_restricted_being_id, monitor.EC_CIVIC, monitor.SUBJ_SENTIENT_BEING)
	_obligation_id = monitor.open_obligation(monitor.OBLIG_REVIEW_RESTRICTION, _oversight_office, _restricted_being,
		0, DUE_TICK, 0, "Standing review of a liberty restriction")
	SystemLog.log("Obligation opened: review of %s due at tick %d (%s)." % [
		_restricted_being_id, DUE_TICK, monitor.obligation_kind_name(monitor.OBLIG_REVIEW_RESTRICTION)])

func _step_check_before_due() -> void:
	var lapses = monitor.run_builtin_test(5)
	var supported = monitor.restriction_supported(_restricted_being, 5)
	SystemLog.log("Tick 5: built-in test found %d lapse(s). Restriction still supported: %s." % [lapses, supported])

func _step_run_builtin_test() -> void:
	var lapses = monitor.run_builtin_test(LAPSE_CHECK_TICK)
	var supported = monitor.restriction_supported(_restricted_being, LAPSE_CHECK_TICK)
	SystemLog.log("Tick %d: built-in test found %d lapse(s). Restriction still supported: %s." % [
		LAPSE_CHECK_TICK, lapses, supported])

func _step_show_violations() -> void:
	var office_violations = monitor.get_violations_for(_oversight_office_id)
	var being_violations = monitor.get_violations_for(_restricted_being_id)
	print("[Obligation] violations against oversight office: ", office_violations)
	print("[Obligation] violations against restricted being (should be empty): ", being_violations)
	SystemLog.log("Violations against the oversight office: %d. Against the detained citizen: %d." % [
		office_violations.size(), being_violations.size()])

func _on_obligation_lapsed(obligation_id: int, kind: int, owed_by_id: String, concerning_id: String,
		severity: int, citation: String) -> void:
	print("[Obligation] LAPSED id=%d kind=%s owed_by=%s concerning=%s severity=%s citation=%s" % [
		obligation_id, monitor.obligation_kind_name(kind), owed_by_id, concerning_id,
		monitor.fault_class_name(severity), citation])
	SystemLog.log("Obligation lapsed: %s owed a review of %s and missed it (%s)." % [
		owed_by_id, concerning_id, citation])

func _build_tutorial_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "AevoriaPanel"
	# Below the CUR HUD panels, not beside them -- see governance_level.gd's
	# note on why a fixed x=760 ran off-screen on a real window.
	panel.custom_minimum_size = Vector2(700, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 280)
	canvas.add_child(panel)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)

	var header = Label.new()
	header.text = "BUILT-IN TEST WALKTHROUGH"
	header.add_theme_color_override("font_color", Color("1a1f26"))
	outer.add_child(header)

	_tutorial_label = Label.new()
	_tutorial_label.add_theme_color_override("font_color", Color("1a1f26"))
	_tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_tutorial_label)

	var row = HBoxContainer.new()
	outer.add_child(row)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.theme_type_variation = "AevoriaButton"
	_next_button.pressed.connect(_on_next_pressed)
	row.add_child(_next_button)

	_finish_button = Button.new()
	_finish_button.text = "Finish & Return to Level Select"
	_finish_button.theme_type_variation = "AevoriaButton"
	_finish_button.visible = false
	_finish_button.pressed.connect(_on_finish_pressed)
	row.add_child(_finish_button)

	_back_button = Button.new()
	_back_button.text = "Back to Level Select"
	_back_button.theme_type_variation = "AevoriaButton"
	_back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	row.add_child(_back_button)

func _show_step(index: int) -> void:
	_step = index
	var step = _steps[_step]
	_tutorial_label.text = step["text"]
	step["action"].call()
	var is_last = _step == _steps.size() - 1
	_next_button.visible = not is_last
	_finish_button.visible = is_last

func _on_next_pressed() -> void:
	if _step + 1 < _steps.size():
		_show_step(_step + 1)

func _on_finish_pressed() -> void:
	LevelContext.finish_current_level({"CompliancePoints": 10.0})
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
