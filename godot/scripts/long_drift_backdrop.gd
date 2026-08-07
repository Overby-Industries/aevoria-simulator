extends Node3D

## Decorative 3D backdrop for The Long Drift -- a Nomad Flotilla supply
## run with no charter and no home base (see docs/FACTIONS.md's "Nomad
## Flotilla" section and the_long_drift.gd's own doc comment: the only
## score that exists for this level is the Flotilla's own Vital
## Continuity Index, because nobody else is keeping a ledger on their
## behalf). That statelessness is the whole visual brief: this can't read
## as a station interior the way Main Hangar Deck does (hangar_backdrop.gd)
## -- the Flotilla doesn't have one. It reads as the inside of one ship
## instead: a cramped, improvised bridge/cargo-hold hybrid, patched
## together out of whatever the crew could scavenge, with a single
## porthole out onto unclaimed deep space to make "nobody's territory"
## a literal thing you can see.
##
## Built exactly like hangar_backdrop.gd (docs/GRAPHICS_GUIDE.md System 2
## + its "Main Hangar Deck" worked example): a standalone `extends Node3D`
## class, pure SimpleShapes primitives, its own WorldEnvironment and fixed
## Camera3D, "camera never moves, geometry hand-placed to fit it." The
## difference is where it's instantiated from -- the_long_drift.gd's scene
## root is `extends Node` with no Camera3D anywhere in TheLongDrift.tscn,
## so this node brings its own camera as a child of itself rather than
## sitting alongside one defined in the .tscn. A Node3D camera under a
## plain-Node ancestor still resolves a valid world transform in Godot,
## so `add_child(LongDriftBackdrop.new())` from the_long_drift.gd's
## _ready() is the entire integration.
##
## Colors come from FactionVisuals.backdrop_palette(LevelCatalog.NOMAD_FLOTILLA)
## -- warm rust/worn-metal walls, teal accent/light, not gleaming (see that
## function's own doc comment for why, and docs/FACTIONS.md for the
## reasoning: rejecting both governments means no institution ever
## refits this ship). A couple of extra rust/patch tones are derived from
## the palette's own wall color (see _patch_color()) rather than
## hardcoded, so any future palette change still flows through here.
##
## Kept intentionally basic -- a deck, an enclosing bulkhead, a console,
## a couple of crates and a porthole, not a final art pass. LevelChrome's
## glass UI theme defaults to dark (light_theme = false, untouched here),
## so the WorldEnvironment background stays near-black-teal (the
## palette's own "fog" color) rather than the bright white
## Main Hangar Deck uses under its opaque-panel theme.

const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const Starfield = preload("res://scripts/starfield.gd")
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

# 1 unit = 1 meter. Deliberately small -- a ship's bridge/cargo hold, not
# a station bay: ~4.2m wide, a low 2.7m ceiling (cramped on purpose), and
# 8.1m from the open threshold (DEPTH_NEAR, where the camera sits -- there
# is no wall behind it, same "room keeps going" trick hangar_backdrop.gd
# uses at its seam rib) to the front bulkhead (DEPTH_FAR).
const HALF_WIDTH := 2.1
const CEILING_HEIGHT := 2.7
const DEPTH_NEAR := 3.5
const DEPTH_FAR := -4.6

const CAMERA_POS := Vector3(0.45, 1.5, 3.0)
const CAMERA_LOOK_AT := Vector3(-0.15, 1.25, DEPTH_FAR)
const CAMERA_FOV := 80.0  # wider than default -- sells "cramped" by getting both walls in frame this close

# Off-center on purpose (single-operator console left, cargo right) --
# a scavenged fleet doesn't build a symmetric bridge.
const CONSOLE_X := -1.3
const CONSOLE_Z := -2.3

const PORTHOLE_X := 0.5
const PORTHOLE_Y := 1.5
const PORTHOLE_RADIUS := 0.75

# Rust trim -- a warm oxidized-orange pop used sparingly (crates, pipe,
# repair patches) against the muted wall/floor palette so the room reads
# as patchwork rather than one flat scavenged-metal color throughout.
const RUST_ACCENT := Color("7a4a2c")

