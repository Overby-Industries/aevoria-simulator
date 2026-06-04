#ifndef REGULATORY_ENGINE_HPP
#define REGULATORY_ENGINE_HPP

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/templates/vector.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

// The Domains defined in your CUR Naming Convention
enum class LawDomain {
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
    bool validate_action(PlayerAction action, String &out_error_message);
};

} // namespace godot

#endif