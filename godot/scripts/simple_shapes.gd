extends RefCounted

## Shared primitive-mesh + point-light helpers for hand-built level
## scenery (asteroid nodes, grow bays, furnaces, tanks, and any future
## props like habitat furniture). Factored out after the same
## "MeshInstance3D + StandardMaterial3D + optional OmniLight3D"
## boilerplate showed up in four level scripts in a row. See
## docs/GRAPHICS_GUIDE.md for the full reference and a worked example
## (the desk in GreenhouseBay).
##
## Deliberately separate from PartDefinition/PartAssembler (src/part_*):
## that system is for player-assembled, socket-based ship/habitat parts
## with stats and categories, and requires a C++ rebuild to add a new
## shape. This one is for static scene dressing a level script just wants
## to drop in and forget -- no sockets, no stats, pure GDScript, no
## rebuild ever needed. Shape vocabulary intentionally matches
## PartDefinition.mesh_recipe's ("box"/"cylinder"/"capsule") plus
## "sphere" (which only this system needs so far), so switching a prop
## between the two systems later never means relearning a shape name.
##
## No class_name, matching every other *_catalog.gd/*_builder.gd file in
## this codebase -- consumers preload() this instead of relying on the
## editor's global class_name cache, which isn't reliably warm headless.

## Builds one MeshInstance3D from a small shape description. Shape keys:
##   {"shape": "box", "size": Vector3}
##   {"shape": "cylinder"|"capsule", "radius": float, "height": float}
##   {"shape": "sphere", "radius": float, "radial_segments": int, "rings": int}
## Plus optional appearance keys, valid with any shape:
##   "albedo_color": Color        -- base surface color (default white)
##   "albedo_texture": Texture2D  -- overrides albedo_color if given
##                                    (e.g. a ProceduralArtGenerator texture)
##   "emission_color": Color      -- omit entirely for a non-glowing prop
##   "emission_energy": float     -- multiplier, only used if emission_color is set (default 1.0)
static func make_mesh_instance(recipe: Dictionary) -> MeshInstance3D:
	var shape: String = recipe.get("shape", "box")
	var mesh: Mesh

	if shape == "cylinder":
		var cyl := CylinderMesh.new()
		var radius: float = float(recipe.get("radius", 0.5))
		cyl.top_radius = radius
		cyl.bottom_radius = radius
		cyl.height = float(recipe.get("height", 1.0))
		mesh = cyl
	elif shape == "capsule":
		var cap := CapsuleMesh.new()
		cap.radius = float(recipe.get("radius", 0.5))
		cap.height = float(recipe.get("height", 1.0))
		mesh = cap
	elif shape == "sphere":
		var sph := SphereMesh.new()
		var radius: float = float(recipe.get("radius", 0.5))
		sph.radius = radius
		sph.height = radius * 2.0
		sph.radial_segments = int(recipe.get("radial_segments", 16))
		sph.rings = int(recipe.get("rings", 8))
		mesh = sph
	else:
		var box := BoxMesh.new()
		box.size = recipe.get("size", Vector3(1.0, 1.0, 1.0))
		mesh = box

	var instance := MeshInstance3D.new()
	instance.mesh = mesh

	var material := StandardMaterial3D.new()
	if recipe.has("albedo_texture"):
		material.albedo_texture = recipe["albedo_texture"]
	else:
		material.albedo_color = recipe.get("albedo_color", Color.WHITE)
	if recipe.has("emission_color"):
		material.emission_enabled = true
		material.emission = recipe["emission_color"]
		material.emission_energy_multiplier = float(recipe.get("emission_energy", 1.0))
	instance.material_override = material

	return instance

## A point light sized to match a glowing prop built above -- the two are
## almost always added together (every _spawn_* function this replaced
## did exactly that), so this saves re-typing the same 4 lines each time.
static func make_point_light(color: Color, energy: float = 1.0, light_range: float = 4.0) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	return light