var _wall_color: Color
var _floor_color: Color
var _accent_color: Color
var _light_color: Color
var _fog_color: Color

func _ready() -> void:
	var palette: Dictionary = FactionVisuals.backdrop_palette(LevelCatalog.NOMAD_FLOTILLA)
	_wall_color = palette["wall"]
	_floor_color = palette["floor"]
	_accent_color = palette["accent"]
	_light_color = palette["light"]
	_fog_color = palette["fog"]

	_build_environment()
	_build_camera()
	_build_floor()
	_build_walls()
	_build_ceiling()
	_build_porthole()
	_build_console()
	_build_crates()
	_build_pipe()
	_build_lights()
	Starfield.spawn(self, 40.0)

## A lightened/darkened variant of the palette's own wall color -- how
## every "different scavenged plate" in this room gets its color instead
## of hand-picked hex values that could drift out of sync with
## FactionVisuals.backdrop_palette().
func _patch_color(amount: float) -> Color:
	if amount >= 0.0:
		return _wall_color.lightened(amount)
	return _wall_color.darkened(-amount)

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _fog_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = _wall_color.lerp(_accent_color, 0.12)
	env.ambient_light_energy = 0.45
	env.glow_enabled = false
	# A little recycled-air haze rather than crisp station lighting --
	# reinforces "improvised" the same way hangar_backdrop.gd's fog reads
	# as "far away" (docs/GRAPHICS_GUIDE.md's worked example), just tuned
	# for a much smaller room.
	env.fog_enabled = true
	env.fog_light_color = _fog_color
	env.fog_density = 0.025
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.position = CAMERA_POS
	camera.fov = CAMERA_FOV
	camera.current = true
	add_child(camera)
	camera.look_at(CAMERA_LOOK_AT, Vector3.UP)

func _build_floor() -> void:
	var floor_mesh = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(HALF_WIDTH * 2.0, 0.15, DEPTH_NEAR - DEPTH_FAR),
		"albedo_color": _floor_color,
	})
	floor_mesh.position = Vector3(0, -0.075, (DEPTH_NEAR + DEPTH_FAR) * 0.5)
	add_child(floor_mesh)

	# A lighter deck-plate seam off the centerline -- two salvaged floor
	# sections welded together, not one continuous cast floor.
	var seam = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(0.1, 0.02, DEPTH_NEAR - DEPTH_FAR),
		"albedo_color": _patch_color(0.1),
	})
	seam.position = Vector3(0.6, 0.005, (DEPTH_NEAR + DEPTH_FAR) * 0.5)
	add_child(seam)

func _build_walls() -> void:
	_build_front_wall()
	for x_sign in [-1.0, 1.0]:
		_build_side_wall(x_sign)

## Each side wall is three short panels instead of one long plate, in
## three slightly different tones of the same base color -- the visual
## shorthand for "assembled from whatever hull plating was on hand," plus
## one crude repair patch bolted over the inside face.
func _build_side_wall(x_sign: float) -> void:
	var bounds = [DEPTH_NEAR, 0.6, -2.0, DEPTH_FAR]
	var colors = [_wall_color, _patch_color(0.08), _patch_color(-0.09)]
	for i in range(bounds.size() - 1):
		var z_from = bounds[i]
		var z_to = bounds[i + 1]
		var panel = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.18, CEILING_HEIGHT, z_from - z_to),
			"albedo_color": colors[i],
		})
		panel.position = Vector3(x_sign * HALF_WIDTH, CEILING_HEIGHT * 0.5, (z_from + z_to) * 0.5)
		add_child(panel)

	var patch_z = -1.5 if x_sign > 0.0 else 1.1
	var patch = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(0.06, 0.55, 0.65),
		"albedo_color": RUST_ACCENT,
	})
	patch.position = Vector3(x_sign * (HALF_WIDTH - 0.15), 1.4, patch_z)
	add_child(patch)

