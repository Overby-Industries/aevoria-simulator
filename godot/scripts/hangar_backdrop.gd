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
##
## Faction-aware since the retrofit that made Main Hangar Deck one shared
## scene for all three factions (main_hangar_deck.gd's own doc comment) --
## the wall/floor/rib colors, the ceiling fixtures' glow, the window glass
## tint, and the room's ambient/background all now come from the
## faction_id passed to _init() below (see _apply_faction_palette())
## instead of being hardcoded "eceef1" white. Everything else on this
## page -- why there's no bloom, why shadows are off, why the floor is
## reflective, the exact camera framing -- is unchanged and applies
## equally to all three faction looks; only material/light color values
## vary per faction, never the room's geometry.

const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

## Per-faction interior mood -- these replace what used to be FLOOR_COLOR/
## WALL_COLOR/RIB_COLOR/WINDOW_TINT_COLOR constants (all a flat "eceef1"
## white/pale-blue glass, from when this room was Commonwealth-only).
## Populated once by _apply_faction_palette(), called first thing in
## _ready(), from the faction_id passed to _init() -- they can no longer
## be compile-time constants once they depend on a constructor argument.
## _wall_color/_floor_color/_light_color come straight from
## FactionVisuals.backdrop_palette(); _window_tint_color/_ambient_color/
## _ambient_energy/_background_color are this file's own per-faction
## tuning for the extra knobs the shared palette doesn't carry (see
## _apply_faction_palette()). Commonwealth's values reproduce this file's
## original hardcoded look almost exactly, per backdrop_palette()'s own
## doc comment, so Commonwealth barely changes -- the Combine and Flotilla
## arms are what make the same geometry actually read as three different
## factions' hangars.
var _faction_id: String
var _wall_color: Color
var _floor_color: Color
var _rib_color: Color
var _light_color: Color
var _window_tint_color: Color
var _ambient_color: Color
var _ambient_energy: float
var _background_color: Color

## Mirrors CycleStatusPanel/VCICommonsPanel's own _init(faction_id) --
## just stashes the id; the actual palette lookup happens in
## _apply_faction_palette() at the top of _ready(), same split those two
## panels use between _init() and _ready().
func _init(faction_id: String) -> void:
	_faction_id = faction_id

# Back wall window band -- see _build_back_wall(). Fraction of the wall's
# own height (0 = floor, 1 = ceiling) where the glass starts; the glass
# always runs from there to the top, so this is the only knob needed.
const WINDOW_BOTTOM_FRACTION := 0.55

# 1 unit = 1 meter (this codebase's global scale convention). Full width
# 40m/~131ft and full depth 100m/~328ft both clear Helga's 30.48m/36.58m
# with real margin, not a tight fit. The depth is two of the original 50m
# hangar back to back (see ARCH_Z_POSITIONS/FIXTURE_Z_POSITIONS below) --
# the wall that used to close off the first 50m is gone, replaced by one
# more rib exactly where it stood, so the room just keeps going instead of
# dead-ending; only the very last copy still has a real end wall.
const HANGAR_HALF_WIDTH := 20.0
const HANGAR_DEPTH_NEAR := 20.0   # toward the camera
const HANGAR_DEPTH_FAR := -80.0   # the back wall
const CEILING_HEIGHT := 12.0

# Shared by the window band (_build_back_wall()) and the catwalk/staircase
# below, so the platform sits exactly at the window's own bottom edge --
# "middle of the wall, just below the windows" is this same value, since
# the window already starts a bit past the wall's actual half-height (see
# WINDOW_BOTTOM_FRACTION above). lerp(-0.1, CEILING_HEIGHT - 0.1, t) with
# a = -0.1 and (b - a) = CEILING_HEIGHT simplifies to this.
const CATWALK_HEIGHT := -0.1 + CEILING_HEIGHT * WINDOW_BOTTOM_FRACTION

# Top of the back wall's solid extent -- also the top of the window band
# and where it meets the ceiling. Shared by the door frame (reaches all
# the way up to it) and the catwalk's top rail (set to half this height
# above CATWALK_HEIGHT), so both stay correct if CEILING_HEIGHT ever
# changes instead of quietly drifting out of sync with it.
const WALL_TOP := CEILING_HEIGHT - 0.1

