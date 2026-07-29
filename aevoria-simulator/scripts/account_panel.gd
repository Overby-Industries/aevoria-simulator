extends CanvasLayer

## Logs the player into the same Commonwealth account they use on the web
## marketplace (via the AevoriaAuth autoload) and shows what they own --
## closing the loop between buying a skin on the web and actually having
## it here. Built in code, matching cur_fsm_display.gd's pattern. Docked to
## the bottom-right of the screen; the game's Exit button lives here too.

const GlassPanel = preload("res://scripts/glass_panel.gd")

var _panel: PanelContainer
var _logged_out_box: VBoxContainer
var _logged_in_box: VBoxContainer
var _email_input: LineEdit
var _password_input: LineEdit
var _status_label: Label
var _account_label: Label
var _skins_vbox: VBoxContainer

func _ready():
	_build_ui()

	AevoriaAuth.login_succeeded.connect(_on_login_succeeded)
	AevoriaAuth.login_failed.connect(_on_login_failed)
	AevoriaAuth.logged_out.connect(_refresh_state)
	AevoriaAuth.skins_fetched.connect(_on_skins_fetched)
	AevoriaAuth.skins_fetch_failed.connect(_on_skins_fetch_failed)

	_refresh_state()

func _build_ui():
	_panel = PanelContainer.new()
	_panel.theme = ThemeBootstrap.theme
	_panel.custom_minimum_size = Vector2(280, 0)
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# Docked bottom-right -- computed from the viewport rather than a fixed
	# literal since this panel's height grows with the skins list.
	var viewport_size = get_viewport().get_visible_rect().size
	_panel.position = Vector2(viewport_size.x - 300, viewport_size.y - 340)
	add_child(_panel)

	var bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.45))
	_panel.add_child(bg)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	_panel.add_child(outer)

	var header = Label.new()
	header.text = "COMMONWEALTH ACCOUNT"
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.95, 0.6, 0.5))
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
	login_button.pressed.connect(_on_login_pressed)
	_logged_out_box.add_child(login_button)

	# --- logged-in state: account info + owned skins ---
	_logged_in_box = VBoxContainer.new()
	outer.add_child(_logged_in_box)

	_account_label = Label.new()
	_account_label.add_theme_font_size_override("font_size", 12)
	_logged_in_box.add_child(_account_label)

	var skins_header_row = HBoxContainer.new()
	_logged_in_box.add_child(skins_header_row)

	var skins_header = Label.new()
	skins_header.text = "MY SKINS"
	skins_header.add_theme_font_size_override("font_size", 12)
	skins_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skins_header_row.add_child(skins_header)

	var refresh_button = Button.new()
	refresh_button.text = "Refresh"
	refresh_button.add_theme_font_size_override("font_size", 10)
	refresh_button.pressed.connect(func(): AevoriaAuth.fetch_owned_skins())
	skins_header_row.add_child(refresh_button)

	var skins_scroll = ScrollContainer.new()
	skins_scroll.custom_minimum_size = Vector2(0, 100)
	_logged_in_box.add_child(skins_scroll)
	_skins_vbox = VBoxContainer.new()
	_skins_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skins_scroll.add_child(_skins_vbox)

	var logout_button = Button.new()
	logout_button.text = "Log Out"
	logout_button.pressed.connect(AevoriaAuth.logout)
	_logged_in_box.add_child(logout_button)

	# Outside both boxes so it's visible whether or not the player is
	# logged in -- exiting the game shouldn't require an account.
	outer.add_child(HSeparator.new())
	var exit_button = Button.new()
	exit_button.text = "Exit Game"
	exit_button.pressed.connect(func(): get_tree().quit())
	outer.add_child(exit_button)

func _refresh_state():
	var logged_in = AevoriaAuth.is_logged_in()
	_logged_out_box.visible = not logged_in
	_logged_in_box.visible = logged_in
	if logged_in:
		_account_label.text = "Logged in: %s" % AevoriaAuth.user_email
		AevoriaAuth.fetch_owned_skins()
	else:
		for child in _skins_vbox.get_children():
			child.queue_free()

func _on_login_pressed():
	_status_label.text = ""
	AevoriaAuth.login(_email_input.text, _password_input.text)

func _on_login_succeeded(_user_info: Dictionary):
	_status_label.text = ""
	_password_input.text = ""
	_refresh_state()

func _on_login_failed(message: String):
	_status_label.text = message

func _on_skins_fetched(purchases: Array):
	for child in _skins_vbox.get_children():
		child.queue_free()
	if purchases.is_empty():
		var empty_label = Label.new()
		empty_label.text = "(no purchases yet)"
		empty_label.add_theme_font_size_override("font_size", 11)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		_skins_vbox.add_child(empty_label)
		return
	for purchase in purchases:
		# A Tier 1 (first-party store) purchase has no skin_id, so the
		# embedded "skins" join comes back as an explicit JSON null rather
		# than a missing key -- .get()'s default only covers the latter.
		var skin = purchase.get("skins", {})
		if skin == null:
			skin = {}
		var label = Label.new()
		label.text = "- %s" % skin.get("title", "(store item)")
		label.add_theme_font_size_override("font_size", 11)
		_skins_vbox.add_child(label)

func _on_skins_fetch_failed(message: String):
	_status_label.text = message
