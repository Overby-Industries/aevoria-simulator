extends RefCounted

## Shared light/dark text-color pairs for every LevelChrome-hosted HUD
## panel (vci_commons_panel.gd, account_panel.gd, cycle_status_panel.gd,
## console_log_panel.gd). Each of those panels can render either against
## GlassPanelFrame (dark frosted glass, blurring whatever 3D scene is
## behind it) or AevoriaPanel (the opaque white card main_hangar_deck.gd's
## own panel already uses) via its own `light_theme` flag -- see
## level_chrome.gd's matching flag, which is how a level opts every panel
## it hosts into one look or the other.
##
## Centralized here instead of duplicated per panel: every panel needs the
## same header/body/muted/status-band set, and a light pastel tuned to
## read on near-black glass (e.g. Color(0.6, 0.8, 0.95)) is nowhere near
## dark enough to read on white -- that decision should only be made once,
## not drift slightly different across four files.

const GlassPanel = preload("res://scripts/glass_panel.gd")

static func panel_variation(light: bool) -> String:
	return "AevoriaPanel" if light else "GlassPanelFrame"

static func button_variation(light: bool) -> String:
	return "AevoriaButton" if light else "GlassButton"

## Adds the frosted-glass background child a GlassPanelFrame panel needs --
## a no-op under light_theme, since AevoriaPanel already paints its own
## opaque stylebox (theme_builder.gd's _build_aevoria_civil()); adding the
## blur child on top of that would just waste a draw call on nothing.
static func add_background(panel: PanelContainer, light: bool, tint: Color, inset: float = 1.0) -> void:
	if light:
		return
	panel.add_child(GlassPanel.make(tint, inset))

static func header_color(light: bool) -> Color:
	return Color("1a1f26") if light else Color(0.85, 0.92, 1.0)

static func body_color(light: bool) -> Color:
	return Color("3a4048") if light else Color(0.75, 0.85, 0.95)

static func muted_color(light: bool) -> Color:
	return Color("70757c") if light else Color(0.5, 0.53, 0.58)

## Status-band colors -- same semantic ladder VCI/supply-chain readouts
## already used (good/info/warn/high-risk/bad), just re-picked dark enough
## to hold contrast on white instead of the original glass-tuned pastels.
static func good_color(light: bool) -> Color:
	return Color("1f8a4c") if light else Color(0.45, 0.85, 0.55)

static func info_color(light: bool) -> Color:
	return Color("2563a8") if light else Color(0.6, 0.8, 0.95)

static func warn_color(light: bool) -> Color:
	return Color("b3690a") if light else Color(0.95, 0.75, 0.35)

static func high_risk_color(light: bool) -> Color:
	return Color("c0491f") if light else Color(0.95, 0.55, 0.3)

static func bad_color(light: bool) -> Color:
	return Color("c0392b") if light else Color(0.95, 0.35, 0.35)

static func badge_color(light: bool) -> Color:
	return Color("8a6d1f") if light else Color(0.95, 0.82, 0.4)

## console_log_panel.gd's terminal-green log lines -- kept green in both
## modes (that's the "reads as a console" cue), just darkened for light.
static func console_color(light: bool) -> Color:
	return Color("1f7a4a") if light else Color(0.55, 0.95, 0.75)
