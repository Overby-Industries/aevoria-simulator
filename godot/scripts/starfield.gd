extends RefCounted

## A static field of tiny points scattered in a big sphere around the
## camera -- the game's answer to the web app's starry Three.js hero
## background (see web/app/page.tsx). One GPUParticles3D, zero velocity,
## a long lifetime/preprocess so the field is fully "seeded" the instant
## the scene loads rather than fading in. Mirrors the
## GPUParticles3D+ParticleProcessMaterial pattern already used for the
## ship exhaust effect in assembly_bay.gd._spawn_exhaust_effect().

static func spawn(parent: Node3D, radius: float = 90.0) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 700
	particles.lifetime = 60.0
	particles.preprocess = 60.0
	particles.emitting = true
	particles.visibility_aabb = AABB(Vector3(-radius, -radius, -radius), Vector3(radius, radius, radius) * 2.0)

	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	mesh.radial_segments = 4
	mesh.rings = 2
	particles.draw_pass_1 = mesh

	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	process_material.emission_sphere_radius = radius
	process_material.direction = Vector3.ZERO
	process_material.spread = 0.0
	process_material.gravity = Vector3.ZERO
	process_material.initial_velocity_min = 0.0
	process_material.initial_velocity_max = 0.0
	process_material.scale_min = 0.6
	process_material.scale_max = 2.2
	process_material.color = Color(0.9, 0.94, 1.0)
	particles.process_material = process_material

	parent.add_child(particles)
	return particles
