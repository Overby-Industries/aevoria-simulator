#include "alarm_system.h"
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void AlarmSystem::_bind_methods() {
    ClassDB::bind_method(
        D_METHOD("trigger_alarm", "alarmType", "message", "corruptorUID", "targetUID", "resource"),
        &AlarmSystem::trigger_alarm
    );

    ClassDB::bind_method(
        D_METHOD("resolve_alarm", "alarmIndex", "solution"),
        &AlarmSystem::resolve_alarm
    );

    ClassDB::bind_method(
        D_METHOD("get_active_alarms"),
        &AlarmSystem::get_active_alarms
    );

    ClassDB::bind_method(
        D_METHOD("get_corruption_record", "UID"),
        &AlarmSystem::get_corruption_record
    );
}

AlarmSystem::AlarmSystem() {}
AlarmSystem::~AlarmSystem() {}

void AlarmSystem::_ready() {
    UtilityFunctions::print("AlarmSystem initialized.");
}

void AlarmSystem::trigger_alarm(const String& alarmType,
                                const String& message,
                                const String& corruptorUID,
                                const String& targetUID,
                                const String& resource) 
{
    Alarm newAlarm;
    newAlarm.alarmType = alarmType.utf8().get_data();
    newAlarm.message = message.utf8().get_data();
    newAlarm.corruptorUID = corruptorUID.utf8().get_data();
    newAlarm.targetUID = targetUID.utf8().get_data();
    newAlarm.resourceOrAction = resource.utf8().get_data();
    newAlarm.triggerTime = std::time(nullptr);
    newAlarm.isResolved = false;

    activeAlarms.push_back(newAlarm);
    corruptionRecords[newAlarm.corruptorUID].push_back(newAlarm.alarmType);

    UtilityFunctions::print("🚨 ALARM TRIGGERED: ", alarmType, " | ", message);
}

void AlarmSystem::resolve_alarm(int alarmIndex, const String& solution) {
    if (alarmIndex >= 0 && alarmIndex < (int)activeAlarms.size()) {
        Alarm& alarm = activeAlarms[alarmIndex];
        alarm.isResolved = true;

        UtilityFunctions::print("✅ ALARM RESOLVED: ",
                                String(alarm.alarmType.c_str()),
                                " | Solution: ",
                                solution);
    }
}

Array AlarmSystem::get_active_alarms() {
    Array alarms;

    for (const auto& alarm : activeAlarms) {
        Dictionary alarmDict;
        alarmDict["alarmType"] = String(alarm.alarmType.c_str());
        alarmDict["message"] = String(alarm.message.c_str());
        alarmDict["corruptorUID"] = String(alarm.corruptorUID.c_str());
        alarmDict["targetUID"] = String(alarm.targetUID.c_str());
        alarmDict["resourceOrAction"] = String(alarm.resourceOrAction.c_str());
        alarmDict["isResolved"] = alarm.isResolved;
        alarmDict["triggerTime"] = (int64_t)alarm.triggerTime;

        alarms.push_back(alarmDict);
    }

    return alarms;
}

Array AlarmSystem::get_corruption_record(const String& UID) {
    Array records;
    std::string uidStr = UID.utf8().get_data();

    if (corruptionRecords.count(uidStr)) {
        for (const auto& record : corruptionRecords[uidStr]) {
            records.push_back(String(record.c_str()));
        }
    }

    return records;
}

} // namespace godot