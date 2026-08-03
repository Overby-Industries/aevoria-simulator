extends Node3D

## The consolidation hub the user asked for: instead of Level Select
## showing four separate top-level cards for Assembly Bay/Greenhouse Bay/
## Refinery Bay/Electrolysis Bay, it shows one -- "you've come in from
## outside the station, floating in space, into the station's main
## hangar deck" -- and this scene is what's on the other side of that
## door. One shared scene for all three factions (LevelCatalog's three
## main_hangar_deck catalog entries all point here): the sub-levels it
## routes to are already faction-agnostic (assembly_bay.gd/greenhouse_bay.gd/
## refinery_bay.gd/electrolysis_bay.gd all key off
## LevelContext.current_faction_id already), so the only thing that
## changes per faction is the header and the Assembly Bay flavor text --
## both already centralized in LevelCatalog.hangar_deck_label()/
## hangar_levels().
##
## Not a walkable 3D hangar interior -- there's no raycast/Area3D picking
## anywhere in this codebase, so hangar_backdrop.gd's dressing behind the
## fixed camera is scenery, same role hero_backdrop.gd plays on Level
## Select, not a room you actually move through. It's still a real
## intermediate location, not a cosmetic wrapper: its own faction-aware
## header and back button -- Level Select no longer has to show four
## cards to do what one door now does.

const LevelCatalog = preload("res://scripts/level_catalog.gd")
const FactionHomeBase = preload("res://scripts/faction_home_base.gd")
const LevelChrome = preload("res://scripts/level_chrome.gd")
const HangarBackdrop = preload("res://scripts/hangar_backdrop.gd")

## One per bay card, in the order LevelCatalog.hangar_levels() returns them
## (Assembly Bay, then the three production bays) -- the rainbow accent
## that replaced hangar_backdrop.gd's door banners once the hangar itself
## went back to plain white/gold (see that file's top comment).
const CARD_ACCENT_COLORS = [
	Color("e4342f"),  # Assembly Bay -- red
	Color("3aa655"),  # Greenhouse Bay -- green
	Color("2b6cb0"),  # Refinery Bay -- blue
	Color("7b4fa6"),  # Electrolysis Bay -- violet
]

@onready var camera: Camera3D = $Camera3D

func _ready():
	add_child(HangarBackdrop.new())
	# Opaque white cards read fine against a bright hangar; the shared
	# glass HUD panels don't (see level_chrome.gd's light_theme comment) --
	# this is what makes the bright backdrop below viable again.
	var chrome = LevelChrome.new()
	chrome.light_theme = true
	add_child(chrome)
	camera.make_current()
	_build_ui()

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var panel = PanelContainer.new()
	panel.theme = ThemeBootstrap.theme
	panel.theme_type_variation = "AevoriaPanel"
	panel.custom_minimum_size = Vector2(460, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	canvas.add_child(panel)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var faction_id = LevelContext.current_faction_id
	var header = Label.new()
	header.text = LevelCatalog.hangar_deck_label(faction_id).to_upper()
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color("1a1f26"))
	outer.add_child(header)

	var subheader = Label.new()
	subheader.text = "You've come in from outside, floating in space -- this is what's behind the door. Pick a bay."
	subheader.add_theme_font_size_override("font_size", 11)
	subheader.add_theme_color_override("font_color", Color("4a5460"))
	subheader.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subheader.custom_minimum_size = Vector2(430, 0)
	outer.add_child(subheader)

	outer.add_child(HSeparator.new())

	var state = FactionHomeBase.load_state(faction_id)
	var levels = LevelCatalog.hangar_levels(faction_id)
	for i in range(levels.size()):
		var accent = CARD_ACCENT_COLORS[i % CARD_ACCENT_COLORS.size()]
		outer.add_child(_build_bay_card(levels[i], faction_id, state, accent))

	outer.add_child(HSeparator.new())

	var back_button = Button.new()
	back_button.text = "Back to Level Select"
	back_button.theme_type_variation = "AevoriaButton"
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	outer.add_child(back_button)

func _build_bay_card(level: Dictionary, faction_id: String, state: Dictionary, accent_color: Color) -> PanelContainer:
	var card = PanelContainer.new()
	card.theme_type_variation = "AevoriaPanel"

	# A colored left-edge stripe per bay, duplicated off the real
	# AevoriaPanel stylebox (theme_builder.gd) rather than hand-rebuilding
	# its bg/shadow/corner-radius values here, so this card still picks up
	# any future change to that shared look automatically.
	var card_style: StyleBoxFlat = ThemeBootstrap.theme.get_stylebox("panel", "AevoriaPanel").duplicate()
	card_style.border_width_left = 5
	card_style.border_color = accent_color
	card.add_theme_stylebox_override("panel", card_style)

	var inner = VBoxContainer.new()
	card.add_child(inner)

	var complete = state["completed_levels"].has(level["id"])
	var title = Label.new()
	title.text = "%s%s" % [level["title"], "  [DONE]" if complete else ""]
	title.add_theme_color_override("font_color", Color("1a1f26"))
	inner.add_child(title)

	var objective = Label.new()
	objective.text = level["objective"]
	objective.add_theme_font_size_override("font_size", 11)
	objective.add_theme_color_override("font_color", Color("4a5460"))
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size = Vector2(420, 0)
	inner.add_child(objective)

	var launch_button = Button.new()
	launch_button.text = "Enter"
	launch_button.theme_type_variation = "AevoriaButton"
	var level_id = level["id"]
	var scene_path = level["scene_path"]
	launch_button.pressed.connect(func():
		LevelContext.start_level(level_id, faction_id)
		get_tree().change_scene_to_file(scene_path)
	)
	inner.add_child(launch_button)

	return card