func _build_front_wall() -> void:
	var wall = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(HALF_WIDTH * 2.0, CEILING_HEIGHT, 0.2),
		"albedo_color": _patch_color(0.03),
	})
	wall.position = Vector3(0, CEILING_HEIGHT * 0.5, DEPTH_FAR)
	add_child(wall)

func _build_ceiling() -> void:
	var ceiling = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(HALF_WIDTH * 2.0, 0.15, DEPTH_NEAR - DEPTH_FAR),
		"albedo_color": _patch_color(-0.04),
	})
	ceiling.position = Vector3(0, CEILING_HEIGHT, (DEPTH_NEAR + DEPTH_FAR) * 0.5)
	add_child(ceiling)

## A round porthole in the front bulkhead -- "drifting debris or
## unclaimed deep space" made literal, per the level's own premise (no
## home base, no jurisdiction, nobody's territory to see through). A
## CylinderMesh rotated so its flat circular face points down +Z reads as
## a round window with a bolted rim; SimpleShapes has no dedicated
## "porthole" shape, so this composites two of its primitives the same
## way hangar_backdrop.gd composites boxes into an I-beam rib.
func _build_porthole() -> void:
	var frame = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": PORTHOLE_RADIUS + 0.12, "height": 0.1,
		"albedo_color": _patch_color(-0.14),
	})
	frame.rotation_degrees.x = 90.0
	frame.position = Vector3(PORTHOLE_X, PORTHOLE_Y, DEPTH_FAR + 0.05)
	add_child(frame)

	var glass := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = PORTHOLE_RADIUS
	cyl.bottom_radius = PORTHOLE_RADIUS
	cyl.height = 0.06
	glass.mesh = cyl
	glass.material_override = _glass_material()
	glass.rotation_degrees.x = 90.0
	glass.position = Vector3(PORTHOLE_X, PORTHOLE_Y, DEPTH_FAR + 0.11)
	add_child(glass)

	_build_debris()

## Tinted with the faction accent rather than a neutral gray-blue like
## Main Hangar Deck's window (_window_material() there) -- this glass
## belongs to the Flotilla, not a Commonwealth bay.
func _glass_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.32)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.1
	mat.roughness = 0.05
	return mat

## Wreckage/rubble hanging beyond the porthole, at increasing depth for a
## little parallax -- unclaimed space has debris nobody is charged with
## clearing. Positions are hand-placed against CAMERA_POS/CAMERA_LOOK_AT
## like every other prop here, not random.
func _build_debris() -> void:
	var specs = [
		{"pos": Vector3(PORTHOLE_X + 1.3, PORTHOLE_Y + 0.5, DEPTH_FAR - 9.0), "size": Vector3(1.1, 0.7, 0.9), "rot": Vector3(20.0, 35.0, 10.0)},
		{"pos": Vector3(PORTHOLE_X - 1.6, PORTHOLE_Y - 0.6, DEPTH_FAR - 15.0), "size": Vector3(1.5, 0.85, 1.2), "rot": Vector3(-12.0, 60.0, 4.0)},
	]
	for spec in specs:
		var chunk = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": spec["size"],
			"albedo_color": Color("221f19"),
		})
		chunk.position = spec["pos"]
		chunk.rotation_degrees = spec["rot"]
		add_child(chunk)

## The bridge's single console -- tucked in the left corner, angled
## instrument panel, a handful of mismatched indicator lights (salvaged
## parts, not a matched set). This is the room's "console" per
## docs/GRAPHICS_GUIDE.md's suggested reading, the same role
## greenhouse_bay.gd's desk plays for that level.
func _build_console() -> void:
	var base = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(1.1, 1.0, 0.6),
		"albedo_color": _patch_color(-0.06),
	})
	base.position = Vector3(CONSOLE_X, 0.5, CONSOLE_Z)
	add_child(base)

	var panel = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(1.1, 0.08, 0.5),
		"albedo_color": _patch_color(0.05),
	})
	panel.position = Vector3(CONSOLE_X, 1.02, CONSOLE_Z - 0.02)
	panel.rotation_degrees.x = -18.0
	add_child(panel)

	var readouts = [
		{"pos": Vector3(-0.3, 0.05, -0.02), "color": _accent_color},
		{"pos": Vector3(0.0, 0.05, 0.0), "color": Color(1.0, 0.6, 0.2)},
		{"pos": Vector3(0.3, 0.05, -0.02), "color": _accent_color},
	]
	for r in readouts:
		var indicator = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.08, 0.03, 0.06),
			"albedo_color": r["color"],
			"emission_color": r["color"], "emission_energy": 2.0,
		})
		indicator.position = r["pos"]
		panel.add_child(indicator)

