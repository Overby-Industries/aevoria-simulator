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
const SolarSystemState = preload("res://scripts/solar_system_state.gd")

## Set before add_child() -- see founders_monument.gd's embedded_mode for
## the same pattern. Opts every panel below into the opaque white
## AevoriaPanel look (hud_panel_theme.gd) instead of the default dark
## frosted glass -- for a level whose own 3D backdrop is bright (Main
## Hangar Deck), the glass panels' light-on-dark text would otherwise
## wash out against it.
var light_theme: bool = false

## How often to recheck the real-time cycle clock while a level stays
## open, so a session left running across a day rollover still catches
## the cycle instead of waiting for the next scene load.
const CYCLE_RECHECK_SECONDS = 1800.0

func _ready() -> void:
	var faction_id = LevelContext.current_faction_id
	if faction_id == "":
		faction_id = LevelCatalog.AEVORIA_COMMONWEALTH

	_process_due_cycles(faction_id)

	var account = AccountPanel.new()
	account.light_theme = light_theme
	add_child(account)

	var console = ConsoleLogPanel.new()
	console.light_theme = light_theme
	add_child(console)

	var vci = VCICommonsPanel.new(faction_id)
	vci.light_theme = light_theme
	add_child(vci)

	var cycle = CycleStatusPanel.new(faction_id)
	cycle.light_theme = light_theme
	add_child(cycle)

	var recheck_timer = Timer.new()
	recheck_timer.wait_time = CYCLE_RECHECK_SECONDS
	recheck_timer.timeout.connect(_process_due_cycles.bind(faction_id))
	add_child(recheck_timer)
	recheck_timer.start()

## Catches the shared clock up to real wall-clock time (SolarSystemState.
## process_due_cycles()) and reports whatever happened to the system log
## and the always-on cycle readout -- the only place either of those
## happens now that there's no manual "Run Supply Cycle" button to do it
## inline.
func _process_due_cycles(faction_id: String) -> void:
	var result = SolarSystemState.process_due_cycles(faction_id)
	if int(result["cycles_run"]) <= 0:
		return
	SystemLog.log("[Solar System] %d supply cycle(s) elapsed in real time -- now at cycle %d." % [result["cycles_run"], result["cycle"]])
	for shortfall_cycle in result["shortfalls"]:
		SystemLog.log("[Solar System] WARNING: cycle %d ran short on upkeep -- resources were not enough to cover it." % shortfall_cycle)
	get_tree().call_group("cycle_status_panel", "refresh")
