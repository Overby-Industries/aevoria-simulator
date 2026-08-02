extends Node3D

## Decorative 3D backdrop for Main Hangar Deck -- the interior counterpart
## to hero_backdrop.gd's exterior space dressing. Main Hangar Deck used to
## be "deliberately just a UI hub" (see main_hangar_deck.gd's old doc
## comment) with nothing behind its cards but Godot's default clear color.
## This fills that documented gap: a real interior hangar bay -- floor,
## back wall, entrance archway, ceiling truss, pillars -- built the same
## way as every other prop in this codebase (docs/GRAPHICS_GUIDE.md
## System 2, SimpleShapes, pure GDScript primitives, no imported models,
## never needs a rebuild). Purely scene dressing, no gameplay meaning,
## same as hero_backdrop.gd.
##
## Bright white/gold, matching the reference photo this scene is modeled
## on -- this only works because main_hangar_deck.gd renders its shared
## HUD panels (level_chrome.gd) with light_theme = true (opaque white
## AevoriaPanel cards, see hud_panel_theme.gd). Those panels used to be
## dark frosted glass tuned for near-black space backdrops, which this
## bright a scene would have washed out to near-illegible -- see
## level_chrome.gd's light_theme comment for the fix. Color now lives in
## the UI instead of the room: main_hangar_deck.gd tints each bay card's
## left edge a different rainbow color rather than this file painting
## rainbow banners into the 3D scene.
##
## Camera framing: MainHangarDeck.tscn's own fixed Camera3D sits at
## (0, 5, 14) pitched down ~32.5 degrees toward the origin -- every
## position below is hand-placed against that specific view, the same
## "camera never moves, geometry is placed to fit it" approach
## hero_backdrop.gd uses for SUN_POSITION.

const SimpleShapes = preload("res://scripts/simple_shapes.gd")

const FLOOR_COLOR = Color("d7d9dc")
const WALL_COLOR = Color("eceef1")
const ACCENT_GOLD = Color("c9a24b")

const HANGAR_HALF_WIDTH := 9.0
const HANGAR_DEPTH_NEAR := 16.0   # toward the camera
const HANGAR_DEPTH_FAR := -18.0   # the back wall
const CEILING_HEIGHT := 9.0

func _ready() -> void:
	_build_environment()
	_build_lights()
	_build_floor()
	_build_back_wall()
	_build_pillars()
	_build_ceiling()
	_build_props()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.66, 0.69, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.9, 0.94)
	env.ambient_light_energy = 1.0
	# Modest bloom -- enough for the LED ceiling strips and gold trim to
	# read as genuinely glowing without a bright white wall blowing out.
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 1.05
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _gold_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ACCENT_GOLD
	mat.metallic = 0.75
	mat.roughness = 0.25
	mat.emission_enabled = true
	mat.emission = ACCENT_GOLD
	mat.emission_energy_multiplier = 0.4
	return mat

func _build_lights() -> void:
	# MainHangarDeck.tscn already has its own DirectionalLight3D (0.5
	# energy, tuned for the old empty scene) -- left alone. These are
	# purely additive: a highlight on the signage, and a couple of soft
	# fills so the new geometry doesn't read as flat.
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, CEILING_HEIGHT - 0.5, 6.0)
	add_child(spot)
	spot.look_at(Vector3(0, CEILING_HEIGHT - 2.2, HANGAR_DEPTH_FAR), Vector3.UP)
	spot.spot_range = 30.0
	spot.spot_angle = 28.0
	spot.light_energy = 3.2
	spot.light_color = Color(1.0, 0.97, 0.9)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 5.0, 2.0)
	fill.light_color = Color(0.95, 0.96, 1.0)
	fill.light_energy = 0.7
	fill.omni_range = 24.0
	add_child(fill)

func _build_floor() -> void:
	var floor_mesh = SimpleShapes.make_mesh_instance({
		"shape": "box",
		"size": Vector3(HANGAR_HALF_WIDTH * 2.0, 0.2, HANGAR_DEPTH_NEAR - HANGAR_DEPTH_FAR),
		"albedo_color": FLOOR_COLOR,
	})
	floor_mesh.position = Vector3(0, -0.1, (HANGAR_DEPTH_NEAR + HANGAR_DEPTH_FAR) * 0.5)
	add_child(floor_mesh)

	# Aisle guide stripes, gold, running the depth of the bay -- the
	# reference photo's floor tram-lines leading the eye to the archway.
	for x_offset in [-2.6, 2.6]:
		var stripe = SimpleShapes.make_mesh_instance({
			"shape": "box",
			"size": Vector3(0.15, 0.01, HANGAR_DEPTH_NEAR - HANGAR_DEPTH_FAR - 4.0),
			"albedo_color": ACCENT_GOLD,
			"emission_color": ACCENT_GOLD, "emission_energy": 0.6,
		})
		stripe.position = Vector3(x_offset, 0.005, (HANGAR_DEPTH_NEAR + HANGAR_DEPTH_FAR) * 0.5)
		add_child(stripe)

	# Circular floor emblem -- TorusMesh already lies flat (hole axis is Y
	# by default), so no rotation needed to read as an inlay underfoot.
	var emblem = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": 2.2, "height": 0.02,
		"albedo_color": Color("c7c9cd"),
	})
	emblem.position = Vector3(0, 0.006, 2.0)
	add_child(emblem)

	var emblem_ring := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 2.05
	ring.outer_radius = 2.2
	emblem_ring.mesh = ring
	emblem_ring.position = Vector3(0, 0.02, 2.0)
	emblem_ring.material_override = _gold_material()
	add_child(emblem_ring)

