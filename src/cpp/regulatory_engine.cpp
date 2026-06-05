#include "regulatory_engine.hpp"
#include <gdextension_interface.h>
#include <godot.hpp>

using namespace godot;

void RegulatoryEngine::_bind_methods() {
    // Bind methods so they can be called from GDScript
    ClassDB::bind_method(D_METHOD("add_law", "domain", "id", "desc", "min_tier", "consent"), 
                         &RegulatoryEngine::add_law);
    
    ClassDB::bind_method(D_METHOD("validate_action", "action", "out_error_message"), 
                         &RegulatoryEngine::validate_action);
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