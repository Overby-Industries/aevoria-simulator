extends CanvasLayer

## Logs the player into the same Commonwealth account they use on the web
## marketplace (via the AevoriaAuth autoload). Built in code, matching
## cur_fsm_display.gd's pattern. Docked to the bottom-right of the screen;
## the game's Exit button lives here too.
##
## Skins/Badges inventory used to be shown here, but it duplicated
## assembly_bay.gd's own "SKIN"/"MY CREATIONS" skin picker and badge
## label -- moved there entirely (see assembly_bay.gd's _badge_label/
## _badge_detail_label) so this panel only shows identity (email + badge)
## and the ship-name readout, not a second copy of the same inventory.

const HudPanelTheme = preload("res://scripts/hud_panel_theme.gd")

## Set before add_child() -- see level_chrome.gd's matching flag.
var light_theme: bool = false

var _panel: PanelContainer
var _logged_out_box: VBoxContainer
var _logged_in_box: VBoxContainer
var _email_input: LineEdit
var _password_input: LineEdit
var _status_label: Label
var _account_label: Label
var _account_badge_label: Label
var _ship_name_label: Label

func _ready():
	_build_ui()

	AevoriaAuth.login_succeeded.connect(_on_login_succeeded)
	AevoriaAuth.login_failed.connect(_on_login_failed)
	AevoriaAuth.logged_out.connect(_refresh_state)
	AevoriaAuth.skins_fetched.connect(_on_skins_fetched)
	AevoriaAuth.skins_fetch_failed.connect(_on_skins_fetch_failed)
	PlayerProfile.badges_updated.connect(_refresh_account_label)
	PlayerProfile.ship_name_updated.connect(_refresh_ship_name_label)

	_refresh_state()

