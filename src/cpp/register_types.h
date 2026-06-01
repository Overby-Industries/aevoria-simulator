#pragma once
#include "register_types.h"
#include "direct_democracy_os.h"
#include "resource_commons.h"
#include <godot_cpp/core/class_db.hpp>
#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_aevoria_module(ModuleInitializationLevel p_level);
void uninitialize_aevoria_module(ModuleInitializationLevel p_level);
