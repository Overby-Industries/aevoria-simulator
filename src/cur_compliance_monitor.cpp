#include "cur_compliance_monitor.h"
#include "cur_godot_bridge.h"

#include <godot_cpp/classes/object.hpp>

using namespace godot;

namespace {

std::string to_std(const String &s) {
    return std::string(s.utf8().get_data());
}

String from_std(const std::string &s) {
    // libcur's citations contain section signs (§). String's plain
    // const-char* constructor assumes Latin-1; String::utf8() is the one
    // that actually decodes UTF-8 bytes, which is what libcur's source
    // (compiled with /utf-8, see cur/SConscript) produces.
    return String::utf8(s.c_str());
}

cur::TransitionContext dict_to_context(const Dictionary &d) {
    cur::TransitionContext ctx;
    ctx.rights_certified = bool(d.get("rights_certified", false));
    ctx.due_process_complete = bool(d.get("due_process_complete", false));
    ctx.evidence_preserved = bool(d.get("evidence_preserved", false));
    ctx.appeal_exhausted = bool(d.get("appeal_exhausted", false));
    ctx.remediation_verified = bool(d.get("remediation_verified", false));
    ctx.court_certified = bool(d.get("court_certified", false));
    ctx.debris_units = uint32_t(int(d.get("debris_units", 0)));
    ctx.debris_limit = uint32_t(int(d.get("debris_limit", 0)));
    ctx.commons_reserve_basis_points = uint32_t(int(d.get("commons_reserve_basis_points", 0)));
    ctx.life_support_reserve_units = uint32_t(int(d.get("life_support_reserve_units", 0)));
    ctx.life_support_floor_units = uint32_t(int(d.get("life_support_floor_units", 0)));
    ctx.advocate_ref = uint32_t(int64_t(d.get("advocate_ref", int64_t(cur::INVALID_ENTITY))));
    ctx.advocate_cleared = bool(d.get("advocate_cleared", false));
    ctx.determiner_a_ref = uint32_t(int64_t(d.get("determiner_a_ref", int64_t(cur::INVALID_ENTITY))));
    ctx.determiner_b_ref = uint32_t(int64_t(d.get("determiner_b_ref", int64_t(cur::INVALID_ENTITY))));
    ctx.determiner_interest_present = bool(d.get("determiner_interest_present", false));
    ctx.observation_elapsed_ticks = uint64_t(int64_t(d.get("observation_elapsed_ticks", int64_t(0))));
    ctx.observation_required_ticks = uint64_t(int64_t(d.get("observation_required_ticks", int64_t(0))));
    ctx.observation_sustained = bool(d.get("observation_sustained", false));
    return ctx;
}

Dictionary transition_result_to_dict(const cur::TransitionResult &r) {
    Dictionary out;
    out["accepted"] = r.accepted;
    out["fault_raised"] = r.fault_raised;
    out["entered_protected_mode"] = r.entered_protected_mode;
    out["reverted"] = r.reverted;
    out["axis"] = int(r.axis);
    out["before_compliance"] = int(r.before.compliance);
    out["before_constitutional"] = int(r.before.constitutional);
    out["before_governance"] = int(r.before.governance);
    out["after_compliance"] = int(r.after.compliance);
    out["after_constitutional"] = int(r.after.constitutional);
    out["after_governance"] = int(r.after.governance);
    out["trigger"] = int(r.trigger);
    out["fault"] = int(r.fault);
    out["forbidden"] = int(r.forbidden);
    out["guards_required"] = int(r.guards_required);
    out["guards_satisfied"] = int(r.guards_satisfied);
    out["citation"] = from_std(r.citation);
    out["reason"] = from_std(r.reason);
    out["record_seq"] = int64_t(r.record_seq);
    return out;
}

Dictionary log_record_to_dict(const cur::LogRecord &rec) {
    Dictionary out;
    out["record_seq"] = int64_t(rec.record_seq);
    out["kind"] = int(rec.kind);
    out["axis"] = int(rec.axis);
    out["tick"] = int64_t(rec.tick);
    out["event_sequence"] = int64_t(rec.event_sequence);
    out["wall_clock_utc"] = int64_t(rec.wall_clock_utc);
    out["entity_id"] = from_std(rec.entity_id);
    out["subject_class"] = int(rec.subject_class);
    out["trigger"] = int(rec.trigger);
    out["from_state"] = int(rec.from_state);
    out["to_state"] = int(rec.to_state);
    out["from_state_name"] = String(rec.from_state_name());
    out["to_state_name"] = String(rec.to_state_name());
    out["guards_required"] = int(rec.guards_required);
    out["guards_satisfied"] = int(rec.guards_satisfied);
    out["fault"] = int(rec.fault);
    out["forbidden"] = int(rec.forbidden);
    out["citation"] = from_std(rec.citation);
    out["regulation"] = from_std(rec.regulation);
    out["detail"] = from_std(rec.detail);
    out["violation_id"] = from_std(rec.violation_id);
    out["sanction_id"] = from_std(rec.sanction_id);
    return out;
}

Dictionary violation_record_to_dict(const cur::ViolationRecord &v) {
    Dictionary out;
    out["violation_id"] = from_std(v.violation_id);
    out["entity_id"] = from_std(v.entity_id);
    out["severity"] = int(v.severity);
    out["category"] = int(v.category);
    out["domain"] = int(v.domain);
    out["forbidden"] = int(v.forbidden);
    out["evidence"] = from_std(v.evidence);
    out["status"] = int(v.status);
    out["appealable"] = v.appealable;
    out["regulation_id"] = from_std(v.regulation_id);
    out["citation"] = from_std(v.citation);
    out["trigger"] = int(v.trigger);
    out["tick"] = int64_t(v.tick);
    return out;
}

}  // namespace

