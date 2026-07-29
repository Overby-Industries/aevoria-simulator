#include "part_assembler.h"

#include "assembly_blueprint.h"
#include "part_definition.h"
#include "procedural_art_generator.h"

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/basis.hpp>
#include <godot_cpp/variant/rect2i.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector2i.hpp>

using namespace godot;

namespace {

std::string to_std(const String &s) {
    return std::string(s.utf8().get_data());
}

// AssemblyBlueprint's skin_recipe stores colors as "#rrggbb" hex strings
// (JSON-transport-safe, matching web/lib/skin-recipe.ts) while
// ProceduralArtGenerator's recipe expects real Color values -- this is the
// one place those two conventions meet, so the conversion is explicit
// rather than relying on any implicit Variant coercion.
Color hex_to_color(const Dictionary &recipe, const String &key, const Color &fallback) {
    String hex = recipe.get(key, String());
    if (hex.is_empty()) {
        return fallback;
    }
    return Color(hex);
}

// Most part shapes are a single MeshInstance3D, but a composite shape (e.g.
// build_winged_fuselage's body+nose+wings) returns a plain Node3D wrapping
// several -- walk the whole subtree so every mesh in a composite part gets
// the same skin texture as everything else, not just the parts that happen
// to be a MeshInstance3D themselves.
void collect_mesh_instances(Node3D *node, std::vector<MeshInstance3D *> &out) {
    if (node == nullptr) {
        return;
    }
    if (MeshInstance3D *mesh = Object::cast_to<MeshInstance3D>(node)) {
        out.push_back(mesh);
    }
    for (int i = 0; i < node->get_child_count(); ++i) {
        collect_mesh_instances(Object::cast_to<Node3D>(node->get_child(i)), out);
    }
}

}  // namespace

void PartAssembler::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_part_library", "library"), &PartAssembler::set_part_library);
    ClassDB::bind_method(D_METHOD("get_part_library"), &PartAssembler::get_part_library);
    ClassDB::bind_method(D_METHOD("find_part", "part_id"), &PartAssembler::find_part);
    ClassDB::bind_method(D_METHOD("assemble", "blueprint"), &PartAssembler::assemble);
    ClassDB::bind_method(D_METHOD("compute_aggregate_stats", "blueprint"), &PartAssembler::compute_aggregate_stats);

    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "part_library"), "set_part_library", "get_part_library");
}

PartAssembler::PartAssembler() {}
PartAssembler::~PartAssembler() {}

void PartAssembler::_ready() {
    rebuild_part_index();
}

void PartAssembler::rebuild_part_index() {
    part_index.clear();
    for (int i = 0; i < part_library.size(); ++i) {
        Object *obj = part_library[i];
        PartDefinition *part = Object::cast_to<PartDefinition>(obj);
        if (part != nullptr) {
            part_index[to_std(part->get_part_id())] = Ref<PartDefinition>(part);
        }
    }
}

void PartAssembler::set_part_library(const Array &p_library) {
    part_library = p_library;
    rebuild_part_index();
}
Array PartAssembler::get_part_library() const { return part_library; }

Ref<PartDefinition> PartAssembler::find_part(const String &part_id) const {
    auto it = part_index.find(to_std(part_id));
    return it != part_index.end() ? it->second : Ref<PartDefinition>();
}

