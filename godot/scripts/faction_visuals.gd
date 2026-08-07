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

## Shared room/interior mood per faction, for any level backdrop built with
## a fixed camera looking into a space (hangar_backdrop.gd's approach,
## docs/GRAPHICS_GUIDE.md's "System 2" worked example) -- not just the
## tactical-table markers above. One canonical palette so every faction-
## aware backdrop across the game (governance chambers, the Combine
## boardroom, the Flotilla's drift ship, the shared hangar/bay interiors)
## reads as the same three factions instead of each level script picking
## its own hex colors. See docs/FACTIONS.md for the reasoning behind each
## look:
##   - Commonwealth: chartered, orderly, CUR-compliant -- clean and bright
##     (the existing white/gold hangar interior is this faction's look).
##   - Combine: corporate-captured sovereignty, concentrated capital --
##     dark, gilded, opulent rather than clean; wealth without the
##     Commonwealth's institutional openness.
##   - Flotilla: nomadic, no home base, outside both governments' reach --
##     scavenged/patchwork, warm rust and worn metal, not gleaming.
## Keys: accent (the same hue as territory_color, for trim/UI/emissive
## highlights), wall/floor (base structural surface colors), light (the
## interior's key-light color), fog (a near-black WorldEnvironment
## background for any scene that also needs a window/gap out to space).
static func backdrop_palette(faction_id: String) -> Dictionary:
	match faction_id:
		LevelCatalog.OLIGARCH_COMBINE:
			return {
				"accent": Color("ffb020"),
				"wall": Color("2a241a"),
				"floor": Color("1c1712"),
				"light": Color(1.0, 0.85, 0.6),
				"fog": Color(0.014, 0.01, 0.004),
			}
		LevelCatalog.NOMAD_FLOTILLA:
			return {
				"accent": Color("2fd9c4"),
				"wall": Color("3a352e"),
				"floor": Color("2a2620"),
				"light": Color(0.85, 0.95, 0.9),
				"fog": Color(0.006, 0.009, 0.009),
			}
		_:
			return {
				"accent": Color("3d7bff"),
				"wall": Color("eceef1"),
				"floor": Color("eceef1"),
				"light": Color(1.0, 0.98, 0.94),
				"fog": Color(0.006, 0.007, 0.012),
			}
