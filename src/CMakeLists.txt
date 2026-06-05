cmake_minimum_required(VERSION 3.16)
project(aevoria_simulator)

# Find Godot's GDExtension headers
find_package(Godot REQUIRED)

# Include directories
include_directories(
    ${GODOT_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Add your C++ classes as a shared library
add_library(aevoria_simulator SHARED
    direct_democracy_os/direct_democracy_os.cpp
    resource_commons/resource_commons.cpp
)

# Link to Godot's GDExtension library
target_link_libraries(aevoria_simulator
    ${GODOT_LIBRARIES}
)

# Set output directory for the compiled library
set_target_properties(aevoria_simulator PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
    OUTPUT_NAME aevoria_simulator
)

# Copy the compiled library to the Godot project's bin folder
add_custom_command(TARGET aevoria_simulator POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_BINARY_DIR}/bin/aevoria_simulator${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${CMAKE_SOURCE_DIR}/godot/bin/
)