extends Node3D

## Decorative 3D backdrop for Main Hangar Deck -- the interior counterpart
## to hero_backdrop.gd's exterior space dressing. Main Hangar Deck used to
## be "deliberately just a UI hub" (see main_hangar_deck.gd's old doc
## comment) with nothing behind its cards but Godot's default clear color.
## Built the same way as every other prop in this codebase
## (docs/GRAPHICS_GUIDE.md System 2, SimpleShapes, pure GDScript
## primitives, no imported models, never needs a rebuild). Purely scene
## dressing, no gameplay meaning, same as hero_backdrop.gd.
##
## No glow/bloom -- a bloom halo around a light is a real-lens artifact
## that makes sense for a photographed light source, not an in-scene
## fluorescent fixture. An earlier version also gave each ceiling fixture
## its own screen-space anamorphic streak sprite, but at fixture scale/
## count that read as an artificial overlay rather than a real light, so
## it's gone -- the fixtures' own emissive material plus their reflection
## in the glossy floor sells them now.
##
## MainHangarDeck.tscn's DirectionalLight3D has shadow_enabled = false --
## an earlier version turned shadows on hoping for contact shadow under
## the ribs, but the shadow's own hard edge (the ceiling/ribs occluding it
## at a shallow angle) was what caused the two-tone line across the floor
## described below, and no shadow mode fixed it -- only turning shadows
## off did. So the ribs read purely off their material's specular
## highlight and ambient, not cast shadow, for now.
##
## Sized to actually fit the SSTO hull ("Helga", part_catalog.gd's
## ssto_hull_helga -- 36.58m/120ft long, 30.48m/100ft wingspan, see
## docs/GRAPHICS_GUIDE.md's System 1 section) with real clearance, not
## just "looks about right": HANGAR_HALF_WIDTH/HANGAR_DEPTH_NEAR/FAR below
## give a floor comfortably larger than both dimensions.
##
## The floor is a real reflective surface (low roughness/some metallic +
## WorldEnvironment SSR) -- the ceiling light grid exists specifically to
## give that surface something bright to reflect.
##
## Camera framing: MainHangarDeck.tscn's own fixed Camera3D sits at
## (0, 5, 14), pitched up to bring the ceiling into frame, with a wider
## FOV than Godot's 75-degree default for a more dramatic vanishing-point
## convergence toward the back wall -- every position below is hand-placed
## against that view, the same "camera never moves, geometry is placed to
## fit it" approach hero_backdrop.gd uses for SUN_POSITION.

const SimpleShapes = preload("res://scripts/simple_shapes.gd")

const FLOOR_COLOR = Color("eceef1")
const WALL_COLOR = Color("eceef1")
const RIB_COLOR = WALL_COLOR

# 1 unit = 1 meter (this codebase's global scale convention). Full width
# 40m/~131ft and full depth 50m/~164ft both clear Helga's 30.48m/36.58m
# with real margin, not a tight fit.
const HANGAR_HALF_WIDTH := 20.0
const HANGAR_DEPTH_NEAR := 20.0   # toward the camera
const HANGAR_DEPTH_FAR := -30.0   # the back wall
const CEILING_HEIGHT := 12.0

# Ceiling fixture grid -- see _build_lights(). Spaced every 8m in both
# directions so a big room still reads as evenly lit.
const FIXTURE_X_POSITIONS = [-16.0, -8.0, 0.0, 8.0, 16.0]
const FIXTURE_Z_POSITIONS = [16.0, 8.0, 0.0, -8.0, -16.0, -24.0]

# Structural ribs -- offset from the fixture rows (see FIXTURE_Z_POSITIONS)
# so a rib never sits directly behind a light row; they read as distinct
# ceiling elements between the rows of fixtures.
const ARCH_Z_POSITIONS = [12.0, 4.0, -4.0, -12.0, -20.0]
# How far the ribs' feet sit in front of the side walls' inner faces, so
# they stay flush with the walls without clipping through them (the walls
# are centered ON the HANGAR_HALF_WIDTH boundary, so their inner face is
# already a bit short of it).
const WALL_INSET := 0.25
const RIB_BASE_Y := 0.0   # flush with the floor -- _build_base_plate() plants it there
const RIB_CORNER_RADIUS := 2.5
const RIB_CORNER_SEGMENTS := 4

# I-beam cross section -- "big, wide" wide-flange steel, not a thin rod.
const RIB_HEIGHT := 4.0          # overall depth, flange face to flange face
const RIB_FLANGE_WIDTH := 0.85   # flange plate width, along the hangar's depth axis
const RIB_FLANGE_THICKNESS := 0.09
const RIB_WEB_THICKNESS := 0.12
const RIB_BASE_PLATE_MARGIN := 0.5
const RIB_BASE_PLATE_THICKNESS := 0.12

