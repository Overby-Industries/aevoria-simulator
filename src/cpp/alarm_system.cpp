#include "alarm_system.h"
#include <gdextension_interface.h>
#include <godot.hpp>

using namespace godot;

void AlarmSystem::_register_methods() {
    register_method("_init", &AlarmSystem::_init);
    register_method("trigger_alarm", &AlarmSystem::trigger_alarm);
    register_method("resolve_alarm", &AlarmSystem::resolve_alarm);
    register_method("get_active_alarms", &AlarmSystem::get_active_alarms);
    register_method("get_corruption_record", &AlarmSystem::get_corruption_record);
}

AlarmSystem::AlarmSystem() {
    // Constructor
}

AlarmSystem::~AlarmSystem() {
    // Destructor
}

void AlarmSystem::_init() {
    // Initialization
}

void AlarmSystem::trigger_alarm(const String& alarmType, const String& message, const String& corruptorUID, const String& targetUID, const String& resource) {
    Alarm newAlarm;
    newAlarm.alarmType = alarmType.utf8().get_data();
    newAlarm.message = message.utf8().get_data();
    newAlarm.corruptorUID = corruptorUID.utf8().get_data();
    newAlarm.targetUID = targetUID.utf8().get_data();
    newAlarm.resourceOrAction = resource.utf8().get_data();
    newAlarm.triggerTime = std::time(nullptr);
    newAlarm.isResolved = false;

    activeAlarms.push_back(newAlarm);
    corruptionRecords[corruptorUID.utf8().get_data()].push_back(alarmType.utf8().get_data());

    Godot::print("🚨 ALARM TRIGGERED: " + alarmType + " | " + message);
}

void AlarmSystem::resolve_alarm(int alarmIndex, const String& solution) {
    if (alarmIndex >= 0 && alarmIndex < activeAlarms.size()) {
        activeAlarms[alarmIndex].isResolved = true;
        Godot::print("✅ ALARM RESOLVED: " + activeAlarms[alarmIndex].alarmType + " | Solution: " + solution);
    }
}

Array AlarmSystem::get_active_alarms() {
    Array alarms;
    for (const auto& alarm : activeAlarms) {
        Dictionary alarmDict;
        alarmDict["alarmType"] = alarm.alarmType.c_str();
        alarmDict["message"] = alarm.message.c_str();
        alarmDict["corruptorUID"] = alarm.corruptorUID.c_str();
        alarmDict["targetUID"] = alarm.targetUID.c_str();
        alarmDict["resourceOrAction"] = alarm.resourceOrAction.c_str();
        alarmDict["isResolved"] = alarm.isResolved;
        alarms.push_back(alarmDict);
    }
    return alarms;
}

Array AlarmSystem::get_corruption_record(const String& UID) {
    Array records;
    std::string uidStr = UID.utf8().get_data();
    for (const auto& record : corruptionRecords[uidStr]) {
        records.push_back(record.c_str());
    }
    return records;
}