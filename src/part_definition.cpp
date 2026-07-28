#include "part_definition.h"

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/capsule_mesh.hpp>
#include <godot_cpp/classes/cylinder_mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/surface_tool.hpp>
#include <godot_cpp/variant/vector3.hpp>

using namespace godot;

namespace {

// One solid swept-delta wing: a planform triangle (root leading edge, root
// trailing edge, swept-back tip) extruded by `thickness` along Z into a
// thin wedge. `mirror` reflects the planform across X for the opposite
// wing -- a reflection has determinant -1, so triangle winding is flipped
// too (via swapped vertex order in add_tri), or the mirrored wing would
// render inside-out (back-face culled from the camera's usual side).
Ref<ArrayMesh> build_delta_wing_mesh(float span, float root_chord, float tip_sweep,
                                     float thickness, bool mirror) {
    const float sign = mirror ? -1.0f : 1.0f;
    const float half_chord = root_chord * 0.5f;

    const Vector3 root_lead(0, half_chord, 0);
    const Vector3 root_trail(0, -half_chord, 0);
    const Vector3 tip(sign * span, -half_chord - tip_sweep, 0);

    const Vector3 front_offset(0, 0, thickness * 0.5f);
    const Vector3 back_offset(0, 0, -thickness * 0.5f);

    const Vector3 fl = root_lead + front_offset, ft = root_trail + front_offset, fp = tip + front_offset;
    const Vector3 bl = root_lead + back_offset, bt = root_trail + back_offset, bp = tip + back_offset;

    Ref<SurfaceTool> st;
    st.instantiate();
    st->begin(Mesh::PRIMITIVE_TRIANGLES);

    auto add_tri = [&](const Vector3 &a, const Vector3 &b, const Vector3 &c) {
        st->add_vertex(a);
        if (mirror) {
            st->add_vertex(c);
            st->add_vertex(b);
        } else {
            st->add_vertex(b);
            st->add_vertex(c);
        }
    };

    add_tri(fl, ft, fp);                    // front face
    add_tri(bp, bt, bl);                    // back face (already reverse-ordered vs. front)
    add_tri(fl, fp, bp); add_tri(fl, bp, bl); // leading-edge side
    add_tri(ft, bt, bp); add_tri(ft, bp, fp); // trailing-edge side
    add_tri(fl, bl, bt); add_tri(fl, bt, ft); // root side (fuselage-facing)

    st->generate_normals();
    return st->commit();
}

}  // namespace

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

    if (shape == "winged_fuselage") {
        return build_winged_fuselage();
    }

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

Node3D *PartDefinition::build_winged_fuselage() const {
    const float radius = float(double(mesh_recipe.get("radius", 0.5)));
    const float height = float(double(mesh_recipe.get("height", 2.0)));
    const float nose_length = float(double(mesh_recipe.get("nose_length", 0.6)));
    const float nose_tip_radius = float(double(mesh_recipe.get("nose_tip_radius", 0.04)));
    const float wing_span = float(double(mesh_recipe.get("wing_span", 1.6)));
    const float wing_root_chord = float(double(mesh_recipe.get("wing_root_chord", 1.6)));
    const float wing_tip_sweep = float(double(mesh_recipe.get("wing_tip_sweep", 1.4)));
    const float wing_thickness = float(double(mesh_recipe.get("wing_thickness", 0.1)));
    const float wing_y_offset = float(double(mesh_recipe.get("wing_y_offset", -0.3)));

    Node3D *root = memnew(Node3D);
    root->set_name(display_name.is_empty() ? part_id : display_name);

    // Body: the capsule shape this hull already used, unchanged -- the
    // "top" (+Y) hemisphere cap gets covered by the nose cone below, the
    // "bottom" (-Y) cap stays as the rounded tail.
    Ref<CapsuleMesh> body_mesh = memnew(CapsuleMesh);
    body_mesh->set_radius(radius);
    body_mesh->set_height(height);
    MeshInstance3D *body = memnew(MeshInstance3D);
    body->set_mesh(body_mesh);
    body->set_name("Body");
    root->add_child(body);

    // Nose cone: a CylinderMesh tapering from the body's radius down to a
    // near-point, base positioned at the capsule's "shoulder" (where its
    // dome starts, already at full radius) so the two surfaces meet
    // without an awkward step -- CylinderMesh's own long axis is already Y,
    // same as CapsuleMesh's, so no rotation is needed to line them up.
    Ref<CylinderMesh> nose_mesh = memnew(CylinderMesh);
    nose_mesh->set_top_radius(nose_tip_radius);
    nose_mesh->set_bottom_radius(radius);
    nose_mesh->set_height(nose_length);
    MeshInstance3D *nose = memnew(MeshInstance3D);
    nose->set_mesh(nose_mesh);
    nose->set_name("Nose");
    const float shoulder_y = height * 0.5f - radius;
    nose->set_position(Vector3(0, shoulder_y + nose_length * 0.5f, 0));
    root->add_child(nose);

    // Wings: a mirrored pair of swept delta wings, root chord embedded in
    // the fuselage at wing_y_offset (embedding the inner edge inside the
    // solid body is simplest and matches how socket-attached parts already
    // just sit at their socket position with no separate fitting step).
    for (bool mirror : {false, true}) {
        Ref<ArrayMesh> wing_mesh = build_delta_wing_mesh(wing_span, wing_root_chord, wing_tip_sweep,
                                                         wing_thickness, mirror);
        MeshInstance3D *wing = memnew(MeshInstance3D);
        wing->set_mesh(wing_mesh);
        wing->set_name(mirror ? "WingLeft" : "WingRight");
        wing->set_position(Vector3(0, wing_y_offset, 0));
        root->add_child(wing);
    }

    return root;
}