func _build_back_wall() -> void:
	var wall = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(HANGAR_HALF_WIDTH * 2.0, CEILING_HEIGHT, 0.4),
		"albedo_color": WALL_COLOR,
	})
	wall.position = Vector3(0, CEILING_HEIGHT * 0.5 - 0.1, HANGAR_DEPTH_FAR)
	add_child(wall)

	# The dark recessed entrance -- what "ASSEMBLY BAY" sits above, echoing
	# the reference photo's central doorway.
	var archway = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(4.4, 4.2, 0.1),
		"albedo_color": Color("14161a"),
	})
	archway.position = Vector3(0, 2.0, HANGAR_DEPTH_FAR + 0.25)
	add_child(archway)

	var archway_glow = SimpleShapes.make_point_light(Color("7d8492"), 0.6, 7.0)
	archway_glow.position = Vector3(0, 2.0, HANGAR_DEPTH_FAR + 2.0)
	add_child(archway_glow)

	# No "OVERBY INDUSTRIES" wordmark centered high on this wall, even
	# though the reference photo has one there. Tried it twice now -- once
	# assuming a dark-glass panel there would just blend/garble it (wrong:
	# it read as broken overlapping text), then again assuming going
	# opaque fixed that (wrong in a different way: cycle_status_panel.gd's
	# HUD panel docks flush against the top of the screen on every level,
	# this one included, with essentially no gap above it, so the wordmark
	# just sits almost entirely hidden behind an opaque card instead of
	# garbled behind a translucent one -- still not legible either way).
	# There's no world-space spot at this X that isn't under that panel.
	# The floor's gold ring emblem below and "ASSEMBLY BAY" carry the
	# branding instead.
	var bay_label := Label3D.new()
	bay_label.text = "ASSEMBLY BAY"
	bay_label.font_size = 40
	bay_label.pixel_size = 0.011
	bay_label.modulate = ACCENT_GOLD
	bay_label.position = Vector3(0, 4.5, HANGAR_DEPTH_FAR + 0.3)
	add_child(bay_label)

func _build_pillars() -> void:
	for z_position in [10.0, -2.0, -14.0]:
		for x_sign in [-1.0, 1.0]:
			var pillar = SimpleShapes.make_mesh_instance({
				"shape": "box", "size": Vector3(0.8, CEILING_HEIGHT, 0.8),
				"albedo_color": WALL_COLOR,
			})
			pillar.position = Vector3(x_sign * (HANGAR_HALF_WIDTH - 0.6), CEILING_HEIGHT * 0.5 - 0.1, z_position)
			add_child(pillar)

			var trim = SimpleShapes.make_mesh_instance({
				"shape": "box", "size": Vector3(0.85, 0.12, 0.85),
				"albedo_color": ACCENT_GOLD,
				"emission_color": ACCENT_GOLD, "emission_energy": 0.5,
			})
			trim.position = Vector3(x_sign * (HANGAR_HALF_WIDTH - 0.6), 3.4, z_position)
			add_child(trim)

func _build_ceiling() -> void:
	var ceiling = SimpleShapes.make_mesh_instance({
		"shape": "box",
		"size": Vector3(HANGAR_HALF_WIDTH * 2.0, 0.3, HANGAR_DEPTH_NEAR - HANGAR_DEPTH_FAR),
		"albedo_color": Color("aeb1b6"),
	})
	ceiling.position = Vector3(0, CEILING_HEIGHT, (HANGAR_DEPTH_NEAR + HANGAR_DEPTH_FAR) * 0.5)
	add_child(ceiling)

	for z_position in [8.0, 0.0, -8.0, -16.0]:
		var truss = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(HANGAR_HALF_WIDTH * 2.0 - 1.0, 0.35, 0.35),
			"albedo_color": Color("55585e"),
		})
		truss.position = Vector3(0, CEILING_HEIGHT - 0.35, z_position)
		add_child(truss)

		var strip = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(HANGAR_HALF_WIDTH * 1.2, 0.06, 0.2),
			"albedo_color": Color("f5f8ff"),
			"emission_color": Color("eaf2ff"), "emission_energy": 2.0,
		})
		strip.position = Vector3(0, CEILING_HEIGHT - 0.5, z_position)
		add_child(strip)

		var strip_light = SimpleShapes.make_point_light(Color("eaf2ff"), 0.7, 9.0)
		strip_light.position = Vector3(0, CEILING_HEIGHT - 1.0, z_position)
		add_child(strip_light)

## A handful of crates near the pillar bases -- the docs/GRAPHICS_GUIDE.md
## "add a prop" worked example, applied a few times for detail.
func _build_props() -> void:
	var crate_specs = [
		{"pos": Vector3(-6.6, 0.35, 9.0), "size": Vector3(0.9, 0.9, 0.9), "color": Color("8a8f96")},
		{"pos": Vector3(-6.9, 0.3, 10.2), "size": Vector3(0.7, 0.6, 0.7), "color": Color("c9a24b")},
		{"pos": Vector3(6.6, 0.35, 9.0), "size": Vector3(0.9, 0.9, 0.9), "color": Color("8a8f96")},
		{"pos": Vector3(6.9, 0.3, 10.2), "size": Vector3(0.7, 0.6, 0.7), "color": Color("55585e")},
	]
	for spec in crate_specs:
		var crate = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": spec["size"], "albedo_color": spec["color"],
		})
		crate.position = spec["pos"]
		add_child(crate)
