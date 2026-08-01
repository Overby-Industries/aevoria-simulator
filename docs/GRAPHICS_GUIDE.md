# Graphics Guide: procedural art, ship parts, and level props

Aevoria's visuals are entirely code-generated — no imported 3D models, no
texture files. This is deliberate: it means anyone who can edit a GDScript
dictionary can change the look of a ship, a resource node, or a room prop,
without a modeling tool in the loop. This doc explains the three systems
that make that true, and — the important part — **which changes need a C++
rebuild and which don't.**

## The one thing to remember: data vs. code

| You want to... | Where | Rebuild needed? |
|---|---|---|
| Resize/reshape an *existing* ship part, prop, or resource node | Edit a `mesh_recipe` / shape dictionary in a `.gd` file | **No** |
| Change a color, skin, or emissive glow | Edit a dictionary in a `.gd` file | **No** |
| Move a prop, add another copy of an existing prop | Edit/add a few lines in a level's `.gd` script | **No** |
| Add a genuinely new *shape* (not achievable by changing numbers on box/cylinder/capsule/sphere) | Add a new branch in `src/part_definition.cpp` (C++) | **Yes** |

The overwhelming majority of "make the SSTO's nose longer" / "make the
furnace glow orange instead" / "move the desk two units left" style changes
are the first four rows — plain data edits, no build step, just relaunch
Godot (or hot-reload in the editor).

## System 1: Ship/habitat parts (`PartDefinition`, C++)

Used for anything built through the Assembly Bay's kit-bashing system —
hulls, thrusters, drill arms, habitat rings, and so on
(`aevoria-simulator/scripts/part_catalog.gd` is the catalog; `src/part_definition.{h,cpp}`
is the C++ that turns a `mesh_recipe` dictionary into an actual mesh).

### Existing shapes and their `mesh_recipe` keys

**`"box"`**
```gdscript
{"shape": "box", "size": Vector3(1.0, 1.0, 1.0)}
```

**`"cylinder"`**
```gdscript
{"shape": "cylinder", "radius": 0.5, "height": 1.0}
```

**`"capsule"`**
```gdscript
{"shape": "capsule", "radius": 0.5, "height": 1.0}
```

**`"winged_fuselage"`** — the SSTO hull's shape. A capsule body + a tapered
nose cone + a mirrored pair of swept delta wings, all in one composite part.
```gdscript
{
    "shape": "winged_fuselage",
    "radius": 2.7,              # body radius (meters)
    "height": 36.58,            # body length -- 120ft, the capsule's long axis is Y
    "nose_length": 4.5,         # how far the nose cone extends past the body
    "nose_tip_radius": 0.15,    # ~0 = sharp point; bigger = a blunter nose
    "wing_span": 15.24,         # how far each wing extends from the centerline -- half of the 100ft total wingspan
    "wing_root_chord": 12.0,    # length of the wing where it meets the fuselage
    "wing_tip_sweep": 12.7,     # how far back the wingtip is swept vs. the root
    "wing_thickness": 0.6,      # wing thickness (keep this small relative to chord -- it's a wedge, not a slab)
    "wing_y_offset": -3.05,     # where along the body the wings attach (0 = center, negative = toward the tail)
}
```
All nine keys are plain floats — this is the one to reach for if you want to
change the SSTO's proportions yourself (`ssto_hull_helga` in
`part_catalog.gd`). **No rebuild needed** — this whole shape is driven by
data, even though the shape-*builder* itself is C++.

**Scale convention: 1 Godot unit = 1 meter.** Every hull and accessory in
`part_catalog.gd` is sized to real-world aerospace proportions (Helga's
36.58m/30.48m fuselage/wingspan above is the anchor the rest of the catalog
is sized against). If you add a new part, size it in meters consistently
with the rest of the catalog rather than picking an arbitrary small number
— and if it's a root hull meant to carry other parts, remember the camera
in `assembly_bay.gd`/`parts-demo.gd` auto-frames on the assembled ship's
actual bounding box (`camera_framing.gd`), so an unrealistically large or
tiny part will visibly throw off the framing rather than silently working.

### Where the actual ship definitions live

`aevoria-simulator/scripts/part_catalog.gd`, `build_demo_catalog()`. Each
part is a `PartDefinition` with `mesh_recipe` (shape, above), `sockets`
(named attachment points other parts plug into), `stats` (mass/cargo/etc.,
summed by `PartAssembler`), and `faction_id` (empty = every faction can build
it; a faction id like `LevelCatalog.AEVORIA_COMMONWEALTH` restricts it to
that faction only — see `ssto_hull_helga`, `tube_rocket_hull_mk1`,
`drift_hull_mk1` for the three faction-exclusive hulls).

### Adding a brand-new shape (requires the C++ rebuild)