# Ceiling fixture grid -- see _build_lights(). Spaced every 8m in both
# directions so a big room still reads as evenly lit. The second half
# (from -34 on) is the first half's own pattern (16..-24) shifted back by
# exactly one hangar-length (50m), same as ARCH_Z_POSITIONS below.
const FIXTURE_X_POSITIONS = [-16.0, -8.0, 0.0, 8.0, 16.0]
const FIXTURE_Z_POSITIONS = [16.0, 8.0, 0.0, -8.0, -16.0, -24.0, -34.0, -42.0, -50.0, -58.0, -66.0, -74.0]

# Structural ribs -- offset from the fixture rows (see FIXTURE_Z_POSITIONS)
# so a rib never sits directly behind a light row; they read as distinct
# ceiling elements between the rows of fixtures. -30.0 is the seam rib --
# it sits exactly where the original back wall used to be. Everything from
# -38.0 on is the original 5-rib pattern (12..-20) shifted back by one
# hangar-length (50m), i.e. a second copy of the same hangar continuing
# behind the seam rib, ending at the real back wall (HANGAR_DEPTH_FAR).
const ARCH_Z_POSITIONS = [12.0, 4.0, -4.0, -12.0, -20.0, -30.0, -38.0, -46.0, -54.0, -62.0, -70.0]
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

# Staircase (right side, starting out in the open floor where the camera
# can see it) up to a catwalk that spans the back wall just below the
# windows (CATWALK_HEIGHT above), which in turn leads to a door frame on
# the left. See _build_staircase()/_build_catwalk()/_build_door_frame().
const CATWALK_DEPTH := 2.0        # how far the platform sticks out from the wall
const CATWALK_WALL_GAP := 0.3     # gap between the platform's back edge and the glass
const CATWALK_THICKNESS := 0.2
# Top rail sits halfway up the window band; the mid rail sits halfway
# between the deck and the top rail. Two "sturdy" horizontal rails read
# as a real guardrail from across the room, not just a trip-wire.
const CATWALK_RAIL_HEIGHT := (WALL_TOP - CATWALK_HEIGHT) * 0.5
const CATWALK_RAIL_MID_HEIGHT := CATWALK_RAIL_HEIGHT * 0.5
const CATWALK_RAIL_THICKNESS := 0.14
const CATWALK_POST_THICKNESS := 0.12
const CATWALK_X_RIGHT := HANGAR_HALF_WIDTH - WALL_INSET
const CATWALK_X_LEFT := -(HANGAR_HALF_WIDTH - WALL_INSET)
const CATWALK_Z_BACK := HANGAR_DEPTH_FAR + CATWALK_WALL_GAP
const CATWALK_Z_FRONT := CATWALK_Z_BACK + CATWALK_DEPTH

# Kept clear of the ceiling ribs' own foot flanges, not just clear of the
# wall itself -- the last rib (ARCH_Z_POSITIONS' -70.0) lands squarely in
# the stair run's own Z span, and each rib's flange reaches RIB_HEIGHT*0.5
# in from its wall centerline (see _build_rib()/_build_beam_segment()), so
# at the ribs' current 4m depth that's 2m in from the wall -- enough to
# have been cutting straight through the middle of the old, wider stairs.
# STAIR_X derives its distance from the wall from RIB_HEIGHT itself so
# this stays correct if the I-beam size is tuned again later.
const STAIR_WIDTH := 2.2
const STAIR_STEPS := 20
const STAIR_RUN_LENGTH := 11.0    # horizontal distance the stair run covers
const STAIR_WALL_CLEARANCE := 0.5 # gap between the stair's outer edge and the rib flange's inner face
const STAIR_X := (HANGAR_HALF_WIDTH - WALL_INSET) - RIB_HEIGHT * 0.5 - STAIR_WALL_CLEARANCE - STAIR_WIDTH * 0.5
const STAIR_TOP_Z := CATWALK_Z_FRONT       # top step lands on the catwalk's front edge
const STAIR_BOTTOM_Z := STAIR_TOP_Z + STAIR_RUN_LENGTH  # further from the wall, at floor level

