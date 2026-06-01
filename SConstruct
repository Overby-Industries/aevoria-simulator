import os
import sys

from SCons.Script import *

# Add the godot-cpp bindings to the path
godot_cpp_path = os.path.join(os.getcwd(), "godot-cpp")
sys.path.insert(0, godot_cpp_path)

from godot_cpp import *

# Initialize the environment
env = Environment(
    tools=["default"],
    toolpath=[godot_cpp_path],
)

env.Append(CPPFLAGS=["-std=c++17"])
env.Append(LIBPATH=["#lib"])
env.Append(LINKFLAGS=["-lgdnative"])

# Compile the C++ bindings
env.GdnativeLibrary(
    target="libaevoria",
    source=[
        "src/cpp/direct_democracy_os.cpp",
        "src/cpp/resource_commons.cpp",
    ],
    cppdefines=["GODOT_CPP"],
    cpppath=["src/cpp", godot_cpp_path + "/include"],
    libpath=[godot_cpp_path + "/lib"],
    bindirs=[godot_cpp_path + "/bin"],
)