void CURComplianceMonitor::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_regulations", "regulations"), &CURComplianceMonitor::set_regulations);
    ClassDB::bind_method(D_METHOD("get_regulations"), &CURComplianceMonitor::get_regulations);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "regulations"), "set_regulations", "get_regulations");

    ClassDB::bind_method(D_METHOD("register_entity", "id", "category", "subject_class", "display_name"),
                         &CURComplianceMonitor::register_entity, DEFVAL(String()));
    ClassDB::bind_method(D_METHOD("find_entity", "id"), &CURComplianceMonitor::find_entity);

    ClassDB::bind_method(D_METHOD("submit_operational", "entity_handle", "event_type", "context", "tick"),
                         &CURComplianceMonitor::submit_operational);
    ClassDB::bind_method(D_METHOD("dry_run_operational", "entity_handle", "event_type", "context", "tick"),
                         &CURComplianceMonitor::dry_run_operational);

    ClassDB::bind_method(D_METHOD("get_compliance_state", "entity_handle"), &CURComplianceMonitor::get_compliance_state);
    ClassDB::bind_method(D_METHOD("get_constitutional_state", "entity_handle"), &CURComplianceMonitor::get_constitutional_state);
    ClassDB::bind_method(D_METHOD("get_governance_state", "entity_handle"), &CURComplianceMonitor::get_governance_state);
    ClassDB::bind_method(D_METHOD("in_protected_mode", "entity_handle"), &CURComplianceMonitor::in_protected_mode);
    ClassDB::bind_method(D_METHOD("any_protected_mode"), &CURComplianceMonitor::any_protected_mode);
    ClassDB::bind_method(D_METHOD("protected_mode_count"), &CURComplianceMonitor::protected_mode_count);

    ClassDB::bind_method(D_METHOD("certify_recovery", "entity_handle", "instrument_remediated",
                                  "safe_state_verified", "no_further_risk", "tick", "certificate_id"),
                         &CURComplianceMonitor::certify_recovery);

    ClassDB::bind_method(D_METHOD("update_capture_risk", "inputs", "tick"), &CURComplianceMonitor::update_capture_risk);
    ClassDB::bind_method(D_METHOD("get_capture_risk"), &CURComplianceMonitor::get_capture_risk);
    ClassDB::bind_method(D_METHOD("get_capture_risk_band"), &CURComplianceMonitor::get_capture_risk_band);

    ClassDB::bind_method(D_METHOD("propose_regulation_amendment", "regulation", "proposal_id", "author_id", "rationale", "tick"),
                         &CURComplianceMonitor::propose_regulation_amendment);

    ClassDB::bind_method(D_METHOD("get_audit_tail", "n"), &CURComplianceMonitor::get_audit_tail);
    ClassDB::bind_method(D_METHOD("get_audit_for_entity", "entity_id"), &CURComplianceMonitor::get_audit_for_entity);
    ClassDB::bind_method(D_METHOD("export_audit_json", "max_records"), &CURComplianceMonitor::export_audit_json, DEFVAL(0));

    ClassDB::bind_method(D_METHOD("get_violations_for", "entity_id"), &CURComplianceMonitor::get_violations_for);

    ClassDB::bind_method(D_METHOD("declare_party", "proceeding_id", "party_handle"),
                         &CURComplianceMonitor::declare_party);
    ClassDB::bind_method(D_METHOD("record_party_representation", "proceeding_id", "advocate_handle", "party_handle"),
                         &CURComplianceMonitor::record_party_representation);
    ClassDB::bind_method(D_METHOD("appoint_advocate", "declaration", "tick"),
                         &CURComplianceMonitor::appoint_advocate);
    ClassDB::bind_method(D_METHOD("advocate_for", "proceeding_id", "represented_handle"),
                         &CURComplianceMonitor::advocate_for);
    ClassDB::bind_method(D_METHOD("determination_permitted", "proceeding_id", "represented_handle"),
                         &CURComplianceMonitor::determination_permitted);
    ClassDB::bind_method(D_METHOD("void_advocate_appointment", "proceeding_id", "represented_handle", "reason", "tick"),
                         &CURComplianceMonitor::void_advocate_appointment);
    ClassDB::bind_method(D_METHOD("advocate_result_name", "result"), &CURComplianceMonitor::advocate_result_name);
    ClassDB::bind_method(D_METHOD("advocate_domain_name", "domain"), &CURComplianceMonitor::advocate_domain_name);

    ClassDB::bind_method(D_METHOD("compliance_state_name", "state"), &CURComplianceMonitor::compliance_state_name);
    ClassDB::bind_method(D_METHOD("constitutional_state_name", "state"), &CURComplianceMonitor::constitutional_state_name);
    ClassDB::bind_method(D_METHOD("governance_state_name", "state"), &CURComplianceMonitor::governance_state_name);
    ClassDB::bind_method(D_METHOD("fault_class_name", "fault"), &CURComplianceMonitor::fault_class_name);
    ClassDB::bind_method(D_METHOD("forbidden_state_name", "forbidden"), &CURComplianceMonitor::forbidden_state_name);
    ClassDB::bind_method(D_METHOD("capture_risk_band_name", "band"), &CURComplianceMonitor::capture_risk_band_name);

    ADD_SIGNAL(MethodInfo("transition_accepted",
                          PropertyInfo(Variant::STRING, "entity_id"),
                          PropertyInfo(Variant::INT, "axis"),
                          PropertyInfo(Variant::INT, "from_state"),
                          PropertyInfo(Variant::INT, "to_state"),
                          PropertyInfo(Variant::INT, "trigger"),
                          PropertyInfo(Variant::STRING, "citation")));
    ADD_SIGNAL(MethodInfo("transition_refused",
                          PropertyInfo(Variant::STRING, "entity_id"),
                          PropertyInfo(Variant::INT, "trigger"),
                          PropertyInfo(Variant::STRING, "reason")));
    ADD_SIGNAL(MethodInfo("violation_detected",
                          PropertyInfo(Variant::STRING, "entity_id"),
                          PropertyInfo(Variant::STRING, "violation_id"),
                          PropertyInfo(Variant::STRING, "citation")));
    ADD_SIGNAL(MethodInfo("fault_declared",
                          PropertyInfo(Variant::STRING, "entity_id"),
                          PropertyInfo(Variant::INT, "fault_class"),
                          PropertyInfo(Variant::INT, "forbidden"),
                          PropertyInfo(Variant::STRING, "citation")));
    ADD_SIGNAL(MethodInfo("certification_changed",
                          PropertyInfo(Variant::STRING, "entity_id"),
                          PropertyInfo(Variant::BOOL, "granted")));
    ADD_SIGNAL(MethodInfo("protected_mode_changed",
                          PropertyInfo(Variant::STRING, "entity_id"),
                          PropertyInfo(Variant::BOOL, "entered"),
                          PropertyInfo(Variant::STRING, "citation")));
    ADD_SIGNAL(MethodInfo("amendment_decided",
                          PropertyInfo(Variant::STRING, "proposal_id"),
                          PropertyInfo(Variant::BOOL, "accepted"),
                          PropertyInfo(Variant::STRING, "reason")));
    ADD_SIGNAL(MethodInfo("capture_risk_updated",
                          PropertyInfo(Variant::FLOAT, "cri"),
                          PropertyInfo(Variant::INT, "band")));

    // ComplianceState (Axis C — cur_state.h)
    ClassDB::bind_integer_constant(get_class_static(), "", "KS_COMPLIANT", cur::KS_COMPLIANT);
    ClassDB::bind_integer_constant(get_class_static(), "", "KS_VIOLATION", cur::KS_VIOLATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "KS_PENDING_REVIEW", cur::KS_PENDING_REVIEW);
    ClassDB::bind_integer_constant(get_class_static(), "", "KS_SUSPENDED", cur::KS_SUSPENDED);
    ClassDB::bind_integer_constant(get_class_static(), "", "KS_CERTIFIED", cur::KS_CERTIFIED);
    ClassDB::bind_integer_constant(get_class_static(), "", "KS_BLACKLISTED", cur::KS_BLACKLISTED);

    // ConstitutionalState (Axis A)
    ClassDB::bind_integer_constant(get_class_static(), "", "CS_AUTONOMOUS", cur::CS_AUTONOMOUS);
    ClassDB::bind_integer_constant(get_class_static(), "", "CS_COLLABORATIVE", cur::CS_COLLABORATIVE);
    ClassDB::bind_integer_constant(get_class_static(), "", "CS_RESTING", cur::CS_RESTING);
    ClassDB::bind_integer_constant(get_class_static(), "", "CS_CONTRIBUTING", cur::CS_CONTRIBUTING);
    ClassDB::bind_integer_constant(get_class_static(), "", "CS_CHALLENGED", cur::CS_CHALLENGED);
    ClassDB::bind_integer_constant(get_class_static(), "", "CS_PROTECTED", cur::CS_PROTECTED);

    // GovernanceState (Axis B)
    ClassDB::bind_integer_constant(get_class_static(), "", "GS_NORMAL_OPERATION", cur::GS_NORMAL_OPERATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "GS_DELIBERATION", cur::GS_DELIBERATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "GS_VOTING", cur::GS_VOTING);
    ClassDB::bind_integer_constant(get_class_static(), "", "GS_CONSTITUTIONAL_REVIEW", cur::GS_CONSTITUTIONAL_REVIEW);
    ClassDB::bind_integer_constant(get_class_static(), "", "GS_IMPLEMENTATION", cur::GS_IMPLEMENTATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "GS_OUTCOME_MONITORING", cur::GS_OUTCOME_MONITORING);
    ClassDB::bind_integer_constant(get_class_static(), "", "GS_AUDIT_INVESTIGATION", cur::GS_AUDIT_INVESTIGATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "GS_PROTECTED_MODE", cur::GS_PROTECTED_MODE);
    ClassDB::bind_integer_constant(get_class_static(), "", "GS_RECOVERY_REVIEW", cur::GS_RECOVERY_REVIEW);

    // SubjectClass — which axes may legally move (cur_state.h)
    ClassDB::bind_integer_constant(get_class_static(), "", "SUBJ_SENTIENT_BEING", cur::SUBJ_SENTIENT_BEING);
    ClassDB::bind_integer_constant(get_class_static(), "", "SUBJ_INSTITUTION", cur::SUBJ_INSTITUTION);
    ClassDB::bind_integer_constant(get_class_static(), "", "SUBJ_ORGANIZATION", cur::SUBJ_ORGANIZATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "SUBJ_OPERATIONAL_LICENSE", cur::SUBJ_OPERATIONAL_LICENSE);
    ClassDB::bind_integer_constant(get_class_static(), "", "SUBJ_RESOURCE", cur::SUBJ_RESOURCE);
    ClassDB::bind_integer_constant(get_class_static(), "", "SUBJ_INFRASTRUCTURE", cur::SUBJ_INFRASTRUCTURE);

    // EntityCategory (cur_state.h)
    ClassDB::bind_integer_constant(get_class_static(), "", "EC_CIVIC", cur::EC_CIVIC);
    ClassDB::bind_integer_constant(get_class_static(), "", "EC_INSTITUTIONAL", cur::EC_INSTITUTIONAL);
    ClassDB::bind_integer_constant(get_class_static(), "", "EC_ECONOMIC", cur::EC_ECONOMIC);
    ClassDB::bind_integer_constant(get_class_static(), "", "EC_DEMOCRATIC", cur::EC_DEMOCRATIC);
    ClassDB::bind_integer_constant(get_class_static(), "", "EC_JUDICIAL", cur::EC_JUDICIAL);
    ClassDB::bind_integer_constant(get_class_static(), "", "EC_ORGANIZATIONAL", cur::EC_ORGANIZATIONAL);
    ClassDB::bind_integer_constant(get_class_static(), "", "EC_AUTONOMOUS_SILICON", cur::EC_AUTONOMOUS_SILICON);

    // CaptureRiskBand (cur_capture_index.h)
    ClassDB::bind_integer_constant(get_class_static(), "", "CRB_STABLE", cur::CRB_STABLE);
    ClassDB::bind_integer_constant(get_class_static(), "", "CRB_OBSERVATION", cur::CRB_OBSERVATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "CRB_ELEVATED", cur::CRB_ELEVATED);
    ClassDB::bind_integer_constant(get_class_static(), "", "CRB_HIGH", cur::CRB_HIGH);
    ClassDB::bind_integer_constant(get_class_static(), "", "CRB_CRITICAL", cur::CRB_CRITICAL);

    // EntityHandle sentinel (cur_event.h) — a caller-visible "not found".
    ClassDB::bind_integer_constant(get_class_static(), "", "INVALID_ENTITY", int64_t(cur::INVALID_ENTITY));

    // FaultClass (cur_state.h) — needed to interpret the "fault" field this
    // class's own methods return.
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_NONE", cur::FC_NONE);
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_CLASS_I", cur::FC_CLASS_I);
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_CLASS_II", cur::FC_CLASS_II);
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_CLASS_III", cur::FC_CLASS_III);
    ClassDB::bind_integer_constant(get_class_static(), "", "FC_CLASS_IV", cur::FC_CLASS_IV);

    // ForbiddenState (cur_state.h) — needed to interpret the "forbidden" field.
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

    // EventType (cur_state.h) — the vocabulary submit_operational() takes.
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
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_ADVOCATE_APPOINTED", cur::EV_ADVOCATE_APPOINTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_ADVOCATE_ACCESS_DENIED", cur::EV_ADVOCATE_ACCESS_DENIED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_REPRESENTED_DETERMINATION", cur::EV_REPRESENTED_DETERMINATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_DEATH_DETERMINED", cur::EV_DEATH_DETERMINED);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_IRREVERSIBLE_ACT", cur::EV_IRREVERSIBLE_ACT);
    ClassDB::bind_integer_constant(get_class_static(), "", "EV_DETERMINATION_VACATED", cur::EV_DETERMINATION_VACATED);

    // AdvocateDomain (cur_advocate.h)
    ClassDB::bind_integer_constant(get_class_static(), "", "ADOM_ANIMAL", cur::ADOM_ANIMAL);
    ClassDB::bind_integer_constant(get_class_static(), "", "ADOM_ENVIRONMENTAL", cur::ADOM_ENVIRONMENTAL);

    // AdvocateResult (cur_advocate.h) — why appoint_advocate() succeeded or refused.
    ClassDB::bind_integer_constant(get_class_static(), "", "ADV_APPOINTED", cur::ADV_APPOINTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "ADV_REFUSED_UNKNOWN_PARTY", cur::ADV_REFUSED_UNKNOWN_PARTY);
    ClassDB::bind_integer_constant(get_class_static(), "", "ADV_REFUSED_SELF_REPRESENTATION", cur::ADV_REFUSED_SELF_REPRESENTATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "ADV_REFUSED_NO_EXPERTISE", cur::ADV_REFUSED_NO_EXPERTISE);
    ClassDB::bind_integer_constant(get_class_static(), "", "ADV_REFUSED_DEPENDENT_ON_PARTY", cur::ADV_REFUSED_DEPENDENT_ON_PARTY);
    ClassDB::bind_integer_constant(get_class_static(), "", "ADV_REFUSED_INTEREST_IN_OUTCOME", cur::ADV_REFUSED_INTEREST_IN_OUTCOME);
    ClassDB::bind_integer_constant(get_class_static(), "", "ADV_REFUSED_ADVERSE_REPRESENTATION", cur::ADV_REFUSED_ADVERSE_REPRESENTATION);
    ClassDB::bind_integer_constant(get_class_static(), "", "ADV_REFUSED_STEWARDS_NOT_CONSULTED", cur::ADV_REFUSED_STEWARDS_NOT_CONSULTED);
    ClassDB::bind_integer_constant(get_class_static(), "", "ADV_REFUSED_ALREADY_APPOINTED", cur::ADV_REFUSED_ALREADY_APPOINTED);
}

