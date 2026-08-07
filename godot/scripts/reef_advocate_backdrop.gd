extends Node3D

## Decorative 3D backdrop for AdvocateLevel ("The Reef's Advocate") -- a
## habitat-determination hearing room with a tinted picture window looking
## out onto the lit reef habitat under review, so this reads differently
## from the other two CUR hearing levels (governance_chamber_backdrop.gd's
## tribunal, standing_review_backdrop.gd's archive) instead of just being
## another bare office. Built the same way as hangar_backdrop.gd
## (docs/GRAPHICS_GUIDE.md System 2 -- SimpleShapes primitives, its own
## WorldEnvironment/camera, "camera never moves, geometry is hand-placed to
## fit it"). The window itself reuses hangar_backdrop.gd's tinted-glass
## technique (a low solid sill, a seamless glass pane above it), just
## pointed at a lit tank instead of daylight.
##
## Lit bright like Main Hangar Deck now, per the user's direction that
## every Commonwealth level should read as that same clean white --
## AdvocateLevel now runs LevelChrome with light_theme = true (see
## advocate_level.gd) and this file's background/ambient values match
## hangar_backdrop.gd's Commonwealth branch exactly (background
## (0.66,0.69,0.74), ambient (0.88,0.9,0.94) @ 0.85 energy, no glow). The
## reef beyond the glass stays the one saturated color note in the room --
## its own point light (REEF_GLOW) still reads clearly against a bright
## hearing room the same way it did against a dark one. Palette comes from
## FactionVisuals.backdrop_palette(LevelCatalog.AEVORIA_COMMONWEALTH) --
## AdvocateLevel is Commonwealth-only, never reached by another faction.
## Purely scene dressing, no gameplay meaning.
##
## Camera framing: fixed at (0, 2.0, 8) looking toward the window -- every
## position below is hand-placed against that view, same convention
## hero_backdrop.gd/hangar_backdrop.gd use for their own fixed cameras.

const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

# 1 unit = 1 meter. Z follows hangar_backdrop.gd's convention -- positive
# toward the camera, negative toward the back of the room. The hearing
# room itself is shallow (ROOM_FAR_Z is close to the camera compared to
# the other two backdrops) because the reef cluster beyond the window is
# what gives this scene its depth instead.
const ROOM_HALF_WIDTH := 7.0
const ROOM_NEAR_Z := 8.0
const ROOM_FAR_Z := -6.0
const CEILING_HEIGHT := 6.0
const WINDOW_SILL_HEIGHT := 1.0

const REEF_COLOR := Color("1c6e63")
const REEF_GLOW := Color("57e8c8")

var _palette: Dictionary

func _ready() -> void:
	_palette = FactionVisuals.backdrop_palette(LevelCatalog.AEVORIA_COMMONWEALTH)
	_build_environment()
	_build_camera()
	_build_lights()
	_build_floor()
	_build_walls_and_window()
	_build_table()
	_build_seats()
	_build_reef()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.66, 0.69, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.9, 0.94)
	env.ambient_light_energy = 0.85
	env.glow_enabled = false
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.0, 8.0)
	camera.fov = 62.0
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.4, -10.0), Vector3.UP)
	camera.current = true

func _build_lights() -> void:
	# Warm key light over the hearing table.
	var key = SimpleShapes.make_point_light(_palette["light"], 2.2, 12.0)
	key.position = Vector3(0.0, 4.5, 2.0)
	add_child(key)

	# The reef's own glow, well behind the window -- this is what makes
	# the habitat beyond the glass read as lit from within rather than as
	# a flat silhouette.
	var reef_glow = SimpleShapes.make_point_light(REEF_GLOW, 3.0, 16.0)
	reef_glow.position = Vector3(0.0, 2.0, -14.0)
	add_child(reef_glow)

func _build_floor() -> void:
	var floor_mesh = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(ROOM_HALF_WIDTH * 2.0, 0.2, ROOM_NEAR_Z - ROOM_FAR_Z),
		"albedo_color": _palette["floor"],
	})
	floor_mesh.position = Vector3(0.0, -0.1, (ROOM_NEAR_Z + ROOM_FAR_Z) * 0.5)
	add_child(floor_mesh)

