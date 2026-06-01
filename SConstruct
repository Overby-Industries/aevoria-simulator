import os
import sys

# Initialize the godot-cpp environment using its own SConstruct helper
env = SConscript("godot-cpp/SConstruct")

# Add your source files
sources = Glob("src/cpp/*.cpp")

# Build the shared library
env.Append(CPPPATH=["src/cpp"])

library = env.SharedLibrary(
    "bin/libaevoria{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
    source=sources,
)

Default(library)