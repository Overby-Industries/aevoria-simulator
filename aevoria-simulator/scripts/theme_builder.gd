extends RefCounted

## Builds the unified UI theme shared across the simulator: Overby
## Industries' dark tech console (the default -- hardware, mining,
## ship/habitat assembly) and an "AevoriaPanel"/"AevoriaButton" variation
## (clean flat civil slate -- Commonwealth governance/compliance data),
## plus a "GlassResourceSlab" variation for resource call-outs. Panels
## opt into the light variation with theme_type_variation; everything
## else gets the dark console look automatically via the root Theme.
##
## No class_name, following part_catalog.gd's convention -- avoids the
## editor class_name cache in headless runs.

const COLOR_OVERBY_BG     = Color("0a0c10")
const COLOR_OVERBY_PANEL  = Color("12161f")
const COLOR_OVERBY_BORDER = Color("232936")
const COLOR_AEVORIA_BG    = Color("f4f6f9")
const COLOR_AEVORIA_PANEL = Color("ffffff")
const COLOR_TEXT_DARK     = Color("1a1f26")
const COLOR_TEXT_LIGHT    = Color("e2e8f0")
const COLOR_ACCENT_AMBER  = Color("ff9f1c")
const COLOR_ACCENT_TEAL   = Color("2ec4b6")
const COLOR_BORDER_GLASS  = Color(1, 1, 1, 0.15)

static func build() -> Theme:
	var theme = Theme.new()
	theme.set_default_font_size(14)

	_build_overby_console(theme)
	_build_aevoria_civil(theme)
	_build_glass_resource_slab(theme)
	_build_glass_panel_frame(theme)
	_build_glass_button(theme)

	return theme