func _ready() -> void:
	_build_environment()
	_build_floor()
	_build_walls()
	_build_ceiling()
	_build_wall_ceiling_fillets()
	_build_ceiling_ribs()
	_build_lights()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.66, 0.69, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.9, 0.94)
	env.ambient_light_energy = 0.85
	env.glow_enabled = false
	# The actual "trick" for floor reflections: screen-space reflections
	# read the floor's low-roughness material (_floor_material()) and
	# mirror whatever's above it -- the ceiling fixtures/ribs, mainly --
	# instead of the floor just picking up a flat specular highlight. The
	# floor's own two-tone seam was a shadow cascade artifact, not this --
	# see MainHangarDeck.tscn's DirectionalLight3D and the doc comment above.
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	# Atmospheric perspective -- the far end of a 50m room fading gently
	# toward the background color instead of staying pin-sharp all the way
	# back is what actually reads as "far away," the same cue real
	# haze/dust gives depth over distance outdoors, applied indoors here.
	env.fog_enabled = true
	env.fog_light_color = env.background_color
	env.fog_density = 0.015
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _floor_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FLOOR_COLOR
	# Glossy but not a mirror -- a near-zero roughness sharpened SSR's own
	# ray-march stepping into visible banding on the segmented ribs' shape.
	mat.metallic = 0.5
	mat.roughness = 0.15
	return mat

func _build_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(HANGAR_HALF_WIDTH * 2.0, 0.2, HANGAR_DEPTH_NEAR - HANGAR_DEPTH_FAR)
	floor_mesh.mesh = box
	floor_mesh.position = Vector3(0, -0.1, (HANGAR_DEPTH_NEAR + HANGAR_DEPTH_FAR) * 0.5)
	floor_mesh.material_override = _floor_material()
	add_child(floor_mesh)

func _build_walls() -> void:
	var back_wall = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(HANGAR_HALF_WIDTH * 2.0, CEILING_HEIGHT, 0.4),
		"albedo_color": WALL_COLOR,
	})
	back_wall.position = Vector3(0, CEILING_HEIGHT * 0.5 - 0.1, HANGAR_DEPTH_FAR)
	add_child(back_wall)

	for x_sign in [-1.0, 1.0]:
		var side_wall = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.4, CEILING_HEIGHT, HANGAR_DEPTH_NEAR - HANGAR_DEPTH_FAR),
			"albedo_color": WALL_COLOR,
		})
		side_wall.position = Vector3(x_sign * HANGAR_HALF_WIDTH, CEILING_HEIGHT * 0.5 - 0.1, (HANGAR_DEPTH_NEAR + HANGAR_DEPTH_FAR) * 0.5)
		add_child(side_wall)

func _build_ceiling() -> void:
	var ceiling = SimpleShapes.make_mesh_instance({
		"shape": "box",
		"size": Vector3(HANGAR_HALF_WIDTH * 2.0, 0.3, HANGAR_DEPTH_NEAR - HANGAR_DEPTH_FAR),
		"albedo_color": WALL_COLOR,
	})
	ceiling.position = Vector3(0, CEILING_HEIGHT, (HANGAR_DEPTH_NEAR + HANGAR_DEPTH_FAR) * 0.5)
	add_child(ceiling)

# How far past the curve's own radius the fillet's solid material extends,
# outward, away from the room's interior. The flat side wall and flat
# ceiling (built above) still meet at their original sharp 90-degree
# corner underneath this -- rather than trimming them back to match the
# curve exactly, the fillet is just built thick enough that its outer
# edge always reaches past that sharp corner and buries it, in every
# direction along the arc (worst case is the diagonal corner point itself,
# at RIB_CORNER_RADIUS * sqrt(2) from the arc's center -- about 1.41x the
# radius -- so this margin only needs to clear the remaining ~0.41x).
const FILLET_THICKNESS := 4.0

## Rounds the seam where each flat side wall meets the flat ceiling, using
## the exact same corner radius as the ceiling ribs (RIB_CORNER_RADIUS/
## RIB_CORNER_SEGMENTS) so the room's actual shell reads as one continuous
## curved vault instead of a sharp box corner sitting behind rounded ribs
## that don't match it. Built the same way as the ribs -- a chain of
## straight box segments approximating the quarter-circle -- except each
## segment here runs the full room depth in one piece (this is a single
## continuous seam, not a repeated cross-section like the ribs).
func _build_wall_ceiling_fillets() -> void:
	for x_sign in [-1.0, 1.0]:
		_build_fillet(x_sign)

