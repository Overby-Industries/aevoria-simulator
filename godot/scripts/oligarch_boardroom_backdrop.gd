extends Node3D

## Decorative 3D backdrop for Boardroom Capture (OligarchBoardroom.tscn) --
## the Combine's own counterpart to hangar_backdrop.gd's Commonwealth
## hangar interior. oligarch_boardroom.gd `extends Node`, not `extends
## Node3D`, and has no Camera3D of its own, so this standalone Node3D
## builds everything it needs itself (its own Camera3D marked `current`,
## its own WorldEnvironment, its own lights) rather than depending on
## anything in OligarchBoardroom.tscn -- a Node3D camera under a plain-Node
## ancestor still resolves a valid world transform, since only Node3D
## ancestors contribute to that transform in the first place. See
## docs/GRAPHICS_GUIDE.md System 2 and its "Main Hangar Deck" worked
## example for the general technique this follows.
##
## A literal corporate boardroom: a long table as the one clear centerpiece
## prop, a handful of chairs, an enclosing room, and a tinted window at the
## far end looking out over a few distant Combine industrial silhouettes.
## Colors come from FactionVisuals.backdrop_palette(OLIGARCH_COMBINE) --
## dark gunmetal-bronze walls/floor, amber accent/light -- per
## docs/FACTIONS.md: the Combine is corporate-captured sovereignty,
## concentrated capital running its own government, opulent rather than
## clean. Colder and more calculating than the Commonwealth hangar's
## bright white-and-gold: near-black background, warm pools of amber
## pendant light over the table rather than an evenly-lit room.
##
## Deliberately basic -- a first pass ready to be refined later, not a
## final art pass. Kept intentionally low on prop count/detail per
## docs/GRAPHICS_GUIDE.md's guidance for level dressing like this.
##
## The scene's own choice/round panel uses the opaque "AevoriaPanel" theme
## regardless of this backdrop (see oligarch_boardroom.gd's _build_ui()),
## so it isn't affected by how dark this background is -- but LevelChrome's
## shared corner panels (account/console/VCI/cycle) use the default dark
## frosted-glass theme (light_theme defaults to false, not flipped here),
## so this backdrop stays on the dark/moody side using the palette's own
## "fog" color, not a bright one, to keep those panels readable.
##
## Camera never moves; every position below is hand-placed against the
## fixed camera transform in _build_camera(), same "camera never moves,
## geometry is placed to fit it" convention as hero_backdrop.gd/
## hangar_backdrop.gd.

const SimpleShapes = preload("res://scripts/simple_shapes.gd")
const FactionVisuals = preload("res://scripts/faction_visuals.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

# Not a const -- GDScript const initializers must be constant expressions,
# and this calls a static function, so it has to be a plain var (still
# only ever evaluated once, at construction).
var _palette: Dictionary = FactionVisuals.backdrop_palette(LevelCatalog.OLIGARCH_COMBINE)

# 1 unit = 1 meter, this codebase's global scale convention (see
# docs/GRAPHICS_GUIDE.md). A modest room, not the hangar's scale -- this is
# one boardroom, not a ship bay.
const ROOM_HALF_WIDTH := 6.0
const ROOM_NEAR_Z := 7.0    # toward the camera
const ROOM_FAR_Z := -14.0   # the back wall/window
const CEILING_HEIGHT := 6.0

# Back wall window band -- same convention as hangar_backdrop.gd's
# WINDOW_BOTTOM_FRACTION: fraction of the wall's own height (0 = floor,
# 1 = ceiling) where the glass starts; it always runs from there to the
# top. Bigger than the hangar's, since this is meant to read as a
# prestige view out over Combine holdings, not just a light source.
const WINDOW_BOTTOM_FRACTION := 0.4

# The table -- the one clear centerpiece prop, per the brief. Long axis
# along Z, roughly centered in the room so there's open floor near the
# camera and a clear sightline to the window beyond the far end.
const TABLE_LENGTH := 9.0
const TABLE_WIDTH := 2.6
const TABLE_TOP_THICKNESS := 0.15
const TABLE_TOP_Y := 0.78
const TABLE_CENTER_Z := -3.0
const TABLE_MATERIAL_COLOR := Color("140f09")  # near-black lacquered wood, darker than the walls so the table still reads as the centerpiece against them

# A handful of chairs -- two per side plus one head chair at the far end,
# not a full boardroom's worth. Simple two-box seat+back per chair, same
# "copy the desk in Greenhouse Bay" spirit docs/GRAPHICS_GUIDE.md
# recommends for room furniture.
const CHAIR_Z_OFFSETS := [-2.5, 2.5]  # relative to TABLE_CENTER_Z
const CHAIR_SIDE_GAP := 0.7           # gap between the table edge and a side chair's seat center
const CHAIR_HEAD_GAP := 0.8           # gap between the table's far end and the head chair's seat center
const CHAIR_SEAT_COLOR := Color("1a140d")

# Pendant lights over the table -- warm pools of amber light rather than a
# flat, evenly-lit room, per the "colder and more calculating" brief.
const PENDANT_Z_OFFSETS := [-2.5, 0.0, 2.5]  # relative to TABLE_CENTER_Z

# A few distant silhouettes beyond the back window, standing in for
# Combine industrial holdings -- basic cylinder shapes, faded by fog/tint
# rather than modeled in any detail.
const TOWER_SPECS := [
	{"x": -4.0, "z_behind": -6.0, "radius": 0.9, "height": 7.0},
	{"x": 1.5, "z_behind": -10.0, "radius": 0.7, "height": 9.0},
	{"x": 4.5, "z_behind": -5.0, "radius": 1.1, "height": 5.5},
]

func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_lights()
	_build_floor()
	_build_walls()
	_build_ceiling()
	_build_window_view()
	_build_table()
	_build_chairs()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _palette["fog"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = _palette["wall"]
	env.ambient_light_energy = 0.55
	# A little glow on the amber accents/pendant lights -- opulent rather
	# than clean, per docs/FACTIONS.md, unlike hangar_backdrop.gd's
	# deliberately glow-free fluorescent fixtures.
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 1.0
	# Compact room, so a higher density than the hangar's 100m-room value
	# is what actually gives the distant towers beyond the window any
	# haze/fade over their much shorter distance.
	env.fog_enabled = true
	env.fog_light_color = _palette["fog"]
	env.fog_density = 0.035
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(4.2, 2.6, 6.0)
	camera.fov = 65.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.1, -6.0), Vector3.UP)