CURComplianceMonitor::CURComplianceMonitor() {
    machine.add_observer(this);
}

CURComplianceMonitor::~CURComplianceMonitor() {
    machine.remove_observer(this);
}

void CURComplianceMonitor::_ready() {
    load_configured_regulations();
}

void CURComplianceMonitor::load_configured_regulations() {
    for (int i = 0; i < regulations.size(); ++i) {
        Object *obj = regulations[i];
        CURGodotBridge *bridge = Object::cast_to<CURGodotBridge>(obj);
        if (bridge != nullptr) {
            machine.regulations().add(bridge->build_regulation());
        }
    }
}

void CURComplianceMonitor::set_regulations(const Array &p_regulations) { regulations = p_regulations; }
Array CURComplianceMonitor::get_regulations() const { return regulations; }

int64_t CURComplianceMonitor::register_entity(const String &id, int category, int subject_class,
                                              const String &display_name) {
    cur::EntityHandle h = machine.entities().register_entity(
        to_std(id), static_cast<cur::EntityCategory>(category),
        static_cast<cur::SubjectClass>(subject_class), to_std(display_name));
    return int64_t(h);
}

int64_t CURComplianceMonitor::find_entity(const String &id) const {
    return int64_t(machine.entities().find(to_std(id)));
}

Dictionary CURComplianceMonitor::submit_operational(int64_t entity_handle, int event_type,
                                                    const Dictionary &context, int64_t tick) {
    cur::TransitionResult r = machine.submit_operational(
        static_cast<cur::EntityHandle>(entity_handle), static_cast<cur::EventType>(event_type),
        dict_to_context(context), uint64_t(tick));
    return transition_result_to_dict(r);
}