Node3D *PartAssembler::assemble(const Ref<AssemblyBlueprint> &blueprint) {
    if (blueprint.is_null()) {
        UtilityFunctions::push_error("PartAssembler::assemble: blueprint is null.");
        return nullptr;
    }

    Ref<PartDefinition> root_part = find_part(blueprint->get_root_part_id());
    if (root_part.is_null()) {
        UtilityFunctions::push_error("PartAssembler::assemble: unknown root_part_id '", blueprint->get_root_part_id(), "'.");
        return nullptr;
    }

    Node3D *root_node = root_part->build_mesh_node();
    root_node->set_name(blueprint->get_ship_id().is_empty() ? root_part->get_part_id() : blueprint->get_ship_id());

    std::unordered_map<std::string, Node3D *> node_by_attach_id;
    std::unordered_map<std::string, String> part_id_by_attach_id;
    node_by_attach_id["root"] = root_node;
    part_id_by_attach_id["root"] = root_part->get_part_id();

    std::vector<MeshInstance3D *> mesh_instances;
    collect_mesh_instances(root_node, mesh_instances);

    Array attachments = blueprint->get_attachments();
    std::vector<int> remaining;
    remaining.reserve(attachments.size());
    for (int i = 0; i < attachments.size(); ++i) {
        remaining.push_back(i);
    }

    bool made_progress = true;
    while (!remaining.empty() && made_progress) {
        made_progress = false;
        std::vector<int> still_remaining;

        for (int i : remaining) {
            Dictionary entry = attachments[i];
            String parent_id = entry.get("parent_id", "root");
            auto parent_it = node_by_attach_id.find(to_std(parent_id));
            if (parent_it == node_by_attach_id.end()) {
                still_remaining.push_back(i);
                continue;
            }
            made_progress = true;

            String attach_id = entry.get("attach_id", "");
            String socket_id = entry.get("socket_id", "");
            String part_id = entry.get("part_id", "");

            Ref<PartDefinition> parent_part = find_part(part_id_by_attach_id[to_std(parent_id)]);
            Ref<PartDefinition> child_part = find_part(part_id);
            if (parent_part.is_null() || child_part.is_null()) {
                UtilityFunctions::push_error("PartAssembler::assemble: unknown part in attachment '", attach_id, "'.");
                continue;
            }

            Dictionary socket = parent_part->find_socket(socket_id);
            if (socket.is_empty()) {
                UtilityFunctions::push_error("PartAssembler::assemble: parent part '", parent_part->get_part_id(),
                                             "' has no socket '", socket_id, "'.");
                continue;
            }

            int accepts = int(socket.get("accepts", 0));
            if (!child_part->matches_category_mask(accepts)) {
                UtilityFunctions::push_error("PartAssembler::assemble: part '", part_id,
                                             "' is not an accepted category for socket '", socket_id, "'.");
                continue;
            }

            Node3D *child_node = child_part->build_mesh_node();
            Vector3 pos = socket.get("position", Vector3());
            Vector3 rot_deg = socket.get("rotation_deg", Vector3());
            Vector3 rot_rad(Math::deg_to_rad(rot_deg.x), Math::deg_to_rad(rot_deg.y), Math::deg_to_rad(rot_deg.z));

            parent_it->second->add_child(child_node);
            child_node->set_transform(Transform3D(Basis::from_euler(rot_rad), pos));

            collect_mesh_instances(child_node, mesh_instances);

            node_by_attach_id[to_std(attach_id)] = child_node;
            part_id_by_attach_id[to_std(attach_id)] = part_id;
        }

        remaining = still_remaining;
    }

    for (int i : remaining) {
        Dictionary entry = attachments[i];
        UtilityFunctions::push_error("PartAssembler::assemble: could not resolve attachment '",
                                     String(entry.get("attach_id", "")), "' -- unknown parent_id '",
                                     String(entry.get("parent_id", "")), "'.");
    }

    Dictionary skin_recipe = blueprint->get_skin_recipe();
    if (!skin_recipe.is_empty() && !mesh_instances.empty()) {
        Dictionary texture_recipe;
        texture_recipe["seed"] = skin_recipe.get("seed", 0);
        texture_recipe["frequency"] = skin_recipe.get("frequency", 0.05);
        texture_recipe["dark_color"] = hex_to_color(skin_recipe, "dark_color", Color(0.15f, 0.12f, 0.10f));
        texture_recipe["base_color"] = hex_to_color(skin_recipe, "base_color", Color(0.75f, 0.65f, 0.55f));
        texture_recipe["highlight_color"] = hex_to_color(skin_recipe, "highlight_color", Color(0.85f, 0.78f, 0.68f));

        Ref<ProceduralArtGenerator> generator;
        generator.instantiate();
        Ref<ImageTexture> texture = generator->generate_procedural_texture(texture_recipe, 256, 256);

        // Optional badge/logo composited on top of the procedural pattern --
        // a separate reward from the skin_recipe colors (e.g. the Founding
        // Citizen bundle's commemorative badge), so it layers onto whatever
        // pattern is already selected rather than replacing it.
        String decal_path = blueprint->get_decal_path();
        if (!decal_path.is_empty()) {
            Ref<Image> decal;
            decal.instantiate();
            if (decal->load(decal_path) == OK) {
                Ref<Image> base_image = texture->get_image();
                if (base_image.is_valid()) {
                    Vector2i decal_size = decal->get_size();
                    Vector2i base_size = base_image->get_size();
                    Vector2i dst(base_size.x - decal_size.x - 8, base_size.y - decal_size.y - 8);
                    dst.x = dst.x > 0 ? dst.x : 0;
                    dst.y = dst.y > 0 ? dst.y : 0;
                    base_image->blend_rect(decal, Rect2i(Vector2i(0, 0), decal_size), dst);
                    texture = ImageTexture::create_from_image(base_image);
                }
            } else {
                UtilityFunctions::push_warning("PartAssembler::assemble: could not load decal at '", decal_path, "'.");
            }
        }

        Ref<StandardMaterial3D> material;
        material.instantiate();
        material->set_texture(BaseMaterial3D::TEXTURE_ALBEDO, texture);
        // Composite shapes (e.g. PartDefinition::build_winged_fuselage's
        // hand-built delta-wing ArrayMesh) don't need backface culling to
        // look right and a single wrong winding on one of those hand-derived
        // triangles would otherwise punch an invisible hole in it -- safer
        // to disable culling for the whole shared skin material than to
        // hand-verify winding on every custom face.
        material->set_cull_mode(BaseMaterial3D::CULL_DISABLED);

        for (MeshInstance3D *mesh_instance : mesh_instances) {
            mesh_instance->set_material_override(material);
        }
    }

    return root_node;
}

Dictionary PartAssembler::compute_aggregate_stats(const Ref<AssemblyBlueprint> &blueprint) const {
    Dictionary totals;
    if (blueprint.is_null()) {
        return totals;
    }

    auto accumulate = [&](const Ref<PartDefinition> &part) {
        if (part.is_null()) {
            return;
        }
        Dictionary stats = part->get_stats();
        Array keys = stats.keys();
        for (int i = 0; i < keys.size(); ++i) {
            String key = keys[i];
            double prev = double(totals.get(key, 0.0));
            totals[key] = prev + double(stats[key]);
        }
    };

    accumulate(find_part(blueprint->get_root_part_id()));

    Array attachments = blueprint->get_attachments();
    for (int i = 0; i < attachments.size(); ++i) {
        Dictionary entry = attachments[i];
        accumulate(find_part(String(entry.get("part_id", ""))));
    }

    return totals;
}