func _build_fillet(x_sign: float) -> void:
	var wall_x = x_sign * HANGAR_HALF_WIDTH
	var corner_top_y = CEILING_HEIGHT - RIB_CORNER_RADIUS
	var center = Vector3(wall_x - x_sign * RIB_CORNER_RADIUS, corner_top_y, 0.0)
	var depth = HANGAR_DEPTH_NEAR - HANGAR_DEPTH_FAR
	var mid_z = (HANGAR_DEPTH_NEAR + HANGAR_DEPTH_FAR) * 0.5

	# Sweeps from the wall side of the curve to the ceiling side -- same
	# angle convention _build_rib() uses for this same corner.
	var angle_wall = PI if x_sign < 0.0 else 0.0
	var angle_ceiling = PI * 0.5
	for i in range(RIB_CORNER_SEGMENTS):
		var angle1 = lerp(angle_wall, angle_ceiling, float(i) / float(RIB_CORNER_SEGMENTS))
		var angle2 = lerp(angle_wall, angle_ceiling, float(i + 1) / float(RIB_CORNER_SEGMENTS))
		var dir1 = Vector3(cos(angle1), sin(angle1), 0.0)
		var dir2 = Vector3(cos(angle2), sin(angle2), 0.0)
		var p1 = center + dir1 * RIB_CORNER_RADIUS
		var p2 = center + dir2 * RIB_CORNER_RADIUS
		var outward = (dir1 + dir2).normalized()
		_build_fillet_segment(p1, p2, outward, mid_z, depth)

func _build_fillet_segment(p1: Vector3, p2: Vector3, outward: Vector3, mid_z: float, depth: float) -> void:
	var length = p1.distance_to(p2)
	if length < 0.001:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WALL_COLOR

	var beam := MeshInstance3D.new()
	var box := BoxMesh.new()
	# Local X = thickness (pushed fully outward below, so the segment's
	# INNER face sits exactly on the p1-p2 curve and only the outer face
	# extends further out -- not centered on the curve, which would pull
	# the visible inner surface tighter than RIB_CORNER_RADIUS and break
	# the match with the ribs). Local Y = world Z (this profile is planar,
	# same reasoning as _build_beam_segment's doc comment), so `depth`
	# extrudes the whole thing the full room length in one piece.
	box.size = Vector3(FILLET_THICKNESS, depth, length)
	beam.mesh = box
	beam.material_override = mat
	var midpoint = (p1 + p2) * 0.5 + outward * (FILLET_THICKNESS * 0.5)
	beam.position = Vector3(midpoint.x, midpoint.y, mid_z)
	add_child(beam)
	var direction = (p2 - p1).normalized()
	beam.look_at(beam.position + direction, Vector3.BACK)

## Matte white painted steel -- low metallic, moderate roughness, so the
## ribs read as the same white as the walls/ceiling, distinguished from
## them mainly by their own specular highlight and by ambient shading
## along their curve rather than by a color difference or a cast shadow.
func _rib_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = RIB_COLOR
	mat.metallic = 0.15
	mat.roughness = 0.45
	return mat

## Exposed structural ribs arching from one side wall, over the ceiling,
## down to the other side wall -- the aircraft-carrier-hangar look, and
## repeated down the length of the bay, a set of receding identical
## frames that reinforces the vanishing-point perspective on its own.
## Each rib is a chain of straight beam segments approximating a rounded
## rectangle (two quarter-circle corners + a flat ceiling span) rather
## than a true curve -- there's no curved-primitive/spline system in this
## codebase, and straight segments in a tight enough arc read as curved
## from this camera distance. Flush with the floor at both feet
## (RIB_BASE_Y = 0), each planted on its own base plate. Spans the full
## wall-to-wall width and reaches full ceiling height -- the back wall
## itself is plain for now (the cargo door that used to sit in it is
## being redesigned).
func _build_ceiling_ribs() -> void:
	for z_position in ARCH_Z_POSITIONS:
		_build_rib(z_position)

