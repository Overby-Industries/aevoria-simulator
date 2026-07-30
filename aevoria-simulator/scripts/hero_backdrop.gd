extends Node3D

## Decorative 3D backdrop for the game's front door (LevelSelect) -- a
## slowly-rotating torus+cone silhouette plus a starfield, echoing the
## web app's Three.js hero object (web/app/page.tsx: a ring around a
## tapered cylinder, drifting in a starfield) so the game's own front
## door reads as the same product. Purely scene dressing, no gameplay
## meaning. Every HUD panel in LevelSelect/AccountHud is built under a
## CanvasLayer, which always composites on top of 3D content in the same
## viewport -- so this just needs to exist somewhere in the tree with a
## `current` Camera3D; it doesn't need to be a scene child of anything
## UI-related. See glass_panel.gd/frosted_glass_panel.gdshader for the
## other half of this: the panels blur *this* scene, not a flat color.

const Starfield = preload("res://scripts/starfield.gd")

const COLOR_HULL = Color("1c2a45")
const COLOR_AMBER = Color("ff9f1c")

var _rotator: Node3D

func _ready() -> void:
	Starfield.spawn(self)
	_build_camera()
	_build_lights()
	_build_object()

func _process(delta: float) -> void:
	if _rotator:
		_rotator.rotate_y(delta * 0.15)
		_rotator.rotate_x(delta * 0.04)

func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(5.0, 2.5, 12.0)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

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