# Full height, catwalk deck to ceiling, and flush against the left wall's
# own inner face -- DOOR_X is set so the door's LEFT jamb lands right on
# CATWALK_X_LEFT (the same "flush with the wall" line the ribs/catwalk
# use), leaving only the right jamb, lintel, and threshold reading as a
# visible frame from inside the room.
const DOOR_WIDTH := 2.2
const DOOR_HEIGHT := WALL_TOP - CATWALK_HEIGHT
const DOOR_FRAME_THICKNESS := 0.15
const DOOR_X := CATWALK_X_LEFT + DOOR_WIDTH * 0.5

func _ready() -> void:
	_apply_faction_palette()
	_build_environment()
	_build_floor()
	_build_walls()
	_build_ceiling()
	_build_wall_ceiling_fillets()
	_build_ceiling_ribs()
	_build_lights()
	_build_staircase()
	_build_catwalk()
	_build_door_frame()

## Reads this room's base colors from FactionVisuals.backdrop_palette()
## (see docs/FACTIONS.md for the reasoning behind each faction's look) and
## fills in the handful of extra values that shared palette doesn't cover
## but this file still needs: window glass tint, and the environment's
## ambient/background color+energy (the "haze" the far end of the room
## fades into -- see _build_environment()'s own doc comment). The
## Commonwealth arm below is this file's literal original values,
## unchanged, so its look stays the same; Combine gets a darker, amber-lit,
## gilded feel and Flotilla a darker, warm-rust feel with a teal-tinted
## glow, per docs/FACTIONS.md's Combine/Flotilla sections.
func _apply_faction_palette() -> void:
	var palette: Dictionary = FactionVisuals.backdrop_palette(_faction_id)
	_wall_color = palette["wall"]
	_floor_color = palette["floor"]
	_rib_color = _wall_color
	_light_color = palette["light"]

	match _faction_id:
		LevelCatalog.OLIGARCH_COMBINE:
			_window_tint_color = Color(0.55, 0.42, 0.22, 0.5)
			_ambient_color = Color(0.45, 0.36, 0.24)
			_ambient_energy = 0.5
			_background_color = Color(0.08, 0.06, 0.04)
		LevelCatalog.NOMAD_FLOTILLA:
			_window_tint_color = Color(0.35, 0.55, 0.52, 0.45)
			_ambient_color = Color(0.42, 0.38, 0.34)
			_ambient_energy = 0.55
			_background_color = Color(0.09, 0.08, 0.07)
		_:
			_window_tint_color = Color(0.68, 0.78, 0.86, 0.4)
			_ambient_color = Color(0.88, 0.9, 0.94)
			_ambient_energy = 0.85
			_background_color = Color(0.66, 0.69, 0.74)

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _background_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = _ambient_color
	env.ambient_light_energy = _ambient_energy
	env.glow_enabled = false
	# The actual "trick" for floor reflections: screen-space reflections
	# read the floor's low-roughness material (_floor_material()) and
	# mirror whatever's above it -- the ceiling fixtures/ribs, mainly --
	# instead of the floor just picking up a flat specular highlight. The
	# floor's own two-tone seam was a shadow cascade artifact, not this --
	# see MainHangarDeck.tscn's DirectionalLight3D and the doc comment above.
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	# Atmospheric perspective -- the far end of a 100m room fading gently
	# toward the background color instead of staying pin-sharp all the way
	# back is what actually reads as "far away," the same cue real
	# haze/dust gives depth over distance outdoors, applied indoors here.
	# At this length it also does real work hiding the seam rib/back wall
	# in haze rather than leaving them pin-sharp and obviously far off.
	env.fog_enabled = true
	env.fog_light_color = env.background_color
	env.fog_density = 0.015
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _floor_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _floor_color
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
	_build_back_wall()

	for x_sign in [-1.0, 1.0]:
		var side_wall = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.4, CEILING_HEIGHT, HANGAR_DEPTH_NEAR - HANGAR_DEPTH_FAR),
			"albedo_color": _wall_color,
		})
		side_wall.position = Vector3(x_sign * HANGAR_HALF_WIDTH, CEILING_HEIGHT * 0.5 - 0.1, (HANGAR_DEPTH_NEAR + HANGAR_DEPTH_FAR) * 0.5)
		add_child(side_wall)

