extends CanvasLayer

## Top-right dock: Vital Continuity Index + Commons (raw banked resources
## + the Critical Supply Chain meter), for whichever faction_id is passed
## in. Extracted from level_select.gd so every level can show the same
## live standing Level Select does -- previously only Level Select had
## this panel at all, so switching into a level meant losing sight of VCI/
## resources entirely. See level_chrome.gd, which bundles this with the
## account and system-log panels for any level that isn't Level Select
## itself (Level Select already has its own AccountHud/ConsoleLogPanel
## wired in LevelSelect.tscn/_ready(), so it uses this panel directly
## rather than going through LevelChrome).

const GlassPanel = preload("res://scripts/glass_panel.gd")
const VCITracker = preload("res://scripts/vci_tracker.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")

var _faction_id: String

func _init(faction_id: String) -> void:
	_faction_id = faction_id

func _ready() -> void:
	var state = FactionHomeBase.load_state(_faction_id)

	var column = VBoxContainer.new()
	column.custom_minimum_size = Vector2(360, 0)
	column.add_theme_constant_override("separation", 12)
	add_child(column)

	_build_vci_panel(column, state)
	_build_commons_panel(column, state)

	# PRESET_MODE_MINSIZE's offset math reads get_combined_minimum_size(),
	# which for a Container reflects its CHILDREN's minimum sizes -- calling
	# this before column had any children (the original order here) meant
	# it read essentially zero width, anchoring the whole panel into a
	# sliver a couple pixels wide at the right edge with all its text
	# rendering off past the window boundary (confirmed via pixel-sampling
	# a screenshot: no left border was found anywhere near where a 360px-
	# wide panel should have one). Building all content first, then
	# applying the preset, is what makes MINSIZE mode compute a real size.
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.LayoutPresetMode.PRESET_MODE_MINSIZE, 20)
	# The preset alone leaves grow_horizontal at its default (END, i.e.
	# grows further right) -- for a right-docked column that grows the
	# minimum-size rect off the edge of the screen instead of leftward
	# from the anchor. Force it explicitly.
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN

func _build_vci_panel(column: VBoxContainer, state: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "GlassPanelFrame"
	column.add_child(panel)

	var bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.35), 1.0)
	panel.add_child(bg)

	# The full VCI breakdown (4 categories x several sub-measures each) is
	# taller than the window in a lot of cases -- same off-screen-content
	# lesson as the level list and AssemblyBay before it: cap the panel
	# height and scroll instead of letting it run off-screen.
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 4)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "VITAL CONTINUITY INDEX"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)

	var vci = _compute_vci(state)
	var overall_label = Label.new()
	overall_label.text = "%.0f / 100 -- %s" % [vci["score"], vci["band_name"]]
	overall_label.add_theme_font_size_override("font_size", 22)
	overall_label.add_theme_color_override("font_color", vci["band_color"])
	outer.add_child(overall_label)

	outer.add_child(HSeparator.new())

	for category_label in vci["categories"].keys():
		var category = vci["categories"][category_label]
		var cat_label = Label.new()
		cat_label.text = "%s -- %.0f" % [category_label, category["score"]]
		cat_label.add_theme_font_size_override("font_size", 12)
		cat_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		cat_label.custom_minimum_size = Vector2(330, 0)
		cat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outer.add_child(cat_label)

		for measure in category["sub_measures"]:
			var m_label = Label.new()
			var suffix = "" if measure["tracked"] else "  (baseline -- not yet tracked)"
			m_label.text = "   - %s: %.0f%s" % [measure["label"], measure["score"], suffix]
			m_label.add_theme_font_size_override("font_size", 10)
			var tracked_color = Color(0.75, 0.85, 0.95) if measure["tracked"] else Color(0.5, 0.53, 0.58)
			m_label.add_theme_color_override("font_color", tracked_color)
			# autowrap alone does nothing without an explicit width to wrap
			# within -- a Label's minimum size is otherwise however wide its
			# unwrapped text is, which pushed this panel past the window
			# edge before this was added (same fix _build_level_card's
			# objective label already needed).
			m_label.custom_minimum_size = Vector2(330, 0)
			m_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			outer.add_child(m_label)

