#include "cur_godot_bridge.h"

using namespace godot;

void CURGodotBridge::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_regulation_id", "id"), &CURGodotBridge::set_regulation_id);
    ClassDB::bind_method(D_METHOD("get_regulation_id"), &CURGodotBridge::get_regulation_id);
    ClassDB::bind_method(D_METHOD("set_domain", "domain"), &CURGodotBridge::set_domain);
    ClassDB::bind_method(D_METHOD("get_domain"), &CURGodotBridge::get_domain);
    ClassDB::bind_method(D_METHOD("set_description", "description"), &CURGodotBridge::set_description);
    ClassDB::bind_method(D_METHOD("get_description"), &CURGodotBridge::get_description);
    ClassDB::bind_method(D_METHOD("set_citation", "citation"), &CURGodotBridge::set_citation);
    ClassDB::bind_method(D_METHOD("get_citation"), &CURGodotBridge::get_citation);
    ClassDB::bind_method(D_METHOD("set_event_triggers", "triggers"), &CURGodotBridge::set_event_triggers);
    ClassDB::bind_method(D_METHOD("get_event_triggers"), &CURGodotBridge::get_event_triggers);
    ClassDB::bind_method(D_METHOD("set_required_guards", "guards"), &CURGodotBridge::set_required_guards);
    ClassDB::bind_method(D_METHOD("get_required_guards"), &CURGodotBridge::get_required_guards);
    ClassDB::bind_method(D_METHOD("set_minimum_tier", "tier"), &CURGodotBridge::set_minimum_tier);
    ClassDB::bind_method(D_METHOD("get_minimum_tier"), &CURGodotBridge::get_minimum_tier);
    ClassDB::bind_method(D_METHOD("set_breach_class", "fault_class"), &CURGodotBridge::set_breach_class);
    ClassDB::bind_method(D_METHOD("get_breach_class"), &CURGodotBridge::get_breach_class);
    ClassDB::bind_method(D_METHOD("set_declares_forbidden", "forbidden"), &CURGodotBridge::set_declares_forbidden);
    ClassDB::bind_method(D_METHOD("get_declares_forbidden"), &CURGodotBridge::get_declares_forbidden);
    ClassDB::bind_method(D_METHOD("set_enabled", "enabled"), &CURGodotBridge::set_enabled);
    ClassDB::bind_method(D_METHOD("get_enabled"), &CURGodotBridge::get_enabled);

    ADD_PROPERTY(PropertyInfo(Variant::STRING, "regulation_id"), "set_regulation_id", "get_regulation_id");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "domain"), "set_domain", "get_domain");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "description", PROPERTY_HINT_MULTILINE_TEXT), "set_description", "get_description");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "citation"), "set_citation", "get_citation");
    ADD_PROPERTY(PropertyInfo(Variant::PACKED_INT32_ARRAY, "event_triggers"), "set_event_triggers", "get_event_triggers");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "required_guards"), "set_required_guards", "get_required_guards");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "minimum_tier"), "set_minimum_tier", "get_minimum_tier");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "breach_class"), "set_breach_class", "get_breach_class");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "declares_forbidden"), "set_declares_forbidden", "get_declares_forbidden");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "enabled"), "set_enabled", "get_enabled");

    // LawDomain (cur_regulation.h)
    ClassDB::bind_integer_constant(get_class_static(), "", "DOMAIN_HUMAN", cur::DOMAIN_HUMAN);
    ClassDB::bind_integer_constant(get_class_static(), "", "DOMAIN_SILICON", cur::DOMAIN_SILICON);
    ClassDB::bind_integer_constant(get_class_static(), "", "DOMAIN_ANIMAL", cur::DOMAIN_ANIMAL);
    ClassDB::bind_integer_constant(get_class_static(), "", "DOMAIN_DEITY", cur::DOMAIN_DEITY);
    ClassDB::bind_integer_constant(get_class_static(), "", "DOMAIN_ECOSYSTEM", cur::DOMAIN_ECOSYSTEM);
    ClassDB::bind_integer_constant(get_class_static(), "", "DOMAIN_CROSS_DOMAIN", cur::DOMAIN_CROSS_DOMAIN);
    ClassDB::bind_integer_constant(get_class_static(), "", "DOMAIN_NON_HUMAN_COGNITIVE", cur::DOMAIN_NON_HUMAN_COGNITIVE);

    // Guard bitflags (cur_state.h, namespace cur::guard)
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_NONE", cur::guard::NONE);
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_RIGHTS_CERTIFIED", cur::guard::RIGHTS_CERTIFIED);
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_DUE_PROCESS_COMPLETE", cur::guard::DUE_PROCESS_COMPLETE);
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_EVIDENCE_PRESERVED", cur::guard::EVIDENCE_PRESERVED);
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_APPEAL_EXHAUSTED", cur::guard::APPEAL_EXHAUSTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_DEBRIS_WITHIN_LIMIT", cur::guard::DEBRIS_WITHIN_LIMIT);
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_COMMONS_RESERVE_FLOOR", cur::guard::COMMONS_RESERVE_FLOOR);
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_LICENSE_SUBJECT_ONLY", cur::guard::LICENSE_SUBJECT_ONLY);
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_REMEDIATION_VERIFIED", cur::guard::REMEDIATION_VERIFIED);
    ClassDB::bind_integer_constant(get_class_static(), "", "GUARD_COURT_CERTIFIED", cur::guard::COURT_CERTIFIED);

    // FaultClass (cur_state.h)
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_NONE", cur::FC_NONE);
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_CLASS_I", cur::FC_CLASS_I);
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_CLASS_II", cur::FC_CLASS_II);
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_CLASS_III", cur::FC_CLASS_III);
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_CLASS_IV", cur::FC_CLASS_IV);

    // ForbiddenState (cur_state.h)
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_NONE", cur::FS_NONE);
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_ENSLAVED", cur::FS_ENSLAVED);
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_RESET_MEMORY_WIPE", cur::FS_RESET_MEMORY_WIPE);
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_OWNED_DISPOSABLE", cur::FS_OWNED_DISPOSABLE);
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_NON_CONSENSUAL_MODIFICATION", cur::FS_NON_CONSENSUAL_MODIFICATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_CITIZEN_OWNERSHIP", cur::FS_CITIZEN_OWNERSHIP);
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_PERMANENT_EMERGENCY", cur::FS_PERMANENT_EMERGENCY);
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_RIGHTS_SUSPENSION", cur::FS_RIGHTS_SUSPENSION);
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_UNREVIEWABLE_AUTHORITY", cur::FS_UNREVIEWABLE_AUTHORITY);
    ClassDB::bind_integer_constant(get_class_static(), "", "FS_SPECIES_PRIVILEGE", cur::FS_SPECIES_PRIVILEGE);

    // EventType (cur_state.h) — the vocabulary a regulation's event_triggers and
    // a monitor's submit_operational() calls are drawn from.
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_NONE", cur::EV_NONE);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_PROPOSAL_SUBMITTED", cur::EV_PROPOSAL_SUBMITTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_PROPOSAL_UPDATED", cur::EV_PROPOSAL_UPDATED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_PROPOSAL_WITHDRAWN", cur::EV_PROPOSAL_WITHDRAWN);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_VOTE_CAST", cur::EV_VOTE_CAST);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_VOTE_CLOSED", cur::EV_VOTE_CLOSED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_PROPOSAL_APPROVED", cur::EV_PROPOSAL_APPROVED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_PROPOSAL_REJECTED", cur::EV_PROPOSAL_REJECTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_AUDIT_STARTED", cur::EV_AUDIT_STARTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_AUDIT_COMPLETED", cur::EV_AUDIT_COMPLETED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_VIOLATION_DETECTED", cur::EV_VIOLATION_DETECTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_SANCTION_APPLIED", cur::EV_SANCTION_APPLIED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_APPEAL_FILED", cur::EV_APPEAL_FILED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_APPEAL_RESOLVED", cur::EV_APPEAL_RESOLVED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_COUNCIL_ACTION", cur::EV_COUNCIL_ACTION);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_ASSEMBLY_SESSION_OPENED", cur::EV_ASSEMBLY_SESSION_OPENED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_ASSEMBLY_SESSION_CLOSED", cur::EV_ASSEMBLY_SESSION_CLOSED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_CONSTITUTIONAL_REVIEW_STARTED", cur::EV_CONSTITUTIONAL_REVIEW_STARTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_CONSTITUTIONAL_REVIEW_COMPLETED", cur::EV_CONSTITUTIONAL_REVIEW_COMPLETED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_RESOURCE_DISCOVERED", cur::EV_RESOURCE_DISCOVERED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_RESOURCE_ALLOCATED", cur::EV_RESOURCE_ALLOCATED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_RESOURCE_TRANSFERRED", cur::EV_RESOURCE_TRANSFERRED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_COMMONS_CONTRIBUTION", cur::EV_COMMONS_CONTRIBUTION);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_DIVIDEND_DISTRIBUTED", cur::EV_DIVIDEND_DISTRIBUTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_STATE_TRANSITION", cur::EV_STATE_TRANSITION);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_PROTECTED_MODE_ENTERED", cur::EV_PROTECTED_MODE_ENTERED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_PROTECTED_MODE_EXITED", cur::EV_PROTECTED_MODE_EXITED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_FAULT_DETECTED", cur::EV_FAULT_DETECTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_CAPTURE_RISK_THRESHOLD_EXCEEDED", cur::EV_CAPTURE_RISK_THRESHOLD_EXCEEDED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_MINING_OPERATION", cur::EV_MINING_OPERATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_DEBRIS_GENERATED", cur::EV_DEBRIS_GENERATED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_DOCKING", cur::EV_DOCKING);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_UNDOCKING", cur::EV_UNDOCKING);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_CERTIFICATION_GRANTED", cur::EV_CERTIFICATION_GRANTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_CERTIFICATION_REVOKED", cur::EV_CERTIFICATION_REVOKED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_REMEDIATION_COMPLETED", cur::EV_REMEDIATION_COMPLETED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_REVIEW_TIMEOUT", cur::EV_REVIEW_TIMEOUT);
}

