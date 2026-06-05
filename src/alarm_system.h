#ifndef ALARM_SYSTEM_H
#define ALARM_SYSTEM_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <vector>
#include <string>
#include <unordered_map>
#include <ctime>

namespace godot {

/**
 * @brief AlarmSystem
 * 
 * The AlarmSystem is the crisis‑response and governance‑oversight subsystem
 * for the Aevoria Simulator. It is responsible for:
 * 
 *  - Logging corruption‑related events (Sybil attacks, bribery, hoarding)
 *  - Triggering alarms when suspicious behavior occurs
 *  - Tracking unresolved alarms for review by governance systems
 *  - Maintaining corruption records per player UID
 *  - Integrating with:
 *      • CorruptionDetector (event source)
 *      • DirectDemocracyOS (public review, votes)
 *      • RegulatoryEngine (CUR‑law enforcement)
 *      • ResourceCommons (resource‑related alarms)
 * 
 * This class acts as the “black box recorder” for the society.
 */
class AlarmSystem : public Node {
    GDCLASS(AlarmSystem, Node)

private:
    /**
     * @brief Internal alarm structure.
     * 
     * Represents a single corruption or crisis event.
     */
    struct Alarm {
        std::string alarmType;        // e.g., "Sybil Attack", "Bribery", "Hoarding"
        std::string message;          // Human‑readable description
        std::string corruptorUID;     // Who caused the alarm
        std::string targetUID;        // Who was affected (if applicable)
        std::string resourceOrAction; // Resource or action involved
        time_t triggerTime;           // Timestamp
        bool isResolved;              // Whether governance resolved it
    };

    // Active alarms awaiting resolution
    std::vector<Alarm> activeAlarms;

    // Historical corruption record: UID -> list of alarm types
    std::unordered_map<std::string, std::vector<std::string>> corruptionRecords;

protected:
    /**
     * @brief Bind methods and properties to Godot.
     * 
     * Called automatically during engine initialization.
     */
    static void _bind_methods();

public:
    /**
     * @brief Constructor.
     */
    AlarmSystem();

    /**
     * @brief Destructor.
     */
    ~AlarmSystem();

    /**
     * @brief Called when the node enters the scene tree.
     */
    void _ready() override;

    /**
     * @brief Called every frame.
     * 
     * @param delta Time since last frame.
     * 
     * This can be used for:
     *  - auto‑resolving alarms after timeouts
     *  - escalating unresolved alarms
     *  - triggering governance events
     */
    void _process(double delta) override;

    // ---------------------------------------------------------------------
    // Methods exposed to GDScript
    // ---------------------------------------------------------------------

    /**
     * @brief Creates
    */
    Array get_corruption_record(const String& UID);
};

} // namespace godot

#endif // ALARM_SYSTEM_H