#include "register_types.h"
#include "direct_democracy_os.h"
#include "resource_commons.h"
#include "regulatory_engine.hpp"

#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_aevoria_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;

    ClassDB::register_class<RegulatoryEngine>();
    ClassDB::register_class<DirectDemocracyOS>();
    ClassDB::register_class<ResourceCommons>();
}

void uninitialize_aevoria_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
}

extern "C" {

GDExtensionBool GDE_EXPORT gdextension_init(
    const GDExtensionInterface *p_interface,
    const GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization
) {
    godot::GDExtensionBinding::InitObject init_obj(p_interface, p_library, r_initialization);

    init_obj.register_initializer(initialize_aevoria_module);
    init_obj.register_terminator(uninitialize_aevoria_module);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

    return init_obj.init();
}

}
