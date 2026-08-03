import os

# Load godot-cpp build environment
env = SConscript("godot-cpp/SConstruct")

# Add include paths
env.Append(CPPPATH=[
    "src",
    "core",
    "godot-cpp/include",
    "godot-cpp/include/godot_cpp",
    "cur/include",
])

# libcur (the CUR submodule) returns its own source node list rather than
# being Globbed directly, per cur/docs/cur-library-api.md section 2 — it
# builds with this project's flags rather than shipping a prebuilt lib.
cur_sources = SConscript("cur/SConscript", exports="env")

# Add your source files
sources = Glob("src/*.cpp") + Glob("core/*.cpp") + cur_sources

# Output directory inside the actual Godot project. Resolved relative to this
# SConstruct file's own directory (Dir("#")) rather than the caller's cwd, so
# it lands in the same place no matter where `scons` is invoked from.
output_dir = os.path.join(Dir("#").abspath, "godot", "bin")

# Ensure directory exists
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Build the shared library
library = env.SharedLibrary(
    target=os.path.join(output_dir, f"libaevoria{env['suffix']}{env['SHLIBSUFFIX']}"),
    source=sources,
)

Default(library)
