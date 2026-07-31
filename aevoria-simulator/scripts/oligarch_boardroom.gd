extends Node

## The Oligarch Combine's first real differentiated playstyle: instead of a
## scripted walkthrough (governance_level.gd/advocate_level.gd/
## obligation_level.gd all just click Next through a fixed narration), this
## level puts an actual choice in front of the player each round -- a clean
## option and a corrupt one -- and both options are real. The corrupt path
## banks more PGM every time; what it costs is the Combine's own Capture
## Risk Index (CURComplianceMonitor.update_capture_risk), the same
## machinery CUR-X.4 §4.2(d) requires be applied to an enterprise "on the
## same basis as concentration within a governance institution". Nothing
## here gates or punishes the corrupt choice mechanically -- CUR-X.4 §4.9(a)
## requires due process before any measure attaches, and no due-process
## step exists in this walkthrough, so the level only ever shows the score
## climbing. That's deliberate: it's what capture looks like before anyone
## with standing to act on it does.
##
## Reuses CURComplianceMonitor + CurHud verbatim -- the existing "Capture
## Risk: —" label in cur_fsm_display.gd already updates live off
## capture_risk_updated, so this level needs no HUD work of its own.

@onready var monitor: CURComplianceMonitor = $CURComplianceMonitor
@onready var hud = $CurHud

const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const LevelChrome = preload("res://scripts/level_chrome.gd")

# CaptureRiskInputs defaults (cur_capture_index.h): iii/dpi/thi start at
# 100 (higher is better), eci/ici/rdi start at 0 (higher is worse). Each
# round's deltas are added on top and clamped back into 0..100 -- these
# are cumulative across the quarter, not reset per round, since that's
# what actually lets three small corrupt choices compound into one big
# score the way real regulatory capture does.
var _inputs := {"eci": 0.0, "ici": 0.0, "iii": 100.0, "dpi": 100.0, "thi": 100.0, "rdi": 0.0}
var _pgm_banked: float = 0.0
var _round: int = 0
var _combine

const ROUNDS = [
	{
		"prompt": "A rival prospector's claim overlaps Combine territory.",
		"straight": {
			"label": "File a competing claim through proper channels",
			"pgm": 40.0,
			"deltas": {"eci": 5.0},
			"result": "Filed cleanly. Modest yield, barely moves the needle.",
		},
		"corrupt": {
			"label": "Buy out the rival's charter below market, fold it into Combine holdings",
			"pgm": 120.0,
			"deltas": {"eci": 35.0, "ici": 5.0, "rdi": 10.0},
			"result": "Absorbed. Three times the yield -- and the field now depends on one buyer.",
		},
	},
	{
		"prompt": "A CUR compliance officer flags the Combine's debris output.",
		"straight": {
			"label": "Pay the retrofit costs, come into compliance",
			"pgm": 20.0,
			"deltas": {},
			"result": "Compliant, and poorer for it. Nothing about the Combine's standing changed.",
		},
		"corrupt": {
			"label": "Quietly compensate the officer to let it slide",
			"pgm": 100.0,
			"deltas": {"ici": 25.0, "thi": -30.0, "iii": -20.0},
			"result": "The flag disappears. So does a chunk of institutional integrity and transparency.",
		},
	},
	{
		"prompt": "The quarterly governance transparency report is due.",
		"straight": {
			"label": "File the full report, buyout and payment included",
			"pgm": 10.0,
			"deltas": {},
			"result": "On the record. Whatever the score is now, it's the real one.",
		},
		"corrupt": {
			"label": "File a report that omits both",
			"pgm": 30.0,
			"deltas": {"thi": -25.0, "dpi": -15.0},
			"result": "Clean report, dirty ledger. Transparency and participation both take the hit.",
		},
	},
]

var _canvas: CanvasLayer
var _header: Label
var _prompt_label: Label
var _result_label: Label
var _straight_button: Button
var _corrupt_button: Button
var _next_button: Button
var _finish_button: Button
var _back_button: Button

func _ready():
	add_child(LevelChrome.new())
	hud.set_monitor(monitor)
	_combine = monitor.register_entity("oligarch-combine-holdings", monitor.EC_ECONOMIC, monitor.SUBJ_OPERATIONAL_LICENSE)
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
	_header.text = "BOARDROOM CAPTURE"
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

	_straight_button = Button.new()
	_straight_button.theme_type_variation = "AevoriaButton"
	_straight_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_straight_button.custom_minimum_size = Vector2(320, 0)
	_straight_button.pressed.connect(func(): _on_choice("straight"))
	choice_row.add_child(_straight_button)

	_corrupt_button = Button.new()
	_corrupt_button.theme_type_variation = "AevoriaButton"
	_corrupt_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_corrupt_button.custom_minimum_size = Vector2(320, 0)
	_corrupt_button.pressed.connect(func(): _on_choice("corrupt"))
	choice_row.add_child(_corrupt_button)

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
	_prompt_label.text = "Round %d/%d -- %s" % [_round + 1, ROUNDS.size(), round_data["prompt"]]
	_result_label.text = ""
	_straight_button.text = round_data["straight"]["label"]
	_corrupt_button.text = round_data["corrupt"]["label"]
	_straight_button.visible = true
	_corrupt_button.visible = true
	_straight_button.disabled = false
	_corrupt_button.disabled = false
	_next_button.visible = false
	_finish_button.visible = false

func _on_choice(kind: String) -> void:
	var round_data = ROUNDS[_round]
	var choice = round_data[kind]

	_pgm_banked += float(choice["pgm"])
	for key in choice["deltas"].keys():
		_inputs[key] = clampf(_inputs[key] + float(choice["deltas"][key]), 0.0, 100.0)

	var cri = monitor.update_capture_risk(_inputs, _round + 1)
	var band = monitor.get_capture_risk_band()
	var band_name = monitor.capture_risk_band_name(band)

	_result_label.text = "%s (+%.0f PGM) -- Capture Risk now %.1f (%s)." % [
		choice["result"], choice["pgm"], cri, band_name]
	SystemLog.log("[Boardroom] Round %d: %s -> CRI %.1f (%s)." % [
		_round + 1, choice["label"], cri, band_name])

	_straight_button.disabled = true
	_corrupt_button.disabled = true
	if _round + 1 >= ROUNDS.size():
		_finish_button.visible = true
	else:
		_next_button.visible = true

func _on_next_pressed() -> void:
	_round += 1
	_show_round()

func _show_summary() -> void:
	var cri = monitor.get_capture_risk()
	var band = monitor.get_capture_risk_band()
	var band_name = monitor.capture_risk_band_name(band)
	_prompt_label.text = "Quarter closed. %.0f PGM banked, Capture Risk %.1f (%s)." % [_pgm_banked, cri, band_name]
	_result_label.text = "The same Capture Risk Index the Commonwealth is scored on just scored the Combine -- CUR-X.4 §4.2(d) applies it to an enterprise on the same basis as a governance institution. Nothing forced a choice here; §4.9(a) requires a completed determination before any measure attaches, and none happened. That's the gap the Combine plays in."
	_straight_button.visible = false
	_corrupt_button.visible = false
	_next_button.visible = false
	_finish_button.visible = true

func _on_finish_pressed() -> void:
	LevelContext.finish_current_level({"PGM": _pgm_banked})
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
