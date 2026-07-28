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
    "radius": 0.55,             # body radius
    "height": 3.6,              # body length (the capsule's long axis is Y)
    "nose_length": 0.8,         # how far the nose cone extends past the body
    "nose_tip_radius": 0.04,    # ~0 = sharp point; bigger = a blunter nose
    "wing_span": 1.8,           # how far each wing extends from the centerline
    "wing_root_chord": 1.7,     # length of the wing where it meets the fuselage
    "wing_tip_sweep": 1.5,      # how far back the wingtip is swept vs. the root
    "wing_thickness": 0.1,      # wing thickness (keep this small -- it's a wedge, not a slab)
    "wing_y_offset": -0.3,      # where along the body the wings attach (0 = center, negative = toward the tail)
}
```
All nine keys are plain floats — this is the one to reach for if you want to
change the SSTO's proportions yourself (`ssto_hull_helga` in
`part_catalog.gd`). **No rebuild needed** — this whole shape is driven by
data, even though the shape-*builder* itself is C++.

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