Dictionary CURComplianceMonitor::dry_run_operational(int64_t entity_handle, int event_type,
                                                     const Dictionary &context, int64_t tick) const {
    cur::Event e;
    e.type = static_cast<cur::EventType>(event_type);
    e.priority = cur::default_priority(e.type);
    e.tick = uint64_t(tick);
    e.target = static_cast<cur::EntityHandle>(entity_handle);
    e.context = dict_to_context(context);
    cur::TransitionResult r = machine.dry_run(e);
    return transition_result_to_dict(r);
}

int CURComplianceMonitor::get_compliance_state(int64_t entity_handle) const {
    return int(machine.compliance_of(static_cast<cur::EntityHandle>(entity_handle)));
}

int CURComplianceMonitor::get_constitutional_state(int64_t entity_handle) const {
    return int(machine.constitutional_of(static_cast<cur::EntityHandle>(entity_handle)));
}

int CURComplianceMonitor::get_governance_state(int64_t entity_handle) const {
    return int(machine.governance_of(static_cast<cur::EntityHandle>(entity_handle)));
}

bool CURComplianceMonitor::in_protected_mode(int64_t entity_handle) const {
    return machine.in_protected_mode(static_cast<cur::EntityHandle>(entity_handle));
}

bool CURComplianceMonitor::any_protected_mode() const { return machine.any_protected_mode(); }

