import os
import sys

# Load godot-cpp build environment
env = SConscript("godot-cpp/SConstruct")

# Add include paths
env.Append(CPPPATH=[
    "src/cpp",
    "godot-cpp/include",
    "godot-cpp/include/godot_cpp",
])

# Add your source files
sources = Glob("src/cpp/*.cpp")

# Output directory inside your Godot project
output_dir = "../aevoria-simulator/bin"

# Ensure directory exists
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Build the shared library
library = env.SharedLibrary(
    target=f"{output_dir}/libaevoria{env['suffix']}",
    source=sources,
)

Default(library)
