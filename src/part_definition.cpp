#include "part_definition.h"

#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/capsule_mesh.hpp>
#include <godot_cpp/classes/cylinder_mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/variant/vector3.hpp>

using namespace godot;

void PartDefinition::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_part_id", "id"), &PartDefinition::set_part_id);
    ClassDB::bind_method(D_METHOD("get_part_id"), &PartDefinition::get_part_id);
    ClassDB::bind_method(D_METHOD("set_display_name", "name"), &PartDefinition::set_display_name);
    ClassDB::bind_method(D_METHOD("get_display_name"), &PartDefinition::get_display_name);
    ClassDB::bind_method(D_METHOD("set_category", "category"), &PartDefinition::set_category);
    ClassDB::bind_method(D_METHOD("get_category"), &PartDefinition::get_category);
    ClassDB::bind_method(D_METHOD("set_faction_id", "faction_id"), &PartDefinition::set_faction_id);
    ClassDB::bind_method(D_METHOD("get_faction_id"), &PartDefinition::get_faction_id);
    ClassDB::bind_method(D_METHOD("set_mesh_recipe", "recipe"), &PartDefinition::set_mesh_recipe);
    ClassDB::bind_method(D_METHOD("get_mesh_recipe"), &PartDefinition::get_mesh_recipe);
    ClassDB::bind_method(D_METHOD("set_sockets", "sockets"), &PartDefinition::set_sockets);
    ClassDB::bind_method(D_METHOD("get_sockets"), &PartDefinition::get_sockets);
    ClassDB::bind_method(D_METHOD("set_stats", "stats"), &PartDefinition::set_stats);
    ClassDB::bind_method(D_METHOD("get_stats"), &PartDefinition::get_stats);
    ClassDB::bind_method(D_METHOD("get_stat", "key"), &PartDefinition::get_stat);
    ClassDB::bind_method(D_METHOD("matches_category_mask", "mask"), &PartDefinition::matches_category_mask);
    ClassDB::bind_method(D_METHOD("find_socket", "socket_id"), &PartDefinition::find_socket);
    ClassDB::bind_method(D_METHOD("build_mesh_node"), &PartDefinition::build_mesh_node);

    ADD_PROPERTY(PropertyInfo(Variant::STRING, "part_id"), "set_part_id", "get_part_id");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "display_name"), "set_display_name", "get_display_name");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "category"), "set_category", "get_category");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "faction_id"), "set_faction_id", "get_faction_id");
    ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "mesh_recipe"), "set_mesh_recipe", "get_mesh_recipe");
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "sockets"), "set_sockets", "get_sockets");
    ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "stats"), "set_stats", "get_stats");

    // PartCategory (part_types.h) -- kept in one flat enum so a single socket
    // system serves ships, droids, and habitat/life-support builds alike.
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_HULL_SEGMENT", PART_CAT_HULL_SEGMENT);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_CHASSIS", PART_CAT_CHASSIS);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_LEG", PART_CAT_LEG);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_THRUSTER", PART_CAT_THRUSTER);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_DRILL_ARM", PART_CAT_DRILL_ARM);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_MANIPULATOR_ARM", PART_CAT_MANIPULATOR_ARM);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_CARGO_POD", PART_CAT_CARGO_POD);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_SENSOR_POD", PART_CAT_SENSOR_POD);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_SOLAR_ARRAY", PART_CAT_SOLAR_ARRAY);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_RADIATOR", PART_CAT_RADIATOR);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_HABITAT_RING", PART_CAT_HABITAT_RING);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_HYDROPONICS_BAY", PART_CAT_HYDROPONICS_BAY);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_O2_SCRUBBER", PART_CAT_O2_SCRUBBER);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_WATER_RECLAIMER", PART_CAT_WATER_RECLAIMER);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_WASTE_RECYCLER", PART_CAT_WASTE_RECYCLER);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_POWER_CELL", PART_CAT_POWER_CELL);
    ClassDB::bind_integer_constant(get_class_static(), "", "CAT_COSMETIC", PART_CAT_COSMETIC);
}

PartDefinition::PartDefinition() {}
PartDefinition::~PartDefinition() {}

void PartDefinition::set_part_id(const String &p_id) { part_id = p_id; }
String PartDefinition::get_part_id() const { return part_id; }

void PartDefinition::set_display_name(const String &p_name) { display_name = p_name; }
String PartDefinition::get_display_name() const { return display_name; }

void PartDefinition::set_category(int p_category) { category = p_category; }
int PartDefinition::get_category() const { return category; }

void PartDefinition::set_faction_id(const String &p_faction_id) { faction_id = p_faction_id; }
String PartDefinition::get_faction_id() const { return faction_id; }

void PartDefinition::set_mesh_recipe(const Dictionary &p_recipe) { mesh_recipe = p_recipe; }
Dictionary PartDefinition::get_mesh_recipe() const { return mesh_recipe; }

void PartDefinition::set_sockets(const Array &p_sockets) { sockets = p_sockets; }
Array PartDefinition::get_sockets() const { return sockets; }

void PartDefinition::set_stats(const Dictionary &p_stats) { stats = p_stats; }
Dictionary PartDefinition::get_stats() const { return stats; }

double PartDefinition::get_stat(const String &key) const {
    return double(stats.get(key, 0.0));
}

bool PartDefinition::matches_category_mask(int mask) const {
    return (part_category_bit(category) & uint32_t(mask)) != 0u;
}

Dictionary PartDefinition::find_socket(const String &socket_id) const {
    for (int i = 0; i < sockets.size(); ++i) {
        Dictionary entry = sockets[i];
        if (String(entry.get("id", "")) == socket_id) {
            return entry;
        }
    }
    return Dictionary();
}

Node3D *PartDefinition::build_mesh_node() const {
    String shape = mesh_recipe.get("shape", "box");
    Ref<Mesh> mesh;

    if (shape == "cylinder") {
        Ref<CylinderMesh> cyl = memnew(CylinderMesh);
        float radius = float(double(mesh_recipe.get("radius", 0.5)));
        cyl->set_top_radius(radius);
        cyl->set_bottom_radius(radius);
        cyl->set_height(float(double(mesh_recipe.get("height", 1.0))));
        mesh = cyl;
    } else if (shape == "capsule") {
        Ref<CapsuleMesh> cap = memnew(CapsuleMesh);
        cap->set_radius(float(double(mesh_recipe.get("radius", 0.5))));
        cap->set_height(float(double(mesh_recipe.get("height", 1.0))));
        mesh = cap;
    } else {
        Ref<BoxMesh> box = memnew(BoxMesh);
        Vector3 size = mesh_recipe.get("size", Vector3(1.0f, 1.0f, 1.0f));
        box->set_size(size);
        mesh = box;
    }

    MeshInstance3D *instance = memnew(MeshInstance3D);
    instance->set_mesh(mesh);
    instance->set_name(display_name.is_empty() ? part_id : display_name);
    return instance;
}
