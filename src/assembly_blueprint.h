#pragma once

// AssemblyBlueprint — a saved kit-bashed design: a root part plus a flat
// list of attachments, each referencing which already-placed part/socket
// it plugs into by id. A Resource (like PartDefinition/CURGodotBridge) so
// it can be authored as a .tres, and it round-trips through JSON since
// that's the natural transport format for a future web-side builder (same
// reasoning as the skin recipe: a small parametric description, not a
// baked asset).
//
// All fields are JSON-primitive-safe on purpose (strings/ints/floats/
// nested arrays+dicts of same) -- no Vector3/Color embedded here, so
// JSON::stringify/parse_string round-trip cleanly with no custom codec.

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class AssemblyBlueprint : public Resource {
    GDCLASS(AssemblyBlueprint, Resource)

private:
    String ship_id;
    String root_part_id;

    // Array of {"attach_id": String, "parent_id": String ("root" or another
    // entry's attach_id), "socket_id": String, "part_id": String}.
    Array attachments;

    // {"seed": int, "frequency": float, "dark_color": "#rrggbb",
    // "base_color": "#rrggbb", "highlight_color": "#rrggbb"} -- same shape
    // as web/lib/skin-recipe.ts's SkinRecipe.
    Dictionary skin_recipe;

protected:
    static void _bind_methods();

public:
    AssemblyBlueprint();
    ~AssemblyBlueprint() override;

    void set_ship_id(const String &p_id);
    String get_ship_id() const;

    void set_root_part_id(const String &p_id);
    String get_root_part_id() const;

    void set_attachments(const Array &p_attachments);
    Array get_attachments() const;

    void set_skin_recipe(const Dictionary &p_recipe);
    Dictionary get_skin_recipe() const;

    String to_json() const;
    static Ref<AssemblyBlueprint> from_json(const String &json_text);
};

}  // namespace godot
