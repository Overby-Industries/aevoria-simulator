extends RefCounted

## Builds a random field of mineable resource nodes -- asteroids (PGM) and
## comets (H2O), per the user's sketch. Deliberately basic: a node is a
## Dictionary (id/display_name/node_type/resource_name/yield_amount/
## position/texture_recipe), not a Resource subclass -- there's no need
## for save/load or editor-inspector support here the way PartDefinition
## needs it, just enough shape for asteroid_field.gd to spawn and mine.
##
## No class_name, matching part_catalog.gd / level_catalog.gd's
## preload()-only convention.

const ASTEROID_RECIPE = {
	"seed": 0, "frequency": 0.12,
	"dark_color": Color("2a2a28"), "base_color": Color("8a8a86"), "highlight_color": Color("ffd54a"),
}
const COMET_RECIPE = {
	"seed": 0, "frequency": 0.10,
	"dark_color": Color("0a1830"), "base_color": Color("2a6fd6"), "highlight_color": Color("dff3ff"),
}
const NICKEL_RECIPE = {
	"seed": 0, "frequency": 0.16,
	"dark_color": Color("2e3336"), "base_color": Color("8f9aa0"), "highlight_color": Color("d8e2e6"),
}
const REGOLITH_RECIPE = {
	"seed": 0, "frequency": 0.09,
	"dark_color": Color("3a2f22"), "base_color": Color("a68a5f"), "highlight_color": Color("e8d3a0"),
}

static func build_field(asteroid_count: int, comet_count: int, nickel_count: int = 0, regolith_count: int = 0) -> Array:
	var nodes: Array = []
	for i in range(asteroid_count):
		var recipe = ASTEROID_RECIPE.duplicate()
		recipe["seed"] = randi() % 100000
		nodes.append({
			"id": "asteroid_%d" % i,
			"display_name": "Asteroid A%d" % (i + 1),
			"node_type": "asteroid",
			"resource_name": "PGM",
			"yield_amount": randf_range(8.0, 20.0),
			"position": _random_position(),
			"texture_recipe": recipe,
		})
	for i in range(comet_count):
		var recipe = COMET_RECIPE.duplicate()
		recipe["seed"] = randi() % 100000
		nodes.append({
			"id": "comet_%d" % i,
			"display_name": "Comet C%d" % (i + 1),
			"node_type": "comet",
			"resource_name": "H2O",
			"yield_amount": randf_range(10.0, 30.0),
			"position": _random_position(),
			"texture_recipe": recipe,
		})
	for i in range(nickel_count):
		var recipe = NICKEL_RECIPE.duplicate()
		recipe["seed"] = randi() % 100000
		nodes.append({
			"id": "nickel_%d" % i,
			"display_name": "Nickel Deposit N%d" % (i + 1),
			"node_type": "nickel_ore",
			"resource_name": "Nickel",
			"yield_amount": randf_range(6.0, 16.0),
			"position": _random_position(),
			"texture_recipe": recipe,
		})
	for i in range(regolith_count):
		var recipe = REGOLITH_RECIPE.duplicate()
		recipe["seed"] = randi() % 100000
		nodes.append({
			"id": "regolith_%d" % i,
			"display_name": "Regolith Field R%d" % (i + 1),
			"node_type": "regolith_deposit",
			"resource_name": "Regolith",
			"yield_amount": randf_range(10.0, 24.0),
			"position": _random_position(),
			"texture_recipe": recipe,
		})
	return nodes

static func _random_position() -> Vector3:
	return Vector3(
		randf_range(-8.0, 8.0),
		randf_range(-2.0, 2.0),
		randf_range(-8.0, 8.0),
	)