If box/cylinder/capsule/sphere genuinely can't make what you want (like the
delta wings couldn't — no primitive gives a swept triangular planform), you
add a new branch to `PartDefinition::build_mesh_node()` in
`src/part_definition.cpp`. The winged fuselage is the fullest worked example
in the codebase:

- `build_winged_fuselage()` — composites several `MeshInstance3D` children
  under one `Node3D` (a capsule + a cone + two wings), reading all its
  parameters from `mesh_recipe` with sensible defaults via
  `mesh_recipe.get("key", default)`.
- `build_delta_wing_mesh()` (anonymous namespace, same file) — hand-builds a
  solid wedge mesh via `SurfaceTool` when no built-in Godot primitive gives
  the shape you need. If you copy this as a template for another custom
  shape: get the triangle winding right for at least the two flat cap faces
  (get it wrong and, thanks to `PartAssembler`'s shared material having
  `cull_mode` disabled, you won't even get an obvious visual warning — see
  the comment on that line for why that tradeoff was made deliberately).

After changing `src/part_definition.{h,cpp}`, rebuild both targets (see
[CONTRIBUTING.md](../CONTRIBUTING.md)) before the new shape will show up in
Godot.

**One structural gotcha worth knowing if you add a composite (multi-mesh)
part**: `PartAssembler::assemble()` applies the ship's skin texture to every
mesh in the built tree via a recursive walk (`collect_mesh_instances()` in
`src/part_assembler.cpp`). If you ever bypass `build_mesh_node()` and attach
meshes some other way, they won't get skinned automatically — go through the
normal path unless you have a specific reason not to.

## System 2: Level props and resource nodes (`SimpleShapes`, pure GDScript)

Used for anything that's just scene dressing — asteroid/comet nodes, grow
bay racks, furnaces, electrolysis tanks, room furniture. This is
`aevoria-simulator/scripts/simple_shapes.gd` — no sockets, no stats, no C++,
**never needs a rebuild**, because it's just a thin GDScript wrapper around
Godot's own primitive mesh classes.

### Shape keys (same vocabulary as `PartDefinition.mesh_recipe` where they overlap)

```gdscript
{"shape": "box", "size": Vector3(1.0, 1.0, 1.0)}
{"shape": "cylinder", "radius": 0.5, "height": 1.0}
{"shape": "capsule", "radius": 0.5, "height": 1.0}
{"shape": "sphere", "radius": 0.5, "radial_segments": 16, "rings": 8}
```

### Appearance keys (add any of these to any shape dict above)

```gdscript
"albedo_color": Color("2a3038")    # base surface color
"albedo_texture": some_texture     # overrides albedo_color if set (e.g. a ProceduralArtGenerator texture)
"emission_color": Color("8dffc2")  # omit entirely for a non-glowing prop
"emission_energy": 2.5             # only used if emission_color is set (default 1.0)
```

### Using it

```gdscript
const SimpleShapes = preload("res://scripts/simple_shapes.gd")

var my_prop = SimpleShapes.make_mesh_instance({
    "shape": "box", "size": Vector3(1.4, 0.08, 0.8),
    "albedo_color": Color("2a3038"),
})
my_prop.position = Vector3(0, -0.3, 3.0)
add_child(my_prop)

# For a glowing prop that should also actually light up the room:
var light = SimpleShapes.make_point_light(Color("8dffc2"), 1.2, 4.0)  # color, energy, range
light.position = my_prop.position + Vector3(0, 0.5, 0)
add_child(light)
```

### Worked example: the desk in Greenhouse Bay

`aevoria-simulator/scripts/greenhouse_bay.gd`'s `_spawn_desk()` is a real,
currently-in-the-game example of exactly this — a plain two-box desk
(tabletop + support block), called once from `_ready()`. Open that function
as your starting template for adding any other static room furniture (a
chair, a console, a locker) to any level: copy the function, change the
`size`/`albedo_color`/`position` values, add one call to it from `_ready()`.
That's the entire process — no other file needs to change.

## System 3: Procedural skin textures (`ProceduralArtGenerator`)

Separate from mesh shape entirely — this is the *surface texture* system
(the noisy, layered color pattern you see on ships, asteroids, and comets).
A "skin recipe" is:

```gdscript
{
    "seed": 12345,                       # any integer -- same seed always gives the same pattern
    "frequency": 0.08,                   # noise scale; higher = smaller/busier pattern
    "dark_color": Color("26201a"),       # or "#26201a" hex string, depending on context (see below)
    "base_color": Color("8a8f96"),
    "highlight_color": Color("c7ccd1"),
}
```

Two calling conventions exist and it matters which one you're in:
- **Direct GDScript** (level scripts spawning asteroids/comets, etc.):
  colors are real `Color` objects. See `resource_node_catalog.gd`'s
  `ASTEROID_RECIPE`/`COMET_RECIPE` for examples.
