import os
import sys

# Define the path to godot-cpp
godot_cpp_path = os.path.join(os.getcwd(), "godot-cpp")
sys.path.insert(0, godot_cpp_path)

# Import the SCons tools from godot-cpp
from godot_cpp import *

# Initialize the environment
env = Environment(
    tools=["default"],
    toolpath=[godot_cpp_path],
)

# Add godot-cpp include path
env.Append(CPPPATH=[os.path.join(godot_cpp_path, "include")])

# Compile the GDNative library
env.GdnativeLibrary(
    target="libaevoria",
    source=[
        "src/cpp/direct_democracy_os.cpp",
        "src/cpp/resource_commons.cpp",
    ],
    cppdefines=["GODOT_CPP"],
    cpppath=["src/cpp"],
    libpath=[os.path.join(godot_cpp_path, "lib")],
    bindirs=[os.path.join(godot_cpp_path, "bin")],
)