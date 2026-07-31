extends Node

## The advocate-system teaching level: an environmental interest (a reef
## habitat) that can't speak for itself, weighed against a mining expansion
## near it -- CUR-E §1.6. Mirrors governance_level.gd's step-by-step
## walkthrough pattern, but for the AdvocateRegistry bound to
## CURComplianceMonitor in this session's advocate-binding pass, rather than
## the base compliance FSM.

const LevelChrome = preload("res://scripts/level_chrome.gd")

@onready var monitor: CURComplianceMonitor = $CURComplianceMonitor
@onready var hud = $CurHud

const PROCEEDING_ID = "prc-reef-expansion-01"

var _reef
var _operator
var _dependent_advocate
var _independent_advocate
var _step: int = 0
var _steps: Array = []
var _tutorial_label: Label
var _next_button: Button
var _finish_button: Button
var _back_button: Button

func _ready():
	add_child(LevelChrome.new())
	hud.set_monitor(monitor)
	_build_steps()
	_build_tutorial_ui()
	_show_step(0)

func _build_steps() -> void:
	_steps = [
		{
			"text": "A mining operator wants to expand extraction near a reef habitat. The reef can't speak for itself -- CUR-E §1.6 requires a named advocate before any determination affecting it can proceed. Registering the reef, the operator, and a proposed advocate.",
			"action": _step_register_entities,
		},
		{
			"text": "First attempt: the operator proposes their own contracted biologist as the reef's advocate. Watch the Violation Log -- §7.7(c)(1)/§1.6(c)(1) disqualifies an advocate who depends on a party to the proceeding outright, not as a factor to weigh.",
			"action": _step_appoint_dependent_advocate,
		},
		{
			"text": "Second attempt: an independent ecologist with no ties to the operator, expertise demonstrated. This one clears every disqualification.",
			"action": _step_appoint_independent_advocate,
		},
		{
			"text": "With a cleared advocate appointed, the determination on the mining expansion can now proceed. Watch the Compliance Status panel -- this reports through the same TransitionContext.advocate_cleared the appointment check just set.",
			"action": _step_submit_determination,
		},
		{
			"text": "That's the loop: appointment can be refused outright on a conflict of interest, and only a live, cleared appointment lets a determination on a voiceless interest stand. Void that appointment later and any determination built on it becomes voidable too -- the record stays, marked, not erased.",
			"action": func(): pass,
		},
	]

func _step_register_entities() -> void:
	_reef = monitor.register_entity("reef-habitat-03", monitor.EC_CIVIC, monitor.SUBJ_RESOURCE)
	_operator = monitor.register_entity("mining-operator-04", monitor.EC_ECONOMIC, monitor.SUBJ_OPERATIONAL_LICENSE)
	_dependent_advocate = monitor.register_entity("contracted-biologist-01", monitor.EC_CIVIC, monitor.SUBJ_SENTIENT_BEING)
	_independent_advocate = monitor.register_entity("independent-ecologist-02", monitor.EC_CIVIC, monitor.SUBJ_SENTIENT_BEING)

func _step_appoint_dependent_advocate() -> void:
	var result = monitor.appoint_advocate({
		"advocate": _dependent_advocate, "represented": _reef,
		"domain": monitor.ADOM_ENVIRONMENTAL, "proceeding_id": PROCEEDING_ID,
		"expertise_demonstrated": true, "dependent_on_party": true,
	}, 1)
	print("[Advocate] contracted biologist appointment: ", monitor.advocate_result_name(result))

func _step_appoint_independent_advocate() -> void:
	var result = monitor.appoint_advocate({
		"advocate": _independent_advocate, "represented": _reef,
		"domain": monitor.ADOM_ENVIRONMENTAL, "proceeding_id": PROCEEDING_ID,
		"expertise_demonstrated": true,
	}, 2)
	print("[Advocate] independent ecologist appointment: ", monitor.advocate_result_name(result))

func _step_submit_determination() -> void:
	monitor.submit_operational(_reef, monitor.EV_REPRESENTED_DETERMINATION, {
		"advocate_ref": _independent_advocate, "advocate_cleared": true,
	}, 3)

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
	header.text = "ADVOCATE WALKTHROUGH"
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