- **`AssemblyBlueprint.skin_recipe`** (ship skins, JSON-transport-safe so it
  round-trips to the web app and back): colors are `"#rrggbb"` hex strings.
  See `part_catalog.gd`'s `HULL_SKIN_SUGGESTIONS` for examples — this is
  also where each faction hull's default look (the SSTO's white, the tube
  rocket's gunmetal-and-brass, the drift hull's rust) is defined, applied
  automatically in `assembly_bay.gd` when you pick that hull.

## System 4: The game's front door (starfield, hero backdrop, lens flares)

Everything LevelSelect shows behind its glass UI panels — the starfield, the
rotating torus+cone hull silhouette, the distant sun, and its lens flares —
is built in code by `hero_backdrop.gd`, instantiated once from
`level_select.gd`'s `_ready()`. Same philosophy as the rest of this doc: pure
GDScript, **never needs a rebuild**, and every knob is a plain constant or
dictionary near the top of the file.

### Starfield

`starfield.gd`, one static method: `Starfield.spawn(parent, radius=90.0)`.
It's a `GPUParticles3D` scattered across a sphere around the camera, zero
velocity (the stars don't move). To change star count or spread, edit
`particles.amount` or the `radius` argument in `starfield.gd`.

### The rotating hull silhouette

`hero_backdrop.gd::_build_object()` builds a `TorusMesh` + a tapered
`CylinderMesh` ("cone" — `top_radius` near 0), parented under `_rotator`,
which spins slowly in `_process()`:
```gdscript
_rotator.rotate_y(delta * 0.15)   # spin speed around the vertical axis
_rotator.rotate_x(delta * 0.04)   # a slower tumble on the other axis
```
Resize the ring/cone by changing `torus.inner_radius`/`outer_radius` or
`cone.bottom_radius`/`height` in that same function. Its material comes from
`_hull_material()` — change `COLOR_HULL` at the top of the file to recolor it.

### Space background and glow

`_build_environment()` builds a `WorldEnvironment` — `env.background_color`
is the near-black space color; `env.glow_intensity`/`glow_bloom`/
`glow_hdr_threshold` control how strongly bright things (like the sun below)
bloom. This bloom is what turns a plain bright sphere into something that
actually reads as a light source instead of a flat bright dot.

### The sun and its lens flares

This is the part worth understanding in detail if you want to tune it:

- **`SUN_POSITION`** (top of `hero_backdrop.gd`) is a hand-placed `Vector3`,
  chosen by eye relative to the *fixed* camera set up in `_build_camera()`
  (position `(5, 2.5, 12)`, looking at the origin). The camera never moves in
  this scene — only the hull silhouette rotates — so a fixed world position
  for the sun is enough. **If you ever make the camera move, this whole rig
  needs to switch to tracking a moving light instead**, since nothing here
  recomputes SUN_POSITION relative to a moving viewpoint.
- The sun's own brightness/color comes from `_build_sun()`'s
  `StandardMaterial3D.emission` / `emission_energy_multiplier` — this is what
  the glow effect above actually blooms.
- **Round flare "ghosts"** — `FLARE_SPECS`, a list of dictionaries:
  ```gdscript
  {"t": 0.6, "scale": 0.14, "color": Color(0.6, 0.8, 1.0, 0.3)}
  ```
  `t` places the ghost along the line from the sun's on-screen position
  through the screen center: `t=0` sits right on the sun, `t=1` sits at
  screen center, `t>1` lands on the opposite side of the screen — this is
  the standard real-lens-flare-ghost technique. `scale` is the ghost's size;
  `color`'s alpha is its intensity.
- **Anamorphic streaks** (the horizontal blue bars, added on request to get
  the classic sci-fi look) — `STREAK_SPECS`, same idea but `width`/`height`
  instead of `scale`:
  ```gdscript
  {"t": 0.0, "width": 640.0, "height": 8.0, "color": Color(0.55, 0.78, 1.0, 0.8)}
  ```
  These reuse the exact same round gradient texture as the ghosts above —
  there's no separate streak texture. A `TextureRect`'s default stretch mode
  fills whatever rect size it's given, ignoring aspect ratio, so a circle
  squashed into a wide-short rect *becomes* a horizontal streak for free.
  All the current streaks sit at `t=0` (directly on the sun), since that's
  where a real anamorphic streak originates — unlike the round ghosts, which
  are meant to trail toward screen center.
- Everything auto-hides when the sun is off-screen or behind the camera
  (`_update_lens_flare()`) — you don't need to handle visibility yourself
  when adding a new entry to either list.

**Worked example: add a second, teal-tinted streak** — one line in
`STREAK_SPECS`:
```gdscript
{"t": 0.0, "width": 500.0, "height": 14.0, "color": Color(0.3, 0.9, 0.85, 0.2)}
```

**Worked example: add a ghost further past screen center** — one line in
`FLARE_SPECS`:
```gdscript
{"t": 2.0, "scale": 0.2, "color": Color(0.8, 0.5, 1.0, 0.15)}
```

### A second worked example: Main Hangar Deck's interior

`hangar_backdrop.gd` (instantiated from `main_hangar_deck.gd`'s `_ready()`,
same one-line pattern as `HeroBackdrop`) is the interior counterpart —
floor, back wall, entrance archway, ceiling truss, pillars, and the two
rainbow accent banners, all built from the exact same primitives as System
2 above (it calls `SimpleShapes.make_mesh_instance()`/`make_point_light()`
throughout, it just also adds its own `WorldEnvironment` and a couple of
extra lights the way `hero_backdrop.gd` does). If you want a similar
interior for another level, this is a closer starting template than
`hero_backdrop.gd` itself — it's dressing a room with a fixed camera
looking into it, not an exterior space scene with a rotating hull
silhouette. Every position in it is hand-placed against
`MainHangarDeck.tscn`'s specific camera transform (see the file's own top
comment for the exact numbers), same "camera never moves, geometry is
placed to fit it" approach as `SUN_POSITION` above.

