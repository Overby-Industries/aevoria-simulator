#pragma once

// CURComplianceMonitor — the Godot-facing home of the CUR state machine.
//
// A Node (per the brief: it has to be able to live in the scene tree) that
// owns exactly one cur::CURStateMachine and implements cur::ICURObserver so
// every transition, refusal, fault, certification, Protected Mode change,
// amendment decision, and capture-risk update the machine produces is
// re-emitted as a Godot signal GDScript can react to.
//
// This class does the Variant marshaling (String <-> std::string, Dictionary
// <-> TransitionContext/TransitionResult, etc.) so nothing upstream of it
// needs to know libcur exists. libcur itself stays engine-agnostic; this file
// is the one place that depends on both.

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

#include <cur/cur.h>

namespace godot {

class CURGodotBridge;

class CURComplianceMonitor : public Node, public cur::ICURObserver {
    GDCLASS(CURComplianceMonitor, Node)

private:
    cur::CURStateMachine machine;
    cur::AdvocateRegistry advocate_registry;  // CUR-A §7.7, CUR-E §1.6
    Array regulations;  // expected to hold CURGodotBridge resources

    void load_configured_regulations();

protected:
    static void _bind_methods();

public:
    CURComplianceMonitor();
    ~CURComplianceMonitor() override;

    void _ready() override;

    void set_regulations(const Array &p_regulations);
    Array get_regulations() const;

    // --- entities -----------------------------------------------------------
    int64_t register_entity(const String &id, int category, int subject_class,
                            const String &display_name = String());
    int64_t find_entity(const String &id) const;

    // --- stepping -------------------------------------------------------------
    Dictionary submit_operational(int64_t entity_handle, int event_type,
                                  const Dictionary &context, int64_t tick);
    Dictionary dry_run_operational(int64_t entity_handle, int event_type,
                                   const Dictionary &context, int64_t tick) const;

    // --- queries --------------------------------------------------------------
    int get_compliance_state(int64_t entity_handle) const;
    int get_constitutional_state(int64_t entity_handle) const;
    int get_governance_state(int64_t entity_handle) const;
    bool in_protected_mode(int64_t entity_handle) const;
    bool any_protected_mode() const;
    int64_t protected_mode_count() const;

    // --- Protected Mode recovery, PDDC §12.5(d) --------------------------------
    bool certify_recovery(int64_t entity_handle, bool instrument_remediated,
                          bool safe_state_verified, bool no_further_risk,
                          int64_t tick, const String &certificate_id);

    // --- capture risk -----------------------------------------------------------
    double update_capture_risk(const Dictionary &inputs, int64_t tick);
    double get_capture_risk() const;
    int get_capture_risk_band() const;

    // --- amendments, the AI contributor path -------------------------------------
    Dictionary propose_regulation_amendment(const Ref<CURGodotBridge> &regulation,
                                            const String &proposal_id,
                                            const String &author_id,
                                            const String &rationale, int64_t tick);

    // --- audit trail --------------------------------------------------------------
    Array get_audit_tail(int64_t n) const;
    Array get_audit_for_entity(const String &entity_id) const;
    String export_audit_json(int64_t max_records = 0) const;

    // --- violations -----------------------------------------------------------------
    Array get_violations_for(const String &entity_id) const;

    // --- advocate registry, CUR-A §7.7 / CUR-E §1.6 -----------------------------------
    // Representation of interests that cannot speak for themselves. Confers no
    // authority over any being -- cur::AdvocateRegistry::confers_authority() is
    // false unconditionally; nothing here produces a measure, sanction, or
    // state change. determination_permitted() is what a caller reports through
    // TransitionContext::advocate_cleared before submitting
    // EV_REPRESENTED_DETERMINATION.
    void declare_party(const String &proceeding_id, int64_t party_handle);
    void record_party_representation(const String &proceeding_id, int64_t advocate_handle,
                                     int64_t party_handle);
    // declaration keys: advocate, represented, domain, proceeding_id,
    // expertise_demonstrated, dependent_on_party, interest_in_outcome,
    // stewardship_relationship, stewards_consulted -- see cur_advocate.h's
    // AdvocateDeclaration. Returns an AdvocateResult (ADV_APPOINTED on success).
    int appoint_advocate(const Dictionary &declaration, int64_t tick);
    int64_t advocate_for(const String &proceeding_id, int64_t represented_handle) const;
    bool determination_permitted(const String &proceeding_id, int64_t represented_handle) const;
    bool void_advocate_appointment(const String &proceeding_id, int64_t represented_handle,
                                   int reason, int64_t tick);
    String advocate_result_name(int result) const;
    String advocate_domain_name(int domain) const;

    // --- state names, for UI ---------------------------------------------------------
    // Wraps libcur's own cur::to_string() so a display never hardcodes a name
    // table that could drift from the C++ enum definitions.
    String compliance_state_name(int state) const;
    String constitutional_state_name(int state) const;
    String governance_state_name(int state) const;
    String fault_class_name(int fault) const;
    String forbidden_state_name(int forbidden) const;
    String capture_risk_band_name(int band) const;

    // --- cur::ICURObserver — re-emitted as Godot signals -------------------------------
    void on_transition(const cur::TransitionResult &r, const cur::EntityRecord &e) override;
    void on_refusal(const cur::TransitionResult &r, const cur::EntityRecord &e) override;
    void on_fault(const cur::FaultRecord &f) override;
    void on_certification(const cur::EntityRecord &e, bool granted) override;
    void on_protected_mode(const cur::EntityRecord &e, bool entered,
                           const cur::FaultRecord &cause) override;
    void on_amendment(const cur::AmendmentProposal &p, const cur::AmendmentResult &r) override;
    void on_capture_risk(double cri, cur::CaptureRiskBand band) override;
};

}  // namespace godot
