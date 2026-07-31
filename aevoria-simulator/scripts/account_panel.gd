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
	PlayerProfile.badges_updated.connect(_refresh_account_label)

	_refresh_state()

func _build_ui():
	_panel = PanelContainer.new()
	_panel.theme = ThemeBootstrap.theme
	_panel.custom_minimum_size = Vector2(280, 0)
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
	_panel.theme_type_variation = "GlassPanelFrame"
	add_child(_panel)

	var bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.35), 1.0)
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
	login_button.theme_type_variation = "GlassButton"
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
	refresh_button.theme_type_variation = "GlassButton"
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
	logout_button.theme_type_variation = "GlassButton"
	logout_button.pressed.connect(AevoriaAuth.logout)
	_logged_in_box.add_child(logout_button)

	# Outside both boxes so it's visible whether or not the player is
	# logged in -- exiting the game shouldn't require an account.
	outer.add_child(HSeparator.new())
	var exit_button = Button.new()
	exit_button.text = "Exit Game"
	exit_button.theme_type_variation = "GlassButton"
	exit_button.pressed.connect(func(): get_tree().quit())
	outer.add_child(exit_button)

func _refresh_state():
	var logged_in = AevoriaAuth.is_logged_in()
	_logged_out_box.visible = not logged_in
	_logged_in_box.visible = logged_in
	if logged_in:
		_refresh_account_label()
		AevoriaAuth.fetch_owned_skins()
	else:
		for child in _skins_vbox.get_children():
			child.queue_free()

func _refresh_account_label():
	if not AevoriaAuth.is_logged_in():
		return
	_account_label.text = "Logged in: %s%s" % [AevoriaAuth.user_email, PlayerProfile.badge_suffix()]

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
	PlayerProfile.update_from_purchases(purchases)
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

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_skins_vbox.add_child(row)

		var thumb = TextureRect.new()
		thumb.custom_minimum_size = Vector2(20, 20)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_SCALE
		row.add_child(thumb)

		var label = Label.new()
		label.text = "- %s" % skin.get("title", "(store item)")
		label.add_theme_font_size_override("font_size", 11)
		row.add_child(label)

		# Procedural skins have no storage_path (see 0005_skin_recipes.sql
		# in web/supabase/migrations) -- preview_image_path is their only
		# image. An uploaded file skin's own storage_path is used only if
		# it's actually an image (could be a non-image 3D asset instead),
		# matching the exact same fallback the web marketplace page uses.
		var image_extensions = [".png", ".jpg", ".jpeg", ".webp"]
		var storage_path = skin.get("storage_path")
		var is_image = storage_path != null and image_extensions.any(
			func(ext): return storage_path.to_lower().ends_with(ext)
		)
		var preview_path = storage_path if is_image else skin.get("preview_image_path")
		if preview_path != null:
			_load_skin_thumbnail(thumb, preview_path)

func _on_skins_fetch_failed(message: String):
	_status_label.text = message

# The "skins" storage bucket is private (see 0001_init.sql), so a plain
# public URL won't work -- has to go through Supabase's sign endpoint
# first, same as web/app/(app)/marketplace/page.tsx does server-side.
# Each thumbnail gets its own throwaway HTTPRequest pair (sign, then
# download) since several can be in flight at once for a longer skins list.
func _load_skin_thumbnail(thumb: TextureRect, path: String) -> void:
	var sign_request = HTTPRequest.new()
	add_child(sign_request)
	var sign_url = "%s/storage/v1/object/sign/skins/%s" % [AevoriaAuth.SUPABASE_URL, path]
	var headers = [
		"apikey: %s" % AevoriaAuth.SUPABASE_ANON_KEY,
		"Authorization: Bearer %s" % AevoriaAuth.access_token,
		"Content-Type: application/json",
	]
	var body = JSON.stringify({"expiresIn": 600})
	sign_request.request_completed.connect(func(_result, response_code, _resp_headers, resp_body):
		sign_request.queue_free()
		if response_code != 200:
			return
		var data = JSON.parse_string(resp_body.get_string_from_utf8())
		if not (data is Dictionary) or not data.has("signedURL"):
			return
		_download_skin_thumbnail(thumb, "%s/storage/v1%s" % [AevoriaAuth.SUPABASE_URL, data["signedURL"]])
	)
	sign_request.request(sign_url, headers, HTTPClient.METHOD_POST, body)

func _download_skin_thumbnail(thumb: TextureRect, image_url: String) -> void:
	var image_request = HTTPRequest.new()
	add_child(image_request)
	image_request.request_completed.connect(func(_result, response_code, _resp_headers, image_bytes):
		image_request.queue_free()
		if response_code != 200:
			return
		var image = Image.new()
		# Try each format in turn -- the response has no reliable
		# extension to key off (it's a signed URL, not a file path).
		var loaded = (
			image.load_png_from_buffer(image_bytes) == OK
			or image.load_jpg_from_buffer(image_bytes) == OK
			or image.load_webp_from_buffer(image_bytes) == OK
		)
		if loaded:
			thumb.texture = ImageTexture.create_from_image(image)
	)
	image_request.request(image_url, [], HTTPClient.METHOD_GET)
