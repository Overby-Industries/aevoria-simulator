extends CanvasLayer

## Top-center dock: the shared cycle/day counter (solar_system_state.gd)
## plus a live read of this faction's population and supply-cycle
## upkeep, docked everywhere VCI/Commons/the account panel already are
## (see level_chrome.gd) so a starvation warning is visible no matter
## which level you're standing in, not just inside the Situation View
## itself (situation_view.gd's own Civil Engineering panel has the same
## numbers plus the actual Run Supply Cycle / Grow Population actions --
## this is the always-on summary).
##
## Joins the "cycle_status_panel" group and exposes refresh() so
## situation_view.gd can push a live update after Run Supply Cycle/Grow
## Population -- otherwise this panel (built once in _ready(), unlike
## situation_view.gd's own Civil Engineering panel which rebuilds its
## own labels every action) would keep showing a stale cycle number
## until the next scene load. group broadcast (call_group), not a
## direct reference, since LevelChrome owns this panel's construction
## and never hands the instance back to the level that added it.
##
## Same styling convention as vci_commons_panel.gd -- GlassPanelFrame +
## GlassPanel.make() background, ThemeBootstrap.theme.

const GlassPanel = preload("res://scripts/glass_panel.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const SolarSystemState = preload("res://scripts/solar_system_state.gd")

const GROUP_NAME = "cycle_status_panel"

var _faction_id: String
var _header: Label
var _pop_label: Label
var _status_label: Label

func _init(faction_id: String) -> void:
	_faction_id = faction_id

func _ready() -> void:
	add_to_group(GROUP_NAME)

	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "GlassPanelFrame"
	panel.custom_minimum_size = Vector2(380, 0)
	# set_anchors_and_offsets_preset()'s MINSIZE-mode margin computes
	# offsets against the control's parent-area size at call time -- since
	# this panel isn't in the tree yet here, that computation used a stale/
	# default size instead of the real viewport width, landing the anchor
	# at the box's left edge rather than centering it (confirmed via
	# screenshot: box visibly offset right by ~half its own width). The
	# lobby's "Solar System Table" button (level_select.gd) never had this
	# bug because it uses the same manual preset+position technique this
	# now matches: set_anchors_preset() alone (no offset computation) plus
	# a hand-computed position = -half_width, so centering never depends on
	# the parent size being known at call time.
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-190, 20)
	add_child(panel)

	var bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.35), 1.0)
	panel.add_child(bg)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 4)
	panel.add_child(outer)

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 14)
	_header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_header)

	_pop_label = Label.new()
	_pop_label.add_theme_font_size_override("font_size", 11)
	_pop_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	_pop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_pop_label)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(330, 0)
	outer.add_child(_status_label)

	refresh()

func refresh() -> void:
	var cycle = SolarSystemState.get_current_cycle()
	var totals = SolarSystemState.total_population(_faction_id)
	var cost = SolarSystemState.upkeep_cost(_faction_id)
	var state = FactionHomeBase.load_state(_faction_id)
	var short = false
	for resource_name in cost.keys():
		if float(state["resources"].get(resource_name, 0.0)) < float(cost[resource_name]):
			short = true

	_header.text = "CYCLE %d" % cycle
	_pop_label.text = "Population: %d biological, %d silicon-based" % [totals["biological"], totals["silicon"]]

	_status_label.visible = totals["total"] > 0
	if short:
		_status_label.text = "WARNING: population at risk of starving -- supply cycle short on resources."
		_status_label.add_theme_color_override("font_color", Color(0.95, 0.45, 0.4))
	else:
		_status_label.text = "Supply cycle upkeep fully covered."
		_status_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.6))