## Two mismatched cargo crates stacked in the opposite corner from the
## console -- the supply-route cargo the_long_drift.gd's rounds are
## literally about (O2/PGM banked each leg), not set dressing unrelated
## to the level's own premise.
func _build_crates() -> void:
	var crate_a = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(0.9, 0.9, 0.9),
		"albedo_color": RUST_ACCENT,
	})
	crate_a.position = Vector3(1.55, 0.45, -2.7)
	crate_a.rotation_degrees.y = 8.0
	add_child(crate_a)

	var crate_b = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(0.65, 0.55, 0.65),
		"albedo_color": _patch_color(0.06),
	})
	crate_b.position = Vector3(1.5, 1.02, -2.15)
	crate_b.rotation_degrees.y = -14.0
	add_child(crate_b)

## A single conduit run along the ceiling on the console's side only --
## asymmetric, improvised routing rather than hangar_backdrop.gd's
## symmetric ceiling grid, the kind of exposed piping a scavenged hull
## accumulates over time.
func _build_pipe() -> void:
	var pipe_x = HALF_WIDTH - 0.35
	var pipe = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": 0.07, "height": DEPTH_NEAR - DEPTH_FAR - 0.6,
		"albedo_color": RUST_ACCENT,
	})
	pipe.rotation_degrees.x = 90.0
	pipe.position = Vector3(pipe_x, CEILING_HEIGHT - 0.25, (DEPTH_NEAR + DEPTH_FAR) * 0.5)
	add_child(pipe)

	for z in [2.4, 0.2, -2.2]:
		var clip = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.05, 0.15, 0.05),
			"albedo_color": _patch_color(-0.1),
		})
		clip.position = Vector3(pipe_x, CEILING_HEIGHT - 0.15, z)
		add_child(clip)

## One hanging bulb over the console (warm, improvised work light) plus a
## faint teal console glow and a dim fill toward the porthole so the far
## bulkhead doesn't vanish into black -- three small lights, not a grid,
## same "single fixture, not properly wired" read as _build_pipe()'s
## conduit.
func _build_lights() -> void:
	var bulb_pos = Vector3(CONSOLE_X, CEILING_HEIGHT - 0.55, CONSOLE_Z + 0.4)

	var cord = SimpleShapes.make_mesh_instance({
		"shape": "cylinder", "radius": 0.02, "height": 0.55,
		"albedo_color": Color(0.05, 0.05, 0.05),
	})
	cord.position = bulb_pos + Vector3(0, 0.28, 0)
	add_child(cord)

	var bulb = SimpleShapes.make_mesh_instance({
		"shape": "sphere", "radius": 0.12,
		"albedo_color": Color(1.0, 0.92, 0.75),
		"emission_color": Color(1.0, 0.85, 0.55), "emission_energy": 2.2,
	})
	bulb.position = bulb_pos
	add_child(bulb)

	var work_light = SimpleShapes.make_point_light(Color(1.0, 0.85, 0.6), 1.4, 6.0)
	work_light.position = bulb_pos
	add_child(work_light)

	var console_light = SimpleShapes.make_point_light(_accent_color, 0.8, 3.0)
	console_light.position = Vector3(CONSOLE_X, 1.3, CONSOLE_Z)
	add_child(console_light)

	var fill = SimpleShapes.make_point_light(_light_color, 0.4, 8.0)
	fill.position = Vector3(0.0, CEILING_HEIGHT - 0.4, DEPTH_FAR + 1.5)
	add_child(fill)
