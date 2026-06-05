#include "resource_commons.h"
#include <gdextension_interface.h>
#include <godot.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

ResourceCommons::ResourceCommons() {
    // Constructor
}

ResourceCommons::~ResourceCommons() {
    // Destructor
}

void ResourceCommons::_bind_methods() {
    // Register methods and properties so GDScript can see them, e.g.:
    // ClassDB::bind_method(D_METHOD("my_method"), &ResourceCommons::my_method);
}

void ResourceCommons::_ready() {
    // Runs when the node enters the scene tree
}

void ResourceCommons::_process(double delta) {
    // Runs every frame
}

} // namespace godot