func _build_ui():
	_panel = PanelContainer.new()
	_panel.theme = ThemeBootstrap.theme
	_panel.custom_minimum_size = Vector2(280, 0)
	# Must be in the tree before set_anchors_and_offsets_preset() is
	# called -- it computes offsets against the real parent-area size,
	# which isn't known correctly before add_child() (see
	# vci_commons_panel.gd's matching fix/comment for the bug this avoids).
	add_child(_panel)
	# A real anchor (not a one-off position computed from today's window
	# size) -- PRESET_MODE_MINSIZE keeps the panel pinned to the
	# bottom-right corner, 20px in, and Godot recomputes that on every
	# resize automatically, including toggling fullscreen.
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.LayoutPresetMode.PRESET_MODE_MINSIZE, 20)
	# The preset alone leaves grow direction at its default (END, i.e.
	# grows further right/down) -- for a bottom-right-docked panel that
	# grows the minimum-size rect off the edge of the screen instead of
	# up-and-left from the anchor. Force it explicitly.
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.theme_type_variation = HudPanelTheme.panel_variation(light_theme)

	HudPanelTheme.add_background(_panel, light_theme, Color(0.05, 0.08, 0.15, 0.35), 1.0)

	# Used to cap this panel's height with an internal scroll when it also
	# carried Ship Name / Badges & Perks / Inventory content, tall enough to
	# overlap the VCI/Commons stack anchored above it. That content moved to
	# assembly_bay.gd -- identity + ship name + logout/exit is short enough
	# now to size to its own content, so no scroll is needed here anymore.
	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	_panel.add_child(outer)

	var header = Label.new()
	header.text = "COMMONWEALTH ACCOUNT"
	header.add_theme_color_override("font_color", HudPanelTheme.header_color(light_theme))
	outer.add_child(header)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", HudPanelTheme.bad_color(light_theme))
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_status_label)

	# --- logged-out state: login form ---
	_logged_out_box = VBoxContainer.new()
	outer.add_child(_logged_out_box)

	_email_input = LineEdit.new()
	_email_input.placeholder_text = "email"
	_logged_out_box.add_child(_email_input)

	_password_input = LineEdit.new()
	_password_input.placeholder_text = "password"
	_password_input.secret = true
	_logged_out_box.add_child(_password_input)

	var login_button = Button.new()
	login_button.text = "Log In"
	login_button.theme_type_variation = HudPanelTheme.button_variation(light_theme)
	login_button.pressed.connect(_on_login_pressed)
	_logged_out_box.add_child(login_button)

	# --- logged-in state: account info + owned skins ---
	_logged_in_box = VBoxContainer.new()
	outer.add_child(_logged_in_box)

	var account_row = HBoxContainer.new()
	_logged_in_box.add_child(account_row)

	_account_label = Label.new()
	_account_label.add_theme_font_size_override("font_size", 12)
	_account_label.add_theme_color_override("font_color", HudPanelTheme.body_color(light_theme))
	account_row.add_child(_account_label)

	# Separate Label (not baked into _account_label's own text) so the
	# badge can be gold while "Logged in: <email>" stays the normal
	# color -- a single Label can't mix font colors mid-string.
	_account_badge_label = Label.new()
	_account_badge_label.add_theme_font_size_override("font_size", 12)
	_account_badge_label.add_theme_color_override("font_color", HudPanelTheme.badge_color(light_theme))
	account_row.add_child(_account_badge_label)

	# Read-only here -- the ship's actual name is set in the Assembly Bay's
	# Ship Name field (PlayerProfile.set_active_ship_name()); this just
	# reflects it so a player's personalization is visible from their
	# account panel too, on every level (level_chrome.gd), not just there.
	_ship_name_label = Label.new()
	_ship_name_label.add_theme_font_size_override("font_size", 11)
	_ship_name_label.add_theme_color_override("font_color", HudPanelTheme.body_color(light_theme))
	_logged_in_box.add_child(_ship_name_label)

	_logged_in_box.add_child(HSeparator.new())

	var logout_button = Button.new()
	logout_button.text = "Log Out"
	logout_button.theme_type_variation = HudPanelTheme.button_variation(light_theme)
	logout_button.pressed.connect(AevoriaAuth.logout)
	_logged_in_box.add_child(logout_button)

	# Outside both boxes so it's visible whether or not the player is
	# logged in -- exiting the game shouldn't require an account.
	outer.add_child(HSeparator.new())
	var exit_button = Button.new()
	exit_button.text = "Exit Game"
	exit_button.theme_type_variation = HudPanelTheme.button_variation(light_theme)
	exit_button.pressed.connect(func(): get_tree().quit())
	outer.add_child(exit_button)

func _refresh_state():
	var logged_in = AevoriaAuth.is_logged_in()
	_logged_out_box.visible = not logged_in
	_logged_in_box.visible = logged_in
	if logged_in:
		_refresh_account_label()
		_refresh_ship_name_label()
		# Still fetched here (not just in assembly_bay.gd) so the badge
		# next to the player's email is correct on every level, not only
		# after a visit to the Assembly Bay.
		AevoriaAuth.fetch_owned_skins()

func _refresh_account_label():
	if not AevoriaAuth.is_logged_in():
		return
	_account_label.text = "Logged in: %s" % AevoriaAuth.user_email
	_account_badge_label.text = PlayerProfile.badge_suffix()

func _refresh_ship_name_label():
	_ship_name_label.text = "Ship: %s" % PlayerProfile.active_ship_name

func _on_login_pressed():
	_status_label.text = ""
	AevoriaAuth.login(_email_input.text, _password_input.text)

func _on_login_succeeded(_user_info: Dictionary):
	_status_label.text = ""
	_password_input.text = ""
	_refresh_state()

func _on_login_failed(message: String):
	_status_label.text = message

## Skins list and the fuller badge/perk breakdown both moved to
## assembly_bay.gd (_on_skins_fetched there does the equivalent work) --
## this handler now only has to keep PlayerProfile's badge state and this
## panel's own label in sync.
func _on_skins_fetched(purchases: Array):
	PlayerProfile.update_from_purchases(purchases)
	_refresh_account_label()

func _on_skins_fetch_failed(message: String):
	_status_label.text = message
