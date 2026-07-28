#pragma once

// PartAssembler — turns an AssemblyBlueprint plus a catalog of
// PartDefinition resources into an actual Node3D scene graph, and can sum
// a blueprint's part stats into an aggregate (mass/power/life-support/...)
// without building any nodes at all. Node, not Resource, since it owns a
// part-catalog lookup built at _ready() -- same shape as
// CURComplianceMonitor loading its regulations array.

#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

#include <unordered_map>
#include <vector>

namespace godot {

class PartDefinition;
class AssemblyBlueprint;

class PartAssembler : public Node {
    GDCLASS(PartAssembler, Node)

private:
    Array part_library;  // expected to hold PartDefinition resources
    std::unordered_map<std::string, Ref<PartDefinition>> part_index;

    void rebuild_part_index();

protected:
    static void _bind_methods();

public:
    PartAssembler();
    ~PartAssembler() override;

    void _ready() override;

    void set_part_library(const Array &p_library);
    Array get_part_library() const;

    Ref<PartDefinition> find_part(const String &part_id) const;

    // Builds and returns a fully assembled, skinned Node3D. Caller owns the
    // returned node (add_child it into the scene). Returns nullptr if the
    // blueprint's root part can't be resolved.
    Node3D *assemble(const Ref<AssemblyBlueprint> &blueprint);

    // Sums every included part's stats dictionary (root + every attachment)
    // into one aggregate Dictionary -- no nodes are built. Lets a builder UI
    // show projected mass/power/life-support numbers before committing.
    Dictionary compute_aggregate_stats(const Ref<AssemblyBlueprint> &blueprint) const;
};

}  // namespace godot
