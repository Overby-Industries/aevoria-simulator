extends RefCounted

## Shared per-faction marker look, promoted out of situation_table.gd so
## situation_view.gd (the new solar-system table) can draw the same
## station silhouettes without duplicating the shape table. See
## situation_table.gd's original comment for why these are approximations
## of each faction's real Assembly Bay hull (part_catalog.gd) rather than
## literal reproductions -- SimpleShapes only knows box/cylinder/capsule/
## sphere, not the C++-side PartAssembler's composite hulls.

const LevelCatalog = preload("res://scripts/level_catalog.gd")

static func ship_marker_spec(faction_id: String) -> Dictionary:
	match faction_id:
		LevelCatalog.OLIGARCH_COMBINE:
			return {"shape": "cylinder", "radius": 0.28, "height": 0.85, "color": "b8862b"}
		LevelCatalog.NOMAD_FLOTILLA:
			return {"shape": "box", "size": Vector3(0.45, 0.35, 1.0), "color": "c9a227"}
		_:
			return {"shape": "capsule", "radius": 0.22, "height": 0.9, "color": "ffffff"}

## Distinct from ship_marker_spec's colors on purpose -- territory shading
## needs to read clearly against the sun/planets/starfield at a glance,
## which the ship-marker hues (tuned to match each hull's own highlight
## color) don't guarantee. Picked for maximum separation against a near-
## black background: Commonwealth blue, Combine amber, Flotilla teal.
static func territory_color(faction_id: String) -> Color:
	match faction_id:
		LevelCatalog.OLIGARCH_COMBINE:
			return Color("ffb020")
		LevelCatalog.NOMAD_FLOTILLA:
			return Color("2fd9c4")
		_:
			return Color("3d7bff")
