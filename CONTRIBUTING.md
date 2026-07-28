# Contributing to Aevoria Simulator

This is the practical, "how do I actually change something" guide. For
the vision/lore, see [README.md](README.md). For the deep reference on
the procedural graphics system specifically, see
[docs/GRAPHICS_GUIDE.md](docs/GRAPHICS_GUIDE.md).

## Project layout

```
aevoria-simulator/     Godot 4 project (scenes, GDScript, shaders)
  scenes/               .tscn scene files -- one per level, plus shared HUD scenes
  scripts/              GDScript -- level logic, catalogs, UI
  shaders/              .gdshader files (e.g. the frosted-glass panel background)
  bin/                  Built GDExtension DLL lands here (gitignored)
src/                   C++ GDExtension source -- the game logic exposed to GDScript
cur/                   Git submodule: the CUR regulations library (separate repo/team)
godot-cpp/             Git submodule: Godot's C++ bindings
web/                   Next.js companion app (account system, skin marketplace, store)
docs/                  Deeper reference docs (this file is the index/entry point)
```

Most levels are **pure GDScript** (`aevoria-simulator/scripts/*.gd`) and need no
C++ rebuild at all to edit. The C++ layer (`src/`) exists for things GDScript
can't do on its own: the CUR compliance state machine bridge, and the
kit-bashing parts system (`PartDefinition`/`PartAssembler`) that ships,
droids, and habitat modules are built from.

## Setting up your environment

- **Godot 4.6.3** (stable) — the exact editor/runtime this project targets
  (`aevoria-simulator/project.godot` pins `config/features` to `"4.6"`). Using
  a different 4.x version will often still open the project, but a version
  mismatch is the first thing to suspect if something that should work
  doesn't.
- **Python 3** with SCons (`pip install scons` if you don't have it) — used to
  build the GDExtension. On Windows, invoke it as `python -m SCons` rather
  than bare `scons`, since `scons` isn't always on `PATH` even when the
  package is installed.
- **A C++17 compiler** — MSVC (Visual Studio Build Tools) on Windows.
- **Node.js 20+** — only needed if you're touching `web/` (the account/store/
  marketplace site).

Godot-cpp and the `cur` regulations library are git submodules — clone with
`git clone --recurse-submodules`, or run `git submodule update --init
--recursive` after a normal clone.

## Building the GDExtension

From the repo root:

```bash
python -m SCons platform=windows target=template_debug -j4
python -m SCons platform=windows target=template_release -j4
```

This compiles everything under `src/` and `cur/src/` into
`aevoria-simulator/bin/libaevoria.windows.template_{debug,release}.x86_64.dll`.
Build the **debug** target for day-to-day editor/dev-server use; build
**release** too before exporting a distributable build (see below) — Godot's
export step needs the release DLL and will silently produce a broken
export if it's missing or stale.

You only need to run SCons after changing a file under `src/` (or pulling a
`cur` submodule update). Editing anything under `aevoria-simulator/scripts/`
or `aevoria-simulator/scenes/` is pure GDScript/scene-file data — no build
step, just relaunch (or hot-reload in the editor).

## Running the project

Open `aevoria-simulator/` in the Godot 4.6.3 editor, or launch it directly:

```bash
"<path to godot>/Godot_v4.6.3-stable_win64_console.exe" --path aevoria-simulator
```

The `_console.exe` variant is worth using over the plain `.exe` even for a
normal windowed run — it gives you a visible stdout/stderr window, which is
where GDScript `print()` output and any `SCRIPT ERROR:`/`Parse Error:` lines
show up.

