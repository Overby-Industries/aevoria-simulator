#ifndef REGULATORY_ENGINE_HPP
#define REGULATORY_ENGINE_HPP

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/templates/vector.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

// The Domains defined in your CUR Naming Convention.
// Deliberately a plain (unscoped) enum, not `enum class` — ClassDB's
// BIND_ENUM_CONSTANT needs an implicit conversion to int64_t to expose these
// as GDScript-facing constants, which a scoped enum doesn't allow.
enum LawDomain {
    HUMAN,          // CUR-H
    SILICON,        // CUR-S
    ANIMAL,         // CUR-A
    DEITY,          // CUR-D
    ECOSYSTEM,      // CUR-E
    CROSS_DOMAIN    // CUR-X
};

// Represents a single Law from the CUR
struct CUR_Law {
    LawDomain domain;
    String law_id;          // e.g., "CUR-S.4.1"
    String description;
    int minimum_tier;       // For Silicon/Sentience tiers
    bool requires_consent;  // For human/animal interaction
};

// Represents an attempt to do something in the game
struct PlayerAction {
    LawDomain actor_domain;
    int actor_tier;
    String action_type;     // e.g., "decommission", "mine", "vote"
    bool has_consent;
};

class RegulatoryEngine : public RefCounted {
    GDCLASS(RegulatoryEngine, RefCounted)

private:
    Vector<CUR_Law> laws;

protected:
    static void _bind_methods();

public:
    RegulatoryEngine();
    ~RegulatoryEngine();

    // Core Logic Functions
    void add_law(LawDomain domain, String id, String desc, int min_tier, bool consent);

    // The "Regulatory Gate" - This is the heart of the system
    // Returns true if the action is LEGAL, false if it VIOLATES a law
    // (Internal C++ API — PlayerAction is a plain struct and can't be
    // marshaled across the GDExtension boundary, so this is not bound to
    // ClassDB directly. See validate_action_simplified() for the
    // GDScript-facing entry point.)
    bool validate_action(PlayerAction action, String &out_error_message);

    // GDScript-facing wrapper around validate_action(). Assumes a
    // Silicon-domain actor (the only case the current CUR rules need from
    // GDScript). Returns an empty string if the action is legal, or the
    // violation message if it isn't.
    String validate_action_simplified(int actor_tier, bool has_consent);
};

} // namespace godot

// Must live outside `namespace godot` — the macro opens its own
// `namespace godot { ... }` block to specialize the binder templates that
// let LawDomain be used as a bound-method parameter/return type.
VARIANT_ENUM_CAST(godot::LawDomain);

#endif