static func _build_overby_console(theme: Theme) -> void:
	var panel = StyleBoxFlat.new()
	panel.bg_color = COLOR_OVERBY_PANEL
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_color = COLOR_OVERBY_BORDER
	panel.set_corner_radius_all(2)
	panel.set_content_margin_all(10)
	theme.set_stylebox("panel", "PanelContainer", panel)

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = COLOR_OVERBY_BG
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = COLOR_OVERBY_BORDER
	btn_normal.set_content_margin_all(8)
	var btn_hover = btn_normal.duplicate()
	btn_hover.border_color = COLOR_ACCENT_AMBER
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = COLOR_OVERBY_PANEL
	btn_pressed.border_color = COLOR_ACCENT_TEAL
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_color("font_color", "Button", COLOR_TEXT_LIGHT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", COLOR_ACCENT_TEAL)

	theme.set_color("font_color", "Label", COLOR_TEXT_LIGHT)

	var line_edit = StyleBoxFlat.new()
	line_edit.bg_color = COLOR_OVERBY_BG
	line_edit.border_width_bottom = 1
	line_edit.border_color = COLOR_OVERBY_BORDER
	line_edit.set_content_margin_all(6)
	var line_edit_focus = line_edit.duplicate()
	line_edit_focus.border_color = COLOR_ACCENT_TEAL
	theme.set_stylebox("normal", "LineEdit", line_edit)
	theme.set_stylebox("focus", "LineEdit", line_edit_focus)
	theme.set_color("font_color", "LineEdit", COLOR_TEXT_LIGHT)
	theme.set_color("font_placeholder_color", "LineEdit", Color(0.6, 0.65, 0.72))

static func _build_aevoria_civil(theme: Theme) -> void:
	var panel = StyleBoxFlat.new()
	panel.bg_color = COLOR_AEVORIA_PANEL
	panel.shadow_color = Color(0, 0, 0, 0.08)
	panel.shadow_size = 8
	panel.shadow_offset = Vector2(0, 4)
	panel.set_corner_radius_all(6)
	panel.set_content_margin_all(12)
	theme.set_type_variation("AevoriaPanel", "PanelContainer")
	theme.set_stylebox("panel", "AevoriaPanel", panel)
	theme.set_color("font_color", "AevoriaPanel", COLOR_TEXT_DARK)

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = COLOR_AEVORIA_BG
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = Color("d8dce3")
	btn_normal.set_corner_radius_all(4)
	btn_normal.set_content_margin_all(8)
	var btn_hover = btn_normal.duplicate()
	btn_hover.border_color = COLOR_ACCENT_TEAL
	theme.set_type_variation("AevoriaButton", "Button")
	theme.set_stylebox("normal", "AevoriaButton", btn_normal)
	theme.set_stylebox("hover", "AevoriaButton", btn_hover)
	theme.set_color("font_color", "AevoriaButton", COLOR_TEXT_DARK)
	theme.set_color("font_hover_color", "AevoriaButton", COLOR_TEXT_DARK)

static func _build_glass_resource_slab(theme: Theme) -> void:
	var slab = StyleBoxFlat.new()
	slab.bg_color = Color(1, 1, 1, 0.03)
	slab.border_width_left = 1
	slab.border_width_top = 1
	slab.border_width_right = 1
	slab.border_width_bottom = 1
	slab.border_color = COLOR_BORDER_GLASS
	slab.set_corner_radius_all(4)
	slab.set_content_margin_all(10)
	theme.set_type_variation("GlassResourceSlab", "PanelContainer")
	theme.set_stylebox("panel", "GlassResourceSlab", slab)

## The frame for panels whose real background is glass_panel.gd's frosted
## shader (which blurs whatever 3D scene is behind it -- see
## hero_backdrop.gd) rather than a flat theme color. bg_color is fully
## transparent here on purpose: painting any opaque color first would
## defeat the shader's screen-texture read. Only a thin amber outline
## remains, so the panel still reads as a distinct card.
static func _build_glass_panel_frame(theme: Theme) -> void:
	var frame = StyleBoxFlat.new()
	frame.bg_color = Color(0, 0, 0, 0)
	frame.border_width_left = 1
	frame.border_width_top = 1
	frame.border_width_right = 1
	frame.border_width_bottom = 1
	frame.border_color = Color(COLOR_ACCENT_AMBER.r, COLOR_ACCENT_AMBER.g, COLOR_ACCENT_AMBER.b, 0.4)
	frame.set_corner_radius_all(6)
	frame.set_content_margin_all(14)
	theme.set_type_variation("GlassPanelFrame", "PanelContainer")
	theme.set_stylebox("panel", "GlassPanelFrame", frame)
	theme.set_color("font_color", "GlassPanelFrame", COLOR_TEXT_LIGHT)

## The amber-glass button look requested to match the web app's sci-fi
## feel: a near-transparent amber wash instead of a flat panel color, so
## the frosted scene behind still reads through, with amber text instead
## of white/light-gray.
static func _build_glass_button(theme: Theme) -> void:
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(COLOR_ACCENT_AMBER.r, COLOR_ACCENT_AMBER.g, COLOR_ACCENT_AMBER.b, 0.08)
	btn_normal.border_width_left = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_right = 1
	btn_normal.border_width_bottom = 1
	btn_normal.border_color = Color(COLOR_ACCENT_AMBER.r, COLOR_ACCENT_AMBER.g, COLOR_ACCENT_AMBER.b, 0.5)
	btn_normal.set_corner_radius_all(4)
	btn_normal.set_content_margin_all(8)
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(COLOR_ACCENT_AMBER.r, COLOR_ACCENT_AMBER.g, COLOR_ACCENT_AMBER.b, 0.18)
	btn_hover.border_color = COLOR_ACCENT_AMBER
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = Color(COLOR_ACCENT_AMBER.r, COLOR_ACCENT_AMBER.g, COLOR_ACCENT_AMBER.b, 0.28)
	btn_pressed.border_color = COLOR_ACCENT_AMBER
	theme.set_type_variation("GlassButton", "Button")
	theme.set_stylebox("normal", "GlassButton", btn_normal)
	theme.set_stylebox("hover", "GlassButton", btn_hover)
	theme.set_stylebox("pressed", "GlassButton", btn_pressed)
	theme.set_color("font_color", "GlassButton", COLOR_ACCENT_AMBER)
	theme.set_color("font_hover_color", "GlassButton", Color.WHITE)
	theme.set_color("font_pressed_color", "GlassButton", COLOR_ACCENT_AMBER)