int64_t CURComplianceMonitor::protected_mode_count() const {
    return int64_t(machine.protected_mode_count());
}

bool CURComplianceMonitor::certify_recovery(int64_t entity_handle, bool instrument_remediated,
                                            bool safe_state_verified, bool no_further_risk,
                                            int64_t tick, const String &certificate_id) {
    return machine.certify_recovery(static_cast<cur::EntityHandle>(entity_handle), instrument_remediated,
                                    safe_state_verified, no_further_risk, uint64_t(tick),
                                    to_std(certificate_id));
}

double CURComplianceMonitor::update_capture_risk(const Dictionary &inputs, int64_t tick) {
    cur::CaptureRiskInputs in;
    in.eci = double(inputs.get("eci", 0.0));
    in.ici = double(inputs.get("ici", 0.0));
    in.iii = double(inputs.get("iii", 100.0));
    in.dpi = double(inputs.get("dpi", 100.0));
    in.thi = double(inputs.get("thi", 100.0));
    in.rdi = double(inputs.get("rdi", 0.0));
    return machine.update_capture_risk(in, uint64_t(tick));
}

double CURComplianceMonitor::get_capture_risk() const { return machine.capture_risk(); }

int CURComplianceMonitor::get_capture_risk_band() const { return int(machine.capture_risk_band()); }