## System 5: The glass/amber UI theme

The frosted-glass panels and amber-outlined buttons used across
LevelSelect, AccountHud, and the Founders Monument are two `Theme` type
variations, built in `theme_builder.gd`:

- **`GlassPanelFrame`** — a `PanelContainer` variation with a fully
  transparent background and a thin amber border. It's transparent on
  purpose: the *actual* background is a separate `ColorRect` child (see
  below) whose shader blurs whatever 3D scene is behind it — an opaque
  panel stylebox would defeat that.
- **`GlassButton`** — a `Button` variation: near-transparent amber wash,
  amber text, brightens on hover.
- Both read their color from **`COLOR_ACCENT_AMBER`** at the top of
  `theme_builder.gd` — change that one constant to re-theme every glass
  panel/button in the project at once.

To make a new panel use this look:
```gdscript
const GlassPanel = preload("res://scripts/glass_panel.gd")

panel.theme_type_variation = "GlassPanelFrame"
var bg = GlassPanel.make(Color(0.05, 0.08, 0.15, 0.35), 1.0)  # tint, inset (px)
panel.add_child(bg)
```
`inset` should roughly match the border width (1px currently) so the
frosted-glass shader doesn't paint over the panel's own border. `tint`'s
alpha controls how strongly the glass darkens what's behind it — every
panel today uses ~0.3-0.35; raise it for a panel with dense text that needs
more contrast, lower it for something that should read as more see-through.

To make a new button match: `button.theme_type_variation = "GlassButton"`.

## Quick recipe: "I want to change X"

- **"Make the SSTO's wings bigger"** → `part_catalog.gd`, `ssto_hull.mesh_recipe`,
  bump `wing_span`/`wing_root_chord`. No rebuild.
- **"Add a chair next to the desk in Greenhouse Bay"** → `greenhouse_bay.gd`,
  copy `_spawn_desk()`, change the box sizes, call it from `_ready()`. No rebuild.
- **"Make the Refinery furnaces glow a different color"** →
  `refinery_bay.gd`'s `RECIPES` array, change the `"glow"` `Color(...)` value
  per recipe. No rebuild.
- **"Give the Tube Rocket Hull a different default skin"** →
  `part_catalog.gd`, `HULL_SKIN_SUGGESTIONS["tube_rocket_hull_mk1"]`. No rebuild.
- **"I want an entirely new hull shape, not just different numbers"** →
  new branch in `src/part_definition.cpp`'s `build_mesh_node()`. Rebuild required
  (see [CONTRIBUTING.md](../CONTRIBUTING.md)).
- **"Move the sun/lens flares on the level-select screen"** →
  `hero_backdrop.gd`, `SUN_POSITION`. No rebuild.
- **"Add another lens-flare ghost or anamorphic streak"** →
  `hero_backdrop.gd`, `FLARE_SPECS` (round ghosts) or `STREAK_SPECS`
  (horizontal streaks). No rebuild.
- **"Make the level-select space background lighter/darker"** →
  `hero_backdrop.gd`, `_build_environment()`'s `env.background_color`. No rebuild.
- **"Change the accent color used by every glass panel/button"** →
  `theme_builder.gd`, `COLOR_ACCENT_AMBER`. No rebuild.
- **"Make a new panel or button match the glass/amber look"** → set
  `theme_type_variation = "GlassPanelFrame"` (panels, plus a
  `GlassPanel.make()` background child) or `"GlassButton"` (buttons). No rebuild.
