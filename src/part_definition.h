#pragma once

// PartDefinition — one entry in a kit-bashing parts catalog: a Resource so
// a designer can author one .tres per part and tune it entirely from the
// Inspector, same rationale as CURGodotBridge for regulations.
//
// A part is data, not a hand-modeled mesh: `mesh_recipe` is a small
// parametric description (shape + dimensions) that build_mesh_node()
// turns into an actual MeshInstance3D using Godot's built-in primitive
// meshes (BoxMesh/CylinderMesh/CapsuleMesh) -- the same "generate it with
// code" approach as ProceduralArtGenerator, so new parts don't require a
// 3D modeling pipeline. `sockets` are named attachment points other parts
// plug into; `stats` are summed by PartAssembler into an assembly's
// aggregate mass/power/life-support numbers.

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

#include "part_types.h"

namespace godot {

class PartDefinition : public Resource {
    GDCLASS(PartDefinition, Resource)

private:
    String part_id;
    String display_name;
    int category = PART_CAT_HULL_SEGMENT;

    // Empty (the default) means available to every faction. Non-empty
    // restricts this part to one faction id (matched against
    // LevelContext.current_faction_id on the GDScript side -- this class
    // stays a plain data holder and does no gating itself, same division
    // of responsibility as everywhere else in this pipeline).
    String faction_id;

    // {"shape": "box"|"cylinder"|"capsule", "size": Vector3, "radius": float, "height": float}
    Dictionary mesh_recipe;

    // Array of {"id": String, "position": Vector3, "rotation_deg": Vector3, "accepts": int}
    Array sockets;

    // String -> float: "mass", "power_draw", "power_generation", "o2_throughput",
    // "water_throughput", "food_throughput", "mining_yield", "thrust", "cargo_capacity".
    // A flat dictionary rather than one property per stat since most parts only
    // ever populate two or three of these -- same rationale as ResourceCommons'
    // name-keyed stock map.
    Dictionary stats;

protected:
    static void _bind_methods();

public:
    PartDefinition();
    ~PartDefinition() override;

    void set_part_id(const String &p_id);
    String get_part_id() const;

    void set_display_name(const String &p_name);
    String get_display_name() const;

    void set_category(int p_category);
    int get_category() const;

    void set_faction_id(const String &p_faction_id);
    String get_faction_id() const;

    void set_mesh_recipe(const Dictionary &p_recipe);
    Dictionary get_mesh_recipe() const;

    void set_sockets(const Array &p_sockets);
    Array get_sockets() const;

    void set_stats(const Dictionary &p_stats);
    Dictionary get_stats() const;

    double get_stat(const String &key) const;

    // True if this part's category is allowed by a socket's "accepts" bitmask.
    bool matches_category_mask(int mask) const;

    // Finds a socket entry by id; returns an empty Dictionary if not found.
    Dictionary find_socket(const String &socket_id) const;

    // Builds a fresh MeshInstance3D from mesh_recipe. Bound so a part palette
    // UI can preview a single part without going through PartAssembler.
    Node3D *build_mesh_node() const;

private:
    // "winged_fuselage" shape: a capsule body + tapered nose cone + a pair
    // of swept delta wings, all built from mesh_recipe keys. Returns a
    // plain Node3D wrapping several MeshInstance3D children rather than a
    // single MeshInstance3D -- PartAssembler::assemble() walks the built
    // tree for meshes to skin, so this composes cleanly with the existing
    // single-primitive shapes without needing a new part-attachment system.
    Node3D *build_winged_fuselage() const;
};

}  // namespace godot
