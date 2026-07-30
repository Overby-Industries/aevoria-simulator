extends Node3D

## Decorative 3D backdrop for the game's front door (LevelSelect) -- a
## slowly-rotating torus+cone silhouette plus a starfield, a near-black
## space background, and a distant "sun" with a screen-space lens-flare
## rig, echoing the web app's Three.js hero object (web/app/page.tsx).
## Purely scene dressing, no gameplay meaning. Every HUD panel in
## LevelSelect/AccountHud is built under a CanvasLayer, which always
## composites on top of 3D content in the same viewport -- so this just
## needs to exist somewhere in the tree with a `current` Camera3D. See
## glass_panel.gd/frosted_glass_panel.gdshader for the other half of
## this: the panels blur *this* scene, not a flat color.

const Starfield = preload("res://scripts/starfield.gd")

const COLOR_HULL = Color("1c2a45")
const COLOR_AMBER = Color("ff9f1c")

# Placed by hand relative to the fixed camera framing below (camera never
# moves, only the torus+cone rotate) so it reads in the upper-right of
# frame without sitting on top of the hull silhouette. If the camera ever
# starts moving, this whole rig would need to switch to a moving light
# instead of a fixed world position.
const SUN_POSITION := Vector3(2.46, 3.66, -6.94)

# Screen-space lens-flare "ghosts" -- classic technique: small glow
# sprites placed along the line from the light's projected screen
# position through the screen center, at various t (0 = on the sun,
# 1 = at screen center, >1 = past center on the opposite side).
const FLARE_SPECS = [
	{"t": 0.0, "scale": 2.6, "color": Color(1.0, 0.95, 0.8, 0.55)},
	{"t": 0.0, "scale": 1.1, "color": Color(1.0, 1.0, 0.95, 0.9)},
	{"t": 0.35, "scale": 0.22, "color": Color(1.0, 0.85, 0.5, 0.35)},
	{"t": 0.6, "scale": 0.14, "color": Color(0.6, 0.8, 1.0, 0.3)},
	{"t": 0.85, "scale": 0.3, "color": Color(1.0, 0.7, 0.4, 0.25)},
	{"t": 1.0, "scale": 0.5, "color": Color(1.0, 0.9, 0.6, 0.3)},
	{"t": 1.3, "scale": 0.12, "color": Color(0.5, 0.9, 1.0, 0.25)},
	{"t": 1.6, "scale": 0.45, "color": Color(1.0, 0.6, 0.3, 0.18)},
]

var _rotator: Node3D
var _camera: Camera3D
var _flare_sprites: Array = []
var _flare_texture: GradientTexture2D

func _ready() -> void:
	_build_environment()
	Starfield.spawn(self)
	_build_camera()
	_build_lights()
	_build_sun()
	_build_object()
	_build_lens_flare()

func _process(delta: float) -> void:
	if _rotator:
		_rotator.rotate_y(delta * 0.15)
		_rotator.rotate_x(delta * 0.04)
	_update_lens_flare()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Near-black, not pure black -- a hair of blue keeps it from reading
	# as a broken/transparent viewport.
	env.background_color = Color(0.006, 0.007, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.04, 0.045, 0.06)
	env.ambient_light_energy = 0.5
	# Glow/bloom is what makes the sun's emissive sphere actually read as
	# a glare instead of a flat bright dot -- the other "lens flare" half
	# is the hand-placed 2D ghost sprites in _build_lens_flare/_update_lens_flare.
	env.glow_enabled = true
	env.glow_intensity = 1.6
	env.glow_bloom = 0.35
	env.glow_hdr_threshold = 1.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.position = Vector3(5.0, 2.5, 12.0)
	_camera.current = true
	add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

func _build_lights() -> void:
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35.0, -25.0, 0.0)
	key_light.light_energy = 1.0
	add_child(key_light)

	# A soft amber rim light -- the one deliberate hue accent in an
	# otherwise near-monochrome scene, matching the amber sci-fi accent
	# now used on every button (see theme_builder.gd's GlassButton).
	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(-6.0, 1.5, -3.0)
	rim_light.light_color = COLOR_AMBER
	rim_light.light_energy = 4.0
	rim_light.omni_range = 22.0
	add_child(rim_light)

func _build_sun() -> void:
	var sun := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.1
	sun.mesh = sphere
	sun.position = SUN_POSITION

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.97, 0.88)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.92, 0.65)
	mat.emission_energy_multiplier = 9.0
	sun.material_override = mat
	add_child(sun)

	var sun_light := OmniLight3D.new()
	sun_light.position = SUN_POSITION
	sun_light.light_color = Color(1.0, 0.95, 0.85)
	sun_light.light_energy = 2.0
	sun_light.omni_range = 40.0
	add_child(sun_light)

func _build_object() -> void:
	_rotator = Node3D.new()
	add_child(_rotator)

	var torus := TorusMesh.new()
	torus.inner_radius = 2.6
	torus.outer_radius = 3.35
	var torus_instance := MeshInstance3D.new()
	torus_instance.mesh = torus
	torus_instance.material_override = _hull_material()
	_rotator.add_child(torus_instance)

	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 1.7
	cone.height = 3.2
	var cone_instance := MeshInstance3D.new()
	cone_instance.mesh = cone
	cone_instance.material_override = _hull_material()
	_rotator.add_child(cone_instance)

func _hull_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_HULL
	mat.metallic = 0.6
	mat.roughness = 0.35
	return mat

# --- lens flare (2D overlay, screen-space) --------------------------------

func _build_lens_flare() -> void:
	_flare_texture = _make_radial_texture()

	var flare_layer := CanvasLayer.new()
	# Below every UI panel's default layer (1) so glass panels still sit
	# on top of the flares, but CanvasLayers always draw above raw 3D
	# content regardless of layer number, so this still shows over the
	# starfield/backdrop.
	flare_layer.layer = 0
	add_child(flare_layer)

	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	for spec in FLARE_SPECS:
		var rect := TextureRect.new()
		rect.texture = _flare_texture
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.material = additive
		rect.modulate = spec["color"]
		rect.set_meta("t", spec["t"])
		rect.set_meta("flare_scale", spec["scale"])
		rect.visible = false
		flare_layer.add_child(rect)
		_flare_sprites.append(rect)

func _make_radial_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex

func _update_lens_flare() -> void:
	if _camera == null or _flare_sprites.is_empty():
		return
	if _camera.is_position_behind(SUN_POSITION):
		for sprite in _flare_sprites:
			sprite.visible = false
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var sun_screen = _camera.unproject_position(SUN_POSITION)

	# Sun projects way off-frame -- don't keep flares alive off in space.
	var margin = 120.0
	var visible_rect = Rect2(-margin, -margin, viewport_size.x + margin * 2.0, viewport_size.y + margin * 2.0)
	if not visible_rect.has_point(sun_screen):
		for sprite in _flare_sprites:
			sprite.visible = false
		return

	var center = viewport_size * 0.5
	var to_center = center - sun_screen
	for sprite in _flare_sprites:
		var t: float = sprite.get_meta("t")
		var scale: float = sprite.get_meta("flare_scale")
		var pos = sun_screen + to_center * t
		var size = 130.0 * scale
		sprite.size = Vector2(size, size)
		sprite.position = pos - Vector2(size, size) * 0.5
		sprite.visible = true