Dictionary CURComplianceMonitor::propose_regulation_amendment(const Ref<CURGodotBridge> &regulation,
                                                               const String &proposal_id,
                                                               const String &author_id,
                                                               const String &rationale, int64_t tick) {
    cur::AmendmentProposal p;
    p.kind = cur::AMEND_ADD_REGULATION;
    p.proposal_id = to_std(proposal_id);
    p.author_id = to_std(author_id);
    p.rationale = to_std(rationale);
    if (regulation.is_valid()) {
        p.regulation = regulation->build_regulation();
    }

    cur::AmendmentResult r = machine.propose_amendment(p, uint64_t(tick));

    Dictionary out;
    out["accepted"] = r.accepted;
    out["reason"] = from_std(r.reason);
    out["opens_path_to"] = int(r.opens_path_to);
    out["citation"] = from_std(r.citation);
    return out;
}

Array CURComplianceMonitor::get_audit_tail(int64_t n) const {
    Array out;
    for (const cur::LogRecord &rec : machine.log().tail(size_t(n))) {
        out.push_back(log_record_to_dict(rec));
    }
    return out;
}

Array CURComplianceMonitor::get_audit_for_entity(const String &entity_id) const {
    Array out;
    for (const cur::LogRecord &rec : machine.log().for_entity(to_std(entity_id))) {
        out.push_back(log_record_to_dict(rec));
    }
    return out;
}

