extends RefCounted

## Shared frosted-glass panel background -- the translucent, blurred card
## look that matches the web app's UI more closely than a flat opaque
## PanelContainer. Originally hand-rolled once inside account_panel.gd;
## factored out here so every HUD panel (level select, account, resource
## HUD, etc.) can look consistent without duplicating the shader setup.

## `inset` pulls the shader rect in from all four edges (in pixels) so a
## caller's own PanelContainer border -- e.g. theme_builder.gd's
## GlassPanelFrame -- stays visible instead of being painted over, since
## this ColorRect is added as a child and would otherwise draw on top of
## the container's border at the same rect.
static func make(tint: Color, inset: float = 0.0) -> ColorRect:
	var bg = ColorRect.new()
	bg.color = Color(1, 1, 1, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	if inset > 0.0:
		bg.offset_left = inset
		bg.offset_top = inset
		bg.offset_right = -inset
		bg.offset_bottom = -inset
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = load("res://shaders/frosted_glass_panel.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("blur_amount", 2.0)
	mat.set_shader_parameter("tint_color", tint)
	bg.material = mat
	return bg
