extends Node

## The shared HUD every level now has alongside Level Select: VCI +
## Commons top-right (vci_commons_panel.gd), the account panel with Exit
## Game bottom-right (account_panel.gd), the system log bottom-left
## (console_log_panel.gd), and the cycle/population readout top-center
## (cycle_status_panel.gd). A level's own UI only has to build its
## top-left panel -- one `add_child(LevelChrome.new())` in _ready() gets
## the rest.
##
## Level Select doesn't use this: it already wires AccountHud and
## ConsoleLogPanel itself (LevelSelect.tscn / level_select.gd's _ready())
## and uses VCICommonsPanel/CycleStatusPanel directly rather than through
## here, since it also owns HeroBackdrop and the Founders Monument that
## don't belong on every level. Everything else -- Assembly Bay, the
## production bays, the Hangar Deck, the Situation Table, the Situation
## View, every governance/CUR level, Boardroom Capture, The Long Drift --
## adds this instead of duplicating four panels' worth of setup per scene.
##
## Reads LevelContext.current_faction_id for the VCI/Commons/Cycle panels,
## which is correct for every level reached the normal way (Level
## Select's Launch/Enter buttons call LevelContext.start_level() first).
## Falls back to the Commonwealth if a scene is opened directly (editor
## "Run Current Scene", or a headless smoke test) and current_faction_id
## is still "".

const AccountPanel = preload("res://scripts/account_panel.gd")
const ConsoleLogPanel = preload("res://scripts/console_log_panel.gd")
const VCICommonsPanel = preload("res://scripts/vci_commons_panel.gd")
const CycleStatusPanel = preload("res://scripts/cycle_status_panel.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

func _ready() -> void:
	var faction_id = LevelContext.current_faction_id
	if faction_id == "":
		faction_id = LevelCatalog.AEVORIA_COMMONWEALTH
	add_child(AccountPanel.new())
	add_child(ConsoleLogPanel.new())
	add_child(VCICommonsPanel.new(faction_id))
	add_child(CycleStatusPanel.new(faction_id))
