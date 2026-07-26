import os

# Load godot-cpp build environment
env = SConscript("godot-cpp/SConstruct")

# Add include paths
env.Append(CPPPATH=[
    "src",
    "core",
    "godot-cpp/include",
    "godot-cpp/include/godot_cpp",
])

# Add your source files
sources = Glob("src/*.cpp") + Glob("core/*.cpp")

# Output directory inside the actual Godot project. Resolved relative to this
# SConstruct file's own directory (Dir("#")) rather than the caller's cwd, so
# it lands in the same place no matter where `scons` is invoked from.
output_dir = os.path.join(Dir("#").abspath, "aevoria-simulator", "bin")

# Ensure directory exists
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Build the shared library
library = env.SharedLibrary(
    target=os.path.join(output_dir, f"libaevoria{env['suffix']}{env['SHLIBSUFFIX']}"),
    source=sources,
)

Default(library)
