#pragma once

// Godot-facing wrapper around a cur::Regulation (see include/cur/cur_regulation.h
// in the CUR submodule). A Resource, not a Node, so a designer can author one
// CURGodotBridge per citable provision as a .tres file and configure it entirely
// from the Inspector — no C++ required to add or tune a regulation.
//
// build_regulation() is the only thing that isn't Variant-safe here, so it is
// not bound to ClassDB; CURComplianceMonitor calls it directly in C++ when it
// loads its configured regulation list.

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/string.hpp>

#include <cur/cur.h>

namespace godot {

class CURGodotBridge : public Resource {
    GDCLASS(CURGodotBridge, Resource)

private:
    String regulation_id;
    int domain = cur::DOMAIN_CROSS_DOMAIN;
    String description;
    String citation;
    PackedInt32Array event_triggers;  // cur::EventType values; empty == applies to all
    int required_guards = cur::guard::NONE;
    int minimum_tier = 0;
    int breach_class = cur::FC_CLASS_II;
    int declares_forbidden = cur::FS_NONE;
    bool enabled = true;

protected:
    static void _bind_methods();

public:
    CURGodotBridge();
    ~CURGodotBridge() override;

    void set_regulation_id(const String &p_id);
    String get_regulation_id() const;

    void set_domain(int p_domain);
    int get_domain() const;

    void set_description(const String &p_description);
    String get_description() const;

    void set_citation(const String &p_citation);
    String get_citation() const;

    void set_event_triggers(const PackedInt32Array &p_triggers);
    PackedInt32Array get_event_triggers() const;

    void set_required_guards(int p_guards);
    int get_required_guards() const;

    void set_minimum_tier(int p_tier);
    int get_minimum_tier() const;

    void set_breach_class(int p_class);
    int get_breach_class() const;

    void set_declares_forbidden(int p_forbidden);
    int get_declares_forbidden() const;

    void set_enabled(bool p_enabled);
    bool get_enabled() const;

    // Internal C++ API — not bound. cur::Regulation is not a Variant type.
    cur::Regulation build_regulation() const;
};

}  // namespace godot
