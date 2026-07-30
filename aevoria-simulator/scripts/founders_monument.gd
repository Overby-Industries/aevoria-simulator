extends CanvasLayer

## The Founders Monument -- a plaque listing everyone who's bought the
## "Founding Citizen" Commemorative Bundle, fulfilling that pack's "your
## name etched into the Founders Monument loading screen" promise (see
## web/scripts/create-tier1-products.mjs). Shown automatically the moment
## the game's front door (LevelSelect) loads, dismissible, and reopenable
## any time via the "Admire the Founders Monument" button level_select.gd
## adds to the hub.
##
## FOUNDERS_API_URL always points at production -- unlike aevoria_auth.gd,
## this doesn't split by debug/dev build. The founder list is a low-stakes
## display feature, not something that needs an isolated test dataset, and
## the dev-branch equivalent URL sits behind Vercel's Deployment Protection
## bypass secret, not worth wiring through for this.

const FOUNDERS_API_URL = "https://www.aevoria.space/api/founders"

const GlassPanel = preload("res://scripts/glass_panel.gd")

var _panel: PanelContainer
var _names_vbox: VBoxContainer
var _status_label: Label
var _fetch_request: HTTPRequest

func _ready():
	layer = 10  # above LevelSelect's own panels
	_build_ui()
	_fetch_request = HTTPRequest.new()
	add_child(_fetch_request)
	_fetch_request.request_completed.connect(_on_fetch_completed)
	_fetch_founders()

func show_monument():
	visible = true
	_fetch_founders()

func _fetch_founders():
	_status_label.text = "Loading..."
	var err = _fetch_request.request(FOUNDERS_API_URL)
	if err != OK:
		_status_label.text = "Could not load the Founders Monument right now."

func _on_fetch_completed(_result, response_code, _headers, body):
	if response_code != 200:
		_status_label.text = "Could not load the Founders Monument right now."
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary) or not (data.get("founders") is Array):
		_status_label.text = "Could not load the Founders Monument right now."
		return

	for child in _names_vbox.get_children():
		child.queue_free()

	var founders: Array = data["founders"]
	if founders.is_empty():
		_status_label.text = "Be the first Founding Citizen -- see the Heritage Fleet Store."
		return

	_status_label.text = ""
	for founder_name in founders:
		var label = Label.new()
		label.text = "- %s" % founder_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_names_vbox.add_child(label)

func _build_ui():
	var scrim = ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.6)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)

	_panel = PanelContainer.new()
	_panel.theme = ThemeBootstrap.theme
	_panel.custom_minimum_size = Vector2(420, 0)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.LayoutPresetMode.PRESET_MODE_MINSIZE)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.theme_type_variation = "GlassPanelFrame"
	add_child(_panel)

	var glass = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.75), 1.0)
	_panel.add_child(glass)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	_panel.add_child(outer)

	var header = Label.new()
	header.text = "FOUNDERS MONUMENT"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	outer.add_child(header)

	var subtitle = Label.new()
	subtitle.text = "In recognition of the Founding Citizens of the Aevoria Commonwealth."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	outer.add_child(subtitle)

	outer.add_child(HSeparator.new())

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 11)
	outer.add_child(_status_label)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_names_vbox = VBoxContainer.new()
	_names_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_names_vbox)

	var close_button = Button.new()
	close_button.text = "Close"
	close_button.theme_type_variation = "GlassButton"
	close_button.pressed.connect(func(): visible = false)
	outer.add_child(close_button)