func _build_lights() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45.0, -20.0, 0.0)
	key.light_color = _palette["light"]
	key.light_energy = 0.7
	key.shadow_enabled = false
	add_child(key)

	# A soft amber rim light near the table, echoing hero_backdrop.gd's
	# rim_light -- the deliberate warm highlight in an otherwise dark room.
	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(-3.0, 1.6, -2.0)
	rim_light.light_color = _palette["accent"]
	rim_light.light_energy = 3.0
	rim_light.omni_range = 10.0
	add_child(rim_light)

	for z_offset in PENDANT_Z_OFFSETS:
		var z = TABLE_CENTER_Z + z_offset
		var fixture = SimpleShapes.make_mesh_instance({
			"shape": "cylinder", "radius": 0.18, "height": 0.12,
			"albedo_color": _palette["wall"],
			"emission_color": _palette["light"], "emission_energy": 2.0,
		})
		fixture.position = Vector3(0, CEILING_HEIGHT - 1.4, z)
		add_child(fixture)

		var light = SimpleShapes.make_point_light(_palette["light"], 1.4, 6.0)
		light.position = Vector3(0, CEILING_HEIGHT - 1.6, z)
		add_child(light)

func _floor_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _palette["floor"]
	mat.metallic = 0.5
	mat.roughness = 0.3
	return mat

func _build_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(ROOM_HALF_WIDTH * 2.0, 0.2, ROOM_NEAR_Z - ROOM_FAR_Z)
	floor_mesh.mesh = box
	floor_mesh.position = Vector3(0, -0.1, (ROOM_NEAR_Z + ROOM_FAR_Z) * 0.5)
	floor_mesh.material_override = _floor_material()
	add_child(floor_mesh)

func _build_walls() -> void:
	_build_back_wall()

	for x_sign in [-1.0, 1.0]:
		var side_wall = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.4, CEILING_HEIGHT, ROOM_NEAR_Z - ROOM_FAR_Z),
			"albedo_color": _palette["wall"],
		})
		side_wall.position = Vector3(x_sign * ROOM_HALF_WIDTH, CEILING_HEIGHT * 0.5 - 0.1, (ROOM_NEAR_Z + ROOM_FAR_Z) * 0.5)
		add_child(side_wall)

## Solid below, one tinted-amber-glass band above, same layout as
## hangar_backdrop.gd's back wall -- except the "view" behind this glass is
## Combine industrial silhouettes (_build_window_view()), not open space.
func _build_back_wall() -> void:
	var wall_bottom = -0.1
	var wall_top = CEILING_HEIGHT - 0.1
	var window_bottom = CEILING_HEIGHT * WINDOW_BOTTOM_FRACTION

	var lower = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(ROOM_HALF_WIDTH * 2.0, window_bottom - wall_bottom, 0.4),
		"albedo_color": _palette["wall"],
	})
	lower.position = Vector3(0, (wall_bottom + window_bottom) * 0.5, ROOM_FAR_Z)
	add_child(lower)

	var window := MeshInstance3D.new()
	var window_box := BoxMesh.new()
	window_box.size = Vector3(ROOM_HALF_WIDTH * 2.0, wall_top - window_bottom, 0.4)
	window.mesh = window_box
	window.material_override = _window_material()
	window.position = Vector3(0, (window_bottom + wall_top) * 0.5, ROOM_FAR_Z)
	add_child(window)