**Headless testing** (no window, useful for a quick "does this even parse
and boot" check after an edit):

```bash
"<godot>/Godot_v4.6.3-stable_win64_console.exe" --headless --path aevoria-simulator res://scenes/<SceneName>.tscn --quit-after 60
```

This boots straight into the named scene and exits after 60 frames. It
catches parse errors, missing autoloads, and null-reference crashes, but
**cannot** catch layout/rendering problems (a panel positioned off-screen, a
mesh with a hole in it, wrong colors) — headless mode uses a dummy renderer.
For anything visual, you have to actually launch it windowed and look.

## Where levels live and how they're wired up

Every level is one `.tscn` scene + one matching GDScript in
`aevoria-simulator/scripts/`, listed in `scripts/level_catalog.gd`
(`build_levels()` returns the array `level_select.gd` renders as cards). To
add a new level:

1. Build the scene's script (`Node3D` root, usually a `Camera3D` +
   `DirectionalLight3D`, plus whatever UI/props the level needs — copy an
   existing level like `greenhouse_bay.gd` as a starting skeleton).
2. Add a `.tscn` for it (again, copy an existing one's structure).
3. Add an entry to `level_catalog.gd`'s `build_levels()` array.
4. Every level should end with a "Back to Level Select" button
   (`get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")`) — every
   existing level has one, players have no other way back.
5. If the level's UI panel might grow past a few items, wrap it in a
   `ScrollContainer` from the start (see any level's `_build_ui()`) — this bit
   the project twice already (`AssemblyBay`, then `LevelSelect` itself) once a
   panel outgrew a smaller test window.

## Adding or tuning 3D art

This is covered in full in **[docs/GRAPHICS_GUIDE.md](docs/GRAPHICS_GUIDE.md)**,
but the one-sentence version: most visual tuning (resizing a wing, changing a
color, moving a prop) is a **plain GDScript dictionary edit** in
`part_catalog.gd` or a level script, and needs no C++ rebuild — only adding a
genuinely new *shape* (not just new numbers for an existing shape) touches
`src/part_definition.cpp` and needs one.

## Exporting and deploying

`aevoria-simulator/export_presets.cfg` defines the "Windows Desktop" export
preset. `aevoria-simulator/deploy_to_itch.ps1` does the full release cycle in
one command: exports a release build, then pushes it to itch.io via
`butler` (incremental patches only — fast after the first push). Requires
Godot's export templates to be installed
(`%APPDATA%\Godot\export_templates\4.6.3.stable\`) and `butler login` to have
been run once already.

## Common problems and their actual cause

- **"scons: command not found" / scons not recognized** — use `python -m
  SCons` instead of bare `scons`.
- **Godot opens but the DLL/classes aren't there (`CURComplianceMonitor`,
  `PartDefinition`, etc. unknown)** — the GDExtension didn't build, or built
  for the wrong target. Rebuild `template_debug` and check
  `aevoria-simulator/bin/` for a DLL with today's timestamp.
- **A level "looks blank" after Launch** — almost always a layout bug (a
  panel positioned assuming a bigger window than you actually have), not a
  broken scene transition. Launch windowed and actually look; headless mode
  won't show you this.
- **Windows SmartScreen flags the exported .exe as dangerous** — inherent to
  any unsigned executable downloaded from the internet, not a bug in the
  build. Only a paid code-signing certificate removes it; the download page
  already has guidance text for players about this.
- **A newly-added `.gd` file needs a `.gd.uid` committed alongside it** —
  Godot generates these sidecar files the first time it touches a script;
  `git add` them along with the script itself or the next person's editor
  will regenerate a different one and create pointless diff noise.

## The `cur` submodule

`cur/` is maintained by a separate team/session against
[`code-of-universe-regulations`](https://github.com/Overby-Industries/code-of-universe-regulations).
When it's updated (`git submodule update --remote cur` or a fast-forward
`git pull` inside `cur/`), check `cur/include/cur/cur_state.h` and
`cur/include/cur/cur_event.h` for anything new (guard bitflags, event types,
`TransitionContext` fields) and wire it into
`src/cur_compliance_monitor.cpp`'s `dict_to_context()` and `_bind_methods()`
the same way every existing field is: read by name with a default, bound as
a named constant. Then rebuild both targets and verify with a real (not just
compiled) test before considering it done — a wrong guard-bit binding won't
show up as a compile error.
