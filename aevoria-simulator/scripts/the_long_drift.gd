extends Node

## The Nomad Flotilla's first differentiated playstyle. Where
## oligarch_boardroom.gd trades the Combine's Capture Risk Index --
## externalizing cost onto institutional trust that isn't theirs to spend --
## the Flotilla has no institution to spend against. It has no home base,
## no built infrastructure (faction_home_base.gd's built_infrastructure
## count stays at zero for a fleet that never stops to build), and no CUR
## charter obliging it to report anything. What it has is its own crew's
## margins, so every hard choice here spends the Flotilla's own Vital
## Continuity Index instead -- the same FOUNDATION-003 §11 system the
## Commonwealth's infrastructure is scored on, just pointed at a wandering
## fleet's life support instead of a station's built infrastructure.
##
## Structurally this mirrors oligarch_boardroom.gd on purpose (three rounds,
## a safe choice and a risky one, cumulative inputs, a live score at the
## end) -- same shape, opposite axis: the Combine's number goes UP when it
## does harm to others, the Flotilla's number goes DOWN when it gambles
## with itself. update_vital_continuity()'s may_gate_service_access()
## returns false unconditionally (VitalContinuityModel, cur_capture_index.h)
## so nothing here locks content on a bad score either -- same diagnostic-
## only rule VCI follows everywhere else in this game.

@onready var monitor: CURComplianceMonitor = $CURComplianceMonitor
@onready var hud = $CurHud

const FactionHomeBase = preload("res://scripts/faction_home_base.gd")

# VitalContinuityInputs defaults (cur_capture_index.h): all four start at
# 100 (higher is better) and only ever move down here -- there's no
# built infrastructure in this level to raise them back up, which is the
# point: a flotilla that keeps choosing the risky leg has nothing to
# recover on except making it to the next port.
var _inputs := {"biological_life_support": 100.0, "silicon_life_support": 100.0, "infrastructure_resilience": 100.0, "accessibility": 100.0}
var _o2_banked: float = 0.0
var _pgm_banked: float = 0.0
var _round: int = 0
var _flotilla
var _flotilla_handle: int

const ROUNDS = [
	{
		"prompt": "Reserves are thin leaving port. The belt ahead is two days out at cruising burn, one day at strain.",
		"safe": {
			"label": "Ration tight, hold reserves for the full two days",
			"o2": 10.0, "pgm": 10.0,
			"deltas": {},
			"result": "Slow and steady. Nobody notices the ration -- that's the point.",
		},
		"risky": {
			"label": "Burn hard, make the belt in one day",
			"o2": 15.0, "pgm": 40.0,
			"deltas": {"biological_life_support": -20.0, "infrastructure_resilience": -10.0},
			"result": "First to the belt, first pick of the field. The reserve tanks are a lot emptier than the manifest says.",
		},
	},
	{
		"prompt": "The nav computer starts throwing parity errors under the strain of running two systems past their duty cycle.",
		"safe": {
			"label": "Throttle back, run full diagnostics before continuing",
			"o2": 5.0, "pgm": 15.0,
			"deltas": {},
			"result": "Clean bill of health. Cost most of a shift nobody was mining.",
		},
		"risky": {
			"label": "Patch it live, keep the drills running",
			"o2": 10.0, "pgm": 60.0,
			"deltas": {"silicon_life_support": -25.0, "accessibility": -15.0},
			"result": "The patch holds. Half the fleet can't raise the flagship on comms until it's re-flashed properly.",
		},
	},
	{
		"prompt": "An uncharted claim is sitting unclaimed at the edge of scanner range -- but the safe approach window is six hours out.",
		"safe": {
			"label": "Hold position, wait for the safe window",
			"o2": 5.0, "pgm": 20.0,
			"deltas": {},
			"result": "Someone else may beat you to it. The Flotilla is still whole.",
		},
		"risky": {
			"label": "Go in now, strip what you can before anyone else arrives",
			"o2": 5.0, "pgm": 90.0,
			"deltas": {"infrastructure_resilience": -20.0, "accessibility": -10.0},
			"result": "First and biggest haul of the run. The ships that made the dash are running on fumes and improvised repairs.",
		},
	},
]

var _canvas: CanvasLayer
var _header: Label
var _prompt_label: Label
var _result_label: Label
var _safe_button: Button
var _risky_button: Button
var _next_button: Button
var _finish_button: Button
var _back_button: Button

func _ready():
	hud.set_monitor(monitor)
	_flotilla = monitor.register_entity("nomad-flotilla-vanguard", monitor.EC_CIVIC, monitor.SUBJ_INFRASTRUCTURE, "Nomad Flotilla Vanguard")
	_flotilla_handle = _flotilla
	_build_ui()
	_show_round()

