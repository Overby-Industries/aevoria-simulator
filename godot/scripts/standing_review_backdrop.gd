extends Node3D

## Decorative 3D backdrop for ObligationLevel ("The Standing Review") -- an
## audit/records-review chamber: rows of archive shelving flanking a
## review desk, all facing a big wall clock. The clock is the one prop
## this room is actually built around -- obligation_level.gd's own header
## comment is explicit that "the whole point of this system is that a
## lapse is caught by the CLOCK, not by a submission", so the backdrop
## makes that literal instead of just dressing another office (see
## governance_chamber_backdrop.gd's tribunal and reef_advocate_backdrop.gd's
## window-on-a-reef for how the other two CUR hearing levels read
## differently). Built the same way as hangar_backdrop.gd
## (docs/GRAPHICS_GUIDE.md System 2 -- SimpleShapes primitives, its own
## WorldEnvironment/camera, "camera never moves, geometry is hand-placed to
## fit it").
##
## Lit bright like Main Hangar Deck now, per the user's direction that
## every Commonwealth level should read as that same clean white --
## ObligationLevel now runs LevelChrome with light_theme = true (see
## obligation_level.gd) and this file's background/ambient values match
## hangar_backdrop.gd's Commonwealth branch exactly (background
## (0.66,0.69,0.74), ambient (0.88,0.9,0.94) @ 0.85 energy, no glow).
## Palette comes from
## FactionVisuals.backdrop_palette(LevelCatalog.AEVORIA_COMMONWEALTH) --
## ObligationLevel is Commonwealth-only, never reached by another faction.
## Purely scene dressing, no gameplay meaning.
##
## Camera framing: fixed at (0, 2.2, 8) looking toward the clock wall --
## every position below is hand-placed against that view, same convention
## hero_backdrop.gd/hangar_backdrop.gd use for their own fixed cameras.

const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

# 1 unit = 1 meter. Z follows hangar_backdrop.gd's convention -- positive
# toward the camera, negative toward the back of the room.
const ROOM_HALF_WIDTH := 7.0
const ROOM_NEAR_Z := 8.0
const ROOM_FAR_Z := -12.0
const CEILING_HEIGHT := 6.5

const CLOCK_CENTER := Vector3(0.0, 4.2, -11.7)
const CLOCK_RADIUS := 1.6

var _palette: Dictionary

func _ready() -> void:
	_palette = FactionVisuals.backdrop_palette(LevelCatalog.AEVORIA_COMMONWEALTH)
	_build_environment()
	_build_camera()
	_build_lights()
	_build_floor()
	_build_walls()
	_build_clock()
	_build_desk()
	_build_archive_racks()

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
	camera.position = Vector3(0.0, 2.2, 8.0)
	camera.fov = 60.0
	add_child(camera)
	camera.look_at(Vector3(0.0, 2.6, -12.0), Vector3.UP)
	camera.current = true

func _build_lights() -> void:
	var key = SimpleShapes.make_point_light(_palette["light"], 2.4, 12.0)
	key.position = Vector3(0.0, 4.5, -2.0)
	add_child(key)

	var clock_light = SimpleShapes.make_point_light(_palette["accent"], 1.8, 8.0)
	clock_light.position = CLOCK_CENTER + Vector3(0.0, 0.0, 1.5)
	add_child(clock_light)

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

## A big wall clock -- face, rim and two hands. The face is a squashed
## cylinder rotated 90 degrees about X so its flat end-caps (which
## normally face +Y/-Y) face the camera along +Z instead.
func _build_clock() -> void:
	var face = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": CLOCK_RADIUS, "height": 0.12,
		"albedo_color": _palette["wall"],
	})
	face.position = CLOCK_CENTER
	face.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(face)

	var rim = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": CLOCK_RADIUS + 0.1, "height": 0.06,
		"albedo_color": _palette["accent"],
		"emission_color": _palette["accent"], "emission_energy": 1.2,
	})
	rim.position = CLOCK_CENTER + Vector3(0.0, 0.0, -0.05)
	rim.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(rim)

	_build_hand(0.9, 0.08, 20.0)
	_build_hand(0.55, 0.09, 145.0)

## One clock hand -- a thin box pivoted from CLOCK_CENTER so it swings
## around the face's own plane (world X/Y, since the face itself is
## rotated to look down +Z, see _build_clock()). `angle_degrees` roughly
## measures from straight up (0 = 12 o'clock) around that plane; exact
## time-telling accuracy doesn't matter here, this is a decorative prop.
func _build_hand(length: float, width: float, angle_degrees: float) -> void:
	var pivot := Node3D.new()
	pivot.position = CLOCK_CENTER + Vector3(0.0, 0.0, -0.09)
	add_child(pivot)
	pivot.rotation_degrees = Vector3(0.0, 0.0, -angle_degrees)

	var hand = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(width, length, 0.03),
		"albedo_color": Color("14161c"),
	})
	hand.position = Vector3(0.0, length * 0.5, 0.0)  # pivots from its own base
	pivot.add_child(hand)

func _build_desk() -> void:
	var desk = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(2.6, 0.9, 1.0),
		"albedo_color": Color("1b1e26"),
	})
	desk.position = Vector3(0.0, 0.45, -5.0)
	add_child(desk)

	var console = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(1.6, 0.05, 0.5),
		"albedo_color": Color("1b1e26"),
		"emission_color": _palette["accent"], "emission_energy": 1.4,
	})
	console.position = Vector3(0.0, 0.93, -5.0)
	add_child(console)

## Archive shelving flanking the room, each rack with a small status light
## suggesting a records system -- exactly the kind of routine paperwork
## this level's whole point is that nobody filed on time.
func _build_archive_racks() -> void:
	var rack_z_positions = [5.0, 1.5, -2.0, -5.5]
	for x_sign in [-1.0, 1.0]:
		for z in rack_z_positions:
			var rack = SimpleShapes.make_mesh_instance({
				"shape": "box", "size": Vector3(0.7, 4.2, 1.3),
				"albedo_color": _palette["wall"],
			})
			rack.position = Vector3(x_sign * (ROOM_HALF_WIDTH - 0.6), 2.1, z)
			add_child(rack)

			var status_light = SimpleShapes.make_mesh_instance({
				"shape": "box", "size": Vector3(0.1, 0.1, 0.05),
				"albedo_color": _palette["accent"],
				"emission_color": _palette["accent"], "emission_energy": 2.5,
			})
			# On the rack's inward-facing side (toward room center), not
			# its outer face against the wall.
			status_light.position = rack.position - Vector3(x_sign * 0.36, -1.7, 0.0)
			add_child(status_light)
