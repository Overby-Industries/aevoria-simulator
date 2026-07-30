extends RefCounted

## Auto-frames a Camera3D on one or more Node3D subjects by computing their
## actual combined mesh bounding box, rather than relying on a hand-picked
## camera distance baked into a .tscn. Needed once ship parts moved to
## real-world scale (see part_catalog.gd) -- a single fixed distance can't
## work for both a 14m mining hull and a 42m industrial hauler.

static func frame(camera: Camera3D, subjects: Array, direction: Vector3 = Vector3(0, 0.5, 1), margin: float = 1.3) -> void:
	var combined := AABB()
	var has_bounds := false
	for subject in subjects:
		for mesh_instance in _collect_mesh_instances(subject):
			if mesh_instance.mesh == null:
				continue
			var world_aabb: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
			if not has_bounds:
				combined = world_aabb
				has_bounds = true
			else:
				combined = combined.merge(world_aabb)

	var center = combined.get_center() if has_bounds else Vector3.ZERO
	# .length() (the diagonal) rather than the longest single axis --
	# generous on purpose so a ship viewed from an angle doesn't clip.
	var extent = combined.size.length() if has_bounds else 20.0

	camera.global_position = center + direction.normalized() * extent * margin
	camera.look_at(center, Vector3.UP)

static func _collect_mesh_instances(node: Node) -> Array:
	var result: Array = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_collect_mesh_instances(child))
	return result
