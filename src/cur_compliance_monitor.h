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