func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "AevoriaPanel"
	panel.custom_minimum_size = Vector2(700, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 280)
	_canvas.add_child(panel)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)

	_header = Label.new()
	_header.text = "THE LONG DRIFT"
	_header.add_theme_color_override("font_color", Color("1a1f26"))
	outer.add_child(_header)

	_prompt_label = Label.new()
	_prompt_label.add_theme_color_override("font_color", Color("1a1f26"))
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_prompt_label)

	_result_label = Label.new()
	_result_label.add_theme_color_override("font_color", Color("5a4406"))
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_result_label)

	var choice_row = HBoxContainer.new()
	choice_row.add_theme_constant_override("separation", 10)
	outer.add_child(choice_row)

	_safe_button = Button.new()
	_safe_button.theme_type_variation = "AevoriaButton"
	_safe_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_safe_button.custom_minimum_size = Vector2(320, 0)
	_safe_button.pressed.connect(func(): _on_choice("safe"))
	choice_row.add_child(_safe_button)

	_risky_button = Button.new()
	_risky_button.theme_type_variation = "AevoriaButton"
	_risky_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_risky_button.custom_minimum_size = Vector2(320, 0)
	_risky_button.pressed.connect(func(): _on_choice("risky"))
	choice_row.add_child(_risky_button)

	var nav_row = HBoxContainer.new()
	outer.add_child(nav_row)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.theme_type_variation = "AevoriaButton"
	_next_button.visible = false
	_next_button.pressed.connect(_on_next_pressed)
	nav_row.add_child(_next_button)

	_finish_button = Button.new()
	_finish_button.text = "Finish & Return to Level Select"
	_finish_button.theme_type_variation = "AevoriaButton"
	_finish_button.visible = false
	_finish_button.pressed.connect(_on_finish_pressed)
	nav_row.add_child(_finish_button)

	_back_button = Button.new()
	_back_button.text = "Back to Level Select"
	_back_button.theme_type_variation = "AevoriaButton"
	_back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	nav_row.add_child(_back_button)

func _show_round() -> void:
	if _round >= ROUNDS.size():
		_show_summary()
		return
	var round_data = ROUNDS[_round]
	_prompt_label.text = "Leg %d/%d -- %s" % [_round + 1, ROUNDS.size(), round_data["prompt"]]
	_result_label.text = ""
	_safe_button.text = round_data["safe"]["label"]
	_risky_button.text = round_data["risky"]["label"]
	_safe_button.visible = true
	_risky_button.visible = true
	_safe_button.disabled = false
	_risky_button.disabled = false
	_next_button.visible = false
	_finish_button.visible = false

func _on_choice(kind: String) -> void:
	var round_data = ROUNDS[_round]
	var choice = round_data[kind]

	_o2_banked += float(choice["o2"])
	_pgm_banked += float(choice["pgm"])
	for key in choice["deltas"].keys():
		_inputs[key] = clampf(_inputs[key] + float(choice["deltas"][key]), 0.0, 100.0)

	var vci = monitor.update_vital_continuity(_flotilla_handle, _inputs, _round + 1)
	var band = monitor.get_vital_continuity_band()
	var band_name = monitor.vital_continuity_band_name(band)

	_result_label.text = "%s (+%.0f O2, +%.0f PGM) -- Flotilla VCI now %.1f (%s)." % [
		choice["result"], choice["o2"], choice["pgm"], vci, band_name]
	SystemLog.log("[Long Drift] Leg %d: %s -> VCI %.1f (%s)." % [
		_round + 1, choice["label"], vci, band_name])

	_safe_button.disabled = true
	_risky_button.disabled = true
	if _round + 1 >= ROUNDS.size():
		_finish_button.visible = true
	else:
		_next_button.visible = true

func _on_next_pressed() -> void:
	_round += 1
	_show_round()

func _show_summary() -> void:
	var vci = monitor.get_vital_continuity()
	var band = monitor.get_vital_continuity_band()
	var band_name = monitor.vital_continuity_band_name(band)
	_prompt_label.text = "Made port. %.0f O2 and %.0f PGM in the hold, Flotilla VCI %.1f (%s)." % [_o2_banked, _pgm_banked, vci, band_name]
	_result_label.text = "No charter to report to, no institution scoring the Combine's kind of number against this crew -- just the same life-support math FOUNDATION-003 §11 runs on the Commonwealth's stations, pointed at a fleet that never stops to build reserves back up. A bad score here doesn't lock anything (may_gate_service_access() is false by design); it just means the next leg starts from wherever this one left off."
	_safe_button.visible = false
	_risky_button.visible = false
	_next_button.visible = false
	_finish_button.visible = true

func _on_finish_pressed() -> void:
	LevelContext.finish_current_level({"O2": _o2_banked, "PGM": _pgm_banked})
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