## Amber-tinted glass -- the accent color at low alpha, not a neutral tint,
## so the view beyond reads as warmed by the same palette as the room.
func _window_material() -> StandardMaterial3D:
	var accent: Color = _palette["accent"]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(accent.r, accent.g, accent.b, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.2
	mat.roughness = 0.05
	return mat

func _build_ceiling() -> void:
	var ceiling = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(ROOM_HALF_WIDTH * 2.0, 0.3, ROOM_NEAR_Z - ROOM_FAR_Z),
		"albedo_color": _palette["wall"],
	})
	ceiling.position = Vector3(0, CEILING_HEIGHT, (ROOM_NEAR_Z + ROOM_FAR_Z) * 0.5)
	add_child(ceiling)

## A few basic cylinder silhouettes standing in for distant Combine
## industrial holdings, placed just beyond the back wall so they only show
## through the window band above -- faded by both the window's own tint
## and the room's fog (see _build_environment()), so no detail beyond a
## plain emissive silhouette is needed at this distance.
func _build_window_view() -> void:
	for spec in TOWER_SPECS:
		var tower = SimpleShapes.make_mesh_instance({
			"shape": "cylinder", "radius": spec["radius"], "height": spec["height"],
			"albedo_color": _palette["wall"],
			"emission_color": _palette["accent"], "emission_energy": 0.7,
		})
		tower.position = Vector3(spec["x"], spec["height"] * 0.5 - 0.1, ROOM_FAR_Z + spec["z_behind"])
		add_child(tower)

func _table_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = TABLE_MATERIAL_COLOR
	mat.metallic = 0.25
	mat.roughness = 0.2
	return mat

## The boardroom table -- the one clear centerpiece prop the brief calls
## for. A plain tabletop + two support blocks (same two-box spirit as the
## Greenhouse Bay desk in docs/GRAPHICS_GUIDE.md's worked example) plus a
## thin gilded-amber trim strip along each long edge, since "gilded" is
## part of the Combine's look per docs/FACTIONS.md/the level brief.
func _build_table() -> void:
	var top := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(TABLE_WIDTH, TABLE_TOP_THICKNESS, TABLE_LENGTH)
	top.mesh = box
	top.material_override = _table_material()
	top.position = Vector3(0, TABLE_TOP_Y, TABLE_CENTER_Z)
	add_child(top)

	var support_height = TABLE_TOP_Y - 0.05
	for z_offset in [-TABLE_LENGTH * 0.32, TABLE_LENGTH * 0.32]:
		var support = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(TABLE_WIDTH * 0.6, support_height, 0.4),
			"albedo_color": _palette["wall"],
		})
		support.position = Vector3(0, support_height * 0.5, TABLE_CENTER_Z + z_offset)
		add_child(support)

	for x_sign in [-1.0, 1.0]:
		var trim = SimpleShapes.make_mesh_instance({
			"shape": "box", "size": Vector3(0.05, 0.04, TABLE_LENGTH),
			"albedo_color": _palette["accent"],
			"emission_color": _palette["accent"], "emission_energy": 0.6,
		})
		trim.position = Vector3(x_sign * TABLE_WIDTH * 0.5, TABLE_TOP_Y + TABLE_TOP_THICKNESS * 0.5 + 0.02, TABLE_CENTER_Z)
		add_child(trim)

func _build_chairs() -> void:
	for z_offset in CHAIR_Z_OFFSETS:
		for x_sign in [-1.0, 1.0]:
			var pos = Vector3(x_sign * (TABLE_WIDTH * 0.5 + CHAIR_SIDE_GAP), 0.0, TABLE_CENTER_Z + z_offset)
			_build_chair(pos, Vector3(x_sign, 0.0, 0.0))

	# Head chair at the far end, facing back up the table toward the camera.
	var head_pos = Vector3(0.0, 0.0, TABLE_CENTER_Z - TABLE_LENGTH * 0.5 - CHAIR_HEAD_GAP)
	_build_chair(head_pos, Vector3(0.0, 0.0, -1.0))

## One chair = one seat box + one backrest box, offset from the seat along
## `back_dir` (pointing away from the table) -- same "two boxes" simplicity
## as the table's own support blocks.
func _build_chair(pos: Vector3, back_dir: Vector3) -> void:
	var seat = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(0.5, 0.42, 0.5),
		"albedo_color": CHAIR_SEAT_COLOR,
	})
	seat.position = pos + Vector3(0, 0.21, 0)
	add_child(seat)

	var back = SimpleShapes.make_mesh_instance({
		"shape": "box", "size": Vector3(0.5, 0.55, 0.08),
		"albedo_color": CHAIR_SEAT_COLOR,
	})
	back.position = pos + Vector3(0, 0.5, 0) + back_dir * 0.29
	add_child(back)
