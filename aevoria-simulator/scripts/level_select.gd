extends Node

## The game's front door: pick a level (hardware build vs governance/CUR
## walkthrough), see faction standing, or drop into the full Main.tscn
## sandbox that all the earlier demo/dev work still lives in. Login
## (account_panel.gd / AccountHud) is declared as a sibling node in
## LevelSelect.tscn so it's available from the hub too. Docked top-left;
## the resource/status readout is a separate small panel docked top-right,
## the account panel (with Exit Game) docks bottom-right, and the system
## log (console_log_panel.gd) docks bottom-left.

const LevelCatalog = preload("res://scripts/level_catalog.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const GlassPanel = preload("res://scripts/glass_panel.gd")
const FoundersMonument = preload("res://scripts/founders_monument.gd")
const HeroBackdrop = preload("res://scripts/hero_backdrop.gd")
const ConsoleLogPanel = preload("res://scripts/console_log_panel.gd")
const VCICommonsPanel = preload("res://scripts/vci_commons_panel.gd")

const FACTION_IDS = [
	LevelCatalog.AEVORIA_COMMONWEALTH,
	LevelCatalog.OLIGARCH_COMBINE,
	LevelCatalog.NOMAD_FLOTILLA,
]

var _faction_id = LevelCatalog.AEVORIA_COMMONWEALTH
var _founders_monument: CanvasLayer

func _ready() -> void:
	if LevelContext.faction_override != "":
		_faction_id = LevelContext.faction_override
	add_child(HeroBackdrop.new())
	add_child(ConsoleLogPanel.new())
	SystemLog.log("Level Select loaded.")
	_build_ui()
	# Shown automatically on the game's front door (see founders_monument.gd);
	# the "Admire" button below reopens it any time after this first look.
	_founders_monument = FoundersMonument.new()
	add_child(_founders_monument)

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "GlassPanelFrame"
	panel.custom_minimum_size = Vector2(420, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	canvas.add_child(panel)

	var panel_bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.35), 1.0)
	panel.add_child(panel_bg)

	# The level roster no longer fits a fixed-height window now that
	# there are five cards -- same off-screen-content bug that hit
	# AssemblyBay earlier, same fix: cap the panel height and scroll.
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	scroll.add_child(outer)

	var header = Label.new()
	header.text = "%s — LEVEL SELECT" % LevelCatalog.faction_label(_faction_id).to_upper()
	outer.add_child(header)

	outer.add_child(_build_faction_row())

	outer.add_child(HSeparator.new())

	# Each faction only ever sees its own levels -- the Commonwealth
	# shouldn't see Boardroom Capture any more than the Combine should
	# see The Reef's Advocate. See docs/FACTIONS.md for why the three
	# rosters are genuinely different playthroughs, not one shared list.
	var state = FactionHomeBase.load_state(_faction_id)
	for level in LevelCatalog.build_levels():
		if level["faction_id"] != _faction_id:
			continue
		outer.add_child(_build_level_card(level, state))

	outer.add_child(HSeparator.new())

	var sandbox_button = Button.new()
	sandbox_button.text = "Open Sandbox / Dev Demos"
	sandbox_button.theme_type_variation = "GlassButton"
	sandbox_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	outer.add_child(sandbox_button)

	var monument_button = Button.new()
	monument_button.text = "Admire the Founders Monument"
	monument_button.theme_type_variation = "GlassButton"
	monument_button.pressed.connect(func(): _founders_monument.show_monument())
	outer.add_child(monument_button)

	add_child(VCICommonsPanel.new(_faction_id))

## Row of buttons for switching which faction the player is browsing/
## playing as -- a real gameplay feature in every build, not just debug
## ones, since it's what makes the level roster below actually faction-
## specific (see _build_ui()'s filter). Rebuilds the whole scene on
## change (simplest way to propagate the new faction into every already-
## built panel/card) rather than trying to patch every affected label in
## place.
func _build_faction_row() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var label = Label.new()
	label.text = "FACTION:"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	row.add_child(label)

	for faction_id_option in FACTION_IDS:
		var button = Button.new()
		button.text = LevelCatalog.faction_label(faction_id_option)
		button.theme_type_variation = "GlassButton"
		button.add_theme_font_size_override("font_size", 10)
		button.disabled = faction_id_option == _faction_id
		var faction_id = faction_id_option
		button.pressed.connect(func():
			LevelContext.faction_override = faction_id
			SystemLog.log("Switched faction to %s." % LevelCatalog.faction_label(faction_id))
			get_tree().reload_current_scene()
		)
		row.add_child(button)

	return row

func _build_level_card(level: Dictionary, state: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.theme_type_variation = "GlassPanelFrame"
	var card_bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.3), 1.0)
	card.add_child(card_bg)

	var inner = VBoxContainer.new()
	card.add_child(inner)

	var complete = state["completed_levels"].has(level["id"])
	var title = Label.new()
	title.text = "%s%s" % [level["title"], "  [DONE]" if complete else ""]
	inner.add_child(title)

	var objective = Label.new()
	objective.text = level["objective"]
	objective.add_theme_font_size_override("font_size", 11)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size = Vector2(380, 0)
	inner.add_child(objective)

	var launch_button = Button.new()
	launch_button.text = "Launch"
	launch_button.theme_type_variation = "GlassButton"
	var level_id = level["id"]
	# _build_ui() already filters cards to level["faction_id"] == _faction_id,
	# so this is never a mismatch -- using _faction_id directly (rather than
	# level["faction_id"]) keeps the faction switcher the single source of
	# truth for who's playing.
	var faction_id = _faction_id
	var scene_path = level["scene_path"]
	launch_button.pressed.connect(func():
		LevelContext.start_level(level_id, faction_id)
		get_tree().change_scene_to_file(scene_path)
	)
	inner.add_child(launch_button)

	return card
