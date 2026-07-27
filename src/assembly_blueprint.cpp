#include "assembly_blueprint.h"

#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void AssemblyBlueprint::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_ship_id", "id"), &AssemblyBlueprint::set_ship_id);
    ClassDB::bind_method(D_METHOD("get_ship_id"), &AssemblyBlueprint::get_ship_id);
    ClassDB::bind_method(D_METHOD("set_root_part_id", "id"), &AssemblyBlueprint::set_root_part_id);
    ClassDB::bind_method(D_METHOD("get_root_part_id"), &AssemblyBlueprint::get_root_part_id);
    ClassDB::bind_method(D_METHOD("set_attachments", "attachments"), &AssemblyBlueprint::set_attachments);
    ClassDB::bind_method(D_METHOD("get_attachments"), &AssemblyBlueprint::get_attachments);
    ClassDB::bind_method(D_METHOD("set_skin_recipe", "recipe"), &AssemblyBlueprint::set_skin_recipe);
    ClassDB::bind_method(D_METHOD("get_skin_recipe"), &AssemblyBlueprint::get_skin_recipe);
    ClassDB::bind_method(D_METHOD("to_json"), &AssemblyBlueprint::to_json);
    ClassDB::bind_static_method("AssemblyBlueprint", D_METHOD("from_json", "json_text"), &AssemblyBlueprint::from_json);

    ADD_PROPERTY(PropertyInfo(Variant::STRING, "ship_id"), "set_ship_id", "get_ship_id");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "root_part_id"), "set_root_part_id", "get_root_part_id");
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "attachments"), "set_attachments", "get_attachments");
    ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "skin_recipe"), "set_skin_recipe", "get_skin_recipe");
}

AssemblyBlueprint::AssemblyBlueprint() {}
AssemblyBlueprint::~AssemblyBlueprint() {}

void AssemblyBlueprint::set_ship_id(const String &p_id) { ship_id = p_id; }
String AssemblyBlueprint::get_ship_id() const { return ship_id; }

void AssemblyBlueprint::set_root_part_id(const String &p_id) { root_part_id = p_id; }
String AssemblyBlueprint::get_root_part_id() const { return root_part_id; }

void AssemblyBlueprint::set_attachments(const Array &p_attachments) { attachments = p_attachments; }
Array AssemblyBlueprint::get_attachments() const { return attachments; }

void AssemblyBlueprint::set_skin_recipe(const Dictionary &p_recipe) { skin_recipe = p_recipe; }
Dictionary AssemblyBlueprint::get_skin_recipe() const { return skin_recipe; }

String AssemblyBlueprint::to_json() const {
    Dictionary root;
    root["ship_id"] = ship_id;
    root["root_part_id"] = root_part_id;
    root["attachments"] = attachments;
    root["skin_recipe"] = skin_recipe;
    return JSON::stringify(root, "  ");
}

Ref<AssemblyBlueprint> AssemblyBlueprint::from_json(const String &json_text) {
    Variant parsed = JSON::parse_string(json_text);
    if (parsed.get_type() != Variant::DICTIONARY) {
        UtilityFunctions::push_error("AssemblyBlueprint::from_json: invalid JSON (expected an object): ", json_text);
        return Ref<AssemblyBlueprint>();
    }

    Dictionary root = parsed;
    Ref<AssemblyBlueprint> blueprint;
    blueprint.instantiate();
    blueprint->set_ship_id(root.get("ship_id", ""));
    blueprint->set_root_part_id(root.get("root_part_id", ""));
    blueprint->set_attachments(root.get("attachments", Array()));
    blueprint->set_skin_recipe(root.get("skin_recipe", Dictionary()));
    return blueprint;
}