func _build_rib(z_position: float) -> void:
	var half_w = HANGAR_HALF_WIDTH - WALL_INSET
	var corner_top_y = CEILING_HEIGHT - RIB_CORNER_RADIUS
	var points: Array = []
	points.append(Vector3(-half_w, RIB_BASE_Y, z_position))
	points.append(Vector3(-half_w, corner_top_y, z_position))

	var left_center = Vector3(-half_w + RIB_CORNER_RADIUS, corner_top_y, z_position)
	for i in range(1, RIB_CORNER_SEGMENTS + 1):
		var t = float(i) / float(RIB_CORNER_SEGMENTS)
		var angle = PI - t * (PI * 0.5)
		points.append(left_center + Vector3(cos(angle), sin(angle), 0.0) * RIB_CORNER_RADIUS)

	var right_center = Vector3(half_w - RIB_CORNER_RADIUS, corner_top_y, z_position)
	for i in range(0, RIB_CORNER_SEGMENTS + 1):
		var t = float(i) / float(RIB_CORNER_SEGMENTS)
		var angle = PI * 0.5 - t * (PI * 0.5)
		points.append(right_center + Vector3(cos(angle), sin(angle), 0.0) * RIB_CORNER_RADIUS)

	points.append(Vector3(half_w, RIB_BASE_Y, z_position))

	for i in range(points.size() - 1):
		_build_beam_segment(points[i], points[i + 1])

	_build_base_plate(points[0])
	_build_base_plate(points[points.size() - 1])

## Every point in a rib shares the same Z (see z_position above), so every
## segment's direction vector has a zero Z component -- meaning
## Vector3.BACK (world +Z) is *always* perpendicular to it and never
## degenerate as a look_at() up-hint, unlike Vector3.UP which fails on the
## near-vertical foot segments. Using it uniformly (instead of switching
## hints per segment, as an earlier version did to dodge that failure)
## keeps the resulting local frame continuous around the whole arch: local
## Y lands exactly on world Z and local X on the in-plane perpendicular,
## for every segment, so the flanges below stay lined up edge-to-edge
## instead of twisting where the hint used to change.
func _build_beam_segment(p1: Vector3, p2: Vector3) -> void:
	var length = p1.distance_to(p2)
	if length < 0.001:
		return
	var beam := Node3D.new()
	beam.position = (p1 + p2) * 0.5
	add_child(beam)
	beam.look_at(p2, Vector3.BACK)

	var mat := _rib_material()
	var flange_offset = RIB_HEIGHT * 0.5 - RIB_FLANGE_THICKNESS * 0.5
	for flange_sign in [-1.0, 1.0]:
		var flange := MeshInstance3D.new()
		var flange_box := BoxMesh.new()
		flange_box.size = Vector3(RIB_FLANGE_THICKNESS, RIB_FLANGE_WIDTH, length)
		flange.mesh = flange_box
		flange.material_override = mat
		flange.position = Vector3(flange_sign * flange_offset, 0, 0)
		beam.add_child(flange)

	var web := MeshInstance3D.new()
	var web_box := BoxMesh.new()
	web_box.size = Vector3(RIB_HEIGHT - RIB_FLANGE_THICKNESS * 2.0, RIB_WEB_THICKNESS, length)
	web.mesh = web_box
	web.material_override = mat
	beam.add_child(web)

## A flat plate under each rib's foot -- what makes the beam read as
## bolted to the floor instead of just poking through it.
func _build_base_plate(point: Vector3) -> void:
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(RIB_HEIGHT + RIB_BASE_PLATE_MARGIN, RIB_BASE_PLATE_THICKNESS, RIB_FLANGE_WIDTH + RIB_BASE_PLATE_MARGIN)
	plate.mesh = box
	plate.material_override = _rib_material()
	plate.position = Vector3(point.x, RIB_BASE_PLATE_THICKNESS * 0.5, point.z)
	add_child(plate)

## A grid of small fluorescent-tube fixtures across the ceiling -- each
## one ~4ft (1.22m) long, oriented with their long edge along X, which is
## perpendicular to the hangar's length (Z, HANGAR_DEPTH_NEAR/FAR).
## Positioned between the ceiling ribs (see ARCH_Z_POSITIONS vs
## FIXTURE_Z_POSITIONS) rather than on them, so a rib is never blocking a
## fixture -- the glossy floor's specular highlight under each one is what
## actually sells these from the camera's shallow angle, more than the
## fixtures themselves.
func _build_lights() -> void:
	for z_position in FIXTURE_Z_POSITIONS:
		for x_position in FIXTURE_X_POSITIONS:
			var pos = Vector3(x_position, CEILING_HEIGHT - 0.2, z_position)
			var fixture = SimpleShapes.make_mesh_instance({
				"shape": "box", "size": Vector3(1.22, 0.08, 0.15),
				"albedo_color": Color("f5f8ff"),
				"emission_color": Color("eaf2ff"), "emission_energy": 3.0,
			})
			fixture.position = pos
			add_child(fixture)

			var light = SimpleShapes.make_point_light(Color("eaf2ff"), 1.6, 9.0)
			light.position = Vector3(x_position, CEILING_HEIGHT - 0.5, z_position)
			add_child(light)