func _build_commons_panel(column: VBoxContainer, state: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "GlassPanelFrame"
	column.add_child(panel)

	var bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.35), 1.0)
	panel.add_child(bg)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 4)
	panel.add_child(outer)

	var resources_header = Label.new()
	resources_header.text = "COMMONS (raw banked resources)"
	resources_header.add_theme_font_size_override("font_size", 12)
	resources_header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(resources_header)

	# One bullet per resource, not one big comma-joined/wrapped paragraph --
	# far easier to scan at a glance. Resources vci_tracker.gd already has
	# a TARGETS entry for (the ones actually consumed somewhere -- Food/
	# Potable Water/O2/Steel/etc.) double as a color-changing health meter,
	# same band colors _supply_health_color() already uses for the
	# Critical Supply Chain section below, so the whole panel reads with
	# one consistent color language. Resources with no target yet (Nickel,
	# Regolith, UHPC Concrete, Shield Plating) stay a neutral color rather
	# than implying a health reading that doesn't exist.
	#
	# Used to be height-capped with a ScrollContainer here since one bullet
	# per line ran this panel into the Account panel docked below it -- the
	# user wants every bulleted resource visible without scrolling, and
	# account_panel.gd no longer carries the tall Skins/Badges content that
	# caused the overlap, so there's room to let this grow to its full
	# height uncapped now.
	var resources_vbox = VBoxContainer.new()
	resources_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(resources_vbox)

	var resources = state["resources"]
	var keys = resources.keys()
	keys.sort()
	for key in keys:
		var row = Label.new()
		var amount = float(resources[key])
		row.text = "•  %s: %.1f" % [key, amount]
		row.add_theme_font_size_override("font_size", 11)
		row.custom_minimum_size = Vector2(330, 0)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if VCITracker.TARGETS.has(key):
			var pct = clamp(amount / float(VCITracker.TARGETS[key]) * 100.0, 0.0, 100.0)
			row.add_theme_color_override("font_color", _supply_health_color(pct))
		else:
			row.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
		resources_vbox.add_child(row)
	if resources.is_empty():
		var empty_label = Label.new()
		empty_label.text = "(nothing banked yet)"
		empty_label.add_theme_font_size_override("font_size", 11)
		resources_vbox.add_child(empty_label)

	outer.add_child(HSeparator.new())

	# Health meter for the two raw feedstocks everything else in the
	# commons is refined from (see vci_tracker.gd's critical_supply_health()
	# note on why H2O and PGM specifically) -- same color language as VCI's
	# bands above, so a glance at either panel reads the same way, but this
	# isn't an actual VCI sub-measure: it's a display-only early-warning
	# meter on the two inputs, not the downstream products VCI scores.
	var supply_header = Label.new()
	supply_header.text = "CRITICAL SUPPLY CHAIN"
	supply_header.add_theme_font_size_override("font_size", 12)
	supply_header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(supply_header)

	for entry in VCITracker.critical_supply_health(state["resources"]):
		var row = Label.new()
		row.text = "%s: %.0f / %.0f -- %s" % [
			entry["resource"], entry["banked"], entry["target"], _supply_band_name(entry["pct"])]
		row.add_theme_font_size_override("font_size", 11)
		row.add_theme_color_override("font_color", _supply_health_color(entry["pct"]))
		row.custom_minimum_size = Vector2(330, 0)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outer.add_child(row)

## Mirrors VitalContinuityBand's own thresholds (cur_capture_index.h:
## 0-19 Critical, 20-39 High Risk, 40-59 Elevated, 60-79 Observation,
## 80-100 Stable) and _band_color()'s colors for them, without spinning up
## a CURComplianceMonitor for what's ultimately just a percentage-of-target
## display convention.
func _supply_band_name(pct: float) -> String:
	if pct >= 80.0:
		return "Stable"
	elif pct >= 60.0:
		return "Observation"
	elif pct >= 40.0:
		return "Elevated"
	elif pct >= 20.0:
		return "High Risk"
	else:
		return "Critical"

func _supply_health_color(pct: float) -> Color:
	if pct >= 80.0:
		return Color(0.45, 0.85, 0.55)
	elif pct >= 60.0:
		return Color(0.6, 0.8, 0.95)
	elif pct >= 40.0:
		return Color(0.95, 0.75, 0.35)
	elif pct >= 20.0:
		return Color(0.95, 0.55, 0.3)
	else:
		return Color(0.95, 0.35, 0.35)

## Feeds real banked-resource state (via vci_tracker.gd's mapping) into
## the VCI binding added to CURComplianceMonitor. The monitor here is a
## throwaway, scene-tree-free instance -- update_vital_continuity() only
## touches the C++ machine object, not anything that needs to be in the
## tree (unlike the per-level monitors in governance_level.gd/
## advocate_level.gd, which also load configured regulations on _ready()
## -- this one has none to load).
func _compute_vci(state: Dictionary) -> Dictionary:
	var computed = VCITracker.compute(state)
	var monitor = CURComplianceMonitor.new()
	var handle = monitor.register_entity("commonwealth-vci", monitor.EC_CIVIC, monitor.SUBJ_INFRASTRUCTURE, "Aevoria Commonwealth")
	var score = monitor.update_vital_continuity(handle, computed["inputs"], int(Time.get_unix_time_from_system()))
	var band = monitor.get_vital_continuity_band()
	var band_name = monitor.vital_continuity_band_name(band)
	var result = {
		"score": score,
		"band_name": band_name,
		"band_color": _band_color(band),
		"categories": computed["categories"],
	}
	monitor.free()
	return result

func _band_color(band: int) -> Color:
	match band:
		CURComplianceMonitor.VCB_STABLE:
			return Color(0.45, 0.85, 0.55)
		CURComplianceMonitor.VCB_OBSERVATION:
			return Color(0.6, 0.8, 0.95)
		CURComplianceMonitor.VCB_ELEVATED:
			return Color(0.95, 0.75, 0.35)
		CURComplianceMonitor.VCB_HIGH_RISK:
			return Color(0.95, 0.55, 0.3)
		_:
			return Color(0.95, 0.35, 0.35)

