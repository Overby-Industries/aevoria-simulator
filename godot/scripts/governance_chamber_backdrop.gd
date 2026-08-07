extends Node3D

## Decorative 3D backdrop for GovernanceLevel ("First Violation") -- a CUR
## compliance-hearing chamber: a raised tribunal bench facing a lone
## lectern where the mining charter's operational reports get read into
## the record, with a lit insignia monolith standing behind the bench.
## Built the same way as hangar_backdrop.gd (docs/GRAPHICS_GUIDE.md System
## 2 -- SimpleShapes primitives, its own WorldEnvironment/camera, "camera
## never moves, geometry is hand-placed to fit it") -- and, per the user's
## direction, now actually lit like it: same bright background/ambient
## values as hangar_backdrop.gd's Commonwealth branch
## (background (0.66,0.69,0.74), ambient (0.88,0.9,0.94) @ 0.85 energy, no
## glow), floor/walls pulled from the palette instead of hardcoded near-
## black, so this reads as the same clean chartered-institution white the
## Hangar already established rather than a separately-invented dark mood.
## GovernanceLevel also runs LevelChrome with light_theme = true now (see
## governance_level.gd), matching. Palette comes from
## FactionVisuals.backdrop_palette(LevelCatalog.AEVORIA_COMMONWEALTH) --
## GovernanceLevel is Commonwealth-only, never reached by another faction.
## Purely scene dressing, no gameplay meaning.
##
## Camera framing: fixed at (0, 2.4, 8) looking toward the bench -- every
## position below is hand-placed against that view, same convention
## hero_backdrop.gd/hangar_backdrop.gd use for their own fixed cameras.

const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

# 1 unit = 1 meter, this codebase's global scale convention. Z follows
# hangar_backdrop.gd's own convention -- positive toward the camera,
# negative toward the back of the room.
const ROOM_HALF_WIDTH := 7.0
const ROOM_NEAR_Z := 8.0
const ROOM_FAR_Z := -14.0
const CEILING_HEIGHT := 7.0

const BENCH_Z := -11.0
const BENCH_DEPTH := 2.5
const MONOLITH_Z := ROOM_FAR_Z + 0.5

var _palette: Dictionary

func _ready() -> void:
	_palette = FactionVisuals.backdrop_palette(LevelCatalog.AEVORIA_COMMONWEALTH)
	_build_environment()
	_build_camera()
	_build_lights()
	_build_floor()
	_build_walls()
	_build_bench()
	_build_lectern()
	_build_gallery_benches()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.66, 0.69, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.9, 0.94)
	env.ambient_light_energy = 0.85
	env.glow_enabled = false
	env.fog_enabled = true
	env.fog_light_color = env.background_color
	env.fog_density = 0.015
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.4, 8.0)
	camera.fov = 60.0
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.6, -10.0), Vector3.UP)
	camera.current = true

func _build_lights() -> void:
	# Key light over the bench -- the room's brightest point, drawing the
	# eye to the tribunal furniture the way a real hearing room's fixture
	# grid would.
	var key = SimpleShapes.make_point_light(_palette["light"], 3.0, 14.0)
	key.position = Vector3(0.0, 5.5, -9.0)
	add_child(key)

	# A dim accent fill near the camera so the lectern/gallery in the
	# foreground don't read as pure silhouette.
	var fill = SimpleShapes.make_point_light(_palette["accent"], 1.0, 10.0)
	fill.position = Vector3(0.0, 2.0, 2.0)
	add_child(fill)

func _build_floor() -> void:
	var floor_mesh = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(ROOM_HALF_WIDTH * 2.0, 0.2, ROOM_NEAR_Z - ROOM_FAR_Z),
		"albedo_color": _palette["floor"],
	})
	floor_mesh.position = Vector3(0.0, -0.1, (ROOM_NEAR_Z + ROOM_FAR_Z) * 0.5)
	add_child(floor_mesh)

func _build_walls() -> void:
	var back = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(ROOM_HALF_WIDTH * 2.0, CEILING_HEIGHT, 0.4),
		"albedo_color": _palette["wall"],
	})
	back.position = Vector3(0.0, CEILING_HEIGHT * 0.5 - 0.1, ROOM_FAR_Z)
	add_child(back)

	for x_sign in [-1.0, 1.0]:
		var side = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.3, CEILING_HEIGHT, ROOM_NEAR_Z - ROOM_FAR_Z),
			"albedo_color": _palette["wall"],
		})
		side.position = Vector3(x_sign * ROOM_HALF_WIDTH, CEILING_HEIGHT * 0.5 - 0.1, (ROOM_NEAR_Z + ROOM_FAR_Z) * 0.5)
		add_child(side)

	# The insignia monolith -- a lit panel standing behind the bench, the
	# room's one bright accent besides the bench trim itself, giving the
	# chamber a focal point the way a coat-of-arms/seal would in a real
	# tribunal room.
	var monolith = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(3.0, 4.0, 0.2),
		"albedo_color": _palette["wall"],
	})
	monolith.position = Vector3(0.0, 2.9, MONOLITH_Z)
	add_child(monolith)

	var stripe = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(0.3, 3.4, 0.05),
		"albedo_color": _palette["accent"],
		"emission_color": _palette["accent"], "emission_energy": 2.0,
	})
	stripe.position = Vector3(0.0, 2.9, MONOLITH_Z + 0.15)  # proud of the monolith's own front face
	add_child(stripe)

func _build_bench() -> void:
	var podium = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(8.0, 1.2, BENCH_DEPTH),
		"albedo_color": _palette["wall"],
	})
	podium.position = Vector3(0.0, 0.6, BENCH_Z)
	add_child(podium)

	var trim = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(8.0, 0.12, 0.06),
		"albedo_color": _palette["accent"],
		"emission_color": _palette["accent"], "emission_energy": 1.6,
	})
	trim.position = Vector3(0.0, 1.15, BENCH_Z + BENCH_DEPTH * 0.5 + 0.03)  # proud of the podium's front face
	add_child(trim)

func _build_lectern() -> void:
	var base = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(0.8, 1.1, 0.5),
		"albedo_color": Color("1b1e26"),
	})
	base.position = Vector3(0.0, 0.55, -2.0)
	add_child(base)

	var top = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(0.9, 0.08, 0.65),
		"albedo_color": _palette["wall"],
	})
	top.position = Vector3(0.0, 1.14, -2.0)
	top.rotation_degrees = Vector3(-12.0, 0.0, 0.0)  # a slight forward tilt, like a reading surface
	add_child(top)

func _build_gallery_benches() -> void:
	for z in [2.0, 5.0]:
		var bench = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(9.0, 0.5, 0.6),
			"albedo_color": Color("1b1e26"),
		})
		bench.position = Vector3(0.0, 0.25, z)
		add_child(bench)
