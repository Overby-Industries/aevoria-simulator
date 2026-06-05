#ifndef ALARM_SYSTEM_H
#define ALARM_SYSTEM_H

#include <gdextension_interface.h>
#include <godot.hpp>
#include <Godot.hpp>
#include <Node.hpp>
#include <vector>
#include <string>
#include <ctime>

using namespace godot;

class AlarmSystem : public Node {
    GODOT_CLASS(AlarmSystem, Node)

private:
    struct Alarm {
        std::string alarmType;
        std::string message;
        std::string corruptorUID;
        std::string targetUID;
        std::string resourceOrAction;
        time_t triggerTime;
        bool isResolved;
    };

    std::vector<Alarm> activeAlarms;
    std::unordered_map<std::string, std::vector<std::string>> corruptionRecords; // UID -> [Alarm Types]

public:
    static void _register_methods();

    AlarmSystem();
    ~AlarmSystem();

    void _init();

    // Methods to expose to GDScript
    void trigger_alarm(const String& alarmType, const String& message, const String& corruptorUID, const String& targetUID, const String& resource);
    void resolve_alarm(int alarmIndex, const String& solution);
    Array get_active_alarms();
    Array get_corruption_record(const String& UID);
};

#endif // ALARM_SYSTEM_H