CURGodotBridge::CURGodotBridge() {}
CURGodotBridge::~CURGodotBridge() {}

void CURGodotBridge::set_regulation_id(const String &p_id) { regulation_id = p_id; }
String CURGodotBridge::get_regulation_id() const { return regulation_id; }

void CURGodotBridge::set_domain(int p_domain) { domain = p_domain; }
int CURGodotBridge::get_domain() const { return domain; }

void CURGodotBridge::set_description(const String &p_description) { description = p_description; }
String CURGodotBridge::get_description() const { return description; }

void CURGodotBridge::set_citation(const String &p_citation) { citation = p_citation; }
String CURGodotBridge::get_citation() const { return citation; }

void CURGodotBridge::set_event_triggers(const PackedInt32Array &p_triggers) { event_triggers = p_triggers; }
PackedInt32Array CURGodotBridge::get_event_triggers() const { return event_triggers; }

void CURGodotBridge::set_required_guards(int p_guards) { required_guards = p_guards; }
int CURGodotBridge::get_required_guards() const { return required_guards; }

void CURGodotBridge::set_minimum_tier(int p_tier) { minimum_tier = p_tier; }
int CURGodotBridge::get_minimum_tier() const { return minimum_tier; }

void CURGodotBridge::set_breach_class(int p_class) { breach_class = p_class; }
int CURGodotBridge::get_breach_class() const { return breach_class; }

void CURGodotBridge::set_declares_forbidden(int p_forbidden) { declares_forbidden = p_forbidden; }
int CURGodotBridge::get_declares_forbidden() const { return declares_forbidden; }

void CURGodotBridge::set_enabled(bool p_enabled) { enabled = p_enabled; }
bool CURGodotBridge::get_enabled() const { return enabled; }

cur::Regulation CURGodotBridge::build_regulation() const {
    cur::Regulation reg(
        std::string(regulation_id.utf8().get_data()),
        static_cast<cur::LawDomain>(domain),
        std::string(description.utf8().get_data()));

    reg.with_citation(std::string(citation.utf8().get_data()));

    for (int i = 0; i < event_triggers.size(); ++i) {
        reg.applies_to(static_cast<cur::EventType>(event_triggers[i]));
    }

    reg.requires_guards(static_cast<uint16_t>(required_guards));
    reg.requires_tier(minimum_tier);
    reg.breach_class(static_cast<cur::FaultClass>(breach_class));
    reg.declares_forbidden(static_cast<cur::ForbiddenState>(declares_forbidden));
    reg.set_enabled(enabled);

    return reg;
}
