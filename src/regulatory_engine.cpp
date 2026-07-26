#include "regulatory_engine.hpp"

using namespace godot;

void RegulatoryEngine::_bind_methods() {
    // Bind methods so they can be called from GDScript
    ClassDB::bind_method(D_METHOD("add_law", "domain", "id", "desc", "min_tier", "consent"),
                         &RegulatoryEngine::add_law);

    ClassDB::bind_method(D_METHOD("validate_action_simplified", "actor_tier", "has_consent"),
                         &RegulatoryEngine::validate_action_simplified);

    // Exposed as plain integer constants (not BIND_ENUM_CONSTANT): LawDomain
    // is a namespace-scope enum, not nested in this class, so the type name
    // VARIANT_ENUM_CAST registers it under ("godot.LawDomain") doesn't match
    // the "RegulatoryEngine.LawDomain" name BIND_ENUM_CONSTANT would produce
    // here — GDScript's static type checker then rejects add_law() calls as
    // a type mismatch. Plain constants sidestep that entirely.
    BIND_CONSTANT(HUMAN);
    BIND_CONSTANT(SILICON);
    BIND_CONSTANT(ANIMAL);
    BIND_CONSTANT(DEITY);
    BIND_CONSTANT(ECOSYSTEM);
    BIND_CONSTANT(CROSS_DOMAIN);
}

RegulatoryEngine::RegulatoryEngine() {}
RegulatoryEngine::~RegulatoryEngine() {}

void RegulatoryEngine::add_law(LawDomain domain, String id, String desc, int min_tier, bool consent) {
    CUR_Law new_law = {domain, id, desc, min_tier, consent};
    laws.push_back(new_law);
}

bool RegulatoryEngine::validate_action(PlayerAction action, String &out_error_message) {
    for (const CUR_Law &law : laws) {
        
        // LOGIC 1: Tier Check (Essential for CUR-S)
        if (action.actor_domain == LawDomain::SILICON && action.actor_tier < law.minimum_tier) {
            if (law.domain == LawDomain::SILICON) {
                out_error_message = "Violation: " + law.law_id + " - Actor tier too low.";
                return false;
            }
        }

        // LOGIC 2: Consent Check (Essential for CUR-H and CUR-A)
        if (law.requires_consent && !action.has_consent) {
            if (action.actor_domain == LawDomain::HUMAN || action.actor_domain == LawDomain::ANIMAL) {
                out_error_message = "Violation: " + law.law_id + " - Action requires explicit consent.";
                return false;
            }
        }
        
        // LOGIC 3: Cross-Domain Conflict (CUR-X)
        // (This is where we will later add complex logic for interacting with ecosystems/deities)
    }

    return true; // If no laws were broken, the action is valid.
}

String RegulatoryEngine::validate_action_simplified(int actor_tier, bool has_consent) {
    PlayerAction action;
    action.actor_domain = LawDomain::SILICON;
    action.actor_tier = actor_tier;
    action.action_type = "";
    action.has_consent = has_consent;

    String error_message;
    bool is_legal = validate_action(action, error_message);
    return is_legal ? String() : error_message;
}