## Solid below, one seamless tinted-glass band above -- full width, no
## mullions/frame dividing it into separate panes, starting a bit above
## the wall's own half-height and running to its top edge.
func _build_back_wall() -> void:
	var wall_bottom = -0.1
	var wall_top = WALL_TOP
	var window_bottom = CATWALK_HEIGHT

	var lower = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(HANGAR_HALF_WIDTH * 2.0, window_bottom - wall_bottom, 0.4),
		"albedo_color": _wall_color,
	})
	lower.position = Vector3(0, (wall_bottom + window_bottom) * 0.5, HANGAR_DEPTH_FAR)
	add_child(lower)

	var window := MeshInstance3D.new()
	var window_box := BoxMesh.new()
	window_box.size = Vector3(HANGAR_HALF_WIDTH * 2.0, wall_top - window_bottom, 0.4)
	window.mesh = window_box
	window.material_override = _window_material()
	window.position = Vector3(0, (window_bottom + wall_top) * 0.5, HANGAR_DEPTH_FAR)
	add_child(window)

## Slightly tinted, translucent glass -- low roughness for a glassy
## highlight, alpha well under 1 so it reads as glass, not a solid panel
## the same color as the wall.
func _window_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _window_tint_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.2
	mat.roughness = 0.05
	return mat

func _build_ceiling() -> void:
	var ceiling = SimpleShapes.make_mesh_instance({
		"shape": "box",
		"size": Vector3(HANGAR_HALF_WIDTH * 2.0, 0.3, HANGAR_DEPTH_NEAR - HANGAR_DEPTH_FAR),
		"albedo_color": _wall_color,
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
	mat.albedo_color = _wall_color

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
	mat.albedo_color = _rib_color
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
## wall-to-wall width and reaches full ceiling height -- the real back
## wall (no door -- that's still being redesigned, but it does have a
## window band, see _build_back_wall()) only exists at the very end of
## the room now; see ARCH_Z_POSITIONS for why.
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
				"emission_color": _light_color, "emission_energy": 3.0,
			})
			fixture.position = pos
			add_child(fixture)

			var light = SimpleShapes.make_point_light(_light_color, 1.6, 9.0)
			light.position = Vector3(x_position, CEILING_HEIGHT - 0.5, z_position)
			add_child(light)

## Shared by the stairs/catwalk/door frame -- same flat white as the
## walls, plus a faint self-illumination. Without it these thin, distant
## elements go nearly flat gray in the room's own atmospheric fog (see
## _build_environment(); the haze itself stays -- it's the whole point of
## this room reading as genuinely far away) and lose their edges entirely
## by the time they're ~90-100m from the camera. A small emissive boost
## keeps them legible without making them look like lit fixtures the way
## the much brighter ceiling lights do.
func _architectural_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _wall_color
	mat.emission_enabled = true
	mat.emission = _wall_color
	mat.emission_energy = 0.4
	return mat

## A simple straight staircase against the right wall, ascending from the
## open floor (STAIR_BOTTOM_Z, out where the camera can see it start) up
## to CATWALK_HEIGHT right at the catwalk's front edge (STAIR_TOP_Z). Each
## step is one solid box reaching down to the floor rather than a floating
## tread -- gives the same ascending-block silhouette as a real staircase
## with a fraction of the geometry, and there's no gap to see through.
func _build_staircase() -> void:
	var step_rise = CATWALK_HEIGHT / float(STAIR_STEPS)
	var step_run = STAIR_RUN_LENGTH / float(STAIR_STEPS)
	var mat := _architectural_material()

	for i in range(STAIR_STEPS):
		var top_y = (i + 1) * step_rise
		var z_far = STAIR_BOTTOM_Z - i * step_run
		var z_near = STAIR_BOTTOM_Z - (i + 1) * step_run
		var step := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(STAIR_WIDTH, top_y, z_far - z_near)
		step.mesh = box
		step.material_override = mat
		step.position = Vector3(STAIR_X, top_y * 0.5, (z_far + z_near) * 0.5)
		add_child(step)

