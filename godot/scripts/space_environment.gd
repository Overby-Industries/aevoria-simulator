extends RefCounted

## The one near-black WorldEnvironment every deep-space scene should be
## using -- promoted out of hero_backdrop.gd, which had it first (the
## lobby's backdrop), after situation_table.gd and situation_view.gd were
## both found rendering against Godot's default grey/blue clear color:
## neither ever built a WorldEnvironment of its own, so they silently fell
## back to the engine default instead of the game's actual "near-black
## space" look. Any new space-table scene should call this in _ready()
## too instead of re-deriving these constants.

static func build() -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Near-black, not pure black -- a hair of blue keeps it from reading
	# as a broken/transparent viewport.
	env.background_color = Color(0.006, 0.007, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.04, 0.045, 0.06)
	env.ambient_light_energy = 0.5
	# Glow/bloom is what makes emissive props (the lobby's sun, mined
	# asteroids/comets, this table's own sun) read as a glare instead of a
	# flat bright shape.
	env.glow_enabled = true
	env.glow_intensity = 1.6
	env.glow_bloom = 0.35
	env.glow_hdr_threshold = 1.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	return world_env
