extends Node

## Registered as the ThemeBootstrap autoload. Builds the shared Theme once
## at boot.
##
## NOTE: assigning to get_tree().root.theme does NOT reach Controls nested
## under a CanvasLayer -- confirmed empirically, CanvasLayer breaks the
## ancestor walk Control theme resolution relies on -- and every panel in
## this project (CURFSMDisplay, CURViolationLog, AccountPanel, AssemblyBay,
## LevelSelect, GovernanceLevel) is built under a CanvasLayer. So there is
## no project-wide fallback here; each panel-building script explicitly
## sets its own root Control's `theme = ThemeBootstrap.theme`, and its
## children resolve normally from there.

const ThemeBuilder = preload("res://scripts/theme_builder.gd")

var theme: Theme

func _ready() -> void:
	theme = ThemeBuilder.build()
