extends Node

## The governance-side starter level: walks a mining charter through the
## CUR compliance FSM step by step, with plain-language callouts at each
## stage -- the "CUR learning tool tips" the level select promises.
## Reuses CURComplianceMonitor + CurHud verbatim; this script only adds
## the step script and the tutorial overlay around them.
##
## Every step here is scripted and local to this one player's session --
## there's no real community vote yet. The _steps array (a "text" + an
## "action" closure per step) is the shape a future real-vote step would
## slot into: see docs/MULTIPLAYER_ROADMAP.md for how a step's action
## would call a community_governance.gd autoload instead of
## monitor.submit_operational() directly.

@onready var monitor: CURComplianceMonitor = $CURComplianceMonitor
@onready var hud = $CurHud

var _charter
var _step: int = 0
var _steps: Array = []
var _tutorial_label: Label
var _next_button: Button
var _finish_button: Button
var _back_button: Button

func _ready():
	hud.set_monitor(monitor)
	_build_steps()
	_build_tutorial_ui()
	_show_step(0)

func _build_steps() -> void:
	_steps = [
		{
			"text": "The Code of Universal Regulations (CUR) tracks every operational licence through a compliance FSM. First, we register one for a mining charter.",
			"action": func(): _charter = monitor.register_entity("charter-prospector-01", monitor.EC_ECONOMIC, monitor.SUBJ_OPERATIONAL_LICENSE),
		},
		{
			"text": "Now the charter reports a mining operation within its debris budget. Watch the Compliance Status panel on the left -- it should read Compliant.",
			"action": func(): monitor.submit_operational(_charter, monitor.EV_MINING_OPERATION, {"debris_units": 40, "debris_limit": 100}, 1),
		},
		{
			"text": "Next it reports an operation that blows way past its debris limit. This is what triggers a violation -- watch the Violation Log panel fill in.",
			"action": func(): monitor.submit_operational(_charter, monitor.EV_MINING_OPERATION, {"debris_units": 400, "debris_limit": 100}, 2),
		},
		{
			"text": "That's the whole loop: report -> FSM checks the rule -> compliant or violation, logged either way. Every entity in the simulator that touches shared resources goes through this same path.",
			"action": func(): pass,
		},
	]

func _build_tutorial_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "AevoriaPanel"
	# Below the CUR HUD panels (which occupy roughly x=20..740, y=20..240),
	# not to their right -- a fixed x=760 previously ran past the default
	# window width and got clipped. This stays within the default 1152px
	# window regardless.
	panel.custom_minimum_size = Vector2(700, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 280)
	canvas.add_child(panel)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)

	var header = Label.new()
	header.text = "CUR WALKTHROUGH"
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