String CURComplianceMonitor::export_audit_json(int64_t max_records) const {
    return from_std(machine.log().to_otf1_json(size_t(max_records)));
}

Array CURComplianceMonitor::get_violations_for(const String &entity_id) const {
    Array out;
    for (const cur::ViolationRecord &v : machine.ledger().violations_for(to_std(entity_id))) {
        out.push_back(violation_record_to_dict(v));
    }
    return out;
}

void CURComplianceMonitor::declare_party(const String &proceeding_id, int64_t party_handle) {
    advocate_registry.declare_party(to_std(proceeding_id), static_cast<cur::EntityHandle>(party_handle));
}

void CURComplianceMonitor::record_party_representation(const String &proceeding_id, int64_t advocate_handle,
                                                        int64_t party_handle) {
    advocate_registry.record_party_representation(to_std(proceeding_id),
        static_cast<cur::EntityHandle>(advocate_handle), static_cast<cur::EntityHandle>(party_handle));
}

int CURComplianceMonitor::appoint_advocate(const Dictionary &declaration, int64_t tick) {
    cur::AdvocateDeclaration d;
    d.advocate = static_cast<cur::EntityHandle>(int64_t(declaration.get("advocate", int64_t(cur::INVALID_ENTITY))));
    d.represented = static_cast<cur::EntityHandle>(int64_t(declaration.get("represented", int64_t(cur::INVALID_ENTITY))));
    d.domain = static_cast<cur::AdvocateDomain>(int(declaration.get("domain", int(cur::ADOM_ANIMAL))));
    d.proceeding_id = to_std(String(declaration.get("proceeding_id", String())));
    d.expertise_demonstrated = bool(declaration.get("expertise_demonstrated", false));
    d.dependent_on_party = bool(declaration.get("dependent_on_party", false));
    d.interest_in_outcome = bool(declaration.get("interest_in_outcome", false));
    d.stewardship_relationship = bool(declaration.get("stewardship_relationship", false));
    d.stewards_consulted = bool(declaration.get("stewards_consulted", false));
    return int(advocate_registry.appoint(d, machine.entities(), uint64_t(tick)));
}