## The catwalk platform + two horizontal rails (top and mid-height) along
## its front (room-facing) edge only -- the back edge sits close against
## the glass, so there's nothing to fall off of there. Spans nearly the
## full width (CATWALK_X_LEFT/RIGHT match the ribs' own wall inset) so the
## staircase's landing on the right and the door frame on the left both
## sit within it.
func _build_catwalk() -> void:
	var mat := _architectural_material()
	var center_x = (CATWALK_X_RIGHT + CATWALK_X_LEFT) * 0.5
	var span_x = CATWALK_X_RIGHT - CATWALK_X_LEFT

	var platform := MeshInstance3D.new()
	var platform_box := BoxMesh.new()
	platform_box.size = Vector3(span_x, CATWALK_THICKNESS, CATWALK_Z_FRONT - CATWALK_Z_BACK)
	platform.mesh = platform_box
	platform.material_override = mat
	platform.position = Vector3(center_x, CATWALK_HEIGHT - CATWALK_THICKNESS * 0.5, (CATWALK_Z_FRONT + CATWALK_Z_BACK) * 0.5)
	add_child(platform)

	for rail_height in [CATWALK_RAIL_MID_HEIGHT, CATWALK_RAIL_HEIGHT]:
		var rail := MeshInstance3D.new()
		var rail_box := BoxMesh.new()
		rail_box.size = Vector3(span_x, CATWALK_RAIL_THICKNESS, CATWALK_RAIL_THICKNESS)
		rail.mesh = rail_box
		rail.material_override = mat
		rail.position = Vector3(center_x, CATWALK_HEIGHT + rail_height, CATWALK_Z_FRONT)
		add_child(rail)

	var post_count = 8
	for i in range(post_count + 1):
		var post_x = lerp(CATWALK_X_LEFT, CATWALK_X_RIGHT, float(i) / float(post_count))
		var post := MeshInstance3D.new()
		var post_box := BoxMesh.new()
		post_box.size = Vector3(CATWALK_POST_THICKNESS, CATWALK_RAIL_HEIGHT, CATWALK_POST_THICKNESS)
		post.mesh = post_box
		post.material_override = mat
		post.position = Vector3(post_x, CATWALK_HEIGHT + CATWALK_RAIL_HEIGHT * 0.5, CATWALK_Z_FRONT)
		add_child(post)

## A plain white rectangular frame (no separate door panel or cut-out
## opening) marking a glass door's location, floor-to-ceiling (DOOR_HEIGHT
## = WALL_TOP - CATWALK_HEIGHT) and flush against the left wall's own
## inner face -- the window pane behind it stays one seamless piece, per
## the "simple glass door, just show where it is" request. Flush-left
## placement means the left jamb sits right on the wall itself, so only
## the right jamb, lintel, and threshold read as a distinct frame from
## inside the room -- the same shape a real door built into the corner of
## a room would have.
func _build_door_frame() -> void:
	var mat := _architectural_material()
	var door_z = HANGAR_DEPTH_FAR + 0.05  # just proud of the glass, avoids z-fighting
	var half_w = DOOR_WIDTH * 0.5
	var bottom_y = CATWALK_HEIGHT
	var top_y = CATWALK_HEIGHT + DOOR_HEIGHT

	for x_offset in [-half_w, half_w]:
		var jamb := MeshInstance3D.new()
		var jamb_box := BoxMesh.new()
		jamb_box.size = Vector3(DOOR_FRAME_THICKNESS, DOOR_HEIGHT, DOOR_FRAME_THICKNESS)
		jamb.mesh = jamb_box
		jamb.material_override = mat
		jamb.position = Vector3(DOOR_X + x_offset, (bottom_y + top_y) * 0.5, door_z)
		add_child(jamb)

	for y in [bottom_y, top_y]:
		var bar := MeshInstance3D.new()
		var bar_box := BoxMesh.new()
		bar_box.size = Vector3(DOOR_WIDTH + DOOR_FRAME_THICKNESS, DOOR_FRAME_THICKNESS, DOOR_FRAME_THICKNESS)
		bar.mesh = bar_box
		bar.material_override = mat
		bar.position = Vector3(DOOR_X, y, door_z)
		add_child(bar)