func _build_walls_and_window() -> void:
	for x_sign in [-1.0, 1.0]:
		var side = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.3, CEILING_HEIGHT, ROOM_NEAR_Z - ROOM_FAR_Z),
			"albedo_color": _palette["wall"],
		})
		side.position = Vector3(x_sign * ROOM_HALF_WIDTH, CEILING_HEIGHT * 0.5 - 0.1, (ROOM_NEAR_Z + ROOM_FAR_Z) * 0.5)
		add_child(side)

	# Solid sill below, one seamless tinted window above -- same technique
	# as hangar_backdrop.gd's _build_back_wall(), just a lower sill so more
	# of the wall is glass, since the reef beyond needs to actually be
	# visible from the fixed camera.
	var sill = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(ROOM_HALF_WIDTH * 2.0, WINDOW_SILL_HEIGHT, 0.4),
		"albedo_color": _palette["wall"],
	})
	sill.position = Vector3(0.0, WINDOW_SILL_HEIGHT * 0.5 - 0.1, ROOM_FAR_Z)
	add_child(sill)

	var window := MeshInstance3D.new()
	var window_box := BoxMesh.new()
	window_box.size = Vector3(ROOM_HALF_WIDTH * 2.0, CEILING_HEIGHT - WINDOW_SILL_HEIGHT, 0.3)
	window.mesh = window_box
	# Slightly tinted, translucent glass, teal-shifted to hint at the tank
	# beyond -- low roughness for a glassy highlight, alpha well under 1 so
	# it reads as glass, same reasoning as hangar_backdrop.gd's
	# _window_material().
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.7, 0.68, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.1
	mat.roughness = 0.05
	window.material_override = mat
	window.position = Vector3(0.0, WINDOW_SILL_HEIGHT + (CEILING_HEIGHT - WINDOW_SILL_HEIGHT) * 0.5 - 0.1, ROOM_FAR_Z)
	add_child(window)

func _build_table() -> void:
	var table = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": 1.6, "height": 0.1,
		"albedo_color": _palette["wall"],
	})
	table.position = Vector3(0.0, 0.75, -1.0)
	add_child(table)

	var pedestal = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": 0.35, "height": 0.7,
		"albedo_color": Color("1b1e26"),
	})
	pedestal.position = Vector3(0.0, 0.35, -1.0)
	add_child(pedestal)

func _build_seats() -> void:
	for x in [-2.2, 2.2]:
		var seat = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.6, 0.9, 0.6),
			"albedo_color": Color("1b1e26"),
		})
		seat.position = Vector3(x, 0.45, 1.0)
		add_child(seat)

## The reef habitat, seen through the window -- a cluster of coral
## "branches" (plain cylinders of varying height/radius; SimpleShapes has
## no tapered-cylinder shape, see docs/GRAPHICS_GUIDE.md System 1 for where
## a genuinely new shape would have to go) around one large habitat dome,
## all lit from within by REEF_GLOW so it reads as the thing under review,
## not just backdrop.
func _build_reef() -> void:
	var dome = SimpleShapes.make_mesh_instance({
		"shape": "sphere", "radius": 2.2, "radial_segments": 16, "rings": 8,
		"albedo_color": REEF_COLOR,
		"emission_color": REEF_GLOW, "emission_energy": 0.6,
	})
	dome.position = Vector3(0.0, 1.6, -15.5)
	add_child(dome)

	var branch_specs = [
		{"x": -3.5, "z": -11.0, "h": 2.4, "r": 0.35},
		{"x": -2.0, "z": -13.0, "h": 3.4, "r": 0.3},
		{"x": 2.2, "z": -11.5, "h": 2.8, "r": 0.32},
		{"x": 3.6, "z": -13.5, "h": 1.9, "r": 0.28},
		{"x": 0.3, "z": -17.0, "h": 3.8, "r": 0.42},
	]
	for spec in branch_specs:
		var branch = SimpleShapes.make_mesh_instance({
			"shape": "cylinder", "radius": spec["r"], "height": spec["h"],
			"albedo_color": REEF_COLOR,
			"emission_color": REEF_GLOW, "emission_energy": 0.5,
		})
		# Base sits on the (implied) tank floor at y=0; the cylinder's own
		# origin is its center, so its position is half its own height.
		branch.position = Vector3(spec["x"], spec["h"] * 0.5, spec["z"])
		add_child(branch)