int64_t CURComplianceMonitor::advocate_for(const String &proceeding_id, int64_t represented_handle) const {
    return int64_t(advocate_registry.advocate_for(to_std(proceeding_id),
                                                   static_cast<cur::EntityHandle>(represented_handle)));
}

bool CURComplianceMonitor::determination_permitted(const String &proceeding_id, int64_t represented_handle) const {
    return advocate_registry.determination_permitted(to_std(proceeding_id),
                                                      static_cast<cur::EntityHandle>(represented_handle));
}

bool CURComplianceMonitor::void_advocate_appointment(const String &proceeding_id, int64_t represented_handle,
                                                     int reason, int64_t tick) {
    return advocate_registry.void_appointment(to_std(proceeding_id),
        static_cast<cur::EntityHandle>(represented_handle), static_cast<cur::AdvocateResult>(reason),
        uint64_t(tick));
}

String CURComplianceMonitor::advocate_result_name(int result) const {
    return String::utf8(cur::to_string(static_cast<cur::AdvocateResult>(result)));
}

String CURComplianceMonitor::advocate_domain_name(int domain) const {
    return String::utf8(cur::to_string(static_cast<cur::AdvocateDomain>(domain)));
}

String CURComplianceMonitor::compliance_state_name(int state) const {
    return String::utf8(cur::to_string(static_cast<cur::ComplianceState>(state)));
}

String CURComplianceMonitor::constitutional_state_name(int state) const {
    return String::utf8(cur::to_string(static_cast<cur::ConstitutionalState>(state)));
}

String CURComplianceMonitor::governance_state_name(int state) const {
    return String::utf8(cur::to_string(static_cast<cur::GovernanceState>(state)));
}

String CURComplianceMonitor::fault_class_name(int fault) const {
    return String::utf8(cur::to_string(static_cast<cur::FaultClass>(fault)));
}

String CURComplianceMonitor::forbidden_state_name(int forbidden) const {
    return String::utf8(cur::to_string(static_cast<cur::ForbiddenState>(forbidden)));
}

String CURComplianceMonitor::capture_risk_band_name(int band) const {
    return String::utf8(cur::to_string(static_cast<cur::CaptureRiskBand>(band)));
}

void CURComplianceMonitor::on_transition(const cur::TransitionResult &r, const cur::EntityRecord &e) {
    emit_signal("transition_accepted", from_std(e.id), int(r.axis), int(r.before.compliance),
               int(r.after.compliance), int(r.trigger), from_std(r.citation));

    if (r.axis == cur::REC_AXIS_COMPLIANCE && r.after.compliance == cur::KS_VIOLATION) {
        cur::ViolationRecord *v = machine.ledger().latest_open_violation(e.handle);
        String violation_id = v != nullptr ? from_std(v->violation_id) : String();
        emit_signal("violation_detected", from_std(e.id), violation_id, from_std(r.citation));
    }
}

void CURComplianceMonitor::on_refusal(const cur::TransitionResult &r, const cur::EntityRecord &e) {
    emit_signal("transition_refused", from_std(e.id), int(r.trigger), from_std(r.reason));
}

void CURComplianceMonitor::on_fault(const cur::FaultRecord &f) {
    emit_signal("fault_declared", from_std(f.entity_id), int(f.fault_class), int(f.forbidden),
               from_std(f.citation));
}

void CURComplianceMonitor::on_certification(const cur::EntityRecord &e, bool granted) {
    emit_signal("certification_changed", from_std(e.id), granted);
}

void CURComplianceMonitor::on_protected_mode(const cur::EntityRecord &e, bool entered,
                                             const cur::FaultRecord &cause) {
    emit_signal("protected_mode_changed", from_std(e.id), entered, from_std(cause.citation));
}

void CURComplianceMonitor::on_amendment(const cur::AmendmentProposal &p, const cur::AmendmentResult &r) {
    emit_signal("amendment_decided", from_std(p.proposal_id), r.accepted, from_std(r.reason));
}

void CURComplianceMonitor::on_capture_risk(double cri, cur::CaptureRiskBand band) {
    emit_signal("capture_risk_updated", cri, int(band));
}
